; ---------------------------------------------------------------------------
; Delirium crack intro for Liberation - Captive II
; ---------------------------------------------------------------------------
;
; Reconstructed by Volker Schwaberow <volker@schwaberow.de>
;
; Build:
;   vasmm68k_mot -m68000 -no-opt -Fbin -o delirium_liberation_reconstructed.bin delirium_liberation_reconstructed.s
;
; ---------------------------------------------------------------------------

        org     $00000000

; ---------------------------------------------------------------------------
; Hardware / OS constants
; ---------------------------------------------------------------------------

CUSTOM                  equ     $00dff000
DMACONR                 equ     $00dff002
VPOSR_VHPOSR_LONG       equ     $00dff004
COP1LCH                 equ     $00dff080
COPJMP1                 equ     $00dff088
DMACON                  equ     $00dff096
INTENA                  equ     $00dff09a
INTREQ                  equ     $00dff09c
ADKCON                  equ     $00dff09e
AUD0LCH                 equ     $00dff0a0
AUD0LEN                 equ     $00dff0a4
AUD0PER                 equ     $00dff0a6
AUD0VOL                 equ     $00dff0a8
AUD1LCH                 equ     $00dff0b0
AUD1LEN                 equ     $00dff0b4
AUD1PER                 equ     $00dff0b6
AUD1VOL                 equ     $00dff0b8

CIAA_PRA_JOY_MOUSE      equ     $00bfe001
CIAA_SDR_KEYBOARD       equ     $00bfec01

EXEC_BASE_PTR           equ     $00000004
LEVEL3_INTERRUPT_VECTOR equ     $0000006c

_LVOForbid              equ     -132
_LVOEnable              equ     -138
_LVODisable             equ     -120
_LVOSupervisor          equ     -30
_LVOCloseLibrary        equ     -414
_LVOOpenLibrary         equ     -552

AMIGADOS_HUNK_HEADER    equ     $000003f3
AMIGADOS_HUNK_CODE      equ     $000003e9
HUNKF_CHIP              equ     $40000000
DELIRIUM_HUNK_LONGS     equ     $00001184       ; 4484 longwords = 17936 bytes.

; ---------------------------------------------------------------------------
; Decrunched image
; ---------------------------------------------------------------------------

delirium_file_preamble:
        dc.l    0,0                      ; Two leading null longwords kept exactly as they are in the decrunched file.

delirium_amigados_hunk_header:
        ; This is an AmigaDOS hunk executable header. In coffee-kitchen terms:
        ; it says "one CHIP-memory code hunk follows, and it is 4484 longwords
        ; long". The following HUNK_CODE block is where the actual intro starts.
        dc.l    AMIGADOS_HUNK_HEADER
        dc.l    0                        ; No hunk name strings.
        dc.l    1                        ; One hunk in the table.
        dc.l    0                        ; First hunk number.
        dc.l    0                        ; Last hunk number.
        dc.l    HUNKF_CHIP|DELIRIUM_HUNK_LONGS ; Allocate the hunk in CHIP RAM.
        dc.l    AMIGADOS_HUNK_CODE
        dc.l    DELIRIUM_HUNK_LONGS      ; Size of the code hunk in longwords.

; Entry trampoline found in the decrunched header.
file_entry_jump:
        jmp  delirium_intro_entry(pc)              ; Jump over the header and text, straight into the real intro code.

; The text pager treats this as a sequence of text pages:
; - byte 10 starts a new line
; - byte 0 ends the current page and advances to the next one
; - byte $ff at the end makes the text logic wrap back to the start
;
; Lines are not fixed-width screen rows. They are raw ASCII strings which the
; renderer measures with font_width_table before centering them.
delirium_intro_text:
delirium_intro_text_page_1_title_and_credits:
        dc.b    "*  D  E  L  I  R  I  U  M  *",10
        dc.b    "A Touch Of Perfection",10
        dc.b    10
        dc.b    10
        dc.b    "--------------------------------------------",10
        dc.b    "LIBERATION - Captive II",10
        dc.b    "From MINDSCAPE",10
        dc.b    "--------------------------------------------",10
        dc.b    10
        dc.b    "Protection Removed By: MARIANNE",10
        dc.b    "Original Supplied By: MAD MAGGOT",10
        dc.b    10
        dc.b    "PLEASE NOTE!!!",10
        dc.b    10
        dc.b    "You MUST Enter CENTURY At The Password Prompt!",10
        dc.b    10
        dc.b    0
delirium_intro_text_page_2_member_thanks:
        dc.b    "Special thanks to all our members because..",10
        dc.b    "without their help this wouldn't be possible",10
        dc.b    10
        dc.b    10
        dc.b    10
        dc.b    10
        dc.b    0
delirium_intro_text_page_3_joining_bbs:
        dc.b    "If you're interested in joining then call us",10
        dc.b    "on any of our bulletin board systems... ",10
        dc.b    10
        dc.b    10
        dc.b    10
        dc.b    10
        dc.b    0
delirium_intro_text_page_4_board_names:
        dc.b    "Bloody Decision",10
        dc.b    10
        dc.b    "Death Valley",10
        dc.b    10
        dc.b    "Eleventh Hour",10
        dc.b    10
        dc.b    "End Of The World",10
        dc.b    10
        dc.b    "Future Shock",10
        dc.b    10
        dc.b    "Hades",10
        dc.b    10
        dc.b    "Imperial Dominium",10
        dc.b    10
        dc.b    "Road To Nowhere",10
        dc.b    10
        dc.b    "The Vault",10
        dc.b    10
        dc.b    10
        dc.b    " ",$ff


; ---------------------------------------------------------------------------
; Main intro code
; ---------------------------------------------------------------------------
delirium_intro_entry:
        lea     delirium_intro_text(pc),a0         ; A0 now points at the first text page for the scroller.
        movem.l  d0-d7/a0-a6,-(a7)                 ; Save the registers; this routine is going to make a mess for a bit.
        btst.b  #$6,CIAA_PRA_JOY_MOUSE             ; Check the fire button, because that is our quick way out.
        beq.b  intro_return                        ; If the exit button is already down, skip the whole show and return.
        lea     graphics_library_name(pc),a5       ; Use the graphics.library name; the runtime variables live right after it.
        lea     CUSTOM,a6                          ; A6 is the custom-chip base from here on, so the hardware writes stay short.
        move.l  a0,$56(a5)                         ; Remember A0 at $56(a5); the text code comes back to it later.
        lea     screen_memory(pc),a0               ; Point at the blank screen memory the intro draws into.
        move.l  a0,$26(a5)                         ; Store the screen buffer pointer in the runtime block.
        movea.l  main_text_stream_ptr(pc),a0       ; Fetch the current text pointer from our local data.
        bsr.w  start_scroller_line                 ; Call start_scroller_line; it measures and positions the first message.
        bsr.w  blitter_fill_step                   ; Call blitter_fill_step; it updates the blitter-driven logo/shape state.
        lea     dynamic_copper_wait_buffer(pc),a0         ; Point at the buffer where we build copper waits on the fly.
        moveq  #-1,d0                              ; Use -1 as a quick filler word for the two sentinel longs below.
        move.l  d0,(a0)+                           ; Write this longword and move to the next output slot.
        move.l  d0,(a0)+                           ; Write this longword and move to the next output slot.
        bsr.b  open_libraries_and_grab_display     ; Set up Exec/graphics.library and take over the display.
        bne.b  intro_return                        ; If setup reported an error, restore the registers and get out.
        bsr.w  install_display_and_irq             ; Call install_display_and_irq; it installs our copper list and VBlank hook.
        bsr.w  setup_audio_dma                     ; Call setup_audio_dma; it primes the two simple click channels.

loc_02f0:
        tst.b  $4b(a5)                             ; Just test this flag/counter and let the next branch decide.
        beq.b  loc_02f0                            ; Stay here until the VBlank handler says the intro is done.
        btst.b  #$6,$2(a6)                         ; Look at the blitter busy bit before touching blitter registers.

loc_02fc:
        btst.b  #$6,$2(a6)                         ; Look at the blitter busy bit before touching blitter registers.
        bne.b  loc_02fc                            ; Keep waiting while the blitter is still busy.
        bsr.w  restore_system_and_exit             ; Call restore_system_and_exit; it puts the machine back the way we found it.

intro_return:
        movem.l  (a7)+,d0-d7/a0-a6                 ; Put the registers back before we leave.
        moveq  #$0,d0                              ; Return zero; from the caller's view the intro exits cleanly.
        rts                                        ; Done here, go back to the caller.

open_libraries_and_grab_display:
        movea.l  EXEC_BASE_PTR.w,a6                ; Grab ExecBase from address 4, the usual AmigaOS entry point.
        jsr  -$84(a6)                              ; Ask Exec to forbid task switching while we take over the display.
        moveq  #$f,d0                              ; Start with a small mask; we only care about the low interrupt state bits.
        and.w  $128(a6),d0                         ; Keep only the bits we actually care about.
        beq.b  loc_032c                            ; If there is nothing special pending, skip the supervisor detour.
        move.l  a5,-(a7)                           ; Keep our runtime base safe before the supervisor call borrows A5.
        lea     supervisor_probe_stub(pc),a5       ; Point A5 at the tiny supervisor probe stub.
        jsr  -$1e(a6)                              ; Call into Exec or graphics.library through the library vector in A6.
        movea.l  (a7)+,a5                          ; Bring our runtime base back after the supervisor probe.

loc_032c:
        move.l  d0,$22(a5)                         ; Save that Exec state at $22(a5) for cleanup.
        lea     graphics_library_name(pc),a1       ; Use the graphics.library name; the runtime variables live right after it.
        moveq  #$21,d0                             ; Request graphics.library version 33, the Kickstart-era graphics API this intro wants.
        jsr  -$228(a6)                             ; Open graphics.library through Exec, using the name in A1 and version in D0.
        move.l  d0,$12(a5)                         ; Keep the GfxBase pointer at $12(a5).
        bne.b  loc_0344                            ; If OpenLibrary worked, carry on with the display grab.
        moveq  #-1,d0                              ; Return -1, the intro's quick way of saying setup failed.
        rts                                        ; Done here, go back to the caller.

loc_0344:
        movea.l  d0,a6                             ; Treat the returned library base as GfxBase for the graphics calls.
        move.l  $22(a6),$16(a5)                    ; Save the old graphics pointer from GfxBase for restore time.
        jsr  -$e4(a6)                              ; Call into Exec or graphics.library through the library vector in A6.
        jsr  -$1c8(a6)                             ; Call into Exec or graphics.library through the library vector in A6.
        jsr  -$e4(a6)                              ; Call into Exec or graphics.library through the library vector in A6.
        suba.l  a1,a1                              ; Back this value up by the amount shown.
        jsr  -$de(a6)                              ; Call into Exec or graphics.library through the library vector in A6.
        jsr  -$10e(a6)                             ; Call into Exec or graphics.library through the library vector in A6.
        jsr  -$10e(a6)                             ; Call into Exec or graphics.library through the library vector in A6.
        lea     CUSTOM,a6                          ; A6 is the custom-chip base from here on, so the hardware writes stay short.
        move.w  $2(a6),d0                          ; Read custom-chip register $2(a6) into d0 before we disturb the machine.
        or.w  d0,$1a(a5)                           ; Fold these hardware bits into our saved copy.
        move.w  $1c(a6),d0                         ; Read custom-chip register $1c(a6) into d0 before we disturb the machine.
        or.w  d0,$1c(a5)                           ; Fold these hardware bits into our saved copy.
        moveq  #$0,d0                              ; Return zero to say the display grab was successful.
        rts                                        ; Done here, go back to the caller.

install_display_and_irq:
        lea     CUSTOM,a6                          ; A6 is the custom-chip base from here on, so the hardware writes stay short.
        move.w  #$7fff,d0                          ; Use $7fff as the "clear everything" mask for DMA and interrupts.
        move.w  d0,$96(a6)                         ; Write D0 to DMACON.
        move.w  d0,$9a(a6)                         ; Write D0 to INTENA.
        move.w  d0,$9c(a6)                         ; Write D0 to INTREQ.
        lea     bitplane_a(pc),a0                  ; Start patching the first visible bitplane pointer.
        move.l  screen_buffer_ptr(pc),d0           ; Load the screen buffer address we saved earlier.
        moveq  #$28,d1                             ; Use 40 bytes per row, which is the screen stride here.
        moveq  #$1,d2                              ; Load the small step value into D2.
        bsr.b  loc_03fa                            ; Patch those bitplane pointer words.
        lea     copper_bpl_pointer_words(pc),a0    ; Walk into the copper list where bitplane pointer words live.
        lea     copper_colour_table(pc),a1         ; Grab the colour/pointer table used to finish the copper setup.
        move.l  a1,d2                              ; Keep the table base in D2 so offsets can be added to it.
        moveq  #$7,d1                              ; Patch eight copper pointer slots.
        move.l  (a1)+,d0                           ; Read the next byte and advance the pointer.
        add.l  d2,d0                               ; Add this in; it advances the current position/counter.
        move.w  d0,$4(a0)                          ; Write the low word of the pointer into the copper slot.
        swap  d0                                   ; Swap the address halves; copper wants high word and low word separately.
        move.w  d0,(a0)                            ; Store d0 at the current pointer without moving it.
        addq.w  #$8,a0                             ; Add this in; it advances the current position/counter.
        dbra  d1,$3b0                              ; Loop until the DBRA counter runs out.
        lea     copper_runtime_list(pc),a0         ; Select the runtime copper list that will be handed to the chipset.
        move.w  $7c(a6),d0                         ; Read custom-chip register $7c(a6) into d0 before we disturb the machine.
        cmpi.b  #$f8,d0                            ; Compare with the marker value used by the next branch.
        bne.b  loc_03d2                            ; If the last test was non-zero, take this branch.
        subq.w  #$8,a0                             ; Back this value up by the amount shown.

loc_03d2:
        move.l  a0,$80(a6)                         ; Write a0 to custom-chip register $80(a6), so the display or audio state changes immediately.
        move.w  d0,$88(a6)                         ; Strobe COPJMP1 so the restored copper list takes effect.
        movea.l  exception_vector_base(pc),a0                  ; Fetch the exception vector base; usually zero on a plain 68000.
        move.l  $6c(a0),$1e(a5)                    ; Save the old level-3 vector before installing ours.
        lea     level3_vblank_irq(pc),a1           ; Prepare our VBlank interrupt handler address.
        move.l  a1,$6c(a0)                         ; Install our level-3/VBlank interrupt vector.
        move.w  #$83e0,$96(a6)                     ; Turn the DMA channels back on for the intro display.
        move.w  #$c020,$9a(a6)                     ; Enable the level-3 interrupt bit we use for VBlank.
        rts                                        ; Done here, go back to the caller.

loc_03fa:
        move.w  d0,$4(a0)                          ; Write the low word of the pointer into the copper slot.
        swap  d0                                   ; Swap the address halves; copper wants high word and low word separately.
        move.w  d0,(a0)                            ; Store d0 at the current pointer without moving it.
        swap  d0                                   ; Swap the address halves; copper wants high word and low word separately.
        add.l  d1,d0                               ; Add this in; it advances the current position/counter.
        addq.w  #$8,a0                             ; Add this in; it advances the current position/counter.
        dbra  d2,$3fa                              ; Loop until the DBRA counter runs out.
        rts                                        ; Done here, go back to the caller.

supervisor_probe_stub:
        dc.b    $4e,$7a,$08,$01,$4e,$73                                         ; 00040e  Nz..Ns

restore_system_and_exit:
        lea     CUSTOM,a6                          ; A6 is the custom-chip base from here on, so the hardware writes stay short.
        movea.l  exception_vector_base(pc),a0                  ; Fetch the exception vector base; usually zero on a plain 68000.
        move.l  saved_level3_vector(pc),$6c(a0)              ; Restore the original level-3 interrupt vector.
        move.w  saved_intena_bits(pc),$9a(a6)              ; Restore the interrupt enable bits we saved on entry.
        move.w  saved_dmacon_bits(pc),$96(a6)              ; Restore the DMA enable bits we saved on entry.
        movea.l  gfxbase_ptr(pc),a1                  ; Fetch the saved GfxBase pointer.
        move.l  $26(a1),$80(a6)                    ; Restore the system copper list pointer from GfxBase.
        move.w  d0,$88(a6)                         ; Strobe COPJMP1 so the restored copper list takes effect.
        move.w  #$0,$a8(a6)                        ; Silence audio channel 0.
        move.w  #$0,$b8(a6)                        ; Silence audio channel 1.
        movea.l  gfxbase_ptr(pc),a6                  ; Use GfxBase again for the graphics cleanup calls.
        jsr  -$e4(a6)                              ; Call into Exec or graphics.library through the library vector in A6.
        jsr  -$1ce(a6)                             ; Call into Exec or graphics.library through the library vector in A6.
        jsr  -$e4(a6)                              ; Call into Exec or graphics.library through the library vector in A6.
        movea.l  saved_active_view_ptr(pc),a1                  ; Put the old active View in A1 for LoadView.
        jsr  -$de(a6)                              ; Call into Exec or graphics.library through the library vector in A6.
        movea.l  a6,a1                             ; CloseLibrary wants the library base in A1, so move GfxBase there.
        movea.l  EXEC_BASE_PTR.w,a6                ; Go back to ExecBase so the final cleanup calls use the right library.
        jsr  -$19e(a6)                             ; Call into Exec or graphics.library through the library vector in A6.
        jmp  -$8a(a6)                              ; Re-enable multitasking through Exec and leave the cleanup routine from there.

level3_vblank_irq:
        movem.l  d0-d7/a0-a6,-(a7)                 ; Save the registers; this routine is going to make a mess for a bit.
        lea     graphics_library_name(pc),a5       ; Use the graphics.library name; the runtime variables live right after it.
        lea     CUSTOM,a6                          ; A6 is the custom-chip base from here on, so the hardware writes stay short.
        btst.b  #$6,CIAA_PRA_JOY_MOUSE             ; Check the fire button, because that is our quick way out.
        bne.b  loc_048c                            ; If the last test was non-zero, take this branch.
        st.b  $4a(a5)                              ; Set the flag byte.

loc_048c:
        bsr.w  advance_main_text                   ; Call advance_main_text; it feeds the next character when the timer allows it.
        bsr.w  update_copper_colours               ; Call update_copper_colours; it rebuilds the little raster colour pattern.
        bsr.w  render_equalizer_or_logo            ; Call render_equalizer_or_logo; it nudges the animated bars toward their targets.
        bsr.w  blitter_fill_step                   ; Call blitter_fill_step; it updates the blitter-driven logo/shape state.
        bsr.w  drive_typewriter_beep               ; Call drive_typewriter_beep; it makes the tiny keyboard-click style sound.
        move.w  #$20,$9c(a6)                       ; Acknowledge the VBlank interrupt.
        movem.l  (a7)+,d0-d7/a0-a6                 ; Put the registers back before we leave.
        rte                                        ; Return from interrupt; the beam can carry on.

advance_main_text:
        lea     text_delay_counter(pc),a0          ; Check the little timer that paces the text.
        tst.w  (a0)                                ; Just test this flag/counter and let the next branch decide.
        beq.b  loc_04b8                            ; If the last test was zero, take this branch.
        subq.w  #$1,(a0)                           ; Back this value up by the amount shown.
        bra.b  loc_04c0                            ; Jump straight to the next named step in this little state machine.

loc_04b8:
        movea.l  main_text_stream_ptr(pc),a0       ; Fetch the current text pointer from our local data.
        bsr.w  next_scroller_byte                  ; Call next_scroller_byte; it consumes the next byte from the message stream.

loc_04c0:
        cmpi.w  #$24,$40(a5)                       ; Compare with the marker value used by the next branch.
        bgt.b  loc_04cc                            ; If it is still above the limit, branch.
        bsr.w  scroll_text_up                      ; Call scroll_text_up; it clears the next band as the message rolls upward.

loc_04cc:
        rts                                        ; Done here, go back to the caller.

consume_scroller_byte:
        cmpi.b  #$a,d0                             ; Compare with the marker value used by the next branch.
        bne.w  draw_scroller_character             ; If the last test was non-zero, take this branch.
        addi.w  #$9,$36(a5)                        ; Add this in; it advances the current position/counter.
        bsr.b  loc_050c                            ; Recalculate the horizontal centering for the current line.

next_scroller_byte:
        movea.l  current_text_ptr(pc),a1           ; Pick up the text stream pointer.
        moveq  #$0,d0                              ; Clear D0 before reading the next signed text byte into its low byte.
        move.b  (a1)+,d0                           ; Read the next byte and advance the pointer.
        movem.l  a1,$32(a5)                        ; Move the whole register block in one go.
        bgt.b  consume_scroller_byte               ; If it is still above the limit, branch.
        beq.b  reset_scroller_line                 ; If the last test was zero, take this branch.
        move.l  a0,$32(a5)                         ; Stash a0 in the intro runtime block at $32(a5); we will need it again next frame.

reset_scroller_line:
        bsr.b  count_scroller_lines                ; Call count_scroller_lines; it counts newlines so the block can sit vertically centered.
        move.w  d0,$36(a5)                         ; Stash d0 in the intro runtime block at $36(a5); we will need it again next frame.
        move.w  text_initial_y(pc),d1              ; Load the starting Y position for this text page.
        move.w  d1,$3a(a5)                         ; Stash d1 in the intro runtime block at $3a(a5); we will need it again next frame.
        move.w  d0,$3c(a5)                         ; Stash d0 in the intro runtime block at $3c(a5); we will need it again next frame.
        move.w  #$14a,$40(a5)                      ; Set the scroll countdown high enough to let the page roll in.

loc_050c:
        bsr.b  measure_current_line_width          ; Call measure_current_line_width; it works out how far to indent this line.
        move.w  d0,$38(a5)                         ; Stash d0 in the intro runtime block at $38(a5); we will need it again next frame.
        rts                                        ; Done here, go back to the caller.

start_scroller_line:
        move.l  a0,$32(a5)                         ; Stash a0 in the intro runtime block at $32(a5); we will need it again next frame.
        bsr.b  reset_scroller_line                 ; Call reset_scroller_line; it resets the cursor for the next text block.
        clr.w  $40(a5)                             ; Clear the word; this resets that bit of state.
        rts                                        ; Done here, go back to the caller.

measure_current_line_width:
        movea.l  current_text_ptr(pc),a0           ; Pick up the text stream pointer.
        lea     font_width_table(pc),a1            ; Use the per-character width table so the line can be centered.
        move.w  #$140,d0                           ; Start from 320 pixels and subtract the line width from there.

loc_052c:
        moveq  #$0,d1                              ; Clear D1 cheaply; we are about to build a byte-sized value in it.
        move.b  (a0)+,d1                           ; Read the next byte and advance the pointer.
        subi.b  #$20,d1                            ; Keep the original machine operation in place.
        blt.b  loc_053e                            ; If it is still below the threshold, branch.
        move.b  (a1,d1.w),d1                       ; Look up this character width in the width table.
        sub.w  d1,d0                               ; Back this value up by the amount shown.
        bra.b  loc_052c                            ; Jump straight to the next named step in this little state machine.

loc_053e:
        lsr.w  #$1,d0                              ; Shift the bits into the shape the hardware wants.
        rts                                        ; Done here, go back to the caller.

count_scroller_lines:
        movea.l  current_text_ptr(pc),a0           ; Pick up the text stream pointer.
        moveq  #$0,d1                              ; Clear D1 cheaply; we are about to build a byte-sized value in it.

loc_0548:
        move.b  (a0)+,d0                           ; Read the next byte and advance the pointer.
        ble.b  loc_0556                            ; Stop here when the byte is a control/end marker.
        cmpi.b  #$a,d0                             ; Compare with the marker value used by the next branch.
        bne.b  loc_0548                            ; If the last test was non-zero, take this branch.
        addq.w  #$1,d1                             ; Add this in; it advances the current position/counter.
        bra.b  loc_0548                            ; Jump straight to the next named step in this little state machine.

loc_0556:
        move.w  #$90,d0                            ; Start from the vertical middle before subtracting the text block height.
        mulu.w  #$9,d1                             ; Multiply by the stride to reach the right entry.
        lsr.l  #$1,d1                              ; Shift the bits into the shape the hardware wants.
        sub.w  d1,d0                               ; Back this value up by the amount shown.
        rts                                        ; Done here, go back to the caller.

draw_scroller_character:
        subi.w  #$20,d0                            ; Back this value up by the amount shown.
        lea     font_width_table(pc),a0            ; Use the per-character width table so the line can be centered.
        moveq  #$0,d1                              ; Clear D1 cheaply; we are about to build a byte-sized value in it.
        move.b  (a0,d0.w),d1                       ; Look up the width for this character.
        mulu.w  #$10,d0                            ; Multiply by the stride to reach the right entry.
        lea     font_glyph_data(pc),a0             ; Jump to the packed bitmap for the character we are drawing.
        adda.w  d0,a0                              ; Add this in; it advances the current position/counter.
        movea.l  screen_buffer_ptr(pc),a1          ; A1 points at the screen buffer we are drawing into.
        move.w  text_row_index(pc),d0              ; Load the current text row.
        mulu.w  #$28,d0                            ; Multiply by the stride to reach the right entry.
        adda.w  d0,a1                              ; Add this in; it advances the current position/counter.
        moveq  #$0,d0                              ; Clear D0 before loading the current pixel column into it.
        move.w  text_column_pixel(pc),d0           ; Load the current pixel column.
        add.w  d1,$38(a5)                          ; Add this in; it advances the current position/counter.
        ror.l  #$4,d0                              ; Shift the bits into the shape the hardware wants.
        add.w  d0,d0                               ; Add this in; it advances the current position/counter.
        adda.w  d0,a1                              ; Add this in; it advances the current position/counter.
        swap  d0                                   ; Swap the address halves; copper wants high word and low word separately.
        addi.w  #$dfc,d0                           ; Add this in; it advances the current position/counter.
        btst.b  #$6,$2(a6)                         ; Look at the blitter busy bit before touching blitter registers.

loc_05a6:
        btst.b  #$6,$2(a6)                         ; Look at the blitter busy bit before touching blitter registers.
        bne.b  loc_05a6                            ; If the last test was non-zero, take this branch.
        move.w  d0,$40(a6)                         ; Set BLTCON0 for this character blit.
        move.w  #$0,$42(a6)                        ; Clear BLTCON1.
        move.l  #$ffff0000,$44(a6)                 ; Use a full first mask and an empty last mask for the blit.
        move.w  #$24,$62(a6)                       ; Set the B-channel modulo.
        move.w  #$fffe,$64(a6)                     ; Set the A-channel modulo for the font data.
        move.w  #$24,$66(a6)                       ; Set the D-channel modulo.
        move.l  a1,$4c(a6)                         ; Set the destination pointer for the blit.
        move.l  a0,$50(a6)                         ; Set the source pointer for the glyph data.
        move.l  a1,$54(a6)                         ; Set the second blitter pointer to the same screen position.
        move.w  #$202,$58(a6)                      ; Kick the blitter: 2 words wide, 2 rows high in this packed setup.
        rts                                        ; Done here, go back to the caller.

scroll_text_up:
        move.w  text_delay_counter(pc),d0          ; Load the text delay/row counter.
        beq.b  keyboard_ack_delay                  ; If the last test was zero, take this branch.
        movem.l  d2-d7/a2,-(a7)                    ; Save the registers; this routine is going to make a mess for a bit.
        mulu.w  #$140,d0                           ; Multiply by the stride to reach the right entry.
        movea.l  screen_buffer_ptr(pc),a2          ; A2 points into the screen buffer we are clearing.
        adda.w  d0,a2                              ; Add this in; it advances the current position/counter.
        moveq  #$0,d0                              ; Clear D0 once, then copy that zero into the other registers.
        move.l  d0,d1                              ; Copy the zero into D1.
        move.l  d0,d2                              ; Copy the value into D2.
        move.l  d0,d3                              ; Copy the value into D3.
        move.l  d0,d4                              ; Copy the value into D4.
        move.l  d0,d5                              ; Copy the value into D5.
        move.l  d0,d6                              ; Copy the zero into D6.
        move.l  d0,d7                              ; Copy the zero into D7.
        movea.l  d0,a0                             ; Clear A0 as part of the bulk-zero setup.
        movea.l  d0,a1                             ; Clear A1 as part of the bulk-zero setup.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  d0-d7/a0-a1,-(a2)                 ; Move the whole register block in one go.
        movem.l  (a7)+,d2-d7/a2                    ; Put the registers back before we leave.

keyboard_ack_delay:
        rts                                        ; Done here, go back to the caller.

update_copper_colours:
        lea     text_delay_counter(pc),a0          ; Check the little timer that paces the text.
        cmpi.w  #$70,(a0)                          ; Compare with the marker value used by the next branch.
        bge.b  keyboard_ack_delay                  ; If we have reached the threshold, branch.
        cmpi.w  #$1f,(a0)                          ; Compare with the marker value used by the next branch.
        beq.w  loc_06ea                            ; If the last test was zero, take this branch.
        blt.b  keyboard_ack_delay                  ; If it is still below the threshold, branch.
        move.w  (a0),d0                            ; Read the current script character.
        subi.w  #$20,d0                            ; Back this value up by the amount shown.
        lea     dynamic_copper_wait_buffer(pc),a0         ; Point at the buffer where we build copper waits on the fly.
        lea     copper_waveform_table(pc),a1          ; Use the waveform table for the raster colour motion.
        move.b  (a1,d0.w),d0                       ; Pick the waveform byte for this copper step.
        moveq  #$a,d1                              ; Start the colour spacing at ten; the loop widens it as it goes.
        move.w  text_page_top_y(pc),d3                   ; Load the base raster line for the colour bands.
        moveq  #-1,d2                              ; Load the small step value into D2.
        sf.b  $49(a5)                              ; Clear the flag byte.
        bra.b  loc_066e                            ; Jump straight to the next named step in this little state machine.

loc_0668:
        move.w  d0,d2                              ; Copy the value into D2.
        mulu.w  d1,d2                              ; Multiply by the stride to reach the right entry.
        lsr.l  #$8,d2                              ; Shift the bits into the shape the hardware wants.

loc_066e:
        add.w  d3,d2                               ; Add this in; it advances the current position/counter.
        addi.w  #$19,d2                            ; Add this in; it advances the current position/counter.
        cmpi.w  #$139,d2                           ; Compare with the marker value used by the next branch.
        bgt.b  loc_06de                            ; If it is still above the limit, branch.
        tst.b  $49(a5)                             ; Just test this flag/counter and let the next branch decide.
        bne.b  loc_0690                            ; If the last test was non-zero, take this branch.
        cmpi.w  #$100,d2                           ; Compare with the marker value used by the next branch.
        blt.b  loc_0690                            ; If it is still below the threshold, branch.
        move.l  #$ffdffffe,(a0)+                   ; Insert the copper wrap/wait guard and move on.
        st.b  $49(a5)                              ; Set the flag byte.

loc_0690:
        move.b  d2,(a0)+                           ; Drop d2 into the output stream and advance the pointer.
        move.b  #$9,(a0)+                          ; Write the copper horizontal wait byte.
        move.w  #$fffe,(a0)+                       ; Write the copper wait mask.
        move.w  #$100,(a0)+                        ; Select COLOR00 in the copper stream.
        move.w  #$2200,(a0)+                       ; Write the bright colour value for this band.
        addi.w  #$9,d2                             ; Add this in; it advances the current position/counter.
        cmpi.w  #$139,d2                           ; Compare with the marker value used by the next branch.
        bgt.b  loc_06de                            ; If it is still above the limit, branch.
        tst.b  $49(a5)                             ; Just test this flag/counter and let the next branch decide.
        bne.b  loc_06c2                            ; If the last test was non-zero, take this branch.
        cmpi.w  #$100,d2                           ; Compare with the marker value used by the next branch.
        blt.b  loc_06c2                            ; If it is still below the threshold, branch.
        move.l  #$ffdffffe,(a0)+                   ; Insert the copper wrap/wait guard and move on.
        st.b  $49(a5)                              ; Set the flag byte.

loc_06c2:
        move.b  d2,(a0)+                           ; Drop d2 into the output stream and advance the pointer.
        move.b  #$9,(a0)+                          ; Write the copper horizontal wait byte.
        move.w  #$fffe,(a0)+                       ; Write the copper wait mask.
        move.w  #$100,(a0)+                        ; Select COLOR00 in the copper stream.
        move.w  #$200,(a0)+                        ; Write the dark colour value for this band.
        addi.w  #$28,d1                            ; Add this in; it advances the current position/counter.
        addi.w  #$9,d3                             ; Add this in; it advances the current position/counter.
        bra.b  loc_0668                            ; Jump straight to the next named step in this little state machine.

loc_06de:
        sf.b  $49(a5)                              ; Clear the flag byte.
        moveq  #-2,d0                              ; Use -2 as the copper end marker value.
        move.l  d0,(a0)+                           ; Write this longword and move to the next output slot.
        move.l  d0,(a0)+                           ; Write this longword and move to the next output slot.
        rts                                        ; Done here, go back to the caller.

loc_06ea:
        lea     dynamic_copper_wait_buffer(pc),a0         ; Point at the buffer where we build copper waits on the fly.
        bra.b  loc_06de                            ; Jump straight to the next named step in this little state machine.

render_equalizer_or_logo:
        tst.b  $4a(a5)                             ; Just test this flag/counter and let the next branch decide.
        bne.b  loc_0702                            ; If the last test was non-zero, take this branch.
        move.w  text_delay_counter(pc),d0          ; Load the text delay/row counter.
        beq.b  loc_073c                            ; If the last test was zero, take this branch.
        cmpi.w  #$40,d0                            ; Compare with the marker value used by the next branch.
        bge.b  loc_073a                            ; If we have reached the threshold, branch.

loc_0702:
        not.b  $4c(a5)                             ; Flip the flag so this bit of animation only runs every other frame.
        beq.b  loc_073a                            ; If the last test was zero, take this branch.
        lea     logo_bar_ease_state_table(pc),a0       ; Open the small table holding current and target bar positions.
        move.w  #$3,d3                             ; Do four bar entries, counted with DBRA.
        sf.b  d4                                   ; Clear the flag byte.
        move.w  (a0),d0                            ; Read the current script character.
        move.w  #$312,d1                           ; Use $312 as the target packed bar value.
        move.w  #$1,d2                             ; Ease by one nibble-step at a time.
        bsr.b  loc_0752                            ; Ease one packed bar value toward its target.
        cmp.w  d1,d0                               ; Compare the two values; the next branch does the talking.
        beq.b  loc_0724                            ; If the last test was zero, take this branch.
        st.b  d4                                   ; Set the flag byte.

loc_0724:
        move.w  d0,(a0)                            ; Store d0 at the current pointer without moving it.
        addq.w  #$4,a0                             ; Add this in; it advances the current position/counter.
        dbra  d3,$712                              ; Loop until the DBRA counter runs out.
        tst.b  $4a(a5)                             ; Just test this flag/counter and let the next branch decide.
        beq.b  loc_073a                            ; If the last test was zero, take this branch.
        tst.b  d4                                  ; Just test this flag/counter and let the next branch decide.
        bne.b  loc_073a                            ; If the last test was non-zero, take this branch.
        st.b  $4b(a5)                              ; Set the flag byte.

loc_073a:
        rts                                        ; Done here, go back to the caller.

loc_073c:
        lea     logo_bar_ease_state_table(pc),a0       ; Open the small table holding current and target bar positions.
        move.w  #$0,(a0)                           ; Reset this bar current value to zero.
        addq.w  #$4,a0                             ; Add this in; it advances the current position/counter.
        move.w  #$cbd,(a0)                         ; Set this bar target value.
        addq.w  #$4,a0                             ; Add this in; it advances the current position/counter.
        move.w  #$cbd,(a0)                         ; Set this bar target value.
        rts                                        ; Done here, go back to the caller.

loc_0752:
        movem.l  d2-d6/a0,-(a7)                    ; Save the registers; this routine is going to make a mess for a bit.
        move.w  #$f,d5                             ; Start with a one-nibble mask.
        swap  d5                                   ; Swap the address halves; copper wants high word and low word separately.
        move.w  d2,d5                              ; Put the step size into the low word of D5.
        moveq  #$0,d4                              ; Load a small quick constant into d4.
        moveq  #$2,d6                              ; Load a small quick constant into d6.

loc_0762:
        move.w  d0,d2                              ; Copy the value into D2.
        move.w  d1,d3                              ; Copy the target value into D3.
        swap  d5                                   ; Swap the address halves; copper wants high word and low word separately.
        and.w  d5,d2                               ; Keep only the bits we actually care about.
        and.w  d5,d3                               ; Keep only the bits we actually care about.
        swap  d5                                   ; Swap the address halves; copper wants high word and low word separately.
        cmp.w  d2,d3                               ; Compare the two values; the next branch does the talking.
        beq.b  loc_0786                            ; If the last test was zero, take this branch.
        bcs.b  loc_077e                            ; Branch on carry; here that means the rounded value is still below target.
        add.w  d5,d2                               ; Add this in; it advances the current position/counter.
        cmp.w  d2,d3                               ; Compare the two values; the next branch does the talking.
        bge.b  loc_0786                            ; If we have reached the threshold, branch.
        move.w  d3,d2                              ; Clamp the current nibble to the target value.
        bra.b  loc_0786                            ; Jump straight to the next named step in this little state machine.

loc_077e:
        sub.w  d5,d2                               ; Back this value up by the amount shown.
        cmp.w  d2,d3                               ; Compare the two values; the next branch does the talking.
        ble.b  loc_0786                            ; Stop here when the byte is a control/end marker.
        move.w  d3,d2                              ; Clamp the current nibble to the target value.

loc_0786:
        or.w  d2,d4                                ; Fold these hardware bits into our saved copy.
        lsl.l  #$4,d5                              ; Shift the bits into the shape the hardware wants.
        bpl.b  loc_0762                            ; Keep stepping through the nibbles until the mask wraps.
        move.w  d4,d0                              ; Return the rebuilt packed value in D0.
        movem.l  (a7)+,d2-d6/a0                    ; Put the registers back before we leave.
        rts                                        ; Done here, go back to the caller.

blitter_fill_step:
        tst.b  $4a(a5)                             ; Just test this flag/counter and let the next branch decide.
        bne.b  loc_07ce                            ; If the last test was non-zero, take this branch.
        lea     logo_motion_height_script(pc),a0        ; Read the next height byte from the logo motion script.
        adda.w  logo_motion_script_offset(pc),a0                   ; Add this in; it advances the current position/counter.
        move.b  (a0),d1                            ; Read the current script byte into D1.
        beq.w  keyboard_ack_delay                  ; If the last test was zero, take this branch.
        addq.w  #$1,$44(a5)                        ; Add this in; it advances the current position/counter.
        lea     logo_strip_top_blit_words(pc),a0                   ; Point at one of the three packed logo strips.
        move.w  #$198,d0                           ; Start drawing the logo strip around line $198.
        ext.w  d1                                  ; Sign-extend it so the word math behaves.
        moveq  #$9,d2                              ; Load the small step value into D2.
        bsr.b  loc_07fe                            ; Patch this strip through the shared helper.
        lea     logo_strip_middle_blit_words(pc),a0                   ; Point at one of the three packed logo strips.
        addi.w  #$10,d0                            ; Add this in; it advances the current position/counter.
        bsr.b  loc_07fe                            ; Patch this strip through the shared helper.
        lea     logo_strip_bottom_blit_words(pc),a0                   ; Point at one of the three packed logo strips.
        addi.w  #$10,d0                            ; Add this in; it advances the current position/counter.
        bra.b  loc_07fe                            ; Jump straight to the next named step in this little state machine.

loc_07ce:
        move.w  logo_exit_base_y(pc),d0                   ; Load the reverse/exit animation base line.
        addq.w  #$4,$46(a5)                        ; Add this in; it advances the current position/counter.
        lea     logo_motion_height_script(pc),a0        ; Read the next height byte from the logo motion script.
        adda.w  logo_motion_script_offset(pc),a0                   ; Add this in; it advances the current position/counter.
        subq.w  #$1,a0                             ; Back this value up by the amount shown.
        move.b  (a0),d1                            ; Read the current script byte into D1.
        ext.w  d1                                  ; Sign-extend it so the word math behaves.
        moveq  #$9,d2                              ; Load the small step value into D2.
        lea     logo_strip_top_blit_words(pc),a0                   ; Point at one of the three packed logo strips.
        bsr.b  loc_07fe                            ; Patch this strip through the shared helper.
        lea     logo_strip_middle_blit_words(pc),a0                   ; Point at one of the three packed logo strips.
        addi.w  #$10,d0                            ; Add this in; it advances the current position/counter.
        bsr.b  loc_07fe                            ; Patch this strip through the shared helper.
        lea     logo_strip_bottom_blit_words(pc),a0                   ; Point at one of the three packed logo strips.
        addi.w  #$10,d0                            ; Add this in; it advances the current position/counter.

loc_07fe:
        movem.w  d0-d2,-(a7)                       ; Save the registers; this routine is going to make a mess for a bit.
        exg.l  d0,d2                               ; Swap the registers so the helper can reuse the same path.
        movem.w  d0/d2,-(a7)                       ; Save the registers; this routine is going to make a mess for a bit.
        move.w  d1,d2                              ; Copy the signed motion value into D2.
        clr.w  d0                                  ; Clear the word; this resets that bit of state.
        clr.w  d1                                  ; Clear the word; this resets that bit of state.
        btst    #$8,d2                             ; Keep the original machine operation in place.
        beq.b  loc_0818                            ; If the last test was zero, take this branch.
        bset    #$2,d1                             ; Keep the original machine operation in place.

loc_0818:
        lsl.w  #$8,d2                              ; Shift the bits into the shape the hardware wants.
        or.w  d2,d0                                ; Fold these hardware bits into our saved copy.
        lsr.w  #$8,d2                              ; Shift the bits into the shape the hardware wants.
        add.w  (a7)+,d2                            ; Add this in; it advances the current position/counter.
        btst    #$8,d2                             ; Keep the original machine operation in place.
        beq.b  loc_082a                            ; If the last test was zero, take this branch.
        bset    #$1,d1                             ; Keep the original machine operation in place.

loc_082a:
        lsl.w  #$8,d2                              ; Shift the bits into the shape the hardware wants.
        or.w  d2,d1                                ; Fold these hardware bits into our saved copy.
        move.w  (a7)+,d2                           ; Restore D2 from the temporary word on the stack.
        lsr.w  #$1,d2                              ; Shift the bits into the shape the hardware wants.
        bcc.b  loc_0838                            ; Branch when no carry was produced by the previous shift or compare.
        bset    #$0,d1                             ; Keep the original machine operation in place.

loc_0838:
        or.w  d2,d0                                ; Fold these hardware bits into our saved copy.
        movem.w  d0-d1,(a0)                        ; Move the whole register block in one go.
        movem.w  (a7)+,d0-d2                       ; Put the registers back before we leave.
        rts                                        ; Done here, go back to the caller.

setup_audio_dma:
        lea     audio_click_sample(pc),a0                   ; Point both audio channels at the tiny click sample.
        move.l  a0,$a0(a6)                         ; Write a0 to custom-chip register $a0(a6), so the display or audio state changes immediately.
        move.l  a0,$b0(a6)                         ; Write a0 to custom-chip register $b0(a6), so the display or audio state changes immediately.
        move.w  #$c,$a4(a6)                        ; Set audio channel 0 length to 12 words.
        move.w  #$c,$b4(a6)                        ; Set audio channel 1 length to 12 words.
        move.w  #$0,$a8(a6)                        ; Silence audio channel 0.
        move.w  #$0,$b8(a6)                        ; Silence audio channel 1.
        move.w  #$10e,$a6(a6)                      ; Set audio channel 0 period.
        move.w  #$10e,$b6(a6)                      ; Set audio channel 1 period.
        move.w  #$800f,$96(a6)                     ; Enable the audio DMA bits.
        bra.b  reset_beep_script_pointer           ; Jump straight to the next named step in this little state machine.

drive_typewriter_beep:
        subq.w  #$1,$50(a5)                        ; Back this value up by the amount shown.
        bgt.w  loc_08a4                            ; If it is still above the limit, branch.
        not.b  $5c(a5)                             ; Flip the flag so this bit of animation only runs every other frame.
        bne.b  loc_08a6                            ; If the last test was non-zero, take this branch.
        move.w  #$6,$50(a5)                        ; Wait six ticks before the next click phase.

loc_0890:
        move.w  #$0,$a8(a6)                        ; Silence audio channel 0.
        move.w  #$0,$b8(a6)                        ; Silence audio channel 1.
        bset.b  #$1,CIAA_PRA_JOY_MOUSE             ; Set the CIA bit; that gates the click pulse.

loc_08a4:
        rts                                        ; Done here, go back to the caller.

loc_08a6:
        movea.l  beep_script_ptr(pc),a0            ; Fetch the current click-script pointer.
        move.w  #$3,d1                             ; Default click pause is three ticks.
        move.b  (a0)+,d0                           ; Read the next byte and advance the pointer.
        movem.l  a0,$52(a5)                        ; Move the whole register block in one go.
        beq.b  loc_08d2                            ; If the last test was zero, take this branch.
        bmi.b  loc_08ce                            ; Branch when the script byte is negative, which marks a longer pause.
        cmpi.b  #$20,d0                            ; Compare with the marker value used by the next branch.
        beq.b  loc_08c6                            ; If the last test was zero, take this branch.
        pea     loc_08a6(pc)                       ; Push a return address by hand, so the shared note routine can fall back here.
        bra.b  advance_beep_script_pointer         ; Jump straight to the next named step in this little state machine.

loc_08c6:
        move.w  #$f,$50(a5)                        ; Use a longer pause for a space in the script.
        bra.b  loc_0890                            ; Jump straight to the next named step in this little state machine.

loc_08ce:
        move.w  #$c,d1                             ; Use a longer pause for the negative script marker.

loc_08d2:
        move.w  d1,$50(a5)                         ; Stash d1 in the intro runtime block at $50(a5); we will need it again next frame.
        move.w  #$40,$a8(a6)                       ; Bring audio channel 0 volume up for the click.
        move.w  #$40,$b8(a6)                       ; Bring audio channel 1 volume up for the click.
        bclr.b  #$1,CIAA_PRA_JOY_MOUSE             ; Clear the CIA bit and finish the click pulse.
        rts                                        ; Done here, go back to the caller.

reset_beep_script_pointer:
        lea     beep_period_table(pc),a0           ; Go back to the period table for the click melody.
        move.l  a0,$52(a5)                         ; Stash a0 in the intro runtime block at $52(a5); we will need it again next frame.
        rts                                        ; Done here, go back to the caller.

advance_beep_script_pointer:
        lea     beep_script_stream(pc),a0          ; Find the current note letter in the beeper script.
        adda.w  beep_script_char_index(pc),a0                   ; Add this in; it advances the current position/counter.
        addq.w  #$1,$4e(a5)                        ; Add this in; it advances the current position/counter.
        move.b  (a0),d0                            ; Read the current script character.
        bne.b  loc_090c                            ; If the last test was non-zero, take this branch.
        clr.w  $4e(a5)                             ; Clear the word; this resets that bit of state.
        bra.b  advance_beep_script_pointer         ; Jump straight to the next named step in this little state machine.

loc_090c:
        lea     beep_note_alphabet(pc),a0          ; Use this alphabet to turn script characters into note offsets.
        moveq  #-1,d1                              ; Start the note lookup at -1 because the loop increments before comparing.

loc_0912:
        addq.w  #$1,d1                             ; Add this in; it advances the current position/counter.
        cmp.b  (a0)+,d0                            ; Compare the two values; the next branch does the talking.
        bne.b  loc_0912                            ; If the last test was non-zero, take this branch.
        lea     beep_period_table(pc),a0           ; Go back to the period table for the click melody.
        clr.w  d0                                  ; Clear the word; this resets that bit of state.
        subq.w  #$1,d1                             ; Back this value up by the amount shown.
        bmi.b  loc_092a                            ; Branch when the script byte is negative, which marks a longer pause.
        move.b  (a0)+,d0                           ; Read the next byte and advance the pointer.
        adda.w  d0,a0                              ; Add this in; it advances the current position/counter.
        dbra  d1,$922                              ; Loop until the DBRA counter runs out.

loc_092a:
        addq.w  #$1,a0                             ; Add this in; it advances the current position/counter.
        move.l  a0,$52(a5)                         ; Stash a0 in the intro runtime block at $52(a5); we will need it again next frame.
        rts                                        ; Done here, go back to the caller.


; ---------------------------------------------------------------------------
; Runtime data,copper/font/audio tables and buffers
; ---------------------------------------------------------------------------
graphics_library_name:
        ; Exec/OpenLibrary sees this as the library name. The intro also uses
        ; the bytes after it as a tiny runtime variable block, so keep the
        ; trailing even alignment exactly where the original had two zeros.
        dc.b    "graphics.library",0
        even

gfxbase_ptr:
        dc.l    0                       ; OpenLibrary("graphics.library") result, used again during cleanup.

saved_active_view_ptr:
        dc.l    0                       ; GfxBase+$22, the View pointer restored with LoadView.

saved_dmacon_bits:
        dc.w    $8000                   ; Starts with the SET/CLR bit, then ORs in DMACONR.

saved_intena_bits:
        dc.w    $8000                   ; Starts with the SET/CLR bit, then ORs in INTENAR.

saved_level3_vector:
        dc.l    0                       ; Original level-3 interrupt vector, restored on exit.

exception_vector_base:
        dc.b    $00,$00,$00,$00                                                 ; 000954  ....

screen_buffer_ptr:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                 ; 000958  ............

current_text_ptr:
        dc.b    $00,$00,$00,$00                                                 ; 000964  ....

text_row_index:
        dc.b    $00,$00                                                         ; 000968  ..

text_column_pixel:
        dc.b    $00,$00                                                         ; 00096a  ..

text_page_top_y:
        ; The text code writes the current page's top Y here. The copper colour
        ; builder reads it back as the base raster line for the moving bands.
        dc.b    $00,$00                                                         ; 00096c  ..

text_initial_y:
        dc.b    $00,$00,$00,$00                                                 ; 00096e  ....

text_delay_counter:
        dc.b    $00,$00,$00,$00                                                 ; 000972  ....

logo_motion_script_offset:
        ; Offset into logo_motion_height_script. The logo animation increments
        ; this while the three packed logo strips move through their script.
        dc.b    $00,$00                                                         ; 000976  ..

logo_exit_base_y:
        dc.w    $0198                   ; Base raster line used when the logo runs its exit/reverse pass.
runtime_unused_byte_097a:
        dc.b    0
copper_wrap_inserted_flag:
        dc.b    0                       ; Set once a copper wait crosses line $100.
intro_exit_requested_flag:
        dc.b    0                       ; Set by the mouse/fire button in the VBlank handler.
intro_done_flag:
        dc.b    0                       ; Main code waits for this before restoring the system.
logo_frame_toggle_flag:
        dc.b    0                       ; Flipped every VBlank to slow the bar easing down.
runtime_unused_byte_097f:
        dc.b    0

beep_script_char_index:
        dc.l    0                       ; Character index into beep_script_stream.

beep_script_ptr:
        dc.b    $00,$00,$00,$00                                                 ; 000984  ....

main_text_stream_ptr:
        dc.b    $00,$00,$00,$00,$00,$00,$00                                     ; 000988  .......

beep_script_stream:
        dc.b    $01,$69,$6e,$74,$72,$6f,$63,$6f,$64,$65,$64,$62,$79,$6d,$61,$64 ; 00098f  .introcodedbymad
        dc.b    $69,$73,$6f,$6e,$6f,$66,$74,$2e,$72,$2e,$73,$2e,$69,$2e,$00     ; 00099f  isonoft.r.s.i..

audio_click_sample:
        ; Tiny signed-ish click waveform. setup_audio_dma points both AUD0 and
        ; AUD1 at this buffer and uses a length of 12 words.
        dc.b    $00,$20,$40,$60,$6e,$7f,$7f,$7f,$6e,$60,$40,$20,$00,$e0,$c0,$a0 ; 0009ae  . @`n...n`@ ....
        dc.b    $92,$81,$81,$81,$9c,$a0,$c0,$e0                                 ; 0009be  ........

beep_note_alphabet:
        dc.b    $61,$e4,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f ; 0009c6  a.bcdefghijklmno
        dc.b    $f6,$70,$71,$72,$73,$74,$75,$fc,$76,$77,$78,$79,$7a,$31,$32,$33 ; 0009d6  .pqrstu.vwxyz123
        dc.b    $34,$35,$36,$37,$38,$39,$30,$2e,$2c,$3a,$2d,$27,$28,$29,$3f,$22 ; 0009e6  4567890.,:-'()?"
        dc.b    $00,$01                                                         ; 0009f6  ..

beep_period_table:
        dc.b    $02,$00,$ff,$04,$00,$ff,$00,$ff,$04,$ff,$00,$00,$00,$04,$ff,$00 ; 0009f8  ................
        dc.b    $ff,$00,$03,$ff,$00,$00,$01,$00,$04,$00,$00,$ff,$00,$03,$ff,$ff ; 000a08  ................
        dc.b    $00,$04,$00,$00,$00,$00,$02,$00,$00,$04,$00,$ff,$ff,$ff,$03,$ff ; 000a18  ................
        dc.b    $00,$ff,$04,$00,$ff,$00,$00,$02,$ff,$ff,$02,$ff,$00,$03,$ff,$ff ; 000a28  ................
        dc.b    $ff,$04,$ff,$ff,$ff,$00,$04,$00,$ff,$ff,$00,$04,$ff,$ff,$00,$ff ; 000a38  ................
        dc.b    $03,$ff,$00,$ff,$03,$00,$00,$00,$01,$ff,$03,$00,$00,$ff,$04,$00 ; 000a48  ................
        dc.b    $00,$ff,$ff,$04,$00,$00,$00,$ff,$03,$00,$ff,$ff,$04,$ff,$00,$00 ; 000a58  ................
        dc.b    $ff,$04,$ff,$00,$ff,$ff,$04,$ff,$ff,$00,$00,$05,$00,$ff,$ff,$ff ; 000a68  ................
        dc.b    $ff,$05,$00,$00,$ff,$ff,$ff,$05,$00,$00,$00,$ff,$ff,$05,$00,$00 ; 000a78  ................
        dc.b    $00,$00,$ff,$05,$00,$00,$00,$00,$00,$05,$ff,$00,$00,$00,$00,$05 ; 000a88  ................
        dc.b    $ff,$ff,$00,$00,$00,$05,$ff,$ff,$ff,$00,$00,$05,$ff,$ff,$ff,$ff ; 000a98  ................
        dc.b    $00,$05,$ff,$ff,$ff,$ff,$ff,$06,$00,$ff,$00,$ff,$00,$ff,$06,$ff ; 000aa8  ................
        dc.b    $ff,$00,$00,$ff,$ff,$06,$ff,$ff,$ff,$00,$00,$00,$06,$ff,$00,$00 ; 000ab8  ................
        dc.b    $00,$00,$ff,$06,$00,$ff,$ff,$ff,$ff,$00,$06,$ff,$00,$ff,$ff,$00 ; 000ac8  ................
        dc.b    $ff,$06,$ff,$00,$ff,$ff,$00,$ff,$06,$00,$00,$ff,$ff,$00,$00,$06 ; 000ad8  ................
        dc.b    $00,$ff,$00,$00,$ff,$00,$06,$00,$00,$00,$ff,$00,$ff,$05,$ff,$00 ; 000ae8  ................
        dc.b    $ff,$00,$ff,$01                                                 ; 000af8  ....

logo_motion_height_script:
        ; Height/offset script for the three small logo strips below. Each
        ; VBlank takes one byte, feeds it into loc_07fe, and stops on zero.
        dc.b    $1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1f,$22,$26,$28,$2b,$2c ; 000afc  ..........."&(+,
        dc.b    $2d,$2b,$27,$25,$25,$27,$2b,$2d,$2b,$2d,$00                     ; 000b0c  -+'%%'+-+-.

font_width_table:
        dc.b    $06,$03,$06,$08,$07,$07,$08,$04,$05,$05,$08,$07,$04,$07,$03,$07 ; 000b17  ................
        dc.b    $07,$04,$07,$07,$08,$07,$07,$07,$07,$07,$03,$04,$06,$07,$06,$07 ; 000b27  ................
        dc.b    $08,$07,$07,$07,$07,$07,$07,$07,$07,$03,$07,$07,$07,$08,$07,$07 ; 000b37  ................
        dc.b    $07,$07,$07,$07,$07,$07,$07,$08,$08,$07,$07,$05,$07,$05,$08,$08 ; 000b47  ................
        dc.b    $04,$07,$07,$07,$07,$07,$05,$07,$07,$03,$05,$07,$05,$08,$07,$07 ; 000b57  ................
        dc.b    $07,$07,$07,$07,$07,$07,$07,$08,$08,$07,$07,$08,$08,$08,$02     ; 000b67  ...............

copper_waveform_table:
        ; Signed-looking waveform used while rebuilding the dynamic copper
        ; waits. Think of it as the little sine-ish table that makes the raster
        ; colour bands breathe instead of moving linearly.
        dc.b    $ff,$ff,$fe,$fd,$fb,$f9,$f7,$f4,$f1,$ed,$ea,$e5,$e1,$dc,$d7,$d1 ; 000b76  ................
        dc.b    $cb,$c5,$bf,$b8,$b1,$a9,$a2,$9a,$92,$89,$81,$78,$6f,$66,$5d,$54 ; 000b86  ...........xof]T
        dc.b    $4a,$40,$37,$2d,$23,$19,$0f,$05,$05,$0f,$19,$23,$2c,$36,$3f,$47 ; 000b96  J@7-#......#,6?G
        dc.b    $4f,$57,$5e,$65,$6a,$70,$74,$78,$7b,$7e,$7f,$80,$80,$7f,$7e,$7b ; 000ba6  OW^ejptx{~....~{
        dc.b    $78,$74,$70,$6a,$65,$5e,$57,$4f,$47,$3f,$36,$2c,$23,$19,$0f,$05 ; 000bb6  xtpje^WOG?6,#...

copper_colour_table:
        dc.b    $00,$00,$06,$d4,$00,$00,$07,$00,$00,$00,$07,$2c,$00,$00,$06,$fc ; 000bc6  ...........,....
        dc.b    $00,$00,$06,$fc,$00,$00,$06,$fc,$00,$00,$06,$fc,$00,$00,$06,$fc ; 000bd6  ................
        dc.b    $01,$06,$00,$00,$01,$fc,$00,$00                                 ; 000be6  ........

copper_runtime_list:
        dc.b    $00,$8e,$19,$81,$00,$90,$39,$c1,$00,$92,$00,$38,$00,$94,$00,$d0 ; 000bee  ......9....8....
        dc.b    $01,$00,$22,$00,$01,$02,$00,$01,$01,$04,$00,$00,$01,$08,$00,$00 ; 000bfe  ..".............
        dc.b    $01,$0a,$00,$00,$01,$80,$03,$12,$01,$82                         ; 000c0e  ..........

logo_bar_ease_state_table:
        ; Current/target words for the animated copper/logo bars. The code in
        ; render_equalizer_or_logo eases the current value toward the target
        ; nibble by nibble, so the movement feels stepped but deliberate.
        dc.b    $00,$00,$01,$84,$0c,$bd,$01,$86,$0c,$bd,$01,$a0,$00,$00,$01,$a2 ; 000c18  ................
        dc.b    $00,$00,$01,$a4,$0a,$9b,$01,$a6,$0c,$bd,$01,$a8,$00,$00,$01,$aa ; 000c28  ................
        dc.b    $00,$00,$01,$ac,$0a,$9b,$01,$ae,$0c,$bd,$01,$20                 ; 000c38  ........... 

copper_bpl_pointer_words:
        dc.b    $00,$00,$01,$22,$00,$00,$01,$24,$00,$00,$01,$26,$00,$00,$01,$28 ; 000c44  ..."...$...&...(
        dc.b    $00,$00,$01,$2a,$00,$00,$01,$2c,$00,$00,$01,$2e,$00,$00,$01,$30 ; 000c54  ...*...,.......0
        dc.b    $00,$00,$01,$32,$00,$00,$01,$34,$00,$00,$01,$36,$00,$00,$01,$38 ; 000c64  ...2...4...6...8
        dc.b    $00,$00,$01,$3a,$00,$00,$01,$3c,$00,$00,$01,$3e,$00,$00,$00,$e0 ; 000c74  ...:...<...>....

bitplane_a:
        dc.b    $00,$00,$00,$e2,$00,$00,$00,$e4,$00,$00,$00,$e6,$00,$00         ; 000c84  ..............

dynamic_copper_wait_buffer:
        ; Runtime-built copper wait/colour command buffer. The original image
        ; stores this as 1536 zero bytes; ds.b keeps the binary identical
        ; without making us stare at pages of zeros.
        ds.b    1536
dynamic_copper_wait_buffer_end:
        dc.l    $fffffffe,$fffffffe       ; Initial copper end markers after the empty runtime buffer.

logo_strip_top_blit_words:
        ; First of the three packed logo/bar strips. loc_07fe patches the
        ; first few words from the motion script so the strip slides/breathes.
        dc.b    $1c,$cc,$25,$00,$6c,$38,$6c,$7c,$fe,$7c,$fe,$d6,$ff,$fb,$fe,$92 ; 00129a  ..%.l8l|.|......
        dc.b    $7f,$eb,$7c,$aa,$3e,$55,$38,$c6,$1c,$3b,$10,$7c,$08,$3e,$00,$00 ; 0012aa  ..|.>U8..;.|.>..
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                 ; 0012ba  ............

logo_strip_middle_blit_words:
        ; Second strip, handled with the same helper but drawn 16 pixels lower.
        dc.b    $1c,$d4,$25,$00,$00,$fc,$00,$fc,$19,$7e,$19,$fc,$4f,$fb,$4f,$37 ; 0012c6  ..%......~..O.O7
        dc.b    $e7,$bf,$e6,$34,$7f,$3e,$4f,$34,$3f,$bb,$19,$b7,$0c,$eb,$00,$30 ; 0012d6  ...4.>O4?......0
        dc.b    $00,$18,$00,$20,$00,$10,$00,$00,$00,$00,$00,$00                 ; 0012e6  ... ........

logo_strip_bottom_blit_words:
        ; Third strip, another 16 pixels down; together the three tables make
        ; the small animated Delirium logo/bar graphic.
        dc.b    $1c,$dc,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$c0,$00,$80,$00 ; 0012f2  ..%.............
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$c0,$00,$80,$00,$00,$00,$00,$00 ; 001302  ................
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                 ; 001312  ............

font_glyph_data:
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00131e  ................
        dc.b    $c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$00,$00,$c0,$00,$00,$00 ; 00132e  ................
        dc.b    $d8,$00,$d8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00133e  ................
        dc.b    $6c,$00,$6c,$00,$fe,$00,$6c,$00,$fe,$00,$6c,$00,$6c,$00,$00,$00 ; 00134e  l.l...l...l.l...
        dc.b    $30,$00,$7c,$00,$c0,$00,$78,$00,$0c,$00,$f8,$00,$30,$00,$00,$00 ; 00135e  0.|...x.....0...
        dc.b    $c4,$00,$cc,$00,$18,$00,$30,$00,$60,$00,$cc,$00,$8c,$00,$00,$00 ; 00136e  ......0.`.......
        dc.b    $38,$00,$6c,$00,$68,$00,$76,$00,$dc,$00,$cc,$00,$76,$00,$00,$00 ; 00137e  8.l.h.v.....v...
        dc.b    $60,$00,$60,$00,$c0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00138e  `.`.............
        dc.b    $30,$00,$60,$00,$c0,$00,$c0,$00,$c0,$00,$60,$00,$30,$00,$00,$00 ; 00139e  0.`.......`.0...
        dc.b    $c0,$00,$60,$00,$30,$00,$30,$00,$30,$00,$60,$00,$c0,$00,$00,$00 ; 0013ae  ..`.0.0.0.`.....
        dc.b    $00,$00,$6c,$00,$38,$00,$fe,$00,$38,$00,$6c,$00,$00,$00,$00,$00 ; 0013be  ..l.8...8.l.....
        dc.b    $00,$00,$30,$00,$30,$00,$fc,$00,$30,$00,$30,$00,$00,$00,$00,$00 ; 0013ce  ..0.0...0.0.....
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$00,$60,$00,$c0,$00 ; 0013de  ..........`.`...
        dc.b    $00,$00,$00,$00,$00,$00,$fc,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 0013ee  ................
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$c0,$00,$c0,$00,$00,$00 ; 0013fe  ................
        dc.b    $04,$00,$0c,$00,$18,$00,$30,$00,$60,$00,$c0,$00,$80,$00,$00,$00 ; 00140e  ......0.`.......
        dc.b    $78,$00,$cc,$00,$dc,$00,$fc,$00,$ec,$00,$cc,$00,$78,$00,$00,$00 ; 00141e  x...........x...
        dc.b    $60,$00,$e0,$00,$60,$00,$60,$00,$60,$00,$60,$00,$60,$00,$00,$00 ; 00142e  `...`.`.`.`.`...
        dc.b    $78,$00,$cc,$00,$0c,$00,$18,$00,$30,$00,$60,$00,$fc,$00,$00,$00 ; 00143e  x.......0.`.....
        dc.b    $fc,$00,$0c,$00,$18,$00,$38,$00,$0c,$00,$cc,$00,$78,$00,$00,$00 ; 00144e  ......8.....x...
        dc.b    $1c,$00,$3c,$00,$6c,$00,$cc,$00,$fe,$00,$0c,$00,$0c,$00,$00,$00 ; 00145e  ..<.l...........
        dc.b    $fc,$00,$c0,$00,$f8,$00,$0c,$00,$0c,$00,$cc,$00,$78,$00,$00,$00 ; 00146e  ............x...
        dc.b    $18,$00,$30,$00,$60,$00,$f8,$00,$cc,$00,$cc,$00,$78,$00,$00,$00 ; 00147e  ..0.`.......x...
        dc.b    $fc,$00,$0c,$00,$0c,$00,$18,$00,$30,$00,$30,$00,$30,$00,$00,$00 ; 00148e  ........0.0.0...
        dc.b    $78,$00,$cc,$00,$cc,$00,$78,$00,$cc,$00,$cc,$00,$78,$00,$00,$00 ; 00149e  x.....x.....x...
        dc.b    $78,$00,$cc,$00,$cc,$00,$7c,$00,$18,$00,$30,$00,$60,$00,$00,$00 ; 0014ae  x.....|...0.`...
        dc.b    $00,$00,$c0,$00,$c0,$00,$00,$00,$00,$00,$c0,$00,$c0,$00,$00,$00 ; 0014be  ................
        dc.b    $00,$00,$00,$00,$60,$00,$60,$00,$00,$00,$60,$00,$60,$00,$c0,$00 ; 0014ce  ....`.`...`.`...
        dc.b    $18,$00,$30,$00,$60,$00,$c0,$00,$60,$00,$30,$00,$18,$00,$00,$00 ; 0014de  ..0.`...`.0.....
        dc.b    $00,$00,$00,$00,$fc,$00,$00,$00,$00,$00,$fc,$00,$00,$00,$00,$00 ; 0014ee  ................
        dc.b    $c0,$00,$60,$00,$30,$00,$18,$00,$30,$00,$60,$00,$c0,$00,$00,$00 ; 0014fe  ..`.0...0.`.....
        dc.b    $78,$00,$cc,$00,$c0,$00,$60,$00,$30,$00,$00,$00,$30,$00,$00,$00 ; 00150e  x.....`.0...0...
        dc.b    $7c,$00,$c6,$00,$de,$00,$de,$00,$de,$00,$c0,$00,$7c,$00,$00,$00 ; 00151e  |...........|...
        dc.b    $78,$00,$cc,$00,$cc,$00,$fc,$00,$cc,$00,$cc,$00,$cc,$00,$00,$00 ; 00152e  x...............
        dc.b    $f8,$00,$cc,$00,$cc,$00,$f8,$00,$cc,$00,$cc,$00,$f8,$00,$00,$00 ; 00153e  ................
        dc.b    $78,$00,$cc,$00,$c0,$00,$c0,$00,$c0,$00,$cc,$00,$78,$00,$00,$00 ; 00154e  x...........x...
        dc.b    $f0,$00,$d8,$00,$cc,$00,$cc,$00,$cc,$00,$d8,$00,$f0,$00,$00,$00 ; 00155e  ................
        dc.b    $7c,$00,$c0,$00,$c0,$00,$f8,$00,$c0,$00,$c0,$00,$7c,$00,$00,$00 ; 00156e  |...........|...
        dc.b    $7c,$00,$c0,$00,$c0,$00,$f8,$00,$c0,$00,$c0,$00,$c0,$00,$00,$00 ; 00157e  |...............
        dc.b    $78,$00,$cc,$00,$c0,$00,$dc,$00,$cc,$00,$cc,$00,$7c,$00,$00,$00 ; 00158e  x...........|...
        dc.b    $cc,$00,$cc,$00,$cc,$00,$fc,$00,$cc,$00,$cc,$00,$cc,$00,$00,$00 ; 00159e  ................
        dc.b    $c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$00,$00 ; 0015ae  ................
        dc.b    $0c,$00,$0c,$00,$0c,$00,$0c,$00,$0c,$00,$cc,$00,$78,$00,$00,$00 ; 0015be  ............x...
        dc.b    $cc,$00,$cc,$00,$d8,$00,$f0,$00,$d8,$00,$cc,$00,$cc,$00,$00,$00 ; 0015ce  ................
        dc.b    $c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$7c,$00,$00,$00 ; 0015de  ............|...
        dc.b    $c6,$00,$ee,$00,$fe,$00,$d6,$00,$c6,$00,$c6,$00,$c6,$00,$00,$00 ; 0015ee  ................
        dc.b    $cc,$00,$ec,$00,$fc,$00,$dc,$00,$cc,$00,$cc,$00,$cc,$00,$00,$00 ; 0015fe  ................
        dc.b    $78,$00,$cc,$00,$cc,$00,$cc,$00,$cc,$00,$cc,$00,$78,$00,$00,$00 ; 00160e  x...........x...
        dc.b    $f8,$00,$cc,$00,$cc,$00,$f8,$00,$c0,$00,$c0,$00,$c0,$00,$00,$00 ; 00161e  ................
        dc.b    $78,$00,$cc,$00,$cc,$00,$cc,$00,$cc,$00,$dc,$00,$78,$00,$0c,$00 ; 00162e  x...........x...
        dc.b    $f8,$00,$cc,$00,$cc,$00,$f8,$00,$f0,$00,$d8,$00,$cc,$00,$00,$00 ; 00163e  ................
        dc.b    $78,$00,$cc,$00,$c0,$00,$78,$00,$0c,$00,$cc,$00,$78,$00,$00,$00 ; 00164e  x.....x.....x...
        dc.b    $fc,$00,$30,$00,$30,$00,$30,$00,$30,$00,$30,$00,$30,$00,$00,$00 ; 00165e  ..0.0.0.0.0.0...
        dc.b    $cc,$00,$cc,$00,$cc,$00,$cc,$00,$cc,$00,$cc,$00,$78,$00,$00,$00 ; 00166e  ............x...
        dc.b    $cc,$00,$cc,$00,$cc,$00,$cc,$00,$d8,$00,$f0,$00,$e0,$00,$00,$00 ; 00167e  ................
        dc.b    $c6,$00,$c6,$00,$c6,$00,$d6,$00,$fe,$00,$ee,$00,$c6,$00,$00,$00 ; 00168e  ................
        dc.b    $c6,$00,$c6,$00,$6c,$00,$38,$00,$6c,$00,$c6,$00,$c6,$00,$00,$00 ; 00169e  ....l.8.l.......
        dc.b    $cc,$00,$cc,$00,$cc,$00,$78,$00,$30,$00,$30,$00,$30,$00,$00,$00 ; 0016ae  ......x.0.0.0...
        dc.b    $fc,$00,$0c,$00,$18,$00,$30,$00,$60,$00,$c0,$00,$fc,$00,$00,$00 ; 0016be  ......0.`.......
        dc.b    $f0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$f0,$00,$00,$00 ; 0016ce  ................
        dc.b    $80,$00,$c0,$00,$60,$00,$30,$00,$18,$00,$0c,$00,$04,$00,$00,$00 ; 0016de  ....`.0.........
        dc.b    $f0,$00,$30,$00,$30,$00,$30,$00,$30,$00,$30,$00,$f0,$00,$00,$00 ; 0016ee  ..0.0.0.0.0.....
        dc.b    $10,$00,$38,$00,$6c,$00,$c6,$00,$00,$00,$00,$00,$01,$00,$00,$00 ; 0016fe  ..8.l...........
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$00,$00,$00 ; 00170e  ................
        dc.b    $c0,$00,$c0,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 00171e  ....`...........
        dc.b    $00,$00,$00,$00,$78,$00,$cc,$00,$fc,$00,$cc,$00,$cc,$00,$00,$00 ; 00172e  ....x...........
        dc.b    $c0,$00,$c0,$00,$f8,$00,$cc,$00,$cc,$00,$cc,$00,$f8,$00,$00,$00 ; 00173e  ................
        dc.b    $00,$00,$00,$00,$78,$00,$cc,$00,$c0,$00,$cc,$00,$78,$00,$00,$00 ; 00174e  ....x.......x...
        dc.b    $0c,$00,$0c,$00,$7c,$00,$cc,$00,$cc,$00,$cc,$00,$7c,$00,$00,$00 ; 00175e  ....|.......|...
        dc.b    $00,$00,$00,$00,$7c,$00,$c0,$00,$fc,$00,$c0,$00,$7c,$00,$00,$00 ; 00176e  ....|.......|...
        dc.b    $70,$00,$c0,$00,$f0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$00,$00 ; 00177e  p...............
        dc.b    $00,$00,$00,$00,$7c,$00,$cc,$00,$cc,$00,$7c,$00,$0c,$00,$78,$00 ; 00178e  ....|.....|...x.
        dc.b    $c0,$00,$c0,$00,$cc,$00,$cc,$00,$fc,$00,$cc,$00,$cc,$00,$00,$00 ; 00179e  ................
        dc.b    $c0,$00,$00,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$00,$00 ; 0017ae  ................
        dc.b    $30,$00,$00,$00,$30,$00,$30,$00,$30,$00,$30,$00,$30,$00,$e0,$00 ; 0017be  0...0.0.0.0.0...
        dc.b    $c0,$00,$c0,$00,$cc,$00,$d8,$00,$f0,$00,$d8,$00,$cc,$00,$00,$00 ; 0017ce  ................
        dc.b    $c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$c0,$00,$70,$00,$00,$00 ; 0017de  ............p...
        dc.b    $00,$00,$00,$00,$c6,$00,$ee,$00,$fe,$00,$d6,$00,$c6,$00,$00,$00 ; 0017ee  ................
        dc.b    $00,$00,$00,$00,$cc,$00,$ec,$00,$fc,$00,$dc,$00,$cc,$00,$00,$00 ; 0017fe  ................
        dc.b    $00,$00,$00,$00,$78,$00,$cc,$00,$cc,$00,$cc,$00,$78,$00,$00,$00 ; 00180e  ....x.......x...
        dc.b    $00,$00,$00,$00,$f8,$00,$cc,$00,$cc,$00,$f8,$00,$c0,$00,$c0,$00 ; 00181e  ................
        dc.b    $00,$00,$00,$00,$7c,$00,$cc,$00,$cc,$00,$7c,$00,$0c,$00,$0c,$00 ; 00182e  ....|.....|.....
        dc.b    $00,$00,$00,$00,$f8,$00,$cc,$00,$f8,$00,$d8,$00,$cc,$00,$00,$00 ; 00183e  ................
        dc.b    $00,$00,$00,$00,$7c,$00,$c0,$00,$78,$00,$0c,$00,$f8,$00,$00,$00 ; 00184e  ....|...x.......
        dc.b    $00,$00,$00,$00,$fc,$00,$30,$00,$30,$00,$30,$00,$30,$00,$00,$00 ; 00185e  ......0.0.0.0...
        dc.b    $00,$00,$00,$00,$cc,$00,$cc,$00,$cc,$00,$cc,$00,$78,$00,$00,$00 ; 00186e  ............x...
        dc.b    $00,$00,$00,$00,$cc,$00,$cc,$00,$d8,$00,$f0,$00,$e0,$00,$00,$00 ; 00187e  ................
        dc.b    $00,$00,$00,$00,$c6,$00,$d6,$00,$d6,$00,$6c,$00,$6c,$00,$00,$00 ; 00188e  ..........l.l...
        dc.b    $00,$00,$00,$00,$c6,$00,$6c,$00,$38,$00,$6c,$00,$c6,$00,$00,$00 ; 00189e  ......l.8.l.....
        dc.b    $00,$00,$00,$00,$cc,$00,$cc,$00,$cc,$00,$7c,$00,$0c,$00,$78,$00 ; 0018ae  ..........|...x.
        dc.b    $00,$00,$00,$00,$fc,$00,$18,$00,$30,$00,$60,$00,$fc,$00,$00,$00 ; 0018be  ........0.`.....
        dc.b    $00,$00,$ff,$00,$ff,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00 ; 0018ce  ................
        dc.b    $00,$00,$f0,$00,$f9,$00,$19,$00,$f0,$00,$e0,$00,$7f,$00,$3f,$00 ; 0018de  ..............?.
        dc.b    $00,$00,$ff,$00,$ff,$00,$80,$00,$f8,$00,$0c,$00,$fc,$00,$f8,$00 ; 0018ee  ................
        dc.b    $00,$00,$e0,$00,$e0,$00,$60,$00,$60,$00,$60,$00,$60,$00,$60,$00 ; 0018fe  ......`.`.`.`.`.

screen_memory:
        ; Empty screen/render memory used by the intro at runtime. The original
        ; image keeps 11564 zero bytes here, then one final word below.
        ds.b    11564
screen_memory_tail_word:
        dc.w    $03f2


        end     file_entry_jump
