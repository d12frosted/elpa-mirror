Major mode for viewing certificates, CRLs, and other PKI-related files.

Uses OpenSSL for viewing PEM and DER encoded PKI entities.

Prerequisites: OpenSSL.  Customize the variable `x509-openssl-cmd' to name
the openssl binary.  Defaults are "openssl" on Linux (assuming it's on PATH)
and "C:/Program Files/Git/mingw64/bin/openssl.exe" on Windows (assuming Git
for Windows is installed in its default location).

Usage: Open a file containing a certificate, either PEM or DER encode.  Now
use M-x `x509-viewcert' to create a new buffer that displays the decoded
certificate.  Use `x509-viewcrl', `x509-viewasn1',`x509-viewkey',
`x509-viewpublickey', `x509-viewdh', `x509-viewreq', `x509-viewpkcs7' in a
similar manner.

M-x `x509-dwim' tries to guess what view-function to call.  It falls back to
`x509-viewasn1' if it fails.

If point is at the beginning of, or in, a PEM region, all view functions,
including `x509-dwim', tries extra hard to use that region as input.  This
often works even when there is other data ahead and after region and if the
region is indented or the lines are quoted.

Use C-u prefix with any command for editing the command arguments.

When in a x509 buffer, use keys `e' and `t' to edit current command or
toggle between x509-asn1-mode and x509-mode respectively.

In `x509-asn1-mode', keys `d' and `s' does asn1parse -offset (mnemonic
"down")
or -strparse.  `u' undoes the last `d' or `s'.

Also in `x509-asn1-mode', key `x' displays a buffer in `hexl-mode' that
follows the current line in the asn1 buffer.  Inspired by `rmsbolt-mode'.
