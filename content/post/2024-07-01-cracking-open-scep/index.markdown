---
title: Cracking Open SCEP
author: ''
date: '2024-07-01'
slug: []
categories: [Shell PKI]
tags: []
images: []
---

![SCEP Capture](scep_capture.png)

# Request


```sh
cut -c1-64 scep_message 
```

```
## MIILbAYJKoZIhvcNAQcCoIILXTCCC1kCAQExCzAJBgUrDgMCGgUAMIIEzwYJKoZI
```


```sh
< scep_message perl -MURI::Escape -e 'print uri_unescape(<STDIN>)' | base64 -d > scep_raw

openssl cms -in scep_raw -cmsout -inform DER -print
```

```
## CMS_ContentInfo: 
##   contentType: pkcs7-signedData (1.2.840.113549.1.7.2)
##   d.signedData: 
##     version: 1
##     digestAlgorithms:
##         algorithm: sha1 (1.3.14.3.2.26)
##         parameter: NULL
##     encapContentInfo: 
##       eContentType: pkcs7-data (1.2.840.113549.1.7.1)
##       eContent: 
##         0000 - 30 82 04 b8 06 09 2a 86-48 86 f7 0d 01 07 03   0.....*.H......
##         000f - a0 82 04 a9 30 82 04 a5-02 01 00 31 82 01 9d   ....0......1...
##         001e - 30 82 01 99 02 01 00 30-81 80 30 73 31 0b 30   0......0..0s1.0
##         002d - 09 06 03 55 04 06 13 02-41 55 31 11 30 0f 06   ...U....AU1.0..
##         003c - 03 55 04 08 0c 08 56 69-63 74 6f 72 69 61 31   .U....Victoria1
##         004b - 12 30 10 06 03 55 04 07-0c 09 4d 65 6c 62 6f   .0...U....Melbo
##         005a - 75 72 6e 65 31 1c 30 1a-06 03 55 04 03 0c 13   urne1.0...U....
##         0069 - 66 6f 6c 65 74 74 61 2e-78 79 7a 20 52 6f 6f   foletta.xyz Roo
##         0078 - 74 20 43 41 31 1f 30 1d-06 09 2a 86 48 86 f7   t CA1.0...*.H..
##         0087 - 0d 01 09 01 16 10 67 72-65 67 40 66 6f 6c 65   ......greg@fole
##         0096 - 74 74 61 2e 6f 72 67 02-09 00 b7 fb cd b8 e7   tta.org........
##         00a5 - 3a 91 a6 30 0d 06 09 2a-86 48 86 f7 0d 01 01   :..0...*.H.....
##         00b4 - 01 05 00 04 82 01 00 24-e8 22 93 82 cc ce fe   .......$.".....
##         00c3 - f9 e5 c7 ca 2a 7c 60 fd-29 38 fb 66 9a 69 b9   ....*|`.)8.f.i.
##         00d2 - d5 50 f9 f1 b4 36 75 d8-08 17 ac 53 1b 7a 0f   .P...6u....S.z.
##         00e1 - a3 bf 52 73 c2 59 14 03-66 1d 0b 2a 02 02 fe   ..Rs.Y..f..*...
##         00f0 - 4f 1d 6c 52 eb 68 91 c3-36 a1 3a 61 00 e9 67   O.lR.h..6.:a..g
##         00ff - 37 7a b3 1d ab fa f1 98-e8 d5 d0 37 70 30 94   7z.........7p0.
##         010e - ba f2 ea d1 af 74 d7 26-02 5f 5e 5c 9b 9e 75   .....t.&._^\..u
##         011d - 36 63 f6 71 9f 8d 49 5f-bd f2 bc 3e 05 03 2f   6c.q..I_...>../
##         012c - b2 29 6c f2 09 9f 65 a7-26 ed 81 51 58 1c f0   .)l...e.&..QX..
##         013b - 45 ff d3 14 b6 c0 8a 60-f9 f3 81 24 5e 4a 85   E......`...$^J.
##         014a - 93 22 bc 2d 75 b6 28 04-8c f0 dd ca fe a0 89   .".-u.(........
##         0159 - 81 f0 9b 7e 07 f1 32 b8-c1 d2 88 54 25 58 4e   ...~..2....T%XN
##         0168 - 7e fa fb c1 93 a8 77 c2-f2 b2 3f c5 89 ec af   ~.....w...?....
##         0177 - 3e 48 ee 21 e4 42 6b 12-ce 17 62 27 9a 44 90   >H.!.Bk...b'.D.
##         0186 - 57 30 40 30 b1 b3 fd 22-79 f6 f9 57 f6 74 6d   W0@0..."y..W.tm
##         0195 - c6 f4 06 e3 e9 7a 6a ca-ec 6e f9 cd 23 35 f3   .....zj..n..#5.
##         01a4 - 75 0f 90 b9 58 32 e6 eb-f3 f0 17 ec 2f f3 7f   u...X2....../..
##         01b3 - 9c c2 d4 14 51 d4 18 24-30 82 02 fd 06 09 2a   ....Q..$0.....*
##         01c2 - 86 48 86 f7 0d 01 07 01-30 14 06 08 2a 86 48   .H......0...*.H
##         01d1 - 86 f7 0d 03 07 04 08 7e-68 5e da 66 fa 30 7d   .......~h^.f.0}
##         01e0 - 80 82 02 d8 67 4e 6d d1-0f 5e a5 d5 1f 75 b6   ....gNm..^...u.
##         01ef - 28 7a 1a eb d1 ae f5 5e-fb 3c cb 73 f9 6a 4b   (z.....^.<.s.jK
##         01fe - 81 6a 13 5c 73 01 f6 e0-00 2f a0 31 23 ed 8e   .j.\s..../.1#..
##         020d - cc 7d 4c 5b 9b 18 20 59-09 9b 0c 93 18 32 e5   .}L[.. Y.....2.
##         021c - 70 33 b9 80 31 2b 3e c9-bc d0 f7 03 e1 be cd   p3..1+>........
##         022b - 52 eb aa 85 1b 22 69 e1-8c 3f 3c 4e 55 e6 a6   R...."i..?<NU..
##         023a - ce 3d c2 ba 38 1c a8 1c-67 64 e4 b5 eb 9d 1b   .=..8...gd.....
##         0249 - e6 66 1f 80 a2 1e da 80-f7 d9 9c 63 6f bc 12   .f.........co..
##         0258 - ed d0 f0 fc f5 80 96 9d-1f 89 fb 2f 58 38 8d   .........../X8.
##         0267 - 6a a3 59 47 52 f4 bc 2e-09 4f 98 2f d0 79 ec   j.YGR....O./.y.
##         0276 - 58 70 a1 a0 c0 4b 6a 54-4f c1 69 d7 39 70 2e   Xp...KjTO.i.9p.
##         0285 - 0c 02 ab d0 95 8a 8d a4-3b 97 ae 22 d0 e4 aa   ........;.."...
##         0294 - c1 27 89 56 e2 ad 1e 2d-bb f8 6a 78 ad 30 93   .'.V...-..jx.0.
##         02a3 - a6 98 da 13 01 ee 2c 14-21 c6 de 99 c5 3f 02   ......,.!....?.
##         02b2 - 96 92 1c 16 c2 6d 55 6d-49 9d 0b d2 80 ab 05   .....mUmI......
##         02c1 - e6 18 3f 0d eb 73 a2 f1-23 32 67 09 38 56 c4   ..?..s..#2g.8V.
##         02d0 - ce 29 22 5e b9 c1 5c a7-7d 66 7c e0 53 ae f9   .)"^..\.}f|.S..
##         02df - 34 14 f6 d1 22 dd 4e 28-47 e9 8d be 20 7d f5   4...".N(G... }.
##         02ee - bd 6d 3c f0 d2 b1 74 24-80 ff cb f7 85 81 01   .m<...t$.......
##         02fd - f0 17 33 2a 95 fd 53 c2-4a cb c9 a6 17 cc b5   ..3*..S.J......
##         030c - 9a 18 d5 55 93 9b 42 25-77 bf b2 6d b1 36 77   ...U..B%w..m.6w
##         031b - fa 3f c6 9c 2c cc e6 8c-f0 b1 40 16 e4 99 95   .?..,.....@....
##         032a - b1 81 76 82 b8 e3 5a 74-8e 8f 7b cd 91 1e 02   ..v...Zt..{....
##         0339 - a1 28 7e d0 11 a0 3a 7c-44 43 c3 9d bc 15 f4   .(~...:|DC.....
##         0348 - dc 43 b2 70 0c 24 19 62-c0 bc 94 7b a2 d0 83   .C.p.$.b...{...
##         0357 - 12 6e 5e 24 ab e5 13 ee-db a1 1d d5 c4 ad 02   .n^$...........
##         0366 - 3d 1b ac d9 b3 05 c1 b0-a1 b7 c8 8c a9 87 e3   =..............
##         0375 - 82 60 83 59 b1 65 01 5f-ae 28 ae a2 dd 40 a2   .`.Y.e._.(...@.
##         0384 - 0f 8b 5f 9d 73 45 ef 80-c0 7a 2e e7 42 28 a5   .._.sE...z..B(.
##         0393 - 84 fb 05 9f b9 18 25 b4-01 25 d4 e7 e7 00 7a   ......%..%....z
##         03a2 - 41 8f 11 3f 82 2c ef 10-22 2b 06 39 27 2e ca   A..?.,.."+.9'..
##         03b1 - 59 02 57 4a b5 1c c8 32-ac cc e0 c4 36 60 03   Y.WJ...2....6`.
##         03c0 - ed 81 35 bb fa 69 b8 62-42 b3 f8 25 7e 8c 8f   ..5..i.bB..%~..
##         03cf - f2 52 71 80 30 50 02 f2-49 b4 54 c3 ff b0 b6   .Rq.0P..I.T....
##         03de - 1c a1 c2 e5 de 5f 17 65-69 b9 18 b3 74 7d 7d   ....._.ei...t}}
##         03ed - 8f 10 48 66 ad f9 b1 f8-c0 60 76 40 99 56 d6   ..Hf.....`v@.V.
##         03fc - 87 1b de 86 3a de 75 55-d2 9b d0 ba 5b 5b cf   ....:.uU....[[.
##         040b - 11 42 21 85 1a cc c0 1d-d0 1f ff 52 32 a0 37   .B!........R2.7
##         041a - 9f 23 df e5 fb 75 bf 9a-b7 ce ed 54 84 12 3a   .#...u.....T..:
##         0429 - df 06 a1 bc 1c de a8 de-84 16 16 02 a2 f3 a4   ...............
##         0438 - ea c4 0d ac e0 75 1e 89-86 ed 63 b4 3d c5 db   .....u....c.=..
##         0447 - 82 0b c8 32 29 98 9c f1-6c b6 01 82 b0 16 79   ...2)...l.....y
##         0456 - 7b d0 5f 2b 12 d6 6b 3a-b1 75 0f 7e 1b f3 99   {._+..k:.u.~...
##         0465 - 14 44 27 76 de 06 aa 95-f8 cb 9a e0 f4 30 36   .D'v.........06
##         0474 - af 74 a4 c8 e8 d0 e7 f3-12 9e c5 f7 89 23 be   .t...........#.
##         0483 - ba f2 4d 98 08 af 9a 7b-50 ff c7 8b fd 4c d1   ..M....{P....L.
##         0492 - 5f 45 38 06 ff 73 cd 59-2d 10 5a f2 dd 9c 00   _E8..s.Y-.Z....
##         04a1 - 04 1f e2 fa 6c b8 d2 44-45 81 56 d9 17 8e e7   ....l..DE.V....
##         04b0 - 44 1e 35 03 13 57 62 a8-ce bf ff e5            D.5..Wb.....
##     certificates:
##       d.certificate: 
##         cert_info: 
##           version: 2
##           serialNumber: 0x3734313741353030463237374346373435413346333630333837374338443143
##           signature: 
##             algorithm: sha1WithRSAEncryption (1.2.840.113549.1.1.5)
##             parameter: NULL
##           issuer: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=fw1-i-foletta-xyz
##           validity: 
##             notBefore: Jun 24 20:39:17 2024 GMT
##             notAfter: Jul  1 20:39:17 2025 GMT
##           subject: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=fw1-i-foletta-xyz
##           key:           X509_PUBKEY: 
##             algor: 
##               algorithm: rsaEncryption (1.2.840.113549.1.1.1)
##               parameter: NULL
##             public_key:  (0 unused bits)
##               0000 - 30 82 01 0a 02 82 01 01-00 cc 5a 25 e6 1c   0.........Z%..
##               000e - df e4 ce 10 16 76 80 77-dd 4b 83 ce 53 e2   .....v.w.K..S.
##               001c - b7 d5 7a 7a b9 e3 58 96-40 c3 75 25 f1 80   ..zz..X.@.u%..
##               002a - 97 6b c2 60 bb 28 eb 8d-0a 00 a4 b0 0b 7e   .k.`.(.......~
##               0038 - b7 01 21 81 77 a9 38 4a-65 dd 8b 14 81 14   ..!.w.8Je.....
##               0046 - 07 2f 58 a9 d8 d7 0b a2-f9 fd 50 33 60 66   ./X.......P3`f
##               0054 - 6e 89 5b 43 a9 97 05 2f-21 9b e0 82 80 98   n.[C.../!.....
##               0062 - 12 d1 3b 3a 03 c4 7f 29-93 04 76 2c 06 13   ..;:...)..v,..
##               0070 - 6a 21 03 af 7a f3 96 c6-e7 cd a8 03 f5 d2   j!..z.........
##               007e - 60 ad 3b e9 8e aa 20 f4-7f 56 2c 05 94 9b   `.;... ..V,...
##               008c - bb 7a 34 b6 49 57 4a bb-be 29 dd bc ee c1   .z4.IWJ..)....
##               009a - 57 0a db 90 8a 0f 24 8d-b3 c6 01 df 48 1a   W.....$.....H.
##               00a8 - 69 e6 0a 99 fb 3e 2a 25-b3 1a 1b ae e5 cf   i....>*%......
##               00b6 - f3 c7 f9 a0 c7 20 27 79-22 c4 ce f8 4d 32   ..... 'y"...M2
##               00c4 - 05 d4 f1 db 55 b6 3a cc-c2 75 69 5d 10 c5   ....U.:..ui]..
##               00d2 - 3f 82 39 c6 6d 09 84 eb-95 87 90 7a 7c 59   ?.9.m......z|Y
##               00e0 - e3 9e f6 e7 68 88 14 20-43 ab 74 c4 7b 09   ....h.. C.t.{.
##               00ee - 27 73 d6 b7 94 8c c7 4c-bf 1a a1 56 50 0f   's.....L...VP.
##               00fc - 74 d9 71 a2 9f 78 02 12-ac 5f 9c 28 19 02   t.q..x..._.(..
##               010a - 03 01 00 01                                 ....
##           issuerUID: <ABSENT>
##           subjectUID: <ABSENT>
##           extensions:
##               object: X509v3 Subject Key Identifier (2.5.29.14)
##               critical: BOOL ABSENT
##               value: 
##                 0000 - 04 14 78 66 df 81 e6 26-07 a2 48 0b f2   ..xf...&..H..
##                 000d - 13 87 51 1d fe 14 27 fd-ac               ..Q...'..
## 
##               object: X509v3 Authority Key Identifier (2.5.29.35)
##               critical: BOOL ABSENT
##               value: 
##                 0000 - 30 16 80 14 78 66 df 81-e6 26 07 a2 48   0...xf...&..H
##                 000d - 0b f2 13 87 51 1d fe 14-27 fd ac         ....Q...'..
## 
##               object: X509v3 Basic Constraints (2.5.29.19)
##               critical: TRUE
##               value: 
##                 0000 - 30 03 01 01 ff                           0....
## 
##               object: X509v3 Key Usage (2.5.29.15)
##               critical: TRUE
##               value: 
##                 0000 - 03 02 01 86                              ....
##         sig_alg: 
##           algorithm: sha1WithRSAEncryption (1.2.840.113549.1.1.5)
##           parameter: NULL
##         signature:  (0 unused bits)
##           0000 - 0d fd 2b c8 7e b5 a3 08-d2 cd 5b 40 72 40 d0   ..+.~.....[@r@.
##           000f - b2 0c cb af 60 fc 37 1a-7a 32 c1 58 4a ef 4d   ....`.7.z2.XJ.M
##           001e - 51 80 4f cc 88 86 ed f9-10 62 8b 02 96 4b ac   Q.O......b...K.
##           002d - 9e 2f 5b 6e 79 b1 b5 70-17 76 e2 59 11 31 9f   ./[ny..p.v.Y.1.
##           003c - 3e d9 66 94 fb d1 a1 3b-fd 10 f4 d9 d9 16 36   >.f....;......6
##           004b - c8 22 95 1a 8e 25 df a0-f7 fc d6 ea 4b 46 67   ."...%......KFg
##           005a - c3 38 1b f9 d5 e6 8a 2c-41 84 ad e9 bd 3d 40   .8.....,A....=@
##           0069 - 06 d7 2b 09 a2 c3 9b 04-0b 6a fc 6d 52 5d a3   ..+......j.mR].
##           0078 - 56 d0 63 3e d0 25 a5 96-b0 a6 22 6b 2a 7b 51   V.c>.%...."k*{Q
##           0087 - a6 fb 1b 4c a7 d6 bd 55-13 92 5c 2e ed 6a a3   ...L...U..\..j.
##           0096 - 2c 90 dc b6 81 9a a5 a4-32 94 16 a8 45 d1 f0   ,.......2...E..
##           00a5 - e4 48 a1 f9 21 d0 ad 3d-12 7c df 17 75 88 18   .H..!..=.|..u..
##           00b4 - 4c 03 fc 1e 4e 82 0a 07-03 9a ad 59 ff 53 07   L...N......Y.S.
##           00c3 - 4d 1f 08 bb a8 54 f0 a1-a3 31 2c a8 91 5e 02   M....T...1,..^.
##           00d2 - 6f 48 f2 ad 0d b2 d7 23-9e 9d fb c8 5f fe 3c   oH.....#...._.<
##           00e1 - 50 65 8c c7 96 0c 4a fa-8b 36 b1 92 02 9f f6   Pe....J..6.....
##           00f0 - c2 ed 98 89 6e ce d5 e7-84 10 d6 b3 63 4b a2   ....n.......cK.
##           00ff - fe                                             .
##     crls:
##       <ABSENT>
##     signerInfos:
##         version: 1
##         d.issuerAndSerialNumber: 
##           issuer: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=fw1-i-foletta-xyz
##           serialNumber: 0x3734313741353030463237374346373435413346333630333837374338443143
##         digestAlgorithm: 
##           algorithm: sha1 (1.3.14.3.2.26)
##           parameter: NULL
##         signedAttrs:
##             object: undefined (2.16.840.1.113733.1.9.2)
##             set:
##               PRINTABLESTRING:19
## 
##             object: contentType (1.2.840.113549.1.9.3)
##             set:
##               OBJECT:pkcs7-data (1.2.840.113549.1.7.1)
## 
##             object: signingTime (1.2.840.113549.1.9.5)
##             set:
##               UTCTIME:Jul  1 20:39:17 2024 GMT
## 
##             object: undefined (2.16.840.1.113733.1.9.5)
##             set:
##               OCTET STRING:
##                 0000 - 7f 26 a5 b4 50 6f 97 9c-96 73 91 92 de   .&..Po...s...
##                 000d - 48 6d 2d                                 Hm-
## 
##             object: messageDigest (1.2.840.113549.1.9.4)
##             set:
##               OCTET STRING:
##                 0000 - b4 f0 31 e7 2a e4 78 33-9e 8b 8e fb 2b   ..1.*.x3....+
##                 000d - 7f 0e 1d e6 fb ca 6a                     ......j
## 
##             object: undefined (2.16.840.1.113733.1.9.7)
##             set:
##               PRINTABLESTRING:7417A500F277CF745A3F3603877C8D1C
##         signatureAlgorithm: 
##           algorithm: rsaEncryption (1.2.840.113549.1.1.1)
##           parameter: NULL
##         signature: 
##           0000 - 4c a5 72 cf 1d ea e6 5d-9d bd 7a 48 62 91 aa   L.r....]..zHb..
##           000f - 52 29 e2 cb da 47 d6 74-0e bb 6f 63 52 2e 2a   R)...G.t..ocR.*
##           001e - f0 be 52 98 a9 37 cc e8-13 00 8a 14 5a ae 4a   ..R..7......Z.J
##           002d - f2 8b 80 5d 90 03 f1 2c-fa 01 74 c2 92 28 98   ...]...,..t..(.
##           003c - 81 7d f0 98 98 42 b4 03-57 cc c0 f2 3c 6c be   .}...B..W...<l.
##           004b - 7c 84 3a a4 1e 30 b9 b4-4e a2 78 a6 79 96 53   |.:..0..N.x.y.S
##           005a - 07 7a d2 4e c6 7f 40 16-09 f6 eb 3d 95 4c 70   .z.N..@....=.Lp
##           0069 - b2 04 1d 16 60 d2 3b b1-df ac 61 56 ba 1d 1a   ....`.;...aV...
##           0078 - 2b 9b 45 2f 61 07 f8 e0-bf 4e d1 29 32 6d a7   +.E/a....N.)2m.
##           0087 - 3f 28 d6 b8 8a cc 77 ed-c5 1b 99 f9 67 21 f9   ?(....w.....g!.
##           0096 - 08 c9 37 69 18 d9 32 20-a7 02 9a 2f c3 34 37   ..7i..2 .../.47
##           00a5 - a1 cc 67 1f 7c cc 03 18-fb 6c 2f 05 c3 e6 7c   ..g.|....l/...|
##           00b4 - 15 6e c8 8a 92 f1 51 ad-f6 3c 11 1a 0e 19 10   .n....Q..<.....
##           00c3 - bd 2b 2b c9 44 80 7a ea-f4 4a 9c 98 c9 52 7d   .++.D.z..J...R}
##           00d2 - f8 51 d7 91 bd 37 fd df-82 f7 e6 17 4c f9 84   .Q...7......L..
##           00e1 - 73 f0 ee 16 05 80 43 72-45 0b 36 46 dc 86 da   s.....CrE.6F...
##           00f0 - 32 e7 62 29 2c 38 ae d3-e9 2c c0 4f c3 1d 2e   2.b),8...,.O...
##           00ff - f2                                             .
##         unsignedAttrs:
##           <ABSENT>
```



```sh
< scep_raw openssl cms -verify -noverify -in - -inform DER |
  openssl cms -inform DER -cmsout -print
```

```
## CMS Verification successful
## CMS_ContentInfo: 
##   contentType: pkcs7-envelopedData (1.2.840.113549.1.7.3)
##   d.envelopedData: 
##     version: 0
##     originatorInfo: <ABSENT>
##     recipientInfos:
##       d.ktri: 
##         version: 0
##         d.issuerAndSerialNumber: 
##           issuer: C=AU, ST=Victoria, L=Melbourne, CN=foletta.xyz Root CA/emailAddress=greg@foletta.org
##           serialNumber: 13257416122132238758
##         keyEncryptionAlgorithm: 
##           algorithm: rsaEncryption (1.2.840.113549.1.1.1)
##           parameter: NULL
##         encryptedKey: 
##           0000 - 24 e8 22 93 82 cc ce fe-f9 e5 c7 ca 2a 7c 60   $.".........*|`
##           000f - fd 29 38 fb 66 9a 69 b9-d5 50 f9 f1 b4 36 75   .)8.f.i..P...6u
##           001e - d8 08 17 ac 53 1b 7a 0f-a3 bf 52 73 c2 59 14   ....S.z...Rs.Y.
##           002d - 03 66 1d 0b 2a 02 02 fe-4f 1d 6c 52 eb 68 91   .f..*...O.lR.h.
##           003c - c3 36 a1 3a 61 00 e9 67-37 7a b3 1d ab fa f1   .6.:a..g7z.....
##           004b - 98 e8 d5 d0 37 70 30 94-ba f2 ea d1 af 74 d7   ....7p0......t.
##           005a - 26 02 5f 5e 5c 9b 9e 75-36 63 f6 71 9f 8d 49   &._^\..u6c.q..I
##           0069 - 5f bd f2 bc 3e 05 03 2f-b2 29 6c f2 09 9f 65   _...>../.)l...e
##           0078 - a7 26 ed 81 51 58 1c f0-45 ff d3 14 b6 c0 8a   .&..QX..E......
##           0087 - 60 f9 f3 81 24 5e 4a 85-93 22 bc 2d 75 b6 28   `...$^J..".-u.(
##           0096 - 04 8c f0 dd ca fe a0 89-81 f0 9b 7e 07 f1 32   ...........~..2
##           00a5 - b8 c1 d2 88 54 25 58 4e-7e fa fb c1 93 a8 77   ....T%XN~.....w
##           00b4 - c2 f2 b2 3f c5 89 ec af-3e 48 ee 21 e4 42 6b   ...?....>H.!.Bk
##           00c3 - 12 ce 17 62 27 9a 44 90-57 30 40 30 b1 b3 fd   ...b'.D.W0@0...
##           00d2 - 22 79 f6 f9 57 f6 74 6d-c6 f4 06 e3 e9 7a 6a   "y..W.tm.....zj
##           00e1 - ca ec 6e f9 cd 23 35 f3-75 0f 90 b9 58 32 e6   ..n..#5.u...X2.
##           00f0 - eb f3 f0 17 ec 2f f3 7f-9c c2 d4 14 51 d4 18   ...../......Q..
##           00ff - 24                                             $
##     encryptedContentInfo: 
##       contentType: pkcs7-data (1.2.840.113549.1.7.1)
##       contentEncryptionAlgorithm: 
##         algorithm: des-ede3-cbc (1.2.840.113549.3.7)
##         parameter: OCTET STRING:
##           0000 - 7e 68 5e da 66 fa 30 7d-                       ~h^.f.0}
##       encryptedContent: 
##         0000 - 67 4e 6d d1 0f 5e a5 d5-1f 75 b6 28 7a 1a eb   gNm..^...u.(z..
##         000f - d1 ae f5 5e fb 3c cb 73-f9 6a 4b 81 6a 13 5c   ...^.<.s.jK.j.\
##         001e - 73 01 f6 e0 00 2f a0 31-23 ed 8e cc 7d 4c 5b   s..../.1#...}L[
##         002d - 9b 18 20 59 09 9b 0c 93-18 32 e5 70 33 b9 80   .. Y.....2.p3..
##         003c - 31 2b 3e c9 bc d0 f7 03-e1 be cd 52 eb aa 85   1+>........R...
##         004b - 1b 22 69 e1 8c 3f 3c 4e-55 e6 a6 ce 3d c2 ba   ."i..?<NU...=..
##         005a - 38 1c a8 1c 67 64 e4 b5-eb 9d 1b e6 66 1f 80   8...gd......f..
##         0069 - a2 1e da 80 f7 d9 9c 63-6f bc 12 ed d0 f0 fc   .......co......
##         0078 - f5 80 96 9d 1f 89 fb 2f-58 38 8d 6a a3 59 47   ......./X8.j.YG
##         0087 - 52 f4 bc 2e 09 4f 98 2f-d0 79 ec 58 70 a1 a0   R....O./.y.Xp..
##         0096 - c0 4b 6a 54 4f c1 69 d7-39 70 2e 0c 02 ab d0   .KjTO.i.9p.....
##         00a5 - 95 8a 8d a4 3b 97 ae 22-d0 e4 aa c1 27 89 56   ....;.."....'.V
##         00b4 - e2 ad 1e 2d bb f8 6a 78-ad 30 93 a6 98 da 13   ...-..jx.0.....
##         00c3 - 01 ee 2c 14 21 c6 de 99-c5 3f 02 96 92 1c 16   ..,.!....?.....
##         00d2 - c2 6d 55 6d 49 9d 0b d2-80 ab 05 e6 18 3f 0d   .mUmI........?.
##         00e1 - eb 73 a2 f1 23 32 67 09-38 56 c4 ce 29 22 5e   .s..#2g.8V..)"^
##         00f0 - b9 c1 5c a7 7d 66 7c e0-53 ae f9 34 14 f6 d1   ..\.}f|.S..4...
##         00ff - 22 dd 4e 28 47 e9 8d be-20 7d f5 bd 6d 3c f0   ".N(G... }..m<.
##         010e - d2 b1 74 24 80 ff cb f7-85 81 01 f0 17 33 2a   ..t$.........3*
##         011d - 95 fd 53 c2 4a cb c9 a6-17 cc b5 9a 18 d5 55   ..S.J.........U
##         012c - 93 9b 42 25 77 bf b2 6d-b1 36 77 fa 3f c6 9c   ..B%w..m.6w.?..
##         013b - 2c cc e6 8c f0 b1 40 16-e4 99 95 b1 81 76 82   ,.....@......v.
##         014a - b8 e3 5a 74 8e 8f 7b cd-91 1e 02 a1 28 7e d0   ..Zt..{.....(~.
##         0159 - 11 a0 3a 7c 44 43 c3 9d-bc 15 f4 dc 43 b2 70   ..:|DC......C.p
##         0168 - 0c 24 19 62 c0 bc 94 7b-a2 d0 83 12 6e 5e 24   .$.b...{....n^$
##         0177 - ab e5 13 ee db a1 1d d5-c4 ad 02 3d 1b ac d9   ...........=...
##         0186 - b3 05 c1 b0 a1 b7 c8 8c-a9 87 e3 82 60 83 59   ............`.Y
##         0195 - b1 65 01 5f ae 28 ae a2-dd 40 a2 0f 8b 5f 9d   .e._.(...@..._.
##         01a4 - 73 45 ef 80 c0 7a 2e e7-42 28 a5 84 fb 05 9f   sE...z..B(.....
##         01b3 - b9 18 25 b4 01 25 d4 e7-e7 00 7a 41 8f 11 3f   ..%..%....zA..?
##         01c2 - 82 2c ef 10 22 2b 06 39-27 2e ca 59 02 57 4a   .,.."+.9'..Y.WJ
##         01d1 - b5 1c c8 32 ac cc e0 c4-36 60 03 ed 81 35 bb   ...2....6`...5.
##         01e0 - fa 69 b8 62 42 b3 f8 25-7e 8c 8f f2 52 71 80   .i.bB..%~...Rq.
##         01ef - 30 50 02 f2 49 b4 54 c3-ff b0 b6 1c a1 c2 e5   0P..I.T........
##         01fe - de 5f 17 65 69 b9 18 b3-74 7d 7d 8f 10 48 66   ._.ei...t}}..Hf
##         020d - ad f9 b1 f8 c0 60 76 40-99 56 d6 87 1b de 86   .....`v@.V.....
##         021c - 3a de 75 55 d2 9b d0 ba-5b 5b cf 11 42 21 85   :.uU....[[..B!.
##         022b - 1a cc c0 1d d0 1f ff 52-32 a0 37 9f 23 df e5   .......R2.7.#..
##         023a - fb 75 bf 9a b7 ce ed 54-84 12 3a df 06 a1 bc   .u.....T..:....
##         0249 - 1c de a8 de 84 16 16 02-a2 f3 a4 ea c4 0d ac   ...............
##         0258 - e0 75 1e 89 86 ed 63 b4-3d c5 db 82 0b c8 32   .u....c.=.....2
##         0267 - 29 98 9c f1 6c b6 01 82-b0 16 79 7b d0 5f 2b   )...l.....y{._+
##         0276 - 12 d6 6b 3a b1 75 0f 7e-1b f3 99 14 44 27 76   ..k:.u.~....D'v
##         0285 - de 06 aa 95 f8 cb 9a e0-f4 30 36 af 74 a4 c8   .........06.t..
##         0294 - e8 d0 e7 f3 12 9e c5 f7-89 23 be ba f2 4d 98   .........#...M.
##         02a3 - 08 af 9a 7b 50 ff c7 8b-fd 4c d1 5f 45 38 06   ...{P....L._E8.
##         02b2 - ff 73 cd 59 2d 10 5a f2-dd 9c 00 04 1f e2 fa   .s.Y-.Z........
##         02c1 - 6c b8 d2 44 45 81 56 d9-17 8e e7 44 1e 35 03   l..DE.V....D.5.
##         02d0 - 13 57 62 a8 ce bf ff e5-                       .Wb.....
##     unprotectedAttrs:
##       <ABSENT>
```


```sh
< scep_raw openssl cms -verify -noverify -in - -inform DER -out - |
  openssl cms -inform DER -decrypt -recip Blog_Post_SubCA.key |
  openssl req -inform DER -noout -text
```

```
## CMS Verification successful
## Certificate Request:
##     Data:
##         Version: 1 (0x0)
##         Subject: C = AU, ST = Victoria, L = Melbourne, O = foletta.xyz, OU = IT, CN = fw1-i-foletta-xyz
##         Subject Public Key Info:
##             Public Key Algorithm: rsaEncryption
##                 Public-Key: (2048 bit)
##                 Modulus:
##                     00:cc:5a:25:e6:1c:df:e4:ce:10:16:76:80:77:dd:
##                     4b:83:ce:53:e2:b7:d5:7a:7a:b9:e3:58:96:40:c3:
##                     75:25:f1:80:97:6b:c2:60:bb:28:eb:8d:0a:00:a4:
##                     b0:0b:7e:b7:01:21:81:77:a9:38:4a:65:dd:8b:14:
##                     81:14:07:2f:58:a9:d8:d7:0b:a2:f9:fd:50:33:60:
##                     66:6e:89:5b:43:a9:97:05:2f:21:9b:e0:82:80:98:
##                     12:d1:3b:3a:03:c4:7f:29:93:04:76:2c:06:13:6a:
##                     21:03:af:7a:f3:96:c6:e7:cd:a8:03:f5:d2:60:ad:
##                     3b:e9:8e:aa:20:f4:7f:56:2c:05:94:9b:bb:7a:34:
##                     b6:49:57:4a:bb:be:29:dd:bc:ee:c1:57:0a:db:90:
##                     8a:0f:24:8d:b3:c6:01:df:48:1a:69:e6:0a:99:fb:
##                     3e:2a:25:b3:1a:1b:ae:e5:cf:f3:c7:f9:a0:c7:20:
##                     27:79:22:c4:ce:f8:4d:32:05:d4:f1:db:55:b6:3a:
##                     cc:c2:75:69:5d:10:c5:3f:82:39:c6:6d:09:84:eb:
##                     95:87:90:7a:7c:59:e3:9e:f6:e7:68:88:14:20:43:
##                     ab:74:c4:7b:09:27:73:d6:b7:94:8c:c7:4c:bf:1a:
##                     a1:56:50:0f:74:d9:71:a2:9f:78:02:12:ac:5f:9c:
##                     28:19
##                 Exponent: 65537 (0x10001)
##         Attributes:
##             challengePassword        :8qKfdeen
##             Requested Extensions:
##     Signature Algorithm: sha1WithRSAEncryption
##     Signature Value:
##         58:47:15:93:7f:c1:da:a4:26:35:c2:04:97:ca:ef:e9:da:fe:
##         b3:60:5f:52:c2:a0:2b:df:f1:d8:d5:5e:d0:90:5f:c9:00:86:
##         1d:a2:4b:05:31:89:2a:f4:38:1c:c4:19:e0:26:70:ee:c7:56:
##         6e:bc:ed:f5:66:b8:b5:3d:ea:90:e0:2c:76:49:c8:60:cc:9f:
##         20:e9:3a:de:d7:7c:6f:ce:7f:77:92:ff:ef:65:40:4f:0b:6f:
##         dd:d1:6f:3c:c0:68:2d:6d:3d:b7:54:6e:3e:b6:94:70:d5:df:
##         84:8d:b0:72:c6:11:2e:36:e9:38:3c:b6:3c:25:7f:9d:be:4c:
##         e3:bc:08:89:96:bb:69:24:42:92:ea:aa:ed:1f:41:32:10:11:
##         6c:03:15:22:12:b7:35:48:a4:aa:9f:42:5a:3e:33:3e:ed:c5:
##         b7:6c:89:b2:1e:c9:71:aa:7b:86:52:b7:4f:a0:d7:90:d9:c7:
##         f2:d1:0c:1e:35:51:a3:03:4c:b3:f2:b3:0e:f4:4d:1a:ab:2c:
##         81:2c:61:a7:2e:00:f1:65:e6:75:36:55:d0:cc:3b:dc:95:d7:
##         0e:50:40:1a:93:b7:6e:2c:c0:27:9f:aa:09:c4:b8:47:a8:97:
##         b2:2b:07:76:b1:bf:8b:44:c0:bc:7a:72:85:b7:57:16:ec:bf:
##         c6:06:44:8a
```

# Response

