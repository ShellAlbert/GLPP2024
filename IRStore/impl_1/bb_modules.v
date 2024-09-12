`timescale 100 ps/100 ps
module HSOSC (
  CLKHFPU,
  CLKHFEN,
  CLKHF
)
;
input CLKHFPU ;
input CLKHFEN ;
output CLKHF ;
endmodule /* HSOSC */

module PLL_B (
  REFERENCECLK,
  FEEDBACK,
  DYNAMICDELAY7,
  DYNAMICDELAY6,
  DYNAMICDELAY5,
  DYNAMICDELAY4,
  DYNAMICDELAY3,
  DYNAMICDELAY2,
  DYNAMICDELAY1,
  DYNAMICDELAY0,
  BYPASS,
  RESET_N,
  SCLK,
  SDI,
  LATCH,
  INTFBOUT,
  OUTCORE,
  OUTGLOBAL,
  OUTCOREB,
  OUTGLOBALB,
  SDO,
  LOCK
)
;
input REFERENCECLK ;
input FEEDBACK ;
input DYNAMICDELAY7 ;
input DYNAMICDELAY6 ;
input DYNAMICDELAY5 ;
input DYNAMICDELAY4 ;
input DYNAMICDELAY3 ;
input DYNAMICDELAY2 ;
input DYNAMICDELAY1 ;
input DYNAMICDELAY0 ;
input BYPASS ;
input RESET_N ;
input SCLK ;
input SDI ;
input LATCH ;
output INTFBOUT ;
output OUTCORE ;
output OUTGLOBAL ;
output OUTCOREB ;
output OUTGLOBALB ;
output SDO ;
output LOCK ;
endmodule /* PLL_B */

module IOL_B (
  PADDI,
  DO1,
  DO0,
  CE,
  IOLTO,
  HOLD,
  INCLK,
  OUTCLK,
  PADDO,
  PADDT,
  DI1,
  DI0
)
;
input PADDI ;
input DO1 ;
input DO0 ;
input CE ;
input IOLTO ;
input HOLD ;
input INCLK ;
input OUTCLK ;
output PADDO ;
output PADDT ;
output DI1 ;
output DI0 ;
endmodule /* IOL_B */

