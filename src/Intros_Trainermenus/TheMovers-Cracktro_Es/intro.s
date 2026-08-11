; ============================================================================
; THE MOVERS - cracktro for "Emetic Skimmer" (Dated: Jan 8, 1988)
; Reconstructed, commented vasm source (motorola syntax)
;
; Assemble with:
;   vasmm68k_mot -Fhunkexe -nosym -no-opt -kick1hunks -o intro intro.s
; 
; Reconstructed by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================

; -------------------- custom chip hardware registers ------------------------
AUD0LCH  = $dff0a0
AUD0LEN  = $dff0a4
AUD0PER  = $dff0a6
AUD0VOL  = $dff0a8
AUD1LCH  = $dff0b0
AUD1LEN  = $dff0b4
AUD1PER  = $dff0b6
AUD1VOL  = $dff0b8
BLTAFWM  = $dff044
BLTAMOD  = $dff064
BLTAPT   = $dff050
BLTCON0  = $dff040
BLTCON1  = $dff042
BLTDMOD  = $dff066
BLTDPT   = $dff054
BLTSIZE  = $dff058
BPLCON0  = $dff100
BPLCON1  = $dff102
BPLCON2  = $dff108
CIAAPRA  = $bfe001
DDFSTOP  = $dff094
DDFSTRT  = $dff092
DIWSTOP  = $dff090
DIWSTRT  = $dff08e
DMACON   = $dff096
DMACONR  = $dff002
INTENA   = $dff09a
INTREQR  = $dff01e

SCREEN   = $50000        ; bitplane in chip RAM (40 bytes/line, 204 lines)
COLS     = 40            ; bytes per raster line (320 pixels, 1 bitplane)

IRQOldVec = IRQJump+2   ; operand of the 'jmp' in the IRQ handler (patched-in vector)

		section	code,code_c

; ============================================================================
; STARTUP: open the library, hook in the copper list, initialize everything
; ============================================================================
		movea.l  #GfxName,a1                                ; library name for OldOpenLibrary
		movea.l  $4.l,a6                                    ; ExecBase
		jsr      -$198(a6)                                  ; _LVOOldOpenLibrary(-$198): open graphics.library
		movea.l  d0,a0                                      ; GfxBase into a0
		move.l   d0,GfxBase.l                               ; remember it for the cleanup on exit
		adda.l   #$32,a0                                    ; a0 -> GfxBase.LOFlist: pointer to the copper list
		move.w   #$80,DMACON.l                              ; copper DMA off while we swap the list
		move.l   (a0),OldLOFlist.l                          ; save the old LOFlist
		move.l   #CopperList,(a0)                           ; hook in ours (the OS vblank picks it up)
		move.w   #$8080,DMACON.l                            ; copper DMA back on
		jsr      SoundStart.l
		jsr      ClearScreen.l
		jsr      CopyLogo.l
		jsr      PrintTitle.l
		jsr      SetupDisplay.l
		jsr      InitVars.l
		jsr      InstallIRQ.l
WaitMouse:
		move.b   CIAAPRA.l,d0                               ; CIA-A PRA bit 6: left mouse button (0 = pressed)
		andi.l   #$40,d0                                    ; test bit 6
		bne.w    WaitMouse                                  ; hang out until it gets clicked
		move.w   #$4000,INTENA.l                            ; master interrupt enable off
		move.l   IRQOldVec.l,$6c.l                          ; put the old level 3 vector back
		move.w   #$c000,INTENA.l                            ; interrupts back on
		movea.l  GfxBase.l,a0
		adda.l   #$32,a0
		move.w   #$80,DMACON.l                              ; copper DMA off
		move.l   OldLOFlist.l,(a0)                          ; restore the original LOFlist
		move.w   #$8080,DMACON.l                            ; copper DMA back on
		move.l   #$0,d0                                     ; return code 0
		jsr      SoundStop.l
		rts

; ============================================================================
; DATA: library name + saved OS pointers
; ============================================================================
GfxName:	dc.b	"graphics.library",0
		dc.b	0			; pad byte (keeps the next label even)
OldLOFlist:	dc.l	0		; original GfxBase.LOFlist, saved at runtime
GfxBase:	dc.l	0		; graphics.library base address

; ============================================================================
; SoundStart: play the digi sample in an endless loop on channels 0+1
; ============================================================================
SoundStart:
		move.l   #Sample,AUD0LCH.l                          ; sample address, channel 0
		move.l   #Sample,AUD1LCH.l                          ; sample address, channel 1
		move.w   #$6881,AUD0LEN.l                           ; length $6881 words (~53 KB)
		move.w   #$6881,AUD1LEN.l
		move.w   #$40,AUD0VOL.l                             ; full volume
		move.w   #$40,AUD1VOL.l
		move.w   #$101,AUD0PER.l                            ; period $101 (~11 kHz)
		move.w   #$101,AUD1PER.l
		move.w   #$8383,DMACON.l                            ; audio DMA on for channels 0+1, loops forever
		rts

; ============================================================================
; SoundStop: silence both audio channels
; ============================================================================
SoundStop:
		clr.w    AUD0VOL.l                                  ; volume to 0
		clr.w    AUD1VOL.l
		move.w   #$3,DMACON.l                               ; audio DMA off
		rts

; ============================================================================
; InitVars: set up the text and color pointers
; ============================================================================
InitVars:
		move.l   #ScrollTextTop,TxtPtrTop.l                 ; text pointer, upper scroller
		move.l   #ScrollTextBottom,TxtPtrBottom.l           ; text pointer, lower scroller
		move.l   #ColorTable,ColPtrBars.l                   ; color table pointer, scroll bar pipeline
		move.l   #ColorTable,ColPtrLogo.l                   ; color table pointer, logo pipeline
		rts

; ============================================================================
; PrintTitle: stamp "emetic skimmer!" onto line 160, once
; ============================================================================
PrintTitle:
		movea.l  #TitleText,a4                              ; a4 -> title string
		move.b   #$0,CharX.l                                ; X = 0 (byte column)
		move.b   #$a0,CharY.l                               ; Y = $a0 (line 160)
PTLoop:
		move.b   (a4)+,CharCode.l                           ; fetch a character
		jsr      PrintChar.l                                ; and draw it
		cmpi.b   #$0,(a4)                                   ; hit the 0 terminator?
		bne.w    PTLoop
		rts

; ============================================================================
; Scroll texts (plain ASCII, 0-terminated)
; ============================================================================
ScrollTextBottom:
		dc.b	" cracked on the 8.1.1988 by general zoff & skylab !!!  original supplied by drago & amadeus !!! new member list:  drago , amadeus , rgb (canada) , general zoff and skylab !!!              ",0,0
ScrollTextTop:
		dc.b	" golden regards to the mighty:  bamiga sector one & the kent team , the bitstoppers  !!!Greetings to our friends:  the hellion , the cure , tom , unit a , supremacy , delta force , hqc , ssi , bfbs , rage , blizzard , eca , enterprise , vision , the general , gigaflops , tristar , triad , red sector , aca , tcs , jazzcat , fairlight , ikari , popeye , rdi , hellraider , danish gold , defsam , ibb , ccw team , crm crew , sca , antitrax , starfrontiers , spreadpoint , the web inc. , the light circle , survivors , destroyer , dr. soft , alex , pascal , 1001 crew , visitors , dr.f , heavy bits , hotline ......                               ",0,0
TitleText:
		dc.b	"             emetic skimmer!   ",0

; ============================================================================
; ScrollTick: every 8 frames, print the next character of both scrollers
; ============================================================================
ScrollTick:
		movea.l  TxtPtrTop.l,a0                             ; --- upper scroller ---
		move.b   (a0)+,CharCode.l
		move.l   a0,TxtPtrTop.l
		cmpi.b   #$0,(a0)                                   ; end of text?
		bne.w    STNoWrap1
		move.l   #ScrollTextTop,TxtPtrTop.l                 ; wrap around to the start
STNoWrap1:
		move.b   #$27,CharX.l                               ; X = 39 (right edge)
		move.b   #$20,CharY.l                               ; Y = $20 (line 32, upper scroller)
		jsr      PrintChar.l
		movea.l  TxtPtrBottom.l,a0                          ; --- lower scroller ---
		move.b   (a0)+,CharCode.l
		move.l   a0,TxtPtrBottom.l
		cmpi.b   #$0,(a0)
		bne.w    STNoWrap2
		move.l   #ScrollTextBottom,TxtPtrBottom.l
STNoWrap2:
		move.b   #$27,CharX.l                               ; X = 39
		move.b   #$c0,CharY.l                               ; Y = $c0 (line 192, lower scroller)
		jsr      PrintChar.l
		rts

; ============================================================================
; CycleBarCols: shift the rainbow through the scroll bar strips (every frame)
; ============================================================================
CycleBarCols:
		move.w   ColTabBars+48.l,ColTabBars+56.l            ; shift the 8-slot pipeline down by one
		move.w   ColTabBars+40.l,ColTabBars+48.l
		move.w   ColTabBars+32.l,ColTabBars+40.l
		move.w   ColTabBars+24.l,ColTabBars+32.l
		move.w   ColTabBars+16.l,ColTabBars+24.l
		move.w   ColTabBars+8.l,ColTabBars+16.l
		move.w   ColTabBars.l,ColTabBars+8.l
		movea.l  ColPtrBars.l,a0                            ; pull the next color from the table
		move.w   (a0)+,ColTabBars.l
		move.l   a0,ColPtrBars.l
		cmpi.w   #$ffff,(a0)                                ; end marker ($ffff)?
		bne.w    FLSNoReset
		move.l   #ColorTable,ColPtrBars.l                   ; start the table over
FLSNoReset:
		move.w   ColTabBars.l,CopBarBottom.l                ; copy the pipeline into the lower bar's copper slots
		move.w   ColTabBars+8.l,CopBarBottom+8.l
		move.w   ColTabBars+16.l,CopBarBottom+16.l
		move.w   ColTabBars+24.l,CopBarBottom+24.l
		move.w   ColTabBars+32.l,CopBarBottom+32.l
		move.w   ColTabBars+40.l,CopBarBottom+40.l
		move.w   ColTabBars+48.l,CopBarBottom+48.l
		move.w   ColTabBars+56.l,CopBarBottom+56.l
		rts

; ============================================================================
; InstallIRQ: hook in our own level 3 interrupt (VERTB)
; ============================================================================
InstallIRQ:
		move.w   #$4000,INTENA.l                            ; master interrupt enable off
		move.l   $6c.l,IRQOldVec.l                          ; save the old level 3 vector ($6c)
		move.l   #IRQHandler,$6c.l                          ; point it at our handler
		move.w   #$c000,INTENA.l                            ; interrupts back on
		rts

; ============================================================================
; FrameMain: runs on every vertical blank
; ============================================================================
FrameMain:
		jsr      CycleBarCols.l                             ; cycle the colors, move the scrollers
		jsr      ScrollBars.l
		jsr      CycleLogoCols.l
		addi.b   #$1,FrameCount.l                           ; frame counter++
		cmpi.b   #$8,FrameCount.l                           ; every 8th frame...
		bne.w    FRNoTick
		jsr      ScrollTick.l                               ; ...print the next character of both texts
		move.b   #$0,FrameCount.l
FRNoTick:
		rts

; ============================================================================
; IRQHandler: level 3 autovector ($6c)
; ============================================================================
IRQHandler:
		movem.l  d0-d6/a0-a6,-(a7)                          ; save the registers
		move.w   sr,-(a7)
		move.w   INTREQR.l,d0                               ; what's asking?
		btst     #$5,d0                                     ; bit 5 = VERTB (vertical blank)
		beq.w    IRQDone                                    ; not ours -> done
		jsr      FrameMain.l
IRQDone:
		move.w   (a7)+,sr
		movem.l  (a7)+,d0-d6/a0-a6
IRQJump:
		jmp      $0.l                                       ; chain to the old handler (address patched by InstallIRQ!)

; ============================================================================
; PrintChar: copy one 8x8 character from the font bitmap into the screen
; ============================================================================
PrintChar:
		jsr      CalcFontPos.l                              ; where the glyph lives in the font
		jsr      CalcScreenPos.l                            ; where it goes on screen
		move.b   #$8,d0                                     ; 8 lines per character
		movea.l  FontPos.l,a0
		movea.l  ScreenPos.l,a1
PCLoop:
		move.b   (a0),(a1)                                  ; copy 1 byte = 8 pixels
		adda.l   #$28,a0                                    ; font bitmap: 40 bytes per line
		adda.l   #$28,a1                                    ; screen: 40 bytes per line
		subi.b   #$1,d0
		bne.w    PCLoop
		rts

; ============================================================================
; ScrollBars: blit both scroll lines 1 pixel to the left
; ============================================================================
ScrollBars:
		jsr      BlitBarTop.l                               ; upper bar...
		jsr      WaitBlit.l                                 ; one blit at a time
		jsr      BlitBarBottom.l                            ; ...then the lower one
		rts

; ============================================================================
; CycleLogoCols: shift the rainbow through the logo area (66 raster lines)
; ============================================================================
CycleLogoCols:
		move.w   ColTabLogo+520.l,ColTabLogo+528.l          ; shift the 66-slot pipeline down by one
		move.w   ColTabLogo+512.l,ColTabLogo+520.l
		move.w   ColTabLogo+504.l,ColTabLogo+512.l
		move.w   ColTabLogo+496.l,ColTabLogo+504.l
		move.w   ColTabLogo+488.l,ColTabLogo+496.l
		move.w   ColTabLogo+480.l,ColTabLogo+488.l
		move.w   ColTabLogo+472.l,ColTabLogo+480.l
		move.w   ColTabLogo+464.l,ColTabLogo+472.l
		move.w   ColTabLogo+456.l,ColTabLogo+464.l
		move.w   ColTabLogo+448.l,ColTabLogo+456.l
		move.w   ColTabLogo+440.l,ColTabLogo+448.l
		move.w   ColTabLogo+432.l,ColTabLogo+440.l
		move.w   ColTabLogo+424.l,ColTabLogo+432.l
		move.w   ColTabLogo+416.l,ColTabLogo+424.l
		move.w   ColTabLogo+408.l,ColTabLogo+416.l
		move.w   ColTabLogo+400.l,ColTabLogo+408.l
		move.w   ColTabLogo+392.l,ColTabLogo+400.l
		move.w   ColTabLogo+384.l,ColTabLogo+392.l
		move.w   ColTabLogo+376.l,ColTabLogo+384.l
		move.w   ColTabLogo+368.l,ColTabLogo+376.l
		move.w   ColTabLogo+360.l,ColTabLogo+368.l
		move.w   ColTabLogo+352.l,ColTabLogo+360.l
		move.w   ColTabLogo+344.l,ColTabLogo+352.l
		move.w   ColTabLogo+336.l,ColTabLogo+344.l
		move.w   ColTabLogo+328.l,ColTabLogo+336.l
		move.w   ColTabLogo+320.l,ColTabLogo+328.l
		move.w   ColTabLogo+312.l,ColTabLogo+320.l
		move.w   ColTabLogo+304.l,ColTabLogo+312.l
		move.w   ColTabLogo+296.l,ColTabLogo+304.l
		move.w   ColTabLogo+288.l,ColTabLogo+296.l
		move.w   ColTabLogo+280.l,ColTabLogo+288.l
		move.w   ColTabLogo+272.l,ColTabLogo+280.l
		move.w   ColTabLogo+264.l,ColTabLogo+272.l
		move.w   ColTabLogo+256.l,ColTabLogo+264.l
		move.w   ColTabLogo+248.l,ColTabLogo+256.l
		move.w   ColTabLogo+240.l,ColTabLogo+248.l
		move.w   ColTabLogo+232.l,ColTabLogo+240.l
		move.w   ColTabLogo+224.l,ColTabLogo+232.l
		move.w   ColTabLogo+216.l,ColTabLogo+224.l
		move.w   ColTabLogo+208.l,ColTabLogo+216.l
		move.w   ColTabLogo+200.l,ColTabLogo+208.l
		move.w   ColTabLogo+192.l,ColTabLogo+200.l
		move.w   ColTabLogo+184.l,ColTabLogo+192.l
		move.w   ColTabLogo+176.l,ColTabLogo+184.l
		move.w   ColTabLogo+168.l,ColTabLogo+176.l
		move.w   ColTabLogo+160.l,ColTabLogo+168.l
		move.w   ColTabLogo+152.l,ColTabLogo+160.l
		move.w   ColTabLogo+144.l,ColTabLogo+152.l
		move.w   ColTabLogo+136.l,ColTabLogo+144.l
		move.w   ColTabLogo+128.l,ColTabLogo+136.l
		move.w   ColTabLogo+120.l,ColTabLogo+128.l
		move.w   ColTabLogo+112.l,ColTabLogo+120.l
		move.w   ColTabLogo+104.l,ColTabLogo+112.l
		move.w   ColTabLogo+96.l,ColTabLogo+104.l
		move.w   ColTabLogo+88.l,ColTabLogo+96.l
		move.w   ColTabLogo+80.l,ColTabLogo+88.l
		move.w   ColTabLogo+72.l,ColTabLogo+80.l
		move.w   ColTabLogo+64.l,ColTabLogo+72.l
		move.w   ColTabLogo+56.l,ColTabLogo+64.l
		move.w   ColTabLogo+48.l,ColTabLogo+56.l
		move.w   ColTabLogo+40.l,ColTabLogo+48.l
		move.w   ColTabLogo+32.l,ColTabLogo+40.l
		move.w   ColTabLogo+24.l,ColTabLogo+32.l
		move.w   ColTabLogo+16.l,ColTabLogo+24.l
		move.w   ColTabLogo+8.l,ColTabLogo+16.l
		move.w   ColTabLogo.l,ColTabLogo+8.l
		movea.l  ColPtrLogo.l,a0                            ; pull the next color from the table
		move.w   (a0)+,ColTabLogo.l
		move.l   a0,ColPtrLogo.l
		cmpi.w   #$ffff,(a0)                                ; end marker?
		bne.w    FLLNoReset
		move.l   #ColorTable,ColPtrLogo.l                   ; start the table over
FLLNoReset:
		rts

; ============================================================================
; BlitBarTop / BlitBarBottom / WaitBlit: the blitter scrolling
; ============================================================================
BlitBarTop:
		move.w   #$f9f0,BLTCON0.l                           ; A->D, shift 15; with dst = src-1 that's 1 pixel left
		move.w   #$0,BLTCON1.l
		move.l   #$ffffffff,BLTAFWM.l                       ; no masking
		move.l   #$50500,BLTAPT.l                           ; source: screen lines 32..40 (upper scroller)
		move.l   #$504ff,BLTDPT.l                           ; dest: one byte earlier
		move.w   #$0,BLTAMOD.l                              ; no modulos
		move.w   #$0,BLTDMOD.l
		move.w   #$253,BLTSIZE.l                            ; 9 lines x 19 words, fire
		rts
BlitBarBottom:
		move.w   #$f9f0,BLTCON0.l                           ; same thing for the lower scroller (lines 192..200)
		move.w   #$0,BLTCON1.l
		move.l   #$ffffffff,BLTAFWM.l
		move.l   #$51e00,BLTAPT.l
		move.l   #$51dff,BLTDPT.l
		move.w   #$0,BLTAMOD.l
		move.w   #$0,BLTDMOD.l
		move.w   #$253,BLTSIZE.l
		rts
WaitBlit:
		move.w   DMACONR.l,d0                               ; wait for the blitter to finish (BBUSY)
		btst     #$e,d0
		bne.w    WaitBlit
		rts

; ============================================================================
; CalcScreenPos / CalcFontPos / CharToFontOffset: address math
; ============================================================================
CalcScreenPos:
		clr.l    d0                                         ; dest = SCREEN + Y*40 + X
		move.b   CharY.l,d0
		mulu.w   #$28,d0
		clr.l    d1
		move.b   CharX.l,d1
		add.l    d1,d0
		addi.l   #$50000,d0
		move.l   d0,ScreenPos.l
		addi.b   #$1,CharX.l                                ; bump X for the next character
		rts
CalcFontPos:
		jsr      CharToFontOffset.l                         ; glyph offset + font base
		addi.l   #Font,d0
		move.l   d0,FontPos.l
		rts
CharToFontOffset:
		clr.l    d0                                         ; ASCII code -> byte offset into the 40-column font bitmap
		move.b   CharCode.l,d0
		subi.b   #$1,d0                                     ; code-1, plus one row-block offset per 40 chars
		cmpi.b   #$77,d0
		bls.w    CTOLow
		addi.w   #$348,d0
		rts
CTOLow:
		cmpi.b   #$4f,d0
		bls.w    CTOMid
		addi.w   #$230,d0
		rts
CTOMid:
		cmpi.b   #$27,d0
		bls.w    CTORts
		addi.w   #$118,d0
CTORts:
		rts

; ============================================================================
; ClearScreen: wipe the 8 KB screen at $50000
; ============================================================================
ClearScreen:
		movea.l  #$50000,a0
		move.w   #$2000,d0
CSLoop:
		move.b   #$0,(a0)+
		subi.w   #$1,d0
		bne.w    CSLoop
		rts

; ============================================================================
; SetupDisplay: display registers (1 bitplane, 320x~204)
; ============================================================================
SetupDisplay:
		move.w   #$1200,BPLCON0.l                           ; 1 bitplane, color on
		clr.w    BPLCON1.l                                  ; no scroll offset
		clr.w    BPLCON2.l                                  ; no playfield priority tricks
		move.w   #$38,DDFSTRT.l                             ; data fetch: 320 pixels
		move.w   #$d0,DDFSTOP.l
		move.w   #$2c81,DIWSTRT.l                           ; display window start/stop
		move.w   #$f4b9,DIWSTOP.l
		move.l   #$0,$70000.l                               ; clear the null sprite at $70000 (sprites off, see copper list)
		rts

; ============================================================================
; CopyLogo: copy the logo bitmap into the screen
; ============================================================================
CopyLogo:
		movea.l  #Font,a0                                   ; the logo sits right behind the font in the hunk
		adda.l   #$7d0,a0                                   ; source = Font+$7d0 = Logo
		movea.l  #$507d0,a1                                 ; dest = SCREEN+$7d0 (line 50)
CLLoop:
		move.l   (a0)+,(a1)+                                ; 6192 bytes = ~154 lines
		cmpa.l   #$52000,a1
		bne.w    CLLoop
		rts

; ============================================================================
; Variables (they live in the code hunk and get written at runtime)
; ============================================================================
ColPtrLogo:	dc.l	0	; read pointer into ColorTable (logo pipeline)
ColPtrBars:	dc.l	0	; read pointer into ColorTable (scroll bar pipeline)
TxtPtrTop:	dc.l	0	; read pointer into ScrollTextTop
TxtPtrBottom:	dc.l	0	; read pointer into ScrollTextBottom
ScreenPos:	dc.l	0	; current destination address in the screen
FontPos:	dc.l	0	; current source address in the font
CharCode:	dc.b	0	; the character being printed (ASCII)
CharX:	dc.b	0	; X position (byte column 0..39)
CharY:	dc.b	0	; Y position (raster line)
FrameCount:	dc.b	0	; frame counter 0..7

; ============================================================================
; Copper list: 1 bitplane at $50000, palette, rainbow color strips
; ============================================================================
; The color slots are 8-byte records: MOVE COLOR01,<value> followed by a
; WAIT. The color value sits at the start of each record; CycleBarCols/
; CycleLogoCols shift those values one slot down every frame — that's what
; makes the rainbow "run" through the bars.
CopperList:
		dc.w	$0180,$0000		; COLOR00 = black
		dc.w	$00e0,$0005		; BPL1PTH: bitplane at $50000
		dc.w	$00e2,$0000		; BPL1PTL
						; Point all 8 sprites at a null sprite at $70000 (sprites off).
						; SetupDisplay clears a long there.
		dc.w	$0120,$0007		; SPR0PTH/PTL = $70000
		dc.w	$0122,$0000
		dc.w	$0124,$0007		; SPR1PTH/PTL = $70000
		dc.w	$0126,$0000
		dc.w	$0128,$0007		; SPR2PTH/PTL = $70000
		dc.w	$012a,$0000
		dc.w	$012c,$0007		; SPR3PTH/PTL = $70000
		dc.w	$012e,$0000
		dc.w	$0130,$0007		; SPR4PTH/PTL = $70000
		dc.w	$0132,$0000
		dc.w	$0134,$0007		; SPR5PTH/PTL = $70000
		dc.w	$0136,$0000
		dc.w	$0138,$0007		; SPR6PTH/PTL = $70000
		dc.w	$013a,$0000
		dc.w	$013c,$0007		; SPR7PTH/PTL = $70000
		dc.w	$013e,$0000
		dc.w	$4a01,$ff00		; WAIT line $4a
		dc.w	$0180,$0777		; COLOR00 = grey
		dc.w	$4c01,$ff00		; WAIT line $4c
		dc.w	$0180,$0333		; COLOR00 = dark grey

; --- 8 color slots: upper scroll bar (lines $4d-$54 = screen lines 33-40) ---
		dc.w	$0182
ColTabBars:
		dc.w	$0000,$4d01,$ff00	; slot 0 (color value + WAIT $4d)
		dc.w	$0182
		dc.w	$0000,$4e01,$ff00	; slot 1 (ColTabBars+8, WAIT $4e)
		dc.w	$0182
		dc.w	$0000,$4f01,$ff00	; slot 2 (ColTabBars+16, WAIT $4f)
		dc.w	$0182
		dc.w	$0000,$5001,$ff00	; slot 3 (ColTabBars+24, WAIT $50)
		dc.w	$0182
		dc.w	$0000,$5101,$ff00	; slot 4 (ColTabBars+32, WAIT $51)
		dc.w	$0182
		dc.w	$0000,$5201,$ff00	; slot 5 (ColTabBars+40, WAIT $52)
		dc.w	$0182
		dc.w	$0000,$5301,$ff00	; slot 6 (ColTabBars+48, WAIT $53)
		dc.w	$0182
		dc.w	$0000,$5401,$ff00	; slot 7 (ColTabBars+56, WAIT $54)
		dc.w	$0180,$0777		; COLOR00 = grey
		dc.w	$5601,$ff00		; WAIT line $56
		dc.w	$0180,$0000		; COLOR00 = black
		dc.w	$6001,$ff00		; WAIT line $60
		dc.w	$0182,$0000		; COLOR01 = black
		dc.w	$6201,$ff00		; WAIT line $62

; --- 66 color slots: logo area (lines $63-$a5, COLOR01 rainbow) ---
		dc.w	$0182
ColTabLogo:
		dc.w	$0000,$6301,$ff00	; slot 0 (WAIT $63)
		dc.w	$0182
		dc.w	$0000,$6401,$ff00	; slot 1 (WAIT $64)
		dc.w	$0182
		dc.w	$0000,$6501,$ff00	; slot 2 (WAIT $65)
		dc.w	$0182
		dc.w	$0000,$6601,$ff00	; slot 3 (WAIT $66)
		dc.w	$0182
		dc.w	$0000,$6701,$ff00	; slot 4 (WAIT $67)
		dc.w	$0182
		dc.w	$0000,$6801,$ff00	; slot 5 (WAIT $68)
		dc.w	$0182
		dc.w	$0000,$6901,$ff00	; slot 6 (WAIT $69)
		dc.w	$0182
		dc.w	$0000,$6a01,$ff00	; slot 7 (WAIT $6a)
		dc.w	$0182
		dc.w	$0000,$6b01,$ff00	; slot 8 (WAIT $6b)
		dc.w	$0182
		dc.w	$0000,$6c01,$ff00	; slot 9 (WAIT $6c)
		dc.w	$0182
		dc.w	$0000,$6d01,$ff00	; slot 10 (WAIT $6d)
		dc.w	$0182
		dc.w	$0000,$6e01,$ff00	; slot 11 (WAIT $6e)
		dc.w	$0182
		dc.w	$0000,$6f01,$ff00	; slot 12 (WAIT $6f)
		dc.w	$0182
		dc.w	$0000,$7001,$ff00	; slot 13 (WAIT $70)
		dc.w	$0182
		dc.w	$0000,$7101,$ff00	; slot 14 (WAIT $71)
		dc.w	$0182
		dc.w	$0000,$7201,$ff00	; slot 15 (WAIT $72)
		dc.w	$0182
		dc.w	$0000,$7301,$ff00	; slot 16 (WAIT $73)
		dc.w	$0182
		dc.w	$0000,$7401,$ff00	; slot 17 (WAIT $74)
		dc.w	$0182
		dc.w	$0000,$7501,$ff00	; slot 18 (WAIT $75)
		dc.w	$0182
		dc.w	$0000,$7601,$ff00	; slot 19 (WAIT $76)
		dc.w	$0182
		dc.w	$0000,$7701,$ff00	; slot 20 (WAIT $77)
		dc.w	$0182
		dc.w	$0000,$7801,$ff00	; slot 21 (WAIT $78)
		dc.w	$0182
		dc.w	$0000,$7901,$ff00	; slot 22 (WAIT $79)
		dc.w	$0182
		dc.w	$0000,$7a01,$ff00	; slot 23 (WAIT $7a)
		dc.w	$0182
		dc.w	$0000,$7b01,$ff00	; slot 24 (WAIT $7b)
		dc.w	$0182
		dc.w	$0000,$7c01,$ff00	; slot 25 (WAIT $7c)
		dc.w	$0182
		dc.w	$0000,$7d01,$ff00	; slot 26 (WAIT $7d)
		dc.w	$0182
		dc.w	$0000,$7e01,$ff00	; slot 27 (WAIT $7e)
		dc.w	$0182
		dc.w	$0000,$7f01,$ff00	; slot 28 (WAIT $7f)
		dc.w	$0182
		dc.w	$0000,$8001,$ff00	; slot 29 (WAIT $80)
		dc.w	$0182
		dc.w	$0000,$8101,$ff00	; slot 30 (WAIT $81)
		dc.w	$0182
		dc.w	$0000,$8201,$ff00	; slot 31 (WAIT $82)
		dc.w	$0182
		dc.w	$0000,$8301,$ff00	; slot 32 (WAIT $83)
		dc.w	$0182
		dc.w	$0000,$8401,$ff00	; slot 33 (WAIT $84)
		dc.w	$0182
		dc.w	$0000,$8501,$ff00	; slot 34 (WAIT $85)
		dc.w	$0182
		dc.w	$0000,$8601,$ff00	; slot 35 (WAIT $86)
		dc.w	$0182
		dc.w	$0000,$8701,$ff00	; slot 36 (WAIT $87)
		dc.w	$0182
		dc.w	$0000,$8801,$ff00	; slot 37 (WAIT $88)
		dc.w	$0182
		dc.w	$0000,$8901,$ff00	; slot 38 (WAIT $89)
		dc.w	$0182
		dc.w	$0000,$8a01,$ff00	; slot 39 (WAIT $8a)
		dc.w	$0182
		dc.w	$0000,$8b01,$ff00	; slot 40 (WAIT $8b)
		dc.w	$0182
		dc.w	$0000,$8c01,$ff00	; slot 41 (WAIT $8c)
		dc.w	$0182
		dc.w	$0000,$8d01,$ff00	; slot 42 (WAIT $8d)
		dc.w	$0182
		dc.w	$0000,$8e01,$ff00	; slot 43 (WAIT $8e)
		dc.w	$0182
		dc.w	$0000,$8f01,$ff00	; slot 44 (WAIT $8f)
		dc.w	$0182
		dc.w	$0000,$9001,$ff00	; slot 45 (WAIT $90)
		dc.w	$0182
		dc.w	$0000,$9101,$ff00	; slot 46 (WAIT $91)
		dc.w	$0182
		dc.w	$0000,$9201,$ff00	; slot 47 (WAIT $92)
		dc.w	$0182
		dc.w	$0000,$9301,$ff00	; slot 48 (WAIT $93)
		dc.w	$0182
		dc.w	$0000,$9401,$ff00	; slot 49 (WAIT $94)
		dc.w	$0182
		dc.w	$0000,$9501,$ff00	; slot 50 (WAIT $95)
		dc.w	$0182
		dc.w	$0000,$9601,$ff00	; slot 51 (WAIT $96)
		dc.w	$0182
		dc.w	$0000,$9701,$ff00	; slot 52 (WAIT $97)
		dc.w	$0182
		dc.w	$0000,$9801,$ff00	; slot 53 (WAIT $98)
		dc.w	$0182
		dc.w	$0000,$9901,$ff00	; slot 54 (WAIT $99)
		dc.w	$0182
		dc.w	$0000,$9a01,$ff00	; slot 55 (WAIT $9a)
		dc.w	$0182
		dc.w	$0000,$9b01,$ff00	; slot 56 (WAIT $9b)
		dc.w	$0182
		dc.w	$0000,$9c01,$ff00	; slot 57 (WAIT $9c)
		dc.w	$0182
		dc.w	$0000,$9d01,$ff00	; slot 58 (WAIT $9d)
		dc.w	$0182
		dc.w	$0000,$9e01,$ff00	; slot 59 (WAIT $9e)
		dc.w	$0182
		dc.w	$0000,$9f01,$ff00	; slot 60 (WAIT $9f)
		dc.w	$0182
		dc.w	$0000,$a001,$ff00	; slot 61 (WAIT $a0)
		dc.w	$0182
		dc.w	$0000,$a101,$ff00	; slot 62 (WAIT $a1)
		dc.w	$0182
		dc.w	$0000,$a201,$ff00	; slot 63 (WAIT $a2)
		dc.w	$0182
		dc.w	$0000,$a301,$ff00	; slot 64 (WAIT $a3)
		dc.w	$0182
		dc.w	$0000,$a401,$ff00	; slot 65 (WAIT $a4)
		dc.w	$0182
		dc.w	$0000,$a501,$ff00	; slot 66 (WAIT $a5)
		dc.w	$0180,$0000		; COLOR00 = black
		dc.w	$ea01,$ff00		; WAIT line $ea
		dc.w	$0180,$0777		; COLOR00 = grey
		dc.w	$ec01,$ff00		; WAIT line $ec
		dc.w	$0180,$0333		; COLOR00 = dark grey

; --- 8 color slots: lower scroll bar (lines $ed-$f4) ---
		dc.w	$0182
CopBarBottom:
		dc.w	$0000,$ed01,$ff00	; slot 0 (WAIT $ed)
		dc.w	$0182
		dc.w	$0000,$ee01,$ff00	; slot 1 (WAIT $ee)
		dc.w	$0182
		dc.w	$0000,$ef01,$ff00	; slot 2 (WAIT $ef)
		dc.w	$0182
		dc.w	$0000,$f001,$ff00	; slot 3 (WAIT $f0)
		dc.w	$0182
		dc.w	$0000,$f101,$ff00	; slot 4 (WAIT $f1)
		dc.w	$0182
		dc.w	$0000,$f201,$ff00	; slot 5 (WAIT $f2)
		dc.w	$0182
		dc.w	$0000,$f301,$ff00	; slot 6 (WAIT $f3)
		dc.w	$0182
		dc.w	$0000,$f401,$ff00	; slot 7 (WAIT $f4)
		dc.w	$0180,$0777		; COLOR00 = grey
		dc.w	$f601,$ff00		; WAIT line $f6
		dc.w	$0180,$0000		; COLOR00 = black
		dc.w	$ffff,$fffe		; end of the copper list

; ============================================================================
; ColorTable: the rainbow gradient for the color strips ($ffff = end/restart)
; ============================================================================
ColorTable:
		dc.w	$02fb,$02fa,$02f9,$02f8,$02f7,$02f6,$02f5,$02f4
		dc.w	$02f3,$02f2,$03f2,$04f2,$05f2,$06f2,$07f2,$08f2
		dc.w	$09f2,$0af2,$0bf2,$0cf2,$0df2,$0ef2,$0ff2,$0fe2
		dc.w	$0fd2,$0fc2,$0fb2,$0fa2,$0f92,$0f82,$0f72,$0f62
		dc.w	$0f52,$0f42,$0f32,$0f22,$0f23,$0f24,$0f25,$0f26
		dc.w	$0f27,$0f28,$0f29,$0f2a,$0f2b,$0f2c,$0f2d,$0f2e
		dc.w	$0f2f,$0e2f,$0d2f,$0c2f,$0b2f,$0a2f,$092f,$082f
		dc.w	$072f,$062f,$052f,$042f,$032f,$022f,$023f,$024f
		dc.w	$025f,$026f,$027f,$028f,$029f,$02af,$02bf,$02cf
		dc.w	$02df,$02ef,$02ff
		dc.w	$ffff			; end marker

; ============================================================================
; Font: 8x8 charset as a 320-pixel-wide bitmap (40 bytes x 32 lines)
; ============================================================================
; 160 character codes (1..160), 40 characters per 8-pixel row; code 0 = end
Font:	incbin	"assets/font.bin"

		ds.b	720			; unused (zeros)

; ============================================================================
; Logo: "THE MOVERS PRESENT" bitmap (40 bytes x ~150 lines, 1 bitplane)
; ============================================================================
Logo:	incbin	"assets/logo.bin"

; ============================================================================
; Sample: digi sample (~53 KB, 8-bit signed, period $101)
; ============================================================================
; Looped endlessly on audio channels 0+1 (length $6881 words).
Sample:	incbin	"assets/sample.bin"

; ============================================================================
; BSS hunk (4 bytes; the original never actually uses it)
; ============================================================================
		section	bss,bss_c
		ds.l	1
