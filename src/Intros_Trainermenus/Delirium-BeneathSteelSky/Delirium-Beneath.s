
; ============================================================================
; Source  : Delirium Cracktro for Beneath the steel sky
; Author  : Wayne Mendoza
; Creator : Reconstructed by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================

; OS Library Bases and offsets
ExecBase        EQU     $00000004               ; Exec library base pointer stored at address 4.
OpenLibrary     EQU     -552                    ; Exec OpenLibrary vector offset.
CloseLibrary    EQU     -414                    ; Exec CloseLibrary vector offset.
SuperState      EQU     -150                    ; Exec SuperState vector offset.
Supervisor      EQU     -30                     ; Exec Supervisor (Kickstart 1.x) vector offset.
Supervisor20    EQU     -648                    ; Exec Supervisor (Kickstart 2.0+) vector offset.

; GfxBase offsets
LoadView        EQU     -228                    ; graphics.library LoadView vector offset.
WaitTOF         EQU     -270                    ; graphics.library WaitTOF vector offset.
OwnBlitter      EQU     -222                    ; graphics.library OwnBlitter vector offset.
WaitBlit        EQU     -270                    ; graphics.library WaitBlit vector offset.

; Custom Chip Registers
CUSTOM          EQU     $dff000                 ; Base address of the Amiga Custom Chip registers.
DMACONR         EQU     $002                    ; DMA control read register offset.
VPOSR           EQU     $004                    ; Vertical beam position read register offset.
VHPOSR          EQU     $006                    ; Vertical/horizontal beam position read offset.
COP1LCH         EQU     $080                    ; Copper list 1 pointer high offset.
COPJMP1         EQU     $088                    ; Copper restart 1 register offset.
DMACON          EQU     $096                    ; DMA control register offset.
INTENA          EQU     $09a                    ; Interrupt enable register offset.
INTENAR         EQU     $01c                    ; Interrupt enable register read offset.
INTREQ          EQU     $09c                    ; Interrupt request register offset.
COLOR00         EQU     $180                    ; Background color register offset.
BLTAFWM         EQU     $044                    ; Blitter A first word mask offset.
DENISEID        EQU     $07c                    ; Denise ID register offset.

; ========================================
	SECTION Hunk_0_Code, CODE
	movea.l  ExecBase.w,a6                  ; Load ExecBase pointer to invoke OS calls.
	moveq    #0,d0                          ; Open any version of graphics.library.
	lea      Str_GfxLibraryName(pc),a1      ; Load graphics.library name pointer.
	jsr      OpenLibrary(a6)                ; Call Exec OpenLibrary.
	lea      Var_GfxBase(pc),a0             ; Load GfxBase variable pointer.
	move.l   d0,(a0)                        ; Save GfxBase pointer for later.
	beq.w    Exit_GfxError                  ; If OpenLibrary failed, branch to exit.
	movea.l  a6,a5                                 ; Backup ExecBase pointer in a5.
	movea.l  d0,a6                                 ; Move graphics.library base pointer to a6.
	lea      Var_OldView(pc),a0                    ; Point to OldView backup variable.
	move.l   $22(a6),(a0)                          ; Save original system View pointer.
	suba.l   a1,a1                                 ; Clear a1 for LoadView (pass NULL).
	jsr      OwnBlitter(a6)                        ; Gain exclusive ownership of the Blitter.
	jsr      WaitBlit(a6)                          ; Wait for active blits to complete.
	jsr      WaitBlit(a6)                          ; Wait again for safety.
	movea.l  a6,a1                                 ; Prepare GfxBase pointer in a1.
	movea.l  a5,a6                                 ; Restore ExecBase pointer in a6.
	jsr      CloseLibrary(a6)                      ; Close graphics.library.
	movea.l  ExecBase.w,a6                        ; Load ExecBase to check hardware/OS details.
	move.w   $128(a6),d0                          ; Read AttnFlags (CPU features).
	andi.w   #$e,d0                               ; Check for 68020, 68030, or 68040.
	beq.b    .no_cache_control                    ; If 68000/68010, skip cache settings.
	move.w   $14(a6),d1                           ; Read LibVersion (Kickstart version).
	cmpi.w   #$25,d1                              ; Is OS version >= 37 (Kickstart 2.0+)?
	bmi.b    .kick1x_cache                        ; If Kickstart 1.x, handle cache manually.
	moveq    #0,d0                                ; Clear bits to clear.
	move.l   #$101,d1                             ; Bits to set (clear instruction & data cache).
	jsr      Supervisor20(a6)                     ; Execute CacheControl on Kickstart 2.0+.
	bra.b    .no_cache_control                    ; Continue to VBR check.
.kick1x_cache:
	btst     #3,d0                                ; Check if CPU is 68040.
	bne.b    .is_68040                            ; If 68040, use 68040 cache flush.
	lea      Supervisor_DisableCache(pc),a5       ; Load 68020/68030 cache disable routine.
	jsr      Supervisor(a6)                       ; Run in supervisor mode.
	bra.b    .no_cache_control                    ; Continue.
.is_68040:
	lea      Supervisor_FlushCache40(pc),a5       ; Load 68040 cache flush routine.
	jsr      Supervisor(a6)                       ; Run in supervisor mode.
.no_cache_control:
	move.w   $128(a6),d0                          ; Re-read AttnFlags.
	andi.w   #$f,d0                               ; Check for 68010+ (which has VBR).
	beq.b    .no_vbr                              ; If 68000, skip VBR detection.
	lea      Supervisor_GetVBR(pc),a5             ; Load VBR retrieval routine.
	jsr      Supervisor(a6)                       ; Run in supervisor mode to get VBR.
.no_vbr:
	lea      $dff000.l,a6                          ; Point a6 to Amiga Custom Chip base.
	move.w   DMACONR(a6),Var_OldDMACON.l           ; Backup original DMA control register value.
	move.w   INTENAR(a6),Var_OldINTENA.l           ; Backup original interrupt enable register value.
	move.l   #$7fff7fff,INTENA(a6)                 ; Disable all interrupts & clear requests.
	moveq    #$0,d0                                ; Clear register d0.
	move.l   d0,$144(a6)                           ; Reset Paula audio channel 0 period & length.
	move.w   #$7fff,DMACON(a6)                     ; Disable all DMA channels.
	move.w   #$0,COLOR00(a6)                       ; Set background color to black.
	move.w   DENISEID(a6),d0                ; Read Denise chip revision ID.
	cmpi.b   #$f8,d0                        ; Check if it's an AGA machine ($f8).
	bne.b    .init_bss_clear                ; If not AGA, skip AGA FMODE copper setup.
	lea      Copper_FMODE.l,a0              ; Point to FMODE entry in copper list.
	move.l   #$1fc0000,(a0)+                ; Set FMODE register address ($01fc) and high word.
	move.l   #$1060c00,(a0)+                ; Set FMODE low word and BPLCON3 ($0106).
.init_bss_clear:
	lea      Buf_Bpl1.l,a4                  ; Start of BSS buffer to clear.
	lea      Buf_BssEnd.l,a5                ; End of BSS buffer.
	move.l   a4,d0                          ; Check BSS buffer alignment.
	andi.l   #1,d0                          ; Check if odd address.
	beq.b    .bss_aligned                   ; If even, skip alignment fix.
	clr.b    (a4)+                          ; Clear first byte to align address.
.bss_aligned:
	movem.l  Var_ZeroBlock(pc),d0-d7/a0-a3  ; Load 48 bytes of zeroes.
.clear_bss_loop:
	lea      48(a4),a4                      ; Step BSS pointer by 48 bytes.
	cmpa.l   a5,a4                          ; Have we reached the end of BSS?
	bge.b    .clear_bss_loop_done           ; If yes, exit loop.
	movem.l  d0-d7/a0-a3,-48(a4)            ; Zero 48 bytes of BSS.
	bra.b    .clear_bss_loop                ; Loop again.
.clear_bss_loop_done:
	lea      -48(a4),a4                     ; Adjust pointer back.
.clear_bss_tail:
	cmpa.l   a5,a4                          ; Have we cleared the whole BSS range?
	bge.b    .copy_maniac_logo              ; If yes, proceed to copy the Maniac logo.
	clr.b    (a4)+                          ; Clear one byte of BSS padding.
	bra.b    .clear_bss_tail                ; Loop until done.
.copy_maniac_logo:
	lea      Gfx_ManiacLogo(pc),a0          ; Load pointer to "MANIAC" logo graphic.
	lea      Buf_ManiacLogoDest.l,a1        ; Load destination in bitplane 4 buffer.
	moveq    #7,d0                          ; Copy 8 rows of graphic.
.row_loop:
	move.b   (a0)+,(a1)+                    ; Copy byte 0 of row.
	move.b   (a0)+,(a1)+                    ; Copy byte 1 of row.
	move.b   (a0)+,(a1)+                    ; Copy byte 2 of row.
	move.b   (a0)+,(a1)+                    ; Copy byte 3 of row.
	move.b   (a0)+,(a1)+                    ; Copy byte 4 of row.
	move.b   (a0)+,(a1)+                    ; Copy byte 5 of row.
	lea      26(a1),a1                      ; Move destination to next row (32 bytes stride).
	dbra     d0,.row_loop                   ; Loop for all 8 rows.
	lea      Font_RawData(pc),a0            ; Point to raw font bitmap.
	lea      Var_FontOffsetTable.l,a1       ; Point to font offset table in BSS.
	moveq    #13,d7                         ; 14 font rows to process.
.font_outer_loop:
	moveq    #59,d6                         ; 60 font characters to process in each row.
.font_inner_loop:
	move.b   (a0)+,d0                       ; Read one byte of raw font bitmap.
	move.b   d0,(a1)+                       ; Store byte in offset table.
	clr.b    (a1)+                          ; Interleave with a zero byte to form a word offset.
	dbra     d6,.font_inner_loop            ; Loop for all characters in row.
	dbra     d7,.font_outer_loop            ; Loop for all rows.
	lea      Buf_Bpl2.l,a0                  ; Point to playfield 2 (even bitplane) buffer.
	lea      $18e0(a0),a1                   ; Point to bottom border position (row 199).
	moveq    #-1,d0                         ; Value for filled border pixels ($FFFFFFFF).
	moveq    #7,d1                          ; Fill 8 longwords (32 bytes).
.fill_border_loop:
	move.l   d0,(a0)+                       ; Fill top border of playfield 2.
	move.l   d0,(a1)+                       ; Fill bottom border of playfield 2.
	dbra     d1,.fill_border_loop           ; Loop for 32 bytes.
	lea      Buf_Bpl2.l,a0                  ; Point to playfield 2 buffer start.
	move.w   #199,d3                        ; Draw vertical borders for all 200 screen rows.
	move.b   #$80,d0                        ; Left border pixel mask (MSB set).
	moveq    #1,d1                          ; Right border pixel mask (LSB set).
	moveq    #32,d2                         ; Step size (32 bytes per row).
.draw_vertical_border_loop:
	or.b     d0,(a0)                        ; Draw left vertical border bit.
	or.b     d1,31(a0)                      ; Draw right vertical border bit.
	adda.w   d2,a0                          ; Step to the next screen row.
	dbra     d3,.draw_vertical_border_loop  ; Loop for all 200 rows.
	lea      Copper_RasterSplitList.l,a0    ; Point a0 to copper wait split list.
	move.w   #$35e1,d0                      ; Initial wait line coordinate.
	moveq    #99,d7                         ; Build split wait instructions for 100 lines.
.build_split_list_loop:
	move.w   d0,(a0)+                       ; Write wait instruction (low word).
	move.w   #$fffe,(a0)+                   ; Write wait line mask.
	move.l   #$108ffe0,(a0)+                ; Write shift offset to BPLCON1 (horizontal scroll).
	addi.w   #$100,d0                       ; Step wait position to next line.
	move.w   d0,(a0)+                       ; Write wait instruction for next line.
	move.w   #$fffe,(a0)+                   ; Write wait line mask.
	move.l   #$1080000,(a0)+                ; Reset BPLCON1 scroll to 0.
	addi.w   #$100,d0                       ; Step wait position to next line.
	cmpi.w   #$f7e1,d0                      ; Is this the split line where palette changes?
	bne.b    .next_split_row                ; If not, skip color table injection.
	lea      Palette_Main.l,a1              ; Point a1 to main palette values.
	moveq    #31,d6                         ; Write 32 colors to copper list.
	move.w   #$180,d2                       ; Start with COLOR00 ($0180).
.write_palette_loop:
	move.w   d2,(a0)+                       ; Write copper destination register.
	move.w   (a1)+,(a0)+                    ; Write copper source color value.
	addq.w   #2,d2                          ; Step to the next color register.
	dbra     d6,.write_palette_loop         ; Loop for all 32 colors.
.next_split_row:
	dbra     d7,.build_split_list_loop      ; Continue building split list.
	lea      Table_LineOffsets(pc),a0       ; Point to line offsets table.
	moveq    #0,d0                          ; Start offset 0.
	moveq    #32,d1                         ; Step size (32 bytes per row).
	move.w   #99,d2                         ; Init 100 table entries.
.init_line_offsets_loop:
	move.w   d0,(a0)+                       ; Store current row offset.
	add.w    d1,d0                          ; Add 32 bytes stride.
	dbra     d2,.init_line_offsets_loop     ; Loop for all 100 table entries.
	lea      Copper_BplPtrs.l,a1            ; Point to copper bitplane registers list.
	move.w   #$e2,(a1)+                     ; Set register BPL1PTL.
	move.l   #Buf_Bpl1,d0                   ; Set pointer to bitplane 1.
	move.w   d0,(a1)+                       ; Store low word.
	swap     d0                             ; Swap pointer words.
	move.w   #$e0,(a1)+                     ; Set register BPL1PTH.
	move.w   d0,(a1)+                       ; Store high word.
	move.w   #$e6,(a1)+                     ; Set register BPL2PTL.
	move.l   #Buf_Bpl2,d0                   ; Set pointer to bitplane 2.
	move.w   d0,(a1)+                       ; Store low word.
	swap     d0                             ; Swap pointer words.
	move.w   #$e4,(a1)+                     ; Set register BPL2PTH.
	move.w   d0,(a1)+                       ; Store high word.
	move.l   #Buf_Bpl3,d0                   ; Set pointer to bitplane 3.
	move.w   #$ea,(a1)+                     ; Set register BPL3PTL.
	move.w   d0,(a1)+                       ; Store low word.
	swap     d0                             ; Swap pointer words.
	move.w   #$e8,(a1)+                     ; Set register BPL3PTH.
	move.w   d0,(a1)+                       ; Store high word.
	move.l   #Buf_Bpl4,d0                   ; Set pointer to bitplane 4.
	move.w   #$ee,(a1)+                     ; Set register BPL4PTL.
	move.w   d0,(a1)+                       ; Store low word.
	swap     d0                             ; Swap pointer words.
	move.w   #$ec,(a1)+                     ; Set register BPL4PTH.
	move.w   d0,(a1)+                       ; Store high word.
	move.l   #Buf_Bpl5,d0                   ; Set pointer to bitplane 5.
	move.w   #$f2,(a1)+                     ; Set register BPL5PTL.
	move.w   d0,(a1)+                       ; Store low word.
	swap     d0                             ; Swap pointer words.
	move.w   #$f0,(a1)+                     ; Set register BPL5PTH.
	move.w   d0,(a1)+                       ; Store high word.
	lea      Logo_Mask(pc),a0               ; Load packed logo mask address.
	lea      Buf_DecompressedLogo.l,a1      ; Load BSS decompressed logo buffer.
	movea.l  a1,a2                          ; Setup pointers to 4 bitplanes.
	movea.l  a2,a3                          ; plane 2.
	movea.l  a3,a4                          ; plane 3.
	adda.l   #$4000,a2                      ; Offset for bitplane 2 ($4000).
	adda.l   #$8000,a3                      ; Offset for bitplane 3 ($8000).
	adda.l   #$c000,a4                      ; Offset for bitplane 4 ($c000).
	moveq    #63,d7                         ; 64 outer rows to process.
.outer_row_loop:
	moveq    #127,d6                        ; 128 bits per row (16 bytes).
	moveq    #$0,d0                                ; Reset mask bit index counter.
.bit_loop:
	move.b   d0,d2                          ; Copy bit index.
	move.w   d0,d1                          ; Copy index to calculate byte offset.
	lsr.w    #3,d1                          ; Divide index by 8 to get byte offset.
	not.b    d2                             ; Negate for reverse bit order.
	moveq    #0,d4                          ; Default to clear pixel value.
	btst     d2,(a0,d1.w)                   ; Is the mask bit set?
	beq.b    .bit_zero                      ; If clear, skip setting pixel.
	moveq    #-1,d4                         ; Set pixel value to all set bits.
.bit_zero:
	move.b   #$c0,d3                               ; Set bitplane 1 mask bits (7-6).
	and.b    d4,d3                                 ; Mask with current pixel value.
	move.b   d3,(a1)+                              ; Store in decompressed bitplane 1.
	move.b   d3,$1fff(a1)                          ; Duplicate in memory at +8192 bytes.
	moveq    #$30,d3                               ; Set bitplane 2 mask bits (5-4).
	and.b    d4,d3                                 ; Mask with current pixel value.
	move.b   d3,(a2)+                              ; Store in decompressed bitplane 2.
	move.b   d3,$1fff(a2)                          ; Duplicate in memory at +8192 bytes.
	moveq    #$c,d3                                ; Set bitplane 3 mask bits (3-2).
	and.b    d4,d3                                 ; Mask with current pixel value.
	move.b   d3,(a3)+                              ; Store in decompressed bitplane 3.
	move.b   d3,$1fff(a3)                          ; Duplicate in memory at +8192 bytes.
	moveq    #$3,d3                                ; Set bitplane 4 mask bits (1-0).
	and.b    d4,d3                                 ; Mask with current pixel value.
	move.b   d3,(a4)+                              ; Store in decompressed bitplane 4.
	move.b   d3,$1fff(a4)                          ; Duplicate in memory at +8192 bytes.
	addq.w   #1,d0                          ; Advance to next bit index.
	dbra     d6,.bit_loop                   ; Loop for all 128 bits.
	lea      16(a0),a0                      ; Step to next 16-byte packed row.
	dbra     d7,.outer_row_loop             ; Loop for all 64 rows.
	moveq    #-1,d0                         ; Value for Blitter A first/last word mask ($FFFFFFFF).
.wait_blit_init:
	btst     #14,DMACONR(a6)                ; Check if Blitter is busy.
	bne.b    .wait_blit_init                ; Wait until Blitter is ready.
	move.l   d0,BLTAFWM(a6)                 ; Write blitter masks.
	movea.l  Var_VBRBase(pc),a0                    ; Get Vector Base Register.
	move.l   $6c(a0),Var_OldVBlankVector.l         ; Backup original VBlank interrupt vector.
	move.l   #InterruptHandler_VBlank,$6c(a0)      ; Install custom VBlank interrupt handler.
	move.w   #$c020,INTENA(a6)                     ; Enable VBlank and master interrupts.
	move.l   #CopperList_Main,COP1LCH(a6)          ; Load custom copper list address.
	tst.w    COPJMP1(a6)                           ; Trigger copper list switch.
	move.w   #$83c0,DMACON(a6)                     ; Enable DMA for Copper, Bpl, Blit.
Main_Loop:
	bsr.w    Playfield_RenderCopperWave     ; Render the wavy copper split screen.
	move.w   Var_WaveX(pc),d0               ; Load current wave X coordinate.
	move.w   Var_WaveY(pc),d1               ; Load current wave Y coordinate.
	move.w   Var_WaveDirection(pc),d2       ; Load wave animation step direction.
	bmi.b    .check_min_boundary            ; If negative, check left/min boundary.
	cmpi.w   #$500,d0                       ; Check if right/max boundary is reached.
	ble.b    .no_direction_change           ; If WaveX <= $500, continue wave animation.
	bra.b    .reverse_direction             ; Otherwise, reverse direction.
.check_min_boundary:
	cmpi.w   #$40,d0                        ; Check if left/min boundary is reached.
	bge.b    .no_direction_change           ; If WaveX >= $40, continue wave animation.
.reverse_direction:
	neg.w    Var_WaveDirection.l            ; Invert wave step direction (ping-pong bounce).
.no_direction_change:
	add.w    d2,d0                          ; Step wave X coordinate.
	add.w    d2,d1                          ; Step wave Y coordinate.
	move.w   d0,Var_WaveX.l                 ; Save updated wave X coordinate.
	move.w   d1,Var_WaveY.l                 ; Save updated wave Y coordinate.
	addq.w   #2,Var_WavePixelOffset.l       ; Increment wave offset by 2.
	cmpi.w   #$2d0,Var_WavePixelOffset.l     ; Check if it exceeded limit.
	bmi.b    .no_pixel_reset                ; If not, skip reset.
	clr.w    Var_WavePixelOffset.l          ; Otherwise reset wave offset.
.no_pixel_reset:
	bsr.w    Playfield_UpdateBitplanes       ; Rotate and update bitplane pointers.
	btst     #6,$bfe001.l                   ; Check if left mouse button is pressed.
	bne.b    Main_Loop                      ; If released, continue main loop.
	movea.l  a6,a5                                 ; Point a5 to Custom Chip base.
	move.l   #$7fff7fff,$9a(a5)                    ; Disable all interrupts and requests.
	move.w   #$7fff,$96(a5)                        ; Disable all DMA channels.
	movea.l  Var_VBRBase(pc),a0                    ; Get Vector Base Register.
	move.l   Var_OldVBlankVector(pc),$6c(a0)       ; Restore original VBlank interrupt vector.
	move.w   Var_OldINTENA(pc),d0                  ; Load original Interrupt Enable value.
	bset     #$f,d0                                ; Set master interrupt enable bit.
	move.w   d0,$9a(a5)                            ; Restore system INTENA.
	move.w   Var_OldDMACON(pc),d0                  ; Load original DMA Control value.
	bset     #$f,d0                                ; Set master DMA enable bit.
	move.w   d0,$96(a5)                            ; Restore system DMACON.
	movea.l  Var_GfxBase(pc),a6                    ; Load graphics.library base.
	movea.l  Var_OldView(pc),a1                    ; Load original system View.
	jsr      OwnBlitter(a6)                        ; Regain blitter ownership.
	move.l   $26(a6),$80(a5)                       ; Restore original system copper list.
	moveq    #$0,d0                                ; Clear return register d0.
	rts                                            ; Return to OS.
; ============================================================================
; Function: Exit_GfxError
; Purpose : Handles error exit when graphics.library cannot be opened.
; Notes   : Returns standard Amiga CLI error code 20 (ERROR_BAD_TEMPLATE).
; ============================================================================
Exit_GfxError:
	moveq    #20,d0                         ; Return code 20 (standard error code).
	rts                                     ; Return.
; ============================================================================
; Function: Playfield_UpdateBitplanes
; Purpose : Rotates active bitplane pointers and updates copper list register addresses.
; Notes   : Waits for raster line 255 before writing to copper registers to
;           prevent tearing or glitches.
; ============================================================================
Playfield_UpdateBitplanes:
	lea      Var_BitplanePtrs(pc),a0        ; Load active bitplane pointers block.
	movem.l  (a0),d0-d3                     ; Read first 4 bitplane pointers.
	movem.l  d1-d3,(a0)                     ; Shift pointers left (rotate).
	move.l   d0,12(a0)                      ; Put the first pointer at the end.
.wait_raster:
	move.l   VPOSR(a6),d1                   ; Read vertical beam position.
	andi.l   #$1ff00,d1                     ; Mask vertical beam lines.
	cmpi.l   #$ff00,d1                      ; Wait for line 255.
	bne.b    .wait_raster                   ; Loop until raster line 255 is reached.
	lea      Copper_BplPtrs+2.l,a1          ; Point a1 to copper list bitplane register values.
	addq.w   #4,a0                          ; Skip first pointer (not currently shown).
	move.l   (a0)+,d0                       ; Load next bitplane pointer.
	move.w   d0,(a1)                        ; Store low word of BPL1PT.
	swap     d0                             ; Swap words of pointer.
	move.w   d0,4(a1)                       ; Store high word of BPL1PT.
	move.l   (a0)+,d0                       ; Load next bitplane pointer.
	move.w   d0,16(a1)                      ; Store low word of BPL3PT.
	swap     d0                             ; Swap words of pointer.
	move.w   d0,20(a1)                      ; Store high word of BPL3PT.
	move.l   (a0)+,d0                       ; Load next bitplane pointer.
	move.w   d0,32(a1)                      ; Store low word of BPL5PT.
	swap     d0                             ; Swap words of pointer.
	move.w   d0,36(a1)                      ; Store high word of BPL5PT.
	rts                                     ; Return.
; ============================================================================
; Function: Playfield_RenderCopperWave
; Purpose : Calculates and renders the wavy copper split screen effect.
; Notes   : Uses Table_Sine for wave calculations.
;           Uses self-modifying code to dynamically inject row offsets into
;           the combine loop.
; ============================================================================
Playfield_RenderCopperWave:
	movea.l  Var_BitplanePtrs(pc),a5        ; Load active bitplane pointer.
	lea      Table_Sine(pc),a0              ; Load sine table base pointer.
	adda.w   Var_WavePixelOffset(pc),a0     ; Apply current wave pixel offset.
	lea      $b4(a0),a1                     ; Point to shifted sine values (90 degrees offset).
	move.l   #$ffffff80,d0                  ; Load multiplier/scale.
	move.l   d0,d1                          ; Duplicate scale.
	muls.w   (a1),d0                        ; Multiply cosine by scale.
	muls.w   (a0),d1                        ; Multiply sine by scale.
	sub.l    d1,d0                          ; Subtract sine term.
	asr.l    #8,d0                          ; Scale down to 16-bit.
	move.l   #$ffffff80,d1                  ; Load second scale.
	move.l   #$ffffffc0,d2                  ; Load third scale.
	muls.w   (a0),d1                        ; Sine scaling.
	muls.w   (a1),d2                        ; Cosine scaling.
	add.l    d2,d1                          ; Combine terms.
	asr.l    #8,d1                          ; Scale down to 16-bit.
	movem.w  Var_WaveX(pc),d2-d3            ; Load wave step coordinates.
	muls.w   (a1),d2                        ; Rotate step coordinates.
	add.l    d2,d2                          ; Scale step.
	swap     d2                             ; Put step size in low word.
	muls.w   (a0),d3                        ; Rotate second step coordinate.
	add.l    d3,d3                          ; Scale second step.
	swap     d3                             ; Put step size in low word.
	moveq    #31,d7                         ; Loop for 32 wave steps (32 lines).
	lea      Wave_SelfMod_Target(pc),a4     ; Load self-modifying code write target.
	move.w   #$3fff,d5                      ; Mask for 16KB window.
	move.w   #$1fff,d6                      ; Mask for 8KB window.
	and.w    d5,d0                          ; Wrap coordinate d0.
	and.w    d6,d1                          ; Wrap coordinate d1.
	movem.w  d0-d1,-(a7)                    ; Save coordinates for next loop.
.wave_loop:
; Wave_SelfMod_Target points to the displacement field in the first instruction of the combine loop (.combine_loop).
Wave_SelfMod_Target EQU .wave_loop+$B6          ; Offset where self-mod displacements are written.
	and.w    d5,d0                          ; Wrap coordinate d0.
	and.w    d6,d1                          ; Wrap coordinate d1.
	move.w   d0,d4                          ; Copy coordinate d0.
	lsr.w    #$7,d4                         ; Divide coordinate by 128 to get byte offset.
	movea.w  d4,a2                          ; Load offset in a2.
	move.w   d1,d4                          ; Copy coordinate d1.
	andi.b   #$80,d4                        ; Mask coordinate.
	adda.w   d4,a2                          ; Add to offset in a2.
	move.w   a2,(a4)+                       ; Write displacement 1 (Plane 1 segment). a4 moves to opcode of next instruction.
	addq.w   #$2,a4                         ; Skip opcode of next instruction (2 bytes).
	add.w    d2,d0                          ; Step wave coordinate d0.
	add.w    d3,d1                          ; Step wave coordinate d1.
	and.w    d5,d0                          ; Wrap coordinate d0.
	and.w    d6,d1                          ; Wrap coordinate d1.
	move.w   d0,d4                          ; Copy coordinate d0.
	lsr.w    #$7,d4                         ; Divide coordinate by 128 to get byte offset.
	movea.w  d4,a2                          ; Load offset in a2.
	move.w   d1,d4                          ; Copy coordinate d1.
	andi.b   #$80,d4                        ; Mask coordinate.
	adda.w   d4,a2                          ; Add to offset in a2.
	move.w   a2,(a4)+                       ; Write displacement 2 (Plane 2 segment). a4 moves to opcode of next instruction.
	addq.w   #$2,a4                         ; Skip opcode of next instruction (2 bytes).
	add.w    d2,d0                          ; Step wave coordinate d0.
	add.w    d3,d1                          ; Step wave coordinate d1.
	and.w    d5,d0                          ; Wrap coordinate d0.
	and.w    d6,d1                          ; Wrap coordinate d1.
	move.w   d0,d4                          ; Copy coordinate d0.
	lsr.w    #$7,d4                         ; Divide coordinate by 128 to get byte offset.
	movea.w  d4,a2                          ; Load offset in a2.
	move.w   d1,d4                          ; Copy coordinate d1.
	andi.b   #$80,d4                        ; Mask coordinate.
	adda.w   d4,a2                          ; Add to offset in a2.
	move.w   a2,(a4)+                       ; Write displacement 3 (Plane 3 segment). a4 moves to opcode of next instruction.
	addq.w   #$2,a4                         ; Skip opcode of next instruction (2 bytes).
	add.w    d2,d0                          ; Step wave coordinate d0.
	add.w    d3,d1                          ; Step wave coordinate d1.
	and.w    d5,d0                          ; Wrap coordinate d0.
	and.w    d6,d1                          ; Wrap coordinate d1.
	move.w   d0,d4                          ; Copy coordinate d0.
	lsr.w    #$7,d4                         ; Divide coordinate by 128 to get byte offset.
	movea.w  d4,a2                          ; Load offset in a2.
	move.w   d1,d4                          ; Copy coordinate d1.
	andi.b   #$80,d4                        ; Mask coordinate.
	adda.w   d4,a2                          ; Add to offset in a2.
	move.w   a2,(a4)+                       ; Write displacement 4 (Plane 4 segment). a4 moves to next instruction.
	addq.w   #$2,a4                         ; Skip opcode of next instruction.
	add.w    d2,d0                          ; Step wave coordinate d0.
	add.w    d3,d1                          ; Step wave coordinate d1.
	addq.w   #2,a4                          ; Combined with previous addq, skips "move.b d4,(a5)+" and the next opcode word.
	dbra     d7,.wave_loop                  ; Continue for all 32 horizontal byte steps.
	movem.w  (a7)+,d0-d1                    ; Restore saved coordinates.
	movem.w  Var_WaveX(pc),d2-d3            ; Load wave step coordinates.
	muls.w   (a0),d2                        ; Rotate step coordinate.
	add.l    d2,d2                                 ; Double coordinate scale.
	swap     d2                                    ; Put step size in low word.
	neg.w    d2                                    ; Negate step for reverse scan.
	muls.w   (a1),d3                               ; Cosine scaling terms.
	add.l    d3,d3                                 ; Double second term scale.
	swap     d3                                    ; Put second step size in low word.
	moveq    #99,d7                          ; 100 raster lines to process.
	lea      Buf_DecompressedLogo.l,a4      ; Point a4 to decompressed mask buffer.
	movea.l  #$4000,a6                      ; Offset between bitplane buffers.
.combine_loop:
	movea.l  a4,a0                          ; Point to output buffer.
	movem.w  d0-d1,-(a7)                           ; Save coordinates on stack.
	lsr.w    #$7,d0                                ; Divide coordinate by 128 for X offset.
	andi.b   #$80,d1                               ; Mask for Y offset step.
	add.w    d1,d0                                 ; Combine X and Y offsets.
	adda.w   d0,a0                                 ; Apply offset to bitplane 1 pointer.
	movem.w  (a7)+,d0-d1                           ; Restore saved coordinates.
	movea.l  a0,a1                                 ; Set source bitplane 2 pointer.
	adda.l   a6,a1                                 ; Apply bitplane 2 offset ($4000).
	movea.l  a1,a2                                 ; Set source bitplane 3 pointer.
	adda.l   a6,a2                                 ; Apply bitplane 3 offset ($4000).
	movea.l  a2,a3                                 ; Set source bitplane 4 pointer.
	adda.l   a6,a3                                 ; Apply bitplane 4 offset ($4000).
	move.b   $a(a0),d4                             ; Read byte  0 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  0 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  1 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  1 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  2 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  2 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  3 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  3 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  4 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  4 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  5 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  5 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  6 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  6 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  7 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  7 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  8 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  8 to back buffer.
	move.b   $a(a0),d4                             ; Read byte  9 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte  9 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 10 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 10 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 11 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 11 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 12 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 12 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 13 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 13 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 14 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 14 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 15 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 15 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 16 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 16 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 17 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 17 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 18 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 18 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 19 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 19 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 20 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 20 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 21 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 21 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 22 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 22 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 23 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 23 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 24 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 24 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 25 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 25 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 26 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 26 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 27 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 27 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 28 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 28 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 29 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 29 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 30 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 30 to back buffer.
	move.b   $a(a0),d4                             ; Read byte 31 from decompressed bitplane 1.
	or.b     $a(a1),d4                             ; Combine with bitplane 2 byte.
	or.b     $a(a2),d4                             ; Combine with bitplane 3 byte.
	or.b     $a(a3),d4                             ; Combine with bitplane 4 byte.
	move.b   d4,(a5)+                              ; Write combined byte 31 to back buffer.
	add.w    d2,d0                                 ; Step wave coordinate d0.
	add.w    d3,d1                                 ; Step wave coordinate d1.
	and.w    d5,d0                                 ; Wrap wave coordinate d0.
	and.w    d6,d1                          ; Wrap d1 coordinate.
	dbra     d7,.combine_loop               ; Loop for all 100 raster lines.
	lea      CUSTOM,a6                      ; Point a6 at Amiga Custom Chips base.
	rts                                            ; Return.
; ============================================================================
; Function: PageWriter_RenderChar
; Purpose : Renders the next character of the intro text into the BSS buffer.
; Notes   : Uses the Blitter in cookie-cut mode to copy the character font glyph.
;           Supports newline, space, and a page pause command ($65).
;           The font is stored in interleaved format, so character offset is simply index * 2.
; ============================================================================
PageWriter_RenderChar:
	lea      IntroText(pc),a0               ; Load page text base pointer.
	adda.w   Var_TextOffset(pc),a0          ; Apply current character offset.
	addq.w   #1,Var_TextOffset.l            ; Advance text offset for the next frame.
	movea.l  Var_TextDestPtr(pc),a1         ; Load current typewriter destination pointer.
.char_loop:
	moveq    #0,d0                          ; Clear character register.
	move.b   (a0)+,d0                       ; Read character byte and advance pointer.
	beq.w    .text_loop_reset               ; If 0, we reached the end of text -> reset.
	cmpi.b   #$65,d0                        ; Check for pause command '$65' ('e').
	beq.w    .char_pause                    ; If so, trigger page pause state.
	cmpi.b   #10,d0                         ; Check for newline character.
	beq.w    .char_newline                  ; If so, move to the next line in the buffer.
	subi.w   #32,d0                         ; Subtract 32 (ASCII space) for 0-based font index.
	beq.b    .char_space                    ; If space character, just advance pointers.
	add.w    d0,d0                          ; Multiply index by 2 for word-interleaved font offset.
	lea      Var_FontOffsetTable.l,a2       ; Load font graphics buffer address in BSS.
	adda.w   d0,a2                          ; Point to the character's first row.
	move.l   #$0dfc0000,d1                  ; BLTCON0 = $0dfc (cookie-cut), BLTCON1 = 0.
	move.l   a1,d0                          ; Copy destination pointer to check alignment.
	btst     #0,d0                          ; Is destination address odd?
	beq.b    .wait_blit                     ; If even, proceed with standard blit.
	bclr     #0,d0                          ; If odd, align to even boundary.
	movea.l  d0,a1                          ; Use aligned destination pointer.
	move.l   #$8dfc0000,d1                  ; BLTCON0 = $8dfc (shift 8), BLTCON1 = 0.
.wait_blit:
	btst     #14,DMACONR(a6)                ; Check if blitter is busy (bit 14 of word is bit 6 of byte).
	bne.b    .wait_blit                     ; Wait until blitter is free.
	move.l   a2,$50(a6)                     ; BLTAPT = font source pointer.
	move.l   a1,$54(a6)                     ; BLTDPT = destination pointer.
	move.l   a1,$4c(a6)                     ; BLTBPT = source pointer (C = D for cookie-cut).
	move.l   d1,$40(a6)                     ; BLTCON0/BLTCON1.
	move.l   #$0076001e,$64(a6)             ; BLTAMOD = 118 (stride 120 - 2), BLTBMOD = 30 (stride 32 - 2).
	move.w   #30,$62(a6)                    ; BLTDMOD = 30 (stride 32 - 2).
	move.l   #$ffffffff,$44(a6)             ; BLTAFWM / BLTALWM = $ffff (no mask).
	move.w   #$0381,$58(a6)                 ; BLTSIZE (width 1 word, height 14 lines).
	addq.w   #1,a1                          ; Advance destination by 1 byte (8 pixels).
	cmpi.l   #$8dfc0000,d1                  ; Was this an odd-aligned blit (shift 8)?
	bne.b    .next_char                     ; If not, proceed.
	addq.w   #1,a1                          ; If shift 8, advance pointer by another byte.
.next_char:
	move.l   a1,Var_TextDestPtr.l           ; Save updated typewriter destination pointer.
	rts                                     ; Return.

.char_space:
	addq.w   #1,a1                          ; Advance destination by 1 byte (space width).
	addq.w   #1,Var_TextOffset.l            ; Increment typewriter text offset.
	bra.w    .char_loop                     ; Loop back to process next character.

.char_pause:
	addq.w   #1,Var_TextOffset.l            ; Increment typewriter text offset.
	clr.w    Var_TextLineIndex.l            ; Reset line index.
	move.l   #Var_TextBuffer,Var_TextDestPtr.l ; Reset destination pointer to buffer start.
	st.b     Var_VBlankCounter.l            ; Trigger vertical blank pause wait state.
	move.w   #300,Var_PageWaitCounter.l     ; Set wait counter to 300 frames (6 seconds).
	rts                                     ; Return.

.text_loop_reset:
	clr.w    Var_TextOffset.l               ; Reset text index to loop intro text.
	rts                                     ; Return.

.char_newline:
	addq.w   #1,Var_TextLineIndex.l         ; Increment line index.
	move.w   Var_TextLineIndex(pc),d0       ; Load updated line index.
	lsl.w    #8,d0                          ; Multiply index by 256.
	add.w    d0,d0                          ; index * 512 bytes per line.
	lea.l    Var_TextBuffer.l,a0            ; Base address of render buffer.
	adda.w   d0,a0                          ; Point to the next line buffer.
	move.l   a0,Var_TextDestPtr.l           ; Save as new typewriter destination pointer.
	rts                                     ; Return.

; ============================================================================
; Function: Palette_Init
; Purpose : Resets the copper list palette to default values.
; ============================================================================
Palette_Init:
	lea.l    Palette_Default(pc),a0         ; Load default palette source address.
	lea.l    Copper_Palette+2.l,a1          ; Load copper palette destination pointer (point to value word).
	moveq    #31,d0                         ; 32 colors to copy.
.color_loop:
	move.w   (a0)+,(a1)+                    ; Copy color value to copper list.
	addq.w   #2,a1                          ; Skip register address word.
	dbra     d0,.color_loop                 ; Loop until all colors are copied.
	rts                                     ; Return.

; ============================================================================
; Function: Palette_FadeStep
; Purpose : Fades the current copper list colors one step closer to target colors.
; ============================================================================
Palette_FadeStep:
	lea.l    Palette_FadeTarget.l,a0        ; Load target palette pointer.
	lea.l    Copper_Palette+2.l,a1          ; Load copper palette pointer (point to value word).
	moveq    #31,d7                         ; 32 colors to process.
.color_loop:
	move.w   (a1),d0                        ; Read current copper color value ($0RGB).
	move.w   d0,d1                          ; Copy color value for G extraction.
	move.w   d1,d2                          ; Copy color value for B extraction.
	move.w   (a0)+,d3                       ; Read target color value ($0RGB).
	move.w   d3,d4                          ; Copy target color for G extraction.
	move.w   d4,d5                          ; Copy target color for B extraction.
	lsr.w    #8,d0                          ; Extract current R component.
	lsr.w    #4,d1                          ; Extract current G component.
	lsr.w    #8,d3                          ; Extract target R component.
	lsr.w    #4,d4                          ; Extract target G component.
	andi.w   #$f,d0                         ; Mask R (current).
	andi.w   #$f,d1                         ; Mask G (current).
	andi.w   #$f,d2                         ; Mask B (current).
	andi.w   #$f,d3                         ; Mask R (target).
	andi.w   #$f,d4                         ; Mask G (target).
	andi.w   #$f,d5                         ; Mask B (target).
	cmp.w    d3,d0                          ; Compare current R with target R.
	beq.b    .r_done                        ; If equal, R is done.
	bmi.b    .r_inc                         ; If current < target, increment.
	subq.w   #1,d0                          ; Decrement R.
	bra.b    .r_done                        ; Done with R.
.r_inc:
	addq.w   #1,d0                          ; Increment R.
.r_done:
	cmp.w    d4,d1                          ; Compare current G with target G.
	beq.b    .g_done                        ; If equal, G is done.
	bmi.b    .g_inc                         ; If current < target, increment.
	subq.w   #1,d1                          ; Decrement G.
	bra.b    .g_done                        ; Done with G.
.g_inc:
	addq.w   #1,d1                          ; Increment G.
.g_done:
	cmp.w    d5,d2                          ; Compare current B with target B.
	beq.b    .b_done                        ; If equal, B is done.
	bmi.b    .b_inc                         ; If current < target, increment.
	subq.w   #1,d2                          ; Decrement B.
	bra.b    .b_done                        ; Done with B.
.b_inc:
	addq.w   #1,d2                          ; Increment B.
.b_done:
	lsl.w    #8,d0                          ; Shift R back to position.
	lsl.w    #4,d1                          ; Shift G back to position.
	or.w     d2,d0                          ; Recombine B.
	or.w     d1,d0                          ; Recombine G.
	move.w   d0,(a1)+                       ; Write updated color value to copper list.
	addq.w   #2,a1                          ; Skip register address word.
	dbra     d7,.color_loop                 ; Continue for all colors.
	rts                                     ; Return.

; ============================================================================
; Function: Blitter_ClearBuffer
; Purpose : Uses the Blitter to clear the typewriter text render buffer.
; ============================================================================
Blitter_ClearBuffer:
	btst     #14,DMACONR(a6)                ; Check if blitter is busy.
	bne.b    Blitter_ClearBuffer            ; Wait until blitter is free.
	move.l   #Buf_Bpl4,$54(a6)              ; BLTDPT = start of buffer.
	move.l   #$01000000,$40(a6)             ; BLTCON0 = $0100 (clear D), BLTCON1 = 0.
	clr.w    $66(a6)                        ; BLTDMOD = 0.
	move.w   #$3010,$58(a6)                 ; BLTSIZE (width 16 words, height 192 lines).
	rts                                     ; Return.
; ============================================================================
; Function: InterruptHandler_VBlank
; Purpose : Vertical blank interrupt handler state machine.
; Notes   : Updates typewriter intro text rendering and manages screen page fades.
; ============================================================================
InterruptHandler_VBlank:
	movem.l  d0-d7/a0-a6,-(a7)              ; Save all registers to stack.
	lea.l    CUSTOM,a6                      ; Point a6 to the Custom Chips base.
	tst.b    Var_StateFlag_ResetMusic.l                 ; Check state flag 0.
	bne.b    .state0_active                 ; If non-zero, run state 0 handler.
	tst.b    Var_StateFlag_FadePalette.l                 ; Check state flag 1.
	bne.b    .state1_active                 ; If non-zero, run state 1 handler.
	tst.b    Var_VBlankCounter.l            ; Check VBlank counter.
	bne.b    .vblank_active                 ; If non-zero, handle active VBlank state.
	bsr.w    PageWriter_RenderChar          ; Render next character of the intro text.
	bra.b    .interrupt_exit                ; Exit VBlank handler.

.vblank_active:
	subq.w   #1,Var_PageWaitCounter.l       ; Decrement active page wait frames.
	bgt.b    .interrupt_exit                ; If wait counter > 0, exit.
	clr.b    Var_VBlankCounter.l            ; Reset VBlank counter.
	st       Var_StateFlag_FadePalette.l                 ; Activate state flag 1.
	clr.b    Var_FadeFrameCounter.l                 ; Reset state flag 3.
	bra.b    .interrupt_exit                ; Exit interrupt handler.

.state1_active:
	bsr.w    Palette_FadeStep                   ; Call graphics/fade routine 858.
	addq.b   #1,Var_FadeFrameCounter.l              ; Increment state flag 3.
	cmpi.b   #17,Var_FadeFrameCounter.l             ; Compare state flag 3 to 17.
	ble.b    .interrupt_exit                ; If <= 17, exit.
	clr.b    Var_StateFlag_FadePalette.l                 ; Clear state flag 1.
	bsr.w    Blitter_ClearBuffer                   ; Call final setup routine 8C8.
	st       Var_StateFlag_ResetMusic.l                 ; Activate state flag 0.
	bra.b    .interrupt_exit                ; Exit interrupt handler.

.state0_active:
	bsr.w    Palette_Init                   ; Call music update or state routine 842.
	clr.b    Var_StateFlag_ResetMusic.l                 ; Clear state flag 0.

.interrupt_exit:
	move.w   #$20,INTREQ(a6)                ; Clear Vertical Blank interrupt request.
	movem.l  (a7)+,d0-d7/a0-a6              ; Restore saved registers.
	rte                                     ; Return from exception.
; ============================================================================
; Function: Supervisor_GetVBR
; Purpose : Retrieves the Vector Base Register (VBR) value in supervisor mode.
; Notes   : Runs in supervisor mode. Stores VBR register into Var_VBRBase.
; ============================================================================
Supervisor_GetVBR:
	dc.w    $4e7a,$0801             ; movec   vbr,d0 (retrieve VBR)
	dc.w    $41fa,$0042             ; lea     Var_VBRBase(pc),a0
	dc.w    $2080                   ; move.l  d0,(a0) (store value)
	dc.w    $4e73                   ; rte (return from exception)

; ============================================================================
; Function: Supervisor_DisableCache
; Purpose : Disables CPU caches on 68020/68030 machines.
; Notes   : Disables instruction/data cache and sets cache control registers.
; ============================================================================
Supervisor_DisableCache:
	dc.w    $007c,$0700             ; ori.w   #$700,sr (disable interrupts)
	dc.w    $203c,$0000,$0e0e       ; move.l  #$0e0e,d0 (disable instruction/data caches)
	dc.w    $4e7b,$0002             ; movec   d0,cacr (write to cache control register)
	dc.w    $4e73                   ; rte (return from exception)

; ============================================================================
; Function: Supervisor_FlushCache40
; Purpose : Flushes and disables caches on 68040+ machines.
; ============================================================================
Supervisor_FlushCache40:
	dc.w    $7000                   ; moveq   #0,d0
	dc.w    $f4f8                   ; cpusha  bc (68040 cache push/flush)
	dc.w    $4e7b,$0002             ; movec   d0,cacr (clear cache control register)
	dc.w    $4e73                   ; rte (return from exception)

; ============================================================================
; Data: Str_GfxLibraryName
; Purpose : Name of graphics library for OpenLibrary call.
; ============================================================================
Str_GfxLibraryName:
	dc.b "graphics.library"
	dc.b $00, $00                   ; Null terminator and padding to word boundary.

; ============================================================================
; Variables
; ============================================================================
Var_GfxBase:
	dc.l    0                       ; Pointer to opened graphics.library base.
Var_OldView:
	dc.l    0                       ; Backup of original system View pointer.
Var_OldDMACON:
	dc.w    0                       ; Backup of original system DMA control register.
Var_OldINTENA:
	dc.w    0                       ; Backup of original system Interrupt Enable register.
Var_OldVBlankVector:
	dc.l    0                       ; Backup of original system VBlank interrupt handler.
Var_VBRBase:
	dc.l    0                       ; Vector Base Register (VBR) address backup.
Var_BitplanePtrs:
	dc.l Buf_Bpl1
	dc.l Buf_Bpl3
	dc.l Buf_Bpl5
	dc.l Buf_Bpl4_Alt
Var_TextDestPtr:
	dc.l Var_TextBuffer
	dc.w 0
Var_TextIndex:
	dc.w 0
Var_WaveX:
	dc.w $0500
Var_WaveY:
	dc.w $0500
Var_WavePixelOffset:
	dc.w 0
Var_WaveDirection:
	dc.w 3,3
Var_TextOffset:
	dc.w 0
Var_PageWaitCounter:
	dc.w 0
Var_TextLineIndex:
	dc.w 0
Var_StateFlag_ResetMusic:
	dc.b 0
Var_StateFlag_FadePalette:
	dc.b 0
Var_VBlankCounter:
	dc.b 0
Var_FadeFrameCounter:
	dc.b 0
Var_ZeroBlock:
	ds.b 64
Table_LineOffsets:
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
Table_Sine:
	dc.w 0,572,1144,1715,2286,2856,3425,3993
	dc.w 4560,5126,5690,6252,6813,7371,7927,8481
	dc.w 9032,9580,10126,10668,11207,11743,12275,12803
	dc.w 13328,13848,14364,14876,15383,15886,16383,16876
	dc.w 17364,17846,18323,18794,19260,19720,20173,20621
	dc.w 21062,21497,21925,22347,22762,23170,23571,23964
	dc.w 24351,24730,25101,25465,25821,26169,26509,26841
	dc.w 27165,27481,27788,28087,28377,28659,28932,29196
	dc.w 29451,29697,29934,30162,30381,30591,30791,30982
	dc.w 31163,31335,31498,31650,31794,31927,32051,32165
	dc.w 32269,32364,32448,32523,32588,32642,32687,32722
	dc.w 32747,32762,32767,32762,32747,32722,32687,32642
	dc.w 32587,32523,32448,32364,32269,32165,32051,31927
	dc.w 31794,31650,31498,31335,31163,30982,30791,30591
	dc.w 30381,30162,29934,29697,29451,29196,28932,28659
	dc.w 28377,28087,27788,27481,27165,26841,26509,26169
	dc.w 25821,25465,25101,24730,24351,23964,23571,23170
	dc.w 22762,22347,21925,21497,21062,20621,20173,19720
	dc.w 19260,18794,18323,17846,17364,16876,16384,15886
	dc.w 15383,14876,14364,13848,13328,12803,12275,11743
	dc.w 11207,10668,10126,9580,9032,8481,7927,7371
	dc.w 6813,6252,5690,5126,4560,3993,3425,2856
	dc.w 2286,1715,1144,572,0,-572,-1143,-1715
	dc.w -2286,-2856,-3425,-3993,-4560,-5126,-5690,-6252
	dc.w -6812,-7371,-7927,-8481,-9032,-9580,-10125,-10668
	dc.w -11207,-11742,-12275,-12803,-13327,-13848,-14364,-14876
	dc.w -15383,-15886,-16383,-16876,-17364,-17846,-18323,-18794
	dc.w -19260,-19719,-20173,-20621,-21062,-21497,-21925,-22347
	dc.w -22762,-23170,-23570,-23964,-24350,-24729,-25101,-25465
	dc.w -25821,-26169,-26509,-26841,-27165,-27481,-27788,-28087
	dc.w -28377,-28658,-28931,-29195,-29451,-29697,-29934,-30162
	dc.w -30381,-30590,-30791,-30982,-31163,-31335,-31498,-31650
	dc.w -31794,-31927,-32051,-32165,-32269,-32364,-32448,-32523
	dc.w -32587,-32642,-32687,-32722,-32747,-32762,-32767,-32762
	dc.w -32747,-32722,-32687,-32642,-32588,-32523,-32448,-32364
	dc.w -32269,-32165,-32051,-31927,-31794,-31651,-31498,-31335
	dc.w -31163,-30982,-30791,-30591,-30381,-30162,-29934,-29697
	dc.w -29451,-29196,-28932,-28659,-28377,-28087,-27788,-27481
	dc.w -27165,-26841,-26509,-26169,-25821,-25465,-25101,-24730
	dc.w -24351,-23965,-23571,-23170,-22762,-22347,-21926,-21498
	dc.w -21063,-20621,-20174,-19720,-19260,-18795,-18324,-17847
	dc.w -17364,-16877,-16384,-15886,-15384,-14876,-14365,-13849
	dc.w -13328,-12804,-12275,-11743,-11208,-10669,-10126,-9581
	dc.w -9032,-8481,-7928,-7372,-6813,-6253,-5691,-5127
	dc.w -4561,-3994,-3426,-2857,-2286,-1716,-1144,-573
	dc.w 0,572,1144,1715,2286,2856,3425,3993
	dc.w 4560,5126,5690,6252,6813,7371,7927,8481
	dc.w 9032,9580,10126,10668,11207,11743,12275,12803
	dc.w 13328,13848,14364,14876,15383,15886,16383,16876
	dc.w 17364,17846,18323,18794,19260,19720,20173,20621
	dc.w 21062,21497,21925,22347,22762,23170,23571,23964
	dc.w 24351,24730,25101,25465,25821,26169,26509,26841
	dc.w 27165,27481,27788,28087,28377,28659,28932,29196
	dc.w 29451,29697,29934,30162,30381,30591,30791,30982
	dc.w 31163,31335,31498,31650,31794,31927,32051,32165
	dc.w 32269,32364,32448,32523,32588,32642,32687,32722
	dc.w 32747,32762,32767
Palette_FadeTarget:
	dc.w $0000,$0214,$0438,$0438,$0214,$0438,$0438,$0438
	dc.w $0000,$0214,$0438,$0438,$0214,$0438,$0438,$0438
	dc.w $0214,$0438,$0438,$0438,$0438,$086f,$0438,$0438
	dc.w $0214,$0438,$0438,$0438,$0438,$086f,$0438,$0438

Palette_Default:
	dc.w $0000,$0214,$0438,$0438,$0214,$0438,$0438,$0438
	dc.w $0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff
	dc.w $0214,$0438,$0438,$0438,$0438,$086f,$0438,$0438
	dc.w $0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff

Palette_Main:
	dc.w $0000,$0214,$0438,$0438,$0214,$0438,$0438,$0438
	dc.w $064a,$064a,$064a,$064a,$064a,$064a,$064a,$064a
	dc.w $0214,$0438,$0438,$0438,$0438,$086f,$0438,$0438
	dc.w $064a,$064a,$064a,$064a,$064a,$064a,$064a,$064a
Logo_Mask:
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $00000000,$3e03e000,$00000000,$00000000     ; ..................................*****.......*****.............................................................................
	dc.l $000001fc,$3e03e000,$0f803f00,$00000000     ; .......................*******....*****.......*****.................*****.........******........................................
	dc.l $000007ff,$3e03e03e,$3fe0ffc0,$00000000     ; .....................***********..*****.......*****.......*****...*********.....**********......................................
	dc.l $00000fff,$be03e03e,$fff1ffe0,$00000000     ; ....................*************.*****.......*****.......*****.************...************.....................................
	dc.l $00001fff,$fe03e03f,$fffbfff0,$00000000     ; ...................********************.......*****.......*******************.**************....................................
	dc.l $00003f83,$fe03e03f,$e1ffc3f0,$00000000     ; ..................*******.....*********.......*****.......*********....***********....******....................................
	dc.l $00007e01,$fe03e03f,$c0ff01f8,$00000000     ; .................******........********.......*****.......********......********.......******...................................
	dc.l $00007c00,$fe03e03f,$807f00f8,$00000000     ; .................*****..........*******.......*****.......*******........*******........*****...................................
	dc.l $0000f800,$7e03e03f,$007e00f8,$00000000     ; ................*****............******.......*****.......******.........******.........*****...................................
	dc.l $0000f800,$7e03e03f,$007c00f8,$00000000     ; ................*****............******.......*****.......******.........*****..........*****...................................
	dc.l $0000f800,$3e03e03e,$007c00f8,$00000000     ; ................*****.............*****.......*****.......*****..........*****..........*****...................................
	dc.l $0001f000,$3e03e03e,$007c00f8,$00000000     ; ...............*****..............*****.......*****.......*****..........*****..........*****...................................
	dc.l $fff1f000,$3e03e03e,$007c00f8,$1ffe0000     ; ************...*****..............*****.......*****.......*****..........*****..........*****......************.................
	dc.l $fff1f000,$3e03e03e,$007c00f8,$1ffe0000     ; ************...*****..............*****.......*****.......*****..........*****..........*****......************.................
	dc.l $fff1f000,$3e03e03e,$007c00f8,$1ffe0000     ; ************...*****..............*****.......*****.......*****..........*****..........*****......************.................
	dc.l $fff1f000,$3e03e03e,$007c00f8,$1ffe0000     ; ************...*****..............*****.......*****.......*****..........*****..........*****......************.................
	dc.l $fff1f000,$3e03e03e,$007c00f8,$1ffe0000     ; ************...*****..............*****.......*****.......*****..........*****..........*****......************.................
	dc.l $0001f000,$3e03e03e,$007c00f8,$00000000     ; ...............*****..............*****.......*****.......*****..........*****..........*****...................................
	dc.l $0001f000,$3e03e03e,$007c00f8,$00000000     ; ...............*****..............*****.......*****.......*****..........*****..........*****...................................
	dc.l $0001f800,$7e03e03e,$007c00f8,$00000000     ; ...............******............******.......*****.......*****..........*****..........*****...................................
	dc.l $0000f800,$7e03e03e,$007c00f8,$00000000     ; ................*****............******.......*****.......*****..........*****..........*****...................................
	dc.l $0000f800,$7e03e03e,$007c00f8,$00000000     ; ................*****............******.......*****.......*****..........*****..........*****...................................
	dc.l $0000fc00,$fe03e03e,$007c00f8,$00000000     ; ................******..........*******.......*****.......*****..........*****..........*****...................................
	dc.l $00007e01,$fe03e03e,$007c00f8,$00000000     ; .................******........********.......*****.......*****..........*****..........*****...................................
	dc.l $00003f03,$fe03e03e,$007c00f8,$00000000     ; ..................******......*********.......*****.......*****..........*****..........*****...................................
	dc.l $00003fff,$fe03e03e,$007c00f8,$00000000     ; ..................*********************.......*****.......*****..........*****..........*****...................................
	dc.l $00001fff,$be03e03e,$007c00f8,$00000000     ; ...................**************.*****.......*****.......*****..........*****..........*****...................................
	dc.l $000007fe,$3e03e03e,$007c00f8,$00000000     ; .....................**********...*****.......*****.......*****..........*****..........*****...................................
	dc.l $000001f8,$00000000,$00000000,$00000000     ; .......................******...................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
	dc.l $00000000,$00000000,$00000000,$00000000     ; ................................................................................................................................
IntroText:
	dc.b "--------------------------------"
	dc.b $0A
	dc.b "     D  E  L  I  R  I  U  M    "
	dc.b $0A
	dc.b "--------------------------------           "
	dc.b $0A
	dc.b $0A
	dc.b "      BENEATH A STEEL SKY!"
	dc.b $0A
	dc.b "          FROM VIRGIN"
	dc.b $0A
	dc.b $0A
	dc.b $0A
	dc.b "    CRACKED BY: PHIL DOUGLAS     "
	dc.b $0A
	dc.b $0A
	dc.b $65
	dc.b $0A
	dc.b $20
	dc.b $0A
	dc.b " - CALL OUR BOARDS WORLDWIDE! -"
	dc.b $0A
	dc.b $0A
	dc.b "         BLOODY DECISION"
	dc.b $0A
	dc.b "           COLD FUSION"
	dc.b $0A
	dc.b "          DEATH VALLEY!"
	dc.b $0A
	dc.b "          FUTURE SHOCK!"
	dc.b $0A
	dc.b "              HADES"
	dc.b $0A
	dc.b "            THE VAULT"
	dc.b $0A
	dc.b "               "
	dc.b $0A
	dc.b $0A
	dc.b $65
	dc.b $0A
	dc.b $20
	dc.b $0A
	dc.b $0A
	dc.b "       - QUICK CREDITS! -       "
	dc.b $0A
	dc.b $0A
	dc.b "   PROGRAMMING: WAYNE MENDOZA"
	dc.b $0A
	dc.b $0A
	dc.b "           FONT: MAZ!    "
	dc.b $0A
	dc.b $0A
	dc.b "--------------------------------"
	dc.b $0A
	dc.b "DELIRIUM - A TOUCH OF PERFECTION"
	dc.b $0A
	dc.b "--------------------------------"
	dc.b $0A
	dc.b $65
	dc.b $0A
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
Font_RawData:
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $03
	dc.b $00
	dc.b $00
	dc.b $03
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $03
	dc.b $03
	dc.b $03
	dc.b $03
	dc.b $03
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $33
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $3E
	dc.b $3E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $07
	dc.b $3E
	dc.b $0C
	dc.b ">>w~>"
	dc.b $7F
	dc.b $3E
	dc.b $3E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $3E
	dc.b $00
	dc.b ">~>~??>{??{xc~>~>~>"
	dc.b $7F
	dc.b "{{s{{"
	dc.b $7F
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $66
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $7E
	dc.b $3F
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $07
	dc.b $7F
	dc.b $1C
	dc.b $7F
	dc.b $7F
	dc.b $77
	dc.b $7E
	dc.b $7E
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $7F
	dc.b $00
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b "{??{xw"
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7E
	dc.b $7F
	dc.b "{{s{{"
	dc.b $7F
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $66
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $7E
	dc.b $3F
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $0E
	dc.b "{<ggw~~"
	dc.b $7F
	dc.b $73
	dc.b $73
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $77
	dc.b $00
	dc.b "{{{{xx{{"
	dc.b $1E
	dc.b $03
	dc.b $7B
	dc.b $78
	dc.b $7F
	dc.b "{{{{{x"
	dc.b $1C
	dc.b "{{s;{"
	dc.b $06
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $70
	dc.b $07
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $0E
	dc.b $7B
	dc.b $1C
	dc.b "fgw``"
	dc.b $07
	dc.b $73
	dc.b $73
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $77
	dc.b $00
	dc.b "{{x{xxx{"
	dc.b $1E
	dc.b $03
	dc.b $7A
	dc.b $78
	dc.b $7F
	dc.b "{{{{{~"
	dc.b $1C
	dc.b $7B
	dc.b $7B
	dc.b $73
	dc.b $1B
	dc.b $7B
	dc.b $06
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $70
	dc.b $07
	dc.b $66
	dc.b $18
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $1C
	dc.b $73
	dc.b $1C
	dc.b $0C
	dc.b $0E
	dc.b $7F
	dc.b $7E
	dc.b $7E
	dc.b $07
	dc.b $3E
	dc.b $73
	dc.b $1C
	dc.b $1C
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $07
	dc.b $00
	dc.b $7F
	dc.b "~x{~~{"
	dc.b $7F
	dc.b $1E
	dc.b "{~xk{{~{"
	dc.b $7F
	dc.b $3F
	dc.b $1C
	dc.b "{{s>>"
	dc.b $0C
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $FF
	dc.b $00
	dc.b $70
	dc.b $07
	dc.b $3C
	dc.b $FF
	dc.b $00
	dc.b $7F
	dc.b $00
	dc.b $1C
	dc.b $7F
	dc.b $1C
	dc.b $0C
	dc.b $06
	dc.b $07
	dc.b $7F
	dc.b $7F
	dc.b $07
	dc.b $3E
	dc.b $73
	dc.b $1C
	dc.b $1C
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $3F
	dc.b $00
	dc.b "{{x{xx{{"
	dc.b $1E
	dc.b "{{xs{{x{z"
	dc.b $03
	dc.b $1C
	dc.b "{{sz"
	dc.b $1C
	dc.b $18
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $FF
	dc.b $00
	dc.b $70
	dc.b $07
	dc.b $FF
	dc.b $FF
	dc.b $00
	dc.b $7F
	dc.b $00
	dc.b $38
	dc.b $79
	dc.b $1C
	dc.b $18
	dc.b $77
	dc.b $07
	dc.b $03
	dc.b $73
	dc.b $0E
	dc.b $73
	dc.b $3F
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $7E
	dc.b $00
	dc.b "{{x{xxy{"
	dc.b $1E
	dc.b "{{xs{{x{{{"
	dc.b $1C
	dc.b "{{s{"
	dc.b $1C
	dc.b $30
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $FF
	dc.b $00
	dc.b $70
	dc.b $07
	dc.b $3C
	dc.b $FF
	dc.b $00
	dc.b $7F
	dc.b $00
	dc.b $38
	dc.b $7B
	dc.b $1C
	dc.b $38
	dc.b $77
	dc.b $07
	dc.b $73
	dc.b $73
	dc.b $0E
	dc.b $73
	dc.b $07
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b "{{x{xxy{"
	dc.b $1E
	dc.b "{{xs{{x{{{"
	dc.b $1C
	dc.b "{{k{"
	dc.b $1C
	dc.b $70
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $70
	dc.b $07
	dc.b $66
	dc.b $18
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $70
	dc.b $7B
	dc.b $1C
	dc.b $7F
	dc.b $77
	dc.b $07
	dc.b $73
	dc.b $73
	dc.b $0E
	dc.b $73
	dc.b $77
	dc.b $1C
	dc.b $1C
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b "{{{{xxy{"
	dc.b $1E
	dc.b "{{xs{{xy{{"
	dc.b $1C
	dc.b $7B
	dc.b $7B
	dc.b $7F
	dc.b $7B
	dc.b $1C
	dc.b $70
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $7F
	dc.b $7F
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $70
	dc.b $7F
	dc.b $3E
	dc.b $7F
	dc.b $7F
	dc.b $07
	dc.b $7F
	dc.b $7F
	dc.b $0E
	dc.b $7F
	dc.b $7F
	dc.b $1C
	dc.b $1C
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b $7B
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $78
	dc.b $7F
	dc.b $7B
	dc.b $3F
	dc.b $7F
	dc.b $7B
	dc.b $7F
	dc.b $73
	dc.b $7B
	dc.b $7F
	dc.b $78
	dc.b $76
	dc.b $7B
	dc.b $7F
	dc.b $1C
	dc.b $7F
	dc.b $3E
	dc.b $7F
	dc.b $7B
	dc.b $1C
	dc.b $7F
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $7F
	dc.b $7F
	dc.b $00
	dc.b $18
	dc.b $0C
	dc.b $00
	dc.b $00
	dc.b $E0
	dc.b $7F
	dc.b $3E
	dc.b $7F
	dc.b $7F
	dc.b $07
	dc.b $7F
	dc.b $7F
	dc.b $0E
	dc.b $7F
	dc.b $7F
	dc.b $00
	dc.b $38
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b $7B
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $7F
	dc.b $78
	dc.b $7F
	dc.b $7B
	dc.b $3F
	dc.b $7F
	dc.b $7B
	dc.b $7F
	dc.b $73
	dc.b $7B
	dc.b $7F
	dc.b $78
	dc.b $7B
	dc.b $7B
	dc.b $7F
	dc.b $1C
	dc.b $7F
	dc.b $1C
	dc.b $77
	dc.b $7B
	dc.b $1C
	dc.b $7F
	dc.b $00
	dc.b $00
	dc.b $1E
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $3F
	dc.b $7E
	dc.b $00
	dc.b $00
	dc.b $1C
	dc.b $00
	dc.b $18
	dc.b $E0
	dc.b $3E
	dc.b $3E
	dc.b $7F
	dc.b $3E
	dc.b $07
	dc.b $3E
	dc.b $3E
	dc.b $0E
	dc.b $3E
	dc.b $3E
	dc.b $00
	dc.b $70
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b "{~>~"
	dc.b $7F
	dc.b "x>{?>{"
	dc.b $7F
	dc.b "s{>x={>"
	dc.b $1C
	dc.b $3E
	dc.b $08
	dc.b $63
	dc.b $7B
	dc.b $1C
	dc.b $7F
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $18
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b $70
	dc.b $78
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $00
	dc.b $78
	dc.b $00
	dc.b $00
	dc.b $00
; ============================================================================
; Data: Gfx_ManiacLogo
; Purpose : 48x8 1-bitplane logo for "MASQUE" displayed on screen.
; Notes   : The copy loop copies 8 rows * 6 bytes = 48 bytes.
;           However, this data block is only 44 bytes long, meaning the last
;           4 bytes of the 8th row are read from the start of Hunk 1 DATA
;           (CopperList_Main: $00, $8E, $36, $A1).
; ============================================================================
Gfx_ManiacLogo:
	dc.b $D1,$CC,$E9,$30,$00,$00            ; **.*...***..**..***.*..*..**....................
	dc.b $AA,$51,$29,$50,$00,$00            ; *.*.*.*..*.*...*..*.*..*.*.*....................
	dc.b $AA,$5D,$29,$60,$00,$00            ; *.*.*.*..*.***.*..*.*..*.**.....................
	dc.b $AA,$C5,$29,$40,$00,$00            ; *.*.*.*.**...*.*..*.*..*.*......................
	dc.b $A9,$58,$C7,$30,$00,$00            ; *.*.*..*.*.**...**...***..**....................
	dc.b $00,$00,$20,$00,$00,$00            ; ..................*.............................
	dc.b $00,$00,$20,$00,$00,$00            ; ..................*.............................
	dc.b $00,$00                            ; ................ (rem. 4 bytes read from Hunk 1)

; ============================================================================
; Hunk 1: Copper Lists and Palette Data
; ============================================================================
	SECTION Hunk_1_Data, DATA, CHIP

CopperList_Main:
	dc.w    $008e,$36a1                     ; DIWSTRT: Display Window Start (y=54, x=161)
	dc.w    $0090,$fea1                     ; DIWSTOP: Display Window Stop (y=254, x=161)
	dc.w    $0092,$0048                     ; DDFSTRT: Data Fetch Start (low res, start x=72)
	dc.w    $0094,$00c0                     ; DDFSTOP: Data Fetch Stop (low res, stop x=192)
	dc.w    $0102,$0000                     ; BPLCON1: Playfield scroll offset 0.
	dc.w    $0104,$0000                     ; BPLCON2: Playfield priority 0.
	dc.w    $0108,$0000                     ; BPL1MOD: Playfield 1 (odd) modulo 0.
	dc.w    $010a,$0000                     ; BPL2MOD: Playfield 2 (even) modulo 0.

Copper_FMODE:
	dc.w    $01fe,$0000                     ; FMODE: Fetch mode (OCS/ECS compatibility).
	dc.w    $01fe,$0000                     ; (Duplicate for alignment/redundancy).

Copper_BplPtrs:
	dc.w    $0000,$0000                     ; BPL1PTL ($00e2) placeholder (written at runtime).
	dc.w    $0000,$0000                     ; BPL1PTH ($00e0)
	dc.w    $0000,$0000                     ; BPL2PTL ($00e6)
	dc.w    $0000,$0000                     ; BPL2PTH ($00e4)
	dc.w    $0000,$0000                     ; BPL3PTL ($00ea)
	dc.w    $0000,$0000                     ; BPL3PTH ($00e8)
	dc.w    $0000,$0000                     ; BPL4PTL ($00ee)
	dc.w    $0000,$0000                     ; BPL4PTH ($00ec)
	dc.w    $0000,$0000                     ; BPL5PTL ($00f2)
	dc.w    $0000,$0000                     ; BPL5PTH ($00f0)
	dc.w    $0100,$5200                     ; BPLCON0 ($0100) = $5200 (Dual playfield, 5 bitplanes)

Copper_Palette:
	dc.w    $0180,$0000                     ; COLOR00: Black
	dc.w    $0182,$0214                     ; COLOR01: Dark blue
	dc.w    $0184,$0438                     ; COLOR02: Blue
	dc.w    $0186,$0438                     ; COLOR03: Blue
	dc.w    $0188,$0214                     ; COLOR04: Dark blue
	dc.w    $018a,$0438                     ; COLOR05: Blue
	dc.w    $018c,$0438                     ; COLOR06: Blue
	dc.w    $018e,$0438                     ; COLOR07: Blue
	dc.w    $0190,$0fff                     ; COLOR08: White
	dc.w    $0192,$0fff                     ; COLOR09: White
	dc.w    $0194,$0fff                     ; COLOR10: White
	dc.w    $0196,$0fff                     ; COLOR11: White
	dc.w    $0198,$0fff                     ; COLOR12: White
	dc.w    $019a,$0fff                     ; COLOR13: White
	dc.w    $019c,$0fff                     ; COLOR14: White
	dc.w    $019e,$0fff                     ; COLOR15: White
	dc.w    $01a0,$0214                     ; COLOR16: Dark blue
	dc.w    $01a2,$0438                     ; COLOR17: Blue
	dc.w    $01a4,$0438                     ; COLOR18: Blue
	dc.w    $01a6,$0438                     ; COLOR19: Blue
	dc.w    $01a8,$0438                     ; COLOR20: Blue
	dc.w    $01aa,$086f                     ; COLOR21: Light blue/cyan
	dc.w    $01ac,$0438                     ; COLOR22: Blue
	dc.w    $01ae,$0438                     ; COLOR23: Blue
	dc.w    $01b0,$0fff                     ; COLOR24: White
	dc.w    $01b2,$0fff                     ; COLOR25: White
	dc.w    $01b4,$0fff                     ; COLOR26: White
	dc.w    $01b6,$0fff                     ; COLOR27: White
	dc.w    $01b8,$0fff                     ; COLOR28: White
	dc.w    $01ba,$0fff                     ; COLOR29: White
	dc.w    $01bc,$0fff                     ; COLOR30: White
	dc.w    $01be,$0fff                     ; COLOR31: White

Copper_RasterSplitList:
	dcb.l   501,$fffffffe                   ; 501 copper wait split lines instructions ($fffffffe).

; ========================================
	SECTION Hunk_2_Bss, BSS, CHIP
Buf_Bpl1:
	ds.b 27312
Buf_Bpl3             EQU     Buf_Bpl1+$C80
Buf_Bpl5             EQU     Buf_Bpl1+$1900
Buf_Bpl4_Alt         EQU     Buf_Bpl1+$2580
Buf_Bpl2             EQU     Buf_Bpl1+$3200
Buf_Bpl4             EQU     Buf_Bpl1+$4B00
Var_TextBuffer       EQU     Buf_Bpl1+$4B40
Buf_ManiacLogoDest   EQU     Buf_Bpl1+$633C
Var_FontOffsetTable  EQU     Buf_Bpl1+$6420
Buf_BssEnd           EQU     Buf_Bpl1+$6AB0

; ========================================
	SECTION Hunk_3_Bss, BSS
Buf_DecompressedLogo:
	ds.b 65536                      ; 64KB decompressed logo mask buffer.

