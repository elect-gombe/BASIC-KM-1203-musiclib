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

label main
  cls
  var i,a
  DIM S(512)
  gosub setpwm
  gosub setbst
  gosub setdma,S,2048

  gosub clrbuf

  gosub inimus,"music.raw"

  cursor 0,0
  color 7
  print "music.raw"
  print "Hit any key to abort"

  while 1
    wait 1
    gosub dsptim
    gosub mustas
    if inkey() then
      gosub stpmus
      fclose
    endif
  wend

end

label clrbuf
  var i
  for i=0 to 511
    s(i)=0x7F7F7F7F
  next
return

label dsptim
  var s
  s = c * 2048 / 32000
  cursor 0,3
  color 7
  print s/60%10;":";s%60/10;s%60%10
return



label setdma
  var A
  A = 0xBF883000
  A(2) = 0x00008000
  A = 0xBF883060
  A(0) = 0x00000012
  A(4) = 0x1310
  A(12) = ARGS(1) AND 0x1FFFFFFF
  A(16) = 0x1F803620
  A(20) = ARGS(2)
  A(24) = 1
  A(36) = 1
  gosub clrflg
  A(2) = 0x00000080
return

label dmaabo
  var A
  A = 0xBF883060
  A(6) =0x40
return

label clrflg
  var A
  A = 0xBF883060
  A(9) = 0x00FF00FF
return

label dmishf
  var A
  A = 0xBF883080
return A(0) AND 0x40

label dmisfi
  var A
  A = 0xBF883080
return A(0) AND 0x80

label setbst
  var A
  A = 0xBF800C00
  A(0) = 0x00000000
  A(4) = 0x0000
  A(8) = 1790
  A = 0xBF881060
  A(1) = 0x00080000
  A = 0xBF800C00
  A(2) = 0x00008000
return

label setpwm
  var A
  A = 0xBF80FB60
  A(0) = 5
  A = 0xBF800A00
  A(4) = 0x0000
  A(8) = 0x0100
  A(0) = 0x8000
  A = 0xBF803600
  A(0) = 0x000e
  A(2) = 0x8000
return

label stopsn
  var A
  A = 0xBF800A00
  A(1) = 0x8000
  A = 0xBF800C00
  A(1) = 0x8000  
return

label inimus
  fopen ARGS$(1),"r"
return

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
      gosub clrbuf
      fseek 0
    endif
  endif
return

label stpmus
  gosub stopsn
  gosub dmaabo
end
