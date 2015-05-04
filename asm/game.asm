RobotFindsKitten:
;------ StartGame --------------------------------------------------------------
StartGame:
	; Reset some vars
	ld	hl, 0
	ld	(foundObject), hl
	ld	(stringOffset), hl
	ld	(stringStage), hl
	ld	(scrollTimer), hl
	; Clear object table
	ld	a, 255
	ld	hl, objectArray
	call	ClearMem
; Choose number of NKIs to generate
	ld	b, 12
	call	RandRange8
	add	a, 16
	ld	(objectCount), a
	ld	(stringStage), a
	ld	ix, objectArray
generateLoop:

	ld	a, '.'
	call	PutC

	; Random location
;	push	ix
	call	RandomLocation
	ld	(ix), e
	ld	(ix+1), d
robj:	; Random item
;	push	ix
	b_call(_OP1Set1)
	b_call(_OP1ToOP5)
	ld	hl, fpItems
	ld	de, OP6
	b_call(_Mov9B)
	call	GetRandomInt
;	pop	ix
	dec	hl
;#ifdef	NEVER
	ex	de, hl
	ld	hl, objectArray
	ld	a, (objectCount)
	ld	b, a
	inc	hl
	inc	hl
robjlp:	ld	a, (hl)
	inc	hl
	cp	e
	jr	nz, +_
	ld	a, (hl)
	cp	d
	jr	z, robj
_:	inc	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	djnz	robjlp
;#endif
	ld	(ix+2), e
	ld	(ix+3), d
rglph:	; Random glyph
;	push	ix
	ld	hl, fpFirstChar
	ld	de, OP5
	b_call(_Mov9B)
	ld	hl, fpLastChar
	ld	de, OP6
	b_call(_Mov9B)
	call	GetRandomInt
	ld	a, l
	cp	'#'
;	pop	ix
	jr	z, rglph
	ld	(ix+4), a
rclr:	; Random color
;	push	ix
	b_call(_OP1Set1)
	b_call(_OP1ToOP5)
	ld	hl, fp255
	ld	de, OP6
	b_call(_Mov9B)
	call	GetRandomInt
;	pop	ix
	ld	a, l
	ld	hl, colorsBlacklist
	ld	b, (hl)
	inc	hl
_:	cp	(hl)
	inc	hl
	jr	z, rclr
	djnz	-_
	ld	(ix+5), a
	; Loop control
	ld	de, 6
	add	ix, de
	ld	a, (stringStage)
	dec	a
	ld	(stringStage), a
	jp	nz, generateLoop
	ld	a, 255
	ld	(textForeColor), a
; Random location for kitten
; Just use the last generated random item
	ld	(ix-3), 255
	ld	(ix-4), 255

; Initial Location
	call	RandomLocation
	ld	(cursorY), de


;------ ------------------------------------------------------------------------


	
	
	
	ld	bc, (itemCount)
	call	RandRange16
	
; Generate NKIs
; Start game loop
	

	call	ClearScreen
	jp	Quit
	
	call	GetKey

;====== Routines ===============================================================
;------ TestCollision ----------------------------------------------------------
TestCollision:
; Tests if is an item at the given location.
; Input:
;  - D: X
;  - E: Y
; Output:
;  - C on collision
;  - NC if no collision
;  - HL points to object entry's itemId
;  - HL points to garbage otherwise
; Destroys:
;  - AF
;  - BC
	push	bc
	ld	hl, objectArray
	ld	a, (objectCount)
	ld	b, a
testCollisionLoop:
	ld	a, (hl)
	inc	hl
	cp	e
	ld	a, (hl)
	inc	hl
	jr	nz, +_
	cp	d
	jr	nz, +_
	scf
	pop	bc
	ret
_:	inc	hl
	inc	hl
	inc	hl
	inc	hl
	djnz	testCollisionLoop
	or	a
	pop	bc
	ret


;------ RandomLocation ---------------------------------------------------------
RandomLocation:
; Returns DE
;	push	ix
	call	Rand16
	ld	a, h
	and	1Fh
	ld	d, a
	ld	a, l
	and	0Fh
	ld	e, a
	call	TestCollision
	jr	c, RandomLocation
	ret


;------ OneSecondWait ----------------------------------------------------------
OneSecondWait:
; Does what it says.
; TODO
; Destroys:
;  - HL
;  - AF
	ld	hl, 0
	ld	(genFastTimer), hl
_:	ei
	halt
	ld	hl, (genFastTimer)
	ld	a, l
	or	h
	jr	nz, -_
	ret
