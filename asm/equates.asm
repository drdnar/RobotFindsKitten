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
foreColor	.equ	textColors
backColor	.equ	foreColor + 1
lcdRow		.equ	textColors + 3
lcdCol		.equ	lcdRow + 1
fontHeight	.equ	lcdCol + 3
fontWidthsPtr	.equ	fontHeight + 1
fontDataPtr	.equ	fontWidthsPtr + 3

ivtLocation	.equ	(pixelShadow2 + 8400 - 258) & 0FFFF00h
isrLocation	.equ	0D4D4D4h