This package provides displaying all misspelled words in the buffer
with consult.

With the variable `consult-flyspell-select-function' it is possible to apply a function
after choosing a candidate.
Two possibilities are:
(setq consult-flyspell-select-function 'flyspell-correct-at-point)
To correct word directly with `flyspell-correct-word'.

(setq consult-flyspell-select-function (lambda () (flyspell-correct-at-point) (consult-flyspell)))
To correct word directly with `flyspell-correct-word' and jump back to `consult-flyspell'.
