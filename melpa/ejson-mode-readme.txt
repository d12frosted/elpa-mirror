Major mode designed for editing ejson files.  Will automatocally
generate encryption keys if none are present in the file and allows
for manual in-buffer encryption and decryption, and optional
automatic ejson encryption on save.  Location of ejson keystore and
binary can be set manually.  See https://github.com/Shopify/ejson
for more details.

; Default keybindings

C-x C-s Save and encrypt a file, generate a key if necessary
C-c C-e Encrypt the saved file (run on save by default)
C-c C-d Decrypt the file into the current buffer

; Variables

All can be set through customization group ejson

`ejson-binary-location' Manually specify the location of the ejson binary
`ejson-keystore-location' Specify an alternate location for the ejson keystore
`ejson-encrypt-on-save' Disable automatic encryption on save
