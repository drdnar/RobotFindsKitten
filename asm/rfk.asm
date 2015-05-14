.assume ADL=1
#include "ti84pce.inc"
#include "equates.asm"

	.org	userMem - 2
	.db	tExtTok, tAsm84CeCmp

#ifdef	NEVER	
	ld	hl, blarg
	call	_PutS
	call	_NewLine
	ret
blarg:
	.db	"Blargh. ", 0
	
	call	GetKey
	cp	sk1
	jr	z, saveFlags
	
	ld	de, pixelShadow2
	ld	hl, 0D00000h
	ld	b, 255
_:	ld	a, (de)
	inc	de
	xor	(hl)
	inc	hl
	jr	z, +_
	push	hl
	push	de
	push	bc
	push	af
	ld	a, l
	call	DispByte
	pop	af
	call	DispByte
	ld	a, ','
	call	_PutC
	pop	bc
	pop	de
	pop	hl
_:	djnz	--_
	ret
	
saveFlags:
	ld	de, pixelShadow2
	ld	hl, 0D00000h
	ld	bc, 256
	ldir
	ret
#endif	
	
	call	_RunIndicOff
	
	; Some entropy
	ld	bc, 3
	ld	iy, ((1024 * 256) + (320 * 240 * 2)) / 256
	ld	hl, 0D00000h
_:	xor	a
_:	ld	de, (hl)
	add	hl, bc
	add	ix, de
	dec	a
	jr	nz, -_
	dec	iy
	ld	a, iyl
	or	iyh
	jr	nz, --_
	ld	iy, flags
	
	; Clear variables
	ld	de, vars
	or	a
	sbc	hl, hl
	add	hl, de
	inc	de
	ld	(hl), 0
	ld	bc, 255	; Just pick a number, I guess
	ldir
	
	; Save value from above
	ld	(seed1), ix
	call	GetRtcTimeLinear
	ld	(seed2), hl
	
	; Initialize short-mode routines
	call	InitializeRandomRoutines
	
	; Search for data file
	ld	hl, rfkDataName
	call	_Mov9ToOP1
	call	VerifyDataFile
	jr	nz, dataFileFound
	; Data file not found!
	ld	a, (iy + 44h)
	push	af
	res	2, (iy + 44h)
	ld	hl, dataNotFoundMsg
	call	_PutS
	call	_NewLine
	pop	af
	ld	(iy + 44h), a
	ret
	
dataFileFound:
	ld	(savedSp), sp
	; Get pointer to Huffman decode tree
	ld	hl, (itemsCount)
	add	hl, hl
	ld	de, objTblOffset
	add	hl, de
	ld	de, (dataFileLoc)
	add	hl, de
	ld	(huffmanTable), hl
	
	; Text driver
	ld	hl, fontWidthTable
	ld	(fontWidthsPtr), hl
	ld	hl, fontDataTable
	ld	(fontDataPtr), hl
	ld	a, (font)
	ld	(fontHeight), a
	call	SetTextMode
;	call	ClearScreen
	ld	a, 255
	ld	(textColors), a
	ld	hl, 0
	ld	(lcdRow), hl
	ld	(lcdCol), hl
	

TitleScreen:
	call	ClearScreen
	ld	hl, titleText
	call	PutS
	jp	RobotFindsKitten
	
	
	
Quit:
	call	GetKey
	
Panic:
	
	ld	iy, flags
	ld	sp, (savedSp)
	call	FixLcdMode
	ret


;------ VerifyDataFile ---------------------------------------------------------
VerifyDataFile:
; Returns:
;  - NZ if valid datafile
;  - Z if not valid datafile
datafileDataBase	.equ	19	; An empirical constant.  Basically, it comes from the format of archived items.
	call	_ChkFindSym
	jr	nc, +_
vdfz:	xor	a
	ret
	; Data file found!
_:	; Save location, short-term
	ld	(dataFileLoc), de
	; I need a flag for in-RAM status
	ex	de, hl
	ld	a, (dataFileLoc + 2)
	cp	0D0h
	jr	nc, +_
	; Is in flash
	ld	de, 9	; Size of flash var header
	add	hl, de
	ld	a, (hl)	; Name size byte
	inc	hl
	ld	e, a
	add	hl, de	; Skip name
_:	inc	hl
	inc	hl
	; Save file location
	ld	(dataFileLoc), hl
	; Check header
	ld	de, dataVerifyString
	ld	bc, 8FFh
_:	ld	a, (de)
	inc	de
	cp	(hl)
	inc	hl
	jr	nz, vdfz
	djnz	-_
	; Save the number of objects found
	ld	de, 0
	inc	hl
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	(itemsCount), de
	; Return NZ
	inc	a
	ret

#include "game.asm"
#include "dehuffman.asm"
#include "random.asm"
#include "text.asm"
#include "routines.asm"
#include "data.asm"
#include "font.asm"
