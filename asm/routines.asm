;------ DivDByE ----------------------------------------------------------------
DivDByE:
; Divides D by E
; Inputs:
;  - D
;  - E
; Outputs:
;  - D: Quotient
;  - A: Remainder
; Destroys:
;  - B
	xor	a
	ld	b, 8
DivDByELoop:
	sla	d		; unroll 8 times
	rla			; ...
	cp	e		; ...
	jr	c, $ + 4	; ...
	sub	e		; ...
	inc	d		; ...
	djnz	DivDByELoop
	ret


;------ DivHlByC ---------------------------------------------------------------
DivHlByC:
; Divides HL by C.
; Inputs:
;  - HL 16 bits
;  - C
; Outputs:
;  - HL: Quotient
;  - A: Remainder
; Destroys:
;  - BC
	xor	a
	ld	b, 16
DivHlByCLoop:
	add.s	hl, hl		; unroll 16 times
	rla			; ...
	cp	c		; ...
	jr	c, $ + 4	; ...
	sub	c		; ...
	inc	l		; ...
	djnz	DivHlByCLoop
	ret


;------ DispUHL ----------------------------------------------------------------
DispUHL:
	call	GetHighByte
	call	DispByte
	call	GetHighByte
	call	DispByte
	call	GetHighByte
	jr	DispByte
	

;------ GetHighByte ------------------------------------------------------------
GetHighByte:
	add	hl, hl
	adc	a, a
	add	hl, hl
	adc	a, a
	add	hl, hl
	adc	a, a
	add	hl, hl
	adc	a, a
	add	hl, hl
	adc	a, a
	add	hl, hl
	adc	a, a
	add	hl, hl
	adc	a, a
	add	hl, hl
	adc	a, a
	ret
	

;------ DispHl -----------------------------------------------------------------
DispHl:
	ld	a, h
	call	DispByte
	ld	a, l
;------ DispByte ---------------------------------------------------------------
DispByte:
; Display A in hex.
; Input:
;  - A: Byte
; Output:
;  - Byte displayed
; Destroys:
;  - AF
	push	af
	rra
	rra
	rra
	rra
	call	_dba
	pop	af
_dba:	or	0F0h
	daa
	add	a, 0A0h
	adc	a, 40h
;	call	PutC
	call	_PutC
	ret


;------ GetStrIndexed ----------------------------------------------------------
GetStrIndexed:
; Given an index into a table of ZTSs, this finds the specified string
; Inputs:
;  - A: Index
;  - HL: Pointer to table
; Output:
;  - HL: Pointer to selected string
	or	a
	ret	z
	push	bc
	ld	b, a
	xor	a
_gsia:	cp	(hl)
	inc	hl
	jr	nz, _gsia
	djnz	_gsia
	pop	bc
	ret


;------ GetStrLength -----------------------------------------------------------
GetStrLength:
; Finds the null terminator in a string.
; Input:
;  - HL: Ptr to string
; Output:
;  - HL: Length
;  - DE: Ptr to string
; Destroys:
;  - BC
	ld	bc, 0
	xor	a
	ex	de, hl
	add	hl, de
	cpir
	or	a
	sbc	hl, de
	ret


