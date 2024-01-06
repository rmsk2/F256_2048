sid .namespace

SID_BASE = $D400


init
    ldx #0
    lda #0
_loopRegister
    sta SID_BASE, x
    inx
    cpx #25
    bne _loopRegister
    lda #15
    sta SID_BASE + 24                               ; volume at max
    rts

poke .macro  addr, val
    lda #\val
    sta \addr
.endmacro

; --------------------------------------------------
; beepIllegal gives feedback to the user that the chosen move was invalid
; 
; INPUT:  None
; OUTPUT: None
; --------------------------------------------------
beepIllegal
    #poke SID_BASE + 5, 9
    #poke SID_BASE + 6, 0
    #poke SID_BASE + 1, 25
    #poke SID_BASE, 177
    #poke SID_BASE + 4, 33
    jsr delay

    rts 

LO_COUNT .byte 0
MIDDLE_COUNT .byte 0
HI_COUNT .byte 0

; A simple counting loop to cause a delay in the program 
delay
    stz LO_COUNT
    stz MIDDLE_COUNT
    stz HI_COUNT
_loop
    inc LO_COUNT
    bne _loop
    inc MIDDLE_COUNT
    bne _loop
    inc HI_COUNT
    lda HI_COUNT
    cmp #2
    bne _loop
    rts   

; --------------------------------------------------
; beepOff turns off sound
; 
; INPUT:  None
; OUTPUT: None
; --------------------------------------------------
beepOff
    #poke SID_BASE + 4, 32
    rts

.endnamespace