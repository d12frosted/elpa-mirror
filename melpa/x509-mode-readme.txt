Major for viewing certificates, CRLs, keys and DH-parameters.

Uses OpenSSL for viewing PEM and DER encoded PKI entities.

Usage:
Open a file containing a certificate, either PEM or DER encode.  Now
use M-x `x509-viewcert' to create a new buffer that displays the decoded
certificate.
Use M-x `x509-viewcrl', M-X `x509-viewasn1', M-x `x509-viewkey' and M-x
`x509-viewdh' in a similar manner.
