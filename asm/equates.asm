charWidth = 9
charHeight = 14
textRows = 17
textCols = 35

chQuotes	.equ	22h
chNewLine	.equ	01h
chEnter		.equ	01h
chTab		.equ	02h
chBackspace	.equ	03h
chDel		.equ	03h
ch1stPrintableChar	.equ	4

;===============================================================================
;====== Vars ===================================================================
;===============================================================================

vars		.equ	pixelShadow2

savedSp		.equ	vars
textColors	.equ	savedSp + 3
currentRow	.equ	textColors + 4
currentCol	.equ	currentRow + 1
tabPos1		.equ	currentCol + 2
tabPos2		.equ	tabPos1 + 1
tabPos3		.equ	tabPos2 + 1
tabPos4		.equ	tabPos3 + 1
windTop		.equ	tabPos4 + 1
windLeft	.equ	windTop + 1
windBottom	.equ	windLeft + 2
windRight	.equ	windBottom + 1
maxRow		.equ	windRight + 2
maxCol		.equ	maxRow + 1
fontDataPtr	.equ	maxCol + 2
fontWidth	.equ	fontDataPtr + 3
fontHeight	.equ	fontWidth + 1
fontCharLength	.equ	fontHeight + 1
fontLineSize	.equ	fontCharLength + 1
asciiBufferPtr	.equ	fontLineSize + 3
asciiBufferMain	.equ	asciiBufferPtr + 3	; Should be at least 1590 bytes (53 x 30 bytes for 6x8 character cell)

ivtLocation	.equ	(pixelShadow2 + 8400 - 258) & 0FFFF00h
isrLocation	.equ	0D4D4D4h