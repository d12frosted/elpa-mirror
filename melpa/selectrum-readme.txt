Selectrum is a better solution for incremental narrowing in Emacs,
replacing Helm, Ivy, and IDO. Its design philosophy is based on
choosing the right abstractions and prioritizing consistency and
predictability over special-cased improvements for particular
cases. As such, Selectrum follows existing Emacs conventions where
they exist and are reasonable, and it declines to implement
features which have marginal benefit compared to the additional
complexity of a new interface.

Getting started: Selectrum provides a global minor mode,
`selectrum-mode', which enhances `completing-read' and all related
functions automatically without the need for further configuration.

Please see https://github.com/raxod502/selectrum for more
information.
