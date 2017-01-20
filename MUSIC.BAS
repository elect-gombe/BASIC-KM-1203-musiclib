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


rem ==gloval variables==
 rem c : count playing
 rem s : sound buff(1024*2) 

rem ==functions==
 rem setpwm
  rem initialize pwm for audio
  rem use TMR3,OC4
  rem resolution:8bit
 rem setbst
  rem initialize base timer
  rem use TMR4
  rem interval:1/32KHz
  rem  if you use graphic mode, you
  rem need reculculation of interval.
 rem setdma
  rem initialize DMA
  rem args
   rem ARGS(1):buffer
   rem ARGS(2):buffer size
  rem for detail, ref:body
 rem clrbuf
  rem clear buffer
  rem clear audio buffer with 0x7F
 rem inimus
  rem initialize for music
  rem ARG(1):filename
 rem diptim
  rem display time
 rem mustas
  rem do music task
  rem  this function must be called 
  rem every 1 frame, or overrun.
 rem stpmus
  rem  deinit dma and timers to stop 
  rem music.


rem ===================
rem ====source code====
rem ===================


label main
rem  usegraphic
  cls
  var i,a
  DIM S(512)
rem pwm setup
  gosub setpwm
rem time base setup
  gosub setbst
rem dma setup
  gosub setdma,S,2048

  gosub clrbuf

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
    if inkey() then
      gosub stpmus
      fclose
    endif
  wend

end

rem clear buffer
label clrbuf
  var i
  for i=0 to 511
    s(i)=0x7F7F7F7F
  next
return

rem display time @(0,3)
label dsptim
  var s
  s = c * 2048 / 32000
  cursor 0,3
  color 7
  print s/60%10;":";s%60/10;s%60%10
return

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
  A = 0xBF883000
rem dma on
  A(2) = 0x00008000
  A = 0xBF883060
rem enable ch0 (auto mode,pri lv=2)
  A(0) = 0x00000012
rem transfer @irq tmr4(19)
rem (19<<8) OR (1<<4)
  A(4) = 0x1310
rem set source addr
  A(12) = ARGS(1) AND 0x1FFFFFFF
rem set dest addr OC4RS
rem (0x8F803620 AND 0x1FFFFFFF)
  A(16) = 0x1F803620
rem set source size [0(as 65536)-65535]
  A(20) = ARGS(2)
rem set dist size
  A(24) = 1
rem set cell size
  A(36) = 1
  gosub clrflg
rem turn on dma ch0
  A(2) = 0x00000080
return

rem dma abort
label dmaabo
rem force abort
  var A
  A = 0xBF883060
  A(6) =0x40
return

rem dma clear if flags
label clrflg
rem clear if flags(Half and full trans)
  var A
  A = 0xBF883060
  A(9) = 0x00FF00FF
return

rem dma trans half?
label dmishf
  var A
  A = 0xBF883080
return A(0) AND 0x40

rem dma trans finished?
label dmisfi
  var A
  A = 0xBF883080
return A(0) AND 0x80

rem set base timer(timer4)
rem to generate interval (sampling rate 32kHz)
label setbst
  var A
  A = 0xBF800C00
  A(0) = 0x00000000
rem TMR4 reset
  A(4) = 0x0000
rem PR4 set (3.58*16)MHz/32kHz = 1790
rem  if you use graphic mode, set this
rem value to
rem (3.58*15)MHz/32KHz = 1678
  A(8) = 1790
rem disable interrupt
  A = 0xBF881060
  A(1) = 0x00080000
rem tmr start
  A = 0xBF800C00
  A(2) = 0x00008000
return

label setpwm
  var A
rem **Pin setting**
  A = 0xBF80FB60
  A(0) = 5
rem **TIMR3 settings**
  A = 0xBF800A00
rem clear TMR3
  A(4) = 0x0000
rem clear PR3
  A(8) = 0x0100
rem start TMR3
  A(0) = 0x8000
rem **OC4 setting**
  A = 0xBF803600
  A(0) = 0x000e
  A(2) = 0x8000
return

rem stop sound
label stopsn
  var A
rem stop TMR3
  A = 0xBF800A00
  A(1) = 0x8000
rem stop TMR4
  A = 0xBF800C00
  A(1) = 0x8000  
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
rem done until half?
  if gosub(dmishf) then
    b=s
  elseif gosub(dmisfi) then
rem finished?
    b=s+1024
    c=c+1
  endif
rem any buff is empty?
  if b then
rem turn off flags
    gosub clrflg
rem is end of music?
    if fget(b,1024)=0 then
      gosub clrbuf
      fseek 0
    endif
  endif
return

rem deinit for music.
label stpmus
  gosub stopsn
  gosub dmaabo
end
