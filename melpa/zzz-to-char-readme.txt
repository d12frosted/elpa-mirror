This package provides two new commands: `zzz-to-char' and
`zzz-up-to-char' which work like the built-ins `zap-to-char' and
`zap-up-to-char', but allow the user to quickly select the exact
character they want to zzz to.  The commands work like the built-ins when
there is only one occurrence of the target character, excepting that they
automatically work in the backward direction, too.  One can specify how
many characters to scan from each side of the point, see
`zzz-to-char-reach'.
