Major for viewing certificates, CRLs, keys and DH-parameters.

Uses OpenSSL for viewing PEM and DER encoded PKI entities.

Usage:
Open a file containing a certificate, either PEM or DER encode.  Now
use M-x `x509-viewcert' to create a new buffer that displays the decoded
certificate.

Use `x509-viewcrl', `x509-viewasn1',`x509-viewkey', `x509-viewdh',
`x509-viewreq' in a similar manner.
