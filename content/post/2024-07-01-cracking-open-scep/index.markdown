---
title: Cracking Open SCEP
author: 'Greg Foletta'
date: '2024-07-10'
categories: [Shell PKI]
---

Most of the posts on this site tend to be long form, a result of me finding it hard to leave stones unturned. This leads to big gaps between posts; in fact the the radio silence over the past nine months is because I've had two in draft form and haven't been able to get them over the line.

As an antidote to this I've put together something a little more bite-size. In this post we're going to crack open a *Simple Certificate Enrollment Protocol (SCEP)* request. We'll do this on the command line, using the openssl tool peer underneath the hood, and get a good understanding of some of the structures, and the verification and encryption processes.

# The SCEP Request

Here's a screenshot of a packet capture taken during a SCEP request for a new certificate:

![SCEP Capture](scep_capture.png)

This SCEP request is actually two requests: the first returns an X509 CA certificate, and the second is the certificate request. We'll see how the X509 certificate is used later on, but if we focus in on the second one we see the bulk of the request is passed in the *message* query parameter. I've copied the contents of this to a file named *scep_message*:

```sh
# Size in bytes
wc -c scep_message
4089 

# First 64 bytes
cut -c1-64 scep_message 
MIILLAYJKoZIhvcNAQcCoIILHTCCCxkCAQExDzANBglghkgBZQMEAgMFADCCBM8G
```

This message parameter contins the singing request, wrapped up like an onion (sometimes including the tears), with layer after layer of different encodings and structures. This first *message* parameter is URI encoded, then base64 encoded, so we decode these store what I'll call the 'raw' SCEP in a file called *scep_raw*.


```sh
# Remove the URI and base64 encoding
< scep_message perl -MURI::Escape -e 'print uri_unescape(<STDIN>)' | base64 -d > scep_raw
```

## Signing

Before moving on, a quick view of the PKI layout:

- The CN of the certificate request is **BlogPostCert**.
- I've created a sub-CA with a CN of **Blog Post Sub CA** that will sign the request.
- This sub-CA is signed by the root CA which has a CN of **foletta.xyz Root CA**.

Now we can get into the meat and bones. After URI/base64 decoding, the next wrapper is [Cryptographic Message Syntax (CMS)](https://en.wikipedia.org/wiki/Cryptographic_Message_Syntax) encapsulated data. Originally part of the PKCS standards defined by RSA security (PKCS7 to be exact), CMS is now an IETF standard under [RFC 5652 ](https://datatracker.ietf.org/doc/html/rfc5652). It provides a way to digitally sign, digest, authenticate, or encrypt arbitrary message content. 

Using the openssl *cms* command with the *-print* argument, we look at the structure of this first CMS wrapper. I've redacted some of the less-relevant content and added some comments:

```{.sh .fold-hide}
# Print the CMS structure
openssl cms -in scep_raw -cmsout -inform DER -print
```

```sh
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
        # The verified content (removed for brevity)
    certificates:
      # This is an inline certificate, partner of the private key that signed the content
      d.certificate: 
        cert_info: 
          version: 2
          serialNumber: 0x3945353734443130303430394339423632364233303838354342353735443100
          signature: 
            algorithm: sha512WithRSAEncryption (1.2.840.113549.1.1.13)
            parameter: NULL
          # We see this is a temporary, self-signed certificate
          issuer: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=BlogPostCert
          # We get a week to sign the request
          validity: 
            notBefore: Jul  8 22:24:59 2024 GMT
            notAfter: Jul 15 00:24:59 2024 GMT
          subject: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=BlogPostCert
          key:           X509_PUBKEY: 
            algor: 
              algorithm: rsaEncryption (1.2.840.113549.1.1.1)
              parameter: NULL
            public_key:  (0 unused bits)
                # Removed for brevity
          issuerUID: <ABSENT>
          subjectUID: <ABSENT>
          extensions:
            <ABSENT>
        sig_alg: 
          algorithm: sha512WithRSAEncryption (1.2.840.113549.1.1.13)
          parameter: NULL
        signature:  (0 unused bits)
            # Signature to verify removed for brevity
    crls:
      <ABSENT>
    # The signing information to allow the content to be verified
    signerInfos:
        version: 1
        d.issuerAndSerialNumber: 
          # Issuer and serial number of the certificate required to verify.
          # This matches the above inline certificate
          issuer: C=AU, ST=Victoria, L=Melbourne, O=foletta.xyz, OU=IT, CN=BlogPostCert
          serialNumber: 0x3945353734443130303430394339423632364233303838354342353735443100
        digestAlgorithm: 
          algorithm: sha512 (2.16.840.1.101.3.4.2.3)
          parameter: NULL
        signedAttrs:
            # Removed for brevity
        signatureAlgorithm: 
          algorithm: rsaEncryption (1.2.840.113549.1.1.1)
          parameter: NULL
        signature: 
            # Signature used to verify (removed for brevity).
        unsignedAttrs:
          <ABSENT>
```

The main question I had was what signs this content? The answer we see from the above output is that it's signed by the requestor's newly generated private key. But as there's no certificate yet (that's the whole point of the request), the requestor creates a temporary self-signed certificate containing the public key, and includes it in the CMS data. This allows the SCEP server to authenticate the data that's been transferred.

This self-signed certificate will come in handy later, so it's extracted using the *-verify* and *-signer* arguments:

```sh
# Extract the self signed certificate
openssl cms -verify -in scep_raw -inform DER -signer self_signed.cer -noverify -out /dev/null

# View the self-signed cert
openssl x509 -in self_signed.cer -noout -text
```

```sh
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            39:45:35:37:34:44:31:30:30:34:30:39:43:39:42:36:32:36:42:33:30:38:38:35:43:42:35:37:35:44:31:00
        Signature Algorithm: sha512WithRSAEncryption
        Issuer: C = AU, ST = Victoria, L = Melbourne, O = foletta.xyz, OU = IT, CN = BlogPostCert
        Validity
            Not Before: Jul  8 22:24:59 2024 GMT
            Not After : Jul 15 00:24:59 2024 GMT
        Subject: C = AU, ST = Victoria, L = Melbourne, O = foletta.xyz, OU = IT, CN = BlogPostCert
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    # Removed for brevity
                Exponent: 65537 (0x10001)
    Signature Algorithm: sha512WithRSAEncryption
    Signature Value:
        # Removed for brevity
```

## Encryption

The keen eyed will have noticed that the `eContentType` was `pkcs7-data`. I.e. inside this CMS encapsulation is another CMS encapsulation, except this one is responsible for encrypting the certificate request.

Using the *-verify* command we can verify the signature and extract the content, piping to openssl again to view the structure of the encrypted CMS. The seemingly contradictory *-noverify* disables verification of the signing certificate of the message (while still checking the actual signature) as we can't verify that self-signed certificate.

```{.sh .language-sh}
# Verify, extract, and pipe out contents
openssl cms -verify -in scep_raw -inform DER -noverify |
# Print second CMS structure
  openssl cms -inform DER -cmsout -print
```

```sh
CMS_ContentInfo: 
  contentType: pkcs7-envelopedData (1.2.840.113549.1.7.3)
  d.envelopedData: 
    version: 0
    originatorInfo: <ABSENT>
    recipientInfos:
      d.ktri: 
        version: 0
        d.issuerAndSerialNumber: 
          # CN of the issuer and serial of the certificate/keypair required to decrypt the contents
          issuer: C=AU, ST=Victoria, L=Melbourne, CN=foletta.xyz Root CA/emailAddress=greg@foletta.org
          serialNumber: 13257416122132238758
        keyEncryptionAlgorithm: 
          algorithm: rsaEncryption (1.2.840.113549.1.1.1)
          parameter: NULL
        encryptedKey: 
            # 255 byte random key, encrypted with the RSA certificate
    encryptedContentInfo: 
      contentType: pkcs7-data (1.2.840.113549.1.7.1)
      contentEncryptionAlgorithm: 
        # Note the symmetric cipher below
        algorithm: des-ede3-cbc (1.2.840.113549.3.7)
        # I *think* this is the initialisation vector for 3DES
        parameter: OCTET STRING:
          0000 - 01 ed 63 51 42 91 6e a0-                       ..cQB.n.
      encryptedContent: 
        # Content encrypted with the symmetric key
    unprotectedAttrs:
      <ABSENT>
```
The two main sections are *encryptedKey* and *encryptedContent*. The content-encryption key is randomly generated and used to encrypt the data with a symmetric cipher (3DES), then the key itself is encrypted using the public key of the signing CA that was requested in the first step. I have a copy of the private key of the signing CA ("Blog Post SubCA"), so we can decrypt the content and look at the request.

## The Signing Request

Using the *-decrypt* option and the sub-CA certificate/private key, we can decrypt the second CMS to take a look at the certificate signing request, again redacted for brevity:

```sh
# Extract, verify and pipe out content
openssl cms -in scep_raw -verify -inform DER -noverify |
# Decrypt and pipe out content
  openssl cms -inform DER -decrypt -recip Blog_Post_SubCA.cer -inkey Blog_Post_SubCA.key |
# Parse certificate request
  openssl req -inform DER -noout -text
```

```sh
Certificate Request:
    Data:
        Version: 1 (0x0)
        Subject: C = AU, ST = Victoria, L = Melbourne, O = foletta.xyz, OU = IT, CN = BlogPostCert
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    # Removed for brevity
                Exponent: 65537 (0x10001)
        Attributes:
            challengePassword        :8qKfdeen
            Requested Extensions:
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        # Removed for brevity
```

In the core we've got a bog-standard certificate request ready for signing, with no fancy requested extensions. The only attribute is the SCEP challenge password.

A quick aside: as per [RFC 4210](https://www.rfc-editor.org/rfc/rfc4210#section-5.2.1), the signer is able to change any field in this CSR except the public key.

# SCEP Response

The response from the SCEP server containing the certificate is similar to the request: 
- The verification CMS, signed using the public key in the certificate request, allowing to requestor to verify it with their generated private key
- The encrypted CMS, with a key encrypted by self-signed certificate that was sent in the request, allowing the requestor to decrypt using it's generated private key.

The difference is at the core is a degenerate case of the SignedData, with no signers and content, just the certificates. In our case, it has our newly-signed certificate, as well as the certificate of the CA that signed it. The requestor now has the certificate to use as a server certficate on a web-server, or as a client certificate to authenticate themselves to a service.

```sh
# Extract, verify, and pipe response
openssl cms -verify -in scep_response -inform der |
# Decrypt and pipe response
openssl cms -decrypt -inform der -recip self_signed.cer -inkey blog.key |
# View 'degenerate' signed data certificates
# I can't get CMS to open it, so I use pkcs7
openssl pkcs7 -inform der -noout -print_certs -text
```

```sh
# This first certificate is the signed response to our request
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
                    # Removed for brevity
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            # We can't use this certificate to issue other certificates
            X509v3 Basic Constraints: critical
                CA:FALSE
            # Identifier of the public key of this certificate
            X509v3 Subject Key Identifier: 
                7A:DC:05:7B:2C:A8:E3:F8:9C:E6:40:72:6B:50:4F:81:85:C0:9C:6B
            # Identifier of the public key of the CA that signed this certificate
            X509v3 Authority Key Identifier: 
                keyid:7D:10:79:F8:A3:27:D5:8A:31:1C:82:1C:29:40:DF:AD:6B:61:44:D1
                DirName:/C=AU/ST=Victoria/L=Melbourne/CN=foletta.xyz Root CA/emailAddress=greg@foletta.org
                serial:B7:FB:CD:B8:E7:3A:91:A6
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        # Removed for brevity

# This certificate is a copy of the sub-CA that signed the certificate, with the bulk removed for brevity
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
        # Rest of the CA certificate follows from here
```

# Summary

Not sure if this ended up being 'bite-size' in the end, but it was an enjoyable challenge to take the request and response and peel back the layers. The openssl application has got an immense amount of functionality fronted by a pretty hard-to-use interface. I find challenges like this are the best way to get familiar with its incantations, as opposed to copy and pasting commands in from the internet. 
