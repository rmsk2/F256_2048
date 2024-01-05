rectParam_t .struct txtrect
    xpos      .byte 0                                   ; xpos of left upper edge
    ypos      .byte 0                                   ; ypos of the left upper edge
    lenx      .byte 0                                   ; number of characters between the left and right edge
    leny      .byte 0                                   ; number of characters between the upper and lower edge
    col       .byte 0                                   ; colour to use (4 bit foreground and 4 bit background colour)
    overwrite .byte 0                                   ; set to 1 to clear the contents of the rectangle. Use 0 to leave the contents untouched
.endstruct

RECT_PARAMS .dstruct rectParam_t

DRAW_TRUE = 1
DRAW_FALSE = 0

txtrect .namespace

drawParam_t .struct  leftMost, middle, rightMost
    left    .byte \leftMost
    middle  .byte \middle
    right   .byte \rightMost
.endstruct


BLANK_CHAR = 32
LEFT_UPPER_CHAR = 160
RIGHT_UPPER_CHAR = 161
MIDDLE_UPPER_CHAR = 150
LEFT_MIDDLE_CHAR = 130
RIGHT_MIDDLE_CHAR = 130
LEFT_LOWER_CHAR = 162
RIGHT_LOWER_CHAR = 163
MIDDLE_LOWER_CHAR = 150


UPPER_LINE  .dstruct drawParam_t, LEFT_UPPER_CHAR, MIDDLE_UPPER_CHAR, RIGHT_UPPER_CHAR
LOWER_LINE  .dstruct drawParam_t, LEFT_LOWER_CHAR, MIDDLE_LOWER_CHAR, RIGHT_LOWER_CHAR
MIDDLE_LINE .dstruct drawParam_t, LEFT_MIDDLE_CHAR, BLANK_CHAR, RIGHT_MIDDLE_CHAR
CLEAR_LINE  .dstruct drawParam_t, BLANK_CHAR, BLANK_CHAR, BLANK_CHAR
WORKING_LINE .dstruct drawParam_t, 0, 0, 0

IO_STATE .byte 0
OFFSET .byte 0, 0
LEN_X_COUNT .byte 0
LEN_Y_COUNT .byte 0
DRAW_MIDDLE .byte 0

moveToNextChar .macro
    inx                                                         ; increment draw pos
    #inc16Bit TXT_DRAW_PTR1                                     ; increment memory pointer
.endmacro

YPOS_HELP .byte 0
; --------------------------------------------------
; This routine calculates the memory address of the cursor positon that
; is given by RECT_PARAMS.xpos and the contents of the Y-register.
;
; This routine does not return a value but as a side effect it stores the
; calculated address at the location OFFSET.
; --------------------------------------------------
calcStartOffset
    sty YPOS_HELP    
    #calcMemoryOffset RECT_PARAMS.xpos, YPOS_HELP, OFFSET
    rts

; --------------------------------------------------
; This routine draws a line on the text screen beginning at the coordinate that
; is defined by RECT_PARAMS.xpos and the contents of the Y-register. The line
; consists of single characters on the left and right end and a number of characters
; in the middle. The value of these characters is read from WORKING_LINE. The
; color RAM is filled with the value given in RECT_PARAMS.col. The number of middle 
; characters written is determined by RECT_PARAMS.lenx.
;
; This routine does not return a value.
; --------------------------------------------------
drawLine
    ; x contains current x pos. X has to be < 80
    ldx RECT_PARAMS.xpos
    ; LEN_X_COUNT contains number of middle characters already processed in this line
    ; LEN_X_COUNT has to be < RECT_PARAMS.lenx
    stz LEN_X_COUNT

    ; save current IO state
    lda $01
    sta IO_STATE

    ; calculate start address in text and colour memory
    jsr calcStartOffset
    #move16Bit OFFSET, TXT_DRAW_PTR1
    
    ; store leftmost character and its colour in memory
    #toTxtMatrix
    lda WORKING_LINE.left
    sta (TXT_DRAW_PTR1)
    #toColorMatrix
    lda RECT_PARAMS.col 
    sta (TXT_DRAW_PTR1)

    ; move to next character
    #moveToNextChar

    ; write all the characters in the middle
_loopMiddle
    ;cpx #X_MAX                                                 ; Have we left the screen?
    cpx CURSOR_STATE.xMax                                       ; Have we left the screen?
    bcs _lineDone                                               ; Yes, we have reached the right border => we are done
    lda LEN_X_COUNT
    cmp RECT_PARAMS.lenx                                        ; Have we drawn all middle characters?
    bcs _middleDone                                             ; We have drawn all middle characters => draw right edge
    lda DRAW_MIDDLE                                             ; do we actually draw the contents?
    beq _nextChar                                               ; no => on to next char
    #toTxtMatrix
    lda WORKING_LINE.middle
    sta (TXT_DRAW_PTR1)
    #toColorMatrix
    lda RECT_PARAMS.col
    sta (TXT_DRAW_PTR1)
_nextChar
    ; move to next character
    #moveToNextChar
    inc LEN_X_COUNT                                             ; increment counter for middle characters
    bra _loopMiddle
    ; if we get here then x is still <= 79
    ; otherwise the check at _loopMiddle would have resulted
    ; in a branch to _lineDone.
_middleDone
    #toTxtMatrix
    ; write rightmost character and its colour
    lda WORKING_LINE.right
    sta (TXT_DRAW_PTR1)
    #toColorMatrix
    lda RECT_PARAMS.col
    sta (TXT_DRAW_PTR1)
_lineDone
    ; restore original IO state
    lda IO_STATE
    sta $01
    rts

; --------------------------------------------------
; This macro sets the contents of WORKING_LINE, i.e. the actual characters
; which are used to draw the leftmost and rightmost chars of the line as
; well as all characters in the middle of the current line.
; --------------------------------------------------
setDrawParams .macro params
    lda \params
    sta txtrect.WORKING_LINE.left
    lda \params+1
    sta txtrect.WORKING_LINE.middle
    lda \params+2
    sta txtrect.WORKING_LINE.right
.endmacro

; --------------------------------------------------
; This macro calls drawLine for all y positions between RECT_PARAMS.ypos and
; RECT_PARAMS.ypos+RECT_PARAMS.leny where all these line start at 
; RECT_PARAMS.xpos. It can be parameterized by the character sets which
; are to be used on the first or UPPER line, the last or LOWER line and for
; all lines in between (the MIDDLE lines).
; --------------------------------------------------
makeRect .macro UPPER, MIDDLE, LOWER
    ; the Y-register contains the current y position which is used for
    ; drawing
    ldy RECT_PARAMS.ypos
    ; LEN_Y_COUNT counts the number of middle lines that have been process until now
    stz txtrect.LEN_Y_COUNT
    #setDrawParams \UPPER                                                            ; set draw characters for the first line  
    lda #DRAW_TRUE
    sta txtrect.DRAW_MIDDLE                                                          ; we always draw the middle characters of the first line
    jsr txtrect.drawLine    
    #setDrawParams \MIDDLE                                                           ; set draw characters for the middle lines
    iny
    ; Load and store the value provided by the caller which decides whether
    ; the middle characters are actually drawn or are simply skipped.
    lda RECT_PARAMS.overwrite
    sta txtrect.DRAW_MIDDLE
    ; draw all middle lines
_loopLine
    ;cpy #txtrect.Y_MAX                                                              
    cpy CURSOR_STATE.yMax                                                            ; have we left the screen?
    bcs _rectDone                                                                    ; Yes => we are done
    lda txtrect.LEN_Y_COUNT
    cmp RECT_PARAMS.leny                                                             ; have we drawn all middle lines?
    bcs _middleDone                                                                  ; Yes => draw last line
    jsr txtrect.drawLine                                                             ; draw a middle line
    iny
    inc txtrect.LEN_Y_COUNT
    bra _loopLine
_middleDone
    ; draw last line
    #setDrawParams \LOWER                                                            ; set draw characters for last line
    lda #DRAW_TRUE                                                                   ; we always draw the middle characters of the last line
    sta txtrect.DRAW_MIDDLE
    jsr txtrect.drawLine
_rectDone
.endmacro

; --------------------------------------------------
; This routine draws a rectangle with text characters on the text screen. The draw
; parameters have to be stored by the caller in the rectParam_t struct stored at
; RECT_PARAMS.
;
; This routine does not return a value.
; --------------------------------------------------
drawRect
    #makeRect txtrect.UPPER_LINE, txtrect.MIDDLE_LINE, txtrect.LOWER_LINE
    rts


; --------------------------------------------------
; This routine clears (i.e. fills with blank characters) a rectangle on the text screen.
; The draw parameters have to be stored by the caller in the rectParam_t struct stored at
; RECT_PARAMS.
;
; This routine does not return a value.
; --------------------------------------------------
clearRect
    #makeRect txtrect.CLEAR_LINE, txtrect.CLEAR_LINE, txtrect.CLEAR_LINE
    rts


.endnamespace