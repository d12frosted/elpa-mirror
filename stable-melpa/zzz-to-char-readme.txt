This package provides two new commands: `zzz-to-char' and
`zzz-up-to-char' which work like built-ins `zap-to-char' and
`zap-up-to-char', but allow you quickly select exact character you want
to “zzz” to.

The commands are minimalistic and often work like built-in ones when
there is only one occurrence of target character (except they
automatically work in backward direction too). You can also specify how
many characters to scan from each side of point, see `zzz-to-char-reach'.
