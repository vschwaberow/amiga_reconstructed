; ============================================================================
; TRSI-TrRobocod.s
; Trainermenu for Robocod
; Reconstructed by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================
CUSTOM          EQU     $dff000		; CUSTOM - Custom chips base
INTREQ          EQU     $09c            ; Interrupt request register offset
INTENA          EQU     $09a            ; Interrupt enable register offset
DMACON          EQU     $096            ; DMA control register offset
DMACONR         EQU     $002            ; DMA control read register offset
BLTCON0         EQU     $040            ; Blitter control 0 register offset
BLTCON1         EQU     $042            ; Blitter control 1 register offset
BLTAFWM         EQU     $044            ; Blitter A first word mask offset
BLTALWM         EQU     $046            ; Blitter A last word mask offset
BLTAPT          EQU     $050            ; Blitter A pointer offset
BLTBPT          EQU     $04c            ; Blitter B pointer offset
BLTDPT          EQU     $054            ; Blitter D pointer offset
BLTSIZE         EQU     $058            ; Blitter size register offset
BLTCMOD         EQU     $060            ; Blitter C modulo offset
BLTBMOD         EQU     $062            ; Blitter B modulo offset
BLTAMOD         EQU     $064            ; Blitter A modulo offset
BLTDMOD         EQU     $066            ; Blitter D modulo offset
COP1LCH         EQU     $080            ; Copper list 1 pointer high offset
COPJMP1         EQU     $088            ; Copper restart 1 register offset
SPR0DATA        EQU     $140            ; Sprite 0 data register offset
BLTADAT         EQU     $074            ; Blitter A data register offset
BLTBDAT         EQU     $072            ; Blitter B data register offset
VPOSR           EQU     $004            ; Vertical beam position read high offset
VHPOSR          EQU     $006            ; Vertical/horizontal beam position read offset
POTINP          EQU     $016            ; Potentiometer input register offset
COLOR00         EQU     $180            ; Background color register offset
COLOR03         EQU     $186            ; Palette color 3 register offset
COLOR08         EQU     $190            ; Palette color 8 register offset
COLOR11         EQU     $196            ; Palette color 11 register offset
COLOR17         EQU     $1a2            ; Sprite color 1 register offset
COLOR18         EQU     $1a4            ; Sprite color 2 register offset
COLOR19         EQU     $1a6            ; Sprite color 3 register offset
BPL1PTH         EQU     $0e0            ; Bitplane 1 pointer high offset
BPL1PTL         EQU     $0e2            ; Bitplane 1 pointer low offset
BPL2PTH         EQU     $0e4            ; Bitplane 2 pointer high offset
BPL2PTL         EQU     $0e6            ; Bitplane 2 pointer low offset
BPL3PTH         EQU     $0e8            ; Bitplane 3 pointer high offset
BPL3PTL         EQU     $0ea            ; Bitplane 3 pointer low offset
BPL4PTH         EQU     $0ec            ; Bitplane 4 pointer high offset
BPL4PTL         EQU     $0ee            ; Bitplane 4 pointer low offset
BPLCON0         EQU     $100            ; Bitplane control 0 register offset
BPLCON1         EQU     $102            ; Bitplane control 1 register offset
BPLCON2         EQU     $104            ; Bitplane control 2 register offset
BPL1MOD         EQU     $108            ; Bitplane 1 modulo offset
BPL2MOD         EQU     $10a            ; Bitplane 2 modulo offset
DIWSTRT         EQU     $08e            ; Display window start register offset
DIWSTOP         EQU     $090            ; Display window stop register offset
DDFSTRT         EQU     $092            ; Display data fetch start register offset
DDFSTOP         EQU     $094            ; Display data fetch stop register offset
CIAA_SDR        EQU     $bfec01         ; CIAA Serial Shift Register (Keyboard Data)
ExecBase        EQU     $00000004       ; ExecBase library pointer address

; ============================================================================
; Project-specific Equates
; ============================================================================
ScrollTextChar   EQU     Var_ScrollTextState
ScrollTextIndex  EQU     Var_ScrollTextState+1
CopperListPtr    EQU     Var_ActiveScreen
MusicPlayer_Init EQU     MusicData
MusicPlayer_Play EQU     MusicData+12
DecrunchDataPtr  EQU     Decruncher
Var_FontPtr      EQU     SpriteData_Const

	org	$30000

; ============================================================================
; Function: IntroStart
; Purpose : Initialization for the TRSI trainer intro.
; ============================================================================
        clr.l   ($0).l                  ; Clear zero page vector / interrupt table
        movea.l ExecBase.l,a6           ; Load Exec library base pointer (ExecBase)
        move.l  #$dc80,d1               ; Set counter to clear intro memory block ($DC80 bytes)
        lea     DecrunchDataPtr(pc),a0  ; Point to the compressed keyboard/installer block
        lea     ($c0).w,a1              ; Copy target zero-page offset at $C0
        move.w  #$e3,d2                 ; Loop counter to copy 228 bytes of the decruncher
ClearBssLoop:
        move.b  (a0)+,(a1)+             ; Copy decruncher byte by byte to $C0
        dbra    d2,ClearBssLoop         ; Loop until decruncher is copied
        lea     ($60000).l,a0           ; Work memory base address ($60000) for screen and playfield buffers
        move.l  a0,d0                   ; Copy base address for variable calculation
ClearIntroMemLoop:
        clr.b   (a0)+                   ; Clear current memory byte
        dbra    d1,ClearIntroMemLoop    ; Loop to clear the BSS area ($DC80 bytes)
        move.l  d0,Var_ScreenBase1.l    ; Set screen buffer 1 pointer to $60000
        move.l  d0,Var_MemoryTemp.l     ; Store screen pointer in temp variable
        addi.l  #$4000,Var_MemoryTemp.l ; Calculate next buffer offset ($64000)
        eor.l   d0,Var_MemoryTemp.l     ; Compute XOR flag to flip screen pointers
        addi.l  #$8000,d0               ; Advance pointer to $68000
        move.l  d0,Var_SpriteBase.l     ; Set sprite base address buffer to $68000
        addi.l  #$5050,d0               ; Advance pointer to $6D050
        move.l  d0,Var_ScrollerBase.l   ; Set scroller buffer base address to $6D050
        addi.l  #$3c0,d0                ; Advance pointer to $6D410
        move.l  d0,Var_CopperBase.l     ; Set copper list buffer base address to $6D410
        move.l  Var_ScreenBase1.l,Var_ActiveScreen.l ; Initialize Var_ActiveScreen to screen buffer 1
        bsr.w   BuildCopperList            ; Build the custom copper list for screen & gradient bars
        bsr.w   InitScreen                  ; Call subroutine InitScreen
        bsr.w   SetupCopperBitplanes        ; Setup odd and even bitplane pointers in the copper list
        bsr.w   EnableInterrupts                  ; Call subroutine EnableInterrupts
        bsr.w   MusicPlayer_Init            ; Initialize the Paula music tracker player
        nop                             ; NOP instruction
; ============================================================================
; Function: WaitRaster
; Purpose : Wait for a specific raster line to sync the intro loop.
; ============================================================================
WaitVBlank:
        move.b  (CUSTOM+VPOSR+1).l,d0   ; Read VPOSR low byte (containing vertical beam pos bit 8)
        andi.b  #$1,d0                  ; Mask out all but vertical beam bit 8
        lsl.w   #$8,d0                  ; Shift vertical beam bit 8 to bit 8 of the word
        move.b  (CUSTOM+VHPOSR).l,d0    ; Read VHPOSR high byte (containing vertical beam pos bits 7-0)
        cmpi.w  #$10a,d0                ; Compare vertical position to target line 266 ($10A, vblank area)
        bne.s   WaitVBlank              ; Keep waiting until beam reaches line 266
        btst.b  #$a,(CUSTOM+POTINP).l   ; Test Right Mouse Button (RMB) state (bit 10 of POTINP / bit 2 of POTINP high byte)
        beq.w   ExitIntro               ; Branch to exit intro if RMB is pressed
        bsr.w   UpdateScrollerDelay         ; Update scroller delay timer / pause checks
        move.l  CopperListPtr(pc),d0    ; Load current copper list base pointer
        bsr.w   UpdateScreen1                  ; Call subroutine UpdateScreen1
        move.l  CopperListPtr(pc),d0    ; Load current copper list base pointer
        movea.l Var_CopperBase.l,a0     ; Load copper list buffer base address
        addq.w  #$8,a0                  ; Advance to first screen pointer slot in copper list
        move.w  #$ec,d2                 ; Set line count offset for screen update
        addi.l  #$40,d0                 ; Offset copper pointer to secondary screen slot
        bsr.w   UpdateScreen2                  ; Call subroutine UpdateScreen2
        move.l  Var_MemoryTemp.l,d0     ; Load double-buffering temp memory flag
        eor.l   d0,Var_ActiveScreen.l           ; Update pointer/flag
        bsr.w   UpdateScroller                  ; Call subroutine UpdateScroller
        bsr.w   AnimateCopperFonts         ; Animate the copper text font color effects
        bsr.w   MusicPlayer_Play            ; Play the next frame of the Paula music module
        bra.s   WaitVBlank                  ; Jump to WaitVBlank
Var_MemoryTemp:
        dc.l    0                       ; XOR mask toggle for double-buffering screen pointer ($60000 ^ $64000)
; ============================================================================
; Function: SpriteUpdateLoop
; Purpose : Updates the horizontal positions and graphics pointers for the
;           active hardware sprites (representing the bouncing metallic rings).
; ============================================================================
SpriteUpdateLoop:
        movea.l Var_SpriteBase.l,a2     ; Load sprite buffer base address
        lea     (a2,d1.w),a2            ; Offset to current sprite slot in copper
        tst.b   (a3)                    ; Check if we reached end of sprite config (null byte)
        beq.s   ExitSpriteUpdate        ; Exit loop if end of sprite configuration
        move.b  (a3)+,d0                ; Read next sprite horizontal offset coordinate
        bsr.w   GetSpritePtr                  ; Call subroutine GetSpritePtr
        lsl.w   #$1,d0                  ; Multiply by 2 for word offset
        lea     SpriteList(pc),a0       ; Point to SpriteList (font glyphs for sprites)
        lea     (a0,d0.w),a0            ; Get pointer to sprite graphics
        move.l  a0,BLTAPT(a5)           ; BLTAPT (Blitter A pointer)
        move.l  a2,BLTDPT(a5)           ; BLTDPT (Blitter D pointer)
        addq.w  #$2,d1                  ; Step coordinate offset pointer
        move.l  #$9f00000,BLTCON0(a5)   ; BLTCON0 (Blitter control 0)
        move.w  #$401,BLTSIZE(a5)       ; BLTSIZE (Blitter start and size)
        bsr.w   SetSpritePos                  ; Call subroutine SetSpritePos
        adda.w  #$2828,a2               ; Move to the second hardware sprite slot in copper
        move.l  a0,BLTAPT(a5)           ; BLTAPT (Blitter A pointer)
        move.l  a2,BLTDPT(a5)           ; BLTDPT (Blitter D pointer)
        move.l  #$19f00000,BLTCON0(a5)  ; BLTCON0 (Blitter control 0)
        move.w  #$401,BLTSIZE(a5)       ; BLTSIZE (Blitter start and size)
        bsr.w   SetSpritePos                  ; Call subroutine SetSpritePos
        bra.s   SpriteUpdateLoop                  ; Jump to SpriteUpdateLoop
ExitSpriteUpdate:
        rts                             ; Return from subroutine
SpriteData_Const:
        dc.l    FontData                ; Pointer to base FontData ($30D22)
; ============================================================================
; Function: AnimateCopperFonts
; Purpose : Updates character color patterns directly in the copper list to create
;           the animated waving text color effect on screen.
; Notes   : This was previously named DecrunchAndInit in disassembler output.
; ============================================================================
AnimateCopperFonts:
        lea     SpriteData_Const(pc),a3   ; Point to font/sprite offset pointer table
        lea     TextData(pc),a4           ; Point to mapped text data structure
        movea.l (a3),a3                 ; Load base graphics pointer
        movea.l Var_CopperBase.l,a2     ; Load copper list buffer address
        lea     $6a(a2),a2              ; Offset to first text line color pointer in copper
        movea.l a3,a0                   ; Copy base graphics pointer to a0
        move.w  #$a4,d4                 ; Offset stride / line height for characters
        moveq   #$8,d3                  ; Number of characters to process in loop 1
        bsr.s   InitLoop1               ; Initialize first set of characters
        movea.l Var_CopperBase.l,a2     ; Load copper list buffer address
        lea     $2d5e(a2),a2            ; Offset to secondary text line color pointer
        lea     $44(a3),a0              ; Offset pointer for second group of characters
        bsr.w   RelocateCheck           ; Relocate graphics pointers if necessary
        move.w  #$ff5c,d4               ; Negative offset stride for secondary characters
        move.w  #$fff8,d3               ; Loop counter modifier
        move.w  #$13,d1                 ; Number of characters to process in loop 2
        bsr.s   InitLoop1               ; Initialize second set of characters
        movea.l Var_CopperBase.l,a2     ; Load copper list buffer address
        lea     $abe(a2),a2             ; Offset to third text line color pointer
        lea     $28(a3),a0              ; Offset pointer for third group of characters
        bsr.w   RelocateCheck           ; Relocate graphics pointers
        move.w  #$1c,d4                 ; Offset stride for third group
        bsr.s   InitLoop2               ; Initialize third set of characters
        movea.l Var_CopperBase.l,a2     ; Load copper list buffer address
        lea     $2312(a2),a2            ; Offset to fourth text line color pointer
        lea     $6c(a3),a0              ; Offset pointer for fourth group of characters
        bsr.w   RelocateCheck           ; Relocate graphics pointers
        move.w  #$ffe4,d4               ; Negative offset stride for fourth group
        bsr.s   InitLoop2               ; Initialize fourth set of characters
        addq.w  #$2,a3                  ; Step to next font data record
        tst.w   (a3)                    ; Test if end of font data reached
        bpl.s   .no_font_reset                  ; If positive, continue
        lea     FontData(pc),a3         ; Reset to base FontData address
.no_font_reset:
        move.l  a3,Var_FontPtr.l        ; Store updated font data pointer
        rts                             ; Return

; ============================================================================
; Function: InitLoop1
; Purpose : Copies character bitmaps to copper locations with vertical step.
; ============================================================================
InitLoop1:
        move.w  #$13,d1                 ; Loop counter for 20 characters
        moveq   #$0,d2                  ; Clear offset index
InitLoop1_Inner:
        tst.w   (a0)                    ; Check if character pointer is valid
        bpl.s   InitLoop1_Skip          ; If positive, skip fallback
        lea     FontData(pc),a0         ; Fallback to default FontData address
InitLoop1_Skip:
        move.w  (a0)+,d0                ; Read character bitmap word
        move.w  #$f,d5                  ; Loop counter for 16 pixel rows
InitLoop1_Copy:
        move.w  d0,(a2,d2.w)            ; Write character word to copper color register
        add.w   d4,d2                   ; Apply horizontal line stride offset
        dbra    d5,InitLoop1_Copy       ; Copy all 16 rows of the character
        moveq   #$0,d2                  ; Reset offset index
        adda.w  d3,a2                   ; Step to next copper character slot
        dbra    d1,InitLoop1_Inner      ; Continue character loop
        rts                             ; Return

; ============================================================================
; Function: InitLoop2
; Purpose : Copies character bitmaps directly to copper locations.
; ============================================================================
InitLoop2:
        move.w  #$d,d2                  ; Loop counter for 14 characters
InitLoop2_Inner:
        tst.w   (a0)                    ; Check if character pointer is valid
        bpl.s   InitLoop2_Skip          ; If positive, skip fallback
        lea     FontData(pc),a0         ; Fallback to default FontData address
InitLoop2_Skip:
        move.w  (a0)+,d0                ; Read character bitmap word
        move.w  #$f,d3                  ; Loop counter for 16 pixel rows
InitLoop2_Copy:
        move.w  d0,(a2)                 ; Write character word to copper color register
        adda.w  d4,a2                   ; Step copper destination pointer by stride
        dbra    d3,InitLoop2_Copy       ; Copy all 16 rows of the character
        dbra    d2,InitLoop2_Inner      ; Continue character loop
        rts                             ; Return

; ============================================================================
; Function: RelocateCheck
; Purpose : Adjusts character pointer relative to FontData base.
; ============================================================================
RelocateCheck:
        cmpa.l  a4,a0                   ; Check if pointer exceeds TextData boundaries
        bcs.s   RelocateSkip            ; If below, skip relocation adjustment
        suba.l  a4,a0                   ; Calculate offset from TextData base
        lea     FontData(pc),a1         ; Load base FontData address
        adda.l  a1,a0                   ; Add FontData base to resolve pointer
RelocateSkip:
        rts                             ; Return
; ============================================================================
; Function: SetupCopperBitplanes
; Purpose : Sets up initial bitplane pointers (planes 1-4) in the copper list
;           and initializes default blitter size, modulo, and masks.
; ============================================================================
SetupCopperBitplanes:
        move.l  Var_SpriteBase.l,d0     ; Load sprite buffer base pointer
        movea.l Var_CopperBase.l,a0     ; Load copper list buffer address
        adda.w  #$10,a0                 ; Offset to sprite pointer slots in copper
        move.w  #$e0,d2                 ; Height / line count parameter
        bsr.w   UpdateScreen2           ; Write sprite buffer pointer to copper list
        move.l  Var_SpriteBase.l,d0     ; Load sprite buffer base pointer
        addi.l  #$2800,d0               ; Offset to secondary sprite graphics layer
        movea.l Var_CopperBase.l,a0     ; Load copper list buffer address
        adda.w  #$18,a0                 ; Offset to secondary sprite slots in copper
        move.w  #$e8,d2                 ; Height / line count parameter
        bsr.w   UpdateScreen2           ; Write secondary sprite pointer to copper list
        move.w  #$401,Var_CopperBlitSize.l          ; Set default blitter size/control values in copper
        move.w  #$76,Var_CopperBlitMod.l           ; Set default blitter modulo values in copper
        move.w  #$26,Var_CopperBlitShift.l           ; Set default blitter shift parameters in copper
        move.l  #$ffffffff,Var_CopperBlitMask.l     ; Set blitter first/last word masks in copper
        move.l  #$9f00000,Var_CopperBlitCon0.l      ; Set blitter control word (BLTCON0/1) copy mode
        movea.l Var_SpriteBase.l,a2     ; Load sprite buffer base pointer
        lea     MenuText,a3             ; Point to the stationary MenuText data
        moveq   #$f,d1                  ; Loop counter for 16 blitter setup passes
CopperLoop1:
        moveq   #$13,d2                 ; Loop counter for 20 words per pass
CopperLoop1_Inner:
        move.b  (a3)+,d0                ; Read setup parameter byte
        bsr.w   GetCopperAddr           ; Calculate copper register address
        addq.w  #$2,a2                  ; Step sprite buffer pointer
        dbra    d2,CopperLoop1_Inner    ; Continue inner loop
        adda.w  #$258,a2                ; Apply vertical spacing stride to sprite pointer
        dbra    d1,CopperLoop1          ; Continue blitter setup loop
        move.l  #$0,Var_CopperBlitMod.l            ; Clear blitter modulo register values in copper
        move.w  #$3fd4,Var_CopperBlitSize.l         ; Set modified blitter size parameter in copper
        move.l  Var_SpriteBase.l,Var_CopperSprite1.l ; Write sprite pointer 1 to copper list setup
        move.l  Var_SpriteBase.l,Var_CopperSprite2.l ; Write sprite pointer 2 to copper list setup
        addi.l  #$2828,Var_CopperSprite2.l         ; Add offset for secondary sprite layer pointer
        move.b  #$19,Var_CopperBlitCon0.l           ; Set blitter control parameter in copper
        bra.w   StartCopperList         ; Start the copper list execution
        rts                             ; Return
UpdateScroller:
        moveq   #$0,d0                  ; Clear d0
        move.b  ScrollTextIndex(pc),d0  ; Read current scroller character index
        lsl.w   #$2,d0                  ; Multiply by 4 for longword pointer table offset
        lea     ScrollTextPtrs(pc),a0   ; Point to scroller text pointer table
        lea     (a0,d0.w),a0            ; Calculate address of character pointer
        move.l  (a0),ScrollTextBase.l           ; Store current character pointer in ScrollTextBase
        movea.l ScrollTextBase(pc),a0   ; Load current character pointer to a0
        move.w  -(a0),ScrollTextWidth.l          ; Read character width and store in ScrollTextWidth
        move.l  ScrollTextBase(pc),ScrollTextStart.l ; Update base scroller text pointer in ScrollTextStart
        bsr.w   BlitterClearScreen      ; Clear the scroller screen area using the blitter
        moveq   #$0,d0                  ; Clear d0
        move.w  #$8f,d1                 ; Loop counter for 144 columns (screen width scroll)
        lea     CUSTOM,a5               ; Point a5 to the Amiga Custom Chip base
        move.w  #$24,BLTAMOD(a5)        ; Set Blitter A Modulo to 36 bytes
        move.w  #$3e,BLTBMOD(a5)        ; Set Blitter B Modulo to 62 bytes
        move.w  #$3e,BLTDMOD(a5)        ; Set Blitter D Modulo to 62 bytes
        move.l  #$dfc0000,BLTCON0(a5)   ; Set blitter control (BLTCON0/1) for shift/copy mode
        move.w  #$401,d6                ; Set blitter size (64x1 pixels) in d6
        move.w  #$ffff,BLTALWM(a5)      ; Set blitter last word mask (BLTALWM) to all ones
        move.w  #$c000,d5               ; Set initial bitmask in d5
        movea.l Var_ScrollerBase.l,a4   ; Point to scroller playfield buffer base
        movea.l CopperListPtr(pc),a3    ; Load active copper list pointer
        suba.w  #$3be,a3                ; Offset to scroll plane pointer in copper
        movea.l ScrollTextStart.l,a1             ; Load current scroll character data pointer
ScrollerLoop:
        moveq   #$0,d2                  ; Clear d2
        move.b  (a1)+,d2                ; Read next character scan byte
        lsl.w   #$6,d2                  ; Multiply by 64 for font glyph offset
        add.l   a3,d2                   ; Add copper scroll plane pointer base
        move.w  d5,BLTAFWM(a5)          ; Set blitter first word mask (BLTAFWM)
        move.l  a4,BLTAPT(a5)           ; Set blitter source A pointer (playfield data)
        move.l  d2,BLTBPT(a5)           ; Set blitter source B pointer (font glyph data)
        move.l  d2,BLTDPT(a5)           ; Set blitter destination D pointer (scroll plane in copper)
        move.w  d6,BLTSIZE(a5)          ; Start the blit operation (size 64x1)
        ror.w   #$2,d5                  ; Rotate scroll mask by 2 bits
        bcc.s   BlitterWait             ; If carry clear, continue without pointer step
        addq.w  #$2,a4                  ; Step playfield buffer pointer by 2 bytes
        addq.w  #$2,a3                  ; Step copper plane pointer by 2 bytes
BlitterWait:
        btst    #14,DMACONR(a5)         ; Check if the blitter is still busy (bit 14 of DMACONR)
        bne.s   BlitterWait             ; Wait until the blit completes
        dbra    d1,ScrollerLoop         ; Continue loop for all 144 columns
        tst.w   Var_ScrollerDelay.l     ; Test scroller delay timer
        beq.w   ScrollText              ; If timer is 0, fetch next character / scroll
        subq.w  #$1,Var_ScrollerDelay.l ; Decrement scroller delay timer
        rts                             ; Return

ScrollText:
        movea.l ScrollTextStart(pc),a0  ; Load current scroll text pointer
        movea.l a0,a2                   ; Copy to a2
        movea.l a2,a1                   ; Copy to a1
        move.w  -(a2),d0                ; Read character width/count
        moveq   #$0,d2                  ; Clear d2
        move.b  ScrollTextChar(pc),d2   ; Read current horizontal scroll offset
        sub.w   d2,d0                   ; Calculate remaining characters to copy
        subq.w  #$1,d2                  ; Adjust count for dbra loop
        lea     ScrollTempBuffer.l,a3             ; Point to temp scroll text buffer ScrollTempBuffer
ScrollText_Copy1:
        move.b  (a1)+,(a3)+             ; Copy leading characters to temp buffer
        dbra    d2,ScrollText_Copy1     ; Loop until done
ScrollText_Copy2:
        move.b  (a1)+,(a0)+             ; Shift text bytes left in buffer
        dbra    d0,ScrollText_Copy2     ; Loop until text shifted
        moveq   #$0,d2                  ; Clear d2
        move.b  ScrollTextChar(pc),d2   ; Read horizontal scroll offset again
        subq.w  #$1,d2                  ; Adjust count for dbra
        lea     ScrollTempBuffer.l,a3             ; Point to temp scroll text buffer ScrollTempBuffer
ScrollText_Copy3:
        move.b  (a3)+,(a0)+             ; Append the wrapped characters at the end
        dbra    d2,ScrollText_Copy3     ; Loop until wrapping complete
        rts                             ; Return
; --- Data Block 03e6 - 040c ---
ScrollTempBuffer:
		dc.w	$0000                            ; Temporary scroll buffer word 0
		dc.w	$0000                            ; Temporary scroll buffer word 1
		dc.w	$0000                            ; Temporary scroll buffer word 2
		dc.w	$0000                            ; Temporary scroll buffer word 3
		dc.w	$0000                            ; Temporary scroll buffer word 4
		dc.w	$0000                            ; Temporary scroll buffer word 5
		dc.w	$0000                            ; Temporary scroll buffer word 6
		dc.w	$0000                            ; Temporary scroll buffer word 7
		dc.w	$0000                            ; Temporary scroll buffer word 8
		dc.w	$0000                            ; Temporary scroll buffer word 9
Var_ScrollTextState:
		dc.w	$0500                            ; ScrollTextChar (low byte) / ScrollTextIndex (high byte)
Var_ScrollerDelay:
		dc.w	$0000                            ; Temporary scroll buffer word 11
ScrollTextPtrs:
		dc.l	SineTable+2                      ; Pointer to the active scroll sine table values
ScrollTextStart:
		dc.l	SineTable+2                      ; Active pointer to current position in sine table
ScrollTextBase:
		dc.l	0                                ; ScrollTextBase - Active character font graphics pointer
ScrollTextWidth:
		dc.w	0                                ; Character width in pixels

; ============================================================================
; Data: SineTable
; Purpose : Sine wave vertical offset values for the bouncing scroll text.
; Values  : Range from $50 (lowest) to $C0 (highest) with $88 as center.
;           First word ($0166 = 358) represents the table length in bytes.
;           Last byte ($FF) marks the end of the table.
; ============================================================================
SineTable:
		dc.w	$0166                            ; Length of the sine table (358 bytes)
		dc.w	$8889,$8a8b,$8c8d,$8e8f,$9091,$9293,$9495
		dc.w	$9696,$9798,$999a,$9b9c,$9d9e,$9fa0,$a1a1,$a2a3
		dc.w	$a4a5,$a6a6,$a7a8,$a9aa,$aaab,$acad,$adae,$afb0
		dc.w	$b0b1,$b2b2,$b3b4,$b4b5,$b5b6,$b6b7,$b7b8,$b8b9
		dc.w	$b9ba,$babb,$bbbc,$bcbc,$bdbd,$bdbe,$bebe,$bebf
		dc.w	$bfbf,$bfbf,$bfc0,$c0c0,$c0c0,$c0c0,$c0c0,$c0c0
		dc.w	$c0c0,$c0c0,$bfbf,$bfbf,$bfbf,$bebe,$bebe,$bdbd
		dc.w	$bdbc,$bcbc,$bbbb,$baba,$b9b9,$b8b8,$b7b7,$b6b6
		dc.w	$b5b5,$b4b4,$b3b2,$b2b1,$b0b0,$afae,$adad,$acab
		dc.w	$aaaa,$a9a8,$a7a6,$a6a5,$a4a3,$a2a1,$a1a0,$9f9e
		dc.w	$9d9c,$9b9a,$9998,$9796,$9695,$9493,$9291,$908f
		dc.w	$8e8d,$8c8b,$8a89,$8887,$8685,$8483,$8281,$807f
		dc.w	$7e7d,$7c7b,$7a7a,$7978,$7776,$7574,$7372,$7170
		dc.w	$6f6f,$6e6d,$6c6a,$6968,$6766,$6665,$6463,$6362
		dc.w	$6160,$605f,$5e5e,$5d5c,$5c5b,$5b5a,$5a59,$5958
		dc.w	$5857,$5756
		dc.w	$5655,$5554,$5454,$5353,$5352,$5252,$5251,$5151
		dc.w	$5151,$5150,$5050,$5050,$5050,$5050,$5050,$5050
		dc.w	$5050,$5151,$5151,$5151,$5252,$5252,$5353,$5354
		dc.w	$5454,$5555,$5656,$5757,$5858,$5959,$5a5a,$5b5b
		dc.w	$5c5c,$5d5e,$5e5f,$6060,$6162,$6363,$6465,$6666
		dc.w	$6768,$6969,$6a6b,$6c6d,$6e6f,$6f70,$7172,$7374
		dc.w	$7576,$7778,$797a,$7a7b,$7c7d,$7e7f,$8081,$8283
		dc.w	$8485,$8687,$88ff
; --- Code Block 0576 - 0642 ---
BlitterClearScreen:
		movea.l	CopperListPtr(pc),a0          ; Load copperlist pointer
		addq.w	#$2,a0                         ; Advance copper list pointer to next entry
		move.l	a0,Var_CopperSprite2                      ; Set active copper list address as blitter destination
		move.w	#$1c,d0                        ; Set blitter size (28 words)
		move.w	d0,Var_CopperBlitShift                      ; Store in blitter vertical size parameter
		move.w	d0,Var_CopperBlitMod                      ; Store in blitter horizontal size parameter
		move.l	#$ffffffff,Var_CopperBlitMask              ; Set blitter first/last word mask parameters
		move.w	#$4012,Var_CopperBlitSize                  ; Set blitter control register size
		clr.w	Var_CopperBlitCon1                          ; Clear blitter control register 1
		move.w	#$1f0,Var_CopperBlitCon0                   ; Set blitter control register 0 copy mode
		clr.w	CUSTOM+BLTBDAT                  ; Clear BLTCON1 (Blitter control 1)
		clr.w	CUSTOM+BLTADAT                  ; Clear BLTCON0 (Blitter control 0)
		bra.w	StartCopperList                 ; Jump to start copper list execution
UpdateScrollerDelay:
		tst.w	Var_ScrollWaitTimer                          ; Check scroller delay timer
		beq.b	UpdateScroller_ReadChar         ; Read next character if delay timer is 0
		subq.w	#$1,Var_ScrollWaitTimer                     ; Decrement scroller delay timer
		rts                                   ; Return
UpdateScroller_ReadChar:
		movea.l	Var_ScrollTextPtr,a0                     ; Read character pointer from scroller buffer
		tst.b	(a0)                            ; Test if byte is null (end of scroll text)
		bne.b	.no_reset                          ; If not null, continue processing
		lea.l	ScrollTextData,a0               ; Reset scroller text pointer to start of text
.no_reset:
		move.b	(a0)+,d0                       ; Read character byte from scroller text
		cmpi.b	#$f,d0                         ; Check if character is a delay/command byte (value <= 15)
		bhi.b	UpdateScroller_DrawChar                          ; If normal character, branch to scroller draw
		andi.w	#$ff,d0                        ; Mask byte to word index
		lsl.w	#$4,d0                          ; Shift offset left to calculate delay
		move.w	d0,Var_ScrollWaitTimer                      ; Store delay value
		move.l	a0,Var_ScrollTextPtr                      ; Save current scroller text position
		rts                                   ; Return
UpdateScroller_DrawChar:
		cmpi.b	#$10,d0                        ; Check for control command 0x10
		bne.b	UpdateScroller_DoScroll                          ; Branch if not command 0x10
		movea.l	Var_CopperBase,a4             ; Load copper list buffer address
		eori.w	#$40,$3e(a4)                   ; Toggle scroller playfield scroll offset flag
		move.l	a0,Var_ScrollTextPtr                      ; Save current scroller text position
		bra.b	UpdateScroller_ReadChar         ; Loop back to read next character
UpdateScroller_DoScroll:
		bsr.w	ScrollPlayfieldLeft             ; Shift scroller playfield left by 2 pixels
		tst.b	Var_ScrollSubPixel                          ; Test shift step counter
		beq.b	InitScroller                    ; If 0, branch to initialize scroller
		subi.b	#$1,Var_ScrollSubPixel                     ; Decrement shift step counter
		rts                                   ; Return
InitScroller:
		move.b	#$7,Var_ScrollSubPixel                     ; Set shift step counter to 7
		move.l	a0,Var_ScrollTextPtr                      ; Save current scroller text position
		bsr.w	BlitNewCharToScroller           ; Render next text character to the edge of the buffer
		rts                                   ; Return
; --- Data Block 0642 - 064a ---
Var_ScrollWaitTimer:
		dc.w	$0000                            ; Scroller delay timer
Var_ScrollSubPixel:
		dc.w	$0000                            ; Scroller sub-pixel step shift counter
Var_ScrollTextPtr:
		dc.w	$0000                            ; ScrollTextData current read pointer
		dc.w	$0000                            ; Scroller delay and state parameters 3
ScrollTextData:
; --- Text Block 064a - 0a66 ---
		dc.b	".........trip and dip slip the hip now grip 2 the techno house o"
		dc.b	"f hip oohhhh yeaaaaaaahhhhhhhh !!!!                  ",$10,"members of"
		dc.b	" trsi surprise! production r: adec, bishop, corwin, jhl, j.o.e.,"
		dc.b	" luke, reebok, spike, spock and myself .... and now        the g"
		dc.b	"reetinx    ",$08,$10,"special greetinx 2:      iratex       ",$10,$08,$10,"      *atr"
		dc.b	"on       ",$10,$08,$10,"      *liroy       ",$10,$08,"greetinx 2:  arics, scoopex (ch"
		dc.b	"arly), robotech, subway, jacko, shark, vision factory, nitrobit,"
		dc.b	" paradox, angeles, shining 2, micron & maverick, alpha flight, f"
		dc.b	"resh, skid row, the dodgers, tetragon, fairlight, defjam, trilog"
		dc.b	"y, abakus, thrust and all we konw 2 !!!!  look out for a trainer"
		dc.b	" by trion. our newest trainer 'ill come very soooon !!   bye !! "
		dc.b	"                          ",$10,$00
MenuText:
		dc.b	"*********************               "
		dc.b	"   ** james pond ii ++ **                  **  trsi surprise!  *"
		dc.b	"* trainer by trion **                  ** use f keys on/ff **   "
		dc.b	"               ** f1 credits (red) ** f2 lives (green) ** f3 ene"
		dc.b	"rgy (blue) **                  ** withe: train off **           "
		dc.b	"       *********************"
; --- Code Block 0a66 - 0ce6 ---
; ============================================================================
; Function: ScrollPlayfieldLeft
; Purpose : Scrolls the playfield display buffer left by 2 pixels using the blitter
;           shifter function (updates pointers in the copper list).
; Notes   : This was previously named MainLoop in disassembler output.
; ============================================================================
ScrollPlayfieldLeft:
		move.l	Var_ScrollerBase,Var_CopperSprite1        ; Load scroller playfield base pointer
		addi.l	#$260,Var_CopperSprite1                   ; Add row offset displacement ($260 bytes)
		move.l	Var_CopperSprite1,Var_CopperSprite2                  ; Set scroller active copper address
		move.l	#$0,Var_CopperBlitMod                     ; Set blitter modulo values to 0
		move.l	#$3fffffff,Var_CopperBlitMask              ; Set blitter masks to all ones
		move.l	#$29f00002,Var_CopperBlitCon0              ; Set blitter control values for copy/shift
		move.w	#$413,Var_CopperBlitSize                   ; Set blitter vertical/horizontal size
		bra.w	StartCopperList                 ; Run blitter copper list setup
; ============================================================================
; Function: BlitNewCharToScroller
; Purpose : Blits the font glyph data for a new character onto the right edge of
;           the scroller playfield display buffer.
; Notes   : This was previously named UpdateScrollerBlitter in disassembler output.
; ============================================================================
BlitNewCharToScroller:
		move.w	#$401,Var_CopperBlitSize                   ; Set blitter size (64x1 words)
		move.w	#$76,Var_CopperBlitMod                    ; Set blitter source modulo (118 bytes)
		move.w	#$24,Var_CopperBlitShift                    ; Set blitter shift parameters
		move.l	#$ffffffff,Var_CopperBlitMask              ; Set blitter first/last word masks
		move.l	#$9f00000,Var_CopperBlitCon0               ; Set blitter control register copy mode
		movea.l	Var_ScrollerBase,a2           ; Load scroller playfield base pointer
		adda.w	#$24,a2                        ; Add modulo offset to base pointer
GetCopperAddr:
		move.l	a2,Var_CopperSprite2                      ; Write pointer to copper list variable
		bsr.b	GetSpritePtr                    ; Look up current character pointer index
		lsl.l	#$1,d0                          ; Multiply sprite index by 2 for word offset
		move.l	#SpriteList,Var_CopperSprite1             ; Load SpriteList base address
		add.l	d0,Var_CopperSprite1                       ; Calculate offset pointer to sprite graphics
		bra.w	StartCopperList                 ; Jump to start copper list execution
GetSpritePtr:
		lea.l	MappedCharacterTable(pc),a0                   ; Point to mapped characterset index table
		movea.l	a0,a1                         ; Keep track of the table start pointer
.loop:
		tst.b	(a0)                            ; Test if current table entry is null (end mark)
		beq.b	.exit                          ; Exit loop if end of table reached
		cmp.b	(a0),d0                         ; Compare current table entry with target character
		beq.b	.exit                          ; If matched, exit loop
		addq.w	#$1,a0                         ; Step to next character entry in table
		bra.b	.loop                          ; Loop back to scan next character
.exit:
		suba.l	a1,a0                          ; Subtract start pointer to get character index offset
		move.l	a0,d0                          ; Store result in d0
		rts                                   ; Return
InitScreen:
		move.l	Var_ScreenBase1,d0             ; Load screen buffer base pointer
UpdateScreen1:
		movea.l	Var_CopperBase,a0             ; Load copper list buffer address
		move.w	#$e4,d2                        ; Set copper target register offset for first pointer
UpdateScreen2:
		move.w	#$0,d1                         ; Loop counter for screen updates
		move.l	#$2800,d3                      ; Offset stride between bitplanes ($2800 bytes)
.loop:
		swap	d0                               ; Swap register halves to get high word
		move.w	d2,(a0)+                       ; Write copper destination register offset (e.g. BPLxPTH)
		move.w	d0,(a0)+                       ; Write high word of screen pointer
		addq.w	#$2,d2                         ; Advance copper offset register pointer
		swap	d0                               ; Swap register halves back to get low word
		move.w	d2,(a0)+                       ; Write copper destination register offset (e.g. BPLxPTL)
		move.w	d0,(a0)+                       ; Write low word of screen pointer
		addq.w	#$2,d2                         ; Advance copper offset register pointer
		add.l	d3,d0                           ; Step pointer to next bitplane buffer ($2800 offset)
		dbra	d1,.loop                        ; Loop to write next bitplane pointer
		rts                                   ; Return
EnableInterrupts:
		bsr.b	EnableInterrupts_Core                          ; Enable custom interrupts and copper
		rts                                   ; Return
ExitIntro:
		bsr.w	MusicPlayer_Init                ; Initialize music player to turn off sound
		bsr.w	ExitIntro_Core                          ; Restore system interrupts and copper state
		rts                                   ; Return
Var_ScreenBase1:
		dc.l	0                               ; Base address of screen buffer 1 (allocated at $60000)
Var_SpriteBase:
		dc.l	0                               ; Base address of sprite graphics buffer (allocated at $68000)
Var_ScrollerBase:
		dc.l	0                               ; Base address of playfield scroller buffer (allocated at $6D050)
Var_CopperBase:
		dc.l	0                               ; Base address of custom copper list buffer (allocated at $6D410)
EnableInterrupts_Core:
		move.w	#$4000,CUSTOM+INTENA           ; Clear INTENA (disable system interrupts)
		move.w	#$87f0,CUSTOM+DMACON           ; Configure DMACON (enable Copper, Sprite, Blitter, and Bitplane DMA)
		move.w	#$20,CUSTOM+DMACON             ; Disable audio DMA
		clr.w	CUSTOM+SPR0DATA                 ; Clear sprite display registers
		move.l	Var_CopperBase,CUSTOM+COP1LCH  ; Set COP1LCH to point to custom copper list
		clr.w	CUSTOM+COPJMP1                  ; Write to COPJMP1 to restart copper list execution
		rts                                   ; Return
; ============================================================================
; Function: BuildCopperList
; Purpose : Copies the base copper list template and dynamically appends the
;           raster wait-lines and color registers for background & gradient bars.
; Notes   : This was previously named InitMusic in disassembler output.
; ============================================================================
BuildCopperList:
		lea.l	CopperListTemplate(pc),a0                   ; Load address of template copper list
		movea.l	Var_CopperBase,a1             ; Load destination copper list buffer address
		move.w	#$18,d0                        ; Loop counter to copy 25 longwords (100 bytes)
.copy_loop:
		move.l	(a0)+,(a1)+                    ; Copy one longword from template to buffer
		dbra	d0,.copy_loop                        ; Loop until template copper list copied
		move.l	a1,Var_CopperWritePtr                      ; Store current copper buffer write pointer in Var_CopperWritePtr
		movea.l	Var_CopperWritePtr(pc),a2                 ; Load copper list buffer pointer to a2
		move.w	#$f,d0                         ; Loop counter for first block of copper wait lines
		move.w	#$2c3f,d1                      ; Set start vertical raster line position and mask
		move.w	#$444,d4                       ; Initial background color value
		bsr.b	BuildCopperList_Lines                          ; Call routine to generate copper lines
		move.b	#$3b,d1                        ; Set start vertical raster line for second block
		move.w	#$df,d0                        ; Loop counter for second block of copper lines
		lea.l	ColorGradientTable(pc),a0                   ; Point to ColorGradient table
		bsr.w	BuildCopperList_Gradient                          ; Call routine to generate color gradient copper lines
		move.b	#$3f,d1                        ; Set start vertical raster line for third block
		move.w	#$f,d0                         ; Loop counter for third block of copper lines
		move.l	a2,$70000                      ; Store current copper buffer address in absolute location $70000
		bsr.b	BuildCopperList_Lines                          ; Call routine to generate copper lines
		bra.w	BuildCopperList_Finalize                          ; Jump to finalize copper list
BuildCopperList_Lines:
		move.w	d1,(a2)+                       ; Write raster wait horizontal/vertical position instruction
		move.w	#$fffe,(a2)+                   ; Write wait mask ($fffe)
		move.w	#$13,d3                        ; Loop counter to generate 20 color registers per line
.color_loop:
		move.w	#$186,(a2)+                    ; Write COLOR03 register offset
		move.w	d4,(a2)+                       ; Write color value
		move.l	#$1900000,(a2)+                ; Write COLOR08 register offset and color value
		eori.w	#$202,d4                       ; Modify color gradient pattern using XOR
		dbra	d3,.color_loop                        ; Loop for all 20 color registers in this line
		addi.w	#$100,d1                       ; Increment target vertical raster line coordinate by 1
		dbra	d0,BuildCopperList_Lines                        ; Loop for all lines in block
		rts                                   ; Return
BuildCopperList_Block2:
		move.w	d1,(a2)+                       ; Write vertical raster line wait instruction
		move.w	#$fffe,(a2)+                   ; Write wait mask ($fffe)
.loop2:
		move.l	#$1860ff0,(a2)+                ; Write copper instruction (COLOR03 = yellow)
		move.l	#$1900000,(a2)+                ; Write copper instruction (COLOR08 = black)
		move.l	#$1860777,(a2)+                ; Write copper instruction (COLOR03 = grey)
		move.w	d1,(a2)+                       ; Write vertical raster line wait instruction
		move.b	#$cf,-$1(a2)                   ; Modify copper instruction wait position to horizontal $cf
		move.w	#$fffe,(a2)+                   ; Write wait mask ($fffe)
		move.l	#$18600f0,(a2)+                ; Write copper instruction (COLOR03 = blue)
		addi.w	#$100,d1                       ; Increment target vertical raster line coordinate
		bcc.b	.next2                          ; Branch if vertical raster coordinate did not overflow past 255
		move.l	#$ffdffffe,(a2)+               ; Write copper wait instruction for frame page flip ($ffdffffe)
		dbra	d0,.loop2                        ; Loop to generate next copper line entries
		rts                                   ; Return
.next2:
		dbra	d0,BuildCopperList_Block2                        ; Loop to generate next copper line entries
		rts                                   ; Return
BuildCopperList_Gradient:
		move.w	d1,(a2)+                       ; Write vertical raster line wait instruction
		move.w	#$fffe,(a2)+                   ; Write wait mask ($fffe)
.loop_gradient:
		tst.w	(a0)                            ; Test if gradient color end marker reached
		bpl.b	.gradient_no_reset                          ; Branch if not at end
		lea.l	ColorGradientTable,a0           ; Reset gradient color pointer to start of ColorGradientTable
.gradient_no_reset:
		move.w	#$196,(a2)+                    ; Write COLOR11 register offset
		move.w	(a0)+,(a2)+                    ; Write gradient color value
		move.l	#$1860f0f,(a2)+                ; Write copper instruction (COLOR03 = purple)
		move.w	d1,(a2)+                       ; Write vertical raster line wait instruction
		move.b	#$4b,-$1(a2)                   ; Modify copper instruction wait position to horizontal $4b
		move.w	#$fffe,(a2)+                   ; Write wait mask ($fffe)
		move.l	#$1860777,(a2)+                ; Write copper instruction (COLOR03 = grey)
		move.w	d1,(a2)+                       ; Write vertical raster line wait instruction
		move.b	#$cf,-$1(a2)                   ; Modify copper instruction wait position to horizontal $cf
		move.w	#$fffe,(a2)+                   ; Write wait mask ($fffe)
		move.l	#$1860f00,(a2)+                ; Write copper instruction (COLOR03 = red)
		addi.w	#$100,d1                       ; Increment target vertical raster line coordinate
		bcc.b	.gradient_no_pageflip                          ; Branch if vertical raster coordinate did not overflow past 255
		move.l	#$ffdffffe,(a2)+               ; Write copper wait instruction for frame page flip ($ffdffffe)
		dbra	d0,.loop_gradient                        ; Loop to generate next gradient copper line entries
		rts                                   ; Return
.gradient_no_pageflip:
		dbra	d0,BuildCopperList_Gradient                        ; Loop to generate next gradient copper line entries
		rts                                   ; Return
BuildCopperList_Finalize:
		move.l	#$1a20ea4,(a2)+                ; Write sprite pointer registers in copper (SPR1PTH/SPR1PTL)
		move.l	#$1a40a62,(a2)+                ; Write sprite pointer registers in copper (SPR2PTH/SPR2PTL)
		move.l	#$1a60630,(a2)+                ; Write sprite pointer registers in copper (SPR3PTH/SPR3PTL)
		move.w	#$d,d1                         ; Loop counter to disable remaining 6 sprites (SPR4 to SPR7)
		move.w	#$124,d2                       ; Load SPR4PTH register offset
.disable_sprites_loop:
		move.w	d2,(a2)+                       ; Write sprite pointer register offset
		clr.w	(a2)+                           ; Write zero pointer value
		addi.w	#$2,d2                         ; Advance to next sprite pointer register offset
		dbra	d1,.disable_sprites_loop                        ; Loop to disable remaining sprites
		move.l	#$1000000,(a2)+                ; Write BPL1CON0 copper instruction (disable bitplanes)
		move.l	#$fffffffe,(a2)+               ; Write copper list end instruction ($fffffffe)
		move.l	a2,Var_CopperWritePtr                      ; Save final copper list write pointer in Var_CopperWritePtr
		rts                                   ; Return
; --- Data Block Grouped 0ce6 - 0d22 ---
ColorGradientTable:
		dc.w	$0ea4,$0d93,$0c83,$0c72,$0b62,$0a62,$0951,$0841
		dc.w	$0741,$0630,$0620,$0410,$0310,$0200,$0200,$0310
		dc.w	$0410,$0620,$0630,$0741,$0841,$0951,$0a62,$0b62
		dc.w	$0c72,$0c83,$0d93,$0ea4,$0fb4,$ffff
; --- Data Block 0d22 - 0dac ---
FontData:
		dc.w	$0503                            ; Font glyph index offset for characters
		dc.w	$0602                            ; Font glyph index offset for characters
		dc.w	$0701                            ; Font glyph index offset for characters
		dc.w	$0800                            ; Font glyph index offset for characters
		dc.w	$0900                            ; Font glyph index offset for characters
		dc.w	$0a00                            ; Font glyph index offset for characters
		dc.w	$0b00                            ; Font glyph index offset for characters
		dc.w	$0c00                            ; Font glyph index offset for characters
		dc.w	$0d00                            ; Font glyph index offset for characters
		dc.w	$0e00                            ; Font glyph index offset for characters
		dc.w	$0f00                            ; Font glyph index offset for characters
		dc.w	$0f10                            ; Font glyph index offset for characters
		dc.w	$0f20                            ; Font glyph index offset for characters
		dc.w	$0f30                            ; Font glyph index offset for characters
		dc.w	$0f40                            ; Font glyph index offset for characters
		dc.w	$0f50                            ; Font glyph index offset for characters
		dc.w	$0f60                            ; Font glyph index offset for characters
		dc.w	$0f70                            ; Font glyph index offset for characters
		dc.w	$0f80                            ; Font glyph index offset for characters
		dc.w	$0f90                            ; Font glyph index offset for characters
		dc.w	$0fa0                            ; Font glyph index offset for characters
		dc.w	$0fb0                            ; Font glyph index offset for characters
		dc.w	$0fc0                            ; Font glyph index offset for characters
		dc.w	$0fd0                            ; Font glyph index offset for characters
		dc.w	$0fe0                            ; Font glyph index offset for characters
		dc.w	$0ff0                            ; Font glyph index offset for characters
		dc.w	$0ef0                            ; Font glyph index offset for characters
		dc.w	$0df0                            ; Font glyph index offset for characters
		dc.w	$0cf0                            ; Font glyph index offset for characters
		dc.w	$0bf0                            ; Font glyph index offset for characters
		dc.w	$0af0                            ; Font glyph index offset for characters
		dc.w	$09f0                            ; Font glyph index offset for characters
		dc.w	$08f0                            ; Font glyph index offset for characters
		dc.w	$07f0                            ; Font glyph index offset for characters
		dc.w	$06f0                            ; Font glyph index offset for characters
		dc.w	$05f0                            ; Font glyph index offset for characters
		dc.w	$04f0                            ; Font glyph index offset for characters
		dc.w	$03f0                            ; Font glyph index offset for characters
		dc.w	$02f0                            ; Font glyph index offset for characters
		dc.w	$01f0                            ; Font glyph index offset for characters
		dc.w	$00f0                            ; Font glyph index offset for characters
		dc.w	$00e1                            ; Font glyph index offset for characters
		dc.w	$00d2                            ; Font glyph index offset for characters
		dc.w	$00d3                            ; Font glyph index offset for characters
		dc.w	$00c4                            ; Font glyph index offset for characters
		dc.w	$00b5                            ; Font glyph index offset for characters
		dc.w	$00a6                            ; Font glyph index offset for characters
		dc.w	$0097                            ; Font glyph index offset for characters
		dc.w	$0088                            ; Font glyph index offset for characters
		dc.w	$0079                            ; Font glyph index offset for characters
		dc.w	$006a                            ; Font glyph index offset for characters
		dc.w	$005b                            ; Font glyph index offset for characters
		dc.w	$004c                            ; Font glyph index offset for characters
		dc.w	$003d                            ; Font glyph index offset for characters
		dc.w	$002e                            ; Font glyph index offset for characters
		dc.w	$001f                            ; Font glyph index offset for characters
		dc.w	$000f                            ; Font glyph index offset for characters
		dc.w	$010e                            ; Font glyph index offset for characters
		dc.w	$020d                            ; Font glyph index offset for characters
		dc.w	$030c                            ; Font glyph index offset for characters
		dc.w	$040b                            ; Font glyph index offset for characters
		dc.w	$050a                            ; Font glyph index offset for characters
		dc.w	$0509                            ; Font glyph index offset for characters
		dc.w	$0508                            ; Font glyph index offset for characters
		dc.w	$0507                            ; Font glyph index offset for characters
		dc.w	$0506                            ; Font glyph index offset for characters
		dc.w	$0505                            ; Font glyph index offset for characters
		dc.w	$0504                            ; Font glyph index offset for characters
TextData:
		dc.w	$ffff                            ; Original offset $0daa
; --- Code Block 0dac - 0dce ---
ExitIntro_Core:
		move.w	#$c000,CUSTOM+INTENA           ; Restore INTENA (enable system interrupts)
		move.w	#$8020,CUSTOM+DMACON           ; Restore DMACON (enable system DMA channels)
		movea.l	ExecBase.l,a6                  ; Load ExecBase base pointer
		movea.l	(a6),a6                       ; Load current active Task/Process pointer
		movea.l	(a6),a6                       ; Load parent system copper list pointer
		move.l	$26(a6),CUSTOM+COP1LCH         ; Restore parent system copper list to COP1LCH
		rts                                    ; Return to system / caller
; --- Code Block 0dd0 - 0e1c ---
StartCopperList:
		lea.l	CUSTOM,a5                       ; Point to Custom Chip registers base address
		move.l	Var_CopperSprite1(pc),BLTAPT(a5)          ; Write SpriteList pointer to active copper list setup
		move.l	Var_CopperSprite2(pc),BLTBPT(a5)          ; Write secondary SpriteList pointer to active copper list setup
		move.l	Var_CopperSprite2(pc),BLTDPT(a5)          ; Write destination pointer parameter to active copper list setup
		move.w	Var_CopperBlitMod(pc),BLTAMOD(a5)         ; Write modulo parameter to active copper list setup
		move.w	Var_CopperBlitShift(pc),BLTBMOD(a5)         ; Write control register shift parameter to copper list
		move.w	Var_CopperBlitShift(pc),BLTDMOD(a5)         ; Write control register shift parameter to copper list
		move.l	Var_CopperBlitMask(pc),BLTAFWM(a5)         ; Write mask parameter to active copper list setup
		move.w	Var_CopperBlitCon0(pc),BLTCON0(a5)         ; Write control mode parameter to active copper list setup
		move.w	Var_CopperBlitCon1(pc),BLTCON1(a5)         ; Write control mode parameter to active copper list setup
		move.w	Var_CopperBlitSize(pc),BLTSIZE(a5)         ; Write blitter vertical size parameter to start blit
SetSpritePos:
		btst.b	#$e,DMACONR(a5)                ; Test blitter busy bit in DMACONR
		bne.b	SetSpritePos                    ; Loop until blit is complete
		rts                                   ; Return
; --- Data Block 0e1c - 0ee2 ---
		dc.w	$0001                            ; Copper instruction template word 0
		dc.w	$0000                            ; Copper instruction template word 1
		dc.w	$0000                            ; Copper instruction template word 2
		dc.w	$0000                            ; Copper instruction template word 3
		dc.w	$0000                            ; Copper instruction template word 4
Var_CopperBlitSize:
		dc.w	$0000                            ; Blitter size register value (BLTSIZE)
Var_CopperBlitMod:
		dc.w	$0000                            ; Blitter modulo value (BLTAMOD)
Var_CopperBlitShift:
		dc.w	$0000                            ; Blitter control value (BLTCON0)
Var_CopperBlitMask:
		dc.w	$0000                            ; Blitter first word mask value (BLTAFWM)
		dc.w	$0000                            ; Blitter last word mask value (BLTALWM)
Var_CopperBlitCon0:
		dc.w	$0000                            ; Blitter control mode value (BLTCON1)
Var_CopperBlitCon1:
		dc.w	$0000                            ; Blitter control mode value (BLTCON1)
		dc.w	$0000                            ; Blitter shift value
Var_CopperSprite1:
		dc.w	$0000                            ; Copper sprite/scroll pointer high word
		dc.w	$0000                            ; Copper sprite/scroll pointer low word
Var_CopperSprite2:
		dc.w	$0000                            ; Copper secondary sprite/scroll pointer high word
		dc.w	$0000                            ; Copper secondary sprite/scroll pointer low word
CopperListTemplate:
		dc.w	$00e4                            ; BPL2PTH (Bitplane 2 pointer high word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$00e6                            ; BPL2PTL (Bitplane 2 pointer low word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$00ec                            ; BPL4PTH (Bitplane 4 pointer high word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$00ee                            ; BPL4PTL (Bitplane 4 pointer low word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$00e0                            ; BPL1PTH (Bitplane 1 pointer high word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$00e2                            ; BPL1PTL (Bitplane 1 pointer low word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$00e8                            ; BPL3PTH (Bitplane 3 pointer high word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$00ea                            ; BPL3PTL (Bitplane 3 pointer low word register offset)
		dc.w	$0000                            ; Default value = 0
		dc.w	$008e                            ; DIWSTRT (Display Window Start register offset)
		dc.w	$2c81                            ; Start coordinates value ($2C81)
		dc.w	$0090                            ; DIWSTOP (Display Window Stop register offset)
		dc.w	$2bc1                            ; Stop coordinates value ($BC12)
		dc.w	$0092                            ; DDFSTRT (Display Data Fetch Start register offset)
		dc.w	$0038                            ; Start horizontal coordinate ($38)
		dc.w	$0094                            ; DDFSTOP (Display Data Fetch Stop register offset)
		dc.w	$00d0                            ; Stop horizontal coordinate ($D0)
		dc.w	$0102                            ; BPLCON1 (Playfield horizontal scroll register offset)
		dc.w	$0000                            ; Scroll value = 0
		dc.w	$0108                            ; BPL1MOD (Odd bitplane modulo register offset)
		dc.w	$0000                            ; Modulo value = 0
		dc.w	$010a                            ; BPL2MOD (Even bitplane modulo register offset)
		dc.w	$0018                            ; Modulo value = 24 bytes ($18)
		dc.w	$0104                            ; BPLCON2 (Priority control register offset)
		dc.w	$0024                            ; Priority value = $24
		dc.w	$0180                            ; COLOR00 (Background color register offset)
		dc.w	$0444                            ; Color value: dark grey ($444)
		dc.w	$0182                            ; COLOR01 register offset
		dc.w	$0aaa                            ; Color value: light grey ($AAA)
		dc.w	$0184                            ; COLOR02 register offset
		dc.w	$0222                            ; Color value ($222)
		dc.w	$0186                            ; COLOR03 register offset
		dc.w	$0777                            ; Color value ($777)
		dc.w	$0192                            ; COLOR09 register offset
		dc.w	$0800                            ; Color value ($800)
		dc.w	$0194                            ; COLOR10 register offset
		dc.w	$0f00                            ; Color value ($F00)
		dc.w	$0100                            ; BPLCON0 (Bitplane control 0 register offset)
		dc.w	$0200                            ; Mode value: 4 bitplanes, color enabled ($200)
		dc.w	$2c01                            ; Copper Wait horizontal/vertical position ($2C01)
		dc.w	$fffe                            ; Wait instruction mask ($FFFE)
		dc.w	$0100                            ; BPLCON0 register offset
		dc.w	$4600                            ; Mode value: 4 bitplanes, highres/dualplayfield ($4600)
Var_CopperWritePtr:
		dc.w	$0000                            ; Copper list dynamic extension pointer high word
		dc.w	$0000                            ; Copper list dynamic extension pointer low word
MappedCharacterTable:
		dc.b	"abcdefghijklmnopqrstuvwxyz0123456789.,:;" ; ASCII font mapping characters a-z, 0-9, and punctuation
		dc.b	$27,$22					; ASCII mapping for single quote (') and double quote (")
		dc.b	"!?"					; ASCII mapping for exclamation mark and question mark
		dc.b	"#", $24				; ASCII mapping for hash and dollar sign (escaped)
		dc.b	$25,$26,$2a,$2d,$3d,$2b,$2f,$28,$29,$5b,$5d,$3c,$3e,0 ; ASCII: %&*-=+/( ) [ ] < > followed by null terminator
; ============================================================================
; 16x16 One-Bitplane Font Data (60 Characters)
; ============================================================================
; Glyph: 'a'
; ----------------------------------------------------------------------------
SpriteList:
		incbin	"assets/fonts/font_1bpl.raw"
Var_ActiveScreen:
		dc.w	$0000                            ; Original offset $1662
		dc.w	$0000                            ; Original offset $1664
; ============================================================================
; Function: Decruncher
; Purpose : Keyboard interrupt handler hook copied to address $C0.
;           Checks for F1, F2, F3 key presses to toggle trainer options.
; ============================================================================
Decruncher:
        move.b  CIAA_SDR.l,d0            ; Read key scan code from CIAA SDR
        movem.l d0-d3/a0-a2,-(a7)       ; Save working registers
        bsr.s   KeyboardProcess         ; Process the keyboard scan code
        movem.l (a7)+,d0-d3/a0-a2       ; Restore registers
        rts                             ; Return from interrupt/hook

; ============================================================================
; Function: KeyboardProcess
; Purpose : Checks scan code against target keys to toggle option flags.
; Inputs  : d0.b = Raw scan code.
; ============================================================================
KeyboardProcess:
        lea     KeyTable(pc),a0         ; Point to the list of target scan codes
        moveq   #0,d2                   ; Initialize trainer option index
KeyScanLoop:
        move.b  (a0)+,d1                ; Read next scan code from table
        beq.w   KeyboardProcess_Done    ; If null terminator, stop scanning
        cmp.b   d0,d1                   ; Compare key code with current key
        beq.s   KeyMatched              ; If key matches, handle the toggle
        addq.w  #1,d2                   ; Increment option index
        bra.s   KeyScanLoop             ; Check next key

KeyMatched:
        lea     CUSTOM+COLOR00,a1       ; Point to background color register for flash
        lea     HandlerJumpTable(pc),a0 ; Point to the branch table
        move.w  d2,d0                   ; Copy option index
        lsl.w   #1,d0                   ; Multiply index by 2 for word offset
        move.w  (a0,d0.w),d1            ; Fetch the relative branch offset
        lea     (a0,d1.w),a0            ; Calculate final handler address
        lea     FlagState(pc),a2        ; Point to trainer option flags
        adda.w  d2,a2                   ; Select flag for this option index
        moveq   #$19,d3                 ; Set toggle bitmask pattern
        jmp     (a0)                    ; Jump to specific key handler

; ============================================================================
; Data: KeyTable, FlagState, HandlerJumpTable
; ============================================================================
KeyTable:
        dc.b    $5f,$5d,$5b,$00         ; Scan codes for F1, F2, F3
FlagState:
        dc.b    $00,$00,$00             ; State flags for options F1, F2, F3
        dc.b    $00                     ; Alignment byte
HandlerJumpTable:
        dc.w    Target_F1-HandlerJumpTable ; Offset to F1 Key Handler
        dc.w    Target_F2-HandlerJumpTable ; Offset to F2 Key Handler
        dc.w    Target_F3-HandlerJumpTable ; Offset to F3 Key Handler

; ============================================================================
; Function: Target_F1
; Purpose : Toggle Infinite Credits (F1). Patches address $158B4.
; ============================================================================
Target_F1:
        tst.b   (a2)                    ; Check if F1 option is already active
        beq.s   Enable_F1               ; If clear, enable the option
        eor.b   d3,$158b4.l             ; Restore/toggle original game code
        bra.s   KeyboardProcess_Disable ; Disable trainer flag and color flash
Enable_F1:
        move.w  #$0f00,(a1)             ; Set background to Red (F1 active)
        move.b  #1,(a2)                 ; Set F1 option flag to active
        move.w  #2,$2282.w              ; Patch game code at $2282
        eor.b   d3,$158b4.l             ; Apply patch to game code at $158B4
        rts

; ============================================================================
; Function: Target_F2
; Purpose : Toggle Infinite Lives (F2). Patches address $1006C.
; ============================================================================
Target_F2:
        tst.b   (a2)                    ; Check if F2 option is already active
        beq.s   Enable_F2               ; If clear, enable the option
        eor.b   d3,$1006c.l             ; Restore/toggle original game code
        bra.s   KeyboardProcess_Disable ; Disable trainer flag and color flash
Enable_F2:
        move.w  #$00f0,(a1)             ; Set background to Green (F2 active)
        move.b  #1,(a2)                 ; Set F2 option flag to active
        move.w  #3,$2284.w              ; Patch game code at $2284
        eor.b   d3,$1006c.l             ; Apply patch to game code at $1006C
        rts

; ============================================================================
; Function: Target_F3
; Purpose : Toggle Infinite Energy (F3). Patches addresses $FF3A and $FFB2.
; ============================================================================
Target_F3:
        tst.b   (a2)                    ; Check if F3 option is already active
        beq.s   Enable_F3               ; If clear, enable the option
        eor.b   d3,$ff3a.l              ; Restore/toggle energy patch 1
        eor.b   d3,$ffb2.l              ; Restore/toggle energy patch 2
        bra.s   KeyboardProcess_Disable ; Disable trainer flag and color flash
Enable_F3:
        move.w  #$000f,(a1)             ; Set background to Blue (F3 active)
        move.b  #1,(a2)                 ; Set F3 option flag to active
        move.w  #3,$2286.w              ; Patch game code at $2286
        eor.b   d3,$ff3a.l              ; Apply patch 1
        eor.b   d3,$ffb2.l              ; Apply patch 2
        rts

; ============================================================================
; Function: KeyboardProcess_Disable
; Purpose : Clear option flag and reset background color.
; ============================================================================
KeyboardProcess_Disable:
        clr.b   (a2)                    ; Clear current trainer option flag
        move.w  #$0fff,(a1)             ; Restore background color to White
KeyboardProcess_Done:
        rts                             ; Return

; ============================================================================
; Function: KeyInstallHandler
; Purpose : Installs the key handler at zero-page $C0 and starts the game.
; ============================================================================
KeyInstallHandler:
        move.l  #$4eb800c0,$eed6.l      ; Patch game keyboard vector to call our handler at $C0
        move.w  #$4e71,$eeda.l          ; NOP out key check logic in game
        jmp     $4000.w                 ; Jump to the main game code at $4000
MusicData:
		incbin	"music.bin"
