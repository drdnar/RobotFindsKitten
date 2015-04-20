.assume ADL=1
#include "ti84pce.inc"
#include "equates.asm"


	.org	userMem - 2
	.db	tExtTok, tAsm84CeCmp

	call	_RunIndicOff
	
	ld	de, vars
	or	a
	sbc	hl, hl
	add	hl, de
	inc	de
	ld	(hl), 0
	ld	bc, 256
	ldir
	
	ld	(savedSp), sp
	ld	hl, fontWidthTable
	ld	(fontWidthsPtr), hl
	ld	hl, fontDataTable
	ld	(fontDataPtr), hl
	ld	a, (font)
	ld	(fontHeight), a
	
	call	ClearScreen

Quit:
	ld	sp, (savedSp)
	call	FixLcdMode
	ret

GetKey:
	call	_GetCSC
	or	a
	ret	nz
	jr	GetKey


#include "text.asm"
#include "routines.asm"
#include "font.asm"