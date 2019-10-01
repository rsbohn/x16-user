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

;; Initialize text and graphics
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
	;; map w/h 128x64, tile w/h 8x8
	vpoke 15, L0REGS+1, 6
	;; map base is 0
	vpoke 15, L0REGS+2, 0
	vpoke 15, L0REGS+3, 0
	;; leave tile base (font) as is.
	;; leave HSCROLL, VSCROLL as is.
	lda 0
	rts
	
TG_FILL:
	jmp TG_FILL
TG_PLOT:
	jmp TG_PLOT
TG_PCOPY:
	jmp TG_PCOPY
TG_PSET:
	jmp TG_PSET
