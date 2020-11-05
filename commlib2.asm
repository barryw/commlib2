#import "cia.asm"
#import "vic.asm"
#import "kernal.asm"
#import "equates.asm"
#import "settings.asm"

*=$ca00 "commlib2"

*=* "Setup"
Setup:
  jmp setup

*=* "Uninstall"
Uninstall:
  jmp uninstall

*=* "Enable"
Enable:
  jmp enable

*=* "Disable"
Disable:
  jmp disable

*=* "PutByte"
PutByte:
  jmp putbyte

*=* "GetByte"
GetByte:
  jmp getbyte

*=* "SafePutByte"
SafePutByte:
  jmp safeputbyte

*=* "ASCIITable"
ASCIITable:
  jmp asciitable

*=* "Terminal"
Terminal:
  jmp terminal

*=* "SetSpeed"
SetSpeed:
  jmp speedselect

  .byte $00, $00

/*
Set everything up. Does not require anything to be passed to it.
*/
setup:
  sei
  lda #<irq
  sta NMINV
  lda #>irq
  sta NMINV + $01
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
  sta inbsta + $01
  sta inbend + $01
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

  .for(var i = 0; i < 7; i++) {
    .byte $00
  }

/*
Uninstall and exit
*/
uninstall:
  sei
  lda #$7f
  sta cia.CI2ICR
  lda #<kernal.NMIINT + $04
  sta NMINV
  lda #>kernal.NMIINT + $04
  sta NMINV + $01
  lda cia.CI2PRA
  ora #$04
  sta cia.CI2PRA
  cli
  clc
  rts

/*
Disable flow control
*/
disable:
  bit flow
  bpl Lcaa1
  lda cia.CI2PRB
  and #$fd
  sta cia.CI2PRB
  bit flow
Lcaa1:
  bvc Lcaad
  lda #$13
  jsr putbyte
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

/*
Enable flow control
*/
enable:
  lda Terminal
  sta cia.TI2BLO
  lda sbaud
  sta cia.TI2ALO
  lda sbaud + $01
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
  jsr putbyte
Lcaed:
  clc
  rts

/*
Send the byte in the A register

A: the byte to send
*/
putbyte:
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
  jmp kernal.NMIINT + $13

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
  sta tmploc + $01
  lda inbend + $01
  sta tmploc + $02
  lda tempinp
tmploc:
  sta $7432
  inc inbend
  bne Lcbca
  inc inbend + $01
  clc
  lda inbuf
  adc inblen
  cmp inbend + $01
  beq Lcbc4
  bcs Lcbca
Lcbc4:
  lda inbuf
  sta inbend + $01
Lcbca:
  lda #$90
  sta cia.CI2ICR
  pla
  rti

/*
Wait for the VIC raster to be off-screen before sending a byte.
This allows you to use this library in conjunction with applications
that take advantage of the VIC-II.

A: byte to send
*/
safeputbyte:
  php
  pha
Lcbd3:
  lda vic.RASTER
  cmp #RASTER_BOTTOM
  bcs Lcbde
  cmp #RASTER_TOP
  bcs Lcbd3
Lcbde:
  jmp Lcaf1

/*
Set up baud rate.

A: value from 0 - 7 to specify baud. look in equates for baud rate enum
*/
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

/*
Receive a byte from RS-232. Returns the byte in the A register.
Sets the carry flag and returns $00 if there's nothing waiting.
*/
getbyte:
  lda inbsta
  cmp inbend
  bne Lcc0d
  lda inbsta + $01
  cmp inbend + $01
  bne Lcc0d
  sec
  lda #$00
  rts

Lcc0d:
  lda inbsta
  sta bufloc + $01
  lda inbsta + $01
  sta bufloc + $02
bufloc:
  lda INBUF
  sta input
  inc inbsta
  bne Lcc3e
  inc inbsta + $01
  clc
  lda inbuf
  adc inblen
  cmp inbsta + $01
  beq Lcc35
  bcs Lcc3b
Lcc35:
  lda inbuf
  sta inbsta + $01
Lcc3b:
  lda input
Lcc3e:
  clc
  rts

/*
Sets up an ASCII -> PETSCII lookup table
*/
asciitable:
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

/*
Runs a mini-terminal to test the library. Use CTRL-J to exit.
*/
terminal:
  jsr Setup
  lda #$0d
  jsr kernal.CHROUT
  lda #$00
  sta $19
  lda #$ce
  sta $1a
  jsr ASCIITable
Lccb0:
  jsr kernal.GETIN
  beq Lccbb
  tay
  lda ($19),y
  jsr PutByte
Lccbb:
  jsr GetByte
  bcs Lccc9
  tay
  lda ($19),y
  jsr kernal.CHROUT
  jmp Lccbb

Lccc9:
  lda cia.CIAPRA
  and #$10
  bne Lccb0
  jsr Uninstall
  clc
  rts

  .for(var i = 0; i<43; i++) {
    .byte $00
  }

/*
State storage
*/
busy:
  .byte $01
timeout:
  .byte $10
inbuf:
  .byte >INBUF
outbuf:
  .byte >OUTBUF
inblen:
  .byte $10
outblen:
  .byte $10
inbsta:
  .byte <INBUF, >INBUF
inbend:
  .byte <INBUF, >INBUF
outbsta:
  .byte <OUTBUF, >OUTBUF
outbend:
  .byte <OUTBUF, >OUTBUF
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
  sbaud()
rbaud:
  rbaud()
flow:
  .byte $00
loc01:
  .byte $c3
loc02:
  .byte $c3
loc10:
  .byte $c7
speed:
  .byte baud
extra:
  .byte $00
timings:
  .for(var i = 0; i<32; i++) {
    .byte baudSettings.get(i)
  }
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

  .for(var i = 0; i<32; i++) {
    .byte $00
  }
