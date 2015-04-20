; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://sam.zoy.org/wtfpl/COPYING for more details.


;------ GetMessage -------------------------------------------------------------
GetMessage:
; Input:
;  - HL: Item number to fetch
; Output:
;  - Item text decompressed to itemCache
; Destroys:
;  - Everything
	; Get pointer to message
	add	hl, hl
	ld	de, objTblOffset
	add	hl, de
	ld	de, (dataFileLoc)
	add	hl, de
	ld	de, 0
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	de, (dataFileLoc)
	add	hl, de
	ld	(currentReadLoc), hl
	ld	a, 1
	ld	(currentBit), a
DeHuffman:
; Need:
;  - HL: Pointer to Huffman table entry
;  - DE: Pointer to string being generated.
	ld	ix, itemCacheSize
	ld	de, itemCache
deHuffmanLoop:	
	ld	hl, huffmanTable
deHuffmanInnerLoop:
	ld	a, (hl)
	bit	7, a
	jr	nz, deHuffmanDone
	call	HuffmanGetNextBit
	jr	z, +_
	inc	hl
_:	ld	bc, 0
	ld	c, (hl)
	add	hl, bc
	jr	deHuffmanInnerLoop
deHuffmanDone:
	and	7Fh
	ld	(de), a
	dec	ix
	ld	a, ixh
	or	ixl
	jp	z, Panic
	ld	a, (de)
	inc	de
	or	a
	jr	nz, deHuffmanLoop
	ret
	
	
;------ HuffmanGetNextBit ------------------------------------------------------
HuffmanGetNextBit:
; Gets the next bit from the Huffman code stream.
; Inputs:
;  - Memory locations
; Output:
;  - A is zero and z flag is set if next bit is zero.
;  - A is non-zero and z flag is reset if next bit 1.
; Destroys:
;  - Nothing
	push	hl
	push	de
	push	bc
	ld	a, (currentBit)
	dec	a
	jr	nz, +_
	ld	hl, (currentReadLoc)
	ld	a, (hl)
	inc	hl
	ld	(currentByte), a
	ld	(currentReadLoc), hl
	ld	a, 8
_:	ld	(currentBit), a
	ld	a, (currentByte)
	rrca
	ld	(currentByte), a
	sbc	a, a
	pop	bc
	pop	de
	pop	hl
	ret