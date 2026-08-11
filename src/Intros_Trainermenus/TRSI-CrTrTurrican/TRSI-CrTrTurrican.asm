; ==============================================================================
; TRSI (Tristar & Red Sector Inc.) - Turrican 100% Trainer Intro
;
; Reconstructed Motorola 68000 Assembly Source Code by
; Volker Schwaberow <volker@schwaberow.de>
;
; Original Code by TRANSFORMER / TRSI (1990)
;
; Target Assembler: vasmm68k_mot -Fhunkexe -nosym -o build/output.exe main.asm
; ==============================================================================

; ------------------------------------------------------------------------------
; Amiga Hardware Registers & System Equates
; ------------------------------------------------------------------------------
ExecBase            EQU $000004         ; System ExecBase Pointer
CIAB_PRA            EQU $bfd000         ; CIA-B Port A (Disk Control / Parallel)
CIAA_PRA            EQU $bfe001         ; CIA-A Port A (Gameports / Left Mouse Button)
CUSTOM              EQU $dff000         ; Amiga Custom Chip Base Address
DMACONR             EQU $dff002         ; Read DMA Control & State
VPOSR               EQU $dff004         ; Read Vertical & Long Frame Bit
VHPOSR              EQU $dff006         ; Read Vertical & Horizontal Raster Position
COP1LC              EQU $dff080         ; Copper 1 Location Pointer
COPJMP1             EQU $dff088         ; Copper 1 Restart Trigger
DMACON              EQU $dff096         ; Write DMA Control
INTENA              EQU $dff09a         ; Write Interrupt Enable
INTREQ              EQU $dff09c         ; Write Interrupt Request
BPLCON0             EQU $dff100         ; Bitplane Control 0
COLOR00             EQU $dff180         ; Color 00 (Background)
COLOR01             EQU $dff182         ; Color 01 (Foreground)

; ------------------------------------------------------------------------------
; AmigaOS Exec & Graphics Library Vector Offsets (LVOs)
; ------------------------------------------------------------------------------
_LVOAllocMem        EQU -198            ; AllocMem(byteSize, requirements)
_LVOFreeMem         EQU -210            ; FreeMem(memoryBlock, byteSize)
_LVOOpenLibrary     EQU -408            ; OpenLibrary(libName, version)
_LVOCloseLibrary    EQU -414            ; CloseLibrary(libraryVector)
_LVOOpenFont        EQU -390            ; OpenFont(textAttr)
_LVOText            EQU -60             ; Text(rp, string, length)
_LVOBltBitMap       EQU -240            ; BltBitMap(src, srcX, srcY, dst, dstX, dstY...)

; ------------------------------------------------------------------------------
; Turrican Sound Driver & Decruncher Entry Vectors
; ------------------------------------------------------------------------------
Audio_Init          EQU $170a           ; Initialize Sound Driver & Audio DMA
Audio_UpdateTempo   EQU $154c           ; Update Music Tempo & Beat Counter
Audio_PlaySound     EQU $1576           ; Play Sound Effect Trigger
Audio_UpdateChannels EQU $15fe          ; Update Active Audio Channels
Decruncher_GameEntry EQU $1bb28          ; Turrican Main Game Entry Point
Decruncher_Cleanup  EQU $1bb48          ; Decruncher Memory Cleanup Routine
Decruncher_RestoreHW EQU $1bb4c          ; System Hardware Restore Routine

; ------------------------------------------------------------------------------
; Workspace RAM Variables
; ------------------------------------------------------------------------------
var_Bitplane2       EQU $304c8         ; Bitplane 2 Buffer Pointer
var_CopperListBuf   EQU $304cc         ; Copper List Buffer Pointer
var_VBlankFlag1     EQU $304e8         ; VBlank Sync Flag 1
var_VBlankFlag2     EQU $304ea         ; VBlank Sync Flag 2
var_ScrollFlag      EQU $304ec         ; Scroll Motion Flag
var_IntroActiveFlag EQU $304ee         ; Intro Active Flag ($FFFF = Running)
var_GfxBase         EQU $304f0         ; GfxBase Library Pointer
var_ExecBase        EQU $304f4         ; ExecBase Library Pointer
var_GfxVBlankNode   EQU $304f8         ; Backup GfxBase VBlank Node
var_ScrollTextPtr   EQU $304fc         ; Scrolltext Read Pointer
var_ChipRamBase     EQU $30500         ; Allocated 12 KB Chip RAM Base
var_Bitplane1       EQU $30504         ; Bitplane 1 Buffer Pointer
var_CopperListEnd   EQU $30508         ; Copper List End Address
var_CopperListMax   EQU $3050c         ; Copper List Max Boundary
var_RenderFontTarget EQU $30518        ; Font Bitmap Render Target Pointer
var_TextRenderBuf   EQU $30544         ; Text Render Workspace Pointer

	SECTION main,CODE_C

; ------------------------------------------------------------------------------
; Main Intro Initialization & Memory Allocation
; ------------------------------------------------------------------------------

MainEntry:
	movem.l   	d0-d7/a0-a6,-(a7)           	; Save registers & disable system interrupts
	move.w    	#$8100,$dff096.l            	; Enable Copper DMA
	move.l    	$4.l,var_ExecBase.l
	movea.l   	var_ExecBase_slot(pc),a6
	move.l    	#$10002,d1
	move.l    	#$2ee0,d0                   	; Alloc 12KB Chip RAM for Bitplanes & Copper
	jsr       	_LVOAllocMem(a6)                    	; Exec.AllocMem()
	tst.l     	d0
	beq.w     	ReturnToCaller
	move.l    	d0,var_ChipRamBase.l
	addi.l    	#$7d0,d0
	move.l    	d0,var_Bitplane1.l
	addi.l    	#$1770,d0
	move.l    	d0,var_Bitplane2.l
	addi.l    	#$7d0,d0
	move.l    	d0,var_CopperListBuf.l
	lea.l     	graphics_lib_name(pc),a1
	jsr       	_LVOOpenLibrary(a6)                   	; Exec.OpenLibrary("graphics.library")
	move.l    	d0,var_GfxBase.l
	moveq     	#$1,d0
	move.l    	#$170,d1
	move.l    	#$28,d2
	lea.l     	font_spec(pc),a0
	movea.l   	var_GfxBase_slot(pc),a6
	jsr       	_LVOOpenFont(a6)
	lea.l     	text_render_workspace(pc),a1
	jsr       	_LVOAllocMem(a6)
	move.l    	#$30510,var_TextRenderBuf.l
	move.l    	var_ChipRamBase_slot(pc),var_RenderFontTarget.l
	lea.l     	text_attr_struct(pc),a0
	jsr       	_LVOText(a6)
	movea.l   	d0,a0
	lea.l     	text_render_workspace(pc),a1
	jsr       	_LVOBltBitMap(a6)
	lea.l     	copper_template_base+$28(pc),a0
	lea.l     	palette_table_primary(pc),a1
	moveq     	#$7,d0
	move.l    	(a1)+,d1
	move.w    	d1,$6(a0)
	swap      	d1
	move.w    	d1,$2(a0)
	addq.l    	#$8,a0
	dbra      	d0,$b8
	bsr.w     	InitCopperList              	; Build Copper list in Chip RAM
	bsr.w     	UpdateCopperPointers        	; Set bitplane pointers in Copper list
	bsr.w     	InitRasterColorTables       	; Setup raster bar sine tables
	movea.l   	var_GfxBase_slot(pc),a6
	move.l    	$32(a6),var_GfxVBlankNode.l
	move.l    	var_Bitplane1_slot(pc),$32(a6)
	move.l    	$6c.l,$302e2.l
	move.l    	#VBlankInterruptHandler,$6c.l
	move.w    	#$8020,$dff096.l            	; Enable Vertical Blank interrupts in DMACON
	move.w    	#$0,var_ScrollFlag.l
	moveq     	#$1,d4
	move.l    	#scrolltext,var_ScrollTextPtr.l
	move.w    	#$ffff,var_IntroActiveFlag.l

MainEventLoop:
	tst.w     	var_IntroActiveFlag.l       	; Main intro loop
	beq.w     	ExitIntro
	subq.l    	#$1,d4
	bne.b     	MainEventLoop
	move.l    	#$60000,d4
	tst.w     	var_ScrollFlag.l
	beq.b     	RenderScrollTextStep
	bsr.w     	WaitForVBlankFlag1
	movea.l   	var_ChipRamBase_slot(pc),a1
	move.w    	#$1f3,d2
	clr.l     	(a1)+
	dbra      	d2,$148
	tst.w     	var_IntroActiveFlag.l
	beq.w     	ExitIntro

RenderScrollTextStep:
	; Render 3-line text page: Row 1 at Y = 6px, Row 2 at Y = 16px, Row 3 at Y = 26px
	moveq     	#$6,d6                      	; Row 1: Y-raster offset = 6 pixels
	bsr.b     	FetchCharAndRender
	moveq     	#$10,d6                     	; Row 2: Y-raster offset = 16 pixels
	bsr.b     	FetchCharAndRender
	moveq     	#$1a,d6                     	; Row 3: Y-raster offset = 26 pixels
	bsr.b     	FetchCharAndRender
	bsr.w     	WaitForVBlankFlag2          	; Sync with VBlank interrupt flag 2
	tst.w     	var_IntroActiveFlag.l       	; Check if intro is active
	beq.w     	ExitIntro
	bra.w     	MainEventLoop

ExitIntro:
	move.l    	var_VBR_Backup(pc),$6c.l              	; Clean up & restore system vectors
	movea.l   	var_GfxBase_slot(pc),a6
	move.l    	var_GfxVBlankNode_slot(pc),$32(a6)
	movea.l   	var_ExecBase_slot(pc),a6
	movea.l   	var_GfxBase_slot(pc),a1
	jsr       	_LVOCloseLibrary(a6)                   	; Exec.CloseLibrary()
	move.l    	#$2ee0,d0
	movea.l   	var_ChipRamBase_slot(pc),a1
	jsr       	_LVOFreeMem(a6)                    	; Exec.FreeMem()

ReturnToCaller:
	movem.l   	(a7)+,d0-d7/a0-a6
	rts       	

FetchCharAndRender:
	move.l    	d6,-(a7)                    	; Save Y-raster row offset (D6) onto stack
	move.w    	#$ffff,var_ScrollFlag.l     	; Mark scroll motion flag active
	movea.l   	var_ScrollTextPtr_slot(pc),a5 	; Load current text page read pointer
	cmpi.b    	#$ff,(a5)                   	; Check for end-of-text marker ($FF)
	bne.b     	loc_01c2
	movea.l   	#scrolltext,a5              	; Reset text pointer to start if end marker reached

loc_01c2:
	cmpi.b    	#$1,(a5)                    	; Check for control code $01 (page marker)
	bne.b     	loc_01d6
	adda.l    	#$1,a5                      	; Advance past control code $01
	move.w    	#$5555,var_IntroActiveFlag.l

loc_01d6:
	movea.l   	a5,a4                       	; A4 = Temporary pointer for string length loop
	moveq     	#$0,d6                      	; D6 = Character counter (reset to 0)

loc_01da:
	tst.b     	(a4)+                       	; Read byte and advance A4
	beq.b     	loc_01e2                    	; Null terminator (0) reached? Exit count loop
	addq.w    	#$1,d6                      	; Increment character count
	bra.b     	loc_01da

loc_01e2:
	move.l    	a4,var_ScrollTextPtr.l      	; Update text pointer to start of next line
	
	; --------------------------------------------------------------------------
	; Horizontal Centering Math: X_Start = Screen_Center (176) - (Char_Count * 4)
	; --------------------------------------------------------------------------
	move.l    	#$b0,d0                     	; D0 = 176 ($B0) -> Center pixel coordinate of screen
	move.l    	d6,d1                       	; D1 = String character length (Chars)
	lsl.w     	#$2,d1                      	; D1 = Chars * 4 (Half of 8px character width: String_Width / 2)
	sub.l     	d1,d0                       	; D0 = 176 - (Chars * 4) -> Calculated X-Start coordinate!

	lea.l     	text_render_workspace(pc),a1 	; Load RastPort text workspace
	move.l    	(a7)+,d1                    	; Restore Y-raster row offset (D1) from stack
	movea.l   	var_GfxBase_slot(pc),a6     	; GfxBase library vector pointer
	jsr       	_LVOBltBitMap(a6)           	; Prepare/clear raster line bitplane workspace

	lea.l     	text_render_workspace(pc),a1 	; Load RastPort workspace
	movea.l   	a5,a0                       	; A0 = Pointer to ASCII string text line
	move.l    	d6,d0                       	; D0 = Character count parameter
	movea.l   	var_GfxBase_slot(pc),a6
	jsr       	_LVOText(a6)                	; Gfx.Text() -> Render string at (X_Start, Y_Offset)
	rts       	

WaitForVBlankFlag1:
	move.w    	#$ffff,var_VBlankFlag1.l

loc_021c:
	tst.w     	var_IntroActiveFlag.l
	beq.w     	loc_022e
	tst.w     	var_VBlankFlag1.l
	bne.b     	loc_021c

loc_022e:
	rts       	

WaitForVBlankFlag2:
	move.w    	#$ffff,var_VBlankFlag2.l

loc_0238:
	tst.w     	var_IntroActiveFlag.l
	beq.w     	loc_024a
	tst.w     	var_VBlankFlag2.l
	bne.b     	loc_0238

loc_024a:
	rts       	

VBlankInterruptHandler:
	movem.l   	d0-d7/a0-a6,-(a7)           	; VBlank Interrupt Handler (50 Hz PAL)
	btst.b    	#$6,$bfe001.l               	; Read CIA-A Port A ($bfe001) - Left Mouse Button exit
	bne.b     	loc_026c
	cmpi.w    	#$ffff,var_IntroActiveFlag.l
	beq.b     	loc_026c
	move.w    	#$0,var_IntroActiveFlag.l

loc_026c:
	tst.w     	var_VBlankFlag1.l
	beq.b     	loc_02a0
	move.w    	color_gradient_table_1+$36(pc),d2
	cmp.w     	#$64,d2
	bls.b     	loc_0286
	clr.w     	var_VBlankFlag1.l
	bra.b     	loc_02a0

loc_0286:
	lea.l     	color_gradient_table_1(pc),a0
	lea.l     	color_gradient_table_2(pc),a1
	moveq     	#$1b,d0
	move.l    	(a1)+,d1
	add.w     	d1,$2(a0)
	adda.l    	#$4,a0
	dbra      	d0,$290

loc_02a0:
	tst.w     	var_VBlankFlag2.l
	beq.b     	loc_02d4
	move.w    	color_gradient_table_1+$36(pc),d0
	cmp.w     	#$1,d0
	bhi.b     	loc_02ba
	clr.w     	var_VBlankFlag2.l
	bra.b     	loc_02d4

loc_02ba:
	lea.l     	color_gradient_table_1(pc),a0
	lea.l     	color_gradient_table_2(pc),a1
	moveq     	#$1b,d0
	move.l    	(a1)+,d1
	sub.w     	d1,$2(a0)
	adda.l    	#$4,a0
	dbra      	d0,$2c4

loc_02d4:
	bsr.w     	UpdateCopperPointers
	bsr.w     	AnimateRasterBars
	movem.l   	(a7)+,d0-d7/a0-a6
	jmp       	$12345678.l

var_VBR_Backup:
	dc.l	$00000000

InitCopperList:
	lea.l     	copper_template_base(pc),a0                 	; Build Copper list scanlines & gradient color moves
	movea.l   	var_Bitplane1_slot(pc),a1

loc_02ee:
	move.w    	(a0)+,(a1)+
	cmpa.l    	#$30730,a0
	bne.b     	loc_02ee
	move.l    	a1,var_CopperListEnd.l
	move.l    	#$2805fffe,d0

loc_0304:
	move.l    	d0,(a1)+
	move.l    	#$1820000,(a1)+
	move.l    	#$e00000,(a1)+
	move.l    	#$e20000,(a1)+
	addi.l    	#$1000000,d0
	cmp.l     	#$fe05fffe,d0
	bcs.b     	loc_0304
	move.l    	a1,var_CopperListMax.l
	lea.l     	copper_template_end(pc),a0

loc_0330:
	move.w    	(a0)+,(a1)+
	cmpa.l    	#$30828,a0
	bne.b     	loc_0330
	movea.l   	var_CopperListEnd_slot(pc),a1
	adda.l    	#$6,a1
	lea.l     	color_index_array(pc),a0

loc_0348:
	move.w    	(a0)+,d0
	move.w    	(a0)+,d1
	cmp.w     	#$ffff,d0
	beq.b     	loc_0360
	move.w    	d1,(a1)
	adda.l    	#$10,a1
	dbra      	d0,$352
	bra.b     	loc_0348

loc_0360:
	rts       	

UpdateCopperPointers:
	movea.l   	var_CopperListEnd_slot(pc),a0                 	; Animate 32-bit bitplane pointers with sine wobble
	move.l    	var_ChipRamBase_slot(pc),d0
	addi.l    	#$730,d0

loc_0370:
	move.w    	d0,$e(a0)
	swap      	d0
	move.w    	d0,$a(a0)
	swap      	d0
	adda.l    	#$10,a0
	cmpa.l    	var_CopperListMax_slot(pc),a0
	bne.b     	loc_0370
	lea.l     	color_gradient_table_1(pc),a0
	movea.l   	var_CopperListEnd_slot(pc),a1
	adda.l    	#$8,a1
	moveq     	#$1b,d1
	moveq     	#$0,d2
	moveq     	#$0,d0
	move.w    	(a0)+,d0
	add.l     	var_ChipRamBase_slot(pc),d0
	move.w    	(a0)+,d2
	cmp.w     	#$64,d2
	bhi.b     	loc_03d4
	cmp.w     	#$e,d1
	bcs.b     	loc_03bc
	move.l    	#$94,d3
	sub.w     	d2,d3
	move.l    	d3,d2
	bra.b     	loc_03c0

loc_03bc:
	addi.w    	#$94,d2

loc_03c0:
	subi.w    	#$28,d2
	lsl.l     	#$4,d2
	movea.l   	a1,a2
	adda.l    	d2,a2
	move.w    	d0,$6(a2)
	swap      	d0
	move.w    	d0,$2(a2)

loc_03d4:
	dbra      	d1,$39a
	rts       	

InitRasterColorTables:
	movem.l   	d0-d7/a0-a6,-(a7)           	; Initialize copper palette gradient tables
	moveq     	#$29,d0
	lea.l     	color_table_upper(pc),a0
	lea.l     	color_index_map_upper(pc),a2
	movea.l   	palette_table_primary(pc),a1

loc_03ec:
	lea.l     	color_palette_table(pc),a3
	move.b    	d0,(a1)+
	move.b    	(a0)+,(a1)+
	move.b    	d0,d1
	addq.b    	#$1,d1
	move.b    	d1,(a1)+
	clr.b     	(a1)+
	moveq     	#$0,d2
	move.b    	(a2)+,d2
	cmp.b     	#$5,d2
	bne.b     	loc_040a
	clr.l     	(a1)+
	bra.b     	loc_0410

loc_040a:
	lsl.w     	#$2,d2
	adda.l    	d2,a3
	move.l    	(a3),(a1)+

loc_0410:
	addq.b    	#$2,d0
	cmp.b     	#$fd,d0
	bcs.b     	loc_03ec
	clr.l     	(a1)
	move.b    	#$28,d0
	lea.l     	color_table_lower(pc),a0
	lea.l     	color_index_map_lower(pc),a2
	movea.l   	color_gradient_table_2(pc),a1

loc_042a:
	lea.l     	color_palette_table(pc),a3
	move.b    	d0,(a1)+
	move.b    	(a0)+,(a1)+
	move.b    	d0,d1
	addq.b    	#$1,d1
	move.b    	d1,(a1)+
	clr.b     	(a1)+
	moveq     	#$0,d2
	move.b    	(a2)+,d2
	cmp.b     	#$5,d2
	bne.b     	loc_0448
	clr.l     	(a1)+
	bra.b     	loc_044e

loc_0448:
	lsl.w     	#$2,d2
	adda.l    	d2,a3
	move.l    	(a3),(a1)+

loc_044e:
	addq.b    	#$2,d0
	cmp.b     	#$fe,d0
	bcs.b     	loc_042a
	clr.l     	(a1)
	movem.l   	(a7)+,d0-d7/a0-a6
	rts       	

AnimateRasterBars:
	move.l    	#$d3,d0                     	; Horizontal raster bar color animation step
	lea.l     	color_index_map_upper(pc),a2
	movea.l   	palette_table_primary(pc),a1
	addq.l    	#$1,a1
	move.b    	(a1),d1
	move.b    	(a2)+,d2
	sub.b     	d2,d1
	cmp.b     	#$e0,d1
	bcs.b     	loc_047e
	move.b    	#$e0,d1

loc_047e:
	move.b    	d1,(a1)
	addq.l    	#$8,a1
	dbra      	d0,$46e
	move.l    	#$d5,d0
	lea.l     	color_index_map_lower(pc),a2
	movea.l   	palette_table_secondary(pc),a1
	addq.l    	#$1,a1
	move.b    	(a1),d1
	move.b    	(a2)+,d2
	sub.b     	d2,d1
	cmp.b     	#$e0,d1
	bcs.b     	loc_04a6
	move.b    	#$df,d1

loc_04a6:
	move.b    	d1,(a1)
	addq.l    	#$8,a1
	dbra      	d0,$496
	rts       	


; ------------------------------------------------------------------------------
; Intro RAM Load Base Address & Dynamic Color Buffer Equates
; ------------------------------------------------------------------------------
INTRO_BASE_ADDR     EQU $030000         ; Base RAM offset where intro code is loaded
copper_color_buffer EQU INTRO_BASE_ADDR+$05ac ; Allocated RAM buffer for dynamic Copper color gradients

; ------------------------------------------------------------------------------
; Struct Section: AmigaOS TextAttr & Workspace Pointers
; ------------------------------------------------------------------------------

text_attr_struct:
	dc.w	$0003,$04bc
	dc.b	$00,$08,$00,$00
	dc.l	$00000000

palette_table_primary:
	dc.l	copper_color_buffer

palette_table_secondary:
	dc.l	copper_color_buffer,$000305ac,$000305ac,$000305ac,$000305ac

workspace_vars:
var_GfxBase_slot:
	dc.l	$00000000
var_ExecBase_slot:
	dc.l	$00000000
var_GfxVBlankNode_slot:
	dc.l	$00000000
var_ScrollTextPtr_slot:
	dc.l	$00000000
var_ChipRamBase_slot:
	dc.l	$00000000
var_Bitplane1_slot:
	dc.l	$00000000
var_CopperListEnd_slot:
	dc.l	$00000000
var_CopperListMax_slot:
	dc.l	$00000000
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

font_spec:
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

text_render_workspace:
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$01,$80,$00,$00,$01,$04

copper_template_base:

; ------------------------------------------------------------------------------
; Copperlist Scanline Template (WAIT & COLOR Instructions)
; ------------------------------------------------------------------------------
	dc.w	$0000,$0100		; MOVE #$0000, BPLCON0 ($dff100)
	dc.w	$1200,$0102		; MOVE #$1200, BPLCON1 ($dff102)
	dc.w	$0000,$0108		; MOVE #$0000, BPL1MOD ($dff108)
	dc.w	$0000,$010a		; MOVE #$0000, BPL2MOD ($dff10a)
	dc.w	$0000,$008e		; MOVE #$0000, DIWSTRT ($dff08e)
	dc.w	$2871,$0090		; MOVE #$2871, DIWSTOP ($dff090)
	dc.w	$ffd1,$0092		; MOVE #$FFD1, DDFSTRT ($dff092)
	dc.w	$0030,$0094		; MOVE #$0030, DDFSTOP ($dff094)
	dc.w	$00d8,$0120		; MOVE #$00D8, SPR0PTH ($dff120)
	dc.w	$0000,$0122		; MOVE #$0000, SPR0PTL ($dff122)
	dc.w	$0000,$0124		; MOVE #$0000, SPR1PTH ($dff124)
	dc.w	$0000,$0126		; MOVE #$0000, SPR1PTL ($dff126)
	dc.w	$0000,$0128		; MOVE #$0000, SPR2PTH ($dff128)
	dc.w	$0000,$012a		; MOVE #$0000, SPR2PTL ($dff12a)
	dc.w	$0000,$012c		; MOVE #$0000, SPR3PTH ($dff12c)
	dc.w	$0000,$012e		; MOVE #$0000, SPR3PTL ($dff12e)
	dc.w	$0000,$0130		; MOVE #$0000, SPR4PTH ($dff130)
	dc.w	$0000,$0132		; MOVE #$0000, SPR4PTL ($dff132)
	dc.w	$0000,$0134		; MOVE #$0000, SPR5PTH ($dff134)
	dc.w	$0000,$0136		; MOVE #$0000, SPR5PTL ($dff136)
	dc.w	$0000,$0138		; MOVE #$0000, SPR6PTH ($dff138)
	dc.w	$0000,$0132		; MOVE #$0000, SPR4PTL ($dff132)
	dc.w	$0000,$013c		; MOVE #$0000, SPR7PTH ($dff13c)
	dc.w	$0000,$013a		; MOVE #$0000, SPR6PTL ($dff13a)
	dc.w	$0000,$01a0		; MOVE #$0000, COLOR16 ($dff1a0)
	dc.w	$0000,$01a2		; MOVE #$0000, COLOR17 ($dff1a2)
	dc.w	$0777,$01a4		; MOVE #$0777, COLOR18 ($dff1a4)
	dc.w	$0aaa,$01a6		; MOVE #$0AAA, COLOR19 ($dff1a6)
	dc.w	$0fff,$2619		; WAIT VP=$26, HP=$19 ($FFFE mask) -> Wait for raster line $26
	dc.w	$fffe,$0180		; MOVE #$FFFE, COLOR00 ($dff180)
	dc.w	$0f00,$0180		; MOVE #$0F00, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0f00,$0180		; MOVE #$0F00, COLOR00 ($dff180)
	dc.w	$0f00,$0180		; MOVE #$0F00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0000,$2705		; WAIT VP=$27, HP=$05 ($FFFE mask) -> Wait for raster line $27
	dc.w	$fffe,$0180		; MOVE #$FFFE, COLOR00 ($dff180)
	dc.w	$0004,$fe19		; WAIT VP=$FE, HP=$19 ($FFFE mask) -> Wait for raster line $FE
	dc.w	$fffe,$0100		; MOVE #$FFFE, BPLCON0 ($dff100)

copper_template_end:

; ------------------------------------------------------------------------------
; Copperlist Termination Block Template
; ------------------------------------------------------------------------------
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0f00,$0180		; MOVE #$0F00, COLOR00 ($dff180)
	dc.w	$0f00,$0180		; MOVE #$0F00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0e00,$0180		; MOVE #$0E00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0d00,$0180		; MOVE #$0D00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0c00,$0180		; MOVE #$0C00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0b00,$0180		; MOVE #$0B00, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0a00,$0180		; MOVE #$0A00, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0900,$0180		; MOVE #$0900, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0800,$0180		; MOVE #$0800, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0700,$0180		; MOVE #$0700, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0600,$0180		; MOVE #$0600, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0500,$0180		; MOVE #$0500, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0400,$0180		; MOVE #$0400, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0300,$0180		; MOVE #$0300, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0200,$0180		; MOVE #$0200, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0100,$0180		; MOVE #$0100, COLOR00 ($dff180)
	dc.w	$0000,$ffff		; MOVE #$0000, CUSTOM+$1FF ($dff1ff)
	dc.w	$fffe,$0001		; WAIT VP=$00, HP=$01 ($FFFE mask) -> Wait for top scanline
	dc.w	$0000,$000a		; MOVE #$0000, CUSTOM+$00A ($dff00a)

color_index_array:

; ------------------------------------------------------------------------------
; Initial Copper Color Index Table
; ------------------------------------------------------------------------------
	dc.w	$0004,$0004
	dc.w	$0224,$0004
	dc.w	$0446,$0009
	dc.w	$0554,$0009
	dc.w	$0660,$0009
	dc.w	$0880,$0006
	dc.w	$0aa0,$0006
	dc.w	$0cc0,$0006
	dc.w	$0dd0,$0006
	dc.w	$0ee0,$0030
	dc.w	$0ff0,$0006
	dc.w	$0ee0,$0006
	dc.w	$0dd0,$0006
	dc.w	$0cc0,$0003
	dc.w	$0aa0,$0009
	dc.w	$0880,$0009
	dc.w	$0660,$0009
	dc.w	$0554,$0004
	dc.w	$0446,$0004
	dc.w	$0226,$0005
	dc.w	$0006,$ffff
	dc.w	$0000,$001b
	dc.w	$002e,$0019

color_gradient_table_1:
	dc.w	$005c,$0017,$008a,$0015,$00b8,$0013,$00e6,$0011
	dc.w	$0114,$000f,$0142,$000d,$0170,$000b,$019e,$0009
	dc.w	$01cc,$0007,$01fa,$0005,$0228,$0003,$0256,$0001
	dc.w	$0284,$0001,$02b2,$0003,$02e0,$0005,$030e,$0007
	dc.w	$033c,$0009,$036a,$000b,$0398,$000d,$03c6,$000f
	dc.w	$03f4,$0011,$0422,$0013,$0450,$0015,$047e,$0017
	dc.w	$04ac,$0019,$04da,$001b,$0000,$001c,$0000,$001a

; ------------------------------------------------------------------------------
; Raster Bar Color Gradient Wave Table 1
; ------------------------------------------------------------------------------

color_gradient_table_2:
	dc.w	$0000,$0018,$0000,$0016,$0000,$0014,$0000,$0012
	dc.w	$0000,$0010,$0000,$000e,$0000,$000c,$0000,$000a
	dc.w	$0000,$0008,$0000,$0006,$0000,$0004,$0000,$0002
	dc.w	$0000,$0002,$0000,$0004,$0000,$0006,$0000,$0008
	dc.w	$0000,$000a,$0000,$000c,$0000,$000e,$0000,$0010
	dc.w	$0000,$0012,$0000,$0014,$0000,$0016,$0000,$0018
	dc.w	$0000,$001a,$0000,$00

; ------------------------------------------------------------------------------
; Raster Bar Color Gradient Wave Table 2
; ------------------------------------------------------------------------------

topaz_font_name:
	dc.b	"topaz.font",0

graphics_lib_name:
	dc.b	"graphics.library",0

color_palette_table:
	; Primary Color Palette RGB Array
	dc.w	$0000,$8000
	dc.w	$8000,$8000
	dc.w	$8000,$8000
	dc.w	$1edd,$cb7d
	dc.w	$1bb3,$f7f3
	dc.w	$88ab,$bc73

color_table_upper:
	dc.w	$278a,$0e82,$bc3b,$200e,$9149,$efe3,$f169,$ba38
	dc.w	$aeee,$8323,$9b53,$911f,$12b5,$ed8d,$6e57,$e831
	dc.w	$921d,$94b1,$6111,$471a,$44df,$1b5b,$a75d,$6fc7
	dc.w	$7cfc,$6797,$b659,$6966,$cfb0,$9eb3,$4363,$7762
	dc.w	$1377,$253c,$4317,$206a,$5c0f,$a0fe,$ea51,$276b
	dc.w	$0073,$f508,$af30,$9290,$93e2,$49a5,$460f,$a748
	dc.w	$dfca,$5776,$8bab,$ce73,$8cae,$da50

color_table_lower:
	dc.w	$52c8,$1dc3,$5114,$7dea,$834d,$a6c4,$e455,$86b3
	dc.w	$f5b3,$cf01,$3b11,$7958,$bcbb,$3d48,$8824,$1bc4
	dc.w	$2f61,$d4a5,$44aa,$7027,$dfe0,$ba67,$2003,$bfea
	dc.w	$a5b7,$5419,$14c8,$8dbd,$94a3,$4689,$54d9,$9d8d
	dc.w	$02a0,$75c3,$5452,$f586,$83ec,$0816,$ca90,$db16
	dc.w	$eb04,$620d,$ab30

sine_table:

; ------------------------------------------------------------------------------
; Sine Wave Table for Text Raster Bouncing Effect
; ------------------------------------------------------------------------------
	dc.b	$d3,$e8,$53,$a3,$29,$76,$2d,$0f,$a2,$ea,$04,$02,$01,$03,$05,$03
	dc.b	$02,$05,$03,$04,$04,$02

color_index_map_upper:
	dc.b	$04,$03,$04,$03,$04,$03,$03,$02,$05,$04,$02,$04,$02,$03,$02,$04
	dc.b	$04,$02,$03,$03,$01,$02,$05,$01,$01,$03,$04,$04,$01,$05,$03,$05
	dc.b	$05,$05,$04,$05,$02,$02,$03,$01,$03,$03,$05,$02,$05,$02,$01,$05
	dc.b	$04,$03,$01,$04,$03,$01,$05,$02,$04,$04,$05,$05,$03,$03,$03,$02
	dc.b	$05,$03,$05,$03,$05,$03,$05,$01,$05,$04,$01,$05,$05,$05,$03,$02
	dc.b	$01,$03,$03,$04,$04,$03,$02,$05,$05,$03,$03,$01,$03,$00,$04,$03
	dc.b	$01,$01,$02,$04,$02,$05,$05,$02,$02,$04,$02,$05

color_index_map_lower:
	dc.b	$04,$03,$04,$03,$04,$03,$03,$02,$05,$04,$02,$04,$02,$03,$02,$04
	dc.b	$04,$02,$03,$03,$01,$02,$05,$01,$01,$03,$04,$04,$01,$05,$03,$05
	dc.b	$05,$05,$04,$05,$02,$02,$03,$01,$03,$03,$05,$02,$05,$02,$01,$05
	dc.b	$04,$03,$01,$04,$03,$01,$05,$02,$04,$04,$05,$05,$03,$03,$03,$02
	dc.b	$05,$03,$05,$03,$05,$03,$05,$01,$05,$04,$01,$05,$05,$05,$03,$02
	dc.b	$01,$03,$03,$04,$04,$03,$02,$05,$05,$03,$03,$01,$03,$00,$04,$03
	dc.b	$01,$01,$02,$04,$02,$05


; ==============================================================================
; Intro Text Page Display Buffer (Centered Page Layout)
; ==============================================================================

scrolltext:
text_pages:

	; --- Page 1: Main Title ---
	dc.b	"TRISTAR & RED SECTOR PRESENT:",0
	dc.b	"»» T U R R I C A N ««",0
	dc.b	"The 100% - One Disk - Version. !!",0
	dc.b	0

	; --- Page 2: Trainer Options ---
	dc.b	$01,"For The TRAINER Press Joystickbutton",0
	dc.b	"After DeCrunching The Mainpart.",0
	dc.b	"Now You Will Have 99 Lives !!",0
	dc.b	0

	; --- Page 3: End-Part Instructions ---
	dc.b	"For The END-Part Press Left Mousebutton",0
	dc.b	"After DeCrunching The Mainpart.",0
	dc.b	"HiScores Will Be Saved On Track 0 !",0
	dc.b	0,0

	; --- Page 4: Cooperation Boards in Germany ---
	dc.b	"Another QUALITY Production.",0
	dc.b	0,0
	dc.b	"Call Our COOPERATION-Boards In GERMANY:",0
	dc.b	0
	dc.b	"»»       Westpoint       ««",0
	dc.b	"»»   The Black Skyline   ««",0
	dc.b	"»»  Unlimited  Pleasure  ««",0
	dc.b	0
	dc.b	"!! Ask The ELITE For The Numbers !!",0
	dc.b	0,0

	; --- Page 5: International Boards ---
	dc.b	"Or Call One Of Our NON German Boards:",0
	dc.b	0
	dc.b	"»»  Infinity        +41-224-85274   ««",0
	dc.b	"»»  Unity Fields    +31-757-029987  ««",0
	dc.b	"»»  Maximum Overdrive +46-441-26638   ««",0
	dc.b	0

	; --- Page 6: Contact Address - Red Sector ---
	dc.b	"Contact Us If You Dare And Write To:",0
	dc.b	0
	dc.b	"R·E·D S·E·C·T·O·R",0
	dc.b	"======================================",0
	dc.b	"Postbox 138 · 6460 NA Kerkrade · NL",0

	; --- Page 7: Contact Address - Tristar & Credits ---
	dc.b	"T·R·I·S·T·A·R",0
	dc.b	"======================================",0
	dc.b	"Postlagernd · A 4802 Ebensee · Austria",0
	dc.b	0
	dc.b	"PLK 145601E · 4200 Oberhausen 1 · Germany",0
	dc.b	0,0
	dc.b	"Intro Made By TRANSFORMER.",0
	dc.b	0,0
	dc.b	"Back To The Roots",0
	dc.b	$ff

; ------------------------------------------------------------------------------
; Amiga Copper List Data Template
; ------------------------------------------------------------------------------

	even
copper_list:
	dc.w	$00ff,$0000                       	; Custom chip register offset / dummy padding
	dc.w	$0188,$0222                       	; COLOR04 = dark grey (RGB #222)
	dc.w	$018a,$0000                       	; COLOR05 = black (RGB #000)
	dc.w	$018c,$0400                       	; COLOR06 = dark red (RGB #400)
	dc.w	$018e,$0003                       	; COLOR07 = dark blue (RGB #003)
	dc.w	$0180,$0001                       	; COLOR00 = subtle blue (RGB #001)
	dc.w	$0201,$fffe                       	; WAIT scanline 2
	dc.w	$0180,$0002                       	; COLOR00 = RGB #002
	dc.w	$0301,$fffe                       	; WAIT scanline 3
	dc.w	$0180,$0003                       	; COLOR00 = RGB #003
	dc.w	$0401,$fffe                       	; WAIT scanline 4
	dc.w	$0180,$0004                       	; COLOR00 = RGB #004
	dc.w	$0501,$fffe                       	; WAIT scanline 5
	dc.w	$0180,$0005                       	; COLOR00 = RGB #005
	dc.w	$ffff,$fffe                       	; WAIT bottom frame (scanline 255)
	dc.w	$ff01,$fffe                       	; WAIT PAL VBlank start
	dc.w	$009c,$8010                       	; Trigger Level 3 VBlank Interrupt in INTREQ
	dc.w	$0180,$0000                       	; Reset background Color 00 to black
	dc.w	$ffff,$fffe                       	; Copper end halt marker

; ------------------------------------------------------------------------------
; TRSI Trainer Menu & Decruncher Return Handler
; ------------------------------------------------------------------------------

	even
TrainerRoutine:
	lea.l     	$dff000.l,a6                	; Trainer Routine: 99 Lives / Track 0 Highscore setup
	move.w    	#$200,$100(a6)
	bsr.w     	Audio_Init
	move.l    	#$32216,$80(a6)
	clr.w     	$88(a6)
	move.w    	#$83e0,$96(a6)              	; Re-enable Custom Chip DMAs & Jump back to decrunched game
	move.w    	#$e018,$9a(a6)

loc_0f68:
	cmpi.b    	#$5a,$31a25.l
	bne.b     	loc_0f68

loc_0f72:
	move.w    	#$8400,$96(a6)
	bsr.w     	Audio_PlaySound
	bsr.w     	Audio_UpdateTempo
	bsr.w     	Audio_UpdateChannels
	st.b      	$31a48.l

loc_0f8a:
	tst.b     	$31a48.l
	bne.b     	loc_0f8a
	tst.w     	$31a9c.l
	bpl.b     	loc_0f72

loc_0f9a:
	cmpi.l    	#$3103a,$6c.l
	bne.b     	loc_0f9a

loc_0fa6:
	btst.b    	#$7,$bfe001.l
	bne.b     	loc_0fa6
	move.l    	#$100000,d0
	jsr       	Decruncher_Cleanup.l
	jsr       	Decruncher_RestoreHW.l

loc_0fc2:
	tst.w     	(a0)
	bne.b     	loc_0fc2
	move.w    	#$8000,$31a22.l
loc_0fce:
	tst.w     	$31a22.l                    	; Wait for decruncher completion
	bmi.b     	loc_0fce                    	; Loop until decrunching done
	jsr       	Decruncher_GameEntry.l                    	; Jump to Main Game Entry Point ($01BB28)!

; ------------------------------------------------------------------------------
; Uninitialized BSS Workspace Buffer (4144 Bytes)
; ------------------------------------------------------------------------------

bss_buffer:
	ds.b	$1030
