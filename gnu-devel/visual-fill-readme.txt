This `visual-fill-mode' minor mode basically "unfills" paragraphs within
jit-lock, hence without modifying the buffer.  Combined with the normal
line-wrapping this performs a kind of "auto refill" which can be more or
less sophisticated depending on the line-wrapping used.

For best effect, combine it with `visual-line-mode' and
`adaptive-wrap-prefix-mode'.