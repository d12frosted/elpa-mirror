This package adds support for harper (https://writewithharper.com/)
for Flymake.  This package is a fork of Manuel Uberti's
"flymake-proselint".  Once installed, the backend can be enabled
with by calling `flymake-harper-setup' manually or using a hook.
Configure `flymake-harper-disable' to disable certain types of
warnings, if you are experiencing too many false positives.