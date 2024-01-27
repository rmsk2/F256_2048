

SPR_SIZE_8 = 64 | 32
SPR_SIZE_16 = 64
SPR_SIZE_24 = 32
SPR_SIZE_32 = 0

SPR_LAYER_0 = 0
SPR_LAYER_1 = 8
SPR_LAYER_2 = 16
SPR_LAYER_3 = 16 | 8

SPR_LUT_0 = 0
SPR_LUT_1 = 2
SPR_LUT_2 = 4
SPR_LUT_3 = 2 | 4

SPR_ENABLE = %00000001
SPR_DISABLE = ~SPR_ENABLE

SpriteBlock_t .struct 
    control .byte ?
    addr .long ?
    xpos .word ?
    ypos .word ?
.endstruct


setSpritePtr .macro sprnum
    lda #\sprnum
    jsr callSetSpritePointer
.endmacro

sprites .namespace

BIT_TEXT = 1
BIT_OVERLY = 2
BIT_GRAPH = 4
BIT_BITMAP = 8
BIT_TILE = 16
BIT_SPRITE = 32
BIT_GAMMA = 64
BIT_X = 128

BIT_CLK_70 = 1
BIT_DBL_X = 2
BIT_DBL_Y = 4
BIT_MON_SLP = 8 
BIT_FON_OVLY = 16
BIT_FON_SET = 32

activate
    lda #BIT_TEXT | BIT_OVERLY | BIT_SPRITE | BIT_GRAPH
    sta $D000
    lda #0
    sta $D001
    rts


deactivate
    lda #BIT_TEXT
    sta $D000
    lda #$00
    sta $D001    
    rts


init
    ldy #0
_loop
    tya
    jsr callSetSpritePointer
    jsr Off
    iny
    cpy #16
    bne _loop
    jsr setPositions
    jsr activate
    rts

; a contains 0-15 after routins SPRITE_PTR1  is set to addrss
; of corresponding sprite block
callSetSpritePointer
    asl
    asl
    asl
    sta SPRITE_PTR1
    lda #$D9
    sta SPRITE_PTR1+1
    rts

; SPRITE_PTR1 is set to correct block
On
    lda #SPR_SIZE_32 | SPR_LAYER_0 | SPR_LUT_0 | SPR_ENABLE
    sta (SPRITE_PTR1)
    rts

; SPRITE_PTR1 is set to correct block
Off
    lda #SPR_SIZE_32 | SPR_LAYER_0 | SPR_LUT_0 
    sta (SPRITE_PTR1)
    rts    


SPR_DATA_ADDR
.word 0
.word 1 * 1024
.word 2 * 1024
.word 3 * 1024
.word 4 * 1024
.word 5 * 1024
.word 6 * 1024
.word 7 * 1024
.word 8 * 1024
.word 9 * 1024
.word 10 * 1024
.word 11 * 1024
.word 12 * 1024

; SPRITE_PTR1 is set to correct block
; accu contains value on playfield
setBitmapAddr    
    cmp #0
    bne _changeAddr
    jsr Off
    rts
_changeAddr
    phx
    phy    
    dea
    asl
    tax
    ldy #SpriteBlock_t.addr
    lda SPR_DATA_ADDR, x
    sta (SPRITE_PTR1), y
    inx
    iny
    lda SPR_DATA_ADDR, x
    sta (SPRITE_PTR1), y
    iny
    lda #2
    sta (SPRITE_PTR1), y
    jsr On
    ply
    plx
    rts

X_OFFSET = 79 + 32
Y_OFFSET = 41 + 32

XPOSITIONS
.word X_OFFSET
.word X_OFFSET + 1 * (32 + 4)
.word X_OFFSET + 2 * (32 + 4)
.word X_OFFSET + 3 * (32 + 4)

YPOSITIONS
.word Y_OFFSET
.word Y_OFFSET + 1 * (32 + 4)
.word Y_OFFSET + 2 * (32 + 4)
.word Y_OFFSET + 3 * (32 + 4)

XCOUNT .byte 0
YCOUNT .byte 0
SCOUNT .byte 0

setPositions
    stz XCOUNT
    stz YCOUNT
    stz SCOUNT
    phy
    phx

_sprLoop
    lda SCOUNT
    jsr callSetSpritePointer

    lda XCOUNT
    asl
    tax
    ldy #SpriteBlock_t.xpos
    lda XPOSITIONS, x
    sta (SPRITE_PTR1), y
    inx
    iny
    lda XPOSITIONS, x
    sta (SPRITE_PTR1), y
    
    lda YCOUNT
    asl
    tax
    ldy #SpriteBlock_t.ypos
    lda YPOSITIONS, x
    sta (SPRITE_PTR1), y
    inx
    iny
    lda YPOSITIONS, x
    sta (SPRITE_PTR1), y

    inc SCOUNT

    inc XCOUNT
    lda XCOUNT
    cmp #4
    bne _sprLoop

    stz XCOUNT
    inc YCOUNT
    lda YCOUNT
    cmp #4
    bne _sprLoop
    plx
    ply
    rts

.endnamespace