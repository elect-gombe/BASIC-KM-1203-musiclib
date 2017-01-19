# ===raw audio player===
## lisence
```
 Copyright 2017, gombe all right reserved.
```
 This software is free software and there is NO WARRANTY.
 No restriction on use. You can use, modify and redistribute it under your responsibility.
 Redistribution of source code must retain the above copyright notice.

このソフトウェアは無保証です。制約はありません。自己責任において誰でも改変、再公開ができます。ただし著作権は留保しますので上の条項を示す必要があります。

## howto

for BASIC KM-1203 or later. (use SD library.)
これはBASIC KM-1203以降に対応します

without LPF, AMP may be damaged.
もしかするとLPFがないとアンプにダメージを与えるかもしれません。
例えばこのようにします。
```
in>-----+---------->output
         |
         = C
         |
         - (Ground)
```
C is 0.01uF or so.
Cは0.01uF程がいいでしょう。

## sound data format
 sampling    : 32KHz
 channel     : 1ch
 resolution  : 8bit
 data format : raw
 size        : 1024*2 Byte

## Specific
 DMA         : use ch 1
 PWM         : use OC4
 PWMtimebase : use tmr3
 DMATimeBase : use tmr4
 clock freq  : 3.58*16

## other
  If you want to use graphic mode,
 you must reculculate DMATimeBase.
もしあなたがグラフィックモードを使用している場合はDMAのタイムベースの再計算が必要です。

  If you want to make audio data,
 you should use sox command.
 もしあなたがオーディオデータを作成したいのなら`sox`を使うといいでしょう。
```sh
$ sox <in> -r32000 -c1 -b8 -u <out>.raw
```

  If you play pade data, you 
 can use aplay command.
 作成したデータを再生したいのならこうします。
```sh
$ aplay <in> -r32000
```

## Global variable
 c : count playing
 s : sound buff(1024*2) 

## Special thanks
音声データ：魔王魂
