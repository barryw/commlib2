// Define the locations for input and output buffers.
// Each should be 4kb
.label INBUF   = $9000
.label OUTBUF  = $8000

// Where the safesend routine should check for raster locations
.const RASTER_TOP     = $2c
.const RASTER_BOTTOM  = $f2

// Specify the baud rate from the enum in equates.asm. This is only the
// default that the library is built with. The speed can still be set at
// runtime using a call to 'Speed'
.const baud = b2400
