random .namespace

RNG_LO = $D6A4
RNG_HI = $D6A5
RNG_CTRL = $D6A6

RAND_NIBBLES .fill 4
SEED_VAL_LO .byte 0
SEED_VAL_HI .byte 0

init
    jsr kGetTimeStamp
    lda RTC_BUFFER.centis
    sta SEED_VAL_LO
    lda RTC_BUFFER.seconds
    sta SEED_VAL_HI

    lda $D651
    eor SEED_VAL_LO
    sta SEED_VAL_LO

    lda $D659
    eor SEED_VAL_HI
    sta SEED_VAL_HI

    clc
    lda $D01A
    adc SEED_VAL_LO
    sta SEED_VAL_LO

    clc
    lda $D018
    adc SEED_VAL_HI
    sta SEED_VAL_HI

    lda SEED_VAL_LO
    sta RNG_LO
    lda SEED_VAL_HI
    sta RNG_HI
    lda #2
    sta RNG_CTRL

    rts

; get random 16 bit number in accu and x register
get
    phx
    lda #1
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