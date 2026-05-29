; ---------------------------------------------------------------------------
; Phil Douglas trainer menu for Miami Chase
; ---------------------------------------------------------------------------
;
; Reconstructed by Volker Schwaberow <volker@schwaberow.de>
;
; Build:
;   vasmm68k_mot -m68000 -no-opt -Fbin -o phil_miami_trainer.bin phil_miami_trainer.s
;
; ---------------------------------------------------------------------------

        org     $00030000

; ---------------------------------------------------------------------------
; Hardware / OS constants
; ---------------------------------------------------------------------------

CUSTOM                  equ     $00dff000
DMACON                  equ     $00dff096
INTENA                  equ     $00dff09a
INTREQ                  equ     $00dff09c
COLOR00                 equ     $00dff180
CIAA_PRA_JOY_MOUSE      equ     $00bfe001
CIAA_SDR_KEYBOARD       equ     $00bfec01
CIAB_PRB                equ     $00bfd100
EXEC_BASE_PTR           equ     $00000004
LEVEL2_INTERRUPT_VECTOR equ     $00000068
LEVEL3_INTERRUPT_VECTOR equ     $0000006c
_LVOForbid              equ     -132
_LVOEnable              equ     -138

; ---------------------------------------------------------------------------
; Resident trainer menu code
; ---------------------------------------------------------------------------

phil_douglas_trainer_entry:
        movea.l  $4.l,a6                         ; ExecBase sits at address 4, so A6 is ready for Exec calls.
        jsr      -$84(a6)                        ; Forbid task switching while the trainer owns the display.
        lea.l    $dff000.l,a5                    ; Keep the custom-chip base in A5 for the hardware writes below.
        move.w   #$3e0,$96(a5)                   ; Stop the DMA channels the menu is about to reconfigure.
        lea.l    $306ac.l,a0                     ; A0 points at the copper slots that get generated now.
        move.l   #$30fb2,d0                      ; First bitplane address used for the copper pointer words.
        move.l   #$ffffffd4,d2                   ; Step backwards by 44 bytes for each generated pointer pair.
        move.l   #$2,d3                          ; Build three pointer pairs for the opening copper setup.
        bsr.w    $3013a                          ; Write the generated bitplane pointer words into the copper list.
        bsr.w    $3019c                          ; Prime the audio registers used by the little menu sound.
        bsr.w    $301ca                          ; Install the keyboard/VBlank interrupt hook.
        move.l   #$3069c,$84(a5)                 ; COP1LC gets the trainer copper list address.
        clr.w    $8a(a5)                         ; Poke COPJMP1 so the copper starts using that list now.
        move.l   #$e60f0000,$302fe.l             ; Seed the self-modified copper WAIT used by the colour wave.
        clr.w    $30266.l                        ; Start with no keyboard scan code latched.
        move.w   #$83c0,$96(a5)                  ; Enable the DMA mix needed for copper, bitplanes and audio.
        lea.l    $307bd.l,a0                     ; A0 starts on the first rendered 40-column menu page.
        bsr.w    $30302                          ; Draw that menu page into the text bitplane.
        tst.w    $30138.l                        ; The page wipe sets this while the effect is still moving.
        bne.w    $30066                          ; Wait here until the wipe has finished.
        btst.b   #$7,$bfe001.l                   ; Right mouse button leaves the trainer menu.
        beq.w    $300ba                          ; Button down, so exit and restore the machine.
        btst.b   #$6,$bfe001.l                   ; Left mouse button flips to the other text page.
        bne.b    $30070                          ; Nothing pressed, stay in the input loop.
        move.b   #$ff,$30267.l                   ; Tell the IRQ path to skip option toggles during the page flip.
        bsr.w    $30120                          ; Kick the wipe direction and wait for it to close.
        bsr.w    $30302                          ; Draw the next trainer page while the screen is hidden.
        tst.b    d0                              ; The text renderer returns zero when there is no next page.
        beq.w    $300ba                          ; No page left, so use this as the exit path.
        bsr.w    $30120                          ; Open the wipe again after the new page is in memory.
        btst.b   #$7,$bfe001.l                   ; Right mouse button still means leave.
        beq.w    $300ba                          ; Button down, clean up and return.
        btst.b   #$6,$bfe001.l                   ; Wait until the page-flip button is released.
        bne.b    $300a0                          ; Still released/not active, keep polling here.
        bra.w    $30070                          ; Jump back into the trainer loop.
        bsr.w    $30224                          ; Restore the interrupt vectors and INTENA state.
        move.w   #$0,$102(a5)                    ; Silence AUD0 volume before handing the machine back.
        lea.l    $3079c.l,a0                     ; Walk the option-state table for F1 through F7.
        lea.l    $3327a.l,a1                     ; A1 points into the copied game patch jump table.
        moveq    #$6,d0                          ; Seven options are patched here, counted DBF-style.
        tst.b    (a0)+                           ; A zero option means this patch should be disabled.
        bne.b    $300dc                          ; Non-zero stays active, so leave that jump alone.
        move.l   #$4e714e71,(a1)                 ; Disabled option becomes two NOPs in the game patch.
        addq.l   #$4,a1                          ; Bump the pointer/counter by a small amount.
        dbra     d0,$300d2                       ; Count one loop down and keep going while it is not finished.
        moveq    #$0,d0                          ; Clear D0 before fetching the level value byte.
        move.b   (a0),d0                         ; Last table byte is the selected start level.
        move.l   d0,$33298.l                     ; Pass that start level into the copied patch payload.
        movea.l  $4.l,a6                         ; Back to ExecBase for the final Enable call.
        jsr      -$8a(a6)                        ; Re-enable task switching.
        clr.l    d0                              ; Return code is zero after the trainer is done.
        lea.l    $33276.l,a0                     ; Copy starts inside the in-game hotkey dispatcher tail.
        lea.l    $7f000.l,a1                     ; Destination is the game's patch area.
        lea.l    $7f200.l,a2                     ; Stop once the copy reaches the end of that 512-byte block.
        move.b   (a0)+,(a1)+                     ; Copy one patch byte into game memory.
        cmpa.l   a1,a2                           ; Have we reached $7f200 yet?
        bne.b    $3010a                          ; Branch when the last test says there is still work to do.
        moveq    #$f,d0                          ; Clear the first 16 colour registers.
        lea.l    $dff180.l,a0                    ; COLOR00 starts here in the custom register block.
        clr.w    (a0)+                           ; Blank one colour register and move to the next.
        dbra     d0,$30118                       ; Count one loop down and keep going while it is not finished.
        rts                                      ; Done here, return to the caller.
toggle_text_page_wait:
        not.w    $30138.l                        ; Mark the wipe as active.
        not.w    $30300.l                        ; Reverse the colour-wave direction for closing/opening.
        tst.w    $30138.l                        ; The IRQ clears this when the wave reaches its end.
        bne.w    $3012c                          ; Wait here until the interrupt side says it is done.
        rts                                      ; Done here, return to the caller.
wipe_busy_flag:
        dc.w    $ffff                       ; The copper wipe code flips this while the colour bars move.
build_dynamic_copper_bitplane_words:
        move.w   #$e0,d1                         ; Start with BPL1PTH's copper register number.
        move.w   d3,d4                           ; Use the plane index to build the initial modulo offset.
        mulu.w   #$1000,d4                       ; Scale the value for the screen/table stride.
        addi.w   #$200,d4                        ; Add the fixed step used by this little effect.
        move.w   #$100,(a0)+                     ; First generated copper move writes BPLCON0.
        move.w   d4,(a0)+                        ; Store the BPLCON0 value for this plane group.
        cmpi.l   #$00006700,d3                  ; This odd compare is exactly how the old code stores the bytes.
        dc.w     $001e                          ; Keep the in-between word; executing it was never the point here.
        subq.w   #1,d3                          ; Count one generated copper pair down.
        move.w   d1,(a0)+                        ; Write the current bitplane pointer register number.
        addi.w   #$2,d1                          ; Add the fixed step used by this little effect.
        swap     d0                              ; Swap the high and low words before writing the next copper word.
        move.w   d0,(a0)+                        ; Store the high word of the bitplane address.
        move.w   d1,(a0)+                        ; Write the matching low-word register number.
        addi.w   #$2,d1                          ; Add the fixed step used by this little effect.
        swap     d0                              ; Swap the high and low words before writing the next copper word.
        move.w   d0,(a0)+                        ; Store the low word of the bitplane address.
        add.l    d2,d0                           ; Add the running delta.
        dbra     d3,$30158                       ; Count one loop down and keep going while it is not finished.
        rts                                      ; Done here, return to the caller.
write_eight_copper_pointer_longs:
        move.w   #$120,d1                        ; Start at SPR0PTH; this writes sprite pointer copper moves.
        move.l   #$7,d3                          ; Eight pointer longs are copied, DBF counts 7 down to -1.
        move.l   (a1)+,d0                        ; Fetch the next 32-bit pointer from the source table.
        move.w   d1,(a0)+                        ; Emit the copper register number for the high word.
        addi.w   #$2,d1                          ; Add the fixed step used by this little effect.
        swap     d0                              ; Swap the high and low words before writing the next copper word.
        move.w   d0,(a0)+                        ; Emit the high word of that pointer.
        move.w   d1,(a0)+                        ; Emit the copper register number for the low word.
        addi.w   #$2,d1                          ; Add the fixed step used by this little effect.
        swap     d0                              ; Swap the high and low words before writing the next copper word.
        move.w   d0,(a0)+                        ; Emit the low word of that pointer.
        dbra     d3,$3017e                       ; Count one loop down and keep going while it is not finished.
        rts                                      ; Done here, return to the caller.
init_audio_registers:
        move.w   #$3081,$8e(a5)                  ; AUD0 period, giving the menu its sharp little tone.
        move.w   #$f8c1,$90(a5)                  ; AUD0 volume/data setup as the original left it.
        move.w   #$38,$92(a5)                    ; AUD0 length/pointer low-side setup.
        move.w   #$d0,$94(a5)                    ; AUD0 length/pointer high-side setup.
        clr.w    $102(a5)                        ; Start with the audio volume muted.
        clr.w    $104(a5)                        ; Clear the paired audio length/control word.
        move.w   #$4,$108(a5)                    ; Small period/length value for the click sound.
        move.w   #$4,$10a(a5)                    ; Same short value for the paired audio register.
        rts                                      ; Done here, return to the caller.
install_keyboard_vblank_irq:
        move.b   #$ff,$bfd100.l                  ; Pulse CIA-B port B, the usual old keyboard handshake poke.
        move.b   #$87,$bfd100.l                  ; Middle value of that handshake pulse.
        move.b   #$ff,$bfd100.l                  ; Return CIA-B port B to the idle value.
        move.w   #$4000,$dff09a.l                ; Disable the interrupt master bit while vectors are changed.
        move.w   $dff01c.l,$3025c.l              ; Save INTENAR so cleanup can put the mask back.
        move.l   $6c.l,$3025e.l                  ; Save the old level-3/VBlank vector.
        move.l   $68.l,$30262.l                  ; Save the old level-2 vector as well.
        move.l   #$30268,$6c.l                   ; Install our keyboard/VBlank handler on level 3.
        move.w   #$7fff,$dff09a.l                ; Clear all interrupt enable bits.
        move.w   #$c028,$dff09a.l                ; Enable master, VBlank and the bits this menu uses.
        rts                                      ; Done here, return to the caller.
restore_keyboard_vblank_irq:
        move.w   #$4000,$dff09a.l                ; Drop the interrupt master bit before restoring vectors.
        bset.b   #$f,$3025c.l                    ; Set the bit back before the machine is handed over.
        move.w   $3025c.l,$dff09a.l              ; Restore the saved interrupt enable mask.
        move.l   $3025e.l,$6c.l                  ; Put the old level-3 vector back.
        move.l   $30262.l,$68.l                  ; Put the old level-2 vector back.
        move.w   #$c000,$dff09a.l                ; Re-enable interrupts after the vectors are sane again.
        rts                                      ; Done here, return to the caller.
irq_runtime_storage:
        dc.w    $0000                       ; Spare runtime word left in the original image.
saved_intena_bits:
        dc.w    $0000                       ; INTENA is copied here before the trainer owns VBlank.
saved_level3_vector:
        dc.l    $00000000                   ; Old level-3 vector, restored on the way out.
saved_level2_vector:
        dc.l    $000048e7                   ; Original bytes double as the old vector storage once installed.
last_key_scan_code:
        dc.b    $fe                         ; Raw keyboard byte, updated by the interrupt handler.
menu_page_flip_requested:
        dc.b    $fe                         ; Set when the mouse asks for the next trainer page.
keyboard_vblank_irq:
        move.b   $bfec01.l,d0                    ; Read the raw keyboard byte from CIA-A.
        not.b    d0                              ; The Amiga keyboard line is active-low, so invert it.
        ror.b    #$1,d0                          ; Rotate the raw CIA key byte into the form this trainer uses.
        move.b   d0,$30266.l                     ; Keep the decoded scan code for the main trainer logic.
        bsr.w    $304da                          ; Advance the bottom scroll message by one tick.
        bsr.w    $3029c                          ; Move the copper colour wave one step.
        tst.b    $30267.l                        ; During page flips, option keys are ignored for a frame.
        bne.w    $3028e                          ; Skip the option handler when that guard byte is set.
        bsr.w    $3036c                          ; Handle F-key toggles and level changes.
        move.w   #$20,$dff09c.l                  ; Acknowledge the VBlank interrupt request.
        movem.l  (a7)+,d0-d6/a0-a6               ; Save or restore the register set around the interrupt work.
        rte                                      ; Return from the interrupt handler.
animate_copper_colour_wave:
        moveq    #$0,d0                          ; Work in a clean longword; only the low word is meaningful.
        move.w   $302fe.l,d0                     ; Current copper WAIT word for the moving colour band.
        tst.w    $30300.l                        ; Direction flag: zero moves the band upward.
        bne.w    $302be                          ; Non-zero means move the band downward instead.
        cmpi.w   #$2c0f,d0                       ; Compare with the fixed value from the original code.
        beq.w    $302f2                          ; Top edge reached; mark the wipe as finished.
        subi.w   #$100,d0                        ; Subtract the fixed step used by this little effect.
        bra.w    $302ca                          ; Jump back into the trainer loop.
        cmpi.w   #$e50f,d0                       ; Compare with the fixed value from the original code.
        beq.w    $302f2                          ; Bottom edge reached; mark the wipe as finished.
        addi.w   #$100,d0                        ; Add the fixed step used by this little effect.
        move.w   d0,$302fe.l                     ; Save the new WAIT word for the next interrupt tick.
        lea.l    $306d4.l,a1                     ; First copper WAIT word patched by this wave.
        moveq    #$3,d5                          ; Four WAITs are staggered through the colour band.
        move.w   d0,(a1)                         ; Patch this copper WAIT line.
        addi.w   #$100,d0                        ; Add the fixed step used by this little effect.
        adda.l   #$18,a1                         ; Next patched WAIT is 24 bytes later in the copper list.
        dbra     d5,$302d8                       ; Count one loop down and keep going while it is not finished.
        move.w   #$ffff,$30138.l                 ; Tell the main loop the wipe is still moving.
        rts                                      ; Done here, return to the caller.
        clr.w    $30138.l                        ; Wipe has reached the end, so release the waiting main loop.
        rts                                      ; Done here, return to the caller.
copper_wave_instruction_seed:
        dc.w    $e60f,$0000                  ; Spare original words just before the text renderer entry.

patched_text_end_test:
        cmpi.b  #$fe,(a0)                   ; $fe marks the end of a menu text page.
draw_menu_text_page:
        beq.w   $30328                      ; End marker: return zero to say there is no page to draw.
        lea.l   $30fde.l,a1                 ; Destination is the menu text bitplane buffer.
        moveq   #$13,d4                     ; Draw 20 rows, counted DBF-style.
menu_draw_next_row:
        moveq   #$27,d5                     ; Each row is 40 characters wide.
menu_draw_next_char:
        move.b  (a0)+,d0                    ; Pull one character from the page text.
        bsr.w   $3032c                      ; Stamp that character into the bitplane.
        dbra    d5,menu_draw_next_char      ; Keep going until the row is full.
        adda.l  #$164,a1                    ; Move to the next rendered text row.
        dbra    d4,menu_draw_next_row       ; Draw the next of the 20 rows.
        moveq   #-1,d0                      ; Non-zero means a page was rendered.
        rts                                 ; Text page is done.
menu_text_end_reached:
        clr.l   d0                          ; Zero tells the caller there was no next page.
        rts                                 ; Back to the page-flip logic.

draw_trainer_font_char:
        lea.l   $30dfd.l,a2                 ; A2 walks the packed glyph bitmap columns.
        lea.l   $30764.l,a3                 ; Charset table maps text bytes to glyph slots.
font_lookup_next_char:
        addq.l  #1,a2                       ; Step to the next glyph column.
        cmp.b   (a3)+,d0                    ; Is this the glyph for the current text byte?
        bne.b   font_lookup_next_char       ; Not yet, keep looking through the charset.
        ; Odd original byte-overlap ahead: if this is written as seven normal
        ; "move.b disp(a2),disp(a1)" instructions, vasm inserts another $136a
        ; opcode word and the binary changes. These exact bytes are kept because
        ; the surrounding renderer expects this packed glyph-copy sequence.
        dc.b    $13,$6a,$00,$00,$13,$6a,$00,$38,$00,$2c,$13,$6a,$00,$70,$00,$58
        dc.b    $13,$6a,$00,$a8,$00,$84,$13,$6a,$00,$e0,$00,$b0,$13,$6a,$01,$18
        dc.b    $00,$dc,$13,$6a,$01,$50,$01,$08
        addq.l  #1,a1                       ; Advance one character column in the destination.
        rts                                 ; Character is drawn.

handle_function_key_toggles:
        tst.w   $304dc.l                    ; Key repeat delay active?
        bne.w   $304cc                      ; Yes, just count it down.
        moveq   #0,d0                       ; Clear the high bits before using the scan code.
        move.b  $30266.l,d0                 ; Get the decoded key from the IRQ handler.
        cmpi.b  #$50,d0                     ; F1 starts at scan code $50 in this table.
        bcs.w   $304d4                      ; Below F1, nothing to do.
        subi.b  #$50,d0                     ; Convert F1-F8 into option index 0-7.
        cmpi.b  #7,d0                       ; Only eight visible trainer rows exist.
        bhi.w   $304d4                      ; Outside that range, ignore it.
        move.w  #10,$304dc.l                ; Start a short repeat delay so one press is one toggle.
        lea.l   $307b4.l,a0                 ; Option type table: normal toggle or level field.
        move.b  (a0,d0.l),d3                ; D3 decides how this option is edited.
        moveq   #0,d1                       ; D1 will hold the current option value.
        lea.l   $3079c.l,a0                 ; Current visible option values.
        move.b  (a0,d0.l),d1                ; Fetch this option's current value.
        move.l  d0,d2                       ; Build an offset to the ON/OFF/level text field.
        mulu.w  #9,d2                       ; Each option row contributes a small field stride.
        add.b   $307bc.l,d2                 ; Page-dependent base adjustment.
        mulu.w  #$2c,d2                     ; Convert the row index into bitplane bytes.
        lea.l   $30fb2.l,a1                 ; Base of the editable text fields in the buffer.
        adda.l  d2,a1                       ; Land on the chosen row.
        adda.l  #$25,a1                     ; Step to the ON/OFF or numeric field.
        cmpi.b  #5,d3                       ; Type 5 is the numeric start-level field.
        beq.w   $3040c                      ; Handle it separately from ON/OFF toggles.
        tst.b   d1                          ; Is this option currently on?
        beq.w   $303f2                      ; No, write " ON".
        clr.b   (a0,d0.l)                   ; Turn the option off in the state table.
        moveq   #'O',d0                     ; First letter of "OFF".
        bsr.w   $3032a                      ; Draw it into the editable field.
        moveq   #'F',d0                     ; Second letter.
        bsr.w   $3032a                      ; Draw it.
        moveq   #'F',d0                     ; Third letter.
        bsr.w   $3032a                      ; Draw it.
        rts                                 ; Toggle is written.
write_option_on_text:
        move.b  #1,(a0,d0.l)                ; Turn the option on in the state table.
        moveq   #' ',d0                     ; The ON field starts with a leading space.
        bsr.w   $3032a                      ; Draw the space.
        moveq   #'O',d0                     ; Draw O.
        bsr.w   $3032a
        moveq   #'N',d0                     ; Draw N.
        bsr.w   $3032a
        rts

edit_start_level_value:
        lea.l   $307ac.l,a0                 ; Maximum allowed level table.
        move.b  (a0,d0.l),d2                ; D2 is this option's max value.
        lea.l   $307a4.l,a0                 ; Minimum/start level table.
        move.b  (a0,d0.l),d3                ; D3 is this option's minimum value.
        cmp.b   d1,d2                       ; Are we already at the maximum?
        bne.w   $3042a                      ; No, just increment.
        move.b  d3,d1                       ; Wrap back to minimum...
        subq.b  #1,d1                       ; ...minus one because the next instruction increments.
        addq.b  #1,d1                       ; Step to the next level value.
        lea.l   $3079c.l,a0                 ; Back to the current option values.
        move.b  d1,(a0,d0.l)                ; Store the new level.
        bsr.w   $3045c                      ; Convert the value into packed decimal digits.
        lsr.l   #8,d0                       ; Bring the hundreds digit down.
        move.l  d0,d1                       ; Keep the remaining digits for the next writes.
        moveq   #'0',d0                     ; ASCII zero base.
        add.b   d1,d0                       ; Add the digit value.
        bsr.w   $3032a                      ; Draw the first digit.
        lsr.l   #8,d1                       ; Bring the tens digit down.
        moveq   #'0',d0
        add.b   d1,d0
        bsr.w   $3032a                      ; Draw the second digit.
        lsr.l   #8,d1                       ; Bring the ones digit down.
        moveq   #'0',d0
        add.b   d1,d0
        bsr.w   $3032a                      ; Draw the third digit.
        rts

make_three_digit_level_text:
        move.l  d1,d2                       ; D2 keeps the remaining value as we peel digits off.
        move.l  d1,d3                       ; D3 is the working division register.
        divu.w  #1000,d3                    ; Pull the thousands slot used by the original routine.
        move.b  d3,d0                       ; Pack that digit into D0.
        lsl.l   #8,d0                       ; Make room for the next digit.
        andi.l  #$ff,d3                     ; Keep only the quotient byte.
        mulu.w  #1000,d3                    ; Turn it back into a value to subtract.
        sub.l   d3,d2                       ; Remainder after thousands.
        move.l  d2,d3                       ; Work on the remainder.
        divu.w  #100,d3                     ; Pull hundreds.
        move.b  d3,d0
        lsl.l   #8,d0
        andi.l  #$ff,d3
        mulu.w  #100,d3
        sub.l   d3,d2                       ; Remainder after hundreds.
        move.l  d2,d3
        divu.w  #10,d3                      ; Pull tens.
        move.b  d3,d0
        lsl.l   #8,d0
        andi.l  #$ff,d3
        mulu.w  #10,d3
        sub.l   d3,d2                       ; D2 is now ones.
        move.b  d2,d0                       ; Pack ones into the low byte.
        move.l  d0,d3                       ; The next block reorders the packed bytes.
        move.l  d0,d4
        move.l  d0,d5
        andi.l  #$ff000000,d5
        swap    d5
        lsr.l   #8,d5
        andi.l  #$00ff0000,d4
        swap    d4
        lsr.l   #8,d3
        move.b  d2,d0
        lsl.l   #8,d0
        move.b  d3,d0
        lsl.l   #8,d0
        move.b  d4,d0
        lsl.l   #8,d0
        move.b  d5,d0
        rts

option_repeat_delay_tick:
        subi.w  #1,$304dc.l                 ; Count down the key repeat guard.
        rts

scroll_tick_state:
        dc.w    $0000                       ; Alignment/runtime word before the scroll tick routine.
advance_scroll_message:
        addi.w  #2,$30560.l                 ; Advance the scroll every few VBlank calls.
        cmpi.w  #8,$30560.l                 ; Four ticks later, draw a new character.
        bne.w   $3052a                      ; Not time yet, only refresh the blitter state.
        clr.w   $30560.l                    ; Reset the scroll tick counter.
        movea.l $30562.l,a0                 ; Current source pointer inside the scroll text.
        move.b  (a0)+,d0                    ; Fetch the next scroll character.
        lea.l   $33082.l,a1                 ; Draw position for the incoming scroll character.
        bsr.w   $3032a                      ; Render that character.
        cmpa.l  #$3069c,a0                  ; Reached the copper data after the scroll text?
        bne.w   $30514                      ; No, keep this pointer.
        movea.l #$3056e,a0                  ; Wrap to the visible start of the message.
        cmpa.l  #$3056c,a0                  ; Hit the short pre-message marker?
        bne.w   $30524                      ; No, keep going.
        movea.l #$30566,a0                  ; Skip over the marker bytes.
        move.l  a0,$30562.l                 ; Store the updated scroll pointer.
        move.l  #$ffffff00,$44(a5)          ; Blitter mask/control for shifting the scroll buffer.
        move.l  #$3305a,$50(a5)             ; BLTB pointer for the scroll copy.
        move.l  #$33058,$54(a5)             ; BLTA pointer for the scroll copy.
        move.l  #$00000064,$2b7c(a5)        ; Odd original write; keep it as the binary has it.
        dc.w    $e9f0,$0000,$0040           ; Original tail words before the final blitter size write.
        move.w  #$216,$58(a5)               ; BLTSIZE kicks the scroll blit.
        rts


; ---------------------------------------------------------------------------
; Runtime pointers, scroller text, copper list and menu data
; ---------------------------------------------------------------------------

scroll_runtime_and_text:
        dc.l    $00000003                   ; Small runtime seed exactly as the original left it.
        dc.w    $056c                       ; Initial scroll text offset used by the old code.
trainer_scroll_text:
        ; One long blank-padded message. The IRQ code pulls one byte at a time
        ; and wraps when it reaches the small marker block after the spaces.
        dc.b    "          PHIL DOUGLAS PRESENTS MIAMI CHASE MEGATRAINER +30     "
        dc.b    "TRAINED FOR FUN AGAINST ALL BUSINESS     GREETINX TO ALL MY FRIE"
        dc.b    "NDS AROUND THE GLOBE     WITHIN 3 MONTHS MY TRAINER REIGN WILL C"
        dc.b    "OME !    QUALITY FOREVER !           L8ER AND CATCH YA IN ANOTHE"
        dc.b    "R PRODUCTION !!!                        "
pre_copper_palette_reset:
        ; These are already copper-style words after the scroll text:
        ; COLOR00 is black, COLOR01-03 are set to the same dark grey.
        dc.w    $0180,$0000                  ; COLOR00 = black.
        dc.w    $0182,$0505                  ; COLOR01 = dark grey.
        dc.w    $0184,$0505                  ; COLOR02 = dark grey.
        dc.w    $0186,$0505                  ; COLOR03 = dark grey.
        dc.w    $0000,$0000,$0000            ; Quiet padding before the real copper list starts.
main_copper_list:
        ; Copper setup for the menu display. The first three MOVE slots are
        ; filled at runtime with the bitplane pointer words.
        dc.w    $0000,$0000                  ; Runtime patch slot, usually BPL pointer high word.
        dc.w    $0000,$0000                  ; Runtime patch slot, usually BPL pointer low word.
        dc.w    $0000,$0000                  ; Runtime patch slot for the next generated plane word.
        dc.w    $0102,$0010                  ; BPLCON1: small horizontal scroll offset.

        dc.w    $2a0f,$fffe                  ; Wait near the top of the menu area.
        dc.w    $0180,$0f0f                  ; COLOR00 = bright background flash.
        dc.w    $2b0f,$fffe                  ; Wait one raster line lower.
        dc.w    $0180,$0505                  ; COLOR00 = darker background.

        dc.w    $e50f,$fffe                  ; Wait for the lower colour band.
        dc.w    $0182,$0fff                  ; COLOR01 = bright cyan/white edge.
        dc.w    $0184,$0f5f                  ; COLOR02 = magenta mid tone.
        dc.w    $0186,$0fff                  ; COLOR03 = bright edge again.
        dc.w    $0180,$0707                  ; COLOR00 = neutral grey behind it.
        dc.w    $0102,$0043                  ; BPLCON1: change the scroll/shift for this band.

        dc.w    $e60f,$fffe                  ; Next raster line of the band.
        dc.w    $0182,$0bbb                  ; COLOR01 = softer highlight.
        dc.w    $0184,$0888                  ; COLOR02 = darker center.
        dc.w    $0186,$0bbb                  ; COLOR03 = matching softer highlight.
        dc.w    $0180,$0707                  ; COLOR00 stays grey.
        dc.w    $0102,$0032                  ; BPLCON1: step the horizontal shift back.

        dc.w    $e70f,$fffe                  ; Next raster line of the band.
        dc.w    $0182,$0999                  ; COLOR01 = dimmer highlight.
        dc.w    $0184,$0666                  ; COLOR02 = dim center.
        dc.w    $0186,$0999                  ; COLOR03 = dimmer highlight.
        dc.w    $0180,$0707                  ; COLOR00 stays grey.
        dc.w    $0102,$0021                  ; BPLCON1: another shift step.

        dc.w    $e80f,$fffe                  ; Next raster line of the band.
        dc.w    $0182,$0f5f                  ; COLOR01 = magenta highlight.
        dc.w    $0184,$0838                  ; COLOR02 = darker purple.
        dc.w    $0186,$0f5f                  ; COLOR03 = magenta highlight.
        dc.w    $0180,$0707                  ; COLOR00 stays grey.
        dc.w    $0102,$0010                  ; BPLCON1: back to the base shift.

        dc.w    $e90f,$fffe                  ; Last bright line before the band closes.
        dc.w    $0180,$0f0f                  ; COLOR00 = bright background.
        dc.w    $0182,$0f5f                  ; COLOR01 = magenta highlight.
        dc.w    $0184,$0838                  ; COLOR02 = darker purple.
        dc.w    $0186,$0f5f                  ; COLOR03 = magenta highlight.

        dc.w    $ea0f,$fffe                  ; Drop out of the band.
        dc.w    $0180,$0505                  ; COLOR00 = dark grey again.
        dc.w    $f90f,$fffe                  ; Wait near the bottom.
        dc.w    $0180,$0f0f                  ; COLOR00 = final bright line.
        dc.w    $fa0f,$fffe                  ; One more raster line down.
        dc.w    $0180,$0000                  ; COLOR00 = black.
        dc.w    $ffff,$fffe                  ; End of copper list.
trainer_font_charset:
        ; Characters supported by the compact menu font.
        dc.b    "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789%[]<>=+-/*!?&.,'",$22,"ad"
trainer_option_tables:
        ; Compact setup bytes for the eight menu options before the hidden
        ; title marker. One byte per F-key row keeps the original layout easy
        ; to compare against the menu text below.
trainer_option_default_states:
        dc.b    $00                         ; F1 default state: OFF.
        dc.b    $00                         ; F2 default state: OFF.
        dc.b    $00                         ; F3 default state: OFF.
        dc.b    $00                         ; F4 default state: OFF.
        dc.b    $00                         ; F5 default state: OFF.
        dc.b    $01                         ; F6 default state/value seed.
        dc.b    $00                         ; F7 default state: OFF.
        dc.b    $00                         ; F8 default state/value seed.
trainer_option_min_values:
        dc.b    $00                         ; F1 minimum/start value.
        dc.b    $00                         ; F2 minimum/start value.
        dc.b    $00                         ; F3 minimum/start value.
        dc.b    $01                         ; F4 minimum/start value.
        dc.b    $00                         ; F5 minimum/start value.
        dc.b    $00                         ; F6 minimum/start value.
        dc.b    $00                         ; F7 minimum/start value.
        dc.b    $00                         ; F8 minimum/start value.
trainer_option_kinds:
        dc.b    $00                         ; F1 normal ON/OFF option.
        dc.b    $05                         ; F2 numeric/special option marker.
        dc.b    $01                         ; F3 game-trainer key option.
        dc.b    $01                         ; F4 game-trainer key option.
        dc.b    $01                         ; F5 game-trainer key option.
        dc.b    $01                         ; F6 game-trainer key option.
        dc.b    $01                         ; F7 game-trainer key option.
        dc.b    $05                         ; F8 numeric/special option marker.
trainer_menu_text_pages:
trainer_menu_text_marker:
        dc.b    "%"
trainer_menu_text_page_1:
        ;        123456789012345678901234567890123456
        dc.b    "   THE INDEPENDENT PHIL DOUGLAS!      "
        dc.b    "PRESENTS ANOTHER QUALITY PRODUCTION        "
        dc.b    "MIAMI CHASE MEGATRAINER !      "
        dc.b    "--------------------------------------"
        dc.b    "F1....UNLIMITED CARS             OFF"
        dc.b    "F2....UNLIMITED TIME             OFF"
        dc.b    "F3....UNLIMITED ENERGY           OFF"
        dc.b    "F4....UNLIMITED MONEY            OFF"
        dc.b    "F5....LAME COPS                  OFF"
        dc.b    "F6....GAMETRAINER                OFF"
        dc.b    "F7....GET WEAPONS FOR FREE       OFF"
        dc.b    "F8....START AT LEVEL             001"
        dc.b    "--------------------------------------"
        dc.b    "NEXT PAGE[S] EXPLAIN GAMETRAINER KEYS!!!"
        dc.b    "--------------------------------------"
        dc.b    "        CRACKED BY AGILE !                 "
        dc.b    "TRAINED BY PHIL DOUGLAS        "
        dc.b    "--------------------------------------"
        dc.b    "  GREETINX TO ALL DEFJAM MEMBERS!   "
        dc.b    "--------------------------------------"
        dc.b    " USE THESE KEYS ONLY DURING GAMEPLAY !! "
        dc.b    "--------------------------------------"

trainer_menu_text_page_2:
        ;        123456789012345678901234567890123456
        dc.b    "F1....UNLIMITED CARS              ON"
        dc.b    "F2....UNLIMITED TIME              ON"
        dc.b    "F3....UNLIMITED ENERGY            ON"
        dc.b    "F4....UNLIMITED MONEY             ON"
        dc.b    "F5....LAME COPS                   ON"
        dc.b    "F6....UNLIMITED CARS             OFF"
        dc.b    "F7....UNLIMITED TIME             OFF"
        dc.b    "F8....UNLIMITED ENERGY           OFF"
        dc.b    "F9....UNLIMITED MONEY            OFF"
        dc.b    "F0....LAME COPS                  OFF"
        dc.b    "  '1'..SURE TYRE   '2'..MINES        "
        dc.b    " '3'..WHEELBLADES   '4'..FUEL INJECTION  "
        dc.b    "'5'..POWERSTEERING '6'..OIL TANKS     "
        dc.b    "'7'..GLASS       '8'..BODY BANELS          "
        dc.b    " '9'..TURBO SYSTEM           "
        dc.b    "--------------------------------------"
        dc.b    "ALSO TRY KEYS 'QWERTYUI' FOR OTHER STUFF"
        dc.b    "AND PRESS HELP TO SKIP TO NEXT LEVEL !!!",$fe
trainer_font_bitmap_columns:
        ; This is where the text ends and the compact menu font starts. The
        ; renderer copies seven byte rows per glyph from here into the bitplane.
        dc.b    $7c,$fc,$7e,$fc,$fe,$7e,$7c,$c6,$fc,$06
        dc.b    $c6,$c0,$6c,$fc,$7c,$fc,$7c,$fc,$7e,$fc,$c6,$c6,$c6,$fe,$00,$7c
        dc.b    $18,$fc,$fe,$c6,$fe,$7e,$fe,$7c
        dc.b    $7c,$c6,$3c,$3c,$1c,$70,$00,$00,$00,$06,$00,$18,$7c,$70,$00,$00
        dc.b    $18,$6c,$0e,$f0,$c6,$c6,$c0,$c6,$60,$c0,$c6,$c6,$30,$06,$cc,$c0
        dc.b    $fe,$c6,$c6,$c6,$c0,$06,$c6,$c6
        dc.b    $c6,$00,$00,$c6,$38,$06,$0c,$c6,$c0,$c0,$06,$c6,$c6,$8c,$30,$0c
        dc.b    $30,$18,$00,$18,$00,$0c,$6c,$38,$c6,$d8,$00,$00,$18,$6c,$12,$98
        dc.b    $c6,$c6,$c0,$c6,$30,$c0,$c0,$c6
        dc.b    $30,$06,$d8,$c0,$d6,$c6,$c6,$c6,$c0,$06,$c6,$c6,$c6,$0c,$00,$ce
        dc.b    $18,$06,$18,$c6,$c0,$c0,$0c,$c6,$c6,$18,$30,$0c,$60,$0c,$7e,$18
        dc.b    $00
        dc.b    $18,$38,$38,$06,$d8,$00,$00,$10,$00,$22,$8c,$de,$dc,$c0,$c6,$f8
        dc.b    $dc,$ce,$f6,$30,$06,$fc,$c0,$c6,$c6,$c6,$dc,$c6,$dc,$7c,$06,$c6
        dc.b    $c6,$d6,$74,$76,$18,$00,$de,$18,$7c,$3c,$7e,$fc,$fc,$18,$7c,$7e
        dc.b    $30,$30,$0c,$c0,$06,$00,$7e,$7e,$30,$fe,$38,$3c,$7a,$00,$00,$46
        dc.b    $c6,$c6,$c6,$c0,$c6,$c0,$c0,$c6,$c6,$30,$06,$c6,$c0,$c6,$c6,$c6
        dc.b    $c0,$c6,$d8,$06,$06,$c6,$cc,$d6,$c6,$06,$30,$00,$f6,$18,$c0,$06
        dc.b    $06,$06,$c6,$18,$c6,$06,$60,$30,$0c,$60,$0c,$7e,$18,$00,$60,$38
        dc.b    $30,$30,$cc,$00,$18,$00,$00,$fe,$c6,$c6,$c6,$c0,$c6,$c0,$c0,$c6
        dc.b    $c6,$30,$c6,$c6,$c0,$c6,$c6,$c6,$c0,$ce,$cc,$06,$06,$c6,$d8,$fe
        dc.b    $c6,$06,$60,$00,$e6,$18,$c0,$06,$06,$06,$c6,$18,$c6,$06,$c6,$30
        dc.b    $0c,$30,$18,$00,$18,$00,$c0,$6c,$00,$00,$cc,$18,$18,$00,$00,$c6
        dc.b    $c6,$c6,$dc,$7e,$dc,$fe,$c0,$7c,$c6,$fc,$7c,$c6,$7e,$c6,$c6,$7c
        dc.b    $c0,$7e,$c6,$fc,$06,$7c,$f0,$6c,$c6,$fc,$fe,$00,$7c,$3c,$fe,$fc
        dc.b    $06,$fc,$7c,$18,$7c,$fc,$84,$3c,$3c,$1c,$70,$00,$00,$00,$80,$00
        dc.b    $30,$30,$7a,$18,$10,$00,$00,$c6,$fe,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00
menu_text_bitplane_buffer:
        ; Render buffer for the trainer text plane. The menu renderer feeds it
        ; as 20 rows x 40 characters; each glyph is copied as 7 one-byte rows.
        ; The actual text destination starts 104 bytes into this buffer at
        ; $30fde, and the next text row starts $164 bytes later, so the effective
        ; row stride is 356 bytes. This is one bitplane with padding around the
        ; visible text and scroll area, not a tight 320x256 screen.
        ds.b    8418
scroll_render_work_word:
        ds.b    2
scroll_render_buffer:
        ; Horizontal scroll work area. The blitter uses $33058/$3305a as source
        ; pointers and draws incoming characters around $33082.
        ds.b    310

; ---------------------------------------------------------------------------
; Game patch payload
; ---------------------------------------------------------------------------

game_patch_payload:
        ; Resident patch helper block. On trainer exit the menu first NOPs out
        ; disabled option branches around $3327a, stores the selected start level
        ; at $33298, then copies 512 bytes from $33276 to game memory at $7f000.
        ;
        ; The copied code patches Miami Chase in place:
        ; - $71546/$7154a becomes "NOP; JSR $7f0be", wiring the in-game hook.
        ; - $71540 is the game key byte watched by that hook.
        ; - $6c688/$6c7da/$6c728 hold the car/life style counters.
        ; - $66a92, $6b5b6 and $6f8c2 are patched code bytes/words.
        ; - $64a50/$64a7a/$64a4c/$64a76/$692f0 hold equipment/weapon masks.
        ; - $69276 is used for the HELP-key level skip.
game_patch_entry:
        movem.l d0/a0,-(a7)                  ; Keep the game's D0/A0 while we apply the enabled trainer patches.
        bsr.w   game_patch_unlimited_cars_off ; Apply the default car-count patch state.
        bsr.w   game_patch_lame_cops_j_patch ; Apply the default cop behaviour patch state.
        bsr.w   game_patch_energy_off        ; Apply the default energy patch state.
        bsr.w   game_patch_money_nop         ; Apply the default money patch state.
        bsr.w   game_patch_cop_branch_skip   ; Apply the default cop branch patch state.
        bsr.w   game_patch_install_key_hook  ; Install the in-game key hook.
        bsr.w   game_patch_clear_weapon_flags ; Clear the game's temporary weapon/equipment flags.
        move.l  #1,d0                        ; The original game expects these flags set after the trainer runs.
        move.l  d0,$0006477a.l               ; Patch game state flag 1.
        move.l  d0,$00063ba6.l               ; Patch game state flag 2.
        movem.l (a7)+,d0/a0                  ; Give the game its registers back.
        jmp     $0006232e.l                  ; Continue in the original game code.

game_patch_clear_weapon_flags:
        lea.l   $0006bce6.l,a0               ; Start of the small game flag block to clear.
        moveq   #8,d0                        ; Clear nine longwords, DBF-style.
clear_weapon_flags_loop:
        clr.l   (a0)+                        ; Clear one game flag longword.
        dbra    d0,clear_weapon_flags_loop   ; Keep clearing until the block is clean.
        rts

game_patch_unlimited_cars_off:
        moveq   #0,d0                        ; OFF writes zero into the car counters.
        bra.b   write_unlimited_cars_state

game_patch_unlimited_cars_on:
        moveq   #1,d0                        ; ON writes one into the car counters.
write_unlimited_cars_state:
        move.l  d0,$0006c688.l               ; First car/life counter used by the game.
        move.l  d0,$0006c7da.l               ; Second mirrored counter.
        move.l  d0,$0006c728.l               ; Third mirrored counter.
        rts

game_patch_lame_cops_j_patch:
        moveq   #$4a,d0                      ; ASCII 'J', the normal game branch/key byte.
        bra.b   write_lame_cops_byte

game_patch_lame_cops_s_patch:
        moveq   #$53,d0                      ; ASCII 'S', the trainer's altered byte.
write_lame_cops_byte:
        move.b  d0,$00066a92.l               ; Patch the cop behaviour byte in the game.
        rts

game_patch_energy_off:
        moveq   #0,d0                        ; OFF writes zero into the energy patch variables.
        bra.b   write_energy_state

game_patch_energy_on:
        moveq   #1,d0                        ; ON writes one into the energy patch variables.
write_energy_state:
        move.l  d0,$0006ccdc.l               ; First energy-related game variable.
        move.l  d0,$0006cdfe.l               ; Second energy-related game variable.
        rts

game_patch_money_nop:
        move.w  #$4e71,d0                    ; NOP disables the money-changing instruction.
        bra.b   write_money_instruction

game_patch_money_original:
        move.w  #$9081,d0                    ; Original instruction word when the money patch is off.
write_money_instruction:
        move.w  d0,$0006b5b6.l               ; Patch the game's money instruction.
        rts

game_patch_cop_branch_skip:
        moveq   #$60,d0                      ; BRA skips a cop check.
        bra.b   write_cop_branch_byte

game_patch_cop_branch_original:
        moveq   #$67,d0                      ; BEQ restores the original cop check.
write_cop_branch_byte:
        move.b  d0,$0006f8c2.l               ; Patch the branch opcode in the game.
        rts

game_patch_install_key_hook:
        move.l  #$4e714eb9,$00071546.l       ; Write NOP + JSR absolute into the game code.
        move.l  #$0007f0be,$0007154a.l       ; The JSR target is this copied trainer hook.
        rts

game_patch_ingame_key_hook:
        movem.l d0-d2/a0,-(a7)               ; Keep game registers while reading the trainer hotkey byte.
        lea.l   $00071540.l,a0               ; Game key buffer watched by the hook.
        bsr.b   game_patch_dispatch_key      ; Apply any trainer action for that key.
        cmpi.b  #$45,(a0)                    ; Leave condition from the original hook path.
        movem.l (a7)+,d0-d2/a0               ; Restore the game registers.
        rts

game_patch_dispatch_key:
        cmpi.b  #$50,(a0)                    ; F1 toggles unlimited cars off path.
        beq.w   game_patch_unlimited_cars_off
        cmpi.b  #$51,(a0)                    ; F2 toggles lame cops J/S byte.
        beq.b   game_patch_lame_cops_j_patch
game_patch_copy_start:
        cmpi.b  #$52,(a0)                    ; F3 toggles energy off path.
        beq.b   game_patch_energy_off
        cmpi.b  #$53,(a0)                    ; F4 toggles money NOP path.
        beq.b   game_patch_money_nop
        cmpi.b  #$54,(a0)                    ; F5 toggles cop branch skip path.
        beq.b   game_patch_cop_branch_skip
        cmpi.b  #$55,(a0)                    ; F6 toggles unlimited cars on path.
        beq.w   game_patch_unlimited_cars_on
        cmpi.b  #$56,(a0)                    ; F7 toggles lame cops alternate byte.
        beq.w   game_patch_lame_cops_s_patch
        cmpi.b  #$57,(a0)                    ; F8 toggles energy on path.
        beq.w   game_patch_energy_on
        cmpi.b  #$58,(a0)                    ; F9 restores the money instruction.
        beq.w   game_patch_money_original
        cmpi.b  #$59,(a0)                    ; F0 restores the cop branch byte.
        beq.b   game_patch_cop_branch_original
        moveq   #0,d2                        ; D2 becomes the gameplay equipment/key index.
        cmpi.b  #1,(a0)                      ; Gameplay key 1 uses the broad mask below.
        beq.b   game_patch_set_broad_mask
        cmpi.b  #2,(a0)                      ; Gameplay key 2 uses the narrower mask.
        beq.b   game_patch_set_narrow_mask
        cmpi.b  #3,(a0)                      ; Gameplay keys 3-5 use the broad mask.
        beq.b   game_patch_set_broad_mask
        cmpi.b  #4,(a0)
        beq.b   game_patch_set_broad_mask
        cmpi.b  #5,(a0)
        beq.b   game_patch_set_broad_mask
        cmpi.b  #6,(a0)                      ; Gameplay keys 6-7 use the narrower mask.
        beq.b   game_patch_set_narrow_mask
        cmpi.b  #7,(a0)
        beq.b   game_patch_set_narrow_mask
        cmpi.b  #8,(a0)                      ; Gameplay keys 8-9 use the broad mask.
        beq.b   game_patch_set_broad_mask
        cmpi.b  #9,(a0)
        beq.b   game_patch_set_broad_mask
        move.b  (a0),d2                      ; Other hotkeys become bit indexes after subtracting $10.
        subi.b  #$10,d2                      ; Convert the raw key byte into a bit number.
        cmpi.w  #7,d2                        ; Only bits 0-7 are valid here.
        bhi.b   game_patch_check_help_key    ; Outside the range, check HELP instead.
        bset.b  d2,$00064a50.l               ; Set the equipment/weapon bit in the first game byte.
        bset.b  d2,$00064a7a.l               ; Mirror the bit in the second game byte.

game_patch_check_help_key:
        cmpi.b  #$5f,(a0)                    ; HELP skips to the next level.
        bne.b   game_patch_key_done
        move.l  #$00010001,$00069276.l       ; Tell the game to advance the level.
game_patch_key_done:
        rts

game_patch_set_narrow_mask:
        move.w  #$033a,d1                    ; Mask used for keys 2, 6 and 7.
        bra.b   game_patch_write_gameplay_mask

game_patch_set_broad_mask:
        move.w  #$03fe,d1                    ; Mask used for the other equipment keys.
game_patch_write_gameplay_mask:
        move.b  (a0),d2                      ; Current gameplay key becomes the bit number.
        move.w  $00064a4c.l,d0               ; Read the first game equipment mask.
        and.w   d1,d0                        ; Keep only the bits this key group allows.
        bset    d2,d0                        ; Add the requested equipment bit in the register mask.
        move.w  d0,$00064a4c.l               ; Store the first equipment mask.
        move.w  d0,$000692f0.l               ; Mirror it where the game also checks it.
        move.w  $00064a76.l,d0               ; Read the second game equipment mask.
        and.w   d1,d0                        ; Keep the allowed bits here too.
        bset    d2,d0                        ; Add the requested equipment bit in the register mask.
        move.w  d0,$00064a76.l               ; Store the second equipment mask.
        move.w  d0,$000692f0.l               ; Mirror the second result as well.
        rts

        dc.l    0                            ; Padding kept at the end of the copied payload.
end_of_patch_payload:
        dc.w    $0000                       ; Padding word after the copied patch payload.
empty_tail_buffer:
        ds.b    9396
