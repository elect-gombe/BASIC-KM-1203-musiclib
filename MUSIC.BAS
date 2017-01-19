rem ===raw audio player===

rem Copyright 2017, gombe all right reserved.

rem   This software is free software
rem and there is NO WARRANTY.
rem   No restriction on use. You can
rem use, modify and redistribute it
rem under your responsibility.
rem   Redistribution of source code 
rem must retain the above copyright
rem notice.

rem for BASIC KM-1203 or later.
rem (use SD library.)

rem   without LPF, AMP may be damaged.

rem in>-----+---------->output
rem         |
rem         = C
rem         |
rem         - (Ground)
rem C is 0.01uF or so.

rem c : count playing
rem s : sound buff(1024*2) 

rem ==sound data format==
rem sampling    : 32KHz
rem channel     : 1ch
rem resolution  : 8bit
rem data format : raw
rem size        : 1024*2 Byte

rem ==system specific==
rem DMA         : use ch 1
rem PWM         : use OC4
rem PWMtimebase : use tmr3
rem DMATimeBase : use tmr4
rem clock freq  : 3.58*16

rem ==memo==
rem  If you want to use graphic mode,
rem you must reculculate DMATimeBase.

rem  If you want to make audio data,
rem you should use sox command.
rem $ sox <in> -r32000 -c1 -b8 -u <out>.raw

rem  If you play premade data, you 
rem can use aplay command.
rem $ aplay <in> -r32000


label main
  cls
  var i,a
  DIM S(512)
rem pwm setup
  gosub setpwm
rem time base setup
  gosub setbst
rem dma setup
  gosub setdma,S,2048

  for i=0 to 1024*2
rem set default data
    poke s+i,0x7F AND 0xFF
  next

rem init for music
  gosub inimus,"music.raw"

  cursor 0,0
  color 7
  print "music.raw"
  print "Hit any key to abort"

  while 1
rem call music task
    wait 1
    gosub dsptim
    gosub mustas
rem hit any key to exit
    if inkey() then gosub finmus
  wend

end

rem display time @(0,3)
label dsptim
  var s
  s = c * 2048 / 32000
  cursor 0,3
  color 7
  print s/60%10;":";s%60/10;s%60%10
return

rem ==DMA addresses==
rem for common register
  rem DMACON     0xBF883000 : 0
  rem DMASTAT    0xBF883010 : 1
  rem DMAADDR    0xBF883020 : 2

rem for each cannel
  rem DCH0CON    0xBF883060 : 0
  rem DCH0ECON   0xBF883070 : 1
  rem DCH0INT    0xBF883080 : 2
  rem DCH0SSA    0xBF883090 : 3
  rem DCH0DSA    0xBF8830A0 : 4
  rem DCH0SSIZ   0xBF8830B0 : 5
  rem DCH0DSIZ   0xBF8830C0 : 6
  rem DCH0SPTR   0xBF8830D0 : 7
  rem DCH0DPTR   0xBF8830E0 : 8
  rem DCH0CSIZ   0xBF8830F0 : 9
  rem DCH0CPTR   0xBF883100 : 10

rem maskoffs
  rem none   : 0
  rem clear  : 1
  rem set    : 2
  rem invers : 3

rem dma init
rem args(1):buff pointer
rem args(2):size of buff[byte]

rem DMAMode     : auto
rem trigger     : TMR4IRQ
rem DMAchannel  : ch0
rem source      : buff
rem destination : OC4RS

label setdma
  var A
rem dma on
  A = 0xBF883000
  A((0*4+2)) = 0x00008000
  A = 0xBF883060
rem enable ch0 (auto mode,pri lv=2)
  A(0*4+0) = 0x00000012
rem transfer @irq tmr4(19)
  A((1*4+0)) = (19<<8)OR(1<<4)
rem set source addr
  A((3*4+0)) = ARGS(1) AND 0x1FFFFFFF
rem set dest addr OC4RS
  A((4*4+0)) = 0xBF803620 AND 0x1FFFFFFF
rem set source size [0(as 65536)-65535]
  A((5*4+0)) = ARGS(2)
rem set dist size
  A((6*4+0)) = 1
rem set cell size
  A((9*4+0)) = 1
  gosub clrflg
rem turn on dma ch0
  A(0*4+2) = 0x00000080
return

rem dma abort
label dmaabo
rem force abort
  var A
  A = 0xBF883060
  A((1*4+2)) =(1<<6)
return

rem dma clear if flags
label clrflg
rem clear if flags(Half and full trans)
  var A
  A = 0xBF883060
  A((2*4+1)) = 0x00FF00FF
return

rem dma trans half?
label dmishf
  var A
  A = 0xBF883080
return A(0) AND (1 << 6)

rem dma trans finished?
label dmisfi
  var A
  A = 0xBF883080
return A(0) AND (1 << 7)

rem set base timer(timer4)
rem to generate interval (sampling rate 32kHz)
label setbst
  var A
  A = 0xBF800C00
  A((0*4+0)) = 0x00000000
rem TMR4 reset
  A((1*4+0)) = 0x0000
rem PR4 set 3.58*16MHz/32kHz = 1790
  A((2*4+0)) = 1790
rem disable interrupt
  A = 0xBF881060
  A(0*4+1) = 0x00080000
rem tmr start
  A = 0xBF800C00
  A((0*4+2)) = 0x00008000
return

label setpwm
  var A
rem **Pin setting**
  A = 0xBF80FB60
  A(0) = 5
rem **TIMR3 settings**
  A = 0xBF800A00
rem clear TMR3
  A((1*4+0)) = 0x0000
rem clear PR3
  A((2*4+0)) = 0x0100
rem start TMR3
  A((0*4+0)) = 0x8000
rem **OC4 setting**
  A = 0xBF803600
  A((0*4+0)) = 0x000e
  A((0*4+2)) = 0x8000
return

rem stop sound
label stopsn
  var A
rem stop TMR3
  A = 0xBF800A00
  A((0*4+1)) = 0x8000
rem stop TMR4
  A = 0xBF800C00
  A((0*4+1)) = 0x8000  
return

rem init for music
label inimus
  fopen ARGS$(1),"r"
return

rem music task
rem call every 1F
label mustas
  var b
  b=0
  if gosub(dmishf) then
    b=s
  elseif gosub(dmisfi) then
    b=s+1024
    c=c+1
  endif
  if b then
    gosub clrflg
    if fget(b,1024)=0 then
      gosub finmus
    endif
  endif
return

rem deinit for music.
label finmus
  gosub stopsn
  gosub dmaabo
  fclose
end