random .namespace

RNG_LO = $D6A4
RNG_HI = $D6A5
RNG_CTRL = $D6A6

RAND_NIBBLES .fill 4

init
    rts

; get random 16 bit number in accu and x register
get
    phx
    lda RNG_CTRL
    ora #1
    sta RNG_CTRL
_wait
    lda RNG_CTRL
    beq _wait
    lda RNG_LO
    jsr splitByte
    sta RAND_NIBBLES
    stx RAND_NIBBLES+1
    lda RNG_HI
    jsr splitByte
    sta RAND_NIBBLES+2
    stx RAND_NIBBLES+3
    plx
    rts

.endnamespace