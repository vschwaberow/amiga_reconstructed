; ---------------------------------------------------------------------------
; The Champs intro for Sidewinder
; ---------------------------------------------------------------------------
;
; Reconstructed by Volker Schwaberow <volker@schwaberow.de>
;
; Build:
;   vasmm68k_mot -m68000 -no-opt -Fbin -o thechamps_sidewinder_intro.bin thechamps_sidewinder_intro.s
;
; ---------------------------------------------------------------------------

        org     $00030000

; ---------------------------------------------------------------------------
; Hardware / OS constants
; ---------------------------------------------------------------------------

CUSTOM                  equ     $00dff000
DMACON                  equ     $00dff096
INTENA                  equ     $00dff09a
INTREQR                 equ     $00dff01e
COLOR00                 equ     $00dff180
CIAA_PRA_JOY_MOUSE      equ     $00bfe001
EXEC_BASE_PTR           equ     $00000004
LEVEL3_INTERRUPT_VECTOR equ     $0000006c
_LVOForbid              equ     -132
_LVOEnable              equ     -138
_LVOOpenLibrary         equ     -408

; ---------------------------------------------------------------------------
; Sound engine resident entry points at $70000
; ---------------------------------------------------------------------------
sound_engine_init       equ     $7e000
sound_engine_stop       equ     $7e04a
KICKSTART_LEVEL6_EXIT   equ     $fc0e04

; ---------------------------------------------------------------------------
; Display buffer memory layouts in Chip RAM
; ---------------------------------------------------------------------------
SCREEN_PLANE_1          equ     $00056c34
SCREEN_PLANE_2          equ     $00058804
SCREEN_PLANE_3          equ     $0005a3d4
SCREEN_PLANE_4          equ     $0005bfa4
SCREEN_LOGO_OFFSET      equ     400             ; 10 lines vertical padding
SCROLLER_WORK_BUFFER    equ     $0005db74
RUNTIME_SPRITES_BUFFER  equ     $0006a000       ; 4 linked sprites of 17 lines in Chip RAM

; ---------------------------------------------------------------------------
; Moving object strip memory layout in Chip RAM (Sprites 4, 5, 6)
; ---------------------------------------------------------------------------
RUNTIME_STRIP_1         equ     $0004a000
RUNTIME_STRIP_2         equ     $0004a310
RUNTIME_STRIP_3         equ     $0004a610
RUNTIME_STRIP_1_SIZE    equ     $310            ; Spacing between Strip 1 and 2
RUNTIME_STRIP_2_SIZE    equ     $300            ; Spacing between Strip 2 and 3
RUNTIME_STRIP_3_SIZE    equ     $300            ; Size of Strip 3 buffer

the_champs_intro_entry:
        movem.l    d0-d7/a0-a6,-(a7)               ; Save the caller state; the intro borrows the machine quite directly.
        move.w     #$8100,DMACON                   ; Stop the DMA channels before touching copper and bitplane pointers.
        lea.l      scroller_text_start,a4                     ; Start the scroll text at the first byte after the charset.
        move.l     a4,scroller_text_ptr                     ; Keep the live scroll pointer where the interrupt can update it.
        move.l     #$f,scroller_delay_counter                    ; Use a small delay counter so the scroll does not advance every frame.
        jsr        copy_resident_payload_to_fastmem                         ; Copy the resident side payload up to $70000.
        jsr        open_graphics_and_prepare_screens                         ; Open graphics.library and prepare the display buffers.
        jsr        copy_logo_bitplanes_to_display_memory                         ; Copy the four logo planes into their screen buffers.
        bsr.w      copy_copper_template_to_chipmem                           ; Copy the prepared copper template into its runtime area.
        jsr        install_vblank_and_system_copper_hook                         ; Install the level-3 IRQ and patch the system copper pointer slot.
        jsr        sound_engine_init.l              ; Jump into the resident payload that was just copied to $70000.
        jsr        build_sprite_control_blocks                         ; Build the multiplexed sprite control blocks for the parallax starfield.
        jsr        build_runtime_copper_gradients                         ; Generate the copper colour gradients used by the bars.

wait_for_left_mouse:
        andi.b     #$40,CIAA_PRA_JOY_MOUSE         ; Poll the left mouse button; released means stay in the intro.
        beq.w      exit_intro                           ; Button is down, so leave the intro cleanly.
        jmp        wait_for_left_mouse                         ; Loop here while the user keeps watching the intro.

exit_intro:
        jsr        sound_engine_stop.l              ; Let the resident payload do its own shutdown work first.
        move.w     #$4000,INTENA                   ; Disable interrupts while the old VBlank vector is restored.
        move.l     old_level3_vector,LEVEL3_INTERRUPT_VECTOR ; Restore the level-3 vector saved by the interrupt installer.
        move.w     #$c000,INTENA                   ; Bring interrupt master back once the vector is sane again.
        movea.l    gfxbase_ptr,a0                     ; GfxBase is needed to reach graphics.library runtime data.
        adda.l     #$32,a0                         ; Step to the system copper pointer slot in the library base.
        move.w     #$8f,DMACON                     ; Disable copper DMA for the pointer swap.
        move.l     saved_system_copper_long,(a0)                   ; Put the system copper pointer back where graphics.library expects it.
        move.w     #$8180,DMACON                   ; Re-enable the display DMA mix used by the system.
        movea.l    EXEC_BASE_PTR,a6                ; ExecBase lives at address 4 on every Amiga.
        jsr        -$8a(a6)                         ; Allow task switching again before returning.
        clr.l      d0                               ; Return code is zero; the original does not report a special status.
        movem.l    (a7)+,d0-d7/a0-a6               ; Restore the registers saved at entry.
        rts                                        ; Back to the caller/game loader.

copy_resident_payload_to_fastmem:
        lea.l      $37cd2.l,a0                     ; Source is the payload stored at the end of this file.
        lea.l      $47cd1.l,a1                     ; Stop byte copy just past the payload image (copies 65,535 bytes).
        movea.l    #$70000,a2                      ; Destination is the resident copy at $70000.
.copy_loop:
        move.b     (a0)+,(a2)+                     ; Copy one byte of the resident payload.
        cmpa.l     a1,a0                           ; Check whether the source pointer reached the payload end.
        bne.w      .copy_loop                           ; Keep copying until the whole resident block is in place.
        rts                                        ; Payload copy is finished.

level3_vblank_irq:
        movem.l    d0-d7/a0-a6,-(a7)               ; Interrupts must leave all registers as they found them.
        move.w     sr,-(a7)                        ; Keep the old status register while the IRQ work runs.
        move.w     INTREQR,d0                       ; Read INTREQR so we know what actually interrupted us.
        btst       #$5,d0                          ; Bit 5 is VBlank on the custom chip interrupt request word.
        bne.b      .vblank_work                     ; Only run the animation work on a VBlank tick.
        bra.w      .restore_irq                     ; Not our interrupt, fall through to the old handler path.
.vblank_work:
        bsr.w      advance_scroller_glyph           ; Roll the scroll text by one glyph step.
        bsr.w      rotate_colour_table_and_patch_copper ; Rotate the copper colour table and patch the list.
        bsr.w      update_sprite_positions          ; Refresh the moving sprite positions.
        bsr.w      animate_three_object_strips      ; Animate the three little object strips.
.restore_irq:
        move.w     (a7)+,sr                        ; Restore SR before leaving the interrupt path.
        movem.l    (a7)+,d0-d7/a0-a6               ; Put the saved registers back exactly as the IRQ found them.
        dc.w       $4ef9
old_level3_vector:
        dc.l       0                                ; This longword is patched with the old level-3 vector at runtime.

rotate_colour_table_and_patch_copper:
        lea.l      copper_colour_rotation_table(pc),a0                   ; A0/A1 walk the colour table one word apart for the rotate.
        lea.l      copper_colour_rotation_table+2(pc),a1                   ; A1 is the next colour word, so the table can slide left.
        move.w     copper_colour_rotation_table,d1                     ; Keep the first colour word so it can wrap to the end.
        move.w     #$7a,d0                         ; Copy 123 words; DBRA counts from $7a down to -1.

copy_next_colour_word:
        move.w     (a1)+,(a0)+                     ; Move the next colour word over the previous one.
        dbra       d0,copy_next_colour_word                       ; Keep rotating until the table window is shifted.
        move.w     d1,copper_colour_rotation_table+244                     ; Wrap the saved first word onto the end of the colour table.
        move.l     #$14,d0                         ; Patch 21 copper colour slots from the rotated table.
        lea.l      copper_colour_rotation_table,a0                     ; Read from the colour rotation table.
        lea.l      middle_copper_colour_bar+6,a1                     ; Write into the copper list colour-word positions.

patch_copper_colour_word:
        move.w     (a0)+,(a1)                      ; Patch one colour word in the copper list.
        adda.l     #$8,a1                          ; Next colour slot is eight bytes later: WAIT, mask, register, value.
        dbra       d0,patch_copper_colour_word                       ; Patch all colour slots used by the middle bar.
        rts                                        ; Colour copper list is fresh for this frame.

animate_three_object_strips:
        movea.l    #RUNTIME_STRIP_2,a2             ; First strip uses the sprite/control memory at RUNTIME_STRIP_2.
        move.l     #$5,d7                          ; Six passes give this strip its little falling motion.
        move.l     #$0,d5                          ; First strip starts at the base of the work area.
        bsr.w      animate_object_strip                           ; Animate that strip with no extra base offset.
        movea.l    #RUNTIME_STRIP_3,a2             ; Second strip starts a bit further into the same work area.
        move.l     #$5,d7                          ; Same pass count for the second strip.
        move.l     #RUNTIME_STRIP_1_SIZE,d5        ; Offset into the second strip's generated records.
        bsr.w      animate_object_strip                           ; Use the second strip offset.
        movea.l    #RUNTIME_STRIP_3+RUNTIME_STRIP_3_SIZE,a2 ; Third strip gets its own offset as well.
        move.l     #$5,d7                          ; Same pass count for the third strip.
        move.l     #RUNTIME_STRIP_1_SIZE+RUNTIME_STRIP_2_SIZE,d5 ; Offset into the third strip's generated records.
        bsr.w      animate_object_strip                           ; Use the third strip offset.
        rts                                        ; All three strips have been advanced.

animate_object_strip:
        move.l     d7,d0                           ; Convert the loop index into an eight-byte control-block stride.
        asl.l      #$3,d0                          ; Each sprite/control entry is eight bytes wide here.
        move.l     d7,d6                           ; Keep a second counter for the nested sweep.
        subq.w     #$1,d6                          ; DBRA wants the loop count pre-decremented.

object_strip_column_loop:
.column_loop:
        move.l     d0,-(a7)                        ; Save the current stride while this column is walked.
        lea.l      RUNTIME_STRIP_1.l,a1            ; Base of the starfield sprite work memory.
        adda.l     d5,a1                           ; Pick the current strip inside that work memory.
        adda.w     d0,a1                           ; Step to the current column entry.
        suba.w     #$8,a1                          ; Back up to the byte that gets animated.
.row_loop:
        addi.b     #$1,$1(a1)                      ; Bump one control byte; this is the tiny per-frame motion.
        adda.w     #$28,a1                         ; Next row in this object strip is 40 bytes further on.
        move.w     #$2,d2                          ; Short delay loop; the original burns a few cycles here.
.delay:
        dbra       d2,.delay                       ; Spin the delay counter down.
        cmpa.l     a2,a1                           ; Stop once this strip reached its end address.
        bcs.w      .row_loop                       ; Still below the strip end, so keep walking rows.
        move.l     (a7)+,d0                        ; Restore the stride for the next column pass.
        dbra       d6,.column_loop                 ; Walk the remaining columns for this pass.                       ; Walk the remaining columns for this pass.
        subq.w     #$1,d7                          ; Count down the outer strip pass.
        bne.w      animate_object_strip                           ; Run another pass until the strip animation is done.
        rts                                        ; Object strip animation is finished for this frame.

advance_scroller_glyph:
        clr.l      d0                               ; D0 becomes the row counter for the 7-pixel-high glyph.
        move.b     #$6,d0                          ; The scroll font has seven rows per character.
        lea.l      scroller_shift_buffer,a1                     ; A1 points at the 16-word shift buffer used by the scroller.
        lea.l      $5dbfe.l,a0                     ; A0 starts at the right edge of the scroll bitplane memory.

scroll_one_glyph_row:
        movea.l    a0,a2                           ; A2 walks backwards through one glyph row.
        roxl.w     (a1)+                            ; Roll the carry through the shift buffer word.
        move.w     sr,d6                           ; Save the carry state so the bitplane slices can use it.
        move.l     #$2,d2                          ; Three bitplane slices are shifted for each glyph row.

scroll_one_bitplane_slice:
        move.l     #$16,d1                         ; There are 22 words in one scroller row slice.
        move.w     d6,ccr                          ; Restore the carry before shifting the row bits.
.shift_loop:
        roxl.w     -(a2)                            ; Shift one word of the scroller row through the carry.
        dbra       d1,.shift_loop                  ; Keep shifting this row slice.
        adda.w     #$2e,a0                         ; Jump to the next row inside the scroll work area.
        movea.l    a0,a2                           ; Restart the backwards walk for that row.
        dbra       d2,scroll_one_bitplane_slice                       ; Do the three slices that make up the scroll strip.
        dbra       d0,scroll_one_glyph_row                       ; Do all seven glyph rows.
        lea.l      scroller_delay_counter,a5                     ; A5 points at the scroller timing/pointer variables.
        move.l     (a5),d7                         ; Fetch the current delay counter.
        dbmi       d7,store_scroller_delay                       ; DBMI is the original little timing trick for the scroll speed.
        movea.l    scroller_text_ptr,a6                     ; A6 is the current text pointer in the scroller message.
        clr.l      d7                               ; Clear D7 before reading the next text byte.
        move.b     (a6)+,d7                        ; Read the next character from the scroll text.
        bne.w      have_scroller_byte                           ; A non-zero byte is a normal character.
        lea.l      scroller_text_start,a6                     ; Zero wraps the scroller back to the start of the message.
        move.b     (a6)+,d7                        ; Fetch the first byte after wrapping.

have_scroller_byte:
        clr.l      d0                               ; D0 is the charset index while we search.
        lea.l      scroller_charset,a0                     ; The charset is a compact table before the scroll message.

find_scroller_charset_index:
        cmp.b      (a0)+,d7                        ; Compare the current scroll byte with this charset entry.
        beq.w      charset_match_found                           ; Matched, so the glyph index is known.
        addi.b     #$1,d0                          ; Try the next charset slot.
        cmpi.b     #$14,d0                         ; The table has 20 entries before the fallback path.
        bne.w      find_scroller_charset_index                           ; Keep looking through the charset.
        bra.w      prepare_glyph_source                           ; Unknown character uses the fallback calculation below.

charset_match_found:
        addi.b     #$7b,d0                         ; Offset the charset index into the font block.
        move.l     d0,d7                           ; D7 now holds the glyph selector.

prepare_glyph_source:
        subi.b     #$61,d7                         ; Turn the ASCII-ish byte into the font-table row offset.
        asl.w      #$4,d7                          ; Each glyph is 16 bytes in this small scroll font.
        lea.l      scroller_shift_buffer,a5                     ; A5 receives the glyph words used by the shifter.
        lea.l      champs_scroll_font,a0                     ; A0 is the start of the scroll font bitmap table.
        add.l      a0,d7                           ; Add the glyph offset to the font base.
        movea.l    d7,a4                           ; A4 points at the selected glyph bitmap.
        move.l     #$7,d1                          ; Copy eight words for the glyph shift buffer.

copy_glyph_words_to_shift_buffer:
        move.w     (a4)+,(a5)+                     ; Copy one font word into the runtime shift buffer.
        dbra       d1,copy_glyph_words_to_shift_buffer                       ; Finish all words for this glyph.
        move.l     a6,scroller_text_ptr                     ; Save the advanced text pointer for the next scroll step.
        move.l     #$f,d7                          ; Reset the scroll delay counter.

store_scroller_delay:
        move.l     d7,scroller_delay_counter                     ; Store the delay counter back for the IRQ path.
        rts                                        ; Scroller update is done.

copy_copper_template_to_chipmem:
        lea.l      RUNTIME_SPRITES_BUFFER,a1       ; Destination is the runtime sprite buffer area in Chip RAM.
        lea.l      sprite_template_source.l,a0     ; Source is the static hardware sprite template.
        move.l     #$254,d0                        ; Copy $255 bytes; the DBRA count is one less than the byte count.

copy_copper_template_byte:
        move.b     (a0)+,(a1)+                     ; Copy one copper-template byte.
        dbra       d0,copy_copper_template_byte                       ; Keep going until the template has moved to chip memory.
        move.w     #$0,sprite_sine_counters+6                    ; Reset the fourth sprite sine counter.
        move.w     #$15,sprite_sine_counters+4                   ; Seed the third sprite sine counter.
        move.w     #$e,sprite_sine_counters+2                    ; Seed the second sprite sine counter.
        move.w     #$7,sprite_sine_counters                    ; Seed the first sprite sine counter.
        rts                                        ; Copper template and sprite counters are ready.

update_sprite_positions:
        clr.l      d2                               ; D2 selects which sprite position pair is being updated.
        lea.l      sprite_position_words,a0                     ; A0 points at the calculated sprite position words.
        lea.l      RUNTIME_SPRITES_BUFFER,a1       ; A1 points at the runtime sprite data buffer in Chip RAM.

update_one_sprite_pair:
        clr.l      d0                               ; Clear D0 before loading the X position word.
        move.w     (a0,d2.w),d0                   ; Read the current X position for this sprite.
        lsr.w      #$1,d0                          ; Low X bit is stored in the sprite control byte, so shift it out.
        bcs.b      sprite_x_low_bit_set                           ; Carry clear means that low X bit is zero.
        bclr.b     #$0,$3(a1)                      ; Clear the sprite low-X bit.
        bra.b      store_sprite_position                           ; Join the common store path.

sprite_x_low_bit_set:
        bset.b     #$0,$3(a1)                      ; Set the sprite low-X bit.

store_sprite_position:
        move.b     d0,$1(a1)                       ; Store the high X bits into the sprite control block.
        move.b     d0,$49(a1)                      ; Mirror the same X byte into the second control entry.
        move.w     $8(a0,d2.w),d0                 ; Fetch the Y position for this sprite.
        move.b     d0,(a1)                         ; Store the sprite start line.
        addi.w     #$11,d0                         ; Add 17 lines for the sprite stop line.
        move.b     d0,$2(a1)                       ; Store the sprite stop line.
        adda.l     #$94,a1                         ; Next sprite block is $94 bytes further on.
        addq.w     #$2,d2                          ; Advance to the next word pair.
        cmpi.w     #$6,d2                          ; Four sprite pairs are updated here.
        bls.w      update_one_sprite_pair                           ; Loop until all sprite pairs have positions.
        movem.l    a2-a3,-(a7)                     ; Keep A2/A3 safe while sine tables are sampled.
        clr.l      d2                               ; Start with the first sprite sine counter.
        lea.l      sprite_sine_counters,a0                     ; A0 points at the four sine counters.
        lea.l      $313b2.l,a1                     ; X sine table.
        lea.l      $314b2.l,a2                     ; Y sine table.
        lea.l      sprite_position_words,a3                     ; Output position words used by the sprite writer.

calculate_one_sprite_position:
        move.w     (a0,d2.w),d0                   ; Read one sine counter.
        cmpi.w     #$100,d0                        ; Table wraps at 256 entries.
        bcs.b      sprite_sine_index_ok                           ; Still inside the table range.
        clr.w      d0                               ; Wrap this counter back to zero.

sprite_sine_index_ok:
        move.b     (a1,d0.w),d1                   ; Read the X sine value.
        andi.w     #$ff,d1                         ; Keep the sine byte unsigned.
        addi.w     #$78,d1                         ; Shift the X coordinate into the visible sprite area.
        move.w     d1,(a3,d2.w)                   ; Store the calculated X position.
        move.b     (a2,d0.w),d1                   ; Read the Y sine value.
        andi.w     #$ff,d1                         ; Keep the sine byte unsigned.
        addi.w     #$2c,d1                         ; Shift the Y coordinate into the display window.
        move.w     d1,$8(a3,d2.w)                 ; Store the calculated Y position.
        addq.w     #$1,d0                          ; Advance this sprite sine counter.
        move.w     d0,(a0,d2.w)                   ; Save it back for the next frame.
        addq.w     #$2,d2                          ; Move to the next counter/position word.
        cmpi.l     #$6,d2                          ; Four counters are processed as word offsets 0,2,4,6.
        bls.w      calculate_one_sprite_position                           ; Loop over the remaining counters.
        movem.l    (a7)+,a2-a3                     ; Restore the table registers.
        rts                                        ; Sprite positions are ready for this frame.

open_graphics_and_prepare_screens:
        movea.l    EXEC_BASE_PTR,a6                         ; ExecBase again, this time for Forbid/OpenLibrary.
        jsr        -$84(a6)                         ; Forbid task switches while the intro owns the display.
        lea.l      graphics_library_name(pc),a1                   ; Point at the graphics.library name string.
        jsr        -$198(a6)                        ; Open graphics.library; the version argument is whatever D0 held originally.
        move.l     d0,gfxbase_ptr                     ; Save GfxBase for the cleanup path.
        movea.l    #SCREEN_PLANE_1,a0                      ; First logo bitplane destination.
        move.l     a0,d0                           ; Split the destination pointer for copper BPL words.
        move.w     d0,copper_bpl1ptl                     ; Patch the low pointer word in the copper list.
        swap       d0                               ; Bring the high word down.
        move.w     d0,copper_bpl1pth                     ; Patch the high pointer word in the copper list.
        movea.l    #SCREEN_PLANE_2,a0                      ; Second logo bitplane destination.
        move.l     a0,d0                           ; Split that pointer for the copper list.
        move.w     d0,copper_bpl2ptl                     ; Patch the low word for plane 2.
        swap       d0                               ; Bring the high word down.
        move.w     d0,copper_bpl2pth                     ; Patch the high word for plane 2.
        movea.l    #SCREEN_PLANE_3,a0                      ; Third logo bitplane destination.
        move.l     a0,d0                           ; Split that pointer as well.
        move.w     d0,copper_bpl3ptl                     ; Patch the low word for plane 3.
        swap       d0                               ; Bring the high word down.
        move.w     d0,copper_bpl3pth                     ; Patch the high word for plane 3.
        movea.l    #SCREEN_PLANE_4,a0                      ; Fourth logo bitplane destination.
        move.l     a0,d0                           ; Split the fourth pointer for copper.
        move.w     d0,copper_bpl4ptl                     ; Patch the low word for plane 4.
        swap       d0                               ; Bring the high word down.
        move.w     d0,copper_bpl4pth                     ; Patch the high word for plane 4.
        movea.l    #SCREEN_PLANE_1,a0                      ; Clear the visible logo bitplane memory from the first plane.
        move.l     #$c800,d0                       ; Clear 51,201 bytes of display memory (5 planes of 320x256 / 8 bytes).
        move.b     #$0,d1                          ; Zero byte used by the clear loop.
.clear_logo_loop:
        move.b     d1,(a0)+                        ; Clear one byte.
        dbra       d0,.clear_logo_loop                       ; Keep clearing the logo screen memory.
        movea.l    #SCROLLER_WORK_BUFFER,a0                      ; Clear the scroll/object work buffer.
        move.l     #$1770,d0                       ; Clear 6,001 bytes there.
        move.b     #$0,d1                          ; Zero byte used by this clear loop too.
.clear_work_loop:
        move.b     d1,(a0)+                        ; Clear one byte of work memory.
        dbra       d0,.clear_work_loop                       ; Keep clearing until the work buffer is empty.
        rts                                        ; Display buffers are clean.

copy_logo_bitplanes_to_display_memory:
        movea.l    #SCREEN_PLANE_1+SCREEN_LOGO_OFFSET,a0                      ; Copy plane 1 into chip/display memory.
        movea.l    #logo_bitplane_source_1,a1                      ; Plane 1 source is embedded in this file.
        move.l     #$19c8,d0                       ; Each logo plane copy is 6,601 bytes.

copy_logo_plane_1:
        move.b     (a1)+,(a0)+                     ; Copy one byte of logo plane 1.
        dbra       d0,copy_logo_plane_1                       ; Keep copying plane 1.
        movea.l    #SCREEN_PLANE_2+SCREEN_LOGO_OFFSET,a0                      ; Copy plane 2 into chip/display memory.
        movea.l    #logo_bitplane_source_2,a1                      ; Plane 2 source is embedded later in the file.
        move.l     #$19c8,d0                       ; Same byte count for the second plane.

copy_logo_plane_2:
        move.b     (a1)+,(a0)+                     ; Copy one byte of logo plane 2.
        dbra       d0,copy_logo_plane_2                       ; Keep copying plane 2.
        movea.l    #SCREEN_PLANE_3+SCREEN_LOGO_OFFSET,a0                      ; Copy plane 3 into chip/display memory.
        movea.l    #logo_bitplane_source_3,a1                      ; Plane 3 source is embedded later in the file.
        move.l     #$19c8,d0                       ; Same byte count for the third plane.

copy_logo_plane_3:
        move.b     (a1)+,(a0)+                     ; Copy one byte of logo plane 3.
        dbra       d0,copy_logo_plane_3                       ; Keep copying plane 3.
        movea.l    #SCREEN_PLANE_4+SCREEN_LOGO_OFFSET,a0                      ; Copy plane 4 into chip/display memory.
        movea.l    #logo_bitplane_source_4,a1                      ; Plane 4 source is embedded later in the file.
        move.l     #$19c8,d0                       ; Same byte count for the fourth plane.

copy_logo_plane_4:
        move.b     (a1)+,(a0)+                     ; Copy one byte of logo plane 4.
        dbra       d0,copy_logo_plane_4                       ; Keep copying plane 4.
        rts                                        ; All four logo planes are in display memory.

build_sprite_control_blocks:
        lea.l      RUNTIME_STRIP_1.l,a1            ; Build the first layer of the starfield.
        lea.l      sprite_shape_table_1.l,a0        ; Use the first shape table.
        move.w     #$3e,d0                         ; There are $3f records in this batch.
        bsr.w      build_one_sprite_control_block                           ; Write that control block.
        lea.l      RUNTIME_STRIP_2.l,a1            ; Build the second layer of the starfield.
        lea.l      sprite_shape_table_2.l,a0        ; Use the second shape table.
        move.w     #$3e,d0                         ; Same number of records here.
        bsr.w      build_one_sprite_control_block                           ; Write the second control block.
        lea.l      RUNTIME_STRIP_3.l,a1            ; Build the third layer of the starfield.
        lea.l      sprite_shape_table_3.l,a0        ; Use the third shape table.
        move.w     #$3e,d0                         ; Same record count again.
        bsr.w      build_one_sprite_control_block                           ; Write the third control block.
        rts                                        ; Sprite/control records are ready.

build_one_sprite_control_block:
        move.w     #$58,d7                         ; D7 is the row count used for this generated sprite strip.
        move.w     #$1,d1                          ; D1 is the bit mask that rotates through the records.

write_sprite_control_entry:
        move.b     d0,(a1)+                        ; Store the current Y/control byte.
        move.b     (a0)+,(a1)+                     ; Copy the shape byte paired with this record.
        move.b     d0,(a1)                         ; Store the second Y/control byte.
        addq.b     #$1,(a1)+                       ; Make the second byte one line lower.
        clr.b      (a1)+                            ; Clear the attachment/control byte.
        clr.w      (a1)+                            ; Clear the next word in the generated record.
        move.w     d1,(a1)+                        ; Store the current bit mask.
        addq.w     #$2,d0                          ; Move two lines down for the next generated record.
        rol.w      #$1,d1                          ; Rotate the mask for the next sprite row.
        dbra       d7,write_sprite_control_entry                       ; Keep writing the block.
        rts                                        ; This sprite/control block is done.

build_runtime_copper_gradients:
        lea.l      first_copper_colour_gradient,a0                     ; Start writing the first copper gradient at its runtime address.
        move.l     #$2009,d1                       ; First WAIT line for the gradient.
        move.w     #$1,d2                          ; First colour value.
        move.l     #$d,d0                          ; Fourteen steps in the rising half.

write_upper_gradient_copper_move:
        move.w     d1,(a0)+                        ; Emit one WAIT word.
        move.w     #$fffe,(a0)+                    ; Copper WAIT mask is always $fffe here.
        move.w     #$180,(a0)+                     ; Copper register COLOR00.
        move.w     d2,(a0)+                        ; Store the current colour value.
        addi.w     #$100,d1                        ; Next screen line.
        addi.w     #$1,d2                          ; Next brighter colour.
        dbra       d0,write_upper_gradient_copper_move                       ; Continue the rising gradient.
        move.w     #$f,d2                          ; Start the falling half at colour $f.
        move.l     #$d,d0                          ; Fourteen steps back down.

write_lower_gradient_copper_move:
        move.w     d1,(a0)+                        ; Emit one WAIT word for the falling half.
        move.w     #$fffe,(a0)+                    ; Same WAIT mask.
        move.w     #$180,(a0)+                     ; Still writing COLOR00.
        move.w     d2,(a0)+                        ; Store the current falling colour value.
        addi.w     #$100,d1                        ; Next screen line.
        subi.w     #$1,d2                          ; One colour step darker.
        dbra       d0,write_lower_gradient_copper_move                       ; Continue the falling gradient.
        lea.l      middle_copper_colour_bar,a0                     ; Middle bar uses COLOR01 instead of COLOR00.
        move.l     #$f301,d1                       ; Start near the bottom of the display.
        move.l     #$14,d0                         ; Twenty-one slots are patched here.

write_middle_bar_copper_move:
        move.w     d1,(a0)+                        ; Emit the WAIT word.
        move.w     #$fffe,(a0)+                    ; Copper WAIT mask.
        move.w     #$182,(a0)+                     ; Copper register COLOR01.
        move.w     #$0,(a0)+                       ; Clear the colour value; the IRQ patches it later.
        addi.w     #$100,d1                        ; Next line for the middle bar.
        cmpi.w     #$1,d1                          ; Handle the wrap from $ffxx to the copper end marker style.
        bne.w      middle_bar_wait_ok                           ; No wrap needed yet.
        move.w     #$ffdf,d1                       ; Use $ffdf after the vertical wait wraps.

middle_bar_wait_ok:
        dbra       d0,write_middle_bar_copper_move                       ; Continue building the middle bar.
        lea.l      second_copper_colour_gradient,a0                     ; Second gradient starts later in the copper list.
        move.l     #$1009,d1                       ; First WAIT line for that second gradient.
        move.w     #$1,d2                          ; First colour value for it.
        move.l     #$d,d0                          ; Fourteen rising steps again.

write_second_upper_gradient:
        move.w     d1,(a0)+                        ; Emit one WAIT word.
        move.w     #$fffe,(a0)+                    ; Copper WAIT mask.
        move.w     #$180,(a0)+                     ; Copper register COLOR00.
        move.w     d2,(a0)+                        ; Store the current colour value.
        addi.w     #$100,d1                        ; Next line.
        addi.w     #$1,d2                          ; Next brighter colour.
        dbra       d0,write_second_upper_gradient                       ; Continue the rising half.
        move.w     #$f,d2                          ; Start the falling half.
        move.l     #$d,d0                          ; Fourteen falling steps.

write_second_lower_gradient:
        move.w     d1,(a0)+                        ; Emit one WAIT word.
        move.w     #$fffe,(a0)+                    ; Copper WAIT mask.
        move.w     #$180,(a0)+                     ; Copper register COLOR00.
        move.w     d2,(a0)+                        ; Store the colour value.
        addi.w     #$100,d1                        ; Next line.
        subi.w     #$1,d2                          ; One colour step darker.
        dbra       d0,write_second_lower_gradient                       ; Continue the falling half.
        rts                                        ; Runtime copper gradients are ready.

install_vblank_and_system_copper_hook:
        move.w     #$4000,INTENA                ; Disable interrupt master while vectors and copper hooks move.
        move.l     LEVEL3_INTERRUPT_VECTOR,old_level3_vector                  ; Save the current level-3 vector into our IRQ trampoline.
        move.l     #level3_vblank_irq,LEVEL3_INTERRUPT_VECTOR                   ; Install this intro as the level-3/VBlank handler.
        move.w     #$c000,INTENA                ; Re-enable interrupt master.
        movea.l    gfxbase_ptr,a0                     ; Load GfxBase saved during OpenLibrary.
        adda.l     #$32,a0                         ; Step to the library copper pointer slot that the intro borrows.
        move.w     #$80,DMACON                  ; Disable copper DMA while the pointer is replaced.
        move.l     (a0),saved_system_copper_long                   ; Remember the old system copper pointer for cleanup.
        move.l     #main_copper_list,(a0)                    ; Point graphics.library at this intro copper list.
        move.w     #$80a0,DMACON                ; Re-enable copper and blitter DMA for the intro.
        rts                                        ; IRQ/copper hook is installed.


main_copper_list:
        dc.w    $0180,$0000                     ; COLOR00 = $000 (Black background)
        dc.w    $0182,$0126                     ; COLOR01 = $126
        dc.w    $0184,$0237                     ; COLOR02 = $237
        dc.w    $0186,$0348                     ; COLOR03 = $348
        dc.w    $0188,$0348                     ; COLOR04 = $348
        dc.w    $018a,$0359                     ; COLOR05 = $359
        dc.w    $018c,$0459                     ; COLOR06 = $459
        dc.w    $018e,$056a                     ; COLOR07 = $56A
        dc.w    $0190,$067b                     ; COLOR08 = $67B
        dc.w    $0192,$09ae                     ; COLOR09 = $9AE
        dc.w    $0194,$0abf                     ; COLOR10 = $ABF
        dc.w    $0196,$0bcf                     ; COLOR11 = $BCF
        dc.w    $0198,$0cdf                     ; COLOR12 = $CDF
        dc.w    $019a,$0def                     ; COLOR13 = $DEF
        dc.w    $019c,$0eff                     ; COLOR14 = $EFF
        dc.w    $019e,$0fff                     ; COLOR15 = $FFF
        dc.w    $00e0                           ; BPL1PTH register address (High Word)

copper_bpl1pth:
        dc.w    $0005                           ; BPL1PTH value (patched at runtime)
        dc.w    $00e2                           ; BPL1PTL register address (Low Word)

copper_bpl1ptl:
        dc.w    $5140                           ; BPL1PTL value (patched at runtime)
        dc.w    $00e4                           ; BPL2PTH register address

copper_bpl2pth:
        dc.w    $0005                           ; BPL2PTH value
        dc.w    $00e6                           ; BPL2PTL register address

copper_bpl2ptl:
        dc.w    $5140                           ; BPL2PTL value
        dc.w    $00e8                           ; BPL3PTH register address

copper_bpl3pth:
        dc.w    $0005                           ; BPL3PTH value
        dc.w    $00ea                           ; BPL3PTL register address

copper_bpl3ptl:
        dc.w    $5140                           ; BPL3PTL value
        dc.w    $00ec                           ; BPL4PTH register address

copper_bpl4pth:
        dc.w    $0005                           ; BPL4PTH value
        dc.w    $00ee                           ; BPL4PTL register address

copper_bpl4ptl:
        dc.w    $5140                           ; BPL4PTL value
        dc.w    $0092                           ; DDFSTRT register address
        dc.w    $0038                           ; DDFSTRT value: LORES Display Data Fetch Start
        dc.w    $0094                           ; DDFSTOP register address
        dc.w    $00d0                           ; DDFSTOP value: Display Data Fetch Stop
        dc.w    $0100                           ; BPLCON0 register address
        dc.w    $4200                           ; BPLCON0 value: 4 bitplanes, color display enabled
        dc.w    $0108                           ; BPL1MOD register address
        dc.w    $0000                           ; BPL1MOD value: Modulo odd bitplanes = 0
        dc.w    $010a                           ; BPL2MOD register address
        dc.w    $0000                           ; BPL2MOD value: Modulo even bitplanes = 0
        dc.w    $0104                           ; BPLCON2 register address
        dc.w    $0010                           ; BPLCON2 value: Sprite priority (sprites in foreground)
        dc.w    $008e                           ; DIWSTRT register address
        dc.w    $3c81                           ; DIWSTRT value: Display Window Start (Y: 60, X: 129)
        dc.w    $0090                           ; DIWSTOP register address
        dc.w    $f0be                           ; DIWSTOP value: Display Window Stop (Y: 240, X: 190)
        dc.w    $0102                           ; BPLCON1 register address
        dc.w    $0000                           ; BPLCON1 value: Horizontal scroll offset = 0
        dc.w    $01a2                           ; COLOR17 register address (Sprite 0 color 1)
        dc.w    $0459                           ; COLOR17 value: $459
        dc.w    $01a4                           ; COLOR18 register address (Sprite 0 color 2)
        dc.w    $09ae                           ; COLOR18 value: $9AE
        dc.w    $01a6                           ; COLOR19 register address (Sprite 0 color 3)
        dc.w    $0def                           ; COLOR19 value: $DEF
        dc.w    $01aa                           ; COLOR21 register address (Sprite 1 color 1)
        dc.w    $0459                           ; COLOR21 value: $459
        dc.w    $01ac                           ; COLOR22 register address (Sprite 1 color 2)
        dc.w    $09ae                           ; COLOR22 value: $9AE
        dc.w    $01ae                           ; COLOR23 register address (Sprite 1 color 3)
        dc.w    $0def                           ; COLOR23 value: $DEF
        dc.w    $0120                           ; SPR0PTH register address (Sprite 0 High Pointer)
copper_spr0pth:
        dc.w    $0006                           ; SPR0PTH high word value
        dc.w    $0122                           ; SPR0PTL register address (Sprite 0 Low Pointer)
copper_spr0ptl:
        dc.w    $a128                           ; SPR0PTL low word value (Sprite 0 buffer starting at $6a128)
        dc.w    $0124                           ; SPR1PTH register address (Sprite 1 High Pointer)
copper_spr1pth:
        dc.w    $0006                           ; SPR1PTH high word value
        dc.w    $0126                           ; SPR1PTL register address (Sprite 1 Low Pointer)
copper_spr1ptl:
        dc.w    $a094                           ; SPR1PTL low word value (Sprite 1 buffer starting at $6a094)
        dc.w    $0128                           ; SPR2PTH register address (Sprite 2 High Pointer)
copper_spr2pth:
        dc.w    $0006                           ; SPR2PTH high word value
        dc.w    $012a                           ; SPR2PTL register address (Sprite 2 Low Pointer)
copper_spr2ptl:
        dc.w    $a000                           ; SPR2PTL low word value (Sprite 2 buffer starting at $6a000)
        dc.w    $012c                           ; SPR3PTH register address (Sprite 3 High Pointer)
copper_spr3pth:
        dc.w    $0006                           ; SPR3PTH high word value
        dc.w    $012e                           ; SPR3PTL register address (Sprite 3 Low Pointer)
copper_spr3ptl:
        dc.w    $a1bc                           ; SPR3PTL low word value (Sprite 3 buffer starting at $6a1bc)
        dc.w    $01b4                           ; COLOR26 register address (Sprite 5 color 2)
        dc.w    $008f                           ; COLOR26 value: $08F
        dc.w    $0130                           ; SPR4PTH register address (Sprite 4 High Pointer)
copper_spr4pth:
        dc.w    $0004                           ; SPR4PTH high word value
        dc.w    $0132                           ; SPR4PTL register address (Sprite 4 Low Pointer)
copper_spr4ptl:
        dc.w    $a000                           ; SPR4PTL low word value (Sprite 4 buffer starting at $4a000)
        dc.w    $0134                           ; SPR5PTH register address (Sprite 5 High Pointer)
copper_spr5pth:
        dc.w    $0004                           ; SPR5PTH high word value
        dc.w    $0136                           ; SPR5PTL register address (Sprite 5 Low Pointer)
copper_spr5ptl:
        dc.w    $a310                           ; SPR5PTL low word value (Sprite 5 buffer starting at $4a310)
        dc.w    $0138                           ; SPR6PTH register address (Sprite 6 High Pointer)
copper_spr6pth:
        dc.w    $0004                           ; SPR6PTH high word value
        dc.w    $013a                           ; SPR6PTL register address (Sprite 6 Low Pointer)
copper_spr6ptl:
        dc.w    $a610                           ; SPR6PTL low word value (Sprite 6 buffer starting at $4a610)

; Runtime copper gradient area filled by build_runtime_copper_gradients.

first_copper_colour_gradient:
        ds.b    224
        dc.w    $0180,$0000                     ; COLOR00 = $000
        dc.w    $f001,$fffe                     ; WAIT: line 240 (F0), horizontal position 0
        dc.w    $0180,$0000                     ; COLOR00 = $000
        dc.w    $00e0,$0005                     ; BPL1PTH = $0005 (Scroller Plane High)
        dc.w    $00e2,$db74                     ; BPL1PTL = $db74 (Scroller Plane Low: $5db74)
        dc.w    $0100,$1200                     ; BPLCON0 = $1200 (1 bitplane, color display enabled)
        dc.w    $0092,$0028                     ; DDFSTRT = $0028 (Scrolltext Display Fetch Start)
        dc.w    $0094,$00d8                     ; DDFSTOP = $00d8 (Scrolltext Display Fetch Stop)
        dc.w    $0108,$0000                     ; BPL1MOD = $0000 (Odd modulo = 0)
        dc.w    $0104,$0000                     ; BPLCON2 = $0000 (Reset priorities)
        dc.w    $008e,$f171                     ; DIWSTRT = $f171 (Scroller Display Window Start Y: 241, X: 113)
        dc.w    $0090,$3ac9                     ; DIWSTOP = $3ac9 (Scroller Display Window Stop Y: 298, X: 201)
        dc.w    $0102,$0000                     ; BPLCON1 = $0000 (Scroll offset = 0)

; Middle copper bar colour slots; VBlank rotates these values every frame.

middle_copper_colour_bar:
        ds.b    168

; Second runtime copper gradient area.

second_copper_colour_gradient:
        ds.b    224
        dc.w    $0180,$0000                     ; COLOR00 = $000 (Reset background color)
        dc.w    $ffff,$fffe                     ; COPPER END MARKER ($FFFFFFFE)

; Exec library name used by OpenLibrary.

graphics_library_name:
        dc.b    "graphics.library"
        dc.b    $00,$00,$00,$00,$00,$00

; Runtime pointers saved while the intro owns graphics.library state.

saved_system_copper_long:
        dc.b    $00,$00,$00,$00

gfxbase_ptr:
        dc.b    $00,$00,$00,$00,$00,$00

; Sprite position words and sine counters used by the VBlank path.

sprite_position_words:
        ds.b    16

sprite_sine_counters:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00

scroller_delay_counter:
        dc.b    $00,$00,$00,$00

scroller_text_ptr:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

scroller_shift_buffer:
        ds.b    32

; Scroll charset followed directly by the lower-case marquee text.
; The scroll routine wraps when it reaches the terminating zero byte.

scroller_charset:
        dc.b    " 0123456789!.?:'(),"
scroller_text_start:
        dc.b    " yeah of course !!!  ))))) the champs (((((  "
        dc.b    "present : sidewinder cracked by delta-force    the best salute g"
        dc.b    "o to : hotline high'quality'crackings delta'force and tristar(th"
        dc.b    "e best get better !!!)    the special greetings in alphabetical "
        dc.b    "order go to : axxess antitrax bfbs blizzards bs1 bst ccw ernie f"
        dc.b    "ree'network general indy ibb knight'hawks megaforce new'age mr.n"
        dc.b    "ewlook northern'lights powerxtreme random'access red sector skyl"
        dc.b    "ine tlc tom visitor wizards and all the others we know....   com"
        dc.b    "ming soon more and more new prg from the unattainable   ))))) th"
        dc.b    "e champs ((((( in 1988 !!!!!                                    "
        dc.b    "                                             "
        dc.b    $00
        dc.b    $00,$00

; 16-bit colour ramp used by the VBlank copper colour rotation.

copper_colour_rotation_table:
        dc.w    $0001,$0002,$0003,$0004,$0005,$0006,$0007,$0008
        dc.w    $0009,$000a,$000b,$000c,$000d,$000e,$000f,$011f
        dc.w    $022f,$033f,$044f,$055f,$066f,$077f,$088f,$099f
        dc.w    $0aaf,$0bbf,$0ccf,$0ddf,$0eef,$0eff,$0fff,$0fff
        dc.w    $0eff,$0eef,$0ddf,$0ccf,$0bbf,$0aaf,$099f,$088f
        dc.w    $077f,$066f,$055f,$044f,$033f,$022f,$011f,$000f
        dc.w    $000e,$000d,$000c,$000b,$000a,$0009,$0008,$0007
        dc.w    $0006,$0005,$0004,$0003,$0002,$0001,$0001,$0002
        dc.w    $0003,$0004,$0005,$0006,$0007,$0008,$0009,$000a
        dc.w    $000b,$000c,$000d,$000e,$000f,$011f,$022f,$033f
        dc.w    $044f,$055f,$066f,$077f,$088f,$099f,$0aaf,$0bbf
        dc.w    $0ccf,$0ddf,$0eef,$0eff,$0fff,$0fff,$0eff,$0eef
        dc.w    $0ddf,$0ccf,$0bbf,$0aaf,$099f,$088f,$077f,$066f
        dc.w    $055f,$044f,$033f,$022f,$011f,$000f,$000e,$000d
        dc.w    $000c,$000b,$000a,$0009,$0008,$0007,$0006,$0005
        dc.w    $0004,$0003,$0002,$0001

; 8-word glyph data for the bottom text scroller.

champs_scroll_font:
; -----------------------------------------------------
; Character 'a' (index 0, offset 0)
; -----------------------------------------------------
        dc.w    $0ff8           ; ....********....
        dc.w    $1e3c           ; ...****...****..
        dc.w    $3c00           ; ..****..........
        dc.w    $7ffe           ; .***************
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'b' (index 1, offset 16)
; -----------------------------------------------------
        dc.w    $79f8           ; .****..******...
        dc.w    $783c           ; .****.....****..
        dc.w    $783c           ; .****.....****..
        dc.w    $79fc           ; .****..********.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $79fc           ; .****..********.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'c' (index 2, offset 32)
; -----------------------------------------------------
        dc.w    $39f8           ; ..***..******...
        dc.w    $781c           ; .****......***..
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $781c           ; .****......***..
        dc.w    $39f8           ; ..***..******...
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'd' (index 3, offset 48)
; -----------------------------------------------------
        dc.w    $79f8           ; .****..******...
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $79f8           ; .****..******...
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'e' (index 4, offset 64)
; -----------------------------------------------------
        dc.w    $7ffe           ; .***************
        dc.w    $0000           ; ................
        dc.w    $7800           ; .****...........
        dc.w    $7f80           ; .*******........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $7ffe           ; .***************
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'f' (index 5, offset 80)
; -----------------------------------------------------
        dc.w    $7ffe           ; .***************
        dc.w    $0000           ; ................
        dc.w    $7800           ; .****...........
        dc.w    $7f80           ; .*******........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'g' (index 6, offset 96)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $780e           ; .****........***
        dc.w    $0000           ; ................
        dc.w    $78ee           ; .****...***..***
        dc.w    $780e           ; .****........***
        dc.w    $780e           ; .****........***
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'h' (index 7, offset 112)
; -----------------------------------------------------
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $79fe           ; .****..*********
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'i' (index 8, offset 128)
; -----------------------------------------------------
        dc.w    $0ff0           ; ....********....
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $0ff0           ; ....********....
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'j' (index 9, offset 144)
; -----------------------------------------------------
        dc.w    $7ffe           ; .***************
        dc.w    $0000           ; ................
        dc.w    $001e           ; ...........****.
        dc.w    $001e           ; ...........****.
        dc.w    $003c           ; ..........****..
        dc.w    $3c78           ; ..****....****..
        dc.w    $0ff0           ; ....********....
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'k' (index 10, offset 160)
; -----------------------------------------------------
        dc.w    $781c           ; .****......***..
        dc.w    $7870           ; .****....***....
        dc.w    $79c0           ; .****..***......
        dc.w    $7980           ; .****..**.......
        dc.w    $79c0           ; .****..***......
        dc.w    $7870           ; .****....***....
        dc.w    $781c           ; .****......***..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'l' (index 11, offset 176)
; -----------------------------------------------------
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $0000           ; ................
        dc.w    $7ffe           ; .***************
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'm' (index 12, offset 192)
; -----------------------------------------------------
        dc.w    $6006           ; .**.........**..
        dc.w    $700e           ; .***.......***..
        dc.w    $0000           ; ................
        dc.w    $7e7e           ; .******..******.
        dc.w    $7b9e           ; .****.***.****.
        dc.w    $791e           ; .****..*..****.
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'n' (index 13, offset 208)
; -----------------------------------------------------
        dc.w    $781e           ; .****......****.
        dc.w    $7c1e           ; .*****.....****.
        dc.w    $0000           ; ................
        dc.w    $7b9e           ; .****.***.****.
        dc.w    $79de           ; .****..*..*****
        dc.w    $787e           ; .****....******
        dc.w    $783e           ; .****.....*****
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'o' (index 14, offset 224)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'p' (index 15, offset 240)
; -----------------------------------------------------
        dc.w    $79f8           ; .****..******...
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $79f8           ; .****..******...
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'q' (index 16, offset 256)
; -----------------------------------------------------
        dc.w    $39fc           ; ..***..********.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $79de           ; .****..*..*****
        dc.w    $39fc           ; ..***..********.
        dc.w    $0070           ; ..........***...
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'r' (index 17, offset 272)
; -----------------------------------------------------
        dc.w    $79f8           ; .****..******...
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $79f8           ; .****..******...
        dc.w    $79e0           ; .****..****.....
        dc.w    $7878           ; .****....****...
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 's' (index 18, offset 288)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................
        dc.w    $3ffc           ; ..************..
        dc.w    $001e           ; ...........****.
        dc.w    $781e           ; .****......****.
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 't' (index 19, offset 304)
; -----------------------------------------------------
        dc.w    $7ffe           ; .***************
        dc.w    $0000           ; ................
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $03c0           ; ......****......
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'u' (index 20, offset 320)
; -----------------------------------------------------
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $19f8           ; ...**..******...
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'v' (index 21, offset 336)
; -----------------------------------------------------
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $1e78           ; ...****..****...
        dc.w    $03c0           ; ......****......
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'w' (index 22, offset 352)
; -----------------------------------------------------
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................
        dc.w    $799e           ; .****..*..****.
        dc.w    $7bde           ; .****.***.*****
        dc.w    $7e7e           ; .******..******
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'x' (index 23, offset 368)
; -----------------------------------------------------
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $1e78           ; ...****..****...
        dc.w    $0660           ; ......**..**....
        dc.w    $1e78           ; ...****..****...
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'y' (index 24, offset 384)
; -----------------------------------------------------
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $1ffe           ; ...*************
        dc.w    $001e           ; ...........****.
        dc.w    $0000           ; ................
        dc.w    $781e           ; .****......****.
        dc.w    $3ff8           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character 'z' (index 25, offset 400)
; -----------------------------------------------------
        dc.w    $7e7e           ; .******..******.
        dc.w    $783c           ; .****.....****..
        dc.w    $0070           ; .........***....
        dc.w    $0240           ; ......*..*......
        dc.w    $0e00           ; ....***.........
        dc.w    $3c1e           ; ..****......****.
        dc.w    $7e7e           ; .******..******.
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character ' ' (space) (index 26, offset 416)
; -----------------------------------------------------
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '0' (index 27, offset 432)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $787e           ; .****....******.
        dc.w    $78de           ; .****...**..****
        dc.w    $799e           ; .****..**....***
        dc.w    $7b1e           ; .****.**.....***
        dc.w    $7e1e           ; .******......***
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '1' (index 28, offset 448)
; -----------------------------------------------------
        dc.w    $00f0           ; ........****....
        dc.w    $03f0           ; ......******....
        dc.w    $0ef0           ; ....***.****....
        dc.w    $00f0           ; ........****....
        dc.w    $00f0           ; ........****....
        dc.w    $00f0           ; ........****....
        dc.w    $01f8           ; .......******...
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '2' (index 29, offset 464)
; -----------------------------------------------------
        dc.w    $07fc           ; .....**********.
        dc.w    $1e1e           ; ...****....****.
        dc.w    $001e           ; ...........****.
        dc.w    $0078           ; .........****...
        dc.w    $01e0           ; .......****.....
        dc.w    $0f8e           ; ....*****....***
        dc.w    $1ffe           ; ...*************
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '3' (index 30, offset 480)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $781e           ; .****......****.
        dc.w    $003c           ; ..........****..
        dc.w    $00e0           ; ........***.....
        dc.w    $003c           ; ..........****..
        dc.w    $781e           ; .****......****.
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '4' (index 31, offset 496)
; -----------------------------------------------------
        dc.w    $7800           ; .****...........
        dc.w    $7800           ; .****...........
        dc.w    $79e0           ; .****..****.....
        dc.w    $7ffc           ; .*************..
        dc.w    $01e0           ; .......****.....
        dc.w    $01e0           ; .......****.....
        dc.w    $01e0           ; .......****.....
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '5' (index 32, offset 512)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $3c0c           ; ..****......**..
        dc.w    $3c00           ; ..****..........
        dc.w    $3ff0           ; ..**********....
        dc.w    $003c           ; ..........****..
        dc.w    $303c           ; ..**......****..
        dc.w    $3ff0           ; ..**********....
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '6' (index 33, offset 528)
; -----------------------------------------------------
        dc.w    $1ffc           ; ...************..
        dc.w    $3c1e           ; ..****......****.
        dc.w    $7800           ; .****...........
        dc.w    $7ffc           ; .*************..
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '7' (index 34, offset 544)
; -----------------------------------------------------
        dc.w    $1ffc           ; ...************..
        dc.w    $003c           ; ..........****..
        dc.w    $0078           ; .........****...
        dc.w    $00f0           ; ........****....
        dc.w    $00f0           ; ........****....
        dc.w    $00f0           ; ........****....
        dc.w    $00f0           ; ........****....
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '8' (index 35, offset 560)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $3ffc           ; ..************..
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '9' (index 36, offset 576)
; -----------------------------------------------------
        dc.w    $3ffc           ; ..************..
        dc.w    $781e           ; .****......****.
        dc.w    $781e           ; .****......****.
        dc.w    $3ffe           ; ..***************
        dc.w    $001e           ; ...........****.
        dc.w    $001e           ; ...........****.
        dc.w    $3ffc           ; ..************..
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '!' (index 37, offset 592)
; -----------------------------------------------------
        dc.w    $0380           ; ......***.......
        dc.w    $07c0           ; .....*****......
        dc.w    $07c0           ; .....*****......
        dc.w    $07c0           ; .....*****......
        dc.w    $0380           ; ......***.......
        dc.w    $0000           ; ................
        dc.w    $0380           ; ......***.......
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '.' (index 38, offset 608)
; -----------------------------------------------------
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0380           ; ......***.......
        dc.w    $0380           ; ......***.......
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '?' (index 39, offset 624)
; -----------------------------------------------------
        dc.w    $07fc           ; .....**********.
        dc.w    $0f1e           ; ....****....****.
        dc.w    $001e           ; ...........****.
        dc.w    $0078           ; .........****...
        dc.w    $0078           ; .........****...
        dc.w    $0000           ; ................
        dc.w    $0078           ; .........****...
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character ':' (index 40, offset 640)
; -----------------------------------------------------
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0380           ; ......***.......
        dc.w    $0380           ; ......***.......
        dc.w    $0000           ; ................
        dc.w    $0380           ; ......***.......
        dc.w    $0380           ; ......***.......
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character ''' (index 41, offset 656)
; -----------------------------------------------------
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $1ff8           ; ...*********....
        dc.w    $1ff8           ; ...*********....
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character '(' (index 42, offset 672)
; -----------------------------------------------------
        dc.w    $0330           ; ......**..**....
        dc.w    $0cc0           ; ....**..**......
        dc.w    $1980           ; ...**..**.......
        dc.w    $3300           ; ..**..**........
        dc.w    $1980           ; ...**..**.......
        dc.w    $0cc0           ; ....**..**......
        dc.w    $0330           ; ......**..**....
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character ')' (index 43, offset 688)
; -----------------------------------------------------
        dc.w    $0cc0           ; ....**..**......
        dc.w    $0330           ; ......**..**....
        dc.w    $0198           ; .......**..**...
        dc.w    $00cc           ; ........**..**..
        dc.w    $0198           ; .......**..**...
        dc.w    $0330           ; ......**..**....
        dc.w    $0cc0           ; ....**..**......
        dc.w    $0000           ; ................

; -----------------------------------------------------
; Character ',' (index 44, offset 704)
; Note: This glyph has 14 bytes in raw data. Rendering copies 16 bytes.
; The final word ($7330) overlaps with the next label sprite_shape_table_1!
; Since comma is not used in the scrolltext, this overlap has no visual effect.
; -----------------------------------------------------
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0000           ; ................
        dc.w    $0380           ; ......***.......
        dc.w    $0380           ; ......***.......
        dc.w    $0180           ; .......**.......
        dc.w    $0100           ; .......*........

; ---------------------------------------------------------------------------
; Sprite Shape Trajectory Tables (Deformation Paths for Moving Strips)
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; DATA STORAGE FORMAT: STARFIELD INITIAL X-COORDINATES
; ---------------------------------------------------------------------------
; These tables do NOT contain standard graphic bitmaps/pixel grids.
; Instead, they are 1-dimensional arrays containing raw 8-bit horizontal 
; coordinates (HSTART values).
; 
; Storage Format Details:
; - 1 Byte = 1 Star: Each byte represents the starting X-coordinate for a star.
; (HSTART)
; ---------------------------------------------------------------------------

; ===========================================================================
; Starfield Layer 1 - Initial X-Coordinates
; ===========================================================================
; Each byte defines the horizontal start position (HSTART) for one of the 89
; 1-pixel stars in this layer. The stars are drawn every 2 scanlines, starting
; from Y=62 down to Y=238.
sprite_shape_table_1:
        ; X-values for Stars 1-8
        dc.b    $73,$30,$bd,$02, $4d,$ce,$55,$e7
        ; X-values for Stars 9-16
        dc.b    $10,$ff,$1a,$81, $8f,$aa,$55,$e7
        ; X-values for Stars 17-24
        dc.b    $8f,$aa,$55,$e7, $10,$ff,$1a,$81
        ; X-values for Stars 25-32
        dc.b    $8f,$aa,$55,$e7, $a1,$09,$7a,$da
        ; X-values for Stars 33-40
        dc.b    $55,$e7,$73,$30, $10,$ff,$7a,$da
        ; X-values for Stars 41-48
        dc.b    $8f,$aa,$4d,$ce, $55,$e7,$a1,$09
        ; X-values for Stars 49-56
        dc.b    $73,$30,$db,$85, $c0,$eb,$a1,$09
        ; X-values for Stars 57-64
        dc.b    $7a,$da,$30,$fa, $bd,$02,$4d,$ce
        ; X-values for Stars 65-72
        dc.b    $8f,$aa,$db,$85, $c0,$eb,$a1,$09
        ; X-values for Stars 73-80
        dc.b    $7a,$da,$30,$fa, $7a,$da,$a1,$09
        ; X-values for Stars 81-88
        dc.b    $55,$e7,$73,$30, $10,$ff,$7a,$da
        ; X-value for Star 89 + 7 unused padding bytes
        dc.b    $8f,$aa,$4d,$ce, $55,$e7,$a1,$09

; ===========================================================================
; Starfield Layer 2 - Initial X-Coordinates
; ===========================================================================
sprite_shape_table_2:
        ; X-values for Stars 1-8
        dc.b    $8f,$aa,$55,$e7, $10,$ff,$1a,$81
        ; X-values for Stars 9-16
        dc.b    $8f,$aa,$55,$e7, $a1,$09,$7a,$da
        ; X-values for Stars 17-24
        dc.b    $76,$32,$dd,$87, $c4,$ea,$a5,$21
        ; X-values for Stars 25-32
        dc.b    $7d,$da,$34,$fa, $bd,$12,$4d,$cf
        ; X-values for Stars 33-40
        dc.b    $73,$30,$db,$85, $c0,$eb,$a1,$09
        ; X-values for Stars 41-48
        dc.b    $7a,$da,$30,$fa, $bd,$02,$4d,$ce
        ; X-values for Stars 49-56
        dc.b    $8f,$aa,$55,$e7, $10,$ff,$1a,$81
        ; X-values for Stars 57-64
        dc.b    $8f,$aa,$25,$e7, $a1,$09,$7a,$da
        ; X-values for Stars 65-72
        dc.b    $45,$e5,$33,$30, $40,$ff,$aa,$54
        ; X-values for Stars 73-80
        dc.b    $9f,$aa,$4c,$ce, $95,$e7,$a3,$09
        ; X-values for Stars 81-88
        dc.b    $55,$e7,$74,$60, $15,$ff,$1a,$bc
        ; X-value for Star 89 + 7 unused padding bytes
        dc.b    $7f,$1a,$7d,$ce, $54,$e7,$a1,$49

; ===========================================================================
; Starfield Layer 3 - Initial X-Coordinates
; ===========================================================================
sprite_shape_table_3:
        ; X-values for Stars 1-8
        dc.b    $4f,$da,$52,$e3, $12,$ef,$1b,$31
        ; X-values for Stars 9-16
        dc.b    $2f,$ab,$53,$e7, $aa,$0a,$7d,$da
        ; X-values for Stars 17-24
        dc.b    $73,$30,$db,$85, $c0,$eb,$a1,$09
        ; X-values for Stars 25-32
        dc.b    $7a,$da,$30,$fa, $bd,$02,$4d,$ce
        ; X-values for Stars 33-40
        dc.b    $8f,$aa,$55,$e7, $10,$ff,$1a,$81
        ; X-values for Stars 41-48
        dc.b    $8f,$aa,$34,$fa, $bd,$12,$4d,$cf
        ; X-values for Stars 49-56
        dc.b    $55,$e7,$73,$30, $10,$ff,$7a,$da
        ; X-values for Stars 57-64
        dc.b    $8f,$aa,$4d,$ce, $55,$e7,$a1,$09
        ; X-values for Stars 65-72
        dc.b    $4f,$da,$52,$e3, $12,$ef,$1b,$31
        ; X-values for Stars 73-80
        dc.b    $2f,$ab,$53,$e7, $aa,$0a,$7d,$da
        ; X-values for Stars 81-88
        dc.b    $55,$e7,$a1,$09, $7a,$da,$76,$32
        ; X-value for Star 89 + 7 unused padding bytes
        dc.b    $dd,$87,$c4,$ea, $a5,$21,$7d,$da

sprite_template_source:
        ; ===========================================================================
        ; SPRITE 2 - Animated '1988' Digit
        ; ===========================================================================
        ; Upper digit element: VSTART is overwritten dynamically by sine routines
        dc.w    $6d60,$7e00                     ; Sprite Control: VSTART=$6d, HSTART=$60, VSTOP=$7e
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fff0,$fff0                     ; Graphic Line 2
        dc.w    $8010,$ffe0                     ; Graphic Line 3
        dc.w    $8010,$ffe0                     ; Graphic Line 4
        dc.w    $8010,$ffe0                     ; Graphic Line 5
        dc.w    $9f90,$e0e0                     ; Graphic Line 6
        dc.w    $9090,$e0e0                     ; Graphic Line 7
        dc.w    $9f9e,$efe0                     ; Graphic Line 8
        dc.w    $8002,$fffc                     ; Graphic Line 9
        dc.w    $8002,$fffc                     ; Graphic Line 10
        dc.w    $9f82,$e0fc                     ; Graphic Line 11
        dc.w    $9082,$e0fc                     ; Graphic Line 12
        dc.w    $9f82,$effc                     ; Graphic Line 13
        dc.w    $8002,$fffc                     ; Graphic Line 14
        dc.w    $8002,$fffc                     ; Graphic Line 15
        dc.w    $fffe,$8000                     ; Vertical Chain Link / Multiplex Terminator
        dc.w    $0000,$0000                     ; Blank Spacer / Link Data

        ; Lower digit reflection: VSTART=$d0 (line 208), HSTART is updated to match the top digit
        dc.w    $d060,$e100                     ; Sprite Control: VSTART=$d0, HSTART=$60, VSTOP=$e1
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fff0,$fff0                     ; Graphic Line 2
        dc.w    $8010,$ffe0                     ; Graphic Line 3
        dc.w    $8010,$ffe0                     ; Graphic Line 4
        dc.w    $8010,$ffe0                     ; Graphic Line 5
        dc.w    $9f90,$e0e0                     ; Graphic Line 6
        dc.w    $9090,$e0e0                     ; Graphic Line 7
        dc.w    $9f9e,$efe0                     ; Graphic Line 8
        dc.w    $8002,$fffc                     ; Graphic Line 9
        dc.w    $8002,$fffc                     ; Graphic Line 10
        dc.w    $9f82,$e0fc                     ; Graphic Line 11
        dc.w    $9082,$e0fc                     ; Graphic Line 12
        dc.w    $9f82,$effc                     ; Graphic Line 13
        dc.w    $8002,$fffc                     ; Graphic Line 14
        dc.w    $8002,$fffc                     ; Graphic Line 15
        dc.w    $fffe,$8000                     ; List Terminator for Sprite 2
        dc.w    $0000,$0000                     ; Alignment Padding to next Sprite boundary

        ; ===========================================================================
        ; SPRITE 1 - Animated '1988' Digit
        ; ===========================================================================
        ; Upper digit element: VSTART is overwritten dynamically by sine routines
        dc.w    $6d60,$7e00                     ; Sprite Control: VSTART=$6d, HSTART=$60, VSTOP=$7e
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fff0,$fff0                     ; Graphic Line 2
        dc.w    $8010,$ffe0                     ; Graphic Line 3
        dc.w    $8010,$ffe0                     ; Graphic Line 4
        dc.w    $8010,$ffe0                     ; Graphic Line 5
        dc.w    $8f90,$f0e0                     ; Graphic Line 6
        dc.w    $8890,$f0e0                     ; Graphic Line 7
        dc.w    $8f9c,$f7e0                     ; Graphic Line 8
        dc.w    $8004,$fff8                     ; Graphic Line 9
        dc.w    $8004,$fff8                     ; Graphic Line 10
        dc.w    $8004,$fff8                     ; Graphic Line 11
        dc.w    $7f84,$0078                     ; Graphic Line 12
        dc.w    $7f84,$7ff8                     ; Graphic Line 13
        dc.w    $8004,$fff8                     ; Graphic Line 14
        dc.w    $8004,$fff8                     ; Graphic Line 15
        dc.w    $fffc,$8000                     ; Vertical Chain Link / Multiplex Terminator
        dc.w    $0000,$0000                     ; Blank Spacer / Link Data
        dc.w    $0000,$0000                     ; Blank Spacer / Link Data

        ; Lower bracket element: VSTART=$d0 (line 208), HSTART=$60 (position 96)
        dc.w    $d060,$e100                     ; Sprite Control: VSTART=$d0, HSTART=$60, VSTOP=$e1
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fff0,$fff0                     ; Graphic Line 2
        dc.w    $8010,$ffe0                     ; Graphic Line 3
        dc.w    $8010,$ffe0                     ; Graphic Line 4
        dc.w    $8010,$ffe0                     ; Graphic Line 5
        dc.w    $8f90,$f0e0                     ; Graphic Line 6
        dc.w    $8890,$f0e0                     ; Graphic Line 7
        dc.w    $8f9c,$f7e0                     ; Graphic Line 8
        dc.w    $8004,$fff8                     ; Graphic Line 9
        dc.w    $8004,$fff8                     ; Graphic Line 10
        dc.w    $8004,$fff8                     ; Graphic Line 11
        dc.w    $7f84,$0078                     ; Graphic Line 12
        dc.w    $7f84,$7ff8                     ; Graphic Line 13
        dc.w    $8004,$fff8                     ; Graphic Line 14
        dc.w    $8004,$fff8                     ; Graphic Line 15
        dc.w    $fffc,$8000                     ; List Terminator for Sprite 1
        dc.w    $0000,$0000                     ; Alignment Padding to next Sprite boundary
        dc.w    $0000,$0000                     ; Alignment Padding to next Sprite boundary

        ; ===========================================================================
        ; SPRITE 0 - Animated '1988' Digit
        ; ===========================================================================
        ; Upper digit element: VSTART is overwritten dynamically by sine routines
        dc.w    $6d60,$7e00                     ; Sprite Control: VSTART=$6d, HSTART=$60, VSTOP=$7e
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fe00,$fe00                     ; Graphic Line 2
        dc.w    $8200,$fc00                     ; Graphic Line 3
        dc.w    $8200,$fc00                     ; Graphic Line 4
        dc.w    $8200,$fc00                     ; Graphic Line 5
        dc.w    $8200,$fc00                     ; Graphic Line 6
        dc.w    $83c0,$fc00                     ; Graphic Line 7
        dc.w    $8040,$ff80                     ; Graphic Line 8
        dc.w    $8040,$ff80                     ; Graphic Line 9
        dc.w    $8040,$ff80                     ; Graphic Line 10
        dc.w    $8040,$ff80                     ; Graphic Line 11
        dc.w    $8040,$ff80                     ; Graphic Line 12
        dc.w    $8040,$ff80                     ; Graphic Line 13
        dc.w    $8040,$ff80                     ; Graphic Line 14
        dc.w    $8040,$ff80                     ; Graphic Line 15
        dc.w    $ffc0,$8000                     ; Vertical Chain Link / Multiplex Terminator
        dc.w    $0000,$0000                     ; Blank Spacer / Link Data

        ; Lower digit reflection: VSTART=$d0 (line 208), HSTART is updated to match the top digit
        dc.w    $d060,$e100                     ; Sprite Control: VSTART=$d0, HSTART=$60, VSTOP=$e1
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fe00,$fe00                     ; Graphic Line 2
        dc.w    $8200,$fc00                     ; Graphic Line 3
        dc.w    $8200,$fc00                     ; Graphic Line 4
        dc.w    $8200,$fc00                     ; Graphic Line 5
        dc.w    $8200,$fc00                     ; Graphic Line 6
        dc.w    $83c0,$fc00                     ; Graphic Line 7
        dc.w    $8040,$ff80                     ; Graphic Line 8
        dc.w    $8040,$ff80                     ; Graphic Line 9
        dc.w    $8040,$ff80                     ; Graphic Line 10
        dc.w    $8040,$ff80                     ; Graphic Line 11
        dc.w    $8040,$ff80                     ; Graphic Line 12
        dc.w    $8040,$ff80                     ; Graphic Line 13
        dc.w    $8040,$ff80                     ; Graphic Line 14
        dc.w    $8040,$ff80                     ; Graphic Line 15
        dc.w    $ffc0,$8000                     ; List Terminator for Sprite 0
        dc.w    $0000,$0000                     ; Alignment Padding to next Sprite boundary

        ; ===========================================================================
        ; SPRITE 3 - Animated '1988' Digit
        ; ===========================================================================
        ; Upper digit element: VSTART is overwritten dynamically by sine routines
        dc.w    $6d60,$7e00                     ; Sprite Control: VSTART=$6d, HSTART=$60, VSTOP=$7e
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fff0,$fff0                     ; Graphic Line 2
        dc.w    $8010,$ffe0                     ; Graphic Line 3
        dc.w    $8010,$ffe0                     ; Graphic Line 4
        dc.w    $8010,$ffe0                     ; Graphic Line 5
        dc.w    $9f90,$e0e0                     ; Graphic Line 6
        dc.w    $9090,$e0e0                     ; Graphic Line 7
        dc.w    $9f9e,$efe0                     ; Graphic Line 8
        dc.w    $8002,$fffc                     ; Graphic Line 9
        dc.w    $8002,$fffc                     ; Graphic Line 10
        dc.w    $9f82,$e0fc                     ; Graphic Line 11
        dc.w    $9082,$e0fc                     ; Graphic Line 12
        dc.w    $9f82,$effc                     ; Graphic Line 13
        dc.w    $8002,$fffc                     ; Graphic Line 14
        dc.w    $8002,$fffc                     ; Graphic Line 15
        dc.w    $fffe,$8000                     ; Vertical Chain Link / Multiplex Terminator
        dc.w    $0000,$0000                     ; Blank Spacer / Link Data
        dc.w    $0000,$0000                     ; Blank Spacer / Link Data

        ; Lower digit reflection: VSTART=$d0 (line 208), HSTART is updated to match the top digit
        dc.w    $d060,$e100                     ; Sprite Control: VSTART=$d0, HSTART=$60, VSTOP=$e1
        dc.w    $0000,$0000                     ; Graphic Line 1
        dc.w    $fff0,$fff0                     ; Graphic Line 2
        dc.w    $8010,$ffe0                     ; Graphic Line 3
        dc.w    $8010,$ffe0                     ; Graphic Line 4
        dc.w    $8010,$ffe0                     ; Graphic Line 5
        dc.w    $9f90,$e0e0                     ; Graphic Line 6
        dc.w    $9090,$e0e0                     ; Graphic Line 7
        dc.w    $9f9e,$efe0                     ; Graphic Line 8
        dc.w    $8002,$fffc                     ; Graphic Line 9
        dc.w    $8002,$fffc                     ; Graphic Line 10
        dc.w    $9f82,$e0fc                     ; Graphic Line 11
        dc.w    $9082,$e0fc                     ; Graphic Line 12
        dc.w    $9f82,$effc                     ; Graphic Line 13
        dc.w    $8002,$fffc                     ; Graphic Line 14
        dc.w    $8002,$fffc                     ; Graphic Line 15
        dc.w    $fffe,$8000                     ; List Terminator for Sprite 3
        dc.w    $0000,$0000                     ; Alignment Padding / Final End marker
        dc.w    $0000,$0000                     ; Alignment Padding / Final End marker
        dc.w    $0000,$0000                     ; Alignment Padding / Final End marker

; X and Y sine tables for the four moving sprite pairs.

sprite_x_sine_table:
        dc.b    $50,$50,$51,$53,$56,$5a,$5e,$63,$68,$6e,$74,$7b,$82,$89,$91,$98
        dc.b    $9f,$a7,$ad,$b4,$ba,$c0,$c5,$ca,$ce,$d1,$d4,$d6,$d7,$d8,$d8,$d8
        dc.b    $d6,$d5,$d2,$d0,$cd,$c9,$c5,$c1,$bd,$b9,$b5,$b1,$ad,$a9,$a6,$a2
        dc.b    $a0,$9d,$9b,$99,$98,$97,$97,$97,$97,$98,$99,$9b,$9c,$9e,$a0,$a2
        dc.b    $a4,$a6,$a8,$aa,$ab,$ac,$ad,$ae,$ae,$ae,$ad,$ac,$aa,$a8,$a6,$a3
        dc.b    $a0,$9c,$98,$94,$8f,$8b,$86,$81,$7d,$78,$74,$70,$6c,$69,$66,$64
        dc.b    $62,$61,$61,$61,$62,$64,$66,$6a,$6d,$72,$77,$7d,$83,$89,$90,$97
        dc.b    $9f,$a6,$ae,$b6,$bd,$c4,$cb,$d1,$d7,$dd,$e2,$e6,$e9,$ec,$ee,$ef
        dc.b    $ef,$ee,$ed,$eb,$e8,$e4,$e0,$db,$d6,$d0,$ca,$c3,$bc,$b5,$ae,$a7
        dc.b    $a0,$9a,$93,$8d,$87,$82,$7d,$79,$76,$73,$70,$6f,$6e,$6d,$6d,$6e
        dc.b    $70,$71,$74,$76,$79,$7c,$80,$83,$87,$8b,$8e,$92,$95,$98,$9b,$9d
        dc.b    $9f,$a1,$a2,$a3,$a3,$a3,$a3,$a2,$a1,$a0,$9e,$9c,$9a,$98,$96,$94
        dc.b    $92,$90,$8e,$8d,$8b,$8b,$8a,$8a,$8b,$8b,$8d,$8f,$91,$94,$97,$9b
        dc.b    $9f,$a3,$a8,$ad,$b2,$b7,$bc,$c2,$c7,$cc,$d0,$d4,$d8,$dc,$de,$e1
        dc.b    $e2,$e3,$e3,$e3,$e1,$df,$dd,$d9,$d5,$d0,$cb,$c5,$be,$b7,$b0,$a9
        dc.b    $a1,$99,$91,$8a,$82,$7b,$74,$6e,$68,$63,$5e,$5a,$57,$54,$53,$52

sprite_y_sine_table:
        dc.b    $56,$52,$4f,$4b,$48,$44,$41,$3e,$3c,$39,$37,$36,$35,$34,$33,$33
        dc.b    $33,$34,$35,$36,$37,$39,$3b,$3e,$40,$43,$45,$48,$4b,$4e,$51,$53
        dc.b    $56,$59,$5b,$5d,$5f,$61,$62,$63,$64,$65,$65,$66,$65,$65,$65,$64
        dc.b    $63,$62,$61,$60,$5f,$5e,$5c,$5b,$5a,$59,$58,$57,$57,$56,$56,$56
        dc.b    $56,$56,$57,$58,$58,$59,$5a,$5c,$5d,$5e,$60,$61,$63,$64,$65,$66
        dc.b    $67,$68,$69,$69,$69,$69,$69,$68,$67,$66,$64,$62,$60,$5e,$5c,$59
        dc.b    $56,$53,$50,$4d,$4a,$47,$44,$41,$3f,$3c,$3a,$38,$36,$34,$33,$32
        dc.b    $32,$32,$32,$32,$33,$35,$37,$39,$3b,$3e,$41,$44,$47,$4b,$4e,$52
        dc.b    $56,$59,$5d,$61,$64,$67,$6a,$6d,$6f,$72,$73,$75,$76,$77,$77,$77
        dc.b    $77,$77,$76,$74,$73,$71,$6f,$6d,$6b,$68,$66,$63,$60,$5e,$5b,$59
        dc.b    $56,$54,$52,$50,$4f,$4d,$4c,$4b,$4b,$4a,$4a,$4a,$4b,$4b,$4c,$4c
        dc.b    $4d,$4e,$4f,$50,$51,$52,$53,$54,$55,$56,$57,$57,$57,$57,$57,$57
        dc.b    $56,$56,$55,$54,$52,$51,$50,$4e,$4c,$4b,$49,$48,$46,$45,$43,$42
        dc.b    $41,$41,$40,$40,$40,$40,$41,$42,$43,$44,$46,$48,$4a,$4d,$50,$53
        dc.b    $56,$59,$5c,$5f,$62,$66,$69,$6c,$6f,$71,$74,$76,$78,$79,$7a,$7b
        dc.b    $7c,$7c,$7b,$7b,$79,$78,$76,$74,$72,$6f,$6c,$69,$65,$62,$5e,$5b

; Raw logo bitplane source 1, copied to $56dc4.

logo_bitplane_source_1:
        incbin "logo_bpl1.raw"

logo_bitplane_source_2:
        incbin "logo_bpl2.raw"

logo_bitplane_source_3:
        incbin "logo_bpl3.raw"

logo_bitplane_source_4:
        incbin "logo_bpl4.raw"

; ===========================================================================
; Thomas Lopatic / Dr. Nobody (Phalanx) - Beathoven Synthesizer (BSS)
; Complete disassembler reconstruction of phalanx2.bss player and data.
; Compiled to run at resident address $70000.
; ===========================================================================

; ---------------------------------------------------------------------------
; Symbol Equates relative to resident_payload_source ($70000 at runtime)
; ---------------------------------------------------------------------------
music_song_track_1        equ     $70000
music_song_track_1_start  equ     $70007
music_pattern_t1_p5       equ     $70403
music_pattern_t1_p3       equ     $706e8
music_pattern_t1_p2       equ     $70c04
music_pattern_t1_p1       equ     $7140c
music_pattern_t1_p4       equ     $71c0d
music_song_track_2        equ     $7206c
music_song_track_3        equ     $75568
music_song_track_4        equ     $76cb2
music_pattern_t4_p1       equ     $77300
music_envelope_presets    equ     $7875a
music_wavetable_presets   equ     $78f1e
music_synth_presets       equ     $79fb2
music_player_init         equ     $7e000
music_sub_stop_cia        equ     $7e045
music_player_stop         equ     $7e04a
music_sub_restore_irq     equ     $7e059
music_sub_stop_dma        equ     $7e062
music_vblank_handler      equ     $7e066
music_var_old_level6      equ     $7e06c
music_sub_play_tick       equ     $7e070
music_sub_channel_play    equ     $7e09c
music_sub_channel_loop    equ     $7e0ac
music_sub_freq_calc_voice equ     $7e0b6
music_sub_adsr_process    equ     $7e0d4
music_sub_update_synth    equ     $7e0e2
music_sub_synth_exit      equ     $7e11e
music_mixer_volume        equ     $7e120
music_channel_1_state     equ     $7e124
music_channel_1_vars      equ     $7e170
music_var_7e193           equ     $7e193
music_channel_2_vars      equ     $7e1ac
music_channel_3_vars      equ     $7e1e8
music_channel_4_vars      equ     $7e224
music_vblank_counter      equ     $7e260
music_sub_init_channels   equ     $7e292
music_sub_mixer_tick      equ     $7e36c
music_sub_mixer_channel   equ     $7e37f
music_sub_channel_tick    equ     $7e3fe
music_sub_next_pattern    equ     $7e40a
music_sub_load_track      equ     $7e41c
music_sub_read_sequence   equ     $7e430
music_sub_check_command   equ     $7e43e
music_sub_parse_note      equ     $7e458
music_sub_set_frequency   equ     $7e4ee
music_sub_freq_calc       equ     $7e4f0
music_sub_update_envelope equ     $7e52a
music_sub_envelope_tick   equ     $7e52f
music_sub_volume_tick     equ     $7e5b0
music_sub_pan_tick        equ     $7e5c1
music_sub_lfo_tick        equ     $7e5cf
music_sub_channel_exit    equ     $7e5d8
music_sub_dma_tick        equ     $7e631
music_sub_paula_write     equ     $7e649
music_sub_mixer_exit      equ     $7e652
music_sub_clear_registers equ     $7e656
music_sequence_table_1    equ     $7e658
music_var_7e671           equ     $7e671
music_var_7e6b7           equ     $7e6b7
music_var_7e6cf           equ     $7e6cf
music_sequence_loop_1     equ     $7e6d8
music_var_7e6ed           equ     $7e6ed
music_var_7e6f9           equ     $7e6f9
music_var_7e723           equ     $7e723
music_var_7e748           equ     $7e748
music_var_7e751           equ     $7e751
music_var_7e759           equ     $7e759
music_var_7e78f           equ     $7e78f
music_var_7e837           equ     $7e837
music_sequence_table_2    equ     $7e840
music_sequence_loop_2     equ     $7e848
music_var_7e858           equ     $7e858
music_var_7e867           equ     $7e867
music_sequence_table_3    equ     $7e870
music_sequence_loop_3     equ     $7e888
music_var_7e8a0           equ     $7e8a0
music_sequence_table_4    equ     $7e8d0
music_sequence_loop_4     equ     $7e8e0
music_var_7e8f8           equ     $7e8f8
music_var_7e958           equ     $7e958
music_var_7e964           equ     $7e964
music_var_7e970           equ     $7e970
music_var_7e97c           equ     $7e97c
music_var_7e988           equ     $7e988
music_var_7e994           equ     $7e994
music_var_7e9a0           equ     $7e9a0
music_var_7e9ac           equ     $7e9ac
music_var_7e9ce           equ     $7e9ce
music_var_7e9de           equ     $7e9de
music_var_7ea0a           equ     $7ea0a
music_var_7ea2c           equ     $7ea2c
music_var_7ea3e           equ     $7ea3e
music_var_7ea57           equ     $7ea57
music_var_7ea7a           equ     $7ea7a
music_var_7ea82           equ     $7ea82
music_var_7ead5           equ     $7ead5
music_var_7eb00           equ     $7eb00
music_var_7eb95           equ     $7eb95
music_var_7ebac           equ     $7ebac
music_var_7ec46           equ     $7ec46
music_var_7ec89           equ     $7ec89
music_var_7ecd0           equ     $7ecd0
music_var_7ed06           equ     $7ed06
music_var_7ed12           equ     $7ed12
music_var_7ed18           equ     $7ed18
music_var_7ed3c           equ     $7ed3c
music_var_7ed72           equ     $7ed72
music_var_7ee69           equ     $7ee69
music_var_7eedb           equ     $7eedb
music_var_7ef9b           equ     $7ef9b
music_var_7f0d0           equ     $7f0d0
music_var_7f0d8           equ     $7f0d8
music_var_7f116           equ     $7f116
music_var_7f229           equ     $7f229
music_var_7f270           equ     $7f270
music_var_7f8cd           equ     $7f8cd
music_var_7f903           equ     $7f903
music_var_7f939           equ     $7f939
music_var_7f96f           equ     $7f96f
music_var_7fa2b           equ     $7fa2b
music_var_7fa94           equ     $7fa94
music_var_7fc42           equ     $7fc42
music_var_7feb1           equ     $7feb1

resident_payload_source:

; ---------------------------------------------------------------------------
; Part 1: Song Data ($70000 - $7DFFF) - phalanx2.bss
; ---------------------------------------------------------------------------

; ===========================================================================
; Beathoven Synthesizer Song Data - Track 1 Sequencer & Notes.
; ===========================================================================
music_song_track_1_src:
        dc.b    $00,$00,$00,$00,$00,$00,$00
music_song_track_1_start_src:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$01,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $ff,$00,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fd,$fc,$fb,$f9,$f8,$f5
        dc.b    $f3,$f0,$ec,$e8,$e2,$dc,$da,$db,$de,$ef,$ff,$0d,$1b,$2b,$38,$45
        dc.b    $51,$5b,$63,$6a,$6f,$54,$49,$40,$38,$30,$28,$22,$1c,$18,$13,$0f
        dc.b    $0c,$08,$06,$03,$01,$00,$fe,$fd,$fc,$fa,$f9,$f9,$f8,$f8,$f7,$f6
        dc.b    $f4,$eb,$e4,$de,$d8,$d1,$cc,$c6,$c1,$bc,$b8,$b4,$b1,$ae,$ac,$aa
        dc.b    $a8,$a8,$a7,$a7,$a8,$a9,$aa,$ac,$af,$bf,$cb,$d3,$db,$e1,$e7,$ed
        dc.b    $f1,$f6,$f9,$fc,$ff,$01,$04,$06,$07,$09,$0a,$0c,$0d,$0d,$0e,$0f
        dc.b    $0f,$0f,$10,$10,$11,$11,$11,$11,$11,$11,$11,$11,$14,$17,$19,$1c
        dc.b    $1e,$21,$23,$25,$27,$29,$2b,$2c,$2e,$2f,$2f,$30,$30,$30,$30,$30
        dc.b    $2f,$2e,$2e,$2c,$2b,$2a,$28,$26,$24,$23,$21,$1f,$1d,$14,$80,$8f
        dc.b    $af,$b9,$c2,$ca,$d1,$d7,$dd,$e3,$e7,$eb,$ef,$f2,$f5,$f7,$f9,$fc
        dc.b    $fd,$0b,$23,$35,$43,$53,$62,$6d,$7a,$7f,$7f,$7f,$7f,$78,$68,$59
        dc.b    $4d,$42,$38,$30,$28,$21,$1a,$15,$10,$0c,$08,$04,$01,$ff,$fc,$fb
        dc.b    $f9,$f8,$f6,$f4,$f4,$f3,$f2,$f1,$f1,$f0,$f0,$f0,$f0,$f0,$ef,$ef
        dc.b    $ef,$ef,$ef,$ef,$ef,$ef,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$e5,$e0
        dc.b    $d9,$d3,$cc,$c7,$c1,$bd,$b8,$b4,$b1,$ae,$ab,$a9,$a8,$a7,$a6,$a6
        dc.b    $a6,$a7,$a8,$aa,$ad,$af,$bf,$ca,$d3,$da,$e1,$e7,$ec,$f1,$f5,$f9
        dc.b    $fd,$ff,$02,$03,$06,$07,$09,$0a,$0b,$0c,$0d,$0e,$0e,$0f,$0f,$0f
        dc.b    $10,$10,$10,$10,$11,$10,$11,$11,$15,$17,$19,$1c,$1e,$20,$23,$25
        dc.b    $27,$28,$2a,$2b,$2c,$2d,$2e,$2e,$2e,$2f,$2e,$2e,$2d,$2c,$2c,$2a
        dc.b    $29,$28,$26,$25,$23,$22,$20,$1e,$1c,$14,$d8,$80,$a7,$b5,$be,$c7
        dc.b    $ce,$d5,$db,$e0,$e5,$e9,$ed,$f0,$f3,$f6,$f8,$fa,$fc,$ff,$1d,$2d
        dc.b    $3d,$4b,$59,$65,$71,$7a,$7f,$7f,$7f,$7e,$70,$62,$54,$48,$40,$34
        dc.b    $2c,$25,$1d,$18,$12,$0e,$0a,$06,$03,$00,$fe,$fc,$fa,$f8,$f6,$f5
        dc.b    $f4,$f3,$f2,$f2,$f1,$f0,$f0,$f0,$f0,$f0,$ef,$ef,$ef,$ef,$ef,$ef
        dc.b    $ef,$ef,$ef,$ef,$f0,$f0,$f0,$f0,$f0,$e8,$e1,$db,$d6,$d0,$cb,$c5
        dc.b    $c0,$bc,$b8,$b5,$b1,$ae,$ad,$ab,$aa,$a9,$a9,$a9,$aa,$ab,$ac,$ae
        dc.b    $b0,$b3,$bf,$ca,$d3,$da,$e1,$e7,$ec,$f1,$f5,$f9,$fc,$fe,$01,$03
        dc.b    $05,$07,$08,$0a,$0b,$0c,$0d,$0e,$0e,$0e,$0f,$0f,$0f,$10,$10,$10
        dc.b    $10,$10,$11,$14,$17,$19,$1b,$1e,$20,$23,$24,$26,$27,$29,$2a,$2c
        dc.b    $2c,$2d,$2e,$2e,$2e,$2e,$2d,$2d,$2c,$2b,$2a,$29,$28,$26,$25,$23
        dc.b    $22,$20,$1e,$1c,$1a,$12,$f4,$c8,$90,$9f,$b6,$bf,$c7,$cf,$d5,$db
        dc.b    $e1,$e5,$e9,$ed,$f0,$f3,$f6,$f8,$fb,$ff,$17,$29,$37,$45,$51,$5d
        dc.b    $69,$72,$7b,$7f,$7f,$7f,$79,$68,$5a,$4d,$42,$38,$30,$28,$21,$1b
        dc.b    $15,$10,$0c,$08,$04,$01,$ff,$fc,$fb,$f9,$f8,$f6,$f4,$f4,$f3,$f2
        dc.b    $f1,$f1,$f0,$f0,$f0,$f0,$f0,$ef,$ef,$ef,$ef,$f0,$ef,$f0,$f0,$f0
        dc.b    $f0,$f0,$f0,$f0,$ec,$e4,$e0,$da,$d4,$cf,$ca,$c5,$c0,$bc,$b9,$b6
        dc.b    $b3,$b1,$af,$ae,$ad,$ac,$ac,$ad,$ad,$ae,$b0,$b1,$b3,$b6,$b9,$c6
        dc.b    $cf,$d7,$df,$e5,$ea,$ef,$f3,$f7,$fb,$fe,$00,$03,$05,$06,$08,$09
        dc.b    $0b,$0c,$0c,$0d,$0e,$0f,$0f,$0f,$0f,$0f,$10,$10,$10,$11,$14,$17
        dc.b    $19,$1b,$1e,$1f,$22,$23,$26,$27,$28,$2a,$2b,$2c,$2c,$2d,$2d,$2d
        dc.b    $2d,$2d,$2c,$2c,$2b,$2a,$29,$28,$26,$25,$24,$22,$20,$1f,$1d,$1b
        dc.b    $19,$10,$00,$e2,$c0,$a0,$8f,$b6,$bf,$c7,$cf,$d5,$db,$e0,$e5,$e9
        dc.b    $ed,$f0,$f3,$f6,$f8,$fb,$12,$1f,$2f,$3d,$49,$56,$61,$6a,$73,$79
        dc.b    $7f,$7f,$7f,$78,$62,$55,$4a,$40,$36,$2c,$26,$1e,$19,$13,$0f,$0a
        dc.b    $07,$03,$00,$fe,$fc,$fa,$f8,$f7,$f6,$f4,$f4,$f3,$f2,$f1,$f1,$f0
        dc.b    $f0,$f0,$f0,$f0,$f0,$ef,$f0,$ef,$ef,$f0,$ef,$f0,$f0,$f0,$f0,$f0
        dc.b    $e8,$e2,$dc,$d8,$d3,$cd,$c9,$c4,$c1,$bd,$ba,$b8,$b5,$b3,$b1,$b0
        dc.b    $b0,$b0,$af,$b0,$b1,$b1,$b3,$b5,$b7,$b9,$bd,$bf,$cb,$d4,$db,$e3
        dc.b    $e8,$ed,$f2,$f6,$f9,$fd,$ff,$01,$03,$06,$07,$09,$0a,$0b,$0c,$0d
        dc.b    $0e,$0e,$0f,$0f,$0f,$0f,$10,$10,$13,$15,$18,$19,$1c,$1e,$20,$22
        dc.b    $24,$26,$27,$29,$2a,$2b,$2c,$2c,$2c,$2d,$2d,$2d,$2c,$2c,$2c,$2b
        dc.b    $2a,$29,$28,$26,$25,$24,$22,$20,$1e,$1c,$1b,$19,$18,$10,$02,$f0
        dc.b    $d8,$c0,$a8,$90,$b4,$bd,$c6,$cd,$d4,$da,$e0,$e5,$e9,$ed,$f0,$f3
        dc.b    $f6,$f8,$ff,$17,$25,$33,$3f,$4c,$57,$61,$69,$70
music_pattern_t1_p5_src:
        dc.b    $75,$7b,$7e,$7f,$7a,$62,$55,$49,$40,$35,$2c,$25,$1e,$18,$13,$0e
        dc.b    $0a,$07,$03,$01,$fe,$fc,$fa,$f8,$f7,$f6,$f5,$f4,$f3,$f2,$f1,$f1
        dc.b    $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$ef,$f0,$f0,$f0,$f0,$ea
        dc.b    $e5,$e0,$db,$d6,$d2,$cd,$c8,$c5,$c1,$be,$bb,$b8,$b6,$b5,$b4,$b3
        dc.b    $b2,$b2,$b2,$b3,$b3,$b5,$b6,$b8,$ba,$bd,$bf,$c3,$c6,$cf,$d7,$df
        dc.b    $e5,$eb,$ef,$f3,$f7,$fb,$fe,$00,$03,$05,$06,$08,$09,$0b,$0c,$0c
        dc.b    $0d,$0e,$0f,$0f,$0f,$0f,$11,$14,$16,$18,$1a,$1c,$1e,$20,$22,$24
        dc.b    $26,$27,$28,$2a,$2b,$2b,$2c,$2c,$2c,$2c,$2c,$2c,$2c,$2b,$2a,$2a
        dc.b    $28,$27,$26,$25,$23,$22,$20,$1e,$1d,$1b,$19,$18,$16,$10,$06,$f8
        dc.b    $e8,$d4,$c2,$b0,$a0,$ab,$bb,$c5,$cc,$d3,$d9,$df,$e4,$e9,$ec,$f0
        dc.b    $f3,$f6,$f8,$0c,$1b,$29,$35,$41,$4c,$56,$5e,$66,$6c,$72,$76,$79
        dc.b    $7b,$7a,$62,$54,$48,$40,$35,$2c,$25,$1e,$18,$13,$0f,$0b,$07,$04
        dc.b    $01,$ff,$fc,$fb,$f9,$f8,$f6,$f5,$f4,$f3,$f3,$f2,$f1,$f1,$f0,$f0
        dc.b    $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$ef,$e8,$e3,$de,$d9,$d5
        dc.b    $d0,$cc,$c9,$c5,$c2,$bf,$bc,$ba,$b8,$b7,$b6,$b5,$b5,$b5,$b5,$b6
        dc.b    $b7,$b8,$ba,$bc,$be,$bf,$c3,$c5,$c9,$cc,$cf,$db,$e2,$e7,$ed,$f1
        dc.b    $f5,$f9,$fc,$ff,$01,$03,$05,$07,$08,$0a,$0b,$0c,$0c,$0d,$0e,$0e
        dc.b    $0f,$12,$14,$16,$18,$1a,$1c,$1e,$21,$22,$24,$26,$27,$28,$29,$2a
        dc.b    $2b,$2b,$2c,$2c,$2c,$2c,$2c,$2b,$2b,$2a,$29,$28,$27,$26,$25,$23
        dc.b    $22,$21,$1f,$1d,$1c,$1a,$18,$16,$14,$0e,$06,$fc,$f0,$e4,$d4,$c6
        dc.b    $b8,$ac,$a1,$b9,$c2,$ca,$d1,$d7,$dd,$e3,$e7,$eb,$ef,$f2,$f5,$ff
        dc.b    $0f,$1e,$2b,$37,$42,$4c,$54,$5c,$63,$69,$6e,$71,$74,$75,$76,$68
        dc.b    $56,$49,$40,$36,$2d,$26,$20,$19,$14,$0f,$0b,$07,$04,$01,$ff,$fd
        dc.b    $fb,$f9,$f8,$f6,$f5,$f4,$f3,$f2,$f2,$f1,$f1,$f0,$f0,$f0,$f0,$f0
        dc.b    $f0,$f0,$f0,$f0,$f0,$f0,$ea,$e6,$e1,$dc,$d8,$d4,$d0,$cc,$c9,$c6
        dc.b    $c2,$c0,$bd,$bc,$ba,$b9,$b8,$b8,$b7,$b8,$b8,$b9,$ba,$bb,$bd,$bf
        dc.b    $c1,$c3,$c6,$c8,$cb,$ce,$d2,$d5,$db,$e4,$e9,$ee,$f2,$f6,$fa,$fd
        dc.b    $ff,$02,$04,$06,$07,$09,$0a,$0b,$0c,$0d,$0d,$10,$13,$15,$17,$18
        dc.b    $1a,$1d,$1e,$21,$22,$24,$25,$27,$28,$29,$2a,$2a,$2a,$2b,$2b,$2b
        dc.b    $2b,$2b,$2b,$2a,$29,$28,$28,$27,$25,$24,$23,$22,$20,$1e,$1d,$1b
        dc.b    $1a,$18,$16,$15,$12,$0e,$08,$00,$f8,$ec,$e0,$d5,$ca,$c0,$b6,$b0
        dc.b    $aa,$be,$c7,$ce,$d5,$db,$e1,$e6,$ea,$ee,$f1,$f5,$07,$15,$21,$2d
        dc.b    $37,$42,$4b,$53,$5b,$60,$66,$69,$6c,$6f,$70,$70,$6e,$56,$4a,$40
        dc.b    $36,$2e,$26,$20,$19,$14,$0f,$0b,$08,$04,$01,$ff,$fd,$fb,$f9,$f8
        dc.b    $f7,$f6,$f4,$f3,$f3,$f2,$f2,$f1,$f1,$f1,$f0,$f0,$f0,$f0,$f0,$f0
        dc.b    $f0,$ec,$e7,$e3,$e0,$db,$d7,$d2,$cf,$cc,$c9,$c5,$c3,$c1,$bf,$bd
        dc.b    $bc,$bb,$ba,$ba,$ba,$ba,$bb,$bc,$bd,$be,$bf,$c2,$c4,$c7,$c9,$cc
        dc.b    $ce,$d1,$d4,$d7,$db,$de,$e3,$ea,$ef,$f3,$f7,$fa,$fd,$ff,$02,$04
        dc.b    $06,$07,$09,$0a,$0b,$0e,$10,$13,$14,$17,$19,$1b,$1d,$1e,$20,$22
        dc.b    $23,$25,$26,$27,$28,$29,$2a,$2a,$2b,$2b,$2b,$2a,$2a,$2a,$29,$29
        dc.b    $28,$27,$26,$25,$24,$23,$22,$20,$1e,$1d,$1c,$1a,$19,$17,$15,$14
        dc.b    $11,$0d,$08,$01,$fa,$f2,$e9,$e0,$d7,$ce,$c7,$c0,$ba,$b8,$b6,$bb
        dc.b    $c9,$d1,$d7,$dd,$e3,$e7,$eb,$ef,$ff,$0d,$17,$23,$2e,$38,$41,$4a
        dc.b    $52,$58,$5d,$62,$65,$68,$69,$6a,$6a,$68,$58,$4a,$40,$36,$2e,$27
        dc.b    $20,$1a,$14,$10,$0c,$08,$05,$02,$00,$fd,$fc,$fa,$f8,$f7,$f6,$f5
        dc.b    $f4,$f3,$f3,$f2,$f2,$f1,$f1,$f1,$f0,$f0,$f0,$f0,$ee,$e8,$e5,$e1
        dc.b    $dd,$d9,$d5,$d2,$cf
music_pattern_t1_p3_src:
        dc.b    $cc,$c9,$c7,$c4,$c2,$c0,$bf,$be,$bd,$bc,$bc,$bc,$bd,$be,$bf,$bf
        dc.b    $c1,$c3,$c5,$c7,$c9,$cb,$ce,$d0,$d3,$d6,$d9,$dc,$e0,$e3,$e7,$ea
        dc.b    $ed,$f2,$f7,$fa,$fd,$ff,$01,$03,$05,$08,$0b,$0e,$0f,$12,$14,$16
        dc.b    $19,$1b,$1c,$1e,$20,$22,$23,$24,$26,$27,$27,$28,$29,$29,$29,$2a
        dc.b    $2a,$2a,$29,$29,$29,$28,$28,$27,$26,$25,$24,$23,$21,$20,$1e,$1d
        dc.b    $1c,$1a,$18,$17,$16,$14,$12,$10,$0c,$08,$02,$fc,$f6,$ee,$e8,$e0
        dc.b    $d9,$d3,$ce,$c9,$c5,$c3,$c2,$c3,$c6,$c9,$cf,$d7,$dd,$e5,$ef,$f9
        dc.b    $03,$0e,$19,$24,$2e,$37,$3f,$47,$4e,$54,$58,$5c,$5f,$61,$62,$62
        dc.b    $62,$61,$60,$4a,$40,$36,$2e,$26,$20,$1a,$14,$10,$0c,$08,$05,$02
        dc.b    $00,$fe,$fc,$fa,$f9,$f8,$f6,$f5,$f4,$f4,$f3,$f2,$f2,$f2,$f1,$f1
        dc.b    $f1,$f0,$f0,$ea,$e7,$e3,$e0,$dc,$d8,$d5,$d1,$cf,$cc,$c9,$c7,$c5
        dc.b    $c3,$c1,$c0,$bf,$bf,$bf,$bf,$bf,$bf,$c0,$c1,$c3,$c4,$c6,$c7,$ca
        dc.b    $cb,$ce,$d0,$d3,$d6,$d8,$db,$de,$e2,$e5,$e7,$eb,$ee,$f1,$f4,$f8
        dc.b    $fb,$fe,$00,$03,$06,$08,$0b,$0d,$0f,$12,$14,$16,$18,$1a,$1c,$1e
        dc.b    $1f,$21,$22,$23,$25,$26,$26,$27,$27,$28,$28,$28,$28,$28,$28,$28
        dc.b    $27,$27,$26,$25,$25,$23,$23,$22,$20,$1f,$1d,$1c,$1a,$19,$18,$16
        dc.b    $14,$13,$11,$0f,$0c,$08,$03,$fe,$f9,$f4,$ed,$e8,$e2,$dc,$d8,$d4
        dc.b    $d0,$cf,$cd,$cd,$ce,$d0,$d4,$d8,$de,$e4,$ec,$f3,$fd,$05,$0f,$17
        dc.b    $21,$2a,$32,$3a,$41,$46,$4b,$4f,$53,$55,$56,$58,$58,$58,$56,$55
        dc.b    $46,$3b,$32,$2b,$24,$1e,$18,$12,$0e,$0b,$07,$04,$01,$ff,$fd,$fc
        dc.b    $fa,$f8,$f8,$f6,$f5,$f4,$f4,$f3,$f3,$f2,$f2,$f2,$f1,$f1,$ec,$e8
        dc.b    $e5,$e1,$de,$da,$d8,$d4,$d1,$cf,$cd,$ca,$c8,$c7,$c5,$c3,$c3,$c2
        dc.b    $c2,$c2,$c2,$c2,$c3,$c3,$c5,$c6,$c7,$c9,$cb,$cd,$cf,$d1,$d3,$d6
        dc.b    $d8,$db,$dd,$e0,$e3,$e7,$e9,$ec,$ef,$f2,$f5,$f8,$fb,$fe,$00,$03
        dc.b    $06,$07,$0b,$0d,$0f,$11,$13,$16,$17,$19,$1b,$1d,$1e,$20,$21,$23
        dc.b    $24,$24,$25,$26,$26,$26,$27,$27,$27,$27,$27,$26,$26,$25,$24,$24
        dc.b    $23,$21,$21,$1f,$1e,$1c,$1c,$1a,$19,$18,$16,$14,$13,$11,$10,$0e
        dc.b    $0b,$08,$03,$00,$fb,$f6,$f2,$ed,$e8,$e4,$e0,$dc,$da,$d8,$d7,$d6
        dc.b    $d7,$d8,$db,$de,$e2,$e7,$ed,$f3,$f9,$ff,$07,$0f,$17,$1f,$27,$2e
        dc.b    $33,$39,$3e,$43,$47,$49,$4c,$4d,$4e,$4e,$4e,$4c,$4b,$48,$38,$30
        dc.b    $28,$21,$1c,$16,$12,$0e,$0a,$06,$04,$01,$ff,$fd,$fc,$fa,$f8,$f8
        dc.b    $f6,$f6,$f5,$f4,$f4,$f3,$f3,$f3,$f2,$ed,$ea,$e7,$e4,$e1,$dd,$da
        dc.b    $d7,$d4,$d2,$cf,$cd,$cb,$c9,$c8,$c7,$c6,$c5,$c4,$c4,$c4,$c4,$c5
        dc.b    $c5,$c6,$c7,$c9,$ca,$cc,$cd,$cf,$d1,$d3,$d6,$d8,$da,$dd,$e0,$e3
        dc.b    $e5,$e8,$eb,$ee,$f1,$f3,$f6,$f9,$fc,$fe,$00,$03,$06,$08,$0b,$0d
        dc.b    $0f,$11,$13,$15,$17,$19,$1a,$1c,$1d,$1e,$20,$21,$22,$23,$23,$24
        dc.b    $24,$25,$25,$25,$25,$25,$25,$24,$24,$23,$22,$22,$21,$20,$1f,$1d
        dc.b    $1d,$1b,$1a,$19,$18,$16,$15,$14,$12,$11,$0f,$0e,$0b,$07,$04,$00
        dc.b    $fd,$f9,$f5,$f1,$ed,$ea,$e6,$e4,$e1,$e0,$de,$de,$de,$df,$e0,$e3
        dc.b    $e6,$ea,$ee,$f3,$f8,$fe,$04,$0a,$10,$17,$1d,$23,$29,$2f,$34,$38
        dc.b    $3c,$40,$42,$43,$45,$45,$45,$45,$44,$42,$40,$38,$2e,$27,$20,$1a
        dc.b    $15,$11,$0d,$09,$06,$04,$01,$ff,$fd,$fc,$fa,$f9,$f8,$f7,$f6,$f5
        dc.b    $f5,$f4,$f4,$f2,$ee,$eb,$e8,$e5,$e2,$e0,$dc,$d9,$d7,$d4,$d2,$d0
        dc.b    $ce,$cc,$cb,$ca,$c9,$c8,$c7,$c7,$c7,$c7,$c7,$c7,$c9,$c9,$ca,$cb
        dc.b    $cd,$ce,$cf,$d2,$d4,$d6,$d8,$da,$dd,$df,$e2,$e4,$e7,$ea,$ec,$ef
        dc.b    $f1,$f4,$f7,$f9,$fc,$fe,$01,$03,$05,$07,$0a,$0c,$0e,$10,$12,$14
        dc.b    $16,$18,$19,$1b,$1c,$1e,$1f,$20,$21,$22,$22,$23,$23,$23,$23,$24
        dc.b    $23,$23,$23,$23,$22,$22,$21,$20,$20,$1e,$1d,$1c,$1b,$1a,$19,$18
        dc.b    $16,$15,$14,$13,$11,$10,$0e,$0c,$0a,$07,$04,$01,$fe,$fb,$f8,$f4
        dc.b    $f1,$ee,$ec,$e9,$e7,$e6,$e4,$e4,$e4,$e5,$e6,$e7,$ea,$ed,$f0,$f4
        dc.b    $f8,$fd,$02,$07,$0c,$11,$17,$1b,$21,$26,$2b,$2f,$32,$36,$38,$3a
        dc.b    $3c,$3c,$3d,$3d,$3c,$3c,$3a,$38,$36,$30,$26,$20,$1a,$15,$10,$0d
        dc.b    $09,$06,$03,$01,$ff,$fe,$fc,$fb,$fa,$f8,$f8,$f7,$f6,$f5,$f3,$f0
        dc.b    $ec,$ea,$e7,$e4,$e1,$de,$db,$d9,$d7,$d5,$d2,$d1,$cf,$ce,$cc,$cc
        dc.b    $cb,$ca,$c9,$c9,$c9,$ca,$ca,$ca,$cb,$cc,$cd,$ce,$cf,$d1,$d3,$d5
        dc.b    $d6,$d8,$da,$dc,$df,$e1,$e4,$e6,$e8,$eb,$ed,$f0,$f3,$f5,$f8,$fa
        dc.b    $fc,$ff,$01,$03,$05,$07,$0a,$0c,$0e,$10,$12,$13,$15,$17,$18,$1a
        dc.b    $1b,$1c,$1d,$1e,$1f,$20,$21,$21,$21,$22,$22,$22,$22,$22,$21,$21
        dc.b    $20,$20,$1f,$1e,$1e,$1d,$1c,$1b,$1a,$19,$18,$17,$15,$14,$13,$12
        dc.b    $11,$0f,$0e,$0c,$0a,$07,$04,$02,$00,$fc,$fa,$f7,$f4,$f1,$f0,$ed
        dc.b    $ec,$ea,$e9,$e9,$e9,$e9,$ea,$eb,$ed,$ef,$f2,$f5,$f9,$fd,$ff,$05
        dc.b    $09,$0d,$12,$16,$1b,$1f,$23,$27,$2a,$2d,$30,$32,$34,$35,$36,$36
        dc.b    $36,$36,$34,$33,$31,$30,$2d,$2a,$20,$1a,$16,$11,$0e,$0a,$07,$04
        dc.b    $02,$00,$fe,$fc,$fb,$fa,$f9,$f8,$f6,$f3,$f0,$ee,$eb,$e8,$e5,$e3
        dc.b    $e0,$dd,$db,$d9,$d7,$d5,$d3,$d1,$d0,$cf,$ce,$cd,$cd,$cc,$cc,$cc
        dc.b    $cc,$cc,$cd,$cd,$ce,$cf,$cf,$d1,$d2,$d3,$d5,$d7,$d9,$db,$dc,$df
        dc.b    $e1,$e3,$e5,$e7,$ea,$ec,$ef,$f1,$f3,$f6,$f8,$fb,$fd,$ff,$01,$03
        dc.b    $06,$07,$0a,$0c,$0e,$0f,$11,$13,$14,$16,$17,$19,$1a,$1b,$1c,$1d
        dc.b    $1e,$1e,$1f,$20,$20,$20,$20,$20,$20,$20,$20,$1f,$1f,$1e,$1e,$1d
        dc.b    $1c,$1b,$1b,$19,$19,$18,$17,$15,$14,$13,$12,$11,$0f,$0e,$0d,$0b
        dc.b    $09,$07,$04,$02,$00,$fe,$fb,$f8,$f6,$f4,$f2,$f0,$f0,$ee,$ed,$ed
        dc.b    $ed,$ed,$ee,$ef,$f0,$f2,$f5,$f7,$fa,$fd,$ff,$03,$07,$0b,$0e,$12
        dc.b    $16,$19,$1d,$21,$24,$27,$29,$2b,$2d,$2e,$2f,$30,$30,$30,$2f,$2e
        dc.b    $2c,$2b,$29,$27,$25,$22,$1d,$17,$13,$0f,$0b,$08,$05,$03,$00,$ff
        dc.b    $fd,$fc,$fa,$f8,$f4,$f2,$f0,$ec,$ea,$e7,$e4,$e2,$e0,$dd,$db,$d9
        dc.b    $d8,$d6,$d4,$d3,$d2,$d1,$d0,$cf,$cf,$ce,$ce,$ce,$ce,$cf,$cf,$cf
        dc.b    $d0,$d1,$d2,$d3,$d4,$d6,$d7,$d9,$db,$dc,$de,$e0,$e3,$e5,$e7,$e9
        dc.b    $eb,$ed,$f0,$f2,$f5,$f7,$f9,$fb,$fe,$ff,$02,$04,$06,$07,$0a,$0b
        dc.b    $0e,$0f,$11,$12,$14,$15,$17,$18,$19,$1a,$1b,$1c,$1d,$1d,$1e,$1e
        dc.b    $1e,$1f,$1f,$1f,$1f,$1e,$1e,$1e,$1e,$1d,$1c,$1c,$1b,$1a,$19,$18
        dc.b    $17,$16,$16,$14,$13,$12,$11,$0f,$0f,$0e,$0c,$0a,$08,$07,$05,$03
        dc.b    $00,$fe,$fc,$fa,$f8,$f6,$f5,$f3,$f2,$f1,$f0,$f0
music_pattern_t1_p2_src:
        dc.b    $f0,$f0,$f0,$f1,$f3,$f4,$f6,$f8,$fa,$fd,$ff,$02,$05,$08,$0b,$0f
        dc.b    $12,$15,$18,$1b,$1e,$21,$23,$25,$27,$28,$29,$2a,$2a,$2a,$2a,$29
        dc.b    $29,$27,$26,$24,$22,$20,$1d,$1b,$18,$14,$12,$0f,$0b,$08,$05,$02
        dc.b    $00,$fd,$fa,$f8,$f4,$f1,$ef,$ec,$e9,$e7,$e4,$e2,$e0,$de,$dc,$da
        dc.b    $d8,$d7,$d6,$d5,$d4,$d3,$d2,$d1,$d1,$d1,$d0,$d0,$d1,$d1,$d1,$d2
        dc.b    $d3,$d3,$d5,$d6,$d7,$d8,$da,$db,$dd,$df,$e1,$e3,$e5,$e6,$e8,$eb
        dc.b    $ed,$ef,$f1,$f3,$f5,$f7,$fa,$fc,$fe,$ff,$01,$03,$06,$07,$09,$0b
        dc.b    $0d,$0e,$0f,$11,$13,$14,$15,$17,$17,$19,$1a,$1a,$1b,$1c,$1c,$1d
        dc.b    $1d,$1d,$1e,$1e,$1e,$1e,$1d,$1d,$1c,$1c,$1b,$1a,$1a,$19,$18,$17
        dc.b    $16,$16,$14,$13,$12,$11,$10,$0f,$0e,$0d,$0b,$0a,$08,$06,$04,$03
        dc.b    $01,$ff,$fd,$fc,$fa,$f8,$f7,$f5,$f4,$f3,$f3,$f2,$f3,$f2,$f3,$f4
        dc.b    $f4,$f6,$f7,$f9,$fb,$fd,$ff,$02,$04,$07,$09,$0c,$0f,$12,$14,$17
        dc.b    $19,$1c,$1e,$20,$22,$23,$24,$25,$26,$26,$26,$26,$24,$23,$22,$21
        dc.b    $1f,$1d,$1a,$18,$16,$13,$11,$0e,$0c,$08,$06,$03,$00,$fe,$fb,$f8
        dc.b    $f6,$f3,$f1,$ee,$ec,$e9,$e7,$e5,$e3,$e1,$e0,$de,$dc,$da,$d9,$d8
        dc.b    $d7,$d6,$d5,$d5,$d4,$d4,$d4,$d4,$d3,$d4,$d4,$d5,$d6,$d7,$d7,$d8
        dc.b    $d9,$db,$dc,$de,$df,$e1,$e3,$e4,$e6,$e8,$ea,$ec,$ee,$f0,$f1,$f3
        dc.b    $f6,$f8,$fa,$fc,$fe,$ff,$02,$03,$05,$07,$09,$0b,$0c,$0e,$0f,$11
        dc.b    $12,$13,$15,$16,$17,$18,$19,$19,$1a,$1b,$1b,$1c,$1c,$1c,$1c,$1c
        dc.b    $1c,$1c,$1b,$1b,$1b,$1a,$19,$19,$18,$17,$17,$16,$15,$14,$13,$12
        dc.b    $11,$10,$0f,$0e,$0d,$0c,$0a,$09,$07,$06,$04,$03,$01,$00,$fe,$fc
        dc.b    $fb,$fa,$f8,$f7,$f6,$f6,$f5,$f5,$f5,$f5,$f5,$f6,$f6,$f7,$f8,$fa
        dc.b    $fc,$fe,$ff,$01,$03,$06,$08,$0a,$0d,$0f,$11,$13,$16,$18,$1a,$1b
        dc.b    $1d,$1e,$20,$20,$21,$21,$21,$21,$21,$20,$1f,$1d,$1c,$1a,$19,$17
        dc.b    $14,$12,$10,$0e,$0b,$09,$06,$03,$01,$ff,$fc,$fa,$f7,$f5,$f2,$f0
        dc.b    $ee,$ec,$e9,$e7,$e6,$e3,$e2,$e0,$de,$dd,$dc,$db,$da,$d9,$d8,$d8
        dc.b    $d7,$d7,$d7,$d7,$d7,$d7,$d7,$d8,$d8,$d9,$da,$db,$dc,$dd,$de,$e0
        dc.b    $e1,$e3,$e4,$e6,$e8,$e9,$eb,$ed,$ef,$f1,$f2,$f4,$f6,$f8,$fa,$fc
        dc.b    $fe,$ff,$01,$03,$05,$07,$08,$0a,$0b,$0d,$0e,$0f,$11,$12,$13,$14
        dc.b    $16,$16,$17,$18,$18,$19,$19,$1a,$1a,$1b,$1b,$1a,$1b,$1a,$1a,$1a
        dc.b    $19,$19,$18,$18,$17,$16,$16,$15,$14,$13,$12,$11,$10,$0f,$0e,$0d
        dc.b    $0c,$0b,$0a,$08,$07,$06,$04,$03,$01,$00,$fe,$fd,$fc,$fa,$f9,$f8
        dc.b    $f8,$f7,$f6,$f6,$f6,$f6,$f6,$f7,$f8,$f8,$fa,$fb,$fc,$fe,$ff,$01
        dc.b    $03,$05,$07,$09,$0b,$0d,$0f,$11,$13,$14,$16,$18,$19,$1a,$1b,$1c
        dc.b    $1d,$1d,$1e,$1e,$1d,$1d,$1c,$1b,$1a,$18,$17,$15,$13,$11,$0f,$0d
        dc.b    $0b,$09,$06,$04,$01,$ff,$fd,$fb,$f8,$f6,$f4,$f2,$f0,$ee,$ec,$ea
        dc.b    $e8,$e6,$e5,$e3,$e2,$e0,$e0,$de,$dd,$dc,$db,$da,$da,$da,$da,$d9
        dc.b    $da,$da,$da,$db,$db,$dc,$dc,$dd,$de,$e0,$e1,$e2,$e3,$e4,$e6,$e7
        dc.b    $e9,$ea,$ec,$ee,$f0,$f1,$f3,$f5,$f7,$f9,$fa,$fc,$fe,$ff,$01,$03
        dc.b    $05,$06,$08,$09,$0b,$0d,$0e,$0f,$10,$12,$13,$13,$15,$16,$16,$17
        dc.b    $18,$18,$18,$19,$19,$19,$19,$19,$19,$19,$19,$18,$18,$18,$17,$16
        dc.b    $16,$15,$14,$13,$13,$12,$11,$10,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08
        dc.b    $07,$05,$04,$03,$01,$00,$ff,$fe,$fc,$fc,$fb,$fa,$f9,$f9,$f8,$f8
        dc.b    $f8,$f8,$f8,$f9,$f9,$fa,$fb,$fc,$fd,$fe,$ff,$01,$02,$04,$05,$07
        dc.b    $09,$0b,$0c,$0e,$0f,$11,$13,$14,$16,$17,$18,$18,$19,$1a,$1a,$1a
        dc.b    $1a,$1a,$19,$18,$18,$17,$15,$14,$12,$10,$0f,$0d,$0b,$09,$06,$04
        dc.b    $02,$00,$fe,$fc,$fa,$f8,$f6,$f3,$f2,$f0,$ee,$ec,$ea,$e8,$e7,$e5
        dc.b    $e4,$e3,$e2,$e1,$e0,$df,$de,$dd,$dd,$dc,$dc,$dc,$dc,$dc,$dd,$dd
        dc.b    $dd,$de,$df,$e0,$e0,$e1,$e3,$e3,$e5,$e6,$e7,$e8,$ea,$ec,$ed,$ef
        dc.b    $f0,$f2,$f4,$f5,$f7,$f9,$fb,$fc,$fe,$ff,$01,$03,$04,$06,$07,$09
        dc.b    $0a,$0b,$0d,$0e,$0f,$10,$11,$12,$13,$14,$15,$15,$16,$17,$17,$17
        dc.b    $17,$18,$18,$18,$18,$17,$17,$17,$17,$16,$16,$15,$15,$14,$13,$13
        dc.b    $12,$11,$10,$0f,$0f,$0e,$0c,$0c,$0b,$0a,$08,$07,$06,$05,$04,$02
        dc.b    $01,$00,$ff,$fe,$fd,$fc,$fc,$fb,$fa,$f9,$f9,$f9,$f9,$f9,$f9,$f9
        dc.b    $fa,$fb,$fc,$fc,$fd,$fe,$ff,$01,$02,$03,$05,$07,$07,$0a,$0b,$0c
        dc.b    $0e,$0f,$11,$12,$13,$14,$15,$16,$16,$17,$17,$17,$18,$17,$17,$16
        dc.b    $15,$15,$13,$12,$11,$0f,$0e,$0c,$0a,$08,$06,$04,$02,$00,$ff,$fd
        dc.b    $fa,$f8,$f7,$f5,$f3,$f1,$f0,$ee,$ec,$eb,$e9,$e8,$e7,$e6,$e5,$e3
        dc.b    $e3,$e2,$e1,$e0,$e0,$e0,$e0,$df,$df,$df,$df,$e0,$e0,$e0,$e1,$e1
        dc.b    $e2,$e3,$e4,$e5,$e6,$e7,$e9,$ea,$eb,$ed,$ee,$f0,$f1,$f3,$f4,$f6
        dc.b    $f8,$f9,$fb,$fc,$fe,$ff,$01,$03,$04,$05,$07,$08,$09,$0b,$0c,$0d
        dc.b    $0f,$0f,$10,$11,$12,$13,$14,$14,$15,$15,$16,$16,$17,$17,$17,$17
        dc.b    $17,$17,$16,$16,$16,$15,$15,$14,$14,$13,$12,$11,$10,$10,$0f,$0e
        dc.b    $0d,$0c,$0c,$0b,$0a,$09,$07,$07,$06,$04,$03,$02,$01,$00,$ff,$ff
        dc.b    $fe,$fd,$fc,$fc,$fb,$fb,$fb,$fa,$fa,$fa,$fa,$fb,$fb,$fc,$fc,$fd
        dc.b    $fe,$ff,$ff,$01,$02,$03,$04,$05,$07,$08,$09,$0b,$0c,$0d,$0e,$0f
        dc.b    $10,$11,$12,$13,$13,$14,$14,$15,$15,$14,$14,$14,$13,$13,$12,$11
        dc.b    $0f,$0f,$0d,$0c,$0a,$08,$07,$05,$03,$01,$ff,$fe,$fc,$fa,$f8,$f7
        dc.b    $f5,$f3,$f2,$f0,$ef,$ed,$eb,$ea,$e9,$e8,$e7,$e6,$e5,$e4,$e3,$e2
        dc.b    $e2,$e1,$e1,$e1,$e1,$e1,$e1,$e1,$e2,$e2,$e3,$e3,$e4,$e5,$e5,$e7
        dc.b    $e7,$e9,$ea,$eb,$ec,$ee,$ef,$f0,$f2,$f3,$f5,$f6,$f8,$f9,$fb,$fc
        dc.b    $fe,$ff,$01,$02,$03,$05,$06,$07,$09,$0a,$0b,$0c,$0e,$0f,$0f,$10
        dc.b    $11,$12,$13,$13,$14,$14,$15,$15,$15,$16,$16,$16,$15,$15,$15,$15
        dc.b    $14,$14,$13,$13,$13,$12,$11,$10,$10,$0f,$0e,$0e,$0d,$0c,$0b,$0a
        dc.b    $09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$ff,$ff,$fe,$fd,$fd,$fc
        dc.b    $fc,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fc,$fc,$fc,$fd,$fe,$ff,$ff,$00
        dc.b    $01,$02,$03,$05,$06,$07,$08,$09,$0b,$0c,$0c,$0e,$0f,$0f,$10,$11
        dc.b    $11,$12,$12,$12,$12,$13,$12,$12,$11,$11,$10,$0f,$0f,$0e,$0c,$0b
        dc.b    $0a,$08,$07,$05,$03,$02,$00,$ff,$fd,$fb,$f9,$f8,$f6,$f5,$f3,$f1
        dc.b    $f0,$ef,$ed,$ec,$eb,$ea,$e9,$e8,$e7,$e6,$e6,$e5,$e5,$e4,$e4,$e4
        dc.b    $e3,$e3,$e3,$e4,$e4,$e4,$e5,$e5,$e6,$e7,$e7,$e8,$e9,$ea,$eb,$ec
        dc.b    $ed,$ee,$f0,$f1,$f2,$f3,$f5,$f6,$f8,$f9,$fb,$fc,$fe,$ff,$00,$01
        dc.b    $03,$04,$06,$07,$08,$09,$0b,$0c,$0d,$0e,$0f,$0f,$11,$11,$12,$13
        dc.b    $13,$14,$14,$14,$14,$14,$14,$14,$15,$14,$14,$14,$13,$13,$13,$12
        dc.b    $12,$11,$10,$0f,$0f,$0f,$0e,$0d,$0c,$0b,$0a,$0a,$09,$08,$07,$06
        dc.b    $05,$04,$03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe,$fe,$ff,$ff,$00,$01,$02,$03,$04
        dc.b    $05,$06,$07,$08,$09,$0a,$0b,$0c,$0c,$0d,$0e,$0f,$0f,$0f,$0f,$10
        dc.b    $10,$10,$10,$10,$0f,$0f,$0f,$0e,$0e,$0d,$0c,$0a,$09,$08,$07,$06
        dc.b    $04,$02,$01,$00,$fe,$fc,$fb,$f9,$f8,$f6,$f5,$f3,$f2,$f0,$f0,$ee
        dc.b    $ed,$ec,$eb,$ea,$e9,$e8,$e7,$e7,$e7,$e6,$e6,$e5,$e5,$e5,$e6,$e5
        dc.b    $e5,$e6,$e6,$e7,$e7,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$f0,$f0,$f2
        dc.b    $f3,$f4,$f6,$f7,$f8,$fa,$fb,$fc,$fe,$ff,$00,$02,$03,$04,$06,$07
        dc.b    $08,$09,$0a,$0b,$0c,$0d,$0e,$0f,$0f,$10,$11,$11,$12,$12,$13,$13
        dc.b    $13,$13,$13,$13,$13,$13,$13,$13,$12,$12,$11,$11,$10,$10,$0f,$0f
        dc.b    $0e,$0e,$0d,$0c,$0c,$0b,$0a,$09,$08,$07,$07,$06,$05,$04,$03,$02
        dc.b    $01,$00,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fd
        dc.b    $fc,$fd,$fe,$fe,$ff,$ff,$00,$00,$01,$02,$03,$03,$04,$05,$06,$07
        dc.b    $07,$08,$09,$0a,$0b,$0c,$0c,$0d,$0d,$0e,$0e,$0e,$0e,$0f,$0f,$0e
        dc.b    $0e,$0e,$0d,$0d,$0c,$0c,$0b,$0a,$09,$07,$06,$05,$04,$03,$01,$00
        dc.b    $ff,$fd,$fc,$fa,$f9,$f8,$f6,$f5,$f4,$f2,$f1,$f0,$ef,$ee,$ed,$ec
        dc.b    $eb,$eb,$ea,$e9,$e8,$e8,$e8,$e8,$e7,$e7,$e7,$e7,$e7,$e8,$e8,$e8
        dc.b    $e9,$e9,$ea,$eb,$eb,$ec,$ed,$ee,$ef,$f0,$f1,$f2,$f3,$f5,$f6,$f7
        dc.b    $f8,$fa,$fb,$fc,$fe,$ff,$00,$01,$02,$04,$05,$06,$07,$08,$09,$0a
        dc.b    $0b,$0c,$0d,$0e,$0f,$0f,$10,$10,$11,$11,$12,$12,$12,$13,$13,$13
        dc.b    $13,$12,$12,$12,$12,$11,$11,$10,$10,$0f,$0f,$0f,$0e,$0d,$0c,$0b
        dc.b    $0b,$0a,$09,$08,$07,$07,$06,$05,$04,$03,$03,$02,$01,$00,$00,$ff
        dc.b    $ff,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$fe,$fe
        dc.b    $ff,$ff,$00,$00,$01,$01,$02,$03,$03,$04,$05,$06,$07,$07,$08,$09
        dc.b    $0a,$0a,$0b,$0b,$0c,$0c,$0c,$0d,$0d,$0d,$0d,$0d,$0d,$0c,$0c,$0c
        dc.b    $0b,$0a,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$00,$ff,$fe,$fd,$fc
        dc.b    $fa,$f9,$f8,$f7,$f6,$f4,$f3,$f2,$f1,$f0,$ef,$ee,$ed,$ec,$ec,$eb
        dc.b    $ea,$ea,$e9,$e9,$e9,$e9,$e9,$e9,$e9,$e9,$e9,$e9,$ea,$eb,$eb,$ec
        dc.b    $ec,$ed,$ee,$ef,$f0,$f0,$f2,$f3,$f3,$f5,$f6,$f8,$f8,$fa,$fb,$fc
        dc.b    $fe,$ff,$00,$01,$02,$03,$04,$06,$07,$07,$09,$0a,$0b,$0b,$0c,$0d
        dc.b    $0e,$0f,$0f,$0f,$10,$10,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
        dc.b    $11,$10,$10,$0f,$0f,$0f,$0e,$0e,$0d,$0c,$0c,$0b,$0a,$09,$09,$08
        dc.b    $07,$07,$06,$05,$04,$03,$03,$02,$01,$01,$00,$ff,$ff,$ff,$ff,$fe
        dc.b    $fe,$fe,$fe,$fe,$fd,$fd,$fe,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00
        dc.b    $00,$01,$02,$02,$03,$03,$04,$05,$06,$07,$07,$07,$08,$09,$0a,$0a
        dc.b    $0a,$0b,$0b,$0b,$0c,$0c,$0c,$0b,$0b,$0b,$0b,$0b,$0a,$09,$09,$08
        dc.b    $07,$07,$06,$05,$04,$03,$02,$01,$00,$ff,$fe,$fd,$fc,$fa,$f9,$f8
        dc.b    $f7,$f6,$f4,$f3,$f2,$f2,$f0,$f0,$ef,$ee,$ee,$ed,$ec,$ec,$ec,$eb
        dc.b    $eb,$eb,$eb,$eb,$eb,$ea,$eb,$eb,$ec,$ec,$ec,$ed,$ed,$ee,$ef,$f0
        dc.b    $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f8,$f8,$fa,$fb,$fc,$fd,$fe,$ff,$00
        dc.b    $01,$02,$03,$05,$06,$07,$07,$09,$0a,$0b,$0b,$0c,$0d,$0e,$0e,$0f
        dc.b    $0f,$0f,$10,$10,$11,$11,$11,$11,$11,$11,$10,$10,$10,$0f,$0f,$0f
        dc.b    $0f,$0e,$0e,$0d,$0c,$0c,$0b,$0a,$09,$09,$08,$07,$07,$06,$05,$05
        dc.b    $04,$03,$02,$02,$01,$00,$00,$00
music_pattern_t1_p1_src:
        dc.b    $ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$01,$01,$02,$03,$03,$03,$04,$05,$05,$06,$06,$07
        dc.b    $07,$08,$08,$09,$09,$09,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$09,$09,$09
        dc.b    $09,$08,$08,$07,$07,$06,$05,$05,$04,$03,$02,$01,$00,$ff,$fe,$fe
        dc.b    $fd,$fc,$fb,$fa,$f8,$f8,$f6,$f5,$f5,$f3,$f2,$f2,$f1,$f0,$f0,$ef
        dc.b    $ee,$ee,$ee,$ed,$ed,$ec,$ec,$ec,$ec,$ec,$ec,$ec,$ed,$ed,$ee,$ee
        dc.b    $ee,$ef,$f0,$f0,$f1,$f2,$f3,$f3,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc
        dc.b    $fd,$fe,$ff,$00,$01,$02,$03,$04,$06,$06,$07,$08,$09,$0a,$0b,$0b
        dc.b    $0c,$0d,$0d,$0e,$0e,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
        dc.b    $0f,$0f,$0e,$0e,$0e,$0d,$0c,$0c,$0c,$0b,$0a,$0a,$09,$08,$07,$07
        dc.b    $07,$06,$05,$04,$04,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$00,$00
        dc.b    $00,$01,$01,$02,$02,$03,$03,$04,$05,$05,$05,$06,$07,$07,$07,$08
        dc.b    $08,$08,$09,$09,$09,$09,$09,$09,$09,$09,$09,$08,$08,$08,$07,$07
        dc.b    $06,$06,$05,$04,$03,$03,$02,$01,$00,$00,$ff,$fe,$fd,$fc,$fb,$fa
        dc.b    $f9,$f8,$f8,$f6,$f6,$f5,$f4,$f3,$f2,$f1,$f1,$f0,$f0,$f0,$ef,$ee
        dc.b    $ee,$ee,$ee,$ee,$ee,$ee,$ee,$ee,$ee,$ee,$ef,$ef,$f0,$f0,$f1,$f1
        dc.b    $f2,$f3,$f3,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff,$00
        dc.b    $01,$02,$03,$04,$05,$06,$07,$07,$08,$09,$0a,$0b,$0b,$0c,$0c,$0d
        dc.b    $0e,$0e,$0e,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0e,$0f,$0e,$0e,$0d
        dc.b    $0d,$0d,$0c,$0c,$0b,$0a,$0a,$09,$08,$08,$07,$07,$06,$05,$04,$04
        dc.b    $03,$03,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe
        dc.b    $fe,$fe,$fe,$ff,$fe,$ff,$ff,$ff,$ff,$00,$00,$00,$01,$01,$01,$02
        dc.b    $02,$03,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07,$07,$07,$07,$07
        dc.b    $08,$08,$08,$08,$08,$07,$07,$07,$07,$07,$07,$06,$06,$05,$05,$04
        dc.b    $04,$03,$02,$01,$01,$00,$ff,$ff,$fe,$fd,$fc,$fc,$fb,$fa,$f9,$f8
        dc.b    $f8,$f6,$f6,$f5,$f4,$f4,$f3,$f2,$f2,$f1,$f1,$f0,$f0,$f0,$f0,$f0
        dc.b    $f0,$ef,$ef,$ef,$ef,$f0,$f0,$f0,$f0,$f1,$f1,$f2,$f2,$f3,$f4,$f4
        dc.b    $f5,$f6,$f7,$f8,$f9,$f9,$fb,$fc,$fd,$fe,$ff,$ff,$01,$02,$03,$04
        dc.b    $04,$05,$06,$07,$08,$09,$09,$0a,$0b,$0b,$0c,$0c,$0d,$0d,$0e,$0e
        dc.b    $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e,$0d,$0d,$0c,$0c,$0c,$0b,$0b
        dc.b    $0a,$0a,$09,$08,$08,$07,$07,$06,$06,$05,$04,$04,$03,$03,$02,$01
        dc.b    $01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$01,$01,$01,$02,$02,$03,$03
        dc.b    $03,$04,$04,$05,$05,$05,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07
        dc.b    $07,$07,$07,$07,$07,$07,$06,$06,$05,$05,$04,$04,$03,$03,$02,$01
        dc.b    $00,$00,$ff,$ff,$fe,$fd,$fc,$fc,$fb,$fa,$f9,$f9,$f8,$f7,$f7,$f6
        dc.b    $f5,$f4,$f4,$f3,$f3,$f2,$f2,$f1,$f1,$f1,$f1,$f1,$f1,$f0,$f1,$f0
        dc.b    $f1,$f1,$f1,$f1,$f2,$f2,$f3,$f3,$f4,$f4,$f5,$f6,$f7,$f7,$f8,$f9
        dc.b    $fa,$fb,$fc,$fc,$fd,$fe,$ff,$00,$00,$01,$02,$03,$04,$05,$05,$06
        dc.b    $07,$07,$08,$09,$09,$0a,$0b,$0b,$0c,$0c,$0c,$0c,$0d,$0d,$0d,$0d
        dc.b    $0d,$0d,$0d,$0d,$0d,$0d,$0c,$0c,$0c,$0b,$0b,$0a,$0a,$09,$08,$08
        dc.b    $07,$07,$06,$06,$05,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $00,$00,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04
        dc.b    $05,$05,$05,$06,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,$06
        dc.b    $06,$06,$05,$05,$05,$04,$04,$03,$03,$02,$01,$01,$00,$00,$ff,$fe
        dc.b    $fe,$fd,$fd,$fc,$fc,$fb,$fa,$f9,$f9,$f8,$f8,$f6,$f6,$f6,$f5,$f4
        dc.b    $f4,$f3,$f3,$f3,$f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2,$f2,$f3
        dc.b    $f3,$f3,$f3,$f4,$f5,$f5,$f6,$f7,$f8,$f8,$f9,$f9,$fa,$fb,$fc,$fd
        dc.b    $fe,$ff,$ff,$00,$01,$02,$03,$03,$04,$05,$06,$07,$07,$08,$08,$09
        dc.b    $0a,$0a,$0a,$0b,$0b,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
        dc.b    $0b,$0b,$0b,$0a,$0a,$0a,$09,$09,$08,$08,$07,$07,$06,$06,$05,$05
        dc.b    $04,$04,$03,$03,$03,$02,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00
        dc.b    $00,$01,$01,$01,$02,$02,$03,$03,$03,$03,$04,$04,$05,$05,$05,$05
        dc.b    $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$05,$05,$05
        dc.b    $04,$04,$03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$fe,$fd,$fd,$fc
        dc.b    $fc,$fb,$fa,$f9,$f9,$f8,$f8,$f7,$f6,$f6,$f6,$f5,$f5,$f4,$f4,$f3
        dc.b    $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3,$f4,$f4,$f4,$f5,$f6
        dc.b    $f6,$f7,$f7,$f8,$f8,$f9,$fa,$fa,$fb,$fc,$fc,$fe,$fe,$ff,$ff,$00
        dc.b    $01,$02,$03,$03,$04,$05,$05,$06,$07,$07,$07,$08,$09,$09,$0a,$0a
        dc.b    $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0c,$0b,$0b,$0b,$0b,$0b,$0b,$0a,$0a
        dc.b    $0a,$09,$09,$08,$08,$07,$07,$07,$06,$06,$05,$05,$04,$04,$03,$03
        dc.b    $02,$02,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$01,$01,$01,$02
        dc.b    $02,$03,$03,$03,$03,$04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06
        dc.b    $06,$06,$06,$06,$06,$06,$06,$06,$05,$05,$05,$04,$04,$03,$03,$03
        dc.b    $02,$02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fd,$fc,$fc,$fb,$fb,$fa
        dc.b    $f9,$f9,$f8,$f8,$f8,$f7,$f6,$f6,$f5,$f5,$f5,$f4,$f4,$f4,$f4,$f4
        dc.b    $f4,$f4,$f3,$f4,$f4,$f4,$f4,$f5,$f5,$f5,$f6,$f6,$f7,$f7,$f8,$f8
        dc.b    $f9,$f9,$fa,$fb,$fc,$fc,$fd,$fe,$fe,$ff,$00,$00,$01,$02,$02,$03
        dc.b    $04,$04,$05,$06,$06,$07,$07,$08,$08,$09,$09,$09,$0a,$0a,$0a,$0a
        dc.b    $0a,$0b,$0b,$0b,$0b,$0a,$0a,$0a,$0a,$0a,$09,$09,$09,$08,$08,$08
        dc.b    $07,$07,$07,$06,$06,$05,$05,$04,$03,$03,$03,$03,$02,$02,$01,$01
        dc.b    $01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02
        dc.b    $03,$03,$03,$03,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$05
        dc.b    $05,$05,$05,$05,$05,$04,$04,$04,$04,$03,$03,$03,$03,$02,$01,$01
        dc.b    $00,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fb,$fa,$fa,$f9,$f9,$f8
        dc.b    $f8,$f8,$f7,$f7,$f6,$f6,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5,$f5
        dc.b    $f5,$f5,$f5,$f6,$f6,$f7,$f7,$f7,$f8,$f8,$f9,$f9,$f9,$fa,$fb,$fc
        dc.b    $fc,$fd,$fe,$fe,$ff,$ff,$00,$00,$01,$02,$02,$03,$03,$04,$05,$05
        dc.b    $06,$06,$07,$07,$07,$08,$08,$09,$09,$09,$09,$09,$0a,$0a,$0a,$0a
        dc.b    $0a,$09,$09,$09,$09,$09,$09,$08,$08,$08,$07,$07,$07,$07,$06,$06
        dc.b    $05,$05,$04,$04,$03,$03,$02,$02,$02,$01,$01,$00,$00,$00,$00,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00
        dc.b    $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$03,$03,$03,$03,$04
        dc.b    $04,$04,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
        dc.b    $04,$04,$04,$03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$ff
        dc.b    $fe,$fe,$fd,$fc,$fc,$fc,$fb,$fa,$fa,$fa,$f9,$f9,$f8,$f8,$f8,$f8
        dc.b    $f8,$f7,$f7,$f7,$f6,$f6,$f6,$f6,$f6,$f6,$f6,$f6,$f6,$f6,$f7,$f7
        dc.b    $f7,$f7,$f8,$f8,$f8,$f9,$f9,$fa,$fa,$fb,$fc,$fc,$fd,$fd,$fe,$ff
        dc.b    $ff,$00,$00,$01,$01,$02,$02,$03,$03,$04,$05,$05,$06,$06,$07,$07
        dc.b    $07,$07,$08,$08,$08,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$08
        dc.b    $08,$08,$08,$08,$07,$07,$07,$06,$06,$06,$05,$05,$04,$04,$04,$03
        dc.b    $03,$02,$02,$02,$02,$01,$01,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$04,$03,$04,$04,$04
        dc.b    $04,$04,$04,$05,$05,$05,$05,$05,$05,$04,$04,$04,$04,$04,$04,$03
        dc.b    $03,$03,$02,$02,$01,$01,$01,$00,$00,$00,$ff,$ff,$fe,$fe,$fd,$fd
        dc.b    $fc,$fc,$fc,$fb,$fb,$fa,$fa,$f9,$f9,$f9,$f8,$f8,$f8,$f7,$f7,$f7
        dc.b    $f7,$f6,$f6,$f6,$f6,$f6,$f6,$f6,$f7,$f7,$f7,$f7,$f8,$f8,$f8,$f9
        dc.b    $f9,$fa,$fa,$fa,$fb,$fc,$fc,$fd,$fd,$fe,$fe,$ff,$ff,$00,$00,$01
        dc.b    $01,$02,$03,$03,$03,$04,$04,$05,$05,$06,$06,$06,$07,$07,$07,$07
        dc.b    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$07,$07,$07
        dc.b    $07,$07,$06,$06,$06,$05,$05,$04,$04,$04,$03,$03,$03,$02,$02,$01
        dc.b    $01,$01,$01,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01
        dc.b    $02,$02,$02,$02,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$04
        dc.b    $05,$04,$04,$04,$04,$04,$04,$04,$04,$03,$03,$03,$03,$02,$02,$02
        dc.b    $01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc
        dc.b    $fb,$fb,$fa,$fa,$fa,$f9,$f9,$f9,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
        dc.b    $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$f9,$f8,$f9,$f9,$f9,$fa,$fb,$fb
        dc.b    $fc,$fc,$fc,$fd,$fe,$fe,$ff,$ff,$ff,$00,$00,$01,$01,$02,$02,$02
        dc.b    $03,$03,$04,$04,$05,$05,$06,$06,$06,$07,$07,$07,$07,$07,$08,$08
        dc.b    $08,$08,$08,$08,$08,$08,$07,$07,$07,$07,$07,$07,$06,$06,$06,$06
        dc.b    $05,$05,$05,$04,$04,$03,$03,$03,$03,$02,$02,$01,$01,$01,$01,$00
        dc.b    $00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff
        dc.b    $00,$00,$ff,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02
        dc.b    $03,$03,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$04
        dc.b    $04,$03,$03,$03,$03,$03,$03,$02,$03,$02,$02,$01,$01,$01,$00,$00
        dc.b    $00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fb,$fb,$fa
        dc.b    $fa,$fa,$fa,$f9,$f9,$f9,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
        dc.b    $f8,$f9,$f9,$f9,$f9,$f9,$fa,$fa,$fb,$fb,$fc,$fc,$fc,$fc,$fd,$fe
        dc.b    $fe,$fe,$ff,$ff,$00,$00,$00,$01,$01,$02,$02,$03,$03,$03,$04,$04
        dc.b    $05,$05,$05,$06,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,$07
        dc.b    $07,$07,$07,$07,$06,$06,$06,$06,$06,$05,$05,$05,$04,$04,$04,$04
        dc.b    $03
music_pattern_t1_p4_src:
        dc.b    $03,$03,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00,$00,$00,$ff
        dc.b    $ff,$00,$ff,$ff,$ff,$ff,$00,$ff,$00,$ff,$ff,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$03,$04,$04,$03,$04,$03,$03,$03,$03,$03
        dc.b    $03,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00,$ff,$ff,$ff,$fe
        dc.b    $fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fb,$fb,$fa,$fa,$fa,$fa,$f9,$f9
        dc.b    $f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9,$fa,$fa
        dc.b    $fa,$fa,$fb,$fb,$fb,$fc,$fc,$fd,$fd,$fd,$fe,$fe,$ff,$ff,$ff,$00
        dc.b    $00,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$05,$05,$05,$06,$06
        dc.b    $06,$06,$06,$07,$07,$07,$06,$07,$07,$07,$07,$07,$07,$06,$06,$06
        dc.b    $06,$06,$06,$05,$05,$05,$05,$04,$04,$04,$03,$03,$03,$03,$02,$02
        dc.b    $01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$00,$ff,$00,$00,$ff,$00,$00,$00,$01,$01,$01,$01
        dc.b    $01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02
        dc.b    $02,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fd
        dc.b    $fd,$fd,$fc,$fc,$fc,$fb,$fb,$fb,$fb,$fa,$fa,$fa,$fa,$fa,$fa,$fa
        dc.b    $f9,$f9,$f9,$f9,$fa,$f9,$f9,$fa,$fa,$fa,$fa,$fa,$fb,$fb,$fb,$fb
        dc.b    $fc,$fc,$fc,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$01,$01,$02
        dc.b    $02,$03,$03,$03,$03,$03,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06
        dc.b    $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$05,$05,$05
        dc.b    $05,$05,$04,$04,$04,$03,$03,$03,$03,$02,$02,$02,$01,$01,$01,$01
        dc.b    $01,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$ff,$ff,$ff,$ff,$ff,$00
        dc.b    $ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01
        dc.b    $01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$01,$01,$01
        dc.b    $01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fb,$fb,$fb,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa,$fa
        dc.b    $fa,$fa,$fa,$fa,$fa,$fb,$fb,$fb,$fb,$fc,$fc,$fc,$fc,$fc,$fd,$fd
        dc.b    $fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03
        dc.b    $03,$03,$03,$03,$04,$04,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06
        dc.b    $06,$06,$06,$06,$06,$06,$06,$06,$05,$05,$05,$05,$05,$04,$04,$04
        dc.b    $03,$03,$03,$03,$03,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00
        dc.b    $00,$00,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$00,$ff,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$01,$01,$02,$02,$02,$02
        dc.b    $02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        dc.b    $03,$03,$03,$02,$02,$02,$01,$01,$01,$01,$01,$00,$00,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc
        dc.b    $fc,$fb,$fb,$fb,$fb,$fb,$fb,$fa,$fa,$fb,$fa,$fb,$fb,$fa,$fb,$fb
        dc.b    $fb,$fb,$fb,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fd,$fe,$fe,$fe,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$03,$04
        dc.b    $04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
        dc.b    $05,$05,$05,$05,$04,$04,$04,$04,$04,$03,$03,$03,$03,$03,$03,$02
        dc.b    $02,$02,$02,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$ff,$00,$00,$ff,$00,$00,$ff,$00,$ff,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$03
        dc.b    $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02
        dc.b    $02,$02,$02,$01,$01,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $fe,$fe,$fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fb,$fc,$fb,$fb
        dc.b    $fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fb,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$00,$00,$00
        dc.b    $00,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04,$04,$04
        dc.b    $04,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$04
        dc.b    $04,$04,$04,$04,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$01,$01
        dc.b    $01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$ff,$00,$ff
        dc.b    $00,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
        dc.b    $01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$03,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$01
        dc.b    $01,$01,$01,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe
        dc.b    $fe,$fe,$fd,$fd,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd
        dc.b    $fd,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$01,$01
        dc.b    $01,$02,$02,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$04,$05,$05
        dc.b    $05,$05,$05,$05,$05,$05,$04,$05,$04,$04,$04,$04,$04,$04,$04,$03
        dc.b    $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$ff,$ff,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
        dc.b    $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01
        dc.b    $00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe
; ===========================================================================
; Beathoven Synthesizer Song Data - Track 2 Sequencer & Notes.
; ===========================================================================
music_song_track_2_src:
        dc.b    $01,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$ff,$fe,$ff,$01,$01,$02
        dc.b    $04,$03,$02,$04,$03,$03,$01,$01,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$01,$01,$01,$02,$02,$03,$01,$03,$01,$01,$01,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00,$01,$02,$02,$03,$02,$03,$03
        dc.b    $03,$03,$03,$01,$02,$00,$ff,$ff,$fe,$ff,$fe,$fe,$fe,$ff,$ff,$ff
        dc.b    $00,$01,$ff,$02,$02,$02,$02,$00,$00,$01,$01,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$01,$01,$ff,$03,$01,$02,$02,$02,$01,$02,$03,$01,$01,$01
        dc.b    $00,$00,$00,$00,$ff,$00,$ff,$ff,$00,$ff,$ff,$01,$ff,$00,$01,$00
        dc.b    $00,$00,$00,$01,$00,$ff,$00,$00,$00,$03,$01,$fd,$ff,$00,$ff,$03
        dc.b    $00,$02,$03,$00,$01,$03,$01,$05,$ff,$01,$00,$ff,$fd,$01,$fe,$ff
        dc.b    $01,$ff,$01,$03,$00,$01,$03,$01,$01,$03,$01,$01,$00,$00,$ff,$00
        dc.b    $ff,$fe,$fe,$ff,$03,$fe,$ff,$00,$01,$02,$02,$02,$03,$03,$02,$04
        dc.b    $04,$01,$01,$00,$ff,$00,$ff,$fe,$fe,$fe,$fd,$fd,$fe,$fe,$ff,$ff
        dc.b    $ff,$00,$01,$01,$03,$03,$03,$02,$02,$03,$00,$01,$01,$00,$01,$00
        dc.b    $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01
        dc.b    $02,$02,$01,$01,$00,$00,$00,$01,$00,$ff,$00,$ff,$01,$00,$ff,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$01,$01,$02,$03,$02
        dc.b    $03,$02,$03,$02,$01,$01,$00,$01,$ff,$ff,$ff,$fe,$ff,$ff,$00,$ff
        dc.b    $01,$02,$02,$03,$03,$04,$03,$05,$04,$03,$03,$02,$01,$00,$00,$fe
        dc.b    $fe,$fd,$fd,$fd,$fe,$ff,$fe,$fe,$ff,$01,$00,$01,$03,$01,$03,$03
        dc.b    $03,$03,$00,$02,$00,$01,$02,$00,$ff,$ff,$ff,$00,$00,$00,$01,$00
        dc.b    $00,$00,$00,$01,$01,$ff,$00,$00,$ff,$00,$ff,$ff,$00,$00,$02,$03
        dc.b    $02,$02,$01,$03,$04,$03,$02,$02,$00,$00,$00,$00,$fe,$ff,$fe,$fe
        dc.b    $ff,$ff,$ff,$ff,$ff,$00,$02,$00,$02,$02,$02,$02,$01,$02,$00,$00
        dc.b    $00,$ff,$00,$ff,$ff,$ff,$ff,$00,$00,$00,$01,$00,$01,$01,$02,$02
        dc.b    $01,$00,$01,$01,$ff,$00,$ff,$ff,$ff,$ff,$00,$01,$01,$01,$01,$01
        dc.b    $02,$03,$01,$03,$02,$02,$03,$01,$00,$ff,$fe,$fd,$ff,$fd,$fe,$fe
        dc.b    $fd,$fe,$ff,$00,$01,$02,$02,$03,$03,$02,$03,$02,$02,$01,$01,$01
        dc.b    $00,$ff,$fe,$fd,$fd,$fe,$fe,$ff,$fe,$ff,$00,$02,$01,$02,$03,$03
        dc.b    $03,$03,$03,$03,$03,$02,$02,$01,$00,$ff,$ff,$ff,$ff,$00,$ff,$ff
        dc.b    $00,$00,$01,$01,$01,$01,$00,$02,$02,$01,$00,$00,$ff,$ff,$fe,$ff
        dc.b    $ff,$ff,$fe,$ff,$ff,$00,$ff,$00,$03,$02,$01,$02,$03,$01,$01,$02
        dc.b    $00,$01,$00,$00,$00,$00,$fe,$00,$00,$00,$00,$00,$01,$03,$01,$02
        dc.b    $02,$01,$02,$01,$01,$01,$00,$ff,$00,$fe,$fe,$ff,$ff,$ff,$ff,$ff
        dc.b    $fe,$00,$01,$00,$01,$01,$00,$02,$01,$01,$01,$01,$01,$00,$01,$01
        dc.b    $00,$00,$00,$00,$01,$00,$01,$01,$01,$02,$01,$01,$01,$01,$00,$00
        dc.b    $00,$ff,$fe,$ff,$ff,$ff,$00,$ff,$01,$01,$00,$01,$01,$02,$04,$01
        dc.b    $01,$00,$00,$00,$ff,$ff,$fe,$fd,$fd,$fe,$fe,$fe,$ff,$00,$01,$02
        dc.b    $03,$03,$04,$05,$05,$06,$05,$05,$05,$04,$04,$01,$00,$ff,$fd,$fd
        dc.b    $fe,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$01,$01,$00,$02,$01,$02,$02,$02
        dc.b    $01,$02,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$02,$03
        dc.b    $02,$03,$04,$03,$03,$03,$03,$02,$00,$01,$00,$00,$00,$ff,$ff,$fe
        dc.b    $ff,$fe,$fe,$ff,$ff,$ff,$00,$01,$01,$00,$01,$ff,$00,$01,$00,$ff
        dc.b    $00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$01,$00,$01,$03,$02,$03
        dc.b    $03,$02,$06,$03,$03,$01,$00,$03,$03,$00,$00,$02,$ff,$ff,$00,$00
        dc.b    $00,$01,$ff,$00,$02,$01,$01,$00,$00,$00,$ff,$00,$ff,$00,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$01,$00,$01,$01,$02,$02,$03,$02,$02,$02,$ff,$fe
        dc.b    $f6,$d4,$80,$bf,$7f,$c0,$80,$80,$7f,$80,$bf,$7f,$80,$80,$70,$80
        dc.b    $7f,$70,$80,$bf,$7f,$80,$7f,$40,$80,$80,$7f,$80,$60,$7f,$7f,$7f
        dc.b    $80,$60,$81,$13,$90,$7f,$7f,$80,$9f,$7f,$80,$78,$7f,$7f,$80,$00
        dc.b    $78,$bf,$ff,$80,$40,$7a,$ff,$70,$7f,$7f,$e3,$7f,$7f,$75,$6a,$60
        dc.b    $56,$4d,$46,$40,$38,$32,$2e,$29,$25,$21,$1e,$80,$23,$20,$28,$27
        dc.b    $36,$80,$00,$bf,$80,$80,$80,$80,$80,$80,$80,$80,$81,$8e,$99,$a4
        dc.b    $ad,$b6,$be,$c5,$cb,$cf,$d5,$d9,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
        dc.b    $7f,$7f,$76,$6a,$60,$40,$8f,$80,$80,$80,$80,$80,$80,$80,$80,$80
        dc.b    $8d,$99,$a4,$ad,$b6,$bd,$c4,$ca,$cf,$d5,$d9,$dd,$e1,$e4,$e7,$ea
        dc.b    $ec,$ee,$f0,$f2,$f3,$7f,$48,$5f,$d3,$d7,$78,$d5,$7f,$7e,$7f,$a7
        dc.b    $00,$b5,$bc,$df,$c0,$00,$ae,$7f,$7f,$7f,$7f,$7f,$78,$7f,$7f,$7f
        dc.b    $78,$6c,$61,$58,$4f,$47,$40,$39,$34,$2f,$2a,$26,$22,$1e,$1c,$18
        dc.b    $16,$14,$80,$27,$df,$80,$f0,$80,$80,$80,$80,$80,$80,$9f,$80,$70
        dc.b    $80,$80,$df,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$75,$6a,$60,$54,$4c,$44
        dc.b    $40,$38,$32,$2d,$28,$24,$20,$9f,$20,$00,$20,$97,$20,$80,$80,$80
        dc.b    $80,$80,$80,$80,$80,$80,$80,$8b,$97,$a3,$ac,$b4,$7f,$7f,$7f,$7f
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$74,$69,$60,$55,$4c,$44,$40,$38,$32,$80
        dc.b    $bb,$80,$80,$88,$80,$00,$a0,$3f,$bf,$93,$00,$80,$80,$80,$80,$87
        dc.b    $93,$9e,$a7,$b1,$b9,$bf,$c7,$cd,$d2,$d7,$da,$7f,$77,$7f,$7f,$7f
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$74,$68,$5c,$54,$4b,$80,$b4,$80,$80,$80
        dc.b    $80,$a0,$9e,$80,$70,$80,$80,$83,$8f,$9c,$a7,$af,$b7,$bf,$c6,$cc
        dc.b    $d1,$d6,$da,$de,$e2,$e5,$7f,$7e,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
        dc.b    $7f,$74,$68,$5c,$54,$4b,$1f,$40,$80,$80,$80,$80,$80,$80,$80,$80
        dc.b    $80,$f8,$83,$85,$8f,$9c,$a6,$af,$b8,$bf,$7f,$50,$7f,$7f,$7f,$7f
        dc.b    $73,$7f,$7f,$7f,$7f,$7a,$6e,$63,$58,$50,$47,$40,$3a,$34,$2f,$2a
        dc.b    $8f,$80,$80,$80,$80,$80,$80,$80,$80,$80,$83,$8f,$9b,$a6,$af,$b7
        dc.b    $be,$c5,$cb,$d1,$d6,$da,$de,$e1,$e5,$e7,$ea,$ed,$ef,$f0,$f2,$f4
        dc.b    $f5,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7e,$72,$66,$5c,$52
        dc.b    $4a,$43,$3c,$36,$30,$ff,$88,$80,$80,$80,$80,$80,$80,$80,$80,$80
        dc.b    $82,$8f,$9a,$a4,$ae,$b6,$bd,$c5,$cb,$cf,$d4,$d9,$dd,$7f,$7f,$7f
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7c,$70,$64,$59,$50,$48,$41,$3b,$34
        dc.b    $30,$10,$20,$00,$a0,$80,$80,$80,$80,$80,$80,$80,$80,$80,$86,$93
        dc.b    $9d,$a7,$b1,$b8,$bf,$c7,$cd,$d2,$d7,$db,$df,$e3,$e6,$e8,$eb,$7f
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7c,$70,$65,$5a,$52,$4a,$42
        dc.b    $3b,$35,$30,$2c,$27,$df,$b8,$87,$80,$80,$80,$80,$80,$80,$80,$80
        dc.b    $80,$86,$93,$9e,$a7,$b1,$b9,$bf,$c7,$cc,$d1,$d6,$da,$de,$e2,$ff
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$78,$6c,$60,$56,$4d,$46
        dc.b    $40,$38,$33,$2d,$29,$25,$21,$00,$00,$90,$80,$80,$80,$80,$80,$80
        dc.b    $80,$80,$80,$81,$8e,$99,$a5,$ae,$b6,$be,$c5,$cb,$d0,$d5,$da,$dd
        dc.b    $e1,$e5,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$78,$6c,$62
        dc.b    $57,$4e,$46,$40,$39,$33,$2e,$29,$25,$22,$80,$d0,$80,$80,$80,$80
        dc.b    $80,$80,$80,$80,$80,$81,$8d,$99,$a3,$ad,$b6,$bd,$c3,$ca,$cf,$d4
        dc.b    $d9,$dd,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$78,$6c,$60,$58
        dc.b    $4e,$46,$40,$39,$33,$2e,$2a,$25,$21,$1e,$00,$1a,$c0,$80,$80,$80
        dc.b    $80,$80,$80,$80,$80,$80,$80,$80,$8b,$97,$a3,$ac,$b5,$bc,$c3,$c9
        dc.b    $cf,$d4,$d9,$dd,$e1,$e3,$e7,$e9,$7f,$7f,$70,$7f,$7f,$7f,$7f,$7f
        dc.b    $7f,$7f,$7f,$7e,$70,$66,$5b,$52,$4a,$43,$3c,$36,$30,$2c,$27,$23
        dc.b    $20,$1c,$19,$17,$14,$12,$b0,$80,$80,$80,$80,$80,$80,$80,$80,$80
        dc.b    $80,$81,$8e,$9a,$a5,$ad,$b6,$bd,$c4,$cb,$cf,$d5,$d9,$dd,$de,$ff
        dc.b    $7f,$60,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$75,$6a,$60,$56,$4d
        dc.b    $45,$40,$38,$32,$2d,$13,$26,$22,$1e,$1b,$18,$16,$14,$12,$10,$0f
        dc.b    $f0,$d0,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$8a,$96,$9f
        dc.b    $ab,$b3,$bb,$c3,$c9,$ce,$d3,$d8,$dc,$ef,$38,$48,$7f,$7f,$7f,$7f
        dc.b    $7f,$7f,$7f,$7f,$7f,$7e,$72,$68,$5c,$53,$4c,$44,$3c,$36,$31,$04
        dc.b    $f2,$a8,$9d,$80,$80,$83,$8e,$b7,$b7,$ee,$a8,$bf,$b0,$b8,$90,$80
        dc.b    $80,$80,$80,$80,$8b,$97,$a3,$ac,$b5,$bc,$c3,$ca,$cf,$d4,$d9,$dd
        dc.b    $e1,$e4,$e7,$ea,$ec,$ee,$f7,$1f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
        dc.b    $7f,$7f,$7f,$7f,$78,$6c,$61,$58,$4e,$46,$40,$39,$f0,$f7,$ca,$d0
        dc.b    $80,$a8,$80,$81,$86,$84,$9f,$82,$b7,$d7,$ce,$cf,$f3,$df,$ef,$f0
        dc.b    $ec,$e4,$d0,$b3,$97,$80,$80,$8d,$97,$aa,$ac,$b5,$bc,$c3,$c9,$cf
        dc.b    $d4,$d8,$dc,$e0,$e3,$e6,$10,$ff,$6f,$68,$7f,$7f,$7f,$7f,$7f,$7f
        dc.b    $7f,$7f,$7f,$7f,$7f,$76,$6a,$60,$56,$4e,$46,$40,$1c,$08,$01,$d3
        dc.b    $c8,$bf,$c8,$a2,$a8,$98,$87,$82,$80,$97,$8f,$8f,$cf,$d7,$cc,$e7
        dc.b    $fa,$0c,$fa,$e2,$d1,$e3,$d6,$df,$d5,$f4,$d8,$e1,$b6,$bf,$d3,$df
        dc.b    $c0,$b7,$b8,$9f,$b0,$af,$b7,$e6,$c3,$00,$ff,$ff,$4c,$2f,$60,$75
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7d,$67,$65,$5a,$52,$4a
        dc.b    $02,$36,$e1,$f4,$e7,$dc,$af,$c3,$bf,$9c,$aa,$97,$b5,$c7,$a8,$cf
        dc.b    $b7,$af,$af,$b7,$cb,$d0,$ef,$04,$0c,$f0,$13,$04,$f3,$fb,$00,$f1
        dc.b    $f7,$03,$f6,$00,$e4,$d8,$b2,$a4,$a3,$b0,$bf,$d0,$d1,$9b,$bb,$b3
        dc.b    $db,$f6,$1f,$3f,$57,$1f,$3f,$2b,$30,$40,$54,$6d,$7f,$7f,$57,$50
        dc.b    $1f,$13,$1b,$f3,$28,$28,$1f,$44,$47,$3f,$3e,$27,$20,$2f,$20,$18
        dc.b    $ff,$ff,$04,$1f,$12,$ef,$00,$e0,$ce,$f0,$af,$97,$b7,$cb,$f0,$f8
        dc.b    $d0,$c8,$ed,$b0,$af,$e5,$b0,$ef,$d0,$cf,$d5,$d5,$c0,$bf,$b8,$af
        dc.b    $bd,$c0,$cc,$f0,$e0,$ff,$00,$07,$14,$0c,$03,$30,$07,$0d,$2a,$30
        dc.b    $30,$2a,$40,$42,$4e,$60,$66,$77,$68,$6f,$64,$4f,$40,$3b,$33,$20
        dc.b    $0c,$ff,$09,$00,$fd,$0f,$3f,$63,$48,$57,$50,$54,$44,$32,$ff,$f8
        dc.b    $f8,$e8,$e6,$c8,$f8,$9f,$c0,$80,$80,$80,$88,$8c,$81,$88,$b7,$b1
        dc.b    $bc,$c5,$d1,$0a,$ef,$1e,$2f,$18,$10,$f3,$ea,$0f,$00,$2f,$24,$fb
        dc.b    $08,$da,$fc,$fe,$00,$0c,$13,$20,$0d,$0f,$03,$00,$f2,$e0,$f0,$08
        dc.b    $02,$e1,$e8,$ed,$e7,$04,$0f,$0f,$27,$38,$17,$0d,$17,$37,$30,$2c
        dc.b    $20,$44,$24,$2f,$30,$2f,$2c,$2c,$27,$20,$40,$24,$40,$20,$29,$1c
        dc.b    $17,$29,$04,$f8,$d6,$d8,$af,$b0,$9f,$b3,$c4,$ef,$d8,$f0,$d5,$dc
        dc.b    $ff,$e5,$00,$ff,$30,$2f,$18,$08,$0f,$1c,$f6,$ef,$0b,$d8,$d7,$c0
        dc.b    $b7,$d7,$cd,$e3,$d3,$d0,$cc,$df,$d8,$d0,$d7,$e0,$ec,$d4,$df,$e7
        dc.b    $ec,$f5,$10,$1d,$1f,$30,$50,$34,$38,$2b,$1f,$22,$3f,$3f,$57,$49
        dc.b    $58,$2d,$33,$39,$34,$1b,$30,$0c,$fe,$11,$ff,$07,$17,$32,$17,$30
        dc.b    $23,$2e,$30,$16,$00,$e4,$db,$f0,$f7,$d0,$ef,$ec,$e7,$f0,$d2,$cf
        dc.b    $c2,$bb,$db,$cb,$bc,$c7,$d3,$c7,$cc,$e7,$e8,$f6,$ea,$f3,$f9,$fe
        dc.b    $f4,$f7,$0e,$eb,$db,$df,$fc,$f7,$00,$fb,$f5,$ec,$ef,$fc,$05,$ea
        dc.b    $ff,$ef,$00,$f8,$fd,$01,$ed,$12,$fa,$1f,$40,$37,$33,$23,$35,$18
        dc.b    $11,$17,$2a,$2f,$4d,$4e,$40,$43,$47,$40,$15,$18,$19,$07,$2a,$05
        dc.b    $f3,$04,$09,$04,$02,$ec,$ec,$c4,$c0,$be,$dc,$d0,$ba,$e0,$d3,$d6
        dc.b    $cf,$ee,$e8,$ff,$0b,$1c,$13,$32,$13,$1c,$10,$18,$22,$03,$10,$08
        dc.b    $ff,$00,$df,$ce,$c0,$b5,$e7,$e8,$ce,$d8,$df,$b8,$cf,$ec,$e4,$ff
        dc.b    $16,$07,$0f,$0c,$00,$0b,$00,$08,$00,$27,$f3,$0e,$0f,$11,$27,$26
        dc.b    $05,$07,$17,$10,$15,$23,$1f,$50,$33,$30,$2f,$22,$2f,$2b,$0f,$13
        dc.b    $0f,$10,$04,$f1,$00,$e7,$09,$ed,$ff,$0e,$0e,$0a,$07,$0a,$2c,$08
        dc.b    $10,$00,$ff,$0a,$f3,$ff,$fb,$fb,$ff,$10,$f8,$e8,$e0,$e8,$f0,$e8
        dc.b    $f7,$f0,$f0,$f2,$ef,$ec,$d1,$e0,$e8,$f4,$d9,$08,$e1,$e4,$f4,$f0
        dc.b    $e6,$e7,$e3,$eb,$ff,$00,$00,$ff,$eb,$eb,$22,$0c,$17,$17,$28,$38
        dc.b    $1c,$26,$25,$2e,$1b,$18,$16,$1d,$0f,$14,$27,$1c,$1f,$08,$fa,$df
        dc.b    $d5,$db,$ef,$00,$db,$c0,$b9,$e1,$c8,$e4,$e7,$d0,$08,$f6,$e7,$e4
        dc.b    $db,$e7,$d9,$ef,$df,$ff,$ef,$03,$3f,$11,$40,$44,$20,$25,$1f,$20
        dc.b    $33,$38,$2b,$21,$29,$19,$20,$18,$37,$58,$05,$18,$20,$16,$ff,$f8
        dc.b    $06,$04,$e7,$f6,$e7,$e5,$f0,$db,$e0,$b7,$ec,$de,$e0,$d8,$bf,$ba
        dc.b    $c0,$df,$c7,$b0,$af,$d6,$ce,$ec,$ff,$ec,$eb,$ff,$08,$1b,$37,$40
        dc.b    $1c,$3f,$2a,$28,$15,$1f,$20,$25,$35,$0c,$20,$02,$2c,$2b,$38,$38
        dc.b    $20,$1f,$04,$11,$14,$0b,$28,$00,$f4,$28,$05,$22,$22,$2b,$0f,$ff
        dc.b    $fd,$f5,$e8,$cc,$db,$f4,$da,$c3,$e0,$e0,$cf,$10,$e8,$ef,$df,$d7
        dc.b    $d7,$c7,$e7,$00,$12,$21,$41,$4f,$34,$2b,$40,$28,$0f,$1f,$20,$32
        dc.b    $f2,$10,$15,$0b,$00,$f4,$ef,$00,$0b,$ff,$2c,$0f,$ff,$ff,$ef,$00
        dc.b    $ff,$e7,$e8,$b8,$bc,$d0,$b0,$c0,$e0,$f4,$c8,$ff,$ff,$f4,$ed,$e8
        dc.b    $2b,$f7,$ff,$1f,$f1,$24,$27,$18,$03,$21,$3f,$ff,$fc,$0f,$10,$d7
        dc.b    $1c,$00,$ef,$33,$ff,$00,$ff,$06,$ef,$d6,$ff,$df,$d0,$cf,$df,$bf
        dc.b    $d7,$d6,$f0,$f0,$f8,$bf,$d0,$d5,$ef,$ea,$12,$00,$ff,$0a,$17,$2f
        dc.b    $17,$2f,$1f,$0f,$3b,$24,$2b,$08,$40,$1e,$60,$3f,$50,$5b,$3e,$30
        dc.b    $43,$3c,$10,$08,$eb,$00,$de,$d8,$e0,$d0,$ea,$df,$f2,$ef,$c7,$e0
        dc.b    $d0,$c0,$f2,$cf,$c4,$df,$ef,$ca,$d7,$bf,$ef,$f3,$f7,$ff,$e7,$03
        dc.b    $d0,$20,$0f,$10,$2f,$15,$04,$13,$35,$76,$18,$3f,$30,$f0,$0a,$fc
        dc.b    $fb,$ef,$d7,$e4,$08,$f7,$e0,$1b,$02,$e0,$ff,$f9,$ec,$0b,$ff,$00
        dc.b    $ef,$24,$e4,$b6,$40,$c4,$e4,$ef,$ff,$ff,$14,$14,$e0,$e7,$ff,$00
        dc.b    $e7,$24,$0c,$00,$37,$fb,$10,$ed,$f9,$06,$f2,$0a,$54,$18,$00,$f2
        dc.b    $19,$22,$40,$38,$14,$10,$24,$e3,$10,$e0,$10,$08,$f8,$f5,$00,$00
        dc.b    $20,$00,$0f,$25,$12,$03,$03,$00,$18,$f7,$fc,$f7,$e3,$00,$08,$db
        dc.b    $ff,$bb,$b8,$bf,$e2,$dd,$0f,$00,$fa,$11,$e0,$f0,$fc,$e0,$18,$dd
        dc.b    $ff,$ff,$0e,$eb,$1e,$e8,$0f,$0c,$fd,$40,$2d,$30,$30,$3f,$33,$20
        dc.b    $0f,$00,$18,$20,$40,$1f,$38,$0f,$27,$ec,$ff,$cf,$ff,$b7,$ca,$ff
        dc.b    $cf,$f4,$ff,$e8,$e8,$a3,$e2,$0c,$e7,$2f,$08,$ec,$e1,$e8,$fc,$d0
        dc.b    $ff,$fb,$17,$e8,$e4,$f8,$f0,$07,$25,$e3,$07,$d5,$00,$17,$e3,$08
        dc.b    $1f,$1b,$17,$4a,$30,$fb,$20,$20,$20,$f5,$53,$10,$f8,$ef,$17,$d7
        dc.b    $ff,$ef,$e8,$df,$be,$f0,$e0,$ee,$df,$ee,$df,$0c,$09,$fe,$ea,$f4
        dc.b    $e7,$df,$04,$e7,$27,$fb,$00,$e3,$00,$14,$14,$e7,$08,$06,$ff,$10
        dc.b    $0e,$10,$27,$08,$18,$37,$30,$5d,$27,$30,$e8,$ef,$d8,$ef,$f7,$cf
        dc.b    $00,$fb,$f0,$08,$00,$ff,$00,$f3,$df,$00,$df,$fb,$d3,$e7,$e7,$1f
        dc.b    $2f,$00,$2d,$28,$ec,$ef,$17,$10,$ff,$1a,$ef,$d7,$f0,$f7,$c5,$1f
        dc.b    $1f,$bb,$20,$da,$d2,$c0,$e4,$b9,$01,$f4,$fb,$ff,$e0,$df,$2f,$fb
        dc.b    $e8,$1f,$f0,$ef,$0f,$01,$14,$eb,$08,$2b,$1c,$24,$3f,$07,$28,$48
        dc.b    $01,$f0,$08,$ff,$f0,$10,$ef,$0f,$01,$fd,$04,$14,$32,$fd,$00,$e8
        dc.b    $e3,$e0,$17,$00,$18,$1f,$10,$fc,$ff,$0f,$ff,$f3,$00,$ff,$11,$04
        dc.b    $f3,$00,$ec,$00,$ff,$0b,$08,$ff,$e1,$dc,$b8,$f7,$a9,$e0,$df,$e8
        dc.b    $d1,$dd,$db,$fb,$ef,$0f,$f0,$f7,$38,$fb,$37,$4c,$06,$08,$25,$f3
        dc.b    $ff,$18,$10,$1f,$30,$e7,$1f,$27,$10,$30,$ff,$c0,$ed,$10,$c0,$cf
        dc.b    $dc,$c8,$f0,$e7,$b1,$cf,$02,$00,$d9,$1f,$04,$fa,$dd,$00,$ff,$ff
        dc.b    $1f,$14,$2f,$3c,$20,$fa,$10,$1f,$f7,$5b,$2d,$00,$08,$14,$e1,$e9
        dc.b    $f8,$df,$03,$e7,$10,$00,$fd,$00,$e0,$ff,$0f,$e0,$f6,$d9,$c8,$df
        dc.b    $d0,$ab,$0f,$d8,$db,$ef,$f7,$00,$34,$0b,$50,$0f,$6f,$01,$ff,$24
        dc.b    $17,$4f,$1a,$0c,$db,$f3,$08,$10,$0b,$08,$df,$ff,$1f,$f3,$df,$ff
        dc.b    $0a,$e7,$05,$1f,$f7,$e4,$c6,$bf,$e3,$c7,$c4,$c7,$dd,$df,$f0,$df
        dc.b    $db,$10,$f7,$1b,$00,$40,$4b,$40,$40,$ff,$0c,$fc,$00,$40,$14,$d0
        dc.b    $00,$17,$00,$e0,$20,$d7,$f0,$f5,$f3,$f0,$df,$f7,$df,$30,$ef,$e7
        dc.b    $f0,$ef,$e3,$13,$df,$f4,$0d,$00,$0f,$1f,$f5,$00,$10,$00,$0f,$18
        dc.b    $cf,$16,$0f,$e0,$32,$20,$17,$17,$ff,$18,$00,$ff,$f4,$20,$00,$04
        dc.b    $00,$e7,$00,$17,$00,$00,$0f,$e8,$e8,$d7,$e3,$df,$dd,$00,$d8,$e0
        dc.b    $00,$10,$0b,$0d,$2d,$f7,$1e,$40,$00,$08,$ff,$00,$ff,$fb,$e0,$1f
        dc.b    $1f,$00,$18,$1f,$00,$00,$00,$f6,$ef,$08,$e3,$f1,$04,$ef,$ef,$28
        dc.b    $f4,$c8,$00,$17,$e8,$10,$ec,$f4,$10,$02,$0a,$03,$20,$1f,$17,$d8
        dc.b    $18,$07,$17,$00,$07,$29,$01,$1f,$ea,$f7,$d7,$cf,$da,$c4,$e7,$f0
        dc.b    $ef,$ef,$eb,$07,$fb,$1f,$17,$3c,$20,$3f,$00,$f7,$00,$0f,$27,$0f
        dc.b    $47,$1f,$00,$38,$23,$30,$38,$0f,$0c,$f4,$ef,$00,$df,$f7,$d0,$f9
        dc.b    $e7,$fb,$cd,$ef,$f8,$df,$c8,$e0,$c6,$e3,$e1,$d7,$ef,$c8,$f0,$ef
        dc.b    $fb,$ef,$0b,$1f,$10,$08,$ff,$00,$30,$20,$0f,$23,$f0,$28,$10,$ff
        dc.b    $f3,$10,$26,$ef,$02,$24,$10,$2e,$f8,$ff,$27,$f7,$18,$0c,$20,$10
        dc.b    $ef,$00,$f4,$df,$ff,$fa,$d7,$f3,$04,$cf,$e3,$e7,$04,$e0,$f7,$14
        dc.b    $cc,$e4,$00,$cf,$df,$e0,$df,$18,$08,$17,$00,$10,$f7,$07,$1e,$ff
        dc.b    $06,$28,$f7,$2d,$28,$2f,$40,$02,$2d,$25,$27,$0a,$f7,$ed,$0b,$07
        dc.b    $c7,$0f,$fc,$d3,$06,$e0,$db,$e8,$00,$f0,$bf,$e0,$e4,$d7,$e8,$e0
        dc.b    $ee,$ff,$d0,$14,$f3,$df,$1c,$0c,$14,$0b,$18,$20,$10,$15,$0c,$27
        dc.b    $00,$2b,$0f,$ef,$3f,$20,$1f,$2f,$31,$12,$00,$ff,$18,$ff,$fb,$00
        dc.b    $00,$e0,$27,$d7,$14,$f8,$f7,$0b,$f0,$df,$e9,$08,$c1,$f4,$00,$ec
        dc.b    $f4,$e9,$f4,$ef,$17,$10,$f0,$f7,$f8,$e7,$0a,$e0,$eb,$0c,$e7,$18
        dc.b    $27,$f0,$2c,$18,$10,$1b,$17,$1a,$ff,$05,$10,$fb,$f0,$f0,$df,$ec
        dc.b    $fb,$ff,$00,$10,$f8,$ff,$10,$10,$20,$e4,$00,$e5,$ff,$e0,$08,$ff
        dc.b    $00,$14,$e8,$fc,$e0,$ec,$e0,$07,$09,$e8,$e5,$e8,$f8,$17,$f9,$ff
        dc.b    $36,$1a,$2b,$2e,$17,$10,$30,$10,$01,$10,$df,$d2,$cc,$dc,$eb,$fc
        dc.b    $1f,$0f,$1a,$18,$f7,$ff,$10,$ff,$0f,$20,$f9,$15,$15,$06,$f3,$ed
        dc.b    $00,$f7,$07,$10,$ff,$d7,$00,$e6,$ff,$00,$08,$0f,$09,$00,$10,$ff
        dc.b    $10,$32,$37,$10,$0a,$00,$ff,$20,$ff,$e3,$07,$08,$f7,$e0,$ff,$d6
        dc.b    $f0,$e6,$f5,$ea,$16,$10,$16,$f8,$ef,$f4,$fb,$07,$00,$1b,$10,$0f
        dc.b    $08,$26,$fb,$02,$0f,$00,$f5,$18,$ef,$ef,$0b,$10,$e7,$ff,$00,$f2
        dc.b    $df,$f0,$fb,$ff,$00,$24,$20,$0f,$f4,$f3,$ed,$0d,$0a,$f9,$0c,$f0
        dc.b    $00,$f2,$cf,$00,$08,$e3,$f0,$e0,$ea,$f0,$02,$fe,$00,$ff,$2d,$0f
        dc.b    $0f,$3c,$1f,$32,$14,$05,$03,$00,$df,$17,$ff,$f0,$1e,$07,$e5,$07
        dc.b    $ff,$10,$16,$f8,$00,$1e,$00,$06,$f8,$fb,$08,$f7,$00,$f0,$eb,$00
        dc.b    $d4,$db,$e4,$d6,$e9,$df,$f7,$ec,$f7,$f1,$ff,$18,$19,$01,$1e,$14
        dc.b    $ff,$f9,$1d,$26,$27,$15,$00,$fb,$05,$0f,$2f,$18,$10,$00,$fb,$ec
        dc.b    $05,$07,$ea,$0c,$f0,$f8,$0b,$f9,$f5,$09,$14,$f3,$eb,$ff,$e8,$df
        dc.b    $ea,$fe,$f2,$ff,$06,$12,$ff,$18,$0f,$0b,$04,$f8,$06,$0f,$06,$34
        dc.b    $04,$ee,$07,$04,$fb,$08,$00,$fc,$eb,$e8,$e4,$f0,$db,$03,$00,$27
        dc.b    $11,$fa,$00,$0c,$f7,$0f,$10,$0b,$03,$08,$0c,$ff,$17,$12,$0f,$06
        dc.b    $f7,$1c,$23,$06,$05,$f2,$ea,$f4,$ea,$e8,$d9,$e5,$e6,$eb,$fa,$e6
        dc.b    $0a,$00,$f3,$fd,$f0,$f8,$e3,$e3,$f0,$f4,$ff,$ed,$0a,$fb,$03,$0d
        dc.b    $0f,$09,$0d,$f3,$1b,$20,$1b,$35,$40,$37,$4b,$38,$24,$25,$10,$0f
        dc.b    $10,$07,$00,$db,$e5,$f3,$e8,$d6,$c9,$e5,$e2,$ef,$f4,$e8,$e0,$e7
        dc.b    $ed,$f0,$f7,$fd,$28,$1b,$20,$14,$23,$0c,$03,$10,$00,$f8,$f5,$05
        dc.b    $04,$07,$00,$fe,$ff,$17,$2b,$1e,$24,$1f,$06,$02,$10,$0f,$f8,$f6
        dc.b    $f5,$e8,$ff,$00,$f8,$0a,$f8,$e8,$e9,$ed,$dc,$e6,$e7,$d8,$f6,$f3
        dc.b    $f4,$f5,$ea,$e8,$fa,$f7,$fc,$fa,$09,$02,$00,$0d,$fc,$0b,$1a,$ff
        dc.b    $1c,$32,$08,$19,$1b,$14,$f1,$02,$fc,$0b,$0e,$07,$f4,$fc,$eb,$fb
        dc.b    $ff,$f8,$f3,$ff,$f9,$03,$08,$ef,$26,$20,$08,$00,$fb,$00,$ff,$f3
        dc.b    $f8,$06,$0f,$ff,$10,$ff,$09,$10,$03,$0e,$04,$07,$1c,$18,$ff,$00
        dc.b    $00,$07,$0c,$04,$fa,$f5,$00,$f1,$ff,$f8,$f7,$ea,$e7,$ec,$dd,$de
        dc.b    $fb,$e8,$cf,$ef,$e8,$e6,$ef,$0c,$eb,$f5,$f3,$fa,$05,$1c,$09,$0f
        dc.b    $08,$1d,$27,$29,$2f,$40,$23,$2f,$18,$0d,$02,$07,$08,$0b,$0d,$03
        dc.b    $03,$f8,$f8,$f4,$f7,$fc,$f9,$02,$02,$f2,$ea,$ec,$e0,$dd,$f5,$fc
        dc.b    $04,$02,$f9,$f4,$e8,$db,$f2,$ec,$ef,$09,$04,$fb,$08,$04,$07,$12
        dc.b    $0f,$1d,$0a,$1a,$03,$1d,$0f,$1f,$10,$13,$0a,$fa,$fa,$e6,$ef,$f8
        dc.b    $07,$fa,$03,$02,$fb,$f6,$f5,$04,$07,$15,$12,$08,$0c,$fc,$f9,$f9
        dc.b    $04,$0b,$14,$0c,$00,$e2,$d6,$e1,$d7,$dc,$df,$f0,$ef,$fe,$00,$0b
        dc.b    $00,$fa,$f8,$00,$fb,$09,$00,$05,$0d,$0a,$11,$1a,$03,$01,$0e,$12
        dc.b    $0e,$33,$2d,$34,$2c,$0a,$1b,$04,$00,$fc,$e0,$f7,$ff,$0a,$00,$05
        dc.b    $06,$00,$fd,$f4,$e8,$e6,$e6,$e5,$e2,$e3,$e4,$f3,$f6,$f0,$fd,$ff
        dc.b    $07,$00,$fd,$ff,$01,$ff,$0c,$0c,$f2,$0e,$00,$fb,$00,$f8,$ff,$0b
        dc.b    $00,$f6,$ff,$f3,$f3,$f5,$ff,$0c,$0b,$15,$13,$18,$17,$1e,$1b,$24
        dc.b    $10,$0b,$07,$0b,$05,$fc,$f4,$ee,$ef,$ff,$f4,$d8,$df,$e9,$e2,$e7
        dc.b    $f7,$fa,$f2,$03,$fa,$07,$0c,$0a,$0a,$03,$03,$0b,$15,$0a,$04,$09
        dc.b    $13,$16,$1b,$29,$1c,$0b,$0c,$04,$ff,$00,$fb,$fb,$ea,$e3,$e8,$df
        dc.b    $f5,$ec,$fd,$14,$0c,$07,$f8,$07,$00,$e7,$f7,$f4,$f7,$08,$f8,$05
        dc.b    $fa,$05,$f3,$f7,$f2,$e7,$0f,$12,$04,$ff,$07,$0b,$03,$1f,$28,$15
        dc.b    $23,$3b,$28,$08,$1e,$10,$01,$12,$f8,$e5,$eb,$e9,$e3,$e3,$fd,$fa
        dc.b    $f6,$02,$f4,$e2,$e5,$f1,$eb,$f0,$f6,$e5,$ef,$03,$fa,$fb,$01,$ec
        dc.b    $f7,$f8,$ff,$02,$13,$17,$11,$14,$17,$20,$19,$1b,$1c,$1f,$26,$04
        dc.b    $ff,$06,$f9,$f3,$05,$ec,$e3,$f4,$ec,$f3,$03,$f4,$e8,$f5,$f4,$ec
        dc.b    $ff,$10,$13,$25,$0d,$0a,$02,$f0,$f4,$e9,$f1,$fd,$f9,$f6,$fe,$0b
        dc.b    $23,$2d,$24,$22,$10,$08,$03,$05,$f8,$07,$04,$ec,$fb,$fc,$ec,$f3
        dc.b    $f8,$e7,$e7,$fc,$f6,$f7,$f2,$f4,$f3,$fb,$fc,$ff,$0f,$00,$fa,$0b
        dc.b    $00,$f2,$f5,$0b,$02,$fb,$04,$02,$ff,$08,$06,$0f,$0b,$04,$06,$00
        dc.b    $07,$02,$f3,$ff,$00,$f1,$ff,$f2,$f5,$fc,$f9,$fb,$07,$1a,$1d,$27
        dc.b    $20,$0e,$ff,$07,$09,$12,$08,$f8,$f5,$f2,$f7,$fe,$fa,$fd,$fa,$fd
        dc.b    $f0,$ff,$0c,$f6,$0d,$14,$01,$09,$0e,$08,$01,$fe,$fb,$07,$0a,$06
        dc.b    $0f,$01,$01,$ff,$04,$fd,$f2,$f7,$fe,$fa,$f9,$fa,$00,$0e,$19,$10
        dc.b    $00,$fa,$f4,$ec,$e7,$f0,$dc,$db,$f5,$fe,$f9,$fe,$f4,$f7,$fd,$fe
        dc.b    $03,$fe,$09,$04,$ff,$0e,$09,$07,$09,$10,$11,$27,$26,$16,$29,$1a
        dc.b    $10,$1a,$11,$17,$1d,$11,$0f,$1e,$10,$fe,$04,$fc,$f2,$ef,$ec,$d6
        dc.b    $e5,$e4,$dc,$e2,$de,$e7,$e9,$ec,$e8,$e4,$ee,$ec,$ed,$fe,$f5,$f8
        dc.b    $f4,$e6,$e5,$f3,$ff,$05,$fa,$fb,$f6,$f2,$f9,$fb,$ff,$ff,$0b,$0b
        dc.b    $0b,$14,$19,$1c,$18,$18,$1b,$21,$23,$1b,$14,$f8,$fe,$12,$10,$19
        dc.b    $18,$13,$19,$11,$04,$f3,$f9,$07,$00,$03,$00,$f5,$f2,$f6,$ea,$f7
        dc.b    $fb,$ff,$03,$09,$0c,$fd,$0f,$02,$fd,$00,$04,$fe,$04,$02,$f9,$05
        dc.b    $00,$07,$06,$e8,$e2,$ef,$ef,$f4,$ff,$0e,$15,$1c,$0a,$03,$00,$ef
        dc.b    $f2,$fb,$fb,$ff,$08,$04,$07,$00,$f9,$04,$15,$1d,$1b,$15,$1a,$08
        dc.b    $0f,$10,$0b,$0c,$15,$18,$00,$0e,$11,$08,$02,$01,$fa,$e8,$e9,$e1
        dc.b    $dc,$d4,$d3,$eb,$f6,$f9,$f0,$e4,$e5,$e1,$dc,$e9,$eb,$fc,$f0,$ef
        dc.b    $fe,$f5,$f7,$01,$f8,$f7,$13,$12,$08,$fe,$f4,$e6,$ef,$07,$1b,$24
        dc.b    $1c,$1b,$11,$09,$0c,$13,$0a,$06,$17,$10,$13,$0a,$02,$ff,$09,$13
        dc.b    $09,$11,$0f,$0f,$0f,$04,$fc,$ff,$02,$07,$0c,$f6,$f1,$f3,$f6,$0b
        dc.b    $19,$0d,$0c,$fa,$fd,$00,$f4,$f1,$fb,$f0,$e5,$f7,$f2,$ec,$fa,$f8
        dc.b    $ed,$f3,$00,$f0,$eb,$e9,$eb,$e7,$ef,$f6,$f9,$0d,$1d,$21,$15,$14
        dc.b    $0c,$04,$0f,$0f,$0f,$18,$07,$07,$02,$02,$07,$06,$09,$0f,$0c,$14
        dc.b    $0d,$0f,$0f,$16,$0e,$fd,$fc,$f7,$fb,$ff,$13,$10,$08,$0c,$0a,$09
        dc.b    $fe,$fd,$f6,$ea,$eb,$ea,$e1,$df,$e9,$e4,$dd,$e6,$ef,$f3,$fc,$fb
        dc.b    $f9,$f8,$f5,$f3,$fd,$04,$f6,$0f,$1b,$0b,$1b,$18,$11,$1e,$24,$19
        dc.b    $1e,$34,$28,$11,$13,$08,$01,$0a,$0c,$13,$14,$0b,$08,$02,$f5,$fd
        dc.b    $00,$f1,$ea,$e0,$dc,$df,$e5,$e2,$e2,$f3,$f0,$f0,$f4,$fb,$ff,$06
        dc.b    $0b,$05,$07,$0e,$01,$fa,$fe,$09,$00,$07,$1c,$0d,$03,$03,$f8,$ec
        dc.b    $f1,$f6,$f0,$f2,$f8,$00,$f9,$ee,$e7,$ef,$f0,$f6,$f6,$ff,$0a,$04
        dc.b    $06,$06,$fd,$06,$02,$fc,$e6,$f7,$fa,$f7,$03,$04,$0b,$10,$0c,$07
        dc.b    $fc,$f9,$fb,$02,$ff,$0d,$13,$10,$0e,$12,$1e,$26,$2d,$2c,$1d,$25
        dc.b    $1a,$0a,$07,$06,$f9,$05,$07,$07,$0a,$fc,$f9,$ff,$fc,$ec,$fd,$02
        dc.b    $fc,$fe,$fa,$f5,$ed,$de,$f3,$f2,$e4,$f1,$eb,$e9,$e7,$fa,$f0,$f5
        dc.b    $f0,$f3,$f5,$fa,$04,$0b,$06,$fb,$0d,$04,$03,$0b,$00,$ff,$0b,$16
        dc.b    $04,$0f,$18,$08,$0c,$18,$0d,$0b,$0a,$00,$fb,$0b,$07,$07,$08,$00
        dc.b    $ff,$03,$0c,$04,$08,$00,$f3,$f3,$f4,$ee,$f7,$01,$f7,$fe,$f3,$f3
        dc.b    $f2,$ee,$ef,$f5,$f6,$f1,$fc,$f9,$f5,$ff,$f8,$f6,$05,$0c,$07,$23
        dc.b    $28,$1e,$1b,$1f,$18,$13,$07,$0b,$06,$13,$05,$ff,$0b,$0f,$08,$01
        dc.b    $01,$00,$ff,$fc,$f0,$f6,$f0,$ea,$e2,$ec,$ea,$ea,$ea,$f1,$f0,$ec
        dc.b    $f0,$ed,$ee,$fb,$00,$ff,$0a,$09,$08,$fb,$05,$0d,$12,$0f,$17,$19
        dc.b    $16,$09,$04,$00,$f8,$03,$0d,$08,$02,$0c,$00,$f8,$fc,$02,$f8,$03
        dc.b    $12,$0e,$01,$05,$00,$f1,$f3,$f9,$f9,$f8,$f7,$0b,$0c,$f5,$f7,$07
        dc.b    $fa,$fb,$01,$ed,$f3,$ff,$01,$ff,$02,$f9,$07,$0b,$04,$f8,$ff,$00
        dc.b    $fe,$02,$05,$0c,$0b,$17,$08,$ff,$0a,$08,$fc,$ff,$06,$fa,$01,$06
        dc.b    $fb,$f9,$f0,$fb,$07,$11,$07,$0b,$11,$11,$15,$17,$00,$fa,$fc,$fd
        dc.b    $03,$fe,$f4,$f3,$ec,$ee,$ee,$e5,$e6,$ee,$f1,$fb,$0b,$0f,$0f,$0b
        dc.b    $0c,$05,$0a,$03,$ff,$fe,$f9,$f3,$fe,$ff,$fe,$09,$13,$1d,$0c,$f8
        dc.b    $fc,$f8,$ff,$0a,$0e,$0b,$0f,$0a,$07,$16,$10,$08,$04,$fe,$ff,$fc
        dc.b    $fa,$ec,$df,$f4,$f0,$ef,$ff,$00,$f7,$f8,$f7,$f5,$f1,$f9,$fc,$ff
        dc.b    $07,$0e,$0c,$fc,$fd,$00,$ff,$0e,$0c,$00,$07,$0a,$fd,$0b,$0c,$03
        dc.b    $0b,$04,$fa,$0e,$10,$03,$06,$f8,$f3,$ff,$07,$00,$ff,$05,$0d,$0c
        dc.b    $01,$ff,$fc,$ff,$07,$00,$07,$09,$fe,$fb,$f7,$eb,$f3,$f6,$f2,$fb
        dc.b    $02,$f6,$05,$0e,$04,$00,$03,$02,$fe,$03,$09,$0d,$0c,$06,$06,$02
        dc.b    $f6,$fd,$00,$f4,$f5,$f7,$fd,$06,$01,$03,$fe,$f7,$05,$00,$f7,$f9
        dc.b    $ff,$0d,$0c,$0a,$15,$06,$06,$02,$02,$fc,$fe,$08,$01,$0f,$04,$fd
        dc.b    $fe,$00,$f8,$fb,$fa,$ff,$0b,$0b,$00,$f8,$f0,$f6,$f9,$f6,$f9,$02
        dc.b    $f4,$f6,$fc,$f6,$f2,$f8,$ff,$ff,$13,$13,$0d,$07,$05,$fd,$f8,$fb
        dc.b    $03,$fc,$fb,$ff,$fe,$fc,$fd,$04,$00,$ff,$02,$fc,$ff,$05,$16,$1b
        dc.b    $25,$20,$17,$16,$04,$ff,$00,$f6,$f1,$f6,$fa,$f0,$f9,$f4,$f3,$ff
        dc.b    $0d,$00,$ff,$ff,$fa,$fa,$fb,$fd,$03,$07,$0f,$0a,$0b,$0b,$00,$f0
        dc.b    $f3,$fa,$f7,$fc,$02,$02,$01,$02,$00,$f9,$fe,$15,$0c,$06,$04,$f9
        dc.b    $ec,$f3,$f6,$eb,$ec,$f5,$fb,$ff,$0f,$17,$11,$12,$0c,$08,$f0,$ec
        dc.b    $ec,$ed,$f5,$03,$0e,$11,$16,$0d,$0c,$0c,$0d,$13,$0b,$0d,$04,$fe
        dc.b    $04,$fa,$fa,$fe,$f8,$03,$07,$00,$f0,$f7,$fc,$f0,$ed,$fb,$f6,$f9
        dc.b    $03,$06,$0c,$11,$17,$0f,$0e,$12,$10,$0d,$02,$fe,$f8,$f2,$f7,$f9
        dc.b    $f9,$f3,$f0,$ed,$fa,$00,$fb,$06,$f8,$ff,$0f,$0c,$fd,$07,$13,$0b
        dc.b    $0b,$09,$06,$06,$fc,$f0,$ed,$f1,$ff,$09,$01,$fc,$02,$f8,$ff,$00
        dc.b    $07,$14,$0b,$07,$01,$02,$01,$06,$00,$ff,$02,$ff,$0b,$06,$fa,$fd
        dc.b    $fe,$f2,$ec,$f0,$f2,$f8,$ec,$e9,$f9,$fa,$fb,$03,$0b,$0f,$03,$00
        dc.b    $f9,$fb,$ff,$0d,$08,$0c,$15,$1b,$18,$18,$14,$05,$06,$0f,$09,$0c
        dc.b    $08,$fc,$f8,$f5,$fb,$fb,$fd,$fc,$f2,$f7,$f4,$ee,$f1,$ef,$f9,$ff
        dc.b    $f6,$f5,$f6,$ea,$ef,$f1,$fd,$02,$fe,$02,$f7,$03,$0e,$08,$0b,$0a
        dc.b    $0f,$18,$13,$0a,$0b,$0a,$fe,$03,$00,$ff,$03,$07,$0f,$12,$0c,$0f
        dc.b    $0e,$05,$01,$02,$00,$f9,$fe,$fe,$02,$09,$02,$03,$06,$f8,$ff,$00
        dc.b    $f8,$f0,$ee,$f0,$e6,$e5,$ea,$e8,$ed,$f6,$ff,$08,$0b,$10,$05,$fc
        dc.b    $f2,$f5,$fd,$07,$0e,$0f,$11,$0f,$09,$0e,$17,$1b,$1b,$1b,$14,$10
        dc.b    $07,$05,$01,$fd,$f7,$fd,$f4,$f3,$fe,$f9,$f7,$f8,$ea,$e7,$e8,$e8
        dc.b    $e6,$ec,$f0,$f0,$ff,$05,$fa,$ff,$03,$fc,$fb,$ff,$0a,$16,$18,$14
        dc.b    $17,$0e,$07,$0c,$09,$0d,$14,$13,$13,$0b,$0a,$0d,$02,$fd,$ff,$fd
        dc.b    $fc,$f8,$f6,$fa,$fe,$fd,$02,$0e,$06,$07,$00,$f4,$fc,$00,$f6,$f8
        dc.b    $fc,$f4,$e4,$e3,$ea,$e7,$ed,$fd,$02,$f8,$fb,$fc,$f8,$06,$07,$ff
        dc.b    $01,$09,$05,$0a,$08,$08,$11,$08,$06,$0b,$13,$11,$15,$11,$0f,$0c
        dc.b    $05,$0f,$0d,$05,$0c,$0c,$0a,$06,$07,$f9,$f7,$f2,$f1,$f4,$f7,$fa
        dc.b    $f7,$f9,$f5,$f8,$f9,$fb,$f8,$fa,$f3,$f1,$f7,$f7,$f8,$f3,$f4,$ff
        dc.b    $fe,$f8,$03,$09,$07,$fc,$03,$09,$03,$0f,$19,$14,$04,$07,$0c,$0c
        dc.b    $0c,$0b,$08,$02,$07,$0a,$07,$07,$01,$00,$fd,$07,$04,$02,$02,$fc
        dc.b    $ff,$ff,$f8,$ee,$eb,$ee,$ef,$f4,$f5,$fb,$fb,$fa,$fb,$ff,$fb,$fd
        dc.b    $01,$00,$fa,$03,$01,$ff,$04,$0a,$07,$0e,$0e,$0a,$08,$07,$0f,$11
        dc.b    $14,$08,$05,$04,$07,$07,$ff,$03,$05,$03,$04,$07,$03,$fe,$fc,$ff
        dc.b    $09,$06,$fa,$fa,$ea,$e5,$eb,$f3,$f7,$fa,$f8,$f5,$fb,$ff,$05,$00
        dc.b    $fd,$fc,$fb,$fd,$00,$03,$00,$01,$00,$fd,$01,$07,$0d,$05,$06,$08
        dc.b    $02,$09,$0c,$07,$0d,$14,$08,$fe,$fa,$f1,$07,$0c,$f8,$fd,$fe,$f6
        dc.b    $fa,$04,$00,$00,$02,$fb,$f8,$f0,$ec,$ee,$f8,$f2,$ff,$0c,$0b,$0c
        dc.b    $09,$09,$0b,$09,$13,$10,$11,$09,$09,$08,$07,$08,$01,$00,$01,$02
        dc.b    $f8,$f5,$fc,$fc,$f8,$fe,$f6,$f0,$ff,$0a,$00,$02,$05,$0d,$0b,$fc
        dc.b    $f4,$f2,$ee,$ec,$f2,$f1,$fb,$0b,$0a,$08,$07,$03,$03,$01,$ff,$01
        dc.b    $00,$fd,$09,$08,$06,$12,$07,$09,$0b,$04,$00,$f9,$fc,$ff,$ff,$fe
        dc.b    $01,$fe,$f2,$f3,$f9,$fc,$fe,$ff,$ff,$01,$ff,$07,$09,$04,$09,$0a
        dc.b    $05,$10,$12,$0a,$03,$00,$f9,$03,$00,$02,$06,$03,$fc,$f4,$ea,$f6
        dc.b    $f6,$f4,$fe,$00,$fb,$07,$07,$08,$05,$06,$00,$f8,$f9,$03,$02,$fb
        dc.b    $f9,$f8,$f1,$f4,$f6,$fe,$0d,$0b,$00,$f5,$ff,$fc,$f9,$ff,$ff,$03
        dc.b    $09,$0f,$0d,$16,$18,$0e,$0e,$0e,$13,$12,$09,$08,$05,$07,$04,$00
        dc.b    $fb,$fc,$fb,$ff,$fe,$fd,$05,$08,$fc,$00,$fc,$f9,$fe,$00,$f1,$f1
        dc.b    $f3,$f8,$f8,$f4,$ed,$ef,$e9,$e3,$ef,$f1,$f0,$f9,$fb,$f2,$f9,$01
        dc.b    $03,$0b,$19,$1a,$14,$1b,$1e,$1f,$1b,$14,$14,$0d,$07,$01,$fe,$07
        dc.b    $0d,$04,$ff,$02,$06,$06,$fe,$01,$01,$f7,$fc,$02,$f7,$f2,$f1,$ef
        dc.b    $f6,$ff,$fc,$f9,$fd,$ff,$03,$03,$fb,$f5,$ff,$08,$06,$04,$06,$00
        dc.b    $03,$03,$fa,$f6,$f5,$fa,$f4,$f7,$ff,$05,$09,$02,$01,$09,$07,$07
        dc.b    $06,$02,$07,$06,$01,$02,$03,$07,$00,$fb,$f3,$f7,$f9,$f8,$fa,$ff
        dc.b    $fe,$fb,$00,$fc,$ff,$05,$02,$03,$0d,$04,$fb,$03,$07,$00,$ff,$08
        dc.b    $00,$fc,$01,$09,$0b,$15,$1b,$1b,$12,$0d,$0f,$00,$ff,$01,$f8,$f2
        dc.b    $05,$08,$fe,$ff,$ff,$fb,$f9,$f4,$eb,$ec,$f2,$fa,$f8,$ee,$ef,$f9
        dc.b    $f8,$f6,$f6,$f2,$f8,$02,$02,$05,$05,$07,$02,$fd,$04,$06,$0c,$0b
        dc.b    $0d,$0e,$0f,$11,$11,$0d,$09,$04,$07,$08,$fa,$ff,$01,$f8,$fb,$fc
        dc.b    $f4,$f6,$fc,$f6,$03,$07,$03,$04,$fc,$fe,$fc,$01,$05,$05,$01,$00
        dc.b    $fc,$f4,$f5,$f4,$ee,$f7,$03,$fc,$05,$08,$07,$08,$07,$0b,$0d,$06
        dc.b    $07,$08,$06,$09,$07,$00,$03,$00,$f6,$fa,$07,$06,$fc,$02,$03,$f8
        dc.b    $f8,$fe,$fd,$fe,$fc,$f9,$ff,$06,$03,$05,$00,$f2,$f7,$02,$01,$01
        dc.b    $04,$03,$fe,$ff,$03,$0d,$12,$12,$0f,$09,$06,$01,$00,$fd,$fd,$00
        dc.b    $ff,$f9,$f7,$f4,$f0,$f2,$f7,$f9,$04,$06,$07,$08,$02,$01,$fd,$fc
        dc.b    $ff,$07,$05,$01,$f8,$f9,$03,$06,$05,$04,$01,$fe,$fe,$ff,$ff,$fc
        dc.b    $f9,$fe,$01,$fc,$ff,$fd,$ff,$03,$07,$01,$07,$06,$05,$0a,$07,$09
        dc.b    $0c,$00,$fc,$03,$03,$01,$07,$07,$00,$02,$fc,$fb,$fa,$fc,$fc,$f9
        dc.b    $fa,$fd,$f9,$ff,$06,$04,$03,$02,$06,$05,$11,$0c,$03,$ff,$fc,$f8
        dc.b    $f5,$f4,$fc,$fd,$03,$07,$04,$04,$05,$02,$00,$fe,$ff,$00,$fa,$fb
        dc.b    $fc,$ff,$ff,$fb,$fc,$07,$0e,$0d,$08,$fe,$f7,$fa,$00,$fc,$ff,$00
        dc.b    $ff,$0b,$0f,$0a,$07,$0c,$07,$07,$00,$01,$fc,$fd,$04,$01,$fe,$06
        dc.b    $01,$fb,$f8,$f6,$f3,$f5,$ff,$03,$09,$0e,$0d,$04,$f8,$fa,$fe,$fb
        dc.b    $05,$06,$02,$05,$05,$fc,$ff,$00,$f9,$ff,$05,$00,$01,$fa,$f1,$f2
        dc.b    $f4,$f9,$fd,$01,$02,$03,$0a,$0f,$0e,$08,$07,$07,$02,$01,$03,$0d
        dc.b    $0e,$07,$03,$01,$01,$02,$ff,$fe,$fb,$03,$03,$02,$04,$02,$ff,$03
        dc.b    $fe,$f9,$fa,$f8,$f9,$03,$00,$f9,$f9,$f1,$f2,$fd,$09,$06,$04,$01
        dc.b    $ff,$00,$fd,$fe,$f6,$f2,$fd,$f9,$f7,$fd,$fc,$02,$06,$01,$02,$fe
        dc.b    $ff,$03,$00,$ff,$04,$07,$0b,$08,$07,$09,$05,$07,$03,$0e,$11,$09
        dc.b    $03,$06,$06,$08,$0e,$12,$00,$f6,$02,$00,$f8,$fc,$f8,$f6,$fa,$f9
        dc.b    $f9,$fe,$fc,$f2,$f4,$f3,$f8,$ff,$01,$09,$0c,$06,$05,$08,$04,$f6
        dc.b    $f8,$f9,$fc,$07,$0c,$01,$fe,$07,$13,$16,$11,$0a,$09,$08,$00,$fb
        dc.b    $fb,$fa,$f7,$fd,$fa,$fa,$f5,$f6,$f4,$fd,$f8,$f4,$fb,$f8,$f1,$fa
        dc.b    $ff,$fc,$ff,$07,$05,$04,$02,$08,$02,$03,$09,$0a,$06,$08,$06,$00
        dc.b    $04,$07,$08,$07,$0c,$07,$02,$0b,$0c,$09,$02,$fa,$ff,$03,$00,$07
        dc.b    $04,$03,$00,$02,$00,$f8,$ff,$00,$e8,$ee,$f1,$eb,$f5,$02,$fd,$ff
        dc.b    $fd,$f6,$f4,$fa,$fb,$fb,$00,$fd,$ff,$fe,$ff,$07,$0d,$0f,$10,$06
        dc.b    $02,$06,$fe,$05,$0b,$09,$0c,$09,$06,$09,$05,$02,$fc,$ff,$03,$04
        dc.b    $0a,$0d,$0b,$0c,$07,$00,$fd,$fc,$f9,$f7,$f9,$f8,$f6,$f0,$ee,$eb
        dc.b    $e7,$f3,$f8,$fb,$ff,$06,$04,$09,$16,$11,$04,$04,$01,$fb,$ff,$09
        dc.b    $01,$fd,$05,$06,$07,$06,$03,$ff,$fc,$f6,$f5,$f9,$fc,$ff,$ff,$03
        dc.b    $09,$11,$14,$0a,$07,$09,$0e,$0f,$0c,$04,$f9,$fd,$fb,$f9,$ff,$fa
        dc.b    $ff,$fe,$fa,$f9,$f0,$ef,$f4,$f6,$fc,$f8,$f0,$f9,$fd,$03,$0a,$08
        dc.b    $0b,$06,$02,$05,$0e,$0c,$0b,$0f,$04,$05,$0b,$08,$00,$fa,$fe,$00
        dc.b    $05,$0c,$03,$05,$04,$00,$fd,$02,$02,$fe,$fe,$f3,$fb,$01,$fe,$fc
        dc.b    $05,$00,$fc,$ff,$f2,$f4,$f9,$f8,$01,$09,$06,$01,$ff,$f9,$f5,$f6
        dc.b    $f9,$fc,$03,$0c,$07,$05,$04,$04,$fe,$ff,$fc,$fd,$ff,$fa,$f8,$ff
        dc.b    $05,$09,$0c,$0a,$07,$03,$03,$0b,$06,$04,$07,$09,$0b,$0b,$0c,$08
        dc.b    $09,$0a,$07,$0d,$0a,$03,$05,$fd,$eb,$eb,$f0,$f5,$f6,$f9,$f7,$f9
        dc.b    $f8,$fc,$f6,$f6,$fe,$01,$fd,$ff,$fc,$f6,$f8,$fb,$fa,$fe,$07,$08
        dc.b    $00,$05,$08,$05,$04,$06,$02,$02,$04,$07,$05,$05,$07,$0a,$04,$03
        dc.b    $00,$fc,$f7,$f4,$f2,$f6,$fd,$03,$07,$0c,$10,$0a,$0a,$0f,$11,$0e
        dc.b    $08,$07,$06,$ff,$02,$00,$fb,$00,$fb,$fd,$00,$fa,$f6,$f2,$f3,$f5
        dc.b    $fe,$fc,$f5,$ff,$00,$fb,$03,$04,$04,$07,$07,$00,$f9,$f9,$fc,$fb
        dc.b    $fd,$05,$05,$04,$0b,$0a,$07,$06,$fc,$fc,$f8,$f5,$f6,$fb,$fd,$ff
        dc.b    $07,$0c,$08,$06,$00,$02,$00,$fa,$fe,$fc,$fa,$fc,$07,$09,$0c,$11
        dc.b    $0c,$03,$03,$00,$ff,$01,$03,$01,$00,$fd,$ff,$01,$02,$02,$02,$04
        dc.b    $05,$00,$fc,$fc,$f8,$f0,$f0,$e8,$f5,$fc,$f5,$f8,$f9,$fa,$01,$0b
        dc.b    $08,$06,$09,$0c,$0f,$16,$14,$0c,$0d,$0c,$11,$0c,$00,$03,$06,$02
        dc.b    $fe,$ff,$fd,$fa,$fa,$f9,$fd,$ff,$f8,$fc,$ff,$ff,$fb,$fb,$f9,$f4
        dc.b    $fb,$ff,$fe,$f8,$f9,$f8,$f7,$fe,$02,$02,$02,$03,$07,$07,$06,$09
        dc.b    $08,$06,$0c,$09,$09,$0d,$08,$07,$0d,$06,$fa,$fb,$f8,$f7,$fd,$f3
        dc.b    $f6,$fb,$fb,$fc,$01,$00,$f8,$fd,$00,$02,$00,$f8,$fd,$f4,$ee,$f4
        dc.b    $fb,$ff,$03,$04,$06,$05,$0b,$10,$0a,$09,$11,$10,$0b,$0d,$0c,$01
        dc.b    $01,$06,$08,$04,$fa,$ff,$03,$00,$03,$06,$04,$02,$04,$01,$01,$00
        dc.b    $f9,$fb,$fb,$fb,$01,$fe,$fd,$fe,$fc,$fc,$ff,$00,$ff,$fc,$f8,$f0
        dc.b    $ee,$f3,$f8,$f2,$fb,$08,$09,$09,$06,$00,$ff,$07,$05,$00,$01,$07
        dc.b    $0c,$0d,$13,$10,$0d,$13,$18,$12,$0d,$08,$04,$fc,$fd,$02,$fe,$fc
        dc.b    $f8,$f2,$f6,$fc,$fa,$f6,$fa,$f2,$ef,$f3,$ec,$ee,$f5,$fc,$ff,$02
        dc.b    $00,$fa,$fd,$02,$ff,$01,$03,$00,$05,$0a,$09,$07,$06,$01,$07,$09
        dc.b    $0b,$11,$0c,$0b,$0c,$0a,$08,$04,$03,$00,$fc,$fc,$fa,$fa,$f6,$f4
        dc.b    $f6,$f5,$f4,$fb,$fb,$fd,$ff,$03,$03,$03,$07,$06,$00,$f8,$fc,$ff
        dc.b    $08,$0a,$04,$01,$06,$09,$f8,$ee,$f5,$fb,$ff,$0b,$04,$00,$04,$06
        dc.b    $0b,$05,$09,$13,$13,$0d,$0d,$0b,$00,$f9,$fc,$f6,$f5,$fd,$fa,$fc
        dc.b    $ff,$fc,$f8,$fb,$f6,$ec,$f1,$f4,$f7,$fe,$fc,$fd,$00,$01,$ff,$ff
        dc.b    $00,$fe,$ff,$ff,$0c,$09,$0a,$10,$0b,$07,$0a,$07,$05,$0c,$0d,$0d
        dc.b    $11,$07,$06,$0a,$07,$fe,$ff,$06,$00,$fe,$fe,$fc,$f8,$f7,$fd,$fd
        dc.b    $f6,$f4,$f6,$f3,$f5,$f6,$ea,$ec,$f3,$f3,$fd,$04,$03,$06,$05,$09
        dc.b    $0b,$0a,$0c,$0c,$0a,$07,$03,$fc,$fd,$03,$03,$00,$04,$01,$00,$00
        dc.b    $02,$04,$01,$03,$04,$07,$07,$07,$0b,$0a,$08,$00,$01,$03,$01,$02
        dc.b    $fd,$fc,$03,$01,$01,$03,$00,$f5,$f2,$f3,$f3,$f5,$fa,$f7,$f7,$fb
        dc.b    $f7,$fc,$fe,$fb,$fb,$ff,$00,$05,$06,$00,$ff,$09,$0e,$0f,$0f,$0d
        dc.b    $04,$07,$0b,$03,$00,$05,$09,$0c,$0f,$0b,$01,$ff,$00,$01,$00,$ff
        dc.b    $01,$ff,$01,$00,$fa,$f7,$f9,$f5,$f7,$fc,$f8,$fb,$ff,$ff,$ff,$fc
        dc.b    $fa,$fd,$fc,$fc,$fb,$fb,$ff,$07,$04,$ff,$01,$05,$02,$03,$04,$fe
        dc.b    $04,$09,$06,$06,$04,$02,$01,$02,$06,$0d,$0c,$0e,$0e,$0c,$09,$07
        dc.b    $05,$00,$ff,$fb,$f8,$f8,$f7,$fd,$fc,$f6,$f7,$f4,$f5,$fa,$fd,$fc
        dc.b    $01,$05,$fb,$fb,$fe,$fa,$f4,$f9,$fb,$f9,$ff,$03,$01,$05,$07,$ff
        dc.b    $ff,$01,$06,$0f,$14,$13,$12,$11,$0e,$06,$00,$fe,$fe,$ff,$01,$05
        dc.b    $03,$fe,$ff,$fd,$f9,$f9,$02,$ff,$fc,$fd,$ff,$01,$ff,$02,$00,$03
        dc.b    $03,$ff,$00,$fe,$fb,$fc,$fd,$fa,$ff,$03,$fc,$fb,$f6,$f7,$fa,$f8
        dc.b    $fa,$fc,$00,$fa,$f8,$fc,$f9,$fe,$09,$0b,$0f,$09,$07,$05,$03,$09
        dc.b    $0d,$0f,$13,$10,$0b,$0c,$0a,$07,$05,$07,$01,$fb,$f6,$f1,$f6,$f7
        dc.b    $02,$03,$01,$00,$ff,$fc,$fd,$f9,$f7,$fb,$f4,$f6,$03,$03,$fc,$ff
        dc.b    $fd,$f6,$fb,$fd,$f9,$fd,$fc,$fe,$fc,$01,$03,$04,$04,$06,$05,$02
        dc.b    $06,$0a,$07,$09,$0c,$0d,$0a,$08,$03,$03,$02,$00,$07,$05,$06,$05
        dc.b    $06,$09,$00,$ff,$01,$00,$fe,$ff,$ff,$fb,$fd,$ff,$02,$ff,$fc,$fc
        dc.b    $f9,$fb,$fb,$fa,$fb,$f8,$ec,$ef,$f4,$f5,$f3,$f6,$f8,$00,$02,$08
        dc.b    $08,$05,$02,$02,$03,$04,$09,$04,$07,$0b,$0d,$13,$11,$12,$13,$13
        dc.b    $11,$0d,$07,$06,$00,$fc,$fe,$fb,$fc,$fc,$fc,$fd,$fb,$f8,$f2,$f3
        dc.b    $f6,$f8,$f5,$f3,$f7,$fb,$fe,$ff,$01,$05,$03,$00,$fc,$fd,$ff,$f9
        dc.b    $fb,$ff,$08,$09,$07,$04,$00,$04,$07,$0a,$08,$04,$00,$ff,$03,$04
        dc.b    $04,$07,$0b,$0a,$0a,$0c,$05,$02,$01,$f9,$f7,$fa,$fb,$00,$03,$00
        dc.b    $fa,$f9,$ff,$ff,$fe,$02,$fc,$fa,$fd,$fc,$fe,$00,$00,$fd,$01,$00
        dc.b    $02,$07,$05,$02,$fc,$f9,$f9,$ff,$07,$0c,$0a,$06,$07,$08,$07,$08
        dc.b    $04,$02,$ff,$02,$03,$02,$02,$04,$00,$fe,$00,$fd,$fd,$fe,$fb,$00
        dc.b    $fe,$fa,$f8,$fa,$f3,$f4,$f9,$fa,$fb,$ff,$ff,$03,$05,$0b,$0e,$06
        dc.b    $04,$05,$01,$ff,$07,$02,$ff,$04,$02,$ff,$03,$00,$02,$02,$fa,$f9
        dc.b    $fb,$f7,$fd,$04,$01,$00,$03,$03,$05,$0b,$07,$ff,$fc,$01,$00,$fc
        dc.b    $fb,$fe,$01,$07,$0d,$08,$07,$02,$fd,$03,$00,$ff,$03,$02,$01,$04
        dc.b    $01,$00,$01,$04,$03,$02,$02,$fd,$f8,$f9,$f9,$fa,$fc,$00,$fc,$fb
        dc.b    $01,$03,$01,$00,$00,$fc,$ff,$fe,$01,$04,$02,$00,$00,$fe,$01,$05
        dc.b    $05,$07,$06,$07,$09,$09,$06,$05,$fe,$f7,$fc,$ff,$00,$fb,$fc,$f4
        dc.b    $f3,$fb,$00,$fc,$f9,$02,$00,$ff,$02,$ff,$ff,$08,$04,$ff,$ff,$02
        dc.b    $06,$05,$02,$03,$07,$08,$02,$01,$fe,$fc,$f7,$f9,$fa,$fb,$05,$04
        dc.b    $06,$06,$fc,$ff,$07,$04,$04,$02,$00,$fa,$f9,$fe,$01,$06,$0a,$0b
        dc.b    $09,$07,$05,$02,$00,$fc,$ff,$fc,$fa,$ff,$05,$02,$01,$03,$00,$00
        dc.b    $fe,$fd,$fc,$00,$ff,$fb,$f8,$f6,$f7,$fb,$03,$04,$03,$02,$0a,$0e
        dc.b    $09,$09,$08,$03,$02,$05,$08,$00,$ff,$02,$05,$02,$ff,$03,$00,$01
        dc.b    $00,$fb,$fb,$fa,$f1,$f1,$f2,$f3,$f9,$fd,$ff,$02,$04,$03,$05,$02
        dc.b    $03,$01,$01,$01,$02,$07,$08,$0a,$0a,$07,$04,$03,$00,$fc,$f8,$fc
        dc.b    $fc,$fe,$01,$00,$fe,$ff,$02,$00,$03,$07,$00,$ff,$07,$07,$07,$08
        dc.b    $08,$06,$01,$fd,$01,$00,$f5,$f4,$f9,$f9,$f8,$f6,$f7,$fb,$01,$01
        dc.b    $fe,$f8,$fa,$fd,$fd,$ff,$fe,$fb,$02,$09,$06,$03,$02,$01,$07,$08
        dc.b    $07,$09,$0d,$0b,$0c,$0a,$07,$08,$0b,$06,$04,$07,$06,$05,$05,$fd
        dc.b    $f6,$f4,$f4,$f8,$f7,$f4,$f4,$f5,$f6,$f9,$fb,$fd,$fc,$fc,$fa,$f7
        dc.b    $f7,$ff,$02,$03,$03,$02,$05,$0a,$09,$09,$0e,$12,$10,$0b,$07,$04
        dc.b    $07,$04,$01,$07,$08,$01,$06,$08,$00,$00,$fd,$fb,$ff,$03,$06,$01
        dc.b    $fc,$fc,$fc,$fd,$fe,$01,$ff,$ff,$fe,$f8,$f3,$f1,$ee,$ef,$f2,$f6
        dc.b    $fe,$fd,$ff,$02,$01,$01,$ff,$ff,$00,$00,$ff,$00,$ff,$07,$0d,$10
        dc.b    $11,$0f,$0d,$13,$10,$0b,$0e,$10,$0e,$0e,$08,$07,$09,$07,$02,$06
        dc.b    $0c,$06,$03,$00,$f0,$ed,$f1,$ec,$ea,$f1,$f0,$e8,$ea,$ec,$ee,$f5
        dc.b    $f8,$fd,$fc,$fc,$fe,$fc,$f9,$fa,$fd,$03,$0d,$10,$0d,$0d,$08,$07
        dc.b    $0b,$07,$05,$06,$07,$0f,$11,$0f,$09,$07,$0d,$0b,$07,$09,$08,$03
        dc.b    $03,$00,$fa,$f8,$fc,$fe,$00,$00,$fe,$fc,$f8,$f6,$f7,$f6,$f3,$f3
        dc.b    $f0,$f1,$f5,$f6,$f9,$fc,$fd,$ff,$ff,$03,$03,$04,$07,$07,$07,$0a
        dc.b    $0c,$0c,$06,$02,$01,$00,$ff,$01,$01,$04,$09,$0d,$0a,$07,$06,$03
        dc.b    $07,$08,$03,$03,$04,$00,$fe,$01,$fc,$f8,$f8,$f8,$f4,$f4,$f9,$fa
        dc.b    $fc,$f9,$f3,$f3,$f6,$f9,$f8,$ff,$01,$03,$0b,$0c,$0a,$06,$06,$07
        dc.b    $06,$06,$06,$05,$01,$02,$02,$01,$0b,$08,$07,$09,$0b,$09,$05,$04
        dc.b    $03,$07,$08,$07,$04,$fe,$f9,$fb,$fa,$fe,$fb,$fc,$fa,$f5,$f6,$f4
        dc.b    $f3,$f2,$f9,$ff,$00,$fa,$f9,$f5,$f3,$f5,$fb,$ff,$03,$06,$05,$09
        dc.b    $07,$07,$0b,$0b,$0c,$0b,$0c,$0a,$0a,$0a,$07,$05,$07,$03,$01,$01
        dc.b    $05,$02,$ff,$ff,$04,$03,$01,$03,$00,$02,$02,$fe,$f8,$f7,$ff,$fc
        dc.b    $fd,$03,$fe,$fc,$ff,$fd,$f7,$f5,$f6,$f7,$f8,$fa,$fe,$03,$04,$03
        dc.b    $04,$01,$fe,$fe,$fe,$ff,$03,$03,$04,$04,$05,$07,$06,$08,$07,$05
        dc.b    $07,$00,$fe,$03,$02,$03,$07,$08,$08,$07,$08,$03,$07,$04,$ff,$02
        dc.b    $fe,$fa,$f7,$fb,$01,$03,$00,$fe,$fe,$fd,$fe,$fe,$fb,$f9,$f8,$f7
        dc.b    $f9,$f7,$f9,$fd,$fc,$fa,$f9,$fc,$fa,$fc,$02,$00,$04,$0b,$0c,$09
        dc.b    $05,$08,$07,$07,$0b,$0d,$0d,$09,$05,$01,$ff,$fe,$ff,$fe,$f9,$fb
        dc.b    $fc,$fc,$fd,$ff,$03,$05,$04,$03,$05,$00,$fc,$ff,$04,$02,$ff,$04
        dc.b    $01,$ff,$06,$06,$03,$04,$00,$fa,$f9,$fc,$ff,$ff,$fe,$03,$04,$04
        dc.b    $05,$04,$00,$fe,$fc,$fe,$fd,$ff,$02,$ff,$fd,$fc,$fe,$01,$00,$ff
        dc.b    $01,$ff,$fd,$f8,$f7,$fb,$fe,$00,$01,$02,$02,$09,$0b,$07,$06,$00
        dc.b    $fb,$fd,$01,$fd,$fe,$ff,$ff,$05,$09,$09,$0b,$0a,$08,$06,$01,$00
        dc.b    $02,$01,$ff,$fe,$fc,$01,$07,$07,$06,$06,$06,$04,$00,$fb,$f6,$f0
        dc.b    $ee,$ee,$f1,$f6,$f7,$f9,$fd,$fc,$fc,$ff,$01,$04,$06,$05,$07,$06
        dc.b    $07,$06,$09,$0a,$09,$0b,$0e,$08,$04,$01,$02,$00,$00,$03,$01,$00
        dc.b    $fd,$fc,$fd,$ff,$07,$07,$09,$04,$02,$01,$01,$03,$fe,$fe,$fa,$fa
        dc.b    $fa,$f7,$fa,$f9,$f8,$fb,$fc,$01,$01,$ff,$fe,$fc,$fd,$03,$03,$02
        dc.b    $06,$07,$06,$00,$ff,$03,$04,$04,$04,$00,$fc,$fc,$fe,$02,$02,$01
        dc.b    $00,$03,$07,$00,$fc,$fa,$f8,$f7,$ff,$00,$fe,$ff,$fe,$fa,$ff,$ff
        dc.b    $01,$07,$09,$09,$0a,$0b,$0a,$0a,$09,$08,$05,$02,$03,$06,$08,$0c
        dc.b    $08,$03,$fc,$fc,$ff,$ff,$fc,$fb,$f9,$f8,$fc,$fc,$fa,$f8,$f5,$f9
        dc.b    $fe,$fc,$fd,$fe,$00,$00,$ff,$01,$ff,$fe,$fe,$fd,$01,$03,$07,$07
        dc.b    $08,$04,$fc,$ff,$00,$ff,$fd,$ff,$00,$02,$07,$04,$06,$07,$04,$05
        dc.b    $03,$03,$02,$04,$07,$07,$02,$01,$00,$00,$02,$04,$04,$03,$05,$01
        dc.b    $fc,$f8,$f9,$fa,$f6,$f8,$f9,$fb,$fc,$f9,$f8,$f8,$fb,$fe,$fc,$fe
        dc.b    $01,$07,$02,$01,$00,$fc,$ff,$01,$06,$0c,$0e,$0b,$0c,$0e,$0c,$0b
        dc.b    $09,$07,$07,$07,$08,$04,$00,$02,$03,$ff,$fe,$fb,$f6,$f6,$f6,$f7
        dc.b    $f9,$f9,$fa,$fb,$f6,$f3,$f5,$f6,$f6,$ff,$09,$0b,$09,$07,$02,$01
        dc.b    $03,$03,$02,$00,$01,$fd,$fd,$00,$06,$0a,$0d,$10,$0c,$0b,$0c,$07
        dc.b    $05,$01,$05,$06,$03,$05,$07,$06,$03,$00,$00,$fd,$fc,$f8,$f7,$f5
        dc.b    $f6,$f7,$f8,$f7,$fa,$fa,$f8,$fa,$f6,$f3,$f5,$f5,$f7,$fe,$00,$fe
        dc.b    $fe,$00,$ff,$00,$00,$03,$0b,$0f,$0f,$10,$0d,$09,$0c,$0d,$0b,$07
        dc.b    $06,$05,$06,$06,$07,$0c,$0a,$05,$05,$00,$fe,$fd,$fc,$fc,$f8,$f5
        dc.b    $f4,$f3,$f4,$f7,$fb,$fd,$fc,$f9,$fa,$f6,$f4,$f9,$f9,$f9,$fc,$fe
        dc.b    $fd,$ff,$06,$04,$04,$06,$07,$0a,$0a,$08,$09,$08,$05,$03,$06,$09
        dc.b    $0e,$0d,$0a,$04,$01,$03,$03,$00,$ff,$00,$03,$05,$05,$00,$fe,$ff
        dc.b    $fb,$fb,$fc,$f5,$f4,$f2,$f2,$f6,$f8,$f6,$f9,$ff,$00,$ff,$00,$ff
        dc.b    $ff,$01,$04,$04,$fe,$fd,$fe,$ff,$03,$06,$08,$0d,$0c,$0b,$0f,$0e
        dc.b    $0a,$0a,$0b,$0b,$0c,$0a,$06,$04,$01,$ff,$ff,$fe,$fb,$f7,$f6,$fb
        dc.b    $fb,$fa,$fc,$fc,$f9,$fb,$ff,$fc,$f7,$f7,$f8,$f7,$fa,$fc,$fd,$01
        dc.b    $00,$fc,$ff,$00,$ff,$ff,$02,$04,$06,$09,$08,$07,$07,$04,$06,$06
        dc.b    $06,$07,$08,$09,$0a,$0a,$09,$06,$04,$06,$04,$00,$fc,$fa,$fd,$ff
        dc.b    $fe,$fa,$f6,$f4,$f9,$f9,$f9,$fb,$fa,$fb,$fd,$fd,$fc,$fc,$fd,$fe
        dc.b    $03,$05,$05,$07,$07,$07,$03,$00,$ff,$ff,$ff,$03,$07,$07,$0b,$0c
        dc.b    $08,$06,$07,$07,$05,$07,$02,$ff,$02,$06,$06,$04,$02,$01,$fd,$fa
        dc.b    $fa,$f3,$f3,$f5,$f7,$f8,$fb,$fb,$f8,$fb,$00,$fd,$ff,$01,$02,$01
        dc.b    $00,$fe,$ff,$03,$05,$07,$03,$00,$ff,$fc,$ff,$00,$00,$01,$03,$05
        dc.b    $03,$05,$04,$05,$0a,$07,$06,$05,$00,$ff,$00,$03,$07,$0a,$09,$06
        dc.b    $01,$ff,$ff,$fd,$fa,$fd,$fb,$fd,$fd,$fb,$f9,$fb,$fd,$fe,$ff,$01
        dc.b    $fe,$fe,$ff,$01,$01,$05,$03,$04,$07,$06,$05,$07,$07,$06,$00,$00
        dc.b    $ff,$ff,$ff,$fe,$fc,$fd,$00,$01,$00,$03,$02,$01,$00,$01,$fe,$fe
        dc.b    $ff,$fc,$fc,$fd,$fd,$fb,$fd,$ff,$01,$02,$00,$f9,$f8,$fc,$fe,$01
        dc.b    $04,$03,$05,$0b,$0e,$0b,$0a,$0c,$0a,$09,$08,$04,$04,$00,$fd,$fa
        dc.b    $f8,$f7,$f9,$f8,$fb,$fe,$ff,$ff,$fe,$fa,$f9,$fc,$fe,$fd,$fe,$fe
        dc.b    $fd,$ff,$ff,$02,$06,$09,$0b,$07,$07,$07,$03,$01,$03,$03,$04,$05
        dc.b    $00,$ff,$04,$03,$03,$06,$05,$fe,$fc,$fd,$fb,$f8,$fa,$fa,$fc,$fe
        dc.b    $04,$06,$04,$03,$01,$fd,$fe,$ff,$fe,$fb,$fa,$fc,$fd,$00,$02,$02
        dc.b    $05,$04,$00,$fd,$fc,$fe,$01,$03,$05,$07,$06,$06,$07,$07,$05,$04
        dc.b    $05,$07,$05,$00,$03,$00,$01,$03,$03,$01,$ff,$01,$ff,$fd,$fd,$fb
        dc.b    $fd,$fc,$fa,$fe,$00,$fe,$fd,$fe,$02,$07,$01,$fc,$f9,$f6,$f6,$f9
        dc.b    $ff,$03,$05,$09,$09,$09,$0a,$07,$04,$03,$00,$01,$01,$00,$fe,$fe
        dc.b    $ff,$fe,$fd,$fd,$ff,$05,$04,$02,$00,$fd,$fb,$fe,$fe,$fc,$fa,$fd
        dc.b    $fd,$fc,$fd,$02,$08,$08,$08,$07,$01,$02,$06,$06,$07,$09,$0b,$0a
        dc.b    $08,$02,$00,$03,$00,$01,$00,$fc,$f8,$f6,$f9,$fb,$fc,$fd,$ff,$01
        dc.b    $03,$02,$00,$fd,$fc,$fa,$f8,$ff,$ff,$fe,$fe,$fc,$fc,$fd,$ff,$03
        dc.b    $02,$ff,$ff,$fe,$ff,$05,$06,$06,$07,$09,$08,$04,$03,$02,$00,$00
        dc.b    $ff,$ff,$03,$01,$01,$fe,$ff,$03,$06,$09,$0a,$09,$06,$00,$fd,$ff
        dc.b    $fe,$ff,$02,$01,$fc,$fb,$fb,$f8,$fd,$01,$03,$05,$05,$02,$fe,$ff
        dc.b    $01,$06,$09,$07,$05,$03,$00,$fa,$f4,$f3,$f5,$fb,$fd,$fe,$fb,$fc
        dc.b    $fe,$fd,$fa,$f8,$fb,$fa,$fb,$fd,$fc,$ff,$03,$05,$07,$05,$09,$0a
        dc.b    $07,$0a,$08,$04,$01,$03,$05,$09,$08,$09,$05,$02,$04,$05,$07,$06
        dc.b    $00,$00,$00,$fd,$fe,$01,$00,$03,$06,$06,$03,$01,$fe,$fc,$fc,$fc
        dc.b    $fa,$fa,$fb,$fc,$fa,$fb,$fb,$fb,$fb,$fa,$f9,$fc,$ff,$00,$00,$00
        dc.b    $01,$03,$01,$ff,$03,$03,$03,$07,$07,$04,$02,$03,$03,$05,$03,$00
        dc.b    $03,$04,$00,$03,$07,$06,$02,$03,$06,$06,$06,$07,$02,$00,$fa,$fa
        dc.b    $f9,$f8,$fc,$00,$00,$fe,$fd,$fd,$fe,$fd,$fd,$01,$00,$ff,$fe,$fd
        dc.b    $ff,$02,$00,$ff,$ff,$fe,$ff,$00,$fd,$fe,$02,$03,$06,$04,$00,$f9
        dc.b    $f7,$f3,$f8,$ff,$00,$03,$05,$06,$07,$06,$04,$05,$06,$07,$07,$03
        dc.b    $04,$ff,$ff,$fe,$fe,$fe,$02,$01,$00,$02,$02,$00,$fd,$ff,$fd,$fc
        dc.b    $ff,$00,$01,$ff,$ff,$00,$02,$03,$01,$03,$03,$02,$03,$03,$04,$05
        dc.b    $03,$02,$03,$02,$03,$03,$07,$05,$03,$02,$fd,$fb,$fc,$fa,$f9,$f9
        dc.b    $fb,$fe,$ff,$ff,$ff,$ff,$fe,$fd,$fa,$f7,$fb,$fa,$f9,$fe,$01,$04
        dc.b    $09,$0c,$08,$05,$02,$01,$03,$03,$03,$03,$01,$02,$04,$04,$05,$06
        dc.b    $04,$05,$01,$ff,$fe,$fe,$03,$04,$02,$00,$02,$01,$01,$03,$01,$ff
        dc.b    $fd,$fc,$f9,$fd,$ff,$ff,$ff,$01,$02,$00,$03,$07,$03,$02,$00,$ff
        dc.b    $fe,$fc,$f9,$f9,$fd,$fe,$fe,$ff,$01,$ff,$03,$04,$03,$05,$04,$03
        dc.b    $03,$02,$fe,$ff,$02,$03,$04,$06,$06,$06,$08,$0a,$07,$04,$00,$ff
        dc.b    $00,$ff,$fd,$01,$01,$fe,$fd,$fb,$f9,$f9,$fb,$fa,$fc,$fd,$fd,$fe
        dc.b    $01,$03,$02,$04,$02,$02,$05,$01,$fc,$ff,$02,$00,$fd,$fc,$fd,$00
        dc.b    $01,$00,$04,$05,$05,$08,$06,$05,$09,$05,$01,$fe,$fb,$fb,$ff,$02
        dc.b    $03,$04,$06,$06,$02,$02,$fd,$fb,$fb,$fd,$fb,$fe,$00,$00,$01,$03
        dc.b    $05,$03,$04,$01,$fd,$fc,$fa,$fb,$ff,$01,$01,$00,$ff,$fe,$ff,$ff
        dc.b    $ff,$02,$03,$04,$06,$05,$03,$04,$02,$ff,$00,$02,$05,$06,$03,$05
        dc.b    $00,$fb,$fc,$ff,$ff,$ff,$00,$fe,$fb,$f9,$f9,$f8,$f7,$fa,$fe,$fc
        dc.b    $fc,$ff,$ff,$03,$09,$0a,$06,$07,$07,$07,$04,$03,$06,$07,$05,$03
        dc.b    $01,$00,$01,$01,$00,$00,$ff,$ff,$00,$ff,$01,$03,$01,$03,$05,$04
        dc.b    $02,$02,$02,$fd,$fb,$fe,$fe,$fe,$ff,$fd,$f9,$f8,$fb,$fd,$fe,$ff
        dc.b    $fd,$fe,$fe,$fc,$f9,$fa,$fd,$ff,$02,$01,$ff,$ff,$01,$03,$03,$04
        dc.b    $03,$07,$07,$06,$07,$06,$04,$07,$05,$06,$02,$fe,$fc,$fe,$02,$05
        dc.b    $07,$06,$01,$00,$ff,$fd,$fd,$fe,$fe,$fe,$fe,$00,$02,$01,$ff,$fe
        dc.b    $fc,$ff,$00,$fc,$ff,$06,$03,$01,$03,$02,$00,$01,$02,$fe,$fe,$02
        dc.b    $03,$04,$03,$03,$00,$fd,$ff,$01,$00,$fc,$fc,$fc,$fc,$fc,$fe,$ff
        dc.b    $fd,$fe,$ff,$00,$01,$05,$04,$03,$03,$02,$00,$02,$06,$06,$05,$07
        dc.b    $07,$04,$03,$01,$00,$ff,$03,$05,$03,$02,$02,$00,$fc,$fc,$fb,$fa
        dc.b    $fc,$fe,$ff,$fd,$fe,$fc,$fc,$fe,$fb,$fd,$00,$fe,$fe,$02,$04,$07
        dc.b    $0b,$09,$08,$08,$03,$03,$02,$ff,$00,$fd,$ff,$01,$ff,$fe,$fd,$fd
        dc.b    $fc,$ff,$01,$01,$00,$00,$00,$03,$03,$05,$07,$06,$04,$01,$00,$fe
        dc.b    $fd,$fe,$01,$01,$02,$ff,$fc,$fb,$fc,$ff,$01,$03,$03,$02,$00,$fe
        dc.b    $00,$ff,$01,$01,$fe,$ff,$03,$01,$01,$05,$04,$01,$00,$02,$01,$04
        dc.b    $04,$03,$03,$06,$09,$08,$07,$03,$fe,$fe,$fc,$fc,$ff,$ff,$ff,$fe
        dc.b    $ff,$05,$04,$02,$01,$ff,$fd,$fc,$ff,$fc,$f9,$f6,$f7,$f9,$fd,$02
        dc.b    $03,$05,$06,$04,$03,$04,$05,$06,$07,$04,$01,$02,$01,$03,$06,$05
        dc.b    $00,$fd,$fb,$f8,$fb,$fd,$f9,$fc,$ff,$00,$00,$00,$01,$03,$04,$05
        dc.b    $04,$03,$03,$03,$04,$03,$ff,$ff,$ff,$ff,$00,$fe,$fe,$ff,$00,$fe
        dc.b    $ff,$ff,$03,$07,$07,$02,$01,$00,$00,$ff,$ff,$fe,$fb,$fa,$f9,$f8
        dc.b    $fc,$02,$03,$04,$05,$05,$04,$07,$05,$06,$07,$04,$04,$03,$fe,$ff
        dc.b    $fe,$fc,$fb,$00,$02,$01,$02,$00,$fe,$fd,$ff,$fe,$00,$01,$00,$fd
        dc.b    $fa,$fa,$fb,$fb,$fc,$f8,$fb,$fc,$fc,$fd,$fe,$ff,$03,$04,$06,$06
        dc.b    $05,$05,$06,$07,$07,$09,$0c,$0c,$0b,$0a,$09,$06,$02,$03,$02,$02
        dc.b    $02,$01,$ff,$fe,$fc,$fc,$fc,$fa,$fb,$fd,$fe,$fe,$fd,$fc,$fa,$fb
        dc.b    $fc,$fa,$fc,$fc,$fd,$fd,$fd,$fd,$ff,$02,$01,$01,$01,$fe,$ff,$01
        dc.b    $00,$01,$02,$01,$ff,$04,$03,$01,$02,$05,$07,$0a,$09,$09,$07,$05
        dc.b    $06,$06,$06,$05,$07,$06,$04,$03,$04,$01,$ff,$fe,$fd,$fc,$fb,$f8
        dc.b    $f9,$fd,$ff,$fe,$fc,$00,$00,$00,$00,$fc,$f9,$fa,$f9,$f9,$fc,$fd
        dc.b    $fe,$fd,$fe,$ff,$ff,$06,$07,$07,$06,$04,$03,$07,$07,$0b,$0e,$0d
        dc.b    $07,$04,$02,$fe,$fe,$00,$01,$00,$00,$00,$fe,$ff,$fd,$fd,$fa,$f8
        dc.b    $fa,$fc,$fb,$ff,$01,$01,$02,$06,$02,$fe,$ff,$fa,$fa,$fc,$fe,$00
        dc.b    $00,$01,$ff,$fe,$00,$01,$01,$01,$03,$05,$03,$04,$02,$01,$03,$06
        dc.b    $08,$08,$0b,$0b,$07,$05,$04,$03,$00,$ff,$ff,$02,$03,$02,$02,$02
        dc.b    $01,$00,$ff,$ff,$fc,$fc,$fd,$fc,$fb,$fa,$fa,$fb,$fb,$fa,$f9,$fb
        dc.b    $fe,$ff,$ff,$fe,$fd,$fd,$fc,$fd,$ff,$03,$07,$09,$0b,$0d,$0b,$0e
        dc.b    $0e,$0a,$07,$05,$05,$03,$01,$ff,$fe,$00,$fd,$ff,$fe,$fd,$fd,$ff
        dc.b    $fc,$fa,$f8,$f8,$f8,$fb,$fb,$f9,$fb,$fb,$fc,$fe,$fc,$fd,$fd,$ff
        dc.b    $01,$00,$ff,$ff,$00,$02,$02,$02,$03,$05,$03,$01,$02,$00,$01,$01
        dc.b    $01,$02,$01,$05,$07,$09,$0a,$0a,$09,$07,$05,$05,$02,$00,$fe,$fd
        dc.b    $fb,$fb,$fb,$fb,$fe,$00,$ff,$fd,$fc,$fc,$fd,$fc,$f8,$f8,$fa,$fc
        dc.b    $ff,$01,$02,$03,$00,$ff,$00,$03,$05,$05,$04,$06,$0b,$0d,$0d,$0e
        dc.b    $0a,$07,$08,$06,$06,$02,$00,$00,$fc,$fd,$fd,$fd,$ff,$00,$01,$00
        dc.b    $00,$fe,$fb,$fd,$fa,$f8,$f8,$fa,$ff,$03,$01,$01,$01,$02,$04,$04
        dc.b    $04,$05,$04,$02,$02,$01,$ff,$fc,$fc,$fe,$02,$03,$06,$07,$04,$04
        dc.b    $04,$01,$00,$00,$01,$00,$02,$01,$01,$05,$04,$01,$02,$01,$00,$fc
        dc.b    $fe,$fd,$fe,$ff,$fe,$fc,$fd,$02,$00,$ff,$ff,$00,$01,$01,$03,$00
        dc.b    $fe,$fa,$f8,$fc,$fc,$fe,$02,$03,$03,$03,$04,$00,$ff,$01,$03,$03
        dc.b    $07,$06,$07,$07,$05,$04,$05,$04,$03,$00,$fc,$ff,$00,$fe,$fd,$fb
        dc.b    $fd,$fc,$fc,$fd,$fc,$fa,$fb,$ff,$fe,$00,$00,$00,$01,$03,$06,$03
        dc.b    $01,$01,$00,$01,$00,$fe,$ff,$00,$ff,$00,$01,$02,$02,$01,$fe,$fd
        dc.b    $fe,$fe,$00,$00,$ff,$ff,$01,$05,$04,$07,$07,$07,$09,$05,$01,$ff
        dc.b    $ff,$02,$04,$03,$03,$06,$03,$01,$00,$ff,$00,$ff,$fe,$fc,$fe,$fc
        dc.b    $ff,$05,$04,$00,$01,$00,$ff,$fe,$01,$00,$ff,$fe,$fe,$fe,$fc,$fe
        dc.b    $01,$00,$00,$ff,$fe,$ff,$00,$01,$00,$01,$ff,$ff,$00,$01,$05,$07
        dc.b    $08,$07,$05,$04,$03,$01,$00,$fe,$ff,$ff,$00,$ff,$fe,$00,$00,$ff
        dc.b    $ff,$02,$03,$02,$03,$00,$00,$00,$00,$01,$00,$ff,$ff,$00,$01,$ff
        dc.b    $01,$00,$fe,$fe,$fe,$fd,$fb,$fb,$fb,$fc,$fd,$fe,$ff,$00,$ff,$02
        dc.b    $03,$03,$06,$07,$06,$06,$03,$00,$00,$01,$05,$08,$09,$09,$08,$07
        dc.b    $07,$05,$05,$01,$00,$fe,$fe,$fc,$fb,$fc,$fc,$ff,$ff,$fc,$fb,$f9
        dc.b    $fa,$f8,$fa,$fd,$00,$ff,$ff,$fe,$ff,$ff,$ff,$fd,$ff,$00,$02,$00
        dc.b    $02,$00,$01,$04,$05,$06,$09,$08,$08,$08,$07,$07,$09,$09,$0a,$07
        dc.b    $06,$05,$05,$03,$03,$fe,$fc,$fc,$f8,$f7,$fa,$fc,$fb,$fc,$fd,$fe
        dc.b    $fc,$fd,$fc,$fb,$f9,$f8,$f7,$f7,$f9,$fd,$ff,$01,$02,$03,$04,$07
        dc.b    $07,$06,$04,$03,$03,$05,$07,$0a,$0b,$0c,$09,$0c,$0a,$0c,$0d,$0b
        dc.b    $06,$01,$02,$01,$02,$fd,$fc,$fc,$fb,$fe,$fd,$fc,$f8,$f5,$f4,$f6
        dc.b    $f2,$f4,$f9,$f8,$f8,$fa,$fd,$fc,$00,$02,$03,$04,$03,$04,$03,$02
        dc.b    $03,$05,$04,$02,$03,$03,$01,$03,$02,$00,$00,$00,$03,$04,$03,$01
        dc.b    $03,$03,$01,$ff,$00,$ff,$fe,$ff,$01,$00,$fc,$f8,$f9,$f9,$ff,$00
        dc.b    $fe,$fe,$fe,$fe,$ff,$03,$00,$00,$00,$fe,$fd,$fe,$ff,$ff,$ff,$01
        dc.b    $03,$04,$06,$07,$09,$07,$06,$07,$09,$08,$08,$08,$06,$03,$03,$03
        dc.b    $00,$02,$00,$ff,$fe,$ff,$00,$02,$02,$01,$00,$01,$00,$fe,$fe,$ff
        dc.b    $fe,$fc,$fc,$fc,$fc,$f9,$fa,$fb,$fb,$f9,$fa,$fa,$f8,$f8,$fa,$fa
        dc.b    $fb,$ff,$ff,$00,$01,$03,$03,$05,$07,$09,$08,$0a,$08,$07,$07,$04
        dc.b    $06,$07,$07,$08,$0b,$0a,$09,$08,$06,$04,$05,$04,$02,$01,$00,$fd
        dc.b    $fe,$ff,$00,$00,$ff,$fc,$fc,$fa,$f8,$f8,$fa,$fc,$fd,$ff,$00,$ff
        dc.b    $fe,$fc,$ff,$01,$01,$02,$04,$04,$01,$03,$00,$00,$01,$03,$03,$06
        dc.b    $05,$02,$01,$00,$ff,$01,$02,$fe,$fc,$fc,$fc,$fd,$ff,$ff,$ff,$02
        dc.b    $01,$03,$02,$02,$01,$00,$00,$01,$ff,$ff,$ff,$ff,$ff,$00,$00,$ff
        dc.b    $fe,$fe,$fd,$fd,$fd,$fe,$ff,$01,$03,$02,$04,$03,$01,$01,$03,$06
        dc.b    $09,$08,$04,$04,$03,$00,$01,$ff,$fe,$fe,$fc,$fc,$fe,$fe,$fe,$fe
        dc.b    $ff,$02,$01,$01,$fe,$ff,$ff,$ff,$00,$03,$03,$03,$02,$02,$01,$02
        dc.b    $01,$02,$02,$02,$02,$00,$ff,$01,$03,$03,$06,$04,$01,$03,$02,$ff
        dc.b    $fe,$fe,$ff,$00,$ff,$fd,$fd,$fe,$fd,$01,$00,$ff,$00,$01,$03,$04
        dc.b    $03,$02,$00,$02,$02,$02,$01,$02,$02,$01,$03,$04,$04,$04,$00,$fd
        dc.b    $fc,$fa,$f8,$f9,$f9,$fc,$fe,$fd,$ff,$01,$00,$01,$01,$ff,$ff,$00
        dc.b    $01,$ff,$02,$03,$02,$03,$04,$07,$07,$05,$03,$00,$ff,$00,$01,$02
        dc.b    $00,$00,$ff,$01,$02,$00,$fe,$ff,$ff,$ff,$00,$ff,$fe,$ff,$ff,$fe
        dc.b    $ff,$01,$02,$02,$04,$04,$03,$02,$00,$ff,$ff,$ff,$ff,$ff,$00,$01
        dc.b    $02,$02,$04,$05,$05,$02,$00,$ff,$00,$fe,$fc,$fa,$fa,$fc,$00,$01
        dc.b    $00,$00,$01,$04,$04,$05,$04,$03,$04,$02,$03,$07,$06,$03,$01,$00
        dc.b    $fe,$fc,$fe,$ff,$ff,$ff,$ff,$fe,$fc,$fd,$fb,$ff,$ff,$01,$03,$04
        dc.b    $02,$03,$02,$01,$ff,$00,$ff,$ff,$ff,$00,$02,$02,$06,$07,$05,$05
        dc.b    $04,$05,$02,$01,$ff,$ff,$ff,$01,$04,$04,$04,$07,$06,$03,$02,$00
        dc.b    $fe,$fc,$f8,$f8,$f8,$fa,$fc,$fd,$fe,$fe,$fb,$fb,$fc,$fe,$fe,$fe
        dc.b    $ff,$ff,$01,$02,$03,$02,$02,$03,$04,$05,$05,$04,$05,$03,$01,$03
        dc.b    $03,$01,$01,$00,$00,$01,$04,$03,$03,$06,$05,$04,$03,$02,$03,$02
        dc.b    $02,$01,$00,$fe,$fc,$fb,$fa,$f9,$fa,$fc,$fe,$ff,$01,$01,$ff,$fe
        dc.b    $fe,$fe,$fd,$fe,$fe,$fe,$fe,$00,$00,$01,$03,$03,$03,$04,$02,$02
        dc.b    $01,$01,$01,$03,$01,$03,$04,$04,$05,$03,$04,$06,$06,$06,$05,$03
        dc.b    $02,$03,$01,$01,$02,$04,$02,$03,$00,$fd,$fd,$fc,$fb,$f8,$f9,$fc
        dc.b    $fb,$fd,$ff,$ff,$fc,$fe,$ff,$fe,$fe,$ff,$ff,$02,$03,$05,$04,$03
        dc.b    $03,$02,$01,$01,$03,$02,$03,$02,$03,$04,$04,$02,$02,$02,$ff,$ff
        dc.b    $01,$01,$03,$03,$03,$03,$02,$00,$00,$ff,$00,$ff,$00,$fc,$ff,$ff
        dc.b    $01,$00,$ff,$00,$ff,$fe,$fe,$fd,$ff,$00,$00,$ff,$fe,$fe,$ff,$00
        dc.b    $01,$03,$03,$02,$02,$03,$00,$01,$ff,$00,$02,$02,$03,$03,$04,$04
        dc.b    $02,$00,$ff,$01,$00,$03,$02,$00,$ff,$fe,$ff,$01,$02,$02,$03,$02
        dc.b    $00,$00,$01,$fe,$fe,$fe,$fe,$fb,$fb,$fe,$fc,$fc,$fc,$fd,$fc,$fd
        dc.b    $fe,$fd,$fc,$fc,$fc,$fe,$01,$03,$06,$05,$04,$03,$04,$03,$06,$07
        dc.b    $07,$07,$06,$03,$05,$05,$04,$03,$03,$00,$00,$00,$fe,$fe,$ff,$fe
        dc.b    $00,$ff,$ff,$fe,$ff,$ff,$fe,$ff,$fe,$fe,$fd,$fc,$fe,$fd,$fc,$fe
        dc.b    $ff,$00,$00,$ff,$fe,$fe,$ff,$ff,$03,$03,$05,$06,$06,$07,$07,$04
        dc.b    $03,$04,$03,$03,$02,$00,$00,$02,$02,$03,$02,$03,$03,$03,$01,$00
        dc.b    $00,$fd,$fe,$ff,$fe,$fe,$ff,$fe,$fe,$fe,$fe,$ff,$ff,$fe,$fd,$fd
        dc.b    $fc,$fb,$fc,$fd,$fd,$fe,$ff,$00,$02,$06,$07,$07,$07,$08,$07,$07
        dc.b    $07,$06,$07,$06,$05,$05,$07,$05,$03,$01,$ff,$ff,$ff,$fe,$ff,$fa
        dc.b    $f9,$f8,$fa,$fb,$fc,$fb,$fb,$fc,$ff,$ff,$01,$00,$02,$03,$02,$03
        dc.b    $02,$02,$02,$00,$ff,$01,$03,$03,$04,$05,$04,$03,$06,$07,$07,$05
        dc.b    $06,$08,$07,$06,$03,$01,$01,$ff,$fe,$ff,$ff,$fe,$fe,$fc,$fc,$fd
        dc.b    $fd,$fb,$fb,$fb,$fb,$fc,$fe,$fe,$fe,$fd,$ff,$fe,$fe,$fe,$fd,$ff
        dc.b    $ff,$01,$01,$02,$05,$06,$08,$06,$06,$06,$07,$07,$07,$05,$02,$00
        dc.b    $01,$03,$03,$03,$04,$03,$01,$02,$01,$00,$fe,$fb,$f9,$fa,$fc,$fe
        dc.b    $fd,$ff,$03,$04,$03,$02,$03,$01,$00,$00,$00,$01,$00,$fe,$fc,$fd
        dc.b    $fc,$ff,$ff,$00,$03,$03,$01,$00,$ff,$ff,$ff,$fe,$fd,$ff,$ff,$ff
        dc.b    $00,$00,$fe,$fe,$00,$02,$01,$00,$00,$ff,$00,$01,$02,$01,$03,$03
        dc.b    $03,$02,$00,$00,$01,$02,$03,$00,$00,$00,$00,$ff,$00,$01,$03,$04
        dc.b    $05,$04,$03,$03,$01,$00,$00,$00,$02,$02,$01,$ff,$fd,$fe,$00,$01
        dc.b    $01,$00,$00,$00,$ff,$00,$01,$00,$00,$ff,$00,$fd,$fd,$fd,$fe,$fe
        dc.b    $fe,$fe,$fd,$fe,$ff,$ff,$03,$03,$03,$04,$03,$03,$05,$04,$03,$02
        dc.b    $02,$01,$04,$03,$00,$ff,$fa,$fb,$fc,$fc,$fd,$00,$ff,$00,$02,$03
        dc.b    $04,$05,$04,$03,$02,$00,$00,$fe,$fd,$fe,$ff,$00,$02,$02,$04,$02
        dc.b    $01,$00,$ff,$fd,$fe,$fe,$fd,$fe,$ff,$ff,$00,$03,$01,$03,$02,$ff
        dc.b    $fd,$fe,$fd,$ff,$01,$02,$03,$04,$04,$04,$07,$04,$04,$03,$03,$02
        dc.b    $01,$00,$00,$00,$ff,$fe,$ff,$00,$01,$03,$02,$ff,$ff,$fe,$fd,$fc
        dc.b    $fd,$fd,$fc,$fd,$fd,$ff,$03,$05,$04,$03,$01,$00,$ff,$00,$01,$01
        dc.b    $00,$01,$03,$05,$04,$03,$03,$03,$04,$05,$04,$02,$00,$00,$fd,$fd
        dc.b    $fd,$fe,$ff,$00,$00,$ff,$ff,$ff,$00,$ff,$ff,$01,$00,$ff,$ff,$00
        dc.b    $ff,$fe,$fe,$01,$01,$01,$01,$00,$fe,$fe,$fe,$00,$04,$06,$05,$03
        dc.b    $05,$03,$02,$02,$02,$01,$02,$00,$ff,$ff,$ff,$02,$02,$03,$03,$02
        dc.b    $01,$00,$00,$00,$ff,$fd,$fe,$ff,$fc,$fc,$fc,$fb,$fd,$fc,$fc,$fc
        dc.b    $fd,$fe,$fe,$ff,$ff,$ff,$00,$03,$06,$05,$07,$06,$05,$04,$05,$05
        dc.b    $03,$05,$04,$03,$03,$04,$05,$07,$05,$03,$02,$01,$01,$01,$ff,$fd
        dc.b    $ff,$ff,$fe,$ff,$ff,$fe,$fe,$fe,$fe,$ff,$fe,$fe,$fc,$fa,$fb,$fb
        dc.b    $fc,$fa,$fb,$fd,$fd,$ff,$01,$00,$ff,$ff,$01,$00,$00,$01,$04,$05
        dc.b    $07,$07,$06,$05,$03,$02,$01,$02,$02,$03,$04,$04,$03,$02,$02,$00
        dc.b    $00,$ff,$00,$ff,$02,$03,$03,$03,$02,$00,$00,$00,$ff,$00,$01,$ff
        dc.b    $00,$ff,$fc,$fd,$fd,$ff,$00,$00,$00,$00,$00,$01,$02,$02,$02,$02
        dc.b    $00,$01,$02,$02,$03,$03,$02,$02,$03,$01,$01,$00,$ff,$fe,$fd,$fe
        dc.b    $ff,$ff,$00,$00,$00,$01,$00,$01,$04,$03,$01,$01,$ff,$fd,$fe,$fe
        dc.b    $ff,$01,$01,$01,$ff,$00,$00,$fe,$fd,$fd,$fd,$fd,$ff,$ff,$00,$01
        dc.b    $04,$05,$05,$03,$05,$02,$03,$02,$00,$01,$01,$01,$02,$02,$01,$ff
        dc.b    $01,$ff,$00,$00,$01,$02,$00,$ff,$ff,$fe,$ff,$00,$ff,$ff,$ff,$00
        dc.b    $01,$01,$02,$01,$03,$01,$01,$00,$01,$00,$01,$01,$02,$02,$02,$03
        dc.b    $01,$00,$01,$00,$00,$03,$04,$03,$03,$03,$02,$02,$02,$ff,$fe,$fe
        dc.b    $fc,$fa,$fb,$fc,$fb,$fc,$fd,$fc,$fd,$fd,$ff,$ff,$01,$01,$01,$02
        dc.b    $02,$01,$02,$03,$03,$02,$05,$05,$06,$07,$04,$02,$00,$00,$01,$01
        dc.b    $01,$01,$01,$ff,$00,$fe,$00,$01,$01,$ff,$00,$00,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$fd,$ff,$02,$04,$03,$03,$03,$03,$00,$01,$01,$01,$ff,$ff
        dc.b    $ff,$00,$01,$01,$02,$03,$01,$02,$02,$01,$01,$00,$00,$ff,$02,$03
        dc.b    $03,$03,$01,$02,$02,$00,$ff,$fe,$ff,$fe,$fd,$fe,$fe,$fe,$ff,$ff
        dc.b    $00,$01,$00,$ff,$ff,$00,$ff,$ff,$ff,$00,$00,$00,$01,$01,$02,$01
        dc.b    $02,$03,$04,$04,$04,$05,$02,$04,$04,$03,$04,$02,$01,$01,$00,$ff
        dc.b    $00,$00,$fe,$01,$00,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fe,$fc,$ff
        dc.b    $ff,$00,$01,$00,$01,$03,$02,$02,$02,$01,$01,$02,$00,$00,$00,$fe
        dc.b    $ff,$ff,$00,$ff,$ff,$ff,$ff,$fd,$fd,$fc,$fe,$ff,$00,$ff,$ff,$ff
        dc.b    $01,$02,$02,$03,$04,$03,$03,$04,$05,$03,$03,$03,$02,$04,$03,$04
        dc.b    $03,$01,$01,$ff,$00,$01,$01,$00,$ff,$fe,$fe,$ff,$fe,$fe,$fe,$ff
        dc.b    $ff,$fe,$fd,$fb,$fd,$fd,$fd,$fe,$ff,$00,$01,$01,$01,$02,$02,$01
        dc.b    $00,$01,$00,$ff,$ff,$00,$01,$01,$00,$ff,$00,$01,$03,$03,$05,$05
        dc.b    $06,$05,$05,$04,$04,$03,$01,$01,$00,$01,$01,$01,$00,$ff,$ff,$01
        dc.b    $fe,$fc,$fa,$fb,$fd,$fd,$ff,$fe,$fe,$fd,$fe,$fd,$ff,$00,$00,$01
        dc.b    $01,$01,$02,$00,$00,$00,$00,$ff,$fd,$ff,$ff,$01,$01,$00,$02,$03
        dc.b    $02,$03,$04,$06,$06,$06,$04,$03,$03,$02,$00,$01,$02,$02,$01,$00
        dc.b    $00,$00,$00,$ff,$fe,$fe,$fe,$ff,$ff,$00,$00,$ff,$00,$fe,$ff,$01
        dc.b    $02,$02,$00,$ff,$ff,$01,$02,$03,$03,$03,$03,$00,$ff,$00,$01,$00
        dc.b    $00,$00,$01,$00,$00,$ff,$ff,$00,$00,$01,$03,$01,$00,$ff,$fe,$ff
        dc.b    $ff,$00,$00,$00,$01,$01,$02,$00,$00,$01,$00,$ff,$ff,$00,$02,$01
        dc.b    $01,$01,$02,$03,$04,$05,$04,$04,$03,$01,$01,$ff,$ff,$00,$fe,$ff
        dc.b    $fe,$fd,$fe,$ff,$fd,$fe,$ff,$ff,$00,$00,$ff,$02,$03,$04,$05,$04
        dc.b    $02,$ff,$ff,$ff,$fe,$fd,$ff,$ff,$00,$03,$01,$03,$05,$03,$01,$00
        dc.b    $00,$01,$04,$04,$03,$05,$01,$01,$00,$01,$04,$03,$03,$01,$ff,$00
        dc.b    $00,$01,$01,$00,$ff,$00,$01,$01,$00,$ff,$fd,$fd,$fc,$fe,$fe,$fe
        dc.b    $fd,$fc,$fe,$fc,$fe,$ff,$ff,$ff,$01,$01,$02,$03,$03,$02,$01,$01
        dc.b    $01,$02,$03,$03,$03,$05,$06,$05,$06,$03,$03,$02,$01,$ff,$ff,$fe
        dc.b    $fe,$00,$01,$00,$00,$00,$ff,$ff,$fe,$fc,$fc,$fd,$fc,$fe,$fd,$ff
        dc.b    $fe,$ff,$ff,$ff,$00,$01,$02,$01,$00,$ff,$ff,$ff,$01,$02,$03,$05
        dc.b    $04,$03,$02,$00,$00,$01,$03,$02,$02,$01,$02,$01,$03,$04,$04,$02
        dc.b    $03,$01,$00,$fe,$fc,$fc,$fe,$ff,$01,$01,$00,$ff,$ff,$fe,$ff,$01
        dc.b    $ff,$ff,$fd,$fd,$fe,$fc,$fb,$fe,$ff,$00,$01,$03,$02,$02,$02,$03
        dc.b    $03,$06,$05,$04,$05,$05,$06,$07,$05,$04,$04,$04,$03,$02,$00,$00
        dc.b    $00,$00,$ff,$ff,$ff,$fe,$fc,$fa,$fc,$fb,$fb,$fb,$fc,$fc,$fa,$fb
        dc.b    $fd,$fe,$fe,$ff,$fe,$ff,$ff,$ff,$ff,$00,$ff,$00,$01,$01,$02,$02
        dc.b    $03,$06,$06,$07,$07,$09,$08,$06,$05,$04,$03,$03,$01,$01,$01,$01
        dc.b    $02,$02,$01,$00,$00,$ff,$00,$00,$01,$00,$ff,$00,$fe,$fe,$ff,$fe
        dc.b    $fd,$fe,$fd,$fe,$fd,$fe,$fe,$fe,$fd,$fe,$fe,$fd,$fc,$ff,$ff,$01
        dc.b    $03,$04,$04,$03,$02,$01,$03,$03,$05,$05,$05,$04,$03,$04,$02,$01
        dc.b    $02,$02,$04,$05,$03,$01,$01,$00,$ff,$fe,$ff,$fc,$fd,$fd,$ff,$ff
        dc.b    $00,$00,$00,$02,$01,$02,$01,$01,$fe,$fd,$fd,$fe,$fe,$00,$ff,$ff
        dc.b    $ff,$00,$00,$00,$01,$00,$00,$ff,$00,$01,$02,$04,$05,$06,$06,$05
        dc.b    $05,$02,$02,$01,$00,$ff,$00,$fe,$fd,$ff,$00,$01,$01,$01,$00,$00
        dc.b    $ff,$ff,$fd,$fc,$fd,$fd,$fd,$fd,$ff,$ff,$ff,$ff,$01,$01,$01,$03
        dc.b    $03,$03,$03,$03,$03,$02,$02,$03,$04,$02,$02,$02,$02,$02,$04,$02
        dc.b    $02,$00,$ff,$01,$01,$00,$00,$01,$00,$ff,$ff,$ff,$fd,$fe,$fb,$fc
        dc.b    $fc,$fe,$fe,$fd,$ff,$ff,$00,$01,$01,$02,$03,$04,$03,$03,$04,$03
        dc.b    $03,$03,$01,$02,$03,$03,$03,$02,$01,$00,$ff,$00,$01,$01,$03,$01
        dc.b    $ff,$ff,$00,$01,$00,$00,$fd,$fc,$fe,$fd,$ff,$ff,$00,$00,$00,$ff
        dc.b    $00,$01,$02,$02,$02,$01,$02,$02,$01,$00,$fe,$fc,$fc,$fc,$fe,$ff
        dc.b    $ff,$00,$01,$01,$01,$03,$03,$05,$04,$03,$04,$03,$04,$05,$04,$02
        dc.b    $03,$02,$00,$ff,$ff,$fe,$ff,$00,$01,$ff,$01,$02,$01,$01,$ff,$00
        dc.b    $ff,$ff,$ff,$00,$00,$00,$00,$00,$01,$02,$00,$00,$ff,$00,$01,$01
        dc.b    $02,$01,$01,$03,$03,$03,$00,$01,$01,$fe,$fd,$fd,$fe,$fe,$fe,$00
        dc.b    $ff,$01,$01,$01,$00,$02,$02,$00,$00,$ff,$fe,$fe,$ff,$00,$00,$00
        dc.b    $00,$ff,$01,$03,$02,$01,$02,$03,$02,$02,$01,$02,$01,$01,$01,$ff
        dc.b    $00,$ff,$00,$00,$ff,$00,$ff,$ff,$00,$02,$03,$02,$01,$03,$03,$05
        dc.b    $04,$04,$04,$03,$04,$03,$02,$00,$00,$fd,$fc,$fe,$fc,$fc,$fc,$fd
        dc.b    $fc,$fc,$fd,$fc,$ff,$ff,$ff,$ff,$ff,$fe,$fd,$fd,$fc,$fe,$00,$01
        dc.b    $01,$03,$02,$03,$03,$04,$06,$07,$07,$06,$06,$04,$03,$04,$04,$03
        dc.b    $01,$00,$00,$01,$01,$02,$01,$01,$ff,$ff,$fe,$fe,$fd,$fe,$fe,$ff
        dc.b    $fe,$fe,$fc,$fc,$fd,$fc,$fe,$fe,$ff,$00,$ff,$ff,$fd,$fe,$ff,$01
        dc.b    $03,$02,$04,$06,$06,$04,$02,$00,$01,$03,$04,$05,$05,$04,$04,$02
        dc.b    $02,$01,$00,$fe,$fd,$fd,$fc,$fc,$ff,$00,$01,$02,$01,$00,$02,$02
        dc.b    $00,$01,$02,$01,$00,$01,$01,$01,$01,$ff,$00,$00,$01,$02,$01,$02
        dc.b    $ff,$00,$ff,$00,$00,$00,$00,$01,$00,$01,$00,$00,$ff,$fe,$fe,$fe
        dc.b    $ff,$00,$00,$00,$00,$01,$00,$ff,$ff,$00,$ff,$ff,$00,$ff,$00,$00
        dc.b    $01,$03,$02,$04,$04,$03,$03,$04,$03,$03,$04,$04,$03,$03,$04,$04
        dc.b    $04,$03,$02,$01,$00,$00,$ff,$ff,$ff,$01,$01,$00,$00,$ff,$01,$ff
        dc.b    $ff,$ff,$00,$fe,$fc,$fd,$fd,$fe,$fe,$fc,$fd,$fd,$fd,$fe,$fe,$fe
        dc.b    $ff,$00,$01,$02,$03,$02,$03,$04,$05,$05,$07,$07,$07,$07,$04,$03
        dc.b    $02,$01,$01,$03,$00,$00,$ff,$01,$01,$03,$03,$01,$00,$00,$fd,$fe
        dc.b    $fd,$fe,$fd,$fc,$fd,$fe,$fe,$ff,$ff,$fe,$fe,$fe,$fe,$ff,$fe,$fd
        dc.b    $fc,$fd,$ff,$02,$02,$03,$04,$02,$01,$00,$00,$02,$03,$02,$03,$02
        dc.b    $03,$02,$03,$03,$04,$05,$03,$02,$02,$03,$03,$03
; ===========================================================================
; Beathoven Synthesizer Song Data - Track 3 Sequencer & Notes.
; ===========================================================================
music_song_track_3_src:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$00,$ff,$fd,$fa,$f5,$f0,$ec,$ed,$f5,$fc,$fd,$f5,$e0,$cc
        dc.b    $c0,$bf,$ce,$e5,$ff,$13,$21,$27,$2a,$2f,$3b,$4f,$67,$7f,$74,$60
        dc.b    $52,$48,$40,$14,$f8,$e9,$e3,$e0,$da,$cc,$ba,$a6,$96,$92,$9b,$af
        dc.b    $c7,$db,$e8,$e6,$da,$cc,$c2,$c1,$ce,$e7,$ff,$17,$29,$31,$34,$37
        dc.b    $41,$53,$6b,$7f,$7f,$70,$60,$54,$4a,$28,$04,$f3,$ea,$e6,$e0,$d5
        dc.b    $c4,$b0,$9c,$95,$9b,$ab,$bf,$d7,$e7,$e8,$e0,$d0,$c5,$c2,$cb,$df
        dc.b    $fb,$13,$26,$2f,$33,$36,$3e,$4e,$65,$7d,$7f,$74,$63,$56,$4c,$38
        dc.b    $0a,$f8,$ec,$e7,$e2,$d8,$c8,$b4,$a0,$96,$98,$a7,$bd,$d3,$e5,$e8
        dc.b    $e2,$d4,$c8,$c2,$c9,$db,$f5,$0d,$1f,$2d,$32,$35,$3b,$47,$5d,$75
        dc.b    $7f,$7f,$66,$59,$4e,$42,$10,$fc,$ee,$e8,$e4,$db,$cc,$ba,$a5,$98
        dc.b    $97,$a3,$b7,$cd,$e1,$e8,$e4,$d8,$ca,$c3,$c7,$d7,$ef,$07,$1b,$2a
        dc.b    $30,$33,$38,$43,$56,$6e,$7f,$7f,$68,$5c,$50,$46,$18,$00,$f0,$e9
        dc.b    $e4,$dd,$d0,$c0,$ac,$9c,$97,$9f,$b3,$c7,$db,$e7,$e5,$da,$ce,$c5
        dc.b    $c5,$d1,$e7,$ff,$17,$27,$2f,$32,$36,$3f,$4f,$67,$7d,$7f,$6c,$60
        dc.b    $52,$48,$20,$04,$f2,$eb,$e6,$e0,$d4,$c4,$b0,$a0,$99,$9e,$ae,$c3
        dc.b    $d7,$e5,$e6,$e0,$d1,$c7,$c5,$cf,$e3,$fb,$13,$25,$2d,$31,$34,$3c
        dc.b    $4b,$5f,$77,$7f,$78,$62,$54,$4a,$30,$0a,$f8,$ed,$e7,$e2,$d8,$c8
        dc.b    $b6,$a4,$9a,$9c,$aa,$be,$d3,$e2,$e6,$e0,$d4,$c9,$c6,$cc,$de,$f7
        dc.b    $0d,$1f,$2b,$30,$33,$39,$46,$59,$6f,$7f,$7f,$64,$58,$4c,$40,$10
        dc.b    $fc,$f0,$e8,$e4,$da,$cd,$ba,$a9,$9c,$9b,$a7,$b7,$cd,$de,$e6,$e2
        dc.b    $d8,$cc,$c6,$cb,$d7,$ef,$07,$1b,$29,$2f,$31,$37,$41,$53,$67,$7d
        dc.b    $7f,$68,$5a,$50,$44,$18,$00,$f1,$ea,$e5,$de,$d1,$c0,$ae,$a0,$9b
        dc.b    $a3,$b3,$c7,$db,$e4,$e4,$da,$d0,$c8,$c9,$d5,$ea,$ff,$17,$26,$2e
        dc.b    $30,$34,$3d,$4e,$63,$77,$7f,$70,$60,$52,$46,$20,$04,$f4,$ec,$e7
        dc.b    $e0,$d4,$c4,$b2,$a4,$9c,$a1,$af,$c3,$d7,$e3,$e5,$dc,$d2,$ca,$c9
        dc.b    $d3,$e5,$fe,$13,$23,$2c,$2f,$32,$3a,$47,$5b,$6f,$7f,$7e,$60,$54
        dc.b    $49,$28,$0a,$f8,$ed,$e8,$e2,$d8,$c9,$b8,$a6,$9e,$9f,$ad,$bf,$d2
        dc.b    $df,$e5,$e0,$d6,$cc,$c9,$cf,$df,$f7,$0e,$1f,$2a,$2f,$31,$37,$43
        dc.b    $55,$6b,$7c,$7f,$64,$56,$4c,$30,$10,$fc,$f0,$ea,$e4,$dc,$ce,$bc
        dc.b    $ac,$a0,$9f,$a9,$bb,$ce,$dd,$e4,$e1,$d8,$ce,$ca,$ce,$dc,$f3,$07
        dc.b    $1b,$27,$2d,$30,$35,$3f,$4f,$63,$77,$7f,$68,$59,$4e,$40,$16,$00
        dc.b    $f2,$eb,$e6,$e0,$d1,$c0,$b0,$a3,$9f,$a7,$b7,$c9,$da,$e3,$e3,$da
        dc.b    $d0,$ca,$cd,$d9,$ed,$03,$17,$25,$2c,$2f,$33,$3b,$4b,$5e,$71,$7e
        dc.b    $78,$5d,$50,$44,$1c,$04,$f6,$ed,$e8,$e0,$d5,$c6,$b4,$a6,$a0,$a5
        dc.b    $b3,$c5,$d6,$e1,$e3,$dc,$d4,$cc,$cc,$d6,$e7,$ff,$13,$22,$2a,$2e
        dc.b    $31,$37,$46,$57,$6b,$7a,$7e,$60,$54,$48,$22,$09,$f8,$ee,$e9,$e3
        dc.b    $d8,$ca,$b8,$aa,$a2,$a3,$af,$bf,$d3,$df,$e3,$e0,$d6,$ce,$cc,$d3
        dc.b    $e3,$f7,$0f,$1f,$29,$2d,$30,$35,$41,$53,$65,$76,$7c,$68,$56,$4b
        dc.b    $2c,$10,$fc,$f1,$ea,$e4,$dc,$ce,$c0,$b0,$a4,$a3,$ac,$bb,$ce,$dc
        dc.b    $e3,$e0,$d8,$d0,$cd,$d1,$df,$f5,$09,$1b,$27,$2c,$2f,$33,$3e,$4d
        dc.b    $5f,$71,$7a,$70,$5a,$4e,$32,$14,$00,$f4,$ec,$e6,$e0,$d2,$c2,$b2
        dc.b    $a7,$a3,$aa,$b9,$ca,$d9,$e2,$e2,$da,$d2,$ce,$cf,$db,$ef,$03,$17
        dc.b    $23,$2b,$2e,$31,$3a,$47,$59,$6b,$77,$78,$5c,$50,$40,$1c,$05,$f8
        dc.b    $ee,$e8,$e1,$d6,$c8,$b8,$a9,$a4,$a7,$b5,$c5,$d5,$e1,$e2,$dd,$d5
        dc.b    $cf,$cf,$da,$eb,$ff,$13,$1f,$29,$2d,$30,$37,$43,$53,$65,$73,$76
        dc.b    $61,$54,$44,$22,$0a,$f9,$f0,$ea,$e4,$da,$cc,$bc,$ad,$a6,$a7,$b1
        dc.b    $bf,$d2,$df,$e3,$e0,$d8,$d0,$cf,$d7,$e7,$fb,$0e,$1d,$27,$2c,$2f
        dc.b    $34,$3f,$4f,$5f,$6f,$75,$6c,$56,$4a,$28,$10,$fc,$f2,$ec,$e5,$dc
        dc.b    $d0,$c0,$b0,$a8,$a7,$af,$bd,$cf,$dc,$e2,$e0,$da,$d2,$d0,$d5,$e3
        dc.b    $f7,$09,$19,$25,$2b,$2e,$32,$3b,$4a,$5b,$6b,$73,$70,$59,$4d,$30
        dc.b    $14,$01,$f4,$ec,$e7,$e0,$d4,$c4,$b5,$aa,$a7,$ad,$ba,$cb,$d9,$e1
        dc.b    $e1,$db,$d4,$d0,$d3,$df,$f1,$05,$16,$23,$29,$2c,$30,$38,$45,$55
        dc.b    $66,$71,$70,$60,$50,$35,$1c,$04,$f8,$f0,$e9,$e2,$d8,$c8,$b9,$ad
        dc.b    $a8,$ab,$b7,$c7,$d7,$e0,$e2,$dd,$d6,$d1,$d3,$dd,$ed,$ff,$13,$1f
        dc.b    $27,$2c,$2f,$35,$41,$4f,$5f,$6d,$70,$68,$54,$3a,$20,$0a,$fa,$f0
        dc.b    $ea,$e4,$da,$cd,$be,$b0,$a9,$ab,$b5,$c3,$d3,$de,$e2,$e0,$d8,$d3
        dc.b    $d3,$d9,$ea,$fd,$0f,$1d,$26,$2b,$2e,$33,$3d,$4b,$5b,$69,$6e,$68
        dc.b    $58,$40,$28,$10,$00,$f3,$ec,$e6,$dd,$d0,$c2,$b4,$ac,$ab,$b3,$bf
        dc.b    $cf,$dc,$e2,$e0,$da,$d4,$d3,$d8,$e6,$f7,$0b,$1a,$24,$29,$2c,$30
        dc.b    $39,$47,$57,$65,$6c,$6a,$5c,$48,$2c,$14,$00,$f5,$ee,$e8,$e0,$d4
        dc.b    $c6,$b8,$ae,$ab,$af,$bd,$cd,$d9,$e1,$e1,$dc,$d6,$d3,$d7,$e3,$f3
        dc.b    $05,$16,$22,$28,$2b,$2f,$37,$42,$53,$61,$6a,$6a,$60,$4c,$30,$18
        dc.b    $05,$f8,$f0,$ea,$e2,$d8,$ca,$bc,$b1,$ac,$af,$bb,$c9,$d7,$df,$e2
        dc.b    $e0,$d8,$d4,$d6,$df,$ef,$ff,$11,$1f,$27,$2a,$2e,$33,$3e,$4d,$5c
        dc.b    $67,$69,$61,$50,$38,$20,$09,$fc,$f2,$ec,$e6,$dc,$ce,$c0,$b4,$ae
        dc.b    $af,$b7,$c6,$d5,$de,$e2,$e0,$da,$d5,$d6,$de,$eb,$fd,$0e,$1d,$25
        dc.b    $29,$2c,$31,$3b,$49,$57,$63,$68,$63,$54,$40,$24,$0e,$00,$f4,$ed
        dc.b    $e7,$e0,$d2,$c4,$b8,$b0,$ae,$b6,$c3,$cf,$dc,$e2,$e1,$db,$d7,$d6
        dc.b    $db,$e7,$f9,$0b,$19,$23,$28,$2b,$2f,$38,$45,$53,$5f,$67,$64,$56
        dc.b    $40,$2a,$14,$02,$f6,$ef,$e9,$e1,$d6,$c8,$bb,$b2,$af,$b4,$bf,$ce
        dc.b    $da,$e1,$e2,$dd,$d8,$d6,$da,$e5,$f5,$07,$17,$21,$27,$2b,$2e,$35
        dc.b    $41,$4f,$5b,$65,$64,$59,$48,$30,$18,$05,$f8,$f1,$eb,$e4,$d9,$cc
        dc.b    $c0,$b4,$b0,$b3,$be,$cb,$d7,$e0,$e2,$e0,$da,$d7,$d9,$e3,$f2,$ff
        dc.b    $13,$1e,$26,$29,$2d,$33,$3c,$49,$57,$61,$63,$5c,$4a,$34,$1c,$09
        dc.b    $fc,$f3,$ed,$e6,$dc,$d0,$c3,$b8,$b1,$b2,$bb,$c7,$d5,$df,$e3,$e0
        dc.b    $dc,$d8,$d9,$e1,$ee,$ff,$0f,$1c,$24,$28,$2b,$30,$39,$45,$53,$5e
        dc.b    $62,$5c,$4e,$39,$24,$0c,$00,$f4,$ee,$e8,$e0,$d4,$c6,$ba,$b3,$b3
        dc.b    $b9,$c5,$d3,$dd,$e2,$e2,$dd,$d9,$d9,$df,$eb,$fb,$0b,$19,$23,$27
        dc.b    $2a,$2e,$36,$41,$4f,$5b,$61,$5e,$51,$40,$28,$11,$01,$f8,$f0,$ea
        dc.b    $e2,$d8,$ca,$be,$b6,$b2,$b7,$c1,$cf,$db,$e1,$e2,$de,$da,$d9,$dd
        dc.b    $e9,$f7,$07,$16,$1f,$26,$29,$2d,$33,$3e,$4b,$57,$5e,$60,$53,$41
        dc.b    $2c,$18,$06,$fa,$f2,$ec,$e5,$db,$d0,$c2,$b8,$b3,$b7,$bf,$cc,$d8
        dc.b    $e0,$e3,$e0,$dc,$d9,$dc,$e6,$f3,$03,$13,$1e,$25,$28,$2b,$31,$3b
        dc.b    $47,$53,$5c,$5e,$56,$44,$30,$1c,$09,$fc,$f4,$ee,$e7,$de,$d2,$c6
        dc.b    $bb,$b5,$b6,$be,$c9,$d6,$df,$e3,$e1,$dd,$da,$db,$e3,$f1,$ff,$0f
        dc.b    $1b,$23,$27,$2a,$2f,$37,$43,$4f,$59,$5c,$56,$48,$36,$20,$0e,$00
        dc.b    $f6,$f0,$e9,$e1,$d6,$c9,$be,$b7,$b6,$bc,$c7,$d3,$dd,$e3,$e2,$de
        dc.b    $db,$dc,$e1,$ed,$fb,$0b,$19,$21,$26,$29,$2d,$35,$3f,$4b,$56,$5b
        dc.b    $58,$4a,$39,$24,$11,$02,$f8,$f0,$ea,$e3,$d9,$cd,$c1,$b8,$b6,$bb
        dc.b    $c5,$cf,$db,$e2,$e3,$e0,$dd,$dc,$e0,$eb,$f9,$07,$16,$1f,$25,$28
        dc.b    $2c,$33,$3c,$47,$53,$59,$58,$50,$40,$29,$15,$05,$fa,$f3,$ed,$e5
        dc.b    $dc,$d0,$c4,$bb,$b7,$ba,$c3,$cf,$d9,$e1,$e3,$e1,$dd,$dc,$df,$e7
        dc.b    $f5,$03,$13,$1d,$23,$27,$2a,$2f,$39,$44,$4f,$57,$58,$50,$40,$30
        dc.b    $19,$08,$fc,$f4,$ef,$e8,$e0,$d4,$c8,$be,$b8,$ba,$bf,$cc,$d7,$df
        dc.b    $e3,$e2,$de,$dc,$de,$e6,$f2,$ff,$0f,$1b,$22,$26,$29,$2e,$35,$41
        dc.b    $4c,$55,$57,$52,$45,$32,$20,$0c,$00,$f6,$f0,$ea,$e2,$d8,$cc,$c0
        dc.b    $ba,$b9,$bf,$c9,$d5,$de,$e3,$e3,$e0,$dd,$de,$e4,$ef,$fe,$0d,$17
        dc.b    $1f,$25,$28,$2c,$33,$3d,$47,$51,$56,$52,$48,$38,$24,$10,$02,$f8
        dc.b    $f1,$ec,$e4,$da,$d0,$c4,$bc,$ba,$be,$c7,$d2,$dc,$e2,$e3,$e1,$de
        dc.b    $de,$e3,$ed,$fa,$09,$16,$1f,$24,$27,$2b,$30,$3a,$45,$4f,$54,$53
        dc.b    $4a,$39,$28,$14,$05,$fb,$f4,$ed,$e6,$dd,$d2,$c7,$be,$ba,$bd,$c5
        dc.b    $cf,$da,$e1,$e3,$e2,$e0,$de,$e1,$ea,$f7,$06,$13,$1d,$23,$26,$29
        dc.b    $2f,$37,$42,$4c,$52,$53,$4c,$40,$2c,$18,$08,$fd,$f5,$f0,$e8,$e0
        dc.b    $d5,$ca,$c0,$bc,$bc,$c3,$ce,$d7,$e0,$e3,$e3,$e0,$de,$e1,$e7,$f3
        dc.b    $ff,$0f,$1b,$21,$25,$28,$2c,$33,$3e,$49,$4f,$52,$4d,$41,$30,$1d
        dc.b    $0c,$00,$f8,$f1,$eb,$e4,$d8,$cd,$c3,$bd,$bd,$c2,$cb,$d6,$df,$e3
        dc.b    $e4,$e1,$e0,$e0,$e7,$f1,$ff,$0b,$17,$1f,$24,$27,$2b,$31,$3a,$45
        dc.b    $4e,$51,$4e,$44,$34,$20,$10,$02,$f9,$f2,$ec,$e5,$dc,$d0,$c6,$bf
        dc.b    $bd,$c1,$c9,$d3,$dd,$e3,$e4,$e2,$e0,$e0,$e5,$ef,$fb,$0a,$15,$1e
        dc.b    $23,$26,$29,$2f,$37,$42,$4b,$4f,$4e,$45,$38,$25,$14,$06,$fc,$f4
        dc.b    $ee,$e8,$e0,$d4,$c9,$c1,$be,$bf,$c7,$d1,$db,$e2,$e4,$e3,$e0,$e1
        dc.b    $e4,$ed,$f7,$06,$13,$1b,$22,$25,$28,$2d,$35,$3f,$47,$4e,$4e,$48
        dc.b    $3a,$28,$18,$08,$fe,$f6,$f0,$e9,$e1,$d6,$cc,$c3,$bf,$bf,$c6,$cf
        dc.b    $d9,$e0,$e4,$e3,$e1,$e1,$e3,$ea,$f5,$03,$0f,$19,$1f,$24,$27,$2b
        dc.b    $33,$3c,$45,$4c,$4e,$49,$40,$2c,$1c,$0c,$00,$f8,$f2,$ec,$e4,$da
        dc.b    $d0,$c6,$c0,$bf,$c5,$ce,$d7,$df,$e3,$e4,$e3,$e1,$e3,$e9,$f3,$ff
        dc.b    $0c,$17,$1f,$23,$26,$2a,$2f,$39,$42,$4a,$4d,$49,$40,$30,$20,$10
        dc.b    $02,$fa,$f3,$ed,$e6,$dc,$d2,$c8,$c2,$c0,$c4,$cb,$d5,$de,$e3,$e4
        dc.b    $e3,$e2,$e3,$e7,$f0,$fd,$0a,$15,$1d,$22,$25,$28,$2e,$36,$3f,$47
        dc.b    $4b,$4a,$40,$34,$23,$12,$05,$fc,$f5,$ee,$e8,$e0,$d5,$cc,$c4,$c1
        dc.b    $c3,$ca,$d3,$dc,$e3,$e5,$e4,$e2,$e3,$e7,$ef,$fa,$06,$13,$1b,$21
        dc.b    $24,$27,$2c,$33,$3c,$45,$4a,$4a,$43,$38,$26,$16,$08,$fe,$f6,$f0
        dc.b    $eb,$e2,$d8,$ce,$c6,$c1,$c3,$c7,$d1,$db,$e1,$e5,$e4,$e3,$e2,$e5
        dc.b    $ed,$f7,$03,$0f,$19,$1f,$23,$26,$2a,$30,$39,$42,$47,$49,$44,$39
        dc.b    $2c,$19,$0b,$00,$f8,$f2,$ec,$e4,$dc,$d1,$c8,$c3,$c3,$c7,$cf,$d9
        dc.b    $e0,$e4,$e5,$e3,$e3,$e5,$eb,$f3,$ff,$0d,$17,$1e,$22,$25,$28,$2f
        dc.b    $36,$3f,$46,$48,$45,$3c,$2d,$1d,$0e,$03,$fa,$f4,$ee,$e7,$e0,$d4
        dc.b    $cb,$c5,$c3,$c7,$ce,$d7,$df,$e4,$e5,$e4,$e3,$e5,$e9,$f2,$fe,$0a
        dc.b    $14,$1c,$21,$24,$27,$2c,$33,$3c,$43,$47,$45,$40,$31,$20,$11,$05
        dc.b    $fc,$f6,$f0,$e9,$e1,$d8,$ce,$c7,$c3,$c6,$cc,$d5,$dd,$e3,$e5,$e5
        dc.b    $e4,$e5,$e8,$ef,$fb,$07,$13,$1b,$1f,$23,$26,$2b,$31,$3a,$41,$46
        dc.b    $46,$40,$33,$24,$14,$08,$fe,$f8,$f1,$eb,$e3,$da,$d0,$c8,$c4,$c6
        dc.b    $cb,$d3,$db,$e2,$e5,$e6,$e4,$e4,$e7,$ee,$f9,$03,$0f,$19,$1e,$22
        dc.b    $25,$29,$2f,$37,$3f,$44,$45,$40,$36,$28,$18,$0a,$00,$f8,$f3,$ed
        dc.b    $e5,$dc,$d3,$cb,$c6,$c5,$c9,$d1,$da,$e1,$e5,$e6,$e5,$e4,$e7,$ed
        dc.b    $f6,$ff,$0d,$16,$1d,$21,$24,$27,$2d,$33,$3c,$43,$44,$41,$38,$2c
        dc.b    $1c,$0d,$02,$fa,$f4,$f0,$e8,$e0,$d6,$cd,$c7,$c6,$c9,$cf,$d8,$df
        dc.b    $e5,$e6,$e6,$e5,$e6,$eb,$f3,$ff,$0a,$14,$1b,$1f,$23,$26,$2a,$32
        dc.b    $39,$40,$43,$42,$3a,$2d,$20,$10,$05,$fc,$f6,$f0,$ea,$e2,$d9,$d0
        dc.b    $c9,$c7,$c9,$cf,$d7,$de,$e3,$e6,$e6,$e5,$e6,$ea,$f2,$fc,$07,$11
        dc.b    $19,$1f,$22,$25,$29,$2f,$37,$3e,$42,$42,$3c,$30,$24,$14,$08,$fe
        dc.b    $f8,$f2,$ec,$e4,$dc,$d2,$cb,$c7,$c8,$cd,$d5,$dd,$e3,$e6,$e6,$e5
        dc.b    $e6,$e9,$f0,$fa,$05,$0f,$17,$1e,$21,$24,$27,$2d,$34,$3c,$41,$41
        dc.b    $3c,$33,$26,$16,$0a,$00,$f9,$f3,$ee,$e6,$de,$d5,$cd,$c8,$c8,$cc
        dc.b    $d3,$db,$e2,$e5,$e6,$e6,$e6,$e8,$ee,$f7,$01,$0d,$16,$1c,$20,$23
        dc.b    $26,$2b,$33,$3a,$40,$41,$3e,$35,$29,$1a,$0c,$02,$fb,$f5,$f0,$e9
        dc.b    $e0,$d8,$d0,$ca,$c8,$cb,$d2,$d9,$e1,$e5,$e6,$e7,$e6,$e8,$ed,$f5
        dc.b    $ff,$0b,$13,$1b,$1f,$22,$25,$2a,$2f,$37,$3d,$40,$40,$36,$2c,$1e
        dc.b    $10,$04,$fc,$f6,$f1,$eb,$e4,$da,$d2,$cc,$c9,$cb,$cf,$d8,$df,$e5
        dc.b    $e7,$e7,$e7,$e7,$ec,$f3,$fd,$07,$11,$19,$1e,$21,$24,$28,$2e,$34
        dc.b    $3b,$3f,$3e,$38,$2e,$20,$13,$07,$fe,$f8,$f2,$ec,$e6,$dd,$d4,$cd
        dc.b    $ca,$cb,$cf,$d7,$de,$e4,$e7,$e7,$e7,$e7,$eb,$f2,$fb,$06,$0f,$17
        dc.b    $1c,$20,$23,$27,$2c,$32,$39,$3e,$3e,$39,$30,$24,$16,$09,$00,$f9
        dc.b    $f4,$ee,$e8,$e0,$d6,$d0,$cb,$cb,$ce,$d5,$dc,$e3,$e7,$e7,$e7,$e7
        dc.b    $ea,$f0,$f9,$03,$0d,$15,$1b,$1f,$22,$25,$2a,$30,$37,$3c,$3d,$39
        dc.b    $31,$26,$19,$0d,$02,$fb,$f5,$f0,$ea,$e2,$d9,$d2,$ce,$cc,$cf,$d4
        dc.b    $db,$e2,$e6,$e7,$e8,$e8,$ea,$ef,$f7,$ff,$0b,$13,$19,$1d,$20,$23
        dc.b    $27,$2d,$32,$37,$39,$38,$31,$28,$1c,$0f,$05,$fe,$f8,$f3,$ed,$e6
        dc.b    $de,$d6,$d1,$cf,$d0,$d5,$db,$e1,$e6,$e8,$e9,$e9,$eb,$ef,$f6,$ff
        dc.b    $07,$0f,$17,$1b,$1e,$21,$25,$29,$2f,$33,$36,$35,$30,$27,$1c,$11
        dc.b    $08,$00,$f9,$f4,$f0,$e9,$e2,$da,$d4,$d2,$d2,$d6,$db,$e1,$e6,$e8
        dc.b    $e9,$ea,$ec,$ef,$f5,$fd,$06,$0e,$14,$19,$1c,$1f,$22,$26,$2b,$2f
        dc.b    $33,$32,$2e,$27,$1d,$13,$08,$01,$fc,$f6,$f1,$ec,$e5,$de,$d8,$d4
        dc.b    $d4,$d7,$db,$e1,$e6,$e8,$ea,$eb,$ec,$ef,$f4,$fc,$03,$0c,$13,$17
        dc.b    $1b,$1d,$20,$23,$28,$2c,$2f,$30,$2c,$26,$1e,$14,$0c,$03,$fd,$f8
        dc.b    $f3,$ee,$e8,$e1,$dc,$d8,$d7,$d8,$dc,$e1,$e5,$e9,$eb,$ec,$ed,$ef
        dc.b    $f4,$fb,$02,$09,$0f,$15,$19,$1b,$1e,$21,$25,$29,$2c,$2d,$2b,$26
        dc.b    $1e,$15,$0c,$05,$ff,$fa,$f5,$f0,$eb,$e5,$e0,$db,$d9,$da,$dd,$e1
        dc.b    $e6,$e9,$eb,$ec,$ee,$f0,$f4,$f9,$ff,$07,$0e,$13,$17,$19,$1c,$1e
        dc.b    $22,$26,$29,$2a,$29,$24,$1e,$16,$0e,$06,$00,$fc,$f8,$f2,$ee,$e8
        dc.b    $e2,$de,$dc,$dc,$de,$e2,$e6,$e9,$ec,$ed,$ee,$f0,$f3,$f9,$ff,$06
        dc.b    $0c,$11,$15,$18,$1a,$1c,$1f,$23,$26,$28,$27,$24,$1e,$17,$10,$08
        dc.b    $01,$fd,$f8,$f4,$f0,$eb,$e5,$e1,$de,$dd,$df,$e2,$e6,$e9,$ec,$ed
        dc.b    $ef,$f1,$f3,$f8,$fe,$03,$0a,$0f,$13,$16,$18,$1b,$1d,$21,$23,$25
        dc.b    $25,$23,$1e,$18,$10,$09,$03,$fe,$fa,$f6,$f1,$ec,$e8,$e3,$e0,$e0
        dc.b    $e0,$e3,$e6,$e9,$ec,$ed,$ef,$f0,$f3,$f7,$fd,$03,$07,$0e,$11,$15
        dc.b    $17,$19,$1c,$1e,$21,$23,$24,$22,$1d,$18,$11,$0b,$05,$00,$fc,$f8
        dc.b    $f4,$f0,$ea,$e6,$e3,$e1,$e2,$e3,$e6,$e9,$ec,$ee,$f0,$f1,$f4,$f7
        dc.b    $fc,$01,$07,$0c,$0f,$13,$15,$17,$1a,$1c,$1e,$21,$21,$20,$1c,$18
        dc.b    $11,$0b,$06,$00,$fd,$f9,$f5,$f1,$ec,$e8,$e5,$e3,$e3,$e5,$e7,$ea
        dc.b    $ed,$ef,$f0,$f2,$f4,$f7,$fb,$ff,$06,$0a,$0f,$11,$14,$16,$18,$1a
        dc.b    $1c,$1e,$1f,$1e,$1c,$17,$12,$0c,$06,$02,$fe,$fa,$f6,$f2,$ee,$ea
        dc.b    $e7,$e5,$e4,$e6,$e7,$ea,$ed,$ef,$f0,$f2,$f4,$f7,$fb,$ff,$04,$09
        dc.b    $0d,$10,$13,$15,$16,$18,$1b,$1c,$1d,$1d,$1b,$18,$12,$0d,$08,$03
        dc.b    $ff,$fc,$f8,$f4,$f0,$ed,$e9,$e7,$e6,$e7,$e8,$eb,$ed,$ef,$f1,$f2
        dc.b    $f4,$f7,$fa,$fe,$02,$07,$0b,$0f,$11,$13,$15,$17,$19,$1b,$1c,$1c
        dc.b    $1a,$17,$13,$0d,$08,$04,$00,$fc,$f9,$f6,$f2,$ef,$eb,$e9,$e8,$e8
        dc.b    $e9,$eb,$ed,$ef,$f1,$f2,$f4,$f6,$f9,$fd,$01,$06,$0a,$0d,$0f,$12
        dc.b    $13,$15,$17,$19,$1a,$1a,$19,$16,$13,$0e,$0a,$05,$01,$fe,$fb,$f8
        dc.b    $f4,$f0,$ed,$eb,$e9,$e9,$ea,$ec,$ed,$f0,$f1,$f3,$f4,$f6,$f9,$fd
        dc.b    $01,$05,$09,$0c,$0f,$11,$12,$14,$16,$17,$18,$18,$18,$16,$13,$0e
        dc.b    $0a,$06,$01,$ff,$fc,$f8,$f5,$f2,$ef,$ec,$eb,$ea,$eb,$ec,$ee,$f0
        dc.b    $f2,$f3,$f5,$f7,$f9,$fc,$ff,$03,$07,$0b,$0e,$0f,$11,$13,$14,$16
        dc.b    $17,$18,$17,$15,$12,$0f,$0b,$06,$02,$00,$fc,$f9,$f6,$f3,$f0,$ee
        dc.b    $ec,$eb,$eb,$ed,$ee,$f0,$f2,$f3,$f5,$f7,$f9,$fc,$ff,$03,$06,$0a
        dc.b    $0c,$0e,$10,$11,$13,$14,$16,$16,$16,$15,$12,$0f,$0b,$07,$03,$00
        dc.b    $fe,$fb,$f8,$f5,$f2,$f0,$ee,$ec,$ec,$ed,$ef,$f0,$f2,$f3,$f5,$f7
        dc.b    $f9,$fb,$fe,$01,$05,$08,$0b,$0d,$0f,$10,$12,$13,$14,$15,$15,$13
        dc.b    $12,$0f,$0c,$08,$04,$01,$fe,$fc,$f9,$f6,$f3,$f1,$f0,$ee,$ee,$ee
        dc.b    $f0,$f1,$f2,$f4,$f5,$f7,$f9,$fb,$fe,$01,$04,$07,$0a,$0c,$0e,$0f
        dc.b    $10,$11,$13,$13,$13,$13,$11,$0f,$0b,$08,$05,$02,$ff,$fc,$fa,$f8
        dc.b    $f5,$f2,$f0,$f0,$ef,$ef,$f0,$f1,$f3,$f4,$f6,$f7,$f9,$fb,$fd,$00
        dc.b    $03,$07,$09,$0b,$0d,$0e,$0f,$10,$12,$12,$12,$12,$11,$0f,$0c,$09
        dc.b    $05,$02,$00,$fd,$fb,$f8,$f6,$f4,$f1,$f0,$f0,$f0,$f0,$f1,$f3,$f4
        dc.b    $f6,$f7,$f8,$fb,$fd,$ff,$03,$05,$08,$0a,$0c,$0d,$0f,$0f,$10,$11
        dc.b    $12,$11,$10,$0e,$0c,$09,$06,$03,$00,$fe,$fc,$f9,$f7,$f4,$f3,$f1
        dc.b    $f0,$f0,$f1,$f2,$f3,$f4,$f6,$f7,$f8,$fa,$fd,$ff,$02,$04,$07,$09
        dc.b    $0b,$0d,$0e,$0f,$0f,$11,$11,$11,$10,$0e,$0c,$09,$06,$03,$01,$ff
        dc.b    $fc,$fa,$f8,$f6,$f4,$f2,$f2,$f1,$f1,$f3,$f3,$f5,$f6,$f7,$f9,$fa
        dc.b    $fc,$ff,$01,$03,$06,$08,$0a,$0c,$0d,$0e,$0f,$0f,$10,$0f,$0f,$0e
        dc.b    $0c,$09,$06,$04,$01,$ff,$fd,$fb,$f9,$f7,$f5,$f4,$f2,$f2,$f2,$f3
        dc.b    $f4,$f5,$f6,$f8,$f9,$fa,$fc,$fe,$00,$03,$05,$07,$09,$0b,$0c,$0d
        dc.b    $0e,$0e,$0f,$0f,$0e,$0d,$0c,$09,$07,$04,$02,$00,$fe,$fc,$f9,$f8
        dc.b    $f6,$f4,$f3,$f3,$f3,$f3,$f5,$f6,$f7,$f8,$f9,$fb,$fc,$fe,$00,$02
        dc.b    $05,$07,$09,$0a,$0b,$0c,$0d,$0e,$0e,$0e,$0e,$0d,$0b,$09,$07,$05
        dc.b    $02,$00,$fe,$fc,$fb,$f9,$f7,$f5,$f4,$f4,$f4,$f4,$f5,$f6,$f7,$f8
        dc.b    $f9,$fa,$fc,$fe,$ff,$02,$04,$06,$08,$09,$0b,$0c,$0c,$0d,$0e,$0e
        dc.b    $0e,$0d,$0c,$0a,$07,$05,$03,$01,$ff,$fd,$fc,$f9,$f8,$f7,$f5,$f5
        dc.b    $f4,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fc,$fd,$ff,$01,$03,$05,$07,$08
        dc.b    $0a,$0a,$0b,$0c,$0c,$0d,$0c,$0c,$0b,$09,$07,$05,$03,$01,$00,$fe
        dc.b    $fc,$fa,$f8,$f8,$f6,$f5,$f5,$f5,$f6,$f6,$f7,$f8,$f9,$fa,$fc,$fd
        dc.b    $ff,$01,$03,$05,$06,$07,$09,$0a,$0b,$0b,$0c,$0c,$0c,$0c,$0b,$09
        dc.b    $07,$06,$04,$02,$00,$fe,$fc,$fb,$f9,$f8,$f7,$f6,$f6,$f6,$f6,$f7
        dc.b    $f8,$f8,$f9,$fb,$fc,$fd,$ff,$00,$02,$04,$06,$07,$08,$09,$0a,$0b
        dc.b    $0b,$0c,$0c,$0b,$0a,$09,$07,$06,$03,$02,$00,$ff,$fd,$fb,$fa,$f8
        dc.b    $f8,$f6,$f6,$f6,$f6,$f7,$f8,$f8,$f9,$fa,$fc,$fd,$ff,$00,$02,$04
        dc.b    $05,$07,$08,$09,$0a,$0a,$0b,$0b,$0b,$0b,$0a,$09,$07,$06,$04,$03
        dc.b    $01,$ff,$fe,$fc,$fb,$fa,$f8,$f8,$f7,$f7,$f7,$f8,$f8,$f8,$fa,$fb
        dc.b    $fc,$fd,$fe,$ff,$01,$03,$04,$06,$07,$08,$09,$0a,$0a,$0a,$0a,$0b
        dc.b    $0a,$09,$07,$06,$04,$03,$01,$00,$fe,$fd,$fc,$fa,$f9,$f8,$f8,$f7
        dc.b    $f8,$f8,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff,$01,$02,$04,$05,$07,$07
        dc.b    $08,$09,$09,$0a,$0a,$0a,$09,$08,$07,$06,$04,$03,$01,$00,$ff,$fd
        dc.b    $fc,$fb,$fa,$f9,$f8,$f8,$f8,$f8,$f8,$f9,$fa,$fb,$fc,$fc,$fe,$ff
        dc.b    $01,$02,$03,$05,$06,$07,$07,$08,$09,$09,$09,$09,$09,$08,$07,$06
        dc.b    $05,$03,$02,$00,$ff,$fe,$fc,$fb,$fa,$f9,$f8,$f8,$f8,$f8,$f9,$f9
        dc.b    $fa,$fb,$fc,$fc,$fe,$ff,$00,$01,$03,$04,$05,$07,$07,$07,$08,$09
        dc.b    $09,$09,$09,$08,$07,$06,$05,$04,$02,$00,$ff,$fe,$fd,$fc,$fb,$fa
        dc.b    $f9,$f9,$f8,$f8,$f9,$f9,$fa,$fb,$fc,$fc,$fe,$ff,$ff,$01,$02,$04
        dc.b    $05,$06,$07,$07,$08,$09,$09,$09,$08,$08,$07,$06,$05,$04,$02,$01
        dc.b    $00,$ff,$fe,$fd,$fc,$fa,$fa,$f9,$f9,$f9,$f9,$fa,$fa,$fb,$fc,$fc
        dc.b    $fe,$ff,$ff,$01,$02,$03,$05,$05,$06,$07,$07,$08,$08,$08,$08,$07
        dc.b    $07,$06,$05,$04,$02,$01,$00,$ff,$fe,$fd,$fc,$fb,$fa,$fa,$fa,$f9
        dc.b    $f9,$fa,$fb,$fb,$fc,$fc,$fe,$ff,$ff,$01,$02,$03,$04,$05,$06,$06
        dc.b    $07,$07,$07,$07,$07,$07,$07,$06,$05,$04,$02,$01,$00,$ff,$fe,$fd
        dc.b    $fc,$fc,$fb,$fa,$fa,$fa,$fa,$fa,$fb,$fb,$fc,$fd,$fe,$ff,$ff,$00
        dc.b    $01,$03,$03,$04,$05,$06,$07,$07,$07,$07,$07,$07,$06,$06,$05,$04
        dc.b    $03,$02,$00,$ff,$fe,$fe,$fd,$fc,$fb,$fa,$fa,$fa,$fa,$fa,$fb,$fc
        dc.b    $fc,$fd,$fd,$fe,$ff,$00,$01,$02,$03,$04,$05,$06,$06,$07,$07,$07
        dc.b    $07,$07,$06,$06,$05,$04,$03,$02,$01,$00,$ff,$fe,$fd,$fc,$fc,$fb
        dc.b    $fb,$fa,$fb,$fb,$fb,$fc,$fc,$fd,$fd,$fe,$ff,$00,$01,$02,$02,$03
        dc.b    $04,$05,$06,$06,$06,$06,$07,$06,$06,$06,$05,$04,$03,$02,$01,$00
        dc.b    $ff,$ff,$fe,$fd,$fc,$fc,$fb,$fb,$fb,$fb,$fb,$fc,$fc,$fd,$fe,$fe
        dc.b    $ff,$ff,$01,$02,$03,$03,$04,$05,$05,$06,$06,$06,$06,$06,$06,$06
        dc.b    $05,$04,$03,$02,$01,$00,$ff,$ff,$fe,$fd,$fc,$fc,$fc,$fc,$fb,$fb
        dc.b    $fc,$fc,$fc,$fd,$fd,$fe,$ff,$00,$00,$01,$02,$03,$03,$04,$05,$05
        dc.b    $06,$06,$06,$06,$06,$05,$05,$04,$03,$02,$01,$00,$00,$ff,$fe,$fd
        dc.b    $fc,$fc,$fc,$fb,$fb,$fb,$fc,$fc,$fc,$fd,$fd,$fe,$ff,$ff,$00,$01
        dc.b    $02,$03,$04,$04,$05,$05,$05,$06,$06,$06,$06,$05,$05,$04,$03,$02
        dc.b    $01,$01,$00,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd
        dc.b    $fe,$fe,$ff,$ff,$00,$01,$02,$03,$03,$04,$04,$05,$05,$05,$06,$05
        dc.b    $05,$05,$04,$04,$03,$03,$02,$00,$00,$ff,$ff,$fe,$fe,$fd,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fd,$fd,$fe,$fe,$ff,$ff,$00,$01,$01,$02,$03,$03
        dc.b    $04,$04,$05,$05,$05,$05,$05,$05,$04,$04,$03,$02,$02,$01,$00,$00
        dc.b    $ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fd,$fd,$fd,$fe,$fe,$ff,$ff
        dc.b    $00,$00,$01,$02,$03,$03,$04,$04,$04,$05,$05,$05,$05,$05,$04,$03
        dc.b    $03,$02,$02,$01,$00,$00,$ff,$ff,$fe,$fd,$fd,$fd,$fd,$fc,$fc,$fd
        dc.b    $fd,$fd,$fe,$fe,$ff,$ff,$00,$00,$01,$02,$02,$03,$03,$04,$04,$04
        dc.b    $05,$05,$05,$04,$04,$04,$03,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe
        dc.b    $fd,$fd,$fc,$fd,$fc,$fd,$fd,$fd,$fe,$fe,$ff,$ff,$ff,$00,$01,$01
        dc.b    $02,$03,$03,$04,$04,$04,$05,$05,$05,$04,$04,$04,$03,$03,$02,$01
        dc.b    $01,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
        dc.b    $fe,$ff,$ff,$00,$01,$01,$02,$02,$03,$03,$04,$04,$04,$04,$04,$04
        dc.b    $04,$04,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd
        dc.b    $fd,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$01,$01,$02,$02,$03,$03
        dc.b    $03,$04,$04,$04,$04,$04,$04,$03,$03,$02,$02,$01,$01,$00,$ff,$ff
        dc.b    $ff,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00
        dc.b    $01,$01,$01,$02,$02,$03,$03,$03,$04,$04,$04,$04,$04,$03,$03,$03
        dc.b    $02,$02,$01,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fd,$fe,$fe,$fe
        dc.b    $fe,$fe,$ff,$ff,$ff,$00,$00,$01,$01,$02,$02,$03,$03,$03,$04,$04
        dc.b    $04,$04,$03,$03,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$ff,$fe,$fe
        dc.b    $fe,$fe,$fe,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$00,$01,$01
        dc.b    $02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$01,$01
        dc.b    $00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff
        dc.b    $ff,$00,$00,$00,$01,$01,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03
        dc.b    $03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$02,$02,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$01,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$00
        dc.b    $01,$01,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02
        dc.b    $01,$01,$01,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$ff
        dc.b    $ff,$ff,$ff,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$03
        dc.b    $03,$03,$03,$02,$02,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$00,$00,$00,$01,$01,$01,$01
        dc.b    $02,$02,$02,$02,$03,$03,$03,$03,$03,$02,$02,$02,$01,$01,$01,$00
        dc.b    $00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $00,$00,$00,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03,$03,$02,$02
        dc.b    $02,$01,$01,$01,$01,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$01,$01,$02,$02,$02,$03
        dc.b    $02,$03,$03,$03,$02,$02,$02,$02,$02,$01,$00,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$fe,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00
        dc.b    $01,$01,$01,$02,$02,$02,$03,$03,$03,$03,$03,$02,$02,$02,$01,$01
        dc.b    $01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$00,$00,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02
        dc.b    $02,$02,$02,$02,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$01,$01,$01,$01
        dc.b    $02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00
        dc.b    $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00
        dc.b    $00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$02
        dc.b    $01,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$00,$ff,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02
        dc.b    $02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$01
        dc.b    $01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01
        dc.b    $01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $00,$00,$00,$00,$00,$00,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02
        dc.b    $02,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$00,$ff,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01
        dc.b    $01,$02,$02,$01,$02,$02,$02,$01,$01,$01,$01,$01,$00,$00,$00,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00
        dc.b    $00,$00,$01,$01,$01,$01,$02,$01,$02,$02,$02,$02,$02,$01,$01,$01
        dc.b    $01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00,$ff,$00,$00,$00,$00,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$00,$00,$ff,$00
        dc.b    $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01
        dc.b    $01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$ff,$00,$ff,$ff,$ff
        dc.b    $ff,$00,$ff,$00,$00,$ff,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00
        dc.b    $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$01,$01,$01
        dc.b    $01,$01,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$ff
        dc.b    $ff,$ff,$00,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00
        dc.b    $00,$00,$ff,$ff,$00,$ff,$ff,$00,$ff,$00,$ff,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$ff,$00,$ff,$00,$ff,$ff
        dc.b    $00,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$ff,$ff,$ff,$ff,$00,$00,$ff,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $00,$01,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$00,$ff,$00,$ff,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$00
        dc.b    $ff,$00,$ff,$00,$00,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$00,$00,$00,$00,$00
        dc.b    $00,$00,$ff,$00,$ff,$00,$ff,$ff,$00,$ff,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$00,$00,$00
        dc.b    $ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$ff,$ff,$00,$00,$00,$00,$ff,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$01,$00,$01,$01,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff
        dc.b    $00,$ff,$00,$00,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$00,$00,$00,$00
        dc.b    $00,$00,$00,$ff,$00,$00,$00,$ff,$ff,$00,$00,$00,$00,$ff,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$ff,$00,$00,$ff,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $00,$01,$00,$00,$00,$00,$00,$00,$00,$00
; ===========================================================================
; Beathoven Synthesizer Song Data - Track 4 Sequencer & Notes.
; ===========================================================================
music_song_track_4_src:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00
        dc.b    $00,$01,$01,$01,$02,$03,$03,$03,$03,$03,$03,$03,$02,$01,$00,$fe
        dc.b    $fc,$fa,$f8,$f5,$f2,$ef,$ec,$e8,$e4,$e1,$dd,$da,$d7,$d4,$d1,$ce
        dc.b    $cb,$c9,$c9,$ce,$da,$e9,$ff,$19,$33,$4f,$6b,$7f,$7f,$7f,$7f,$78
        dc.b    $69,$5c,$50,$45,$3c,$34,$18,$e2,$ba,$94,$80,$80,$80,$80,$89,$99
        dc.b    $a6,$db,$07,$37,$5f,$7f,$7f,$7f,$70,$60,$30,$00,$d4,$ac,$8e,$80
        dc.b    $80,$8d,$a3,$bf,$e7,$ff,$17,$21,$21,$16,$00,$ec,$d8,$c8,$bf,$c2
        dc.b    $cb,$d9,$e7,$f6,$ff,$05,$05,$02,$fe,$fc,$fa,$fb,$fe,$05,$0f,$1f
        dc.b    $35,$4d,$67,$7f,$7f,$7f,$7f,$7f,$74,$66,$59,$4e,$42,$39,$30,$2a
        dc.b    $23,$e8,$c0,$a0,$84,$80,$80,$80,$80,$87,$97,$a3,$af,$ba,$d7,$ef
        dc.b    $07,$1f,$36,$49,$5b,$67,$71,$77,$79,$78,$70,$58,$4d,$43,$3a,$31
        dc.b    $29,$10,$00,$f0,$e0,$cc,$be,$b0,$a4,$99,$92,$8c,$88,$87,$88,$8f
        dc.b    $a6,$b1,$bb,$c5,$cd,$d4,$db,$e2,$e7,$ef,$1f,$4f,$7f,$7f,$7f,$7f
        dc.b    $7f,$7c,$40,$0c,$f4,$f9,$13,$3b,$63,$54,$40,$38,$28,$e0,$ba,$b3
        dc.b    $cb,$f3,$1f,$3b,$3c,$20,$f0,$c2,$a6,$a7,$c7,$f7,$1e,$2f,$20,$f8
        dc.b    $ca,$ab,$a7,$bb,$df,$fd,$06,$f8,$da,$bc,$ad,$b1,$c7,$e2,$f0,$f0
        dc.b    $e2,$d0,$c5,$c7,$d3,$e3,$ef,$f0,$ec,$e3,$df,$df,$e7,$f0,$f6,$f8
        dc.b    $f8,$f6,$f5,$f4,$fe,$0f,$25,$3d,$5f,$7f,$7f,$7f,$7f,$7f,$7a,$6c
        dc.b    $60,$52,$40,$00,$d4,$b8,$a1,$97,$97,$9b,$a3,$af,$be,$cf,$df,$f3
        dc.b    $07,$1b,$2d,$3e,$4d,$5b,$67,$72,$74,$58,$4c,$42,$39,$31,$29,$23
        dc.b    $1d,$18,$14,$0f,$0c,$f8,$e8,$d8,$c8,$ba,$ac,$a0,$94,$8b,$84,$80
        dc.b    $80,$80,$80,$9a,$a7,$b3,$bd,$c7,$cf,$d7,$dd,$e3,$e9,$ee,$f2,$f6
        dc.b    $f9,$4b,$6f,$66,$5a,$65,$7b,$7f,$7f,$78,$50,$3b,$3d,$53,$65,$60
        dc.b    $38,$08,$f9,$07,$2d,$3d,$28,$f0,$cc,$d3,$ff,$27,$22,$f0,$b8,$b5
        dc.b    $df,$1d,$24,$f4,$b4,$a7,$df,$1f,$22,$e8,$a2,$9d,$df,$17,$10,$d0
        dc.b    $98,$9f,$e7,$0f,$f8,$c0,$9a,$bb,$fb,$09,$e0,$b0,$b5,$df,$09,$f8
        dc.b    $d0,$c3,$df,$ff,$02,$e8,$d9,$ea,$ff,$01,$f4,$f5,$1f,$5f,$7d,$70
        dc.b    $48,$4c,$6f,$7d,$58,$20,$f0,$f4,$f2,$f0,$f1,$f6,$fe,$07,$0f,$1b
        dc.b    $27,$33,$3d,$49,$52,$5b,$62,$60,$4a,$40,$36,$2e,$28,$21,$1c,$17
        dc.b    $12,$0e,$0b,$08,$05,$03,$00,$fe,$fd,$f8,$e0,$d1,$c2,$b4,$a8,$9c
        dc.b    $91,$88,$81,$80,$80,$80,$80,$93,$9f,$af,$ba,$c3,$cc,$d4,$db,$e2
        dc.b    $e7,$ec,$f1,$f5,$f8,$fb,$fe,$00,$4f,$78,$44,$00,$ff,$7f,$7f,$7f
        dc.b    $28,$e7,$4f,$7f,$7f,$68,$c0,$f7,$7f,$70,$4e,$b0,$ab,$2f,$7f,$40
        dc.b    $d0,$80,$df,$6f,$48,$00,$80,$9f,$3f,$7a,$20,$84,$80,$ef,$6f,$40
        dc.b    $b0,$80,$af,$37,$50,$e0,$80,$87,$f7,$3c,$00,$a0,$80,$bf,$1b,$1a
        dc.b    $c8,$92,$af,$f7,$19,$f4,$00,$07,$73,$00,$04,$e0,$cc,$e8,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$f7,$f5,$f9,$f5,$e1,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$f7,$f5,$f9,$f5,$e1,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$f7,$f5,$f9
        dc.b    $f5,$e1,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f7,$f5,$f9,$f5,$e1,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$f7,$f5,$f9,$f5,$e1,$f5,$f6,$f5,$e1,$f5,$f3
        dc.b    $f5,$f7,$f5,$fd,$f5,$e7,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f7,$f5,$fd
        dc.b    $f5,$e7,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f7,$f5,$fd,$f5,$e7,$f5,$f6
        dc.b    $f5,$e1,$f5,$f3,$f5,$f7,$f5,$fd,$f5,$e7,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$f7,$f5,$fd,$f5,$e7,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f7,$f5,$fd
        dc.b    $f5,$e7,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$f7,$f5,$fd,$f5,$e5,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$f7,$f5,$fd,$f5,$e5,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$f7,$f5,$fd,$f5,$e5,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$f7,$f5,$fd
        dc.b    $f5,$e5,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f7,$f5,$fd,$f5,$e5,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$f7,$f5,$fd,$f5,$e5,$f5,$f5,$f5,$f5,$f5,$f0
        dc.b    $f7,$75,$f5,$f5,$f5,$f5,$f5,$f4,$f5,$fb,$26,$0d,$f5,$ef,$f5,$e1
        dc.b    $f5,$ef,$f5,$ff,$f5,$ef,$f5,$ff,$f5,$e3,$f5,$e1,$f5,$ef,$f5,$ff
        dc.b    $f5,$ef,$f5,$e1,$f5,$ef,$f5,$ff,$f5,$ef,$f5,$ff,$f5,$ef,$f5,$ff
        dc.b    $f5,$e3,$f5,$ff,$f5,$ef,$f5,$ff,$f5,$e3,$f5,$ff,$f5,$ef,$f5,$ff
        dc.b    $f5,$f5,$f5,$f5,$f5,$f4,$f5,$fb,$26,$b4,$f5,$f6,$f5,$e1,$f5,$f3
        dc.b    $f5,$ef,$f5,$d5,$f5,$dd,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$ef,$f5,$d5
        dc.b    $f5,$dd,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$ef,$f5,$d5,$f5,$dd,$f5,$f6
        dc.b    $f5,$e1,$f5,$f3,$f5,$ef,$f5,$d5,$f5,$dd,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$ef,$f5,$d5,$f5,$dd,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$ef,$f5,$d5
        dc.b    $f5,$dd,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$e3,$f5,$d5,$f5,$dd,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$e3,$f5,$d5,$f5,$dd,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$e3,$f5,$d5,$f5,$dd,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$e3,$f5,$d5
        dc.b    $f5,$dd,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$e3,$f5,$d5,$f5,$dd,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$e3,$f5,$d5,$f5,$dd,$f5,$f6,$f5,$e1,$f5,$f3
        dc.b    $f5,$e3,$f5,$eb,$f5,$d1,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$e3,$f5,$eb
        dc.b    $f5,$d1,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$e3,$f5,$eb,$f5,$d1,$f5,$f6
        dc.b    $f5,$e1,$f5,$f3,$f5,$e3,$f5,$eb,$f5,$d1,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$e3,$f5,$eb,$f5,$d1,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$e3,$f5,$eb
        dc.b    $f5,$d1,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$ef,$f5,$eb,$f5,$dd,$f5,$f6
        dc.b    $f5,$ff,$f5,$f3,$f5,$ef,$f5,$eb,$f5,$dd,$f5,$f6,$f5,$ff,$f5,$f3
        dc.b    $f5,$ef,$f5,$eb,$f5,$dd,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$ef,$f5,$eb
        dc.b    $f5,$dd,$f5,$f6,$f5,$ff,$f5,$f3,$f5,$ef,$f5,$eb,$f5,$dd,$f5,$f6
        dc.b    $f5,$e1,$f5,$f3,$f5,$ed,$f5,$eb,$f5,$dd,$f5,$f6,$f5,$ff,$f5,$f3
        dc.b    $f5,$ed,$f5,$eb,$f5,$dd,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$ed,$f5,$eb
        dc.b    $f5,$dd,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$ed,$f5,$eb,$f5,$dd,$f5,$f6
        dc.b    $f5,$e1,$f5,$f3,$f5,$ed,$f5,$eb,$f5,$dd,$f5,$f5,$f5,$f5,$f5,$f4
        dc.b    $f5,$fb,$26,$15,$f5,$ef,$f5,$e1,$f5,$ef,$f5,$e1,$f5,$d5,$f5,$e1
        dc.b    $f5,$ef,$f5,$ff,$f5,$d1,$f5,$e1,$f5,$ef,$f5,$ff,$f5,$dd,$f5,$e1
        dc.b    $f5,$d1,$f5,$e1,$f5,$d5,$f5,$e1,$f5,$d5,$f5,$e1,$f5,$d5,$f5,$e1
        dc.b    $f5,$dd,$f5,$e1,$f5,$d5,$f5,$ff,$f5,$df,$f5,$e1,$f5,$d5,$f5,$ff
        dc.b    $f5,$db,$f5,$e1,$f5,$df,$f5,$e1,$f5,$dd,$f5,$e1,$f5,$e3,$f5,$e1
        dc.b    $f5,$e3,$f5,$e1,$f5,$eb,$f5,$e1,$f5,$e3,$f5,$ff,$f5,$d5,$f5,$e1
        dc.b    $f5,$e3,$f5,$ff,$f5,$d1,$f5,$e1,$f5,$d5,$f5,$e1,$f5,$eb,$f5,$e1
        dc.b    $f5,$dd,$f5,$ff,$f5,$dd,$f5,$ff,$f5,$d1,$f5,$e1,$f5,$d5,$f5,$e1
        dc.b    $f5,$eb,$f5,$e1,$f5,$ef,$f5,$e1,$f5,$eb,$f5,$ff,$f5,$ef,$f5,$c7
        dc.b    $f5,$f5,$f5,$f5,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$ff,$f5,$e5,$f5,$ef,$f5,$f6,$f5,$e1,$f5,$f3
        dc.b    $f5,$fd,$f5,$e5,$f5,$e3,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$fd,$f5,$e5
        dc.b    $f5,$e3,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$fd,$f5,$e5,$f5,$e3,$f5,$f6
        dc.b    $f5,$e1,$f5,$f3,$f5,$fd,$f5,$e5,$f5,$e3,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$fd,$f5,$e5,$f5,$e3,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$fd,$f5,$e5
        dc.b    $f5,$e3,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$f3,$f5,$f9,$f5,$e3,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$f3,$f5,$f9,$f5,$e3,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$f3,$f5,$f9,$f5,$e3,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$f3,$f5,$f9
        dc.b    $f5,$e3,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f3,$f5,$f9,$f5,$e3,$f5,$f6
        dc.b    $f5,$eb,$f5,$f3,$f5,$f3,$f5,$f9,$f5,$e3,$f5,$f6,$f5,$e1,$f5,$f3
        dc.b    $f5,$f3,$f5,$f9,$f5,$e1,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f3,$f5,$f9
        dc.b    $f5,$e1,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f3,$f5,$f9,$f5,$e1,$f5,$f6
        dc.b    $f5,$e1,$f5,$f3,$f5,$f3,$f5,$f9,$f5,$e1,$f5,$f6,$f5,$eb,$f5,$f3
        dc.b    $f5,$f3,$f5,$f9,$f5,$e1,$f5,$f6,$f5,$eb,$f5,$f3,$f5,$f3,$f5,$f9
        dc.b    $f5,$e1,$f5,$f6,$f5,$e1,$f5,$f3,$f5,$f7,$f5,$f9,$f5,$e1
music_pattern_t4_p1_src:
        dc.b    $d9,$db,$9a,$b8,$a7,$24,$07,$c6,$b9,$a7,$05,$e2,$44,$26,$e7,$24
        dc.b    $62,$83,$42,$c5,$c4,$24,$e3,$00,$c0,$c2,$c5,$25,$80,$81,$a0,$42
        dc.b    $a5,$25,$e0,$20,$c0,$05,$44,$a5,$e3,$03,$a2,$e4,$87,$e4,$25,$82
        dc.b    $64,$46,$39,$26,$46,$df,$57,$77,$31,$b9,$c7,$e6,$66,$db,$d0,$b7
        dc.b    $b5,$3f,$b9,$99,$18,$38,$78,$d8,$bb,$ba,$bd,$9c,$9f,$9e,$f1,$90
        dc.b    $53,$12,$32,$51,$7e,$1f,$7c,$bd,$fa,$3a,$bb,$d8,$b8,$38,$f9,$59
        dc.b    $19,$c6,$86,$a6,$26,$45,$e3,$20,$ae,$2f,$ad,$6a,$0b,$68,$a9,$29
        dc.b    $29,$29,$29,$cb,$8d,$0f,$ae,$81,$c0,$e3,$82,$45,$04,$e4,$67,$e7
        dc.b    $06,$de,$b5,$3f,$26,$c4,$dd,$54,$37,$31,$51,$57,$d6,$d6,$32,$3c
        dc.b    $dc,$92,$16,$35,$3c,$26,$d9,$9f,$d0,$bf,$39,$23,$c5,$db,$9f,$3a
        dc.b    $25,$2e,$c3,$d8,$1c,$38,$20,$ac,$c0,$58,$7a,$27,$af,$cd,$c0,$58
        dc.b    $b8,$25,$ac,$cd,$c0,$86,$39,$22,$2f,$cc,$c3,$66,$66,$22,$4e,$ce
        dc.b    $c2,$a6,$66,$25,$a0,$83,$c4,$19,$a6,$e5,$e2,$44,$da,$52,$36,$74
        dc.b    $31,$bb,$a6,$c6,$26,$07,$58,$de,$d5,$37,$b3,$3c,$b9,$f9,$38,$38
        dc.b    $78,$d8,$9b,$ba,$9d,$9c,$9f,$9e,$91,$b0,$73,$d3,$71,$1e,$3f,$1c
        dc.b    $5d,$9a,$3a,$5b,$d8,$b8,$38,$99,$59,$39,$c6,$86,$a6,$a4,$25,$63
        dc.b    $ad,$a8,$a4,$a0,$9e,$9c,$9c,$9c,$9e,$9f,$a3,$a7,$b9,$c3,$ef,$27
        dc.b    $38,$20,$f0,$cc,$cf,$fb,$2f,$49,$40,$10,$e0,$d5,$ef,$1f,$4d,$66
        dc.b    $78,$70,$50,$34,$2b,$37,$4f,$60,$58,$40,$1a,$03,$03,$17,$2e,$34
        dc.b    $24,$04,$e8,$de,$e7,$fd,$0e,$0f,$00,$e4,$ce,$c6,$cf,$e7,$fb,$01
        dc.b    $f6,$e0,$c4,$bc,$cb,$e7,$fd,$01,$f2,$d4,$c0,$be,$cf,$e7,$fb,$fd
        dc.b    $f0,$d8,$c7,$c7,$d7,$f3,$03,$04,$f8,$e8,$ef,$0f,$3b,$67,$7e,$7e
        dc.b    $6a,$48,$28,$0c,$f8,$e6,$da,$d2,$ca,$c8,$cc,$d3,$e7,$ff,$2b,$4b
        dc.b    $67,$7b,$7f,$7c,$6a,$50,$36,$20,$10,$0b,$0a,$07,$08,$0b,$0e,$0e
        dc.b    $0f,$10,$11,$11,$11,$11,$10,$0e,$0c,$09,$07,$03,$00,$fd,$f9,$f5
        dc.b    $f1,$ec,$e5,$de,$d7,$d0,$c9,$c3,$bd,$b8,$b3,$af,$ac,$aa,$a8,$a7
        dc.b    $a8,$a9,$ab,$ad,$b0,$cf,$ff,$2f,$31,$10,$e2,$c4,$cb,$ef,$25,$3f
        dc.b    $34,$10,$e0,$cc,$df,$0d,$3b,$4e,$51,$57,$55,$4e,$46,$42,$42,$44
        dc.b    $44,$40,$34,$28,$1c,$18,$16,$18,$17,$12,$0a,$00,$f8,$f0,$ec,$ed
        dc.b    $f1,$f6,$f7,$f0,$e4,$d4,$ce,$d2,$df,$f3,$fc,$f4,$e2,$cc,$c1,$c9
        dc.b    $df,$f5,$ff,$f6,$e2,$cc,$c1,$ca,$df,$f7,$02,$fc,$e9,$d2,$c9,$cf
        dc.b    $e7,$0b,$29,$3e,$47,$4f,$56,$60,$65,$60,$4a,$28,$00,$e0,$c9,$c4
        dc.b    $c5,$c6,$c7,$c8,$cf,$e7,$ff,$23,$47,$67,$7c,$7f,$7f,$74,$62,$52
        dc.b    $34,$20,$10,$09,$07,$05,$03,$01,$00,$00,$00,$00,$01,$01,$01,$00
        dc.b    $00,$ff,$fe,$fd,$fb,$f9,$f8,$f5,$f3,$f1,$ee,$e8,$e3,$dd,$d8,$d2
        dc.b    $cd,$c8,$c4,$c0,$bc,$b9,$b7,$b5,$b4,$b4,$b4,$b5,$bd,$e7,$17,$34
        dc.b    $2c,$08,$d8,$be,$c7,$eb,$17,$33,$30,$08,$e0,$c4,$cb,$ef,$1f,$3f
        dc.b    $40,$39,$3d,$45,$4f,$54,$52,$49,$3c,$30,$27,$26,$29,$2c,$29,$20
        dc.b    $13,$04,$fc,$fc,$03,$07,$03,$f8,$e5,$da,$da,$e5,$f3,$fa,$f4,$e2
        dc.b    $d0,$c5,$cb,$df,$f6,$03,$fd,$e6,$cd,$c0,$c5,$d7,$f3,$01,$00,$ec
        dc.b    $d4,$c4,$c5,$d7,$ef,$03,$08,$fc,$e8,$e7,$fb,$1b,$47,$6b,$7f,$7d
        dc.b    $6a,$50,$30,$16,$00,$ed,$da,$cc,$c4,$be,$bc,$bf,$c7,$d1,$e7,$ff
        dc.b    $1f,$43,$63,$7b,$7f,$7f,$74,$64,$58,$4c,$34,$1a,$0c,$07,$00,$fb
        dc.b    $f8,$f4,$f3,$f2,$f1,$f1,$f2,$f2,$f2,$f3,$f3,$f3,$f3,$f3,$f4,$f3
        dc.b    $f3,$f3,$f3,$f1,$ed,$e9,$e5,$e1,$dd,$d8,$d4,$d0,$cd,$ca,$c7,$c5
        dc.b    $c2,$c1,$bf,$bf,$cf,$ff,$27,$38,$28,$00,$d4,$ba,$bf,$df,$0d,$29
        dc.b    $28,$0c,$e4,$c2,$bc,$d5,$ff,$2b,$3d,$32,$26,$2c,$3b,$4f,$5d,$5d
        dc.b    $50,$3a,$22,$15,$16,$1f,$2f,$35,$2e,$1c,$00,$ee,$e9,$f2,$03,$0d
        dc.b    $08,$f8,$e0,$ce,$cb,$d7,$ed,$ff,$01,$f4,$da,$c4,$be,$cb,$e5,$ff
        dc.b    $0b,$00,$e8,$d0,$be,$bf,$d3,$ef,$03,$06,$f9,$e2,$cc,$c4,$cf,$e7
        dc.b    $07,$23,$33,$3c,$40,$45,$4e,$59,$61,$60,$50,$34,$10,$ec,$d0,$c0
        dc.b    $bc,$bf,$c1,$c3,$c5,$ca,$d5,$ea,$05,$1f,$3f,$5f,$76,$7f,$7f,$74
        dc.b    $64,$58,$4c,$42,$30,$14,$03,$fb,$f4,$ee,$e9,$e6,$e4,$e3,$e3,$e3
        dc.b    $e4,$e5,$e7,$e8,$ea,$ec,$ee,$ef,$f1,$f3,$f4,$f6,$f6,$f4,$f2,$f0
        dc.b    $ee,$eb,$e8,$e5,$e2,$e0,$dc,$d9,$d7,$d5,$d3,$d3,$ed,$13,$2e,$32
        dc.b    $20,$00,$d8,$c0,$c3,$dd,$fd,$17,$1c,$08,$ea,$cc,$bd,$c6,$df,$07
        dc.b    $26,$2d,$20,$16,$1d,$2e,$43,$53,$54,$49,$34,$1c,$0c,$09,$12,$21
        dc.b    $2e,$2e,$20,$0a,$f0,$e4,$e5,$f1,$ff,$0b,$09,$f9,$e4,$d2,$cc,$d5
        dc.b    $e7,$fd,$07,$02,$f0,$da,$ca,$c8,$d7,$ee,$ff,$0b,$04,$f1,$dc,$cc
        dc.b    $cb,$d7,$eb,$ff,$09,$05,$f8,$e7,$e3,$ef,$07,$27,$47,$5b,$63,$5c
        dc.b    $4e,$39,$28,$16,$08,$f9,$eb,$dc,$d0,$c8,$c5,$c4,$c8,$cf,$d5,$df
        dc.b    $ef,$05,$1b,$33,$4b,$61,$6f,$78,$79,$70,$5a,$4e,$44,$30,$18,$06
        dc.b    $f8,$ee,$e8,$e2,$de,$db,$d9,$d9,$d9,$da,$dc,$de,$e0,$e3,$e6,$e8
        dc.b    $eb,$ee,$f1,$f4,$f7,$f8,$f8,$f8,$f8,$f7,$f6,$f5,$f3,$f1,$f0,$ed
        dc.b    $eb,$e9,$e7,$ed,$03,$1e,$2f,$2c,$18,$00,$e0,$cd,$cd,$de,$f7,$0b
        dc.b    $13,$0a,$f8,$dc,$c8,$c5,$d3,$ed,$07,$1d,$20,$14,$0f,$13,$1f,$31
        dc.b    $40,$45,$40,$30,$1c,$0c,$03,$05,$0f,$1b,$23,$20,$12,$00,$ec,$e4
        dc.b    $e6,$f1,$fe,$07,$08,$fe,$ee,$dd,$d4,$d7,$e3,$f6,$03,$08,$02,$f2
        dc.b    $e0,$d4,$d3,$df,$ef,$ff,$09,$08,$fc,$ea,$dc,$d5,$da,$e7,$f9,$0a
        dc.b    $16,$1c,$1d,$1e,$21,$29,$33,$3e,$44,$43,$38,$25,$10,$f8,$e4,$d6
        dc.b    $ce,$cd,$cf,$d1,$d3,$d5,$d9,$df,$e7,$f6,$06,$17,$2b,$3f,$4f,$5b
        dc.b    $64,$67,$65,$5d,$51,$40,$30,$1c,$0a,$f9,$ee,$e6,$e0,$db,$d8,$d5
        dc.b    $d4,$d4,$d5,$d7,$d9,$dc,$df,$e3,$e6,$ea,$ed,$f1,$f5,$f9,$fb,$fc
        dc.b    $fe,$fe,$ff,$fe,$fe,$fd,$fc,$fa,$f8,$f7,$f6,$ff,$15,$26,$2e,$2a
        dc.b    $18,$00,$e8,$d8,$d5,$de,$ef,$ff,$0b,$09,$fd,$ea,$d8,$cc,$cf,$dd
        dc.b    $f1,$07,$15,$18,$10,$0c,$0f,$17,$23,$2e,$34,$32,$29,$1c,$0f,$05
        dc.b    $01,$04,$0b,$13,$15,$11,$07,$fa,$ee,$e7,$e9,$f1,$fb,$03,$05,$00
        dc.b    $f5,$e9,$e0,$dd,$e3,$ef,$fd,$07,$0a,$04,$f8,$e8,$de,$dc,$e2,$ef
        dc.b    $fc,$06,$09,$04,$f8,$ec,$e4,$e7,$f1,$03,$17,$2c,$39,$3e,$3c,$36
        dc.b    $2c,$22,$19,$11,$09,$01,$f8,$ed,$e1,$d8,$d4,$d2,$d3,$d7,$dc,$e1
        dc.b    $e6,$ee,$f9,$06,$15,$25,$33,$41,$4b,$53,$57,$56,$50,$48,$3a,$2c
        dc.b    $1c,$0c,$00,$f1,$e8,$e1,$dc,$d8,$d6,$d5,$d5,$d5,$d7,$d9,$dc,$df
        dc.b    $e2,$e6,$ea,$ee,$f2,$f6,$fa,$fd,$ff,$01,$02,$03,$03,$03,$03,$02
        dc.b    $01,$00,$02,$0e,$1c,$27,$2c,$27,$18,$04,$f0,$e2,$dd,$e1,$ed,$fa
        dc.b    $04,$07,$02,$f6,$e6,$d8,$d3,$d6,$e1,$f1,$03,$0f,$13,$0f,$0e,$0f
        dc.b    $13,$1a,$1f,$24,$24,$21,$1a,$12,$09,$03,$02,$03,$07,$0b,$0b,$07
        dc.b    $00,$f8,$f0,$ec,$ed,$f2,$f9,$ff,$03,$01,$fb,$f2,$ea,$e4,$e5,$ea
        dc.b    $f5,$ff,$08,$0b,$05,$fc,$f1,$e8,$e3,$e4,$eb,$f6,$ff,$07,$0a,$0a
        dc.b    $08,$07,$07,$0b,$13,$1e,$27,$2f,$32,$2e,$25,$18,$09,$fc,$f0,$e6
        dc.b    $e0,$dc,$dc,$de,$df,$e0,$e2,$e5,$e9,$ee,$f5,$fd,$07,$13,$1f,$2b
        dc.b    $35,$3e,$44,$48,$47,$44,$3c,$34,$28,$1c,$0e,$00,$f6,$ec,$e4,$e0
        dc.b    $db,$d8,$d7,$d6,$d7,$d8,$da,$dd,$e0,$e4,$e7,$ec,$ef,$f3,$f8,$fc
        dc.b    $ff,$01,$03,$05,$06,$07,$07,$07,$07,$06,$0b,$16,$1f,$27,$29,$24
        dc.b    $18,$08,$f8,$ec,$e4,$e5,$eb,$f5,$ff,$03,$04,$fe,$f4,$e8,$dd,$d9
        dc.b    $db,$e3,$f1,$fe,$09,$0f,$0e,$0f,$11,$13,$15,$16,$17,$17,$16,$12
        dc.b    $0e,$0a,$06,$04,$03,$05,$06,$06,$04,$00,$fc,$f6,$f2,$f0,$f1,$f5
        dc.b    $fa,$ff,$03,$03,$00,$fa,$f3,$ed,$e9,$e9,$ef,$f7,$ff,$06,$09,$08
        dc.b    $02,$fa,$f2,$ec,$e8,$ea,$f3,$ff,$0a,$15,$1d,$22,$23,$21,$1e,$1a
        dc.b    $17,$14,$12,$0f,$0b,$06,$00,$f6,$ee,$e6,$e1,$de,$de,$e0,$e3,$e7
        dc.b    $eb,$ee,$f2,$f8,$ff,$07,$0f,$1b,$23,$2c,$33,$38,$3b,$3b,$38,$33
        dc.b    $2c,$24,$1a,$10,$03,$fa,$f0,$e9,$e3,$e0,$dc,$da,$d9,$da,$db,$dd
        dc.b    $df,$e3,$e6,$e9,$ed,$f0,$f5,$f9,$fd,$ff,$02,$05,$07,$08,$09,$0a
        dc.b    $0a,$0b,$11,$19,$22,$26,$27,$22,$18,$0c,$00,$f3,$ec,$e9,$ec,$f2
        dc.b    $f9,$ff,$02,$01,$fc,$f4,$ec,$e4,$e0,$e0,$e6,$ef,$f9,$03,$0a,$0e
        dc.b    $11,$14,$15,$15,$13,$10,$0e,$0b,$08,$06,$04,$04,$05,$06,$07,$07
        dc.b    $06,$04,$01,$fe,$f9,$f5,$f1,$f1,$f2,$f6,$fa,$ff,$03,$05,$04,$01
        dc.b    $fc,$f6,$f1,$ed,$ec,$ef,$f4,$fb,$01,$06,$09,$08,$04,$00,$fb,$f9
        dc.b    $fa,$fe,$05,$0d,$16,$1d,$23,$24,$22,$1c,$15,$0c,$04,$fc,$f5,$f0
        dc.b    $ec,$ea,$e9,$e8,$e8,$e9,$e9,$eb,$ed,$ef,$f3,$f7,$fb,$01,$07,$0f
        dc.b    $17,$1e,$24,$29,$2d,$2f,$30,$2e,$2a,$25,$1e,$16,$0e,$05,$fc,$f4
        dc.b    $ee,$e8,$e3,$e0,$df,$de,$de,$df,$e0,$e3,$e5,$e8,$ec,$ef,$f3,$f6
        dc.b    $fa,$fd,$00,$03,$05,$07,$09,$0a,$0b,$0e,$13,$1a,$1f,$23,$23,$20
        dc.b    $18,$0e,$04,$fa,$f2,$ee,$ee,$f1,$f6,$fb,$ff,$02,$01,$fd,$f8,$f0
        dc.b    $ea,$e6,$e5,$e7,$ed,$f4,$fd,$05,$0a,$11,$15,$18,$18,$15,$11,$0c
        dc.b    $06,$01,$fe,$fd,$fd,$ff,$02,$05,$08,$0a,$0a,$08,$04,$00,$fa,$f6
        dc.b    $f2,$f0,$f0,$f2,$f7,$fc,$01,$05,$07,$07,$06,$02,$fd,$f8,$f2,$f0
        dc.b    $ef,$f0,$f4,$f9,$ff,$05,$0a,$0e,$0f,$0f,$0f,$0e,$0d,$0d,$0e,$0f
        dc.b    $0f,$11,$11,$0f,$0c,$07,$00,$fa,$f4,$ee,$ea,$e7,$e7,$e8,$e9,$ec
        dc.b    $ef,$f1,$f4,$f7,$fa,$fe,$03,$07,$0d,$13,$19,$1e,$22,$25,$26,$27
        dc.b    $26,$23,$1e,$19,$14,$0d,$06,$fe,$f8,$f2,$ec,$e8,$e5,$e3,$e2,$e2
        dc.b    $e2,$e4,$e6,$e8,$eb,$ee,$f1,$f4,$f7,$fb,$fe,$01,$03,$06,$07,$09
        dc.b    $0b,$0e,$13,$18,$1d,$1f,$20,$1d,$18,$10,$08,$00,$f9,$f4,$f1,$f1
        dc.b    $f4,$f7,$fc,$ff,$01,$01,$ff,$fb,$f6,$f1,$ed,$ea,$ea,$ed,$f1,$f7
        dc.b    $fe,$04,$0c,$13,$18,$1a,$19,$16,$10,$09,$02,$fc,$f8,$f6,$f6,$f8
        dc.b    $fc,$ff,$05,$09,$0b,$0b,$09,$05,$00,$fc,$f6,$f2,$f0,$f0,$f1,$f4
        dc.b    $f9,$ff,$03,$07,$09,$09,$08,$04,$00,$fb,$f7,$f4,$f2,$f4,$f8,$fd
        dc.b    $03,$09,$0f,$13,$17,$18,$17,$14,$11,$0c,$08,$04,$00,$fd,$fb,$f8
        dc.b    $f6,$f5,$f3,$f2,$f0,$f0,$f0,$f0,$f1,$f3,$f5,$f7,$fa,$fc,$ff,$03
        dc.b    $07,$0c,$0f,$14,$18,$1b,$1d,$1e,$1f,$1e,$1c,$19,$15,$10,$0c,$06
        dc.b    $00,$fa,$f5,$f0,$ed,$ea,$e7,$e7,$e6,$e7,$e7,$e9,$eb,$ed,$f0,$f2
        dc.b    $f6,$f8,$fc,$ff,$01,$03,$05,$07,$09,$0d,$11,$15,$19,$1b,$1b,$1a
        dc.b    $16,$11,$0b,$04,$fe,$f9,$f5,$f4,$f4,$f6,$f8,$fb,$fe,$00,$01,$00
        dc.b    $fe,$fb,$f8,$f4,$f0,$ef,$ef,$f0,$f3,$f7,$fd,$04,$0b,$13,$17,$19
        dc.b    $19,$16,$11,$0b,$04,$fd,$f8,$f3,$f1,$f2,$f5,$f9,$fe,$03,$07,$0b
        dc.b    $0c,$0b,$08,$04,$00,$fb,$f6,$f3,$f1,$f1,$f2,$f5,$f9,$fd,$01,$05
        dc.b    $07,$08,$08,$06,$04,$02,$00,$ff,$ff,$ff,$01,$04,$07,$0b,$0e,$0f
        dc.b    $11,$11,$0f,$0c,$08,$03,$00,$fa,$f6,$f3,$f0,$ef,$ee,$ef,$f0,$f1
        dc.b    $f3,$f5,$f7,$f9,$fb,$fc,$ff,$01,$04,$07,$0b,$0e,$11,$13,$16,$17
        dc.b    $18,$18,$18,$17,$14,$11,$0e,$0a,$06,$00,$fc,$f8,$f4,$f1,$ee,$ec
        dc.b    $eb,$ea,$eb,$eb,$ed,$ee,$f0,$f2,$f4,$f7,$fa,$fc,$ff,$01,$03,$05
        dc.b    $07,$0b,$0f,$12,$15,$17,$18,$17,$15,$11,$0c,$07,$02,$fe,$fa,$f7
        dc.b    $f5,$f5,$f6,$f8,$fa,$fd,$ff,$00,$01,$00,$ff,$fd,$fa,$f8,$f5,$f3
        dc.b    $f2,$f3,$f4,$f7,$fc,$02,$07,$0d,$12,$15,$16,$15,$12,$0d,$08,$01
        dc.b    $fc,$f7,$f3,$f1,$f1,$f3,$f6,$fb,$ff,$03,$07,$09,$0a,$0a,$08,$05
        dc.b    $01,$fe,$fa,$f8,$f5,$f4,$f4,$f6,$f8,$fb,$fe,$01,$04,$07,$09,$0b
        dc.b    $0c,$0c,$0b,$0b,$09,$08,$07,$06,$05,$05,$04,$03,$02,$01,$00,$ff
        dc.b    $fd,$fb,$f9,$f7,$f6,$f4,$f4,$f4,$f4,$f5,$f6,$f8,$fa,$fc,$fd,$ff
        dc.b    $01,$04,$06,$09,$0b,$0d,$0f,$11,$13,$13,$13,$13,$12,$10,$0e,$0b
        dc.b    $08,$05,$01,$fe,$fa,$f8,$f4,$f2,$f0,$ef,$ee,$ee,$ef,$f0,$f1,$f2
        dc.b    $f4,$f6,$f8,$fb,$fd,$ff,$01,$03,$06,$08,$0b,$0e,$11,$13,$13,$13
        dc.b    $12,$10,$0e,$0a,$06,$01,$fe,$fb,$f8,$f7,$f6,$f7,$f8,$f9,$fb,$fd
        dc.b    $ff,$00,$01,$01,$01,$00,$fe,$fc,$fa,$f9,$f8,$f7,$f7,$f9,$fc,$ff
        dc.b    $03,$07,$0c,$0f,$10,$11,$10,$0e,$0b,$06,$02,$fe,$fa,$f7,$f5,$f4
        dc.b    $f4,$f6,$f8,$fb,$fe,$01,$04,$06,$07,$07,$07,$06,$04,$01,$ff,$fc
        dc.b    $fa,$f8,$f8,$f8,$f9,$fc,$fe,$01,$04,$07,$0a,$0c,$0e,$0f,$0e,$0e
        dc.b    $0c,$0a,$07,$04,$01,$fe,$fc,$fa,$f8,$f6,$f6,$f5,$f5,$f5,$f6,$f7
        dc.b    $f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff,$00,$02,$04,$06,$07,$09,$0b,$0d
        dc.b    $0e,$0f,$0f,$0f,$0f,$0e,$0d,$0b,$09,$07,$04,$01,$ff,$fc,$fa,$f8
        dc.b    $f6,$f4,$f3,$f2,$f2,$f2,$f3,$f3,$f5,$f6,$f8,$f9,$fb,$fd,$ff,$01
        dc.b    $03,$06,$08,$0b,$0d,$0f,$0f,$10,$10,$0f,$0d,$0b,$08,$05,$01,$ff
        dc.b    $fc,$fa,$f8,$f8,$f7,$f7,$f8,$f9,$fb,$fd,$fe,$ff,$01,$02,$02,$02
        dc.b    $01,$00,$ff,$fe,$fd,$fc,$fb,$fc,$fd,$fe,$ff,$02,$05,$07,$08,$09
        dc.b    $0a,$0a,$08,$07,$05,$03,$00,$fe,$fc,$fa,$f9,$f8,$f8,$f9,$fa,$fc
        dc.b    $fe,$ff,$01,$03,$04,$05,$05,$05,$04,$03,$01,$00,$ff,$ff,$fe,$fe
        dc.b    $ff,$ff,$01,$02,$04,$05,$07,$08,$08,$09,$09,$07,$07,$05,$03,$01
        dc.b    $ff,$fd,$fb,$f9,$f8,$f6,$f6,$f6,$f6,$f7,$f8,$f9,$fa,$fc,$fd,$ff
        dc.b    $ff,$01,$02,$03,$05,$07,$08,$09,$0a,$0b,$0c,$0c,$0c,$0c,$0c,$0a
        dc.b    $09,$07,$06,$04,$01,$00,$fd,$fc,$fa,$f8,$f7,$f6,$f5,$f4,$f4,$f5
        dc.b    $f6,$f7,$f8,$f9,$fb,$fc,$fe,$ff,$01,$03,$05,$07,$09,$0b,$0c,$0d
        dc.b    $0d,$0d,$0c,$0b,$09,$07,$04,$02,$00,$fe,$fc,$fa,$f9,$f8,$f8,$f8
        dc.b    $f8,$f9,$fa,$fc,$fd,$ff,$ff,$01,$02,$03,$03,$03,$03,$02,$01,$01
        dc.b    $00,$00,$00,$00,$01,$01,$02,$02,$02,$03,$03,$03,$03,$03,$02,$01
        dc.b    $00,$ff,$fe,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe,$ff,$ff,$01,$02
        dc.b    $03,$04,$05,$06,$06,$06,$06,$06,$05,$05,$04,$03,$03,$03,$02,$01
        dc.b    $01,$00,$00,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fb,$fb
        dc.b    $fc,$fc,$fc,$fc,$fd,$fe,$fe,$ff,$ff,$00,$01,$02,$03,$04,$05,$06
        dc.b    $07,$08,$09,$09,$0a,$09,$09,$09,$08,$07,$06,$05,$03,$02,$00,$fe
        dc.b    $fd,$fc,$fa,$f9,$f8,$f8,$f8,$f7,$f7,$f8,$f8,$f9,$fb,$fb,$fd,$fe
        dc.b    $ff,$01,$03,$05,$06,$07,$09,$0a,$0a,$0a,$0a,$0a,$09,$08,$06,$05
        dc.b    $03,$01,$00,$fe,$fc,$fb,$fa,$f9,$f8,$f8,$f8,$f9,$f9,$fa,$fb,$fc
        dc.b    $fe,$ff,$00,$01,$02,$03,$03,$03,$03,$04,$04,$04,$05,$04,$04,$04
        dc.b    $04,$04,$03,$03,$02,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fd,$fc,$fc
        dc.b    $fb,$fb,$fb,$fc,$fc,$fc,$fd,$fe,$fe,$ff,$00,$02,$03,$04,$06,$07
        dc.b    $08,$09,$09,$09,$09,$09,$08,$07,$07,$05,$04,$02,$01,$ff,$fe,$fd
        dc.b    $fb,$fa,$f9,$f9,$f8,$f8,$f8,$f8,$f9,$fa,$fa,$fc,$fc,$fe,$fe,$ff
        dc.b    $00,$01,$01,$02,$03,$03,$04,$05,$06,$07,$07,$07,$08,$07,$08,$07
        dc.b    $07,$07,$06,$05,$04,$03,$01,$00,$ff,$fe,$fd,$fc,$fb,$fa,$fa,$f9
        dc.b    $f9,$f9,$fa,$fa,$fb,$fb,$fc,$fd,$ff,$ff,$01,$02,$03,$05,$06,$06
        dc.b    $07,$07,$08,$08,$08,$07,$07,$06,$05,$04,$03,$01,$00,$ff,$fe,$fd
        dc.b    $fc,$fc,$fb,$fa,$fa,$fa,$fa,$fa,$fa,$fb,$fc,$fc,$fd,$fe,$ff,$00
        dc.b    $01,$02,$03,$03,$04,$05,$06,$06,$06,$07,$06,$07,$06,$06,$06,$05
        dc.b    $04,$03,$02,$02,$01,$00,$ff,$ff,$fe,$fd,$fc,$fc,$fc,$fb,$fb,$fb
        dc.b    $fb,$fb,$fc,$fc,$fd,$fe,$ff,$00,$01,$02,$03,$04,$05,$06,$06,$07
        dc.b    $07,$06,$06,$06,$05,$04,$03,$02,$01,$00,$ff,$fe,$fd,$fc,$fc,$fb
        dc.b    $fb,$fb,$fb,$fb,$fc,$fc,$fd,$fe,$fe,$ff,$ff,$00,$01,$01,$02,$03
        dc.b    $03,$04,$05,$05,$06,$06,$06,$06,$06,$06,$05,$04,$04,$03,$02,$01
        dc.b    $00,$00,$ff,$fe,$fd,$fc,$fc,$fc,$fb,$fb,$fb,$fb,$fc,$fc,$fd,$fd
        dc.b    $fe,$ff,$00,$01,$01,$03,$03,$04,$05,$05,$06,$06,$06,$06,$06,$06
        dc.b    $05,$05,$04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fb
        dc.b    $fb,$fb,$fb,$fb,$fb,$fc,$fc,$fd,$fd,$fe,$fe,$ff,$ff,$00,$01,$01
        dc.b    $02,$03,$03,$04,$04,$05,$05,$05,$06,$05,$05,$05,$05,$05,$04,$04
        dc.b    $03,$03,$02,$01,$01,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$fe,$ff,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$00,$00
        dc.b    $00,$00,$01,$01,$01,$02,$02,$03,$03,$03,$03,$03,$04,$04,$04,$04
        dc.b    $04,$04,$04,$03,$03,$03,$02,$01,$01,$00,$ff,$ff,$fe,$fe,$fe,$fd
        dc.b    $fd,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$fe,$ff,$ff,$00,$00,$01,$02
        dc.b    $03,$03,$03,$04,$04,$05,$05,$05,$04,$04,$04,$04,$04,$03,$03,$02
        dc.b    $01,$01,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fd,$fd,$fd,$fd
        dc.b    $fd,$fd,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$00,$00,$00,$01,$01
        dc.b    $02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        dc.b    $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01
        dc.b    $00,$00,$00,$ff,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$00,$00,$01,$01,$02,$02,$03,$03
        dc.b    $03,$04,$04,$04,$04,$04,$05,$04,$04,$04,$04,$04,$03,$03,$03,$02
        dc.b    $02,$01,$01,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$ff,$ff,$ff,$00,$00,$00,$01,$01,$02,$02,$02,$03,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$02,$02,$02,$02,$01,$01,$01,$00,$00,$00
        dc.b    $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00,$00,$00,$00,$01,$00,$00
        dc.b    $01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$02,$02,$01,$01,$01,$00,$00,$ff,$ff,$ff
        dc.b    $fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$ff
        dc.b    $ff,$ff,$00,$00,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03
        dc.b    $03,$03,$03,$03,$03,$03,$03,$02,$02,$01,$01,$01,$00,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00
        dc.b    $01,$01,$01,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02
        dc.b    $02,$02,$01,$01,$01,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$ff,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$02,$03,$02,$02,$02,$01
        dc.b    $01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fe,$fd
        dc.b    $fd,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$00,$00,$01,$01,$01,$01
        dc.b    $01,$02,$02,$02,$02,$02,$02,$02,$02,$03,$03,$02,$02,$02,$02,$02
        dc.b    $02,$01,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02
        dc.b    $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$00
        dc.b    $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$01,$02,$02,$02,$02
        dc.b    $02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff
        dc.b    $00,$ff,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02,$01,$01,$01
        dc.b    $02,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01,$01,$00,$00
        dc.b    $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00,$00
        dc.b    $00,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$02
        dc.b    $01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$ff,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01
        dc.b    $01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00,$00,$00,$00,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$00,$00,$ff,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00
        dc.b    $00,$00,$ff,$00,$ff,$00,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$ff,$00
        dc.b    $ff,$00,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02
        dc.b    $01,$02,$02,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$ff,$ff
        dc.b    $ff,$ff,$00,$ff,$00,$ff,$ff,$00,$ff,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $00,$00,$00,$00,$00,$00,$ff,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00
        dc.b    $01,$01,$01,$01,$00,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$ff,$ff,$00,$ff,$00,$ff,$ff,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$01,$01,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$ff,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$00,$00,$ff,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01
        dc.b    $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$00,$01,$00
        dc.b    $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$00
        dc.b    $01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff
        dc.b    $00,$ff,$00,$00,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$ff,$ff,$ff
        dc.b    $ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$01,$00,$00,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$01,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; ===========================================================================
; Sound ADSR envelope tables and synth templates.
; ===========================================================================
music_envelope_presets_src:
        dc.b    $00,$00,$00,$01,$00,$00,$00,$01,$00,$00,$01,$ff,$00,$00,$00,$00
        dc.b    $00,$01,$00,$00,$ff,$01,$ff,$00,$ff,$00,$00,$00,$01,$01,$01,$01
        dc.b    $01,$01,$00,$01,$00,$00,$01,$01,$00,$01,$00,$00,$00,$01,$ff,$01
        dc.b    $00,$00,$01,$00,$01,$00,$00,$00,$ff,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$01,$ff,$00,$ff,$01,$00,$00,$01,$ff,$01,$00,$01,$00,$00,$00
        dc.b    $00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$ff
        dc.b    $00,$01,$ff,$00,$01,$00,$00,$02,$00,$02,$ff,$00,$01,$ff,$00,$01
        dc.b    $ff,$00,$01,$00,$ff,$00,$ff,$01,$00,$ff,$00,$ff,$00,$ff,$ff,$00
        dc.b    $ff,$ff,$ff,$fe,$ff,$fd,$fe,$fd,$fc,$fc,$fb,$fa,$fa,$f8,$f8,$f8
        dc.b    $f7,$f9,$fa,$03,$0c,$4f,$50,$80,$ef,$2f,$78,$5b,$7e,$8f,$1f,$00
        dc.b    $9f,$28,$80,$7f,$80,$40,$ff,$bf,$ff,$7f,$80,$80,$2f,$7f,$80,$ff
        dc.b    $78,$80,$3f,$7f,$80,$8f,$7f,$c0,$8f,$7f,$00,$dc,$3f,$a0,$87,$3f
        dc.b    $7f,$80,$80,$ef,$e6,$1f,$7f,$7f,$00,$d8,$80,$e9,$cd,$ce,$cc,$df
        dc.b    $08,$f3,$07,$3f,$61,$62,$62,$6e,$75,$79,$7b,$7c,$78,$77,$71,$6d
        dc.b    $6a,$50,$90,$ef,$f4,$e5,$e0,$db,$d8,$d7,$d5,$d6,$d5,$d8,$d7,$d9
        dc.b    $d9,$dc,$dc,$e0,$e1,$e3,$e4,$e6,$e7,$e9,$e9,$80,$80,$aa,$9b,$a1
        dc.b    $a4,$ac,$b2,$b9,$bf,$c9,$d0,$da,$e1,$e9,$ef,$f7,$fb,$02,$07,$0b
        dc.b    $0f,$14,$19,$1b,$1e,$21,$23,$25,$26,$27,$28,$2b,$2b,$2d,$2f,$2f
        dc.b    $2f,$2e,$2c,$2e,$2c,$2b,$2b,$2e,$30,$2d,$2a,$2a,$2e,$2f,$30,$32
        dc.b    $31,$2c,$2a,$2d,$2f,$2f,$2f,$2e,$2a,$25,$22,$1e,$1c,$1c,$1d,$1a
        dc.b    $12,$10,$0d,$0a,$07,$09,$07,$01,$ff,$fd,$ff,$fc,$f8,$f8,$f6,$c8
        dc.b    $80,$bf,$b0,$b1,$b2,$b4,$b7,$ba,$bf,$c3,$c8,$cd,$d1,$d5,$db,$de
        dc.b    $e4,$e8,$ec,$f0,$f3,$f6,$fa,$fd,$ff,$02,$04,$06,$08,$0a,$0c,$0e
        dc.b    $0e,$11,$0f,$12,$12,$13,$13,$13,$12,$14,$14,$14,$14,$14,$15,$13
        dc.b    $13,$13,$13,$12,$11,$11,$11,$11,$12,$12,$0f,$10,$0f,$0f,$0f,$11
        dc.b    $12,$13,$14,$14,$11,$10,$0f,$0e,$0f,$11,$11,$0e,$0d,$0e,$0f,$0f
        dc.b    $0f,$0f,$10,$0f,$11,$0c,$09,$07,$05,$04,$05,$04,$03,$02,$fe,$fc
        dc.b    $fa,$f8,$f5,$f4,$f2,$f0,$ee,$ec,$ec,$eb,$ea,$eb,$e8,$e8,$e7,$e7
        dc.b    $e6,$e4,$c1,$88,$bf,$c0,$bd,$be,$c1,$c3,$c7,$80,$8f,$b4,$ae,$b5
        dc.b    $ba,$bf,$c7,$ce,$d5,$db,$e1,$e7,$ee,$f4,$fa,$fe,$02,$07,$0c,$0f
        dc.b    $12,$15,$17,$1a,$1c,$1d,$20,$20,$22,$23,$23,$23,$23,$23,$26,$25
        dc.b    $24,$23,$23,$22,$22,$22,$21,$20,$1f,$1d,$1d,$1c,$1b,$1b,$19,$19
        dc.b    $18,$17,$15,$16,$14,$13,$12,$12,$11,$11,$0f,$0f,$0e,$0d,$0d,$0d
        dc.b    $0c,$0d,$0d,$0c,$0d,$0c,$0d,$0d,$0f,$0c,$0b,$0d,$0c,$0e,$09,$0a
        dc.b    $0c,$0b,$0b,$0c,$0b,$0a,$09,$08,$0a,$09,$0a,$09,$07,$05,$05,$04
        dc.b    $05,$04,$03,$03,$00,$ff,$fe,$fe,$fc,$fd,$fb,$fc,$f9,$f8,$f6,$c0
        dc.b    $dd,$e0,$db,$dc,$de,$de,$e1,$e2,$e6,$e7,$e9,$ec,$ee,$f0,$f3,$f5
        dc.b    $f7,$f9,$fa,$fc,$fe,$ff,$ff,$01,$02,$03,$04,$06,$07,$07,$07,$08
        dc.b    $09,$09,$09,$0a,$09,$0a,$0a,$0a,$09,$09,$0a,$0a,$09,$09,$08,$09
        dc.b    $09,$07,$07,$07,$08,$07,$07,$07,$06,$05,$06,$05,$05,$04,$04,$03
        dc.b    $04,$03,$03,$02,$02,$01,$01,$02,$01,$01,$00,$00,$01,$01,$00,$02
        dc.b    $01,$01,$02,$02,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$03,$03,$02,$02,$03,$03,$03,$02,$03,$01,$00,$02,$01,$01,$00
        dc.b    $00,$00,$ff,$ff,$fe,$fd,$fc,$fc,$fb,$fb,$fc,$f9,$e0,$df,$ec,$e8
        dc.b    $e8,$e0,$bf,$dd,$dc,$dc,$de,$e1,$e4,$e6,$e9,$ec,$f0,$f1,$f3,$f7
        dc.b    $f9,$fc,$fe,$00,$02,$04,$04,$07,$07,$09,$0a,$0b,$0c,$0b,$0c,$0e
        dc.b    $0e,$0e,$0f,$0e,$0f,$0f,$0f,$0e,$0f,$0e,$0e,$0e,$0d,$0d,$0d,$0c
        dc.b    $0d,$0c,$0c,$0a,$0c,$0b,$0a,$0a,$0a,$08,$08,$09,$09,$08,$07,$07
        dc.b    $07,$07,$06,$06,$06,$05,$06,$05,$05,$05,$05,$03,$04,$03,$03,$03
        dc.b    $04,$03,$02,$01,$02,$02,$04,$02,$02,$03,$03,$02,$01,$02,$01,$02
        dc.b    $02,$02,$03,$03,$01,$02,$02,$00,$03,$01,$02,$02,$03,$01,$01,$02
        dc.b    $02,$03,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$00,$02,$00,$00
        dc.b    $00,$00,$ff,$00,$ff,$fe,$fe,$ff,$ff,$fe,$ff,$fe,$fd,$fe,$fe,$fa
        dc.b    $e3,$f5,$f3,$f3,$f3,$f3,$f5,$f5,$f7,$f7,$f8,$f9,$f9,$fc,$fb,$fd
        dc.b    $fd,$fe,$fe,$ff,$ff,$ff,$00,$00,$02,$03,$03,$02,$04,$03,$04,$03
        dc.b    $03,$03,$03,$05,$03,$04,$05,$04,$04,$03,$04,$04,$04,$04,$05,$03
        dc.b    $03,$04,$03,$04,$03,$03,$03,$03,$03,$04,$02,$03,$02,$01,$03,$02
        dc.b    $02,$01,$02,$01,$01,$01,$02,$ff,$00,$01,$00,$01,$01,$00,$00,$01
        dc.b    $ff,$00,$00,$01,$00,$00,$ff,$00,$00,$00,$00,$00,$00,$ff,$00,$ff
        dc.b    $00,$ff,$00,$ff,$00,$00,$00,$00,$ff,$00,$ff,$00,$ff,$00,$00,$00
        dc.b    $01,$00,$01,$00,$ff,$00,$00,$00,$00,$01,$ff,$ff,$00,$00,$00,$00
        dc.b    $00,$ff,$ff,$01,$00,$00,$00,$00,$ff,$00,$00,$f6,$f5,$fc,$f9,$fa
        dc.b    $f9,$f9,$fa,$fb,$fb,$fc,$fc,$fc,$fe,$ff,$ff,$00,$ff,$00,$00,$01
        dc.b    $00,$01,$00,$02,$01,$f8,$fa,$fe,$fc,$fd,$fc,$ff,$ff,$ff,$ff,$ff
        dc.b    $00,$02,$01,$01,$03,$01,$02,$04,$03,$03,$05,$03,$04,$04,$04,$05
        dc.b    $04,$04,$04,$04,$04,$05,$05,$03,$04,$04,$04,$05,$04,$04,$03,$04
        dc.b    $03,$04,$04,$03,$04,$04,$03,$03,$02,$03,$02,$02,$02,$02,$03,$03
        dc.b    $02,$01,$02,$01,$02,$02,$01,$02,$01,$00,$00,$02,$00,$02,$01,$01
        dc.b    $01,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $ff,$01,$ff,$00,$00,$00,$00,$00,$01,$00,$00,$00,$01,$ff,$00,$ff
        dc.b    $01,$00,$00,$00,$01,$00,$00,$00,$01,$ff,$00,$00,$00,$00,$00,$00
        dc.b    $ff,$ff,$00,$00,$00,$01,$00,$ff,$00,$00,$00,$00,$ff,$00,$00,$00
        dc.b    $02,$01,$01,$01,$01,$01,$01,$01,$00,$01,$02,$02,$01,$01,$01,$00
        dc.b    $00,$01,$01,$02,$00,$01,$01,$01,$00,$01,$00,$00,$00,$ff,$00,$ff
        dc.b    $00,$00,$00,$01,$ff,$00,$00,$01,$00,$01,$ff,$00,$00,$00,$00,$01
        dc.b    $00,$ff,$00,$00,$00,$01,$00,$00,$00,$ff,$01,$00,$ff,$01,$ff,$ff
        dc.b    $00,$00,$00,$ff,$00,$00,$00,$00,$01,$00,$00,$ff,$00,$00,$00,$00
        dc.b    $00,$ff,$ff,$ff,$00,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$00,$00,$00,$01,$00,$01,$00,$01,$00,$01,$ff
        dc.b    $01,$00,$00,$01,$00,$00,$01,$00,$01,$00,$00,$02,$00,$01,$01,$ff
        dc.b    $ff,$ff,$00,$00,$01,$01,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$00,$00,$01,$ff,$ff,$00,$01,$00,$00,$00,$01
        dc.b    $ff,$01,$00,$01,$00,$ff,$00,$00,$00,$01,$00,$00,$ff,$01,$00,$01
        dc.b    $00,$02,$00,$00,$ff,$00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$00
        dc.b    $01,$00,$01,$00,$00,$00,$01,$01,$00,$00,$01,$01,$ff,$01,$01,$00
        dc.b    $00,$01,$00,$00,$00,$01,$00,$01,$01,$00,$00,$ff,$00,$00,$00,$00
        dc.b    $00,$fe,$00,$ff,$00,$00,$01,$ff,$00,$ff,$01,$00,$01,$ff,$00,$00
        dc.b    $00,$00,$00,$01,$ff,$00,$00,$00,$02,$01,$00,$01,$02,$01,$01,$01
        dc.b    $01,$01,$01,$02,$01,$01,$01,$01,$01,$01,$00,$02,$00,$01,$01,$00
        dc.b    $00,$01,$01,$00,$ff,$00,$00,$00,$01,$01,$00,$00,$00,$01,$00,$ff
        dc.b    $01,$00,$00,$00,$00,$00,$00,$00,$ff,$00,$00,$00,$00,$00,$ff,$ff
        dc.b    $00,$ff,$01,$00,$00,$ff,$01,$ff,$00,$ff,$00,$00,$00,$02,$ff,$00
        dc.b    $00,$01,$00,$ff,$00,$00,$00,$00,$00,$01,$ff,$00,$00,$ff,$00,$01
        dc.b    $ff,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$01,$00,$01,$00,$00
        dc.b    $ff,$00,$00,$00,$00,$01,$00,$01,$01,$00,$00,$00,$01,$00,$01,$01
        dc.b    $ff,$00,$01,$01,$01,$ff,$00,$00,$01,$00,$01,$00,$00,$00,$01,$00
        dc.b    $00,$ff,$01,$00,$00,$00,$00,$00,$ff,$ff,$00,$00,$00,$01,$ff,$ff
        dc.b    $02,$00,$00,$01,$01,$00,$00,$02,$00,$00,$00,$01,$00,$00,$00,$01
        dc.b    $00,$00,$02,$00,$01,$ff,$00,$00,$00,$01,$00,$01,$00,$01,$01,$ff
        dc.b    $ff,$00,$00,$01,$01,$00,$ff,$00,$01,$00,$01,$01,$01,$00,$00,$01
        dc.b    $00,$00,$ff,$00,$00,$00,$01,$00,$01,$01,$00,$00,$00,$ff,$00,$00
        dc.b    $ff,$00,$00,$00,$01,$ff,$00,$00,$00,$00,$00,$00,$01,$00,$ff,$02
        dc.b    $00,$00,$ff,$01,$00,$00,$ff,$00,$00,$ff,$01,$00,$00,$01,$02,$01
        dc.b    $01,$01,$02,$01,$03,$01,$01,$01,$01,$01,$02,$01,$02,$02,$00,$01
        dc.b    $01,$00,$01,$01,$00,$00,$01,$02,$00,$00,$01,$ff,$00,$ff,$ff,$00
        dc.b    $00,$ff,$00,$00,$ff,$ff,$ff,$00,$ff,$00,$00,$00,$01,$00,$00,$00
        dc.b    $ff,$00,$ff,$00,$ff,$00,$ff,$00,$00,$00,$ff,$ff,$00,$ff,$01,$00
        dc.b    $ff,$01,$ff,$00,$00,$01,$00,$00,$00,$01,$ff,$00,$ff,$01,$00,$00
        dc.b    $00,$00,$00,$00,$01,$00,$00,$00,$01,$ff,$ff,$00,$ff,$00,$00,$01
        dc.b    $00,$00,$00,$00,$00,$01,$00,$00,$ff,$00,$01,$00,$00,$01,$00,$00
        dc.b    $00,$01,$01,$01,$00,$01,$00,$01,$01,$01,$01,$00,$02,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$01,$ff,$00,$00,$00,$01,$00,$00,$00,$01,$00
        dc.b    $00,$00,$00,$00,$ff,$00,$00,$00,$01,$01,$00,$ff,$ff,$00,$00,$00
        dc.b    $00,$00,$00,$01,$00,$00,$01,$00,$00,$00,$01,$00,$ff,$ff,$ff,$00
        dc.b    $00,$00,$01,$01,$00,$01,$00,$01,$01,$01,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$00,$01,$01,$01,$01,$01,$01,$00,$00,$01,$00,$00,$01,$00
        dc.b    $00,$00,$01,$01,$00,$ff,$01,$00,$01,$ff,$00,$01,$00,$00,$00,$01
        dc.b    $ff,$01,$00,$00,$ff,$00,$00,$ff,$01,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$01,$01,$00,$01,$01,$01,$01,$01,$02,$01,$00,$00,$01,$01
        dc.b    $02,$02,$02,$00,$02,$01,$01,$00,$02,$00,$01,$00,$01,$ff,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$00,$00,$01,$00
        dc.b    $00,$01,$00,$00,$00,$ff,$00,$ff,$ff,$ff,$00,$ff,$00,$01,$fe,$ff
        dc.b    $ff,$00,$ff,$01,$ff,$ff,$ff,$00,$00,$ff,$ff,$01,$00,$00,$01,$ff
        dc.b    $00,$00,$00,$00,$00,$ff,$00,$fe,$ff,$ff,$ff,$fe,$ff,$01,$01,$00
        dc.b    $00,$00,$01,$ff
; ===========================================================================
; Wavetable voice waveforms (saw, pulse, sine).
; ===========================================================================
music_wavetable_presets_src:
        dc.b    $fe,$fb,$fc,$fd,$f9,$fa,$fc,$fb,$fc,$ff,$0a,$0e,$0a,$07,$fc,$ec
        dc.b    $e5,$eb,$e5,$d9,$dd,$f7,$17,$36,$28,$2f,$3f,$44,$24,$1f,$26,$00
        dc.b    $80,$80,$80,$80,$df,$7f,$7f,$7f,$70,$10,$80,$80,$9f,$8a,$80,$80
        dc.b    $bf,$b4,$cb,$e7,$ff,$17,$37,$4f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$00
        dc.b    $a0,$9f,$d7,$17,$7f,$7f,$7f,$7e,$74,$6a,$61,$59,$52,$4c,$45,$40
        dc.b    $3a,$20,$80,$80,$80,$80,$80,$80,$80,$80,$87,$3f,$7f,$7f,$7f,$60
        dc.b    $e0,$80,$9f,$b0,$90,$87,$80,$80,$80,$80,$80,$81,$93,$ff,$60,$2f
        dc.b    $53,$61,$77,$7f,$7f,$7f,$7c,$00,$d7,$08,$1b,$3f,$30,$00,$b0,$80
        dc.b    $80,$80,$bf,$7f,$7f,$7f,$7f,$7f,$7f,$00,$87,$80,$80,$80,$80,$80
        dc.b    $80,$80,$80,$bf,$7f,$7f,$40,$57,$67,$40,$e0,$3f,$7f,$40,$e8,$ef
        dc.b    $00,$83,$df,$1f,$7f,$7f,$7f,$7f,$7f,$c0,$ef,$3f,$40,$80,$81,$3f
        dc.b    $7f,$7f,$7c,$72,$69,$60,$58,$50,$4a,$80,$80,$80,$80,$bf,$2b,$00
        dc.b    $a6,$b5,$b0,$80,$80,$80,$80,$97,$b4,$90,$93,$ff,$7f,$00,$aa,$ff
        dc.b    $20,$d0,$d7,$d2,$ff,$6f,$40,$0f,$2f,$70,$14,$e8,$80,$ab,$8f,$99
        dc.b    $a1,$a9,$af,$b7,$bd,$c3,$3f,$00,$c3,$c7,$cd,$d1,$d5,$fb,$f4,$da
        dc.b    $de,$3f,$20,$1f,$38,$41,$45,$4d,$53,$7f,$78,$00,$a6,$ad,$b4,$ba
        dc.b    $bf,$c5,$ca,$cf,$df,$7f,$7f,$7f,$7f,$7f,$40,$c0,$af,$ff,$5f,$7f
        dc.b    $7f,$7f,$00,$80,$80,$80,$80,$87,$0f,$12,$77,$7f,$7f,$00,$80,$80
        dc.b    $80,$89,$93,$9b,$a5,$ac,$ff,$50,$04,$c0,$b2,$b9,$e0,$5f,$60,$1c
        dc.b    $35,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$50,$2b,$00,$f7,$6f,$44
        dc.b    $56,$27,$28,$2f,$6a,$62,$20,$80,$8f,$a8,$80,$90,$9f,$1f,$7f,$7f
        dc.b    $79,$70,$67,$60,$56,$50,$48,$27,$40,$3a,$36,$31,$2d,$1f,$27,$23
        dc.b    $10,$80,$80,$80,$80,$97,$bf,$1d,$10,$fc,$d0,$99,$ff,$6c,$63,$5a
        dc.b    $53,$4c,$46,$40,$30,$f8,$df,$10,$90,$80,$9f,$3f,$54,$4e,$48,$30
        dc.b    $c0,$df,$46,$40,$c0,$80,$80,$80,$81,$1b,$18,$f0,$80,$80,$80,$80
        dc.b    $80,$80,$80,$87,$5f,$7f,$7f,$70,$20,$90,$80,$80,$8f,$bf,$7f,$7f
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7b,$70,$68,$60,$e0,$80,$80,$df,$7c
        dc.b    $71,$60,$61,$58,$51,$4a,$44,$40,$c0,$80,$80,$df,$60,$df,$6b,$62
        dc.b    $59,$52,$00,$80,$80,$8f,$5f,$78,$70,$20,$0b,$08,$f8,$a8,$9f,$fb
        dc.b    $3f,$10,$80,$80,$80,$80,$df,$ea,$df,$5f,$68,$e5,$00,$80,$80,$83
        dc.b    $ff,$7f,$78,$90,$97,$d8,$b8,$9f,$3f,$14,$c8,$80,$ff,$7f,$78,$bf
        dc.b    $0f,$7f,$10,$80,$80,$80,$80,$80,$87,$8f,$99,$a2,$aa,$ff,$7f,$08
        dc.b    $3f,$7f,$60,$8a,$93,$9d,$a5,$ad,$b3,$ba,$bf,$3f,$7f,$77,$60,$50
        dc.b    $10,$c0,$9b,$a3,$ab,$b3,$b9,$bf,$c4,$c9,$ce,$d3,$7f,$7f,$00,$b7
        dc.b    $be,$c3,$c9,$cd,$d1,$d5,$db,$dc,$ff,$e1,$e3,$ff,$40,$0f,$5f,$78
        dc.b    $30,$d8,$cd,$07,$f0,$d4,$d6,$34,$25,$6f,$7f,$7f,$00,$f7,$60,$4f
        dc.b    $7f,$7f,$00,$81,$8d,$96,$ff,$7f,$70,$4b,$7f,$7f,$7f,$78,$e8,$80
        dc.b    $80,$80,$80,$ff,$7f,$5a,$7f,$7f,$7f,$7f,$7f,$7e,$a0,$80,$80,$af
        dc.b    $ef,$30,$c0,$9b,$c1,$b4,$80,$87,$af,$ff,$47,$40,$7f,$7f,$7f,$7c
        dc.b    $08,$f5,$2f,$30,$e5,$3f,$7f,$20,$e0,$5f,$40,$3f,$7f,$7f,$50,$80
        dc.b    $ff,$7e,$60,$2f,$68,$60,$58,$20,$80,$80,$80,$bb,$1f,$e6,$1f,$3a
        dc.b    $5f,$70,$66,$5c,$c8,$83,$ff,$40,$f0,$ff,$57,$59,$52,$40,$12,$1b
        dc.b    $08,$d7,$2f,$42,$3d,$38,$34,$30,$2c,$c0,$d9,$cc,$88,$80,$ff,$4a
        dc.b    $44,$40,$39,$34,$30,$08,$0f,$29,$26,$23,$20,$00,$bf,$1b,$c0,$80
        dc.b    $80,$a7,$cf,$ff,$57,$50,$4a,$40,$06,$d4,$c0,$80,$80,$80,$e7,$df
        dc.b    $1d,$5f,$68,$40,$e0,$80,$80,$80,$bf,$f9,$f8,$ff,$7f,$7f,$30,$33
        dc.b    $7f,$78,$6e,$66,$5c,$54,$1b,$28,$00,$b2,$80,$80,$80,$80,$8f,$2f
        dc.b    $7f,$7f,$78,$6e,$65,$5d,$08,$17,$c0,$80,$80,$80,$80,$80,$80,$80
        dc.b    $8d,$bf,$3f,$60,$7b,$7f,$7c,$40,$07,$20,$18,$e4,$a0,$80,$80,$80
        dc.b    $80,$80,$80,$85,$8f,$ff,$55,$32,$00,$fb,$e4,$98,$9a,$a3,$1a,$c8
        dc.b    $ad,$ff,$48,$00,$ad,$b4,$27,$f0,$b9,$bf,$c5,$ca,$ff,$7f,$7f,$40
        dc.b    $07,$18,$d0,$b4,$ba,$bf,$c6,$cb,$cf,$d3,$d7,$da,$6f,$7f,$7f,$7f
        dc.b    $68,$6f,$78,$40,$00,$e4,$8d,$97,$9f,$a7,$bf,$5f,$48,$f4,$e0,$ab
        dc.b    $b2,$b9,$bf,$c4,$c9,$ce,$d2,$ef,$5f,$7f,$7f,$08,$df,$17,$2a,$2b
        dc.b    $40,$e0,$af,$bf,$3f,$0c,$3f,$7b,$7f,$30,$d0,$c0,$a6,$c5,$c2,$be
        dc.b    $df,$6f,$7f,$7f,$78,$6f,$74,$10,$80,$80,$8f,$8f,$9f,$fb,$16,$3f
        dc.b    $7f,$7f,$7f,$7f,$7f,$7f,$40,$04,$f0,$0f,$5b,$54,$18,$c0,$80,$83
        dc.b    $af,$ff,$42,$46,$20,$05,$27,$61,$62,$28,$08,$07,$1f,$14,$02,$f9
        dc.b    $e8,$ce,$d2,$d3,$fd,$f5,$e8,$ef,$3a,$08,$e4,$ef,$2f,$4a,$41,$40
        dc.b    $40,$28,$2f,$72,$60,$10,$0d,$3f,$7c,$71,$40,$42,$22,$00,$b0,$80
        dc.b    $bf,$ff,$3b,$63,$66,$30,$e7,$f3,$2f,$14,$f0,$ed,$ff,$18,$1f,$28
        dc.b    $00,$f0,$e0,$f5,$1b,$56,$20,$c0,$80,$80,$af,$c8,$ac,$ef,$57,$78
        dc.b    $6c,$64,$5c,$54,$4e,$47,$20,$88,$87,$bb,$b0,$b3,$c5,$bf,$cf,$a2
        dc.b    $bf,$c5,$cf,$2f,$50,$f4,$d8,$b6,$cf,$d4,$ef,$5f,$74,$4d,$57,$55
        dc.b    $57,$5d,$5c,$48,$18,$f7,$24,$10,$d0,$b3,$c7,$a8,$80,$83,$cb,$c0
        dc.b    $80,$a7,$bf,$d7,$f7,$1b,$20,$e0,$98,$bf,$e0,$a8,$87,$c7,$d3,$f7
        dc.b    $e8,$b8,$97,$cf,$1e,$1b,$18,$0e,$00,$c0,$80,$80,$cf,$3f,$28,$18
        dc.b    $00,$ff,$1b,$10,$ef,$3f,$30,$08,$e8,$e5,$ff,$ff,$00,$e3,$ff,$27
        dc.b    $08,$e3,$ff,$1f,$00,$e3,$07,$27,$39,$28,$04,$e0,$a0,$80,$97,$fb
        dc.b    $5f,$60,$30,$00,$e1,$e8,$a0,$83,$8f,$9f,$bb,$db,$ff,$3b,$6b,$50
        dc.b    $30,$18,$f5,$e2,$e0,$d3,$08,$ee,$ec,$da,$ff,$3b,$50,$20,$e7,$f7
        dc.b    $09,$f8,$fb,$0b,$06,$f8,$f7,$e0,$bd,$e7,$17,$59,$30,$f9,$0f,$20
        dc.b    $1a,$23,$47,$77,$68,$00,$ea,$ec,$ff,$1c,$0f,$02,$02,$fb,$0d,$10
        dc.b    $e8,$c7,$e7,$f5,$0f,$48,$2d,$4b,$48,$00,$c7,$f6,$0f,$fc,$05,$08
        dc.b    $f7,$07,$1f,$44,$08,$d8,$e1,$ff,$03,$f8,$07,$20,$00,$05,$f8,$e8
        dc.b    $d4,$c8,$e7,$1f,$4f,$40,$47,$4f,$6b,$62,$75,$6c,$52,$44,$3a,$20
        dc.b    $e2,$e7,$07,$1e,$00,$ff,$0c,$08,$f8,$c8,$84,$af,$ff,$5b,$7f,$6c
        dc.b    $4a,$44,$28,$00,$d6,$eb,$ec,$d8,$b4,$ba,$bf,$cf,$f5,$0b,$17,$3f
        dc.b    $68,$4e,$30,$f4,$d5,$f9,$e0,$ca,$e7,$2d,$34,$20,$26,$37,$4b,$40
        dc.b    $21,$26,$2c,$2d,$18,$00,$e7,$f0,$f2,$06,$f4,$e8,$ef,$e0,$cb,$df
        dc.b    $ff,$00,$fd,$f7,$f0,$f3,$1b,$14,$f0,$e4,$ed,$f0,$e0,$d2,$c6,$df
        dc.b    $e1,$0f,$08,$07,$1b,$25,$12,$0e,$10,$f5,$03,$00,$e8,$cd,$df,$f3
        dc.b    $ee,$ff,$fa,$07,$3b,$40,$28,$27,$2f,$37,$30,$26,$08,$ea,$e3,$e9
        dc.b    $e0,$d6,$ce,$b0,$b7,$df,$d6,$ea,$e0,$da,$dd,$da,$cb,$df,$e0,$cb
        dc.b    $ca,$e7,$f2,$fa,$f8,$e1,$da,$d5,$e3,$fb,$ff,$0d,$1f,$14,$e8,$d0
        dc.b    $c7,$b8,$bb,$db,$ff,$2d,$30,$12,$f4,$d8,$e7,$07,$00,$ec,$ef,$2b
        dc.b    $34,$18,$0b,$0c,$00,$cc,$b9,$b3,$cf,$fe,$07,$fe,$00,$e0,$eb,$0f
        dc.b    $16,$08,$f8,$0f,$3b,$2a,$04,$d4,$cf,$e1,$c8,$bd,$cf,$fb,$0e,$06
        dc.b    $0b,$2f,$40,$26,$18,$00,$e9,$e1,$ed,$f1,$ff,$00,$07,$1f,$3b,$3a
        dc.b    $20,$e0,$c5,$df,$e5,$f5,$f6,$f2,$f7,$1f,$32,$2a,$24,$08,$05,$0d
        dc.b    $1f,$37,$40,$29,$26,$2c,$2b,$25,$1b,$18,$18,$02,$ec,$db,$e4,$e3
        dc.b    $ec,$e6,$e6,$e8,$eb,$ef,$f0,$f4,$fe,$0f,$23,$43,$39,$2c,$18,$f8
        dc.b    $d4,$ce,$eb,$17,$37,$3a,$20,$f0,$d2,$dd,$ef,$ef,$f2,$ee,$e5,$e5
        dc.b    $ee,$fa,$ff,$13,$1a,$16,$1f,$34,$1c,$08,$fe,$ff,$1f,$3f,$38,$2e
        dc.b    $3f,$50,$28,$08,$e0,$d7,$de,$d9,$d9,$df,$fb,$0c,$05,$07,$0e,$13
        dc.b    $14,$10,$04,$f9,$07,$0f,$13,$0c,$06,$03,$0a,$1f,$30,$0c,$fe,$fc
        dc.b    $0b,$22,$30,$20,$1d,$0c,$fa,$07,$24,$1c,$0e,$10,$07,$0b,$0d,$00
        dc.b    $ef,$ff,$02,$06,$0b,$0a,$04,$01,$0c,$01,$ea,$d8,$db,$f3,$0f,$21
        dc.b    $10,$02,$0b,$10,$00,$ea,$ef,$f8,$f1,$f4,$07,$13,$1a,$06,$f4,$ed
        dc.b    $f3,$f6,$f3,$0f,$1d,$29,$20,$f6,$f4,$ee,$e8,$e5,$ef,$fb,$00,$ea
        dc.b    $eb,$fe,$ff,$07,$00,$e8,$d0,$d7,$e0,$d4,$cb,$db,$ef,$17,$2c,$26
        dc.b    $1e,$1f,$23,$10,$f4,$ef,$e8,$ef,$05,$08,$ff,$fe,$ff,$00,$f0,$ee
        dc.b    $f5,$f7,$ff,$17,$33,$30,$18,$f8,$ed,$ea,$d6,$d2,$d9,$d1,$df,$ff
        dc.b    $1f,$26,$1e,$0a,$f8,$f1,$f6,$ff,$04,$ff,$f4,$ee,$fb,$f2,$e0,$e7
        dc.b    $ec,$ec,$ff,$00,$07,$04,$00,$ec,$dc,$d7,$df,$f7,$0f,$14,$04,$fd
        dc.b    $fe,$f8,$f6,$02,$02,$fa,$f2,$e8,$da,$cd,$d6,$d6,$d4,$ef,$1b,$2f
        dc.b    $27,$1a,$0a,$0b,$07,$f8,$e2,$eb,$06,$03,$f3,$f3,$f1,$f7,$07,$16
        dc.b    $13,$13,$1b,$15,$12,$13,$1e,$20,$10,$f2,$ea,$f3,$f2,$ef,$f3,$07
        dc.b    $13,$0f,$0e,$00,$f6,$fe,$0a,$17,$11,$06,$f4,$f2,$e9,$e3,$e6,$ef
        dc.b    $ff,$17,$19,$1b,$1d,$18,$f8,$e1,$e6,$fb,$17,$2a,$14,$11,$0c,$09
        dc.b    $15,$19,$00,$f0,$e8,$ee,$fd,$05,$01,$ff,$09,$0b,$00,$ea,$ea,$fb
        dc.b    $fc,$f6,$f7,$fc,$03,$01,$00,$fd,$fc,$fd,$06,$09,$0f,$1e,$18,$1a
        dc.b    $29,$2c,$14,$00,$f2,$fd,$06,$0c,$0e,$0c,$00,$fa,$f9,$fb,$f8,$fa
        dc.b    $f5,$05,$07,$19,$25,$11,$00,$f7,$fb,$f8,$e9,$ee,$ef,$ff,$15,$12
        dc.b    $10,$0f,$19,$16,$0c,$f8,$da,$de,$eb,$ff,$0f,$17,$12,$fa,$f1,$ff
        dc.b    $0e,$16,$0d,$fd,$f9,$f0,$eb,$f5,$03,$0c,$11,$0f,$04,$f1,$ed,$ff
        dc.b    $0a,$03,$ff,$03,$08,$07,$0d,$16,$15,$0d,$0e,$13,$19,$16,$0c,$00
        dc.b    $fd,$fc,$fb,$03,$07,$0b,$0a,$04,$fd,$07,$00,$f6,$f7,$01,$fc,$f6
        dc.b    $fd,$0c,$0e,$05,$07,$0f,$04,$fb,$01,$07,$0d,$06,$fd,$f4,$f3,$e8
        dc.b    $eb,$f3,$f5,$ef,$f5,$f9,$03,$09,$0d,$03,$fc,$f9,$f2,$ef,$ed,$f2
        dc.b    $05,$09,$00,$f9,$ff,$02,$f4,$f3,$fa,$05,$0f,$10,$09,$03,$fd,$ff
        dc.b    $04,$03,$0a,$0c,$02,$f8,$f9,$fc,$fa,$fc,$f8,$f2,$f4,$f2,$f2,$f0
        dc.b    $ec,$ef,$fa,$ff,$fe,$f9,$f0,$ec,$ef,$f6,$f7,$ff,$17,$24,$1c,$0d
        dc.b    $09,$0b,$0d,$11,$0d,$0a,$09,$02,$f8,$ff,$04,$06,$f6,$ed,$e8,$ed
        dc.b    $f2,$f4,$f7,$07,$08,$0a,$0f,$1b,$1a,$11,$00,$f9,$fe,$f6,$e9,$ef
        dc.b    $fd,$0b,$06,$03,$07,$0d,$04,$fd,$01,$03,$03,$00,$f7,$fb,$03,$00
        dc.b    $f6,$f2,$eb,$e5,$ef,$f5,$f4,$fb,$07,$08,$04,$07,$0c,$06,$07,$00
        dc.b    $05,$0f,$0e,$05,$00,$f9,$f3,$f7,$03,$02,$ff,$07,$0e,$17,$1c,$14
        dc.b    $08,$fe,$fb,$f6,$e9,$e7,$f2,$fe,$07,$07,$0c,$0d,$0b,$0a,$09,$0e
        dc.b    $06,$fc,$fb,$fb,$f4,$f4,$f7,$f3,$f3,$f8,$f7,$fb,$ff,$0a,$0f,$10
        dc.b    $04,$fe,$fe,$ff,$00,$fa,$f2,$ed,$f3,$f9,$03,$0f,$12,$0a,$00,$fd
        dc.b    $02,$04,$03,$07,$11,$10,$06,$07,$0b,$0a,$03,$fc,$f6,$f4,$f2,$f9
        dc.b    $fc,$fc,$fd,$ff,$02,$05,$0d,$0e,$0e,$0b,$0e,$0e,$0b,$00,$f9,$fa
        dc.b    $fa,$f4,$f9,$03,$0e,$0f,$06,$02,$02,$02,$03,$09,$05,$f8,$f7,$ff
        dc.b    $05,$02,$fa,$f8,$f6,$fb,$ff,$04,$01,$fe,$fa,$f7,$f8,$fe,$fb,$f5
        dc.b    $f8,$fc,$fd,$fd,$02,$04,$08,$05,$00,$fe,$fe,$00,$04,$02,$00,$05
        dc.b    $0a,$03,$02,$03,$06,$01,$05,$00,$fa,$f4,$f7,$03,$03,$06,$06,$09
        dc.b    $09,$08,$0b,$0b,$04,$ff,$fc,$f1,$f3,$f5,$f5,$f3,$f7,$fa,$fa,$fc
        dc.b    $fd,$fe,$01,$04,$07,$0a,$0a,$04,$ff,$00,$fc,$fb,$fa,$f9,$fb,$03
        dc.b    $04,$05,$05,$07,$0b,$07,$08,$09,$05,$02,$05,$00,$fe,$fa,$fb,$02
        dc.b    $06,$08,$07,$05,$07,$0a,$05,$0a,$09,$04,$04,$03,$02,$00,$fc,$f1
        dc.b    $f0,$f3,$fb,$ff,$0b,$0b,$0b,$07,$01,$fd,$f9,$fb,$03,$07,$07,$08
        dc.b    $0c,$0d,$02,$f8,$f9,$fa,$f9,$fa,$fb,$fc,$03,$05,$00,$fb,$f8,$f8
        dc.b    $f7,$fb,$02,$04,$07,$07,$03,$01,$01,$ff,$ff,$fe,$00,$05,$09,$04
        dc.b    $00,$01,$07,$07,$03,$02,$04,$03,$04,$05,$02,$03,$06,$03,$00,$fa
        dc.b    $fc,$ff,$09,$07,$04,$02,$03,$02,$03,$00,$01,$06,$00,$fd,$ff,$ff
        dc.b    $fd,$00,$fe,$01,$04,$03,$02,$07,$06,$05,$03,$01,$fb,$f4,$f2,$f6
        dc.b    $fc,$06,$07,$04,$04,$02,$00,$ff,$ff,$f8,$f6,$f8,$ff,$05,$05,$03
        dc.b    $fe,$fb,$fd,$01,$02,$fd,$fb,$fd,$fe,$fb,$fd,$ff,$fd,$fd,$04,$06
        dc.b    $04,$04,$05,$00,$ff,$03,$00,$fc,$fd,$ff,$fc,$f7,$fb,$fc,$ff,$03
        dc.b    $03,$02,$03,$02,$00,$fc,$f9,$fa,$fe,$03,$03,$03,$01,$00,$04,$06
        dc.b    $0a,$08,$05,$02,$03,$03,$03,$02,$00,$ff,$fe,$fc,$fa,$ff,$04,$00
        dc.b    $fe,$00,$02,$ff,$fc,$fc,$fd,$fb,$fc,$fb,$ff,$02,$ff,$fc,$fb,$fc
        dc.b    $fd,$ff,$05,$04,$00,$00,$ff,$fe,$fe,$03,$04,$00,$02,$ff,$01,$03
        dc.b    $06,$02,$fa,$fc,$ff,$00,$ff,$03,$05,$02,$03,$04,$03,$02,$00,$fd
        dc.b    $fc,$ff,$02,$00,$00,$ff,$fc,$fd,$fc,$fa,$fd,$01,$00,$00,$03,$05
        dc.b    $09,$08,$06,$00,$00,$00,$fd,$fb,$f9,$fb,$fc,$ff,$02,$07,$07,$03
        dc.b    $00,$02,$02,$05,$06,$07,$02,$fb,$f5,$fb,$ff,$fe,$fd,$ff,$01,$00
        dc.b    $00,$ff,$03,$04,$06,$09,$08,$01,$ff,$ff,$01,$fc,$fa,$ff,$00,$00
        dc.b    $ff,$02,$0a,$0c,$08,$07,$05,$05,$02,$ff,$02,$00,$fc,$fa,$fb,$ff
        dc.b    $02,$03,$07,$06,$06,$05,$02,$fe,$ff,$fe,$fc,$fb,$fb,$fc,$fd,$fc
        dc.b    $fe,$02,$06,$06,$06,$02,$01,$00,$ff,$01,$07,$09,$09,$05,$01,$03
        dc.b    $03,$03,$04,$02,$ff,$ff,$02,$01,$00,$00,$ff,$03,$03,$01,$02,$03
        dc.b    $03,$03,$02,$00,$ff,$ff,$ff,$00,$00,$fd,$fe,$03,$07,$06,$05,$05
        dc.b    $06,$00,$fe,$fb,$fb,$fe,$01,$03,$00,$03,$03,$04,$03,$06,$05,$03
        dc.b    $ff,$ff,$ff,$ff,$05,$05,$03,$00,$fe,$fe,$ff,$ff,$00,$fd,$ff,$ff
        dc.b    $00,$fc,$00,$fc,$f8,$f9,$fe,$01,$00,$ff,$03,$05,$03,$03,$00,$fc
        dc.b    $fd,$fd,$fc,$fb,$fc,$ff,$02,$04,$05,$09,$05,$03,$02,$01,$00,$ff
        dc.b    $fd,$f9,$fc,$ff,$ff,$02,$04,$06,$03,$00,$fc,$f8,$fb,$fd,$ff,$00
        dc.b    $00,$01,$02,$02,$03,$03,$00,$02,$03,$03,$01,$02,$00,$ff,$ff,$fe
        dc.b    $00,$fe,$fd,$ff,$03,$03,$00,$ff,$fd,$fb,$fd,$01,$04,$04,$01,$04
        dc.b    $06,$00,$fe,$fe,$fe,$fd,$fd,$fe,$01,$05,$04,$00,$fd,$01,$00,$fe
        dc.b    $fe,$02,$01,$ff,$ff,$03,$02,$02,$02,$02,$03,$01,$ff,$fe,$ff,$fe
        dc.b    $ff,$01,$02,$ff,$00,$ff,$fd,$f9,$f8,$fb,$ff,$01,$00,$02,$01,$fe
        dc.b    $fb,$fe,$fe,$fe,$ff,$ff,$00,$01,$ff,$02,$02,$01,$01,$03,$05,$04
        dc.b    $02,$02,$03,$05,$03,$00,$03,$06,$05,$03,$04,$01,$00,$fd,$fe,$ff
        dc.b    $ff,$ff,$04,$03,$00,$01,$fe,$fd,$fd,$ff,$ff,$ff,$01,$00,$02,$01
        dc.b    $01,$fe,$01,$01,$01,$00,$03,$05,$04,$02,$ff,$ff,$00,$fe,$ff,$01
        dc.b    $00,$ff,$ff,$fe,$fe,$ff,$00,$00,$00,$00,$ff,$01,$03,$ff,$fd,$fc
        dc.b    $ff,$ff,$ff,$ff,$04,$06,$07,$08,$06,$07,$06,$07,$06,$04,$01,$05
        dc.b    $04,$02,$00,$ff,$fe,$fe,$ff,$00,$01,$02,$03,$03,$03,$03,$01,$00
        dc.b    $ff,$ff,$fe,$fd,$fc,$fc,$fc,$fc,$ff,$01,$00,$01,$04,$05,$05,$05
        dc.b    $02,$02,$03,$01,$fe,$ff,$ff,$00,$00,$ff,$02,$00,$fd,$fe,$ff,$ff
        dc.b    $fe,$ff,$01,$04,$02,$03,$04,$06,$04,$01,$00,$ff,$01,$00,$01,$ff
        dc.b    $ff,$fe,$fe,$ff,$00,$00,$00,$ff,$fe,$ff,$00,$00,$00,$fe,$01,$00
        dc.b    $01,$ff,$ff,$01,$00,$fe,$fe,$00,$02,$00,$fe,$fe,$ff,$00,$ff,$01
        dc.b    $02,$02,$00,$01,$03,$03,$01,$ff,$02,$00,$ff,$00,$00,$00,$ff,$02
        dc.b    $01,$04,$04,$02,$02,$03,$03,$02,$01,$01,$ff,$fe,$ff,$00,$ff,$ff
        dc.b    $02,$03,$04,$03,$01,$ff,$fe,$fd,$ff,$02,$02,$ff,$00,$00,$ff,$00
        dc.b    $00,$ff,$00,$01,$02,$00,$ff,$00,$ff,$01,$01,$fd,$fd,$fe,$ff,$fe
        dc.b    $00,$01,$02,$02,$ff,$00,$01,$04,$02,$01,$00,$ff,$00,$ff,$ff,$ff
        dc.b    $ff,$00,$02,$01,$00,$00,$02,$05,$03,$03,$03,$01,$00,$01,$03,$02
        dc.b    $00,$ff,$fe,$fc,$fc,$fb,$fc,$fe,$ff,$fe,$03,$02,$01,$fe,$ff,$03
        dc.b    $02,$00,$02,$03,$03,$00,$ff,$01,$01,$00,$ff,$ff,$00,$ff,$03,$03
        dc.b    $04,$03,$03,$04,$06,$05,$02,$02,$ff,$00,$fe,$fe,$ff,$fe,$fc,$ff
        dc.b    $ff,$00,$00,$ff,$ff,$02,$03,$01,$02,$01,$02,$03,$01,$01,$fe,$fd
        dc.b    $fc,$ff,$ff,$02,$01,$06,$05,$02,$03,$03,$02,$00,$ff,$fe,$ff,$fd
        dc.b    $fe,$ff,$ff,$00,$01,$00,$00,$ff,$fe,$ff,$00,$ff,$01,$02,$03,$03
        dc.b    $00,$00,$00,$05,$03,$00,$ff,$ff,$ff,$01,$01,$00,$01,$01,$04,$01
        dc.b    $00,$00,$00,$00,$fd,$fc,$fc,$fe,$ff,$00,$ff,$01,$02,$00,$01,$03
        dc.b    $02,$00,$01,$00,$00,$00,$ff,$01,$00,$fe,$ff,$00,$02,$00,$00,$00
        dc.b    $01,$01,$02,$05,$06,$04,$02,$01,$00,$02,$00,$02,$00,$00,$ff,$ff
        dc.b    $01,$00,$01,$ff,$01,$fe,$fd,$fe,$ff,$ff,$ff,$02,$02,$05,$05,$04
        dc.b    $00,$ff,$fd,$fe,$fe,$ff,$01,$00,$ff,$01,$03,$02,$01,$02,$02,$00
        dc.b    $01,$03,$01,$ff,$00,$01,$00,$ff,$fe,$00,$02,$03,$01,$00,$00,$ff
        dc.b    $fe,$00,$01,$01,$01,$02,$00,$fd,$fe,$ff,$00,$fe,$fc,$ff,$00,$01
        dc.b    $02,$04,$03,$01,$02,$01,$01,$01,$02,$01,$02,$03,$00,$00,$00,$fe
        dc.b    $fe,$fe,$ff,$00,$00,$02,$04,$05,$02,$02,$01,$00,$00,$01,$01,$00
        dc.b    $fe,$fd,$ff,$00,$fe,$fe,$00,$03,$03,$01,$01,$02,$03,$02,$00,$02
        dc.b    $03,$02,$00,$01,$00,$ff,$00,$fd,$fe,$ff,$03,$03,$04,$04,$03,$03
        dc.b    $03,$00,$ff,$fe,$fe,$ff,$ff,$fe,$ff,$ff,$00,$ff,$ff,$ff,$02,$01
        dc.b    $01,$ff,$fe,$ff,$01,$00,$01,$02,$03,$01,$01,$ff,$01,$03,$02,$01
        dc.b    $00,$01,$ff,$ff,$00,$01,$02,$00,$ff,$00,$00,$00,$03,$01,$01,$01
        dc.b    $01,$03,$01,$ff,$fe,$ff,$00,$ff,$fe,$fe,$ff,$00,$00,$00,$02,$02
        dc.b    $00,$00,$01,$02,$00,$01,$02,$02,$ff,$ff,$ff,$01,$ff,$00,$00,$00
        dc.b    $00,$ff,$ff,$00,$01,$ff,$ff,$00,$02,$00,$00,$01,$01,$02,$00,$01
        dc.b    $ff,$00,$fe,$fe,$ff,$fe,$fe,$fe,$fe,$ff,$01,$04,$04,$04,$02,$00
        dc.b    $00,$fe,$fe,$fe,$ff,$ff,$00,$05,$06,$05,$03,$03,$03,$00,$ff,$ff
        dc.b    $00,$01,$00,$00,$00,$00,$ff,$fe,$01,$00,$00,$ff,$00,$00,$ff,$ff
        dc.b    $00,$01,$01,$01,$00,$ff,$00,$02,$03,$03,$02,$01,$02,$02,$04,$05
        dc.b    $02,$00,$fe,$fc,$fe,$00,$fe,$ff,$01,$02,$03,$01,$00,$00,$02,$00
        dc.b    $fe,$ff,$03,$00,$ff,$ff,$00,$00,$fd,$ff,$01,$02,$03,$03,$03,$02
        dc.b    $00,$ff,$ff,$00,$01,$00,$ff,$01,$03,$02,$02,$02,$00,$00,$ff,$ff
        dc.b    $01,$ff,$ff,$00,$00,$02,$01,$01,$fe,$ff,$ff,$00,$ff,$01,$ff,$00
        dc.b    $ff,$fe,$fe,$00,$01,$03,$03,$05,$07,$07,$05,$02,$01,$fd,$fc,$fc
        dc.b    $ff,$00,$ff,$00,$02,$04,$03,$03,$01,$01,$01,$ff,$00,$01,$02,$01
        dc.b    $02,$03,$00,$00,$ff,$01,$ff,$ff,$ff,$00,$00,$fe,$ff,$ff,$ff,$ff
        dc.b    $ff,$00,$00,$ff,$ff,$01,$00,$ff,$01,$04,$05,$03,$01,$00,$00,$fe
        dc.b    $fd,$fd,$01,$00,$01,$01,$03,$02,$03,$03,$02,$00,$fe,$fe,$fe,$fd
        dc.b    $ff,$ff,$02,$ff,$ff,$01,$01,$ff,$ff,$00,$fe,$ff,$fe,$00,$ff,$01
        dc.b    $00,$01,$04,$03,$01,$ff,$01,$ff,$ff,$01,$02,$02,$00,$ff,$00,$02
        dc.b    $01,$ff,$00,$ff,$ff,$00,$02,$01,$01,$01,$03,$03,$01,$00,$00,$ff
        dc.b    $00,$ff,$00,$01,$00,$ff,$01,$01,$01,$01,$02,$02,$00,$ff,$ff,$01
        dc.b    $03,$03,$03,$01,$02,$ff,$fe,$fe,$ff,$fe,$fe,$ff,$ff,$00,$01,$02
        dc.b    $03,$03,$01,$01,$01,$00,$00,$ff,$00,$00,$ff,$02,$01,$01,$fe,$fe
        dc.b    $ff,$01,$02,$03,$03,$04,$04,$03,$02,$02,$00,$00,$ff,$ff,$fc,$fa
        dc.b    $ff,$ff,$00,$fe,$ff,$00,$01,$03,$03,$02,$fe,$fe,$fd,$fe,$fe,$fc
        dc.b    $fd,$01,$04,$04,$03,$03,$03,$01,$02,$01,$04,$04,$03,$04,$03,$02
        dc.b    $02,$ff,$01,$01,$ff,$ff,$00,$ff,$ff,$00,$00,$01,$ff,$01,$01,$02
        dc.b    $00,$00,$02,$03,$03,$00,$ff,$02,$03,$01,$01,$03,$02,$01,$00,$01
        dc.b    $02,$02,$00,$00,$03,$00,$ff,$fc,$fc,$fe,$fc,$fe,$00,$00,$ff,$00
        dc.b    $00,$00,$ff,$02,$02,$01,$01,$00,$01,$01,$02,$01,$01,$ff,$ff,$ff
        dc.b    $ff,$ff,$00,$01,$05,$07,$03,$03,$03,$04,$00,$fe,$fe,$fe,$fd,$fd
        dc.b    $fd,$fe,$ff,$ff,$02,$03,$03,$02,$01,$01,$01,$01,$00,$00,$01,$fe
        dc.b    $ff,$00,$02,$01,$00,$01,$00,$00,$ff,$01,$01,$02,$03,$03,$02,$00
        dc.b    $00,$fe,$fe,$fd,$fe,$fe,$ff,$00,$00,$01,$01,$03,$01,$00,$02,$01
        dc.b    $02,$00,$01,$01,$ff,$00,$ff,$00,$fd,$fe,$00,$00,$ff,$ff,$01,$00
        dc.b    $03,$02,$01,$03,$03,$03,$01,$01,$fe,$fd,$fd,$fc,$fe,$ff,$01,$04
        dc.b    $03,$03,$03,$04,$01,$00,$00,$ff,$fe,$fd,$fe,$fe,$02,$01,$00,$02
        dc.b    $02,$03,$00,$02,$05,$02,$00,$ff,$01,$01,$00,$02,$02,$00,$fe,$fe
        dc.b    $00,$00,$fe,$ff,$00,$02,$01,$01,$01,$01,$00,$ff,$ff,$00,$01,$00
        dc.b    $00,$00,$ff,$00,$00,$01,$ff,$fe,$ff,$ff,$00,$ff,$02,$04,$06,$04
        dc.b    $02,$01,$02,$01,$ff,$fe,$ff,$ff,$00,$00,$ff,$01,$01,$02,$03,$01
        dc.b    $00,$ff,$01,$00,$00,$01,$01,$00,$00,$02,$02,$01,$01,$ff,$01,$00
        dc.b    $ff,$00,$01,$01,$03,$02,$03,$03,$00,$ff,$01,$00,$00,$00,$ff,$00
        dc.b    $01,$ff,$01,$00,$01,$01,$02,$01,$01,$00,$00,$03,$01,$01,$00,$01
        dc.b    $00,$ff,$fe,$ff,$ff,$ff,$00,$01,$02,$01,$ff,$02,$02,$01,$00,$01
        dc.b    $01,$01,$00,$00,$fe,$ff,$ff,$00,$01,$00,$01,$01,$02,$02,$01,$00
        dc.b    $00,$00,$00,$fe,$ff,$ff,$00,$ff,$ff,$00,$fe,$ff,$ff,$fe,$01,$ff
        dc.b    $01,$00,$00,$ff,$00,$01,$01,$02,$01,$01,$01,$00,$fe,$00,$02,$00
        dc.b    $fe,$01,$ff,$00,$01,$02,$ff,$01,$00,$03,$02,$00,$ff,$ff,$ff,$fe
        dc.b    $ff,$ff,$01,$02,$ff,$00,$01,$01,$00,$00,$ff,$ff,$00,$00,$02,$00
        dc.b    $ff,$fe,$03,$02,$02,$02,$03,$01,$00,$ff,$02,$01,$00,$ff,$fe,$01
        dc.b    $00,$ff,$ff,$ff,$00,$ff,$00,$00,$02,$00,$01,$02,$01,$00,$ff,$ff
        dc.b    $01,$00,$01,$00,$00,$01,$04,$03,$02,$01,$02,$02,$01,$ff,$03,$02
        dc.b    $02,$ff,$00,$ff
; ===========================================================================
; Synthesizer instruments presets and vibrato speeds.
; ===========================================================================
music_synth_presets_src:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$ff,$00,$ff,$00,$00,$00,$00,$ff,$00,$00,$00,$00,$00,$00
        dc.b    $00,$01,$01,$01,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$00,$00
        dc.b    $00,$00,$00,$00,$ff,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$00,$00,$00,$00,$00,$00,$01,$01,$01,$03,$03,$03,$03,$03,$03
        dc.b    $02,$02,$02,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$01,$02,$02
        dc.b    $06,$05,$05,$05,$04,$04,$04,$04,$03,$02,$02,$01,$01,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$fe,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe
        dc.b    $fe,$fe,$fe,$02,$03,$03,$07,$08,$07,$07,$07,$07,$06,$05,$05,$04
        dc.b    $03,$02,$01,$01,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fb,$fb
        dc.b    $fb,$fb,$fb,$fb,$fc,$fc,$fc,$fc,$fd,$03,$04,$04,$07,$0e,$0c,$0c
        dc.b    $0c,$0b,$0a,$09,$08,$07,$05,$04,$02,$01,$00,$fe,$fd,$fc,$fb,$fa
        dc.b    $f9,$f9,$f8,$f8,$f8,$f7,$f7,$f7,$f7,$f8,$f8,$f8,$f8,$f9,$fa,$05
        dc.b    $07,$06,$09,$18,$13,$13,$13,$12,$11,$0f,$0d,$0b,$09,$06,$04,$01
        dc.b    $00,$fd,$fc,$f9,$f8,$f6,$f5,$f3,$f2,$f1,$f1,$f0,$f0,$f0,$f0,$f1
        dc.b    $f1,$f2,$f3,$f4,$f6,$07,$0a,$0a,$0d,$27,$20,$1f,$1f,$1e,$1c,$19
        dc.b    $16,$12,$0e,$0b,$07,$03,$00,$fc,$f8,$f5,$f2,$f0,$ee,$eb,$ea,$e8
        dc.b    $e7,$e7,$e6,$e6,$e6,$e7,$e7,$e9,$ea,$ec,$ee,$0f,$10,$10,$13,$2f
        dc.b    $36,$33,$33,$31,$2e,$29,$24,$1e,$18,$11,$0b,$05,$00,$f9,$f4,$ee
        dc.b    $e9,$e5,$e1,$de,$db,$d8,$d6,$d5,$d4,$d4,$d5,$d6,$d7,$d9,$db,$de
        dc.b    $e1,$17,$19,$1a,$1f,$37,$60,$53,$53,$50,$4c,$44,$3c,$33,$28,$1e
        dc.b    $14,$09,$00,$f6,$ec,$e3,$dc,$d4,$ce,$c8,$c3,$bf,$bc,$ba,$b9,$b8
        dc.b    $b9,$ba,$bc,$bf,$c3,$c7,$cd,$17,$28,$29,$31,$3f,$7f,$7f,$7f,$7c
        dc.b    $75,$6a,$5a,$4e,$40,$30,$20,$10,$01,$f4,$e6,$d9,$ce,$c6,$bd,$b6
        dc.b    $b0,$ac,$aa,$a8,$a7,$a8,$aa,$ad,$b2,$b7,$bd,$c3,$cb,$ff,$28,$29
        dc.b    $31,$37,$7f,$7f,$7f,$7f,$78,$6e,$61,$52,$44,$34,$24,$14,$05,$f8
        dc.b    $ea,$e0,$d2,$c8,$c0,$b9,$b3,$ae,$ac,$a9,$a9,$a9,$ab,$ae,$b1,$b7
        dc.b    $bc,$c3,$ca,$17,$28,$27,$2f,$36,$7f,$7f,$7f,$7e,$78,$70,$62,$54
        dc.b    $46,$35,$26,$16,$08,$f9,$ec,$e0,$d4,$ca,$c1,$ba,$b4,$af,$ac,$aa
        dc.b    $a9,$a9,$ab,$ae,$b2,$b6,$bc,$c2,$c9,$17,$24,$27,$2f,$34,$5f,$7f
        dc.b    $7f,$7e,$78,$70,$63,$56,$48,$38,$28,$18,$08,$fa,$ee,$e1,$d4,$cb
        dc.b    $c2,$bb,$b4,$b0,$ad,$aa,$a9,$aa,$ab,$ae,$b1,$b6,$bb,$c2,$c9,$1f
        dc.b    $24,$26,$2f,$33,$3f,$7f,$7e,$7c,$78,$70,$64,$58,$48,$38,$29,$19
        dc.b    $0a,$fc,$f0,$e3,$d6,$cc,$c4,$bc,$b6,$b1,$ae,$ab,$aa,$aa,$ab,$ae
        dc.b    $b1,$b6,$bb,$c1,$c7,$1f,$22,$25,$2e,$33,$37,$7f,$7e,$7c,$78,$70
        dc.b    $64,$58,$4a,$3b,$2c,$1c,$0c,$00,$f1,$e5,$d9,$ce,$c5,$bd,$b8,$b2
        dc.b    $ae,$ac,$aa,$aa,$ab,$ae,$b1,$b6,$bb,$bf,$c7,$1f,$22,$24,$2d,$32
        dc.b    $34,$7f,$7f,$7a,$77,$70,$65,$58,$4c,$40,$2e,$1d,$0e,$00,$f3,$e6
        dc.b    $db,$d0,$c6,$bf,$b8,$b3,$af,$ac,$ab,$ab,$ac,$ae,$b1,$b5,$ba,$bf
        dc.b    $c7,$1f,$20,$23,$2b,$30,$33,$5f,$7f,$78,$75,$70,$65,$59,$4c,$40
        dc.b    $30,$20,$10,$02,$f5,$e8,$dc,$d1,$c8,$c0,$ba,$b4,$b0,$ad,$ac,$ab
        dc.b    $ac,$ae,$b0,$b5,$ba,$bf,$c6,$1f,$20,$23,$2b,$2f,$32,$3f,$7f,$78
        dc.b    $75,$70,$66,$5a,$4e,$40,$31,$21,$12,$04,$f8,$ea,$e0,$d3,$c9,$c1
        dc.b    $ba,$b5,$b1,$ae,$ac,$ac,$ac,$ae,$b1,$b5,$b9,$bf,$c6,$1f,$20,$22
        dc.b    $2a,$2f,$31,$33,$7f,$78,$74,$70,$66,$5c,$50,$41,$32,$23,$14,$06
        dc.b    $f8,$ec,$e0,$d4,$cb,$c3,$bc,$b6,$b2,$af,$ad,$ac,$ad,$ae,$b1,$b5
        dc.b    $b9,$bf,$c6,$1f,$20,$21,$29,$2e,$30,$30,$7f,$78,$72,$70,$66,$5c
        dc.b    $50,$42,$34,$26,$18,$08,$fa,$ee,$e2,$d7,$cd,$c4,$bd,$b8,$b3,$b0
        dc.b    $ad,$ad,$ad,$ae,$b1,$b5,$b9,$bf,$c5,$2f,$1b,$1f,$27,$2d,$2f,$2f
        dc.b    $5f,$7e,$70,$6d,$66,$5c,$50,$43,$35,$26,$18,$08,$fc,$f0,$e3,$d8
        dc.b    $ce,$c5,$be,$b8,$b4,$b0,$af,$ae,$ae,$af,$b1,$b5,$ba,$bf,$c7,$37
        dc.b    $1a,$21,$27,$2c,$2e,$2e,$4f,$7f,$6f,$6c,$64,$5b,$50,$42,$34,$26
        dc.b    $18,$08,$fc,$f0,$e4,$d8,$cf,$c6,$be,$b8,$b4,$b1,$af,$ae,$ae,$b0
        dc.b    $b2,$b6,$ba,$bf,$cb,$38,$19,$21,$27,$2b,$2d,$2c,$3f,$7f,$6d,$6a
        dc.b    $63,$5a,$50,$42,$34,$26,$18,$09,$fc,$f0,$e4,$d8,$d0,$c6,$bf,$b9
        dc.b    $b4,$b1,$af,$af,$af,$b0,$b3,$b6,$bb,$bf,$df,$30,$19,$22,$27,$2b
        dc.b    $2c,$2b,$3f,$7f,$6b,$68,$62,$58,$4d,$40,$33,$25,$18,$08,$fc,$f0
        dc.b    $e3,$d8,$cf,$c6,$bf,$b9,$b5,$b2,$b0,$af,$af,$b1,$b3,$b7,$bb,$bf
        dc.b    $ff,$20,$1b,$23,$27,$2a,$2b,$29,$3f,$7f,$69,$66,$60,$56,$4c,$40
        dc.b    $31,$24,$15,$08,$fa,$ee,$e2,$d8,$ce,$c6,$c0,$b9,$b5,$b2,$b0,$af
        dc.b    $b0,$b2,$b4,$b8,$bc,$c2,$1f,$18,$1d,$23,$27,$29,$29,$28,$3f,$7e
        dc.b    $67,$63,$5d,$53,$48,$3c,$30,$20,$12,$05,$f8,$ec,$e0,$d6,$cd,$c5
        dc.b    $be,$b9,$b5,$b2,$b0,$b0,$b1,$b3,$b5,$b9,$be,$c7,$36,$17,$1f,$25
        dc.b    $27,$29,$28,$26,$4f,$78,$65,$61,$5a,$50,$45,$38,$2c,$1d,$10,$02
        dc.b    $f6,$e9,$e0,$d4,$cc,$c4,$be,$b8,$b5,$b2,$b0,$b1,$b1,$b3,$b7,$bb
        dc.b    $bf,$f7,$20,$18,$21,$25,$27,$28,$26,$24,$6f,$70,$62,$5e,$58,$4d
        dc.b    $42,$34,$28,$19,$0c,$00,$f3,$e8,$dc,$d2,$ca,$c3,$bc,$b8,$b5,$b2
        dc.b    $b1,$b1,$b3,$b5,$b8,$bd,$c3,$35,$15,$1b,$22,$25,$27,$26,$24,$22
        dc.b    $7f,$64,$60,$5a,$53,$49,$40,$30,$23,$15,$08,$fc,$f0,$e4,$d9,$d0
        dc.b    $c8,$c2,$bc,$b8,$b4,$b2,$b2,$b2,$b4,$b7,$ba,$bf,$ef,$20,$16,$1e
        dc.b    $23,$25,$25,$24,$21,$23,$7f,$60,$5b,$56,$4e,$44,$38,$2c,$20,$11
        dc.b    $04,$f8,$ec,$e1,$d7,$ce,$c7,$c0,$bb,$b8,$b4,$b3,$b3,$b3,$b5,$b8
        dc.b    $bc,$c5,$34,$14,$1a,$20,$24,$24,$24,$22,$1f,$2f,$7c,$5b,$58,$52
        dc.b    $4a,$40,$34,$26,$19,$0c,$00,$f4,$e8,$dd,$d4,$cc,$c4,$be,$ba,$b7
        dc.b    $b4,$b3,$b3,$b5,$b7,$ba,$bf,$ff,$18,$17,$1d,$21,$23,$23,$21,$1e
        dc.b    $1c,$5f,$64,$58,$54,$4e,$44,$3a,$2e,$21,$13,$06,$fa,$f0,$e4,$da
        dc.b    $d0,$c9,$c2,$bd,$b9,$b6,$b4,$b4,$b5,$b6,$b9,$bd,$cf,$2c,$13,$1a
        dc.b    $1f,$22,$22,$21,$1e,$1c,$1d,$7f,$58,$55,$50,$48,$40,$34,$28,$1a
        dc.b    $0d,$00,$f6,$ea,$e0,$d6,$ce,$c6,$c0,$bc,$b9,$b7,$b6,$b6,$b7,$b9
        dc.b    $bc,$bf,$1f,$14,$17,$1d,$20,$21,$21,$1e,$1c,$18,$37,$70,$54,$51
        dc.b    $4b,$42,$38,$2d,$21,$14,$08,$fc,$f0,$e6,$dc,$d4,$cc,$c5,$c0,$bc
        dc.b    $b9,$b8,$b7,$b8,$b9,$bc,$bf,$df,$24,$13,$1a,$1e,$20,$20,$1e,$1c
        dc.b    $18,$15,$5f,$60,$50,$4c,$46,$3d,$33,$28,$1c,$10,$02,$f8,$ed,$e4
        dc.b    $da,$d1,$cb,$c4,$c0,$bc,$ba,$b9,$b9,$ba,$bc,$be,$c3,$2b,$12,$16
        dc.b    $1c,$1f,$1f,$1e,$1c,$19,$16,$15,$75,$50,$4d,$48,$42,$38,$2e,$23
        dc.b    $18,$0c,$00,$f4,$ea,$e0,$d8,$d0,$ca,$c4,$c0,$bd,$bb,$ba,$ba,$bc
        dc.b    $be,$c1,$df,$24,$12,$19,$1d,$1e,$1e,$1c,$1a,$16,$13,$1b,$70,$4c
        dc.b    $49,$45,$3d,$34,$2a,$20,$14,$08,$fe,$f2,$e8,$e0,$d7,$d0,$ca,$c4
        dc.b    $c0,$be,$bc,$bc,$bc,$be,$bf,$c5,$1f,$12,$14,$1a,$1c,$1d,$1c,$1a
        dc.b    $17,$13,$10,$1f,$64,$48,$46,$40,$39,$30,$26,$1c,$10,$05,$fa,$f0
        dc.b    $e7,$de,$d6,$d0,$ca,$c5,$c1,$bf,$be,$be,$be,$bf,$c3,$cf,$2c,$10
        dc.b    $17,$1b,$1c,$1c,$1b,$18,$15,$11,$0e,$2f,$60,$46,$43,$40,$36,$2e
        dc.b    $24,$19,$0e,$03,$f8,$f0,$e6,$dd,$d6,$cf,$ca,$c5,$c2,$c0,$bf,$bf
        dc.b    $bf,$c2,$c4,$f7,$20,$11,$17,$1b,$1b,$1b,$19,$16,$13,$0f,$0b,$3f
        dc.b    $54,$43,$40,$3c,$34,$2b,$21,$16,$0c,$02,$f8,$ee,$e5,$dc,$d6,$d0
        dc.b    $ca,$c6,$c3,$c1,$c0,$c0,$c1,$c3,$c6,$0f,$14,$13,$18,$1a,$1b,$1a
        dc.b    $18,$14,$11,$0e,$0a,$37,$52,$41,$40,$39,$32,$2a,$20,$16,$0c,$00
        dc.b    $f8,$ee,$e5,$dd,$d6,$d0,$cb,$c7,$c4,$c3,$c2,$c2,$c3,$c5,$cb,$27
        dc.b    $10,$13,$18,$1a,$1a,$18,$16,$13,$0f,$0c,$07,$37,$50,$40,$3c,$38
        dc.b    $30,$28,$1e,$14,$0b,$00,$f7,$ee,$e6,$de,$d7,$d1,$cc,$c8,$c6,$c4
        dc.b    $c3,$c3,$c5,$c7,$d3,$28,$10,$14,$18,$1a,$19,$18,$15,$12,$0e,$0a
        dc.b    $06,$2b,$50,$3c,$3a,$36,$30,$27,$1e,$14,$0a,$01,$f8,$ee,$e6,$e0
        dc.b    $d8,$d2,$ce,$ca,$c7,$c6,$c5,$c5,$c6,$c8,$df,$24,$10,$15,$18,$19
        dc.b    $18,$16,$13,$10,$0c,$09,$05,$1f,$54,$3a,$38,$34,$2e,$26,$1e,$14
        dc.b    $0b,$02,$f8,$f0,$e8,$e0,$d9,$d4,$cf,$cc,$c8,$c7,$c6,$c6,$c7,$c9
        dc.b    $e7,$22,$10,$15,$17,$19,$18,$15,$12,$0f,$0c,$08,$04,$07,$56,$39
        dc.b    $37,$34,$2e,$28,$1e,$15,$0c,$03,$fa,$f2,$e9,$e2,$dc,$d6,$d1,$ce
        dc.b    $ca,$c9,$c7,$c7,$c9,$ca,$e7,$20,$0f,$14,$17,$18,$17,$14,$12,$0e
        dc.b    $0b,$07,$03,$02,$4f,$3a,$35,$32,$2e,$28,$20,$16,$0e,$05,$fc,$f4
        dc.b    $ec,$e4,$de,$d8,$d3,$cf,$cc,$cb,$c9,$c9,$ca,$cb,$df,$24,$0f,$14
        dc.b    $17,$17,$16,$14,$11,$0e,$0a,$06,$02,$ff,$37,$40,$33,$31,$2e,$28
        dc.b    $20,$18,$0f,$06,$fe,$f6,$ee,$e6,$e0,$da,$d5,$d1,$ce,$cc,$cb,$cb
        dc.b    $cb,$cc,$df,$20,$0f,$14,$17,$17,$16,$13,$10,$0d,$09,$05,$02,$fe
        dc.b    $17,$48,$31,$30,$2d,$28,$20,$19,$10,$08,$00,$f8,$f0,$e8,$e1,$dc
        dc.b    $d7,$d3,$d0,$ce,$cc,$cc,$cc,$cd,$df,$24,$0f,$13,$16,$17,$15,$13
        dc.b    $10,$0c,$09,$04,$01,$fe,$ff,$4b,$32,$2f,$2c,$28,$22,$1a,$12,$0a
        dc.b    $01,$fa,$f2,$eb,$e4,$e0,$d9,$d5,$d2,$cf,$ce,$cd,$ce,$cf,$df,$24
        dc.b    $0f,$13,$16,$16,$15,$12,$0f,$0c,$08,$04,$00,$fd,$fa,$2f,$38,$2d
        dc.b    $2c,$28,$23,$1c,$14,$0c,$04,$fc,$f5,$ee,$e8,$e1,$dc,$d8,$d4,$d1
        dc.b    $cf,$cf,$cf,$cf,$db,$23,$10,$12,$15,$16,$14,$12,$0f,$0c,$08,$04
        dc.b    $00,$fc,$f9,$0f,$42,$2c,$2b,$28,$23,$1d,$16,$0f,$07,$00,$f8,$f0
        dc.b    $ea,$e4,$e0,$da,$d6,$d4,$d1,$d1,$d0,$d0,$d5,$17,$12,$11,$14,$15
        dc.b    $14,$13,$0f,$0c,$08,$04,$00,$fd,$fa,$f9,$3b,$30,$2a,$28,$24,$20
        dc.b    $18,$11,$0a,$02,$fa,$f4,$ed,$e7,$e2,$dd,$d8,$d5,$d3,$d2,$d1,$d1
        dc.b    $d3,$ff,$18,$11,$14,$15,$14,$13,$10,$0c,$09,$05,$01,$fd,$fa,$f8
        dc.b    $0f,$40,$29,$28,$25,$21,$1b,$14,$0d,$06,$fe,$f8,$f0,$ea,$e5,$e0
        dc.b    $db,$d8,$d5,$d3,$d3,$d2,$d3,$ef,$20,$0f,$13,$14,$14,$13,$10,$0d
        dc.b    $09,$05,$01,$fe,$fa,$f8,$f7,$37,$2c,$27,$26,$22,$1d,$17,$10,$09
        dc.b    $02,$fb,$f4,$ee,$e8,$e3,$e0,$db,$d8,$d6,$d4,$d4,$d4,$db,$1f,$10
        dc.b    $12,$14,$14,$13,$11,$0e,$0a,$06,$02,$fe,$fb,$f8,$f5,$0b,$3a,$26
        dc.b    $25,$23,$1f,$19,$13,$0c,$06,$00,$f8,$f2,$ec,$e6,$e2,$de,$da,$d8
        dc.b    $d6,$d5,$d5,$d6,$ff,$1a,$11,$13,$14,$14,$12,$0f,$0b,$07,$03,$00
        dc.b    $fc,$f8,$f5,$f3,$1f,$30,$24,$23,$20,$1c,$16,$10,$0a,$03,$fc,$f6
        dc.b    $f0,$ea,$e5,$e1,$dd,$da,$d8,$d7,$d6,$d7,$e7,$22,$10,$13,$14,$14
        dc.b    $12,$0f,$0c,$08,$04,$00,$fc,$f9,$f6,$f3,$f9,$35,$25,$22,$21,$1e
        dc.b    $19,$14,$0e,$07,$00,$fa,$f4,$ee,$e9,$e5,$e1,$dd,$db,$d9,$d8,$d8
        dc.b    $d9,$0f,$18,$11,$14,$14,$13,$10,$0d,$0a,$06,$02,$fe,$fa,$f8,$f4
        dc.b    $f2,$ff,$34,$22,$21,$20,$1c,$18,$12,$0c,$05,$00,$f9,$f3,$ee,$e9
        dc.b    $e4,$e1,$de,$dc,$da,$d9,$d9,$eb,$21,$10,$13,$14,$13,$11,$0f,$0c
        dc.b    $07,$03,$ff,$fc,$f8,$f4,$f1,$f0,$0f,$30,$20,$20,$1d,$1a,$16,$10
        dc.b    $0a,$04,$fe,$f8,$f2,$ed,$e8,$e4,$e1,$de,$dc,$db,$da,$db,$0f,$18
        dc.b    $11,$13,$14,$13,$10,$0d,$09,$05,$01,$fd,$fa,$f6,$f3,$f0,$ef,$17
        dc.b    $2a,$1e,$1e,$1c,$18,$14,$0e,$09,$03,$fc,$f8,$f2,$ed,$e8,$e5,$e2
        dc.b    $e0,$dd,$dc,$db,$e3,$1d,$12,$13,$14,$13,$12,$0f,$0b,$07,$03,$00
        dc.b    $fc,$f8,$f4,$f1,$ef,$ef,$1f,$24,$1d,$1c,$1a,$17,$12,$0d,$08,$01
        dc.b    $fc,$f6,$f1,$ed,$e8,$e5,$e2,$e0,$de,$dd,$dd,$ff,$20,$11,$13,$14
        dc.b    $13,$10,$0d,$09,$05,$01,$fd,$f9,$f6,$f3,$f0,$ee,$f3,$27,$20,$1c
        dc.b    $1b,$19,$16,$11,$0c,$06,$00,$fb,$f6,$f1,$ed,$e9,$e5,$e3,$e1,$df
        dc.b    $de,$e3,$17,$14,$13,$14,$13,$11,$0f,$0b,$07,$03,$ff,$fb,$f8,$f4
        dc.b    $f1,$ee,$ec,$fb,$2b,$1c,$1b,$1a,$18,$14,$0f,$0b,$05,$00,$fa,$f5
        dc.b    $f0,$ec,$e9,$e6,$e3,$e1,$e0,$e0,$ff,$20,$12,$13,$14,$12,$10,$0c
        dc.b    $08,$04,$00,$fc,$f8,$f4,$f1,$ee,$ec,$eb,$0f,$26,$19,$19,$18,$16
        dc.b    $12,$0d,$08,$03,$fe,$f9,$f5,$f0,$ec,$e9,$e6,$e4,$e2,$e1,$eb,$1f
        dc.b    $14,$13,$14,$13,$11,$0e,$0a,$06,$02,$fd,$f9,$f6,$f2,$f0,$ed,$eb
        dc.b    $ed,$1b,$20,$18,$18,$17,$14,$10,$0c,$06,$02,$fc,$f8,$f3,$f0,$ec
        dc.b    $e8,$e6,$e4,$e3,$e3,$0b,$1c,$12,$14,$14,$12,$0f,$0c,$07,$03,$ff
        dc.b    $fa,$f7,$f3,$f0,$ed,$eb,$e9,$f7,$27,$18,$18,$17,$15,$12,$0e,$09
        dc.b    $04,$00,$fb,$f6,$f2,$ee,$eb,$e8,$e6,$e4,$e3,$f7,$21,$13,$13,$14
        dc.b    $12,$10,$0d,$09,$04,$00,$fc,$f8,$f4,$f1,$ee,$ec,$ea,$e9,$0f,$20
        dc.b    $16,$17,$16,$13,$10,$0c,$07,$02,$fe,$f9,$f5,$f1,$ed,$eb,$e8,$e6
        dc.b    $e4,$eb,$1b,$16,$13,$14,$13,$11,$0e,$0a,$06,$01,$fd,$f8,$f5,$f1
        dc.b    $ef,$ec,$ea,$e8,$f7,$23,$16,$16,$16,$14,$11,$0e,$09,$05,$00,$fc
        dc.b    $f8,$f3,$f0,$ed,$ea,$e8,$e6,$e7,$0f,$1c,$14,$14,$14,$12,$0e,$0b
        dc.b    $06,$02,$fe,$f9,$f6,$f2,$ee,$ec,$ea,$e8,$e7,$0f,$1c,$14,$15,$14
        dc.b    $12,$0f,$0b,$07,$02,$fe,$fa,$f5,$f2,$ef,$ec,$ea,$e8,$e7,$ff,$20
        dc.b    $14,$15,$14,$12,$0f,$0c,$07,$03,$ff,$fa,$f6,$f2,$f0,$ec,$ea,$e8
        dc.b    $e7,$f7,$1f,$14,$14,$14,$13,$10,$0c,$09,$04,$00,$fc,$f8,$f4,$f0
        dc.b    $ee,$eb,$e9,$e8,$ff,$22,$14,$15,$14,$12,$10,$0c,$08,$03,$ff,$fa
        dc.b    $f6,$f2,$f0,$ec,$ea,$e8,$e7,$eb,$17,$18,$13,$14,$13,$10,$0e,$0a
        dc.b    $06,$02,$fe,$fa,$f6,$f3,$f0,$ed,$eb,$e9,$f7,$1f,$16,$15,$14,$13
        dc.b    $10,$0c,$08,$04,$00,$fa,$f7,$f3,$f0,$ec,$ea,$e8,$e6,$e6,$ff,$1d
        dc.b    $12,$13,$13,$11,$0f,$0b,$08,$03,$00,$fc,$f8,$f4,$f1,$ef,$ed,$eb
        dc.b    $fb,$22,$16,$15,$15,$13,$10,$0c,$08,$03,$00,$fb,$f6,$f2,$f0,$ec
        dc.b    $e9,$e8,$e6,$e5,$f7,$1d,$12,$12,$13,$11,$0f,$0c,$08,$04,$00,$fc
        dc.b    $f9,$f6,$f3,$f0,$ee,$ec,$fb,$22,$17,$16,$15,$13,$10,$0c,$08,$04
        dc.b    $00,$fa,$f6,$f2,$ef,$ec,$e9,$e7,$e6,$e4,$eb,$17,$12,$11,$12,$11
        dc.b    $0f,$0c,$09,$05,$01,$fe,$fa,$f7,$f4,$f1,$ef,$ed,$fb,$22,$18,$16
        dc.b    $16,$14,$11,$0d,$08,$04,$ff,$fb,$f6,$f2,$ef,$ec,$e9,$e7,$e5,$e4
        dc.b    $e7,$0f,$18,$10,$11,$11,$0f,$0d,$0a,$07,$02,$ff,$fc,$f8,$f6,$f3
        dc.b    $f0,$ef,$ff,$22,$18,$16,$16,$14,$10,$0c,$08,$04,$ff,$fa,$f6,$f2
        dc.b    $ef,$eb,$e8,$e6,$e5,$e4,$e3,$ff,$18,$0f,$10,$11,$0f,$0e,$0a,$07
        dc.b    $04,$00,$fd,$fa,$f7,$f4,$f2,$f0,$ff,$23,$18,$17,$16,$14,$10,$0c
        dc.b    $08,$03,$fe,$fa,$f5,$f1,$ee,$eb,$e8,$e6,$e4,$e3,$e3,$fb,$19,$0f
        dc.b    $10,$10,$0f,$0e,$0b,$08,$04,$01,$fe,$fb,$f8,$f5,$f3,$f1,$07,$24
        dc.b    $18,$17,$16,$13,$10,$0c,$08,$03,$fe,$f9,$f5,$f1,$ee,$ea,$e8,$e6
        dc.b    $e4,$e3,$e3,$f3,$17,$0f,$0f,$10,$0f,$0e,$0b,$08,$05,$02,$ff,$fc
        dc.b    $f9,$f6,$f4,$f3,$0f,$23,$18,$18,$16,$13,$10,$0c,$07,$02,$fd,$f8
        dc.b    $f4,$f0,$ed,$ea,$e7,$e5,$e3,$e3,$e2,$ef,$17,$0e,$0f,$0f,$0f,$0e
        dc.b    $0c,$08,$05,$02,$ff,$fc,$f9,$f6,$f4,$f5,$17,$20,$18,$18,$16,$13
        dc.b    $0f,$0b,$06,$01,$fc,$f8,$f3,$f0,$ec,$e9,$e7,$e5,$e3,$e3,$e2,$ef
        dc.b    $15,$0e,$0f,$0f,$0f,$0e,$0c,$09,$06,$02,$00,$fc,$fa,$f8,$f6,$fb
        dc.b    $1f,$1c,$18,$18,$15,$13,$0e,$09,$04,$00,$fc,$f7,$f2,$ee,$eb,$e8
        dc.b    $e6,$e4,$e3,$e2,$e2,$f3,$15,$0d,$0e,$0f,$0f,$0d,$0b,$08,$06,$02
        dc.b    $00,$fd,$fa,$f8,$f6,$07,$25,$1a,$19,$18,$15,$11,$0d,$08,$03,$fe
        dc.b    $fa,$f5,$f1,$ed,$ea,$e7,$e5,$e3,$e2,$e2,$e1,$f7,$14,$0c,$0e,$0f
        dc.b    $0e,$0d,$0b,$08,$06,$03,$00,$fd,$fb,$f8,$f8,$15,$23,$1a,$19,$18
        dc.b    $14,$10,$0c,$07,$02,$fd,$f8,$f4,$f0,$ec,$e9,$e6,$e4,$e3,$e2,$e1
        dc.b    $e2,$fb,$14,$0c,$0e,$0f,$0e,$0d,$0b,$08,$06,$03,$00,$fe,$fb,$f9
        dc.b    $ff,$23,$20,$1a,$19,$17,$13,$0f,$0a,$05,$00,$fb,$f6,$f2,$ee,$eb
        dc.b    $e8,$e5,$e3,$e2,$e1,$e1,$e3,$ff,$12,$0c,$0e,$0f,$0e,$0d,$0b,$08
        dc.b    $06,$03,$00,$fe,$fc,$fa,$0f,$26,$1b,$1a,$18,$15,$11,$0c,$08,$02
        dc.b    $fe,$f9,$f4,$f0,$ec,$e9,$e6,$e4,$e2,$e1,$e1,$e1,$e7,$07,$10,$0c
        dc.b    $0e,$0f,$0e,$0c,$0b,$08,$05,$03,$00,$fe,$fc,$ff,$23,$20,$1b,$1a
        dc.b    $18,$14,$10,$0a,$06,$00,$fc,$f7,$f2,$ee,$eb,$e8,$e5,$e3,$e2,$e1
        dc.b    $e1,$e1,$ed,$0f,$0c,$0c,$0e,$0e,$0d,$0c,$0a,$07,$04,$02,$00,$fe
        dc.b    $fc,$13,$27,$1c,$1b,$19,$16,$12,$0d,$08,$03,$fe,$f9,$f4,$f0,$ec
        dc.b    $e9,$e6,$e4,$e2,$e1,$e0,$e0,$e1,$f7,$11,$0b,$0c,$0e,$0e,$0d,$0b
        dc.b    $09,$07,$04,$02,$00,$fe,$07,$25,$20,$1c,$1b,$18,$14,$10,$0a,$05
        dc.b    $00,$fc,$f6,$f2,$ee,$ea,$e8,$e5,$e3,$e1,$e0,$e0,$e0,$e7,$07,$0e
        dc.b    $0b,$0d,$0e,$0e,$0c,$0b,$09,$07,$04,$01,$00,$ff,$1f,$25,$1d,$1c
        dc.b    $19,$16,$11,$0d,$08,$02,$fe,$f8,$f4,$f0,$ec,$e8,$e6,$e3,$e2,$e1
        dc.b    $e0,$e0,$e1,$ef,$0f,$0c,$0c,$0e,$0e,$0e,$0c,$0a,$08,$06,$04,$01
        dc.b    $00,$13,$28,$20,$1d,$1c,$18,$14,$0f,$0a,$05,$00,$fb,$f5,$f1,$ed
        dc.b    $e9,$e7,$e4,$e2,$e0,$e0,$e0,$e0,$e1,$f7,$0f,$0a,$0c,$0e,$0e,$0d
        dc.b    $0c,$0a,$08,$06,$04,$01,$07,$23,$24,$1f,$1d,$1a,$16,$12,$0d,$07
        dc.b    $02,$fd,$f8,$f3,$f0,$ec,$e8,$e5,$e3,$e1,$e0,$e0,$e0,$e0,$e5,$ff
        dc.b    $0f,$0a,$0d,$0e,$0e,$0d,$0c,$0a,$07,$06,$03,$02,$15,$29,$20,$1e
        dc.b    $1c,$18,$15,$10,$0a,$05,$00,$fb,$f6,$f1,$ee,$ea,$e7,$e4,$e2,$e1
        dc.b    $e0,$e0,$e0,$e1,$e7,$07,$0c,$0b,$0d,$0e,$0e,$0d,$0b,$0a,$08,$06
        dc.b    $03,$07,$23,$26,$20,$1e,$1b,$18,$12,$0e,$08,$03,$fe,$f8,$f4,$f0
        dc.b    $ec,$e8,$e5,$e3,$e1,$e0,$e0,$e0,$e0,$e1,$ef,$0b,$0c,$0b,$0d,$0e
        dc.b    $0e,$0d,$0c,$0a,$08,$06,$04,$13,$29,$23,$20,$1d,$1a,$16,$11,$0c
        dc.b    $07,$01,$fc,$f8,$f2,$ef,$eb,$e8,$e5,$e3,$e1,$e0,$e0,$e0,$e0,$e1
        dc.b    $f3,$0d,$0a,$0b,$0d,$0e,$0e,$0d,$0c,$0a,$08,$06,$06,$1e,$2a,$22
        dc.b    $20,$1d,$19,$15,$10,$0b,$05,$00,$fb,$f6,$f1,$ee,$ea,$e7,$e4,$e2
        dc.b    $e1,$e0,$e0,$e0,$e0,$e2,$f5,$0d,$0a,$0b,$0d,$0e,$0e,$0d,$0b,$09
        dc.b    $07,$06,$0b,$25,$28,$21,$1f,$1c,$18,$14,$0f,$09,$04,$ff,$fa,$f6
        dc.b    $f1,$ec,$e9,$e6,$e4,$e2,$e0,$e0,$e0,$e0,$e0,$e2,$f7,$0e,$0a,$0c
        dc.b    $0e,$0f,$0e,$0d,$0c,$0a,$08,$07,$0f,$29,$26,$21,$20,$1c,$18,$13
        dc.b    $0e,$08,$03,$fe,$f9,$f4,$f0,$ec,$e8,$e6,$e3,$e2,$e0,$e0,$e0,$e0
        dc.b    $e1,$e2,$f7,$0d,$0a,$0c,$0e,$0e,$0e,$0e,$0c,$0b,$09,$07,$17,$2b
        dc.b    $24,$21,$1f,$1c,$17,$12,$0d,$07,$02,$fd,$f8,$f4,$f0,$ec,$e8,$e5
        dc.b    $e3,$e1,$e0,$e0,$e0,$e0,$e1,$e2,$f3,$0b,$0a,$0c,$0e,$0e,$0f,$0e
        dc.b    $0d,$0c,$0a,$09,$1d,$2c,$24,$22,$20,$1b,$17,$12,$0d,$07,$02,$fc
        dc.b    $f8,$f3,$f0,$ec,$e8,$e5,$e3,$e1,$e0,$e0,$e0,$e0,$e1,$e2,$ef,$0b
        dc.b    $0b,$0b,$0e,$0f,$0f,$0e,$0d,$0c,$0a,$0b,$1f,$2c,$24,$22,$20,$1c
        dc.b    $17,$12,$0c,$07,$01,$fc,$f8,$f3,$f0,$eb,$e8,$e5,$e3,$e1,$e0,$e0
        dc.b    $e0,$e0,$e1,$e2,$ee,$07,$0c,$0b,$0d,$0f,$0f,$0f,$0e,$0c,$0b,$0b
        dc.b    $1f,$2c,$24,$22,$20,$1c,$17,$12,$0c,$07,$02,$fc,$f8,$f3,$f0,$eb
        dc.b    $e8,$e5,$e3,$e1,$e0,$e0,$e0,$e0,$e1,$e2,$e7,$ff,$0e,$0b,$0d,$0f
        dc.b    $0f,$0f,$0f,$0d,$0c,$0d,$1f,$2c,$25,$23,$20,$1c,$18,$12,$0d,$08
        dc.b    $02,$fd,$f8,$f4,$f0,$ec,$e8,$e5,$e3,$e1,$e0,$e0,$e0,$e0,$e0,$e2
        dc.b    $e5,$fb,$0d,$0b,$0c,$0e,$0f,$0f,$0f,$0e,$0c,$0e,$23,$2d,$26,$24
        dc.b    $21,$1c,$18,$13,$0e,$08,$03,$fd,$f8,$f4,$f0,$ec,$e8,$e6,$e3,$e1
        dc.b    $e0,$e0,$e0,$e0,$e0,$e2,$e3,$f5,$0a,$0b,$0c,$0e,$0f,$0f,$0f,$0e
        dc.b    $0d,$0f,$23,$2d,$26,$24,$22,$1e,$18,$14,$0e,$09,$03,$fe,$f9,$f4
        dc.b    $f0,$ec,$e9,$e6,$e4,$e2,$e0,$e0,$e0,$e0,$e0,$e2,$e3,$ef,$07,$0c
        dc.b    $0b,$0e,$0f,$10,$0f,$0f,$0e,$0e,$23,$2e,$27,$25,$22,$1e,$19,$14
        dc.b    $0f,$0a,$04,$00,$fa,$f5,$f1,$ed,$e9,$e7,$e4,$e2,$e1,$e0,$e0,$e0
        dc.b    $e1,$e2,$e3,$e7,$ff,$0d,$0b,$0d,$0f,$10,$10,$0f,$0f,$0f,$1f,$2e
        dc.b    $28,$25,$23,$20,$1a,$15,$10,$0a,$05,$00,$fb,$f6,$f1,$ed,$ea,$e7
        dc.b    $e4,$e2,$e1,$e0,$e0,$e0,$e0,$e1,$e3,$e5,$f5,$0a,$0c,$0d,$0f,$10
        dc.b    $11,$10,$0f,$0f,$1d,$2d,$29,$26,$24,$20,$1c,$17,$11,$0c,$06,$01
        dc.b    $fc,$f8,$f3,$ee,$eb,$e8,$e5,$e3,$e1,$e0,$e0,$e0,$e0,$e1,$e3,$e4
        dc.b    $eb,$ff,$0d,$0b,$0e,$0f,$10,$10,$10,$0f,$17,$2b,$2c,$27,$25,$22
        dc.b    $1d,$18,$13,$0e,$08,$03,$fe,$f8,$f4,$f0,$ec,$e9,$e6,$e3,$e2,$e1
        dc.b    $e0,$e0,$e0,$e1,$e2,$e3,$e7,$f7,$0b,$0b,$0d,$0f,$10,$10,$10,$0f
        dc.b    $13,$27,$2e,$28,$25,$23,$1e,$1a,$14,$0f,$0a,$04,$00,$fa,$f6,$f1
        dc.b    $ed,$ea,$e7,$e5,$e3,$e1,$e1,$e0,$e0,$e1,$e2,$e3,$e5,$ed,$ff,$0e
        dc.b    $0c,$0e,$10,$11,$11,$10,$11,$1f,$2f,$29,$27,$24,$20,$1c,$17,$12
        dc.b    $0c,$06,$01,$fc,$f8,$f3,$ef,$ec,$e8,$e6,$e4,$e2,$e1,$e0,$e0,$e1
        dc.b    $e1,$e3,$e4,$e7,$f7,$0b,$0c,$0d,$0f,$11,$11,$11,$10,$1b,$2c,$2c
        dc.b    $28,$25,$22,$1e,$19,$14,$0e,$08,$03,$fe,$f9,$f4,$f0,$ed,$e9,$e7
        dc.b    $e4,$e2,$e1,$e0,$e0,$e0,$e1,$e2,$e3,$e5,$eb,$ff,$0d,$0c,$0e,$10
        dc.b    $11,$12,$11,$16,$27,$2f,$29,$27,$24,$20,$1c,$16,$11,$0c,$06,$00
        dc.b    $fc,$f8,$f3,$ef,$eb,$e8,$e6,$e4,$e2,$e1,$e0,$e0,$e1,$e2,$e3,$e5
        dc.b    $e7,$f3,$07,$0d,$0c,$0f,$11,$11,$12,$12,$1f,$2e,$2b,$28,$26,$23
        dc.b    $1e,$19,$14,$0e,$09,$03,$fe,$fa,$f5,$f1,$ed,$ea,$e7,$e5,$e3,$e1
        dc.b    $e1,$e0,$e0,$e1,$e2,$e4,$e5,$e8,$f9,$0a,$0d,$0d,$0f,$11,$12,$12
        dc.b    $17,$29,$2f,$2a,$27,$24,$21,$1c,$17,$11,$0c,$06,$01,$fc,$f8,$f4
        dc.b    $f0,$ec,$e9,$e6,$e4,$e3,$e1,$e1,$e1,$e1,$e2,$e3,$e5,$e7,$eb,$fe
        dc.b    $0c,$0c,$0e,$10,$12,$12,$13,$1f,$2e,$2c,$29,$27,$23,$1f,$1a,$15
        dc.b    $0f,$0a,$04,$00,$fa,$f6,$f2,$ee,$eb,$e8,$e5,$e4,$e2,$e1,$e1,$e1
        dc.b    $e2,$e2,$e4,$e5,$e7,$ee,$ff,$0e,$0d,$0f,$11,$12,$13,$17,$27,$30
        dc.b    $2b,$29,$26,$22,$1e,$18,$13,$0e,$08,$03,$fe,$f9,$f4,$f1,$ed,$ea
        dc.b    $e7,$e5,$e3,$e2,$e1,$e1,$e1,$e1,$e3,$e4,$e6,$e7,$ef,$03,$0e,$0d
        dc.b    $0f,$11,$12,$13,$1d,$2d,$2e,$2a,$28,$25,$21,$1c,$17,$12,$0c,$07
        dc.b    $01,$fc,$f8,$f4,$f0,$ec,$e9,$e7,$e4,$e3,$e2,$e1,$e1,$e1,$e2,$e3
        dc.b    $e5,$e7,$e9,$f3,$06,$0e,$0d,$0f,$12,$13,$15,$26,$30,$2c,$29,$27
        dc.b    $24,$20,$1a,$15,$10,$0a,$05,$00,$fb,$f6,$f2,$ee,$eb,$e8,$e6,$e4
        dc.b    $e3,$e2,$e1,$e1,$e2,$e3,$e4,$e5,$e7,$ea,$f9,$09,$0e,$0e,$11,$12
        dc.b    $13,$1d,$2c,$30,$2a,$29,$26,$22,$1d,$18,$13,$0d,$08,$02,$fe,$f8
        dc.b    $f4,$f0,$ed,$ea,$e7,$e5,$e3,$e2,$e2,$e1,$e1,$e2,$e3,$e5,$e7,$e8
        dc.b    $ed,$ff,$0d,$0d,$0f,$11,$13,$17,$27,$30,$2c,$2a,$28,$24,$20,$1b
        dc.b    $16,$10,$0b,$06,$00,$fc,$f8,$f3,$f0,$ec,$e9,$e6,$e5,$e3,$e2,$e2
        dc.b    $e1,$e2,$e3,$e4,$e6,$e7,$ea,$f2,$03,$0e,$0d,$0f,$12,$13,$1f,$2d
        dc.b    $2f,$2b,$2a,$26,$22,$1d,$18,$13,$0e,$08,$03,$fe,$fa,$f5,$f1,$ee
        dc.b    $eb,$e8,$e5,$e4,$e2,$e2,$e1,$e2,$e2,$e3,$e5,$e6,$e8,$eb,$f7,$09
        dc.b    $0e,$0e,$10,$12,$19,$29,$30,$2c,$2a,$28,$24,$20,$1a,$16,$10,$0b
        dc.b    $06,$00,$fc,$f8,$f3,$f0,$ec,$e9,$e7,$e5,$e3,$e3,$e2,$e2,$e2,$e3
        dc.b    $e4,$e6,$e7,$ea,$ef,$ff,$0d,$0e,$0f,$12,$15,$23,$2f,$2d,$2b,$29
        dc.b    $26,$22,$1d,$18,$12,$0d,$08,$02,$fe,$f9,$f5,$f1,$ee,$ea,$e8,$e6
        dc.b    $e4,$e3,$e2,$e2,$e2,$e3,$e4,$e5,$e7,$e9,$eb,$f7,$07,$0e,$0e,$11
        dc.b    $13,$1f,$2d,$2e,$2b,$2a,$27,$23,$1e,$19,$14,$0f,$0a,$04,$00,$fa
        dc.b    $f6,$f2,$ef,$ec,$e9,$e7,$e5,$e3,$e3,$e2,$e2,$e3,$e4,$e5,$e7,$e8
        dc.b    $eb,$ef,$ff,$0d,$0e,$0f,$12,$1a,$29,$30,$2c,$2a,$28,$25,$20,$1c
        dc.b    $16,$10,$0c,$06,$01,$fc,$f8,$f4,$f0,$ed,$ea,$e8,$e6,$e4,$e3,$e3
        dc.b    $e3,$e3,$e4,$e5,$e6,$e8,$ea,$ed,$fa,$09,$0f,$0f,$11,$17,$27,$2f
        dc.b    $2c,$2b,$29,$26,$21,$1c,$18,$12,$0d,$08,$02,$fe,$f9,$f5,$f1,$ee
        dc.b    $eb,$e8,$e6,$e5,$e3,$e3,$e3,$e3,$e3,$e5,$e6,$e7,$e9,$eb,$f3,$03
        dc.b    $0e,$0e,$10,$15,$24,$2e,$2c,$2a,$29,$26,$22,$1d,$18,$13,$0e,$08
        dc.b    $03,$ff,$fa,$f6,$f2,$ef,$ec,$e9,$e8,$e6,$e4,$e3,$e3,$e3,$e3,$e5
        dc.b    $e6,$e7,$e9,$eb,$ef,$fe,$0c,$0f,$0f,$15,$23,$2e,$2d,$2b,$2a,$27
        dc.b    $23,$1e,$19,$14,$0f,$0a,$04,$00,$fc,$f7,$f3,$f0,$ec,$ea,$e7,$e6
        dc.b    $e4,$e3,$e3,$e3,$e4,$e4,$e6,$e7,$e9,$eb,$ee,$fa,$09,$0f,$0f,$14
        dc.b    $23,$2e,$2d,$2b,$29,$27,$23,$1f,$1a,$15,$0f,$0a,$05,$00,$fc,$f8
        dc.b    $f3,$f0,$ed,$ea,$e8,$e6,$e5,$e4,$e3,$e3,$e4,$e4,$e5,$e7,$e9,$eb
        dc.b    $ed,$f6,$06,$0f,$0f,$13,$23,$2d,$2c,$2b,$2a,$27,$24,$20,$1a,$15
        dc.b    $10,$0b,$05,$00,$fc,$f8,$f4,$f0,$ed,$ea,$e8,$e7,$e5,$e4,$e3,$e3
        dc.b    $e4,$e5,$e6,$e7,$e9,$eb,$ee,$f3,$03,$0e,$0f,$13,$23,$2d,$2d,$2c
        dc.b    $2a,$27,$24,$20,$1b,$16,$10,$0b,$06,$01,$fd,$f8,$f4,$f1,$ee,$eb
        dc.b    $e9,$e7,$e6,$e5,$e4,$e4,$e4,$e5,$e6,$e7,$e9,$eb,$ed,$f1,$ff,$0c
        dc.b    $0f,$13,$22,$2c,$2c,$2b,$2a,$27,$24,$20,$1a,$16,$10,$0b,$06,$01
        dc.b    $fd,$f8,$f5,$f1,$ee,$eb,$e9,$e7,$e6,$e5,$e4,$e4,$e4,$e5,$e6,$e7
        dc.b    $e9,$eb,$ee,$f1,$fd,$0b,$0f,$14,$23,$2d,$2c,$2b,$2a,$27,$24,$20
        dc.b    $1b,$16,$11,$0c,$06,$02,$fd,$f9,$f5,$f1,$ee,$ec,$e9,$e7,$e6,$e5
        dc.b    $e4,$e4,$e4,$e5,$e6,$e7,$e9,$eb,$ee,$f0,$fb,$09,$0f,$14,$23,$2d
        dc.b    $2b,$2b,$29,$27,$23,$20,$1a,$16,$10,$0c,$06,$01,$fd,$f9,$f5,$f2
        dc.b    $ee,$ec,$e9,$e7,$e6,$e5,$e4,$e4,$e5,$e6,$e7,$e8,$e9,$eb,$ee,$f0
        dc.b    $fb,$07,$0f,$17,$26,$2c,$2b,$2a,$29,$26,$23,$1e,$1a,$15,$10,$0b
        dc.b    $06,$01,$fd,$f9,$f5,$f1,$ef,$ec,$e9,$e8,$e6,$e6,$e5,$e5,$e5,$e6
        dc.b    $e7,$e8,$ea,$ec,$ee,$f1,$fb,$09,$0f,$19,$27,$2c,$2b,$2a,$29,$26
        dc.b    $22,$1e,$19,$14,$0f,$0a,$06,$01,$fc,$f8,$f5,$f1,$ee,$ec,$e9,$e8
        dc.b    $e6,$e5,$e5,$e5,$e5,$e6,$e7,$e9,$ea,$ec,$ef,$f1,$fb,$09,$12,$1d
        dc.b    $29,$2b,$2a,$2a,$28,$25,$21,$1d,$18,$13,$0e,$09,$04,$00,$fc,$f8
        dc.b    $f4,$f0,$ee,$eb,$e9,$e7,$e6,$e5,$e5,$e5,$e5,$e6,$e7,$e9,$eb,$ed
        dc.b    $ef,$f2,$fd,$0b,$15,$1f,$2b,$2a,$2a,$29,$27,$24,$20,$1c,$18,$12
        dc.b    $0d,$08,$03,$00,$fb,$f8,$f3,$f0,$ee,$eb,$e9,$e8,$e6,$e6,$e5,$e6
        dc.b    $e6,$e7,$e8,$e9,$eb,$ed,$f0,$f3,$fe,$0c,$19,$25,$2a,$29,$29,$28
        dc.b    $26,$23,$1f,$1a,$16,$11,$0c,$07,$02,$fe,$fa,$f6,$f3,$f0,$ed,$eb
        dc.b    $e9,$e8,$e6,$e6,$e6,$e6,$e7,$e7,$e9,$ea,$ec,$ee,$f0,$f5,$ff,$0f
        dc.b    $1d,$27,$29,$29,$29,$28,$25,$21,$1d,$18,$14,$0f,$0a,$05,$01,$fd
        dc.b    $f9,$f5,$f2,$ef,$ec,$ea,$e9,$e8,$e7,$e6,$e6,$e6,$e7,$e8,$e9,$eb
        dc.b    $ed,$ef,$f1,$f7,$03,$15,$23,$29,$28,$29,$28,$27,$24,$20,$1b,$17
        dc.b    $12,$0d,$09,$04,$00,$fc,$f8,$f4,$f1,$ee,$ec,$ea,$e8,$e7,$e7,$e6
        dc.b    $e6,$e7,$e7,$e9,$ea,$ec,$ee,$f0,$f3,$fb,$0b,$1d,$26,$28,$28,$29
        dc.b    $27,$25,$22,$1e,$1a,$14,$10,$0b,$06,$02,$fe,$fa,$f6,$f3,$f0,$ed
        dc.b    $eb,$e9,$e8,$e7,$e6,$e6,$e7,$e7,$e8,$e9,$eb,$ed,$ef,$f1,$f4,$ff
        dc.b    $13,$23,$27,$27,$28,$28,$26,$23,$20,$1c,$18,$13,$0e,$09,$05,$00
        dc.b    $fc,$f8,$f5,$f2,$f0,$ed,$eb,$e9,$e8,$e7,$e7,$e7,$e7,$e8,$e9,$eb
        dc.b    $ec,$ee,$f0,$f3,$f7,$07,$1d,$26,$26,$27,$28,$27,$24,$21,$1d,$19
        dc.b    $14,$10,$0c,$06,$02,$fe,$fa,$f7,$f4,$f0,$ee,$ec,$ea,$e9,$e8,$e7
        dc.b    $e7,$e7,$e8,$e9,$ea,$eb,$ed,$f0,$f1,$f4,$fd,$12,$24,$26,$26,$27
        dc.b    $27,$26,$22,$1f,$1b,$17,$12,$0e,$09,$04,$00,$fc,$f8,$f5,$f2,$f0
        dc.b    $ed,$eb,$e9,$e8,$e8,$e7,$e7,$e8,$e8,$e9,$eb,$ed,$ee,$f0,$f3,$f7
        dc.b    $07,$1b,$27,$25,$27,$27,$26,$24,$21,$1d,$19,$15,$10,$0c,$07,$02
        dc.b    $ff,$fb,$f7,$f4,$f1,$ef,$ed,$eb,$e9,$e8,$e8,$e8,$e8,$e8,$e9,$eb
        dc.b    $ec,$ee,$f0,$f1,$f4,$fb,$0f,$22,$26,$25,$27,$26,$25,$22,$1f,$1b
        dc.b    $17,$13,$0e,$09,$05,$01,$fd,$f9,$f6,$f3,$f0,$ee,$ec,$ea,$e9,$e8
        dc.b    $e8,$e8,$e8,$e9,$ea,$eb,$ed,$ee,$f0,$f3,$f5,$ff,$15,$25,$24,$25
        dc.b    $26,$25,$24,$21,$1d,$19,$15,$10,$0c,$08,$03,$00,$fc,$f8,$f5,$f2
        dc.b    $f0,$ee,$ec,$ea,$e9,$e9,$e8,$e8,$e9,$ea,$eb,$ec,$ee,$f0,$f1,$f4
        dc.b    $f7,$07,$1b,$25,$24,$26,$26,$25,$23,$20,$1c,$18,$14,$0f,$0b,$06
        dc.b    $02,$fe,$fb,$f8,$f4,$f1,$ef,$ed,$eb,$ea,$e9,$e9,$e9,$e9,$e9,$ea
        dc.b    $eb,$ed,$ee,$f0,$f2,$f4,$fb,$0d,$1e,$24,$24,$25,$25,$24,$22,$1e
        dc.b    $1a,$16,$12,$0e,$0a,$06,$01,$fe,$fa,$f7,$f4,$f1,$ef,$ec,$eb,$ea
        dc.b    $e9,$e9,$e9,$e9,$e9,$eb,$ec,$ed,$ef,$f1,$f3,$f5,$ff,$0f,$1f,$24
        dc.b    $24,$25,$25,$23,$21,$1d,$1a,$16,$12,$0d,$09,$04,$00,$fd,$f9,$f6
        dc.b    $f3,$f0,$ef,$ed,$ec,$ea,$e9,$e9,$e9,$ea,$ea,$eb,$ec,$ee,$f0,$f1
        dc.b    $f4,$f7,$02,$13,$1f,$24,$24,$25,$24,$22,$20,$1c,$18,$15,$10,$0c
        dc.b    $08,$04,$00,$fc,$f9,$f6,$f3,$f1,$ee,$ed,$eb,$ea,$ea,$e9,$e9,$ea
        dc.b    $eb,$eb,$ed,$ee,$f0,$f2,$f4,$f9,$05,$15,$1f,$23,$23,$24,$23,$22
        dc.b    $1e,$1c,$18,$14,$0f,$0c,$07,$03,$00,$fc,$f8,$f5,$f3,$f0,$ee,$ed
        dc.b    $eb,$ea,$ea,$e9,$ea,$ea,$eb,$ec,$ed,$ef,$f0,$f3,$f4,$fb,$07,$15
        dc.b    $1f,$23,$23,$24,$23,$21,$1e,$1b,$18,$13,$0f,$0b,$07,$03,$00,$fc
        dc.b    $f8,$f6,$f3,$f1,$ef,$ed,$ec,$eb,$ea,$ea,$ea,$eb,$eb,$ec,$ed,$ef
        dc.b    $f0,$f2,$f5,$fc,$07,$13,$1d,$23,$23,$23,$22,$20,$1e,$1b,$17,$13
        dc.b    $0f,$0b,$07,$03,$00,$fc,$f9,$f6,$f3,$f1,$ef,$ed,$ec,$eb,$ea,$ea
        dc.b    $ea,$eb,$eb,$ec,$ee,$ef,$f1,$f3,$f5,$fd,$07,$13,$1b,$22,$22,$22
        dc.b    $22,$20,$1e,$1b,$17,$13,$0f,$0b,$07,$03,$00,$fc,$f9,$f6,$f4,$f1
        dc.b    $f0,$ee,$ec,$ec,$eb,$eb,$eb,$eb,$ec,$ed,$ee,$f0,$f1,$f3,$f5,$fd
        dc.b    $07,$0f,$19,$21,$23,$22,$22,$20,$1e,$1b,$17,$14,$10,$0c,$08,$04
        dc.b    $00,$fd,$fa,$f7,$f4,$f2,$f0,$ee,$ed,$ec,$eb,$eb,$eb,$eb,$ec,$ed
        dc.b    $ee,$ef,$f1,$f3,$f5,$fd,$06,$0e,$17,$1f,$22,$21,$21,$20,$1d,$1b
        dc.b    $17,$14,$10,$0c,$08,$04,$00,$fd,$fa,$f7,$f4,$f2,$f0,$ee,$ed,$ec
        dc.b    $eb,$eb,$eb,$eb,$ec,$ed,$ee,$ef,$f0,$f3,$f5,$fc,$06,$0d,$13,$1d
        dc.b    $22,$21,$21,$20,$1e,$1b,$18,$14,$10,$0c,$08,$05,$01,$fe,$fb,$f8
        dc.b    $f5,$f3,$f1,$ef,$ed,$ed,$ec,$ec,$eb,$ec,$ec,$ed,$ee,$ef,$f1,$f2
        dc.b    $f5,$fc,$05,$0b,$11,$1b,$21,$20,$20,$1f,$1d,$1b,$17,$14,$10,$0d
        dc.b    $09,$05,$01,$fe,$fb,$f8,$f6,$f3,$f1,$f0,$ee,$ed,$ec,$ec,$ec,$ec
        dc.b    $ec,$ed,$ee,$ef,$f1,$f2,$f4,$fb,$03,$0a,$0f,$17,$1f,$21,$20,$1f
        dc.b    $1d,$1b,$18,$14,$11,$0d,$0a,$06,$02,$ff,$fc,$f9,$f6,$f4,$f2,$f0
        dc.b    $ef,$ee,$ed,$ec,$ec,$ec,$ed,$ee,$ee,$f0,$f1,$f2,$f4,$fa,$03,$0a
        dc.b    $0d,$14,$1c,$20,$1f,$1f,$1d,$1b,$18,$15,$12,$0e,$0b,$07,$03,$00
        dc.b    $fd,$fa,$f8,$f4,$f3,$f1,$f0,$ee,$ed,$ed,$ec,$ec,$ed,$ed,$ee,$ef
        dc.b    $f0,$f2,$f4,$f8,$ff,$08,$0c,$0f,$19,$1f,$20,$1e,$1d,$1b,$19,$16
        dc.b    $12,$0f,$0c,$08,$04,$01,$fe,$fb,$f8,$f6,$f4,$f2,$f0,$ef,$ee,$ed
        dc.b    $ed,$ec,$ed,$ed,$ee,$ef,$f0,$f1,$f3,$f7,$ff,$07,$0b,$0d,$15,$1c
        dc.b    $1f,$1e,$1d,$1c,$19,$17,$13,$10,$0d,$09,$06,$02,$ff,$fc,$f9,$f7
        dc.b    $f4,$f3,$f1,$f0,$ee,$ee,$ed,$ed,$ed,$ee,$ee,$ef,$f0,$f1,$f3,$f5
        dc.b    $fc,$04,$0a,$0b,$11,$19,$1e,$1e,$1d,$1c,$1a,$18,$14,$11,$0e,$0a
        dc.b    $07,$03,$00,$fd,$fa,$f8,$f5,$f3,$f2,$f0,$ef,$ee,$ee,$ed,$ed,$ee
        dc.b    $ee,$ef,$f0,$f1,$f2,$f4,$fa,$01,$08,$0b,$0d,$14,$1b,$1e,$1d,$1c
        dc.b    $1a,$18,$16,$12,$0f,$0c,$08,$05,$01,$ff,$fc,$f9,$f6,$f4,$f3,$f1
        dc.b    $f0,$ef,$ee,$ee,$ee,$ee,$ee,$ef,$f0,$f1,$f2,$f3,$f7,$ff,$06,$0a
        dc.b    $0b,$0f,$17,$1d,$1d,$1c,$1b,$19,$17,$14,$10,$0e,$0a,$07,$03,$00
        dc.b    $fe,$fb,$f8,$f6,$f4,$f2,$f0,$f0,$ef,$ee,$ee,$ee,$ee,$ef,$f0,$f0
        dc.b    $f1,$f3,$f5,$fb,$03,$08,$0a,$0c,$13,$19,$1d,$1c,$1b,$1a,$18,$15
        dc.b    $12,$0f,$0c,$08,$05,$02,$ff,$fc,$f9,$f8,$f5,$f3,$f1,$f0,$f0,$ef
        dc.b    $ee,$ee,$ee,$ef,$ef,$f0,$f1,$f2,$f4,$f7,$ff,$06,$09,$0a,$0d,$14
        dc.b    $1a,$1c,$1b,$1a,$18,$16,$13,$10,$0e,$0a,$07,$04,$00,$fe,$fc,$f9
        dc.b    $f7,$f5,$f3,$f1,$f0,$f0,$ef,$ef,$ef,$ef,$ef,$f0,$f1,$f2,$f3,$f5
        dc.b    $fb,$03,$08,$0a,$0b,$0f,$15,$1a,$1c,$1a,$19,$17,$15,$12,$0f,$0c
        dc.b    $09,$06,$02,$00,$fd,$fa,$f8,$f6,$f4,$f2,$f1,$f0,$f0,$ef,$ef,$ef
        dc.b    $ef,$f0,$f0,$f1,$f2,$f4,$f7,$ff,$05,$09,$09,$0b,$0f,$16,$1a,$1b
        dc.b    $19,$18,$16,$14,$11,$0e,$0b,$08,$05,$02,$ff,$fc,$fa,$f8,$f6,$f4
        dc.b    $f2,$f1,$f0,$f0,$ef,$ef,$ef,$f0,$f0,$f1,$f2,$f3,$f5,$fa,$01,$07
        dc.b    $09,$0a,$0b,$11,$17,$1b,$1a,$18,$17,$15,$13,$10,$0d,$0a,$07,$04
        dc.b    $01,$ff,$fc,$f9,$f8,$f5,$f4,$f2,$f1,$f0,$f0,$f0,$f0,$f0,$f0,$f0
        dc.b    $f1,$f2,$f4,$f6,$fd,$03,$07,$09,$0a,$0c,$11,$17,$1a,$19,$18,$16
        dc.b    $14,$12,$0f,$0c,$09,$06,$03,$00,$fe,$fb,$f9,$f7,$f5,$f3,$f2,$f1
        dc.b    $f0,$f0,$f0,$f0,$f0,$f0,$f1,$f2,$f3,$f4,$f9,$ff,$06,$08,$09,$0a
        dc.b    $0c,$11,$17,$19,$17,$16,$15,$13,$10,$0e,$0b,$08,$05,$02,$00,$fd
        dc.b    $fb,$f8,$f6,$f5,$f4,$f2,$f1,$f1,$f0,$f0,$f0,$f0,$f1,$f2,$f3,$f4
        dc.b    $f7,$fd,$03,$07,$08,$09,$0a,$0e,$13,$17,$18,$17,$16,$14,$12,$0f
        dc.b    $0d,$0a,$07,$04,$01,$ff,$fc,$fa,$f8,$f6,$f4,$f3,$f2,$f1,$f0,$f0
        dc.b    $f0,$f0,$f1,$f1,$f2,$f3,$f5,$f9,$ff,$06,$07,$08,$09,$0b,$0f,$13
        dc.b    $17,$17,$16,$14,$12,$10,$0e,$0b,$08,$05,$03,$00,$fe,$fb,$f9,$f7
        dc.b    $f5,$f4,$f3,$f2,$f1,$f1,$f0,$f0,$f1,$f1,$f2,$f3,$f3,$f7,$fd,$03
        dc.b    $07,$07,$09,$09,$0b,$0f,$15,$17,$16,$15,$13,$12,$0f,$0c,$0a,$07
        dc.b    $04,$01,$ff,$fd,$fb,$f8,$f7,$f5,$f4,$f3,$f2,$f1,$f1,$f1,$f1,$f1
        dc.b    $f2,$f3,$f4,$f6,$fb,$01,$06,$07,$08,$09,$09,$0d,$12,$16,$16,$15
        dc.b    $13,$12,$10,$0e,$0b,$08,$05,$03,$00,$fe,$fc,$fa,$f8,$f6,$f5,$f3
        dc.b    $f2,$f2,$f1,$f1,$f1,$f1,$f2,$f2,$f3,$f5,$f9,$ff,$04,$07,$07,$08
        dc.b    $09,$0a,$0e,$13,$16,$15,$13,$12,$10,$0e,$0b,$09,$06,$04,$01,$ff
        dc.b    $fc,$fa,$f8,$f7,$f5,$f4,$f3,$f2,$f2,$f1,$f1,$f1,$f2,$f3,$f4,$f4
        dc.b    $f8,$fe,$03,$07,$07,$08,$09,$09,$0c,$11,$15,$15,$13,$12,$11,$0f
        dc.b    $0d,$0a,$07,$05,$02,$00,$fe,$fc,$f9,$f8,$f6,$f5,$f4,$f3,$f2,$f2
        dc.b    $f2,$f2,$f2,$f3,$f3,$f4,$f6,$fc,$01,$05,$07,$07,$08,$09,$0a,$0e
        dc.b    $12,$15,$14,$12,$11,$0f,$0d,$0b,$08,$06,$03,$00,$fe,$fc,$fa,$f8
        dc.b    $f7,$f5,$f4,$f3,$f3,$f2,$f2,$f2,$f2,$f3,$f3,$f4,$f6,$fb,$01,$05
        dc.b    $06,$07,$07,$08,$08,$0c,$0f,$13,$14,$12,$11,$0f,$0e,$0b,$09,$07
        dc.b    $04,$02,$ff,$fd,$fb,$f9,$f8,$f6,$f5,$f4,$f3,$f3,$f2,$f3,$f3,$f3
        dc.b    $f3,$f4,$f6,$fa,$ff,$04,$06,$07,$07,$08,$08,$0a,$0e,$12,$14,$12
        dc.b    $11,$0f,$0e,$0c,$09,$07,$04,$02,$00,$fe,$fc,$fa,$f8,$f7,$f5,$f4
        dc.b    $f3,$f3,$f3,$f2,$f3,$f3,$f3,$f4,$f5,$fa,$ff,$04,$06,$06,$07,$07
        dc.b    $08,$09,$0d,$10,$13,$12,$10,$0f,$0e,$0c,$09,$07,$04,$02,$00,$fe
        dc.b    $fc,$fa,$f8,$f7,$f6,$f4,$f4,$f3,$f3,$f3,$f3,$f3,$f3,$f4,$f6,$fa
        dc.b    $ff,$04,$06,$06,$07,$07,$08,$08,$0b,$0f,$12,$12,$10,$0f,$0e,$0c
        dc.b    $0a,$07,$05,$03,$00,$fe,$fc,$fb,$f9,$f8,$f6,$f5,$f4,$f4,$f3,$f3
        dc.b    $f3,$f3,$f4,$f4,$f6,$fa,$ff,$03,$06,$06,$07,$07,$07,$07,$09,$0d
        dc.b    $11,$12,$10,$0f,$0e,$0c,$0a,$08,$05,$03,$00,$ff,$fd,$fb,$f9,$f8
        dc.b    $f6,$f5,$f4,$f4,$f3,$f3,$f3,$f3,$f4,$f5,$f6,$fa,$ff,$03,$05,$06
        dc.b    $06,$07,$07,$07,$08,$0c,$0f,$11,$10,$0f,$0d,$0c,$0a,$08,$05,$03
        dc.b    $01,$ff,$fe,$fc,$fa,$f8,$f7,$f6,$f5,$f4,$f4,$f4,$f4,$f4,$f4,$f5
        dc.b    $f6,$fa,$ff,$04,$05,$06,$07,$07,$07,$07,$07,$0b,$0f,$11,$10,$0e
        dc.b    $0d,$0c,$0a,$08,$06,$03,$01,$ff,$fe,$fc,$fa,$f9,$f8,$f6,$f5,$f4
        dc.b    $f4,$f4,$f4,$f4,$f4,$f5,$f6,$fb,$ff,$03,$05,$05,$06,$07,$06,$06
        dc.b    $07,$0a,$0e,$10,$0f,$0e,$0d,$0c,$0a,$08,$05,$03,$01,$00,$fe,$fc
        dc.b    $fa,$f8,$f8,$f6,$f5,$f4,$f4,$f4,$f4,$f4,$f4,$f5,$f7,$fb,$ff,$03
        dc.b    $04,$05,$06,$06,$06,$06,$06,$09,$0d,$0f,$0f,$0e,$0d,$0c,$0a,$08
        dc.b    $06,$04,$01,$00,$fe,$fc,$fa,$f9,$f8,$f7,$f6,$f5,$f5,$f4,$f4,$f4
        dc.b    $f5,$f6,$f8,$fd,$01,$04,$04,$05,$06,$06,$06,$06,$06,$08,$0c,$0f
        dc.b    $0f,$0d,$0c,$0b,$09,$07,$05,$03,$01,$ff,$fe,$fc,$fa,$f9,$f8,$f7
        dc.b    $f6,$f5,$f5,$f5,$f5,$f5,$f5,$f6,$f9,$fe,$01,$04,$04,$05,$06,$06
        dc.b    $06,$05,$05,$08,$0c,$0e,$0e,$0d,$0c,$0a,$09,$07,$05,$03,$01,$ff
        dc.b    $fe,$fc,$fa,$f9,$f8,$f7,$f6,$f6,$f5,$f5,$f5,$f5,$f6,$f7,$fb,$ff
        dc.b    $03,$05,$05,$06,$06,$06,$05,$05,$06,$09,$0c,$0e,$0e,$0c,$0b,$0a
        dc.b    $08,$07,$05,$03,$01,$ff,$fe,$fc,$fb,$f9,$f8,$f7,$f6,$f6,$f5,$f5
        dc.b    $f5,$f6,$f6,$f7,$fc,$ff,$03,$04,$05,$05,$05,$05,$05,$04,$05,$08
        dc.b    $0b,$0d,$0d,$0c,$0b,$09,$08,$06,$04,$02,$00,$ff,$fd,$fc,$fa,$f9
        dc.b    $f8,$f7,$f6,$f6,$f6,$f5,$f5,$f6,$f7,$f9,$fe,$02,$04,$04,$04,$05
        dc.b    $05,$05,$04,$04,$05,$07,$0b,$0d,$0c,$0b,$0a,$09,$07,$05,$04,$02
        dc.b    $00,$ff,$fd,$fc,$fa,$f9,$f8,$f8,$f7,$f6,$f6,$f6,$f6,$f6,$f8,$fb
        dc.b    $ff,$03,$04,$04,$05,$05,$05,$05,$04,$04,$05,$09,$0b,$0d,$0c,$0a
        dc.b    $09,$08,$07,$05,$03,$01,$00,$fe,$fc,$fb,$fa,$f9,$f8,$f7,$f7,$f6
        dc.b    $f6,$f6,$f6,$f7,$f9,$fe,$01,$03,$04,$04,$05,$05,$04,$04,$04,$03
        dc.b    $05,$09,$0b,$0c,$0b,$0a,$09,$07,$06,$04,$02,$01,$ff,$fe,$fc,$fb
        dc.b    $fa,$f8,$f8,$f7,$f7,$f6,$f6,$f6,$f7,$f8,$fb,$ff,$03,$04,$04,$05
        dc.b    $04,$05,$04,$04,$03,$03,$06,$09,$0c,$0c,$0a,$09,$08,$07,$05,$04
        dc.b    $02,$00,$ff,$fd,$fc,$fb,$f9,$f9,$f8,$f8,$f7,$f7,$f7,$f7,$f7,$fa
        dc.b    $ff,$02,$04,$04,$04,$04,$04,$04,$04,$03,$03,$03,$07,$0a,$0b,$0a
        dc.b    $09,$08,$07,$06,$04,$03,$01,$ff,$fe,$fd,$fb,$fa,$f9,$f8,$f8,$f7
        dc.b    $f7,$f7,$f7,$f7,$f9,$fd,$01,$03,$03,$04,$04,$04,$04,$03,$03,$03
        dc.b    $02,$05,$07,$0a,$0a,$09,$08,$07,$06,$04,$03,$01,$00,$ff,$fd,$fc
        dc.b    $fb,$fa,$f9,$f8,$f8,$f8,$f8,$f8,$f8,$f8,$fb,$ff,$03,$04,$04,$04
        dc.b    $04,$04,$04,$03,$03,$02,$03,$05,$08,$0a,$0a,$09,$08,$07,$06,$04
        dc.b    $03,$01,$00,$ff,$fd,$fc,$fb,$fa,$f9,$f8,$f8,$f8,$f8,$f8,$f8,$fa
        dc.b    $fe,$01,$03,$03,$04,$04,$04,$04,$03,$03,$02,$02,$03,$06,$08,$0a
        dc.b    $09,$08,$07,$06,$05,$03,$02,$00,$ff,$fe,$fd,$fc,$fb,$fa,$f9,$f8
        dc.b    $f8,$f8,$f8,$f8,$f8,$fb,$ff,$03,$03,$03,$03,$04,$03,$03,$03,$02
        dc.b    $02,$01,$03,$06,$09,$09,$09,$08,$07,$06,$05,$03,$02,$00,$ff,$fe
        dc.b    $fc,$fc,$fb,$fa,$f9,$f9,$f8,$f8,$f8,$f8,$fb,$fe,$01,$03,$03,$04
        dc.b    $04,$04,$03,$03,$03,$02,$02,$01,$03,$06,$08,$09,$08,$07,$07,$05
        dc.b    $04,$03,$01,$00,$ff,$fe,$fc,$fc,$fa,$fa,$f9,$f8,$f8,$f8,$f8,$f9
        dc.b    $fc,$ff,$02,$03,$03,$04,$04,$03,$03,$03,$02,$02,$01,$01,$03,$06
        dc.b    $08,$08,$07,$07,$06,$05,$03,$02,$01,$00,$fe,$fd,$fc,$fb,$fa,$f9
        dc.b    $f9,$f8,$f8,$f8,$f8,$fa,$fd,$ff,$03,$03,$03,$04,$04,$03,$03,$03
        dc.b    $02,$02,$01,$01,$03,$07,$08,$08,$07,$07,$06,$05,$03,$02,$01,$00
        dc.b    $ff,$fd,$fc,$fb,$fa,$fa,$f9,$f9,$f9,$f9,$f9,$fb,$ff,$01,$03,$03
        dc.b    $03,$03,$03,$03,$03,$02,$02,$01,$00,$01,$03,$06,$08,$08,$07,$06
        dc.b    $05,$04,$03,$02,$00,$ff,$fe,$fd,$fc,$fb,$fa,$fa,$f9,$f9,$f9,$f9
        dc.b    $f9,$fc,$ff,$02,$03,$03,$03,$03,$03,$03,$02,$02,$01,$01,$00,$01
        dc.b    $03,$06,$07,$07,$07,$06,$05,$04,$03,$02,$00,$ff,$fe,$fe,$fc,$fc
        dc.b    $fb,$fa,$fa,$fa,$fa,$f9,$fa,$fd,$00,$03,$03,$03,$04,$03,$03,$03
        dc.b    $03,$02,$01,$01,$00,$01,$03,$05,$07,$07,$07,$06,$05,$04,$03,$02
        dc.b    $00,$ff,$fe,$fe,$fc,$fc,$fb,$fa,$fa,$f9,$f9,$f9,$fa,$fe,$00,$03
        dc.b    $03,$03,$03,$03,$03,$03,$02,$02,$01,$00,$00,$00,$02,$05,$07,$07
        dc.b    $06,$06,$05,$04,$03,$02,$01,$00,$fe,$fd,$fd,$fc,$fb,$fa,$fa,$fa
        dc.b    $f9,$fa,$fb,$fe,$01,$03,$03,$03,$03,$03,$03,$02,$02,$01,$01,$00
        dc.b    $00,$ff,$02,$04,$06,$07,$06,$06,$05,$04,$03,$02,$01,$00,$ff,$fe
        dc.b    $fd,$fc,$fc,$fb,$fa,$fa,$fa,$fa,$fb,$fe,$01,$03,$03,$03,$03,$03
        dc.b    $03,$02,$02,$01,$01,$00,$00,$ff,$01,$03,$06,$07,$06,$05,$05,$04
        dc.b    $03,$02,$01,$00,$ff,$fe,$fd,$fc,$fc,$fb,$fb,$fa,$fa,$fa,$fb,$fe
        dc.b    $01,$03,$03,$03,$03,$03,$03,$02,$02,$01,$00,$00,$ff,$ff,$00,$02
        dc.b    $05,$06,$06,$05,$05,$04,$03,$02,$01,$00,$ff,$fe,$fd,$fc,$fc,$fb
        dc.b    $fb,$fb,$fa,$fb,$fc,$ff,$01,$03,$04,$03,$04,$03,$03,$03,$02,$01
        dc.b    $01,$00,$ff,$ff,$ff,$02,$05,$06,$06,$06,$05,$04,$03,$02,$01,$00
        dc.b    $00,$ff,$fe,$fd,$fc,$fc,$fb,$fb,$fb,$fa,$fc,$ff,$01,$03,$03,$03
        dc.b    $03,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$ff,$01,$03,$05,$06,$05
        dc.b    $05,$04,$03,$02,$02,$00,$00,$ff,$fe,$fd,$fc,$fc,$fc,$fb,$fb,$fb
        dc.b    $fc,$ff,$01,$03,$03,$03,$03,$03,$03,$02,$01,$00,$00,$ff,$ff,$ff
        dc.b    $ff,$00,$02,$04,$06,$05,$05,$04,$04,$03,$02,$01,$00,$ff,$ff,$fe
        dc.b    $fd,$fc,$fc,$fc,$fc,$fb,$fc,$ff,$01,$03,$03,$03,$03,$03,$03,$02
        dc.b    $02,$01,$00,$00,$ff,$ff,$ff,$ff,$01,$03,$05,$05,$05,$04,$04,$03
        dc.b    $02,$01,$00,$00,$ff,$fe,$fd,$fd,$fc,$fc,$fb,$fb,$fc,$fe,$00,$03
        dc.b    $03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$fe,$ff,$00,$03
        dc.b    $04,$05,$05,$04,$04,$03,$02,$01,$01,$00,$ff,$fe,$fe,$fd,$fc,$fc
        dc.b    $fc,$fc,$fc,$fe,$00,$02,$03,$03,$03,$03,$03,$02,$02,$01,$00,$00
        dc.b    $00,$ff,$ff,$fe,$ff,$01,$04,$05,$05,$04,$04,$03,$03,$02,$01,$00
        dc.b    $ff,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fe,$ff,$02,$03,$03,$03,$03
        dc.b    $03,$02,$02,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$00,$02,$04,$05,$04
        dc.b    $04,$03,$03,$02,$01,$01,$00,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fd
        dc.b    $ff,$01,$03,$04,$03,$03,$03,$02,$02,$01,$00,$00,$ff,$ff,$ff,$fe
        dc.b    $fe,$ff,$01,$03,$04,$04,$04,$03,$03,$02,$02,$01,$00,$ff,$ff,$fe
        dc.b    $fe,$fd,$fd,$fd,$fc,$fd,$ff,$01,$03,$04,$03,$03,$03,$03,$02,$01
        dc.b    $01,$00,$ff,$ff,$ff,$fe,$fe,$fe,$ff,$02,$03,$05,$04,$04,$03,$03
        dc.b    $02,$01,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fe,$00,$02,$03
        dc.b    $03,$03,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fe,$00
        dc.b    $02,$03,$04,$04,$04,$03,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fd,$fd
        dc.b    $fd,$fc,$fd,$ff,$01,$03,$04,$03,$03,$03,$02,$02,$01,$00,$00,$ff
        dc.b    $ff,$fe,$fe,$fe,$fe,$ff,$01,$03,$04,$04,$04,$04,$03,$03,$02,$01
        dc.b    $00,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$ff,$01,$03,$04,$03,$03,$03
        dc.b    $03,$02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fe,$ff,$01,$03,$04
        dc.b    $04,$03,$03,$03,$02,$01,$01,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fe
        dc.b    $ff,$02,$03,$04,$03,$03,$03,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe
        dc.b    $fd,$fd,$fe,$ff,$01,$03,$04,$03,$03,$03,$02,$02,$01,$01,$00,$ff
        dc.b    $ff,$fe,$fe,$fe,$fd,$fd,$ff,$01,$03,$04,$04,$04,$03,$03,$03,$02
        dc.b    $01,$00,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fe,$ff,$01,$03,$04,$03,$03
        dc.b    $03,$03,$02,$01,$01,$00,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$ff,$01,$03
        dc.b    $04,$03,$03,$03,$02,$02,$01,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fd
        dc.b    $fe,$ff,$01,$03,$04,$03,$03,$03,$03,$02,$01,$00,$00,$ff,$ff,$ff
        dc.b    $fe,$fe,$fe,$ff,$00,$02,$04,$04,$03,$03,$03,$02,$01,$01,$00,$ff
        dc.b    $ff,$fe,$fe,$fe,$fd,$fd,$fd,$fe,$ff,$02,$03,$04,$03,$03,$03,$03
        dc.b    $02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$00,$02,$03,$04,$04,$03
        dc.b    $03,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fe,$ff
        dc.b    $02,$03,$03,$03,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$ff,$fe,$fe
        dc.b    $ff,$01,$03,$04,$04,$03,$03,$03,$02,$01,$01,$00,$ff,$ff,$ff,$fe
        dc.b    $fe,$fd,$fd,$fd,$fd,$ff,$00,$02,$03,$03,$03,$02,$02,$01,$01,$01
        dc.b    $00,$ff,$ff,$ff,$fe,$fe,$ff,$00,$02,$03,$04,$04,$03,$03,$03,$02
        dc.b    $01,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fd,$fe,$ff,$01,$03,$03
        dc.b    $03,$03,$03,$02,$02,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$01,$03
        dc.b    $04,$04,$03,$03,$03,$02,$01,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc
        dc.b    $fc,$fc,$fe,$00,$02,$03,$03,$03,$03,$03,$02,$01,$01,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$ff,$01,$03,$04,$04,$04,$03,$03,$02,$02,$01,$00,$00
        dc.b    $ff,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fd,$ff,$00,$02,$03,$03,$03,$03
        dc.b    $02,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$01,$03,$04,$04,$04,$03
        dc.b    $03,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fe
        dc.b    $ff,$01,$03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff
        dc.b    $00,$02,$03,$04,$04,$04,$03,$03,$02,$01,$01,$00,$ff,$ff,$fe,$fe
        dc.b    $fd,$fd,$fc,$fc,$fc,$fd,$ff,$01,$02,$03,$03,$03,$02,$02,$02,$01
        dc.b    $01,$00,$00,$ff,$ff,$ff,$00,$01,$03,$04,$04,$04,$03,$03,$02,$01
        dc.b    $01,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fc,$fd,$fe,$00,$01,$03
        dc.b    $03,$03,$03,$02,$02,$02,$01,$01,$00,$00,$00,$ff,$00,$01,$03,$04
        dc.b    $04,$04,$03,$03,$02,$02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fc
        dc.b    $fc,$fc,$fd,$ff,$01,$02,$03,$03,$03,$02,$02,$02,$01,$01,$00,$00
        dc.b    $ff,$ff,$00,$01,$03,$04,$05,$04,$03,$03,$02,$02,$01,$00,$ff,$ff
        dc.b    $fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fd,$fe,$00,$01,$03,$03,$02,$03
        dc.b    $02,$02,$01,$01,$01,$00,$00,$00,$00,$02,$03,$05,$05,$05,$04,$03
        dc.b    $03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fd,$fe
        dc.b    $ff,$01,$03,$03,$03,$03,$02,$02,$02,$01,$01,$00,$00,$00,$00,$02
        dc.b    $03,$04,$05,$04,$04,$03,$03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fd
        dc.b    $fc,$fc,$fc,$fc,$fc,$fe,$ff,$01,$02,$03,$03,$03,$03,$02,$02,$01
        dc.b    $01,$01,$00,$00,$00,$02,$03,$04,$05,$04,$04,$03,$02,$02,$01,$00
        dc.b    $ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fd,$ff,$00,$02,$03
        dc.b    $03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$01,$02,$04,$05,$05,$04
        dc.b    $04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc
        dc.b    $fc,$fd,$fe,$ff,$02,$03,$02,$03,$03,$02,$02,$02,$01,$01,$01,$00
        dc.b    $01,$03,$04,$05,$05,$04,$04,$03,$03,$02,$01,$00,$00,$ff,$fe,$fe
        dc.b    $fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff,$01,$02,$02,$02,$02,$02
        dc.b    $02,$02,$01,$01,$01,$01,$01,$03,$04,$05,$05,$04,$04,$03,$03,$02
        dc.b    $01,$00,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff
        dc.b    $01,$02,$02,$03,$03,$02,$02,$02,$01,$01,$01,$01,$02,$03,$04,$05
        dc.b    $05,$04,$04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fe,$ff,$01,$02,$03,$02,$02,$02,$02,$02,$02,$01
        dc.b    $01,$01,$02,$03,$05,$05,$05,$04,$04,$03,$02,$01,$01,$00,$ff,$ff
        dc.b    $fe,$fd,$fd,$fc,$fc,$fc,$fc,$fb,$fc,$fc,$fe,$ff,$01,$02,$02,$02
        dc.b    $02,$03,$02,$02,$02,$01,$01,$02,$03,$04,$05,$06,$05,$05,$04,$03
        dc.b    $03,$01,$01,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fe,$ff,$01,$02,$02,$02,$03,$02,$02,$02,$02,$01,$01,$02,$03,$05
        dc.b    $05,$05,$05,$04,$04,$03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fd,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff,$01,$02,$02,$02,$03,$02,$02,$02
        dc.b    $02,$01,$01,$03,$04,$05,$06,$05,$05,$04,$03,$03,$02,$01,$00,$ff
        dc.b    $ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe,$00,$01,$03
        dc.b    $03,$03,$03,$03,$02,$02,$02,$02,$02,$03,$05,$06,$06,$05,$05,$04
        dc.b    $03,$02,$02,$00,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fd,$fe,$ff,$01,$02,$02,$03,$03,$02,$02,$02,$02,$02,$03,$04
        dc.b    $05,$06,$06,$05,$04,$04,$03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fd
        dc.b    $fc,$fc,$fc,$fb,$fb,$fb,$fc,$fd,$ff,$00,$01,$02,$02,$02,$02,$02
        dc.b    $02,$02,$02,$02,$03,$05,$05,$06,$05,$05,$04,$03,$03,$02,$01,$00
        dc.b    $00,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff,$01
        dc.b    $02,$02,$02,$03,$03,$03,$02,$02,$02,$03,$04,$05,$06,$06,$05,$04
        dc.b    $04,$03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fb,$fc
        dc.b    $fc,$fc,$fd,$fe,$ff,$01,$02,$02,$02,$02,$02,$03,$02,$02,$03,$04
        dc.b    $05,$06,$06,$06,$05,$04,$03,$03,$02,$01,$00,$ff,$fe,$fe,$fd,$fd
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$ff,$00,$02,$02,$03,$03,$03
        dc.b    $03,$03,$03,$03,$04,$05,$06,$07,$06,$05,$05,$04,$03,$02,$01,$00
        dc.b    $00,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fb,$fb,$fb,$fc,$fc,$fe,$ff
        dc.b    $01,$02,$02,$03,$03,$03,$03,$02,$03,$03,$04,$06,$06,$06,$05,$05
        dc.b    $04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fd,$fe,$00,$01,$02,$02,$03,$03,$03,$02,$02,$03,$04
        dc.b    $05,$06,$06,$06,$05,$04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fe,$fd
        dc.b    $fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff,$00,$02,$02,$03,$03
        dc.b    $03,$03,$03,$03,$04,$05,$06,$06,$06,$06,$05,$04,$03,$03,$02,$01
        dc.b    $00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fb,$fc,$fb,$fc,$fe
        dc.b    $ff,$00,$02,$03,$03,$03,$03,$03,$03,$03,$04,$05,$06,$07,$06,$06
        dc.b    $05,$04,$03,$03,$01,$00,$00,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc
        dc.b    $fb,$fb,$fc,$fc,$fc,$fe,$ff,$01,$02,$03,$03,$03,$03,$03,$03,$04
        dc.b    $05,$06,$07,$07,$06,$06,$05,$04,$03,$02,$02,$01,$00,$ff,$fe,$fe
        dc.b    $fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff,$01,$02,$02
        dc.b    $03,$03,$03,$03,$03,$04,$05,$06,$07,$07,$06,$05,$04,$04,$03,$02
        dc.b    $01,$00,$ff,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fb,$fc,$fc,$fc,$fc
        dc.b    $fd,$fe,$ff,$01,$02,$03,$03,$03,$03,$03,$03,$05,$06,$06,$07,$06
        dc.b    $06,$05,$04,$03,$03,$01,$01,$00,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc
        dc.b    $fb,$fb,$fb,$fc,$fc,$fc,$fd,$fe,$00,$01,$02,$03,$03,$03,$03,$03
        dc.b    $04,$05,$06,$07,$07,$06,$06,$05,$04,$03,$03,$02,$01,$00,$ff,$fe
        dc.b    $fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe,$00,$01
        dc.b    $02,$03,$03,$03,$03,$03,$04,$05,$06,$07,$07,$06,$06,$05,$04,$03
        dc.b    $02,$01,$00,$00,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fc,$fb,$fb,$fb
        dc.b    $fc,$fc,$fd,$fe,$ff,$01,$02,$03,$03,$03,$03,$03,$04,$05,$06,$07
        dc.b    $07,$06,$06,$05,$04,$03,$03,$01,$01,$00,$ff,$ff,$fe,$fd,$fd,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe,$ff,$01,$02,$03,$03,$03
        dc.b    $03,$04,$04,$06,$07,$07,$07,$06,$06,$05,$04,$03,$02,$01,$00,$00
        dc.b    $ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fb,$fc,$fc,$fc,$fc,$fd,$fe
        dc.b    $ff,$00,$02,$03,$03,$03,$03,$04,$05,$06,$07,$07,$07,$06,$06,$05
        dc.b    $04,$03,$02,$01,$01,$00,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fb,$fb
        dc.b    $fb,$fb,$fc,$fc,$fc,$fd,$ff,$00,$01,$02,$03,$03,$03,$04,$05,$06
        dc.b    $07,$07,$07,$07,$06,$05,$04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fd
        dc.b    $fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$ff,$00,$01,$02
        dc.b    $03,$03,$03,$04,$05,$06,$07,$07,$07,$06,$06,$05,$04,$03,$03,$02
        dc.b    $01,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fb,$fb,$fc,$fc,$fc
        dc.b    $fc,$fd,$ff,$ff,$01,$02,$03,$03,$03,$04,$05,$06,$07,$07,$07,$06
        dc.b    $06,$05,$04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$ff,$01,$02,$03,$03,$03,$04
        dc.b    $05,$06,$07,$07,$07,$07,$06,$06,$04,$04,$03,$02,$01,$00,$ff,$ff
        dc.b    $fe,$fe,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff
        dc.b    $00,$01,$03,$03,$03,$03,$05,$06,$07,$07,$07,$07,$06,$05,$05,$04
        dc.b    $03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fb
        dc.b    $fc,$fc,$fc,$fc,$fd,$fe,$ff,$01,$02,$03,$03,$03,$04,$05,$06,$07
        dc.b    $07,$07,$06,$06,$05,$04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fe,$fd
        dc.b    $fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe,$ff,$01,$02,$03
        dc.b    $03,$03,$04,$05,$06,$07,$07,$07,$07,$06,$05,$04,$03,$03,$02,$01
        dc.b    $00,$ff,$ff,$fe,$fe,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fe,$ff,$00,$01,$02,$03,$03,$04,$05,$06,$07,$07,$07,$07,$06
        dc.b    $05,$05,$04,$03,$02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe,$ff,$01,$02,$03,$03,$04,$05
        dc.b    $06,$07,$07,$07,$07,$07,$06,$05,$04,$03,$02,$02,$00,$00,$ff,$ff
        dc.b    $fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fe,$ff
        dc.b    $00,$01,$02,$03,$03,$04,$05,$06,$07,$07,$07,$07,$06,$05,$04,$04
        dc.b    $03,$02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fd,$fe,$ff,$01,$01,$03,$03,$03,$05,$06,$07,$07
        dc.b    $07,$07,$06,$06,$05,$04,$03,$02,$01,$01,$00,$ff,$ff,$fe,$fe,$fd
        dc.b    $fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$fe,$00,$01,$02
        dc.b    $03,$03,$05,$06,$07,$07,$07,$07,$07,$06,$05,$05,$04,$03,$02,$01
        dc.b    $00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fd,$fe,$ff,$00,$01,$02,$03,$04,$05,$06,$07,$07,$07,$07,$06
        dc.b    $06,$05,$04,$03,$02,$02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$ff,$00,$01,$03,$03,$04
        dc.b    $06,$07,$07,$07,$07,$07,$06,$06,$05,$04,$03,$02,$01,$00,$00,$ff
        dc.b    $fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fe
        dc.b    $fe,$ff,$01,$02,$03,$03,$05,$06,$07,$07,$07,$07,$07,$06,$05,$04
        dc.b    $04,$03,$02,$01,$00,$ff,$ff,$ff,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fd,$fd,$fe,$ff,$ff,$01,$02,$03,$04,$05,$06,$07
        dc.b    $07,$07,$07,$06,$06,$05,$04,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe
        dc.b    $fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fd,$fe,$ff,$00
        dc.b    $01,$03,$03,$05,$06,$07,$07,$07,$07,$07,$06,$06,$05,$04,$03,$02
        dc.b    $01,$00,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fd,$fd,$fe,$ff,$00,$01,$03,$04,$05,$06,$07,$07,$07,$07
        dc.b    $07,$06,$05,$04,$04,$03,$02,$01,$00,$00,$ff,$fe,$fe,$fd,$fd,$fc
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$ff,$ff,$01,$02,$03
        dc.b    $05,$06,$07,$07,$07,$07,$07,$07,$06,$05,$04,$03,$03,$02,$01,$00
        dc.b    $ff,$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd
        dc.b    $fd,$fe,$ff,$00,$01,$03,$04,$05,$06,$07,$07,$07,$07,$07,$06,$05
        dc.b    $04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fc,$fd,$fd,$fd,$fe,$fe,$ff,$00,$02,$03,$05,$06,$07
        dc.b    $07,$07,$07,$07,$06,$06,$05,$04,$03,$02,$01,$00,$00,$ff,$ff,$fe
        dc.b    $fd,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$fe,$ff
        dc.b    $00,$01,$03,$04,$05,$07,$07,$07,$07,$07,$07,$06,$05,$04,$03,$03
        dc.b    $02,$01,$00,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fd,$fd,$fe,$fe,$ff,$00,$02,$03,$05,$06,$07,$07,$07,$07
        dc.b    $07,$06,$05,$05,$04,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe,$fd,$fd
        dc.b    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fd,$fd,$fe,$ff,$00,$01,$03
        dc.b    $04,$06,$07,$07,$07,$07,$07,$06,$06,$05,$04,$03,$03,$01,$01,$00
        dc.b    $00,$ff,$fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd
        dc.b    $fd,$fe,$ff,$ff,$01,$02,$04,$05,$06,$07,$07,$07,$07,$06,$06,$05
        dc.b    $04,$03,$03,$02,$01,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc
        dc.b    $fc,$fc,$fc,$fd,$fd,$fd,$fd,$fe,$ff,$ff,$00,$02,$03,$05,$06,$07
        dc.b    $07,$07,$07,$06,$06,$05,$04,$03,$03,$02,$01,$00,$ff,$ff,$ff,$fe
        dc.b    $fe,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$fe,$ff
        dc.b    $00,$02,$03,$05,$07,$07,$07,$07,$07,$07,$06,$05,$05,$04,$03,$02
        dc.b    $01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc
        dc.b    $fc,$fd,$fd,$fe,$fe,$ff,$ff,$01,$03,$05,$06,$07,$07,$07,$07,$07
        dc.b    $06,$05,$05,$04,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd
        dc.b    $fd,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fd,$fe,$fe,$ff,$ff,$01,$03,$04
        dc.b    $06,$07,$07,$07,$07,$06,$06,$05,$05,$04,$03,$02,$01,$01,$00,$ff
        dc.b    $ff,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
        dc.b    $fe,$ff,$ff,$01,$02,$04,$06,$07,$07,$07,$07,$06,$06,$05,$04,$04
        dc.b    $03,$02,$01,$01,$00,$00,$ff,$fe,$fe,$fe,$fd,$fd,$fc,$fc,$fc,$fc
        dc.b    $fc,$fc,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$00,$02,$04,$06,$06,$07,$07
        dc.b    $06,$06,$06,$06,$05,$04,$03,$02,$02,$01,$00,$ff,$ff,$ff,$fe,$fe
        dc.b    $fd,$fd,$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fd,$fd,$fe,$fe,$fe,$ff,$00
        dc.b    $02,$04,$06,$06,$07,$07,$07,$07,$06,$06,$05,$04,$03,$03,$02,$01
        dc.b    $00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fd,$fd,$fd
        dc.b    $fd,$fd,$fe,$fe,$ff,$00,$02,$04,$05,$06,$07,$07,$07,$06,$06,$05
        dc.b    $05,$04,$03,$02,$01,$01,$00,$00,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fc
        dc.b    $fc,$fd,$fc,$fd,$fd,$fd,$fe,$fe,$fe,$fe,$ff,$01,$02,$04,$06,$06
        dc.b    $07,$07,$07,$06,$06,$05,$04,$04,$03,$02,$01,$01,$00,$00,$ff,$fe
        dc.b    $fe,$fe,$fd,$fd,$fd,$fd,$fd,$fc,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$ff
        dc.b    $ff,$01,$03,$04,$06,$07,$07,$07,$06,$06,$06,$05,$04,$03,$03,$02
        dc.b    $01,$01,$00,$ff,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fc,$fc,$fc,$fd,$fd
        dc.b    $fd,$fd,$fe,$fe,$fe,$fe,$ff,$01,$03,$04,$06,$06,$07,$07,$06,$06
        dc.b    $06,$05,$04,$03,$03,$02,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd
        dc.b    $fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$01,$03,$05
        dc.b    $06,$06,$06,$06,$06,$06,$05,$04,$04,$03,$02,$02,$01,$00,$00,$ff
        dc.b    $ff,$fe,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe
        dc.b    $fe,$ff,$00,$01,$03,$05,$06,$06,$06,$06,$06,$06,$05,$05,$04,$03
        dc.b    $02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd
        dc.b    $fd,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$00,$02,$04,$05,$06,$06,$06,$06
        dc.b    $06,$05,$05,$04,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fe
        dc.b    $fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$ff,$00,$01,$03
        dc.b    $04,$06,$06,$07,$06,$06,$06,$05,$05,$04,$03,$03,$02,$01,$00,$00
        dc.b    $ff,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
        dc.b    $fe,$fe,$ff,$00,$02,$03,$04,$06,$06,$06,$06,$06,$05,$05,$04,$03
        dc.b    $03,$02,$01,$01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd
        dc.b    $fd,$fd,$fd,$fd,$fe,$fe,$ff,$ff,$00,$01,$02,$04,$05,$06,$06,$06
        dc.b    $06,$05,$05,$04,$03,$03,$02,$02,$01,$00,$00,$ff,$ff,$fe,$fe,$fe
        dc.b    $fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$ff,$ff,$ff,$00,$02
        dc.b    $03,$04,$06,$06,$06,$06,$06,$05,$05,$04,$03,$03,$02,$01,$01,$00
        dc.b    $00,$ff,$ff,$ff,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
        dc.b    $fe,$fe,$ff,$ff,$01,$02,$03,$05,$06,$06,$06,$06,$05,$05,$04,$04
        dc.b    $03,$03,$02,$01,$01,$00,$00,$ff,$fe,$fe,$fe,$fe,$fe,$fd,$fd,$fd
        dc.b    $fd,$fd,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$00,$01,$03,$04,$05,$06,$06
        dc.b    $06,$05,$05,$05,$04,$03,$03,$02,$02,$01,$00,$00,$ff,$ff,$ff,$fe
        dc.b    $fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$fe,$ff,$00,$01
        dc.b    $02,$03,$04,$05,$06,$06,$05,$05,$05,$04,$04,$03,$02,$02,$01,$01
        dc.b    $00,$00,$ff,$ff,$fe,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
        dc.b    $fe,$fe,$ff,$ff,$00,$01,$02,$04,$05,$05,$06,$06,$06,$05,$05,$04
        dc.b    $03,$03,$02,$02,$01,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd
        dc.b    $fd,$fd,$fd,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$00,$01,$03,$04,$05,$05
        dc.b    $06,$06,$06,$05,$05,$04,$03,$03,$02,$02,$01,$00,$00,$ff,$ff,$ff
        dc.b    $fe,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd,$fe,$fe,$fe,$fe,$ff,$ff,$00
        dc.b    $01,$02,$03,$04,$04,$05,$05,$05,$05,$04,$04,$03,$03,$03,$02,$01
        dc.b    $01,$00,$00,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fd,$fd,$fe,$fe,$fe
        dc.b    $fe,$fe,$fe,$ff,$ff,$00,$01,$02,$03,$04,$05,$05,$05,$05,$05,$04
        dc.b    $04,$03,$03,$03,$02,$01,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$00,$00,$01,$02,$03,$04
        dc.b    $05,$05,$05,$05,$05,$04,$04,$03,$03,$02,$02,$01,$00,$00,$ff,$ff
        dc.b    $ff,$fe,$fe,$fe,$fe,$fe,$fe,$fd,$fd,$fd,$fe,$fe,$fe,$fe,$fe,$ff
        dc.b    $ff,$00,$01,$02,$03,$04,$05,$05,$05,$05,$05,$04,$04,$03,$03,$02
        dc.b    $02,$01,$01,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fd,$fd,$fd,$fd,$fd
        dc.b    $fe,$fe,$fe,$fe,$fe,$ff,$ff,$00,$01,$02,$03,$04,$04,$05,$05,$05
        dc.b    $05,$04,$04,$03,$03,$03,$02,$01,$01,$00,$00,$ff,$ff,$ff,$fe,$fe
        dc.b    $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$00,$01,$01,$02
        dc.b    $03,$04,$04,$05,$05,$05,$05,$04,$04,$03,$03,$02,$01,$01,$00,$00
        dc.b    $ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
        dc.b    $ff,$ff,$00,$01,$01,$02,$03,$03,$04,$05,$05,$05,$04,$04,$04,$03
        dc.b    $03,$02,$02,$01,$01,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fd
        dc.b    $fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$01,$01,$02,$03,$03,$04,$05
        dc.b    $05,$05,$04,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$ff
        dc.b    $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$00,$00
        dc.b    $01,$02,$03,$03,$03,$04,$05,$04,$04,$04,$04,$03,$03,$02,$02,$01
        dc.b    $00,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$ff,$ff,$00,$00,$01,$02,$02,$03,$03,$04,$04,$04,$04,$04
        dc.b    $04,$03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$ff,$ff,$ff,$fe,$fe
        dc.b    $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$00,$00,$01,$02,$03,$03
        dc.b    $03,$04,$04,$04,$04,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff
        dc.b    $00,$00,$01,$01,$02,$03,$03,$04,$04,$04,$04,$04,$04,$03,$03,$03
        dc.b    $02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$01,$01,$02,$03,$03,$03,$04,$04
        dc.b    $04,$04,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$01,$01
        dc.b    $02,$02,$03,$03,$03,$04,$04,$04,$04,$03,$03,$03,$02,$02,$01,$00
        dc.b    $00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
        dc.b    $ff,$ff,$ff,$00,$01,$01,$02,$02,$02,$03,$03,$04,$03,$04,$03,$03
        dc.b    $03,$03,$02,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$ff,$00,$01,$01,$02,$02,$02,$03
        dc.b    $03,$04,$04,$04,$04,$03,$03,$03,$03,$02,$01,$01,$01,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff
        dc.b    $00,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$03,$03,$03,$02
        dc.b    $02,$01,$01,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe
        dc.b    $fe,$fe,$ff,$ff,$ff,$ff,$00,$01,$01,$01,$02,$02,$03,$03,$03,$03
        dc.b    $03,$04,$03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$01,$01
        dc.b    $02,$02,$02,$03,$03,$03,$03,$04,$03,$03,$03,$03,$02,$02,$01,$01
        dc.b    $00,$00,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff
        dc.b    $ff,$ff,$ff,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$03,$03,$03
        dc.b    $03,$03,$02,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$fe,$fe
        dc.b    $fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$01,$01,$02,$02,$02
        dc.b    $03,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$00
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$ff,$fe,$fe,$ff,$ff,$ff
        dc.b    $00,$00,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$02
        dc.b    $02,$02,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$fe,$ff
        dc.b    $fe,$ff,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$01,$02,$01,$02,$02,$03
        dc.b    $03,$03,$03,$03,$03,$03,$02,$02,$01,$01,$01,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$fe,$ff,$fe,$fe,$ff,$ff,$ff,$ff,$ff,$00,$00,$01
        dc.b    $01,$01,$01,$01,$02,$02,$03,$03,$03,$03,$03,$03,$03,$02,$02,$01
        dc.b    $01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$fe,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$00,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03
        dc.b    $03,$03,$03,$02,$02,$01,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$fe
        dc.b    $fe,$fe,$fe,$fe,$fe,$fe,$fe,$ff,$ff,$ff,$00,$00,$01,$01,$01,$02
        dc.b    $02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$02,$02,$01,$01,$01,$00
        dc.b    $00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$00,$00,$01,$01,$01,$01,$01,$02,$02,$03,$03,$03,$03,$03,$03
        dc.b    $02,$02,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$01,$01,$01,$02,$02
        dc.b    $02,$02,$03,$03,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00
        dc.b    $01,$01,$01,$01,$01,$01,$02,$02,$02,$03,$03,$03,$03,$02,$02,$01
        dc.b    $01,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02
        dc.b    $03,$03,$03,$02,$02,$02,$01,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$fe,$ff,$fe,$ff,$ff,$ff,$ff,$00,$00,$00,$01,$01,$01
        dc.b    $01,$01,$01,$02,$02,$02,$03,$03,$03,$02,$02,$02,$02,$01,$01,$01
        dc.b    $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$03,$02
        dc.b    $02,$02,$02,$01,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02
        dc.b    $02,$02,$02,$02,$03,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$01
        dc.b    $01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02
        dc.b    $02,$02,$02,$02,$02,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$00
        dc.b    $00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00
        dc.b    $00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02
        dc.b    $02,$01,$01,$01,$01,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$02,$02,$02,$02,$02,$02,$01,$01,$01,$00,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$00,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$01,$01,$01
        dc.b    $01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02
        dc.b    $02,$02,$01,$01,$01,$01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00
        dc.b    $00,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$ff,$ff,$00,$00,$00,$01,$01
        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$01,$01,$01
        dc.b    $01,$01,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        dc.b    $01,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00,$00,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        dc.b    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; ---------------------------------------------------------------------------
; Part 2: Player Engine & Variables ($7E000 - $7FFFF)
; ---------------------------------------------------------------------------

; ===========================================================================
; Initialize player entry point.
; ; Configures CIA-B Timer A interrupts and replaces Level 6 IRQ vector.
; ===========================================================================
music_player_init_src:
        bsr.w   music_sub_init_channels_src     ; Initialize active channel sequencer records and arrangement loop vectors
        move.b  #$3a,$bfd700                    ; Stop CIA-B Timer A to allow safe interval count reload
        move.b  #$0,$bfd600                     ; Clear CIA-B Timer A high byte counter register
        move.b  #$7d,$bfdd00                    ; Set CIA-B Timer A low byte counter to $7D (125 ticks)
        move.b  #$82,$bfdd00                    ; Enable CIA-B Timer A interrupt and start the timer
        move.b  #$2f,$bfdf00                    ; Configure CIA-B Timer B control register for one-shot mode
        move.b  #$81,$bfdf00                    ; Enable CIA-B Timer B interrupt execution
        move.l  $78,music_var_old_level6        ; Backup original Level 6 interrupt vector pointer
        move.l  #music_vblank_handler,$78       ; Install custom sound interrupt handler into Level 6 autovector
        rts                                     ; Return from sound player initialization routine
; ===========================================================================
; Stop player entry point.
; ; Disables Timer A interrupts and restores Level 6 autovector.
; ===========================================================================
music_player_stop_src:
        move.b  #$1,$bfdf00                     ; Disable CIA-B Timer B hardware interrupts
        move.l  music_var_old_level6,$78        ; Restore the original system Level 6 interrupt vector pointer
        move.w  #$f,$dff096                     ; Disable voice DMA channels on Paula to halt audio output
        rts                                     ; Return from stop routine
; ===========================================================================
; CIA Timer A interrupt handler.
; ; Replaces the Level 6 interrupt to run high-frequency synthesis ticks.
; ===========================================================================
music_vblank_handler_src:
        bsr.w   music_sub_mixer_tick_src        ; Process active sound voice synthesizers and mixing step
        jmp     KICKSTART_LEVEL6_EXIT           ; Exit interrupt handler and jump to system Level 6 exit
; ===========================================================================
; Main sequencer and ADSR processing tick handler.
; ===========================================================================
music_sub_play_tick_src:
        lea.l   music_channel_1_state,a1        ; Load address of Channel 1 synth state block into A1
        jsr     music_sub_update_synth          ; Call synthesizer voice routing and setup subroutine
        cmpi.w  #$3,$1c(a1)                     ; Check if channel synthesizer command is #3 (pitch envelope)
        beq.w   music_sub_freq_calc_voice_src   ; Branch to pitch calculation subroutine if equal
        cmpi.w  #$c,$1c(a1)                     ; Check if channel synthesizer command is #12 (volume decay)
        beq.w   music_sub_adsr_process_src      ; Branch to volume decay envelope subroutine if equal
        cmpi.w  #$1,$1c(a1)                     ; Check if channel synthesizer command is #1 (hardware DMA trigger)
        beq.w   music_sub_channel_play_src      ; Branch to DMA trigger processor if equal
        rts                                     ; Return from exception or voice tick handler
; ===========================================================================
; Process sound play state and update volume/period DMA.
; ===========================================================================
music_sub_channel_play_src:
        move.l  $18(a1),d0                      ; Load channel hardware voice bitmask into D0
        move.w  d0,$dff096                      ; Write voice DMA mask to Paula to start sample playback
        move.l  #$96,d1                         ; Set loop delay counter to 150 iterations
; ===========================================================================
; Timing delay loop for voice updates.
; ===========================================================================
music_sub_channel_loop_src:
        clr.w   $a(a6)                          ; Clear Paula voice audio register data slot
        dbra    d1,music_sub_channel_loop_src   ; Decrement counter and spin delay loop to sync hardware DMA
        rts                                     ; Return from DMA voice trigger subroutine
; ===========================================================================
; Determine oscillator pitch frequency word for a channel.
; ===========================================================================
music_sub_freq_calc_voice_src:
        move.l  $18(a1),d0                      ; Load voice DMA bitmask from state block
        ori.w   #$8000,d0                       ; Set the DMA set/clear bit to enable register writes
        move.l  $26(a1),d1                      ; Load target period frequency offset from state block
        lsr.l   #$1,d1                          ; Divide period offset by 2 for voice frequency scaling
        move.w  d1,$4(a6)                       ; Write frequency period word to voice register
        move.l  $22(a1),(a6)                    ; Write voice sample start pointer to Paula custom address
        move.w  d0,$dff096                      ; Write voice DMA enable mask to start hardware voice play
        rts                                     ; Return from pitch frequency calculation subroutine
; ===========================================================================
; Process ADSR volume envelope transitions.
; ===========================================================================
music_sub_adsr_process_src:
        move.w  $2c(a1),$8(a6)                  ; Write envelope volume value to Paula audio channel volume register
        move.w  $2a(a1),$6(a6)                  ; Write envelope sample length to Paula audio channel length register
        rts                                     ; Return from envelope processing subroutine
; ===========================================================================
; Real-time software sound synthesis engine update.
; ; Modulates frequencies, LFO, envelopes, and pulse-width.
; ===========================================================================
music_sub_update_synth_src:
        lea.l   $dff0a0,a6                      ; Load Paula Voice 0 register base address ($dff0a0) into A6
        cmpi.l  #$1,$18(a1)                     ; Check if channel voice selection bitmask is #1 (Voice 0)
        beq.w   music_sub_synth_exit_src        ; Branch to synthesis routing exit if Voice 0 is target
        lea.l   $dff0b0,a6                      ; Load Paula Voice 1 register base address ($dff0b0) into A6
        cmpi.l  #$2,$18(a1)                     ; Check if channel voice selection bitmask is #2 (Voice 1)
        beq.w   music_sub_synth_exit_src        ; Branch to synthesis routing exit if Voice 1 is target
        lea.l   $dff0c0,a6                      ; Load Paula Voice 2 register base address ($dff0c0) into A6
        cmpi.l  #$4,$18(a1)                     ; Check if channel voice selection bitmask is #4 (Voice 2)
        beq.w   music_sub_synth_exit_src        ; Branch to synthesis routing exit if Voice 2 is target
        lea.l   $dff0d0,a6                      ; Load Paula Voice 3 register base address ($dff0d0) into A6
music_sub_synth_exit_src:
        rts                                     ; Return from synthesizer voice routing subroutine
; ===========================================================================
; Master mixer volume scale multiplier.
; ===========================================================================
music_mixer_volume_src:
        dc.w    $0000           ; Master mixer volume scale multiplier
        dc.w    $0000           ; Master mixer volume balance modifier
; ===========================================================================
; Channel 1 synth and ADSR state variables block.
; ; ---------------------------------------------------------------------------
; ; Synthesizer & ADSR Voice State Block Structure (Size: 76 bytes / 38 words)
; ; ---------------------------------------------------------------------------
; ; Offset (dec)  Type   Description
; ;  +0 (0x00)    word   Oscillator active waveform type / flags
; ;  +2 (0x02)    word   Current pitch frequency base period
; ;  +4 (0x04)    word   Pitch modulation envelope counter/index
; ;  +6 (0x06)    word   Low-Frequency Oscillator (LFO) vibrato offset
; ;  +8 (0x08)    word   Envelope volume ADSR state phase index
; ;  +10 (0x0a)   word   Envelope volume slide rate / delta
; ;  +12 (0x0c)   word   Wavetable synthesis sample read step increment
; ;  +14 (0x0e)   word   Pulse-width modulation (PWM) active duty cycle
; ;  +16 (0x10)   word   Stereo panning balance coefficient index
; ;  +18 (0x12)   word   Synthesizer master scale frequency multiplier
; ;  +20 (0x14)   word   Active vibrato speed / modulation depth
; ;  +22 (0x16)   word   Pitch sweep rate multiplier (pitch slide delta)
; ;  +24 (0x18)   long   Paula hardware Voice allocation bitmask ($1, $2, $4, $8)
; ;  +28 (0x1c)   word   Synthesizer routing status / command byte (0=stop, 1=init, 3=note, 12=decay)
; ;  +30 (0x1e)   byte   Synthesizer LFO phase register counter
; ;  +34 (0x22)   long   Active voice audio sample buffer memory start address pointer
; ;  +38 (0x26)   long   Calculated pitch lookup voice frequency target period
; ;  +42 (0x2a)   word   Paula audio Voice length repeat register value
; ;  +44 (0x2c)   word   Paula audio Voice volume envelope attenuation value (0 to 64)
; ;  +46 (0x2e)   word   Arpeggio pitch volume decay multiplier / ADSR start volume
; ; ---------------------------------------------------------------------------
; ===========================================================================
music_channel_1_state_src:
        dc.w    $0000           ; Oscillator active waveform type / flags
        dc.w    $0000           ; Current pitch frequency base period
        dc.w    $0000           ; Pitch modulation envelope counter/index
        dc.w    $0000           ; Low-Frequency Oscillator (LFO) vibrato offset
        dc.w    $0000           ; Envelope volume ADSR state phase index
        dc.w    $0000           ; Envelope volume slide rate / delta
        dc.w    $0000           ; Wavetable synthesis sample read step increment
        dc.w    $0000           ; Pulse-width modulation (PWM) active duty cycle
        dc.w    $0000           ; Stereo panning balance coefficient index
        dc.w    $0000           ; Synthesizer master scale frequency multiplier
        dc.w    $0000           ; Active vibrato speed / modulation depth
        dc.w    $0000           ; Pitch sweep rate multiplier (pitch slide delta)
        dc.l    $8                     ; Paula hardware Voice allocation bitmask ($1, $2, $4, $8)
        dc.w    $000c           ; Synthesizer routing status / command byte (0=stop, 1=init, 3=note, 12=decay)
        dc.w    $0000           ; Synthesizer LFO phase register counter
        dc.w    $0000           ; Reserved / pad state variables
        dc.l    music_synth_presets    ; Active voice audio sample buffer memory start address pointer
        dc.l    $3600                  ; Calculated pitch lookup voice frequency target period
        dc.w    $00e2           ; Paula audio Voice length repeat register value
        dc.w    $0040           ; Paula audio Voice volume envelope attenuation value (0 to 64)
        dc.w    $0001           ; Arpeggio pitch volume decay multiplier / ADSR start volume
        dc.w    $0000           ; Channel 1 state pad offset +48
        dc.w    $0000           ; Channel 1 state pad offset +50
        dc.w    $0000           ; Channel 1 state pad offset +52
        dc.w    $0000           ; Channel 1 state pad offset +54
        dc.w    $0000           ; Channel 1 state pad offset +56
        dc.w    $0000           ; Channel 1 state pad offset +58
        dc.w    $0000           ; Channel 1 state pad offset +60
        dc.w    $0000           ; Channel 1 state pad offset +62
        dc.w    $0000           ; Channel 1 state pad offset +64
        dc.w    $0000           ; Channel 1 state pad offset +66
        dc.w    $0000           ; Channel 1 state pad offset +68
        dc.w    $0000           ; Channel 1 state pad offset +70
        dc.w    $0000           ; Channel 1 state pad offset +72
        dc.w    $0000           ; Channel 1 state pad offset +74
; ===========================================================================
; Channel 1 sequencing and track variables block.
; ; ---------------------------------------------------------------------------
; ; Sequencer & Track Variable Block Structure (Size: 60 bytes / 30 words)
; ; ---------------------------------------------------------------------------
; ; Offset (dec)  Type   Description
; ;  +0 (0x00)    long   Active instrument preset base pointer address (preset parameters)
; ;  +4 (0x04)    word   Sequencer timing delay tick countdown (triggers next event when 0)
; ;  +6 (0x06)    long   Active sequence pattern note read pointer (tracks note bytes)
; ;  +10 (0x0a)   long   Sequence pattern track definitions table start pointer
; ;  +14 (0x0e)   long   Sequence pattern track loop restart address pointer
; ;  +18 (0x12)   long   Active sequence pattern instrument/wavetable synth block pointer
; ;  +22 (0x16)   word   Active wave arpeggio command index counter
; ;  +24 (0x18)   word   Current sequence wave table size length limits
; ;  +26 (0x1a)   word   Current active arpeggio step counter / wave note index
; ;  +28 (0x1c)   long   Active wave arpeggio offset table memory pointer
; ;  +32 (0x20)   long   Channel hardwired Paula Voice allocation bitmask (Voice 0=1, 1=2, 2=4, 3=8)
; ; ---------------------------------------------------------------------------
; ===========================================================================
music_channel_1_vars_src:
        dc.l    music_var_7e958        ; Channel 1 Active instrument preset base pointer address
        dc.w    $0009           ; Channel 1 Sequencer timing delay tick countdown
        dc.l    music_var_7e9ce        ; Channel 1 Active sequence pattern note read pointer
        dc.l    music_var_7e748        ; Channel 1 Sequence pattern track definitions table start pointer
        dc.l    music_sequence_loop_1  ; Channel 1 Sequence pattern track loop restart address pointer
        dc.l    $4                     ; Channel 1 Active sequence pattern instrument/wavetable synth block pointer
        dc.w    $0000           ; Channel 1 Active wave arpeggio command index counter
        dc.w    $0000           ; Channel 1 Current sequence wave table size length limits
        dc.w    $0000           ; Channel 1 Current active arpeggio step counter / wave note index
        dc.l    $0                     ; Channel 1 Active wave arpeggio offset table memory pointer
        dc.l    $1                     ; Channel 1 Channel hardwired Paula Voice allocation bitmask (Voice 0=1, 1=2, 2=4, 3=8)
        dc.w    $0000           ; Channel 1 sequencer pad offset +36
        dc.w    $0000           ; Channel 1 sequencer pad offset +38
        dc.w    $0000           ; Channel 1 sequencer pad offset +40
        dc.w    $0000           ; Channel 1 sequencer pad offset +42
        dc.w    $0000           ; Channel 1 sequencer pad offset +44
        dc.w    $0000           ; Channel 1 sequencer pad offset +46
        dc.w    $0000           ; Channel 1 sequencer pad offset +48
        dc.w    $0000           ; Channel 1 sequencer pad offset +50
        dc.w    $0000           ; Channel 1 sequencer pad offset +52
        dc.w    $0000           ; Channel 1 sequencer pad offset +54
        dc.w    $0000           ; Channel 1 sequencer pad offset +56
        dc.w    $0000           ; Channel 1 sequencer pad offset +58
; ===========================================================================
; Channel 2 sequencing and track variables block.
; ; [Structurally identical layout to Channel 1 sequencing block at $7e170]
; ===========================================================================
music_channel_2_vars_src:
        dc.l    music_var_7e988        ; Channel 2 Active instrument preset base pointer address
        dc.w    $0004           ; Channel 2 Sequencer timing delay tick countdown
        dc.l    music_var_7ea2c        ; Channel 2 Active sequence pattern note read pointer
        dc.l    music_var_7e858        ; Channel 2 Sequence pattern track definitions table start pointer
        dc.l    music_sequence_loop_2  ; Channel 2 Sequence pattern track loop restart address pointer
        dc.l    $0                     ; Channel 2 Active sequence pattern instrument/wavetable synth block pointer
        dc.w    $0000           ; Channel 2 Active wave arpeggio command index counter
        dc.w    $0000           ; Channel 2 Current sequence wave table size length limits
        dc.w    $0000           ; Channel 2 Current active arpeggio step counter / wave note index
        dc.l    $0                     ; Channel 2 Active wave arpeggio offset table memory pointer
        dc.l    $2                     ; Channel 2 Channel hardwired Paula Voice allocation bitmask (Voice 0=1, 1=2, 2=4, 3=8)
        dc.w    $0000           ; Channel 2 sequencer pad offset +36
        dc.w    $0000           ; Channel 2 sequencer pad offset +38
        dc.w    $0000           ; Channel 2 sequencer pad offset +40
        dc.w    $0000           ; Channel 2 sequencer pad offset +42
        dc.w    $0000           ; Channel 2 sequencer pad offset +44
        dc.w    $0000           ; Channel 2 sequencer pad offset +46
        dc.w    $0000           ; Channel 2 sequencer pad offset +48
        dc.w    $0000           ; Channel 2 sequencer pad offset +50
        dc.w    $0000           ; Channel 2 sequencer pad offset +52
        dc.w    $0000           ; Channel 2 sequencer pad offset +54
        dc.w    $0000           ; Channel 2 sequencer pad offset +56
        dc.w    $0000           ; Channel 2 sequencer pad offset +58
; ===========================================================================
; Channel 3 sequencing and track variables block.
; ; [Structurally identical layout to Channel 1 sequencing block at $7e170]
; ===========================================================================
music_channel_3_vars_src:
        dc.l    music_var_7e9a0        ; Channel 3 Active instrument preset base pointer address
        dc.w    $000e           ; Channel 3 Sequencer timing delay tick countdown
        dc.l    music_var_7ed18        ; Channel 3 Active sequence pattern note read pointer
        dc.l    music_var_7e8a0        ; Channel 3 Sequence pattern track definitions table start pointer
        dc.l    music_sequence_loop_3  ; Channel 3 Sequence pattern track loop restart address pointer
        dc.l    $0                     ; Channel 3 Active sequence pattern instrument/wavetable synth block pointer
        dc.w    $0001           ; Channel 3 Active wave arpeggio command index counter
        dc.w    $0003           ; Channel 3 Current sequence wave table size length limits
        dc.w    $0000           ; Channel 3 Current active arpeggio step counter / wave note index
        dc.l    music_var_7ed12        ; Channel 3 Active wave arpeggio offset table memory pointer
        dc.l    $4                     ; Channel 3 Channel hardwired Paula Voice allocation bitmask (Voice 0=1, 1=2, 2=4, 3=8)
        dc.w    $0000           ; Channel 3 sequencer pad offset +36
        dc.w    $0000           ; Channel 3 sequencer pad offset +38
        dc.w    $0000           ; Channel 3 sequencer pad offset +40
        dc.w    $0000           ; Channel 3 sequencer pad offset +42
        dc.w    $0000           ; Channel 3 sequencer pad offset +44
        dc.w    $0000           ; Channel 3 sequencer pad offset +46
        dc.w    $0000           ; Channel 3 sequencer pad offset +48
        dc.w    $0000           ; Channel 3 sequencer pad offset +50
        dc.w    $0000           ; Channel 3 sequencer pad offset +52
        dc.w    $0000           ; Channel 3 sequencer pad offset +54
        dc.w    $0000           ; Channel 3 sequencer pad offset +56
        dc.w    $0000           ; Channel 3 sequencer pad offset +58
; ===========================================================================
; Channel 4 sequencing and track variables block.
; ; [Structurally identical layout to Channel 1 sequencing block at $7e170]
; ===========================================================================
music_channel_4_vars_src:
        dc.l    music_var_7e9a0        ; Channel 4 Active instrument preset base pointer address
        dc.w    $000e           ; Channel 4 Sequencer timing delay tick countdown
        dc.l    music_var_7ed18        ; Channel 4 Active sequence pattern note read pointer
        dc.l    music_var_7e8f8        ; Channel 4 Sequence pattern track definitions table start pointer
        dc.l    music_sequence_loop_4  ; Channel 4 Sequence pattern track loop restart address pointer
        dc.l    $0                     ; Channel 4 Active sequence pattern instrument/wavetable synth block pointer
        dc.w    $0001           ; Channel 4 Active wave arpeggio command index counter
        dc.w    $0003           ; Channel 4 Current sequence wave table size length limits
        dc.w    $0002           ; Channel 4 Current active arpeggio step counter / wave note index
        dc.l    music_var_7ed12        ; Channel 4 Active wave arpeggio offset table memory pointer
        dc.l    $8                     ; Channel 4 Channel hardwired Paula Voice allocation bitmask (Voice 0=1, 1=2, 2=4, 3=8)
        dc.w    $0000           ; Channel 4 sequencer pad offset +36
        dc.w    $0000           ; Channel 4 sequencer pad offset +38
        dc.w    $0000           ; Channel 4 sequencer pad offset +40
        dc.w    $0000           ; Channel 4 sequencer pad offset +42
        dc.w    $0000           ; Channel 4 sequencer pad offset +44
        dc.w    $0000           ; Channel 4 sequencer pad offset +46
        dc.w    $0000           ; Channel 4 sequencer pad offset +48
        dc.w    $0000           ; Channel 4 sequencer pad offset +50
        dc.w    $0000           ; Channel 4 sequencer pad offset +52
        dc.w    $0000           ; Channel 4 sequencer pad offset +54
        dc.w    $0000           ; Channel 4 sequencer pad offset +56
        dc.w    $0000           ; Channel 4 sequencer pad offset +58
; ===========================================================================
; Sequencer tick and sync pulse counter.
; ===========================================================================
music_vblank_counter_src:
        dc.w    $01fc           ; VBlank tick counter / system synchronization pulse
        dc.w    $01e0           ; Sequencer sync active pulse flag
        dc.w    $01c5           ; Variable offset $0264
        dc.w    $01ac           ; Variable offset $0266
        dc.w    $0194           ; Variable offset $0268
        dc.w    $017d           ; Variable offset $026a
        dc.w    $0168           ; Variable offset $026c
        dc.w    $0153           ; Variable offset $026e
        dc.w    $0140           ; Variable offset $0270
        dc.w    $012e           ; Variable offset $0272
        dc.w    $011d           ; Variable offset $0274
        dc.w    $010d           ; Variable offset $0276
        dc.w    $00fe           ; Variable offset $0278
        dc.w    $00f0           ; Variable offset $027a
        dc.w    $00e2           ; Variable offset $027c
        dc.w    $00d6           ; Variable offset $027e
        dc.w    $00ca           ; Variable offset $0280
        dc.w    $00be           ; Variable offset $0282
        dc.w    $00b4           ; Variable offset $0284
        dc.w    $00aa           ; Variable offset $0286
        dc.w    $00a0           ; Variable offset $0288
        dc.w    $0097           ; Variable offset $028a
        dc.w    $008f           ; Variable offset $028c
        dc.w    $0087           ; Variable offset $028e
        dc.w    $007f           ; Variable offset $0290
; ===========================================================================
; Reset and initialize channel memory registers and reload sequence lists.
; ===========================================================================
music_sub_init_channels_src:
        lea.l   music_channel_1_vars,a0         ; Load Channel 1 sequencer block ($7e170) into A0
        move.l  #music_sequence_table_1,$a(a0)  ; Load Channel 1 track sequence pointer start address ($7e658)
        move.l  #music_sequence_loop_1,$e(a0)   ; Load Channel 1 track sequence loop restart address ($7e6d8)
        clr.w   $16(a0)                         ; Reset Channel 1 pattern command counter index
        movea.l $a(a0),a1                       ; Load Channel 1 arrangement tracking list address into A1
        move.l  (a1),$6(a0)                     ; Copy Track 1 sequence pattern pointer to sequencer state
        move.l  $4(a1),$12(a0)                  ; Copy Track 1 synth block data pointer to sequencer state
        move.w  #$1,$4(a0)                      ; Set Channel 1 sequence timing delay tick count to 1
        move.l  #$1,$20(a0)                     ; Configure Channel 1 voice allocation bitmask (Voice 0)
        lea.l   music_channel_2_vars,a0         ; Load Channel 2 sequencer block ($7e1ac) into A0
        move.l  #music_sequence_table_2,$a(a0)  ; Load Channel 2 track sequence pointer start address ($7e840)
        move.l  #music_sequence_loop_2,$e(a0)   ; Load Channel 2 track sequence loop restart address ($7e848)
        clr.w   $16(a0)                         ; Reset Channel 2 pattern command counter index
        movea.l $a(a0),a1                       ; Load Channel 2 arrangement tracking list address into A1
        move.l  (a1),$6(a0)                     ; Copy Track 2 sequence pattern pointer to sequencer state
        move.l  $4(a1),$12(a0)                  ; Copy Track 2 synth block data pointer to sequencer state
        move.w  #$1,$4(a0)                      ; Set Channel 2 sequence timing delay tick count to 1
        move.l  #$2,$20(a0)                     ; Configure Channel 2 voice allocation bitmask (Voice 1)
        lea.l   music_channel_3_vars,a0         ; Load Channel 3 sequencer block ($7e1e8) into A0
        move.l  #music_sequence_table_3,$a(a0)  ; Load Channel 3 track sequence pointer start address ($7e870)
        move.l  #music_sequence_loop_3,$e(a0)   ; Load Channel 3 track sequence loop restart address ($7e888)
        clr.w   $16(a0)                         ; Reset Channel 3 pattern command counter index
        movea.l $a(a0),a1                       ; Load Channel 3 arrangement tracking list address into A1
        move.l  (a1),$6(a0)                     ; Copy Track 3 sequence pattern pointer to sequencer state
        move.l  $4(a1),$12(a0)                  ; Copy Track 3 synth block data pointer to sequencer state
        move.w  #$1,$4(a0)                      ; Set Channel 3 sequence timing delay tick count to 1
        move.l  #$4,$20(a0)                     ; Configure Channel 3 voice allocation bitmask (Voice 2)
        lea.l   music_channel_4_vars,a0         ; Load Channel 4 sequencer block ($7e224) into A0
        move.l  #music_sequence_table_4,$a(a0)  ; Load Channel 4 track sequence pointer start address ($7e8d0)
        move.l  #music_sequence_loop_4,$e(a0)   ; Load Channel 4 track sequence loop restart address ($7e8e0)
        clr.w   $16(a0)                         ; Reset Channel 4 pattern command counter index
        movea.l $a(a0),a1                       ; Load Channel 4 arrangement tracking list address into A1
        move.l  (a1),$6(a0)                     ; Copy Track 4 sequence pattern pointer to sequencer state
        move.l  $4(a1),$12(a0)                  ; Copy Track 4 synth block data pointer to sequencer state
        move.w  #$1,$4(a0)                      ; Set Channel 4 sequence timing delay tick count to 1
        move.l  #$8,$20(a0)                     ; Configure Channel 4 voice allocation bitmask (Voice 3)
        rts                                     ; Return from active channels initialization subroutine
; ===========================================================================
; Main real-time mixer tick routine.
; ; Calculates and mixes active digital voices into Paula buffers.
; ===========================================================================
music_sub_mixer_tick_src:
        movem.l d0-d7/a0-a6,-(a7)               ; Push working registers D0-D7/A0-A6 onto the stack
        lea.l   $dff0a0,a6                      ; Load Paula Voice 0 register base address ($dff0a0) into A6
        move.w  #$1,$4(a6)                      ; Set Voice 0 synthesizer command status byte to 1 (initiate voice play)
        move.l  #music_mixer_volume,(a6)        ; Set Voice 0 master mixer volume scale multiplier pointer address ($7e120)
        lea.l   $dff0b0,a6                      ; Load Paula Voice 1 register base address ($dff0b0) into A6
        move.w  #$1,$4(a6)                      ; Set Voice 1 synthesizer command status byte to 1 (initiate voice play)
        move.l  #music_mixer_volume,(a6)        ; Set Voice 1 master mixer volume scale multiplier pointer address ($7e120)
        lea.l   $dff0c0,a6                      ; Load Paula Voice 2 register base address ($dff0c0) into A6
        move.w  #$1,$4(a6)                      ; Set Voice 2 synthesizer command status byte to 1 (initiate voice play)
        move.l  #music_mixer_volume,(a6)        ; Set Voice 2 master mixer volume scale multiplier pointer address ($7e120)
        lea.l   $dff0d0,a6                      ; Load Paula Voice 3 register base address ($dff0d0) into A6
        move.w  #$1,$4(a6)                      ; Set Voice 3 synthesizer command status byte to 1 (initiate voice play)
        move.l  #music_mixer_volume,(a6)        ; Set Voice 3 master mixer volume scale multiplier pointer address ($7e120)
        move.l  #$0,d7                          ; Initialize panning tick scaling value to 0
        lea.l   music_channel_1_vars,a0         ; Load Channel 1 sequencer variable block ($7e170) into A0
        bsr.w   music_sub_channel_tick_src      ; Call sequencer channel tick processor subroutine
        move.l  #$3,d7                          ; Set panning tick scaling value to 3 (right panning balance offset)
        lea.l   music_channel_2_vars,a0         ; Load Channel 2 sequencer variable block ($7e1ac) into A0
        bsr.w   music_sub_channel_tick_src      ; Call sequencer channel tick processor subroutine
        move.l  #$0,d7                          ; Set panning tick scaling value to 0 (left panning balance offset)
        lea.l   music_channel_3_vars,a0         ; Load Channel 3 sequencer variable block ($7e1e8) into A0
        bsr.w   music_sub_channel_tick_src      ; Call sequencer channel tick processor subroutine
        move.l  #$0,d7                          ; Set panning tick scaling value to 0
        lea.l   music_channel_4_vars,a0         ; Load Channel 4 sequencer variable block ($7e224) into A0
        bsr.w   music_sub_channel_tick_src      ; Call sequencer channel tick processor subroutine
        movem.l (a7)+,d0-d7/a0-a6               ; Pop and restore saved registers D0-D7/A0-A6 from the stack
        rts                                     ; Return from software mixer tick routine
; ===========================================================================
; Process sequencer patterns and arrangement instructions.
; ===========================================================================
music_sub_channel_tick_src:
        subq.w  #$1,$4(a0)                      ; Decrement channel sequencing delay tick counter by 1
        bne.w   music_sub_channel_exit_src      ; Branch to sequencer exit if active delays are still pending
        clr.w   $16(a0)                         ; Clear channel sequencer command flag before fetching new pattern step
; ===========================================================================
; Fetch next sequence pattern list instruction.
; ===========================================================================
music_sub_next_pattern_src:
        movea.l $6(a0),a1                       ; Load current sequence pattern pointer address into A1
        tst.w   (a1)                            ; Test if pattern instruction command word is 0 (end of pattern)
        bne.w   music_sub_check_command_src     ; Branch if pattern command is not 0 (process valid command word)
        addi.l  #$8,$a(a0)                      ; Add 8 to arrangement sequence table pointer (step to next track sequence entry)
; ===========================================================================
; Load track sequence arrangement pointers.
; ===========================================================================
music_sub_load_track_src:
        movea.l $a(a0),a1                       ; Load current arrangement sequence table entry pointer into A1
        tst.l   (a1)                            ; Test if the arrangement entry pointer is null (end of arrangement list)
        bne.w   music_sub_read_sequence_src     ; Branch if not null (valid next pattern entry to read)
        move.l  $e(a0),$a(a0)                   ; Reload sequence table starting offset pointer (loop arrangement list)
        bra.w   music_sub_load_track_src        ; Branch unconditionally to reload the new track sequence pointer
; ===========================================================================
; Read sequence table values and transition patterns.
; ===========================================================================
music_sub_read_sequence_src:
        move.l  (a1),$6(a0)                     ; Load current pattern note pointer address from sequence track definition
        move.l  $4(a1),$12(a0)                  ; Load pattern synthesizer block data pointer from sequence track definition
        bra.w   music_sub_next_pattern_src      ; Branch unconditionally to process pattern step
; ===========================================================================
; Check for instrument, arpeggio, or pitch modulation commands.
; ===========================================================================
music_sub_check_command_src:
        cmpi.w  #$80,(a1)                       ; Test if pattern command word is $80 (set instrument sound presets)
        bne.w   music_sub_parse_note_src        ; Branch if not $80 (check other pattern command flags)
        move.l  $2(a1),$0(a0)                   ; Load synthesizer instrument presets data pointer address
        addi.l  #$6,$6(a0)                      ; Advance pattern note pointer by 6 bytes (step over instrument select block)
        bra.w   music_sub_next_pattern_src      ; Branch unconditionally to process next pattern command word
; ===========================================================================
; Decode and parse a musical note trigger.
; ===========================================================================
music_sub_parse_note_src:
        cmpi.w  #$81,(a1)                       ; Test if pattern command word is $81 (parse dynamic wave arpeggio)
        bne.w   music_sub_set_frequency_src     ; Branch if not $81 (check for standard musical note trigger)
        addq.w  #$1,$16(a0)                     ; Increment channel sequencer command flag index counter
        move.w  $4(a1),$18(a0)                  ; Copy current sequence wave table length value into sequencer block
        clr.w   $1c(a0)                         ; Clear synthesizer relative vibrato command index counter
        move.w  $2(a1),$4(a0)                   ; Copy wave arpeggio tick speed value to channel timing register
        lea.l   $6(a1),a2                       ; Load address of arpeggio wave table offset records into A2
        move.l  a2,$1c(a0)                      ; Store active wave table offset address in channel block
        clr.l   d0                              ; Clear data register D0 for calculation
        move.w  $18(a0),d0                      ; Load wave arpeggio list size length word into D0
        addi.l  #$3,d0                          ; Add 3 to the length word to include header offset bytes
        mulu.w  #$2,d0                          ; Multiply by 2 for word scaling offset calculation
        add.l   d0,$6(a0)                       ; Advance current pattern note pointer by calculated arpeggio stride
        lea.l   music_channel_1_state,a2        ; Load address of Channel 1 synth state block into A2
        move.l  $20(a0),$18(a2)                 ; Write voice bitmask into synthesizer state allocation slot
        move.w  #$1,$1c(a2)                     ; Set voice synthesizer command status byte to 1 (initiate arpeggio setup)
        clr.b   $1e(a2)                         ; Clear synthesizer LFO phase modulation counter register
        movem.l a0-a1,-(a7)                     ; Save current state pointers A0-A1 onto the stack
        bsr.w   music_sub_play_tick_src         ; Call main synthesizer voice routing and setup subroutine
        movem.l (a7)+,a0-a1                     ; Pop and restore active sequencer state pointers A0-A1
        lea.l   music_channel_1_state,a2        ; Load address of Channel 1 synth state block into A2
        move.l  $20(a0),$18(a2)                 ; Write voice bitmask into synthesizer state allocation slot
        move.w  #$3,$1c(a2)                     ; Set voice synthesizer command status byte to 3 (process arpeggio envelope)
        clr.b   $1e(a2)                         ; Clear synthesizer LFO phase modulation counter register
        movea.l $0(a0),a3                       ; Load current instrument preset base pointer address into A3
        move.l  $2(a3),$26(a2)                  ; Copy wave vibrato speed pointer address into synth state
        move.l  $6(a3),$22(a2)                  ; Copy wave vibrato envelope pointer address into synth state
        move.w  $a(a3),$2e(a2)                  ; Copy wave arpeggio ADSR pitch volume word into synth state
        movem.l d1/a0-a3,-(a7)                  ; Save registers D1/A0-A3 onto the stack before voice setup call
        bsr.w   music_sub_play_tick_src         ; Call main synthesizer voice routing and setup subroutine
        movem.l (a7)+,d1/a0-a3                  ; Pop and restore saved registers D1/A0-A3 from the stack
        bra.w   music_sub_channel_exit_src      ; Branch unconditionally to exit sequencer channel tick routine
; ===========================================================================
; Determine and write hardware voice frequency values.
; ===========================================================================
music_sub_set_frequency_src:
        cmpi.w  #$82,(a1)                       ; Test if pattern command word is $82 (rest/pause command)
        bne.w   music_sub_update_envelope_src   ; Branch if not $82 (parse standard musical note and play pitch)
        move.w  $2(a1),$4(a0)                   ; Load rest tick length delay count from pattern note block
        addi.l  #$4,$6(a0)                      ; Advance current pattern note pointer by 4 bytes (step over rest block)
        lea.l   music_channel_1_state,a2        ; Load address of Channel 1 synth state block into A2
        move.l  $20(a0),$18(a2)                 ; Write voice bitmask into synthesizer state allocation slot
        move.w  #$1,$1c(a2)                     ; Set voice synthesizer command status byte to 1 (terminate voice)
        clr.b   $1e(a2)                         ; Clear synthesizer LFO phase modulation counter register
        movem.l a0-a1,-(a7)                     ; Save current state pointers A0-A1 onto the stack
        bsr.w   music_sub_play_tick_src         ; Call main synthesizer voice routing and setup subroutine
        movem.l (a7)+,a0-a1                     ; Pop and restore active sequencer state pointers A0-A1
        bra.w   music_sub_channel_exit_src      ; Branch unconditionally to exit sequencer channel tick routine
; ===========================================================================
; Update synthesizer envelopes and pitch slide registers.
; ===========================================================================
music_sub_update_envelope_src:
        lea.l   music_channel_1_state,a2        ; Load address of Channel 1 synth state block into A2
        move.l  $20(a0),$18(a2)                 ; Write voice bitmask into synthesizer state allocation slot
        move.w  #$1,$1c(a2)                     ; Set voice synthesizer command status byte to 1 (initiate note play)
        clr.b   $1e(a2)                         ; Clear synthesizer LFO phase modulation counter register
        movem.l a0-a1,-(a7)                     ; Save current state pointers A0-A1 onto the stack
        bsr.w   music_sub_play_tick_src         ; Call main synthesizer voice routing and setup subroutine
        movem.l (a7)+,a0-a1                     ; Pop and restore active sequencer state pointers A0-A1
        clr.l   d0                              ; Clear data register D0 for pitch calculation
        move.w  $2(a1),$4(a0)                   ; Load note play length tick delay count from pattern note block
        move.w  (a1),d0                         ; Load musical note octave / pitch index value into D0
        clr.l   d1                              ; Clear data register D1 for frequency table index lookup
        lea.l   music_vblank_counter,a2         ; Load base address of Pitch Frequency Lookup Table ($7e260) into A2
        add.l   $12(a0),d0                      ; Add active instrument synthesis wavetable offset value to note index
        add.l   d7,d0                           ; Add active voice panning balance offset to note index
        subi.l  #$1,d0                          ; Subtract 1 for zero-indexed frequency table alignment
        mulu.w  #$2,d0                          ; Multiply by 2 for word-indexed pitch offset scaling
        move.w  (a2,d0.l),d1                    ; Read note frequency period word from lookup table into D1
        lea.l   music_channel_1_state,a2        ; Load address of Channel 1 synth state block into A2
        move.l  $20(a0),$18(a2)                 ; Write voice bitmask into synthesizer state allocation slot
        move.w  #$3,$1c(a2)                     ; Set voice synthesizer command status byte to 3 (process note play)
        clr.b   $1e(a2)                         ; Clear synthesizer LFO phase modulation counter register
        movea.l $0(a0),a3                       ; Load active instrument preset data pointer address into A3
        move.l  $2(a3),$26(a2)                  ; Copy pitch slide envelope pointer address into synth state
        move.l  $6(a3),$22(a2)                  ; Copy vibrato delay LFO envelope pointer address into synth state
        move.w  $a(a3),$2e(a2)                  ; Copy instrument ADSR start volume word into synth state
        movem.l d1/a0-a3,-(a7)                  ; Save registers D1/A0-A3 onto the stack before setup call
        bsr.w   music_sub_play_tick_src         ; Call main synthesizer voice routing and setup subroutine
        movem.l (a7)+,d1/a0-a3                  ; Pop and restore saved registers D1/A0-A3 from the stack
        move.l  $20(a0),$18(a2)                 ; Write voice bitmask into synthesizer state allocation slot
; ===========================================================================
; Update sound channel volume envelopes.
; ===========================================================================
music_sub_volume_tick_src:
        move.w  #$c,$1c(a2)                     ; Set voice synthesizer command status byte to 12 (process decay volume)
        clr.b   $1e(a2)                         ; Clear synthesizer LFO phase modulation counter register
        move.w  d1,$2a(a2)                      ; Copy pitch lookup period frequency word into synth state
        move.w  $0(a3),$2c(a2)                  ; Copy instrument ADSR envelope release rate word into synth state
        movem.l d1/a0-a3,-(a7)                  ; Save registers D1/A0-A3 onto the stack before setup call
        bsr.w   music_sub_play_tick_src         ; Call main synthesizer voice routing and setup subroutine
        movem.l (a7)+,d1/a0-a3                  ; Pop and restore saved registers D1/A0-A3 from the stack
        addi.l  #$4,$6(a0)                      ; Advance current pattern note pointer by 4 bytes (step over note command)
; ===========================================================================
; Exit channel sequencer parsing routine.
; ===========================================================================
music_sub_channel_exit_src:
        tst.w   $16(a0)                         ; Test if channel wave arpeggio command index flag is active
        beq.w   music_sub_clear_registers_src   ; Branch if arpeggio command is 0 (exit sequencer voice tick)
        clr.l   d0                              ; Clear data register D0 for arpeggio step calculation
        move.w  $1a(a0),d0                      ; Load active wave arpeggio command index counter value into D0
        mulu.w  #$2,d0                          ; Multiply by 2 for word-scaled arpeggio table offset calculation
        clr.l   d1                              ; Clear data register D1 for arpeggio wave pitch read
        movea.l $1c(a0),a3                      ; Load address of arpeggio wave table offset values into A3
        move.w  (a3,d0.l),d1                    ; Read arpeggio wave pitch offset value from table into D1
        clr.l   d0                              ; Clear data register D0 for note lookup calculation
        lea.l   music_vblank_counter,a3         ; Load base address of Pitch Frequency Lookup Table ($7e260) into A3
        add.l   $12(a0),d1                      ; Add active instrument synthesis wavetable offset value to arpeggio pitch
        add.l   d7,d1                           ; Add active voice panning balance offset to arpeggio pitch
        subi.l  #$1,d1                          ; Subtract 1 for zero-indexed frequency table alignment
        mulu.w  #$2,d1                          ; Multiply by 2 for word-indexed pitch offset scaling
        move.w  (a3,d1.l),d0                    ; Read note frequency period word from lookup table into D0
        movea.l $0(a0),a3                       ; Load active instrument preset data pointer address into A3
        lea.l   music_channel_1_state,a2        ; Load address of Channel 1 synth state block into A2
        move.l  $20(a0),$18(a2)                 ; Write voice bitmask into synthesizer state allocation slot
        move.w  #$c,$1c(a2)                     ; Set voice synthesizer command status byte to 12 (process decay volume)
        clr.b   $1e(a2)                         ; Clear synthesizer LFO phase modulation counter register
        move.w  d0,$2a(a2)                      ; Copy arpeggio period frequency word into synth state
        move.w  $0(a3),$2c(a2)                  ; Copy instrument ADSR envelope release rate word into synth state
        movem.l a0-a3,-(a7)                     ; Save sequencer registers A0-A3 onto the stack
        bsr.w   music_sub_play_tick_src         ; Call main synthesizer voice routing and setup subroutine
        movem.l (a7)+,a0-a3                     ; Pop and restore active sequencer state pointers A0-A3
        clr.l   d0                              ; Clear data register D0 for counter update
        move.w  $1a(a0),d0                      ; Load active wave arpeggio command index counter value into D0
        addq.w  #$1,d0                          ; Increment arpeggio command index counter by 1
        cmp.w   $18(a0),d0                      ; Compare index counter with active wave table size limit
        bne.w   music_sub_mixer_exit_src        ; Branch if not equal (limit not reached, keep arpeggiator active)
        clr.l   d0                              ; Clear index counter to loop arpeggiator back to start
; ===========================================================================
; Exit software mixer tick subroutine.
; ===========================================================================
music_sub_mixer_exit_src:
        move.w  d0,$1a(a0)                      ; Save updated arpeggio index counter back to channel state
; ===========================================================================
; Clear Paula voice control hardware registers.
; ===========================================================================
music_sub_clear_registers_src:
        rts                                     ; Return from sequencer channel tick processor subroutine
; ===========================================================================
; Arrangement track sequence definitions list for Channel 1.
; ===========================================================================
music_sequence_table_1_src:
        dc.l    music_var_7e9ac           ; Entry 00 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 00 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 00 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 01 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 01 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 01 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 02 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 02 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 02 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 03 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 03 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 03 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 04 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 04 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 04 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 05 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 05 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 05 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 06 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 06 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 06 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 07 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 07 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 07 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 08 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 08 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 08 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 09 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 09 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 09 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 10 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 10 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 10 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 11 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 11 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 11 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 12 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 12 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 12 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 13 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 13 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 13 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 14 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 14 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 14 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 15 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 15 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 15 [offset +6]: Synthesizer instrument preset / envelope index
music_sequence_loop_1_src:
        dc.l    music_var_7e9ac           ; Entry 16 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 16 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 16 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 17 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 17 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 17 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 18 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 18 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 18 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 19 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 19 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 19 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 20 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 20 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 20 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 21 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 21 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 21 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 22 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 22 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 22 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 23 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 23 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 23 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 24 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 24 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 24 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 25 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 25 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 25 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 26 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 26 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 26 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 27 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 27 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 27 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 28 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 28 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $000e           ; Entry 28 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 29 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 29 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0009           ; Entry 29 [offset +6]: Synthesizer instrument preset / envelope index
music_var_7e748_src:
        dc.l    music_var_7e9ac           ; Entry 30 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 30 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0004           ; Entry 30 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 31 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 31 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0007           ; Entry 31 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 32 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 32 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $000a           ; Entry 32 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 33 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 33 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 33 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 34 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 34 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0009           ; Entry 34 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 35 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 35 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0004           ; Entry 35 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 36 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 36 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $000b           ; Entry 36 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 37 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 37 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 37 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 38 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 38 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 38 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 39 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 39 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $000c           ; Entry 39 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 40 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 40 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0004           ; Entry 40 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 41 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 41 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0007           ; Entry 41 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 42 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 42 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $000a           ; Entry 42 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 43 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 43 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 43 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 44 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 44 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 44 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 45 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 45 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 45 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 46 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 46 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 46 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 47 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 47 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 47 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 48 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 48 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 48 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 49 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 49 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 49 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 50 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 50 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 50 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 51 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 51 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 51 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 52 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 52 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 52 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 53 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 53 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 53 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 54 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 54 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 54 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 55 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 55 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 55 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 56 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 56 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0002           ; Entry 56 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 57 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 57 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0005           ; Entry 57 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 58 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 58 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 58 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7e9ac           ; Entry 59 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 59 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0009           ; Entry 59 [offset +6]: Synthesizer instrument preset / envelope index
        dc.w    $0000           ; Variable offset $0838
        dc.w    $0000           ; Variable offset $083a
        dc.w    $0000           ; Entry 60 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 60 [offset +6]: Synthesizer instrument preset / envelope index
; ===========================================================================
; Arrangement track sequence definitions list for Channel 2.
; ===========================================================================
music_sequence_table_2_src:
        dc.l    music_var_7e9de           ; Entry 61 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 61 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 61 [offset +6]: Synthesizer instrument preset / envelope index
music_sequence_loop_2_src:
        dc.l    music_var_7ea0a           ; Entry 62 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 62 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 62 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea0a           ; Entry 63 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 63 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 63 [offset +6]: Synthesizer instrument preset / envelope index
music_var_7e858_src:
        dc.l    music_var_7ea0a           ; Entry 64 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 64 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 64 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea3e           ; Entry 65 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 65 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 65 [offset +6]: Synthesizer instrument preset / envelope index
        dc.w    $0000           ; Variable offset $0868
        dc.w    $0000           ; Variable offset $086a
        dc.w    $0000           ; Entry 66 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 66 [offset +6]: Synthesizer instrument preset / envelope index
; ===========================================================================
; Arrangement track sequence definitions list for Channel 3.
; ===========================================================================
music_sequence_table_3_src:
        dc.l    music_var_7ea7a           ; Entry 67 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 67 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 67 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea82           ; Entry 68 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 68 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 68 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea82           ; Entry 69 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 69 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 69 [offset +6]: Synthesizer instrument preset / envelope index
music_sequence_loop_3_src:
        dc.l    music_var_7ea82           ; Entry 70 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 70 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 70 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea82           ; Entry 71 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 71 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 71 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea82           ; Entry 72 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 72 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 72 [offset +6]: Synthesizer instrument preset / envelope index
music_var_7e8a0_src:
        dc.l    music_var_7ec46           ; Entry 73 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 73 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 73 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea82           ; Entry 74 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 74 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 74 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea82           ; Entry 75 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 75 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 75 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea82           ; Entry 76 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 76 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 76 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f116           ; Entry 77 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 77 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 77 [offset +6]: Synthesizer instrument preset / envelope index
        dc.w    $0000           ; Variable offset $08c8
        dc.w    $0000           ; Variable offset $08ca
        dc.w    $0000           ; Entry 78 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 78 [offset +6]: Synthesizer instrument preset / envelope index
; ===========================================================================
; Arrangement track sequence definitions list for Channel 4.
; ===========================================================================
music_sequence_table_4_src:
        dc.l    music_var_7ea7a           ; Entry 79 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 79 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 79 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7ea7a           ; Entry 80 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 80 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 80 [offset +6]: Synthesizer instrument preset / envelope index
music_sequence_loop_4_src:
        dc.l    music_var_7ebac           ; Entry 81 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 81 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 81 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f270           ; Entry 82 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 82 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 82 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d0           ; Entry 83 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 83 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 83 [offset +6]: Synthesizer instrument preset / envelope index
music_var_7e8f8_src:
        dc.l    music_var_7ec46           ; Entry 84 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 84 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 84 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d0           ; Entry 85 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 85 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 85 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 86 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 86 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 86 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 87 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 87 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0003           ; Entry 87 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 88 [offset +0]: Pointer to note pattern data list
        dc.w    $ffff           ; Entry 88 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $fffe           ; Entry 88 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 89 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 89 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 89 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 90 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 90 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 90 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 91 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 91 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0003           ; Entry 91 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 92 [offset +0]: Pointer to note pattern data list
        dc.w    $ffff           ; Entry 92 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $fffe           ; Entry 92 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d8           ; Entry 93 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 93 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 93 [offset +6]: Synthesizer instrument preset / envelope index
        dc.l    music_var_7f0d0           ; Entry 94 [offset +0]: Pointer to note pattern data list
        dc.w    $0000           ; Entry 94 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 94 [offset +6]: Synthesizer instrument preset / envelope index
        dc.w    $0000           ; Variable offset $0950
        dc.w    $0000           ; Variable offset $0952
        dc.w    $0000           ; Entry 95 [offset +4]: Sequencer playback options / control flags (0)
        dc.w    $0000           ; Entry 95 [offset +6]: Synthesizer instrument preset / envelope index
music_var_7e958_src:
        dc.w    $0040           ; Track 1 sequence payload definition descriptor - Offset +0: Asset flags / category ($40=track, $30=envelope)
        dc.w    $0000           ; Track 1 sequence payload definition descriptor - Offset +2: Unused pad word (0)
        dc.w    $206c           ; Track 1 sequence payload definition descriptor - Offset +4: Total byte size of asset payload segment
        dc.l    music_song_track_1     ; Track 1 sequence payload definition descriptor - Offset +6: Pointer to resident memory payload
        dc.w    $0001           ; Track 2 sequence payload definition descriptor - Offset +0: Asset flags / category ($40=track, $30=envelope)
music_var_7e964_src:
        dc.w    $0040           ; Track 2 sequence payload definition descriptor - Offset +2: Unused pad word (0)
        dc.w    $0000           ; Track 2 sequence payload definition descriptor - Offset +4: Total byte size of asset payload segment
        dc.l    $34fc0007              ; Track 2 sequence payload definition descriptor - Offset +6: Pointer to resident memory payload
        dc.w    $206c           ; Track 3 sequence payload definition descriptor - Offset +0: Asset flags / category ($40=track, $30=envelope)
        dc.w    $0001           ; Track 3 sequence payload definition descriptor - Offset +2: Unused pad word (0)
music_var_7e970_src:
        dc.w    $0040           ; Track 3 sequence payload definition descriptor - Offset +4: Total byte size of asset payload segment
        dc.l    $174a                  ; Track 3 sequence payload definition descriptor - Offset +6: Pointer to resident memory payload
        dc.w    $0007           ; Track 4 sequence payload definition descriptor - Offset +0: Asset flags / category ($40=track, $30=envelope)
        dc.w    $5568           ; Track 4 sequence payload definition descriptor - Offset +2: Unused pad word (0)
        dc.w    $0001           ; Track 4 sequence payload definition descriptor - Offset +4: Total byte size of asset payload segment
music_var_7e97c_src:
        dc.l    $250000                ; Track 4 sequence payload definition descriptor - Offset +6: Pointer to resident memory payload
        dc.w    $1aa8           ; Sound ADSR envelope tables definition descriptor - Offset +0: Asset flags / category ($40=track, $30=envelope)
        dc.w    $0007           ; Sound ADSR envelope tables definition descriptor - Offset +2: Unused pad word (0)
        dc.w    $6cb2           ; Sound ADSR envelope tables definition descriptor - Offset +4: Total byte size of asset payload segment
        dc.l    $10030                 ; Sound ADSR envelope tables definition descriptor - Offset +6: Pointer to resident memory payload
        dc.w    $0000           ; Wavetable voice waveforms definition descriptor - Offset +0: Asset flags / category ($40=track, $30=envelope)
        dc.w    $0458           ; Wavetable voice waveforms definition descriptor - Offset +2: Unused pad word (0)
        dc.w    $0007           ; Wavetable voice waveforms definition descriptor - Offset +4: Total byte size of asset payload segment
        dc.l    $875a0001              ; Wavetable voice waveforms definition descriptor - Offset +6: Pointer to resident memory payload
music_var_7e994_src:
        dc.w    $0040           ; Synthesizer instruments presets definition descriptor - Offset +0: Asset flags / category ($40=track, $30=envelope)
        dc.w    $0000           ; Synthesizer instruments presets definition descriptor - Offset +2: Unused pad word (0)
        dc.w    $1094           ; Synthesizer instruments presets definition descriptor - Offset +4: Total byte size of asset payload segment
        dc.l    music_wavetable_presets ; Synthesizer instruments presets definition descriptor - Offset +6: Pointer to resident memory payload
        dc.w    $0001           ; Asset descriptor 7 - Offset +0: Asset flags / category ($40=track, $30=envelope)
music_var_7e9a0_src:
        dc.w    $0040           ; Asset descriptor 7 - Offset +2: Unused pad word (0)
        dc.w    $0000           ; Asset descriptor 7 - Offset +4: Total byte size of asset payload segment
        dc.l    $36000007              ; Asset descriptor 7 - Offset +6: Pointer to resident memory payload
        dc.w    $9fb2           ; Asset descriptor 8 - Offset +0: Asset flags / category ($40=track, $30=envelope)
        dc.w    $0001           ; Asset descriptor 8 - Offset +2: Unused pad word (0)
music_var_7e9ac_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e958 ;   Target preset descriptor: music_var_7e958
        dc.w    $0001,$000a     ; [Play Note]: Pitch index 1, Duration 10 ticks
        dc.w    $0001,$000a     ; [Play Note]: Pitch index 1, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0001,$000a     ; [Play Note]: Pitch index 1, Duration 10 ticks
        dc.w    $0001,$000a     ; [Play Note]: Pitch index 1, Duration 10 ticks
        dc.w    $0001,$0005     ; [Play Note]: Pitch index 1, Duration 5 ticks
        dc.w    $0001,$000a     ; [Play Note]: Pitch index 1, Duration 10 ticks
music_var_7e9ce_src:
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0001,$000a     ; [Play Note]: Pitch index 1, Duration 10 ticks
        dc.w    $0001,$0005     ; [Play Note]: Pitch index 1, Duration 5 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7e9de_src:
        dc.w    $0082,$00f0     ; [Rest Silence]: Duration 240 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e988 ;   Target preset descriptor: music_var_7e988
        dc.w    $0005,$0014     ; [Play Note]: Pitch index 5, Duration 20 ticks
        dc.w    $0005,$0014     ; [Play Note]: Pitch index 5, Duration 20 ticks
        dc.w    $0005,$0014     ; [Play Note]: Pitch index 5, Duration 20 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e994 ;   Target preset descriptor: music_var_7e994
        dc.w    $000b,$000a     ; [Play Note]: Pitch index 11, Duration 10 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7ea0a_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e988 ;   Target preset descriptor: music_var_7e988
        dc.w    $0005,$0014     ; [Play Note]: Pitch index 5, Duration 20 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e964 ;   Target preset descriptor: music_var_7e964
        dc.w    $000f,$0014     ; [Play Note]: Pitch index 15, Duration 20 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e988 ;   Target preset descriptor: music_var_7e988
        dc.w    $0005,$0005     ; [Play Note]: Pitch index 5, Duration 5 ticks
        dc.w    $0005,$000a     ; [Play Note]: Pitch index 5, Duration 10 ticks
music_var_7ea2c_src:
        dc.w    $0005,$0005     ; [Play Note]: Pitch index 5, Duration 5 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e964 ;   Target preset descriptor: music_var_7e964
        dc.w    $000f,$0014     ; [Play Note]: Pitch index 15, Duration 20 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7ea3e_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e988 ;   Target preset descriptor: music_var_7e988
        dc.w    $0005,$0014     ; [Play Note]: Pitch index 5, Duration 20 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e964 ;   Target preset descriptor: music_var_7e964
        dc.w    $000f,$0014     ; [Play Note]: Pitch index 15, Duration 20 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e988 ;   Target preset descriptor: music_var_7e988
        dc.w    $0005,$0005     ; [Play Note]: Pitch index 5, Duration 5 ticks
        dc.w    $0005,$0005     ; [Play Note]: Pitch index 5, Duration 5 ticks
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e964 ;   Target preset descriptor: music_var_7e964
        dc.w    $000f,$000a     ; [Play Note]: Pitch index 15, Duration 10 ticks
        dc.w    $000f,$000a     ; [Play Note]: Pitch index 15, Duration 10 ticks
        dc.w    $000f,$0005     ; [Play Note]: Pitch index 15, Duration 5 ticks
        dc.w    $000f,$0005     ; [Play Note]: Pitch index 15, Duration 5 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7ea7a_src:
        dc.w    $0082,$0280     ; [Rest Silence]: Duration 640 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7ea82_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e9a0 ;   Target preset descriptor: music_var_7e9a0
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
music_var_7eb00_src:
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7ebac_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e970 ;   Target preset descriptor: music_var_7e970
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0014,$000a     ; [Play Note]: Pitch index 20, Duration 10 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $0014,$000a     ; [Play Note]: Pitch index 20, Duration 10 ticks
        dc.w    $0010,$0005     ; [Play Note]: Pitch index 16, Duration 5 ticks
        dc.w    $0015,$000a     ; [Play Note]: Pitch index 21, Duration 10 ticks
        dc.w    $0010,$0005     ; [Play Note]: Pitch index 16, Duration 5 ticks
        dc.w    $0017,$000a     ; [Play Note]: Pitch index 23, Duration 10 ticks
        dc.w    $0015,$000a     ; [Play Note]: Pitch index 21, Duration 10 ticks
        dc.w    $0014,$000a     ; [Play Note]: Pitch index 20, Duration 10 ticks
        dc.w    $000b,$000a     ; [Play Note]: Pitch index 11, Duration 10 ticks
        dc.w    $000b,$000a     ; [Play Note]: Pitch index 11, Duration 10 ticks
        dc.w    $000f,$000a     ; [Play Note]: Pitch index 15, Duration 10 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000f,$000a     ; [Play Note]: Pitch index 15, Duration 10 ticks
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0014,$000a     ; [Play Note]: Pitch index 20, Duration 10 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7ec46_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e9a0 ;   Target preset descriptor: music_var_7e9a0
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
music_var_7ecd0_src:
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000a,$000f,$0012 ;   Semitone pitch offsets: [+10, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000f,$0012 ;   Semitone pitch offsets: [+10, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000f,$0012 ;   Semitone pitch offsets: [+10, +15, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000a,$000f,$0012 ;   Semitone pitch offsets: [+10, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000f,$0012 ;   Semitone pitch offsets: [+10, +15, +18]
music_var_7ed18_src:
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000f,$0012 ;   Semitone pitch offsets: [+10, +15, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000a,$000d,$0012 ;   Semitone pitch offsets: [+10, +13, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000d,$0012 ;   Semitone pitch offsets: [+10, +13, +18]
music_var_7ed3c_src:
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000d,$0012 ;   Semitone pitch offsets: [+10, +13, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000a,$000d,$0012 ;   Semitone pitch offsets: [+10, +13, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000d,$0012 ;   Semitone pitch offsets: [+10, +13, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000a,$000d,$0012 ;   Semitone pitch offsets: [+10, +13, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0009,$000d,$0010 ;   Semitone pitch offsets: [+9, +13, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0009,$000d,$0010 ;   Semitone pitch offsets: [+9, +13, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0009,$000d,$0010 ;   Semitone pitch offsets: [+9, +13, +16]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0009,$000d,$0010 ;   Semitone pitch offsets: [+9, +13, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0009,$000d,$0010 ;   Semitone pitch offsets: [+9, +13, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0009,$000d,$0010 ;   Semitone pitch offsets: [+9, +13, +16]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0008,$000b,$0010 ;   Semitone pitch offsets: [+8, +11, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$0010 ;   Semitone pitch offsets: [+8, +11, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$0010 ;   Semitone pitch offsets: [+8, +11, +16]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0008,$000b,$0010 ;   Semitone pitch offsets: [+8, +11, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$0010 ;   Semitone pitch offsets: [+8, +11, +16]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$0010 ;   Semitone pitch offsets: [+8, +11, +16]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0008,$000b,$000f ;   Semitone pitch offsets: [+8, +11, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$000f ;   Semitone pitch offsets: [+8, +11, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$000f ;   Semitone pitch offsets: [+8, +11, +15]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0008,$000b,$000f ;   Semitone pitch offsets: [+8, +11, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$000f ;   Semitone pitch offsets: [+8, +11, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0008,$000b,$000f ;   Semitone pitch offsets: [+8, +11, +15]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0006,$000a,$000f ;   Semitone pitch offsets: [+6, +10, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0006,$000a,$000f ;   Semitone pitch offsets: [+6, +10, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0006,$000a,$000f ;   Semitone pitch offsets: [+6, +10, +15]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0006,$000a,$000f ;   Semitone pitch offsets: [+6, +10, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0006,$000a,$000f ;   Semitone pitch offsets: [+6, +10, +15]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0006,$000a,$000f ;   Semitone pitch offsets: [+6, +10, +15]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0005,$000a,$000d ;   Semitone pitch offsets: [+5, +10, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$000a,$000d ;   Semitone pitch offsets: [+5, +10, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$000a,$000d ;   Semitone pitch offsets: [+5, +10, +13]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0005,$000a,$000d ;   Semitone pitch offsets: [+5, +10, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$000a,$000d ;   Semitone pitch offsets: [+5, +10, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$000a,$000d ;   Semitone pitch offsets: [+5, +10, +13]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0005,$0008,$000d ;   Semitone pitch offsets: [+5, +8, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$0008,$000d ;   Semitone pitch offsets: [+5, +8, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$0008,$000d ;   Semitone pitch offsets: [+5, +8, +13]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0005,$0008,$000d ;   Semitone pitch offsets: [+5, +8, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$0008,$000d ;   Semitone pitch offsets: [+5, +8, +13]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0005,$0008,$000d ;   Semitone pitch offsets: [+5, +8, +13]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0004,$0008,$000b ;   Semitone pitch offsets: [+4, +8, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0004,$0008,$000b ;   Semitone pitch offsets: [+4, +8, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0004,$0008,$000b ;   Semitone pitch offsets: [+4, +8, +11]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0004,$0008,$000b ;   Semitone pitch offsets: [+4, +8, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0004,$0008,$000b ;   Semitone pitch offsets: [+4, +8, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0004,$0008,$000b ;   Semitone pitch offsets: [+4, +8, +11]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0003,$0006,$000b ;   Semitone pitch offsets: [+3, +6, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000b ;   Semitone pitch offsets: [+3, +6, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000b ;   Semitone pitch offsets: [+3, +6, +11]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0003,$0006,$000b ;   Semitone pitch offsets: [+3, +6, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000b ;   Semitone pitch offsets: [+3, +6, +11]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000b ;   Semitone pitch offsets: [+3, +6, +11]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0003,$0006,$000a ;   Semitone pitch offsets: [+3, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000a ;   Semitone pitch offsets: [+3, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000a ;   Semitone pitch offsets: [+3, +6, +10]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0003,$0006,$000a ;   Semitone pitch offsets: [+3, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000a ;   Semitone pitch offsets: [+3, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0003,$0006,$000a ;   Semitone pitch offsets: [+3, +6, +10]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0001,$0006,$000a ;   Semitone pitch offsets: [+1, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0006,$000a ;   Semitone pitch offsets: [+1, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0006,$000a ;   Semitone pitch offsets: [+1, +6, +10]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0001,$0006,$000a ;   Semitone pitch offsets: [+1, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0006,$000a ;   Semitone pitch offsets: [+1, +6, +10]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0006,$000a ;   Semitone pitch offsets: [+1, +6, +10]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0001,$0004,$0009 ;   Semitone pitch offsets: [+1, +4, +9]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0009 ;   Semitone pitch offsets: [+1, +4, +9]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0009 ;   Semitone pitch offsets: [+1, +4, +9]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0001,$0004,$0009 ;   Semitone pitch offsets: [+1, +4, +9]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0009 ;   Semitone pitch offsets: [+1, +4, +9]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0009 ;   Semitone pitch offsets: [+1, +4, +9]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0001,$0004,$0008 ;   Semitone pitch offsets: [+1, +4, +8]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0008 ;   Semitone pitch offsets: [+1, +4, +8]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0008 ;   Semitone pitch offsets: [+1, +4, +8]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $0001,$0004,$0008 ;   Semitone pitch offsets: [+1, +4, +8]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0008 ;   Semitone pitch offsets: [+1, +4, +8]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $0001,$0004,$0008 ;   Semitone pitch offsets: [+1, +4, +8]
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7f0d0_src:
        dc.w    $0082,$0140     ; [Rest Silence]: Duration 320 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7f0d8_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e97c ;   Target preset descriptor: music_var_7e97c
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $000b,$000a     ; [Play Note]: Pitch index 11, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7f116_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e9a0 ;   Target preset descriptor: music_var_7e9a0
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000d,$0010,$0014 ;   Semitone pitch offsets: [+13, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$0010,$0014 ;   Semitone pitch offsets: [+11, +16, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000f,$0003 ; [Arpeggio Envelope]: Speed 15 ticks, Length 3 steps
        dc.w    $000b,$000f,$0012 ;   Semitone pitch offsets: [+11, +15, +18]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$000f,$0014 ;   Semitone pitch offsets: [+13, +15, +20]
        dc.w    $0081,$0005,$0003 ; [Arpeggio Envelope]: Speed 5 ticks, Length 3 steps
        dc.w    $000d,$000f,$0014 ;   Semitone pitch offsets: [+13, +15, +20]
        dc.w    $0081,$0005,$0003 ; [Arpeggio Envelope]: Speed 5 ticks, Length 3 steps
        dc.w    $000d,$000f,$0014 ;   Semitone pitch offsets: [+13, +15, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000d,$000f,$0014 ;   Semitone pitch offsets: [+13, +15, +20]
        dc.w    $0081,$0005,$0003 ; [Arpeggio Envelope]: Speed 5 ticks, Length 3 steps
        dc.w    $000d,$000f,$0014 ;   Semitone pitch offsets: [+13, +15, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$0005,$0003 ; [Arpeggio Envelope]: Speed 5 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0081,$000a,$0003 ; [Arpeggio Envelope]: Speed 10 ticks, Length 3 steps
        dc.w    $000c,$000f,$0014 ;   Semitone pitch offsets: [+12, +15, +20]
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
music_var_7f270_src:
        dc.w    $0080           ; [Inst Preset]: Command - Load Synth Instrument
        dc.l    music_var_7e970 ;   Target preset descriptor: music_var_7e970
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $000d,$0005     ; [Play Note]: Pitch index 13, Duration 5 ticks
        dc.w    $0014,$000a     ; [Play Note]: Pitch index 20, Duration 10 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $0014,$000a     ; [Play Note]: Pitch index 20, Duration 10 ticks
        dc.w    $0010,$0005     ; [Play Note]: Pitch index 16, Duration 5 ticks
        dc.w    $0015,$000a     ; [Play Note]: Pitch index 21, Duration 10 ticks
        dc.w    $0010,$0005     ; [Play Note]: Pitch index 16, Duration 5 ticks
        dc.w    $0017,$000a     ; [Play Note]: Pitch index 23, Duration 10 ticks
        dc.w    $0015,$000a     ; [Play Note]: Pitch index 21, Duration 10 ticks
        dc.w    $0014,$000a     ; [Play Note]: Pitch index 20, Duration 10 ticks
        dc.w    $000b,$000a     ; [Play Note]: Pitch index 11, Duration 10 ticks
        dc.w    $000b,$000a     ; [Play Note]: Pitch index 11, Duration 10 ticks
        dc.w    $000f,$000a     ; [Play Note]: Pitch index 15, Duration 10 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000b,$0005     ; [Play Note]: Pitch index 11, Duration 5 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000f,$000a     ; [Play Note]: Pitch index 15, Duration 10 ticks
        dc.w    $0014,$0005     ; [Play Note]: Pitch index 20, Duration 5 ticks
        dc.w    $0014,$0005     ; [Play Note]: Pitch index 20, Duration 5 ticks
        dc.w    $0012,$000a     ; [Play Note]: Pitch index 18, Duration 10 ticks
        dc.w    $0010,$000a     ; [Play Note]: Pitch index 16, Duration 10 ticks
        dc.w    $000f,$000a     ; [Play Note]: Pitch index 15, Duration 10 ticks
        dc.w    $000d,$000a     ; [Play Note]: Pitch index 13, Duration 10 ticks
        dc.w    $000f,$0005     ; [Play Note]: Pitch index 15, Duration 5 ticks
        dc.w    $000d,$0019     ; [Play Note]: Pitch index 13, Duration 25 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $ffff,$ffff     ; [Play Note]: Pitch index 65535, Duration 65535 ticks
        dc.w    $ffff,$ffff     ; [Play Note]: Pitch index 65535, Duration 65535 ticks
        dc.w    $ffff,$0000     ; [Play Note]: Pitch index 65535, Duration 0 ticks
        dcb.w   961,0           ; [End Pattern / Zero Padding]: 961 consecutive stop/padding words
music_var_7fa94_src:
        dcb.w   215,0           ; [End Pattern / Zero Padding]: 215 consecutive stop/padding words
music_var_7fc42_src:
        dcb.w   379,0           ; [End Pattern / Zero Padding]: 379 consecutive stop/padding words
        dc.w    $00fc,$1e94     ; [Play Note]: Pitch index 252, Duration 7828 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $00fc,$1b9e     ; [Play Note]: Pitch index 252, Duration 7070 ticks
        dc.w    $00fe,$529c     ; [Play Note]: Pitch index 254, Duration 21148 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $2d54,$0000     ; [Play Note]: Pitch index 11604, Duration 0 ticks
        dc.w    $0016,$00fe     ; [Play Note]: Pitch index 22, Duration 254 ticks
        dc.w    $5ef8,$00fe     ; [Play Note]: Pitch index 24312, Duration 254 ticks
        dc.w    $5d38,$0000     ; [Play Note]: Pitch index 23864, Duration 0 ticks
        dc.w    $0016,$00fe     ; [Play Note]: Pitch index 22, Duration 254 ticks
        dc.w    $97c8,$0000     ; [Play Note]: Pitch index 38856, Duration 0 ticks
        dc.w    $00fc,$1e94     ; [Play Note]: Pitch index 252, Duration 7828 ticks
        dc.w    $00fc,$1e94     ; [Play Note]: Pitch index 252, Duration 7828 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $00fe,$5ef8     ; [Play Note]: Pitch index 254, Duration 24312 ticks
        dc.w    $00fe,$5d38     ; [Play Note]: Pitch index 254, Duration 23864 ticks
        dc.w    $00fc,$1e94     ; [Play Note]: Pitch index 252, Duration 7828 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $00fc,$1e94     ; [Play Note]: Pitch index 252, Duration 7828 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0200,$00fc     ; [Play Note]: Pitch index 512, Duration 252 ticks
        dc.w    $00fc,$1e94     ; [Play Note]: Pitch index 252, Duration 7828 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $00fc,$1b9e     ; [Play Note]: Pitch index 252, Duration 7070 ticks
        dc.w    $00fe,$529c     ; [Play Note]: Pitch index 254, Duration 21148 ticks
        dc.w    $0020,$073c     ; [Play Note]: Pitch index 32, Duration 1852 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0016,$0020     ; [Play Note]: Pitch index 22, Duration 32 ticks
        dc.w    $1f18,$00fe     ; [Play Note]: Pitch index 7960, Duration 254 ticks
        dc.w    $569c,$4000     ; [Play Note]: Pitch index 22172, Duration 16384 ticks
        dc.w    $0038,$10cf     ; [Play Note]: Pitch index 56, Duration 4303 ticks
        dc.w    $0034,$00fc     ; [Play Note]: Pitch index 52, Duration 252 ticks
        dc.w    $1e94,$00fe     ; [Play Note]: Pitch index 7828, Duration 254 ticks
        dc.w    $5ef8,$00fe     ; [Play Note]: Pitch index 24312, Duration 254 ticks
        dc.w    $5d38,$00fc     ; [Play Note]: Pitch index 23864, Duration 252 ticks
        dc.w    $1e94,$0000     ; [Play Note]: Pitch index 7828, Duration 0 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $00fc,$00fc     ; [Play Note]: Pitch index 252, Duration 252 ticks
        dc.w    $1e94,$0000     ; [Play Note]: Pitch index 7828, Duration 0 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $00fc,$1b9e     ; [Play Note]: Pitch index 252, Duration 7070 ticks
        dc.w    $00fe,$a706     ; [Play Note]: Pitch index 254, Duration 42758 ticks
        dc.w    $0020,$055e     ; [Play Note]: Pitch index 32, Duration 1374 ticks
        dc.w    $00fe,$ac82     ; [Play Note]: Pitch index 254, Duration 44162 ticks
        dc.w    $00fc,$6e0a     ; [Play Note]: Pitch index 252, Duration 28170 ticks
        dc.w    $0000           ; [End Pattern]: Command - Stop Sequencer Voice
        dc.w    $0652,$0000     ; [Play Note]: Pitch index 1618, Duration 0 ticks
        dcb.w   4,0           ; [End Pattern / Zero Padding]: 4 consecutive stop/padding words
        dc.w    $080c,$0020     ; [Play Note]: Pitch index 2060, Duration 32 ticks
        dc.w    $7a1e,$0020     ; [Play Note]: Pitch index 31262, Duration 32 ticks
        dc.w    $7bf0,$0000     ; [Play Note]: Pitch index 31728, Duration 0 ticks
        dc.w    $0640,$0010     ; [Play Note]: Pitch index 1600, Duration 16 ticks
        dc.w    $00fc           ; [Play Note]: Partial note pitch word
        dc.b    $08           ; [Pattern Event]: Last byte of payload
