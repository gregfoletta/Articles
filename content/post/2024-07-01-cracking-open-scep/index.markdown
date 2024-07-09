---
title: Cracking Open SCEP
author: 'Greg Foletta'
date: '2024-07-01'
categories: [Shell PKI]
output:
    html_document:
        code_folding: hide
---



Most of the posts on this site tend to be long form, a result of me finding it hard to leave stones unturned. This leads to big gaps between posts, in fact the the radio silence over the past nine months is because I've had two in draft form, not quite neing able to get them across the line.

As an antidote to this I've put together something a little more bite-size. In this post we're going to crack open a *Simple Certificate Enrollment Protocol (SCEP)* request. We'll do this on the command line, using the openssl tool peer underneath the hood.

# The Request

Here's a screenshot of a packet capture taken during a SCEP request for a new certificate.

![SCEP Capture](scep_capture.png)
The SCEP request is actually two requests: the first returns X509 CA certificate, and the second is the certificate request. Zooming in on the second one, the bulk of the request is passed in the *message* query parameter. What I've done is extracted the value of this parameter into a file named *scep_message*.


```sh
# Size in bytes
wc -c scep_message
# First 64 bytes
cut -c1-64 scep_message 
```

```
4089 scep_message
MIILLAYJKoZIhvcNAQcCoIILHTCCCxkCAQExDzANBglghkgBZQMEAgMFADCCBM8G
```

As you'll soon see, SCEP has an onion like quality (often including the tears), with layer after layer of different encodings and structures. The *message* parameter is URI encoded, then base64 encoded, so we decode these store what I'll call the 'raw' SCEP in a file called *scep_raw*.


```sh
# Remove the URI and base64 encoding
< scep_message perl -MURI::Escape -e 'print uri_unescape(<STDIN>)' | base64 -d > scep_raw
```

# Signing

Now we can get into the meat and bones. The first wrapper is [Cryptographic Message Syntax (CMS)](https://en.wikipedia.org/wiki/Cryptographic_Message_Syntax) encapsulated data. Originally part of the PKCS standards defined by RSA security, it is now an IETF standard under [RFC 5652 ](https://datatracker.ietf.org/doc/html/rfc5652). CMS provides a way to 'digitally sign, digest, authenticate, or encrypt arbitrary message content'. 

Using the openssl *cms* command with the *-print* argument, we can look at the structure of this first CMS wrapper. I've redacted some of the less-relevant content and added some comments, but some of the key sections are:

* *eContent*: the encapsulated content.
* *certificates*: a set of certificates that are sent along with the content.
* *signerInfos*: information pertaining to the signing of the content.


```{.sh .fold-hide}
# Print the CMS structure
openssl cms -in scep_raw -cmsout -inform DER -print
```

```language-sh
CMS_ContentInfo: 
  contentType: pkcs7-signedData (1.2.840.113549.1.7.2)
  d.signedData: 
    version: 1
    digestAlgorithms:
        algorithm: sha512 (2.16.840.1.101.3.4.2.3)
        parameter: NULL
    encapContentInfo: 
      eContentType: pkcs7-data (1.2.840.113549.1.7.1)
      eContent: 
        0000 - 30 82 04 b8 06 09 2a 86-48 86 f7 0d 01 07 03   0.....*.H......
        000f - a0 82 04 a9 30 82 04 a5-02 01 00 31 82 01 9d   ....0......1...
        001e - 30 82 01 99 02 01 00 30-81 80 30 73 31 0b 30   0......0..0s1.0
        002d - 09 06 03 55 04 06 13 02-41 55 31 11 30 0f 06   ...U....AU1.0..
        003c - 03 55 04 08 0c 08 56 69-63 74 6f 72 69 61 31   .U....Victoria1
        004b - 12 30 10 06 03 55 04 07-0c 09 4d 65 6c 62 6f   .0...U....Melbo
        005a - 75 72 6e 65 31 1c 30 1a-06 03 55 04 03 0c 13   urne1.0...U....
        0069 - 66 6f 6c 65 74 74 61 2e-78 79 7a 20 52 6f 6f   foletta.xyz Roo
        0078 - 74 20 43 41 31 1f 30 1d-06 09 2a 86 48 86 f7   t CA1.0...*.H..
        0087 - 0d 01 09 01 16 10 67 72-65 67 40 66 6f 6c 65   ......greg@fole
        0096 - 74 74 61 2e 6f 72 67 02-09 00 b7 fb cd b8 e7   tta.org........
        00a5 - 3a 91 a6 30 0d 06 09 2a-86 48 86 f7 0d 01 01   :..0...*.H.....
        00b4 - 01 05 00 04 82 01 00 5f-29 c1 27 27 6a fd 1b   ......._).''j..
        00c3 - 56 01 ac 78 0a 4d b9 f8-2b 55 c4 81 54 c4 9d   V..x.M..+U..T..
        00d2 - a2 6c ed 91 fe 34 61 60-b8 41 7b 97 f3 3f bf   .l...4a`.A{..?.
        00e1 - 5e 5e d3 4e 62 1b 9b b8-30 84 97 4e 25 91 2b   ^^.Nb...0..N%.+
        00f0 - 7b 3f 07 52 b9 5a 6b 9b-55 30 03 43 65 ce bc   {?.R.Zk.U0.Ce..
        00ff - 8e 5b 4f 68 15 ad 70 3b-a7 0e 76 28 08 95 83   .[Oh..p;..v(...
        010e - 7d 46 91 16 cc ac ce b7-6f c3 5d 9c 99 0f 63   }F......o.]...c
        011d - 69 82 be 6d b5 81 5a 92-ab 4a 49 1a 84 eb 24   i..m..Z..JI...$
        012c - 7c ae 32 37 c4 d5 16 af-93 d4 c4 68 8a 92 e1   |.27.......h...
        013b - 7e 82 6b 70 8c 61 e9 d6-f7 ab 6f 3d 42 88 ae   ~.kp.a....o=B..
        014a - 7d b8 83 e4 da f6 bc b8-2e 14 24 59 96 44 58   }.........$Y.DX
        0159 - 8b e9 c6 ab 17 81 c1 72-b5 bd fc 9c 3b 12 a5   .......r....;..
        0168 - ea 54 69 f9 cd 4e 6d 3f-07 73 5e 5a e1 3d 5d   .Ti..Nm?.s^Z.=]
        0177 - 57 ca 80 a1 e9 3b 44 f1-9b 1c 18 c6 b1 32 8b   W....;D......2.
        0186 - a1 89 c2 cc cc 1b b5 dc-12 90 b3 a3 4b fe 9a   ............K..
        0195 - 2d fc 2f 69 21 6d 4b 62-3a c6 53 0b 64 27 9a   -./i!mKb:.S.d'.
        01a4 - 22 df bb 2d 65 bc d9 56-13 ca fd d3 fc e3 d0   "..-e..V.......
        01b3 - 1a 69 03 c6 1b 06 23 0f-30 82 02 fd 06 09 2a   .i....#.0.....*
        01c2 - 86 48 86 f7 0d 01 07 01-30 14 06 08 2a 86 48   .H......0...*.H
        01d1 - 86 f7 0d 03 07 04 08 01-ed 63 51 42 91 6e a0   .........cQB.n.
        01e0 - 80 82 02 d8 7e f2 df fc-ee 14 b2 62 5a ea c0   ....~......bZ..
        01ef - 56 17 73 ce 15 d2 15 d0-5d 35 82 78 c5 87 ec   V.s.....]5.x...
        01fe - 01 92 f1 ef e9 c4 9a 93-56 22 eb bc e1 9d 45   ........V"....E
        020d - 1a 9c 0d 58 bf b8 4e ba-82 ac 74 18 23 1c 89   ...X..N...t.#..
        021c - 07 1f 29 3b cc 4c a1 db-80 e9 94 25 97 71 9c   ..);.L.....%.q.
        022b - 38 b8 53 dc 44 0d 8b 4f-6f c1 f8 61 b7 bb d8   8.S.D..Oo..a...
        023a - 8d 33 49 68 11 07 c0 1a-dd c5 ab be 2f ac 63   .3Ih......../.c
        0249 - 71 79 59 2f 2a 19 15 df-79 9d 6c c0 e2 b4 c3   qyY/*...y.l....
        0258 - 39 9d 6f ce f8 6a 9a a3-a7 83 4c 84 8a 0c 08   9.o..j....L....
        0267 - 12 2d 27 1d 4f 63 a4 52-ce 32 df 12 52 03 3f   .-'.Oc.R.2..R.?
        0276 - a4 d9 6c e7 b7 5d ff a4-08 4c 03 21 8d 49 3d   ..l..]...L.!.I=
        0285 - 6b f7 f0 a9 33 d1 d5 76-c4 89 8d 2c 02 e9 9d   k...3..v...,...
        0294 - 75 d3 16 33 38 3d 72 11-b2 86 7a 87 a0 a7 6c   u..38=r...z...l
        02a3 - a2 bd 5b c7 9c e0 f3 0a-bb fc 61 d0 87 65 44   ..[.......a..eD
        02b2 - c2 89 bc 48 d9 52 05 83-da eb 22 c4 e0 2b 40   ...H.R...."..+@
        02c1 - ae 25 5c ca 0b 43 43 60-e7 05 dc 4d 4f a8 08   .%\..CC`...MO..
        02d0 - 3d 0c a1 5f a4 9a aa 44-6a 68 a2 bd cd 26 35   =.._...Djh...&5
        02df - a4 a6 52 a3 59 f7 0b 15-a1 6c 66 86 f9 4e 42   ..R.Y....lf..NB
        02ee - ae 6b b7 33 31 18 01 5b-5c 93 47 e9 ca e4 7a   .k.31..[\.G...z
        02fd - 5b d7 4a 8e bc 1e b2 7b-63 ab 82 dc 30 64 51   [.J....{c...0dQ
        030c - 96 91 6a 48 4c 1b ec 6f-f0 ed 46 39 7e 95 ff   ..jHL..o..F9~..
        031b - bc 4a 2a 55 2a 4c 99 4b-f0 12 4f db 56 15 37   .J*U*L.K..O.V.7
        032a - 12 ee 15 0a 58 91 f2 24-6c 34 a8 37 3b a1 02   ....X..$l4.7;..
        0339 - 68 5b ac e1 e7 2e 48 f1-c9 1b 8d 73 8c e3 6a   h[....H....s..j
        0348 - ef b5 c6 79 74 f3 11 2c-15 91 f5 9f f2 d7 bd   ...yt..,.......
        0357 - d6 f2 64 90 be 62 5a c1-f5 78 c5 80 27 bb 73   ..d..bZ..x..'.s
        0366 - 9e 08 2b 81 a6 df c0 48-c5 2d 2f 83 74 a7 b8   ..+....H.-/.t..
        0375 - 1f cc fe d7 e7 a6 17 f9-03 71 21 76 46 6f 2d   .........q!vFo-
        0384 - 9b 20 a2 70 e1 32 e9 6f-14 7a 25 96 38 32 bf   . .p.2.o.z%.82.
        0393 - 3f 87 81 f5 64 ee e5 0f-78 e7 66 32 2d 9f e3   ?...d...x.f2-..
        03a2 - 59 2c 9b 99 5a b4 a6 89-12 d7 d1 d1 59 73 a5   Y,..Z.......Ys.
        03b1 - cd 22 a1 a6 ef ed 87 b3-da 9e fa 82 41 87 03   ."..........A..
        03c0 - 07 7f de 60 32 b9 04 75-35 a0 52 95 88 47 bd   ...`2..u5.R..G.
        03cf - d5 5f b1 5d f7 ee 36 c4-8d 1d 99 bb 48 5d 03   ._.]..6.....H].
        03de - 47 2c 50 2f a6 15 7d 28-dc 80 d0 75 97 8a f7   G,P/..}(...u...
        03ed - ce f8 17 f4 cb 32 e0 17-e1 c4 f2 ac 8e f0 92   .....2.........
        03fc - 06 b3 01 25 13 fe 67 58-dc 19 f9 ea 68 e1 dc   ...%..gX....h..
        040b - ec 7d d4 2e a6 b3 1b 89-fa 81 95 09 de ba b3   .}.............
        041a - 3c 82 b0 7e 65 df c7 e4-b9 13 db d2 e9 79 05   <..~e........y.
        0429 - 65 a1 af 11 cb 46 f1 16-d1 30 07 cb ba 8f 81   e....F...0.....
        0438 - a0 41 98 45 56 52 83 f6-1f e1 43 17 6e a3 d3   .A.EVR....C.n..
        0447 - ee 9a 5c 1b 85 59 8f 45-26 6f 3c 7c fa c9 29   ..\..Y.E&o<|..)
        0456 - 2c 61 74 2e 89 16 1d ae-b8 8f 25 22 c1 62 99   ,at.......%".b.
        0465 - dc c2 b6 30 f0 ea d5 79-6e f5 f3 9b 87 90 be   ...0...yn......
        0474 - ed 71 99 a5 da 7b 29 29-d2 cc 49 f3 a8 0d 3c   .q...{))..I...<
        0483 - 4b fc 4f 83 5e 76 fc 2f-41 92 ba e5 08 80 38   K.O.^v./A.....8
        0492 - 98 e8 e4 64 02 8d 26 83-19 3a b2 0a a8 b1 06   ...d..&..:.....
        04a1 - 64 7c 4d 9d ec 8f b4 eb-ec c4 86 4b 7b cc 68   d|M........K{.h
        04b0 - d5 f3 4d 9b f4 b3 53 e6-88 a6 ad bb            ..M...S.....
    certificates:
      d.certificate: 
        cert_info: 
          version: 2
          serialNumber: 0x3945353734443130303430394339423632364233303838354342353735443100
          signature: 
            algorithm: sha512WithRSAEncryption (1.2.840.113549.1.1.13)
            parameter: NULL
          issuer: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=BlogPostCert
          validity: 
            notBefore: Jul  8 22:24:59 2024 GMT
            notAfter: Jul 15 00:24:59 2024 GMT
          subject: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=BlogPostCert
          key:           X509_PUBKEY: 
            algor: 
              algorithm: rsaEncryption (1.2.840.113549.1.1.1)
              parameter: NULL
            public_key:  (0 unused bits)
              0000 - 30 82 01 0a 02 82 01 01-00 d5 c7 b1 67 69   0...........gi
              000e - b2 57 d8 f6 90 5f 54 5f-50 0e e1 51 02 9d   .W..._T_P..Q..
              001c - 19 78 e1 41 69 70 40 1f-f0 a0 58 b8 37 4e   .x.Aip@...X.7N
              002a - 59 69 55 6c 51 37 37 ec-e1 41 71 d0 ac fe   YiUlQ77..Aq...
              0038 - fe df 77 25 95 5e 0b 40-d5 31 5f 99 9a 69   ..w%.^.@.1_..i
              0046 - a2 23 ca da 58 4c d7 c9-73 cd 41 b1 bd cb   .#..XL..s.A...
              0054 - a6 d8 22 fb c1 6e c2 42-62 6b 8d 25 63 6a   .."..n.Bbk.%cj
              0062 - f0 c8 35 af 22 e7 4f fa-c6 19 da 2f 4e 67   ..5.".O..../Ng
              0070 - 97 f4 a2 9f a2 e3 88 27-08 d3 0f 9a b6 a7   .......'......
              007e - 21 fe a1 d5 21 65 7d 55-08 18 a8 b4 91 3f   !...!e}U.....?
              008c - 51 f4 eb 5c f6 cd 17 d3-07 e3 d2 86 33 83   Q..\........3.
              009a - 82 87 e6 84 44 59 f5 f7-79 e1 f1 3b 1c ba   ....DY..y..;..
              00a8 - 35 66 8b 8d d3 cb 2b 6d-4e 59 08 46 af b2   5f....+mNY.F..
              00b6 - 03 f4 7e 94 4d 9b 9c c4-ac d2 2a eb 92 51   ..~.M.....*..Q
              00c4 - 48 57 e4 73 95 ad 5f 12-d8 1f bc 00 7f c3   HW.s.._.......
              00d2 - b2 3e 74 0b af 8e 78 34-14 d2 79 d2 5e c7   .>t...x4..y.^.
              00e0 - ea 60 36 7c 39 4d ae 7a-3c 96 9a e5 d2 1f   .`6|9M.z<.....
              00ee - 79 43 16 25 4e c2 91 09-a3 d2 17 f6 cf 13   yC.%N.........
              00fc - 27 55 70 14 93 a2 99 57-5b d8 0d 18 d7 02   'Up....W[.....
              010a - 03 01 00 01                                 ....
          issuerUID: <ABSENT>
          subjectUID: <ABSENT>
          extensions:
            <ABSENT>
        sig_alg: 
          algorithm: sha512WithRSAEncryption (1.2.840.113549.1.1.13)
          parameter: NULL
        signature:  (0 unused bits)
          0000 - 2b 62 c2 af 16 cd 4e ea-50 76 17 1b ac 66 4f   +b....N.Pv...fO
          000f - f8 a1 2f d5 4c 32 2e 0b-55 67 ab 4c 5c 5e 1a   ../.L2..Ug.L\^.
          001e - 1f 5a e9 3b 2f 73 1c 57-13 9e 37 5e 44 72 c4   .Z.;/s.W..7^Dr.
          002d - ee 0f 9e 5e 91 ad 3a 62-40 7d 38 0a c8 df 45   ...^..:b@}8...E
          003c - c1 de 65 82 d8 fa 8c a9-39 da dd 18 af 60 9e   ..e.....9....`.
          004b - 39 4d a5 ad ac 72 25 35-c8 35 a8 6e 0d b8 67   9M...r%5.5.n..g
          005a - 9b 15 5d d8 a7 2b 7d 58-8e 5b a6 20 3b f8 9a   ..]..+}X.[. ;..
          0069 - 21 2c a4 60 1d cf 56 6e-c1 42 ef 28 89 d8 3d   !,.`..Vn.B.(..=
          0078 - a7 66 da 78 47 60 92 ae-2b 1a b5 64 4c f9 96   .f.xG`..+..dL..
          0087 - 6c 24 34 70 50 0e 3d 64-db 6a be 60 f7 99 64   l$4pP.=d.j.`..d
          0096 - 47 86 15 cd 3e d0 81 4c-c7 af ca fa f4 bd cf   G...>..L.......
          00a5 - bd 1d 08 01 03 d4 cd e1-3f 75 0c e1 34 9a 0b   ........?u..4..
          00b4 - 4f 43 cb da ae 4d 79 b3-a0 69 51 c4 13 ba 44   OC...My..iQ...D
          00c3 - 8b a4 c1 6e 19 ee 19 1c-e6 fe bc 68 6e 04 0b   ...n.......hn..
          00d2 - 8c 1b f6 4c e9 17 09 08-1c 86 98 a9 43 25 88   ...L........C%.
          00e1 - 9a 2c bd e3 7b 4a e7 65-89 d2 8b 78 86 21 77   .,..{J.e...x.!w
          00f0 - 28 7f 0f 06 ab 66 17 07-f4 89 cb bf c9 1a 19   (....f.........
          00ff - fb                                             .
    crls:
      <ABSENT>
    signerInfos:
        version: 1
        d.issuerAndSerialNumber: 
          issuer: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=BlogPostCert
          serialNumber: 0x3945353734443130303430394339423632364233303838354342353735443100
        digestAlgorithm: 
          algorithm: sha512 (2.16.840.1.101.3.4.2.3)
          parameter: NULL
        signedAttrs:
            object: undefined (2.16.840.1.113733.1.9.2)
            set:
              PRINTABLESTRING:19

            object: contentType (1.2.840.113549.1.9.3)
            set:
              OBJECT:pkcs7-data (1.2.840.113549.1.7.1)

            object: signingTime (1.2.840.113549.1.9.5)
            set:
              UTCTIME:Jul  8 22:24:59 2024 GMT

            object: undefined (2.16.840.1.113733.1.9.5)
            set:
              OCTET STRING:
                0000 - ce 41 25 b3 4a 01 e3 57-83 36 04 c8 72   .A%.J..W.6..r
                000d - ac 0f 61                                 ..a

            object: undefined (2.16.840.1.113733.1.9.7)
            set:
              PRINTABLESTRING:9E574D100409C9B626B30885CB575D1A

            object: messageDigest (1.2.840.113549.1.9.4)
            set:
              OCTET STRING:
                0000 - 3b 33 8f 3d c7 3c f1 a2-00 16 85 2f a5   ;3.=.<...../.
                000d - ad 7c b5 4b e5 95 cf c2-f2 ee d4 59 3f   .|.K.......Y?
                001a - 8f b0 6b a8 01 37 39 01-a7 e5 8e f4 ee   ..k..79......
                0027 - 67 70 cd 9d e9 43 03 a4-8d 8a ea e0 20   gp...C...... 
                0034 - 50 34 68 8e f2 f4 70 88-c7 e0 5f d3      P4h...p..._.
        signatureAlgorithm: 
          algorithm: rsaEncryption (1.2.840.113549.1.1.1)
          parameter: NULL
        signature: 
          0000 - 38 89 f3 cd c7 9c 88 ef-a6 ca f3 c5 6d 33 0c   8...........m3.
          000f - 3e b3 51 d2 26 79 fd 7e-d6 ec 66 53 43 81 fd   >.Q.&y.~..fSC..
          001e - bf a1 bf f3 f5 6c c1 cc-c6 42 5c e2 6d ce aa   .....l...B\.m..
          002d - 76 c2 c3 f6 d2 62 73 c6-05 48 8d c9 78 d5 9b   v....bs..H..x..
          003c - b0 c9 36 65 87 d3 da 4e-7b 70 61 23 c2 ff 74   ..6e...N{pa#..t
          004b - ea 4b 6d 1d d7 f8 fa 09-2e 66 4b 45 08 fb cb   .Km......fKE...
          005a - 38 43 68 d7 b8 5f e7 6b-91 db 52 15 82 c3 d7   8Ch.._.k..R....
          0069 - 52 56 7d f2 aa f4 e3 75-96 2e fd 1e 68 16 16   RV}....u....h..
          0078 - e1 99 51 c8 bc 9d 4c e7-82 33 12 d8 a3 78 45   ..Q...L..3...xE
          0087 - 75 dd 95 e8 f5 d7 dc d9-c0 64 70 ac 2b 0e f1   u........dp.+..
          0096 - f7 27 d3 da 4a 80 b9 d0-16 16 4c 69 bd ef 71   .'..J.....Li..q
          00a5 - aa 6f 8a 4c bf 10 63 d4-27 9a 0c e8 21 fe ae   .o.L..c.'...!..
          00b4 - 0d ca cc 52 c6 9d 12 dc-4f 8d 82 70 cc 74 00   ...R....O..p.t.
          00c3 - aa 58 5f f8 44 b5 de 84-b0 ef 0e b1 00 c0 82   .X_.D..........
          00d2 - 73 ce 9a ea 49 f5 41 00-34 0a 82 1a ec 46 ce   s...I.A.4....F.
          00e1 - 8d 3c 07 a6 50 6b 7f 11-01 db 08 14 03 6c 72   .<..Pk.......lr
          00f0 - 24 bd 1e 40 50 96 16 bd-cf 59 86 fa 0f 66 57   $..@P....Y...fW
          00ff - e6                                             .
        unsignedAttrs:
          <ABSENT>
```

```sh
# Extract the self signed certificate
openssl cms -verify -in scep_raw -inform DER -signer self_signed.cer -noverify -out /dev/null
```

```
CMS Verification successful
```


# Encryption

The keen eyed will have noticed that the `eContentType` was `pkcs7-data`. I.e. inside this CMS encapsulation is another CMS encapsulation, except this one is responsible for encrypting the certificate request.

Using the *-verify* command we can verify the signature and extract the content. The seemingly contradictory *-noverify* disables verification of the signing certificate of the message, while still checking the signature. We can't verify the certificate because at this point it's a self-signed certificate.

As before, we use take a look at the much simpler structure:


```{.sh .language-sh}
openssl cms -verify -in scep_raw -inform DER -signer self_signed.cer -noverify |
  openssl cms -inform DER -cmsout -print
```

```
CMS Verification successful
CMS_ContentInfo: 
  contentType: pkcs7-envelopedData (1.2.840.113549.1.7.3)
  d.envelopedData: 
    version: 0
    originatorInfo: <ABSENT>
    recipientInfos:
      d.ktri: 
        version: 0
        d.issuerAndSerialNumber: 
          issuer: C=AU, ST=Victoria, L=Melbourne, CN=foletta.xyz Root CA/emailAddress=greg@foletta.org
          serialNumber: 13257416122132238758
        keyEncryptionAlgorithm: 
          algorithm: rsaEncryption (1.2.840.113549.1.1.1)
          parameter: NULL
        encryptedKey: 
          0000 - 5f 29 c1 27 27 6a fd 1b-56 01 ac 78 0a 4d b9   _).''j..V..x.M.
          000f - f8 2b 55 c4 81 54 c4 9d-a2 6c ed 91 fe 34 61   .+U..T...l...4a
          001e - 60 b8 41 7b 97 f3 3f bf-5e 5e d3 4e 62 1b 9b   `.A{..?.^^.Nb..
          002d - b8 30 84 97 4e 25 91 2b-7b 3f 07 52 b9 5a 6b   .0..N%.+{?.R.Zk
          003c - 9b 55 30 03 43 65 ce bc-8e 5b 4f 68 15 ad 70   .U0.Ce...[Oh..p
          004b - 3b a7 0e 76 28 08 95 83-7d 46 91 16 cc ac ce   ;..v(...}F.....
          005a - b7 6f c3 5d 9c 99 0f 63-69 82 be 6d b5 81 5a   .o.]...ci..m..Z
          0069 - 92 ab 4a 49 1a 84 eb 24-7c ae 32 37 c4 d5 16   ..JI...$|.27...
          0078 - af 93 d4 c4 68 8a 92 e1-7e 82 6b 70 8c 61 e9   ....h...~.kp.a.
          0087 - d6 f7 ab 6f 3d 42 88 ae-7d b8 83 e4 da f6 bc   ...o=B..}......
          0096 - b8 2e 14 24 59 96 44 58-8b e9 c6 ab 17 81 c1   ...$Y.DX.......
          00a5 - 72 b5 bd fc 9c 3b 12 a5-ea 54 69 f9 cd 4e 6d   r....;...Ti..Nm
          00b4 - 3f 07 73 5e 5a e1 3d 5d-57 ca 80 a1 e9 3b 44   ?.s^Z.=]W....;D
          00c3 - f1 9b 1c 18 c6 b1 32 8b-a1 89 c2 cc cc 1b b5   ......2........
          00d2 - dc 12 90 b3 a3 4b fe 9a-2d fc 2f 69 21 6d 4b   .....K..-./i!mK
          00e1 - 62 3a c6 53 0b 64 27 9a-22 df bb 2d 65 bc d9   b:.S.d'."..-e..
          00f0 - 56 13 ca fd d3 fc e3 d0-1a 69 03 c6 1b 06 23   V........i....#
          00ff - 0f                                             .
    encryptedContentInfo: 
      contentType: pkcs7-data (1.2.840.113549.1.7.1)
      contentEncryptionAlgorithm: 
        algorithm: des-ede3-cbc (1.2.840.113549.3.7)
        parameter: OCTET STRING:
          0000 - 01 ed 63 51 42 91 6e a0-                       ..cQB.n.
      encryptedContent: 
        0000 - 7e f2 df fc ee 14 b2 62-5a ea c0 56 17 73 ce   ~......bZ..V.s.
        000f - 15 d2 15 d0 5d 35 82 78-c5 87 ec 01 92 f1 ef   ....]5.x.......
        001e - e9 c4 9a 93 56 22 eb bc-e1 9d 45 1a 9c 0d 58   ....V"....E...X
        002d - bf b8 4e ba 82 ac 74 18-23 1c 89 07 1f 29 3b   ..N...t.#....);
        003c - cc 4c a1 db 80 e9 94 25-97 71 9c 38 b8 53 dc   .L.....%.q.8.S.
        004b - 44 0d 8b 4f 6f c1 f8 61-b7 bb d8 8d 33 49 68   D..Oo..a....3Ih
        005a - 11 07 c0 1a dd c5 ab be-2f ac 63 71 79 59 2f   ......../.cqyY/
        0069 - 2a 19 15 df 79 9d 6c c0-e2 b4 c3 39 9d 6f ce   *...y.l....9.o.
        0078 - f8 6a 9a a3 a7 83 4c 84-8a 0c 08 12 2d 27 1d   .j....L.....-'.
        0087 - 4f 63 a4 52 ce 32 df 12-52 03 3f a4 d9 6c e7   Oc.R.2..R.?..l.
        0096 - b7 5d ff a4 08 4c 03 21-8d 49 3d 6b f7 f0 a9   .]...L.!.I=k...
        00a5 - 33 d1 d5 76 c4 89 8d 2c-02 e9 9d 75 d3 16 33   3..v...,...u..3
        00b4 - 38 3d 72 11 b2 86 7a 87-a0 a7 6c a2 bd 5b c7   8=r...z...l..[.
        00c3 - 9c e0 f3 0a bb fc 61 d0-87 65 44 c2 89 bc 48   ......a..eD...H
        00d2 - d9 52 05 83 da eb 22 c4-e0 2b 40 ae 25 5c ca   .R...."..+@.%\.
        00e1 - 0b 43 43 60 e7 05 dc 4d-4f a8 08 3d 0c a1 5f   .CC`...MO..=.._
        00f0 - a4 9a aa 44 6a 68 a2 bd-cd 26 35 a4 a6 52 a3   ...Djh...&5..R.
        00ff - 59 f7 0b 15 a1 6c 66 86-f9 4e 42 ae 6b b7 33   Y....lf..NB.k.3
        010e - 31 18 01 5b 5c 93 47 e9-ca e4 7a 5b d7 4a 8e   1..[\.G...z[.J.
        011d - bc 1e b2 7b 63 ab 82 dc-30 64 51 96 91 6a 48   ...{c...0dQ..jH
        012c - 4c 1b ec 6f f0 ed 46 39-7e 95 ff bc 4a 2a 55   L..o..F9~...J*U
        013b - 2a 4c 99 4b f0 12 4f db-56 15 37 12 ee 15 0a   *L.K..O.V.7....
        014a - 58 91 f2 24 6c 34 a8 37-3b a1 02 68 5b ac e1   X..$l4.7;..h[..
        0159 - e7 2e 48 f1 c9 1b 8d 73-8c e3 6a ef b5 c6 79   ..H....s..j...y
        0168 - 74 f3 11 2c 15 91 f5 9f-f2 d7 bd d6 f2 64 90   t..,.........d.
        0177 - be 62 5a c1 f5 78 c5 80-27 bb 73 9e 08 2b 81   .bZ..x..'.s..+.
        0186 - a6 df c0 48 c5 2d 2f 83-74 a7 b8 1f cc fe d7   ...H.-/.t......
        0195 - e7 a6 17 f9 03 71 21 76-46 6f 2d 9b 20 a2 70   .....q!vFo-. .p
        01a4 - e1 32 e9 6f 14 7a 25 96-38 32 bf 3f 87 81 f5   .2.o.z%.82.?...
        01b3 - 64 ee e5 0f 78 e7 66 32-2d 9f e3 59 2c 9b 99   d...x.f2-..Y,..
        01c2 - 5a b4 a6 89 12 d7 d1 d1-59 73 a5 cd 22 a1 a6   Z.......Ys.."..
        01d1 - ef ed 87 b3 da 9e fa 82-41 87 03 07 7f de 60   ........A.....`
        01e0 - 32 b9 04 75 35 a0 52 95-88 47 bd d5 5f b1 5d   2..u5.R..G.._.]
        01ef - f7 ee 36 c4 8d 1d 99 bb-48 5d 03 47 2c 50 2f   ..6.....H].G,P/
        01fe - a6 15 7d 28 dc 80 d0 75-97 8a f7 ce f8 17 f4   ..}(...u.......
        020d - cb 32 e0 17 e1 c4 f2 ac-8e f0 92 06 b3 01 25   .2............%
        021c - 13 fe 67 58 dc 19 f9 ea-68 e1 dc ec 7d d4 2e   ..gX....h...}..
        022b - a6 b3 1b 89 fa 81 95 09-de ba b3 3c 82 b0 7e   ...........<..~
        023a - 65 df c7 e4 b9 13 db d2-e9 79 05 65 a1 af 11   e........y.e...
        0249 - cb 46 f1 16 d1 30 07 cb-ba 8f 81 a0 41 98 45   .F...0......A.E
        0258 - 56 52 83 f6 1f e1 43 17-6e a3 d3 ee 9a 5c 1b   VR....C.n....\.
        0267 - 85 59 8f 45 26 6f 3c 7c-fa c9 29 2c 61 74 2e   .Y.E&o<|..),at.
        0276 - 89 16 1d ae b8 8f 25 22-c1 62 99 dc c2 b6 30   ......%".b....0
        0285 - f0 ea d5 79 6e f5 f3 9b-87 90 be ed 71 99 a5   ...yn.......q..
        0294 - da 7b 29 29 d2 cc 49 f3-a8 0d 3c 4b fc 4f 83   .{))..I...<K.O.
        02a3 - 5e 76 fc 2f 41 92 ba e5-08 80 38 98 e8 e4 64   ^v./A.....8...d
        02b2 - 02 8d 26 83 19 3a b2 0a-a8 b1 06 64 7c 4d 9d   ..&..:.....d|M.
        02c1 - ec 8f b4 eb ec c4 86 4b-7b cc 68 d5 f3 4d 9b   .......K{.h..M.
        02d0 - f4 b3 53 e6 88 a6 ad bb-                       ..S.....
    unprotectedAttrs:
      <ABSENT>
```
The content-encryption key is randomly generated and used to encrypt the data, then the key itself is encrypted using the signing CA that we received in that first step. I have a copy of the private key of the signing CA ("Blog Post SubCA"), so we can decrypt the content and look at the request.

# The CSR 

Using the *-decrypt* option and the certificate & private key of the signing CA, we can decrypt the CMS content, leaving us with the pure certificate request.


```sh
# Extract verified data
< scep_raw openssl cms -verify -noverify -in - -inform DER -out - |
# Extract encrypted data
  openssl cms -inform DER -decrypt -recip Blog_Post_SubCA.cer -inkey Blog_Post_SubCA.key |
# Parse ceertificate request
  openssl req -inform DER -noout -text
```

```
CMS Verification successful
Certificate Request:
    Data:
        Version: 1 (0x0)
        Subject: C = AU, ST = Victoria, L = Melbourne, O = foletta.xyz, OU = IT, CN = BlogPostCert
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:d5:c7:b1:67:69:b2:57:d8:f6:90:5f:54:5f:50:
                    0e:e1:51:02:9d:19:78:e1:41:69:70:40:1f:f0:a0:
                    58:b8:37:4e:59:69:55:6c:51:37:37:ec:e1:41:71:
                    d0:ac:fe:fe:df:77:25:95:5e:0b:40:d5:31:5f:99:
                    9a:69:a2:23:ca:da:58:4c:d7:c9:73:cd:41:b1:bd:
                    cb:a6:d8:22:fb:c1:6e:c2:42:62:6b:8d:25:63:6a:
                    f0:c8:35:af:22:e7:4f:fa:c6:19:da:2f:4e:67:97:
                    f4:a2:9f:a2:e3:88:27:08:d3:0f:9a:b6:a7:21:fe:
                    a1:d5:21:65:7d:55:08:18:a8:b4:91:3f:51:f4:eb:
                    5c:f6:cd:17:d3:07:e3:d2:86:33:83:82:87:e6:84:
                    44:59:f5:f7:79:e1:f1:3b:1c:ba:35:66:8b:8d:d3:
                    cb:2b:6d:4e:59:08:46:af:b2:03:f4:7e:94:4d:9b:
                    9c:c4:ac:d2:2a:eb:92:51:48:57:e4:73:95:ad:5f:
                    12:d8:1f:bc:00:7f:c3:b2:3e:74:0b:af:8e:78:34:
                    14:d2:79:d2:5e:c7:ea:60:36:7c:39:4d:ae:7a:3c:
                    96:9a:e5:d2:1f:79:43:16:25:4e:c2:91:09:a3:d2:
                    17:f6:cf:13:27:55:70:14:93:a2:99:57:5b:d8:0d:
                    18:d7
                Exponent: 65537 (0x10001)
        Attributes:
            challengePassword        :8qKfdeen
            Requested Extensions:
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        51:ed:42:fa:f0:df:b9:5b:8a:2e:69:0e:26:db:7e:f7:5f:2a:
        c4:49:22:b3:01:ea:db:e1:0e:a9:02:38:22:cd:a2:31:6e:64:
        e3:29:21:4f:17:68:ab:10:20:20:63:ae:1b:d1:85:04:f7:06:
        83:09:99:9a:89:ea:2d:23:62:e9:48:34:a3:08:98:66:ed:da:
        b5:aa:53:28:57:83:e3:9d:ac:ca:b4:05:c7:59:cb:89:7d:12:
        e9:fd:4b:f1:02:d3:29:5e:7f:8e:7c:cd:64:f8:5e:d8:1b:64:
        5f:db:bf:a6:64:e4:95:6b:c0:ae:be:88:bc:e8:ab:b9:14:71:
        60:45:29:cc:6a:7a:31:61:58:81:10:55:a6:d5:a6:4f:09:56:
        f1:f2:2a:a6:e3:e9:d1:24:b4:7f:0b:a2:0b:9d:e1:de:05:14:
        ad:8e:83:ca:c6:23:d1:6a:46:21:c9:1c:00:d2:01:91:4a:48:
        b3:81:df:d8:8b:b4:b1:48:91:52:6f:58:ab:09:4c:0e:b8:14:
        c9:17:da:d9:b6:55:68:64:09:dd:fe:9c:ee:53:3a:22:52:a8:
        2a:98:b7:06:23:43:5a:dc:24:73:cd:c1:cf:34:76:49:01:9e:
        73:63:56:a3:af:ea:4d:53:cb:00:6a:72:5e:81:81:78:e6:73:
        f0:b4:c9:92
```


# Response

The response from the SCEP server containing the certificate is similar: there's the verification CMS, signed using the public key in the certificate request. Within that is the encrypted CMS, signed by the issuing CA. The difference is at the core is a 'degenerate


```sh
# Extract verified response
openssl cms -verify -in scep_response -inform der |
# Decrypt response
openssl cms -decrypt -inform der -recip self_signed.cer -inkey blog.key |
# View 'degenerate' signed data certificates 
openssl pkcs7 -inform der -noout -print_certs -text
```

```
CMS Verification successful
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 5037000822208222218 (0x45e7058f8512540a)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=Blog Post Sub CA
        Validity
            Not Before: Jul  8 22:25:03 2024 GMT
            Not After : Jul  8 22:25:03 2025 GMT
        Subject: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=BlogPostCert
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:d5:c7:b1:67:69:b2:57:d8:f6:90:5f:54:5f:50:
                    0e:e1:51:02:9d:19:78:e1:41:69:70:40:1f:f0:a0:
                    58:b8:37:4e:59:69:55:6c:51:37:37:ec:e1:41:71:
                    d0:ac:fe:fe:df:77:25:95:5e:0b:40:d5:31:5f:99:
                    9a:69:a2:23:ca:da:58:4c:d7:c9:73:cd:41:b1:bd:
                    cb:a6:d8:22:fb:c1:6e:c2:42:62:6b:8d:25:63:6a:
                    f0:c8:35:af:22:e7:4f:fa:c6:19:da:2f:4e:67:97:
                    f4:a2:9f:a2:e3:88:27:08:d3:0f:9a:b6:a7:21:fe:
                    a1:d5:21:65:7d:55:08:18:a8:b4:91:3f:51:f4:eb:
                    5c:f6:cd:17:d3:07:e3:d2:86:33:83:82:87:e6:84:
                    44:59:f5:f7:79:e1:f1:3b:1c:ba:35:66:8b:8d:d3:
                    cb:2b:6d:4e:59:08:46:af:b2:03:f4:7e:94:4d:9b:
                    9c:c4:ac:d2:2a:eb:92:51:48:57:e4:73:95:ad:5f:
                    12:d8:1f:bc:00:7f:c3:b2:3e:74:0b:af:8e:78:34:
                    14:d2:79:d2:5e:c7:ea:60:36:7c:39:4d:ae:7a:3c:
                    96:9a:e5:d2:1f:79:43:16:25:4e:c2:91:09:a3:d2:
                    17:f6:cf:13:27:55:70:14:93:a2:99:57:5b:d8:0d:
                    18:d7
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier: 
                7A:DC:05:7B:2C:A8:E3:F8:9C:E6:40:72:6B:50:4F:81:85:C0:9C:6B
            X509v3 Authority Key Identifier: 
                keyid:7D:10:79:F8:A3:27:D5:8A:31:1C:82:1C:29:40:DF:AD:6B:61:44:D1
                DirName:/C=AU/ST=Victoria/L=Melbourne/CN=foletta.xyz Root CA/emailAddress=greg@foletta.org
                serial:B7:FB:CD:B8:E7:3A:91:A6
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        83:c0:cb:b4:d1:98:32:da:2e:d0:0d:f2:74:f1:2f:a1:9b:05:
        e7:a9:a5:f1:1f:cf:4f:e9:12:27:78:41:c7:76:57:c0:41:1e:
        96:3d:8c:c6:b1:80:17:79:d1:03:ff:ff:fe:ba:01:3a:57:6a:
        ad:30:38:1c:4b:f1:43:60:cd:ca:8e:41:99:d6:24:12:d5:0e:
        1a:c9:ef:e8:b4:6c:ab:33:76:21:e5:66:59:9d:64:10:06:f3:
        b0:96:f8:44:56:69:ee:77:d6:49:57:bc:ff:4a:5b:af:57:7c:
        38:05:85:1d:26:9a:8c:08:de:b2:11:c1:e6:02:bd:88:23:b1:
        2b:1c:5d:d0:bb:fd:a9:87:c5:66:66:d8:f2:95:a1:24:1f:3c:
        ff:14:c3:e4:3b:a5:c1:17:47:5d:f1:e6:c7:b0:12:9c:07:2c:
        cd:ad:68:e2:63:6c:2b:1a:b1:20:ed:53:ce:98:5c:ed:20:fe:
        04:d6:63:bf:15:75:30:0f:bb:6e:91:05:24:9b:6e:99:8f:17:
        57:14:1b:ac:2e:e0:d9:25:3c:64:90:5b:df:dd:d9:24:51:d8:
        b4:8a:31:e0:a4:f4:be:1e:a7:6e:ba:d5:52:15:44:ea:d2:50:
        45:8a:ef:ca:3e:ec:4c:44:f3:72:7e:e5:8d:62:51:dd:8e:f5:
        b1:50:de:71

Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            b7:fb:cd:b8:e7:3a:91:a6
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=AU, ST=Victoria, L=Melbourne, CN=foletta.xyz Root CA/emailAddress=greg@foletta.org
        Validity
            Not Before: Jul  1 02:27:55 2024 GMT
            Not After : Sep 26 06:21:46 2032 GMT
        Subject: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=Blog Post Sub CA
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:b7:77:71:d8:12:49:31:34:1e:86:d6:da:49:85:
                    25:2b:63:06:c6:8f:47:9b:a1:d2:8e:89:fe:41:21:
                    3b:85:19:73:f2:4b:6d:8d:ec:08:8c:fa:5c:4b:fc:
                    a4:5e:e3:4a:34:c8:6d:24:46:16:6a:f1:9b:4a:10:
                    a7:03:b1:e1:73:c0:1a:52:c1:9f:ac:6b:1e:c2:50:
                    29:c8:e4:c7:96:ad:7b:22:8b:0d:57:5e:9f:c9:de:
                    ef:23:63:7a:c8:65:90:27:d1:82:52:3f:cb:a6:40:
                    c8:51:c0:30:62:a7:8d:f8:d1:b3:b3:24:fe:72:89:
                    b0:32:21:4e:ef:36:d7:34:d6:b0:a6:b6:94:4f:21:
                    3e:4f:dd:c6:f6:4e:ed:54:ce:b4:c9:9e:bb:43:32:
                    20:19:a6:c6:7f:78:70:00:55:3e:99:e9:8e:79:95:
                    64:99:d8:0e:c3:79:15:c9:85:37:b2:a4:0a:1f:ff:
                    fb:47:f5:0f:bb:5b:f3:a8:03:b0:c0:0b:f2:61:55:
                    96:bd:68:e2:c0:84:1c:e0:88:a8:bd:5d:13:32:0a:
                    18:33:8c:35:bd:52:08:7a:e7:48:24:da:34:f8:80:
                    63:7c:cc:aa:f9:53:26:fd:ef:4b:7e:a7:b9:a9:c7:
                    16:ae:a1:fd:40:9c:2c:90:04:e7:e7:81:7e:ec:c3:
                    87:95
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier: 
                7D:10:79:F8:A3:27:D5:8A:31:1C:82:1C:29:40:DF:AD:6B:61:44:D1
            X509v3 Authority Key Identifier: 
                keyid:78:F7:FA:39:92:DA:E7:CF:FF:7E:6F:22:15:E5:22:28:D0:18:26:44
                DirName:/C=AU/ST=Victoria/L=Melbourne/CN=foletta.xyz Root CA/emailAddress=greg@foletta.org
                serial:15:A7:81:6A:BC:1B:81:8E
            X509v3 Key Usage: 
                Digital Signature, Certificate Sign, CRL Sign
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        44:ac:84:76:8c:fd:1e:2f:20:15:bd:89:44:39:30:6b:6d:75:
        b2:59:43:e4:05:da:f9:c5:e4:81:41:f1:2d:b8:36:6e:60:9d:
        07:92:0d:38:58:18:78:f2:67:9f:84:f0:10:80:20:5a:7d:d2:
        83:ff:17:9a:4a:ce:a1:69:fd:8c:19:a8:1c:7c:ca:1b:60:f9:
        32:07:97:5b:6b:bc:ce:a2:ca:ec:c1:6c:e4:8c:7e:4f:9a:54:
        de:ed:7b:92:e4:55:6c:f7:bd:f9:05:51:10:e4:a7:6c:2e:eb:
        3c:77:ee:a3:c6:75:5a:e7:c4:a1:74:99:a7:f2:de:0e:c7:b3:
        af:be:58:b3:12:43:16:68:b3:54:b0:01:0a:4a:a5:df:e4:ee:
        dc:d3:d8:f6:d2:75:0a:d5:b6:0d:b1:04:eb:78:3e:4d:e6:c4:
        1f:fa:32:7a:0e:fa:a1:74:c2:a9:69:29:ad:82:16:eb:91:e1:
        97:e1:fd:b3:4b:de:eb:c8:19:c6:fb:02:9c:e9:dc:4d:cf:85:
        53:8a:1b:46:05:d1:1d:0d:04:ca:bb:04:5f:e8:9d:dd:98:d3:
        4e:90:53:28:6e:86:f2:fe:3f:98:ad:6b:31:24:b7:69:22:39:
        47:24:d5:57:0a:29:bf:b9:a1:86:36:d2:31:a3:2b:c6:a6:9d:
        9d:f2:df:b2
```

