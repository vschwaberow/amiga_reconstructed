; ============================================================================
; trs-da_v1.s
; Fully reconstructed source for Tristar Double Action v1.0 Packer (1988)
; Reverse engineered by Volker Schwaberow <volker@schwaberow.de>
; ============================================================================

ExecBase        EQU     $00000004                      ; Exec library base pointer stored at address 4
ThisTask        EQU     $0114                          ; Task structure offset in ExecBase
LibList         EQU     $017a                          ; Library list offset in ExecBase

; Process offsets
pr_MsgPort      EQU     $005c                          ; Process MsgPort offset
pr_CurrentDir   EQU     $0098                          ; Process CurrentDir lock offset
pr_CLI          EQU     $00ac                          ; Process CLI structure pointer offset
pr_WindowPtr    EQU     $00b8                          ; Process WindowPtr (DOS requester redirection)
sc_ViewPort     EQU     $002c                          ; ViewPort offset in Screen structure

; DOS structure offsets (RootNode, DOSInfo, DeviceList)
dl_Root         EQU     $22                            ; DOSBase: RootNode pointer (BPTR)
rn_Info         EQU     $18                            ; RootNode: DOSInfo pointer (BPTR)
di_DevInfo      EQU     $4                             ; DOSInfo: DeviceList pointer (BPTR)
dol_Type        EQU     $4                             ; DeviceList: Entry type (DLT_DEVICE/DLT_VOLUME)
dol_Name        EQU     $28                            ; DeviceList: BSTR name pointer (BPTR)

; MsgPort offsets
mp_SigTask      EQU     $10                            ; MsgPort: Task to be signaled

; IOStdReq / IORequest offsets
io_ReplyPort    EQU     $0e                            ; IOStdReq: Message reply port pointer
io_Command      EQU     $1c                            ; IOStdReq: Device command
io_Length       EQU     $24                            ; IOStdReq: Transfer length
io_Data         EQU     $28                            ; IOStdReq: Data buffer pointer
io_Offset       EQU     $2c                            ; IOStdReq: Byte offset on device

; IntuiMessage offsets
im_Class        EQU     $14                            ; IntuiMessage: IDCMP message class
im_Code         EQU     $18                            ; IntuiMessage: Menu/Gadget code detail
im_IAddress     EQU     $1c                            ; IntuiMessage: Address associated with message

; Window offsets
wd_UserPort     EQU     $56                            ; Window: IDCMP MsgPort pointer

; InfoData offsets
id_NumBlocks    EQU     $c                             ; InfoData: Number of blocks on disk
id_NumBlocksUsed EQU    $10                            ; InfoData: Number of blocks used
id_BytesPerBlock EQU    $14                            ; InfoData: Bytes per block
id_VolumeNode   EQU     $1c                            ; InfoData: BPTR to Volume DevList node

; FileInfoBlock offsets
fib_Size        EQU     $7c                            ; FileInfoBlock: File size in bytes

; DOS file open modes
MODE_OLDFILE    EQU     1005                           ; Open existing file (read/write, shared lock)
MODE_NEWFILE    EQU     1006                           ; Create new file (overwrite if exists)

; ============================================================================
; Standard Amiga OS library vector offsets (LVOs) & Custom Chip registers
; ============================================================================
CUSTOM          EQU     $dff000                        ; Custom chip base address
CIAB_PRB        EQU     $bfd100                        ; CIA-B Port B Data Register (Floppy select/motor control)
POTGOR          EQU     $dff016                        ; Potentiometer port read register (Right Mouse Button)
INTENA          EQU     $09a                           ; Interrupt enable register
INTREQ          EQU     $09c                           ; Interrupt request register
DMACON          EQU     $096                           ; DMA control register

; Exec Library LVOs
_LVOForbid       EQU     -132                          ; Disable multitasking
_LVOPermit       EQU     -138                          ; Enable multitasking
_LVOAllocMem     EQU     -198                          ; Allocate memory
_LVOFreeMem      EQU     -210                          ; Free memory
_LVOAvailMem     EQU     -216                          ; Get available memory size
_LVOFindTask     EQU     -294                          ; Find a task by name (NULL = current)
_LVOSetTaskPri    EQU     -300                          ; Set task execution priority
_LVOGetMsg       EQU     -372                          ; Get message from port
_LVOReplyMsg     EQU     -378                          ; Reply to message
_LVOWaitPort     EQU     -384                          ; Wait for message on port
_LVOOpenLibrary  EQU     -408                          ; Open a library
_LVOCloseLibrary EQU     -414                          ; Close a library
_LVOFindName     EQU     -276                          ; Search list for node by name
_LVOAddPort      EQU     -354                          ; Add a public message port
_LVORemPort      EQU     -360                          ; Remove a public message port
_LVOOpenDevice   EQU     -444                          ; Open a device driver
_LVOCloseDevice  EQU     -450                          ; Close a device driver
_LVODoIO         EQU     -456                          ; Perform synchronous I/O request

; DOS Library LVOs
_LVODupLock      EQU     -96                           ; Duplicate a directory lock
_LVOCreateProc   EQU     -138                          ; Create a background process
_LVOUnLock       EQU     -90                           ; Release a lock
_LVOUnLoadSeg    EQU     -156                          ; Unload a loaded segment list
_LVOOpen         EQU     -30                           ; Open a file
_LVOClose        EQU     -36                           ; Close a file
_LVORead         EQU     -42                           ; Read bytes from file
_LVOWrite        EQU     -48                           ; Write bytes to file
_LVOInput        EQU     -54                           ; Get standard input handle
_LVODeleteFile   EQU     -72                           ; Delete a file
_LVOLock         EQU     -84                           ; Lock a file or directory
_LVOExamine      EQU     -102                          ; Examine a locked file/directory
_LVOExNext       EQU     -108                          ; Examine next entry in directory
_LVOInfo         EQU     -114                          ; Query disk/floppy information block

; Graphics Library LVOs
_LVOBltBitMap    EQU     -30                           ; Block transfer a bitmap
_LVOMrgCop       EQU     -210                          ; Merge copper lists
_LVOLoadView     EQU     -222                          ; Load a view structure
_LVOMove         EQU     -240                          ; Move graphics drawing pen
_LVODraw         EQU     -246                          ; Draw a line to viewport
_LVOSetRGB4      EQU     -288                          ; Set a color register
_LVOLoadRGB4     EQU     -480                          ; Load color map
_LVOText         EQU     -60                           ; Draw a text string
_LVOSetAPen      EQU     -342                          ; Set foreground drawing pen color
_LVOScrollRaster EQU     -396                          ; Scroll raster area
_LVOSyncSBitMap  EQU     -486                          ; Sync super bitmap

; Intuition Library LVOs
_LVOCloseWindow  EQU     -72                           ; Close a window
_LVOOffMenu      EQU     -180                          ; Disable a menu item
_LVOOnMenu       EQU     -192                          ; Enable a menu item
_LVOOpenScreen   EQU     -198                          ; Open a custom screen
_LVOOpenWindow   EQU     -204                          ; Open a custom window
_LVOSetWindowTitles EQU  -276                          ; Set window/screen titles
_LVOCloseScreen  EQU     -66                           ; Close a custom screen
_LVOClearMenuStrip EQU   -54                           ; Clear menu strip from window
_LVOSetMenuStrip EQU     -264                          ; Attach menu strip to window
_LVOCurrentTime  EQU     -84                           ; Get current system timestamp
_LVODoubleClick  EQU     -102                          ; Test double-click time delta
_LVORefreshGadgets EQU   -222                          ; Refresh window gadgets
_LVOFreeSysRequest EQU   -462                          ; Free system requester window

; mathffp.library LVOs
_LVO_SPFlt      EQU     -36                            ; mathffp.library: Convert integer to float
_LVO_SPFix      EQU     -30                            ; mathffp.library: Convert float to integer
_LVO_SPMul      EQU     -78                            ; mathffp.library: Multiply two floats
_LVO_SPDiv      EQU     -84                            ; mathffp.library: Divide two floats

; ================================================================================
	SECTION Hunk_0_Code, CODE
	OPT O-                                        ; Disable optimization for the decruncher header to match byte size
; ============================================================================
; Function: Bootstrap_Start
; Purpose : Main entry point of the Double Action bootstrap hunk.
; Notes   : Checks CLI/Workbench startup context. If Workbench, waits for and
;           saves the startup message. Then detaches its own segment list from
;           the OS list and spawns a background Process to execute Hunk 1.
; ============================================================================
Bootstrap_Start:
	movea.l  ExecBase.l,a6                                  ; Access ExecBase to invoke Exec library services
	movea.l  ThisTask(a6),a0                                ; Retrieve pointer to the current Process structure
	tst.l    pr_CLI(a0)                                     ; Check if the process was launched from the CLI shell
	bne.b    Bootstrap_CreateBackgroundProcess              ; If CLI-launched, immediately spawn the background worker process
	lea      pr_MsgPort(a0),a0                              ; If Workbench-launched, reference the process message port
	jsr      _LVOWaitPort(a6)                               ; Wait for the Workbench startup message to arrive
	jsr      _LVOGetMsg(a6)                                 ; Retrieve the startup message from the port
	move.l   d0,Var_WBMsg.l                                 ; Cache the Workbench message pointer for later cleanup acknowledgment
	jmp      Bootstrap_CreateBackgroundProcess.l            ; Proceed to create the detached background packer task
; ============================================================================
; Function: Bootstrap_CreateBackgroundProcess
; Purpose : Detaches this executable's segment list from the OS to prevent it
;           from being unloaded when Hunk 0 exits. Then calls CreateProc to spawn
;           Hunk 1 as a background task.
; ============================================================================
Bootstrap_CreateBackgroundProcess:
	lea      Bootstrap_Start(pc),a1                         ; Get current PC-relative program entry address
	move.l   -$4(a1),d3                                     ; Extract the primary segment list (SegList) pointer from hunk header
	move.l   d3,$7e.l                                       ; Save the SegList pointer globally at $7e for access by the worker task
	move.l   #$0,d3                                         ; Prepare to clear the process's own SegList pointer
	subq.l   #$4,d3                                         ; Offset to the process SegList field relative to task
	lsr.l    #$2,d3                                         ; Convert to BPTR (divide by 4)
	clr.l    -$4(a1)                                        ; Zero out the Segment pointer in the current process structure
	                                                        ; This detaches the hunks so the OS loader won't unload Hunk 1 when we exit
	lea      LibList(a6),a0                                 ; Reference the Exec library list
	lea      $39b9.l,a1                                   ; Point a1 at $39b9.l (relocated address of dos.library name string)
	jsr      _LVOFindName(a6)                               ; Search for the dos.library base address in system list
	movea.l  ThisTask(a6),a0                                ; Reload current process structure pointer
	movea.l  d0,a6                                          ; Switch library base register a6 to DOS base
	move.l   pr_CurrentDir(a0),d1                           ; Get the lock handle of the current working directory
	jsr      _LVODupLock(a6)                                ; Duplicate the lock to keep the directory alive for the worker process
	move.l   d0,-(a7)                                       ; Store the duplicated directory lock on stack
	move.l   a6,-(a7)                                       ; Keep the DOS base address on stack
	movea.l  ExecBase.l,a6                                  ; Switch a6 back to ExecBase for task management
	jsr      _LVOForbid(a6)                                 ; Temporarily disable multitasking scheduler for atomic task launch
	movea.l  (a7)+,a6                                       ; Restore DOS base pointer into a6
	move.l   #$4,d1                                         ; Set priority for the new process (priority 4)
	clr.l    d2                                             ; Pass no startup argument SegList (new process has its own entry)
	move.l   #$dac,d4                                       ; Allocate 3500 bytes of stack space for the background process
	jsr      _LVOCreateProc(a6)                             ; Spawn the worker process running Hunk 1 (entry Packer_ProcessEntry)
	movea.l  d0,a0                                          ; Reference the newly created process structure
	move.l   (a7)+,pr_CurrentDir-pr_MsgPort(a0)             ; Assign the duplicated current directory lock to the new process
	movea.l  ExecBase.l,a6                                  ; Reload ExecBase pointer
	jsr      _LVOPermit(a6)                                 ; Restore multitasking scheduler
	moveq    #$0,d0                                         ; Set return code to 0 (Success)
	rts                                                     ; Exit Hunk 0 (Bootstrap finishes)
	dc.b $00
	dc.b $00

; ================================================================================
	SECTION Hunk_1_Code, CODE
; ============================================================================
; Function: Packer_ProcessEntry
; Purpose : Entry point of the background process (Hunk 1).
; ============================================================================
Packer_ProcessEntry:
	bra.w    Process_Start                                ; Jump to Process_Start — Main entry point of the packer execution logic
Str_ProgramWatermark:
	dc.b     "Double_Action v1.0 by VINCE/TRISTAR",0 ; Embedded program identity watermark
; ============================================================================
; Function: Process_Start
; Purpose : Main entry point of the packer execution logic.
; ============================================================================
Process_Start:
	move.l   a7,Var_SavedStack.l                          ; Backup active stack pointer in Var_SavedStack
	bsr.w    Packer_Main                                  ; Call Packer_Main — packer main
; ============================================================================
; Function: Process_CleanupAndExit
; Purpose : Cleans up opened libraries and allocated memory, replies to the
;           Workbench message (if started from WB) or unloads segments (if CLI).
; ============================================================================
Process_CleanupAndExit:
	move.l   Var_WBMsg(pc),d7                             ; Load saved Workbench startup message pointer
	movea.l  Var_SavedStack(pc),a7                        ; Restore stack pointer from Var_SavedStack
	move.w   Var_ErrorCode(pc),d6                         ; Load exit/error code into d6
	ext.l    d6                                           ; Sign-extend d6 to longword
	movea.l  Var_SavedSegList(pc),a4                      ; Load saved segment list pointer
	movea.l  Var_DOSBase(pc),a5                           ; Load dos.library base pointer
	movea.l  ExecBase.l,a6                                  ; Load ExecBase pointer into a6
	tst.l    d7                                           ; Check if Workbench startup message is zero
	beq.b    Exit_CLIPath                                 ; Exit clipath if zero/equal — checked d7
	jsr      _LVOForbid(a6)                               ; Enter critical section: disable multitasking
	movea.l  d7,a1                                        ; Pass d7 as argument in a1
	jsr      _LVOReplyMsg(a6)                             ; Reply to Workbench startup message
	move.l   d6,d0                                        ; Set d6 as return value
	rts                                                   ; Return to caller
Exit_CLIPath:
	movea.l  ThisTask(a6),a0                              ; Load pointer to current Task structure
	move.l   pr_CurrentDir(a0),d1                         ; Get lock of current directory
	movea.l  a5,a6                                        ; Switch library base to a5
	jsr      _LVOUnLock(a6)                               ; Release duplicated directory lock
	move.l   a4,d1                                        ; Copy a4 to d1
	jsr      _LVOUnLoadSeg(a6)                            ; Unload process code segments
	move.l   d6,d0                                        ; Set d6 as return value
	rts                                                   ; Return to caller
Var_SavedStack:
	dc.l     0                              ; Saved stack pointer of the caller process
Var_ErrorCode:
	dc.w     0                              ; Saved return/error code of packer execution
Var_SavedSegList:
	dc.l     0                              ; Saved pointer to the process segment list
Var_WBMsg:
	dc.l     0                              ; Saved Workbench startup message pointer (if started from WB)
Packer_Main:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
; ============================================================================
; Function: Packer_OpenLibs
; Purpose : Opens graphics.library, intuition.library, and dos.library,
;           allocates visual and chunky workspaces, and opens the screen/window.
; ============================================================================
Packer_OpenLibs:
	bsr.w    Func_ClearChunkyBuffer                       ; Call Func_ClearChunkyBuffer — clear chunky buffer
	lea      Str_GfxLibName(pc),a1                        ; Load pointer to "graphics.library" name string
	bsr.w    Func_OpenLibrary                             ; Call Func_OpenLibrary — open library
	lea      Var_GfxBase(pc),a0                           ; Point a0 at graphics.library base
	move.l   d0,(a0)                                      ; Store d0 as graphics.library base
	beq.w    Loc_OpenPacker_Done                          ; Open packer done if zero/equal
	lea      Str_IntuitionLibName(pc),a1                  ; Load pointer to "intuition.library" name string
	bsr.w    Func_OpenLibrary                             ; Call Func_OpenLibrary — open library
	lea      Var_IntuitionBase(pc),a0                     ; Point a0 at intuition.library base
	move.l   d0,(a0)                                      ; Store d0 as intuition.library base
	beq.w    Loc_OpenPacker_ErrorExit                     ; Open packer error exit if zero/equal
	lea      Str_DOSLibName(pc),a1                        ; Load pointer to "dos.library" name string
	bsr.w    Func_OpenLibrary                             ; Call Func_OpenLibrary — open library
	lea      Var_DOSBase(pc),a0                           ; Point a0 at dos.library base
	move.l   d0,(a0)                                      ; Store d0 as dos.library base
	beq.w    Loc_OpenPacker_Exit                          ; Open packer exit if zero/equal
	move.l   #$104,d0                                     ; Load visual workspace allocation size ($104 bytes)
	bsr.w    Func_AllocMem                                ; Allocate memory block from system heap
	lea      Var_FIBPointer(pc),a5                        ; Point a5 at FileInfoBlock buffer
	move.l   d0,(a5)                                      ; Store d0 as FileInfoBlock buffer
	beq.w    Loc_OpenPacker_CleanQuit                     ; Open packer clean quit if zero/equal
	moveq    #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	bsr.w    Func_AllocMem                                ; Allocate memory block from system heap
	lea      Var_ChunkyBuffer40(pc),a5                    ; Point a5 at 40-byte chunky row buffer
	move.l   d0,(a5)                                      ; Store d0 as 40-byte chunky row buffer
	beq.w    Loc_OpenPacker_ErrorWindow                   ; Open packer error window if zero/equal
	move.l   #$3e80,d0                                    ; Load custom screen chunky buffer size ($3e80 bytes)
	bsr.w    Func_AllocMem                                ; Allocate memory block from system heap
	lea      Var_ScreenChunkyBuffer(pc),a5                ; Point a5 at screen chunky pixel buffer
	move.l   d0,(a5)                                      ; Store d0 as screen chunky pixel buffer
	beq.w    Loc_OpenPacker_Success                       ; Open packer success if zero/equal
	move.l   #$438,d0                                     ; Load Copper wait viewport list size ($438 bytes)
	bsr.w    Func_AllocMem                                ; Allocate memory block from system heap
	lea      Var_ViewportBuffer(pc),a5                    ; Point a5 at ViewPort display buffer
	move.l   d0,(a5)                                      ; Store d0 as ViewPort display buffer
	beq.w    Loc_OpenPacker_RetryWindow                   ; Open packer retry window if zero/equal
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	lea      Var_DialogListTitle9(pc),a1                  ; Point a1 at dialog list title9
	jsr      _LVOLoadRGB4(a6)                             ; Load initial color palette map
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_DiskInfo_FIBCyl(pc),a0                   ; Point a0 at disk info fibcyl
	jsr      _LVOOpenScreen(a6)                           ; Open custom screen for the packer UI
	lea      Var_Screen(pc),a0                            ; Point a0 at custom screen handle
	move.l   d0,(a0)                                      ; Store d0 as custom screen handle
	beq.w    Loc_Quit_Finish                              ; Quit finish if zero/equal
	lea      Var_DialogITextPointer(pc),a0                ; Point a0 at dialog itext pointer
	move.l   d0,(a0)                                      ; Save result of _LVOOpenScreen as dialogitextpointer
	lea      Var_DialogWindowTop(pc),a0                   ; Point a0 at dialog window top
	move.l   d0,(a0)                                      ; Save result of _LVOOpenScreen as dialogwindowtop
	lea      Var_ProgressWindowLeft(pc),a0                ; Point a0 at progress window left
	move.l   d0,(a0)                                      ; Save result of _LVOOpenScreen as progresswindowleft
	lea      Var_StatusWindowLeft(pc),a0                  ; Point a0 at status window left
	move.l   d0,(a0)                                      ; Save result of _LVOOpenScreen as statuswindowleft
	lea      Var_Window_WorkTitle(pc),a0                  ; Point a0 at window work title
	move.l   d0,(a0)                                      ; Save result of _LVOOpenScreen as window worktitle
	lea      Var_Window_WorkLeft(pc),a0                   ; Point a0 at window work left
	move.l   d0,(a0)                                      ; Save result of _LVOOpenScreen as window workleft
	movea.l  d0,a0                                        ; Pass result of _LVOOpenScreen in a0
	lea      sc_ViewPort(a0),a0                           ; Get pointer to screen ViewPort structure
	lea      Var_ViewPort(pc),a1                          ; Point a1 at screen ViewPort pointer
	move.l   a0,(a1)                                      ; Store a0 as screen ViewPort pointer
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	lea      Table_Color0(pc),a1                          ; Load custom UI screen color configuration array
	movem.l  (a1)+,d0-d3                                  ; Load color palette index and RGB components (index, red, green, blue) from table
	jsr      _LVOSetRGB4(a6)                              ; Set custom screen color value
	movea.l  Var_ViewPort(pc),a0                          ; Load screen ViewPort pointer into a0
	lea      Table_Color1(pc),a1                          ; Load custom UI screen color configuration array
	movem.l  (a1)+,d0-d3                                  ; Load color palette index and RGB components (index, red, green, blue) from table
	jsr      _LVOSetRGB4(a6)                              ; Set custom screen color value
	movea.l  Var_ViewPort(pc),a0                          ; Load screen ViewPort pointer into a0
	lea      Table_Color3(pc),a1                          ; Load custom UI screen color configuration array
	movem.l  (a1)+,d0-d3                                  ; Load color palette index and RGB components (index, red, green, blue) from table
	jsr      _LVOSetRGB4(a6)                              ; Set custom screen color value
	movea.l  Var_ViewPort(pc),a0                          ; Load screen ViewPort pointer into a0
	lea      Table_Color2(pc),a1                          ; Load custom UI screen color configuration array
	movem.l  (a1)+,d0-d3                                  ; Load color palette index and RGB components (index, red, green, blue) from table
	jsr      _LVOSetRGB4(a6)                              ; Set custom screen color value
	bsr.w    Func_OpenPackerWindow                        ; Open custom packer Window and set active menu strip
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_HandleMenuError                          ; Handle menu error if non-zero/not equal — checked value at (a0)
	bsr.w    Func_MergeCopper                             ; Merge dynamic user Copper lists with hardware display
	bsr.w    Func_ScrollVPort                             ; Scroll the custom screen ViewPort vertically
	bsr.w    Func_MakeVPort                               ; Rebuild active ViewPort copper lists
	lea      Str_SourceDestInfo(pc),a0                    ; Load pointer to "Source:                Destination:" info string
	bsr.w    Func_RenderText                              ; Render specified text string to window RastPort
	bra.w    Loc_DrawMenuOptions                          ; Jump to Loc_DrawMenuOptions — draw menu options
Func_AllocMem:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	move.l   #$10000,d1                                   ; Load MEMF_CHIP allocation flag
	jmp      _LVOAllocMem(a6)                             ; Allocate memory from system heap
; ============================================================================
; Function: Func_UpdateMemoryDisplay
; Purpose : Queries the largest free Chip and Fast memory sizes and updates the
;           packer's visual title/status bar display.
; ============================================================================
Func_UpdateMemoryDisplay:
	movem.l  d0-d7/a0-a6,-(a7)                            ; Save working registers to stack
	move.l   #$20002,d1                                   ; Load MEMF_PUBLIC | MEMF_CLEAR allocation flags
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jsr      _LVOAvailMem(a6)                             ; Query free memory size
	movea.l  d0,a0                                        ; Pass returned pointer in a0
	bsr.w    Func_FormatMemSize                           ; Format raw byte size into KB text representation
	lea      Var_FormattedOutputString(pc),a1             ; Point a1 at formatted numeric output string
	lea      Str_Label_FastMem(pc),a0                     ; Point a0 at label fast mem
Loop_CopyMemoryDisplay:
	move.b   (a1)+,(a0)+                                  ; Copy one byte to destination
	bne.w    Loop_CopyMemoryDisplay                       ; Copy memory display if non-zero/not equal
	move.b   #$20,-(a0)                                   ; Load 32 ($20) into -(a0)
	move.l   #$20004,d1                                   ; Load MEMF_CHIP|MEMF_LARGEST flags into d1
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jsr      _LVOAvailMem(a6)                             ; Query free memory size
	movea.l  d0,a0                                        ; Pass returned pointer in a0
	bsr.w    Func_FormatMemSize                           ; Format raw byte size into KB text representation
	lea      Var_FormattedOutputString(pc),a1             ; Point a1 at formatted numeric output string
	lea      Str_Label_Spaces(pc),a0                      ; Point a0 at label spaces
Loop_CopyMemoryDisplayFast:
	move.b   (a1)+,(a0)+                                  ; Copy one byte to destination
	bne.w    Loop_CopyMemoryDisplayFast                   ; Copy memory display fast if non-zero/not equal
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	suba.l   a1,a1                                        ; Clear a1 to zero (self-subtract)
	lea      Str_ScreenTitle(pc),a2                       ; Point a2 at screen title
	jsr      _LVOSetWindowTitles(a6)                      ; Update screen title bar with formatted memory sizes
	movem.l  (a7)+,d0-d7/a0-a6                            ; Restore registers from stack
	rts                                                   ; Return to caller
; ============================================================================
; Function: Loop_EventMain
; Purpose : The main UI event wait loop. Updates the status displays and waits for
;           Intuition window events.
; ============================================================================
Loop_EventMain:
	bsr.w    Func_UpdateMemoryDisplay                     ; Update real-time free Chip/Fast memory status display
	bsr.w    Func_WaitAndGetMsg                           ; Wait for standard task signal, retrieve and reply to message
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$100,d0                                     ; Compare return value from Func_WaitAndGetMsg against $100 (256)
	beq.w    Event_HandleMessage                          ; Event handle message if zero/equal — d0 vs $100 — checked #$100,d0
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Event_HandleMessage:
	move.w   im_Code(a0),d0                                   ; Load IntuiMessage im_Code field (packed menu details)
	cmp.w    #$ffff,d0                                    ; Check if packed Menu Code is MENUNULL ($ffff)
Loc_Event_DecodeMenuCode:
	beq.w    Loop_EventMain                               ; The main ui event wait loop. updates the status displays and waits for if zero/equal
	move.w   d0,d1                                        ; Copy return value to d1
	andi.w   #$7e0,d1                                     ; Mask d1 with $7e0
	lsr.w    #$5,d1                                       ; Divide d1 by 32 (shift right 5)
	cmp.b    #$0,d1                                       ; Check if d1 equals $0 (0)
	beq.w    Loc_Menu_SubItem_FileActions                 ; Menu sub item file actions if zero/equal — d1 vs $0 — checked #$0,d1
	cmp.b    #$1,d1                                       ; Check if d1 equals $1 (1)
	beq.w    Loc_Menu_SubItem_SaveFile                    ; Menu sub item save file if zero/equal — d1 vs $1 — checked #$1,d1
	cmp.b    #$2,d1                                       ; Check if d1 equals $2 (2)
	beq.w    Loc_Menu_SubItem_Crunch                      ; Menu sub item crunch if zero/equal — d1 vs $2 — checked #$2,d1
	cmp.b    #$3,d1                                       ; Check if d1 equals $3 (3)
	beq.w    Loc_Menu_SubItem_Decrunch                    ; Menu sub item decrunch if zero/equal — d1 vs $3 — checked #$3,d1
	cmp.b    #$4,d1                                       ; Check if d1 equals $4 (4)
	beq.w    Loc_Menu_SubItem_Preferences                 ; Menu sub item preferences if zero/equal — d1 vs $4 — checked #$4,d1
	cmp.b    #$5,d1                                       ; Check if d1 equals $5 (5)
	beq.w    Loc_DrawMenuOptions                          ; Draw menu options if zero/equal — d1 vs $5 — checked #$5,d1
	cmp.b    #$6,d1                                       ; Check if d1 equals $6 (6)
	beq.w    Loc_Menu_SubItem_DiskInfo                    ; Menu sub item disk info if zero/equal — d1 vs $6 — checked #$6,d1
	cmp.b    #$7,d1                                       ; Check if d1 equals $7 (7)
	beq.w    Func_Menu_SubItem_Quit                       ; Menu sub item quit if zero/equal — d1 vs $7 — checked #$7,d1
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Loc_Menu_SubItem_Preferences:
	move.w   d0,d1                                        ; Copy return value to d1
	andi.w   #$f800,d1                                    ; Mask d1 with $f800
	moveq    #$b,d2                                       ; Set d2 to 11 ($b)
	lsr.w    d2,d1                                        ; Shift d1 right by d2 bits
	cmp.b    #$0,d1                                       ; Check if d1 equals $0 (0)
	beq.w    Loc_Pref_FastMemBypass                       ; Pref fast mem bypass if zero/equal — d1 vs $0 — checked #$0,d1
	cmp.b    #$1,d1                                       ; Check if d1 equals $1 (1)
	beq.w    Loc_Pref_RleFilterToggle                     ; Pref rle filter toggle if zero/equal — d1 vs $1 — checked #$1,d1
	cmp.b    #$2,d1                                       ; Check if d1 equals $2 (2)
	beq.w    Loc_Pref_ProStubToggle                       ; Pref pro stub toggle if zero/equal — d1 vs $2 — checked #$2,d1
	cmp.b    #$3,d1                                       ; Check if d1 equals $3 (3)
	beq.w    Loc_Pref_StatusUpdate                        ; Pref status update if zero/equal — d1 vs $3 — checked #$3,d1
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Func_EnableMenuItem:
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	jmp      _LVOOnMenu(a6)                               ; Enable menu items
Func_DisableMenuItem:
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	jmp      _LVOOffMenu(a6)                              ; Disable menu items
Loc_Pref_RleFilterToggle:
	move.w   #$80,d0                                      ; Load packed menu index $80
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$880,d0                                     ; Load packed menu index $880
	bsr.w    Func_DisableMenuItem                         ; Disable GUI interactive menu item via Intuition
	move.w   #$1080,d0                                    ; Load packed menu index $1080
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$1880,d0                                    ; Load packed menu index $1880
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	lea      Var_MenuID_Selected(pc),a0                   ; Point a0 at currently selected menu preference ID
	sf.b     (a0)                                         ; Clear selected menu preference to $00 (false)
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	moveq    #$0,d1                                       ; Clear value 0 to zero
	bra.w    Loop_Pref_ToggleBypass                       ; Jump to Loop_Pref_ToggleBypass — pref toggle bypass
Loc_Pref_ProStubToggle:
	move.w   #$80,d0                                      ; Load packed menu index $80
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$880,d0                                     ; Load packed menu index $880
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$1080,d0                                    ; Load packed menu index $1080
	bsr.w    Func_DisableMenuItem                         ; Disable GUI interactive menu item via Intuition
	move.w   #$1880,d0                                    ; Load packed menu index $1880
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	lea      Var_MenuID_Selected(pc),a0                   ; Point a0 at currently selected menu preference ID
	sf.b     (a0)                                         ; Clear selected menu preference to $00 (false)
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	move.b   #$fd,d1                                      ; Set d1 to 253 ($fd)
	bra.w    Loop_Pref_ToggleBypass                       ; Jump to Loop_Pref_ToggleBypass — pref toggle bypass
Loc_Pref_FastMemBypass:
	move.w   #$80,d0                                      ; Load packed menu index $80
	bsr.w    Func_DisableMenuItem                         ; Disable GUI interactive menu item via Intuition
	move.w   #$880,d0                                     ; Load packed menu index $880
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$1080,d0                                    ; Load packed menu index $1080
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$1880,d0                                    ; Load packed menu index $1880
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	lea      Var_MenuID_Selected(pc),a0                   ; Point a0 at currently selected menu preference ID
	sf.b     (a0)                                         ; Clear selected menu preference to $00 (false)
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	moveq    #$3,d1                                       ; Set priority/parameter to 3 in d1
Loop_Pref_ToggleBypass:
	movea.l  d0,a1                                        ; Pass d0 as argument in a1
	move.l   d1,d0                                        ; Copy d1 to d0
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jsr      _LVOSetTaskPri(a6)                           ; Apply selected priority setting to task execution
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Func_GetThisTask:
	suba.l   a1,a1                                        ; Clear a1 to zero (self-subtract)
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jsr      _LVOFindTask(a6)                             ; Find current task structure
	rts                                                   ; Return to caller
Loc_Pref_StatusUpdate:
	lea      Var_MenuID_Selected(pc),a0                   ; Point a0 at currently selected menu preference ID
	st.b     (a0)                                         ; Set selected menu preference to $FF (true)
	move.w   #$80,d0                                      ; Load packed menu index $80
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$880,d0                                     ; Load packed menu index $880
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$1080,d0                                    ; Load packed menu index $1080
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	move.w   #$1880,d0                                    ; Load packed menu index $1880
	bsr.w    Func_DisableMenuItem                         ; Disable GUI interactive menu item via Intuition
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	moveq    #$0,d1                                       ; Clear value 0 to zero
	bra.w    Loop_Pref_ToggleBypass                       ; Jump to Loop_Pref_ToggleBypass — pref toggle bypass
Loc_Menu_SubItem_FileActions:
	move.w   d0,d1                                        ; Save Func_GetThisTask result in d1
	andi.w   #$f800,d1                                    ; Mask d1 with $f800
	moveq    #$b,d2                                       ; Set d2 to 11 ($b)
	lsr.w    d2,d1                                        ; Shift d1 right by d2 bits
	cmp.b    #$0,d1                                       ; Check if d1 equals $0 (0)
	beq.w    Loc_Pref_ToggleMenuState                     ; Pref toggle menu state if zero/equal — d1 vs $0 — checked #$0,d1
	cmp.b    #$1,d1                                       ; Check if d1 equals $1 (1)
	beq.w    Loc_Menu_Done                                ; Menu done if zero/equal — d1 vs $1 — checked #$1,d1
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Loc_Pref_ToggleMenuState:
	lea      Str_Dialog_LoadFile(pc),a0                   ; Point a0 at dialog load file
	bsr.w    Func_OpenDialogAndSetMenu                    ; Call Func_OpenDialogAndSetMenu — open dialog and set menu
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_EventMain                               ; The main ui event wait loop. updates the status displays and waits for if non-zero/not equal — checked value at (a0)
	bsr.w    Func_StartCrunchingUI                        ; Call Func_StartCrunchingUI — start crunching ui
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Loc_Menu_SubItem_SaveFile:
	move.l   Var_PayloadBuffer(pc),d1                     ; Load packed/unpacked file data buffer into d1
	beq.w    Loc_Menu_CrunchDone                          ; Menu crunch done if zero/equal
	move.l   d0,-(a7)                                     ; Save d0 on stack
	lea      Var_DiskInfo_FreeSectors(pc),a1              ; Point a1 at disk info free sectors
	bsr.w    Func_CopyHeaderData                          ; Call Func_CopyHeaderData — copy header data
	lea      Var_DiskInfo_FIBEnd(pc),a1                   ; Point a1 at disk info fibend
	bsr.w    Func_CopyHeaderData                          ; Call Func_CopyHeaderData — copy header data
	lea      Var_DiskInfo_FIBTime(pc),a1                  ; Point a1 at disk info fibtime
	bsr.w    Func_CopyHeaderData                          ; Call Func_CopyHeaderData — copy header data
	move.l   (a7)+,d1                                     ; Restore d1 from stack
	andi.w   #$f800,d1                                    ; Mask d1 with $f800
	moveq    #$b,d2                                       ; Set d2 to 11 ($b)
	lsr.w    d2,d1                                        ; Shift d1 right by d2 bits
	cmp.b    #$0,d1                                       ; Check if d1 equals $0 (0)
	beq.w    Loc_Menu_PreferencesDone                     ; Menu preferences done if zero/equal — d1 vs $0 — checked #$0,d1
	cmp.b    #$1,d1                                       ; Check if d1 equals $1 (1)
	beq.w    Loc_InitDisk_Retry                           ; Init disk retry if zero/equal — d1 vs $1 — checked #$1,d1
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Loc_Menu_PreferencesDone:
	bsr.w    Func_StartSaveFileUI                         ; Call Func_StartSaveFileUI — start save file ui
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Loc_Menu_Done:
	moveq    #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply value 63 by 32 (shift left 5)
	bsr.w    Func_DisableMenuItem                         ; Disable GUI interactive menu item via Intuition
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	move.l   #$400,d0                                     ; Set d0 to 1024 ($400)
	move.l   #$10002,d1                                   ; Load MEMF_CHIP|MEMF_CLEAR flags into d1
	jsr      _LVOOpenScreen(a6)                           ; Open custom screen for the packer UI
	lea      Var_FloppyDataBuffer(pc),a0                  ; Point a0 at floppy disk I/O data buffer
	move.l   d0,(a0)                                      ; Store d0 as floppy disk I/O data buffer
	beq.w    Loop_Init_MenuState                          ; Init menu state if zero/equal
	bsr.w    Func_InitializeMainState                     ; Call Func_InitializeMainState — initialize main state
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_FloppyDataBuffer(pc),a1                  ; Load floppy disk I/O data buffer into a1
	move.l   #$400,d0                                     ; Set d0 to 1024 ($400)
	jsr      _LVOFreeMem(a6)                                     ; Free previously allocated memory block (_LVOFreeMem)
Loop_Init_MenuState:
	moveq    #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply value 63 by 32 (shift left 5)
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Func_InitializeMainState:
	bsr.w    Func_OpenStatusWindow                        ; Call Func_OpenStatusWindow — open status window
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_Status_ErrorReturn                       ; Status error return if non-zero/not equal — checked value at (a0)
	bsr.w    Func_OpenAndHandleStatus                     ; Call Func_OpenAndHandleStatus — open and handle status
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	bsr.w    Func_CloseStatusWindow                       ; Call Func_CloseStatusWindow — close status window
	lea      Var_PayloadSize(pc),a0                       ; Point a0 at current payload data size
	clr.l    (a0)                                         ; Clear current payload data size to zero
	move.l   Var_PayloadBuffer(pc),d0                     ; Load packed/unpacked file data buffer into d0
	beq.w    Loc_Init_SetAPen                             ; Init set apen if zero/equal
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
Loc_Init_SetAPen:
	lea      Var_ProgressWindowTop(pc),a0                 ; Point a0 at progress window top
	move.w   #$100,$c(a0)                                 ; Write $100 to offset $c(a0)
	lea      Var_OperationCancelledFlag(pc),a0            ; Point a0 at user cancellation flag
	sf.b     (a0)                                         ; Clear cancellation flag to $00 (false)
	bsr.w    Func_OpenProgressWindow                      ; Call Func_OpenProgressWindow — open progress window
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_Status_ErrorReturn                       ; Status error return if non-zero/not equal — checked value at (a0)
	bsr.w    Func_HandleStatusProgress                    ; Call Func_HandleStatusProgress — handle status progress
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	bsr.w    Func_CloseProgressWindow                     ; Call Func_CloseProgressWindow — close progress window
	move.l   Var_FloppyRemainingBytes(pc),d0              ; Load remaining bytes to read from disk into d0
	add.l    Var_DirectoryEntryBuffer(pc),d0              ; Add directory entry buffer to d0
	bsr.w    Func_OpenCustomScreen                        ; Call Func_OpenCustomScreen — open custom screen
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_Status_ErrorReturn                       ; Status error return if non-zero/not equal — checked value at (a0)
	move.l   Var_PayloadBufferSize(pc),d1                 ; Load allocated payload buffer size into d1
	move.l   Var_PayloadBuffer(pc),d0                     ; Load packed/unpacked file data buffer into d0
	add.l    d0,d1                                        ; Add d0 to d1
	lea      Var_TempLong(pc),a0                          ; Point a0 at temporary longword workspace
	move.l   d1,(a0)                                      ; Store d1 as temporary longword workspace
	move.l   Var_DirectoryEntryBuffer(pc),d1              ; Load directory entry buffer into d1
	add.l    d1,d0                                        ; Add d1 to d0
	lea      Var_UnusedWorkspace(pc),a0                   ; Point a0 at workspace end pointer
	move.l   d0,(a0)                                      ; Store d0 as workspace end pointer
	bsr.w    Func_OpenDiskDevice                          ; Call Func_OpenDiskDevice — open disk device
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	bra.w    Loc_StartCrunching_PrintStopPrompt           ; Jump to Loc_StartCrunching_PrintStopPrompt — start crunching print stop prompt
Func_OpenDiskDevice:
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	lea      Var_FloppyMsgPort(pc),a1                     ; Point a1 at floppy device message port
	move.l   d0,mp_SigTask(a1)                            ; Set mp_SigTask (signal task) to d0
	jsr      _LVOAddPort(a6)                              ; AddPort — add message port to system list
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	move.l   Var_DiskUnit(pc),d0                          ; Load disk unit number (DF0-DF3) into d0
	moveq    #$0,d1                                       ; Clear value 0 to zero
	lea      Str_TrackdiskDevice(pc),a0                   ; Load pointer to "trackdisk.device" name string
	jsr      _LVOOpenDevice(a6)                           ; OpenDevice — open trackdisk.device
	tst.l    d0                                           ; Check if OpenDevice succeeded
	bne.w    Loc_DiskIO_ErrorReturn                       ; Branch if OpenDevice failed
	move.l   Var_FloppyRemainingBytes(pc),d0              ; Load remaining bytes to read from disk into d0
	clr.l    d1                                           ; Clear d1
	move.w   d0,d1                                        ; Copy remaining bytes to read to d1
	clr.w    d0                                           ; Clear remaining bytes to read to zero
	swap     d0                                           ; Swap high/low words of d0
	mulu.w   #$40,d0                                      ; Multiply d0 by 64 ($40)
	divu.w   #$400,d1                                     ; Divide d1 by 1024 ($400)
	clr.l    d2                                           ; Zero d2
	move.w   d1,d2                                        ; Copy sector count to d2
	add.l    d2,d0                                        ; Add d2 to d0
	lea      Var_FloppyTotalSize(pc),a0                   ; Point a0 at total floppy sectors to transfer
	move.l   d0,(a0)                                      ; Store d0 as total floppy sectors to transfer
	clr.w    d1                                           ; Clear value 0 to zero
	swap     d1                                           ; Swap high/low words of d1
	lea      Var_FloppyIOSize(pc),a0                      ; Point a0 at floppy I/O transfer size
	move.l   d1,(a0)                                      ; Store d1 as floppy I/O transfer size
	lea      Var_FloppyBufferEnd(pc),a0                   ; Point a0 at end-of-buffer write cursor
	move.l   Var_UnusedWorkspace(pc),(a0)                 ; Load workspace end pointer into (a0)
	tst.l    d0                                           ; Check if remaining bytes to read is zero
	beq.w    Loc_InitDisk_Done                            ; Skip if done
Loop_InitDisk_RetryIO:
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	lea      Var_FloppyMsgPort(pc),a2                     ; Point a2 at floppy device message port
	move.l   a2,io_ReplyPort(a1)                          ; Set reply message port pointer
	move.w   #$2,io_Command(a1)                           ; Set floppy IO command to CMD_READ (2)
	move.l   Var_FloppyDataBuffer(pc),io_Data(a1)         ; Load floppy data buffer pointer
	move.l   #$400,io_Length(a1)                          ; Set buffer size to 1024 bytes
	move.l   Var_FloppyIOOffset(pc),io_Offset(a1)         ; Load floppy disk I/O offset
	lea      Var_FloppyIOOffset(pc),a0                    ; Point a0 at current floppy disk byte offset
	addi.l   #$400,(a0)                                   ; Advance offset by 1024 bytes
	jsr      _LVODoIO(a6)                                 ; DoIO — perform synchronous I/O request
	movea.l  Var_FloppyBufferEnd(pc),a1                   ; Load end-of-buffer write cursor into a1
	movea.l  Var_FloppyDataBuffer(pc),a0                  ; Load floppy disk I/O data buffer into a0
	move.w   #$3ff,d0                                     ; Set loop counter to 1023 (1024 bytes)
Loop_InitDisk_Delay:
	move.b   (a0)+,(a1)+                                  ; Copy one byte from floppy buffer to workspace
	dbra     d0,Loop_InitDisk_Delay                       ; Continue until all 1024 bytes are copied
	lea      Var_FloppyBufferEnd(pc),a0                   ; Point a0 at end-of-buffer write cursor
	move.l   a1,(a0)                                      ; Store updated end-of-buffer cursor
	lea      Var_FloppyTotalSize(pc),a0                   ; Point a0 at total floppy sectors to transfer
	subq.l   #$1,(a0)                                     ; Decrement remaining sector count
	bne.w    Loop_InitDisk_RetryIO                        ; Repeat if remaining sector count is non-zero
Loc_InitDisk_Done:
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	lea      Var_FloppyMsgPort(pc),a2                     ; Point a2 at floppy device message port
	move.l   a2,io_ReplyPort(a1)                          ; Set reply message port pointer
	move.w   #$2,io_Command(a1)                           ; Set floppy IO command to CMD_READ (2)
	move.l   Var_FloppyDataBuffer(pc),io_Data(a1)         ; Load floppy data buffer pointer
	move.l   Var_FloppyIOSize(pc),io_Length(a1)           ; Load final partial I/O transfer size
	move.l   Var_FloppyIOOffset(pc),io_Offset(a1)         ; Load floppy disk I/O offset
	jsr      _LVODoIO(a6)                                 ; DoIO — perform synchronous I/O request
	movea.l  Var_FloppyBufferEnd(pc),a1                   ; Load end-of-buffer write cursor into a1
	movea.l  Var_FloppyDataBuffer(pc),a0                  ; Load floppy disk I/O data buffer into a0
	move.l   Var_FloppyIOSize(pc),d0                      ; Load final partial transfer size into d0
	beq.w    Loc_InitDisk_WaitMotor                       ; Skip copying if partial size is zero
Loop_InitDisk_VerifyMotor:
	move.b   (a0)+,(a1)+                                  ; Copy one byte from floppy buffer to workspace
	subq.w   #$1,d0                                       ; Count down remaining bytes
	bne.b    Loop_InitDisk_VerifyMotor                    ; Continue copying remaining bytes
Loc_InitDisk_WaitMotor:
	bsr.w    Func_TurnFloppyMotorOff                      ; Turn drive motor off
	lea      Var_FloppyMsgPort(pc),a1                     ; Point a1 at floppy device message port
	jsr      _LVORemPort(a6)                              ; Remove message port from system list
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	jsr      _LVOCloseDevice(a6)                          ; Close trackdisk.device
	bra.w    Loop_ClearStatusError                        ; Jump back to UI main loop
Loc_InitDisk_Retry:
	moveq    #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply value 63 by 32 (shift left 5)
	bsr.w    Func_DisableMenuItem                         ; Disable GUI interactive menu item via Intuition
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	move.l   #$400,d0                                     ; Set d0 to 1024 ($400)
	move.l   #$10002,d1                                   ; Load MEMF_CHIP|MEMF_CLEAR flags into d1
	jsr      _LVOOpenScreen(a6)                           ; Open custom screen for the packer UI
	lea      Var_FloppyDataBuffer(pc),a0                  ; Point a0 at floppy disk I/O data buffer
	move.l   d0,(a0)                                      ; Store d0 as floppy disk I/O data buffer
	beq.w    Loop_Init_MenuState                          ; Init menu state if zero/equal
	bsr.w    Func_ReadDiskTracks                          ; Call Func_ReadDiskTracks — read disk tracks
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_FloppyDataBuffer(pc),a1                  ; Load floppy disk I/O data buffer into a1
	move.l   #$400,d0                                     ; Set d0 to 1024 ($400)
	jsr      _LVOFreeMem(a6)                                     ; Free previously allocated memory block (_LVOFreeMem)
	moveq    #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply value 63 by 32 (shift left 5)
	bsr.w    Func_EnableMenuItem                          ; Enable GUI interactive menu item via Intuition
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Func_ReadDiskTracks:
	bsr.w    Func_OpenDiskInfoWindow                      ; Call Func_OpenDiskInfoWindow — open disk info window
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_Status_ErrorReturn                       ; Status error return if non-zero/not equal — checked value at (a0)
	bsr.w    Func_OpenAndHandleDiskInfo                   ; Call Func_OpenAndHandleDiskInfo — open and handle disk info
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	bsr.w    Func_CloseDiskInfoWindow                     ; Call Func_CloseDiskInfoWindow — close disk info window
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	lea      Var_FloppyMsgPort(pc),a1                     ; Point a1 at floppy device message port
	move.l   d0,mp_SigTask(a1)                            ; Set mp_SigTask (signal task) to d0
	jsr      _LVOAddPort(a6)                              ; AddPort — add message port to system list
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	move.l   Var_DiskUnit(pc),d0                          ; Load disk unit number (DF0-DF3) into d0
	moveq    #$0,d1                                       ; Clear value 0 to zero
	lea      Str_TrackdiskDevice(pc),a0                   ; Load pointer to "trackdisk.device" name string
	jsr      _LVOOpenDevice(a6)                           ; OpenDevice — open trackdisk.device
	tst.l    d0                                           ; Check if OpenDevice succeeded
	bne.w    Loc_DiskIO_ErrorReturn                       ; Branch if OpenDevice failed
	move.l   Var_PayloadSize(pc),d0                       ; Load current payload data size into d0
	cmp.l    #$181,d0                                     ; Check if d0 equals $181 (385)
	bls.w    Loc_ReadDisk_CopyRest                        ; Read disk copy rest if unsigned lower or same — checked #$181,d0
	cmp.l    #$701,d0                                     ; Check if d0 equals $701 (1793)
	bls.w    Loc_ReadDisk_WriteBuffer                     ; Read disk write buffer if unsigned lower or same — checked #$701,d0
	cmp.l    #$1501,d0                                    ; Check if d0 equals $1501 (5377)
	bls.w    Loc_ReadDisk_SkipMotor                       ; Read disk skip motor if unsigned lower or same — checked #$1501,d0
	bra.w    Loc_ReadDisk_LoopTracks                      ; Jump to Loc_ReadDisk_LoopTracks — read disk loop tracks
Loc_ReadDisk_SkipMotor:
	move.l   #Loc_Event_DecodeMenuCode,d0                 ; Load address of Loc_Event_DecodeMenuCode into d0
	lea      Var_FloppyDriveStatus(pc),a0                 ; Point a0 at floppy drive status flags
	move.l   Var_DirectoryEntrySize(pc),d1                ; Load directory entry data size into d1
	sub.l    Var_DirectoryEntryComment(pc),d1             ; Subtract directory entry comment string from d1
	lea      Var_FloppyRemainingBytes(pc),a1              ; Point a1 at remaining bytes to read from disk
	move.l   d1,(a1)                                      ; Store d1 as remaining bytes to read from disk
	bsr.w    Func_BufferDiskData                          ; Call Func_BufferDiskData — buffer disk data
Loop_ReadDisk_Tracks:
	bsr.w    Func_TurnFloppyMotorOff                      ; Turn floppy motor off
	lea      Var_FloppyMsgPort(pc),a1                     ; Point a1 at floppy device message port
	jsr      _LVORemPort(a6)                              ; Remove message port from system list
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	jsr      _LVOCloseDevice(a6)                          ; Close device driver
	bra.w    Func_FreePayloadBuffer                       ; Free payload buffer
Func_TurnFloppyMotorOff:
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	move.w   #$9,io_Command(a1)                           ; Set floppy IO command to CMD_MOTOR (9) (Turn drive motor on/off)
	clr.l    io_Length(a1)                                ; Clear io_Length (transfer length) to zero
	jmp      _LVODoIO(a6)                                 ; DoIO — perform synchronous I/O request
Func_BufferDiskData:
	movea.l  Var_FloppyDataBuffer(pc),a1                  ; Load floppy disk I/O data buffer into a1
	move.l   d0,d2                                        ; Copy return value to d2
Loop_BufferDisk_Copy:
	move.b   (a0)+,(a1)+                                  ; Copy one byte to destination
	subq.l   #$1,d2                                       ; Decrement d2 by one
	bne.b    Loop_BufferDisk_Copy                         ; Buffer disk copy if non-zero/not equal — checked counter after subq.l
	move.l   #$400,d1                                     ; Set d1 to 1024 ($400)
	lea      Var_FloppyIOSize(pc),a2                      ; Point a2 at floppy I/O transfer size
	move.l   d1,(a2)                                      ; Store d1 as floppy I/O transfer size
	sub.l    d0,d1                                        ; Subtract d0 from d1
	move.l   Var_PayloadBuffer(pc),d0                     ; Load packed/unpacked file data buffer into d0
	movea.l  d0,a0                                        ; Pass file data buffer in a0
	add.l    d1,d0                                        ; Add d1 to d0
	lea      Var_FloppyBufferEnd(pc),a2                   ; Point a2 at end-of-buffer write cursor
	move.l   d0,(a2)                                      ; Store d0 as end-of-buffer write cursor
	move.l   d1,d0                                        ; Copy d1 to d0
Loop_BufferDisk_Wait:
	move.b   (a0)+,(a1)+                                  ; Copy next byte from source to destination
	subq.w   #$1,d1                                       ; Decrement d1 by one
	bne.b    Loop_BufferDisk_Wait                         ; Buffer disk wait if non-zero/not equal — checked counter after subq.w
	lea      Var_FloppyRemainingBytes(pc),a2              ; Point a2 at remaining bytes to read from disk
	sub.l    d0,(a2)                                      ; Subtract d0 from (a2)
	bcs.w    Func_WriteFloppyTrack                        ; Write floppy track if carry set (less than / lower)
	bsr.w    Func_WriteFloppyTrack                        ; Call Func_WriteFloppyTrack — write floppy track
	move.l   Var_FloppyRemainingBytes(pc),d0              ; Load remaining bytes to read from disk into d0
	clr.l    d1                                           ; Clear d1 (second parameter)
	move.w   d0,d1                                        ; Save Func_WriteFloppyTrack result in d1
	divu.w   #$400,d1                                     ; Divide d1 by 1024 ($400)
	clr.w    d0                                           ; Clear remaining bytes to read to zero
	swap     d0                                           ; Swap high/low words of d0
	mulu.w   #$40,d0                                      ; Multiply d0 by 64 ($40)
	clr.l    d2                                           ; Zero d2
	move.w   d1,d2                                        ; Copy d1 to d2
	add.l    d2,d0                                        ; Add d2 to d0
	lea      Var_FloppyTotalSize(pc),a0                   ; Point a0 at total floppy sectors to transfer
	move.l   d0,(a0)                                      ; Store d0 as total floppy sectors to transfer
	clr.w    d1                                           ; Clear d1 (second parameter)
	swap     d1                                           ; Swap high/low words of d1
	lea      Var_FloppyIOSize(pc),a0                      ; Point a0 at floppy I/O transfer size
	move.l   d1,(a0)                                      ; Store d1 as floppy I/O transfer size
	beq.w    Loop_DiskIO_Retry                            ; Disk io retry if zero/equal
	cmp.l    #$200,d1                                     ; Check if d1 equals $200 (512)
	bhi.w    Loc_DoDiskIO_SetFlag                         ; Do disk io set flag if unsigned greater — checked #$200,d1
	move.l   #$200,(a0)                                   ; Load 512 ($200) into (a0)
Loop_DiskIO_Retry:
	tst.l    d0                                           ; Test d0 for zero
	beq.w    Loc_ReadDisk_Retry                           ; Read disk retry if zero/equal — checked d0
Loop_DiskIO_Delay:
	movea.l  Var_FloppyBufferEnd(pc),a0                   ; Load end-of-buffer write cursor into a0
	movea.l  Var_FloppyDataBuffer(pc),a1                  ; Load floppy disk I/O data buffer into a1
	move.w   #$3ff,d0                                     ; Set d0 to 1023 ($3ff)
Loop_DiskIO_Wait:
	move.b   (a0)+,(a1)+                                  ; Copy next byte from source to destination
	dbra     d0,Loop_DiskIO_Wait                          ; Decrement d0 and loop to Loop_DiskIO_Wait until done
	lea      Var_FloppyBufferEnd(pc),a1                   ; Point a1 at end-of-buffer write cursor
	move.l   a0,(a1)                                      ; Store a0 as end-of-buffer write cursor
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	lea      Var_FloppyMsgPort(pc),a2                     ; Point a2 at floppy device message port
	move.l   a2,io_ReplyPort(a1)                          ; Set io_MsgPort (reply port) to a2
	move.w   #$3,io_Command(a1)                           ; Set floppy IO command to CMD_WRITE (3)
	move.l   Var_FloppyDataBuffer(pc),io_Data(a1)         ; Load floppy data buffer pointer into io_Data(a1)
	move.l   #$400,io_Length(a1)                          ; Set buffer/allocation size to 1024 bytes ($400)
	move.l   Var_FloppyIOOffset(pc),io_Offset(a1)         ; Load floppy disk I/O offset into io_Offset(a1)
	lea      Var_FloppyIOOffset(pc),a0                    ; Point a0 at current floppy disk byte offset
	addi.l   #$400,(a0)                                   ; Add 1024 ($400) to (a0)
	jsr      _LVODoIO(a6)                                 ; DoIO — perform synchronous I/O request
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	lea      Var_FloppyTotalSize(pc),a0                   ; Point a0 at total floppy sectors to transfer
	subq.l   #$1,(a0)                                     ; Decrement (a0) by one
	bne.w    Loop_DiskIO_Delay                            ; Disk io delay if non-zero/not equal — checked counter after subq.l
Loc_ReadDisk_Retry:
	move.l   Var_FloppyIOSize(pc),d0                      ; Load floppy I/O transfer size into d0
	beq.w    Loc_DoDiskIO_Write                           ; Do disk io write if zero/equal
	movea.l  Var_FloppyBufferEnd(pc),a0                   ; Load end-of-buffer write cursor into a0
	movea.l  Var_FloppyDataBuffer(pc),a1                  ; Load floppy disk I/O data buffer into a1
Loop_DoDiskIO_Done:
	move.b   (a0)+,(a1)+                                  ; Copy next byte from source to destination
	subq.w   #$1,d0                                       ; Decrement d0 by one
	bne.b    Loop_DoDiskIO_Done                           ; Do disk io done if non-zero/not equal — checked counter after subq.w
Func_WriteFloppyTrack:
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	lea      Var_FloppyMsgPort(pc),a2                     ; Point a2 at floppy device message port
	move.l   a2,io_ReplyPort(a1)                          ; Set io_MsgPort (reply port) to a2
	move.w   #$3,io_Command(a1)                           ; Set floppy IO command to CMD_WRITE (3)
	move.l   Var_FloppyDataBuffer(pc),io_Data(a1)         ; Load floppy data buffer pointer into io_Data(a1)
	move.l   Var_FloppyIOSize(pc),io_Length(a1)           ; Load floppy I/O transfer size into io_Length(a1)
	move.l   Var_FloppyIOOffset(pc),io_Offset(a1)         ; Load floppy disk I/O offset into io_Offset(a1)
	jsr      _LVODoIO(a6)                                 ; DoIO — perform synchronous I/O request
	lea      Var_FloppyIOOffset(pc),a0                    ; Point a0 at current floppy disk byte offset
	addi.l   #$400,(a0)                                   ; Add 1024 ($400) to (a0)
Loc_DoDiskIO_Write:
	lea      Var_FloppyIOReq(pc),a1                       ; Point a1 at floppy I/O request structure
	lea      Var_FloppyMsgPort(pc),a2                     ; Point a2 at floppy device message port
	move.l   a2,io_ReplyPort(a1)                          ; Set io_MsgPort (reply port) to a2
	move.w   #$4,io_Command(a1)                           ; Write $4 to offset io_Command(a1)
	jmp      _LVODoIO(a6)                                 ; DoIO — perform synchronous I/O request
Loc_DoDiskIO_SetFlag:
	move.l   #$400,(a0)                                   ; Set buffer/allocation size to 1024 bytes ($400)
	bra.w    Loop_DiskIO_Retry                            ; Jump to Loop_DiskIO_Retry — disk io retry
Loc_ReadDisk_CopyRest:
	move.l   #$24e,d0                                     ; Set d0 to 590 ($24e)
	lea      Var_DirectoryEntryPath(pc),a0                ; Point a0 at directory entry path
	move.l   Var_DiskInfo_UsedSectors(pc),d1              ; Load disk info used sectors into d1
	sub.l    Var_DiskInfo_BytesPerSector(pc),d1           ; Subtract Var_DiskInfo_BytesPerSector from d1
	lea      Var_FloppyRemainingBytes(pc),a1              ; Point a1 at remaining bytes to read from disk
	move.l   d1,(a1)                                      ; Store d1 as remaining bytes to read from disk
	bsr.w    Func_BufferDiskData                          ; Call Func_BufferDiskData — buffer disk data
	bra.w    Loop_ReadDisk_Tracks                         ; Jump to Loop_ReadDisk_Tracks — read disk tracks
Loc_ReadDisk_WriteBuffer:
	move.l   #$24e,d0                                     ; Set d0 to 590 ($24e)
	lea      Var_DirectoryEntryPath(pc),a0                ; Point a0 at directory entry path
	move.l   Var_DiskInfo_UsedSectors(pc),d1              ; Load disk info used sectors into d1
	sub.l    Var_DiskInfo_BytesPerSector(pc),d1           ; Subtract Var_DiskInfo_BytesPerSector from d1
	lea      Var_FloppyRemainingBytes(pc),a1              ; Point a1 at remaining bytes to read from disk
	move.l   d1,(a1)                                      ; Store d1 as remaining bytes to read from disk
	bsr.w    Func_BufferDiskData                          ; Call Func_BufferDiskData — buffer disk data
	bra.w    Loop_ReadDisk_Tracks                         ; Jump to Loop_ReadDisk_Tracks — read disk tracks
Loc_ReadDisk_LoopTracks:
	move.l   #$24e,d0                                     ; Set d0 to 590 ($24e)
	lea      Var_DirectoryEntryPath(pc),a0                ; Point a0 at directory entry path
	move.l   Var_DiskInfo_UsedSectors(pc),d1              ; Load disk info used sectors into d1
	sub.l    Var_DiskInfo_BytesPerSector(pc),d1           ; Subtract Var_DiskInfo_BytesPerSector from d1
	lea      Var_FloppyRemainingBytes(pc),a1              ; Point a1 at remaining bytes to read from disk
	move.l   d1,(a1)                                      ; Store d1 as remaining bytes to read from disk
	bsr.w    Func_BufferDiskData                          ; Call Func_BufferDiskData — buffer disk data
	bra.w    Loop_ReadDisk_Tracks                         ; Jump to Loop_ReadDisk_Tracks — read disk tracks
Func_CopyHeaderData:
	lea      Var_DirectoryEntryHeader(pc),a0              ; Point a0 at directory entry header pointer
	move.w   #$21,d0                                      ; Set d0 to 33 ($21)
Loop_CopyHeaderData:
	move.b   (a0)+,(a1)+                                  ; Copy one byte to destination
	dbra     d0,Loop_CopyHeaderData                       ; Decrement d0 and loop to Loop_CopyHeaderData until done
	rts                                                   ; Return to caller
Loc_Menu_CrunchDone:
	lea      Str_BufferIsEmptyRightNow(pc),a0             ; Point a0 at buffer is empty right now
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Loc_Menu_SubItem_Crunch:
	lea      Str_Dialog_DeleteFile(pc),a0                 ; Point a0 at dialog delete file
	bsr.w    Func_OpenDialogAndSetMenu                    ; Call Func_OpenDialogAndSetMenu — open dialog and set menu
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_EventMain                               ; The main ui event wait loop. updates the status displays and waits for if non-zero/not equal — checked value at (a0)
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
Loop_Crunch_CopyPath:
	move.b   (a1)+,(a0)+                                  ; Copy one byte to destination
	bne.w    Loop_Crunch_CopyPath                         ; Crunch copy path if non-zero/not equal
	subq.l   #$1,a0                                       ; Decrement a0 by one
	lea      Var_DialogSuffixString(pc),a1                ; Point a1 at dialog filename suffix string
Loop_Crunch_AppendSuffix:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	bne.w    Loop_Crunch_AppendSuffix                     ; Crunch append suffix if non-zero/not equal
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	jsr      _LVODeleteFile(a6)                                     ; Call DeleteFile() — delete file
	lea      Str_FileDeleted(pc),a0                       ; Point a0 at file deleted
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Loc_Menu_SubItem_Decrunch:
	lea      Str_Dialog_RelocateFile(pc),a0               ; Point a0 at dialog relocate file
	bsr.w    Func_OpenDialogAndSetMenu                    ; Call Func_OpenDialogAndSetMenu — open dialog and set menu
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_EventMain                               ; The main ui event wait loop. updates the status displays and waits for if non-zero/not equal — checked value at (a0)
	move.l   Var_PayloadBuffer(pc),d0                     ; Load packed/unpacked file data buffer into d0
	beq.w    Loc_Menu_CrunchError                         ; Menu crunch error if zero/equal
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
Loc_Menu_CrunchError:
	bsr.w    Func_LoadFileHeaderAndVerify                 ; Call Func_LoadFileHeaderAndVerify — load file header and verify
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Func_ClearChunkyBuffer:
	lea      Var_ChunkyBuffer40(pc),a0                    ; Point a0 at 40-byte chunky row buffer
	move.w   #$af,d0                                      ; Set d0 to 175 ($af)
Loop_ClearChunkyBuffer:
	clr.b    (a0)+                                        ; Clear 40-byte chunky row buffer to zero
	dbra     d0,Loop_ClearChunkyBuffer                    ; Decrement d0 and loop to Loop_ClearChunkyBuffer until done
	rts                                                   ; Return to caller
Loc_Menu_SubItem_DiskInfo:
	bsr.w    Func_Menu_SubItem_Quit                       ; Call Func_Menu_SubItem_Quit — menu sub item quit
	lea      Str_IntuitionLibName(pc),a1                  ; Load pointer to "intuition.library" name string
	bsr.w    Func_OpenLibrary                             ; Call Func_OpenLibrary — open library
	lea      Var_IntuitionBase(pc),a0                     ; Point a0 at intuition.library base
	move.l   d0,(a0)                                      ; Store d0 as intuition.library base
	movea.l  d0,a6                                        ; Switch library base to d0
	lea      Var_DiskInfoWindowStruct(pc),a0              ; Point a0 at disk info window struct
	jsr      _LVOOpenWindow(a6)                           ; Open standard custom packer window
	lea      Var_MainWindowPointer(pc),a0                 ; Point a0 at alternative main window pointer
	move.l   d0,(a0)                                      ; Store d0 as alternative main window pointer
Loop_DiskInfo_WaitMsg:
	bsr.w    Func_WaitAndGetMainWindowMsg                 ; Call Func_WaitAndGetMainWindowMsg — wait and get main window msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$100,d0                                     ; Compare return value from Func_WaitAndGetMainWindowMsg against $100 (256)
	beq.w    Loc_DiskInfo_EventLoop                       ; Disk info event loop if zero/equal — d0 vs $100 — checked #$100,d0
	cmp.w    #$200,d0                                     ; Compare return value from Func_WaitAndGetMainWindowMsg against $200 (512)
	beq.w    Loc_DiskInfo_Close                           ; Disk info close if zero/equal — d0 vs $200 — checked #$200,d0
	bra.w    Loop_DiskInfo_WaitMsg                        ; Jump to Loop_DiskInfo_WaitMsg — disk info wait msg
Loc_DiskInfo_EventLoop:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_MainWindowPointer(pc),a0                 ; Load alternative main window pointer into a0
	jsr      _LVOCloseWindow(a6)                                     ; Close window (_LVOCloseWindow)
	movea.l  Var_IntuitionBase(pc),a1                     ; Load intuition.library base into a1
	bsr.w    Func_CloseLibrary                            ; Call Func_CloseLibrary — close library
	bra.w    Packer_OpenLibs                              ; Jump to Packer_OpenLibs — Opens graphics.library, intuition.library, and dos.library,
Func_CloseLibrary:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jmp      _LVOCloseLibrary(a6)                         ; Close opened library
Func_OpenLibrary:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jmp      _LVOOpenLibrary(a6)                          ; Open target system library
Loc_DiskInfo_Close:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_MainWindowPointer(pc),a0                 ; Load alternative main window pointer into a0
	jsr      _LVOCloseWindow(a6)                                     ; Close window (_LVOCloseWindow)
	movea.l  Var_IntuitionBase(pc),a1                     ; Load intuition.library base into a1
	bsr.w    Func_CloseLibrary                            ; Call Func_CloseLibrary — close library
	bra.w    Loc_OpenPacker_Done                          ; Jump to Loc_OpenPacker_Done — open packer done
Func_WaitAndGetMainWindowMsg:
	bsr.w    Func_WaitMainWindowPort                      ; Call Func_WaitMainWindowPort — wait main window port
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_MainWindowPointer(pc),a0                 ; Load alternative main window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jsr      _LVOGetMsg(a6)                               ; Retrieve startup message from MsgPort
	lea      Var_LastIntuiMessage(pc),a1                  ; Point a1 at last received IntuiMessage pointer
	move.l   d0,(a1)                                      ; Store d0 as last received IntuiMessage pointer
	movea.l  d0,a1                                        ; Save _LVOGetMsg result in a1
	beq.w    Func_WaitAndGetMainWindowMsg                 ; Wait and get main window msg if zero/equal
	jmp      _LVOReplyMsg(a6)                                    ; Reply to received message (_LVOReplyMsg)
Func_WaitMainWindowPort:
	movea.l  Var_MainWindowPointer(pc),a0                 ; Load alternative main window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jmp      _LVOWaitPort(a6)                                    ; Wait for message to arrive on port (_LVOWaitPort)
Loc_DrawMenuOptions:
	lea      Var_PrintFormattingZero(pc),a0               ; Point a0 at empty/zero text formatting entry
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_Menu_DoubleActionTitle(pc),a0            ; Load pointer to "Double Action V1.0" splash title string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_Menu_CopyrightTristar(pc),a0             ; Load pointer to copyright notice string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Var_PrintFormattingSpace(pc),a0              ; Point a0 at space text formatting entry
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_Menu_TristarProduction(pc),a0            ; Load pointer to production info string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_Menu_TristarManufactory(pc),a0           ; Load pointer to Tristar Manufactory info string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_Menu_ToolsForFools(pc),a0                ; Load pointer to "Tools for fools..." intro string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_Menu_LamePeople(pc),a0                   ; Load pointer to warning about lame people handling with care
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_Menu_AssembledDate(pc),a0                ; Load pointer to assembly assembler credit string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Var_PrintFormattingEnd(pc),a0                ; Point a0 at end-of-text formatting marker
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_EventMain                               ; Jump to Loop_EventMain — The main UI event wait loop. Updates the status displays and waits for
Func_OpenDialogAndSetMenu:
	lea      Var_DialogTitlePointer(pc),a1                ; Point a1 at dialog window title string pointer
	move.l   a0,(a1)                                      ; Store a0 as dialog window title string pointer
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_DialogWindowStruct(pc),a0                ; Point a0 at dialog NewWindow structure
	jsr      _LVOOpenWindow(a6)                           ; Open standard custom packer window
	lea      Var_Window_Work(pc),a0                       ; Point a0 at dialog/work window handle
	move.l   d0,(a0)                                      ; Store d0 as dialog/work window handle
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	move.w   #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply result of _LVOOpenWindow by 32 (shift left 5)
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	jsr      _LVOOffMenu(a6)                                     ; Disable (grey out) menu item (_LVOOffMenu)
	bsr.w    Func_BuildAndSortDirectory                   ; Call Func_BuildAndSortDirectory — build and sort directory
	lea      Var_FileListBufferPointer(pc),a0             ; Point a0 at file list display buffer
	movea.l  Var_ScreenChunkyBuffer(pc),a1                ; Load screen chunky pixel buffer into a1
	lea      $28(a1),a1                                   ; Get address at offset $28 from a1
	move.l   a1,(a0)                                      ; Store a1 as file list display buffer
	lea      Var_FloppyOperationActive(pc),a0             ; Point a0 at floppy operation active flag
	clr.b    (a0)                                         ; Clear floppy operation active flag to zero
	bsr.w    Func_RefreshFloppyStatusDisplay              ; Call Func_RefreshFloppyStatusDisplay — refresh floppy status display
	bsr.w    Func_DrawDialogLayout                        ; Call Func_DrawDialogLayout — draw dialog layout
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_Window_Work(pc),a0                       ; Load dialog window into a0
	jsr      _LVOCloseWindow(a6)                                     ; Close window (_LVOCloseWindow)
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	move.w   #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply function return value by 32 (shift left 5)
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	jsr      _LVOOnMenu(a6)                                     ; Enable menu item (_LVOOnMenu)
	lea      Var_DialogSuffixString(pc),a0                ; Point a0 at dialog filename suffix string
	tst.b    (a0)                                         ; Check whether dialog filename suffix string is zero/null
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal — checked value at (a0)
	rts                                                   ; Return to caller
Func_Menu_SubItem_Quit:
	move.l   Var_DirectoryLock(pc),d1                     ; Load current directory lock handle into d1
	beq.w    Loc_Quit_CloseWindows                        ; Quit close windows if zero/equal
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	jsr      _LVOUnLock(a6)                               ; Release duplicated directory lock
Loc_Quit_CloseWindows:
	move.l   Var_PayloadBuffer(pc),d0                     ; Load packed/unpacked file data buffer into d0
	beq.w    Loc_Quit_FreeResources                       ; Quit free resources if zero/equal
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
Loc_Quit_FreeResources:
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	movea.l  d0,a0                                        ; Pass returned pointer in a0
	move.l   Var_DiskInfoWindowPointer(pc),pr_WindowPtr(a0); Restore original process requester window pointer
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	jsr      _LVOClearMenuStrip(a6)                            ; Detach menu strip from window prior to closing
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	jsr      _LVOCloseWindow(a6)                                     ; Call CloseWindow() — close window
Loc_HandleMenuError:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_Screen(pc),a0                            ; Load custom screen into a0
	jsr      _LVOCloseScreen(a6)                                     ; Close custom screen (_LVOCloseScreen)
Loc_Quit_Finish:
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	lea      Var_DialogListTitle9(pc),a1                  ; Point a1 at dialog list title9
	jsr      _LVOSyncSBitMap(a6)                                    ; Call SyncSBitMap() — sync super bitmap
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_ViewportBuffer(pc),a1                    ; Load ViewPort display buffer into a1
	move.l   #$438,d0                                     ; Load Copper wait viewport list size ($438 bytes)
	jsr      _LVOFreeMem(a6)                                     ; FreeMem — free allocated memory
Loc_OpenPacker_RetryWindow:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_ScreenChunkyBuffer(pc),a1                ; Load screen chunky pixel buffer into a1
	move.l   #$3e80,d0                                    ; Load custom screen chunky buffer size ($3e80 bytes)
	jsr      _LVOFreeMem(a6)                                     ; FreeMem — free allocated memory
Loc_OpenPacker_Success:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_ChunkyBuffer40(pc),a1                    ; Load 40-byte chunky row buffer into a1
	moveq    #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	jsr      _LVOFreeMem(a6)                                     ; Free previously allocated memory block (_LVOFreeMem)
Loc_OpenPacker_ErrorWindow:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_FIBPointer(pc),a1                        ; Load FileInfoBlock buffer into a1
	move.l   #$104,d0                                     ; Load visual workspace allocation size ($104 bytes)
	jsr      _LVOFreeMem(a6)                                     ; Free previously allocated memory block (_LVOFreeMem)
Loc_OpenPacker_CleanQuit:
	movea.l  Var_DOSBase(pc),a1                           ; Load dos.library base pointer
	bsr.w    Func_CloseLibrary                            ; Call Func_CloseLibrary — close library
Loc_OpenPacker_Exit:
	movea.l  Var_IntuitionBase(pc),a1                     ; Load intuition.library base into a1
	bsr.w    Func_CloseLibrary                            ; Call Func_CloseLibrary — close library
Loc_OpenPacker_ErrorExit:
	movea.l  Var_GfxBase(pc),a1                           ; Load graphics.library base into a1
	bsr.w    Func_CloseLibrary                            ; Call Func_CloseLibrary — close library
Loc_OpenPacker_Done:
	moveq    #$0,d0                                       ; Clear value 0 to zero
	rts                                                   ; Return to caller
Func_OpenPackerWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_DialogWindowLeft(pc),a0                  ; Point a0 at dialog window left
	jsr      _LVOOpenWindow(a6)                           ; Open standard custom packer window
	lea      Var_Window(pc),a0                            ; Point a0 at main packer window handle
	move.l   d0,(a0)                                      ; Store d0 as main packer window handle
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal
	movea.l  d0,a0                                        ; Pass d0 as argument in a0
	lea      Var_DialogListTitle8(pc),a1                  ; Point a1 at dialog list title8
	jsr      _LVOSetMenuStrip(a6)                                    ; Attach menu strip to window (_LVOSetMenuStrip)
	bsr.w    Func_GetThisTask                             ; Query Exec library for current task handle
	movea.l  d0,a0                                        ; Pass returned pointer in a0
	lea      Var_DiskInfoWindowPointer(pc),a1             ; Point a1 at disk info window pointer
	move.l   pr_WindowPtr(a0),(a1)                        ; Backup original process requester window pointer
	move.l   Var_Window(pc),pr_WindowPtr(a0)              ; Redirect DOS system requesters to our UI window
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_WaitAndGetMsg:
	bsr.w    Func_WaitUserPort                            ; Wait until window UserPort receives an Intuition message
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jsr      _LVOGetMsg(a6)                               ; Retrieve startup message from MsgPort
	lea      Var_LastIntuiMessage(pc),a1                  ; Point a1 at last received IntuiMessage pointer
	move.l   d0,(a1)                                      ; Store d0 as last received IntuiMessage pointer
	movea.l  d0,a1                                        ; Save _LVOGetMsg result in a1
	beq.w    Func_WaitAndGetMsg                           ; Wait and get msg if zero/equal
	jmp      _LVOReplyMsg(a6)                                    ; Reply to received message (_LVOReplyMsg)
Func_WaitUserPort:
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jmp      _LVOWaitPort(a6)                                    ; Wait for message to arrive on port (_LVOWaitPort)
Func_ScrollVPortPen99:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	moveq    #$4,d0                                       ; Set d0 to 4 ($4)
	move.w   #$99,d1                                      ; Set d1 to 153 ($99)
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOMove(a6)                          ; Scroll ViewPort vertically
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_ScrollVPortPen1A:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	moveq    #$1a,d0                                      ; Select color/pen index 26 ($1a)
	move.w   #$50,d1                                      ; Set ViewPort offset height (80 pixels)
	movea.l  Var_ProgressWindowPointer(pc),a1             ; Load Progress window pointer
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOMove(a6)                          ; Scroll ViewPort vertically
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_ScrollVPortPenA6:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	moveq    #$4,d0                                       ; Set d0 to 4 ($4)
	move.w   #$a6,d1                                      ; Set d1 to 166 ($a6)
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOMove(a6)                          ; Scroll ViewPort vertically
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_ScrollVPort:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	moveq    #$0,d0                                       ; Clear value 0 to zero
	move.w   #$9d,d1                                      ; Load standard ViewPort height (157 pixels)
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOMove(a6)                          ; Scroll ViewPort vertically
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_MakeVPort:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	move.w   #$1b8,d0                                     ; Load standard ViewPort width (440 pixels)
	move.w   #$9d,d1                                      ; Load standard ViewPort height (157 pixels)
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVODraw(a6)                            ; Rebuild screen ViewPort Copper lists
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_SetAPenToOne:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	moveq    #$1,d0                                       ; Set d0 to 1 ($1)
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  $32(a0),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOSetAPen(a6)                                    ; Set foreground drawing pen color (_LVOSetAPen)
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
	dc.b $48
	dc.b $E7
	dc.b $E0
	dc.b $E2
	dc.b $2C
	dc.b $7A
	dc.b $2D
	dc.b $02
	dc.b $70
	dc.b $01
	dc.b $20
	dc.b $7A
	dc.b $2D
	dc.b $84
	dc.b $22
	dc.b $68
	dc.b $00
	dc.b $32
	dc.b $4E
	dc.b $AE
	dc.b $FE
	dc.b $AA
	dc.b $4C
	dc.b $DF
	dc.b $47
	dc.b $07
	dc.b $4E
	dc.b $75
Func_MergeCopper:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	moveq    #$2,d0                                       ; Set d0 to 2 ($2)
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  $32(a0),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOSetAPen(a6)                                    ; Set foreground drawing pen color (_LVOSetAPen)
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_ClearWindowArea:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	moveq    #$0,d0                                       ; Clear value 0 to zero
	moveq    #$2,d2                                       ; Set d2 to 2 ($2)
	moveq    #$1,d3                                       ; Set d3 to 1 ($1)
	move.w   #$1b4,d4                                     ; Set d4 to 436 ($1b4)
	move.w   #$9b,d5                                      ; Set d5 to 155 ($9b)
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  $32(a0),a1                                   ; Read wd_RPort (Window RastPort) into a1
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	jsr      _LVOScrollRaster(a6)                                    ; Scroll raster contents in rectangle (_LVOScrollRaster)
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Loop_RenderText_Height:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	bra.w    Loc_RenderText_Loop                          ; Jump to Loc_RenderText_Loop — render text loop
Func_RenderText:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	bsr.w    Func_ScrollVPortPenA6                        ; Call Func_ScrollVPortPenA6 — scroll vport pen a6
	bra.w    Loc_RenderText_Loop                          ; Jump to Loc_RenderText_Loop — render text loop
Func_RenderTextAlt:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	bsr.w    Func_ClearWindowArea                         ; Call Func_ClearWindowArea — clear window area
	bsr.w    Func_ScrollVPortPen99                        ; Call Func_ScrollVPortPen99 — scroll vport pen99
Loc_RenderText_Loop:
	bsr.w    Func_SetAPenToOne                            ; Call Func_SetAPenToOne — set apen to one
	movea.l  a0,a1                                        ; Copy a0 to a1
Loop_RenderText_Char:
	tst.b    (a1)+                                        ; Test byte at (a1) for zero
	bne.w    Loop_RenderText_Char                         ; Render text char if non-zero/not equal — checked value at (a1)
	suba.l   a0,a1                                        ; Subtract a0 from a1
	move.l   a1,d0                                        ; Copy a1 to d0
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOText(a6)                                     ; Render text string to RastPort (_LVOText)
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_StartCrunchingUI:
	moveq    #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply value 63 by 32 (shift left 5)
	bsr.w    Func_DisableMenuItem                         ; Disable GUI interactive menu item via Intuition
	lea      Var_PayloadSize(pc),a0                       ; Point a0 at current payload data size
	clr.l    (a0)                                         ; Clear current payload data size to zero
	move.l   Var_PayloadBuffer(pc),d0                     ; Load packed/unpacked file data buffer into d0
	beq.w    Loc_StartCrunching_OpenFile                  ; Start crunching open file if zero/equal
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
Loc_StartCrunching_OpenFile:
	bsr.w    Func_OpenFileOld                             ; Call Func_OpenFileOld — open file old
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	beq.w    Loc_StartCrunching_PrintStopPrompt           ; Start crunching print stop prompt if zero/equal — checked value at (a0)
	moveq    #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply value 63 by 32 (shift left 5)
	bra.w    Func_EnableMenuItem                          ; Jump to Func_EnableMenuItem — enable menu item
Loc_StartCrunching_PrintStopPrompt:
	bsr.w    Func_UpdateMemoryDisplay                     ; Update real-time free Chip/Fast memory status display
	lea      Var_PrintFormattingZero(pc),a0               ; Point a0 at empty/zero text formatting entry
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_StopCrunchingPrompt(pc),a0               ; Load pointer to "Both Buttons To Stop Crunching !" prompt string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Var_PrintFormattingZero(pc),a0               ; Point a0 at empty/zero text formatting entry
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_OriginalLength(pc),a0                    ; Point a0 at original length
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	movea.l  Var_TempLong(pc),a0                          ; Load temporary longword workspace into a0
	suba.l   Var_UnusedWorkspace(pc),a0                   ; Subtract Var_UnusedWorkspace(pc) from a0
	bsr.w    Func_FormatFloppyTrackText                   ; Call Func_FormatFloppyTrackText — format floppy track text
	movea.l  Var_UnusedWorkspace(pc),a2                   ; Load workspace end pointer into a2
	movea.l  Var_TempLong(pc),a6                          ; Load temporary longword workspace into a6
	lea      Var_DirectoryEntryType(pc),a4                ; Point a4 at directory entry type code
	move.b   #$2,d7                                       ; Set d7 to 2 ($2)
	bsr.w    Func_CheckHunkStructure                      ; Call Func_CheckHunkStructure — check hunk structure
	lea      Var_MenuID_Selected(pc),a0                   ; Point a0 at currently selected menu preference ID
	tst.b    (a0)                                         ; Check whether currently selected menu preference ID is zero/null
	beq.w    Loc_StartCrunching_VerifyHeader              ; Start crunching verify header if zero/equal — checked value at (a0)
	lea      CUSTOM.l,a3                                  ; Point a3 at Custom Chip register base ($dff000)
	move.w   #$4000,$9a(a3)                               ; Disable all interrupts (INTENA=$4000, clear master enable)
	move.w   #$200,$96(a3)                                ; Disable copper DMA (DMACON=$200)
	lea      CIAB_PRB.l,a1                                ; Point a1 at CIA-B Port B (floppy drive control)
	move.b   #$fd,(a1)                                    ; Write byte $fd to (a1)
	move.b   #$87,(a1)                                    ; Write byte $87 to (a1)
	move.b   #$fd,(a1)                                    ; Write byte $fd to (a1)
Loc_StartCrunching_VerifyHeader:
	movea.l  Var_UnusedWorkspace(pc),a0                   ; Load workspace end pointer into a0
	movea.l  Var_TempLong(pc),a1                          ; Load temporary longword workspace into a1
	movea.l  Var_PayloadBuffer(pc),a2                     ; Load packed/unpacked file data buffer into a2
	bsr.w    Func_AllocateSegmentList                     ; Call Func_AllocateSegmentList — allocate segment list
	lea      Var_DirectoryEntryHeader(pc),a6              ; Point a6 at directory entry header pointer
	move.l   a2,(a6)                                      ; Store a2 as directory entry header pointer
	lea      CUSTOM.l,a3                                  ; Point a3 at Custom Chip register base ($dff000)
	move.w   #$8200,$96(a3)                               ; Enable copper DMA (DMACON=$8200)
	move.w   #$c000,$9a(a3)                               ; Enable all interrupts (INTENA=$c000, set master enable)
	lea      Str_Phase1Progress(pc),a0                    ; Load pointer to "Phase 1 in progres :" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	suba.l   Var_PayloadBuffer(pc),a2                     ; Subtract Var_PayloadBuffer(pc) from a2
	movea.l  a2,a0                                        ; Pass a2 as argument in a0
	bsr.w    Func_FormatFloppyTrackText                   ; Call Func_FormatFloppyTrackText — format floppy track text
	movea.l  Var_DirectoryEntryHeader(pc),a2              ; Load directory entry header pointer into a2
	bsr.w    Func_CopyBytesBackward                       ; Call Func_CopyBytesBackward — copy bytes backward
	lea      Var_MenuID_Selected(pc),a0                   ; Point a0 at currently selected menu preference ID
	tst.b    (a0)                                         ; Check whether currently selected menu preference ID is zero/null
	beq.w    Loc_StartCrunching_AllocPayload              ; Start crunching alloc payload if zero/equal — checked value at (a0)
	lea      CUSTOM.l,a3                                  ; Point a3 at Custom Chip register base ($dff000)
	move.w   #$4000,$9a(a3)                               ; Disable all interrupts (INTENA=$4000, clear master enable)
	move.w   #$200,$96(a3)                                ; Disable copper DMA (DMACON=$200)
	lea      CIAB_PRB.l,a1                                ; Point a1 at CIA-B Port B (floppy drive control)
	move.b   #$fd,(a1)                                    ; Write byte $fd to (a1)
	move.b   #$87,(a1)                                    ; Write byte $87 to (a1)
	move.b   #$fd,(a1)                                    ; Write byte $fd to (a1)
Loc_StartCrunching_AllocPayload:
	movea.l  Var_UnusedWorkspace(pc),a0                   ; Load workspace end pointer into a0
	movea.l  Var_DirectoryEntryHeader(pc),a1              ; Load directory entry header pointer into a1
	adda.l   Var_DirectoryEntryBuffer(pc),a1              ; Advance a1 by directory entry buffer
	movea.l  Var_PayloadBuffer(pc),a2                     ; Load packed/unpacked file data buffer into a2
	bsr.w    Func_ValidateSegmentTypes                    ; Call Func_ValidateSegmentTypes — validate segment types
	lea      Var_DirectoryEntrySize(pc),a6                ; Point a6 at directory entry data size
	move.l   a2,(a6)                                      ; Store a2 as directory entry data size
	lea      CUSTOM.l,a3                                  ; Point a3 at Custom Chip register base ($dff000)
	move.w   #$8200,$96(a3)                               ; Enable copper DMA (DMACON=$8200)
	move.w   #$c000,$9a(a3)                               ; Enable all interrupts (INTENA=$c000, set master enable)
	lea      Var_StatusErrorFlag(pc),a3                   ; Point a3 at global error status flag
	tst.b    (a3)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_StartCrunching_Error                     ; Start crunching error if non-zero/not equal — checked value at (a3)
	lea      Loc_StartCrunching_LoadHunks(pc),a5          ; Point a5 at start crunching load hunks
	lea      Var_MenuSubID_Selected(pc),a4                ; Point a4 at current menu sub-item preference ID
	bra.w    Loop_LoadFile_CodeBlocks                     ; Jump to Loop_LoadFile_CodeBlocks — load file code blocks
Loc_StartCrunching_LoadHunks:
; ============================================================================
; Data    : Packer_LoaderBlock_Code
; Purpose : Embedded depacker and GUI update code written to packed executables.
; Notes   : This code is written as raw data to preserve byte identity, as it
;           is copied directly into packed files and not executed in-place.
; ============================================================================
	dc.w    $41fa,$2cac             ; lea      $2cae(pc),a0             ; Point a0 to first GUI element
	dc.w    $6100,$fe74             ; bsr.w    Func_RenderTextAlt       ; Call GUI update routine
	dc.w    $95fa,$2be4             ; suba.l   Var_PayloadBuffer(pc),a2 ; Calculate relative offset in payload buffer
	dc.w    $204a                   ; movea.l  a2,a0                    ; Pass payload offset in a0
	dc.w    $6100,$27a6             ; bsr.w    Func_FormatTrackText     ; Update track status text on screen
	dc.w    $41fa,$2caf             ; lea      Str_FileReadyToSave(pc),a0; Point to second GUI element
	dc.w    $6100,$fe62             ; bsr.w    Func_RenderTextAlt       ; Redraw GUI element
	dc.w    $43fa,$2ade             ; lea      Var_Window(pc),a1        ; Load window context pointer
	dc.w    $6100,$fae6             ; bsr.w    Func_OpenLibrary         ; Call OpenLibrary or custom redraw window
	dc.w    $41fa,$2af4             ; lea      Var_ProgressBarState(pc),a0; Get progress bar state pointer
	dc.w    $2080                   ; move.l   d0,(a0)                  ; Save window/screen handle
	dc.w    $6756                   ; beq.s    .SkipProgressUpdate      ; Skip progress update if handle is NULL
	dc.w    $203a,$37f8             ; move.l   Var_ProcessedBytes(pc),d0; Load current processed bytes
	dc.w    $90ba,$2bbe             ; sub.l    Var_PayloadBuffer(pc),d0 ; Subtract payload start to get relative position
	dc.w    $2c7a,$2ae4             ; movea.l  Var_MathBase(pc),a6      ; Load mathffp.library base pointer
	dc.w    $4eae,$ffdc             ; jsr      _LVO_SPFlt(a6)           ; Convert current bytes integer to float
	dc.w    $2f00                   ; move.l   d0,-(a7)                 ; Push current float to stack
	dc.w    $203a,$2bac             ; move.l   Var_TotalExpected(pc),d0 ; Load total expected bytes
	dc.w    $90ba,$2ba4             ; sub.l    Var_StatusErrorFlag(pc),d0; Subtract offset to get relative size
	dc.w    $4eae,$ffdc             ; jsr      _LVO_SPFlt(a6)           ; Convert total expected bytes to float
	dc.w    $2200                   ; move.l   d0,d1                    ; Move total float to d1
	dc.w    $201f                   ; move.l   (a7)+,d0                 ; Pop current float into d0
	dc.w    $4eae,$ffac             ; jsr      _LVO_SPDiv(a6)           ; Divide current by total (d0 = current / total)
	dc.w    $2f00                   ; move.l   d0,-(a7)                 ; Push division result to stack
	dc.w    $7064                   ; moveq    #100,d0                  ; Load multiplier integer 100
	dc.w    $4eae,$ffdc             ; jsr      _LVO_SPFlt(a6)           ; Convert integer 100 to float (100.0)
	dc.w    $221f                   ; move.l   (a7)+,d1                 ; Pop division result to d1
	dc.w    $4eae,$ffb2             ; jsr      _LVO_SPMul(a6)           ; Multiply by 100.0 (percentage float)
	dc.w    $4eae,$ffe2             ; jsr      _LVO_SPFix(a6)           ; Convert percentage float back to integer
	dc.w    $2040                   ; movea.l  d0,a0                    ; Pass percentage integer (0-100) to a0
	dc.w    $6100,$2750             ; bsr.w    Func_DrawProgressBar     ; Draw progress bar graph
	dc.w    $227a,$2aae             ; movea.l  Var_GfxBase(pc),a1       ; Load graphics library context
	dc.w    $6100,$fa90             ; bsr.w    Func_CleanupProgressBar  ; Run graphics/UI cleanup step
	dc.w    $41fa,$2c20             ; lea      Var_ThirdGuiElement(pc),a0; Point to third GUI element
	dc.w    $6100,$fdf0             ; bsr.w    Func_RefreshGuiElement   ; Refresh third GUI element
	dc.w    $41fa,$2e8d             ; lea      Var_FourthGuiElement(pc),a0; Point to fourth GUI element
	dc.w    $6100,$fdfc             ; bsr.w    Func_RenderText          ; Refresh fourth GUI element text
; .SkipProgressUpdate:
	dc.w    $203a,$2b6c             ; move.l   Var_StubToggleFlag(pc),d0; Load adjustment offset
	dc.w    $41fa,$379a             ; lea      Var_CoordinateVars(pc),a0; Point to coordinate variables
	dc.w    $9198                   ; sub.l    d0,(a0)+                 ; Subtract offset from first coordinate
	dc.w    $9198                   ; sub.l    d0,(a0)+                 ; Subtract offset from second coordinate
	dc.w    $203a,$379c             ; move.l   Var_DeltaValue(pc),d0    ; Load delta value to add back
	dc.w    $d1a0                   ; add.l    d0,-(a0)                 ; Add delta back to second coordinate
	dc.w    $d1a0                   ; add.l    d0,-(a0)                 ; Add delta back to first coordinate
	dc.w    $203a,$2b54             ; move.l   Var_SizePosValue(pc),d0  ; Load size or position value
	dc.w    $90ba,$2b4c             ; sub.l    Var_RelOffset(pc),d0     ; Subtract relative offset
	dc.w    $d0ba,$378c             ; add.l    Var_FirstDelta(pc),d0    ; Add first delta value
	dc.w    $d0ba,$3798             ; add.l    Var_SecondDelta(pc),d0   ; Add second delta value
	dc.w    $41fa,$3788             ; lea      Var_FinalSizeVar(pc),a0  ; Point to final size variable
	dc.w    $2080                   ; move.l   d0,(a0)                  ; Store calculated size
Loop_StartCrunch_ErrorDelay:
	moveq    #$3f,d0                                      ; Build menu item code 63<<5=$7e0 in d0
	lsl.w    #$5,d0                                       ; Multiply value 63 by 32 (shift left 5)
	bra.w    Func_EnableMenuItem                          ; Jump to Func_EnableMenuItem — enable menu item
Loc_StartCrunching_Error:
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
	lea      Str_CrunchBreakoff(pc),a0                    ; Load pointer to "Crunching breaking off!" error string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_StartCrunch_ErrorDelay                  ; Jump to Loop_StartCrunch_ErrorDelay — start crunch error delay
Func_StartSaveFileUI:
	lea      Str_Dialog_SaveFile(pc),a0                   ; Point a0 at dialog save file
	bsr.w    Func_OpenDialogAndSetMenu                    ; Call Func_OpenDialogAndSetMenu — open dialog and set menu
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
Loop_SaveFile_CopyPath:
	move.b   (a1)+,(a0)+                                  ; Copy one byte to destination
	bne.w    Loop_SaveFile_CopyPath                       ; Save file copy path if non-zero/not equal
	subq.l   #$1,a0                                       ; Decrement a0 by one
	lea      Var_DialogSuffixString(pc),a1                ; Point a1 at dialog filename suffix string
Loop_SaveFile_AppendSuffix:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	bne.w    Loop_SaveFile_AppendSuffix                   ; Save file append suffix if non-zero/not equal
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	move.l   #MODE_NEWFILE,d2                                     ; Load MODE_NEWFILE into d2 for Open()
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	jsr      _LVOOpen(a6)                                     ; Open file for reading or writing (_LVOOpen)
	lea      Var_FileHandle(pc),a0                        ; Point a0 at open file handle
	move.l   d0,(a0)                                      ; Store d0 as open file handle
	beq.w    Loc_StartSaveFile_Error                      ; Start save file error if zero/equal
	move.l   Var_PayloadSize(pc),d0                       ; Load current payload data size into d0
	cmp.l    #$181,d0                                     ; Check if d0 equals $181 (385)
	bls.w    Loc_StartSaveFile_WriteHunkHeaders           ; Start save file write hunk headers if unsigned lower or same — checked #$181,d0
	cmp.l    #$701,d0                                     ; Check if d0 equals $701 (1793)
	bls.w    Loc_StartSaveFile_WriteRelocData             ; Start save file write reloc data if unsigned lower or same — checked #$701,d0
	cmp.l    #$1501,d0                                    ; Check if d0 equals $1501 (5377)
	bls.w    Loc_StartSaveFile_OpenFile                   ; Start save file open file if unsigned lower or same — checked #$1501,d0
	bra.w    Loc_StartSaveFile_WriteSymbolData            ; Jump to Loc_StartSaveFile_WriteSymbolData — start save file write symbol data
Loc_StartSaveFile_OpenFile:
	move.l   #Loc_Event_DecodeMenuCode,d7                 ; Load address of Loc_Event_DecodeMenuCode into d7
	move.l   Var_DirectoryEntrySize(pc),d6                ; Load directory entry data size into d6
	sub.l    Var_DirectoryEntryComment(pc),d6             ; Subtract directory entry comment string from d6
	add.l    d6,d7                                        ; Add d6 to d7
	move.l   d7,-(a7)                                     ; Save d7 on stack
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_AllocError                 ; Start save file alloc error if carry clear (greater or equal)
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	addq.l   #$1,d7                                       ; Increment d7 by one
	bra.w    Loc_StartSaveFile_WriteLoop                  ; Jump to Loc_StartSaveFile_WriteLoop — start save file write loop
Loc_StartSaveFile_Error:
	bsr.w    Func_PrintCouldNotOpenFile                   ; Call Func_PrintCouldNotOpenFile — print could not open file
	bra.w    Func_StartSaveFileUI                         ; Jump to Func_StartSaveFileUI — start save file ui
Loc_StartSaveFile_AllocError:
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_WriteLoop                  ; Start save file write loop if carry clear (greater or equal)
	addq.l   #$1,d7                                       ; Increment d7 by one
Loc_StartSaveFile_WriteLoop:
	lea      Var_FloppyFormatState(pc),a0                 ; Point a0 at floppy format state
	move.l   d7,(a0)                                      ; Save d7 as floppyformatstate
	move.l   d7,$8(a0)                                    ; Store d7 at offset $8(a0)
	lea      Var_FloppyRetryCount(pc),a0                  ; Point a0 at floppy retry count
	move.l   a0,d2                                        ; Copy floppy retry count to d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   #$27e,d3                                     ; Set d3 to 638 ($27e)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.l    #$27e,d0                                     ; Check if d0 equals $27e (638)
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — d0 vs $27e — checked #$27e,d0
	move.l   Var_PayloadBuffer(pc),d2                     ; Load packed/unpacked file data buffer into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   Var_DirectoryEntrySize(pc),d3                ; Load directory entry data size into d3
	sub.l    Var_DirectoryEntryComment(pc),d3             ; Subtract directory entry comment string from d3
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.l    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — checked d3,d0
	move.l   (a7)+,d7                                     ; Restore d7 from stack
	move.l   Var_FloppyFormatState(pc),d3                 ; Load floppy format state into d3
	lsl.l    #$2,d3                                       ; Multiply floppyformatstate by 4 (shift left 2)
	sub.l    d7,d3                                        ; Subtract d7 from d3
	beq.w    Loc_StartSaveFile_Done                       ; Start save file done if zero/equal
	lea      Var_TotalHunkCount(pc),a0                    ; Point a0 at total hunk count
	move.l   a0,d2                                        ; Load total hunk count into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.b    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — checked d3,d0
Loc_StartSaveFile_Done:
	lea      Var_ExpectedHunkType(pc),a0                  ; Point a0 at expected hunk type
	move.l   a0,d2                                        ; Load expected hunk type into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.b    #$4,d0                                       ; Check if d0 equals $4 (4)
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — d0 vs $4 — checked #$4,d0
	lea      Str_FileSaved(pc),a0                         ; Load pointer to "File saved !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
Func_CloseFile:
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	jmp      _LVOClose(a6)                                     ; Close an open file handle (_LVOClose)
Loop_StartSaveFile_ErrorDelay:
	move.l   (a7)+,d7                                     ; Restore d7 from stack
Loop_StartSaveFile_Cleanup:
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	bsr.w    Func_PrintCouldNotWriteFile                  ; Call Func_PrintCouldNotWriteFile — print could not write file
	bra.w    Func_StartSaveFileUI                         ; Jump to Func_StartSaveFileUI — start save file ui
Loc_StartSaveFile_WriteHunkHeaders:
	move.l   #$24e,d7                                     ; Set d7 to 590 ($24e)
	move.l   Var_DiskInfo_UsedSectors(pc),d6              ; Load disk info used sectors into d6
	sub.l    Var_DiskInfo_BytesPerSector(pc),d6           ; Subtract Var_DiskInfo_BytesPerSector from d6
	add.l    d6,d7                                        ; Add d6 to d7
	move.l   d7,-(a7)                                     ; Save d7 on stack
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_WriteHunkData              ; Start save file write hunk data if carry clear (greater or equal)
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	addq.l   #$1,d7                                       ; Increment d7 by one
	bra.w    Loc_StartSaveFile_WriteHunkBSS               ; Jump to Loc_StartSaveFile_WriteHunkBSS — start save file write hunk bss
Loc_StartSaveFile_WriteHunkData:
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_WriteHunkBSS               ; Start save file write hunk bss if carry clear (greater or equal)
	addq.l   #$1,d7                                       ; Increment d7 by one
Loc_StartSaveFile_WriteHunkBSS:
	lea      Var_DirectoryEntryFIB(pc),a0                 ; Point a0 at directory entry fib
	move.l   d7,(a0)                                      ; Save d7 as directoryentryfib
	move.l   d7,$8(a0)                                    ; Store d7 at offset $8(a0)
	lea      Var_DirectoryEntryLock(pc),a0                ; Point a0 at directory entry lock
	move.l   a0,d2                                        ; Load directory entry lock into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   #$26e,d3                                     ; Set d3 to 622 ($26e)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.l    #$26e,d0                                     ; Check if d0 equals $26e (622)
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — d0 vs $26e — checked #$26e,d0
	move.l   Var_PayloadBuffer(pc),d2                     ; Load packed/unpacked file data buffer into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   Var_DiskInfo_UsedSectors(pc),d3              ; Load disk info used sectors into d3
	sub.l    Var_DiskInfo_BytesPerSector(pc),d3           ; Subtract Var_DiskInfo_BytesPerSector from d3
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.l    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — checked d3,d0
	move.l   (a7)+,d7                                     ; Restore d7 from stack
	move.l   Var_DirectoryEntryFIB(pc),d3                 ; Load directory entry fib into d3
	lsl.l    #$2,d3                                       ; Multiply directoryentryfib by 4 (shift left 2)
	sub.l    d7,d3                                        ; Subtract d7 from d3
	beq.w    Loc_StartSaveFile_WriteRelocs                ; Start save file write relocs if zero/equal
	lea      Var_TotalHunkCount(pc),a0                    ; Point a0 at total hunk count
	move.l   a0,d2                                        ; Load total hunk count into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.b    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — checked d3,d0
Loc_StartSaveFile_WriteRelocs:
	lea      Var_ExpectedHunkType(pc),a0                  ; Point a0 at expected hunk type
	move.l   a0,d2                                        ; Load expected hunk type into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.b    #$4,d0                                       ; Check if d0 equals $4 (4)
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — d0 vs $4 — checked #$4,d0
	lea      Str_FileSaved(pc),a0                         ; Load pointer to "File saved !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
	bra.w    Func_CloseFile                               ; Jump to Func_CloseFile — close file
Loc_StartSaveFile_WriteRelocData:
	move.l   #Loc_Event_DecodeMenuCode,d7                 ; Load address of Loc_Event_DecodeMenuCode into d7
	move.l   Var_DiskInfo_FIBLock(pc),d6                  ; Load disk info fiblock into d6
	sub.l    Var_DiskInfo_FIBName(pc),d6                  ; Subtract Var_DiskInfo_FIBName from d6
	add.l    d6,d7                                        ; Add d6 to d7
	move.l   d7,-(a7)                                     ; Save d7 on stack
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_WriteDebug                 ; Start save file write debug if carry clear (greater or equal)
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	addq.l   #$1,d7                                       ; Increment d7 by one
	bra.w    Loc_StartSaveFile_WriteDebugData             ; Jump to Loc_StartSaveFile_WriteDebugData — start save file write debug data
Loc_StartSaveFile_WriteDebug:
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_WriteDebugData             ; Start save file write debug data if carry clear (greater or equal)
	addq.l   #$1,d7                                       ; Increment d7 by one
Loc_StartSaveFile_WriteDebugData:
	lea      Var_DiskInfo_VolumeLabel(pc),a0              ; Point a0 at disk info volume label
	move.l   d7,(a0)                                      ; Save d7 as diskinfo volumelabel
	move.l   d7,$8(a0)                                    ; Store d7 at offset $8(a0)
	lea      Var_DiskInfo_DiskName(pc),a0                 ; Point a0 at disk info disk name
	move.l   a0,d2                                        ; Load disk info disk name into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   #$27e,d3                                     ; Set d3 to 638 ($27e)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.l    #$27e,d0                                     ; Check if d0 equals $27e (638)
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — d0 vs $27e — checked #$27e,d0
	move.l   Var_PayloadBuffer(pc),d2                     ; Load packed/unpacked file data buffer into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   Var_DiskInfo_FIBLock(pc),d3                  ; Load disk info fiblock into d3
	sub.l    Var_DiskInfo_FIBName(pc),d3                  ; Subtract Var_DiskInfo_FIBName from d3
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.l    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — checked d3,d0
	move.l   (a7)+,d7                                     ; Restore d7 from stack
	move.l   Var_DiskInfo_VolumeLabel(pc),d3              ; Load disk info volume label into d3
	lsl.l    #$2,d3                                       ; Multiply diskinfo volumelabel by 4 (shift left 2)
	sub.l    d7,d3                                        ; Subtract d7 from d3
	beq.w    Loc_StartSaveFile_WriteSymbols               ; Start save file write symbols if zero/equal
	lea      Var_TotalHunkCount(pc),a0                    ; Point a0 at total hunk count
	move.l   a0,d2                                        ; Load total hunk count into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.b    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — checked d3,d0
Loc_StartSaveFile_WriteSymbols:
	lea      Var_ExpectedHunkType(pc),a0                  ; Point a0 at expected hunk type
	move.l   a0,d2                                        ; Load expected hunk type into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.b    #$4,d0                                       ; Check if d0 equals $4 (4)
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — d0 vs $4 — checked #$4,d0
	lea      Str_FileSaved(pc),a0                         ; Load pointer to "File saved !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
	bra.w    Func_CloseFile                               ; Jump to Func_CloseFile — close file
Loc_StartSaveFile_WriteSymbolData:
	move.l   #$268,d7                                     ; Set d7 to 616 ($268)
	move.l   Var_DiskInfo_FIBPath(pc),d6                  ; Load disk info fibpath into d6
	sub.l    Var_DiskInfo_FIBSect(pc),d6                  ; Subtract Var_DiskInfo_FIBSect from d6
	add.l    d6,d7                                        ; Add d6 to d7
	move.l   d7,-(a7)                                     ; Save d7 on stack
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_WriteHunkEnd               ; Start save file write hunk end if carry clear (greater or equal)
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	addq.l   #$1,d7                                       ; Increment d7 by one
	bra.w    Loc_StartSaveFile_WriteHunkEndData           ; Jump to Loc_StartSaveFile_WriteHunkEndData — start save file write hunk end data
Loc_StartSaveFile_WriteHunkEnd:
	lsr.l    #$1,d7                                       ; Divide d7 by 2 (shift right 1)
	bcc.w    Loc_StartSaveFile_WriteHunkEndData           ; Start save file write hunk end data if carry clear (greater or equal)
	addq.l   #$1,d7                                       ; Increment d7 by one
Loc_StartSaveFile_WriteHunkEndData:
	lea      Var_DiskInfo_FIBSz(pc),a0                    ; Point a0 at disk info fibsz
	move.l   d7,(a0)                                      ; Save d7 as diskinfo fibsz
	move.l   d7,$8(a0)                                    ; Store d7 at offset $8(a0)
	lea      Var_DiskInfo_FIBType(pc),a0                  ; Point a0 at disk info fibtype
	move.l   a0,d2                                        ; Load disk info fibtype into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   #$288,d3                                     ; Load chunky buffer row allocation size ($28 bytes)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.l    #$288,d0                                     ; Load chunky buffer row allocation size ($28 bytes)
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — d0 vs $288 — checked #$288,d0
	move.l   Var_PayloadBuffer(pc),d2                     ; Load packed/unpacked file data buffer into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   Var_DiskInfo_FIBPath(pc),d3                  ; Load disk info fibpath into d3
	sub.l    Var_DiskInfo_FIBSect(pc),d3                  ; Subtract Var_DiskInfo_FIBSect from d3
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.l    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_ErrorDelay                ; Start save file error delay if non-zero/not equal — checked d3,d0
	move.l   (a7)+,d7                                     ; Restore d7 from stack
	move.l   Var_DiskInfo_FIBSz(pc),d3                    ; Load disk info fibsz into d3
	lsl.l    #$2,d3                                       ; Multiply diskinfo fibsz by 4 (shift left 2)
	sub.l    d7,d3                                        ; Subtract d7 from d3
	beq.w    Loc_StartSaveFile_Finalize                   ; Start save file finalize if zero/equal
	lea      Var_TotalHunkCount(pc),a0                    ; Point a0 at total hunk count
	move.l   a0,d2                                        ; Load total hunk count into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.b    d3,d0                                        ; Compare d3 with d0
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — checked d3,d0
Loc_StartSaveFile_Finalize:
	lea      Var_ExpectedHunkType(pc),a0                  ; Point a0 at expected hunk type
	move.l   a0,d2                                        ; Load expected hunk type into d2
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	jsr      _LVOWrite(a6)                                     ; Call Write() — write to file
	cmp.b    #$4,d0                                       ; Check if d0 equals $4 (4)
	bne.w    Loop_StartSaveFile_Cleanup                   ; Start save file cleanup if non-zero/not equal — d0 vs $4 — checked #$4,d0
	lea      Str_FileSaved(pc),a0                         ; Load pointer to "File saved !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
	bra.w    Func_CloseFile                               ; Jump to Func_CloseFile — close file
Func_LoadFileHeaderAndVerify:
	lea      Var_DirectoryEntryBuffer(pc),a0              ; Point a0 at directory entry buffer
	clr.l    (a0)                                         ; Clear directory entry buffer to zero
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
Loop_LoadFileHeader_CopyPath:
	move.b   (a1)+,(a0)+                                  ; Copy one byte to destination
	bne.w    Loop_LoadFileHeader_CopyPath                 ; Load file header copy path if non-zero/not equal
	subq.l   #$1,a0                                       ; Decrement a0 by one
	lea      Var_DialogSuffixString(pc),a1                ; Point a1 at dialog filename suffix string
Loop_LoadFileHeader_AppendSuffix:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	bne.w    Loop_LoadFileHeader_AppendSuffix             ; Load file header append suffix if non-zero/not equal
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	move.l   #MODE_OLDFILE,d2                                     ; Load MODE_OLDFILE into d2 for Open()
	jsr      _LVOOpen(a6)                                     ; Open file for reading or writing (_LVOOpen)
	lea      Var_FileHandle(pc),a0                        ; Point a0 at open file handle
	move.l   d0,(a0)                                      ; Store d0 as open file handle
	beq.w    Loc_HandleFileNotFoundError                  ; Handle file not found error if zero/equal
	bsr.w    Func_ClearHeaderBuffer                       ; Call Func_ClearHeaderBuffer — clear header buffer
	moveq    #$8,d3                                       ; Set d3 to 8 ($8)
	bsr.w    Func_ReadFileHeader                          ; Call Func_ReadFileHeader — read file header
	cmp.b    #$ff,d0                                      ; Compare return value from Func_ReadFileHeader against $ff (255)
	beq.w    Loc_HandleFileLoadError                      ; Handle file load error if zero/equal — d0 vs $ff — checked #$ff,d0
	lea      Var_HeaderBuffer(pc),a0                      ; Point a0 at header buffer
	cmpi.l   #$3f3,(a0)                                   ; Compare #$3f3 with (a0)
	bne.w    Loc_HandleNotALoadFileError                  ; Handle not aload file error if non-zero/not equal — checked #$3f3,(a0)
	bsr.w    Func_OpenAndHandleDialog                     ; Call Func_OpenAndHandleDialog — open and handle dialog
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	bsr.w    Func_LoadFileAndVerify                       ; Call Func_LoadFileAndVerify — load file and verify
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	lea      Str_FileReadyToSave(pc),a0                   ; Load pointer to "File ready to save !" success string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
Loop_LoadFileHeader_WaitMotor:
	lea      Str_Dialog_SaveFile(pc),a0                   ; Point a0 at dialog save file
	bsr.w    Func_OpenDialogAndSetMenu                    ; Call Func_OpenDialogAndSetMenu — open dialog and set menu
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_LoadFileHeader_AllocError                ; Load file header alloc error if non-zero/not equal — checked value at (a0)
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
Loop_LoadFileHeader_Delay:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	bne.w    Loop_LoadFileHeader_Delay                    ; Load file header delay if non-zero/not equal
	subq.l   #$1,a0                                       ; Decrement a0 by one
	lea      Var_DialogSuffixString(pc),a1                ; Point a1 at dialog filename suffix string
Loop_LoadFileHeader_Retry:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	bne.w    Loop_LoadFileHeader_Retry                    ; Load file header retry if non-zero/not equal
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	move.l   #MODE_NEWFILE,d2                                     ; Load MODE_NEWFILE into d2 for Open()
	jsr      _LVOOpen(a6)                                     ; Open file for reading or writing (_LVOOpen)
	lea      Var_FileHandle(pc),a0                        ; Point a0 at open file handle
	move.l   d0,(a0)                                      ; Store d0 as open file handle
	beq.w    Loc_LoadFileHeader_Error                     ; Load file header error if zero/equal
	move.l   d0,d1                                        ; Copy function return value to d1
	move.l   Var_UnusedWorkspace(pc),d2                   ; Load workspace end pointer into d2
	move.l   Var_TempLong(pc),d3                          ; Load temporary longword workspace into d3
	sub.l    d2,d3                                        ; Subtract d2 from d3
	move.l   d3,-(a7)                                     ; Save d3 on stack
	jsr      _LVOWrite(a6)                                     ; Write data to open file (_LVOWrite)
	move.l   (a7)+,d3                                     ; Restore d3 from stack
	cmp.l    d0,d3                                        ; Compare d0 with d3
	bne.w    Loc_LoadFileHeader_Done                      ; Load file header done if non-zero/not equal — checked d0,d3
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	lea      Str_FileSaved(pc),a0                         ; Load pointer to "File saved !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Func_FreePayloadBuffer                       ; Jump to Func_FreePayloadBuffer — free payload buffer
Loc_LoadFileHeader_Done:
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	bsr.w    Func_PrintCouldNotWriteFile                  ; Call Func_PrintCouldNotWriteFile — print could not write file
	bra.w    Loop_LoadFileHeader_WaitMotor                ; Jump to Loop_LoadFileHeader_WaitMotor — load file header wait motor
Loc_LoadFileHeader_Error:
	bsr.w    Func_PrintCouldNotOpenFile                   ; Call Func_PrintCouldNotOpenFile — print could not open file
	bra.w    Loop_LoadFileHeader_WaitMotor                ; Jump to Loop_LoadFileHeader_WaitMotor — load file header wait motor
Func_PrintCouldNotOpenFile:
	lea      Str_Err_CouldNotOpen(pc),a0                  ; Point a0 at err could not open
	bra.w    Func_RenderTextAlt                           ; Jump to Func_RenderTextAlt — render text alt
Func_PrintCouldNotWriteFile:
	lea      Str_Err_CouldNotWrite(pc),a0                 ; Point a0 at err could not write
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	jsr      _LVODeleteFile(a6)                                     ; Call DeleteFile() — delete file
	lea      Str_FileDeleted(pc),a0                       ; Point a0 at file deleted
	bra.w    Func_RenderTextAlt                           ; Jump to Func_RenderTextAlt — render text alt
Loc_LoadFileHeader_AllocError:
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
	lea      Str_FileNotSaved(pc),a0                      ; Point a0 at file not saved
	bra.w    Func_RenderTextAlt                           ; Jump to Func_RenderTextAlt — render text alt
Func_WaitDialogWindowPort:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_DialogWindowPointer(pc),a0               ; Load dialog window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jmp      _LVOWaitPort(a6)                                    ; Call WaitPort() — wait for message on port
Func_GetAndReplyDialogMsg:
	bsr.w    Func_WaitDialogWindowPort                    ; Call Func_WaitDialogWindowPort — wait dialog window port
	movea.l  Var_DialogWindowPointer(pc),a0               ; Load dialog window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jsr      _LVOGetMsg(a6)                               ; Retrieve startup message from MsgPort
	lea      Var_LastIntuiMessage(pc),a1                  ; Point a1 at last received IntuiMessage pointer
	move.l   d0,(a1)                                      ; Store d0 as last received IntuiMessage pointer
	movea.l  d0,a1                                        ; Save _LVOGetMsg result in a1
	beq.w    Func_GetAndReplyDialogMsg                    ; Get and reply dialog msg if zero/equal
	jmp      _LVOReplyMsg(a6)                                    ; Reply to received message (_LVOReplyMsg)
Func_OpenAndHandleDialog:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_StatusWindowStruct(pc),a0                ; Point a0 at status window struct
	jsr      _LVOOpenWindow(a6)                           ; Open standard custom packer window
	lea      Var_DialogWindowPointer(pc),a0               ; Point a0 at dialog window pointer
	move.l   d0,(a0)                                      ; Save result of _LVOOpenWindow as dialogwindowpointer
	beq.w    Loc_Dialog_AllocError                        ; Dialog alloc error if zero/equal
Loop_Dialog_EventLoop:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_Window_WorkHeight(pc),a0                 ; Point a0 at window work height
	movea.l  Var_DialogWindowPointer(pc),a1               ; Load dialog window pointer into a1
	suba.l   a2,a2                                        ; Clear a2 to zero (self-subtract)
	jsr      _LVOFreeSysRequest(a6)                       ; Free the system requester window
	bsr.w    Func_GetAndReplyDialogMsg                    ; Call Func_GetAndReplyDialogMsg — get and reply dialog msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$200,d0                                     ; Compare return value from Func_GetAndReplyDialogMsg against $200 (512)
	beq.w    Loc_Dialog_Close                             ; Dialog close if zero/equal — d0 vs $200 — checked #$200,d0
	cmp.w    #$40,d0                                      ; Compare return value from Func_GetAndReplyDialogMsg against $40 (64)
	beq.w    Loc_Dialog_HandleGadget                      ; Dialog handle gadget if zero/equal — d0 vs $40 — checked #$40,d0
	bra.w    Loop_Dialog_EventLoop                        ; Jump to Loop_Dialog_EventLoop — dialog event loop
Loc_Dialog_HandleGadget:
	movea.l  im_IAddress(a0),a1                                   ; Load IntuiMessage im_IAddress field (sender object pointer)
	move.l   $26(a1),d0                                   ; Read offset $26(a1) into d0
	cmp.w    #$a,d0                                       ; Check if d0 equals $a (10)
	bne.w    Loop_Dialog_EventLoop                        ; Dialog event loop if non-zero/not equal — d0 vs $a — checked #$a,d0
	lea      Var_ProgressWindowIText(pc),a0               ; Point a0 at progress window itext
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Dialog_EventLoop                        ; Dialog event loop if non-zero/not equal — checked value at (a0)
	lea      Var_RemainingHunkBytes(pc),a0                ; Point a0 at remaining hunk bytes
	move.l   d4,(a0)                                      ; Save d4 as remaininghunkbytes
	beq.w    Loop_Dialog_EventLoop                        ; Dialog event loop if zero/equal
	bsr.w    Func_CloseDialogWindow                       ; Call Func_CloseDialogWindow — close dialog window
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_CloseDialogWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_DialogWindowPointer(pc),a0               ; Load dialog window pointer into a0
	jmp      _LVOCloseWindow(a6)                                     ; Close window (_LVOCloseWindow)
Loc_Dialog_Close:
	lea      Str_UserBreak(pc),a0                         ; Load pointer to "User break !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_CloseDialogWindow                       ; Call Func_CloseDialogWindow — close dialog window
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loop_Dialog_ErrorCleanup:
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	move.l   #MODE_OLDFILE,d2                                     ; Load MODE_OLDFILE into d2 for Open()
	jsr      _LVOOpen(a6)                                     ; Call OpenIntuition() — open intuition
	lea      Var_FileHandle(pc),a0                        ; Point a0 at open file handle
	move.l   d0,(a0)                                      ; Store d0 as open file handle
	beq.w    Loc_HandleFileNotFoundError                  ; Handle file not found error if zero/equal
	bra.w    Loc_Dialog_Done                              ; Jump to Loc_Dialog_Done — dialog done
Loc_Dialog_Done:
	lea      Var_ProgressWindowTop(pc),a0                 ; Point a0 at progress window top
	move.w   #$100,$c(a0)                                 ; Write $100 to offset $c(a0)
	lea      Var_OperationCancelledFlag(pc),a0            ; Point a0 at user cancellation flag
	sf.b     (a0)                                         ; Clear cancellation flag to $00 (false)
	bsr.w    Func_OpenProgressWindow                      ; Call Func_OpenProgressWindow — open progress window
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_Dialog_AllocError                        ; Dialog alloc error if non-zero/not equal — checked value at (a0)
	bsr.w    Func_HandleStatusProgress                    ; Call Func_HandleStatusProgress — handle status progress
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	bsr.w    Func_CloseProgressWindow                     ; Call Func_CloseProgressWindow — close progress window
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	moveq    #-2,d2                                       ; Quick load constant value #$fe into register d2
	jsr      _LVOLock(a6)                                 ; Obtain a shared lock on the source file
	lea      Var_TempFileHandle(pc),a0                    ; Point a0 at temp file handle
	move.l   d0,(a0)                                      ; Save function return value as tempfilehandle
	beq.w    Loc_HandleFileLoadError                      ; Handle file load error if zero/equal
	move.l   Var_TempFileHandle(pc),d1                    ; Load temp file handle into d1
	move.l   Var_FIBPointer(pc),d2                        ; Load FileInfoBlock buffer into d2
	jsr      _LVOExamine(a6)                              ; Examine the locked file to get its metadata/size
	move.l   d0,-(a7)                                     ; Save d0 on stack
	move.l   Var_TempFileHandle(pc),d1                    ; Load temp file handle into d1
	jsr      _LVOUnLock(a6)                               ; Release duplicated directory lock
	lea      Var_TempFileHandle(pc),a0                    ; Point a0 at temp file handle
	clr.l    (a0)                                         ; Zero Var_TempFileHandle
	move.l   (a7)+,d0                                     ; Restore d0 from stack
	beq.w    Loc_HandleFileLoadError                      ; Handle file load error if zero/equal
	movea.l  Var_FIBPointer(pc),a0                        ; Load FileInfoBlock buffer into a0
	move.l   fib_Size(a0),d0                                   ; Read offset fib_Size(a0) into d0
	add.l    Var_DirectoryEntryBuffer(pc),d0              ; Add directory entry buffer to d0
	bsr.w    Func_OpenCustomScreen                        ; Call Func_OpenCustomScreen — open custom screen
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_Dialog_AllocError                        ; Dialog alloc error if non-zero/not equal — checked value at (a0)
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	move.l   Var_PayloadBuffer(pc),d2                     ; Load packed/unpacked file data buffer into d2
	add.l    Var_DirectoryEntryBuffer(pc),d2              ; Add directory entry buffer to d2
	movea.l  Var_FIBPointer(pc),a0                        ; Load FileInfoBlock buffer into a0
	move.l   d2,d4                                        ; Copy file data buffer to d4
	add.l    fib_Size(a0),d4                                   ; Add fib_Size(a0) to d4
	lea      Var_UnusedWorkspace(pc),a1                   ; Point a1 at workspace end pointer
	move.l   d2,(a1)+                                     ; Store d2 as workspace end pointer
	move.l   d4,(a1)                                      ; Store d4 as workspace end pointer
	move.l   fib_Size(a0),d3                                   ; Read offset fib_Size(a0) into d3
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	jsr      _LVORead(a6)                                 ; Read hunk header/segment bytes from file
	movea.l  Var_FIBPointer(pc),a0                        ; Load FileInfoBlock buffer into a0
	move.l   fib_Size(a0),d3                                   ; Read offset fib_Size(a0) into d3
	cmp.l    d0,d3                                        ; Compare d0 with d3
	bne.w    Loc_HandleAllocError                         ; Handle alloc error if non-zero/not equal — checked d0,d3
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_OpenFileOld:
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
Loop_OpenFileOld_CopyPath:
	move.b   (a1)+,(a0)+                                  ; Copy one byte to destination
	bne.w    Loop_OpenFileOld_CopyPath                    ; Open file old copy path if non-zero/not equal
	subq.l   #$1,a0                                       ; Decrement a0 by one
	lea      Var_DialogSuffixString(pc),a1                ; Point a1 at dialog filename suffix string
Loop_OpenFileOld_AppendSuffix:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	bne.w    Loop_OpenFileOld_AppendSuffix                ; Open file old append suffix if non-zero/not equal
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	lea      Var_FilePathBuffer(pc),a0                    ; Point a0 at file path string buffer
	move.l   a0,d1                                        ; Pass file path pointer in d1 for dos.library call
	move.l   #MODE_OLDFILE,d2                                     ; Load MODE_OLDFILE into d2 for Open()
	jsr      _LVOOpen(a6)                                     ; Open file for reading or writing (_LVOOpen)
	lea      Var_FileHandle(pc),a0                        ; Point a0 at open file handle
	move.l   d0,(a0)                                      ; Store d0 as open file handle
	beq.w    Loc_HandleFileNotFoundError                  ; Handle file not found error if zero/equal
	bsr.w    Func_ClearHeaderBuffer                       ; Call Func_ClearHeaderBuffer — clear header buffer
	moveq    #$8,d3                                       ; Set d3 to 8 ($8)
	bsr.w    Func_ReadFileHeader                          ; Call Func_ReadFileHeader — read file header
	cmp.b    #$ff,d0                                      ; Compare return value from Func_ReadFileHeader against $ff (255)
	beq.w    Loc_HandleFileLoadError                      ; Handle file load error if zero/equal — d0 vs $ff — checked #$ff,d0
	lea      Var_HeaderBuffer(pc),a0                      ; Point a0 at header buffer
	cmpi.l   #$3f3,(a0)                                   ; Compare #$3f3 with (a0)
	bne.w    Loop_Dialog_ErrorCleanup                     ; Dialog error cleanup if non-zero/not equal — checked #$3f3,(a0)
	lea      Var_ProgressWindowTop(pc),a0                 ; Point a0 at progress window top
	move.w   #$0,$c(a0)                                   ; Write $0 to offset $c(a0)
	lea      Var_OperationCancelledFlag(pc),a0            ; Point a0 at user cancellation flag
	st.b     (a0)                                         ; Set cancellation flag to $FF (true)
	bsr.w    Func_OpenProgressWindow                      ; Call Func_OpenProgressWindow — open progress window
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loc_Dialog_AllocError                        ; Dialog alloc error if non-zero/not equal — checked value at (a0)
	bsr.w    Func_HandleStatusProgress                    ; Call Func_HandleStatusProgress — handle status progress
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if non-zero/not equal — checked value at (a0)
	bsr.w    Func_CloseProgressWindow                     ; Call Func_CloseProgressWindow — close progress window
Func_LoadFileAndVerify:
	lea      Var_FileSize(pc),a0                          ; Point a0 at file size
	clr.l    (a0)                                         ; Zero Var_FileSize
	lea      Var_PrintFormattingZero(pc),a0               ; Point a0 at empty/zero text formatting entry
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Str_HunkHeaderEndDebug(pc),a0                ; Point a0 at hunk header end debug
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	lea      Var_HeaderBuffer(pc),a0                      ; Point a0 at header buffer
	tst.l    $4(a0)                                       ; Test register/value $4(a0) for zero or negative condition status
	beq.w    Loc_LoadFile_VerifyHunkTable                 ; Load file verify hunk table if zero/equal — checked $4(a0)
Loop_LoadFileAndVerify_Wait:
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	bsr.w    Func_ReadFileHeader                          ; Call Func_ReadFileHeader — read file header
	cmp.b    #$ff,d0                                      ; Compare return value from Func_ReadFileHeader against $ff (255)
	beq.w    Loc_HandleFileLoadError                      ; Handle file load error if zero/equal — d0 vs $ff — checked #$ff,d0
	lea      Var_HeaderBuffer(pc),a0                      ; Point a0 at header buffer
	tst.l    (a0)                                         ; Check whether Var_HeaderBuffer value is zero
	bne.w    Loop_LoadFileAndVerify_Wait                  ; Load file and verify wait if non-zero/not equal — checked value at (a0)
Loc_LoadFile_VerifyHunkTable:
	moveq    #$c,d3                                       ; Set d3 to 12 ($c)
	bsr.w    Func_ReadFileHeader                          ; Call Func_ReadFileHeader — read file header
	cmp.b    #$ff,d0                                      ; Compare return value from Func_ReadFileHeader against $ff (255)
	beq.w    Loc_HandleFileLoadError                      ; Handle file load error if zero/equal — d0 vs $ff — checked #$ff,d0
	lea      Var_DestBufferPointer(pc),a1                 ; Point a1 at dest buffer pointer
	move.l   Var_HeaderBuffer(pc),(a1)                    ; Load Var_HeaderBuffer into (a1)
	lea      Str_HunkNumber(pc),a0                        ; Point a0 at hunk number
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	movea.l  Var_HeaderBuffer(pc),a0                      ; Load header buffer into a0
	bsr.w    Func_FormatFloppyTrackText                   ; Call Func_FormatFloppyTrackText — format floppy track text
	move.l   Var_DestBufferPointer(pc),d3                 ; Load dest buffer pointer into d3
	lsl.l    #$2,d3                                       ; Multiply destbufferpointer by 4 (shift left 2)
	bsr.w    Func_ReadFileHeader                          ; Call Func_ReadFileHeader — read file header
	cmp.b    #$ff,d0                                      ; Compare return value from Func_ReadFileHeader against $ff (255)
	beq.w    Loc_HandleFileLoadError                      ; Handle file load error if zero/equal — d0 vs $ff — checked #$ff,d0
	move.l   Var_DestBufferPointer(pc),d0                 ; Load dest buffer pointer into d0
	moveq    #$0,d2                                       ; Clear value 0 to zero
	lea      Var_HeaderBuffer(pc),a0                      ; Point a0 at header buffer
	move.l   (a0),d1                                      ; Load value from (a0) into d1
	clr.l    (a0)+                                        ; Zero Var_HeaderBuffer
Loop_LoadFileAndVerify_Delay:
	andi.l   #$ffffff,d1                                  ; ANDI.L #$ffffff,d1
	lsl.l    #$2,d1                                       ; Multiply d1 by 4 (shift left 2)
	add.l    d1,d2                                        ; Add d1 to d2
	move.l   (a0),d1                                      ; Load value from (a0) into d1
	move.l   d2,(a0)+                                     ; Store d2 at address in a0
	subq.l   #$1,d0                                       ; Decrement d0 by one
	bne.w    Loop_LoadFileAndVerify_Delay                 ; Load file and verify delay if non-zero/not equal — checked counter after subq.l
	lea      Var_PayloadBufferSize(pc),a6                 ; Point a6 at allocated payload buffer size
	add.l    Var_DirectoryEntryBuffer(pc),d2              ; Add directory entry buffer to d2
	addq.l   #$4,d2                                       ; Add 4 ($4) to d2
	move.l   d2,(a6)                                      ; Store d2 as allocated payload buffer size
	move.l   d2,d0                                        ; Copy d2 to d0
	move.l   #$10000,d1                                   ; Load MEMF_CHIP allocation flag
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jsr      _LVOOpenScreen(a6)                           ; Open custom screen for the packer UI
	lea      Var_PayloadBuffer(pc),a6                     ; Point a6 at packed/unpacked file data buffer
	move.l   d0,(a6)                                      ; Store d0 as packed/unpacked file data buffer
	beq.w    Loc_Dialog_AllocError                        ; Dialog alloc error if zero/equal
	lea      Var_ReadBytesSize(pc),a6                     ; Point a6 at read bytes size
	add.l    Var_DirectoryEntryBuffer(pc),d0              ; Add directory entry buffer to d0
	move.l   d0,(a6)                                      ; Save result of _LVOOpenScreen as readbytessize
	lea      Var_UnusedWorkspace(pc),a6                   ; Point a6 at workspace end pointer
	move.l   d0,(a6)                                      ; Store d0 as workspace end pointer
Loc_LoadFile_ReadHunkHeader:
	bsr.w    Func_ReadPayloadBytes                        ; Call Func_ReadPayloadBytes — read payload bytes
	cmp.b    #$ff,d0                                      ; Compare return value from Func_ReadPayloadBytes against $ff (255)
	beq.w    Loc_HandleAllocError                         ; Handle alloc error if zero/equal — d0 vs $ff — checked #$ff,d0
	move.l   #$3f6,d1                                     ; Set d1 to 1014 ($3f6)
	movea.l  Var_ReadBytesSize(pc),a0                     ; Load read bytes size into a0
	andi.l   #$ffffff,(a0)                                ; ANDI.L #$ffffff,(a0)
	move.l   (a0),d0                                      ; Load value from (a0) into d0
	sub.l    d0,d1                                        ; Subtract d0 from d1
	bcs.w    Loc_HandleUnsupportedHunkError               ; Handle unsupported hunk error if carry set (less than / lower)
	cmp.w    #$10,d1                                      ; Check if d1 equals $10 (16)
	bcc.w    Loc_HandleUnsupportedHunkError               ; Handle unsupported hunk error if carry clear (greater or equal) — checked #$10,d1
	move.l   d1,-(a7)                                     ; Save d1 on stack
	mulu.w   #$e,d1                                       ; Multiply d1 by 14 ($e)
	lea      Str_HunkBreakOverlay(pc),a0                  ; Point a0 at hunk break overlay
	lea      (a0,d1.w),a0                                 ; Load effective address
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	move.l   (a7)+,d1                                     ; Restore d1 from stack
	lsl.l    #$2,d1                                       ; Multiply d1 by 4 (shift left 2)
	lea      Loc_LoadFile_AllocHunks(pc),a0               ; Point a0 at load file alloc hunks
	jmp      (a0,d1.w)                                    ; Jump to (a0,d1.w)
; ============================================================================
; Function: Loc_LoadFile_AllocHunks
; Purpose : Handles hunk type dispatching or processing for loaded hunks
; ============================================================================
Loc_LoadFile_AllocHunks:
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 0 (code)
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 1
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 2
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 3
	bra.w    Loc_LoadHunk_Debug_Entry                     ; Dispatch to Hunk Debug processing
	bra.w    Loc_LoadHunk_Symbol_Entry                    ; Dispatch to Hunk Symbols processing
	bra.w    Loc_LoadHunk_Reloc32_Entry                   ; Dispatch to Hunk Reloc32 processing
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 7
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 8
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 9
	bra.w    Loc_LoadHunk_BSS_Entry                       ; Dispatch to Hunk BSS allocation
	bra.w    Loc_LoadHunk_Data_Entry                      ; Dispatch to Hunk Data loading
	bra.w    Loc_LoadHunk_Code_Entry                      ; Dispatch to Hunk Code loading
	bra.w    Loc_LoadHunk_Code_Entry                      ; Dispatch to Hunk Code loading
	bra.w    Loc_LoadHunk_Symbol_Entry                    ; Dispatch to Hunk Symbols processing
	bra.w    Loc_HandleUnsupportedHunkError               ; Dispatch table entry for hunk 15
Loc_LoadHunk_PrepSymbolName:
	lea      Str_HunkNr(pc),a0                            ; Point a0 at hunk nr
	bsr.w    Loop_RenderText_Height                       ; Print status message to status area
	movea.l  Var_FileSize(pc),a0                          ; Store variable or pointer
	bra.w    Func_FormatFloppyTrackText                   ; Branch always to next segment
Loc_LoadHunk_IncrementCount:
	lea      Var_FileSize(pc),a0                          ; Point a0 at loaded file size
	addq.l   #$1,(a0)                                     ; Add offset pointer
	rts                                                   ; Return to caller

; ============================================================================
; Function: Loc_LoadHunk_Code_Entry
; Purpose : Handles hunk type dispatching or processing for loaded hunks
; ============================================================================
Loc_LoadHunk_Code_Entry:
	bsr.w    Loc_LoadHunk_IncrementCount                  ; Increment active segment counter
	bsr.w    Loc_LoadHunk_PrepSymbolName                  ; Read segment name length and skip
	bsr.w    Func_ReadPayloadBytes                        ; Read next longword from file
	cmp.b    #$ff,d0                                      ; Check status result
	beq.w    Loc_HandleAllocError                         ; Branch on condition
	movea.l  Var_ReadBytesSize(pc),a0                     ; Store variable or pointer
	move.l   (a0),d3                                      ; Store variable or pointer
	lsl.l    #$2,d3                                       ; Scale size by 4 to convert to bytes
	bsr.w    Func_ReadPayloadBytes+2                      ; Read next payload size word
	cmp.b    #$ff,d0                                      ; Check status result
	beq.w    Loc_HandleAllocError                         ; Branch on condition
	move.l   d0,-(a7)                                     ; Store variable or pointer
	lea      Str_HunkLength(pc),a0                        ; Point a0 at hunk length
	bsr.w    Loop_RenderText_Height                       ; Print status message to status area
	movea.l  (a7),a0                                      ; Store variable or pointer
	bsr.w    Func_FormatFloppyTrackText                   ; Format floppy track size to display text
	lea      Var_ReadBytesSize(pc),a0                     ; Point a0 at readbytessize
	move.l   (a0),d1                                      ; Store variable or pointer
	add.l    (a7)+,d1                                     ; Add offset pointer
	move.l   d1,(a0)                                      ; Store variable or pointer
	bra.w    Loc_LoadFile_ReadHunkHeader                  ; Branch always to next segment

; ============================================================================
; Function: Loc_LoadHunk_Data_Entry
; Purpose : Handles hunk type dispatching or processing for loaded hunks
; ============================================================================
Loc_LoadHunk_Data_Entry:
	bsr.w    Loc_LoadHunk_IncrementCount                  ; Increment active segment counter
	bsr.w    Loc_LoadHunk_PrepSymbolName                  ; Read segment name length and skip
	bsr.w    Func_ReadPayloadBytes                        ; Read next longword from file
	cmp.b    #$ff,d0                                      ; Check status result
	beq.w    Loc_HandleAllocError                         ; Branch on condition
	lea      Str_HunkLength(pc),a0                        ; Point a0 at hunk length
	bsr.w    Loop_RenderText_Height                       ; Print status message to status area
	movea.l  Var_ReadBytesSize(pc),a0                     ; Store variable or pointer
	move.l   (a0),d7                                      ; Store variable or pointer
	lsl.l    #$2,d7                                       ; Scale size by 4 to convert to bytes
	movea.l  d7,a0                                        ; Load variable or pointer
	bsr.w    Func_FormatFloppyTrackText                   ; Format floppy track size to display text
	lea      Var_ReadBytesSize(pc),a0                     ; Point a0 at readbytessize
	movea.l  (a0),a1                                      ; Store variable or pointer
	move.l   (a1),d0                                      ; Store variable or pointer
	lsl.l    #$2,d0                                       ; Scale size by 4 to convert to bytes
	movea.l  a1,a2                                        ; Load variable or pointer
	move.l   d0,d1                                        ; Load variable or pointer
	bcs.w    .skip_data_clear                             ; Branch on condition
.clear_data_loop:
	clr.b    (a2)+                                        ; Clear block data bytes
	subq.l   #$1,d1                                       ; Decrement d1 by one
	bne.b    .clear_data_loop                             ; Branch on condition
.skip_data_clear:
	adda.l   d0,a1                                        ; Add offset pointer
	move.l   a1,(a0)                                      ; Store variable or pointer
	bra.w    Loc_LoadFile_ReadHunkHeader                  ; Branch always to next segment

; ============================================================================
; Function: Loc_LoadHunk_BSS_Entry
; Purpose : Handles hunk type dispatching or processing for loaded hunks
; ============================================================================
Loc_LoadHunk_BSS_Entry:
	bsr.w    Func_ReadPayloadBytes                        ; Read next longword from file
	cmp.b    #$ff,d0                                      ; Check status result
	beq.w    Loc_HandleAllocError                         ; Branch on condition
	movea.l  Var_ReadBytesSize(pc),a0                     ; Store variable or pointer
	tst.l    (a0)                                         ; 
	beq.w    Loc_LoadFile_ReadHunkHeader                  ; Branch on condition
	move.l   (a0),d0                                      ; Store variable or pointer
	lsl.l    #$2,d0                                       ; Scale size by 4 to convert to bytes
	move.l   d0,-(a7)                                     ; Store variable or pointer
	lea      Var_HunkLoad_AllocSz(pc),a0                  ; Point a0 at hunkload allocsz
	move.l   d0,(a0)                                      ; Store variable or pointer
	bsr.w    Loc_LoadHunk_AllocMem                        ; Call local subroutine
	beq.w    Loc_LoadHunk_AllocError                      ; Branch on condition
	bsr.w    Func_ReadPayloadBytes                        ; Read next longword from file
	cmp.b    #$ff,d0                                      ; Check status result
	beq.w    Loc_HandleAllocError                         ; Branch on condition
	movea.l  Var_ReadBytesSize(pc),a0                     ; Store variable or pointer
	move.l   (a7),d3                                      ; Store variable or pointer
	move.l   (a0),-(a7)                                   ; Store variable or pointer
	move.l   Var_HunkLoad_AllocPtr(pc),d2                 ; Store variable or pointer
	bsr.w    Loc_ReadFile                                 ; Call local subroutine
	cmp.b    #$ff,d0                                      ; Check status result
	beq.w    Loc_HandleAllocError                         ; Branch on condition
	move.l   Var_FileSize(pc),d1                          ; Store variable or pointer
	subq.l   #$1,d1                                       ; Decrement d1 by one
	lsl.l    #$2,d1                                       ; Scale size by 4 to convert to bytes
	lea      Var_HeaderBuffer(pc),a0                      ; Point a0 at headerbuffer
	movea.l  (a0,d1.w),a2                                 ; Store variable or pointer
	adda.l   Var_UnusedWorkspace(pc),a2                   ; Add offset pointer
	movem.l  (a7)+,d1-d2                                  ; Restore registers from stack
	movea.l  Var_HunkLoad_AllocPtr(pc),a0                 ; Store variable or pointer
	lea      Var_HeaderBuffer(pc),a1                      ; Point a1 at headerbuffer
	lsl.l    #$2,d1                                       ; Scale size by 4 to convert to bytes
	move.l   (a1,d1.l),d0                                 ; Store variable or pointer
	add.l    Var_RemainingHunkBytes(pc),d0                ; Add offset pointer
	moveq    #0,d5                                        ; 
.reloc_copy_loop:
	move.l   (a0,d5.l),d3                                 ; Store variable or pointer
	add.l    d0,(a2,d3.l)                                 ; Add offset pointer
	addq.l   #4,d5                                        ; Add offset pointer
	cmp.l    d5,d2                                        ; Check status result
	bne.w    .reloc_copy_loop                             ; Branch on condition
	bsr.w    Loc_LoadHunk_FreeMem                         ; Call local subroutine
	bra.w    Loc_LoadHunk_BSS_Entry                       ; Branch always to next segment
Loc_LoadHunk_AllocMem:
	move.l   #$10000,d1                                   ; Load variable or pointer
	movea.l  ExecBase.w,a6                                ; Load variable or pointer
	jsr      _LVOAllocMem(a6)                             ; Allocate memory block for hunk loading
	lea      Var_HunkLoad_AllocPtr(pc),a6                 ; Point a6 at hunkload allocptr
	move.l   d0,(a6)                                      ; Store variable or pointer
	rts                                                   ; Return to caller
Loc_LoadHunk_FreeMem:
	movea.l  Var_HunkLoad_AllocPtr(pc),a1                 ; Store variable or pointer
	move.l   Var_HunkLoad_AllocSz(pc),d0                  ; Store variable or pointer
	movea.l  ExecBase.w,a6                                ; Load variable or pointer
	jmp      _LVOFreeMem(a6)                                     ; Call FreeMem to free allocated workspace
Loc_LoadHunk_AllocError:
	lea      Str_Err_NotEnoughMemory(pc),a0               ; Point a0 at err not enough memory
	bsr.w    Func_RenderTextAlt                           ; Call local subroutine
	bra.w    Loc_HandleUnsupportedHunkError               ; Branch always to next segment

; ============================================================================
; Function: Loc_LoadHunk_Reloc32_Entry
; Purpose : Handles hunk type dispatching or processing for loaded hunks
; ============================================================================
Loc_LoadHunk_Reloc32_Entry:
	bsr.w    Func_ReadPayloadBytes                        ; Read next longword from file
	cmp.b    #$ff,d0                                      ; Check status result
	beq.w    Loc_HandleAllocError                         ; Branch on condition
	movea.l  Var_ReadBytesSize(pc),a0                     ; Store variable or pointer
	cmpi.l   #$3f2,(a0)                                   ; Check status result
	bne.w    Loc_LoadHunk_Reloc32_Entry                   ; Branch on condition
	bra.w    Loc_LoadFile_ReadHunkHeader                  ; Branch always to next segment

; ============================================================================
; Function: Loc_LoadHunk_Symbol_Entry
; Purpose : Handles hunk type dispatching or processing for loaded hunks
; ============================================================================
Loc_LoadHunk_Symbol_Entry:
	bsr.w    Loc_LoadHunk_IncrementCount                  ; Increment active segment counter
	bsr.w    Loc_LoadHunk_PrepSymbolName                  ; Read segment name length and skip
	bsr.w    Func_ReadPayloadBytes                        ; Read next longword from file
	cmp.b    #$ff,d0                                      ; Check status result
	lea      Str_HunkLength(pc),a0                        ; Point a0 at hunk length
	bsr.w    Loop_RenderText_Height                       ; Print status message to status area
	movea.l  Var_ReadBytesSize(pc),a0                     ; Store variable or pointer
	movea.l  (a0),a0                                      ; Store variable or pointer
	bsr.w    Func_FormatFloppyTrackText                   ; Format floppy track size to display text
	movea.l  Var_ReadBytesSize(pc),a0                     ; Store variable or pointer
	move.l   (a0),d3                                      ; Store variable or pointer
	lsl.l    #$2,d3                                       ; Scale size by 4 to convert to bytes
	bsr.w    Func_ReadPayloadBytes+2                      ; Read next payload size word
	cmp.b    #$ff,d0                                      ; Check status result
	bra.w    Loc_LoadFile_ReadHunkHeader                  ; Branch always to next segment

; ============================================================================
; Function: Loc_LoadHunk_Debug_Entry
; Purpose : Handles hunk type dispatching or processing for loaded hunks
; ============================================================================
Loc_LoadHunk_Debug_Entry:
	lea      Var_DestBufferPointer(pc),a0                 ; Point a0 at destbufferpointer
	subq.l   #$1,(a0)                                     ; Decrement (a0) by one
	beq.w    .debug_close                                 ; Branch on condition
	bra.w    Loc_LoadFile_ReadHunkHeader                  ; Branch always to next segment
.debug_close:
	bsr.w    Func_CloseFile                               ; Call local subroutine
	lea      Var_TempLong(pc),a0                          ; Point a0 at temporary longword
	move.l   Var_ReadBytesSize(pc),(a0)                   ; Store variable or pointer
	bra.w    Loop_ClearStatusError                        ; Branch always to next segment
Func_ReadPayloadBytes:
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	move.l   Var_ReadBytesSize(pc),d2                     ; Load read bytes size into d2
	bra.w    Loc_ReadFile                                 ; Jump to Loc_ReadFile — read file
Loop_ConvertHex_LowerChar:
	cmpi.b   #$66,(a0,d1.w)                               ; Compare operands to test comparison conditions
	bhi.w    Loop_ConvertHex_Error                        ; Convert hex error if unsigned greater — checked #$66,(a0,d1.w)
	cmpi.b   #$61,(a0,d1.w)                               ; Compare operands to test comparison conditions
	bcs.w    Loop_ConvertHex_Error                        ; Convert hex error if carry set (less than / lower) — checked #$61,(a0,d1.w)
	subi.b   #$20,(a0,d1.w)                               ; Subtract value
	bra.w    Loc_ConvertHex_HexDigit                      ; Jump to Loc_ConvertHex_HexDigit — convert hex hex digit
Loop_ConvertHex_UpperChar:
	cmpi.b   #$46,(a0,d1.w)                               ; Compare operands to test comparison conditions
	bhi.w    Loop_ConvertHex_LowerChar                    ; Convert hex lower char if unsigned greater — checked #$46,(a0,d1.w)
	cmpi.b   #$41,(a0,d1.w)                               ; Compare operands to test comparison conditions
	bcs.w    Loop_ConvertHex_Error                        ; Convert hex error if carry set (less than / lower) — checked #$41,(a0,d1.w)
	bra.w    Loc_ConvertHex_HexDigit                      ; Jump to Loc_ConvertHex_HexDigit — convert hex hex digit
Loop_ConvertHex_Error:
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Func_ConvertHexStringToLong:
	movea.l  a0,a1                                        ; Copy a0 to a1
Loop_ConvertHex_FindLength:
	tst.b    (a1)+                                        ; Test byte at (a1) for zero
	bne.w    Loop_ConvertHex_FindLength                   ; Convert hex find length if non-zero/not equal — checked value at (a1)
	suba.l   a0,a1                                        ; Subtract a0 from a1
	subq.l   #$2,a1                                       ; Subtract 2 ($2) from a1
	move.l   a1,d1                                        ; Copy a1 to d1
	move.l   a1,d0                                        ; Copy a1 to d0
Loop_ConvertHex_Process:
	cmpi.b   #$39,(a0,d1.w)                               ; Compare operands to test comparison conditions
	bhi.w    Loop_ConvertHex_UpperChar                    ; Convert hex upper char if unsigned greater — checked #$39,(a0,d1.w)
Loc_ConvertHex_HexDigit:
	cmpi.b   #$30,(a0,d1.w)                               ; Compare operands to test comparison conditions
	bcs.w    Loop_ConvertHex_Error                        ; Convert hex error if carry set (less than / lower) — checked #$30,(a0,d1.w)
	dbra     d1,Loop_ConvertHex_Process                   ; Decrement d1 and loop to Loop_ConvertHex_Process until done
	moveq    #$0,d1                                       ; Clear value 0 to zero
	moveq    #$0,d4                                       ; Clear value 0 to zero
Loop_ConvertHex_Shift:
	moveq    #$0,d2                                       ; Clear value 0 to zero
	move.b   (a0,d1.w),d2                                 ; Copy register or memory value
	cmp.b    #$41,d2                                      ; Check if d2 equals $41 (65)
	bcs.w    Loc_ConvertHex_Done                          ; Convert hex done if carry set (less than / lower) — checked #$41,d2
	subi.b   #$7,d2                                       ; Subtract #$7 from d2
Loc_ConvertHex_Done:
	subi.b   #$30,d2                                      ; Subtract #$30 from d2
	move.l   d0,d3                                        ; Copy return value to d3
	lsl.l    #$2,d3                                       ; Multiply d3 by 4 (shift left 2)
	lsl.l    d3,d2                                        ; Shift d2 left by d3 bits
	or.l     d2,d4                                        ; OR.L d2,d4
	addq.b   #$1,d1                                       ; Add #$1 to d1
	subq.b   #$1,d0                                       ; Decrement d0 by one
	bcc.w    Loop_ConvertHex_Shift                        ; Convert hex shift if carry clear (greater or equal)
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_ClearHeaderBuffer:
	lea      Var_HeaderBuffer(pc),a3                      ; Point a3 at header buffer
	moveq    #$0,d0                                       ; Clear value 0 to zero
Loop_ClearHeaderBuffer:
	clr.l    (a3,d0.w)                                    ; Clear target memory location
	addq.w   #$4,d0                                       ; Add 4 ($4) to d0
	cmp.w    #$400,d0                                     ; Check if d0 equals $400 (1024)
	bcs.w    Loop_ClearHeaderBuffer                       ; Clear header buffer if carry set (less than / lower) — checked #$400,d0
	rts                                                   ; Return to caller
Func_CopyBytesBackward:
	movea.l  Var_PayloadBuffer(pc),a0                     ; Load packed/unpacked file data buffer into a0
	movea.l  a2,a1                                        ; Copy a2 to a1
	movea.l  a2,a3                                        ; Copy a2 to a3
	adda.l   Var_DirectoryEntryBuffer(pc),a3              ; Advance a3 by directory entry buffer
Loop_CopyBytesBackward:
	move.b   -(a1),-(a3)                                  ; Copy -(a1) to -(a3)
	cmpa.l   a1,a0                                        ; Compare a1 with a0
	bne.w    Loop_CopyBytesBackward                       ; Copy bytes backward if non-zero/not equal — checked a1,a0
	rts                                                   ; Return to caller
	dc.b $74
	dc.b $01
	dc.b $76
	dc.b $00
	dc.b $12
	dc.b $30
	dc.b $00
	dc.b $00
	dc.b $04
	dc.b $01
	dc.b $00
	dc.b $30
	dc.b $67
	dc.b $00
	dc.b $00
	dc.b $0A
	dc.b $D6
	dc.b $82
	dc.b $53
	dc.b $01
	dc.b $66
	dc.b $00
	dc.b $FF
	dc.b $FA
	dc.b $28
	dc.b $02
	dc.b $E5
	dc.b $8A
	dc.b $D4
	dc.b $84
	dc.b $E3
	dc.b $8A
	dc.b $51
	dc.b $C8
	dc.b $FF
	dc.b $E2
	dc.b $60
	dc.b $00
	dc.b $14
	dc.b $84
Func_OpenCustomScreen:
	lea      Var_PayloadBufferSize(pc),a6                 ; Point a6 at allocated payload buffer size
	move.l   d0,(a6)                                      ; Store d0 as allocated payload buffer size
	move.l   #$10000,d1                                   ; Load MEMF_CHIP allocation flag
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jsr      _LVOOpenScreen(a6)                           ; Open custom screen for the packer UI
	lea      Var_PayloadBuffer(pc),a6                     ; Point a6 at packed/unpacked file data buffer
	move.l   d0,(a6)                                      ; Store d0 as packed/unpacked file data buffer
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_OpenProgressWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_ProgressWindowStruct(pc),a0              ; Point a0 at progress window struct
	jsr      _LVOOpenWindow(a6)                           ; Open standard custom packer window
	lea      Var_ProgressWindowPointer(pc),a0             ; Point a0 at progress indicator window pointer
	move.l   d0,(a0)                                      ; Store d0 as progress indicator window pointer
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_CloseProgressWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_ProgressWindowPointer(pc),a0             ; Load progress indicator window pointer into a0
	jmp      _LVOCloseWindow(a6)                                     ; Close window (_LVOCloseWindow)
Func_OpenStatusWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_Window_WorkStruct(pc),a0                 ; Point a0 at window work struct
	jsr      _LVOOpenWindow(a6)                           ; Open standard custom packer window
	lea      Var_StatusWindowPointer(pc),a0               ; Point a0 at status window pointer
	move.l   d0,(a0)                                      ; Save result of _LVOOpenWindow as statuswindowpointer
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_CloseStatusWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_StatusWindowPointer(pc),a0               ; Load status window pointer into a0
	jmp      _LVOCloseWindow(a6)                                     ; Close window (_LVOCloseWindow)
Func_GetAndReplyStatusMsg:
	bsr.w    Func_WaitStatusWindowPort                    ; Call Func_WaitStatusWindowPort — wait status window port
	movea.l  Var_StatusWindowPointer(pc),a0               ; Load status window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jsr      _LVOGetMsg(a6)                               ; Retrieve startup message from MsgPort
	lea      Var_LastIntuiMessage(pc),a1                  ; Point a1 at last received IntuiMessage pointer
	move.l   d0,(a1)                                      ; Store d0 as last received IntuiMessage pointer
	movea.l  d0,a1                                        ; Save _LVOGetMsg result in a1
	beq.w    Func_GetAndReplyStatusMsg                    ; Get and reply status msg if zero/equal
	jmp      _LVOReplyMsg(a6)                                    ; Tail-call ReplyMsg() — acknowledge IntuiMessage
Func_WaitStatusWindowPort:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_StatusWindowPointer(pc),a0               ; Load status window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jmp      _LVOWaitPort(a6)                                    ; Wait for message to arrive on port (_LVOWaitPort)
Func_OpenAndHandleStatus:
	lea      Var_StatusWindowIText(pc),a0                 ; Point a0 at status window itext
Loop_Status_EventLoop:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_StatusWindowPointer(pc),a1               ; Load status window pointer into a1
	suba.l   a2,a2                                        ; Clear a2 to zero (self-subtract)
	jsr      _LVOFreeSysRequest(a6)                       ; Free the status/progress requester window
Loop_Status_WaitMsg:
	bsr.w    Func_GetAndReplyStatusMsg                    ; Call Func_GetAndReplyStatusMsg — get and reply status msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$200,d0                                     ; Compare return value from Func_GetAndReplyStatusMsg against $200 (512)
	beq.w    Loc_Status_Close                             ; Status close if zero/equal — d0 vs $200 — checked #$200,d0
	cmp.w    #$40,d0                                      ; Compare return value from Func_GetAndReplyStatusMsg against $40 (64)
	beq.w    Loc_Status_HandleGadget                      ; Status handle gadget if zero/equal — d0 vs $40 — checked #$40,d0
	cmp.w    #$8,d0                                       ; Check if d0 equals $8 (8)
	beq.w    Func_OpenAndHandleStatus                     ; Open and handle status if zero/equal — d0 vs $8 — checked #$8,d0
	bra.w    Loop_Status_WaitMsg                          ; Jump to Loop_Status_WaitMsg — status wait msg
Loc_Status_Close:
	lea      Str_UserBreak(pc),a0                         ; Load pointer to "User break !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_CloseStatusWindow                       ; Call Func_CloseStatusWindow — close status window
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_Status_HandleGadget:
	movea.l  im_IAddress(a0),a1                                   ; Load IntuiMessage im_IAddress field (sender object pointer)
	move.l   $26(a1),d0                                   ; Read offset $26(a1) into d0
	beq.w    Loc_Status_Done                              ; Status done if zero/equal
	cmp.w    #$1,d0                                       ; Check if d0 equals $1 (1)
	beq.w    Loc_Status_UpdateProgress                    ; Status update progress if zero/equal — d0 vs $1 — checked #$1,d0
	cmp.w    #$2,d0                                       ; Check if d0 equals $2 (2)
	beq.w    Loc_Status_Cancel                            ; Status cancel if zero/equal — d0 vs $2 — checked #$2,d0
	cmp.w    #$3,d0                                       ; Check if d0 equals $3 (3)
	beq.w    Loc_Status_NoCancel                          ; Status no cancel if zero/equal — d0 vs $3 — checked #$3,d0
	bra.w    Loop_Status_WaitMsg                          ; Jump to Loop_Status_WaitMsg — status wait msg
Loc_Status_UpdateProgress:
	lea      Var_StatusWindowIText(pc),a0                 ; Point a0 at status window itext
	lea      Var_DiskInfoWindowIText(pc),a1               ; Point a1 at disk info window itext
	tst.b    (a1)                                         ; Check whether Var_DiskInfoWindowIText value is zero
	beq.w    Loop_Status_EventLoop                        ; Status event loop if zero/equal — checked value at (a1)
	lea      Var_Window_WorkIText2(pc),a0                 ; Point a0 at window work itext2
	bra.w    Loop_Status_EventLoop                        ; Jump to Loop_Status_EventLoop — status event loop
Loc_Status_Cancel:
	lea      Var_Window_WorkIText2(pc),a0                 ; Point a0 at window work itext2
	lea      Var_DialogWindowWidth(pc),a1                 ; Point a1 at dialog window width
	tst.b    (a1)                                         ; Check whether Var_DialogWindowWidth value is zero
	beq.w    Loop_Status_EventLoop                        ; Status event loop if zero/equal — checked value at (a1)
	lea      Var_DialogWindowHeight(pc),a0                ; Point a0 at dialog window height
	bra.w    Loop_Status_EventLoop                        ; Jump to Loop_Status_EventLoop — status event loop
Loc_Status_NoCancel:
	lea      Var_DialogWindowHeight(pc),a0                ; Point a0 at dialog window height
	lea      Var_DialogIText2(pc),a1                      ; Point a1 at dialog itext2
	tst.b    (a1)                                         ; Check whether Var_DialogIText2 value is zero
	beq.w    Loop_Status_EventLoop                        ; Status event loop if zero/equal — checked value at (a1)
Loc_Status_Done:
	lea      Var_DiskInfoWindowIText(pc),a0               ; Point a0 at disk info window itext
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_StatusWindowIText(pc),a0                 ; Point a0 at status window itext
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_EventLoop                        ; Status event loop if non-zero/not equal — checked value at (a1)
	lea      Var_FloppyRemainingBytes(pc),a1              ; Point a1 at remaining bytes to read from disk
	move.l   d4,(a1)                                      ; Store d4 as remaining bytes to read from disk
	beq.w    Loop_Status_EventLoop                        ; Status event loop if zero/equal
	andi.l   #$ffff,d4                                    ; ANDI.L #$ffff,d4
	divu.w   #$200,d4                                     ; Divide d4 by 512 ($200)
	swap     d4                                           ; Swap high/low words of d4
	tst.w    d4                                           ; Test d4 for zero
	bne.w    Loop_Status_EventLoop                        ; Status event loop if non-zero/not equal — checked d4
	lea      Var_DialogWindowWidth(pc),a0                 ; Point a0 at dialog window width
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_Window_WorkIText2(pc),a0                 ; Point a0 at window work itext2
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_EventLoop                        ; Status event loop if non-zero/not equal — checked value at (a1)
	lea      Var_FloppyIOOffset(pc),a1                    ; Point a1 at current floppy disk byte offset
	move.l   d4,(a1)                                      ; Store d4 as current floppy disk byte offset
	beq.w    Loop_Status_EventLoop                        ; Status event loop if zero/equal
	andi.l   #$ffff,d4                                    ; ANDI.L #$ffff,d4
	divu.w   #$200,d4                                     ; Divide d4 by 512 ($200)
	swap     d4                                           ; Swap high/low words of d4
	tst.w    d4                                           ; Test d4 for zero
	bne.w    Loop_Status_EventLoop                        ; Status event loop if non-zero/not equal — checked d4
	lea      Var_DialogIText2(pc),a0                      ; Point a0 at dialog itext2
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_DialogWindowHeight(pc),a0                ; Point a0 at dialog window height
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_EventLoop                        ; Status event loop if non-zero/not equal — checked value at (a1)
	lea      Var_DiskUnit(pc),a1                          ; Point a1 at disk unit number (DF0-DF3)
	move.l   d4,(a1)                                      ; Store d4 as disk unit number (DF0-DF3)
	cmp.l    #$3,d4                                       ; Check if d4 equals $3 (3)
	bhi.w    Loop_Status_EventLoop                        ; Status event loop if unsigned greater — checked #$3,d4
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_OpenDiskInfoWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_Window_WorkIText(pc),a0                  ; Point a0 at window work itext
	jsr      _LVOOpenWindow(a6)                           ; Open standard custom packer window
	lea      Var_DiskInfoWinPointer(pc),a0                ; Point a0 at disk info win pointer
	move.l   d0,(a0)                                      ; Save result of _LVOOpenWindow as diskinfowinpointer
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_CloseDiskInfoWindow:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_DiskInfoWinPointer(pc),a0                ; Load disk info win pointer into a0
	jmp      _LVOCloseWindow(a6)                                     ; Close window (_LVOCloseWindow)
Func_GetAndReplyDiskInfoMsg:
	bsr.w    Func_WaitDiskInfoWindowPort                  ; Call Func_WaitDiskInfoWindowPort — wait disk info window port
	movea.l  Var_DiskInfoWinPointer(pc),a0                ; Load disk info win pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jsr      _LVOGetMsg(a6)                               ; Retrieve startup message from MsgPort
	lea      Var_LastIntuiMessage(pc),a1                  ; Point a1 at last received IntuiMessage pointer
	move.l   d0,(a1)                                      ; Store d0 as last received IntuiMessage pointer
	movea.l  d0,a1                                        ; Save _LVOGetMsg result in a1
	beq.w    Func_GetAndReplyDiskInfoMsg                  ; Get and reply disk info msg if zero/equal
	jmp      _LVOReplyMsg(a6)                                    ; Tail-call ReplyMsg() — acknowledge IntuiMessage
Func_WaitDiskInfoWindowPort:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_DiskInfoWinPointer(pc),a0                ; Load disk info win pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jmp      _LVOWaitPort(a6)                                    ; Wait for message to arrive on port (_LVOWaitPort)
Func_OpenAndHandleDiskInfo:
	lea      Var_DialogIText3(pc),a0                      ; Point a0 at dialog itext3
Loop_DiskInfo_EventLoop:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_DiskInfoWinPointer(pc),a1                ; Load disk info win pointer into a1
	suba.l   a2,a2                                        ; Clear a2 to zero (self-subtract)
	jsr      _LVOFreeSysRequest(a6)                       ; Free the status/progress requester window
Loop_DiskInfoWin_WaitMsg:
	bsr.w    Func_GetAndReplyDiskInfoMsg                  ; Call Func_GetAndReplyDiskInfoMsg — get and reply disk info msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$200,d0                                     ; Compare return value from Func_GetAndReplyDiskInfoMsg against $200 (512)
	beq.w    Loc_DiskInfo_CloseWindow                     ; Disk info close window if zero/equal — d0 vs $200 — checked #$200,d0
	cmp.w    #$40,d0                                      ; Compare return value from Func_GetAndReplyDiskInfoMsg against $40 (64)
	beq.w    Loc_DiskInfo_HandleGadget                    ; Disk info handle gadget if zero/equal — d0 vs $40 — checked #$40,d0
	cmp.w    #$8,d0                                       ; Check if d0 equals $8 (8)
	beq.w    Func_OpenAndHandleDiskInfo                   ; Open and handle disk info if zero/equal — d0 vs $8 — checked #$8,d0
	bra.w    Loop_DiskInfoWin_WaitMsg                     ; Jump to Loop_DiskInfoWin_WaitMsg — disk info win wait msg
Loc_DiskInfo_CloseWindow:
	lea      Str_UserBreak(pc),a0                         ; Load pointer to "User break !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_CloseDiskInfoWindow                     ; Call Func_CloseDiskInfoWindow — close disk info window
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_DiskInfo_HandleGadget:
	movea.l  im_IAddress(a0),a1                                   ; Load IntuiMessage im_IAddress field (sender object pointer)
	move.l   $26(a1),d0                                   ; Read offset $26(a1) into d0
	beq.w    Loc_DiskInfo_Done                            ; Disk info done if zero/equal
	cmp.w    #$1,d0                                       ; Check if d0 equals $1 (1)
	beq.w    Loc_DiskInfo_UpdateProgress                  ; Disk info update progress if zero/equal — d0 vs $1 — checked #$1,d0
	cmp.w    #$2,d0                                       ; Check if d0 equals $2 (2)
	beq.w    Loc_DiskInfo_Cancel                          ; Disk info cancel if zero/equal — d0 vs $2 — checked #$2,d0
	bra.w    Loop_DiskInfoWin_WaitMsg                     ; Jump to Loop_DiskInfoWin_WaitMsg — disk info win wait msg
Loc_DiskInfo_UpdateProgress:
	lea      Var_DialogIText4(pc),a1                      ; Point a1 at dialog itext4
	tst.b    (a1)                                         ; Check whether Var_DialogIText4 value is zero
	beq.w    Func_OpenAndHandleDiskInfo                   ; Open and handle disk info if zero/equal — checked value at (a1)
	lea      Var_DialogIText5(pc),a0                      ; Point a0 at dialog itext5
	bra.w    Loop_DiskInfo_EventLoop                      ; Jump to Loop_DiskInfo_EventLoop — disk info event loop
Loc_DiskInfo_Cancel:
	lea      Var_DialogIText5(pc),a0                      ; Point a0 at dialog itext5
	lea      Var_DialogIText6(pc),a1                      ; Point a1 at dialog itext6
	tst.b    (a1)                                         ; Check whether Var_DialogIText6 value is zero
	beq.w    Loop_DiskInfo_EventLoop                      ; Disk info event loop if zero/equal — checked value at (a1)
Loc_DiskInfo_Done:
	lea      Var_DialogIText4(pc),a0                      ; Point a0 at dialog itext4
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Func_OpenAndHandleDiskInfo                   ; Open and handle disk info if non-zero/not equal — checked value at (a1)
	lea      Var_FloppyIOOffset(pc),a1                    ; Point a1 at current floppy disk byte offset
	move.l   d4,(a1)                                      ; Store d4 as current floppy disk byte offset
	beq.w    Func_OpenAndHandleDiskInfo                   ; Open and handle disk info if zero/equal
	andi.l   #$ffff,d4                                    ; ANDI.L #$ffff,d4
	divu.w   #$200,d4                                     ; Divide d4 by 512 ($200)
	swap     d4                                           ; Swap high/low words of d4
	tst.w    d4                                           ; Test d4 for zero
	bne.w    Func_OpenAndHandleDiskInfo                   ; Open and handle disk info if non-zero/not equal — checked d4
	lea      Var_DialogIText6(pc),a0                      ; Point a0 at dialog itext6
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_DialogIText5(pc),a0                      ; Point a0 at dialog itext5
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_DiskInfo_EventLoop                      ; Disk info event loop if non-zero/not equal — checked value at (a1)
	lea      Var_DiskUnit(pc),a1                          ; Point a1 at disk unit number (DF0-DF3)
	move.l   d4,(a1)                                      ; Store d4 as disk unit number (DF0-DF3)
	cmp.l    #$3,d4                                       ; Check if d4 equals $3 (3)
	bhi.w    Loop_DiskInfo_EventLoop                      ; Disk info event loop if unsigned greater — checked #$3,d4
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_UpdateDialogProgress:
	bsr.w    Func_WaitDialogTimeout                       ; Call Func_WaitDialogTimeout — wait dialog timeout
	movea.l  Var_ProgressWindowPointer(pc),a0             ; Load progress indicator window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jsr      _LVOGetMsg(a6)                               ; Retrieve startup message from MsgPort
	lea      Var_LastIntuiMessage(pc),a1                  ; Point a1 at last received IntuiMessage pointer
	move.l   d0,(a1)                                      ; Store d0 as last received IntuiMessage pointer
	movea.l  d0,a1                                        ; Save _LVOGetMsg result in a1
	beq.w    Func_UpdateDialogProgress                    ; Update dialog progress if zero/equal
	jmp      _LVOReplyMsg(a6)                                    ; Tail-call ReplyMsg() — acknowledge IntuiMessage
Func_WaitDialogTimeout:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_ProgressWindowPointer(pc),a0             ; Load progress indicator window pointer into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jmp      _LVOWaitPort(a6)                                    ; Wait for message to arrive on port (_LVOWaitPort)
Loop_Status_ProcessDone:
	lea      Var_ProgressWindowHeight(pc),a0              ; Point a0 at progress window height
	bra.w    Loop_Status_DoneDelay                        ; Jump to Loop_Status_DoneDelay — status done delay
Func_HandleStatusProgress:
	lea      Var_OperationCancelledFlag(pc),a0            ; Point a0 at user cancellation flag
	tst.b    (a0)                                         ; Check whether user cancellation flag is zero/null
	beq.w    Loop_Status_ProcessDone                      ; Status process done if zero/equal — checked value at (a0)
	lea      Var_ProgressWindowTop(pc),a0                 ; Point a0 at progress window top
Loop_Status_DoneDelay:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_ProgressWindowPointer(pc),a1             ; Load progress indicator window pointer into a1
	suba.l   a2,a2                                        ; Clear a2 to zero (self-subtract)
	jsr      _LVOFreeSysRequest(a6)                       ; Free the system requester window
Loop_Status_DoneWait:
	bsr.w    Func_UpdateDialogProgress                    ; Call Func_UpdateDialogProgress — update dialog progress
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$200,d0                                     ; Compare return value from Func_UpdateDialogProgress against $200 (512)
	beq.w    Loc_LoadFile_ProcessRelocs                   ; Load file process relocs if zero/equal — d0 vs $200 — checked #$200,d0
	cmp.w    #$40,d0                                      ; Compare return value from Func_UpdateDialogProgress against $40 (64)
	beq.w    Loc_LoadFile_SkipRelocs                      ; Load file skip relocs if zero/equal — d0 vs $40 — checked #$40,d0
	cmp.w    #$8,d0                                       ; Check if d0 equals $8 (8)
	beq.w    Func_HandleStatusProgress                    ; Handle status progress if zero/equal — d0 vs $8 — checked #$8,d0
	bra.w    Loop_Status_DoneWait                         ; Jump to Loop_Status_DoneWait — status done wait
Loc_LoadFile_ProcessRelocs:
	lea      Str_UserBreak(pc),a0                         ; Load pointer to "User break !" status string
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	bsr.w    Func_CloseProgressWindow                     ; Call Func_CloseProgressWindow — close progress window
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_LoadFile_SkipRelocs:
	movea.l  im_IAddress(a0),a1                                   ; Load IntuiMessage im_IAddress field (sender object pointer)
	move.l   $26(a1),d0                                   ; Read offset $26(a1) into d0
	beq.w    Loc_LoadFile_ParseHunkTable                  ; Load file parse hunk table if zero/equal
	cmp.w    #$1,d0                                       ; Check if d0 equals $1 (1)
	beq.w    Loc_LoadFile_NextHunkTable                   ; Load file next hunk table if zero/equal — d0 vs $1 — checked #$1,d0
	cmp.w    #$2,d0                                       ; Check if d0 equals $2 (2)
	beq.w    Loc_LoadFile_EndOfHeader                     ; Load file end of header if zero/equal — d0 vs $2 — checked #$2,d0
	cmp.w    #$3,d0                                       ; Check if d0 equals $3 (3)
	beq.w    Loc_LoadFile_SkipHunkEnd                     ; Load file skip hunk end if zero/equal — d0 vs $3 — checked #$3,d0
	cmp.w    #$4,d0                                       ; Check if d0 equals $4 (4)
	beq.w    Loc_LoadFile_ProcessDebug                    ; Load file process debug if zero/equal — d0 vs $4 — checked #$4,d0
	cmp.w    #$5,d0                                       ; Check if d0 equals $5 (5)
	beq.w    Loc_LoadFile_ProcessSymbols                  ; Load file process symbols if zero/equal — d0 vs $5 — checked #$5,d0
	cmp.w    #$6,d0                                       ; Check if d0 equals $6 (6)
	beq.w    Loc_LoadFile_SkipSymbols                     ; Load file skip symbols if zero/equal — d0 vs $6 — checked #$6,d0
	cmp.w    #$7,d0                                       ; Check if d0 equals $7 (7)
	beq.w    Loc_LoadFile_ProcessLine                     ; Load file process line if zero/equal — d0 vs $7 — checked #$7,d0
	cmp.w    #$8,d0                                       ; Check if d0 equals $8 (8)
	beq.w    Loc_LoadFile_SkipLine                        ; Load file skip line if zero/equal — d0 vs $8 — checked #$8,d0
	cmp.w    #$9,d0                                       ; Check if d0 equals $9 (9)
	beq.w    Loc_LoadFile_ProcessHunkEnd                  ; Load file process hunk end if zero/equal — d0 vs $9 — checked #$9,d0
	cmp.w    #$a,d0                                       ; Check if d0 equals $a (10)
	beq.w    Loc_LoadFile_SkipDebug                       ; Load file skip debug if zero/equal — d0 vs $a — checked #$a,d0
	cmp.w    #$b,d0                                       ; Check if d0 equals $b (11)
	beq.w    Loc_LoadFile_NextTable                       ; Load file next table if zero/equal — d0 vs $b — checked #$b,d0
	bra.w    Loop_Status_DoneWait                         ; Jump to Loop_Status_DoneWait — status done wait
Loc_LoadFile_ProcessDebug:
	lea      Var_ProgressWindowTop(pc),a0                 ; Point a0 at progress window top
	lea      Var_ProgressWindowWidth(pc),a1               ; Point a1 at progress window width
	tst.b    (a1)                                         ; Check whether Var_ProgressWindowWidth value is zero
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal — checked value at (a1)
	lea      Var_ProgressWindowWidth(pc),a0               ; Point a0 at progress window width
	lea      Var_StatusWindowHeight(pc),a1                ; Point a1 at status window height
	lea      Var_DiskInfoWindowTop(pc),a2                 ; Point a2 at disk info window top
Loop_Status_ErrorDelay:
	move.b   (a0),(a1)+                                   ; Copy (a0) to (a1)+
	move.b   (a0)+,(a2)+                                  ; Copy next byte from source to destination
	bne.w    Loop_Status_ErrorDelay                       ; Status error delay if non-zero/not equal
	lea      Var_StatusWindowWidth(pc),a0                 ; Point a0 at status window width
	bsr.w    Func_ReadFormattedText                       ; Call Func_ReadFormattedText — read formatted text
	lea      Var_ProgressWindowHeight(pc),a0              ; Point a0 at progress window height
	bra.w    Loop_Status_DoneDelay                        ; Jump to Loop_Status_DoneDelay — status done delay
Func_ReadFormattedText:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_ProgressWindowPointer(pc),a1             ; Load progress indicator window pointer into a1
	suba.l   a2,a2                                        ; Clear a2 to zero (self-subtract)
	jmp      _LVORefreshGadgets(a6)                       ; Refresh the gadgets in the window
Loc_LoadFile_SkipDebug:
	lea      Var_DialogIText7(pc),a0                      ; Point a0 at dialog itext7
	lea      Var_DialogIText8(pc),a1                      ; Point a1 at dialog itext8
	tst.b    (a1)                                         ; Check whether Var_DialogIText8 value is zero
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal — checked value at (a1)
	bra.w    Func_HandleStatusProgress                    ; Jump to Func_HandleStatusProgress — handle status progress
Loc_LoadFile_ProcessSymbols:
	lea      Var_ProgressWindowHeight(pc),a0              ; Point a0 at progress window height
	lea      Var_StatusWindowTop(pc),a1                   ; Point a1 at status window top
	tst.b    (a1)                                         ; Check whether Var_StatusWindowTop value is zero
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal — checked value at (a1)
	lea      Var_StatusWindowWidth(pc),a0                 ; Point a0 at status window width
	bra.w    Loop_Status_DoneDelay                        ; Jump to Loop_Status_DoneDelay — status done delay
Loc_LoadFile_SkipSymbols:
	lea      Var_StatusWindowWidth(pc),a0                 ; Point a0 at status window width
	lea      Var_StatusWindowHeight(pc),a1                ; Point a1 at status window height
	tst.b    (a1)                                         ; Check whether Var_StatusWindowHeight value is zero
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal — checked value at (a1)
	lea      Var_DiskInfoWindowLeft(pc),a0                ; Point a0 at disk info window left
	bra.w    Loop_Status_DoneDelay                        ; Jump to Loop_Status_DoneDelay — status done delay
Loc_LoadFile_ProcessLine:
	lea      Var_DiskInfoWindowLeft(pc),a0                ; Point a0 at disk info window left
	lea      Var_DiskInfoWindowTop(pc),a1                 ; Point a1 at disk info window top
	tst.b    (a1)                                         ; Check whether Var_DiskInfoWindowTop value is zero
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal — checked value at (a1)
	lea      Var_DiskInfoWindowWidth(pc),a0               ; Point a0 at disk info window width
	bra.w    Loop_Status_DoneDelay                        ; Jump to Loop_Status_DoneDelay — status done delay
Loc_LoadFile_SkipLine:
	lea      Var_Window_WorkTop(pc),a0                    ; Point a0 at window work top
	bra.w    Loop_Status_DoneDelay                        ; Jump to Loop_Status_DoneDelay — status done delay
Loc_LoadFile_ProcessHunkEnd:
	lea      Var_Window_WorkTop(pc),a0                    ; Point a0 at window work top
	lea      Var_Window_WorkWidth(pc),a1                  ; Point a1 at window work width
	tst.b    (a1)                                         ; Check whether Var_Window_WorkWidth value is zero
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal — checked value at (a1)
Loc_LoadFile_SkipHunkEnd:
	lea      Var_OperationCancelledFlag(pc),a0            ; Point a0 at user cancellation flag
	tst.b    (a0)                                         ; Check whether user cancellation flag is zero/null
	beq.w    Loc_LoadFile_HunkDone                        ; Load file hunk done if zero/equal — checked value at (a0)
	lea      Var_ProgressWindowWidth(pc),a0               ; Point a0 at progress window width
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_StatusErrorFlag(pc),a0                   ; Point a0 at global error status flag
	tst.b    (a0)                                         ; Check whether global error status flag is zero/null
	bne.w    Func_HandleStatusProgress                    ; Handle status progress if non-zero/not equal — checked value at (a0)
	lea      Var_RemainingHunkBytes(pc),a0                ; Point a0 at remaining hunk bytes
	move.l   d4,(a0)                                      ; Save d4 as remaininghunkbytes
	beq.w    Func_HandleStatusProgress                    ; Handle status progress if zero/equal
Loc_LoadFile_HunkDone:
	lea      Var_DialogIText8(pc),a0                      ; Point a0 at dialog itext8
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_DialogIText7(pc),a0                      ; Point a0 at dialog itext7
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_DoneDelay                        ; Status done delay if non-zero/not equal — checked value at (a1)
	lea      Var_PayloadSize(pc),a1                       ; Point a1 at current payload data size
	move.l   d4,(a1)                                      ; Store d4 as current payload data size
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal
	cmp.l    #$11101,d4                                   ; Check if d4 equals $11101 (69889)
	bhi.w    Loop_Status_DoneDelay                        ; Status done delay if unsigned greater — checked #$11101,d4
	lea      Var_StatusWindowTop(pc),a0                   ; Point a0 at status window top
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_ProgressWindowHeight(pc),a0              ; Point a0 at progress window height
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_DoneDelay                        ; Status done delay if non-zero/not equal — checked value at (a1)
	lea      Var_DirectoryEntryTime(pc),a1                ; Point a1 at directory entry time
	move.l   d4,(a1)                                      ; Save d4 as directoryentrytime
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal
	lea      Var_StatusWindowHeight(pc),a0                ; Point a0 at status window height
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_StatusWindowWidth(pc),a0                 ; Point a0 at status window width
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_DoneDelay                        ; Status done delay if non-zero/not equal — checked value at (a1)
	lea      Var_DirectoryEntryComment(pc),a1             ; Point a1 at directory entry comment string
	move.l   d4,(a1)                                      ; Store d4 as directory entry comment string
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal
	lea      Var_DiskInfoWindowTop(pc),a0                 ; Point a0 at disk info window top
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_DiskInfoWindowLeft(pc),a0                ; Point a0 at disk info window left
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_DoneDelay                        ; Status done delay if non-zero/not equal — checked value at (a1)
	lea      Var_DirectoryEntryDate(pc),a1                ; Point a1 at directory entry date
	move.l   d4,(a1)                                      ; Save d4 as directoryentrydate
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal
	lea      Var_DiskInfoWindowHeight(pc),a0              ; Point a0 at disk info window height
	tst.b    (a0)                                         ; Check whether Var_DiskInfoWindowHeight value is zero
	beq.w    Loc_LoadFile_VerifyCheck                     ; Load file verify check if zero/equal — checked value at (a0)
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_DiskInfoWindowWidth(pc),a0               ; Point a0 at disk info window width
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_DoneDelay                        ; Status done delay if non-zero/not equal — checked value at (a1)
	lea      Var_DirectoryEntryBufferEnd(pc),a1           ; Point a1 at directory entry buffer end
	move.l   d4,(a1)                                      ; Save d4 as directoryentrybufferend
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal
	bra.w    Loc_LoadFile_Done                            ; Jump to Loc_LoadFile_Done — load file done
Loop_LoadFile_VerifyCheck:
	lea      Var_Window_WorkWidth(pc),a0                  ; Point a0 at window work width
	bsr.w    Func_ConvertHexStringToLong                  ; Convert valid hexadecimal ASCII string in a0 to 32-bit integer in d4
	lea      Var_Window_WorkTop(pc),a0                    ; Point a0 at window work top
	lea      Var_StatusErrorFlag(pc),a1                   ; Point a1 at global error status flag
	tst.b    (a1)                                         ; Check whether global error status flag is zero/null
	bne.w    Loop_Status_DoneDelay                        ; Status done delay if non-zero/not equal — checked value at (a1)
	lea      Var_DirectoryEntryBuffer(pc),a1              ; Point a1 at directory entry buffer
	move.l   d4,(a1)                                      ; Store d4 as directory entry buffer
	beq.w    Loop_Status_DoneDelay                        ; Status done delay if zero/equal
	btst     #$0,d4                                       ; Test bit 0 of d4
	bne.w    Loop_Status_DoneDelay                        ; Status done delay if non-zero/not equal
	move.l   Var_PayloadSize(pc),d0                       ; Load current payload data size into d0
	beq.w    Func_HandleStatusProgress                    ; Handle status progress if zero/equal
	lea      Var_DirectoryEntryComment(pc),a0             ; Point a0 at directory entry comment string
	sub.l    d4,(a0)                                      ; Subtract d4 from (a0)
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Loc_LoadFile_VerifyCheck:
	move.w   Var_NopOpcode(pc),d0                         ; Load nop opcode into d0
	lea      Var_FloppyWriteBuffer(pc),a0                 ; Point a0 at floppy write buffer
	move.w   d0,(a0)+                                     ; Save d0 as floppywritebuffer
	move.w   d0,(a0)                                      ; Save d0 as floppywritebuffer
	lea      Var_DirectoryEntryName(pc),a0                ; Point a0 at directory entry name
	move.w   d0,(a0)+                                     ; Save d0 as directoryentryname
	move.w   d0,(a0)                                      ; Save d0 as directoryentryname
	lea      Var_DiskInfo_VolumeDate(pc),a0               ; Point a0 at disk info volume date
	move.w   d0,(a0)+                                     ; Save d0 as diskinfo volumedate
	move.w   d0,(a0)                                      ; Save d0 as diskinfo volumedate
	lea      Var_DiskInfo_FIBProt(pc),a0                  ; Point a0 at disk info fibprot
	move.w   d0,(a0)+                                     ; Save d0 as diskinfo fibprot
	move.w   d0,(a0)                                      ; Save d0 as diskinfo fibprot
	lea      Var_DirectoryBuffer(pc),a0                   ; Point a0 at directory buffer
	move.w   #$8200,(a0)                                  ; Load 33280 ($8200) into (a0)
	lea      Var_DirectoryBufferEnd(pc),a0                ; Point a0 at directory buffer end
	move.w   #$c000,(a0)                                  ; Load 49152 ($c000) into (a0)
	lea      Var_DiskInfo_TotalTracks(pc),a0              ; Point a0 at disk info total tracks
	move.w   #$8200,(a0)                                  ; Load 33280 ($8200) into (a0)
	lea      Var_DiskInfo_TotalSectors(pc),a0             ; Point a0 at disk info total sectors
	move.w   #$c000,(a0)                                  ; Load 49152 ($c000) into (a0)
	lea      Var_DiskInfo_VolumeTime(pc),a0               ; Point a0 at disk info volume time
	move.w   #$8200,(a0)                                  ; Load 33280 ($8200) into (a0)
	lea      Var_DiskInfo_FIB(pc),a0                      ; Point a0 at disk info fib
	move.w   #$c000,(a0)                                  ; Load 49152 ($c000) into (a0)
	lea      Var_DiskInfo_FIBComment(pc),a0               ; Point a0 at disk info fibcomment
	move.w   #$8200,(a0)                                  ; Load 33280 ($8200) into (a0)
	lea      Var_DiskInfo_FIBDate(pc),a0                  ; Point a0 at disk info fibdate
	move.w   #$c000,(a0)                                  ; Load 49152 ($c000) into (a0)
	bra.w    Loop_LoadFile_VerifyCheck                    ; Jump to Loop_LoadFile_VerifyCheck — load file verify check
Loc_LoadFile_Done:
	lea      Var_FloppyWriteBuffer(pc),a1                 ; Point a1 at floppy write buffer
	move.l   #$2e7a022e,(a1)                              ; Load 779747886 ($2e7a022e) into (a1)
	lea      Var_DirectoryEntryName(pc),a1                ; Point a1 at directory entry name
	move.l   #$2e7a021e,(a1)                              ; Load 779747870 ($2e7a021e) into (a1)
	lea      Var_DiskInfo_VolumeDate(pc),a1               ; Point a1 at disk info volume date
	move.l   #$2e7a022e,(a1)                              ; Load 779747886 ($2e7a022e) into (a1)
	lea      Var_DiskInfo_FIBProt(pc),a1                  ; Point a1 at disk info fibprot
	move.l   #$2e7a0238,(a1)                              ; Load 779747896 ($2e7a0238) into (a1)
	lea      Var_DirectoryBuffer(pc),a0                   ; Point a0 at directory buffer
	clr.w    (a0)                                         ; Zero Var_DirectoryBuffer
	lea      Var_DirectoryBufferEnd(pc),a0                ; Point a0 at directory buffer end
	clr.w    (a0)                                         ; Zero Var_DirectoryBufferEnd
	lea      Var_DiskInfo_TotalTracks(pc),a0              ; Point a0 at disk info total tracks
	clr.w    (a0)                                         ; Zero Var_DiskInfo_TotalTracks
	lea      Var_DiskInfo_TotalSectors(pc),a0             ; Point a0 at disk info total sectors
	clr.w    (a0)                                         ; Zero Var_DiskInfo_TotalSectors
	lea      Var_DiskInfo_VolumeTime(pc),a0               ; Point a0 at disk info volume time
	clr.w    (a0)                                         ; Zero Var_DiskInfo_VolumeTime
	lea      Var_DiskInfo_FIB(pc),a0                      ; Point a0 at disk info fib
	clr.w    (a0)                                         ; Zero Var_DiskInfo_FIB
	lea      Var_DiskInfo_FIBComment(pc),a0               ; Point a0 at disk info fibcomment
	clr.w    (a0)                                         ; Zero Var_DiskInfo_FIBComment
	lea      Var_DiskInfo_FIBDate(pc),a0                  ; Point a0 at disk info fibdate
	clr.w    (a0)                                         ; Zero Var_DiskInfo_FIBDate
	bra.w    Loop_LoadFile_VerifyCheck                    ; Jump to Loop_LoadFile_VerifyCheck — load file verify check
Func_ValidateFileHeader:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	bne.b    Func_ValidateFileHeader                      ; Validate file header if non-zero/not equal
	lea      Var_DialogIText7(pc),a0                      ; Point a0 at dialog itext7
	bra.w    Func_ReadFormattedText                       ; Jump to Func_ReadFormattedText — read formatted text
Loc_LoadFile_ParseHunkTable:
	lea      Var_DialogIText8(pc),a0                      ; Point a0 at dialog itext8
	lea      Var_FloppyTrackLimit_181(pc),a1              ; Point a1 at floppy track limit 181
	bsr.w    Func_ValidateFileHeader                      ; Call Func_ValidateFileHeader — validate file header
	bra.w    Func_HandleStatusProgress                    ; Jump to Func_HandleStatusProgress — handle status progress
Loc_LoadFile_NextHunkTable:
	lea      Var_DialogIText8(pc),a0                      ; Point a0 at dialog itext8
	lea      Var_FloppyTrackLimit_701(pc),a1              ; Point a1 at floppy track limit 701
	bsr.w    Func_ValidateFileHeader                      ; Call Func_ValidateFileHeader — validate file header
	bra.w    Func_HandleStatusProgress                    ; Jump to Func_HandleStatusProgress — handle status progress
Loc_LoadFile_EndOfHeader:
	lea      Var_DialogIText8(pc),a0                      ; Point a0 at dialog itext8
	lea      Str_Const_1501(pc),a1                        ; Point a1 at const 1501
	bsr.w    Func_ValidateFileHeader                      ; Call Func_ValidateFileHeader — validate file header
	bra.w    Func_HandleStatusProgress                    ; Jump to Func_HandleStatusProgress — handle status progress
Loc_LoadFile_NextTable:
	lea      Var_DialogIText8(pc),a0                      ; Point a0 at dialog itext8
	lea      Str_Const_11101(pc),a1                       ; Point a1 at const 11101
	bsr.w    Func_ValidateFileHeader                      ; Call Func_ValidateFileHeader — validate file header
	bra.w    Func_HandleStatusProgress                    ; Jump to Func_HandleStatusProgress — handle status progress
Loc_Dialog_AllocError:
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
Loc_Status_ErrorReturn:
	lea      Str_Err_NotEnoughMemory(pc),a0               ; Point a0 at err not enough memory
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_DiskIO_ErrorReturn:
	lea      Str_Err_DeviceNotMounted(pc),a0              ; Point a0 at err device not mounted
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_HandleFileNotFoundError:
	lea      Str_Err_FileNotFound(pc),a0                  ; Point a0 at err file not found
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Func_ReadFileHeader:
	lea      Var_HeaderBuffer(pc),a0                      ; Point a0 at header buffer
	move.l   a0,d2                                        ; Load header buffer into d2
Loc_ReadFile:
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	move.l   Var_FileHandle(pc),d1                        ; Load open file handle into d1
	jmp      _LVORead(a6)                                 ; Read payload segment data from file
Func_FreePayloadBuffer:
	movea.l  Var_PayloadBuffer(pc),a1                     ; Load packed/unpacked file data buffer into a1
	lea      Var_PayloadBuffer(pc),a6                     ; Point a6 at packed/unpacked file data buffer
	clr.l    (a6)                                         ; Clear packed/unpacked file data buffer to zero
	move.l   Var_PayloadBufferSize(pc),d0                 ; Load allocated payload buffer size into d0
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jsr      _LVOFreeMem(a6)                                     ; FreeMem — free allocated memory
	lea      Str_BufferIsEmpty(pc),a0                     ; Point a0 at buffer is empty
	bra.w    Func_RenderTextAlt                           ; Jump to Func_RenderTextAlt — render text alt
Loc_HandleUnsupportedHunkError:
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	lea      Str_Err_HunkTypeNotSupported(pc),a0          ; Point a0 at err hunk type not supported
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_HandleAllocError:
	bsr.w    Func_FreePayloadBuffer                       ; Call Func_FreePayloadBuffer — free payload buffer
Loc_HandleFileLoadError:
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	lea      Str_LoadError(pc),a0                         ; Point a0 at load error
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_HandleNotALoadFileError:
	bsr.w    Func_CloseFile                               ; Call Func_CloseFile — close file
	lea      Str_Err_FileNoLoadFile(pc),a0                ; Point a0 at err file no load file
	bsr.w    Func_RenderTextAlt                           ; Alternate text render routine (coordinates preset)
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Func_CheckHunkStructure:
	bsr.w    Func_ClearHeaderBuffer                       ; Call Func_ClearHeaderBuffer — clear header buffer
Loop_LoadFile_VerifyIndex:
	moveq    #$0,d0                                       ; Clear value 0 to zero
	move.b   (a2)+,d0                                     ; Load (a2)+ into d0
	lsl.w    #$2,d0                                       ; Multiply value 0 by 4 (shift left 2)
	addq.l   #$1,(a3,d0.w)                                ; Add value
	cmpa.l   a2,a6                                        ; Compare a2 with a6
	bne.w    Loop_LoadFile_VerifyIndex                    ; Load file verify index if non-zero/not equal — checked a2,a6
	moveq    #$0,d0                                       ; Clear value 0 to zero
	moveq    #$0,d2                                       ; Clear value 0 to zero
Loop_LoadFile_VerifyHunk:
	moveq    #$0,d1                                       ; Clear value 0 to zero
Loop_LoadFile_VerifyTable:
	cmp.l    (a3,d1.w),d0                                 ; Compare operands to test comparison conditions
	beq.w    Loc_LoadFile_ReadNextHunk                    ; Load file read next hunk if zero/equal — checked (a3,d1.w),d0
Loop_LoadFile_VerifyHunkLoop:
	addq.w   #$4,d1                                       ; Add 4 ($4) to d1
	cmp.w    #$400,d1                                     ; Check if d1 equals $400 (1024)
	bne.w    Loop_LoadFile_VerifyTable                    ; Load file verify table if non-zero/not equal — d1 vs $400 — checked #$400,d1
	addq.l   #$1,d0                                       ; Increment d0 by one
	bra.w    Loop_LoadFile_VerifyHunk                     ; Jump to Loop_LoadFile_VerifyHunk — load file verify hunk
Loc_LoadFile_ReadNextHunk:
	lsr.w    #$2,d1                                       ; Divide d1 by 4 (shift right 2)
	move.b   d1,(a4)+                                     ; Store d1 at address in a4
	lsl.w    #$2,d1                                       ; Multiply d1 by 4 (shift left 2)
	addq.b   #$1,d2                                       ; Add #$1 to d2
	cmp.b    d7,d2                                        ; Compare d7 with d2
	bne.w    Loop_LoadFile_VerifyHunkLoop                 ; Load file verify hunk loop if non-zero/not equal — checked d7,d2
	rts                                                   ; Return to caller
Func_AllocateSegmentList:
	move.b   Var_DirectoryEntryType(pc),d3                ; Load directory entry type code into d3
	move.b   Var_DirectoryEntryProtection(pc),d4          ; Load directory entry protection into d4
	moveq    #-1,d7                                       ; Load error / exit code -1 ($ff) into register d7
Loop_LoadFile_VerifyDelay:
	move.b   (a0)+,d0                                     ; Load (a0)+ into d0
	move.b   (a0),d1                                      ; Load value from (a0) into d1
	cmp.b    d0,d1                                        ; Compare d0 with d1
	bne.b    Loop_LoadFile_VerifyWait                     ; Load file verify wait if non-zero/not equal — checked d0,d1
	move.b   $1(a0),d2                                    ; Read offset $1(a0) into d2
	cmp.b    d2,d1                                        ; Compare d2 with d1
	beq.b    Loc_LoadFile_HunkCode                        ; Load file hunk code if zero/equal — checked d2,d1
Loop_LoadFile_VerifyWait:
	cmp.b    d4,d0                                        ; Compare d4 with d0
	beq.b    Loc_LoadFile_HunkReloc32                     ; Load file hunk reloc32 if zero/equal — checked d4,d0
	cmp.b    d3,d0                                        ; Compare d3 with d0
	beq.b    Loc_LoadFile_HunkReloc32                     ; Load file hunk reloc32 if zero/equal — checked d3,d0
	move.b   d0,(a2)+                                     ; Store d0 at address in a2
Loop_LoadFile_VerifyRetry:
	cmpa.l   a0,a1                                        ; Compare a0 with a1
	bne.b    Loop_LoadFile_VerifyDelay                    ; Load file verify delay if non-zero/not equal — checked a0,a1
	rts                                                   ; Return to caller
Loc_LoadFile_HunkCode:
	lea      $1(a0),a3                                    ; Get address at offset $1 from a0
	cmpa.l   a3,a1                                        ; Compare a3 with a1
	bls.b    Loop_LoadFile_VerifyWait                     ; Load file verify wait if unsigned lower or same — checked a3,a1
	moveq    #$0,d2                                       ; Clear value 0 to zero
	movea.l  a0,a3                                        ; Copy a0 to a3
	subq.l   #$1,a0                                       ; Decrement a0 by one
Loop_LoadFile_VerifyFinal:
	cmpa.l   a3,a1                                        ; Compare a3 with a1
	beq.b    Loc_LoadFile_HunkSymbol                      ; Load file hunk symbol if zero/equal — checked a3,a1
	addq.b   #$1,d2                                       ; Add #$1 to d2
	beq.b    Loc_LoadFile_HunkData                        ; Load file hunk data if zero/equal
	cmpm.b   (a0)+,(a3)+                                  ; Compare (a0)+ with (a3)+
	beq.b    Loop_LoadFile_VerifyFinal                    ; Load file verify final if zero/equal — checked (a0)+,(a3)+
	bra.b    Loc_LoadFile_HunkBSS                         ; Jump to Loc_LoadFile_HunkBSS — load file hunk bss
Loc_LoadFile_HunkData:
	addq.l   #$1,a0                                       ; Increment a0 by one
Loc_LoadFile_HunkBSS:
	tst.b    d0                                           ; Test d0 for zero
	beq.b    Loc_LoadFile_HunkDebug                       ; Load file hunk debug if zero/equal — checked d0
	move.b   d0,(a2)+                                     ; Store d0 at address in a2
	move.b   d2,(a2)+                                     ; Store d2 at address in a2
	move.b   d3,(a2)+                                     ; Store d3 at address in a2
	bra.b    Loop_LoadFile_VerifyDelay                    ; Jump to Loop_LoadFile_VerifyDelay — load file verify delay
Loc_LoadFile_HunkReloc32:
	move.b   d0,(a2)+                                     ; Store d0 at address in a2
	move.b   #$1,(a2)+                                    ; Write byte $1 to (a2)
	move.b   d3,(a2)+                                     ; Store d3 at address in a2
	bra.b    Loop_LoadFile_VerifyRetry                    ; Jump to Loop_LoadFile_VerifyRetry — load file verify retry
Loc_LoadFile_HunkSymbol:
	addq.b   #$1,d2                                       ; Add #$1 to d2
	tst.b    d0                                           ; Test d0 for zero
	beq.b    Loc_LoadFile_HunkEnd                         ; Load file hunk end if zero/equal — checked d0
	move.b   d0,(a2)+                                     ; Store d0 at address in a2
	move.b   d2,(a2)+                                     ; Store d2 at address in a2
	move.b   d3,(a2)+                                     ; Store d3 at address in a2
	rts                                                   ; Return to caller
Loc_LoadFile_HunkDebug:
	move.b   d2,(a2)+                                     ; Store d2 at address in a2
	move.b   d4,(a2)+                                     ; Store d4 at address in a2
	bra.b    Loop_LoadFile_VerifyDelay                    ; Jump to Loop_LoadFile_VerifyDelay — load file verify delay
Loc_LoadFile_HunkEnd:
	move.b   d2,(a2)+                                     ; Store d2 at address in a2
	move.b   d4,(a2)+                                     ; Store d4 at address in a2
	rts                                                   ; Return to caller
Loop_LoadFile_CodeBlocks:
	move.b   #$70,(a4)                                    ; Write byte $70 to (a4)
	lea      Var_MenuID_Selected(pc),a4                   ; Point a4 at currently selected menu preference ID
	tst.b    (a4)                                         ; Check whether currently selected menu preference ID is zero/null
	bne.b    Loop_LoadFile_HunkHeaderLoop                 ; Load file hunk header loop if non-zero/not equal — checked value at (a4)
	movem.l  d0-d7/a0-a6,-(a7)                            ; Save working registers to stack
	suba.l   Var_UnusedWorkspace(pc),a0                   ; Subtract Var_UnusedWorkspace(pc) from a0
	move.l   a2,-(a7)                                     ; Save a2 on stack
	bsr.w    Func_FormatMemSize                           ; Format raw byte size into KB text representation
	bsr.w    Func_ReadSegmentPayload                      ; Call Func_ReadSegmentPayload — read segment payload
	bsr.w    Func_ParseSegmentHeader                      ; Call Func_ParseSegmentHeader — parse segment header
	lea      Var_FormattedOutputString(pc),a0             ; Point a0 at formatted numeric output string
	movea.l  a0,a1                                        ; Load formatted numeric output string into a1
Loop_LoadFile_DataBlocks:
	tst.b    (a1)+                                        ; Test byte at (a1) for zero
	bne.w    Loop_LoadFile_DataBlocks                     ; Load file data blocks if non-zero/not equal — checked value at (a1)
	suba.l   a0,a1                                        ; Subtract a0 from a1
	move.l   a1,d0                                        ; Copy a1 to d0
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOText(a6)                                     ; Call Text() — render text string to window RastPort
	movea.l  (a7)+,a0                                     ; Restore a0 from stack
	suba.l   Var_PayloadBuffer(pc),a0                     ; Subtract Var_PayloadBuffer(pc) from a0
	bsr.w    Func_FormatMemSize                           ; Format raw byte size into KB text representation
	bsr.w    Func_LoadHunkSegments                        ; Call Func_LoadHunkSegments — load hunk segments
	bsr.w    Func_ParseSegmentHeader                      ; Call Func_ParseSegmentHeader — parse segment header
	lea      Var_FormattedOutputString(pc),a0             ; Point a0 at formatted numeric output string
	movea.l  a0,a1                                        ; Load formatted numeric output string into a1
Loop_LoadFile_BSSBlocks:
	tst.b    (a1)+                                        ; Test byte at (a1) for zero
	bne.w    Loop_LoadFile_BSSBlocks                      ; Load file bssblocks if non-zero/not equal — checked value at (a1)
	suba.l   a0,a1                                        ; Subtract a0 from a1
	move.l   a1,d0                                        ; Copy a1 to d0
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOText(a6)                                     ; Call Text() — render text string to window RastPort
	movem.l  (a7)+,d0-d7/a0-a6                            ; Restore registers from stack
Loop_LoadFile_HunkHeaderLoop:
	bchg     #$1,$bfe001.l                                ; Blink power LED as activity indicator while loading
	btst     #$6,$bfe001.l                                ; Check if left mouse button is pressed (bit 6 = LMB)
	beq.b    Loc_LoadFile_SaveHunkHeader                  ; LMB pressed: skip callback, continue with hunk save
	jmp      (a5)                                         ; LMB not pressed: dispatch to hunk processing callback in a5
Loc_LoadFile_SaveHunkHeader:
	btst     #$a,POTGOR.l                                 ; Check right mouse button (bit 10 of POTGOR = RMB)
	bne.b    Loop_LoadFile_HunkHeaderLoop                 ; RMB not pressed: keep looping
	lea      $4(a7),a7                                    ; RMB pressed: discard return address (abort loading)
	bra.w    Loop_SetStatusError                          ; Signal error and abort loading operation
Func_ParseSegmentHeader:
	moveq    #$1,d0                                       ; Set d0 to 1 ($1)
	movea.l  Var_Window(pc),a0                            ; Load main packer window into a0
	movea.l  $32(a0),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jmp      _LVOSetAPen(a6)                                    ; Call FreeSignal() — free signal bit
Func_ReadSegmentPayload:
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	move.l   #$3e,d0                                      ; Set d0 to 62 ($3e)
	move.l   #$a6,d1                                      ; Set d1 to 166 ($a6)
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jmp      _LVOMove(a6)                                 ; Move graphics cursor to write status text
Func_LoadHunkSegments:
	move.l   #$11a,d0                                     ; Set d0 to 282 ($11a)
	move.l   #$a6,d1                                      ; Set d1 to 166 ($a6)
	movea.l  Var_Window(pc),a1                            ; Load main packer window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jmp      _LVOMove(a6)                                 ; Move graphics cursor to write status text
Func_ValidateSegmentTypes:
	move.l   Var_PayloadSize(pc),d0                       ; Load current payload data size into d0
	cmp.l    #$181,d0                                     ; Check if d0 equals $181 (385)
	bls.w    Loc_LoadFile_DebugLoop                       ; Load file debug loop if unsigned lower or same — checked #$181,d0
	cmp.l    #$701,d0                                     ; Check if d0 equals $701 (1793)
	bls.w    Loc_LoadFile_ProcessBSSHunk                  ; Load file process bsshunk if unsigned lower or same — checked #$701,d0
	cmp.l    #$1501,d0                                    ; Check if d0 equals $1501 (5377)
	bls.w    Loc_LoadFile_ReadHunkData                    ; Load file read hunk data if unsigned lower or same — checked #$1501,d0
	cmp.l    #$11101,d0                                   ; Check if d0 equals $11101 (69889)
	bls.w    Loc_LoadFile_LoopData                        ; Load file loop data if unsigned lower or same — checked #$11101,d0
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loop_LoadFile_HeaderCodeBlocks:
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	cmp.w    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_ReadPayloadBlocks              ; Load file read payload blocks if unsigned lower or same — checked d4,d3
	lea      $2(a3),a4                                    ; Get address at offset $2 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_CopyHunkBSS                     ; Load file copy hunk bss if unsigned lower or same — checked a4,a1
	bra.b    Loc_LoadFile_SkipOverHunk                    ; Jump to Loc_LoadFile_SkipOverHunk — load file skip over hunk
Loop_LoadFile_HeaderDataBlocks:
	moveq    #$3,d3                                       ; Set d3 to 3 ($3)
	cmp.w    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_ReadPayloadBlocks              ; Load file read payload blocks if unsigned lower or same — checked d4,d3
	lea      $1(a3),a4                                    ; Get address at offset $1 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_CopyHunkBSS                     ; Load file copy hunk bss if unsigned lower or same — checked a4,a1
	bra.b    Loc_LoadFile_SkipOverHunk                    ; Jump to Loc_LoadFile_SkipOverHunk — load file skip over hunk
Loop_LoadFile_HeaderBSSBlocks:
	moveq    #$2,d3                                       ; Set d3 to 2 ($2)
	cmp.w    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_ReadPayloadBlocks              ; Load file read payload blocks if unsigned lower or same — checked d4,d3
	cmpa.l   a3,a1                                        ; Compare a3 with a1
	bls.w    Loc_LoadFile_CopyHunkBSS                     ; Load file copy hunk bss if unsigned lower or same — checked a3,a1
	lea      $302(a0),a4                                  ; Get address at offset $302 from a0
	cmpa.l   a4,a3                                        ; Compare a4 with a3
	bcc.b    Loop_LoadFile_ReadPayloadBlocks              ; Load file read payload blocks if carry clear (greater or equal) — checked a4,a3
Loc_LoadFile_SkipOverHunk:
	move.l   a3,d2                                        ; Copy a3 to d2
	sub.l    a0,d2                                        ; Subtract a0 from d2
	subq.w   #$1,d2                                       ; Decrement d2 by one
	bra.b    Loc_LoadFile_CopyHunkData                    ; Jump to Loc_LoadFile_CopyHunkData — load file copy hunk data
Loc_LoadFile_ReadHunkData:
	moveq    #$0,d7                                       ; Clear value 0 to zero
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	moveq    #$0,d4                                       ; Clear value 0 to zero
Loop_LoadFile_SkipBlocks:
	cmp.w    #$ffff,d7                                    ; Check if d7 equals $ffff (65535)
	bne.b    Loc_LoadFile_EndOfHunk                       ; Load file end of hunk if non-zero/not equal — d7 vs $ffff — checked #$ffff,d7
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_LoadFile_EndOfHunk:
	movea.l  a0,a3                                        ; Copy a0 to a3
	move.b   (a3)+,d0                                     ; Load first byte of signature/prefix pattern to match
	move.b   (a3)+,d1                                     ; Load second byte of signature/prefix pattern to match
	move.l   a0,d5                                        ; Set up start pointer of search window
	add.l    Var_PayloadSize(pc),d5                       ; Calculate payload scanning upper limit address
	cmp.l    a1,d5                                        ; Ensure search does not overrun total payload end boundary (a1)
	bls.b    Loop_LoadFile_ReadPayloadBlocks              ; Branch if limit is safe
	move.l   a1,d5                                        ; Clamp maximum search limit to total payload end pointer
Loop_LoadFile_ReadPayloadBlocks:
	cmp.l    a3,d5                                        ; Check if the scanning pointer has reached the search window limit
	bls.b    Loc_LoadFile_CopyHunkBSS                     ; If limit reached without finding a match, handle BSS/reloc block
	cmp.b    (a3)+,d0                                     ; Scan window for the first byte of signature
	bne.b    Loop_LoadFile_ReadPayloadBlocks              ; Continue scanning if first byte mismatches
	cmp.b    (a3),d1                                      ; Check if next byte matches second byte of signature
	bne.b    Loop_LoadFile_ReadPayloadBlocks              ; Continue scanning if second byte mismatches
	move.b   $2(a0),d2                                    ; Load third byte of signature from pattern block
	cmp.b    $1(a3),d2                                    ; Compare with candidate byte at offset +1
	bne.b    Loop_LoadFile_HeaderBSSBlocks                ; If mismatch, branch to try BSS header matching path
	move.b   $3(a0),d2                                    ; Load fourth byte of signature from pattern block
	cmp.b    $2(a3),d2                                    ; Compare with candidate byte at offset +2
	bne.b    Loop_LoadFile_HeaderDataBlocks               ; If mismatch, branch to try DATA header matching path
	move.b   $4(a0),d2                                    ; Load fifth byte of signature from pattern block
	cmp.b    $3(a3),d2                                    ; Compare with candidate byte at offset +3
	bne.w    Loop_LoadFile_HeaderCodeBlocks               ; If mismatch, branch to try CODE header matching path
	lea      (a0),a4                                      ; Match found! Initialize a4 as source pattern start
	lea      (a3),a5                                      ; Initialize a5 as match start in scanning window
	subq.l   #$1,a5                                       ; Adjust scanning window pointer back to actual match start
Loop_LoadFile_CopyPayloadBlocks:
	cmpa.l   a5,a1                                        ; Check if match scanning reached end of total stream buffer
	beq.b    Loc_LoadFile_CopyHunkCode                    ; Branch if end reached to store this match
	cmpm.b   (a4)+,(a5)+                                  ; Byte-by-byte comparison to find match length
	beq.b    Loop_LoadFile_CopyPayloadBlocks              ; Continue comparing as long as characters match
Loc_LoadFile_CopyHunkCode:
	move.l   a4,d3                                        ; Calculate final matched pattern end pointer
	sub.l    a0,d3                                        ; Subtract a0 from d3
	subq.w   #$1,d3                                       ; Adjust match length for DBRA/zero-based counter
	cmp.l    d4,d3                                        ; Compare current match length with previous best match length in d4
	bls.b    Loop_LoadFile_ReadPayloadBlocks              ; Keep looking if this match is shorter than our previous best
	move.l   a5,d2                                        ; New best match found! Save end pointer of matched block
	sub.l    a4,d2                                        ; Calculate match offset relative to source pattern
Loc_LoadFile_CopyHunkData:
	cmp.w    #$10a,d3                                     ; Check if match length exceeds search threshold (max length)
	bcs.b    Loc_LoadFile_RelocDone                       ; Branch if within bounds to complete this relocation step
	move.w   #$10a,d4                                     ; Clamp match length to maximum sliding-window limit
	movea.l  d2,a6                                        ; Save matching offset pointer to a6
	bra.w    Loc_LoadFile_CopyHunkEnd                     ; Branch to finalize hunk block generation
Loc_LoadFile_CopyHunkBSS:
	tst.w    d4                                           ; Check if any valid compression match was found
	bne.w    Loc_LoadFile_CopyHunkEnd                     ; Branch to emit matched block if found
	lea      Var_TempDecrunchVar(pc),a5                   ; Point to temporary decrunch state flag
	tst.b    (a5)                                         ; Check if specific decrunch option is enabled
	beq.b    Loc_LoadFile_CopyHunkReloc32                 ; Branch if flag is clear
	sf.b     (a5)                                         ; Reset the temporary decrunch state flag
Loc_LoadFile_CopyHunkReloc32:
	addq.w   #$1,d7                                       ; Increment hunk index / block sequence counter
	moveq    #$0,d2                                       ; Clear d2 for relocations type/size byte
	move.b   d0,d2                                        ; Fetch relocations type indicator byte from d0
	moveq    #$8,d1                                       ; Set scale value to 8 for reloc table processing
	bsr.b    Func_ProcessRelocs32                         ; Call subroutine to parse and apply HUNK_RELOC32 records
	addq.l   #$1,a0                                       ; Advance input stream pointer by one byte
	cmpa.l   a0,a1                                        ; Check if all input stream blocks have been processed
	bhi.w    Loop_LoadFile_SkipBlocks                     ; Loop back to process next hunk block if more data remains
	bsr.w    Func_LoadHunkSymbols                         ; Parse and load debug symbol hunk tables (HUNK_SYMBOL)
	move.l   d6,(a2)+                                     ; Store decoded hunk segments pointer in output table
	bra.w    Loop_ClearStatusError                        ; Clear error flag and return successfully
Loc_LoadFile_RelocDone:
	move.l   d3,d4                                        ; Copy d3 to d4
	movea.l  d2,a6                                        ; Switch library base to d2
	cmp.l    a3,d5                                        ; Compare a3 with d5
	bhi.w    Loop_LoadFile_ReadPayloadBlocks              ; Load file read payload blocks if unsigned greater — checked a3,d5
	bra.w    Loc_LoadFile_CopyHunkEnd                     ; Jump to Loc_LoadFile_CopyHunkEnd — load file copy hunk end
Loop_LoadFile_RelocEntries:
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	bsr.b    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	bra.b    Loc_LoadFile_SymbolDone                      ; Jump to Loc_LoadFile_SymbolDone — load file symbol done
Loop_LoadFile_RelocTable:
	subi.w   #$502,d2                                     ; Subtract 1282 ($502) from d2
	ori.w    #$3000,d2                                    ; ORI.W #$3000,d2
	moveq    #$e,d1                                       ; Set d1 to 14 ($e)
	bsr.b    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	bra.b    Loc_LoadFile_SymbolDone                      ; Jump to Loc_LoadFile_SymbolDone — load file symbol done
Loop_LoadFile_RelocLoop:
	lsr.w    #$1,d2                                       ; Divide d2 by 2 (shift right 1)
	roxr.l   #$1,d6                                       ; ROXR.L #$1,d6
	bcs.b    Loc_LoadFile_CopyHunkSymbol                  ; Load file copy hunk symbol if carry set (less than / lower)
Func_ProcessRelocs32:
	dbra     d1,Loop_LoadFile_RelocLoop                   ; Decrement d1 and loop to Loop_LoadFile_RelocLoop until done
	rts                                                   ; Return to caller
Loc_LoadFile_CopyHunkSymbol:
	move.l   d6,(a2)+                                     ; Store d6 at address in a2
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	lea      Func_ProcessRelocs32(pc),a5                  ; Point a5 at process relocs32
	lea      Var_MenuSubID_Selected(pc),a4                ; Point a4 at current menu sub-item preference ID
	addq.b   #$1,(a4)                                     ; Add #$1 to (a4)
	bmi.w    Loop_LoadFile_CodeBlocks                     ; Load file code blocks if minus (negative sign bit set)
	bra.b    Func_ProcessRelocs32                         ; Jump to Func_ProcessRelocs32 — process relocs32
Loop_LoadFile_SymbolLength:
	moveq    #$3,d2                                       ; Set d2 to 3 ($3)
	moveq    #$2,d1                                       ; Set priority/parameter to 2 in d1
	bsr.b    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	bra.b    Loc_LoadFile_EndDone                         ; Jump to Loc_LoadFile_EndDone — load file end done
Loop_LoadFile_SymbolChars:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bls.b    Loop_LoadFile_RelocEntries                   ; Load file reloc entries if unsigned lower or same — checked #$101,d2
	cmp.w    #$501,d2                                     ; Check if d2 equals $501 (1281)
	bhi.b    Loop_LoadFile_RelocTable                     ; Load file reloc table if unsigned greater — checked #$501,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$800,d2                                     ; ORI.W #$800,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bsr.b    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
Loc_LoadFile_SymbolDone:
	cmp.w    #$8,d3                                       ; Check if d3 equals $8 (8)
	bcs.b    Loc_LoadFile_CopyHunkDebug                   ; Load file copy hunk debug if carry set (less than / lower) — checked #$8,d3
	cmp.w    #$b,d3                                       ; Check if d3 equals $b (11)
	bcs.b    Loc_LoadFile_DebugDone                       ; Load file debug done if carry set (less than / lower) — checked #$b,d3
	moveq    #$f,d1                                       ; Set d1 to 15 ($f)
	move.l   d3,d2                                        ; Copy d3 to d2
	subi.w   #$b,d2                                       ; Subtract 11 ($b) from d2
	ori.w    #$7f00,d2                                    ; ORI.W #$7f00,d2
Loop_LoadFile_DebugLength:
	bsr.b    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
Loop_LoadFile_DebugChars:
	moveq    #$0,d4                                       ; Clear value 0 to zero
	moveq    #$0,d7                                       ; Clear value 0 to zero
	adda.l   d3,a0                                        ; Add d3 to a0
	bra.w    Loop_LoadFile_SkipBlocks                     ; Jump to Loop_LoadFile_SkipBlocks — load file skip blocks
Loc_LoadFile_CopyHunkDebug:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$5,d2                                       ; Subtract 5 ($5) from d2
	ori.w    #$1c,d2                                      ; ORI.W #$1c,d2
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
	bra.b    Loop_LoadFile_DebugLength                    ; Jump to Loop_LoadFile_DebugLength — load file debug length
Loc_LoadFile_DebugDone:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$8,d2                                       ; Subtract 8 ($8) from d2
	ori.w    #$7c,d2                                      ; ORI.W #$7c,d2
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.b    Loop_LoadFile_DebugLength                    ; Jump to Loop_LoadFile_DebugLength — load file debug length
Loc_LoadFile_CopyHunkEnd:
	lea      Var_TempDecrunchVar(pc),a5                   ; Point a5 at temp decrunch var
	tst.b    (a5)                                         ; Check whether Var_TempDecrunchVar value is zero
	bne.b    Loop_LoadFile_SymbolLength                   ; Load file symbol length if non-zero/not equal — checked value at (a5)
	st.b     (a5)                                         ; Set Var_TempDecrunchVar to $FF (true)
	bsr.w    Func_LoadHunkSymbols                         ; Call Func_LoadHunkSymbols — load hunk symbols
Loc_LoadFile_EndDone:
	move.l   d4,d3                                        ; Copy d4 to d3
	move.l   a6,d2                                        ; Copy a6 to d2
	cmp.w    #$3,d3                                       ; Check if d3 equals $3 (3)
	bcs.b    Loc_LoadFile_ReadBlock                       ; Load file read block if carry set (less than / lower) — checked #$3,d3
	beq.b    Loc_LoadFile_ReadByte                        ; Load file read byte if zero/equal
	cmp.w    #$4,d3                                       ; Check if d3 equals $4 (4)
	bhi.b    Loop_LoadFile_SymbolChars                    ; Load file symbol chars if unsigned greater — checked #$4,d3
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_CheckNext                       ; Load file check next if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$400,d2                                     ; ORI.W #$400,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
Loop_LoadFile_FinalVerify:
	bsr.w    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	bra.b    Loop_LoadFile_DebugChars                     ; Jump to Loop_LoadFile_DebugChars — load file debug chars
Loc_LoadFile_CheckNext:
	cmp.w    #$501,d2                                     ; Check if d2 equals $501 (1281)
	bhi.b    Loc_LoadFile_LoopCheck                       ; Load file loop check if unsigned greater — checked #$501,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$2800,d2                                    ; Load chunky buffer row allocation size ($28 bytes)
	moveq    #$f,d1                                       ; Set d1 to 15 ($f)
	bra.b    Loop_LoadFile_FinalVerify                    ; Jump to Loop_LoadFile_FinalVerify — load file final verify
Loc_LoadFile_LoopCheck:
	subi.w   #$502,d2                                     ; Subtract 1282 ($502) from d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bsr.w    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	moveq    #$b,d2                                       ; Set d2 to 11 ($b)
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
	bra.b    Loop_LoadFile_FinalVerify                    ; Jump to Loop_LoadFile_FinalVerify — load file final verify
Loc_LoadFile_ReadByte:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_ReadWord                        ; Load file read word if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$400,d2                                     ; ORI.W #$400,d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
Loop_LoadFile_LoopCheck:
	bsr.w    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	bra.w    Loop_LoadFile_DebugChars                     ; Jump to Loop_LoadFile_DebugChars — load file debug chars
Loc_LoadFile_ReadWord:
	cmp.w    #$501,d2                                     ; Check if d2 equals $501 (1281)
	bhi.b    Loc_LoadFile_ReadLong                        ; Load file read long if unsigned greater — checked #$501,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$1400,d2                                    ; ORI.W #$1400,d2
	moveq    #$d,d1                                       ; Set d1 to 13 ($d)
	bra.b    Loop_LoadFile_LoopCheck                      ; Jump to Loop_LoadFile_LoopCheck — load file loop check
Loc_LoadFile_ReadLong:
	subi.w   #$502,d2                                     ; Subtract 1282 ($502) from d2
	ori.w    #$6000,d2                                    ; ORI.W #$6000,d2
	moveq    #$f,d1                                       ; Set d1 to 15 ($f)
	bra.b    Loop_LoadFile_LoopCheck                      ; Jump to Loop_LoadFile_LoopCheck — load file loop check
Loc_LoadFile_ReadBlock:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_BlockDone                       ; Load file block done if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
Loop_LoadFile_ReadByteLoop:
	bsr.w    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	bra.w    Loop_LoadFile_DebugChars                     ; Jump to Loop_LoadFile_DebugChars — load file debug chars
Loc_LoadFile_BlockDone:
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$200,d2                                     ; ORI.W #$200,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bra.b    Loop_LoadFile_ReadByteLoop                   ; Jump to Loop_LoadFile_ReadByteLoop — load file read byte loop
Loop_LoadFile_ReadWordLoop:
	moveq    #$3,d1                                       ; Set priority/parameter to 3 in d1
	subq.w   #$1,d7                                       ; Decrement d7 by one
	move.l   d7,d2                                        ; Copy d7 to d2
	bra.w    Func_ProcessRelocs32                         ; Jump to Func_ProcessRelocs32 — process relocs32
Loop_LoadFile_ReadLongLoop:
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	subq.w   #$7,d7                                       ; Subtract 7 ($7) from d7
	move.l   d7,d2                                        ; Copy d7 to d2
	ori.w    #$1b0,d2                                     ; ORI.W #$1b0,d2
	bra.w    Func_ProcessRelocs32                         ; Jump to Func_ProcessRelocs32 — process relocs32
Loop_LoadFile_ReadBlockLoop:
	moveq    #$a,d1                                       ; Set d1 to 10 ($a)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	moveq    #$6e,d2                                      ; Set d2 to 110 ($6e)
	bra.w    Func_ProcessRelocs32                         ; Jump to Func_ProcessRelocs32 — process relocs32
Func_LoadHunkSymbols:
	tst.w    d7                                           ; Test d7 for zero
	beq.b    Loc_LoadFile_ProcessLineDone                 ; Load file process line done if zero/equal — checked d7
	cmp.w    #$7,d7                                       ; Check if d7 equals $7 (7)
	bcs.b    Loop_LoadFile_ReadWordLoop                   ; Load file read word loop if carry set (less than / lower) — checked #$7,d7
	cmp.w    #$e,d7                                       ; Check if d7 equals $e (14)
	bcs.b    Loop_LoadFile_ReadLongLoop                   ; Load file read long loop if carry set (less than / lower) — checked #$e,d7
	cmp.w    #$400,d7                                     ; Check if d7 equals $400 (1024)
	bcs.b    Loop_LoadFile_ReadBlockLoop                  ; Load file read block loop if carry set (less than / lower) — checked #$400,d7
	moveq    #$10,d1                                      ; Set d1 to 16 ($10)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_ProcessRelocs32                         ; Call Func_ProcessRelocs32 — process relocs32
	moveq    #$6f,d2                                      ; Set d2 to 111 ($6f)
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.w    Func_ProcessRelocs32                         ; Jump to Func_ProcessRelocs32 — process relocs32
Loc_LoadFile_ProcessLineDone:
	rts                                                   ; Return to caller
Loop_LoadFile_ProcessLines:
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if unsigned lower or same — checked d4,d3
	lea      $2(a3),a4                                    ; Get address at offset $2 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_LoopDebug                       ; Load file loop debug if unsigned lower or same — checked a4,a1
	bra.b    Loc_LoadFile_LoopCode                        ; Jump to Loc_LoadFile_LoopCode — load file loop code
Loop_LoadFile_ProcessCode:
	moveq    #$3,d3                                       ; Set d3 to 3 ($3)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if unsigned lower or same — checked d4,d3
	lea      $1(a3),a4                                    ; Get address at offset $1 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_LoopDebug                       ; Load file loop debug if unsigned lower or same — checked a4,a1
	lea      $4902(a0),a4                                 ; Get address at offset $4902 from a0
	cmpa.l   a4,a3                                        ; Compare a4 with a3
	bcc.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if carry clear (greater or equal) — checked a4,a3
	bra.b    Loc_LoadFile_LoopCode                        ; Jump to Loc_LoadFile_LoopCode — load file loop code
Loop_LoadFile_ProcessData:
	moveq    #$2,d3                                       ; Set d3 to 2 ($2)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if unsigned lower or same — checked d4,d3
	cmpa.l   a3,a1                                        ; Compare a3 with a1
	bls.w    Loc_LoadFile_LoopDebug                       ; Load file loop debug if unsigned lower or same — checked a3,a1
	lea      $302(a0),a4                                  ; Get address at offset $302 from a0
	cmpa.l   a4,a3                                        ; Compare a4 with a3
	bcc.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if carry clear (greater or equal) — checked a4,a3
Loc_LoadFile_LoopCode:
	move.l   a3,d2                                        ; Copy a3 to d2
	sub.l    a0,d2                                        ; Subtract a0 from d2
	subq.l   #$1,d2                                       ; Decrement d2 by one
	bra.b    Loc_LoadFile_LoopSymbol                      ; Jump to Loc_LoadFile_LoopSymbol — load file loop symbol
Loc_LoadFile_LoopData:
	moveq    #$0,d7                                       ; Clear value 0 to zero
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	moveq    #$0,d4                                       ; Clear value 0 to zero
Loop_LoadFile_ProcessBSS:
	cmp.w    #$ffff,d7                                    ; Check if d7 equals $ffff (65535)
	bne.b    Loc_LoadFile_LoopBSS                         ; Load file loop bss if non-zero/not equal — d7 vs $ffff — checked #$ffff,d7
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_LoadFile_LoopBSS:
	movea.l  a0,a3                                        ; Copy a0 to a3
	move.b   (a3)+,d0                                     ; Load (a3)+ into d0
	move.b   (a3)+,d1                                     ; Load (a3)+ into d1
	move.l   a0,d5                                        ; Copy a0 to d5
	add.l    Var_PayloadSize(pc),d5                       ; Add current payload data size to d5
	cmp.l    a1,d5                                        ; Compare a1 with d5
	bls.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if unsigned lower or same — checked a1,d5
	move.l   a1,d5                                        ; Copy a1 to d5
Loop_LoadFile_ProcessReloc:
	cmp.l    a3,d5                                        ; Compare a3 with d5
	bls.b    Loc_LoadFile_LoopDebug                       ; Load file loop debug if unsigned lower or same — checked a3,d5
	cmp.b    (a3)+,d0                                     ; Compare (a3)+ with d0
	bne.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if non-zero/not equal — checked (a3)+,d0
	cmp.b    (a3),d1                                      ; Compare (a3) with d1
	bne.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if non-zero/not equal — checked (a3),d1
	move.b   $2(a0),d2                                    ; Read offset $2(a0) into d2
	cmp.b    $1(a3),d2                                    ; Compare $1(a3) with d2
	bne.b    Loop_LoadFile_ProcessData                    ; Load file process data if non-zero/not equal — checked $1(a3),d2
	move.b   $3(a0),d2                                    ; Read offset $3(a0) into d2
	cmp.b    $2(a3),d2                                    ; Compare $2(a3) with d2
	bne.b    Loop_LoadFile_ProcessCode                    ; Load file process code if non-zero/not equal — checked $2(a3),d2
	move.b   $4(a0),d2                                    ; Read offset $4(a0) into d2
	cmp.b    $3(a3),d2                                    ; Compare $3(a3) with d2
	bne.w    Loop_LoadFile_ProcessLines                   ; Load file process lines if non-zero/not equal — checked $3(a3),d2
	lea      (a0),a4                                      ; Point a4 at (a0)
	lea      (a3),a5                                      ; Point a5 at (a3)
	subq.l   #$1,a5                                       ; Decrement a5 by one
Loop_LoadFile_ProcessSymbol:
	cmpa.l   a5,a1                                        ; Compare a5 with a1
	beq.b    Loc_LoadFile_LoopReloc32                     ; Load file loop reloc32 if zero/equal — checked a5,a1
	cmpm.b   (a4)+,(a5)+                                  ; Compare (a4)+ with (a5)+
	beq.b    Loop_LoadFile_ProcessSymbol                  ; Load file process symbol if zero/equal — checked (a4)+,(a5)+
Loc_LoadFile_LoopReloc32:
	move.l   a4,d3                                        ; Copy a4 to d3
	sub.l    a0,d3                                        ; Subtract a0 from d3
	subq.w   #$1,d3                                       ; Decrement d3 by one
	cmp.w    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if unsigned lower or same — checked d4,d3
	move.l   a5,d2                                        ; Copy a5 to d2
	sub.l    a4,d2                                        ; Subtract a4 from d2
Loc_LoadFile_LoopSymbol:
	cmp.w    #$10a,d3                                     ; Check if d3 equals $10a (266)
	bcs.b    Loc_LoadFile_CheckHunkCode                   ; Load file check hunk code if carry set (less than / lower) — checked #$10a,d3
	move.w   #$10a,d4                                     ; Set d4 to 266 ($10a)
	movea.l  d2,a6                                        ; Switch library base to d2
	bra.w    Loc_LoadFile_CheckHunkDebug                  ; Jump to Loc_LoadFile_CheckHunkDebug — load file check hunk debug
Loc_LoadFile_LoopDebug:
	tst.w    d4                                           ; Test d4 for zero
	bne.w    Loc_LoadFile_CheckHunkDebug                  ; Load file check hunk debug if non-zero/not equal — checked d4
	tst.b    $3d02.l                                      ; Test register/value $3d02.l for zero or negative condition status
	beq.b    Loc_LoadFile_LoopEnd                         ; Load file loop end if zero/equal — checked $3d02.l
	sf.b     $3d02.l                                      ; Clear $3d02.l to $00 (false)
Loc_LoadFile_LoopEnd:
	addq.w   #$1,d7                                       ; Increment d7 by one
	moveq    #$0,d2                                       ; Clear value 0 to zero
	move.b   d0,d2                                        ; Copy return value to d2
	moveq    #$8,d1                                       ; Set d1 to 8 ($8)
	bsr.b    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	addq.l   #$1,a0                                       ; Increment a0 by one
	cmpa.l   a0,a1                                        ; Compare a0 with a1
	bhi.w    Loop_LoadFile_ProcessBSS                     ; Load file process bss if unsigned greater — checked a0,a1
	bsr.w    Func_LoadAllHunks                            ; Call Func_LoadAllHunks — load all hunks
	move.l   d6,(a2)+                                     ; Store d6 at address in a2
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Loc_LoadFile_CheckHunkCode:
	move.l   d3,d4                                        ; Copy d3 to d4
	movea.l  d2,a6                                        ; Switch library base to d2
	cmp.l    a3,d5                                        ; Compare a3 with d5
	bhi.w    Loop_LoadFile_ProcessReloc                   ; Load file process reloc if unsigned greater — checked a3,d5
	bra.w    Loc_LoadFile_CheckHunkDebug                  ; Jump to Loc_LoadFile_CheckHunkDebug — load file check hunk debug
Loop_LoadFile_CheckCode:
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	bsr.b    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	bra.w    Loc_LoadFile_CheckHunkBSS                    ; Jump to Loc_LoadFile_CheckHunkBSS — load file check hunk bss
Loop_LoadFile_CheckData:
	subi.l   #$1102,d2                                    ; Subtract 4354 ($1102) from d2
	moveq    #$10,d1                                      ; Set d1 to 16 ($10)
	bsr.b    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	moveq    #$3,d2                                       ; Set d2 to 3 ($3)
	moveq    #$2,d1                                       ; Set priority/parameter to 2 in d1
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	bra.b    Loc_LoadFile_CheckHunkBSS                    ; Jump to Loc_LoadFile_CheckHunkBSS — load file check hunk bss
Loop_LoadFile_CheckBSS:
	lsr.w    #$1,d2                                       ; Divide d2 by 2 (shift right 1)
	roxr.l   #$1,d6                                       ; ROXR.L #$1,d6
	bcs.b    Loc_LoadFile_CheckHunkData                   ; Load file check hunk data if carry set (less than / lower)
Func_LoadHunkDebugInfo:
	dbra     d1,Loop_LoadFile_CheckBSS                    ; Decrement d1 and loop to Loop_LoadFile_CheckBSS until done
	rts                                                   ; Return to caller
Loc_LoadFile_CheckHunkData:
	move.l   d6,(a2)+                                     ; Store d6 at address in a2
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	lea      Func_LoadHunkDebugInfo(pc),a5                ; Point a5 at load hunk debug info
	lea      Var_MenuSubID_Selected(pc),a4                ; Point a4 at current menu sub-item preference ID
	addq.b   #$1,(a4)                                     ; Add #$1 to (a4)
	bmi.w    Loop_LoadFile_CodeBlocks                     ; Load file code blocks if minus (negative sign bit set)
	bra.b    Func_LoadHunkDebugInfo                       ; Jump to Func_LoadHunkDebugInfo — load hunk debug info
Loop_LoadFile_CheckReloc:
	moveq    #$3,d2                                       ; Set d2 to 3 ($3)
	moveq    #$2,d1                                       ; Set priority/parameter to 2 in d1
	bsr.b    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	bra.w    Loc_LoadFile_CheckHunkEnd                    ; Jump to Loc_LoadFile_CheckHunkEnd — load file check hunk end
Loop_LoadFile_CheckSymbol:
	cmp.l    #$101,d2                                     ; Check if d2 equals $101 (257)
	bls.w    Loop_LoadFile_CheckCode                      ; Load file check code if unsigned lower or same — checked #$101,d2
	cmp.l    #$1101,d2                                    ; Check if d2 equals $1101 (4353)
	bhi.w    Loop_LoadFile_CheckData                      ; Load file check data if unsigned greater — checked #$1101,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$2000,d2                                    ; ORI.W #$2000,d2
	moveq    #$e,d1                                       ; Set d1 to 14 ($e)
	bsr.b    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
Loc_LoadFile_CheckHunkBSS:
	cmp.w    #$8,d3                                       ; Check if d3 equals $8 (8)
	bcs.b    Loc_LoadFile_CheckHunkReloc32                ; Load file check hunk reloc32 if carry set (less than / lower) — checked #$8,d3
	cmp.w    #$b,d3                                       ; Check if d3 equals $b (11)
	bcs.b    Loc_LoadFile_CheckHunkSymbol                 ; Load file check hunk symbol if carry set (less than / lower) — checked #$b,d3
	moveq    #$f,d1                                       ; Set d1 to 15 ($f)
	move.l   d3,d2                                        ; Copy d3 to d2
	subi.w   #$b,d2                                       ; Subtract 11 ($b) from d2
	ori.w    #$7f00,d2                                    ; ORI.W #$7f00,d2
Loop_LoadFile_CheckDebug:
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
Loop_LoadFile_CheckEnd:
	moveq    #$0,d4                                       ; Clear value 0 to zero
	moveq    #$0,d7                                       ; Clear value 0 to zero
	adda.l   d3,a0                                        ; Add d3 to a0
	bra.w    Loop_LoadFile_ProcessBSS                     ; Jump to Loop_LoadFile_ProcessBSS — load file process bss
Loc_LoadFile_CheckHunkReloc32:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$5,d2                                       ; Subtract 5 ($5) from d2
	ori.w    #$1c,d2                                      ; ORI.W #$1c,d2
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
	bra.b    Loop_LoadFile_CheckDebug                     ; Jump to Loop_LoadFile_CheckDebug — load file check debug
Loc_LoadFile_CheckHunkSymbol:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$8,d2                                       ; Subtract 8 ($8) from d2
	ori.w    #$7c,d2                                      ; ORI.W #$7c,d2
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.b    Loop_LoadFile_CheckDebug                     ; Jump to Loop_LoadFile_CheckDebug — load file check debug
Loc_LoadFile_CheckHunkDebug:
	tst.b    $3d02.l                                      ; Test register/value $3d02.l for zero or negative condition status
	bne.w    Loop_LoadFile_CheckReloc                     ; Load file check reloc if non-zero/not equal — checked $3d02.l
	st.b     $3d02.l                                      ; Set $3d02.l to $FF (true)
	bsr.w    Func_LoadAllHunks                            ; Call Func_LoadAllHunks — load all hunks
Loc_LoadFile_CheckHunkEnd:
	move.l   d4,d3                                        ; Copy d4 to d3
	move.l   a6,d2                                        ; Copy a6 to d2
	cmp.w    #$3,d3                                       ; Check if d3 equals $3 (3)
	bcs.w    Loc_LoadFile_ValidHunkDebug                  ; Load file valid hunk debug if carry set (less than / lower) — checked #$3,d3
	beq.b    Loc_LoadFile_ValidHunkBSS                    ; Load file valid hunk bss if zero/equal
	cmp.w    #$4,d3                                       ; Check if d3 equals $4 (4)
	bhi.w    Loop_LoadFile_CheckSymbol                    ; Load file check symbol if unsigned greater — checked #$4,d3
	cmp.l    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_ValidHunkCode                   ; Load file valid hunk code if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$400,d2                                     ; ORI.W #$400,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
Loop_LoadFile_ValidCode:
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	bra.b    Loop_LoadFile_CheckEnd                       ; Jump to Loop_LoadFile_CheckEnd — load file check end
Loc_LoadFile_ValidHunkCode:
	cmp.l    #$1101,d2                                    ; Check if d2 equals $1101 (4353)
	bhi.b    Loc_LoadFile_ValidHunkData                   ; Load file valid hunk data if unsigned greater — checked #$1101,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	moveq    #$a,d2                                       ; Set d2 to 10 ($a)
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
	bra.b    Loop_LoadFile_ValidCode                      ; Jump to Loop_LoadFile_ValidCode — load file valid code
Loc_LoadFile_ValidHunkData:
	subi.l   #$1102,d2                                    ; Subtract 4354 ($1102) from d2
	moveq    #$10,d1                                      ; Set d1 to 16 ($10)
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	moveq    #$b,d2                                       ; Set d2 to 11 ($b)
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
	bra.b    Loop_LoadFile_ValidCode                      ; Jump to Loop_LoadFile_ValidCode — load file valid code
Loc_LoadFile_ValidHunkBSS:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_ValidHunkReloc                  ; Load file valid hunk reloc if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$400,d2                                     ; ORI.W #$400,d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
Loop_LoadFile_ValidData:
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	bra.w    Loop_LoadFile_CheckEnd                       ; Jump to Loop_LoadFile_CheckEnd — load file check end
Loc_LoadFile_ValidHunkReloc:
	cmp.w    #$901,d2                                     ; Check if d2 equals $901 (2305)
	bhi.b    Loc_LoadFile_ValidHunkSymbol                 ; Load file valid hunk symbol if unsigned greater — checked #$901,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$2800,d2                                    ; Load chunky buffer row allocation size ($28 bytes)
	moveq    #$e,d1                                       ; Set d1 to 14 ($e)
	bra.b    Loop_LoadFile_ValidData                      ; Jump to Loop_LoadFile_ValidData — load file valid data
Loc_LoadFile_ValidHunkSymbol:
	subi.w   #$902,d2                                     ; Subtract 2306 ($902) from d2
	moveq    #$e,d1                                       ; Set d1 to 14 ($e)
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	moveq    #$6,d2                                       ; Set d2 to 6 ($6)
	moveq    #$3,d1                                       ; Set priority/parameter to 3 in d1
	bra.w    Loop_LoadFile_ValidData                      ; Jump to Loop_LoadFile_ValidData — load file valid data
Loc_LoadFile_ValidHunkDebug:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_ValidHunkEnd                    ; Load file valid hunk end if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
Loop_LoadFile_ValidBSS:
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	bra.w    Loop_LoadFile_CheckEnd                       ; Jump to Loop_LoadFile_CheckEnd — load file check end
Loc_LoadFile_ValidHunkEnd:
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$200,d2                                     ; ORI.W #$200,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bra.b    Loop_LoadFile_ValidBSS                       ; Jump to Loop_LoadFile_ValidBSS — load file valid bss
Loop_LoadFile_ValidReloc:
	moveq    #$3,d1                                       ; Set priority/parameter to 3 in d1
	subq.w   #$1,d7                                       ; Decrement d7 by one
	move.l   d7,d2                                        ; Copy d7 to d2
	bra.w    Func_LoadHunkDebugInfo                       ; Jump to Func_LoadHunkDebugInfo — load hunk debug info
Loop_LoadFile_ValidSymbol:
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	subq.w   #$7,d7                                       ; Subtract 7 ($7) from d7
	move.l   d7,d2                                        ; Copy d7 to d2
	ori.w    #$1b0,d2                                     ; ORI.W #$1b0,d2
	bra.w    Func_LoadHunkDebugInfo                       ; Jump to Func_LoadHunkDebugInfo — load hunk debug info
Loop_LoadFile_ValidDebug:
	moveq    #$a,d1                                       ; Set d1 to 10 ($a)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	moveq    #$6e,d2                                      ; Set d2 to 110 ($6e)
	bra.w    Func_LoadHunkDebugInfo                       ; Jump to Func_LoadHunkDebugInfo — load hunk debug info
Func_LoadAllHunks:
	tst.w    d7                                           ; Test d7 for zero
	beq.b    Loc_LoadFile_ProcessCodeHunk                 ; Load file process code hunk if zero/equal — checked d7
	cmp.w    #$7,d7                                       ; Check if d7 equals $7 (7)
	bcs.b    Loop_LoadFile_ValidReloc                     ; Load file valid reloc if carry set (less than / lower) — checked #$7,d7
	cmp.w    #$e,d7                                       ; Check if d7 equals $e (14)
	bcs.b    Loop_LoadFile_ValidSymbol                    ; Load file valid symbol if carry set (less than / lower) — checked #$e,d7
	cmp.w    #$400,d7                                     ; Check if d7 equals $400 (1024)
	bcs.b    Loop_LoadFile_ValidDebug                     ; Load file valid debug if carry set (less than / lower) — checked #$400,d7
	moveq    #$10,d1                                      ; Set d1 to 16 ($10)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_LoadHunkDebugInfo                       ; Call Func_LoadHunkDebugInfo — load hunk debug info
	moveq    #$6f,d2                                      ; Set d2 to 111 ($6f)
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.w    Func_LoadHunkDebugInfo                       ; Jump to Func_LoadHunkDebugInfo — load hunk debug info
Loc_LoadFile_ProcessCodeHunk:
	rts                                                   ; Return to caller
Loop_LoadFile_CodeCopy:
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if unsigned lower or same — checked d4,d3
	lea      $2(a3),a4                                    ; Get address at offset $2 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_ProcessEndHunk                  ; Load file process end hunk if unsigned lower or same — checked a4,a1
	bra.b    Loc_LoadFile_ProcessDataHunk                 ; Jump to Loc_LoadFile_ProcessDataHunk — load file process data hunk
Loop_LoadFile_DataCopy:
	moveq    #$3,d3                                       ; Set d3 to 3 ($3)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if unsigned lower or same — checked d4,d3
	lea      $1(a3),a4                                    ; Get address at offset $1 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_ProcessEndHunk                  ; Load file process end hunk if unsigned lower or same — checked a4,a1
	bra.b    Loc_LoadFile_ProcessDataHunk                 ; Jump to Loc_LoadFile_ProcessDataHunk — load file process data hunk
Loop_LoadFile_BSSClear:
	moveq    #$2,d3                                       ; Set d3 to 2 ($2)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if unsigned lower or same — checked d4,d3
	cmpa.l   a3,a1                                        ; Compare a3 with a1
	bls.w    Loc_LoadFile_ProcessEndHunk                  ; Load file process end hunk if unsigned lower or same — checked a3,a1
	lea      $302(a0),a4                                  ; Get address at offset $302 from a0
	cmpa.l   a4,a3                                        ; Compare a4 with a3
	bcc.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if carry clear (greater or equal) — checked a4,a3
Loc_LoadFile_ProcessDataHunk:
	move.l   a3,d2                                        ; Copy a3 to d2
	sub.l    a0,d2                                        ; Subtract a0 from d2
	subq.l   #$1,d2                                       ; Decrement d2 by one
	bra.b    Loc_LoadFile_ProcessDebugHunk                ; Jump to Loc_LoadFile_ProcessDebugHunk — load file process debug hunk
Loc_LoadFile_ProcessBSSHunk:
	moveq    #$0,d7                                       ; Clear value 0 to zero
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	moveq    #$0,d4                                       ; Clear value 0 to zero
Loop_LoadFile_RelocCopy:
	cmp.w    #$ffff,d7                                    ; Check if d7 equals $ffff (65535)
	bne.b    Loc_LoadFile_ProcessRelocHunk                ; Load file process reloc hunk if non-zero/not equal — d7 vs $ffff — checked #$ffff,d7
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_LoadFile_ProcessRelocHunk:
	movea.l  a0,a3                                        ; Copy a0 to a3
	move.b   (a3)+,d0                                     ; Load (a3)+ into d0
	move.b   (a3)+,d1                                     ; Load (a3)+ into d1
	move.l   a0,d5                                        ; Copy a0 to d5
	add.l    Var_PayloadSize(pc),d5                       ; Add current payload data size to d5
	cmp.l    a1,d5                                        ; Compare a1 with d5
	bls.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if unsigned lower or same — checked a1,d5
	move.l   a1,d5                                        ; Copy a1 to d5
Loop_LoadFile_SymbolCopy:
	cmp.l    a3,d5                                        ; Compare a3 with d5
	bls.b    Loc_LoadFile_ProcessEndHunk                  ; Load file process end hunk if unsigned lower or same — checked a3,d5
	cmp.b    (a3)+,d0                                     ; Compare (a3)+ with d0
	bne.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if non-zero/not equal — checked (a3)+,d0
	cmp.b    (a3),d1                                      ; Compare (a3) with d1
	bne.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if non-zero/not equal — checked (a3),d1
	move.b   $2(a0),d2                                    ; Read offset $2(a0) into d2
	cmp.b    $1(a3),d2                                    ; Compare $1(a3) with d2
	bne.b    Loop_LoadFile_BSSClear                       ; Load file bssclear if non-zero/not equal — checked $1(a3),d2
	move.b   $3(a0),d2                                    ; Read offset $3(a0) into d2
	cmp.b    $2(a3),d2                                    ; Compare $2(a3) with d2
	bne.b    Loop_LoadFile_DataCopy                       ; Load file data copy if non-zero/not equal — checked $2(a3),d2
	move.b   $4(a0),d2                                    ; Read offset $4(a0) into d2
	cmp.b    $3(a3),d2                                    ; Compare $3(a3) with d2
	bne.w    Loop_LoadFile_CodeCopy                       ; Load file code copy if non-zero/not equal — checked $3(a3),d2
	lea      (a0),a4                                      ; Point a4 at (a0)
	lea      (a3),a5                                      ; Point a5 at (a3)
	subq.l   #$1,a5                                       ; Decrement a5 by one
Loop_LoadFile_DebugCopy:
	cmpa.l   a5,a1                                        ; Compare a5 with a1
	beq.b    Loc_LoadFile_ProcessSymbolHunk               ; Load file process symbol hunk if zero/equal — checked a5,a1
	cmpm.b   (a4)+,(a5)+                                  ; Compare (a4)+ with (a5)+
	beq.b    Loop_LoadFile_DebugCopy                      ; Load file debug copy if zero/equal — checked (a4)+,(a5)+
Loc_LoadFile_ProcessSymbolHunk:
	move.l   a4,d3                                        ; Copy a4 to d3
	sub.l    a0,d3                                        ; Subtract a0 from d3
	subq.w   #$1,d3                                       ; Decrement d3 by one
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if unsigned lower or same — checked d4,d3
	move.l   a5,d2                                        ; Copy a5 to d2
	sub.l    a4,d2                                        ; Subtract a4 from d2
Loc_LoadFile_ProcessDebugHunk:
	cmp.w    #$10a,d3                                     ; Check if d3 equals $10a (266)
	bcs.b    Loc_LoadFile_LoopSaveData                    ; Load file loop save data if carry set (less than / lower) — checked #$10a,d3
	move.w   #$10a,d4                                     ; Set d4 to 266 ($10a)
	movea.l  d2,a6                                        ; Switch library base to d2
	bra.w    Loc_LoadFile_LoopSaveEnd                     ; Jump to Loc_LoadFile_LoopSaveEnd — load file loop save end
Loc_LoadFile_ProcessEndHunk:
	tst.w    d4                                           ; Test d4 for zero
	bne.w    Loc_LoadFile_LoopSaveEnd                     ; Load file loop save end if non-zero/not equal — checked d4
	tst.b    $3d01.l                                      ; Test register/value $3d01.l for zero or negative condition status
	beq.b    Loc_LoadFile_LoopSaveCode                    ; Load file loop save code if zero/equal — checked $3d01.l
	sf.b     $3d01.l                                      ; Clear $3d01.l to $00 (false)
Loc_LoadFile_LoopSaveCode:
	addq.w   #$1,d7                                       ; Increment d7 by one
	moveq    #$0,d2                                       ; Clear value 0 to zero
	move.b   d0,d2                                        ; Copy return value to d2
	moveq    #$8,d1                                       ; Set d1 to 8 ($8)
	bsr.b    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	addq.l   #$1,a0                                       ; Increment a0 by one
	cmpa.l   a0,a1                                        ; Compare a0 with a1
	bhi.w    Loop_LoadFile_RelocCopy                      ; Load file reloc copy if unsigned greater — checked a0,a1
	bsr.w    Func_WriteAllHunks                           ; Call Func_WriteAllHunks — write all hunks
	move.l   d6,(a2)+                                     ; Store d6 at address in a2
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Loc_LoadFile_LoopSaveData:
	move.l   d3,d4                                        ; Copy d3 to d4
	movea.l  d2,a6                                        ; Switch library base to d2
	cmp.l    a3,d5                                        ; Compare a3 with d5
	bhi.w    Loop_LoadFile_SymbolCopy                     ; Load file symbol copy if unsigned greater — checked a3,d5
	bra.w    Loc_LoadFile_LoopSaveEnd                     ; Jump to Loc_LoadFile_LoopSaveEnd — load file loop save end
Loop_LoadFile_SaveCode:
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	bsr.b    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	bra.b    Loc_LoadFile_LoopSaveReloc                   ; Jump to Loc_LoadFile_LoopSaveReloc — load file loop save reloc
Loop_LoadFile_SaveData:
	subi.w   #$302,d2                                     ; Subtract 770 ($302) from d2
	ori.w    #$c00,d2                                     ; ORI.W #$c00,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bsr.b    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	bra.b    Loc_LoadFile_LoopSaveReloc                   ; Jump to Loc_LoadFile_LoopSaveReloc — load file loop save reloc
Loop_LoadFile_SaveBSS:
	lsr.w    #$1,d2                                       ; Divide d2 by 2 (shift right 1)
	roxr.l   #$1,d6                                       ; ROXR.L #$1,d6
	bcs.b    Loc_LoadFile_LoopSaveBSS                     ; Load file loop save bss if carry set (less than / lower)
Func_WriteHunkSegment:
	dbra     d1,Loop_LoadFile_SaveBSS                     ; Decrement d1 and loop to Loop_LoadFile_SaveBSS until done
	rts                                                   ; Return to caller
Loc_LoadFile_LoopSaveBSS:
	move.l   d6,(a2)+                                     ; Store d6 at address in a2
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	lea      Func_WriteHunkSegment(pc),a5                 ; Point a5 at write hunk segment
	lea      Var_MenuSubID_Selected(pc),a4                ; Point a4 at current menu sub-item preference ID
	addq.b   #$1,(a4)                                     ; Add #$1 to (a4)
	bmi.w    Loop_LoadFile_CodeBlocks                     ; Load file code blocks if minus (negative sign bit set)
	bra.b    Func_WriteHunkSegment                        ; Jump to Func_WriteHunkSegment — write hunk segment
Loop_LoadFile_SaveReloc:
	moveq    #$3,d2                                       ; Set d2 to 3 ($3)
	moveq    #$2,d1                                       ; Set priority/parameter to 2 in d1
	bsr.b    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	bra.b    Loc_LoadFile_FinalChecks                     ; Jump to Loc_LoadFile_FinalChecks — load file final checks
Loop_LoadFile_SaveSymbol:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bls.b    Loop_LoadFile_SaveCode                       ; Load file save code if unsigned lower or same — checked #$101,d2
	cmp.w    #$301,d2                                     ; Check if d2 equals $301 (769)
	bhi.b    Loop_LoadFile_SaveData                       ; Load file save data if unsigned greater — checked #$301,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$400,d2                                     ; ORI.W #$400,d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
	bsr.b    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
Loc_LoadFile_LoopSaveReloc:
	cmp.w    #$8,d3                                       ; Check if d3 equals $8 (8)
	bcs.b    Loc_LoadFile_LoopSaveSymbol                  ; Load file loop save symbol if carry set (less than / lower) — checked #$8,d3
	cmp.w    #$b,d3                                       ; Check if d3 equals $b (11)
	bcs.b    Loc_LoadFile_LoopSaveDebug                   ; Load file loop save debug if carry set (less than / lower) — checked #$b,d3
	moveq    #$f,d1                                       ; Set d1 to 15 ($f)
	move.l   d3,d2                                        ; Copy d3 to d2
	subi.w   #$b,d2                                       ; Subtract 11 ($b) from d2
	ori.w    #$7f00,d2                                    ; ORI.W #$7f00,d2
Loop_LoadFile_SaveDebug:
	bsr.b    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
Loop_LoadFile_SaveEnd:
	moveq    #$0,d4                                       ; Clear value 0 to zero
	moveq    #$0,d7                                       ; Clear value 0 to zero
	adda.l   d3,a0                                        ; Add d3 to a0
	bra.w    Loop_LoadFile_RelocCopy                      ; Jump to Loop_LoadFile_RelocCopy — load file reloc copy
Loc_LoadFile_LoopSaveSymbol:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$5,d2                                       ; Subtract 5 ($5) from d2
	ori.w    #$1c,d2                                      ; ORI.W #$1c,d2
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
	bra.b    Loop_LoadFile_SaveDebug                      ; Jump to Loop_LoadFile_SaveDebug — load file save debug
Loc_LoadFile_LoopSaveDebug:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$8,d2                                       ; Subtract 8 ($8) from d2
	ori.w    #$7c,d2                                      ; ORI.W #$7c,d2
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.b    Loop_LoadFile_SaveDebug                      ; Jump to Loop_LoadFile_SaveDebug — load file save debug
Loc_LoadFile_LoopSaveEnd:
	tst.b    $3d01.l                                      ; Test register/value $3d01.l for zero or negative condition status
	bne.b    Loop_LoadFile_SaveReloc                      ; Load file save reloc if non-zero/not equal — checked $3d01.l
	st.b     $3d01.l                                      ; Set $3d01.l to $FF (true)
	bsr.w    Func_WriteAllHunks                           ; Call Func_WriteAllHunks — write all hunks
Loc_LoadFile_FinalChecks:
	move.l   d4,d3                                        ; Copy d4 to d3
	move.l   a6,d2                                        ; Copy a6 to d2
	cmp.w    #$3,d3                                       ; Check if d3 equals $3 (3)
	bcs.b    Loc_LoadFile_VerifyDebugSize                 ; Load file verify debug size if carry set (less than / lower) — checked #$3,d3
	beq.b    Loc_LoadFile_VerifyBSSSize                   ; Load file verify bsssize if zero/equal
	cmp.w    #$4,d3                                       ; Check if d3 equals $4 (4)
	bhi.b    Loop_LoadFile_SaveSymbol                     ; Load file save symbol if unsigned greater — checked #$4,d3
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_VerifyCodeSize                  ; Load file verify code size if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$400,d2                                     ; ORI.W #$400,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
Loop_LoadFile_FinalVerifyLoop:
	bsr.w    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	bra.b    Loop_LoadFile_SaveEnd                        ; Jump to Loop_LoadFile_SaveEnd — load file save end
Loc_LoadFile_VerifyCodeSize:
	cmp.w    #$301,d2                                     ; Check if d2 equals $301 (769)
	bhi.b    Loc_LoadFile_VerifyDataSize                  ; Load file verify data size if unsigned greater — checked #$301,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$1400,d2                                    ; ORI.W #$1400,d2
	moveq    #$e,d1                                       ; Set d1 to 14 ($e)
	bra.b    Loop_LoadFile_FinalVerifyLoop                ; Jump to Loop_LoadFile_FinalVerifyLoop — load file final verify loop
Loc_LoadFile_VerifyDataSize:
	subi.w   #$302,d2                                     ; Subtract 770 ($302) from d2
	moveq    #$f,d1                                       ; Set d1 to 15 ($f)
	ori.w    #$2c00,d2                                    ; ORI.W #$2c00,d2
	bra.b    Loop_LoadFile_FinalVerifyLoop                ; Jump to Loop_LoadFile_FinalVerifyLoop — load file final verify loop
Loc_LoadFile_VerifyBSSSize:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_VerifyRelocSize                 ; Load file verify reloc size if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$400,d2                                     ; ORI.W #$400,d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
Loop_LoadFile_VerifyCode:
	bsr.w    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	bra.w    Loop_LoadFile_SaveEnd                        ; Jump to Loop_LoadFile_SaveEnd — load file save end
Loc_LoadFile_VerifyRelocSize:
	cmp.w    #$301,d2                                     ; Check if d2 equals $301 (769)
	bhi.b    Loc_LoadFile_VerifySymbolSize                ; Load file verify symbol size if unsigned greater — checked #$301,d2
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$a00,d2                                     ; ORI.W #$a00,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bra.b    Loop_LoadFile_VerifyCode                     ; Jump to Loop_LoadFile_VerifyCode — load file verify code
Loc_LoadFile_VerifySymbolSize:
	subi.w   #$302,d2                                     ; Subtract 770 ($302) from d2
	ori.w    #$1800,d2                                    ; ORI.W #$1800,d2
	moveq    #$d,d1                                       ; Set d1 to 13 ($d)
	bra.b    Loop_LoadFile_VerifyCode                     ; Jump to Loop_LoadFile_VerifyCode — load file verify code
Loc_LoadFile_VerifyDebugSize:
	cmp.w    #$101,d2                                     ; Check if d2 equals $101 (257)
	bhi.b    Loc_LoadFile_VerifyEndSize                   ; Load file verify end size if unsigned greater — checked #$101,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
Loop_LoadFile_VerifyData:
	bsr.w    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	bra.w    Loop_LoadFile_SaveEnd                        ; Jump to Loop_LoadFile_SaveEnd — load file save end
Loc_LoadFile_VerifyEndSize:
	subi.w   #$102,d2                                     ; Subtract 258 ($102) from d2
	ori.w    #$200,d2                                     ; ORI.W #$200,d2
	moveq    #$c,d1                                       ; Set d1 to 12 ($c)
	bra.b    Loop_LoadFile_VerifyData                     ; Jump to Loop_LoadFile_VerifyData — load file verify data
Loop_LoadFile_VerifyBSS:
	moveq    #$3,d1                                       ; Set priority/parameter to 3 in d1
	subq.w   #$1,d7                                       ; Decrement d7 by one
	move.l   d7,d2                                        ; Copy d7 to d2
	bra.w    Func_WriteHunkSegment                        ; Jump to Func_WriteHunkSegment — write hunk segment
Loop_LoadFile_VerifyReloc:
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	subq.w   #$7,d7                                       ; Subtract 7 ($7) from d7
	move.l   d7,d2                                        ; Copy d7 to d2
	ori.w    #$1b0,d2                                     ; ORI.W #$1b0,d2
	bra.w    Func_WriteHunkSegment                        ; Jump to Func_WriteHunkSegment — write hunk segment
Loop_LoadFile_VerifySymbol:
	moveq    #$a,d1                                       ; Set d1 to 10 ($a)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	moveq    #$6e,d2                                      ; Set d2 to 110 ($6e)
	bra.w    Func_WriteHunkSegment                        ; Jump to Func_WriteHunkSegment — write hunk segment
Func_WriteAllHunks:
	tst.w    d7                                           ; Test d7 for zero
	beq.b    Loc_LoadFile_RelocLoop                       ; Load file reloc loop if zero/equal — checked d7
	cmp.w    #$7,d7                                       ; Check if d7 equals $7 (7)
	bcs.b    Loop_LoadFile_VerifyBSS                      ; Load file verify bss if carry set (less than / lower) — checked #$7,d7
	cmp.w    #$e,d7                                       ; Check if d7 equals $e (14)
	bcs.b    Loop_LoadFile_VerifyReloc                    ; Load file verify reloc if carry set (less than / lower) — checked #$e,d7
	cmp.w    #$400,d7                                     ; Check if d7 equals $400 (1024)
	bcs.b    Loop_LoadFile_VerifySymbol                   ; Load file verify symbol if carry set (less than / lower) — checked #$400,d7
	moveq    #$10,d1                                      ; Set d1 to 16 ($10)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_WriteHunkSegment                        ; Call Func_WriteHunkSegment — write hunk segment
	moveq    #$6f,d2                                      ; Set d2 to 111 ($6f)
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.w    Func_WriteHunkSegment                        ; Jump to Func_WriteHunkSegment — write hunk segment
Loc_LoadFile_RelocLoop:
	rts                                                   ; Return to caller
Loop_LoadFile_VerifyDebug:
	moveq    #$4,d3                                       ; Set d3 to 4 ($4)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SegmentList                    ; Load file segment list if unsigned lower or same — checked d4,d3
	lea      $2(a3),a4                                    ; Get address at offset $2 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_ProcessBSSBlock                 ; Load file process bssblock if unsigned lower or same — checked a4,a1
	bra.b    Loc_LoadFile_SymbolLoop                      ; Jump to Loc_LoadFile_SymbolLoop — load file symbol loop
Loop_LoadFile_VerifyEnd:
	moveq    #$3,d3                                       ; Set d3 to 3 ($3)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SegmentList                    ; Load file segment list if unsigned lower or same — checked d4,d3
	lea      $1(a3),a4                                    ; Get address at offset $1 from a3
	cmpa.l   a4,a1                                        ; Compare a4 with a1
	bls.w    Loc_LoadFile_ProcessBSSBlock                 ; Load file process bssblock if unsigned lower or same — checked a4,a1
	bra.b    Loc_LoadFile_SymbolLoop                      ; Jump to Loc_LoadFile_SymbolLoop — load file symbol loop
Loop_LoadFile_FinalCleanup:
	moveq    #$2,d3                                       ; Set d3 to 2 ($2)
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SegmentList                    ; Load file segment list if unsigned lower or same — checked d4,d3
	cmpa.l   a3,a1                                        ; Compare a3 with a1
	bls.w    Loc_LoadFile_ProcessBSSBlock                 ; Load file process bssblock if unsigned lower or same — checked a3,a1
Loc_LoadFile_SymbolLoop:
	move.l   a3,d2                                        ; Copy a3 to d2
	sub.l    a0,d2                                        ; Subtract a0 from d2
	subq.l   #$1,d2                                       ; Decrement d2 by one
	bra.b    Loc_LoadFile_ProcessDataBlock                ; Jump to Loc_LoadFile_ProcessDataBlock — load file process data block
Loc_LoadFile_DebugLoop:
	moveq    #$0,d7                                       ; Clear value 0 to zero
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	moveq    #$0,d4                                       ; Clear value 0 to zero
Loop_LoadFile_AllocLoop:
	cmp.w    #$ffff,d7                                    ; Check if d7 equals $ffff (65535)
	bne.b    Loc_LoadFile_EndLoop                         ; Load file end loop if non-zero/not equal — d7 vs $ffff — checked #$ffff,d7
	bra.w    Loop_SetStatusError                          ; Jump to Loop_SetStatusError — set status error
Loc_LoadFile_EndLoop:
	movea.l  a0,a3                                        ; Copy a0 to a3
	move.b   (a3)+,d0                                     ; Load (a3)+ into d0
	move.b   (a3)+,d1                                     ; Load (a3)+ into d1
	move.l   a0,d5                                        ; Copy a0 to d5
	add.l    Var_PayloadSize(pc),d5                       ; Add current payload data size to d5
	cmp.l    a1,d5                                        ; Compare a1 with d5
	bls.b    Loop_LoadFile_SegmentList                    ; Load file segment list if unsigned lower or same — checked a1,d5
	move.l   a1,d5                                        ; Copy a1 to d5
Loop_LoadFile_SegmentList:
	cmp.l    a3,d5                                        ; Compare a3 with d5
	bls.b    Loc_LoadFile_ProcessBSSBlock                 ; Load file process bssblock if unsigned lower or same — checked a3,d5
	cmp.b    (a3)+,d0                                     ; Compare (a3)+ with d0
	bne.b    Loop_LoadFile_SegmentList                    ; Load file segment list if non-zero/not equal — checked (a3)+,d0
	cmp.b    (a3),d1                                      ; Compare (a3) with d1
	bne.b    Loop_LoadFile_SegmentList                    ; Load file segment list if non-zero/not equal — checked (a3),d1
	move.b   $2(a0),d2                                    ; Read offset $2(a0) into d2
	cmp.b    $1(a3),d2                                    ; Compare $1(a3) with d2
	bne.b    Loop_LoadFile_FinalCleanup                   ; Load file final cleanup if non-zero/not equal — checked $1(a3),d2
	move.b   $3(a0),d2                                    ; Read offset $3(a0) into d2
	cmp.b    $2(a3),d2                                    ; Compare $2(a3) with d2
	bne.b    Loop_LoadFile_VerifyEnd                      ; Load file verify end if non-zero/not equal — checked $2(a3),d2
	move.b   $4(a0),d2                                    ; Read offset $4(a0) into d2
	cmp.b    $3(a3),d2                                    ; Compare $3(a3) with d2
	bne.w    Loop_LoadFile_VerifyDebug                    ; Load file verify debug if non-zero/not equal — checked $3(a3),d2
	lea      (a0),a4                                      ; Point a4 at (a0)
	lea      (a3),a5                                      ; Point a5 at (a3)
	subq.l   #$1,a5                                       ; Decrement a5 by one
Loop_LoadFile_SegAlloc:
	cmpa.l   a5,a1                                        ; Compare a5 with a1
	beq.b    Loc_LoadFile_ProcessCodeBlock                ; Load file process code block if zero/equal — checked a5,a1
	cmpm.b   (a4)+,(a5)+                                  ; Compare (a4)+ with (a5)+
	beq.b    Loop_LoadFile_SegAlloc                       ; Load file seg alloc if zero/equal — checked (a4)+,(a5)+
Loc_LoadFile_ProcessCodeBlock:
	move.l   a4,d3                                        ; Copy a4 to d3
	sub.l    a0,d3                                        ; Subtract a0 from d3
	subq.w   #$1,d3                                       ; Decrement d3 by one
	cmp.l    d4,d3                                        ; Compare d4 with d3
	bls.b    Loop_LoadFile_SegmentList                    ; Load file segment list if unsigned lower or same — checked d4,d3
	move.l   a5,d2                                        ; Copy a5 to d2
	sub.l    a4,d2                                        ; Subtract a4 from d2
Loc_LoadFile_ProcessDataBlock:
	cmp.w    #$10a,d3                                     ; Check if d3 equals $10a (266)
	bcs.b    Loc_LoadFile_ProcessSymbolBlock              ; Load file process symbol block if carry set (less than / lower) — checked #$10a,d3
	move.w   #$10a,d4                                     ; Set d4 to 266 ($10a)
	movea.l  d2,a6                                        ; Switch library base to d2
	bra.w    Loc_LoadFile_BlockLoopBSS                    ; Jump to Loc_LoadFile_BlockLoopBSS — load file block loop bss
Loc_LoadFile_ProcessBSSBlock:
	tst.w    d4                                           ; Test d4 for zero
	bne.w    Loc_LoadFile_BlockLoopBSS                    ; Load file block loop bss if non-zero/not equal — checked d4
	tst.b    $3d00.l                                      ; Test register/value $3d00.l for zero or negative condition status
	beq.b    Loc_LoadFile_ProcessRelocBlock               ; Load file process reloc block if zero/equal — checked $3d00.l
	sf.b     $3d00.l                                      ; Clear $3d00.l to $00 (false)
Loc_LoadFile_ProcessRelocBlock:
	addq.w   #$1,d7                                       ; Increment d7 by one
	moveq    #$0,d2                                       ; Clear value 0 to zero
	move.b   d0,d2                                        ; Copy return value to d2
	moveq    #$8,d1                                       ; Set d1 to 8 ($8)
	bsr.b    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	addq.l   #$1,a0                                       ; Increment a0 by one
	cmpa.l   a0,a1                                        ; Compare a0 with a1
	bhi.w    Loop_LoadFile_AllocLoop                      ; Load file alloc loop if unsigned greater — checked a0,a1
	bsr.w    Func_VerifyDestinationBuffer                 ; Call Func_VerifyDestinationBuffer — verify destination buffer
	move.l   d6,(a2)+                                     ; Store d6 at address in a2
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Loc_LoadFile_ProcessSymbolBlock:
	move.l   d3,d4                                        ; Copy d3 to d4
	movea.l  d2,a6                                        ; Switch library base to d2
	cmp.l    a3,d5                                        ; Compare a3 with d5
	bhi.w    Loop_LoadFile_SegmentList                    ; Load file segment list if unsigned greater — checked a3,d5
	bra.w    Loc_LoadFile_BlockLoopBSS                    ; Jump to Loc_LoadFile_BlockLoopBSS — load file block loop bss
Loop_LoadFile_BlockCode:
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$8,d1                                       ; Set d1 to 8 ($8)
	bsr.b    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	bra.b    Loc_LoadFile_ProcessEndBlock                 ; Jump to Loc_LoadFile_ProcessEndBlock — load file process end block
Loop_LoadFile_BlockData:
	lsr.w    #$1,d2                                       ; Divide d2 by 2 (shift right 1)
	roxr.l   #$1,d6                                       ; ROXR.L #$1,d6
	bcs.b    Loc_LoadFile_ProcessDebugBlock               ; Load file process debug block if carry set (less than / lower)
Func_ReallocatePayloadBuffer:
	dbra     d1,Loop_LoadFile_BlockData                   ; Decrement d1 and loop to Loop_LoadFile_BlockData until done
	rts                                                   ; Return to caller
Loc_LoadFile_ProcessDebugBlock:
	move.l   d6,(a2)+                                     ; Store d6 at address in a2
	moveq    #$1,d6                                       ; Set d6 to 1 ($1)
	ror.l    #$1,d6                                       ; ROR.L #$1,d6
	lea      Func_ReallocatePayloadBuffer(pc),a5          ; Point a5 at reallocate payload buffer
	lea      Var_MenuSubID_Selected(pc),a4                ; Point a4 at current menu sub-item preference ID
	addq.b   #$1,(a4)                                     ; Add #$1 to (a4)
	bmi.w    Loop_LoadFile_CodeBlocks                     ; Load file code blocks if minus (negative sign bit set)
	bra.b    Func_ReallocatePayloadBuffer                 ; Jump to Func_ReallocatePayloadBuffer — reallocate payload buffer
Loop_LoadFile_BlockBSS:
	moveq    #$3,d2                                       ; Set d2 to 3 ($3)
	moveq    #$2,d1                                       ; Set priority/parameter to 2 in d1
	bsr.b    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	bra.b    Loc_LoadFile_BlockLoopReloc                  ; Jump to Loc_LoadFile_BlockLoopReloc — load file block loop reloc
Loop_LoadFile_BlockReloc:
	cmp.w    #$81,d2                                      ; Check if d2 equals $81 (129)
	bls.b    Loop_LoadFile_BlockCode                      ; Load file block code if unsigned lower or same — checked #$81,d2
	subi.w   #$82,d2                                      ; Subtract 130 ($82) from d2
	ori.w    #$100,d2                                     ; ORI.W #$100,d2
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	bsr.b    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
Loc_LoadFile_ProcessEndBlock:
	cmp.w    #$8,d3                                       ; Check if d3 equals $8 (8)
	bcs.b    Loc_LoadFile_BlockLoopCode                   ; Load file block loop code if carry set (less than / lower) — checked #$8,d3
	cmp.w    #$b,d3                                       ; Check if d3 equals $b (11)
	bcs.b    Loc_LoadFile_BlockLoopData                   ; Load file block loop data if carry set (less than / lower) — checked #$b,d3
	moveq    #$f,d1                                       ; Set d1 to 15 ($f)
	move.l   d3,d2                                        ; Copy d3 to d2
	subi.w   #$b,d2                                       ; Subtract 11 ($b) from d2
	ori.w    #$7f00,d2                                    ; ORI.W #$7f00,d2
Loop_LoadFile_BlockSymbol:
	bsr.b    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
Loop_LoadFile_BlockDebug:
	moveq    #$0,d4                                       ; Clear value 0 to zero
	moveq    #$0,d7                                       ; Clear value 0 to zero
	adda.l   d3,a0                                        ; Add d3 to a0
	bra.w    Loop_LoadFile_AllocLoop                      ; Jump to Loop_LoadFile_AllocLoop — load file alloc loop
Loc_LoadFile_BlockLoopCode:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$5,d2                                       ; Subtract 5 ($5) from d2
	ori.w    #$1c,d2                                      ; ORI.W #$1c,d2
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
	bra.b    Loop_LoadFile_BlockSymbol                    ; Jump to Loop_LoadFile_BlockSymbol — load file block symbol
Loc_LoadFile_BlockLoopData:
	move.l   d3,d2                                        ; Copy d3 to d2
	subq.w   #$8,d2                                       ; Subtract 8 ($8) from d2
	ori.w    #$7c,d2                                      ; ORI.W #$7c,d2
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.b    Loop_LoadFile_BlockSymbol                    ; Jump to Loop_LoadFile_BlockSymbol — load file block symbol
Loc_LoadFile_BlockLoopBSS:
	tst.b    $3d00.l                                      ; Test register/value $3d00.l for zero or negative condition status
	bne.b    Loop_LoadFile_BlockBSS                       ; Load file block bss if non-zero/not equal — checked $3d00.l
	st.b     $3d00.l                                      ; Set $3d00.l to $FF (true)
	bsr.w    Func_VerifyDestinationBuffer                 ; Call Func_VerifyDestinationBuffer — verify destination buffer
Loc_LoadFile_BlockLoopReloc:
	move.l   d4,d3                                        ; Copy d4 to d3
	move.l   a6,d2                                        ; Copy a6 to d2
	cmp.w    #$3,d3                                       ; Check if d3 equals $3 (3)
	bcs.b    Loc_LoadFile_BlockFinalCheck                 ; Load file block final check if carry set (less than / lower) — checked #$3,d3
	beq.b    Loc_LoadFile_BlockLoopDebug                  ; Load file block loop debug if zero/equal
	cmp.w    #$4,d3                                       ; Check if d3 equals $4 (4)
	bhi.b    Loop_LoadFile_BlockReloc                     ; Load file block reloc if unsigned greater — checked #$4,d3
	cmp.w    #$81,d2                                      ; Check if d2 equals $81 (129)
	bhi.b    Loc_LoadFile_BlockLoopSymbol                 ; Load file block loop symbol if unsigned greater — checked #$81,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$100,d2                                     ; ORI.W #$100,d2
	moveq    #$a,d1                                       ; Set d1 to 10 ($a)
Loop_LoadFile_BlockEnd:
	bsr.w    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	bra.b    Loop_LoadFile_BlockDebug                     ; Jump to Loop_LoadFile_BlockDebug — load file block debug
Loc_LoadFile_BlockLoopSymbol:
	subi.w   #$82,d2                                      ; Subtract 130 ($82) from d2
	ori.w    #$600,d2                                     ; ORI.W #$600,d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
	bra.b    Loop_LoadFile_BlockEnd                       ; Jump to Loop_LoadFile_BlockEnd — load file block end
Loc_LoadFile_BlockLoopDebug:
	cmp.w    #$81,d2                                      ; Check if d2 equals $81 (129)
	bhi.b    Loc_LoadFile_BlockLoopEnd                    ; Load file block loop end if unsigned greater — checked #$81,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	ori.w    #$200,d2                                     ; ORI.W #$200,d2
	moveq    #$a,d1                                       ; Set d1 to 10 ($a)
Loop_LoadFile_BlockVerify:
	bsr.w    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	bra.w    Loop_LoadFile_BlockDebug                     ; Jump to Loop_LoadFile_BlockDebug — load file block debug
Loc_LoadFile_BlockLoopEnd:
	subi.w   #$82,d2                                      ; Subtract 130 ($82) from d2
	ori.w    #$500,d2                                     ; ORI.W #$500,d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
	bra.b    Loop_LoadFile_BlockVerify                    ; Jump to Loop_LoadFile_BlockVerify — load file block verify
Loc_LoadFile_BlockFinalCheck:
	cmp.w    #$81,d2                                      ; Check if d2 equals $81 (129)
	bhi.b    Loc_LoadFile_BlockVerified                   ; Load file block verified if unsigned greater — checked #$81,d2
	subq.w   #$2,d2                                       ; Subtract 2 ($2) from d2
	moveq    #$a,d1                                       ; Set d1 to 10 ($a)
Loop_LoadFile_BlockVerifiedLoop:
	bsr.w    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	bra.w    Loop_LoadFile_BlockDebug                     ; Jump to Loop_LoadFile_BlockDebug — load file block debug
Loc_LoadFile_BlockVerified:
	subi.w   #$82,d2                                      ; Subtract 130 ($82) from d2
	ori.w    #$100,d2                                     ; ORI.W #$100,d2
	moveq    #$b,d1                                       ; Set d1 to 11 ($b)
	bra.b    Loop_LoadFile_BlockVerifiedLoop              ; Jump to Loop_LoadFile_BlockVerifiedLoop — load file block verified loop
Loop_LoadFile_BlockDoneLoop:
	moveq    #$3,d1                                       ; Set priority/parameter to 3 in d1
	subq.w   #$1,d7                                       ; Decrement d7 by one
	move.l   d7,d2                                        ; Copy d7 to d2
	bra.w    Func_ReallocatePayloadBuffer                 ; Jump to Func_ReallocatePayloadBuffer — reallocate payload buffer
Loop_LoadFile_BlockCleanup:
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	subq.w   #$7,d7                                       ; Subtract 7 ($7) from d7
	move.l   d7,d2                                        ; Copy d7 to d2
	ori.w    #$1b0,d2                                     ; ORI.W #$1b0,d2
	bra.w    Func_ReallocatePayloadBuffer                 ; Jump to Func_ReallocatePayloadBuffer — reallocate payload buffer
Loop_LoadFile_BlockFinal:
	moveq    #$a,d1                                       ; Set d1 to 10 ($a)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	moveq    #$6e,d2                                      ; Set d2 to 110 ($6e)
	bra.w    Func_ReallocatePayloadBuffer                 ; Jump to Func_ReallocatePayloadBuffer — reallocate payload buffer
Func_VerifyDestinationBuffer:
	tst.w    d7                                           ; Test d7 for zero
	beq.b    Loc_LoadFile_SuccessDone                     ; Load file success done if zero/equal — checked d7
	cmp.w    #$7,d7                                       ; Check if d7 equals $7 (7)
	bcs.b    Loop_LoadFile_BlockDoneLoop                  ; Load file block done loop if carry set (less than / lower) — checked #$7,d7
	cmp.w    #$e,d7                                       ; Check if d7 equals $e (14)
	bcs.b    Loop_LoadFile_BlockCleanup                   ; Load file block cleanup if carry set (less than / lower) — checked #$e,d7
	cmp.w    #$400,d7                                     ; Check if d7 equals $400 (1024)
	bcs.b    Loop_LoadFile_BlockFinal                     ; Load file block final if carry set (less than / lower) — checked #$400,d7
	moveq    #$10,d1                                      ; Set d1 to 16 ($10)
	move.l   d7,d2                                        ; Copy d7 to d2
	bsr.w    Func_ReallocatePayloadBuffer                 ; Call Func_ReallocatePayloadBuffer — reallocate payload buffer
	moveq    #$6f,d2                                      ; Set d2 to 111 ($6f)
	moveq    #$7,d1                                       ; Set d1 to 7 ($7)
	bra.w    Func_ReallocatePayloadBuffer                 ; Jump to Func_ReallocatePayloadBuffer — reallocate payload buffer
Loc_LoadFile_SuccessDone:
	rts                                                   ; Return to caller
Func_BuildAndSortDirectory:
	bsr.w    Func_InitializeFloppyGeometry                ; Call Func_InitializeFloppyGeometry — initialize floppy geometry
	bsr.w    Func_ReadFloppyDirectory                     ; Call Func_ReadFloppyDirectory — read floppy directory
	bsr.w    Func_InitializeDirectoryDisplay              ; Call Func_InitializeDirectoryDisplay — initialize directory display
	move.l   #$11ffee,d0                                  ; Set d0 to 1179630 ($11ffee)
	move.l   Var_DirectoryEntryCount(pc),d1               ; Load directory entry count into d1
	divu.w   d1,d0                                        ; Divide d1,d0
	lea      Var_DialogListTitle3(pc),a0                  ; Point a0 at dialog list title3
	move.w   d0,(a0)                                      ; Save result of Func_InitializeDirectoryDisplay as dialoglisttitle3
	lea      Var_DialogListTitle2(pc),a0                  ; Point a0 at dialog list title2
	clr.w    (a0)                                         ; Zero Var_DialogListTitle2
	lea      Var_DialogListTitle(pc),a0                   ; Point a0 at dialog list title
	bra.w    Func_DrawDirectoryList                       ; Jump to Func_DrawDirectoryList — draw directory list
Func_RenderDialogText:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	lea      Var_DialogIText9(pc),a0                      ; Point a0 at dialog itext9
	movea.l  Var_Window_Work(pc),a1                       ; Load dialog window into a1
	suba.l   a2,a2                                        ; Clear a2 to zero (self-subtract)
	jmp      _LVOFreeSysRequest(a6)                       ; Free the dialog requester window
Loop_LoadFile_BlockExit:
	bsr.w    Func_RenderDialogText                        ; Call Func_RenderDialogText — render dialog text
	bsr.w    Func_GetDialogMsg                            ; Call Func_GetDialogMsg — get dialog msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$8000,d0                                    ; Compare return value from Func_GetDialogMsg against $8000 (32768)
	beq.w    Loc_BuildDir_SwapEntries                     ; Build dir swap entries if zero/equal — d0 vs $8000 — checked #$8000,d0
	cmp.l    #$10000,d0                                   ; Load MEMF_CHIP allocation flag
	beq.w    Loc_BuildDir_SwapEntries                     ; Build dir swap entries if zero/equal — d0 vs $10000 — checked #$10000,d0
	cmp.w    #$200,d0                                     ; Check if d0 equals $200 (512)
	beq.w    Loop_SetStatusError                          ; Set status error if zero/equal — d0 vs $200 — checked #$200,d0
	cmp.w    #$20,d0                                      ; Check if d0 equals $20 (32)
	beq.w    Loc_LoadFile_HeaderEndOfTable                ; Load file header end of table if zero/equal — d0 vs $20 — checked #$20,d0
	cmp.w    #$40,d0                                      ; Check if d0 equals $40 (64)
	beq.w    Loc_LoadFile_HeaderLoop                      ; Load file header loop if zero/equal — d0 vs $40 — checked #$40,d0
	bra.b    Loop_LoadFile_BlockExit                      ; Jump to Loop_LoadFile_BlockExit — load file block exit
Loop_LoadFile_HeaderAlloc:
	rts                                                   ; Return to caller
Loop_LoadFile_HeaderLoop:
	bsr.w    Func_WaitAndGetDialogMsg                     ; Call Func_WaitAndGetDialogMsg — wait and get dialog msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	move.l   im_Class(a0),d0                                   ; Load IntuiMessage im_Class field (IDCMP message class)
	cmp.w    #$40,d0                                      ; Compare return value from Func_WaitAndGetDialogMsg against $40 (64)
	beq.w    Loc_LoadFile_HeaderLoop                      ; Load file header loop if zero/equal — d0 vs $40 — checked #$40,d0
	cmp.w    #$8,d0                                       ; Compare return value from Func_WaitAndGetDialogMsg against $8 (8)
	beq.w    Loop_LoadFile_HeaderVerify                   ; Load file header verify if zero/equal — d0 vs $8 — checked #$8,d0
	lea      Var_FastMemBypassFlag(pc),a0                 ; Point a0 at fast mem bypass flag
	cmpi.b   #$ff,(a0)                                    ; Compare #$ff with (a0)
	beq.w    Loc_LoadFile_SegLoopDebug                    ; Load file seg loop debug if zero/equal — checked #$ff,(a0)
	lea      Var_RleFilterToggleFlag(pc),a0               ; Point a0 at rle filter toggle flag
	cmpi.b   #$ff,(a0)                                    ; Compare #$ff with (a0)
	beq.w    Loc_LoadFile_CheckSegBSS                     ; Load file check seg bss if zero/equal — checked #$ff,(a0)
	lea      Var_ProStubToggleFlag(pc),a0                 ; Point a0 at pro stub toggle flag
	cmpi.b   #$ff,(a0)                                    ; Compare #$ff with (a0)
	beq.w    Loc_LoadFile_SegLoopEnd                      ; Load file seg loop end if zero/equal — checked #$ff,(a0)
	lea      Var_StatusUpdateFlag(pc),a0                  ; Point a0 at status update flag
	cmpi.b   #$ff,(a0)                                    ; Compare #$ff with (a0)
	beq.w    Loc_LoadFile_CheckSegReloc                   ; Load file check seg reloc if zero/equal — checked #$ff,(a0)
	bra.b    Loop_LoadFile_HeaderLoop                     ; Jump to Loop_LoadFile_HeaderLoop — load file header loop
Func_WaitDialogPort:
	movea.l  Var_Window_Work(pc),a0                       ; Load dialog window into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	jmp      _LVOWaitPort(a6)                                    ; Wait for message to arrive on port (_LVOWaitPort)
Func_GetDialogMsg:
	bsr.b    Func_WaitDialogPort                          ; Call Func_WaitDialogPort — wait dialog port
Func_WaitAndGetDialogMsg:
	movea.l  $4.w,a6                                      ; Load ExecBase for following Exec library call
	movea.l  Var_Window_Work(pc),a0                       ; Load dialog window into a0
	movea.l  wd_UserPort(a0),a0                                   ; Read wd_UserPort (IDCMP message port) into a0
	jsr      _LVOGetMsg(a6)                               ; Retrieve startup message from MsgPort
	lea      Var_LastIntuiMessage(pc),a1                  ; Point a1 at last received IntuiMessage pointer
	move.l   d0,(a1)                                      ; Store d0 as last received IntuiMessage pointer
	movea.l  d0,a1                                        ; Save _LVOGetMsg result in a1
	beq.w    Loop_LoadFile_HeaderAlloc                    ; Load file header alloc if zero/equal
	jmp      _LVOReplyMsg(a6)                                    ; Reply to received message (_LVOReplyMsg)
Loc_LoadFile_HeaderLoop:
	movea.l  im_IAddress(a0),a1                                   ; Load IntuiMessage im_IAddress field (sender object pointer)
	move.l   $26(a1),d0                                   ; Read offset $26(a1) into d0
	beq.w    Loc_LoadFile_CheckSegSymbol                  ; Load file check seg symbol if zero/equal
	cmp.w    #$1,d0                                       ; Check if d0 equals $1 (1)
	beq.w    Loc_BuildDir_NextCompare                     ; Build dir next compare if zero/equal — d0 vs $1 — checked #$1,d0
	cmp.w    #$a,d0                                       ; Check if d0 equals $a (10)
	beq.b    Loc_LoadFile_HeaderCheckHunk                 ; Load file header check hunk if zero/equal — d0 vs $a — checked #$a,d0
	cmp.w    #$14,d0                                      ; Check if d0 equals $14 (20)
	bcc.w    Loc_LoadFile_HeaderFinalize                  ; Load file header finalize if carry clear (greater or equal) — checked #$14,d0
	cmp.w    #$6,d0                                       ; Check if d0 equals $6 (6)
	beq.b    Loc_LoadFile_HeaderCheckHunk                 ; Load file header check hunk if zero/equal — d0 vs $6 — checked #$6,d0
	cmp.w    #$8,d0                                       ; Check if d0 equals $8 (8)
	beq.b    Loop_SetStatusError                          ; Set status error if zero/equal — d0 vs $8 — checked #$8,d0
	cmp.w    #$9,d0                                       ; Check if d0 equals $9 (9)
	beq.b    Loop_LoadFile_HeaderDoneLoop                 ; Load file header done loop if zero/equal — d0 vs $9 — checked #$9,d0
	cmp.w    #$7,d0                                       ; Check if d0 equals $7 (7)
	beq.b    Loop_LoadFile_HeaderDoneLoop                 ; Load file header done loop if zero/equal — d0 vs $7 — checked #$7,d0
Loop_LoadFile_HeaderVerify:
	lea      Var_FastMemBypassFlag(pc),a0                 ; Point a0 at fast mem bypass flag
	clr.l    (a0)+                                        ; Zero Var_FastMemBypassFlag
	bra.w    Loop_LoadFile_BlockExit                      ; Jump to Loop_LoadFile_BlockExit — load file block exit
Loop_SetStatusError:
	lea      Var_StatusErrorFlag(pc),a3                   ; Point a3 at global error status flag
	st.b     (a3)                                         ; Set global status error flag byte to TRUE ($ff)
	rts                                                   ; Return to caller
Loc_LoadFile_HeaderCheckHunk:
	lea      Var_DialogSuffixString(pc),a0                ; Point a0 at dialog filename suffix string
	tst.b    (a0)                                         ; Check whether dialog filename suffix string is zero/null
	beq.b    Loop_SetStatusError                          ; Set status error if zero/equal — checked value at (a0)
Loop_ClearStatusError:
	lea      Var_StatusErrorFlag(pc),a3                   ; Point a3 at global error status flag
	sf.b     (a3)                                         ; Clear global status error flag byte to FALSE ($00)
	rts                                                   ; Return to caller
Loop_LoadFile_HeaderDoneLoop:
	bsr.w    Func_LockFloppyDirectory                     ; Call Func_LockFloppyDirectory — lock floppy directory
Func_DrawDialogLayout:
	bsr.w    Func_InitFloppyIOReq                         ; Call Func_InitFloppyIOReq — init floppy ioreq
	bsr.w    Func_ResetDirectoryIndex                     ; Call Func_ResetDirectoryIndex — reset directory index
	move.l   #$11ffee,d0                                  ; Set d0 to 1179630 ($11ffee)
	move.l   Var_CurrentFileIndex(pc),d1                  ; Load current file index into d1
	beq.b    Loc_LoadFile_HeaderNext                      ; Load file header next if zero/equal
	divu.w   d1,d0                                        ; Divide d1,d0
	bvs.b    Loc_LoadFile_HeaderNext                      ; BVS.B Loc_LoadFile_HeaderNext
Loop_LoadFile_HeaderFinal:
	lea      Var_DialogListTitle7(pc),a0                  ; Point a0 at dialog list title7
	move.w   d0,(a0)                                      ; Save d0 as dialoglisttitle7
	lea      Var_DialogListTitle6(pc),a0                  ; Point a0 at dialog list title6
	clr.w    (a0)                                         ; Zero Var_DialogListTitle6
	lea      Var_DialogListTitle5(pc),a0                  ; Point a0 at dialog list title5
	bsr.w    Func_DrawDirectoryList                       ; Call Func_DrawDirectoryList — draw directory list
	bra.w    Loop_LoadFile_BlockExit                      ; Jump to Loop_LoadFile_BlockExit — load file block exit
Loc_LoadFile_HeaderNext:
	moveq    #-1,d0                                       ; Load error / exit code -1 ($ff) into register d0
	bra.b    Loop_LoadFile_HeaderFinal                    ; Jump to Loop_LoadFile_HeaderFinal — load file header final
Loc_LoadFile_HeaderEndOfTable:
	movea.l  im_IAddress(a0),a1                                   ; Load IntuiMessage im_IAddress field (sender object pointer)
	move.l   $26(a1),d0                                   ; Read offset $26(a1) into d0
	cmp.w    #$2,d0                                       ; Check if d0 equals $2 (2)
	beq.w    Loc_LoadFile_CheckSegBSS                     ; Load file check seg bss if zero/equal — d0 vs $2 — checked #$2,d0
	cmp.w    #$4,d0                                       ; Check if d0 equals $4 (4)
	beq.w    Loc_LoadFile_SegLoopDebug                    ; Load file seg loop debug if zero/equal — d0 vs $4 — checked #$4,d0
	cmp.w    #$3,d0                                       ; Check if d0 equals $3 (3)
	beq.w    Loc_LoadFile_CheckSegReloc                   ; Load file check seg reloc if zero/equal — d0 vs $3 — checked #$3,d0
	cmp.w    #$5,d0                                       ; Check if d0 equals $5 (5)
	beq.w    Loc_LoadFile_SegLoopEnd                      ; Load file seg loop end if zero/equal — d0 vs $5 — checked #$5,d0
	cmp.w    #$b,d0                                       ; Check if d0 equals $b (11)
	beq.w    Loop_LoadFile_SegLoop                        ; Load file seg loop if zero/equal — d0 vs $b — checked #$b,d0
	cmp.w    #$c,d0                                       ; Check if d0 equals $c (12)
	beq.w    Loop_LoadFile_SegDataBlocks                  ; Load file seg data blocks if zero/equal — d0 vs $c — checked #$c,d0
	bra.w    Loop_LoadFile_BlockExit                      ; Jump to Loop_LoadFile_BlockExit — load file block exit
Loc_LoadFile_HeaderFinalize:
	cmp.w    #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	bcs.b    Loc_LoadFile_HeaderCleanup                   ; Load file header cleanup if carry set (less than / lower) — checked #$28,d0
	subi.w   #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	mulu.w   #$24,d0                                      ; Multiply d0 by 36 ($24)
	movea.l  Var_FileListBufferSize(pc),a0                ; Load file list buffer size into a0
	addq.l   #$1,a0                                       ; Increment a0 by one
	adda.l   d0,a0                                        ; Add d0 to a0
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
Loop_LoadFile_HeaderExit:
	move.b   (a0)+,(a1)+                                  ; Copy next byte from source to destination
	bne.w    Loop_LoadFile_HeaderExit                     ; Load file header exit if non-zero/not equal
	lea      Var_DialogListTitle4(pc),a0                  ; Point a0 at dialog list title4
	bsr.w    Func_DrawDirectoryList                       ; Call Func_DrawDirectoryList — draw directory list
	bra.w    Loop_LoadFile_HeaderDoneLoop                 ; Jump to Loop_LoadFile_HeaderDoneLoop — load file header done loop
Loop_LoadFile_HeaderClose:
	addq.l   #$1,a0                                       ; Increment a0 by one
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
	lea      $94(a1),a2                                   ; Get address at offset $94 from a1
Loop_LoadFile_HeaderFree:
	move.b   (a1)+,d0                                     ; Load (a1)+ into d0
	bne.b    Loop_LoadFile_HeaderFree                     ; Load file header free if non-zero/not equal
	subq.l   #$1,a1                                       ; Decrement a1 by one
Loop_LoadFile_HeaderQuit:
	cmpa.l   a2,a1                                        ; Compare a2 with a1
	beq.w    Loc_LoadFile_HeaderDone                      ; Load file header done if zero/equal — checked a2,a1
	move.b   (a0)+,(a1)+                                  ; Copy next byte from source to destination
	bne.b    Loop_LoadFile_HeaderQuit                     ; Load file header quit if non-zero/not equal
	subq.l   #$1,a1                                       ; Decrement a1 by one
Loc_LoadFile_HeaderDone:
	move.b   #$2f,(a1)+                                   ; Write byte $2f to (a1)
	clr.b    (a1)                                         ; Clear memory at (a1)
	lea      Var_DialogListTitle4(pc),a0                  ; Point a0 at dialog list title4
	bsr.w    Func_DrawDirectoryList                       ; Call Func_DrawDirectoryList — draw directory list
	bra.w    Loop_LoadFile_HeaderDoneLoop                 ; Jump to Loop_LoadFile_HeaderDoneLoop — load file header done loop
Func_CloseDialogRequester:
	movem.l  d0-d7/a0-a6,-(a7)                            ; Save working registers to stack
	lea      Var_DiskState(pc),a0                         ; Point a0 at disk state
	lea      Var_DiskDriveType(pc),a1                     ; Point a1 at disk drive type
	lea      Var_FloppySectorsPerTrack(pc),a2             ; Point a2 at floppy sectors per track
	lea      Var_FloppyTrackIndex(pc),a3                  ; Point a3 at floppy track index
	move.l   (a0),(a2)                                    ; Copy (a0) to (a2)
	move.l   (a1),(a3)                                    ; Copy (a1) to (a3)
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	jsr      _LVOCurrentTime(a6)                          ; Query the current system timestamp
	movem.l  (a7)+,d0-d7/a0-a6                            ; Restore registers from stack
	rts                                                   ; Return to caller
Loc_LoadFile_HeaderCleanup:
	subi.l   #$14,d0                                      ; Subtract 20 ($14) from d0
	lea      Var_DirectoryBufferPointer(pc),a0            ; Point a0 at directory buffer pointer
	lea      Var_DirectoryBufferSize(pc),a1               ; Point a1 at directory buffer size
	move.l   (a1),(a0)                                    ; Copy (a1) to (a0)
	move.l   d0,(a1)                                      ; Save d0 as directorybuffersize
	bsr.w    Func_CloseDialogRequester                    ; Call Func_CloseDialogRequester — close dialog requester
	mulu.w   #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	movea.l  Var_FileListBufferPointer(pc),a0             ; Load file list display buffer into a0
	adda.l   d0,a0                                        ; Add d0 to a0
	cmpi.b   #$3,(a0)                                     ; Compare #$3 with (a0)
	beq.b    Loop_LoadFile_HeaderClose                    ; Load file header close if zero/equal — checked #$3,(a0)
	addq.l   #$1,a0                                       ; Increment a0 by one
	lea      Var_DialogSuffixString(pc),a1                ; Point a1 at dialog filename suffix string
	moveq    #$1e,d0                                      ; Set d0 to 30 ($1e)
Loop_LoadFile_SegListLoop:
	move.b   (a0)+,(a1)+                                  ; Copy next byte from source to destination
	dbra     d0,Loop_LoadFile_SegListLoop                 ; Decrement d0 and loop to Loop_LoadFile_SegListLoop until done
	lea      Var_DialogIText9(pc),a0                      ; Point a0 at dialog itext9
	bsr.w    Func_DrawDirectoryList                       ; Call Func_DrawDirectoryList — draw directory list
	move.l   Var_FloppySectorsPerTrack(pc),d0             ; Load floppy sectors per track into d0
	move.l   Var_FloppyTrackIndex(pc),d1                  ; Load floppy track index into d1
	move.l   Var_DiskState(pc),d2                         ; Load disk state into d2
	move.l   Var_DiskDriveType(pc),d3                     ; Load disk drive type into d3
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	jsr      _LVODoubleClick(a6)                          ; Check if duration since last action is within double-click limit
	tst.b    d0                                           ; Check if function return value is zero
	beq.w    Loop_LoadFile_BlockExit                      ; Load file block exit if zero/equal — checked d0
	lea      Var_DirectoryBufferPointer(pc),a0            ; Point a0 at directory buffer pointer
	lea      Var_DirectoryBufferSize(pc),a1               ; Point a1 at directory buffer size
	cmpm.l   (a0)+,(a1)+                                  ; Compare (a0)+ with (a1)+
	bne.w    Loop_LoadFile_BlockExit                      ; Load file block exit if non-zero/not equal — checked (a0)+,(a1)+
	bra.w    Loop_ClearStatusError                        ; Jump to Loop_ClearStatusError — clear status error
Func_FormatProgressValue:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	movea.l  Var_Window_Work(pc),a0                       ; Load dialog window into a0
	movea.l  $32(a0),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOSetAPen(a6)                                    ; Call RectFill() — fill rectangle
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_DrawDirectoryList:
	movea.l  Var_IntuitionBase(pc),a6                     ; Load intuition.library base into a6
	movea.l  Var_Window_Work(pc),a1                       ; Load dialog window into a1
	suba.l   a2,a2                                        ; Clear a2 to zero (self-subtract)
	jmp      _LVORefreshGadgets(a6)                       ; Refresh the gadgets in the window
Loop_LoadFile_SegLoop:
	move.w   Var_DialogListTitle6(pc),d0                  ; Load dialog list title6 into d0
	move.l   Var_CurrentFileIndex(pc),d1                  ; Load current file index into d1
	subi.l   #$12,d1                                      ; Subtract 18 ($12) from d1
	bmi.w    Loc_LoadFile_SegLoopCode                     ; Load file seg loop code if minus (negative sign bit set) — checked counter after subi.l
	beq.w    Loc_LoadFile_SegLoopCode                     ; Load file seg loop code if zero/equal
	mulu.w   d1,d0                                        ; Multiply d1,d0
	divu.w   #$ffff,d0                                    ; Divide d0 by 65535 ($ffff)
	move.l   Var_FileListBufferPointer(pc),d1             ; Load file list display buffer into d1
	movea.l  Var_ScreenChunkyBuffer(pc),a0                ; Load screen chunky pixel buffer into a0
	lea      $28(a0),a0                                   ; Get address at offset $28 from a0
	sub.l    a0,d1                                        ; Subtract a0 from d1
	divu.w   #$28,d1                                      ; Load chunky buffer row allocation size ($28 bytes)
	sub.w    d1,d0                                        ; Subtract d1 from d0
	bmi.b    Loc_LoadFile_ProcessSegments                 ; Load file process segments if minus (negative sign bit set)
	beq.w    Loc_LoadFile_SegLoopCode                     ; Load file seg loop code if zero/equal
	move.l   d0,d2                                        ; Copy return value to d2
	movea.l  Var_FileListBufferPointer(pc),a0             ; Load file list display buffer into a0
	lea      Var_FileListBufferPointer(pc),a1             ; Point a1 at file list display buffer
	mulu.w   #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	adda.l   d0,a0                                        ; Add d0 to a0
	move.l   a0,(a1)                                      ; Store a0 as file list display buffer
	cmp.w    #$12,d2                                      ; Check if d2 equals $12 (18)
	bcc.w    Loc_LoadFile_SegLoopData                     ; Load file seg loop data if carry clear (greater or equal) — checked #$12,d2
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	mulu.w   d2,d1                                        ; Multiply d2,d1
	bsr.w    Func_GetListSelectedItem                     ; Call Func_GetListSelectedItem — get list selected item
	move.w   #$ca,d1                                      ; Set d1 to 202 ($ca)
	lea      $2d0(a0),a0                                  ; Get address at offset $2d0 from a0
Loop_LoadFile_SegHunk:
	moveq    #$d,d0                                       ; Set d0 to 13 ($d)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	lea      -$28(a0),a0                                  ; Point a0 at -$28(a0)
	moveq    #$25,d0                                      ; Set d0 to 37 ($25)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	subi.w   #$9,d1                                       ; Subtract 9 ($9) from d1
	subq.w   #$1,d2                                       ; Decrement d2 by one
	bne.b    Loop_LoadFile_SegHunk                        ; Load file seg hunk if non-zero/not equal — checked counter after subq.w
	bra.b    Loop_LoadFile_SegLoop                        ; Jump to Loop_LoadFile_SegLoop — load file seg loop
Loc_LoadFile_ProcessSegments:
	neg.w    d0                                           ; Negate d0
	move.w   d0,d2                                        ; Copy return value to d2
	movea.l  Var_FileListBufferPointer(pc),a0             ; Load file list display buffer into a0
	lea      Var_FileListBufferPointer(pc),a1             ; Point a1 at file list display buffer
	mulu.w   #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	suba.l   d0,a0                                        ; Subtract d0 from a0
	move.l   a0,(a1)                                      ; Store a0 as file list display buffer
	cmp.w    #$12,d2                                      ; Check if d2 equals $12 (18)
	bcc.b    Loc_LoadFile_SegLoopData                     ; Load file seg loop data if carry clear (greater or equal) — checked #$12,d2
	moveq    #-9,d1                                       ; Quick load constant value #$f7 into register d1
	muls.w   d2,d1                                        ; Multiply d2,d1
	bsr.w    Func_GetListSelectedItem                     ; Call Func_GetListSelectedItem — get list selected item
	move.l   #$31,d1                                      ; Set d1 to 49 ($31)
	lea      -$28(a0),a0                                  ; Point a0 at -$28(a0)
Loop_LoadFile_SegCodeBlocks:
	moveq    #$d,d0                                       ; Set d0 to 13 ($d)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	lea      $28(a0),a0                                   ; Get address at offset $28 from a0
	moveq    #$25,d0                                      ; Set d0 to 37 ($25)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	addi.w   #$9,d1                                       ; Add 9 ($9) to d1
	subq.w   #$1,d2                                       ; Decrement d2 by one
	bne.b    Loop_LoadFile_SegCodeBlocks                  ; Load file seg code blocks if non-zero/not equal — checked counter after subq.w
	bra.w    Loop_LoadFile_SegLoop                        ; Jump to Loop_LoadFile_SegLoop — load file seg loop
Loc_LoadFile_SegLoopCode:
	bsr.w    Func_WaitAndGetDialogMsg                     ; Call Func_WaitAndGetDialogMsg — wait and get dialog msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	lea      im_Class(a0),a1                                   ; Get address at offset $14 from a0
	cmpi.l   #$40,(a1)                                    ; Compare #$40 with (a1)
	bne.w    Loop_LoadFile_SegLoop                        ; Load file seg loop if non-zero/not equal — checked #$40,(a1)
	bra.w    Loop_LoadFile_BlockExit                      ; Jump to Loop_LoadFile_BlockExit — load file block exit
Loc_LoadFile_SegLoopData:
	bsr.w    Func_DoFloppyIOReq                           ; Call Func_DoFloppyIOReq — do floppy ioreq
	bra.w    Loop_LoadFile_SegLoop                        ; Jump to Loop_LoadFile_SegLoop — load file seg loop
Loop_LoadFile_SegDataBlocks:
	move.w   Var_DialogListTitle2(pc),d0                  ; Load dialog list title2 into d0
	move.l   Var_DirectoryEntryCount(pc),d1               ; Load directory entry count into d1
	subi.l   #$12,d1                                      ; Subtract 18 ($12) from d1
	bmi.w    Loc_LoadFile_SegLoopReloc                    ; Load file seg loop reloc if minus (negative sign bit set) — checked counter after subi.l
	beq.w    Loc_LoadFile_SegLoopReloc                    ; Load file seg loop reloc if zero/equal
	mulu.w   d1,d0                                        ; Multiply d1,d0
	divu.w   #$ffff,d0                                    ; Divide d0 by 65535 ($ffff)
	move.l   Var_FileListBufferSize(pc),d1                ; Load file list buffer size into d1
	movea.l  Var_ViewportBuffer(pc),a0                    ; Load ViewPort display buffer into a0
	sub.l    a0,d1                                        ; Subtract a0 from d1
	divu.w   #$24,d1                                      ; Divide d1 by 36 ($24)
	sub.w    d1,d0                                        ; Subtract d1 from d0
	bmi.b    Loc_LoadFile_SegLoopBSS                      ; Load file seg loop bss if minus (negative sign bit set)
	beq.w    Loc_LoadFile_SegLoopReloc                    ; Load file seg loop reloc if zero/equal
	move.l   d0,d2                                        ; Copy return value to d2
	movea.l  Var_FileListBufferSize(pc),a0                ; Load file list buffer size into a0
	lea      Var_FileListBufferSize(pc),a1                ; Point a1 at file list buffer size
	mulu.w   #$24,d0                                      ; Multiply d0 by 36 ($24)
	adda.l   d0,a0                                        ; Add d0 to a0
	move.l   a0,(a1)                                      ; Save filelistbuffersize as filelistbuffersize
	cmp.w    #$12,d2                                      ; Check if d2 equals $12 (18)
	bcc.w    Loc_LoadFile_SegLoopSymbol                   ; Load file seg loop symbol if carry clear (greater or equal) — checked #$12,d2
	moveq    #$9,d1                                       ; Set d1 to 9 ($9)
	mulu.w   d2,d1                                        ; Multiply d2,d1
	bsr.w    Func_UpdateDirectorySelection                ; Call Func_UpdateDirectorySelection — update directory selection
	move.w   #$ca,d1                                      ; Set d1 to 202 ($ca)
	lea      $288(a0),a0                                  ; Get address at offset $288 from a0
Loop_LoadFile_SegBSSBlocks:
	move.w   #$14a,d0                                     ; Set d0 to 330 ($14a)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	lea      -$24(a0),a0                                  ; Point a0 at -$24(a0)
	moveq    #$c,d0                                       ; Set d0 to 12 ($c)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	subi.w   #$9,d1                                       ; Subtract 9 ($9) from d1
	subq.w   #$1,d2                                       ; Decrement d2 by one
	bne.b    Loop_LoadFile_SegBSSBlocks                   ; Load file seg bssblocks if non-zero/not equal — checked counter after subq.w
	bra.b    Loop_LoadFile_SegDataBlocks                  ; Jump to Loop_LoadFile_SegDataBlocks — load file seg data blocks
Loc_LoadFile_SegLoopBSS:
	neg.w    d0                                           ; Negate d0
	move.w   d0,d2                                        ; Copy return value to d2
	movea.l  Var_FileListBufferSize(pc),a0                ; Load file list buffer size into a0
	lea      Var_FileListBufferSize(pc),a1                ; Point a1 at file list buffer size
	mulu.w   #$24,d0                                      ; Multiply d0 by 36 ($24)
	suba.l   d0,a0                                        ; Subtract d0 from a0
	move.l   a0,(a1)                                      ; Save filelistbuffersize as filelistbuffersize
	cmp.w    #$12,d2                                      ; Check if d2 equals $12 (18)
	bcc.b    Loc_LoadFile_SegLoopSymbol                   ; Load file seg loop symbol if carry clear (greater or equal) — checked #$12,d2
	moveq    #-9,d1                                       ; Quick load constant value #$f7 into register d1
	muls.w   d2,d1                                        ; Multiply d2,d1
	bsr.w    Func_UpdateDirectorySelection                ; Call Func_UpdateDirectorySelection — update directory selection
	move.l   #$31,d1                                      ; Set d1 to 49 ($31)
	lea      -$24(a0),a0                                  ; Point a0 at -$24(a0)
Loop_LoadFile_SegRelocBlocks:
	move.w   #$14a,d0                                     ; Set d0 to 330 ($14a)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	lea      $24(a0),a0                                   ; Get address at offset $24 from a0
	moveq    #$c,d0                                       ; Set d0 to 12 ($c)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	addi.w   #$9,d1                                       ; Add 9 ($9) to d1
	subq.w   #$1,d2                                       ; Decrement d2 by one
	bne.b    Loop_LoadFile_SegRelocBlocks                 ; Load file seg reloc blocks if non-zero/not equal — checked counter after subq.w
	bra.w    Loop_LoadFile_SegDataBlocks                  ; Jump to Loop_LoadFile_SegDataBlocks — load file seg data blocks
Loc_LoadFile_SegLoopReloc:
	bsr.w    Func_WaitAndGetDialogMsg                     ; Call Func_WaitAndGetDialogMsg — wait and get dialog msg
	movea.l  Var_LastIntuiMessage(pc),a0                  ; Load last received IntuiMessage pointer into a0
	lea      im_Class(a0),a1                                   ; Get address at offset $14 from a0
	cmpi.l   #$40,(a1)                                    ; Compare #$40 with (a1)
	bne.w    Loop_LoadFile_SegDataBlocks                  ; Load file seg data blocks if non-zero/not equal — checked #$40,(a1)
	bra.w    Loop_LoadFile_BlockExit                      ; Jump to Loop_LoadFile_BlockExit — load file block exit
Loc_LoadFile_SegLoopSymbol:
	bsr.w    Func_InitializeDirectoryDisplay              ; Call Func_InitializeDirectoryDisplay — initialize directory display
	bra.w    Loop_LoadFile_SegDataBlocks                  ; Jump to Loop_LoadFile_SegDataBlocks — load file seg data blocks
Loc_LoadFile_SegLoopDebug:
	movea.l  Var_FileListBufferPointer(pc),a0             ; Load file list display buffer into a0
	move.l   Var_CurrentFileIndex(pc),d0                  ; Load current file index into d0
	mulu.w   #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	movea.l  Var_ScreenChunkyBuffer(pc),a1                ; Load screen chunky pixel buffer into a1
	lea      $28(a1),a1                                   ; Get address at offset $28 from a1
	add.l    a1,d0                                        ; Add a1 to d0
	lea      $2d0(a0),a0                                  ; Get address at offset $2d0 from a0
	cmpa.l   d0,a0                                        ; Compare d0 with a0
	bcc.w    Loop_LoadFile_HeaderVerify                   ; Load file header verify if carry clear (greater or equal) — checked d0,a0
	lea      Var_FileListBufferPointer(pc),a2             ; Point a2 at file list display buffer
	lea      -$2a8(a0),a0                                 ; Point a0 at -$2a8(a0)
	move.l   a0,(a2)                                      ; Store a0 as file list display buffer
	bsr.w    Func_ScrollDirectoryList                     ; Call Func_ScrollDirectoryList — scroll directory list
	moveq    #$8,d0                                       ; Set d0 to 8 ($8)
Loop_LoadFile_SegSymbolBlocks:
	moveq    #$1,d1                                       ; Set priority/parameter to 1 in d1
	bsr.b    Func_GetListSelectedItem                     ; Call Func_GetListSelectedItem — get list selected item
	dbra     d0,Loop_LoadFile_SegSymbolBlocks             ; Decrement d0 and loop to Loop_LoadFile_SegSymbolBlocks until done
	moveq    #$d,d0                                       ; Set d0 to 13 ($d)
	move.w   #$ca,d1                                      ; Set d1 to 202 ($ca)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	movea.l  Var_FileListBufferPointer(pc),a0             ; Load file list display buffer into a0
	lea      $2a8(a0),a0                                  ; Get address at offset $2a8 from a0
	moveq    #$25,d0                                      ; Set d0 to 37 ($25)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	lea      Var_FastMemBypassFlag(pc),a0                 ; Point a0 at fast mem bypass flag
	st.b     (a0)                                         ; Set Var_FastMemBypassFlag to $FF (true)
	bra.w    Loop_LoadFile_HeaderLoop                     ; Jump to Loop_LoadFile_HeaderLoop — load file header loop
Loc_LoadFile_SegLoopEnd:
	movea.l  Var_FileListBufferSize(pc),a0                ; Load file list buffer size into a0
	move.l   Var_DirectoryEntryCount(pc),d0               ; Load directory entry count into d0
	mulu.w   #$24,d0                                      ; Multiply d0 by 36 ($24)
	movea.l  Var_ViewportBuffer(pc),a1                    ; Load ViewPort display buffer into a1
	add.l    a1,d0                                        ; Add a1 to d0
	lea      $288(a0),a0                                  ; Get address at offset $288 from a0
	cmpa.l   d0,a0                                        ; Compare d0 with a0
	bcc.w    Loop_LoadFile_HeaderVerify                   ; Load file header verify if carry clear (greater or equal) — checked d0,a0
	lea      Var_FileListBufferSize(pc),a2                ; Point a2 at file list buffer size
	lea      -$264(a0),a0                                 ; Point a0 at -$264(a0)
	move.l   a0,(a2)                                      ; Save filelistbuffersize as filelistbuffersize
	bsr.w    Func_GetSelectedFilename                     ; Call Func_GetSelectedFilename — get selected filename
	moveq    #$8,d0                                       ; Set d0 to 8 ($8)
Loop_LoadFile_SegDebugBlocks:
	moveq    #$1,d1                                       ; Set priority/parameter to 1 in d1
	bsr.b    Func_UpdateDirectorySelection                ; Call Func_UpdateDirectorySelection — update directory selection
	dbra     d0,Loop_LoadFile_SegDebugBlocks              ; Decrement d0 and loop to Loop_LoadFile_SegDebugBlocks until done
	move.w   #$14a,d0                                     ; Set d0 to 330 ($14a)
	move.w   #$ca,d1                                      ; Set d1 to 202 ($ca)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	movea.l  Var_FileListBufferSize(pc),a0                ; Load file list buffer size into a0
	lea      $264(a0),a0                                  ; Get address at offset $264 from a0
	moveq    #$c,d0                                       ; Set d0 to 12 ($c)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	lea      Var_ProStubToggleFlag(pc),a0                 ; Point a0 at pro stub toggle flag
	st.b     (a0)                                         ; Set Var_ProStubToggleFlag to $FF (true)
	bra.w    Loop_LoadFile_HeaderLoop                     ; Jump to Loop_LoadFile_HeaderLoop — load file header loop
Func_GetListSelectedItem:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	moveq    #$0,d0                                       ; Clear value 0 to zero
	moveq    #$d,d2                                       ; Set d2 to 13 ($d)
	moveq    #$2a,d3                                      ; Set d3 to 42 ($2a)
	move.w   #$135,d4                                     ; Set d4 to 309 ($135)
	move.w   #$cb,d5                                      ; Set d5 to 203 ($cb)
	movea.l  Var_Window_Work(pc),a0                       ; Load dialog window into a0
	movea.l  $32(a0),a1                                   ; Read wd_RPort (Window RastPort) into a1
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	jsr      _LVOScrollRaster(a6)                                    ; Scroll raster contents in rectangle (_LVOScrollRaster)
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_UpdateDirectorySelection:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	moveq    #$0,d0                                       ; Clear value 0 to zero
	move.w   #$14a,d2                                     ; Set d2 to 330 ($14a)
	moveq    #$2a,d3                                      ; Set d3 to 42 ($2a)
	move.w   #$1aa,d4                                     ; Set d4 to 426 ($1aa)
	move.w   #$cb,d5                                      ; Set d5 to 203 ($cb)
	movea.l  Var_Window_Work(pc),a0                       ; Load dialog window into a0
	movea.l  $32(a0),a1                                   ; Read wd_RPort (Window RastPort) into a1
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	jsr      _LVOScrollRaster(a6)                                    ; Scroll raster contents in rectangle (_LVOScrollRaster)
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_ScrollDirectoryList:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	move.l   a0,d2                                        ; Copy a0 to d2
	sub.l    a1,d2                                        ; Subtract a1 from d2
	divu.w   #$28,d2                                      ; Load chunky buffer row allocation size ($28 bytes)
	moveq    #-1,d1                                       ; Load error / exit code -1 ($ff) into register d1
	mulu.w   d1,d2                                        ; Multiply d1,d2
	move.l   Var_CurrentFileIndex(pc),d0                  ; Load current file index into d0
	subi.l   #$12,d0                                      ; Subtract 18 ($12) from d0
	beq.b    Loc_LoadFile_CheckSegCode                    ; Load file check seg code if zero/equal — checked counter after subi.l
	divu.w   d0,d2                                        ; Divide d0,d2
Loop_LoadFile_SegEndBlocks:
	lea      Var_DialogListTitle6(pc),a0                  ; Point a0 at dialog list title6
	move.w   d2,(a0)                                      ; Save d2 as dialoglisttitle6
	lea      Var_DialogListTitle5(pc),a0                  ; Point a0 at dialog list title5
	bsr.w    Func_DrawDirectoryList                       ; Call Func_DrawDirectoryList — draw directory list
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Loc_LoadFile_CheckSegCode:
	moveq    #-1,d2                                       ; Load error / exit code -1 ($ff) into register d2
	bra.b    Loop_LoadFile_SegEndBlocks                   ; Jump to Loop_LoadFile_SegEndBlocks — load file seg end blocks
Func_GetSelectedFilename:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	move.l   a0,d2                                        ; Copy a0 to d2
	sub.l    a1,d2                                        ; Subtract a1 from d2
	divu.w   #$24,d2                                      ; Divide d2 by 36 ($24)
	moveq    #-1,d1                                       ; Load error / exit code -1 ($ff) into register d1
	mulu.w   d1,d2                                        ; Multiply d1,d2
	move.l   Var_DirectoryEntryCount(pc),d0               ; Load directory entry count into d0
	subi.l   #$12,d0                                      ; Subtract 18 ($12) from d0
	beq.b    Loc_LoadFile_CheckSegData                    ; Load file check seg data if zero/equal — checked counter after subi.l
	divu.w   d0,d2                                        ; Divide d0,d2
Loop_LoadFile_SegCodeVerify:
	lea      Var_DialogListTitle2(pc),a0                  ; Point a0 at dialog list title2
	move.w   d2,(a0)                                      ; Save d2 as dialoglisttitle2
	lea      Var_DialogListTitle(pc),a0                   ; Point a0 at dialog list title
	bsr.w    Func_DrawDirectoryList                       ; Call Func_DrawDirectoryList — draw directory list
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Loc_LoadFile_CheckSegData:
	moveq    #-1,d2                                       ; Load error / exit code -1 ($ff) into register d2
	bra.b    Loop_LoadFile_SegCodeVerify                  ; Jump to Loop_LoadFile_SegCodeVerify — load file seg code verify
Loc_LoadFile_CheckSegBSS:
	movea.l  Var_FileListBufferPointer(pc),a0             ; Load file list display buffer into a0
	lea      -$28(a0),a0                                  ; Point a0 at -$28(a0)
	movea.l  Var_ScreenChunkyBuffer(pc),a1                ; Load screen chunky pixel buffer into a1
	lea      $28(a1),a1                                   ; Get address at offset $28 from a1
	cmpa.l   a1,a0                                        ; Compare a1 with a0
	bcs.w    Loop_LoadFile_HeaderVerify                   ; Load file header verify if carry set (less than / lower) — checked a1,a0
	lea      Var_FileListBufferPointer(pc),a2             ; Point a2 at file list display buffer
	move.l   a0,(a2)                                      ; Store a0 as file list display buffer
	bsr.w    Func_ScrollDirectoryList                     ; Call Func_ScrollDirectoryList — scroll directory list
	moveq    #$8,d0                                       ; Set d0 to 8 ($8)
Loop_LoadFile_SegDataVerify:
	moveq    #-1,d1                                       ; Load error / exit code -1 ($ff) into register d1
	bsr.w    Func_GetListSelectedItem                     ; Call Func_GetListSelectedItem — get list selected item
	dbra     d0,Loop_LoadFile_SegDataVerify               ; Decrement d0 and loop to Loop_LoadFile_SegDataVerify until done
	moveq    #$d,d0                                       ; Set d0 to 13 ($d)
	moveq    #$31,d1                                      ; Set d1 to 49 ($31)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	movea.l  Var_FileListBufferPointer(pc),a0             ; Load file list display buffer into a0
	moveq    #$25,d0                                      ; Set d0 to 37 ($25)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	lea      Var_RleFilterToggleFlag(pc),a0               ; Point a0 at rle filter toggle flag
	st.b     (a0)                                         ; Set Var_RleFilterToggleFlag to $FF (true)
	bra.w    Loop_LoadFile_HeaderLoop                     ; Jump to Loop_LoadFile_HeaderLoop — load file header loop
Loc_LoadFile_CheckSegReloc:
	movea.l  Var_FileListBufferSize(pc),a0                ; Load file list buffer size into a0
	lea      -$24(a0),a0                                  ; Point a0 at -$24(a0)
	movea.l  Var_ViewportBuffer(pc),a1                    ; Load ViewPort display buffer into a1
	cmpa.l   a1,a0                                        ; Compare a1 with a0
	bcs.w    Loop_LoadFile_HeaderVerify                   ; Load file header verify if carry set (less than / lower) — checked a1,a0
	lea      Var_FileListBufferSize(pc),a2                ; Point a2 at file list buffer size
	move.l   a0,(a2)                                      ; Save filelistbuffersize as filelistbuffersize
	bsr.w    Func_GetSelectedFilename                     ; Call Func_GetSelectedFilename — get selected filename
	moveq    #$8,d0                                       ; Set d0 to 8 ($8)
Loop_LoadFile_SegBSSVerify:
	moveq    #-1,d1                                       ; Load error / exit code -1 ($ff) into register d1
	bsr.w    Func_UpdateDirectorySelection                ; Call Func_UpdateDirectorySelection — update directory selection
	dbra     d0,Loop_LoadFile_SegBSSVerify                ; Decrement d0 and loop to Loop_LoadFile_SegBSSVerify until done
	move.w   #$14a,d0                                     ; Set d0 to 330 ($14a)
	moveq    #$31,d1                                      ; Set d1 to 49 ($31)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	movea.l  Var_FileListBufferSize(pc),a0                ; Load file list buffer size into a0
	moveq    #$c,d0                                       ; Set d0 to 12 ($c)
	bsr.w    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	lea      Var_StatusUpdateFlag(pc),a0                  ; Point a0 at status update flag
	st.b     (a0)                                         ; Set Var_StatusUpdateFlag to $FF (true)
	bra.w    Loop_LoadFile_HeaderLoop                     ; Jump to Loop_LoadFile_HeaderLoop — load file header loop
Func_ResetDirectoryIndex:
	move.w   #$12a,d0                                     ; Set d0 to 298 ($12a)
	moveq    #$14,d1                                      ; Set d1 to 20 ($14)
	bsr.b    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	moveq    #$11,d0                                      ; Set d0 to 17 ($11)
	movea.l  Var_ScreenChunkyBuffer(pc),a0                ; Load screen chunky pixel buffer into a0
	move.b   #$1,(a0)                                     ; Write byte $1 to (a0)
	bra.b    Func_FloppyTrackWrite                        ; Jump to Func_FloppyTrackWrite — floppy track write
Func_InitializeDirectoryDisplay:
	move.w   #$14a,d0                                     ; Set d0 to 330 ($14a)
	moveq    #$31,d1                                      ; Set d1 to 49 ($31)
	moveq    #$11,d2                                      ; Set d2 to 17 ($11)
	movea.l  Var_ViewportBuffer(pc),a0                    ; Load ViewPort display buffer into a0
Loop_LoadFile_SegRelocVerify:
	bsr.b    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	addi.w   #$9,d1                                       ; Add 9 ($9) to d1
	exg.l    d0,d3                                        ; EXG.L d0,d3
	moveq    #$c,d0                                       ; Set d0 to 12 ($c)
	bsr.b    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	exg.l    d3,d0                                        ; EXG.L d3,d0
	lea      $24(a0),a0                                   ; Get address at offset $24 from a0
	dbra     d2,Loop_LoadFile_SegRelocVerify              ; Decrement d2 and loop to Loop_LoadFile_SegRelocVerify until done
	rts                                                   ; Return to caller
Func_InitFloppyIOReq:
	movea.l  Var_ScreenChunkyBuffer(pc),a0                ; Load screen chunky pixel buffer into a0
	lea      $28(a0),a0                                   ; Get address at offset $28 from a0
Func_DoFloppyIOReq:
	moveq    #$d,d0                                       ; Set d0 to 13 ($d)
	moveq    #$31,d1                                      ; Set d1 to 49 ($31)
	moveq    #$11,d2                                      ; Set d2 to 17 ($11)
Loop_InitFloppyIOReq:
	bsr.b    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	addi.w   #$9,d1                                       ; Add 9 ($9) to d1
	exg.l    d0,d3                                        ; EXG.L d0,d3
	moveq    #$25,d0                                      ; Set d0 to 37 ($25)
	bsr.b    Func_FloppyTrackWrite                        ; Call Func_FloppyTrackWrite — floppy track write
	exg.l    d3,d0                                        ; EXG.L d3,d0
	lea      $28(a0),a0                                   ; Get address at offset $28 from a0
	dbra     d2,Loop_InitFloppyIOReq                      ; Decrement d2 and loop to Loop_InitFloppyIOReq until done
	rts                                                   ; Return to caller
Func_FloppyTrackRead:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	movea.l  Var_Window_Work(pc),a1                       ; Load dialog window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOMove(a6)                          ; Scroll ViewPort vertically
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_FloppyTrackWrite:
	move.l   d0,-(a7)                                     ; Save d0 on stack
	move.b   (a0)+,d0                                     ; Load (a0)+ into d0
	bsr.w    Func_FormatProgressValue                     ; Call Func_FormatProgressValue — format progress value
	move.l   (a7)+,d0                                     ; Restore d0 from stack
Func_DoFloppyTrackCommand:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_GfxBase(pc),a6                           ; Load graphics.library base into a6
	movea.l  Var_Window_Work(pc),a1                       ; Load dialog window into a1
	movea.l  $32(a1),a1                                   ; Read wd_RPort (Window RastPort) into a1
	jsr      _LVOText(a6)                                     ; Render text string to RastPort (_LVOText)
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	subq.l   #$1,a0                                       ; Decrement a0 by one
	rts                                                   ; Return to caller
Func_UpdateFloppyStatus:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	lea      Var_FileListBufferPointer(pc),a1             ; Point a1 at file list display buffer
	move.l   Var_ScreenChunkyBuffer(pc),(a1)              ; Access Screen structure pointer
	addi.l   #$28,(a1)                                    ; Load chunky buffer row allocation size ($28 bytes)
	movea.l  Var_ChunkyBuffer40(pc),a0                    ; Load 40-byte chunky row buffer into a0
	moveq    #$9,d0                                       ; Set d0 to 9 ($9)
	bsr.b    Func_ResetFloppyDrive                        ; Call Func_ResetFloppyDrive — reset floppy drive
	movea.l  Var_ScreenChunkyBuffer(pc),a0                ; Load screen chunky pixel buffer into a0
	move.l   #$f9f,d0                                     ; Set d0 to 3999 ($f9f)
	bsr.b    Func_ResetFloppyDrive                        ; Call Func_ResetFloppyDrive — reset floppy drive
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_ResetFloppyDrive:
	clr.l    (a0)+                                        ; Clear memory at (a0)
	dbra     d0,Func_ResetFloppyDrive                     ; Decrement d0 and loop to Func_ResetFloppyDrive until done
	rts                                                   ; Return to caller
Func_InitializeFloppyGeometry:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	lea      Var_FileListBufferSize(pc),a1                ; Point a1 at file list buffer size
	movea.l  Var_ViewportBuffer(pc),a0                    ; Load ViewPort display buffer into a0
	move.l   a0,(a1)                                      ; Save ViewPort display buffer as filelistbuffersize
	move.l   #$10d,d0                                     ; Set d0 to 269 ($10d)
	bsr.b    Func_ResetFloppyDrive                        ; Call Func_ResetFloppyDrive — reset floppy drive
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Loc_LoadFile_CheckSegSymbol:
	lea      Var_FileNameInput(pc),a0                     ; Point a0 at user-entered filename string
Loop_LoadFile_SegEndVerify:
	tst.b    (a0)+                                        ; Check whether user-entered filename string is zero/null
	bne.b    Loop_LoadFile_SegEndVerify                   ; Load file seg end verify if non-zero/not equal — checked value at (a0)
	cmpi.b   #$3a,-$2(a0)                                 ; Compare #$3a with -$2(a0)
	beq.b    Loc_LoadFile_CheckSegEnd                     ; Load file check seg end if zero/equal — checked #$3a,-$2(a0)
	move.l   Var_DirectoryLock(pc),d1                     ; Load current directory lock handle into d1
	beq.b    Loc_LoadFile_CheckSegEnd                     ; Load file check seg end if zero/equal
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	jsr      _LVOFreeMem(a6)                                     ; FreeMem — free allocated memory
	tst.l    d0                                           ; Check if function return value is zero
	beq.b    Loc_LoadFile_CheckSegEnd                     ; Load file check seg end if zero/equal — checked d0
	lea      Var_DirectoryLock(pc),a0                     ; Point a0 at current directory lock handle
	move.l   (a0),d1                                      ; Load value from (a0) into d1
	move.l   d0,(a0)                                      ; Store d0 as current directory lock handle
	jsr      _LVOUnLock(a6)                               ; Release duplicated directory lock
	lea      Var_FileNameInput(pc),a1                     ; Point a1 at user-entered filename string
	movea.l  a1,a2                                        ; Load user-entered filename string into a2
Loop_LoadFile_SegFinal:
	tst.b    (a1)+                                        ; Check whether user-entered filename string is zero/null
	bne.b    Loop_LoadFile_SegFinal                       ; Load file seg final if non-zero/not equal — checked value at (a1)
	lea      -$3(a1),a1                                   ; Point a1 at -$3(a1)
Loop_LoadFile_SegDone:
	move.b   -(a1),d0                                     ; Load -(a1) into d0
	cmp.b    #$2f,d0                                      ; Check if d0 equals $2f (47)
	beq.b    Loc_LoadFile_CheckSegDebug                   ; Load file check seg debug if zero/equal — d0 vs $2f — checked #$2f,d0
	cmp.b    #$3a,d0                                      ; Check if d0 equals $3a (58)
	beq.b    Loc_LoadFile_CheckSegDebug                   ; Load file check seg debug if zero/equal — d0 vs $3a — checked #$3a,d0
	cmpa.l   a2,a1                                        ; Compare a2 with a1
	bcc.b    Loop_LoadFile_SegDone                        ; Load file seg done if carry clear (greater or equal) — checked a2,a1
Loc_LoadFile_CheckSegDebug:
	addq.l   #$1,a1                                       ; Increment a1 by one
	clr.b    (a1)                                         ; Clear memory at (a1)
	lea      Var_DialogListTitle4(pc),a0                  ; Point a0 at dialog list title4
	bsr.w    Func_DrawDirectoryList                       ; Call Func_DrawDirectoryList — draw directory list
	bsr.w    Func_ExamineFloppyDirectory                  ; Call Func_ExamineFloppyDirectory — examine floppy directory
Loc_LoadFile_CheckSegEnd:
	bra.w    Func_DrawDialogLayout                        ; Jump to Func_DrawDialogLayout — draw dialog layout
; ============================================================================
; Function: Func_RefreshFloppyStatusDisplay
; Purpose : Queries current disk/floppy InfoData structure, extracts the volume name
;           from the DeviceList node, formats the free disk space in KB, and updates
;           the status/floppy text display in the UI.
; ============================================================================
Func_RefreshFloppyStatusDisplay:
	movem.l  d0-d2/a0-a2/a6,-(a7)                         ; Save working registers to stack
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	move.l   Var_FIBPointer(pc),d2                        ; Pass InfoData destination buffer pointer (reused FIB)
	move.l   Var_DirectoryLock(pc),d1                     ; Pass lock pointer of directory to query
	beq.w    Loc_FormatMemSize_Finish                     ; Exit if directory lock is null
	jsr      _LVOInfo(a6)                                 ; Call Info(lock, infoData) to query disk info block
	tst.b    d0                                           ; Check if Info() call succeeded
	beq.w    Loc_FormatMemSize_Finish                     ; Exit if Info() call failed
	move.l   Var_FileNameInput(pc),d0                     ; Load user-entered filename string
	cmp.l    #$52414d3a,d0                                ; Check if the name starts with "RAM:"
	beq.b    Loc_FormatMemSize_Loop                       ; Skip volume name extraction for "RAM:"
	cmp.l    #$5241443a,d0                                ; Check if the name starts with "RAD:"
	beq.b    Loc_FormatMemSize_Loop                       ; Skip volume name extraction for "RAD:"
	cmp.l    #$52414d20,d0                                ; Check if the name starts with "RAM "
	beq.b    Loc_FormatMemSize_Loop                       ; Skip volume name extraction for "RAM "
	move.b   Var_FileNameInput(pc),d0                     ; Load first character of filename input
	beq.b    Loc_FormatMemSize_Loop                       ; Skip if empty
	movea.l  Var_FIBPointer(pc),a0                        ; Load InfoData buffer pointer
	movea.l  id_VolumeNode(a0),a0                         ; Get Volume node pointer (BPTR) from InfoData
	adda.l   a0,a0                                        ; Convert Volume BPTR to APTR (part 1)
	adda.l   a0,a0                                        ; Convert Volume BPTR to APTR (part 2)
	movea.l  dol_Name(a0),a0                              ; Get volume name BSTR pointer (BPTR) from DevList node
	adda.l   a0,a0                                        ; Convert BSTR BPTR to APTR (part 1)
	adda.l   a0,a0                                        ; Convert BSTR BPTR to APTR (part 2)
	moveq    #$0,d0                                       ; Clear d0
	move.b   (a0)+,d0                                     ; Load volume name length byte, advancing to string characters
	beq.b    Loc_FormatMemSize_Loop                       ; Skip formatting if name length is 0
	cmp.b    #$28,d0                                      ; Cap volume name length at 40 characters ($28)
	bcs.b    Loc_FormatMemSize_NoZero                     ; Branch if volume name length is less than 40
	moveq    #$28,d0                                      ; Limit to 40 characters
Loc_FormatMemSize_NoZero:
	movea.l  Var_ChunkyBuffer40(pc),a1                    ; Load 40-byte chunky row buffer pointer
Loop_FormatMemSize_Shift:
	move.b   (a0)+,(a1)+                                  ; Copy next character of volume name to chunky buffer
	subq.b   #$1,d0                                       ; Count down characters
	bne.b    Loop_FormatMemSize_Shift                     ; Loop until volume name is copied
Loc_FormatMemSize_Loop:
	moveq    #$1,d0                                       ; Set format type (1)
	bsr.w    Func_FormatProgressValue                     ; Format progress info
	move.w   #$52,d0                                      ; UI text column coordinate
	moveq    #$14,d1                                      ; UI text row coordinate
	bsr.w    Func_FloppyTrackRead                         ; Update floppy status text layout in UI
	movea.l  Var_ChunkyBuffer40(pc),a0                    ; Load volume name chunky buffer pointer
	moveq    #$10,d0                                      ; Text length limit (16 characters)
	bsr.w    Func_DoFloppyTrackCommand                    ; Render volume name to UI status bar
	movea.l  Var_FIBPointer(pc),a0                        ; Load InfoData buffer pointer (reused FIB)
	move.l   id_NumBlocks(a0),d0                          ; Get total blocks on disk
	sub.l    id_NumBlocksUsed(a0),d0                      ; Subtract used blocks to get free block count
	move.l   id_BytesPerBlock(a0),d1                      ; Get block size (bytes per block)
	mulu.w   d1,d0                                        ; Multiply free blocks by block size to get free bytes
	movea.l  d0,a0                                        ; Pass free bytes count in a0
	bsr.b    Func_FormatMemSize                           ; Format free bytes into human-readable KB format
	move.w   #$84,d0                                      ; UI text column coordinate
	moveq    #$22,d1                                      ; UI text row coordinate
	bsr.w    Func_FloppyTrackRead                         ; Update floppy status text layout in UI
	lea      Var_FormattedOutputString(pc),a0             ; Point a0 at formatted free space string
	moveq    #$8,d0                                       ; Free space text length limit (8 characters)
	bsr.w    Func_DoFloppyTrackCommand                    ; Render free space KB string to UI status bar
Loc_FormatMemSize_Finish:
	movem.l  (a7)+,d0-d2/a0-a2/a6                         ; Restore registers from stack
	rts                                                   ; Return to caller
Func_FormatFloppyTrackText:
	bsr.b    Func_FormatMemSize                           ; Format raw byte size into KB text representation
	lea      Var_FormattedOutputString(pc),a0             ; Point a0 at formatted numeric output string
	bra.w    Loop_RenderText_Height                       ; Jump to Loop_RenderText_Height — render text height
Func_FormatMemSize:
	move.l   a0,d7                                        ; Load formatted numeric output string into d7
	move.l   #$989680,d0                                  ; Set d0 to 10000000 ($989680)
	lea      Var_FormattedOutputString(pc),a2             ; Point a2 at formatted numeric output string
	lea      Var_FloppyTrackReady(pc),a0                  ; Point a0 at floppy track ready
	moveq    #$0,d2                                       ; Clear value 0 to zero
Loop_FormatMemSize_Digit:
	moveq    #$2f,d1                                      ; Set d1 to 47 ($2f)
Loop_FormatMemSize_Write:
	addq.b   #$1,d1                                       ; Add #$1 to d1
	sub.l    d0,d7                                        ; Subtract d0 from d7
	bcc.b    Loop_FormatMemSize_Write                     ; Format mem size write if carry clear (greater or equal)
	add.l    d0,d7                                        ; Add d0 to d7
	cmp.b    #$30,d1                                      ; Check if d1 equals $30 (48)
	beq.b    Loc_FormatMemSize_FinalCheck                 ; Format mem size final check if zero/equal — d1 vs $30 — checked #$30,d1
	st.b     (a0)                                         ; Set byte at (a0) to $FF (true)
Loop_FormatMemSize_Pad:
	move.b   d1,(a2)+                                     ; Store d1 at address in a2
Loop_FormatMemSize_Zero:
	tst.b    d2                                           ; Test d2 for zero
	bmi.b    Loc_FormatMemSize_Done                       ; Format mem size done if minus (negative sign bit set) — checked d2
	divu.w   #$2710,d0                                    ; Divide d0 by 10000 ($2710)
	cmp.w    #$1,d0                                       ; Check if d0 equals $1 (1)
	bne.b    Loc_FormatMemSize_WriteDigit                 ; Format mem size write digit if non-zero/not equal — d0 vs $1 — checked #$1,d0
	moveq    #-1,d2                                       ; Load error / exit code -1 ($ff) into register d2
Loc_FormatMemSize_WriteDigit:
	mulu.w   #$3e8,d0                                     ; Multiply d0 by 1000 ($3e8)
	bra.b    Loop_FormatMemSize_Digit                     ; Jump to Loop_FormatMemSize_Digit — format mem size digit
Loc_FormatMemSize_Done:
	divu.w   #$a,d0                                       ; Divide d0 by 10 ($a)
	cmp.w    #$1,d0                                       ; Check if d0 equals $1 (1)
	bne.b    Loop_FormatMemSize_Digit                     ; Format mem size digit if non-zero/not equal — d0 vs $1 — checked #$1,d0
	addi.b   #$30,d7                                      ; Add 48 ($30) to d7
	move.b   d7,(a2)+                                     ; Store d7 at address in a2
	sf.b     (a0)                                         ; Clear byte at (a0) to $00 (false)
	sf.b     (a2)                                         ; Clear byte at (a2) to $00 (false)
	rts                                                   ; Return to caller
Loc_FormatMemSize_FinalCheck:
	tst.b    (a0)                                         ; Test byte at (a0) for zero
	bne.b    Loop_FormatMemSize_Pad                       ; Format mem size pad if non-zero/not equal — checked value at (a0)
	move.b   #$20,(a2)+                                   ; Write byte $20 to (a2)
	bra.b    Loop_FormatMemSize_Zero                      ; Jump to Loop_FormatMemSize_Zero — format mem size zero
; ============================================================================
; Function: Func_ReadFloppyDirectory
; Purpose : Traverses the system DOS device/volume list (DosList) and builds a sorted
;           list of all mounted disk device/volume names in the UI viewport buffer.
; Notes   : Traversal route: DOSBase -> dl_Root -> rn_Info -> di_DevInfo.
;           Filters out non-disk system devices (" PRT", " RAW", " CON", " SER", " PAR").
; ============================================================================
Func_ReadFloppyDirectory:
	lea      Var_DirectoryEntryCount(pc),a0               ; Point a0 at directory entry count
	clr.l    (a0)                                         ; Zero directory entry counter
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	movea.l  dl_Root(a6),a6                               ; Get RootNode pointer (BPTR) from DOSBase
	movea.l  rn_Info(a6),a6                               ; Get DOSInfo pointer (BPTR) from RootNode
	adda.l   a6,a6                                        ; Convert DOSInfo BPTR to APTR (part 1)
	adda.l   a6,a6                                        ; Convert DOSInfo BPTR to APTR (part 2)
	movea.l  di_DevInfo(a6),a6                            ; Get first DevList node pointer (BPTR) from DOSInfo
	movea.l  Var_ViewportBuffer(pc),a4                    ; Load viewport text display buffer pointer
	movea.l  a4,a3                                        ; Keep viewport buffer base pointer in a3
Loop_BuildDir_Entries:
	adda.l   a6,a6                                        ; Convert current DevList BPTR to APTR (part 1)
	adda.l   a6,a6                                        ; Convert current DevList BPTR to APTR (part 2)
	tst.l    dol_Type(a6)                                 ; Check if the entry is a device node (DLT_DEVICE = 0)
	beq.b    Loc_BuildDir_ExamineLoop                     ; If device node (type 0), check if it is a system device to filter
Loop_BuildDir_WaitMotor:
	movea.l  dol_Name(a6),a5                              ; Get BSTR name pointer (BPTR) from current DevList node
	bsr.b    Func_ParseFloppyFilename                     ; Parse BSTR name, format it, and store in viewport list
Loop_BuildDir_Delay:
	tst.l    (a6)                                         ; Check if there is a next DevList node (offset 0 = dol_Next)
	beq.b    Loc_BuildDir_SkipItem                        ; If next node pointer is null, traversal is complete
	movea.l  (a6),a6                                      ; Move to next DevList node (offset 0 = dol_Next)
	bra.b    Loop_BuildDir_Entries                        ; Continue DevList traversal
Loc_BuildDir_ExamineLoop:
	movea.l  dol_Name(a6),a5                              ; Get BSTR name pointer (BPTR) from current DevList node
	adda.l   a5,a5                                        ; Convert BSTR BPTR to APTR (part 1)
	adda.l   a5,a5                                        ; Convert BSTR BPTR to APTR (part 2)
	move.l   (a5),d0                                      ; Load first 4 bytes of BSTR: [length][char1][char2][char3]
	andi.l   #$ffffff,d0                                  ; Clear length byte to prepare character prefix space comparison
	ori.l    #$20000000,d0                                ; Set high byte to ' ' (ASCII space), yielding " XXX" formatted string
	cmp.l    #$20505254,d0                                ; Check if the name starts with " PRT" (Printer device)
	beq.b    Loop_BuildDir_Delay                          ; If matched, skip it (do not add system device to UI list)
	cmp.l    #$20524157,d0                                ; Check if the name starts with " RAW" (Raw console device)
	beq.b    Loop_BuildDir_Delay                          ; If matched, skip it
	cmp.l    #$20434f4e,d0                                ; Check if the name starts with " CON" (Console device)
	beq.b    Loop_BuildDir_Delay                          ; If matched, skip it
	cmp.l    #$20534552,d0                                ; Check if the name starts with " SER" (Serial device)
	beq.b    Loop_BuildDir_Delay                          ; If matched, skip it
	cmp.l    #$20504152,d0                                ; Check if the name starts with " PAR" (Parallel device)
	beq.b    Loop_BuildDir_Delay                          ; If matched, skip it
	bra.b    Loop_BuildDir_WaitMotor                      ; Otherwise, it's a valid disk volume/device, so process it

; ============================================================================
; Function: Func_ParseFloppyFilename
; Purpose : Converts a BSTR device/volume name from a DevList entry, appends a colon,
;           null-terminates it, and stores it in the UI viewport text buffer.
; Inputs  : a5 = BPTR to name BSTR.
;           a3 = Start of current 36-byte slot in UI viewport buffer.
;           a4 = Current write pointer in UI viewport buffer.
; Outputs : a3, a4 updated to point to the next 36-byte slot.
; ============================================================================
Func_ParseFloppyFilename:
	adda.l   a5,a5                                        ; Convert BSTR BPTR to APTR (part 1)
	adda.l   a5,a5                                        ; Convert BSTR BPTR to APTR (part 2)
	move.b   (a5)+,d0                                     ; Load BSTR length byte into d0, advancing a5 to characters
	move.b   #$3,(a4)+                                    ; Write UI pen selection prefix ($03) to buffer
Loop_BuildDir_CopyName:
	move.b   (a5)+,(a4)+                                  ; Copy next character of device name to buffer
	subq.b   #$1,d0                                       ; Count down remaining characters
	bne.b    Loop_BuildDir_CopyName                       ; Continue copying until all characters are copied
	move.b   #$3a,(a4)+                                   ; Append colon (':') to name
	clr.b    (a4)                                         ; Null-terminate the string
	lea      $24(a3),a4                                   ; Advance a4 to next 36-byte slot ($24 bytes from slot base)
	movea.l  a4,a3                                        ; Sync slot base pointer a3 with current slot pointer a4
	lea      Var_DirectoryEntryCount(pc),a5               ; Point a5 at directory entry count variable
	addq.l   #$1,(a5)                                     ; Increment total count of parsed entries
	bra.b    Loop_BuildDir_Delay                          ; Proceed back to process next DevList node
Loc_BuildDir_SkipItem:
	bsr.b    Func_SortFloppyDirectory                     ; Call Func_SortFloppyDirectory — sort floppy directory
	rts                                                   ; Return to caller
Func_SortFloppyDirectory:
	move.l   Var_DirectoryEntryCount(pc),d0               ; Load directory entry count into d0
	subq.l   #$1,d0                                       ; Decrement d0 by one
	bls.b    Loc_BuildDir_Done                            ; Build dir done if unsigned lower or same — checked counter after subq.l
	movea.l  Var_ViewportBuffer(pc),a0                    ; Load ViewPort display buffer into a0
	movea.l  a0,a1                                        ; Pass ViewPort display buffer in a1
Loop_BuildDir_SortOuter:
	move.l   d0,d1                                        ; Copy return value to d1
Loop_BuildDir_SortInner:
	move.l   (a0),d2                                      ; Load value from (a0) into d2
	cmp.l    $24(a1),d2                                   ; Compare $24(a1) with d2
	bcc.b    Loc_BuildDir_CompareStrings                  ; Build dir compare strings if carry clear (greater or equal) — checked $24(a1),d2
Loop_BuildDir_CompareLoop:
	lea      $24(a1),a1                                   ; Get address at offset $24 from a1
	subq.w   #$1,d1                                       ; Decrement d1 by one
	bne.b    Loop_BuildDir_SortInner                      ; Build dir sort inner if non-zero/not equal — checked counter after subq.w
	lea      $24(a0),a0                                   ; Get address at offset $24 from a0
	movea.l  a0,a1                                        ; Copy a0 to a1
	subq.w   #$1,d0                                       ; Decrement d0 by one
	bne.b    Loop_BuildDir_SortOuter                      ; Build dir sort outer if non-zero/not equal — checked counter after subq.w
Loc_BuildDir_Done:
	rts                                                   ; Return to caller
Loc_BuildDir_CompareStrings:
	moveq    #$20,d3                                      ; Set d3 to 32 ($20)
Loop_BuildDir_CharCompare:
	move.l   (a0,d3.w),-(a7)                              ; Copy register or memory value
	move.l   $24(a1,d3.w),(a0,d3.w)                       ; Copy register or memory value
	move.l   (a7)+,$24(a1,d3.w)                           ; Copy register or memory value
	subq.b   #$4,d3                                       ; Subtract 4 ($4) from d3
	bcc.w    Loop_BuildDir_CharCompare                    ; Build dir char compare if carry clear (greater or equal)
	bra.b    Loop_BuildDir_CompareLoop                    ; Jump to Loop_BuildDir_CompareLoop — build dir compare loop
Loc_BuildDir_SwapEntries:
	bsr.w    Func_BuildAndSortDirectory                   ; Call Func_BuildAndSortDirectory — build and sort directory
	bra.w    Loop_LoadFile_BlockExit                      ; Jump to Loop_LoadFile_BlockExit — load file block exit
Loc_BuildDir_NextCompare:
	moveq    #$1,d0                                       ; Set d0 to 1 ($1)
	bsr.w    Func_FormatProgressValue                     ; Call Func_FormatProgressValue — format progress value
	lea      Var_FloppyOperationActive(pc),a2             ; Point a2 at floppy operation active flag
	tst.b    (a2)                                         ; Check whether floppy operation active flag is zero/null
	bne.b    Loc_BuildDir_SortLoop                        ; Build dir sort loop if non-zero/not equal — checked value at (a2)
	move.w   #$132,d0                                     ; Set d0 to 306 ($132)
	moveq    #$22,d1                                      ; Set d1 to 34 ($22)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	lea      Str_Menu_ShowInfoFiles(pc),a0                ; Point a0 at menu show info files
	moveq    #$10,d0                                      ; Set d0 to 16 ($10)
	bsr.w    Func_DoFloppyTrackCommand                    ; Call Func_DoFloppyTrackCommand — do floppy track command
	st.b     (a2)                                         ; Set byte at (a2) to $FF (true)
	bra.w    Loop_LoadFile_HeaderDoneLoop                 ; Jump to Loop_LoadFile_HeaderDoneLoop — load file header done loop
Loc_BuildDir_SortLoop:
	clr.b    (a2)                                         ; Clear memory at (a2)
	move.w   #$132,d0                                     ; Set d0 to 306 ($132)
	moveq    #$22,d1                                      ; Set d1 to 34 ($22)
	bsr.w    Func_FloppyTrackRead                         ; Call Func_FloppyTrackRead — floppy track read
	lea      Str_Menu_HideInfoFiles(pc),a0                ; Point a0 at menu hide info files
	moveq    #$10,d0                                      ; Set d0 to 16 ($10)
	bsr.w    Func_DoFloppyTrackCommand                    ; Call Func_DoFloppyTrackCommand — do floppy track command
	bra.w    Loop_LoadFile_HeaderDoneLoop                 ; Jump to Loop_LoadFile_HeaderDoneLoop — load file header done loop
Func_LockFloppyDirectory:
	move.l   Var_DirectoryLock(pc),-(a7)                  ; Push value onto stack
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	lea      Var_FileNameInput(pc),a0                     ; Point a0 at user-entered filename string
	move.l   a0,d1                                        ; Load user-entered filename string into d1
	moveq    #-2,d2                                       ; Quick load constant value #$fe into register d2
	jsr      _LVOLock(a6)                                 ; Obtain a shared lock on the source file
	lea      Var_DirectoryLock(pc),a0                     ; Point a0 at current directory lock handle
	move.l   d0,(a0)                                      ; Store d0 as current directory lock handle
	beq.w    Loc_Examine_Failed                           ; Examine failed if zero/equal
	move.l   (a7)+,d1                                     ; Restore d1 from stack
	beq.b    Func_ExamineFloppyDirectory                  ; Examine floppy directory if zero/equal
	jsr      _LVOUnLock(a6)                               ; Release duplicated directory lock
Func_ExamineFloppyDirectory:
	bsr.w    Func_UpdateFloppyStatus                      ; Call Func_UpdateFloppyStatus — update floppy status
	bsr.w    Func_RefreshFloppyStatusDisplay              ; Call Func_RefreshFloppyStatusDisplay — refresh floppy status display
	lea      Var_CurrentFileIndex(pc),a0                  ; Point a0 at current file index
	clr.l    (a0)                                         ; Zero Var_CurrentFileIndex
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	move.l   Var_DirectoryLock(pc),d1                     ; Load current directory lock handle into d1
	move.l   Var_FIBPointer(pc),d2                        ; Load FileInfoBlock buffer into d2
	jsr      _LVOExamine(a6)                              ; Examine the locked file to get its metadata/size
	tst.l    d0                                           ; Check if function return value is zero
	beq.w    Loop_Examine_DoneDelay                       ; Examine done delay if zero/equal — checked d0
	bsr.b    Func_ProcessFloppyDirEntry                   ; Call Func_ProcessFloppyDirEntry — process floppy dir entry
Loop_Examine_WaitMotor:
	move.l   Var_DirectoryLock(pc),d1                     ; Load current directory lock handle into d1
	move.l   Var_FIBPointer(pc),d2                        ; Load FileInfoBlock buffer into d2
	jsr      _LVOExNext(a6)                               ; Scan the next file entry in the locked directory
	tst.l    d0                                           ; Check whether return value from Func_ProcessFloppyDirEntry is zero
	beq.w    Loc_Examine_Done                             ; Examine done if zero/equal — return value from Func_ProcessFloppyDirEntry check — checked d0
	bsr.b    Func_ProcessFloppyDirEntry                   ; Call Func_ProcessFloppyDirEntry — process floppy dir entry
	cmpi.l   #$190,Var_CurrentFileIndex.l                 ; Check if Var_CurrentFileIndex equals $190 (400)
	beq.w    Loc_Examine_Done                             ; Examine done if zero/equal — Var_CurrentFileIndex vs $190 — checked #$190,Var_CurrentFileIndex.l
	bra.b    Loop_Examine_WaitMotor                       ; Jump to Loop_Examine_WaitMotor — examine wait motor
Loop_Examine_NextEntry:
	moveq    #$1,d1                                       ; Set priority/parameter to 1 in d1
	bra.b    Loc_Examine_ProcessEntry                     ; Jump to Loc_Examine_ProcessEntry — examine process entry
Func_ProcessFloppyDirEntry:
	movea.l  Var_FIBPointer(pc),a0                        ; Load FileInfoBlock buffer into a0
	move.l   $4(a0),d0                                    ; Read offset $4(a0) into d0
	bmi.b    Loop_Examine_NextEntry                       ; Examine next entry if minus (negative sign bit set)
	moveq    #$3,d1                                       ; Set priority/parameter to 3 in d1
Loc_Examine_ProcessEntry:
	lea      $8(a0),a1                                    ; Get address at offset $8 from a0
	movea.l  Var_ScreenChunkyBuffer(pc),a2                ; Load screen chunky pixel buffer into a2
	move.l   Var_CurrentFileIndex(pc),d0                  ; Load current file index into d0
	mulu.w   #$28,d0                                      ; Load chunky buffer row allocation size ($28 bytes)
	adda.l   d0,a2                                        ; Add d0 to a2
	movea.l  a2,a3                                        ; Copy screen chunky pixel buffer to a3
	move.b   d1,(a2)+                                     ; Write d1 to screen chunky pixel buffer
Loop_Examine_CopyName:
	move.b   (a1)+,d0                                     ; Load (a1)+ into d0
	beq.b    Loc_Examine_Next                             ; Examine next if zero/equal
	cmp.b    #$2e,d0                                      ; Check if d0 equals $2e (46)
	beq.b    Loc_Examine_File                             ; Examine file if zero/equal — d0 vs $2e — checked #$2e,d0
Loop_Examine_PadName:
	move.b   d0,(a2)+                                     ; Store d0 at address in a2
	bra.b    Loop_Examine_CopyName                        ; Jump to Loop_Examine_CopyName — examine copy name
Loc_Examine_File:
	cmpi.b   #$69,(a1)                                    ; Compare #$69 with (a1)
	bne.b    Loop_Examine_PadName                         ; Examine pad name if non-zero/not equal — checked #$69,(a1)
	cmpi.b   #$6e,$1(a1)                                  ; Compare #$6e with $1(a1)
	bne.b    Loop_Examine_PadName                         ; Examine pad name if non-zero/not equal — checked #$6e,$1(a1)
	cmpi.b   #$66,$2(a1)                                  ; Compare #$66 with $2(a1)
	bne.b    Loop_Examine_PadName                         ; Examine pad name if non-zero/not equal — checked #$66,$2(a1)
	cmpi.b   #$6f,$3(a1)                                  ; Compare #$6f with $3(a1)
	bne.b    Loop_Examine_PadName                         ; Examine pad name if non-zero/not equal — checked #$6f,$3(a1)
	move.b   Var_FloppyOperationActive(pc),d1             ; Load floppy operation active flag into d1
	beq.b    Loop_Examine_PadName                         ; Examine pad name if zero/equal
Loop_Examine_NextCheck:
	clr.b    -(a2)                                        ; Zero out -(a2)
	cmpa.l   a2,a3                                        ; Compare a2 with a3
	bne.b    Loop_Examine_NextCheck                       ; Examine next check if non-zero/not equal — checked a2,a3
	rts                                                   ; Return to caller
Loc_Examine_Next:
	move.b   d0,(a2)                                      ; Store d0 at address in a2
	movea.l  fib_Size(a0),a0                                   ; Read offset fib_Size(a0) into a0
	move.l   a0,d0                                        ; Copy a0 to d0
	beq.b    Loc_Examine_Loop                             ; Examine loop if zero/equal
	bsr.w    Func_FormatMemSize                           ; Format raw byte size into KB text representation
	lea      $20(a3),a0                                   ; Get address at offset $20 from a3
	lea      Var_FormattedOutputString(pc),a1             ; Point a1 at formatted numeric output string
	addq.l   #$2,a1                                       ; Add 2 ($2) to a1
	moveq    #$5,d1                                       ; Set d1 to 5 ($5)
Loop_Examine_Delay:
	move.b   (a1)+,(a0)+                                  ; Copy next byte from source to destination
	dbra     d1,Loop_Examine_Delay                        ; Decrement d1 and loop to Loop_Examine_Delay until done
Loc_Examine_Loop:
	cmpi.b   #$3,(a3)                                     ; Compare #$3 with (a3)
	beq.b    Loc_Examine_Error                            ; Examine error if zero/equal — checked #$3,(a3)
Loop_Examine_ExNextLoop:
	addq.l   #$1,Var_CurrentFileIndex.l                   ; Increment Var_CurrentFileIndex.l by one
	rts                                                   ; Return to caller
Loc_Examine_Error:
	move.b   #$5b,$21(a3)                                 ; Load 91 ($5b) into $21(a3)
	move.l   #$6469725d,$22(a3)                           ; Load 1684632157 ($6469725d) into $22(a3)
	clr.b    $26(a3)                                      ; Clear offset $26(a3) to zero
	bra.b    Loop_Examine_ExNextLoop                      ; Jump to Loop_Examine_ExNextLoop — examine ex next loop
Loc_Examine_Done:
	subq.l   #$1,Var_CurrentFileIndex.l                   ; Decrement Var_CurrentFileIndex.l by one
	bsr.b    Func_SortFloppyDirEntries                    ; Call Func_SortFloppyDirEntries — sort floppy dir entries
Loop_Examine_DoneDelay:
	rts                                                   ; Return to caller
Loc_Examine_Failed:
	move.l   (a7)+,d1                                     ; Restore d1 from stack
	beq.b    Loop_Examine_DoneDelay                       ; Examine done delay if zero/equal
	movea.l  Var_DOSBase(pc),a6                           ; Load dos.library base pointer
	jmp      _LVOUnLock(a6)                               ; Release the locked directory handle
Func_SortFloppyDirEntries:
	move.l   Var_CurrentFileIndex(pc),d0                  ; Load current file index into d0
	subq.l   #$1,d0                                       ; Decrement d0 by one
	beq.b    Loc_Examine_SortDone                         ; Examine sort done if zero/equal — checked counter after subq.l
	bmi.b    Loc_Examine_SortDone                         ; Examine sort done if minus (negative sign bit set)
	movea.l  Var_ScreenChunkyBuffer(pc),a0                ; Load screen chunky pixel buffer into a0
	lea      $28(a0),a0                                   ; Get address at offset $28 from a0
	movea.l  a0,a1                                        ; Pass screen chunky pixel buffer in a1
Loop_Examine_SortOuter:
	move.l   d0,d1                                        ; Copy return value to d1
Loop_Examine_SortInner:
	move.l   (a0),d2                                      ; Load value from (a0) into d2
	cmp.l    $28(a1),d2                                   ; Compare $28(a1) with d2
	bcc.b    Loc_Examine_Exit                             ; Examine exit if carry clear (greater or equal) — checked $28(a1),d2
Loop_Examine_CompareLoop:
	lea      $28(a1),a1                                   ; Get address at offset $28 from a1
	subq.w   #$1,d1                                       ; Decrement d1 by one
	bne.b    Loop_Examine_SortInner                       ; Examine sort inner if non-zero/not equal — checked counter after subq.w
	lea      $28(a0),a0                                   ; Get address at offset $28 from a0
	movea.l  a0,a1                                        ; Copy a0 to a1
	subq.w   #$1,d0                                       ; Decrement d0 by one
	bne.b    Loop_Examine_SortOuter                       ; Examine sort outer if non-zero/not equal — checked counter after subq.w
Loc_Examine_SortDone:
	rts                                                   ; Return to caller
Loc_Examine_Exit:
	moveq    #$24,d3                                      ; Set d3 to 36 ($24)
Loop_Examine_Sorted:
	move.l   (a0,d3.l),-(a7)                              ; Copy register or memory value
	move.l   $28(a1,d3.l),(a0,d3.l)                       ; Copy register or memory value
	move.l   (a7)+,$28(a1,d3.l)                           ; Copy register or memory value
	subq.b   #$4,d3                                       ; Subtract 4 ($4) from d3
	bcc.b    Loop_Examine_Sorted                          ; Examine sorted if carry clear (greater or equal)
	bra.b    Loop_Examine_CompareLoop                     ; Jump to Loop_Examine_CompareLoop — examine compare loop
Str_GfxLibName:
	dc.b "graphics.library"
	ds.b     1
Str_IntuitionLibName:
	dc.b "intuition.library"
	ds.b     1
Str_DOSLibName:
	dc.b "dos.library"
	ds.b     1
Str_TrackdiskDevice:
	dc.b "trackdisk.device"
	ds.b     1
	dc.b "mathffp.library"
	ds.b     1
Var_MenuID_Selected:
	ds.b     1

Var_MenuSubID_Selected:
	dc.b $70
Var_GfxBase:
	ds.l     1                              ; graphics.library base pointer
Var_IntuitionBase:
	ds.l     1                              ; intuition.library base pointer
Var_DOSBase:
	ds.l     1                              ; dos.library base pointer
	ds.l     1                              ; Reserved/padding longword
Var_DiskUnit:
	ds.l     1                              ; Disk Unit
Var_MainWindowPointer:
	ds.l     1                              ; Main Window Pointer
Var_DiskInfoWindowPointer:
	ds.l     1                              ; Disk Info Window Pointer
Var_ViewPort:
	ds.l     1                              ; Active custom screen ViewPort pointer
Table_Color0:
	dc.l     0,3,5,5                        ; Screen color index 0 definition: (color_index, r, g, b)
Table_Color1:
	dc.l     1,$0e,$0d,$0d                  ; Screen color index 1 definition: (color_index, r, g, b)
Table_Color2:
	dc.l     2,0,0,0                        ; Screen color index 2 definition: (color_index, r, g, b)
Table_Color3:
	dc.l     3,$0a,9,8                      ; Screen color index 3 definition: (color_index, r, g, b)
Var_ChunkyBuffer40:
	ds.l     1                              ; Allocated 40-byte chunky pixel conversion workspace
Var_ScreenChunkyBuffer:
	ds.l     1                              ; Allocated custom screen dynamic chunky render buffer
Var_ViewportBuffer:
	ds.l     1                              ; Allocated ViewPort dynamic copper assembly workspace
Var_FloppyDataBuffer:
	ds.l     1                              ; Floppy Data Buffer
Var_Screen:
	ds.l     1                              ; Opened custom screen pointer
Var_FloppyBufferEnd:
	ds.l     1                              ; Floppy Buffer End
Var_FloppyIOSize:
	ds.l     1                              ; Floppy IOSize
Var_FloppyTotalSize:
	ds.l     1                              ; Floppy Total Size
Var_Window_Work:
	ds.l     1                              ; Window_Work
Var_Window:
	ds.l     1                              ; Opened custom window pointer
Var_ProgressWindowPointer:
	ds.l     1                              ; Progress Window Pointer
Var_DialogWindowPointer:
	ds.l     1                              ; Dialog Window Pointer
Var_StatusWindowPointer:
	ds.l     1                              ; Status Window Pointer
Var_DiskInfoWinPointer:
	ds.l     1                              ; Disk Info Win Pointer
Var_FloppyIOOffset:
	ds.l     1                              ; Floppy IOOffset
Var_FloppyRemainingBytes:
	ds.l     1                              ; Floppy Remaining Bytes
Var_FloppySectorsPerTrack:
	ds.l     1                              ; Floppy Sectors Per Track
Var_FloppyTrackIndex:
	ds.l     1                              ; Floppy Track Index
Var_DiskState:
	ds.l     1                              ; Disk State
Var_DiskDriveType:
	ds.l     1                              ; Disk Drive Type
Var_LastIntuiMessage:
	ds.l     1                              ; Last Intui Message
Var_DirectoryLock:
	ds.l     1                              ; Directory Lock
Var_DirectoryBufferPointer:
	ds.l     1                              ; Directory Buffer Pointer
Var_DirectoryBufferSize:
	ds.l     1                              ; Directory Buffer Size
Var_CurrentFileIndex:
	ds.l     1                              ; Current File Index
Var_DirectoryEntryCount:
	ds.l     1                              ; Directory Entry Count
Var_FIBPointer:
	ds.l     1                              ; FIBPointer
Var_FileListBufferPointer:
	ds.l     1                              ; File List Buffer Pointer
Var_FileListBufferSize:
	ds.l     1                              ; File List Buffer Size
Var_FastMemBypassFlag:
	ds.b     1

Var_RleFilterToggleFlag:
	ds.b     1

Var_ProStubToggleFlag:
	ds.b     1

Var_StatusUpdateFlag:
	ds.b     1

Var_StatusErrorFlag:
	ds.b     1

Var_OperationCancelledFlag:
	ds.b     1

Var_UnusedWorkspace:
	ds.l     1

Var_TempLong:
	ds.l     1

Var_PayloadBuffer:
	ds.l     1

Var_PayloadSize:
	ds.l     1

Var_FileHandle:
	ds.l     1

Var_TempFileHandle:
	ds.l     1

Var_TotalHunkCount:
	ds.w     1

Var_PayloadBufferSize:
	ds.l     1

Var_DestBufferPointer:
	ds.l     1                              ; Pointer to destination hunk buffer
Var_HunkLoad_AllocPtr:
	ds.l     1                              ; Pointer to allocated temporary block
Var_HunkLoad_AllocSz:
	ds.l     1                              ; Size of allocated temporary block
Var_FileSize:
	ds.l     1

Var_ReadBytesSize:
	ds.l     1

Var_RemainingHunkBytes:
	ds.l     1

Var_ExpectedHunkType:
	ds.w     1

	dc.w    $03F2
Var_NopOpcode:
	dc.w    $4E71
Var_FloppyTrackLimit_181:
	dc.b    "181",0
Var_FloppyTrackLimit_701:
	dc.b    "701",0
Str_Const_1501:
	dc.b    "1501",0
Str_Const_11101:
	dc.b    "11101",0
Str_SourceDestInfo:
	dc.b    "Source:                Destination:",0
Str_CrunchBreakoff:
	dc.b    "Crunching breaking off!",0
Str_StopCrunchingPrompt:
	dc.b    "Both Buttons To Stop Crunching !",0
	dc.b    "% Left",0
Str_Phase1Progress:
	dc.b    "Phase 1 in progres :",0
	dc.b    "Phase 2 in progres :",0
Str_FileReadyToSave:
	dc.b    "File ready to save !",0
Str_FileSaved:
	dc.b "File saved !"
	ds.b     1
Str_UserBreak:
	dc.b "User break !"
	ds.b     1
Str_OriginalLength:
	dc.b "Original length    :"
	ds.b     1
Str_Err_CouldNotWrite:
	dc.b "Could not write file !"
	ds.b     1
Str_Err_DeviceNotMounted:
	dc.b "Device Not Mounted !"
	ds.b     1
Str_FileDeleted:
	dc.b "File deleted !"
	ds.b     1
Str_Err_CouldNotOpen:
	dc.b "Could not open file !"
	ds.b     1
Str_BufferIsEmpty:
	dc.b "Buffer is now empty !"
	ds.b     1
Str_BufferIsEmptyRightNow:
	dc.b "Buffer is empty right now !"
	ds.b     1
Str_FileNotSaved:
	dc.b "File not saved !"
	ds.b     1
Str_Err_NotEnoughMemory:
	dc.b "Not enough memory !"
	ds.b     1
Str_Err_HunkTypeNotSupported:
	dc.b "Hunk_Type not supported !"
	ds.b     1
Str_HunkNumber:
	dc.b "Hunk_Number :"
	ds.b     1
Str_HunkLength:
	dc.b    "Length :",0
Str_LoadError:
	dc.b    "Load Error !",0
Str_HunkNr:
	dc.b    "Nr.:",0
Str_Err_FileNotFound:
	dc.b    "File Not Found Error !",0
Str_Err_FileNoLoadFile:
	dc.b    "File No Load File Error !",0
Var_TempDecrunchVar:
	ds.l     1

Str_HunkBreakOverlay:
	dc.b    "Hunk_Break  ",9,0
	dc.b    "Hunk_Overlay",9,0
	ds.b     14

Str_HunkHeaderEndDebug:
	dc.b    "Hunk_Header ",9,0
	dc.b    "Hunk_End    ",9,0
	dc.b    "Hunk_Debug  ",9,0
	dc.b    "Hunk_Symbol ",9,0
	dc.b    "Hunk_Ext    ",9,0
	dc.b    "Hunk_Reloc8 ",9,0
	dc.b    "Hunk_Reloc16",9,0
	dc.b    "Hunk_Reloc32",9,0
	dc.b    "Hunk_Bss    ",9,0
	dc.b    "Hunk_Data   ",9,0
	dc.b    "Hunk_Code   ",9,0
	dc.b    "Hunk_Name   ",9,0
	dc.b    "Hunk_Unit   ",9,0
Var_PrintFormattingZero:
	ds.b     1

Str_Menu_DoubleActionTitle:
	dc.b    "                ",$BB," Double Action ",$AB," V1.0",0
Str_Menu_CopyrightTristar:
	dc.b    "           Copyright ",$A9," by VINCE of TRISTAR !",0
Var_PrintFormattingSpace:
	ds.b     1

Str_Menu_TristarProduction:
	dc.b    "        This is a new quality production of the",0
Str_Menu_TristarManufactory:
	dc.b    "                 TRISTAR Manufactory.",0
Str_Menu_ToolsForFools:
	dc.b    "      Tools for fools, only for the fucking best,",0
Str_Menu_LamePeople:
	dc.b    "        Lame people should handle with care...",0
Str_Menu_AssembledDate:
	dc.b    "                 Assembled VII/MXM.",0
Var_PrintFormattingEnd:
	ds.w     1

Var_FormattedOutputString:
	ds.b     10
Var_FilePathBuffer:
	ds.b     120
Var_HeaderBuffer:
	ds.b     1024
Var_FileNameInput:
	ds.b     150
Var_FloppyOperationActive:
	ds.b     1

Var_FloppyTrackReady:
	ds.b     1

Var_FloppyIOReq:
	ds.b     80
Var_FloppyMsgPort:
	ds.b     32
Var_FloppyRetryCount:
	ds.w     1

	dc.b $03
	dc.b $F3
	ds.b     7
	dc.b $01
	ds.b     8
Var_FloppyFormatState:
	ds.b     6
	dc.b $03
	dc.b $E9
	ds.b     4
Var_FloppyDriveStatus:
	lea      $dff000,a3                                   ; Load Custom register base
	move.w   #$4000,$9a(a3)                               ; Disable INTENA
	move.w   #$0200,$96(a3)                               ; Disable DMACON
	lea      $bfd100,a1                                   ; Load CIA B PRA
	move.b   #$fd,(a1)                                    ; Motor on / select drive 0
	move.b   #$87,(a1)                                    ; Step/direction setup
	move.b   #$fd,(a1)                                    ; Re-assert
	bset     #1,$f01(a1)                                  ; Set CIAB PRB bit 1
Var_FloppyWriteBuffer:
	dc.b    $2E,$7A,$02,$2E,$41,$FA,$00,$18,$22,$7A,$02,$1E,"$I0<",$02,$15,$12
	dc.w     $D851,$C8FF,$FC41,$FA02,$1A4E,$D222,$7A01,$FC20
	dc.w     $3A01,$F290,$89B1,$C965,$3422,$D859,$8066,$FA60
	dc.b    $6E,$BB," Double Action v1.0 ",$A9," By VINCE of TRISTAR ",$AB,$D1,$C0,$D3,$C0,$23,$20,$59,$80,$66,$FA
	dc.b    "`6SF&",$06,$4D,$FA,$00,$06,$78,$08,$4E,$D4,$15,$06,$51,$CB,$FF,$F8
	dc.b    $4D,$FA,$00,$04,$60,$66,$4A,$06,"gP`Hx",$03,$4D,$FA,$00,$04,$4E,$D4
	dc.w     $5C46,$60D8,$780A,$4DFA,$FFD2,$4ED4,$7810,$60F6
	dc.w     $207A,$0172,$247A,$016A,$D5FA,$0180,$227A,$016C
	dc.w     $7E00,$2A20,$49FA,$00D4,$4BFA,$0032,$7400,$4DFA
	dc.w     $0006,$7803,$4ED4,$BC3C,$0006,$65A0,$6700,$0008
	dc.w     $4DFA,$003C,$4ED5,$4DFA,$0004,$4ED5,$BC3C,$0002
	dc.w     $6512,$670C,$4DFA,$0018,$7801,$4ED4,$7802,$4ED4
	dc.w     $7603,$6044,$7601,$4A06,$674E,$7809,$6052,$4A06
	dc.w     $6786,$4DFA,$0004,$60E0,$4A06,$6788,$608E,$BC3C
	dc.w     $0003,$656A,$4DFA,$0004,$4ED5,$BC3C,$0003,$655A
	dc.w     $4DFA,$0004,$4ED5,$BC3C,$0003,$654A,$7808,$760A
	dc.w     $4DFA,$0004,$4ED4,$D646,$4DFA,$0004,$60AA,$4A06
	dc.w     $6706,$4DFA,$0012,$60A0,$7808,$7402,$6012,$780A
	dc.w     $343C,$0102,$600A,$4A06,$67F4,$780C,$343C,$0502
	dc.w     $4DFA,$0004,$4ED4,$DC82,$2C4A,$DDC6,$1526,$51CB
	dc.w     $FFFC,$6000,$FF4A,$7607,$60BC,$7604,$60B8,$7602
	dc.w     $BC3C,$0001,$65C2,$67C6,$60D0,$7C00,$6006,$E38D
	dc.b    $67,$08,$E3,$56,$51,$CC,$FF,$F8,$4E,$D6,$B1,$C9,$67,$0A,"* 7E",$01
	dc.w     $80E3,$9560
	dc.b     $EA
	dc.b '(K"z'
	ds.b     1
	dc.w     $6424
	dc.b     $7A
	ds.b     1
	dc.w     $6A26,$4AD5
	dc.b     $FA
	ds.b     1
	dc.w     $7416,$DAB3,$CB64,$FA20
	dc.b     $7A
	ds.b     1
	dc.w     $5022
	dc.b     $7A
	ds.b     1
	dc.w     $5624
	dc.b     $7A
	ds.b     1
	dc.w     $561A
	dc.b     $3A
	ds.b     1
	dc.w     $4C1C
	dc.b     $3A
	ds.b     1
	dc.w     $4910,$20B1,$C967,$0E65,$0EB0,$0567,$1CB0,$0667
	dc.w     $2815
	ds.b     1
	dc.w     $60EC
	dc.b     $15
	ds.b     1
	dc.w     $247A
	ds.b     1
	dc.w     $3839
	dc.b     $7C
Var_DirectoryBuffer:
	dc.b     $82
	ds.b     2
	dc.w     $9639
	dc.b     $7C
Var_DirectoryBufferEnd:
	dc.b     $C0
	ds.b     2
	dc.w     $9A4E,$D214,$2012,$2015,$0153,$0266,$FA39,$4101
	dc.w     $8060,$C872
	ds.b     1
	dc.w     $1420,$60EE
Var_DirectoryEntryHeader:
	ds.l     1

Var_DirectoryEntrySize:
	ds.l     1

Var_DirectoryEntryType:
	ds.b     1

Var_DirectoryEntryProtection:
	ds.b     1

Var_DirectoryEntryComment:
	ds.b     8
Var_DirectoryEntryDate:
	ds.l     1

Var_DirectoryEntryTime:
	ds.l     1

Var_DirectoryEntryBuffer:
	ds.l     1

Var_DirectoryEntryBufferEnd:
	ds.l     1

Var_DirectoryEntryLock:
	ds.w     1

	dc.w     $03F3
	ds.b     7
	dc.b     $01
	ds.b     8
Var_DirectoryEntryFIB:
	ds.b     6
	dc.w     $03E9
	ds.b     4
Var_DirectoryEntryPath:
	dc.w     $47F9
	ds.b     1
	dc.w     $DFF0
	ds.b     1
	dc.w     $377C
	dc.b     $40
	ds.b     2
	dc.w     $9A37,$7C02
	ds.b     2
	dc.w     $9643
	dc.b     $F9
	ds.b     1
	dc.w     $BFD1
	ds.b     1
	dc.w     $12BC
	ds.b     1
	dc.w     $FD12
	dc.b     $BC
	ds.b     1
	dc.w     $8712
	dc.b     $BC
	ds.b     1
	dc.w     $FD08
	dc.b     $E9
	ds.b     1
	dc.w     $010F
	dc.b     $01
Var_DirectoryEntryName:
	dc.w     $2E7A,$021E,$41FA
	ds.b     1
	dc.w     $1822,$7A02
	dc.b     $0E
	dc.b "$I0<"
	dc.w     $0205,$12D8,$51C8,$FFFC,$41FA,$020A,$4ED2,$227A
	dc.w     $01EC,$203A,$01E2,$9089,$B1C9,$6534,$22D8,$5980
	dc.w     $66FA,$6070
	dc.b     $BB
	dc.b " Double Action v1.0 "
	dc.b     $A9
	dc.b " By VINCE of TRISTAR "
	dc.w     $ABD1,$C0D3,$C023,$2059,$8066
	dc.b     $FA
	dc.b "`8SF&"
	dc.w     $064D
	dc.b     $FA
	ds.b     1
	dc.w     $0678,$084E,$D415,$0651,$CBFF,$F84D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$684A
	dc.b     $06
	dc.b "gR`Jx"
	dc.w     $034D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D406
	dc.b     $46
	ds.b     1
	dc.w     $0660,$D678,$0A4D,$FAFF,$D04E,$D478,$1060,$F620
	dc.w     $7A01,$6024,$7A01,$58D5,$FA01,$6E22,$7A01,$5A7E
	ds.b     1
	dc.w     $2A20,$49FA
	ds.b     1
	dc.w     $C24B
	dc.b     $FA
	ds.b     1
	dc.w     $3274
	ds.b     1
	dc.w     $4DFA
	ds.b     1
	dc.w     $0678,$034E,$D4BC
	dc.b     $3C
	ds.b     1
	dc.w     $0665,$9E67
	ds.b     2
	dc.w     $084D
	dc.b     $FA
	ds.b     1
	dc.w     $3A4E,$D54D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0265,$1267,$0C4D
	dc.b     $FA
	ds.b     1
	dc.w     $1678,$014E,$D478,$024E,$D476,$0360,$4C76,$014A
	dc.b     $06
	dc.b "gF`JJ"
	dc.w     $0667,$864D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$E24A,$0667,$8A60,$90BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$584D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$484D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$3878,$0876,$0A4D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D4D6,$464D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$AC4A,$0666,$0678,$0774,$0260,$0678,$0834
	dc.b     $3C
	ds.b     1
	dc.w     $824D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D4DC,$822C,$4ADD,$C615,$2651,$CBFF,$FC60
	ds.b     1
	dc.w     $FF5E,$7607,$60CE,$7604,$60CA,$7602,$BC3C
	ds.b     1
	dc.w     $0165,$CE67,$D276,$0360,$CE7C
	ds.b     1
	dc.w     $6006,$E38D,$6708,$E356,$51CC,$FFF8,$4ED6,$B1C9
	dc.w     $670A
	dc.b "* 7E"
	dc.w     $0180,$E395,$60EA
	dc.b '(K"z'
	ds.b     1
	dc.w     $6424
	dc.b     $7A
	ds.b     1
	dc.w     $6A26,$4AD5
	dc.b     $FA
	ds.b     1
	dc.w     $7416,$DAB3,$CB64,$FA20
	dc.b     $7A
	ds.b     1
	dc.w     $5022
	dc.b     $7A
	ds.b     1
	dc.w     $5624
	dc.b     $7A
	ds.b     1
	dc.w     $561A
	dc.b     $3A
	ds.b     1
	dc.w     $4C1C
	dc.b     $3A
	ds.b     1
	dc.w     $4910,$20B1,$C967,$0E65,$0EB0,$0567,$1CB0,$0667
	dc.w     $2815
	ds.b     1
	dc.w     $60EC
	dc.b     $15
	ds.b     1
	dc.w     $247A
	ds.b     1
	dc.w     $3839
	dc.b     $7C
Var_DiskInfo_TotalTracks:
	dc.b     $82
	ds.b     2
	dc.w     $9639
	dc.b     $7C
Var_DiskInfo_TotalSectors:
	dc.b     $C0
	ds.b     2
	dc.w     $9A4E,$D214,$2012,$2015,$0153,$0266,$FA39,$4101
	dc.w     $8060,$C872
	ds.b     1
	dc.w     $1420,$60EE
Var_DiskInfo_FreeSectors:
	ds.l     1

Var_DiskInfo_UsedSectors:
	ds.b     6
Var_DiskInfo_BytesPerSector:
	ds.b     24
Var_DiskInfo_DiskName:
	ds.w     1

	dc.w     $03F3
	ds.b     7
	dc.b     $01
	ds.b     8
Var_DiskInfo_VolumeLabel:
	ds.b     6
	dc.w     $03E9
	ds.b     4
	dc.w     $47F9
	ds.b     1
	dc.w     $DFF0
	ds.b     1
	dc.w     $377C
	dc.b     $40
	ds.b     2
	dc.w     $9A37,$7C02
	ds.b     2
	dc.w     $9643
	dc.b     $F9
	ds.b     1
	dc.w     $BFD1
	ds.b     1
	dc.w     $12BC
	ds.b     1
	dc.w     $FD12
	dc.b     $BC
	ds.b     1
	dc.w     $8712
	dc.b     $BC
	ds.b     1
	dc.w     $FD08
	dc.b     $E9
	ds.b     1
	dc.w     $010F
	dc.b     $01
Var_DiskInfo_VolumeDate:
	dc.w     $2E7A,$022E,$41FA
	ds.b     1
	dc.w     $1822,$7A02
	dc.b     $1E
	dc.b "$I0<"
	dc.w     $0215,$12D8,$51C8,$FFFC,$41FA,$021A,$4ED2,$227A
	dc.w     $01FC,$203A,$01F2,$9089,$B1C9,$6534,$22D8,$5980
	dc.w     $66FA,$6070
	dc.b     $BB
	dc.b " Double Action v1.0 "
	dc.b     $A9
	dc.b " By VINCE of TRISTAR "
	dc.w     $ABD1,$C0D3,$C023,$2059,$8066
	dc.b     $FA
	dc.b "`8SF&"
	dc.w     $064D
	dc.b     $FA
	ds.b     1
	dc.w     $0678,$084E,$D415,$0651,$CBFF,$F84D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$684A
	dc.b     $06
	dc.b "gR`Jx"
	dc.w     $034D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D406
	dc.b     $46
	ds.b     1
	dc.w     $0660,$D678,$0A4D,$FAFF,$D04E,$D478,$1060,$F620
	dc.w     $7A01,$7024,$7A01,$68D5,$FA01,$7E22,$7A01,$6A7E
	ds.b     1
	dc.w     $2A20,$49FA
	ds.b     1
	dc.w     $D24B
	dc.b     $FA
	ds.b     1
	dc.w     $3274
	ds.b     1
	dc.w     $4DFA
	ds.b     1
	dc.w     $0678,$034E,$D4BC
	dc.b     $3C
	ds.b     1
	dc.w     $0665,$9E67
	ds.b     2
	dc.w     $084D
	dc.b     $FA
	ds.b     1
	dc.w     $3A4E,$D54D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0265,$1267,$0C4D
	dc.b     $FA
	ds.b     1
	dc.w     $1678,$014E,$D478,$024E,$D476,$0360,$4276,$014A
	dc.b     $06
	dc.b "gL`PJ"
	dc.w     $0667,$864D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$E24A,$0667,$8A60,$90BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$6A4D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$5A4D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$4A78,$0876,$0A4D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D4D6,$464D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$AC4A,$0667,$064D
	dc.b     $FA
	ds.b     1
	dc.w     $1260,$A278,$0874,$0260,$1278,$0934,$3C01,$0260
	dc.w     $0A4A,$0667,$F478,$0A34,$3C03,$024D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D4DC,$822C,$4ADD,$C615,$2651,$CBFF,$FC60
	ds.b     1
	dc.w     $FF4C,$7607,$60BC,$7604,$60B8,$7602,$BC3C
	ds.b     1
	dc.w     $0165,$C267,$C660,$D07C
	ds.b     1
	dc.w     $6006,$E38D,$6708,$E356,$51CC,$FFF8,$4ED6,$B1C9
	dc.w     $670A
	dc.b "* 7E"
	dc.w     $0180,$E395,$60EA
	dc.b '(K"z'
	ds.b     1
	dc.w     $6424
	dc.b     $7A
	ds.b     1
	dc.w     $6A26,$4AD5
	dc.b     $FA
	ds.b     1
	dc.w     $7416,$DAB3,$CB64,$FA20
	dc.b     $7A
	ds.b     1
	dc.w     $5022
	dc.b     $7A
	ds.b     1
	dc.w     $5624
	dc.b     $7A
	ds.b     1
	dc.w     $561A
	dc.b     $3A
	ds.b     1
	dc.w     $4C1C
	dc.b     $3A
	ds.b     1
	dc.w     $4910,$20B1,$C967,$0E65,$0EB0,$0567,$1CB0,$0667
	dc.w     $2815
	ds.b     1
	dc.w     $60EC
	dc.b     $15
	ds.b     1
	dc.w     $247A
	ds.b     1
	dc.w     $3839
	dc.b     $7C
Var_DiskInfo_VolumeTime:
	dc.b     $82
	ds.b     2
	dc.w     $9639
	dc.b     $7C
Var_DiskInfo_FIB:
	dc.b     $C0
	ds.b     2
	dc.w     $9A4E,$D214,$2012,$2015,$0153,$0266,$FA39,$4101
	dc.w     $8060,$C872
	ds.b     1
	dc.w     $1420,$60EE
Var_DiskInfo_FIBEnd:
	ds.l     1

Var_DiskInfo_FIBLock:
	ds.b     6
Var_DiskInfo_FIBName:
	ds.b     24
Var_DiskInfo_FIBType:
	ds.w     1

	dc.w     $03F3
	ds.b     7
	dc.b     $01
	ds.b     8
Var_DiskInfo_FIBSz:
	ds.b     6
	dc.w     $03E9
	ds.b     4
	dc.w     $47F9
	ds.b     1
	dc.w     $DFF0
	ds.b     1
	dc.w     $377C
	dc.b     $40
	ds.b     2
	dc.w     $9A37,$7C02
	ds.b     2
	dc.w     $9643
	dc.b     $F9
	ds.b     1
	dc.w     $BFD1
	ds.b     1
	dc.w     $12BC
	ds.b     1
	dc.w     $FD12
	dc.b     $BC
	ds.b     1
	dc.w     $8712
	dc.b     $BC
	ds.b     1
	dc.w     $FD08
	dc.b     $E9
	ds.b     1
	dc.w     $010F
	dc.b     $01
Var_DiskInfo_FIBProt:
	dc.w     $2E7A,$0238,$41FA
	ds.b     1
	dc.w     $1822,$7A02
	dc.b "($I0<"
	dc.w     $021F,$12D8,$51C8,$FFFC,$41FA,$0224,$4ED2,$227A
	dc.w     $0206,$203A,$01FC,$9089,$B1C9,$6534,$22D8,$5980
	dc.w     $66FA,$6070
	dc.b     $BB
	dc.b " Double Action v1.0 "
	dc.b     $A9
	dc.b " By VINCE of TRISTAR "
	dc.w     $ABD1,$C0D3,$C023,$2059,$8066
	dc.b     $FA
	dc.b "`8SF&"
	dc.w     $064D
	dc.b     $FA
	ds.b     1
	dc.w     $0678,$084E,$D415,$0651,$CBFF,$F84D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$684A
	dc.b     $06
	dc.b "gR`Jx"
	dc.w     $034D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D406
	dc.b     $46
	ds.b     1
	dc.w     $0660,$D678,$0A4D,$FAFF,$D04E,$D478,$1060,$F620
	dc.w     $7A01,$7A24,$7A01,$72D5,$FA01,$8822,$7A01,$747E
	ds.b     1
	dc.w     $2A20,$49FA
	ds.b     1
	dc.w     $DC4B
	dc.b     $FA
	ds.b     1
	dc.w     $3274
	ds.b     1
	dc.w     $4DFA
	ds.b     1
	dc.w     $0678,$034E,$D4BC
	dc.b     $3C
	ds.b     1
	dc.w     $0665,$9E67
	ds.b     2
	dc.w     $084D
	dc.b     $FA
	ds.b     1
	dc.w     $3C4E,$D54D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0265,$1267,$0C4D
	dc.b     $FA
	ds.b     1
	dc.w     $1878,$014E,$D478,$024E,$D476,$0360,$4476,$014A
	dc.w     $0667,$4E78,$0960,$524A,$0667,$844D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$E04A,$0667,$8860,$8EBC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$6A4D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$5A4D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D5BC
	dc.b     $3C
	ds.b     1
	dc.w     $0365,$4A78,$0876,$0A4D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D4D6,$464D
	dc.b     $FA
	ds.b     1
	dc.w     $0460,$AA4A,$0667,$064D
	dc.b     $FA
	ds.b     1
	dc.w     $1260,$A078,$0874,$0260,$1278,$0C34,$3C01,$0260
	dc.w     $0A4A,$0667,$F478,$1034,$3C11,$024D
	dc.b     $FA
	ds.b     1
	dc.w     $044E,$D4DC,$822C,$4ADD,$C615,$2651,$CBFF,$FC60
	ds.b     1
	dc.w     $FF4A,$7607,$60BC,$7604,$60B8,$780B,$7602,$BC3C
	ds.b     1
	dc.w     $0165,$C067,$C678,$0E34,$3C09,$0260,$CE7C
	ds.b     1
	dc.w     $6006,$E38D,$6708,$E356,$51CC,$FFF8,$4ED6,$B1C9
	dc.w     $670A
	dc.b "* 7E"
	dc.w     $0180,$E395,$60EA
	dc.b '(K"z'
	ds.b     1
	dc.w     $6424
	dc.b     $7A
	ds.b     1
	dc.w     $6A26,$4AD5
	dc.b     $FA
	ds.b     1
	dc.w     $7416,$DAB3,$CB64,$FA20
	dc.b     $7A
	ds.b     1
	dc.w     $5022
	dc.b     $7A
	ds.b     1
	dc.w     $5624
	dc.b     $7A
	ds.b     1
	dc.w     $561A
	dc.b     $3A
	ds.b     1
	dc.w     $4C1C
	dc.b     $3A
	ds.b     1
	dc.w     $4910,$20B1,$C967,$0E65,$0EB0,$0567,$1CB0,$0667
	dc.w     $2815
	ds.b     1
	dc.w     $60EC
	dc.b     $15
	ds.b     1
	dc.w     $247A
	ds.b     1
	dc.w     $3839
	dc.b     $7C
Var_DiskInfo_FIBComment:
	dc.b     $82
	ds.b     2
	dc.w     $9639
	dc.b     $7C
Var_DiskInfo_FIBDate:
	dc.b     $C0
	ds.b     2
	dc.w     $9A4E,$D214,$2012,$2015,$0153,$0266,$FA39,$4101
	dc.w     $8060,$C872
	ds.b     1
	dc.w     $1420,$60EE
Var_DiskInfo_FIBTime:
	ds.l     1

Var_DiskInfo_FIBPath:
	ds.b     6
Var_DiskInfo_FIBSect:
	ds.b     24
Var_DiskInfo_FIBCyl:
	ds.l     1

	dc.w     $0280
	dc.b     $01
	ds.b     2
	dc.w     $0201,$0280
	ds.b     2
	dc.b     $0F
	ds.b     2
	dc.w     $6C6A
	ds.b     2
	dc.w     $4EB2
	ds.b     8
Str_ScreenTitle:
	dc.b     $BB
	dc.b " Double Action V1.0 "
	dc.b     $AB
	dc.b "          Chip:"
Str_Label_FastMem:
	dc.b "            Fast:"
Str_Label_Spaces:
	dc.b "            "
	ds.b     2
Var_DialogWindowStruct:
	ds.l     1

	dc.w     $01C9
	ds.b     1
	dc.w     $FD03
	dc.b     $02
	ds.b     1
	dc.w     $0182
	dc.b     $68
	ds.b     2
	dc.w     $100E
	ds.b     2
	dc.w     $5A72
	ds.b     4
Var_DialogTitlePointer:
	ds.l     1

Var_DialogITextPointer:
	ds.b     9
	dc.b     $0A
	ds.b     1
	dc.w     $0A01
	dc.b     $C9
	ds.b     1
	dc.b     $FD
	ds.b     1
	dc.b     $0F
Str_Dialog_LoadFile:
	dc.b "Load File..."
	ds.b     1
Str_Dialog_SaveFile:
	dc.b "Save File..."
	ds.b     1
Str_Dialog_DeleteFile:
	dc.b "Delete File..."
	ds.b     1
Str_Dialog_RelocateFile:
	dc.b "Relocate File..."
	ds.b     1
Var_DialogWindowLeft:
	ds.b     1

	dc.b     $50
	ds.b     1
	dc.w     $1E01
	dc.b     $B8
	ds.b     1
	dc.w     $AA01
	dc.b     $02
	ds.b     2
	dc.b     $01
	ds.b     3
	dc.b     $11
	ds.b     13
Var_DialogWindowTop:
	ds.b     9
	dc.b     $0A
	ds.b     1
	dc.w     $0A01
	dc.b     $B8
	ds.b     1
	dc.b     $AA
	ds.b     1
	dc.b     $0F
Var_ProgressWindowStruct:
	ds.b     1

	dc.b     $50
	ds.b     1
	dc.w     $1E01
	dc.b     $B8
	ds.b     1
	dc.w     $A001
	dc.b     $02
	ds.b     1
	dc.w     $0182
	dc.b     $68
	ds.b     2
	dc.w     $100E
	ds.b     2
	dc.w     $50CE
	ds.b     6
	dc.w     $4FC0
Var_ProgressWindowLeft:
	ds.b     9
	dc.b     $0A
	ds.b     1
	dc.w     $0A01
	dc.b     $B8
	ds.b     1
	dc.b     $A0
	ds.b     1
	dc.b     $0F
	dc.b "Cruncher Control Window"
	ds.b     1
Var_StatusWindowStruct:
	ds.b     1

	dc.b     $50
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $B4
	ds.b     1
	dc.w     $2801
	dc.b     $02
	ds.b     1
	dc.w     $0182
	dc.b     $68
	ds.b     2
	dc.w     $100E
	ds.b     2
	dc.w     $56C0
	ds.b     6
	dc.w     $5008
Var_StatusWindowLeft:
	ds.b     9
	dc.b     $0A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $64
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $0F
	dc.b "Fix to:"
	ds.b     1
Var_DiskInfoWindowStruct:
	dc.w     $0148
	ds.b     2
	dc.w     $0106
	ds.b     1
	dc.w     $0A01
	dc.b     $02
	ds.b     2
	dc.b     $03
	ds.b     3
	dc.w     $100E
	ds.b     10
	dc.w     $5040
	ds.b     9
	dc.b     $0A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $C8
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.w     $01BB
	dc.b " Double Action V1.0 "
	dc.b     $AB
	ds.b     2
Var_Window_WorkStruct:
	ds.b     1

	dc.b     $50
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $B4
	ds.b     1
	dc.w     $6401
	dc.b     $02
	ds.b     1
	dc.w     $0182
	dc.b     $68
	ds.b     2
	dc.w     $100E
	ds.b     2
	dc.w     $5724
	ds.b     6
	dc.w     $5088
Var_Window_WorkTitle:
	ds.b     9
	dc.b     $0A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $64
	ds.b     1
	dc.b     $64
	ds.b     1
	dc.b     $0F
	dc.b "Readbytes"
	ds.b     1
Var_Window_WorkIText:
	ds.b     1

	dc.b     $50
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $B4
	ds.b     1
	dc.w     $5001
	dc.b     $02
	ds.b     1
	dc.w     $0182
	dc.b     $68
	ds.b     2
	dc.w     $100E
	ds.b     2
	dc.w     $58E6
	ds.b     6
	dc.w     $50C2
Var_Window_WorkLeft:
	ds.b     9
	dc.b     $0A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $64
	ds.b     1
	dc.b     $5A
	ds.b     1
	dc.b     $0F
	dc.b "Writebytes"
	ds.b     4
	dc.w     $51BE
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $519A
	ds.b     6
	dc.w     $50FC
	ds.b     16
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $5110
	ds.b     2
	dc.w     $5116
	dc.b "$181"
	ds.b     2
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.w     $20FF
	dc.b     $F4
	ds.b     6
	dc.w     $512A
	ds.b     2
	dc.b "Q:Crunching Depth"
	ds.b     1
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.w     $38FF
	dc.b     $E4
	ds.b     6
	dc.w     $514E
	ds.b     2
	dc.b "QXCruncher"
	ds.b     2
	dc.w     $0102
	ds.b     1
	dc.w     $0101,$18FF
	dc.b     $E4
	ds.b     6
	dc.w     $516C
	ds.b     2
	dc.b "QvCrunched"
	ds.b     2
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.w     $91FF
	dc.b     $D8
	ds.b     6
	dc.w     $518A
	ds.b     4
	dc.b "Control Window"
	ds.b     2
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $51AA
	ds.b     9
	dc.b     $2D
	ds.b     3
	dc.b     $2D
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $522A
	ds.b     1
	dc.b     $37
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5206
	ds.b     6
	dc.w     $51EC
	ds.b     11
	dc.b     $01
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.b     $52
	ds.b     5
	dc.b "$701"
	ds.b     2
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5216
	ds.b     9
	dc.b     $2D
	ds.b     3
	dc.b     $2D
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $5296
	ds.b     1
	dc.b     $64
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $31
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5272
	ds.b     6
	dc.w     $5258
	ds.b     11
	dc.b     $02
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $526C
	ds.b     4
	dc.b "$1501"
	ds.b     1
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5282
	ds.b     9
	dc.b     $36
	ds.b     3
	dc.b     $36
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $530C
	ds.b     1
	dc.b     $96
	ds.b     1
	dc.b     $8C
	ds.b     1
	dc.b     $95
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $52E8
	ds.b     6
	dc.w     $52C4
	ds.b     11
	dc.b     $03
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $52D8
	ds.b     4
	dc.b "Start Crunching"
	ds.b     1
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $52F8
	ds.b     9
	dc.b     $9A
	ds.b     3
	dc.b     $9A
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $537A
	ds.b     1
	dc.b     $9A
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $39
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5356
	ds.b     6
	dc.w     $533A
	ds.b     11
	dc.b     $0B
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $534E
	ds.b     4
	dc.b "$11101"
	ds.b     2
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5366
	ds.b     9
	dc.b     $3E
	ds.b     3
	dc.b     $3E
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     4
Var_ProgressWindowTop:
	ds.w     1

	dc.w     $5420
	ds.b     1
	dc.b     $5E
	ds.b     1
	dc.b     $58
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $53A8
	ds.b     6
	dc.w     $53EA
	ds.b     3
	dc.b     $04
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $B4
	ds.b     8
	dc.w     $53BC
	ds.b     4
	dc.b "Fix to :$"
	ds.b     1
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $53D6
	ds.b     9
	dc.b     $48
	ds.b     3
	dc.b     $48
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $540E
	ds.b     2
	dc.w     $5417
	ds.b     3
	dc.b     $09
	ds.b     24
Var_ProgressWindowWidth:
	ds.b     18
Var_ProgressWindowHeight:
	ds.w     1

	dc.w     $54A6,$015E
	ds.b     1
	dc.b     $30
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $544E
	ds.b     6
	dc.w     $5470
	ds.b     3
	dc.b     $05
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $9C
	ds.b     8
	dc.w     $5462
	ds.b     4
	dc.b "Decruncher:$"
	ds.b     4
	dc.w     $5494
	ds.b     2
	dc.w     $549D
	ds.b     3
	dc.b     $09
	ds.b     24
Var_StatusWindowTop:
	ds.b     18
Var_StatusWindowWidth:
	ds.w     1

	dc.w     $552C,$015E
	ds.b     1
	dc.b     $3E
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $54D4
	ds.b     6
	dc.w     $54F6
	ds.b     3
	dc.b     $06
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $9C
	ds.b     8
	dc.w     $54E8
	ds.b     4
	dc.b "Decrunched:$"
	ds.b     4
	dc.w     $551A
	ds.b     2
	dc.w     $5523
	ds.b     3
	dc.b     $09
	ds.b     24
Var_StatusWindowHeight:
	ds.b     18
Var_DiskInfoWindowLeft:
	ds.w     1

	dc.w     $55B2,$015E
	ds.b     1
	dc.b     $4C
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $555A
	ds.b     6
	dc.w     $557C
	ds.b     3
	dc.b     $07
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $9C
	ds.b     8
	dc.w     $556E
	ds.b     4
	dc.b "Jump in at:$"
	ds.b     4
	dc.w     $55A0
	ds.b     2
	dc.w     $55A9
	ds.b     3
	dc.b     $09
	ds.b     24
Var_DiskInfoWindowTop:
	ds.b     18
Var_DiskInfoWindowWidth:
	ds.w     1

	dc.w     $5638,$015E
	ds.b     1
	dc.b     $5A
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $55E0
	ds.b     6
	dc.w     $5602
	ds.b     3
	dc.b     $08
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $9C
	ds.b     8
	dc.w     $55F4
	ds.b     4
	dc.b "Stack-ptr.:$"
	ds.b     4
	dc.w     $5626
	ds.b     2
	dc.w     $562F
	ds.b     3
	dc.b     $09
	ds.b     24
Var_DiskInfoWindowHeight:
	ds.b     18
Var_Window_WorkTop:
	ds.w     1

	dc.w     $59E8,$015E
	ds.b     1
	dc.b     $68
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $5666
	ds.b     6
	dc.w     $568A
	ds.b     3
	dc.b     $09
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $8C
	ds.b     8
	dc.w     $567A
	ds.b     4
	dc.b "Sec.Distance:$"
	ds.b     4
	dc.w     $56AE
	ds.b     2
	dc.w     $56B7
	ds.b     3
	dc.b     $09
	ds.b     24
Var_Window_WorkWidth:
	ds.b     18
Var_Window_WorkHeight:
	ds.b     5
	dc.b     $5E
	ds.b     1
	dc.b     $14
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $53A8
	ds.b     6
	dc.w     $56EE
	ds.b     3
	dc.b     $0A
	ds.b     6
	dc.w     $5712
	ds.b     2
	dc.w     $571B
	ds.b     3
	dc.b     $09
	ds.b     24
Var_ProgressWindowIText:
	ds.b     18
Var_StatusWindowIText:
	ds.w     1

	dc.w     $5788
	ds.b     1
	dc.b     $5E
	ds.b     1
	dc.b     $14
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $57EC
	ds.b     6
	dc.w     $5752
	ds.b     3
	dc.b     $01
	ds.b     6
	dc.w     $5776
	ds.b     2
	dc.w     $577F
	ds.b     3
	dc.b     $09
	ds.b     24
Var_DiskInfoWindowIText:
	ds.b     18
Var_Window_WorkIText2:
	ds.w     1

	dc.w     $5890
	ds.b     1
	dc.b     $5E
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $580A
	ds.b     6
	dc.w     $57B6
	ds.b     3
	dc.b     $02
	ds.b     6
	dc.w     $57DA
	ds.b     2
	dc.w     $57E3
	ds.b     3
	dc.b     $09
	ds.b     24
Var_DialogWindowWidth:
	ds.b     18
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $B4
	ds.b     8
	dc.b     $58
	ds.b     5
	dc.b "Length :$"
	ds.b     1
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $B4
	ds.b     8
	dc.w     $581E
	ds.b     4
	dc.b "Offset :$"
	ds.b     1
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $AC
	ds.b     8
	dc.w     $583C
	ds.b     4
	dc.b "Drive Dfx:"
	ds.b     7
	dc.b     $46
	ds.b     1
	dc.b     $50
	ds.b     1
	dc.b     $31
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5272
	ds.b     6
	dc.w     $5876
	ds.b     16
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $588A
	ds.b     4
	dc.b "READ"
	ds.b     2
Var_DialogWindowHeight:
	ds.w     1

	dc.w     $5848
	ds.b     1
	dc.b     $5E
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $5828
	ds.b     6
	dc.w     $58BE
	ds.b     3
	dc.b     $03
	ds.b     6
	dc.w     $58E2
	ds.b     2
	dc.w     $58E4
	ds.b     3
	dc.b     $02
	ds.b     24
Var_DialogIText2:
	ds.l     1

Var_DialogIText3:
	ds.w     1

	dc.w     $594A
	ds.b     1
	dc.b     $5E
	ds.b     1
	dc.b     $14
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $580A
	ds.b     6
	dc.w     $5914
	ds.b     3
	dc.b     $01
	ds.b     6
	dc.w     $5938
	ds.b     2
	dc.w     $5941
	ds.b     3
	dc.b     $09
	ds.b     24
Var_DialogIText4:
	ds.b     18
Var_DialogIText5:
	ds.w     1

	dc.w     $59A0
	ds.b     1
	dc.b     $5E
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $53C6
	ds.b     6
	dc.w     $5828
	ds.b     6
	dc.w     $5978
	ds.b     3
	dc.b     $02
	ds.b     6
	dc.w     $599C
	ds.b     2
	dc.w     $599E
	ds.b     3
	dc.b     $02
	ds.b     24
Var_DialogIText6:
	ds.b     9
	dc.b     $46
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $31
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5272
	ds.b     6
	dc.w     $59CE
	ds.b     16
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $59E2
	ds.b     4
	dc.b "Write"
	ds.b     1
Var_DialogIText7:
	ds.b     5
	dc.b     $5E
	ds.b     1
	dc.b     $49
	ds.b     1
	dc.b     $38
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     10
	dc.w     $5A16
	ds.b     6
	dc.w     $5A42
	ds.b     3
	dc.b     $0A
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $B0
	ds.b     8
	dc.w     $5A2A
	ds.b     4
	dc.b "Scanning $      bytes."
	ds.b     4
	dc.w     $5A66
	ds.b     2
	dc.w     $5A6C
	ds.b     3
	dc.b     $06
	ds.b     24
Var_DialogIText8:
	ds.b     14
	dc.w     $5B3A
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.b     $1B
	ds.b     1
	dc.b     $34
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5B16
	ds.b     6
	dc.w     $5AA0
	ds.b     16
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $02
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $5AB4
	ds.b     2
	dc.w     $5ABC
	dc.b "Parent"
	ds.b     2
	dc.w     $0302
	ds.b     1
	dc.w     $01FF,$FDFF
	dc.b     $F3
	ds.b     6
	dc.w     $5AD0
	ds.b     2
	dc.w     $5ADA
	dc.b "Diskname:"
	ds.b     1
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.w     $CDFF
	dc.b     $F3
	ds.b     6
	dc.w     $5AEE
	ds.b     2
	dc.w     $5AFA
	dc.b "Directory:"
	ds.b     2
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $46
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $5B0E
	ds.b     4
	dc.b "Free :"
	ds.b     2
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5B26
	ds.b     9
	dc.b     $39
	ds.b     3
	dc.b     $39
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $5BC4,$0124
	ds.b     1
	dc.b     $1B
	ds.b     1
	dc.b     $98
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5BA0
	ds.b     6
	dc.w     $5B68
	ds.b     11
	dc.b     $01
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $0E
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $5B7C
	ds.b     4
Str_Menu_HideInfoFiles:
	dc.b "Hide .Info Files"
	ds.b     2
Str_Menu_ShowInfoFiles:
	dc.b "Show .Info Files"
	ds.b     2
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5BB0
	ds.b     9
	dc.b     $9D
	ds.b     3
	dc.b     $9D
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $5C1A,$0137
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $06
	ds.b     1
	dc.b     $03
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5BF2
	ds.b     2
	dc.w     $5C06
	ds.b     15
	dc.b     $02
	ds.b     9
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $02
	dc.l Packer_ProcessEntry
	dc.b     $03
	ds.b     10
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $02
	ds.b     3
	dc.w     $2803
	ds.b     7
	dc.w     $5C48,$01AF
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $06
	ds.b     1
	dc.b     $03
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5BF2
	ds.b     2
	dc.w     $5C06
	ds.b     15
	dc.b     $03
	ds.b     6
	dc.w     $5C9E,$0137
	ds.b     1
	dc.b     $C4
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $06
	ds.b     1
	dc.b     $03
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5C76
	ds.b     2
	dc.w     $5C8A
	ds.b     15
	dc.b     $04
	ds.b     9
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $02
	ds.b     3
	dc.w     $5003
	ds.b     10
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $02
	ds.b     3
	dc.w     $7803
	ds.b     7
	dc.w     $5CCC,$01AF
	ds.b     1
	dc.b     $C4
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $06
	ds.b     1
	dc.b     $03
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5C76
	ds.b     2
	dc.w     $5C8A
	ds.b     15
	dc.b     $05
	ds.b     6
	dc.w     $5D5A
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.b     $EE
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5D12
	ds.b     6
	dc.w     $5CFA
	ds.b     11
	dc.b     $06
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $5D0E
	ds.b     4
	dc.w     $4F6B
	dc.b     $21
	ds.b     1
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5D22
	ds.b     2
	dc.w     $5D36
	ds.b     5
	dc.b     $2D
	ds.b     3
	dc.b     $2D
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     4
	dc.w     $FFFD,$FF3A,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5D46
	ds.b     8
	dc.w     $012E
	ds.b     2
	dc.w     $012E
	ds.b     1
	dc.b     $A5
	ds.b     3
	dc.b     $A5
	ds.b     6
	dc.w     $5DC8
	ds.b     1
	dc.b     $BD
	ds.b     1
	dc.b     $EE
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5DA4
	ds.b     6
	dc.w     $5D88
	ds.b     11
	dc.b     $07
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $02
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $5D9C
	ds.b     4
	dc.b "Get Dir"
	ds.b     1
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5DB4
	ds.b     9
	dc.b     $41
	ds.b     3
	dc.b     $41
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $5E5C,$0171
	ds.b     1
	dc.b     $EE
	ds.b     1
	dc.b     $4C
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $5E14
	ds.b     6
	dc.w     $5DF6
	ds.b     11
	dc.b     $08
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $02
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $5E0A
	ds.b     4
	dc.b "Forget it"
	ds.b     1
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5E24
	ds.b     2
	dc.w     $5E38
	ds.b     5
	dc.b     $51
	ds.b     3
	dc.b     $51
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     4
	dc.w     $FFD6,$FF3A,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $5E48
	ds.b     9
	dc.b     $67
	ds.b     3
	dc.b     $67
	ds.b     1
	dc.b     $A5
	ds.b     3
	dc.b     $A5
	ds.b     6
	dc.w     $5E8A
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $2A01
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $14
	ds.b     6
	dc.w     $5EB8
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $3301
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $15
	ds.b     6
	dc.w     $5EE6
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $3C01
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $16
	ds.b     6
	dc.w     $5F14
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $4501
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $17
	ds.b     6
	dc.w     $5F42
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $4E01
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $18
	ds.b     6
	dc.w     $5F70
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $5701
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $19
	ds.b     6
	dc.w     $5F9E
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $6001
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $1A
	ds.b     6
	dc.w     $5FCC
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $6901
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $1B
	ds.b     6
	dc.w     $5FFA
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $7201
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $1C
	ds.b     6
	dc.w     $6028
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $7B01
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $1D
	ds.b     6
	dc.w     $6056
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $8401
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $1E
	ds.b     6
	dc.w     $6084
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $8D01
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $1F
	ds.b     6
	dc.w     $60B2
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $9601
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $20
	ds.b     6
	dc.w     $60E0
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $9F01
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $21
	ds.b     6
	dc.w     $610E
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $A801
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $22
	ds.b     6
	dc.w     $613C
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $B101
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $23
	ds.b     6
	dc.w     $616A
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $BA01
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $24
	ds.b     6
	dc.w     $6198
	ds.b     1
	dc.b     $0B
	ds.b     1
	dc.w     $C301
	dc.b     $29
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $25
	ds.b     6
	dc.w     $61C6,$014A
	ds.b     1
	dc.b     $2A
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $28
	ds.b     6
	dc.w     $61F4,$014A
	ds.b     1
	dc.b     $33
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $29
	ds.b     6
	dc.w     $6222,$014A
	ds.b     1
	dc.b     $3C
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $2A
	ds.b     6
	dc.w     $6250,$014A
	ds.b     1
	dc.b     $45
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $2B
	ds.b     6
	dc.w     $627E,$014A
	ds.b     1
	dc.b     $4E
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $2C
	ds.b     6
	dc.w     $62AC,$014A
	ds.b     1
	dc.b     $57
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $2D
	ds.b     6
	dc.w     $62DA,$014A
	ds.b     1
	dc.b     $60
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $2E
	ds.b     6
	dc.w     $6308,$014A
	ds.b     1
	dc.b     $69
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $2F
	ds.b     6
	dc.w     $6336,$014A
	ds.b     1
	dc.b     $72
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $30
	ds.b     6
	dc.w     $6364,$014A
	ds.b     1
	dc.b     $7B
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $31
	ds.b     6
	dc.w     $6392,$014A
	ds.b     1
	dc.b     $84
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $32
	ds.b     6
	dc.w     $63C0,$014A
	ds.b     1
	dc.b     $8D
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $33
	ds.b     6
	dc.w     $63EE,$014A
	ds.b     1
	dc.b     $96
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $34
	ds.b     6
	dc.w     $641C,$014A
	ds.b     1
	dc.b     $9F
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $35
	ds.b     6
	dc.w     $644A,$014A
	ds.b     1
	dc.b     $A8
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $36
	ds.b     6
	dc.w     $6478,$014A
	ds.b     1
	dc.b     $B1
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $37
	ds.b     6
	dc.w     $64A6,$014A
	ds.b     1
	dc.b     $BA
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $38
	ds.b     6
	dc.w     $64D4,$014A
	ds.b     1
	dc.b     $C3
	ds.b     1
	dc.b     $62
	ds.b     1
	dc.b     $09
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     23
	dc.b     $39
	ds.b     4
Var_DialogIText9:
	ds.w     1

	dc.w     $6624
	ds.b     1
	dc.b     $44
	ds.b     1
	dc.w     $DF01
	dc.b     $2C
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $651E
	ds.b     6
	dc.w     $6502
	ds.b     6
	dc.w     $6542
	ds.b     3
	dc.b     $0A
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $CA
	ds.b     8
	dc.w     $6516
	ds.b     4
	dc.b "File :"
	ds.b     2
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $652E
	ds.b     8
	dc.w     $012C
	ds.b     2
	dc.w     $012C
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $6566
	ds.b     2
	dc.w     $658E
	ds.b     3
	dc.b     $28
	ds.b     24
Var_DialogSuffixString:
	ds.b     190
Var_DialogListTitle:
	ds.w     1

	dc.w     $6670,$01AF
	ds.b     1
	dc.b     $32
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $92
	ds.b     3
	dc.b     $03
	ds.b     1
	dc.b     $03
	ds.b     2
	dc.w     $6668
	ds.b     14
	dc.w     $6652
	ds.b     3
	dc.b     $0C
	ds.b     5
	dc.b     $05
	ds.b     2
Var_DialogListTitle2:
	ds.l     1

Var_DialogListTitle3:
	dc.w     $FFFF
	ds.b     10
	dc.l Packer_ProcessEntry
	ds.b     6
Var_DialogListTitle4:
	ds.w     1

	dc.w     $6702
	ds.b     1
	dc.b     $44
	ds.b     1
	dc.w     $D201
	dc.b     $2C
	ds.b     1
	dc.b     $08
	ds.b     3
	dc.b     $01
	ds.b     1
	dc.b     $04
	ds.b     2
	dc.w     $66BA
	ds.b     6
	dc.w     $669E
	ds.b     6
	dc.w     $66DE
	ds.b     3
	dc.b     $09
	ds.b     4
	dc.w     $0102
	ds.b     1
	dc.w     $01FF
	dc.b     $CA
	ds.b     8
	dc.w     $66B2
	ds.b     4
	dc.b "Path :"
	ds.b     2
	dc.w     $FFFD,$FFFE,$0302
	ds.b     1
	dc.b     $05
	ds.b     2
	dc.w     $66CA
	ds.b     8
	dc.w     $012C
	ds.b     2
	dc.w     $012C
	ds.b     1
	dc.b     $0C
	ds.b     3
	dc.b     $0C
	ds.b     6
	dc.w     $4398
	ds.b     2
	dc.w     $658E
	ds.b     3
	dc.b     $96
	ds.b     24
Var_DialogListTitle5:
	ds.l     1

	dc.w     $0137
	ds.b     1
	dc.b     $32
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $92
	ds.b     3
	dc.b     $03
	ds.b     1
	dc.b     $03
	ds.b     2
	dc.w     $6746
	ds.b     14
	dc.w     $6730
	ds.b     3
	dc.b     $0B
	ds.b     5
	dc.b     $05
	ds.b     2
Var_DialogListTitle6:
	ds.w     1

	dc.w     $FFFF
Var_DialogListTitle7:
	dc.w     $FFFF
	ds.b     278
Var_DialogListTitle8:
	ds.b     9
	dc.b     $3F
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $686E
	ds.b     2
	dc.w     $6876
	ds.b     8
	dc.b "Projekt"
	ds.b     3
	dc.w     $693C
	ds.b     5
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $92
	ds.b     6
	dc.w     $6898
	ds.b     2
	dc.w     $6898
	ds.b     4
	dc.w     $68B4
	ds.b     2
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $68AC
	ds.b     4
	dc.b "Load "
	dc.w     $BBBB
	ds.b     3
	dc.w     $68F8
	ds.b     1
	dc.w     $64FF
	dc.b     $FB
	ds.b     1
	dc.b     $8A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $68D6
	ds.b     2
	dc.w     $68D6
	dc.b     $4F
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $68EA
	ds.b     4
	dc.b "Load File..."
	ds.b     7
	dc.b     $64
	ds.b     1
	dc.b     $05
	ds.b     1
	dc.b     $8A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $691A
	ds.b     2
	dc.w     $691A
	dc.b     $52
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $692E
	ds.b     4
	dc.b "Read Track..."
	ds.b     3
	dc.w     $6A02
	ds.b     3
	dc.b     $0A
	ds.b     1
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $92
	ds.b     6
	dc.w     $695E
	ds.b     2
	dc.w     $695E
	ds.b     4
	dc.w     $697A
	ds.b     2
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6972
	ds.b     4
	dc.b "Save "
	dc.w     $BBBB
	ds.b     3
	dc.w     $69BE
	ds.b     1
	dc.w     $64FF
	dc.b     $FB
	ds.b     1
	dc.b     $8A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $699C
	ds.b     2
	dc.w     $699C
	dc.b     $57
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $69B0
	ds.b     4
	dc.b "Save File..."
	ds.b     7
	dc.b     $64
	ds.b     1
	dc.b     $05
	ds.b     1
	dc.b     $8A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $69E0
	ds.b     2
	dc.w     $69E0
	dc.b     $53
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $69F4
	ds.b     4
	dc.b "Save Track..."
	ds.b     3
	dc.w     $6A42
	ds.b     3
	dc.b     $14
	ds.b     1
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6A24
	ds.b     2
	dc.w     $6A24
	dc.b     $4B
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6A38
	ds.b     4
	dc.b "Delete..."
	ds.b     3
	dc.w     $6A84
	ds.b     3
	dc.b     $1E
	ds.b     1
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6A64
	ds.b     2
	dc.w     $6A64
	dc.b     $4C
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6A78
	ds.b     4
	dc.b "Relocate..."
	ds.b     3
	dc.w     $6BB2
	ds.b     3
	dc.b     $28
	ds.b     1
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $92
	ds.b     6
	dc.w     $6AA6
	ds.b     2
	dc.w     $6AA6
	ds.b     4
	dc.w     $6AC8
	ds.b     2
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6ABA
	ds.b     4
	dc.b "Task pri. "
	dc.w     $BBBB
	ds.b     4
	dc.w     $6B02
	ds.b     1
	dc.w     $64FF
	dc.b     $F6
	ds.b     1
	dc.b     $4A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6AEA
	ds.b     2
	dc.w     $6AEA
	dc.b     $31
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6AFE
	ds.b     4
	dc.w     $202B
	dc.b     $33
	ds.b     3
	dc.w     $6B3C
	ds.b     1
	dc.b     $64
	ds.b     3
	dc.b     $4A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $46
	ds.b     6
	dc.w     $6B24
	ds.b     2
	dc.w     $6B24
	dc.b     $32
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6B38
	ds.b     4
	dc.w     $2020
	dc.b     $30
	ds.b     3
	dc.w     $6B76
	ds.b     1
	dc.b     $64
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $4A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6B5E
	ds.b     2
	dc.w     $6B5E
	dc.b     $33
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6B72
	ds.b     4
	dc.w     $202D
	dc.b     $33
	ds.b     6
	dc.b     $64
	ds.b     1
	dc.b     $14
	ds.b     1
	dc.b     $4A
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6B98
	ds.b     2
	dc.w     $6B98
	dc.b     $30
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6BAC
	ds.b     4
	dc.w     $3130,$3025

	ds.b     4
	dc.w     $6BEE
	ds.b     3
	dc.b     $32
	ds.b     1
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6BD4
	ds.b     2
	dc.w     $6BD4
	dc.b     $41
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6BE8
	ds.b     4
	dc.b "About"
	ds.b     3
	dc.w     $6C2E
	ds.b     3
	dc.b     $3C
	ds.b     1
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6C10
	ds.b     2
	dc.w     $6C10
	dc.b     $58
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6C24
	ds.b     4
	dc.b "Sleep..."
	ds.b     9
	dc.b     $50
	ds.b     1
	dc.b     $82
	ds.b     1
	dc.b     $0A
	ds.b     1
	dc.b     $56
	ds.b     6
	dc.w     $6C50
	ds.b     2
	dc.w     $6C50
	dc.b     $51
	ds.b     7
	dc.w     $0302
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     1
	dc.b     $01
	ds.b     6
	dc.w     $6C64
	ds.b     4
	dc.b "Quit"
	ds.b     4
	dc.w     $6C72
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.w     $4370,$6569,$676E,$6F74,$2E66,$6F6E
	dc.b     $74

	ds.b     20
Var_DialogListTitle9:
	ds.b     8
	dc.b     $0C
	ds.b     3
	dc.w     $6C72
	ds.b     4
	dc.w     $09B8
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $41
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $06
	ds.b     1
	dc.b     $01
	ds.b     2
	dc.w     $20FF
	ds.b     2
	dc.w     $6CC6
	ds.b     1
	dc.b     $C0
	ds.b     2
	dc.w     $72C6
	ds.b     9
	dc.w     $186C,$6618,$C338,$180C
	dc.b     $30
	ds.b     5
	dc.w     $033C,$183C,$7E1C,$7E0C,$7E3C
	dc.b     $3C
	ds.b     2
	dc.b     $0C
	ds.b     1
	dc.w     $303C,$3E3C,$7C3C,$783E,$3E3C
	dc.b     $66

	dc.w     $1806,$6660,$6366,$3C7C,$3C7C,$3C7E,$6666,$6363
	dc.w     $667E
	dc.b     $3C

	dc.w     $C03C
	dc.b     $10
	ds.b     1
	dc.b     $18
	ds.b     1
	dc.b     $60
	ds.b     1
	dc.b     $06
	ds.b     1
	dc.b     $1C
	ds.b     1
	dc.w     $6018,$1860
	dc.b     $30
	ds.b     14
	dc.w     $0E18,$7072
	dc.b     $CC
	ds.b     1
	dc.w     $180C,$1C42,$C318,$3C66,$7E78

	ds.b     1
	dc.b     $7E
	ds.b     1
	dc.w     $7E7E,$3C18,$F0F0
	dc.b     $18
	ds.b     1
	dc.b     $7E
	ds.b     2
	dc.w     $3070
	ds.b     1
	dc.w     $4060,$C018,$300C,$1832,$663C,$7F3C,$300C,$1866
	dc.w     $300C,$1866,$7832
	dc.b     $30

	dc.w     $0C18,$3266
	ds.b     1
	dc.w     $3D30,$0C18,$CC06,$607C,$300C,$1832,$663C
	ds.b     2
	dc.w     $180C,$0C36,$300C,$1866,$3032
	dc.b     $30

	dc.w     $0C18,$3266
	ds.b     2
	dc.w     $300C
	dc.b     $18
	ds.b     1
	dc.w     $0C30
	dc.b     $66
	ds.b     1
	dc.w     $186C,$663E,$C66C,$1818,$1866
	dc.b     $18
	ds.b     3
	dc.w     $0666,$3866,$063C,$6018,$0666,$6618
	ds.b     1
	dc.b     $18
	ds.b     1
	dc.w     $1866,$6366,$6666,$6C60,$6066
	dc.b     $66

	dc.w     $1806,$6660,$7776,$6666,$6666
	dc.b     $66

	dc.w     $1866,$6663,$6366

	dc.w     $0630,$600C
	dc.b     $38
	ds.b     1
	dc.b     $18
	ds.b     1
	dc.b     $60
	ds.b     1
	dc.b     $06
	ds.b     1
	dc.b     $30
	ds.b     1
	dc.b     $60
	ds.b     2
	dc.w     $6030
	ds.b     14
	dc.w     $1818,$189C
	dc.b     $33
	ds.b     2
	dc.w     $3E36,$3C66

	dc.w     $1840
	ds.b     1
	dc.w     $81D8,$3306
	ds.b     1
	dc.b     $81
	ds.b     1
	dc.w     $6618,$1818
	dc.b     $30
	ds.b     1
	dc.b     $F4
	ds.b     2
	dc.w     $7088,$CCC6,$E623
	ds.b     1
	dc.w     $0810,$244C,$3C66

	dc.w     $CC66,$0810
	dc.b     $24
	ds.b     1
	dc.w     $0810
	dc.b     $24
	ds.b     1
	dc.w     $6C4C,$0810,$244C
	dc.b     $3C
	ds.b     1
	dc.w     $6608,$1024
	ds.b     1
	dc.w     $0860,$6608,$1024
	dc.b     $4C
	ds.b     1
	dc.b     $66
	ds.b     2
	dc.w     $0410
	dc.b     $12
	ds.b     1
	dc.w     $0810
	dc.b     $24
	ds.b     1
	dc.w     $7C4C,$0810,$244C
	ds.b     1
	dc.w     $1801,$0810,$2466,$1030
	ds.b     2
	dc.b     $18
	ds.b     1
	dc.w     $FF60,$0C68,$3030,$0C3C
	dc.b     $18
	ds.b     3
	dc.w     $0C6E,$1806,$0C6C,$7C30,$0666,$6618,$1830,$7E0C
	dc.w     $066F,$6666,$6066,$6060,$6066

	dc.w     $1806,$6C60,$7F7E,$6666,$6666
	dc.b     $60

	dc.w     $1866,$6663,$3666

	dc.w     $0C30,$300C
	dc.b     $6C
	ds.b     1
	dc.w     $0C3C,$7C3C,$3E3E,$3C3E
	dc.b     $66

	dc.w     $1818,$6630,$6366,$3C7C,$3E7C,$3E7E,$6666,$6363
	dc.w     $667E

	dc.w     $1818
	dc.b     $18
	ds.b     1
	dc.b     $CC
	ds.b     1
	dc.w     $186C,$3066
	dc.b     $3C

	dc.w     $183C
	ds.b     1
	dc.w     $BDD8
	dc.b     $66
	ds.b     1
	dc.w     $7EBD
	ds.b     1
	dc.w     $3C7E,$3030

	ds.b     1
	dc.w     $C6F4
	ds.b     2
	dc.w     $3088,$664C,$6C66

	dc.w     $183C,$3C3C,$3C66
	dc.b     $3C

	dc.w     $CC60,$3E3E,$3E3E

	dc.w     $1818,$1818,$6676,$3C3C,$3C3C,$6663,$6E66,$6666

	dc.w     $CC66,$7C66
	ds.b     4
	dc.w     $3C3C,$7F3C,$1E1E,$1E1E
	ds.b     4
	dc.b     $18
	ds.b     5
	dc.b     $3C
	ds.b     1
	dc.b     $3E
	ds.b     5
	dc.w     $3C66
	ds.b     1
	dc.b     $18
	ds.b     1
	dc.w     $663C,$1876
	ds.b     1
	dc.w     $300C,$FF7E
	ds.b     1
	dc.b     $7E
	ds.b     1
	dc.w     $187E,$180C,$1CCC,$067C,$0C3C
	dc.b     $3E
	ds.b     1
	dc.w     $1860
	ds.b     1
	dc.w     $060C,$6F7E,$7C60,$667C,$7C6E
	dc.b     $7E

	dc.w     $1806,$7860,$6B6E,$667C,$667C
	dc.b     $3C

	dc.w     $1866,$666B,$1C3C,$1830,$180C
	dc.b     $C6
	ds.b     2
	dc.w     $6666,$6666,$6030,$6666

	dc.w     $1818,$6C30,$7776,$6666,$6666
	dc.b     $60

	dc.w     $1866,$666B,$3666

	dc.w     $0C70,$080E
	ds.b     1
	dc.b     $33
	ds.b     1
	dc.w     $186C,$783C
	dc.b     $18
	ds.b     1
	dc.b     $66
	ds.b     1
	dc.w     $B17C
	dc.b     $CC
	ds.b     1
	dc.w     $7EA5
	ds.b     2
	dc.w     $1860
	dc.b     $18
	ds.b     1
	dc.w     $C674
	dc.b     $18
	ds.b     1
	dc.w     $3070,$3358,$782C,$3066,$6666,$6666
	dc.b     $66

	dc.w     $FF60,$6060,$6060

	dc.w     $1818,$1818,$F67E,$6666,$6666,$6636,$7E66,$6666

	dc.w     $CC66,$666C,$3C3C,$3C3C,$663C

	dc.w     $CC66,$3030,$3030

	dc.w     $1818,$1818,$3C76,$3C3C,$3C3C,$667E,$6766,$6666
	dc.w     $6666,$3666

	ds.b     1
	dc.b     $18
	ds.b     1
	dc.w     $FF06,$30DC
	ds.b     1
	dc.w     $300C,$3C18
	ds.b     3
	dc.w     $3076,$1818,$06FE,$0666,$1866
	dc.b     $0C
	ds.b     2
	dc.b     $30
	ds.b     1
	dc.w     $0C18,$6F66,$6660,$6660,$6066
	dc.b     $66

	dc.w     $1806,$6C60,$6366,$6660,$6678

	dc.w     $0618,$666C,$7F36,$1830,$300C
	dc.b     $0C
	ds.b     3
	dc.w     $7E66,$6066,$7E30,$667E

	dc.w     $1818,$7830,$7F7E,$6666,$667C
	dc.b     $3C

	dc.w     $1866,$6C6B,$1C66,$1818,$1818
	ds.b     1
	dc.b     $CC
	ds.b     1
	dc.w     $183E,$3042
	dc.b     $3C

	dc.w     $183C
	ds.b     1
	dc.b     $BD
	ds.b     1
	dc.b     $66
	ds.b     2
	dc.b     $B9
	ds.b     2
	dc.w     $18F8
	dc.b     $F0
	ds.b     1
	dc.w     $C614
	dc.b     $18
	ds.b     1
	dc.b     $30
	ds.b     1
	dc.w     $6632,$3FD9,$607E,$7E7E,$7E7E
	dc.b     $7E

	dc.w     $CC66,$7C7C,$7C7C

	dc.w     $1818,$1818,$666E,$6666,$6666
	dc.b     $66

	dc.w     $1C76,$6666
	dc.b     $66

	dc.w     $CC3C,$6666,$6666,$6666,$7E66

	dc.w     $FF60,$3E3E,$3E3E

	dc.w     $1818,$1818,$667E,$6666,$6666
	dc.b     $66

	ds.b     1
	dc.w     $6B66,$6666,$6666,$3666

	ds.b     3
	dc.w     $667C,$63CC
	ds.b     1
	dc.w     $1818,$6618
	dc.b     $18
	ds.b     1
	dc.w     $1860,$6618,$3066,$0C66,$6618,$6618,$1818,$187E
	dc.b     $18
	ds.b     1
	dc.w     $6066,$6666,$6C60,$6066
	dc.b     $66

	dc.w     $1866,$6660,$6366,$6660,$6E6C
	dc.b     $66

	dc.w     $1866,$7877
	dc.b     $63

	dc.w     $1860,$3006
	dc.b     $0C
	ds.b     3
	dc.w     $6666,$6666,$6030,$3E66

	dc.w     $1818,$6C30,$6B6E,$667C,$3E6C

	dc.w     $0618,$6678,$3636,$3E30

	dc.w     $1818
	dc.b     $18
	ds.b     1
	dc.b     $33
	ds.b     1
	dc.w     $180C
	dc.b     $30
	ds.b     1
	dc.w     $1818
	dc.b     $02
	ds.b     1
	dc.w     $81FC
	dc.b     $33
	ds.b     2
	dc.b     $AD
	ds.b     6
	dc.w     $EE14
	ds.b     3
	dc.w     $F8CC,$666B,$3366,$6666,$6666,$6666

	dc.w     $CC3C,$6060,$6060

	dc.w     $1818,$1818,$6C66,$6666,$6666,$6636,$6666,$6666

	dc.w     $CC18,$7C66,$7E7E,$7E7E,$667E

	dc.w     $CC66,$3030,$3030

	dc.w     $1818,$1818,$666E,$6666,$6666
	dc.b     $66

	dc.w     $1873,$6666,$6666,$3E3C
	dc.b     $3E

	ds.b     1
	dc.b     $18
	ds.b     1
	dc.w     $6618,$C376
	ds.b     1
	dc.w     $0C30
	ds.b     2
	dc.b     $18
	ds.b     1
	dc.w     $18C0,$3C18,$7E3C,$0C3C,$3C18,$3C30,$1818
	dc.b     $0C
	ds.b     1
	dc.w     $3018,$3E66,$7C3C,$783E,$603E
	dc.b     $66

	dc.w     $183C,$663E,$6366,$3C60,$3C66
	dc.b     $3C

	dc.w     $183C,$7063
	dc.b     $63

	dc.w     $187E,$3C03
	dc.b     $3C
	ds.b     1
	dc.b     $FE
	ds.b     1
	dc.w     $667C,$3C3E,$3E30

	dc.w     $0666,$1818,$661C,$6366,$3C60

	dc.w     $0666,$7C18,$3C70,$3663

	dc.w     $067E,$0E18
	dc.b     $70
	ds.b     1
	dc.b     $CC
	ds.b     1
	dc.b     $18
	ds.b     1
	dc.b     $7E
	ds.b     1
	dc.w     $3C18
	dc.b     $3C
	ds.b     1
	dc.b     $7E
	ds.b     4
	dc.b     $81
	ds.b     2
	dc.b     $7E
	ds.b     3
	dc.w     $FA14
	ds.b     1
	dc.b     $18
	ds.b     3
	dc.w     $CFC6,$673C,$6666,$6666,$6666

	dc.w     $CF08
	dc.b ">>>>"
	dc.w     $1818,$1818,$7866,$3C3C,$3C3C,$3C63

	dc.w     $BC3C,$3C3C
	dc.b     $78

	dc.w     $1860,$6C66,$6666,$6666
	dc.b     $66

	dc.w     $CF3C,$1E1E,$1E1E,$1818,$1818,$3C66,$3C3C,$3C3C
	dc.b     $3C

	ds.b     1
	dc.w     $3E3C,$3C3C
	dc.b     $3C

	dc.w     $0630
	dc.b     $06
	ds.b     12
	dc.b     $30
	ds.b     14
	dc.b     $30
	ds.b     21
	dc.b     $06
	ds.b     21
	dc.b     $3C
	ds.b     2
	dc.b     $70
	ds.b     5
	dc.w     $6006
	ds.b     7
	dc.b     $3C
	ds.b     5
	dc.b     $33
	ds.b     14
	dc.b     $7E
	ds.b     6
	dc.b     $C0
	ds.b     2
	dc.b     $30
	ds.b     3
	dc.w     $020F
	dc.b     $01
	ds.b     8
	dc.b     $30
	ds.b     22
	dc.w     $6060
	ds.b     7
	dc.b     $10
	ds.b     16
	dc.b     $40
	ds.b     4
	dc.w     $3C30
	dc.b     $3C
	ds.b     3
	dc.b     $08
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $10
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $18
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $20
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $28
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $30
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $38
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $40
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $48
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $50
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $58
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $60
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $68
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $70
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $78
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $80
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $88
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $90
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $98
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $A0
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $A8
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $B0
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $B8
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $C0
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $C8
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $D0
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $D8
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $E0
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $E8
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $F0
	ds.b     1
	dc.b     $08
	ds.b     1
	dc.b     $F8
	ds.b     1
	dc.w     $0801
	ds.b     2
	dc.w     $0801
	dc.b     $08
	ds.b     1
	dc.w     $0801
	dc.b     $10
	ds.b     1
	dc.w     $0801
	dc.b     $18
	ds.b     1
	dc.w     $0801
	dc.b     $20
	ds.b     1
	dc.w     $0801
	dc.b     $28
	ds.b     1
	dc.w     $0801
	dc.b     $30
	ds.b     1
	dc.w     $0801
	dc.b     $38
	ds.b     1
	dc.w     $0801
	dc.b     $40
	ds.b     1
	dc.w     $0801
	dc.b     $48
	ds.b     1
	dc.w     $0801
	dc.b     $50
	ds.b     1
	dc.w     $0801
	dc.b     $58
	ds.b     1
	dc.w     $0801
	dc.b     $60
	ds.b     1
	dc.w     $0801
	dc.b     $68
	ds.b     1
	dc.w     $0801
	dc.b     $70
	ds.b     1
	dc.w     $0801
	dc.b     $78
	ds.b     1
	dc.w     $0801
	dc.b     $80
	ds.b     1
	dc.w     $0801
	dc.b     $88
	ds.b     1
	dc.w     $0801
	dc.b     $90
	ds.b     1
	dc.w     $0801
	dc.b     $98
	ds.b     1
	dc.w     $0801
	dc.b     $A0
	ds.b     1
	dc.w     $0801
	dc.b     $A8
	ds.b     1
	dc.w     $0801
	dc.b     $B0
	ds.b     1
	dc.w     $0801
	dc.b     $B8
	ds.b     1
	dc.w     $0801
	dc.b     $C0
	ds.b     1
	dc.w     $0801
	dc.b     $C8
	ds.b     1
	dc.w     $0801
	dc.b     $D0
	ds.b     1
	dc.w     $0801
	dc.b     $D8
	ds.b     1
	dc.w     $0801
	dc.b     $E0
	ds.b     1
	dc.w     $0801
	dc.b     $E8
	ds.b     1
	dc.w     $0801
	dc.b     $F0
	ds.b     1
	dc.w     $0801
	dc.b     $F8
	ds.b     1
	dc.w     $0802
	ds.b     2
	dc.w     $0802
	dc.b     $08
	ds.b     1
	dc.w     $0802
	dc.b     $10
	ds.b     1
	dc.w     $0802
	dc.b     $18
	ds.b     1
	dc.w     $0802
	dc.b     $20
	ds.b     1
	dc.w     $0802
	dc.b     $28
	ds.b     1
	dc.w     $0802
	dc.b     $30
	ds.b     1
	dc.w     $0802
	dc.b     $38
	ds.b     1
	dc.w     $0802
	dc.b     $40
	ds.b     1
	dc.w     $0802
	dc.b     $48
	ds.b     1
	dc.w     $0802
	dc.b     $50
	ds.b     1
	dc.w     $0802
	dc.b     $58
	ds.b     1
	dc.w     $0802
	dc.b     $60
	ds.b     1
	dc.w     $0802
	dc.b     $68
	ds.b     1
	dc.w     $0802
	dc.b     $70
	ds.b     1
	dc.w     $0802
	dc.b     $78
	ds.b     1
	dc.w     $0802
	dc.b     $80
	ds.b     1
	dc.w     $0802
	dc.b     $88
	ds.b     1
	dc.w     $0802
	dc.b     $90
	ds.b     1
	dc.w     $0802
	dc.b     $98
	ds.b     1
	dc.w     $0802
	dc.b     $A0
	ds.b     1
	dc.w     $0802
	dc.b     $A8
	ds.b     1
	dc.w     $0802
	dc.b     $B0
	ds.b     1
	dc.w     $0802
	dc.b     $B8
	ds.b     1
	dc.w     $0802
	dc.b     $C0
	ds.b     1
	dc.w     $0802
	dc.b     $C8
	ds.b     1
	dc.w     $0802
	dc.b     $D0
	ds.b     1
	dc.w     $0802
	dc.b     $D8
	ds.b     1
	dc.w     $0802
	dc.b     $E0
	ds.b     1
	dc.w     $0802
	dc.b     $E8
	ds.b     1
	dc.w     $0802
	dc.b     $F0
	ds.b     1
	dc.w     $0802
	dc.b     $F8
	ds.b     1
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.w     $0803
	ds.b     2
	dc.b     $08
	ds.b     3
	dc.w     $0803
	dc.b     $08
	ds.b     1
	dc.w     $0803
	dc.b     $10
	ds.b     1
	dc.w     $0803
	dc.b     $18
	ds.b     1
	dc.w     $0803
	dc.b     $20
	ds.b     1
	dc.w     $0803
	dc.b     $28
	ds.b     1
	dc.w     $0803
	dc.b     $30
	ds.b     1
	dc.w     $0803
	dc.b     $38
	ds.b     1
	dc.w     $0803
	dc.b     $40
	ds.b     1
	dc.w     $0803
	dc.b     $48
	ds.b     1
	dc.w     $0803
	dc.b     $50
	ds.b     1
	dc.w     $0803
	dc.b     $58
	ds.b     1
	dc.w     $0803
	dc.b     $60
	ds.b     1
	dc.w     $0803
	dc.b     $68
	ds.b     1
	dc.w     $0803
	dc.b     $70
	ds.b     1
	dc.w     $0803
	dc.b     $78
	ds.b     1
	dc.w     $0803
	dc.b     $80
	ds.b     1
	dc.w     $0803
	dc.b     $88
	ds.b     1
	dc.w     $0803
	dc.b     $90
	ds.b     1
	dc.w     $0803
	dc.b     $98
	ds.b     1
	dc.w     $0803
	dc.b     $A0
	ds.b     1
	dc.w     $0803
	dc.b     $A8
	ds.b     1
	dc.w     $0803
	dc.b     $B0
	ds.b     1
	dc.w     $0803
	dc.b     $B8
	ds.b     1
	dc.w     $0803
	dc.b     $C0
	ds.b     1
	dc.w     $0803
	dc.b     $C8
	ds.b     1
	dc.w     $0803
	dc.b     $D0
	ds.b     1
	dc.w     $0803
	dc.b     $D8
	ds.b     1
	dc.w     $0803
	dc.b     $E0
	ds.b     1
	dc.w     $0803
	dc.b     $E8
	ds.b     1
	dc.w     $0803
	dc.b     $F0
	ds.b     1
	dc.w     $0803
	dc.b     $F8
	ds.b     1
	dc.w     $0804
	ds.b     2
	dc.w     $0804
	dc.b     $08
	ds.b     1
	dc.w     $0804
	dc.b     $10
	ds.b     1
	dc.w     $0804
	dc.b     $18
	ds.b     1
	dc.w     $0804
	dc.b     $20
	ds.b     1
	dc.w     $0804
	dc.b     $28
	ds.b     1
	dc.w     $0804
	dc.b     $30
	ds.b     1
	dc.w     $0804
	dc.b     $38
	ds.b     1
	dc.w     $0804
	dc.b     $40
	ds.b     1
	dc.w     $0804
	dc.b     $48
	ds.b     1
	dc.w     $0804
	dc.b     $50
	ds.b     1
	dc.w     $0804
	dc.b     $58
	ds.b     1
	dc.w     $0804
	dc.b     $60
	ds.b     1
	dc.w     $0804
	dc.b     $68
	ds.b     1
	dc.w     $0804
	dc.b     $70
	ds.b     1
	dc.w     $0804
	dc.b     $78
	ds.b     1
	dc.w     $0804
	dc.b     $80
	ds.b     1
	dc.w     $0804
	dc.b     $88
	ds.b     1
	dc.w     $0804
	dc.b     $90
	ds.b     1
	dc.w     $0804
	dc.b     $98
	ds.b     1
	dc.w     $0804
	dc.b     $A0
	ds.b     1
	dc.w     $0804
	dc.b     $A8
	ds.b     1
	dc.w     $0804
	dc.b     $B0
	ds.b     1
	dc.w     $0804
	dc.b     $B8
	ds.b     1
	dc.w     $0804
	dc.b     $C0
	ds.b     1
	dc.w     $0804
	dc.b     $C8
	ds.b     1
	dc.w     $0804
	dc.b     $D0
	ds.b     1
	dc.w     $0804
	dc.b     $D8
	ds.b     1
	dc.w     $0804
	dc.b     $E0
	ds.b     1
	dc.w     $0804
	dc.b     $E8
	ds.b     1
	dc.w     $0804
	dc.b     $F0
	ds.b     1
	dc.w     $0804
	dc.b     $F8
	ds.b     1
	dc.w     $0805
	ds.b     2
	dc.w     $0805
	dc.b     $08
	ds.b     1
	dc.w     $0805
	dc.b     $10
	ds.b     1
	dc.w     $0805
	dc.b     $18
	ds.b     1
	dc.w     $0805
	dc.b     $20
	ds.b     1
	dc.w     $0805
	dc.b     $28
	ds.b     1
	dc.w     $0805
	dc.b     $30
	ds.b     1
	dc.w     $0805
	dc.b     $38
	ds.b     1
	dc.w     $0805
	dc.b     $40
	ds.b     1
	dc.w     $0805
	dc.b     $48
	ds.b     1
	dc.w     $0805
	dc.b     $50
	ds.b     1
	dc.w     $0805
	dc.b     $58
	ds.b     1
	dc.w     $0805
	dc.b     $60
	ds.b     1
	dc.w     $0805
	dc.b     $68
	ds.b     1
	dc.w     $0805
	dc.b     $70
	ds.b     1
	dc.w     $0805
	dc.b     $78
	ds.b     1
	dc.w     $0805
	dc.b     $80
	ds.b     1
	dc.w     $0805
	dc.b     $88
	ds.b     1
	dc.w     $0805
	dc.b     $90
	ds.b     1
	dc.w     $0805
	dc.b     $98
	ds.b     1
	dc.w     $0805
	dc.b     $A0
	ds.b     1
	dc.w     $0805
	dc.b     $A8
	ds.b     1
	dc.w     $0805
	dc.b     $B0
	ds.b     1
	dc.w     $0805
	dc.b     $B8
	ds.b     1
	dc.w     $0805
	dc.b     $C0
	ds.b     1
	dc.w     $0805
	dc.b     $C8
	ds.b     1
	dc.w     $0805
	dc.b     $D0
	ds.b     1
	dc.w     $0805
	dc.b     $D8
	ds.b     1
	dc.w     $0805
	dc.b     $E0
	ds.b     1
	dc.w     $0805
	dc.b     $E8
	ds.b     1
	dc.w     $0805
	dc.b     $F0
	ds.b     1
	dc.w     $0805
	dc.b     $F8
	ds.b     1
	dc.w     $0803
	ds.b     2
	dc.b     $08
	ds.b     2

; ================================================================================
	SECTION Hunk_2_Data, DATA, CHIP
Table_Hunk2Data:
	dc.l     $018003c0,$06600c30,$1818300c,$7e7e0660,$066007e0,$fe7ffc3f,$f99ff3cf,$e7e7cff3
	dc.l     $8181f99f,$f99ff81f,$018003c0,$06600c30,$199833cc,$66660c30,$18180000,$fe7ffc3f
	dc.l     $f99ff3cf,$e667cc33,$9999f3cf,$e7e7ffff,$07e00660,$06607e7e,$300c1818,$0c300660
	dc.l     $03c00180,$f81ff99f,$f99f8181,$cff3e7e7,$f3cff99f,$fc3ffe7f,$00001818,$0c306666
	dc.l     $33cc1998,$0c300660,$03c00180,$ffffe7e7,$f3cf9999,$cc33e667,$f3cff99f,$fc3ffe7f
