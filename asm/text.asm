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
	ld	de, mpLcdPalette
	or	a
	sbc	hl, hl
	add	hl, de
	inc	de
	ld	(hl), 0
	ldi
	ldi
	ld	(hl), 20h
	ld	bc, 29
	ldir
	ld	a, 10h
	ld	b, 240
paletteLoop:	; This could probably be optimized with LDI?
	ld	(de), a
	inc	de
	ld	(de), a
	inc	de
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
ClearScreen:
	ld	de, (mpLcdBase)
	or	a
	sbc	hl, hl
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
	ld	bc, 320
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
	rrca
	jr	c, PutCSetBit0
	ld	(hl), d
	inc	hl
	rrca
	jr	c, PutCSetBit1
PutCResetBit1:
	ld	(hl), d
	inc	hl
	rrca
	jr	c, PutCSetBit2
PutCResetBit2:
	ld	(hl), d
	inc	hl
	rrca
	jr	c, PutCSetBit3
PutCResetBit3:
	ld	(hl), d
	inc	hl
	rrca
	jr	c, PutCSetBit4
PutCResetBit4:
	ld	(hl), d
	inc	hl
	rrca
	jr	c, PutCSetBit5
PutCResetBit5:
	ld	(hl), d
	inc	hl
	rrca
	jr	c, PutCSetBit6
PutCResetBit6:
	ld	(hl), d
	inc	hl
	rrca
	jr	c, PutCSetBit7
PutCResetBit7:
	ld	(hl), d
	inc	hl
	djnz	PutCBytesLoop
	jr	PutCFinalBits
PutCSetBit0:
	ld	(hl), e
	inc	hl
	rrca
	jr	nc, PutCResetBit1
PutCSetBit1:
	ld	(hl), e
	inc	hl
	rrca
	jr	nc, PutCResetBit2
PutCSetBit2:
	ld	(hl), e
	inc	hl
	rrca
	jr	nc, PutCResetBit3
PutCSetBit3:
	ld	(hl), e
	inc	hl
	rrca
	jr	nc, PutCResetBit4
PutCSetBit4:
	ld	(hl), e
	inc	hl
	rrca
	jr	nc, PutCResetBit5
PutCSetBit5:
	ld	(hl), e
	inc	hl
	rrca
	jr	nc, PutCResetBit6
PutCSetBit6:
	ld	(hl), e
	inc	hl
	rrca
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
	rrca
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
