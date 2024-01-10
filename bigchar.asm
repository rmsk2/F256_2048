printBigAt .macro x, y, colAddr, addr
    ldx #\x
    ldy #\y    
    #load16BitImmediate \addr, TXT_PTR5
    lda \colAddr
    jsr bigchar.printBigChar
.endmacro

printBigAtImpl .macro x, y, addr
    ldx #\x
    ldy #\y    
    #load16BitImmediate \addr, TXT_PTR5
    jsr bigchar.printBigCharImplicitColor
.endmacro

bigchar .namespace


BIG_TWO
.byte $20, $20, $20, $20, $20, $20, $20, $20 ; ________
.byte $20, $A0, $A0, $A0, $A0, $A0, $A0, $20 ; _******_
.byte $20, $20, $20, $20, $20, $A0, $A0, $20 ; _____**_
.byte $20, $20, $20, $20, $20, $A0, $A0, $20 ; _____**_
.byte $20, $A0, $A0, $A0, $A0, $A0, $A0, $20 ; _******_
.byte $20, $A0, $A0, $20, $20, $20, $20, $20 ; _**_____
.byte $20, $A0, $A0, $20, $20, $20, $20, $20 ; _**_____
.byte $20, $A0, $A0, $A0, $A0, $A0, $A0, $20 ; _******_

BIG_ONE
.byte $20, $20, $20, $20, $20, $20, $20, $20 ; ________
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $A0, $A0, $A0, $20, $20, $20 ; __***___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___**___
.byte $20, $20, $20, $A0, $A0, $20, $20, $20 ; ___***__
.byte $20, $20, $A0, $A0, $A0, $A0, $20, $20 ; __****__

BigCharState_t .struct 
    xCoord .byte 0
    yCoord .byte 0
    lineCount .byte 0
    col .byte 0
    revCol .byte 0
    fgCol .byte 0
    bgCol .byte 0
    temp .byte 0
.ends

BIG_CHAR_STATE .dstruct BigCharState_t

; x => x coord
; y => y coord
printBigCharImplicitColor
    stx BIG_CHAR_STATE.xCoord
    sty BIG_CHAR_STATE.yCoord
    stz BIG_CHAR_STATE.lineCount
    jmp cycleBigChar    

; x => x coord
; y => y coord
; accu => color code
; char data in address in TXT_PTR5
printBigChar
    stx BIG_CHAR_STATE.xCoord
    sty BIG_CHAR_STATE.yCoord
    stz BIG_CHAR_STATE.lineCount
    jsr setBigCharCol
cycleBigChar
    ldy #0
_lineDone
    lda BIG_CHAR_STATE.xCoord
    sta CURSOR_STATE.xPos
    lda BIG_CHAR_STATE.yCoord
    sta CURSOR_STATE.yPos
    jsr txtio.cursorSet
    ldx #0
_lineLoop
    lda (TXT_PTR5), y
    cmp #$A0
    beq _normal
    lda BIG_CHAR_STATE.col
    bra _outChar
_normal
    lda BIG_CHAR_STATE.revCol
_outChar    
    sta CURSOR_STATE.col
    lda #32
    jsr txtio.charOut
    iny
    inx
    cpx #08
    bne _lineLoop
    inc BIG_CHAR_STATE.yCoord
    inc BIG_CHAR_STATE.lineCount
    lda BIG_CHAR_STATE.lineCount
    cmp #8
    bne _lineDone
    rts

incForegroundCol
    lda BIG_CHAR_STATE.fgCol
    ina
    and #$0F
    sta BIG_CHAR_STATE.fgCol
    asl
    asl
    asl
    asl
    ora BIG_CHAR_STATE.bgCol
    sta BIG_CHAR_STATE.col
    lda BIG_CHAR_STATE.bgCol
    asl
    asl
    asl
    asl
    ora BIG_CHAR_STATE.fgCol
    sta BIG_CHAR_STATE.revCol
    rts

; accu => Color value
setBigCharCol
    sta BIG_CHAR_STATE.col
    and #$0F
    sta BIG_CHAR_STATE.bgCol
    asl
    asl
    asl
    asl
    sta BIG_CHAR_STATE.temp    
    lda BIG_CHAR_STATE.col
    lsr
    lsr
    lsr
    lsr
    sta BIG_CHAR_STATE.fgCol
    ora BIG_CHAR_STATE.temp
    sta BIG_CHAR_STATE.revCol
    rts

.endnamespace