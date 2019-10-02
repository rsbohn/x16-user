;; tambor.s -- 160x120x4 Simple Graphics Driver
;; Copyright (c) 2019 Randall S. Bohn
;; All rights reserved. License: 2-clause BSD
;; make
;; cp user.bin USER.PRG
;; LOAD "USER.PRG",1,1:NEW
;; SYS$A004 :REM TGINIT
;; REM Now library is loaded and can be used.

;; This is a combined text and graphics mode.
;; Layer 0 is 80x30 text.
;; Layer 1 is 640x240 2bpp graphics.
;; The driver provides 160x120 'big pixels'
;; by mapping one pixel to a 4x2 block.

	.segment "STARTUP"
	;; the X16 loader will use this address
	;; so the library code below 
	;; is actually loaded at $A000 as desired
	.word $A000

	.segment "CODE"
	.org $A000
	.byte 71, 52, 120, 160 ;; 'G4', width*256+height
;; Jump table
	jmp TG_INIT	;; Set up text and graphics
	jmp TG_FILL	;; Fill graphics (CLS)
	jmp TG_PLOT	;; Plot a 4x2 'big pixel'
	jmp TG_PCOPY	;; Copy a palette entry
	jmp TG_PSET	;; Set a pallet entry
	.res 3*6	;; future expansion

;; Macros
VE_LOW	= $9F20
VE_MID	= $9F21
VE_HIGH	= $9F22
VR0	= $9F23
VR1	= $9F24
VE_SEL	= $9F25
.macro vpoke bank, addr, value
	lda #<addr
	sta VE_LOW
	lda #>addr
	sta VE_MID
	lda #bank
	sta VE_HIGH
	lda #$00
	sta VE_SEL
	lda #value
	sta VR0
.endmacro

.macro vstart bank, addr
	lda #<addr
	sta VE_LOW
	lda #>addr
	sta VE_MID
	lda #bank
	sta VE_HIGH
	lda #0
	sta VE_SEL
.endmacro

;; TG_INIT:Initialize text and graphics
;; SYS$A004
;; ARGS: none
;; RETURN: A=0 ok
	L0REGS = $2000
	L1REGS = $3000
TG_INIT:
	;; display compositor DC_HSCALE = 128 DC_VSCALE = 64
	;; resolution 640x240
	vpoke 15, 1, 128
	vpoke 15, 2, 64
	;; set BASIC to 80x30
	MAXCOLS = 217
	MAXROWS = 218
	lda #80
	sta MAXCOLS
	lda #30
	sta MAXROWS
	;; set Layer 0 to mode 0
	vpoke 15, L0REGS, 1
	;; map w/h scale 128x64, tile w/h 8x8
	vpoke 15, L0REGS+1, 6
	;; map base is 0
	vpoke 15, L0REGS+2, 0
	vpoke 15, L0REGS+3, 0
	;; leave tile base (font) as is.
	;; leave HSCROLL, VSCROLL as is.

	;; Each byte is 4 pixels or 1/2 'big pixel'.
	;; The bottom half of each 'big pixel'
	;; is +160 bytes after the top half.
	;; Set Layer 1 to mode 5 2bpp 640x240
	vpoke 15, L1REGS+5, $10	;; map starts at $4000
	vpoke 15, L1REGS+1, $10 ;; %00 0 1 0000
				;; TILEW=1 640 pixels wide
				;; or 160 bytes wide
	vpoke 15, L1REGS,   $A1	;; %101 0000 1 -- mode 5, enabled
	lda 0
	rts
	
;; TG_FILL:Fill VRAM with a single value (CLS)
;; ARGS: A=value to fill
;; RETURN: A=0 ok
TG_FILL:;;
	pha
	vstart $10, $4000
	pla
	ldx #160	;; 160 * 4 = 640
TGFX:	ldy #120*2	;; two rows for each big pixel
TGFY:	sta VR0
	dey
	bne TGFY
	dex
	bne TGFX
	lda #0
	rts

;; TG_PLOT:Plot one big pixel
;; ARGS:
;;	A: value (for solid pixel use $00 $55 $AA or $FF)
;;	X: X coordinate 0-159
;;	Y: Y coordinate 0-119
;; RETURN: A=0 ok
TG_PLOT:
	pha
	lda #0
	sta 1

	sty 0
	clc	;; Y * 64
	asl 0
	rol 1
	clc
	asl 0
	rol 1
	clc
	asl 0
	rol 1
	clc
	asl 0
	rol 1
	clc
	asl 0
	rol 1
	clc
	asl 0
	rol 1
	clc

	tya		;; + Y * 256
	adc 1
	adc #$40	;; + $4000
	sta 1

	clc		;; + X
	txa
	adc 0
	sta 0
	bcc :+
	inc 1

:	lda #0
	sta VE_HIGH
	lda 1
	sta VE_MID
	lda 0
	sta VE_LOW
	lda #0
	sta VE_SEL
	pla
	sta VR0

	pha
	clc
	lda #160	;; plot lower half
	adc 0
	sta 0
	bcc :+
	inc 1

:	sta VE_LOW
	lda 1
	sta VE_MID
	pla
	sta VR0
	lda #0
	rts

TG_PCOPY:
	jmp TG_PCOPY
TG_PSET:
	jmp TG_PSET
