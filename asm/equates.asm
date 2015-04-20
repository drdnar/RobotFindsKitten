chQuotes	.equ	22h
chNewLine	.equ	01h
chEnter		.equ	01h
chTab		.equ	02h
chBackspace	.equ	03h
chDel		.equ	03h
ch1stPrintableChar	.equ	4

objTblOffset	.equ	12

;===============================================================================
;====== Vars ===================================================================
;===============================================================================

vars		.equ	pixelShadow2

savedSp		.equ	vars
; Text
textColors	.equ	savedSp + 3
textForeColor	.equ	textColors
textBackColor	.equ	foreColor + 1
lcdRow		.equ	textColors + 3
lcdCol		.equ	lcdRow + 1
fontHeight	.equ	lcdCol + 3
fontWidthsPtr	.equ	fontHeight + 1
fontDataPtr	.equ	fontWidthsPtr + 3
; Huffman & messages
dataFileLoc	.equ	fontDataPtr + 3
currentReadLoc	.equ	dataFileLoc + 3
huffmanTable	.equ	currentReadLoc + 3
itemCache	.equ	huffmanTable + 1024
itemCacheSize	.equ	1024
; Game
objectArray	.equ	itemCache + itemCacheSize
cursorY		.equ	objectArray + 1024
cursorX		.equ	cursorY + 1
randomVal	.equ	cursorX + 1
seed1		.equ	randomVal
seed2		.equ	randomVal + 2
rotationTimer	.equ	seed2 + 2
itemCount	.equ	rotationTimer + 1
objectCount	.equ	itemCount + 2
foundObject	.equ	objectCount + 1
stringOffset	.equ	foundObject + 1
stringStage	.equ	stringOffset + 2
scrollTimer	.equ	stringStage + 1
lastItemPtr	.equ	scrollTimer + 2
fpItems		.equ	lastItemPtr + 2
OP7		.equ	fpItems + 9
end_of_game_vars	.equ	OP7 + 9

ivtLocation	.equ	(pixelShadow2 + 8400 - 258) & 0FFFF00h
isrLocation	.equ	0D4D4D4h