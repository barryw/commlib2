.label NMINV   = $0318

.enum {b300=0,b1200=1,b2400=2,b4800=3,b7200=4,b9600=5,b14400=6,b19200=7}

.var baudSettings = List().add($00, $0d, $10, $0d, $34, $03, $42, $03, $97, $01, $a2, $01, $c7, $00, $d0, $00,
                               $85, $00, $8b, $00, $60, $00, $65, $00, $41, $00, $44, $00, $2f, $00, $32, $00)

// Return baud timing information as a word
.macro sbaud() {
  .byte baudSettings.get(baud * $04)
  .byte baudSettings.get(baud * $04 + $01)
}

.macro rbaud() {
  .byte baudSettings.get(baud * $04 + $02)
  .byte baudSettings.get(baud * $04 + $03)
}
