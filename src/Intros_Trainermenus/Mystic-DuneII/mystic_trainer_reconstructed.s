; ---------------------------------------------------------------------------
; MyStiC Trainer Menu for Dune II
; Programmed by Colorboy aka. N4cer.
; ---------------------------------------------------------------------------
;
; Reconstructed by Volker Schwaberow <volker@schwaberow.de>
;
; Build:
;   vasmm68k_mot -m68000 -no-opt -Fbin -o mystic_trainer_reconstructed.bin mystic_trainer_reconstructed.s
;
; Notes:
; - Code has been reconstructed as normal Motorola 68000 source.
; - Data regions are embedded directly and kept byte-exact against the Ghidra export.
; - The program expects to run at address 0, matching the Ghidra image base.
; ---------------------------------------------------------------------------

        org     $00000000

; ---------------------------------------------------------------------------
; Hardware / OS constants
; ---------------------------------------------------------------------------

CUSTOM                  equ     $00dff000
DMACONR                 equ     $00dff002
VPOSR_VHPOSR_LONG       equ     $00dff004
BLTCON0                 equ     $00dff040
BLTCON1                 equ     $00dff042
BLTAFWM                 equ     $00dff044
BLTBPTH                 equ     $00dff050
BLTBPTL                 equ     $00dff052
BLTAPTH                 equ     $00dff054
BLTSIZE                 equ     $00dff058
BLTCMOD                 equ     $00dff060
BLTBMOD                 equ     $00dff062
BLTAMOD                 equ     $00dff064
BLTDMOD                 equ     $00dff066
BLTBDAT                 equ     $00dff072
BLTADAT                 equ     $00dff074
COP1LCH                 equ     $00dff080
COPJMP1                 equ     $00dff088
DMACON                  equ     $00dff096
INTENA                  equ     $00dff09a

CIAA_PRA_JOY_MOUSE      equ     $00bfe001
CIAA_TOD_LOW            equ     $00bfe801
CIAA_TOD_MID            equ     $00bfe901
CIAA_TOD_HIGH           equ     $00bfea01
CIAA_SDR_KEYBOARD       equ     $00bfec01

EXEC_BASE_PTR           equ     $00000004
LEVEL3_INTERRUPT_VECTOR equ     $0000006c
saved_level3_interrupt_vector equ $00000290

_LVOForbid              equ     -132
_LVOEnable              equ     -138
_LVOCloseLibrary        equ     -414
_LVOOpenLibrary         equ     -552

; Observed graphics.library calls in this binary.
GFX_OPEN_FONT_CALL      equ     -72
GFX_CLOSE_FONT_CALL     equ     -78

; ---------------------------------------------------------------------------
; Main program
; ---------------------------------------------------------------------------

intro_entry_mainloop:
        lea     CUSTOM,a5                       ; Keep the custom chip base handy for the setup writes.

        ; Patch BPL1 pointer words in the copper list.
        lea     copper_bpl1pth_word(pc),a0      ; The copper list has dummy words until we know the buffer.
        lea     front_bitplane_buffer(pc),a4    ; This is the visible bitplane shown first.
        move.l  a4,d0                           ; Split the 32-bit address into the Amiga's high/low words.
        move.w  d0,4(a0)                        ; Low word goes into the later copper data slot.
        swap    d0                              ; Bring the high word down where move.w can store it.
        move.w  d0,(a0)                         ; High word goes into the first copper data slot.

        ; Patch BPL2 pointer words in the copper list.
        lea     copper_bpl2pth_word(pc),a0      ; Same trick, but this points at the text plane.
        lea     text_render_bitplane_buffer(pc),a4 ; Original encoding is PC-relative, not absolute long.
        move.l  a4,d0
        move.w  d0,4(a0)
        swap    d0
        move.w  d0,(a0)

        ; Stop task switching while the display and interrupt state is changed.
        movea.l EXEC_BASE_PTR.w,a6              ; ExecBase lives at address 4 on AmigaOS.
        jsr     _LVOForbid(a6)                  ; Stop task switches while we borrow the display.

        ; Open graphics.library.
        lea     graphics_library_name(pc),a1    ; Ask Exec for graphics.library.
        moveq   #0,d0                           ; Version 0 means "any version is fine".
        jsr     _LVOOpenLibrary(a6)
        move.l  d0,gfxbase_ptr                  ; Save GfxBase so cleanup can restore the old copper list.

        ; Open/use topaz.font through graphics.library.
        movea.l d0,a6                           ; Graphics.library calls want GfxBase in A6.
        lea     topaz_textattr_name_ptr(pc),a0  ; The TextAttr is in our runtime data block.
        lea     topaz_font_name(pc),a1
        move.l  a1,(a0)                         ; Patch the font name pointer before OpenFont.
        jsr     GFX_OPEN_FONT_CALL(a6)
        move.l  d0,textfont_handle_ptr          ; The renderer pulls glyph data out of this font handle.

        bsr.w   init_copper_template_patch_area ; Copy the small runtime copper snippets used later.
        bsr.w   render_text_page_to_bitplane    ; Draw the static trainer text into bitplane memory.

        ; Install custom copper list.
        lea     copper_display_setup_start(pc),a0 ; Copper starts at the display setup words before BPL pointers.
        move.l  a0,COP1LCH-CUSTOM(a5)
        clr.w   COPJMP1-CUSTOM(a5)              ; Poke COPJMP1 so the copper reloads the new list now.

        ; Install level-3 interrupt hook/trampoline.
        lea     level3_vblank_text_anim_irq(pc),a0 ; Level 3 is the usual vertical blank interrupt.
        lea     LEVEL3_INTERRUPT_VECTOR.w,a1
        move.l  (a1),saved_level3_interrupt_vector ; Keep the old handler so exit is clean.
        move.l  a0,(a1)                         ; Point VBlank at our little colour animator.

        move.w  #$0020,DMACON-CUSTOM(a5)        ; Clear sprite DMA; the intro only needs bitplanes/blitter.
        move.w  #$c070,INTENA-CUSTOM(a5)        ; Enable the interrupt bits this payload relies on.

main_restart_rotation_script:
        movea.l #rotation_delta_table,a4        ; Start again at the first camera/rotation script entry.

main_next_script_segment:
        moveq   #0,d7
        move.w  (a4),d7                         ; First word is the number of frames for this segment.
        subi.l  #1,d7                           ; DBF counts down to -1, so pre-subtract one.

main_script_frame_loop:
        move.w  2(a4),d1                        ; Apply this segment's X rotation speed.
        add.w   d1,rotation_angle_x
        move.w  4(a4),d1                        ; Then Y rotation.
        add.w   d1,rotation_angle_y
        move.w  6(a4),d1                        ; Then Z rotation.
        add.w   d1,rotation_angle_z
        moveq   #0,d1
        move.w  8(a4),d1                        ; Camera depth is nudged in and out for the zoom feel.
        add.l   d1,camera_depth_z

        cmpi.w  #$0168,rotation_angle_x         ; $168 is 360 decimal, so angles wrap after a full turn.
        blt.s   main_angle_x_ok
        move.w  #1,rotation_angle_x             ; Wrap to 1, matching the original table lookup behaviour.
main_angle_x_ok:
        cmpi.w  #$0168,rotation_angle_y
        blt.s   main_angle_y_ok
        move.w  #1,rotation_angle_y
main_angle_y_ok:
        cmpi.w  #$0168,rotation_angle_z
        blt.s   main_angle_z_ok
        move.w  #1,rotation_angle_z
main_angle_z_ok:
        bsr.w   update_rotating_object_vertices ; Rotate/project every point for the current frame.
        bsr.w   render_wireframe_frame          ; Clear, draw all edges, then merge the frame into view.

        ; Raw keyboard scan from CIA-A.
        move.b  CIAA_SDR_KEYBOARD,d0            ; Read the raw key code straight from the CIA serial data.
        btst    #6,CIAA_PRA_JOY_MOUSE           ; Mouse/fire button can also leave the trainer.
        beq.s   exit_intro

        cmpi.b  #$7f,d0                         ; Space toggles every trainer option at once.
        beq.w   toggle_all_options
        cmpi.b  #$75,d0                         ; Escape exits back to the caller.
        beq.s   exit_intro
        cmpi.b  #$5f,d0                         ; F1 through F7 toggle the visible option rows.
        beq.w   option_f1_entry
        cmpi.b  #$5d,d0
        beq.w   option_f2_entry
        cmpi.b  #$5b,d0
        beq.w   option_f3_entry
        cmpi.b  #$59,d0
        beq.w   option_f4_entry
        cmpi.b  #$57,d0
        beq.w   option_f5_entry
        cmpi.b  #$55,d0
        beq.w   option_f6_entry
        cmpi.b  #$53,d0
        beq.w   option_f7_entry

continue_script_loop:
        dbf     d7,main_script_frame_loop       ; Stay on this script entry until its frame count expires.
        adda.l  #10,a4                          ; Each script entry is five words long.
        cmpa.l  #graphics_library_name,a4       ; The text block follows the table, so it acts as the end mark.
        bne.w   main_next_script_segment

        clr.w   rotation_angle_x                ; Reset the pose before looping the animation script.
        clr.w   rotation_angle_y
        clr.w   rotation_angle_z
        move.l  #$0000c350,camera_depth_z       ; Restore the original camera distance.
        bra.w   main_restart_rotation_script

exit_intro:
        move.l  saved_level3_interrupt_vector(pc),LEVEL3_INTERRUPT_VECTOR.w ; Put the old IRQ vector back.
        move.w  #$83e0,DMACON-CUSTOM(a5)        ; Re-enable the normal DMA mix expected by the system.
        move.w  #$e02c,INTENA-CUSTOM(a5)        ; Restore the interrupt mask the payload wants on exit.

        movea.l gfxbase_ptr,a6
        move.l  $26(a6),COP1LCH-CUSTOM(a5)      ; graphics.library keeps the system copper pointer here.
        clr.w   COPJMP1-CUSTOM(a5)              ; Force the copper to pick the system list back up.

        movea.l textfont_handle_ptr,a1
        jsr     GFX_CLOSE_FONT_CALL(a6)         ; Close the Topaz font handle we opened for the menu text.
        movea.l a6,a1                           ; CloseLibrary wants the library base in A1.
        movea.l EXEC_BASE_PTR.w,a6
        jsr     _LVOCloseLibrary(a6)
        jsr     _LVOEnable(a6)                  ; Let Exec schedule tasks again.
        moveq   #0,d0
        rts

; ---------------------------------------------------------------------------
; Text renderer
; ---------------------------------------------------------------------------

render_text_page_to_bitplane:
        movem.l d0-d7/a0-a6,-(sp)               ; This is called from the main loop, so preserve everything.
        movea.l textfont_handle_ptr(pc),a0
        movea.l $22(a0),a3              ; TextFont.tf_CharData
        move.l  a3,font_bitmap_ptr              ; Keep the glyph bitmap pointer visible for debugging.
        move.w  $26(a0),d1              ; TextFont.tf_Modulo
        lea     trainer_menu_text_stream,a2     ; Text stream uses printable bytes plus small control codes.
        moveq   #0,d2
        moveq   #$20,d3                         ; Font starts at ASCII space, so subtract $20 for the index.
        move.l  d2,d4                           ; D4 is the byte column inside the current text row.

.next_glyph_position:
        movea.l a3,a0                           ; Reset to the first glyph in the font bitmap.
        movea.l a4,a1                           ; A4 tracks the top-left address for this text row.
        lea     0(a1,d4.w),a1                   ; Add the current character column.

.next_text_byte:
        move.b  (a2)+,d2                        ; Pull the next byte from the embedded menu text.
        beq.s   .done                           ; Zero terminates the whole text stream.
        cmpi.b  #$0a,d2                         ; $0A means "next normal line".
        bne.s   .not_newline
        lea     $280(a4),a4                     ; Eight font rows * 80 bytes per bitplane row.
        moveq   #0,d4                           ; Start again at column zero.
        bra.s   .next_glyph_position

.not_newline:
        cmpi.b  #$0b,d2                         ; $0B jumps down to the lower option block.
        bne.s   .not_lower_block
        lea     $3c0(a4),a4                     ; Larger vertical skip used between the trainer rows.
        moveq   #$14,d4                         ; Indent the option status column.
        bra.s   .next_glyph_position

.not_lower_block:
        cmpi.b  #$0c,d2                         ; $0C is a smaller horizontal reposition.
        bne.s   .draw_glyph
        moveq   #$12,d4                         ; Used to centre the title and option text.
        bra.s   .next_glyph_position

.draw_glyph:
        sub.w   d3,d2                           ; Convert ASCII to a glyph column inside Topaz.
        lea     0(a0,d2.w),a0                   ; Point at the first row byte of this glyph.
        moveq   #7,d0                           ; Topaz 8 is eight pixel rows tall.
.copy_glyph_row:
        move.b  (a0),(a1)                       ; Copy one glyph row byte into the text bitplane.
        lea     0(a0,d1.w),a0                   ; Next source row uses the font modulo.
        lea     $50(a1),a1                      ; Next screen row is 80 bytes lower.
        dbf     d0,.copy_glyph_row
        addq.w  #1,d4                           ; Move one byte to the right for the next character.
        bra.s   .next_glyph_position

.done:
        movem.l (sp)+,d0-d7/a0-a6
        rts

; ---------------------------------------------------------------------------
; Level-3 / VBlank text effect hook
; ---------------------------------------------------------------------------

level3_vblank_text_anim_irq:
        movem.l d0-d7/a0-a6,-(sp)               ; The interrupt borrows registers, so save the lot.
        tst.w   vblank_text_anim_countdown      ; Only run the colour shuffle every so many VBlanks.
        beq.s   .do_effect
        subi.w  #1,vblank_text_anim_countdown   ; Not time yet, just count down and return.
        bra.s   .return_to_main

.do_effect:
        move.w  #$40,vblank_text_anim_countdown ; Slow the palette motion down so it feels intentional.

        lea     vblank_color_cycle_source_words(pc),a0 ; This small list is rotated in place.
        movea.l a0,a1
        moveq   #$29,d2                         ; Rotate enough words to feed all copper colour slots.
.rotate_words:
        move.w  (a1),d0                         ; Swap neighbouring colour words.
        move.w  2(a1),d1
        move.w  d1,(a1)
        move.w  d0,2(a1)
        lea     2(a1),a1                        ; Slide one word and keep bubbling the colours along.
        dbf     d2,.rotate_words

        lea     vblank_color_cycle_source_words(pc),a0
        lea     copper_color_cycle_dest_slot_01(pc),a1 ; Start at the first animated copper colour value.
        moveq   #$0d,d0                         ; Fourteen colour bands are copied into the copper list.
.copy_color_word:
        move.w  (a0)+,(a1)                      ; Replace only the colour data word, not the wait command.
        lea     8(a1),a1                        ; Next animated slot is eight bytes later.
        dbf     d0,.copy_color_word

.return_to_main:
        movem.l (sp)+,d0-d7/a0-a6
        jmp     intro_entry_mainloop            ; This binary returns to its main loop from the IRQ path.

; ---------------------------------------------------------------------------
; CIA timing helpers
; ---------------------------------------------------------------------------

wait_for_cia_timer_delta:
        bsr.s   read_ciaa_24bit_timer           ; Take a cheap timestamp from CIA-A's TOD counter.
        move.l  d7,d6                           ; Keep the start value for the delta check.
.wait_loop:
        bsr.s   read_ciaa_24bit_timer
        sub.l   d6,d7                           ; Work out how far the counter moved.
        cmpi.w  #2,d7                           ; Wait for a tiny but real hardware-time delay.
        bcs.s   .wait_loop
        rts

read_ciaa_24bit_timer:
        move.b  CIAA_TOD_HIGH,d7                ; Read high, middle, low and pack them into D7.
        lsl.l   #8,d7
        move.b  CIAA_TOD_MID,d7
        lsl.l   #8,d7
        move.b  CIAA_TOD_LOW,d7
        rts

; ---------------------------------------------------------------------------
; Copper template initialisation
; ---------------------------------------------------------------------------

init_copper_template_patch_area:
        lea     copper_pointer_template_words(pc),a1 ; These are copied to runtime RAM exactly as shipped.
        lea     runtime_copper_pointer_patch_area(pc),a0
        moveq   #4,d0                           ; Five template chunks, counted with DBF.
.copy_slot:
        move.l  (a1)+,(a0)+                     ; Copy the first long and advance into the slot.
        move.l  (a1)+,(a0)                      ; Copy the second long beside it.
        lea     $4c(a0),a0                      ; Leave the same spacing the original runtime area expects.
        dbf     d0,.copy_slot
        bsr.s   wait_for_cia_timer_delta        ; Small hardware-paced pause before the intro continues.
        rts

; ---------------------------------------------------------------------------
; Keyboard option toggle dispatcher
; ---------------------------------------------------------------------------

option_f1_entry:
        movem.l d0-d7/a0-a6,-(sp)               ; Option handlers preserve the animation state.
        lea     option_unlimited_lives_onoff_text(pc),a1 ; A1 points at the four visible ON/OFF chars.
        lea     option_unlimited_lives_enabled_flag(pc),a2 ; A2 points at the matching runtime flag.
        bra.s   toggle_single_option

option_f2_entry:
        movem.l d0-d7/a0-a6,-(sp)
        lea     option_unlimited_energy_onoff_text(pc),a1 ; Same toggle helper, just a different row.
        lea     option_unlimited_energy_enabled_flag(pc),a2
        bra.s   toggle_single_option

option_f3_entry:
        movem.l d0-d7/a0-a6,-(sp)
        lea     option_unlimited_weaponry_onoff_text(pc),a1
        lea     option_unlimited_weaponry_enabled_flag(pc),a2
        bra.s   toggle_single_option

option_f4_entry:
        movem.l d0-d7/a0-a6,-(sp)
        lea     option_no_collision_onoff_text(pc),a1
        lea     option_no_collision_enabled_flag(pc),a2
        bra.s   toggle_single_option

option_f5_entry:
        movem.l d0-d7/a0-a6,-(sp)
        lea     option_in_game_keys_onoff_text(pc),a1
        lea     option_in_game_keys_enabled_flag(pc),a2
        bra.s   toggle_single_option

option_f6_entry:
        movem.l d0-d7/a0-a6,-(sp)
        lea     option_start_level_onoff_text(pc),a1
        lea     option_start_level_enabled_flag(pc),a2
        bra.s   toggle_single_option

option_f7_entry:
        movem.l d0-d7/a0-a6,-(sp)
        lea     option_unknown_option_7_onoff_text(pc),a1
        lea     option_unknown_option_7_enabled_flag(pc),a2

toggle_single_option:
        bchg    #0,(a2)                         ; Flip the low bit; the old bit tells us what to print.
        beq.s   .write_off                      ; If it was clear before, the visible state becomes OFF.
.write_on:
        move.b  #' ',(a1)                       ; Keep the text field four characters wide.
        move.b  #'O',1(a1)
        move.b  #'N',2(a1)
        move.b  #' ',3(a1)
        bra.s   .redraw
.write_off:
        move.b  #' ',(a1)                       ; "OFF" fills the same field without shifting the menu.
        move.b  #'O',1(a1)
        move.b  #'F',2(a1)
        move.b  #'F',3(a1)
.redraw:
        lea     text_render_bitplane_buffer(pc),a4 ; Re-render the menu so the changed text becomes pixels.
        bsr.w   render_text_page_to_bitplane
        movem.l (sp)+,d0-d7/a0-a6
        bra.w   continue_script_loop

toggle_all_options:
        movem.l d0-d7/a0-a6,-(sp)
        lea     trainer_all_options_toggle_state(pc),a0 ; One extra flag remembers the global toggle state.
        lea     option_unlimited_lives_onoff_text(pc),a1 ; Start at the first visible option field.
        lea     option_unlimited_lives_enabled_flag(pc),a2 ; And at the first matching flag word.
        bchg    #0,(a0)                         ; Flip between "all ON" and "all OFF" modes.
        beq.s   .all_off

.all_on:
        moveq   #6,d0                           ; Seven option rows, again counted with DBF.
.all_on_loop:
        move.b  #' ',(a1)
        move.b  #'O',1(a1)
        move.b  #'N',2(a1)
        move.b  #' ',3(a1)
        lea     $33(a1),a1                      ; Next ON/OFF field is 51 bytes later in the text stream.
        bclr    #0,(a2)                         ; Match the original polarity for an enabled row.
        lea     2(a2),a2                        ; Flags are word-sized even though only bit 0 matters.
        dbf     d0,.all_on_loop
        bra.s   .redraw

.all_off:
        moveq   #6,d0
.all_off_loop:
        move.b  #' ',(a1)
        move.b  #'O',1(a1)
        move.b  #'F',2(a1)
        move.b  #'F',3(a1)
        lea     $33(a1),a1                      ; Walk to the next option text field.
        bset    #0,(a2)                         ; Store the disabled polarity used by the trainer patcher.
        lea     2(a2),a2
        dbf     d0,.all_off_loop
.redraw:
        lea     text_render_bitplane_buffer(pc),a4
        bsr.w   render_text_page_to_bitplane
        movem.l (sp)+,d0-d7/a0-a6
        bra.w   continue_script_loop

; ---------------------------------------------------------------------------
; Raster sync wait
; ---------------------------------------------------------------------------

wait_for_raster_line_120:
.wait:
        move.l  VPOSR_VHPOSR_LONG,d0            ; Read VPOS and HPOS together so the beam position is stable.
        andi.l  #$0001ff00,d0                   ; Keep just the vertical beam line bits.
        cmpi.l  #$00012000,d0                   ; Wait until the raster reaches line $120.
        bne.s   .wait                           ; Spin here; this is the usual demo-scene beam sync.
        rts

; ---------------------------------------------------------------------------
; 3D wireframe transform and render helpers
; ---------------------------------------------------------------------------

update_rotating_object_vertices:
        movea.l #wireframe_vertex_table,a0      ; Work through the packed model/edge table in place.
.next_vertex:
        cmpi.w  #$0457,2(a0)                    ; $0457 marks a control/sentinel entry inside the table.
        bne.s   .normal_vertex
        adda.l  #4,a0                           ; Skip the marker words and land on the real coordinate data.
.normal_vertex:
        move.w  6(a0),d0                        ; Rotate model X/Z around the X axis first.
        move.w  10(a0),d1
        move.w  rotation_angle_x,d4
        jsr     rotate_point_by_angle_table
        move.w  d0,4(a0)                        ; Store the rotated component back into the working slots.
        move.w  d3,8(a0)

        move.w  2(a0),d0                        ; Then rotate around Y.
        move.w  8(a0),d1
        move.w  rotation_angle_y,d4
        jsr     rotate_point_by_angle_table
        move.w  d0,(a0)
        move.w  d3,8(a0)

        move.w  (a0),d0                         ; Finally rotate the projected X/Y pair around Z.
        move.w  4(a0),d1
        move.w  rotation_angle_z,d4
        jsr     rotate_point_by_angle_table
        move.w  d0,(a0)
        move.w  d3,4(a0)

        move.w  (a0),d3                         ; Feed the rotated 3D point into the perspective divide.
        move.w  4(a0),d4
        move.w  8(a0),d5
        jsr     project_3d_point_to_screen
        move.w  d3,(a0)                         ; Replace working X/Y with final screen coordinates.
        move.w  d4,4(a0)
        adda.l  #12,a0                          ; Next normal vertex/edge record.
        cmpa.l  #rotation_delta_table,a0        ; The animation script immediately follows the vertex data.
        bne.s   .next_vertex
        rts

rotate_point_by_angle_table:
        move.l  d0,d2                           ; Keep original X for the second half of the rotation.
        move.l  d1,d3                           ; Keep original Y as well; the formula needs both originals.
        muls.w  #2,d4                           ; Angles are table indexes, and the table stores words.
        movea.l #sin_table_q10000_start,a1      ; A1 walks forward from sine(0).
        movea.l #sin_table_q10000_end,a2        ; A2 walks backward to synthesize cosine.

        cmpi.w  #$021c,d4                       ; Past 270 degrees, signs flip in the fourth quadrant.
        ble.s   .under_270
        subi.w  #$021c,d4
        suba.l  d4,a2                           ; Mirror into the quarter-wave table.
        move.w  (a2),d5
        muls.w  #-1,d5                          ; Sine is negative in this quadrant.
        adda.l  d4,a1
        move.w  (a1),d4                         ; Cosine stays positive here.
        bra.s   .rotate

.under_270:
        cmpi.w  #$0168,d4                       ; Third quadrant: both values are mirrored, cosine negative.
        ble.s   .under_180
        subi.w  #$0168,d4
        adda.l  d4,a1
        move.w  (a1),d5
        muls.w  #-1,d5
        suba.l  d4,a2
        move.w  (a2),d4
        muls.w  #-1,d4
        bra.s   .rotate

.under_180:
        cmpi.w  #$00b4,d4                       ; Second quadrant: sine positive, cosine negative.
        ble.s   .under_90
        subi.w  #$00b4,d4
        suba.l  d4,a2
        move.w  (a2),d5
        adda.l  d4,a1
        move.w  (a1),d4
        muls.w  #-1,d4
        bra.s   .rotate

.under_90:
        adda.l  d4,a1                           ; First quadrant can read sine directly.
        move.w  (a1),d5
        suba.l  d4,a2                           ; Cosine is the same quarter-wave table read backwards.
        move.w  (a2),d4

.rotate:
        muls.w  d4,d0                           ; x' = x*cos - y*sin, with fixed-point scale 10000.
        muls.w  d5,d1
        sub.l   d1,d0
        divs.w  #10000,d0                       ; Bring the fixed-point result back to integer pixels.
        muls.w  d5,d2                           ; y' = x*sin + y*cos.
        muls.w  d4,d3
        add.l   d2,d3
        divs.w  #10000,d3
        rts

project_3d_point_to_screen:
        ext.l   d3                              ; Promote X/Y/Z to long before the multiplies and divides.
        ext.l   d4
        ext.l   d5
        muls.w  #-1,d4                          ; Flip Y so positive model space points upward on screen.
        muls.w  #-1,d5                          ; Flip Z to match the camera convention used by the model.
        add.l   camera_depth_z,d5               ; Move the point away from the camera to avoid a near divide.
        muls.w  projection_scale,d4             ; Perspective Y: scale first, then divide by depth.
        divs.w  d5,d4
        ext.l   d4
        muls.w  projection_scale,d3             ; Perspective X uses the same depth.
        divs.w  d5,d3
        ext.l   d3
        add.l   screen_center_x,d3              ; Shift from centred coordinates into screen coordinates.
        add.l   screen_center_y,d4
        rts

blitter_draw_line:
        movea.l draw_bitplane_buffer_ptr(pc),a0 ; Start with the active bitplane base.
        lea     $50,a1                         ; One bitplane row is 80 bytes wide.
        lea     $ffff,a2                       ; Constant -1, later used as the B data fill word.
        lsl.w   #1,d0                          ; X coordinates are converted to bitplane bit units.
        lsl.w   #1,d2
        cmp.l   d0,d2                          ; A zero-length line has nothing useful to draw.
        bne.s   .not_same_x
        cmp.l   d1,d3
        beq.w   .done
.not_same_x:
        move.l  a1,d4                          ; d4 becomes the byte address of the first line word.
        mulu.w  d1,d4                          ; y * 80 bytes per row.
        moveq   #-16,d5                        ; Round X down to a 16-pixel word boundary.
        and.w   d0,d5
        lsr.w   #3,d5                          ; Convert bit position to byte offset.
        add.w   d5,d4
        add.l   a0,d4                          ; Final blitter source/destination address.
        moveq   #0,d5                          ; d5 is built into the BLTCON1 octant/control byte.
        sub.w   d1,d3                          ; dy = y2 - y1.
        roxl.b  #1,d5                          ; Save the dy sign in the octant index.
        tst.w   d3
        bge.s   .dy_positive
        neg.w   d3                             ; Work with absolute dy from here on.
.dy_positive:
        sub.w   d0,d2                          ; dx = x2 - x1.
        roxl.b  #1,d5                          ; Save the dx sign in the octant index.
        tst.w   d2
        bge.s   .dx_positive
        neg.w   d2                             ; Work with absolute dx from here on.
.dx_positive:
        move.w  d3,d1                          ; Compare dy and dx to detect steep lines.
        sub.w   d2,d1
        bge.s   .not_steep
        exg     d2,d3                          ; The blitter expects the major axis in d3.
.not_steep:
        roxl.b  #1,d5                          ; Add the steep/shallow bit to the table index.
        move.b  blitter_line_octant_control_table(pc,d5.w),d5 ; Look up the Amiga line octant bits.
        add.w   d2,d2                          ; Initial Bresenham error term uses 2 * minor axis.
.wait_blitter:
        btst    #14,DMACONR                    ; DMACONR bit 14 is BZERO/BBUSY on OCS/ECS.
        bne.s   .wait_blitter                  ; Do not touch blitter registers while it is busy.
        movea.l #CUSTOM,a5                     ; Use A5 as the custom chip base for compact writes.
        move.w  d2,BLTBMOD-CUSTOM(a5)          ; BLTBMOD receives the first error delta.
        sub.w   d3,d2                          ; Subtract the major axis to center the error term.
        bge.s   .error_positive
        ori.b   #$40,d5                        ; Set the sign/carry control bit for a negative start error.
                                                ; Without this, lines in these octants step the wrong way.
.error_positive:
        move.w  d2,BLTBPTL-CUSTOM(a5)          ; Low word doubles as the second line error value.
        sub.w   d3,d2
        move.w  d2,BLTAMOD-CUSTOM(a5)          ; Third error value used by the line drawer.
        move.w  #$8000,BLTADAT-CUSTOM(a5)      ; Single set bit: the line starts at the top bit of A data.
        move.w  a2,BLTBDAT-CUSTOM(a5)          ; $FFFF makes B act as an all-ones mask.
        move.w  #$ffff,BLTAFWM-CUSTOM(a5)      ; No first-word clipping; every bit may be touched.
        andi.w  #$000f,d0                      ; Keep x modulo 16 for the source-word shift.
        ror.w   #4,d0                          ; Move that nibble into BLTCON0's A-shift field.
        ori.w   #$0bca,d0                      ; Line mode + minterm: draw pixels by ORing the line mask.
        move.w  d0,BLTCON0-CUSTOM(a5)          ; BLTCON0: shift, line mode, channel enables, minterm.
        move.w  d5,BLTCON1-CUSTOM(a5)          ; BLTCON1: octant bits plus the sign bit assembled above.
        move.l  d4,$48(a5)                     ; BLTCPTH: C points at the destination word.
        move.l  d4,$54(a5)                     ; BLTAPTH: A uses the same word for line generation.
        move.w  a1,BLTCMOD-CUSTOM(a5)          ; Advance C by one screen row after each blitter step.
        move.w  a1,BLTDMOD-CUSTOM(a5)          ; D follows the same 80-byte row stride.
        lsl.w   #6,d3                          ; BLTSIZE height field is stored in bits 15..6.
        addq.w  #2,d3                          ; Width is one word; line mode wants a width value of 2.
        move.w  d3,BLTSIZE-CUSTOM(a5)          ; Writing BLTSIZE starts the blit.
.done:
        rts

blitter_line_octant_control_table:
        ; Octant lookup for BLTCON1 line mode. The index is built from dy sign,
        ; dx sign, and whether the line is steep. Values are the Amiga blitter's
        ; line-direction bits, before the optional #$40 sign correction is ORed in.
        dc.b    $01,$11,$09,$15,$05,$19,$0d,$1d

blitter_clear_draw_buffer:
        movea.l draw_bitplane_buffer_ptr(pc),a1 ; Clear the off-screen drawing plane.
        lea     $640(a1),a1                     ; Skip the top area before the visible wireframe region.
        move.l  a1,BLTAPTH                      ; A pointer is the clear source/destination base.
        move.l  #$01000000,BLTCON0              ; Use a simple blitter clear/fill setup.
        clr.w   BLTDMOD                         ; Consecutive rows, no extra modulo.
.wait_blitter:
        btst    #14,DMACONR                     ; Wait until the previous blit has really finished.
        bne.s   .wait_blitter
        move.w  #$2da8,BLTSIZE                  ; Starts the clear; height/width packed as Amiga BLTSIZE.
        rts

render_wireframe_frame:
        jsr     blitter_clear_draw_buffer        ; Start each frame with an empty off-screen wire plane.
        movea.l #wireframe_vertex_table,a3      ; The same table also describes line endpoints.
.next_edge:
        cmpi.w  #$0457,$0e(a3)                  ; Sentinel means this record has a small gap/control block.
        bne.s   .normal_edge
        adda.l  #$10,a3                         ; Skip over the marker before reading the next edge.
.normal_edge:
        moveq   #0,d0                           ; Clear the line endpoint registers before loading words.
        move.l  d0,d1
        move.l  d0,d2
        move.l  d0,d3
        move.w  (a3),d0                         ; Endpoint A: screen X.
        move.w  4(a3),d1                        ; Endpoint A: screen Y.
        move.w  12(a3),d2                       ; Endpoint B: screen X from the next record.
        move.w  16(a3),d3                       ; Endpoint B: screen Y from the next record.
        jsr     blitter_draw_line               ; Let the blitter do the Bresenham work.
        adda.l  #12,a3                          ; Advance by one vertex so edges connect as a strip.
        cmpa.l  #wireframe_vertex_table_end,a3  ; Stop before the extra transform-only tail entry.
        bne.s   .next_edge

        lea     CUSTOM,a0                       ; Composite the newly drawn wireframe into the display area.
.wait_blitter:
        btst    #14,DMACONR-CUSTOM(a0)          ; The final copy also waits for all line blits to finish.
        bne.s   .wait_blitter
        move.l  front_bitplane_buffer_ptr(pc),d0 ; Source starts inside the visible front buffer.
        addi.l  #$1310,d0
        move.l  d0,BLTAPTH-CUSTOM(a0)
        move.l  draw_bitplane_buffer_ptr(pc),d0 ; Destination starts inside the newly drawn buffer.
        addi.l  #$1400,d0
        move.l  d0,BLTBPTH-CUSTOM(a0)
        clr.l   BLTAMOD-CUSTOM(a0)              ; A and B modulos are both zero for a packed copy.
        move.l  #$fffffffe,BLTAFWM-CUSTOM(a0)   ; Full first mask, last bit clipped by the low word.
        move.l  #$09f00000,BLTCON0-CUSTOM(a0)   ; Copy/combine mode used to merge the rendered frame.
        move.w  #$1768,BLTSIZE-CUSTOM(a0)       ; Packed height/width; writing it starts the composite blit.
        rts

; ---------------------------------------------------------------------------
; Data exported from the labelled Ghidra image.
; ---------------------------------------------------------------------------

        org     $000006bc

; Projection and animation state used by the wireframe renderer.
screen_center_x:
        dc.l    $000000a0
screen_center_y:
        dc.l    $00000078
projection_scale:
        dc.w    $0320
camera_depth_z:
        dc.l    $0000c350
rotation_angle_x:
        dc.w    $0000
rotation_angle_y:
        dc.w    $0000
rotation_angle_z:
        dc.w    $0000

; Quarter-wave sine table, fixed point scale 10000.
; rotate_point_by_angle_table mirrors this table through sin_table_q10000_end.
sin_table_q10000_start:
        dc.w    $0000,$00ae,$015c,$020b,$02b9,$0367,$0415,$04c2
        dc.w    $056f,$061c,$06c8,$0774,$081f,$08c9,$0973,$0a1c
        dc.w    $0ac4,$0b6b,$0c12,$0cb7,$0d5c,$0dff,$0ea2,$0f43
        dc.w    $0fe3,$1082,$111f,$11bb,$1256,$12f0,$1387,$141e
        dc.w    $14b3,$1546,$15d7,$1667,$16f5,$1782,$180c,$1895
        dc.w    $191b,$19a0,$1a23,$1aa3,$1b22,$1b9f,$1c19,$1c91
        dc.w    $1d07,$1d7b,$1dec,$1e5b,$1ec8,$1f32,$1f9a,$1fff
        dc.w    $2062,$20c2,$2120,$217b,$21d4,$222a,$227d,$22ce
        dc.w    $231b,$2367,$23af,$23f5,$2437,$2477,$24b4,$24ef
        dc.w    $2526,$255b,$258c,$25bb,$25e6,$260f,$2621,$2658
        dc.w    $2678,$2694,$26ae,$26c5,$26d9,$26e9,$26f7,$2702
        dc.w    $2709,$270e
sin_table_q10000_end:
        dc.w    $2710

; Wireframe coordinate table.
; Each normal entry is six words: screen_x/model_y/screen_y/model_x/rotated_z/model_z.
; $0457 is a sentinel/control marker used by the transform and edge walker.
wireframe_vertex_table:
wire_vertex_00:
        dc.w    $ffff,$fd76,$0000,$00fa,$0000,$0000
wire_vertex_01:
        dc.w    $ffff,$fd76,$ffff,$ff6a,$0000,$0000
wire_vertex_02:
        dc.w    $ffff,$fdb2,$ffff,$ff6a,$0000,$0000
wire_vertex_03:
        dc.w    $ffff,$fdb2,$0000,$0014,$0000,$0000
wire_vertex_04:
        dc.w    $ffff,$fdc6,$ffff,$ff6a,$0000,$0000
wire_vertex_05:
        dc.w    $ffff,$fde4,$ffff,$ff6a,$0000,$0000
wire_vertex_06:
        dc.w    $ffff,$fdf8,$0000,$0014,$0000,$0000
wire_vertex_07:
        dc.w    $ffff,$fe07,$ffff,$ff6a,$0000,$0000
wire_vertex_08:
        dc.w    $ffff,$fe2a,$ffff,$ff6a,$0000,$0000
wire_vertex_09:
        dc.w    $ffff,$fe2a,$0000,$00fa,$0000,$0000
wire_vertex_10:
        dc.w    $ffff,$fdd0,$0000,$00fa,$0000,$0000
wire_vertex_11:
        dc.w    $ffff,$fdd0,$0000,$00c8,$0000,$0000
wire_vertex_12:
        dc.w    $0000,$0457,$ffff,$fdd0,$0000,$00fa
wire_vertex_13:
        dc.w    $0000,$0000,$ffff,$fd76,$0000,$00fa
wire_vertex_14:
        dc.w    $0000,$0000,$0000,$0457,$ffff,$fe70
wire_vertex_15:
        dc.w    $0000,$00fa,$0000,$0000,$ffff,$fe3e
wire_vertex_16:
        dc.w    $0000,$00fa,$0000,$0000,$ffff,$fe3e
wire_vertex_17:
        dc.w    $0000,$0064,$0000,$0000,$ffff,$fe84
wire_vertex_18:
        dc.w    $ffff,$ffec,$0000,$0000,$ffff,$fe84
wire_vertex_19:
        dc.w    $ffff,$ff6a,$0000,$0000,$ffff,$fed4
wire_vertex_20:
        dc.w    $ffff,$ff6a,$0000,$0000,$ffff,$fed4
wire_vertex_21:
        dc.w    $ffff,$ffec,$0000,$0000,$ffff,$ff1a
wire_vertex_22:
        dc.w    $0000,$0064,$0000,$0000,$ffff,$ff1a
wire_vertex_23:
        dc.w    $0000,$00fa,$0000,$0000,$ffff,$fee8
wire_vertex_24:
        dc.w    $0000,$00fa,$0000,$0000,$ffff,$fed4
wire_vertex_25:
        dc.w    $0000,$0064,$0000,$0000,$ffff,$fe84
wire_vertex_26:
        dc.w    $0000,$0064,$0000,$0000,$ffff,$fe70
wire_vertex_27:
        dc.w    $0000,$00fa,$0000,$0000,$0000,$0457
wire_vertex_28:
        dc.w    $ffff,$ff6a,$0000,$00fa,$0000,$0000
wire_vertex_29:
        dc.w    $0000,$0000,$0000,$00fa,$0000,$0000
wire_vertex_30:
        dc.w    $0000,$0457,$ffff,$ff9c,$0000,$0096
wire_vertex_31:
        dc.w    $0000,$0000,$ffff,$ff9c,$0000,$0064
wire_vertex_32:
        dc.w    $0000,$0000,$0000,$0032,$0000,$0064
wire_vertex_33:
        dc.w    $0000,$0000,$0000,$0064,$0000,$0032
wire_vertex_34:
        dc.w    $0000,$0000,$0000,$0064,$ffff,$ff9c
wire_vertex_35:
        dc.w    $0000,$0000,$0000,$0032,$ffff,$ff6a
wire_vertex_36:
        dc.w    $0000,$0000,$0000,$0000,$ffff,$ff6a
wire_vertex_37:
        dc.w    $0000,$0000,$ffff,$ff38,$ffff,$ffce
wire_vertex_38:
        dc.w    $0000,$0000,$0000,$0000,$ffff,$ffce
wire_vertex_39:
        dc.w    $0000,$0000,$0000,$0000,$0000,$0000
wire_vertex_40:
        dc.w    $0000,$0000,$ffff,$ff6a,$0000,$0000
wire_vertex_41:
        dc.w    $0000,$0000,$ffff,$ff38,$0000,$0000
wire_vertex_42:
        dc.w    $0000,$0000,$ffff,$ff38,$0000,$00c8
wire_vertex_43:
        dc.w    $0000,$0000,$ffff,$ff6a,$0000,$00fa
wire_vertex_44:
        dc.w    $0000,$0000,$0000,$0457,$ffff,$ff9c
wire_vertex_45:
        dc.w    $0000,$0096,$0000,$0000,$0000,$00c8
wire_vertex_46:
        dc.w    $0000,$0096,$0000,$0000,$0000,$00c8
wire_vertex_47:
        dc.w    $ffff,$ff6a,$0000,$0000,$0000,$00fa
wire_vertex_48:
        dc.w    $ffff,$ff6a,$0000,$0000,$0000,$00fa
wire_vertex_49:
        dc.w    $0000,$0096,$0000,$0000,$0000,$01ae
wire_vertex_50:
        dc.w    $0000,$0096,$0000,$0000,$0000,$01ae
wire_vertex_51:
        dc.w    $0000,$00fa,$0000,$0000,$ffff,$ffce
wire_vertex_52:
        dc.w    $0000,$00fa,$0000,$0000,$0000,$0457
wire_vertex_53:
        dc.w    $0000,$012c,$ffff,$ff6a,$0000,$0000
wire_vertex_54:
        dc.w    $0000,$012c,$0000,$0064,$0000,$0000
wire_vertex_55:
        dc.w    $0000,$017c,$0000,$0064,$0000,$0000
wire_vertex_56:
        dc.w    $0000,$017c,$ffff,$ff6a,$0000,$0000
wire_vertex_57:
        dc.w    $0000,$012c,$ffff,$ff6a,$0000,$0000
wire_vertex_58:
        dc.w    $0000,$0457,$0000,$01f4,$0000,$00fa
wire_vertex_59:
        dc.w    $0000,$0000,$0000,$01c2,$0000,$00c8
wire_vertex_60:
        dc.w    $0000,$0000,$0000,$01c2,$ffff,$ff9c
wire_vertex_61:
        dc.w    $0000,$0000,$0000,$01f4,$ffff,$ff6a
wire_vertex_62:
        dc.w    $0000,$0000,$0000,$02bc,$ffff,$ff6a
wire_vertex_63:
        dc.w    $0000,$0000,$0000,$02bc,$0000,$0064
wire_vertex_64:
        dc.w    $0000,$0000,$0000,$0457,$0000,$01f4
wire_vertex_65:
        dc.w    $0000,$00fa,$0000,$0000,$0000,$02bc
wire_vertex_66:
        dc.w    $0000,$00fa,$0000,$0000,$0000,$02bc
wireframe_partial_edge_words:
        dc.w    $0000,$0064,$0000,$0000
wireframe_vertex_table_end:
; Extra point consumed by update_rotating_object_vertices but not by render_wireframe_frame.
wireframe_transform_tail:
        dc.w    $0000,$0226,$0000,$0064,$0000,$0000

; Rotation script read by intro_entry_mainloop.
; Record format: frame_count, delta_angle_x, delta_angle_y, delta_angle_z, delta_camera_depth.
rotation_delta_table:
rotation_script_00:
        dc.w    $000a,$0000,$0024,$0000,$0050
rotation_script_01:
        dc.w    $0014,$0000,$0012,$0000,$0050
rotation_script_02:
        dc.w    $0028,$0000,$0009,$0000,$0050
rotation_script_03:
        dc.w    $002d,$0004,$0004,$0000,$008c
rotation_script_04:
        dc.w    $0014,$0000,$0000,$0000,$0000
rotation_script_05:
        dc.w    $005a,$0008,$0000,$0000,$fe7a
rotation_script_06:
        dc.w    $002d,$0008,$0000,$0000,$0186
rotation_script_07:
        dc.w    $005a,$0000,$0004,$0004,$0000
rotation_script_08:
        dc.w    $002d,$0008,$0000,$0000,$0186
rotation_script_09:
        dc.w    $002d,$0008,$0000,$0000,$ffec
rotation_script_10:
        dc.w    $00b4,$0004,$0004,$0004,$0000
rotation_script_11:
        dc.w    $002d,$0008,$0000,$0000,$0014
rotation_script_12:
        dc.w    $002d,$0008,$0000,$0000,$fe7a
rotation_script_13:
        dc.w    $005a,$0000,$0004,$0004,$0000
rotation_script_14:
        dc.w    $002d,$0008,$0000,$0000,$fe7a
rotation_script_15:
        dc.w    $005a,$0008,$0000,$0000,$0186
rotation_script_16:
        dc.w    $0014,$0000,$0000,$0000,$0000
rotation_script_17:
        dc.w    $002d,$0004,$0004,$0000,$ff74
rotation_script_18:
        dc.w    $0028,$0000,$0009,$0000,$ffb0
rotation_script_19:
        dc.w    $0014,$0000,$0012,$0000,$ffb0
rotation_script_20:
        dc.w    $000a,$0000,$0024,$0000,$ffb0

        org     $00000b90

text_0b90_103a:
graphics_library_name:
        db      "graphics.library"
        db      $00
topaz_font_name:
        db      "topaz.font"
        db      $00
trainer_menu_text_stream:
        db      "          _______     __/|__    _______________________.  /\______  "
        db      $0a
        db      "         _\  ..  \   /   !  \  _\  ________.   .___.   | /   .___/  "
        db      $0a
        db      "         \_  ||   \ /____.   \_\_____  \___|   |___|   |/    |__Z___"
        db      $0a
        db      "         /   ||  -\Y     !  -\\     V -\\  | -!|axe| -!|\    !   -//"
        db      $0a
        db      "         \____!!_  _/\______  _/\_____  _/\|___|   |___| \____   _/ "
        db      $0a
        db      "          \__\_\_/\\/\____\_/\\/\___\_/\\/ !___!   !___!\/___/\_//  "
        db      $0a
        db      "                   \\/        \\/       \\/   tRaiNed 4 U     \//"
        db      $0a,$0c
        db      "            >>> Dune II <<< 7+ "
        db      $0b,$0c
        db      "[F1]  Unlimited lives ......................"
option_unlimited_lives_onoff_text:
        db      " ON  "
        db      $0b,$0c
        db      "[F2]  Unlimited energy ....................."
option_unlimited_energy_onoff_text:
        db      " ON  "
        db      $0b,$0c
        db      "[F3]  Unlimited weaponry ..................."
option_unlimited_weaponry_onoff_text:
        db      " ON  "
        db      $0b,$0c
        db      "[F4]  No collision ........................."
option_no_collision_onoff_text:
        db      " ON  "
        db      $0b,$0c
        db      "[F5]  No enemies ..........................."
option_in_game_keys_onoff_text:
        db      " ON  "
        db      $0b,$0c
        db      "[F6]  High jump ............................"
option_start_level_onoff_text:
        db      " ON  "
        db      $0b,$0c
        db      "[F7]  Ingame keys .........................."
option_unknown_option_7_onoff_text:
        db      " ON  "
        db      $0b
trainer_instructions_and_credits_text:
        db      "^*^ Instructions ^*^  <=>  ^*^ Credits ^*^"
        db      $0a,$0a
        db      "    [FKeys] Toggle Options On/Off             CODiNG: ColORbOy <=> MyStiC"
        db      $0a
        db      "    [Space] Toggles All Options On/Off          AnSi: aXe      <=> MyStiC"
        db      $0a
        db      "      [Esc] Exits Trainer Menu                 tRaiN: iD       <=> MyStiC"
        db      $00
copper_display_setup_start:
        db      $00,$8e
        db      "08"
        db      $00,$90,$f8,$c1,$00,$92,$00
        db      "<"
        db      $00,$94,$00,$d4,$01,$00,$a2,$00,$01,$08,$00,$00,$01,$0a,$00,$00
        db      $00,$e0

        org     $0000103a

; The first four pointer data words are patched by the intro before the
; copper list is installed. The list then drives a one-bitplane intro screen
; plus a second text bitplane and a simple raster colour sweep.
copper_103a_11f0:
copper_bpl1pth_word:
        dc.w    $0000,$00e2             ; First patched bitplane pointer word in the original list layout.
copper_bpl1ptl_word:
        dc.w    $0000,$00e4             ; Low half of the front bitplane pointer is patched here.
copper_bpl2pth_word:
        dc.w    $0000,$00e6             ; High half of the rendered text bitplane pointer is patched here.
copper_bpl2ptl_word:
        dc.w    $0000,$0180             ; Low half of the text pointer; the next word resumes colour setup.
        dc.w    $0000,$0182             ; COLOR00/COLOR01 start black before the raster colour sweep.
copper_color_cycle_dest_slots:
        dc.w    $0a5f,$0184             ; First visible COLOR02 value before the timed sweep starts.
        dc.w    $0fff,$300f,$fffe,$0184 ; Wait near line $30, then prepare the next COLOR02 write.
copper_color_cycle_dest_slot_01:
        dc.w    $0f01,$340f,$fffe,$0184 ; This value is animated by the VBlank colour rotator.
copper_color_cycle_dest_slot_02:
        dc.w    $0e01,$380f,$fffe,$0184 ; Same pattern: colour word, wait, mask, next COLOR02 move.
        dc.w    $0d02,$3c0f,$fffe,$0184 ; The wait positions create the vertical colour bands.
        dc.w    $0c03,$400f,$fffe,$0184
        dc.w    $0b04,$440f,$fffe,$0184
        dc.w    $0a15,$480f,$fffe,$0184
        dc.w    $0926,$4c0f,$fffe,$0184
        dc.w    $0837,$500f,$fffe,$0184
        dc.w    $0748,$540f,$fffe,$0184
        dc.w    $0659,$580f,$fffe,$0184
        dc.w    $056a,$5c0f,$fffe,$0184
        dc.w    $047b,$600f,$fffe,$0184
        dc.w    $038c,$640f,$fffe,$0184
        dc.w    $029d,$680f,$fffe,$0184
        dc.w    $0099,$690f,$fffe,$0184
        dc.w    $00bb,$6a0f,$fffe,$0184
        dc.w    $00ee,$6a0f,$fffe,$0180 ; Switch to COLOR00 for a small background accent.
        dc.w    $0005,$6b0f,$fffe,$0184 ; Back to COLOR02 for the next coloured text band.
        dc.w    $00ff,$6b0f,$fffe,$0180
        dc.w    $0009,$6c0f,$fffe,$0184
        dc.w    $00dd,$6c0f,$fffe,$0180
        dc.w    $0005,$6d0f,$fffe,$0184
        dc.w    $00bb,$6d0f,$fffe,$0180
        dc.w    $0002,$6f0f,$fffe,$0184
        dc.w    $0aaa,$700f,$fffe,$0184
        dc.w    $0fff,$7b0f,$fffe,$0184
        dc.w    $00f0,$880f,$fffe,$0184
        dc.w    $0fff,$940f,$fffe,$0184
        dc.w    $00f0,$a00f,$fffe,$0184
        dc.w    $0fff,$ab0f,$fffe,$0184
        dc.w    $00f0,$b80f,$fffe,$0184
        dc.w    $0fff,$c80f,$fffe,$0184
        dc.w    $0099,$c90f,$fffe,$0184
        dc.w    $00bb,$ca0f,$fffe,$0184
        dc.w    $00ee,$ca0f,$fffe,$0180
        dc.w    $0005,$cb0f,$fffe,$0180
        dc.w    $0009,$cb0f,$fffe,$0184
        dc.w    $00ff,$cc0f,$fffe,$0180
        dc.w    $0005,$cc0f,$fffe,$0184
        dc.w    $00dd,$cd0f,$fffe,$0180
        dc.w    $0000,$cd0f,$fffe,$0184
        dc.w    $00bb,$cd0f,$fffe,$0180
        dc.w    $0003,$d60f,$fffe,$0184
        dc.w    $00f0,$e00f,$fffe,$0184
        dc.w    $0fff,$e80f,$fffe,$0184
        dc.w    $00f0,$f00f,$fffe,$0184
        dc.w    $0fff,$fc0f,$fffe,$0180
        dc.w    $0005,$fd0f,$fffe,$0180
        dc.w    $0009,$fe0f,$fffe,$0180
        dc.w    $0005,$ff0f,$fffe,$0180
        dc.w    $0000,$ffff,$fffe        ; Final wait terminates the list for the frame.

        org     $000011f0

text_render_bitplane_buffer     equ     $000012a4

; Runtime pointers filled or patched by the intro.
gfxbase_ptr:
        dc.l    0
textfont_handle_ptr:
        dc.l    0
font_bitmap_ptr:
        dc.l    0
front_bitplane_buffer_ptr:
        dc.l    front_bitplane_buffer
draw_bitplane_buffer_ptr:
        dc.l    draw_bitplane_buffer

; Timer and trainer option state.
runtime_unused_word_1204:
        dc.w    0
runtime_unused_word_1206:
        dc.w    0
vblank_text_anim_countdown:
        dc.w    0
option_unlimited_lives_enabled_flag:
        dc.w    1
option_unlimited_energy_enabled_flag:
        dc.w    1
option_unlimited_weaponry_enabled_flag:
        dc.w    1
option_no_collision_enabled_flag:
        dc.w    1
option_in_game_keys_enabled_flag:
        dc.w    1
option_start_level_enabled_flag:
        dc.w    1
option_unknown_option_7_enabled_flag:
        dc.w    1
trainer_all_options_toggle_state:
        dc.w    1
runtime_initial_text_column_state:
        dc.w    $0050

; graphics.library TextAttr-like block for topaz.font.
topaz_textattr_name_ptr:
        dc.l    0                       ; Patched with topaz_font_name before the graphics call.
topaz_textattr_ysize:
        dc.w    8
topaz_textattr_style:
        dc.b    0
topaz_textattr_flags:
        dc.b    0
topaz_textattr_extra_metric:
        dc.w    8                       ; Extra font/text metric word kept from the original image.

copper_pointer_template_words:
        ; Five 8-byte template chunks copied into runtime_copper_pointer_patch_area.
        dc.l    $7cf303c7,$8f0f6600
        dc.l    $c19b066c,$d8d9bc00
        dc.l    $c19b066f,$df199800
        dc.l    $c19b066f,$18d99800
        dc.l    $7cf1f3c4,$cf0f1800

vblank_color_cycle_source_words:
        ; Source words rotated by the level-3/VBlank text effect.
        ; The IRQ bubbles this list along and copies selected words into the
        ; copper colour slots, so the whole gradient has to live in the image.
        dc.w    $0f01,$0e01,$0d02,$0c03,$0b04,$0a15,$0926,$0837
        dc.w    $0748,$0659,$056a,$047b,$038c,$029d,$03ac,$04bb
        dc.w    $05ca,$06d9,$08e8,$09f7,$0af6,$0bf5,$0cf4,$0df3
        dc.w    $0ef2,$0ff1,$0ff0,$0fe0,$0fd0,$0fe0,$0fd0,$0fb0
        dc.w    $0fa0,$0f90,$0f80,$0f70,$0f60,$0f50,$0f40,$0f30
        dc.w    $0f20,$0f10,$0f00

        org     $000042bc
runtime_copper_pointer_patch_area:
        ds.b    $50
runtime_copper_pointer_patch_next_slot:
        ds.b    $50

        org     $00005124
front_bitplane_buffer:
        ds.b    $7d00

        org     $0000ce24
draw_bitplane_buffer:
        ds.b    $3e83
draw_buffer_tail_patch_bytes:
        ; The decrunched file keeps this small odd-aligned tail after the
        ; visible draw buffer area. Nothing in the intro references it, but it
        ; is part of the byte-exact payload image.
        dc.b    $30,$00,$00,$00,$1f,$00,$0b,$00,$11,$00,$0a,$00,$0a,$00,$05,$00
        dc.b    $05,$00,$06,$00,$04,$00,$05,$00,$04,$00,$05,$00,$04,$00,$05,$00
        dc.b    $37,$00,$05,$00,$03,$00,$03,$00,$05,$00,$0e,$00,$08,$00,$14,$00
        dc.b    $05,$00,$31,$00,$05,$00,$05,$00,$da,$00,$0e,$00,$03,$00,$0b,$00
        dc.b    $03,$00,$09,$00,$03,$00,$0b,$00,$09,$00,$09,$00,$03,$00,$3f,$00
        dc.b    $03,$00,$05,$00,$05,$00,$03,$00,$7b,$00,$03,$00,$15,$00,$06,$05
        dc.b    $c6,$00,$02,$00,$00,$ff,$ff

        end     intro_entry_mainloop
