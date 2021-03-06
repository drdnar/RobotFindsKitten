;------ SetTextMode ------------------------------------------------------------
SetTextMode:
; Sets the LCD to 8-bit palette mode
; Inputs:
;  - None
; Output:
;  - LCD mode changed
; Destroys:
;  - Whatever
	ld	hl, lcdBpp8 | lcdPwr | lcdBgr
	ld	(mpLcdCtrl), hl
	ld	hl, mpLcdPalette
	xor	a
	ld	b, 0
paletteLoop:	; This could probably be optimized with LDI?
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	inc	a
	djnz	paletteLoop
	ret


;------ FixLcdMode -------------------------------------------------------------
FixLcdMode:
; Fixes the LCD mode and other settings for the OS's benefit.
; Inputs:
;  - None
; Output:
;  - LCD mode changed
; Destroys:
;  - Whatever
	ld	hl, lcdNormalMode
	ld	(mpLcdCtrl), hl
	ld	hl, vRam
	ld	(mpLcdBase), hl
	ret


;------ ClearScreen ------------------------------------------------------------
ClrScrnFull:
ClearScreen:
	ld	de, (mpLcdBase)
	or	a
	sbc	hl, hl
	ld	(lcdRow), hl
	ld	(lcdCol), hl
	add	hl, de
	inc	de
	ld	(hl), 0
	ld	bc, 320 * 240 - 1
	ldir
	ret


;------ NewLine ----------------------------------------------------------------
NewLine:
; Moves cursor to next line.
; Inputs:
;  - (lcdCol), (lcdRow)
; Outputs:
;  - Cursor adjusted
;  - DE = 0
;  - HL has old value of DE
; Destroys:
;  - AF
;  - B
;  - HL
	or	a
	sbc	hl, hl
	ld	(lcdCol), hl
	ex	de, hl
	ld	a, (fontHeight)
	ld	b, a
	ld	a, (lcdRow)
	add	a, b
	ld	(lcdRow), a
	add	a, b
	cp	240
	ret	c
	; Glyph will extend past bottom of screen, so force wrap
	xor	a
	ld	(lcdRow), a
	ret


;------ ClearEOL ---------------------------------------------------------------
ClearEOL:
; Erases everything from the cursor to the right edge of the screen.
; Inputs:
;  - LCD cursor
;  - Text background color
; Output:
;  - Erasing
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
	push	ix
	push	iy
	ld	de, (lcdCol)
	ld	hl, 320 - 1
	or	a
	sbc	hl, de
	push	hl
	pop	ix
	;ld	a, (textBackColor)
	xor	a
	ld	iyl, 14
	call	GetCursorPtr
clearEolLoop:
	push	hl
	ld	(hl), a
	ex	de, hl
	or	a
	sbc	hl, hl
	add	hl, de
	inc	de
	push	ix
	pop	bc
	ldir
	pop	hl
	ld	de, 320
	add	hl, de
	dec	iyl
	jr	nz, clearEolLoop
	pop	iy
	pop	ix
	ret


;------ PutS -------------------------------------------------------------------
PutS:
; Displays a string.  If the string contains control codes, those codes are
; parsed.
; Input:
;  - HL: String to show
; Output:
;  - String shown
;  - HL advanced to the byte after the null terminator.
; Destroys:
;  - AF
	ld	a, (hl)
	inc	hl
	or	a
	scf
	ret	z
	cp	chNewLine
	jr	z, putSNewLine
	
	push	hl
	push	de
	call	GetGlyphWidth
	sbc	hl, hl	; C is reset from GetGlyphWidth
	ld	l, a
	ld	de, (lcdCol)
	add	hl, de	; C is reset
	ld	de, 320 - 5
	sbc	hl, de
	pop	de
	pop	hl
	ret	nc
	
	dec	hl
	ld	a, (hl)
	inc	hl
	call	PutC
	jr	PutS
putSNewLine:
	push	hl
	call	ClearEOL
	ld	a, (lcdRow)
	add	a, 14
	cp	240 - 14
	jr	c, +_
	xor	a
_:	ld	(lcdRow), a
	or	a
	sbc	hl, hl
	ld	(lcdCol), hl
	pop	hl
	jr	PutS


;------ GetCursorPtr -----------------------------------------------------------
GetCursorPtr:
; Computes the address the LCD cursor is referencing.
; Inputs:
;  - (lcdRow), (lcdCol)
; Outputs:
;  - HL: Pointer
; Destroys:
;  - Nothing
	push	de
	ld	hl, (lcdRow)
	ld	h, 160
	mlt	hl
	add	hl, hl
	ld	de, (lcdCol)
	add	hl, de
	ld	de, (mpLcdBase)
	add	hl, de
	pop	de
	ret


;------ PutC -------------------------------------------------------------------
PutC:
PutC_LocalsSize		.equ	7
PutC_Lines		.equ	0
PutC_Width		.equ	1
PutC_Bytes		.equ	2
PutC_Bits		.equ	3
PutC_Delta		.equ	4
; Displays a glyph.
	push	af
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	ld	iy, -PutC_LocalsSize
	add	iy, sp
	ld	sp, iy
; Compute loop control data
	; Get glyph width
	or	a
	sbc	hl, hl
	ld	l, a
	ld	de, (fontWidthsPtr)
	ex	de, hl
	add	hl, de
	ld	a, (hl)
	ld	(iy + PutC_Width), a
	; Get number of leftover bits
	ld	bc, 0	; Needed for computing line-advance offset
	ld	c, a
	ld	b, a
	and	7
	ld	(iy + PutC_Bits), a
	; Number of full bytes in glyph bitmap
	srl	b
	srl	b
	srl	b
	ld	(iy + PutC_Bytes), b
	ld	a, (fontHeight)
	ld	(iy + PutC_Lines), a
	; Offset to move to next line
	ld	b, 0
	or	a
	ld	hl, 320
	sbc	hl, bc
	ld	(iy + PutC_Delta), hl
; Get ptr to glyph bitmap
	ex	de, hl
	ld	h, 3
	mlt	hl
	ld	de, (fontDataPtr)
	add	hl, de
	ld	ix, (hl)
	add	ix, de
; Update lcdCol
	ld	de, (lcdCol)
	or	a
	sbc	hl, hl
	ld	l, (iy + PutC_Width)
	add	hl, de
	ld	(lcdCol), hl
	ld	bc, 320 + 1	; Easier than checking two flags
	sbc	hl, bc
	call	nc, NewLine	; Glyph will extend past right edge of screen, so force wrap
; VRAM offset
	ld	a, (lcdRow)
	ld	l, a
	ld	h, 160
	mlt	hl
	add	hl, hl
;	ld	de, (lcdCol)
	add	hl, de
	ld	de, (mpLcdBase)
	add	hl, de
; Main output loop
	ld	de, (textColors)
PutCLineLoop:
	ld	a, (iy + PutC_Bytes)
	or	a
	jr	z, PutCFinalBits
	ld	b, a
PutCBytesLoop:
	ld	a, (ix)
	inc	ix
	rlca
	jr	c, PutCSetBit0
	ld	(hl), d
	inc	hl
	rlca
	jr	c, PutCSetBit1
PutCResetBit1:
	ld	(hl), d
	inc	hl
	rlca
	jr	c, PutCSetBit2
PutCResetBit2:
	ld	(hl), d
	inc	hl
	rlca
	jr	c, PutCSetBit3
PutCResetBit3:
	ld	(hl), d
	inc	hl
	rlca
	jr	c, PutCSetBit4
PutCResetBit4:
	ld	(hl), d
	inc	hl
	rlca
	jr	c, PutCSetBit5
PutCResetBit5:
	ld	(hl), d
	inc	hl
	rlca
	jr	c, PutCSetBit6
PutCResetBit6:
	ld	(hl), d
	inc	hl
	rlca
	jr	c, PutCSetBit7
PutCResetBit7:
	ld	(hl), d
	inc	hl
	djnz	PutCBytesLoop
	jr	PutCFinalBits
PutCSetBit0:
	ld	(hl), e
	inc	hl
	rlca
	jr	nc, PutCResetBit1
PutCSetBit1:
	ld	(hl), e
	inc	hl
	rlca
	jr	nc, PutCResetBit2
PutCSetBit2:
	ld	(hl), e
	inc	hl
	rlca
	jr	nc, PutCResetBit3
PutCSetBit3:
	ld	(hl), e
	inc	hl
	rlca
	jr	nc, PutCResetBit4
PutCSetBit4:
	ld	(hl), e
	inc	hl
	rlca
	jr	nc, PutCResetBit5
PutCSetBit5:
	ld	(hl), e
	inc	hl
	rlca
	jr	nc, PutCResetBit6
PutCSetBit6:
	ld	(hl), e
	inc	hl
	rlca
	jr	nc, PutCResetBit7
PutCSetBit7:
	ld	(hl), e
	inc	hl
	djnz	PutCBytesLoop
PutCFinalBits:
	ld	a, (iy + PutC_Bits)
	or	a
	jr	z, PutCNoFinalBits
	ld	b, a
	ld	a, (ix)
	inc	ix
PutCFinalBitsLoop:
	rlca
	jr	c, PutCFinalSetBit
	ld	(hl), d
	inc	hl
	djnz	PutCFinalBitsLoop
	jr	PutCNoFinalBits
PutCFinalSetBit:
	ld	(hl), e
	inc	hl
	djnz	PutCFinalBitsLoop
PutCNoFinalBits:
	ld	bc, (iy + PutC_Delta)
	add	hl, bc
	dec	(iy + PutC_Lines)
	jp	nz, PutCLineLoop
; Close stack frame
	ld	iy, PutC_LocalsSize
	add	iy, sp
	ld	sp, iy
	pop	iy
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
; End of function
	ret


;------ PutSCentered -----------------------------------------------------------
PutSCentered:
; Displays a string, centering it.  However, if the string contains control
; codes, the result will be weird.
; Input:
;  - HL: String to show
;  - B: Line on which to show the string.
; Output:
;  - String shown
;  - HL advanced to the byte after the null terminator.
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL

	push	hl
	ex	de, hl
	ld	l, b
	ld	h, 0
	call	Locate
	call	GetStrWidth
	ex	de, hl
	srl	d
	rr	e
	ld	hl, 320 / 2
	or	a
	sbc	hl, de
	ld	(lcdCol), hl
	pop	hl
	call	PutS
	ret


;------ GetGlyphWidth ----------------------------------------------------------
GetGlyphWidth:
; GetGlyphWidth
; Returns the width of the given glyph
; Input:
;  - A: Codepoint
; Output:
;  - A: Width
;  - Carry is reset
; Destroys:
;  - Nothing
	push	hl
	push	de
	or	a
	sbc	hl, hl
	ld	l, a
	ld	de, (fontWidthsPtr)
	add	hl, de
	ld	a, (hl)
	pop	de
	pop	hl
	ret


;------ GetStrWidth ------------------------------------------------------------
GetStrWidth:
; Computes the width, in pixels, of a string
; Input:
;  - DE: Pointer to string
; Output:
;  - HL: Width of string, in pixels
; Destroys:
;  - AF
	or	a
	sbc	hl, hl
	push	hl
	pop	bc
gswl:	ld	a, (de)
	inc	de
	or	a
	ret	z
	call	GetGlyphWidth
	ld	c, a
	add	hl, bc
	jr	gswl


;------ Locate -----------------------------------------------------------------
Locate:
; Moves the cursor to a grid location.
; Named after a QuickBASIC command.
; Inputs:
;  - H: Column
;  - L: Row
; Output:
;  - Cursor moved
; Destroys:
;  - Nothing
	push	af
	push	de
	push	hl
	ld	d, h
	ld	e, 10
	mlt	de
	ld	(lcdCol), de
	ld	h, 14
	mlt	hl
	ld	a, l
	ld	(lcdRow), a
	pop	hl
	pop	de
	pop	af
	ret