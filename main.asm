; Main program code
;
; Formatting:
; - Width: 132 Columns
; - Tab Size: 4, using tab
; - Comments: Column 57

; Reset handler
; Much of the init tasks are already done by the BIOS reset handler, including the PPU warmup loops.
Reset:
		lda #$00										; clear RAM
		tax
@clrmem:
		sta $00,x
		cpx #4											; preserve BIOS stack variables at $0100~$0103
		bcc :+
		sta $0100,x
:
		sta $0200,x
		sta $0300,x
		sta $0400,x
		sta $0500,x
		sta $0600,x
		sta $0700,x
		inx
		bne @clrmem
		jsr MoveSpritesOffscreen
		jsr InitNametables
		
		lda #BUFFER_SIZE								; set VRAM buffer size
		sta VRAM_BUFFER_SIZE

		lda #%10010000									; enable NMIs & change background pattern map access
		sta PPU_CTRL_MIRROR
		sta PPU_CTRL
		
Main:
		jsr ReadOrDownPads								; read controllers + expansion port
		jsr ProcessBGMode								; handle current state
		jsr WaitForNMI
		beq Main										; back to main loop
	
; NMI handler
NonMaskableInterrupt:
		pha												; back up A/X/Y
		txa
		pha
		tya
		pha
		
		lda NMIReady									; check if ready to do NMI logic (i.e. not a lag frame)
		beq NotReady
		
		jsr SpriteDMA
		
		lda NeedDraw									; transfer Data to PPU if required
		beq :+
		
		jsr DumpRegisters
		dec NeedDraw
		
:
		lda NeedPPUMask									; write PPUMASK if required
		beq :+
		
		lda PPU_MASK_MIRROR
		sta PPU_MASK
		dec NeedPPUMask

:
		dec NMIReady

NotReady:
		jsr SetScroll
		
		pla												; restore X/Y/A
		tay
		pla
		tax
		pla
		
; IRQ handler (unused for now)
InterruptRequest:
		rti

EnableRendering:
		lda #%00011110									; enable rendering and queue it for next NMI
	.byte $2c											; [skip 2 bytes]

RenderBG:
		lda #%00001010
	.byte $2c											; [skip 2 bytes]

RenderSprites:
		lda #%00010100
	.byte $2c											; [skip 2 bytes]

DisableRendering:
		lda #%00000000									; disable rendering and queue it for next NMI

UpdatePPUMask:
		sta PPU_MASK_MIRROR
		lda #$01
		sta NeedPPUMask
		rts

MoveSpritesOffscreen:
		lda #$ff										; fill OAM buffer with $ff to move offscreen
		ldx #>oam
		ldy #>oam
		jmp MemFill

InitNametables:
		lda #$20										; top-left
		jsr InitNametable
		lda #$28										; bottom-left

InitNametable:
		ldx #$00										; clear nametable & attributes for high address held in A
		ldy #$00
		jmp VRAMFill

; The DRAM refresh watchdog may or may not be enabled here, 
; so we must manually call Delay131 while waiting on NMIs
; Hopefully this reduces the risk of PRG-RAM decay...
WaitForNMI:
		inc NMIReady
:
		jsr Delay131									; refresh DRAM rows
		lda NMIReady
		bne :-
		rts

; Jump table for main logic
ProcessBGMode:
		lda Mode
		jsr JumpEngine
	.addr BGInit
	.addr HandleButtons

; Initialise background to display the program name
BGInit:
		jsr DisableRendering
		jsr WaitForNMI
		jsr VRAMStructWrite
	.addr BGData
	
		lda #%10000011									; reenable all registers
		sta FDS_IO_ENABLE_MIRROR
		
		inc Mode										; next state
		rts

HandleButtons:
		lda P1_PRESSED
		and #(BUTTON_A | BUTTON_B)						; wait until A/B is newly pressed
		beq :+
		asl a											; move A/B bits to LSB
		rol a
		rol a
		tay
		lda Masks,y
		eor FDS_IO_ENABLE_MIRROR
		sta FDS_IO_ENABLE_MIRROR						; toggle register I/O enable
:

YPos := 43
StartingXPos := 96
XPos := temp+1
CopyBitfieldSprites:
		lda FDS_IO_ENABLE_MIRROR
		sta temp
		lda #StartingXPos
		sta XPos
		ldy #$08
		ldx #$00
@tile:
		lda #YPos
		sta oam,x										; Y position is constant
		
		lda #'0'										; calculate tile index
		asl temp
		adc #$00
		sta oam+1,x
		
		lda #$00										; attributes are constant
		sta oam+2,x
		
		lda XPos										; store current X position
		sta oam+3,x
		adc #$08										; offset next sprite by 1 tile (carry always clear)
		sta XPos
		
		inx
		inx
		inx
		inx
		dey
		bne @tile										; repeat for all 8 bits
		
		inc NeedDraw
		jmp EnableRendering								; render next frame

Masks:
	.byte %00000000, %00000010, %00000001, %00000011

; Dump $4020~$409f into the nametable
; Yup, we're unrolling this to dump the entire section in a single vblank
.macro write_string ppu16, addr16
	lda #>(ppu16)
	sta PPU_ADDR
	lda #<(ppu16)
	sta PPU_ADDR
	.repeat 16, I
		lda addr16+I
		sta PPU_DATA
	.endrepeat
.endmacro

DumpRegisters:
		lda FDS_IO_ENABLE_MIRROR
		sta FDS_IO_ENABLE
		DisplayAddr := $2000 + (12 << 5) + 8
	.repeat 8, I
		write_string DisplayAddr+I*32, FDS_IRQ_TIMER_LOW+I*16
	.endrepeat
		jmp Delay131									; refresh DRAM rows, just to be safe

; VRAM transfer structures
BGData:

; Just write to all 16 entries so PPUADDR safely leaves the palette RAM region
; PPUADDR ends at $3F20 before the next write (avoids rare palette corruption)
; (palette entries will never be changed anyway, so we might as well set them all)
Palettes:
	.dbyt $3f00
	encode_length INC1, COPY, PaletteDataSize

.proc PaletteData
	; BG
	.byte $0f, $0f, $0f, $0f ; blank entry to hide attribute blocks
	.repeat 3
	.byte $0f, $20, $20, $20
	.endrepeat
	
	; Sprites
	.repeat 4
	.byte $0f, $00, $10, $20
	.endrepeat
.endproc
PaletteDataSize = .sizeof(PaletteData)

HexDumpAttributes:
	.dbyt $23da
	encode_length INC1, FILL, 4
	.byte $ff
	.dbyt $23e2
	encode_length INC1, FILL, 4
	.byte $ff
	
	encode_terminator

