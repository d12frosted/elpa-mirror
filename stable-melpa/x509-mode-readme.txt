Major mode for viewing certificates, CRLs, and other PKI-related files.

Uses OpenSSL for viewing PEM and DER encoded PKI entities.

Usage:
Open a file containing a certificate, either PEM or DER encode.  Now
use M-x `x509-viewcert' to create a new buffer that displays the decoded
certificate.
Use `x509-viewcrl', `x509-viewasn1',`x509-viewkey', `x509-viewdh',
`x509-viewreq', `x509-viewpkcs7' in a similar manner.

When point is at or in a PEM encoded region, M-x `x509-dwim' tries to guess
what view-function to call.  It falls back to `x509-viewasn1' if it fails.

Use C-u prefix with any command for editing the command arguments.

When in a x509 buffer, use keys `e' and `t' to edit current command or
toggle between x509-asn1-mode and x509-mode respectively.
