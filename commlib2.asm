#import "cia.asm"
#import "vic.asm"

*=$ca00

Setup:
     jmp rsetup

Uninstall:
     jmp runinstall

Enable:
     jmp renable

Disable:
     jmp rdisable

Sendit:
     jmp rsendit

GetByte:
     jmp getbyt

PutByte:
     jmp safesend

ASCIITable:
     jmp rasciitable

Terminal:
     jmp rterminal

Speed:
     jmp speedselect

     .byte $00, $00

rsetup:
     sei
     lda #<irq
     sta $0318
     lda #>irq
     sta $0319
     ldy #$03
Lca2d:
     lda sbaud, y
     sta cia.TI2ALO, y
     dey
     bpl Lca2d
     lda #$7f
     sta cia.CI2ICR
     lda #$90
     sta cia.CI2ICR
     lda inbuf
     sta inbsta + 1
     sta inbend + 1
     iny
     sty inbsta
     sty inbend
     sty busy
     lda cia.CI2PRA
     and #$fb
     sta loc02
     ora #$04
     sta loc10
     sta cia.CI2PRA
     lda cia.C2DDRB
     and #$be
     ora #$02
     sta cia.C2DDRB
     cli
     rts

     .byte $00, $00, $00, $00, $00, $00, $00

runinstall:
     sei
     lda #$7f
     sta cia.CI2ICR
     lda #$47
     sta $0318
     lda #$fe
     sta $0319
     lda cia.CI2PRA
     ora #$04
     sta cia.CI2PRA
     cli
     clc
     rts

rdisable:
     bit flow
     bpl Lcaa1
     lda cia.CI2PRB
     and #$fd
     sta cia.CI2PRB
     bit flow
Lcaa1:
     bvc Lcaad
     lda #$13
     jsr rsendit
Lcaa8:
     lda busy
     bmi Lcaa8
Lcaad:
     lda #$7f
     sta cia.CI2ICR
     lda #$80
     sta busy
     clc
     rts

renable:
     lda Terminal
     sta cia.TI2BLO
     lda sbaud
     sta cia.TI2ALO
     lda sbaud + 1
     sta cia.TI2AHI
     sta cia.TI2BHI
     sta busy
     lda #$90
     sta cia.CI2ICR
     bit flow
     bpl Lcae6
     lda cia.CI2PRB
     ora #$02
     sta cia.CI2PRB
     bit flow
Lcae6:
     bvc Lcaed
     lda #$11
     jsr rsendit
Lcaed:
     clc
     rts

rsendit:
     php
     pha
Lcaf1:
     lda busy
     bmi Lcaf1
     sei
     lda #$81
     sta cia.CI2ICR
     lda #$11
     sta cia.CI2CRA
     lda #$08
     sta outidx
     lda #$80
     sta busy
     pla
     sta tempout
     lda loc02
     sta cia.CI2PRA
     lsr tempout
     bcc Lcb1d
     lda loc10
Lcb1d:
     sta loc01
     plp
     rts

nmidetect:
     sei
irq:
     pha
     lda cia.CI2ICR
     bpl Lcb65
     and #$03
     beq Lcb6e
     and #$02
     bne Lcb84
     lda loc01
     sta cia.CI2PRA
     lda loc10
     lsr tempout
     bcs Lcb42
     lda loc02
Lcb42:
     sta loc01
     dec outidx
     bmi Lcb56
     beq Lcb4e
     pla
     rti

Lcb4e:
     lda loc10
     sta loc01
     pla
     rti

Lcb56:
     lda #$10
     sta cia.CI2CRA
     lda #$01
     sta cia.CI2ICR
     sta busy
     pla
     rti

Lcb65:
     txa
     pha
     tya
     pha
     ldy #$00
     jmp $fe56

Lcb6e:
     lda #$11
     sta cia.CI2CRB
     lda #$10
     sta cia.CI2ICR
     lda #$82
     sta cia.CI2ICR
     lda #$08
     sta inpidx
     pla
     rti

Lcb84:
     lda cia.CI2PRB
     lsr
     ror tempinp
     dec inpidx
     beq Lcb92
     pla
     rti

Lcb92:
     lda #$02
     sta cia.CI2ICR
     lda #$10
     sta cia.CI2CRB
     lda inbend
     sta tmploc + 1
     lda inbend + 1
     sta tmploc + 2
     lda tempinp
tmploc:
     sta $7432
     inc inbend
     bne Lcbca
     inc inbend + 1
     clc
     lda inbuf
     adc inblen
     cmp inbend + 1
     beq Lcbc4
     bcs Lcbca
Lcbc4:
     lda inbuf
     sta inbend + 1
Lcbca:
     lda #$90
     sta cia.CI2ICR
     pla
     rti

safesend:
     php
     pha
Lcbd3:
     lda vic.RASTER
     cmp #$f2
     bcs Lcbde
     cmp #$2c
     bcs Lcbd3
Lcbde:
     jmp Lcaf1

speedselect:
     sta speed
     asl
     asl
     tay
     ldx #$00
Lcbe9:
     lda timings,y
     sta sbaud,x
     sta cia.TI2ALO, x
     iny
     inx
     cpx #$04
     bne Lcbe9
     rts

getbyt:
     lda inbsta
     cmp inbend
     bne Lcc0d
     lda inbsta + 1
     cmp inbend + 1
     bne Lcc0d
     sec
     lda #$00
     rts

Lcc0d:
     lda inbsta
     sta bufloc + 1
     lda inbsta + 1
     sta bufloc + 2
bufloc:
     lda $9000
     sta input
     inc inbsta
     bne Lcc3e
     inc inbsta + 1
     clc
     lda inbuf
     adc inblen
     cmp inbsta + 1
     beq Lcc35
     bcs Lcc3b
Lcc35:
     lda inbuf
     sta inbsta + 1
Lcc3b:
     lda input
Lcc3e:
     clc
     rts

rasciitable:
     cmp #$04
     bcc Lcc8c
     cmp #$d0
     bcc Lcc4c
     cmp #$e0
     bcc Lcc8c
Lcc4c:
     tay
     lda $19
     pha
     lda $1a
     pha
     sty $1a
     lda #$00
     sta $19
     ldy #$7f
Lcc5b:
     tya
     sta ($19),y
     dey
     bpl Lcc5b
     ldy #$5a
Lcc63:
     tya
     ora #$20
     sta ($19),y
     dey
     cpy #$40
     bne Lcc63
     ldy #$7a
Lcc6f:
     tya
     and #$df
     sta ($19),y
     dey
     cpy #$60
     bne Lcc6f
     ldy #$da
Lcc7b:
     tya
     and #$5f
     sta ($19),y
     dey
     cpy #$bf
     bne Lcc7b
     ldy #$08
     lda #$14
     sta ($19),y
     tay
Lcc8c:
     lda #$08
     sta ($19),y
     pla
     sta $1a
     pla
     sta $19
     clc
     rts

     .byte $00, $00, $00, $00, $00

rterminal:
     jsr Setup
     lda #$0d
     jsr $ffd2
     lda #$00
     sta $19
     lda #$ce
     sta $1a
     jsr ASCIITable
Lccb0:
     jsr $ffe4
     beq Lccbb
     tay
     lda ($19),y
     jsr Sendit
Lccbb:
     jsr GetByte
     bcs Lccc9
     tay
     lda ($19),y
     jsr $ffd2
     jmp Lccbb

Lccc9:
     lda cia.CIAPRA
     and #$10
     bne Lccb0
     jsr Uninstall
     clc
     rts

     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
busy:
     .byte $01
timeout:
     .byte $10
inbuf:
     .byte $90
outbuf:
     .byte $80
inblen:
     .byte $10
outblen:
     .byte $10
inbsta:
     .byte $00, $90
inbend:
     .byte $00, $90
outbsta:
     .byte $00, $80
outbend:
     .byte $00, $80
inplock:
     .byte $00
outlock:
     .byte $00
input:
     .byte $0a
output:
     .byte $00
tempinp:
     .byte $0a
tempout:
     .byte $00
inpidx:
     .byte $00
outidx:
     .byte $ff
sbaud:
     .byte $97, $01
rbaud:
     .byte $a2, $01
flow:
     .byte $00
loc01:
     .byte $c3
loc02:
     .byte $c3
loc10:
     .byte $c7
speed:
     .byte $02
extra:
     .byte $00
timings:
     .byte $00, $0d, $10, $0d, $34, $03, $42, $03, $97, $01, $a2, $01, $c7, $00, $d0, $00
     .byte $85, $00, $8b, $00, $60, $00, $65, $00, $41, $00, $44, $00, $2f, $00, $32, $00
     .text @"READ THE MANUAL\$0d"
     .text @"OR AT   LEAST   THIS:  \$0d"
     .text @"ROUTINES JUMP   TABLE: \$0d"
     .text @"FROM    $CA00 TO $CA1F \$0d"
     .text @"SETUP  \$0d"
     .text @"UNINSTL\$0d"
     .text @"ENABLE \$0d"
     .text @"DISABLE\$0d"
     .text @"SENDIT \$0d"
     .text @"GETBYT \$0d"
     .text @"PUTBYT \$0d"
     .text @"ASCTABL\$0d"
     .text @"TERM   \$0d"
     .text @"SPEED \$0d\$0d"
     .text @"THE A REGISTER  PASSES  CHARS. \$0d"
     .text @"$9000 IS4K BUFF\$0d"
     .text @"$CD00-  ARE SETTINGS   \$0d"
     .text @"CD1A IS FLOW CNT$00=NONE$80=RTS $40=XON $C0=BOTH       \$0d"
     .text @"ENA/DIS CONTROLSTHE FLOW       \$0d"
     .text @"TERM IS EXAMPLE TERMINALPROGRAM\$0d"
     .text @"CTRL-J  QUITS \$0d\$0d"
     .text @"       \$0d"
     .text @"BY ILKER  1997 \$0d"

     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
     .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00