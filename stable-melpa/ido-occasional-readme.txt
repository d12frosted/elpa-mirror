
This package aims to replace `completing-read' with
`ido-completing-read', similarly to `ido-ubiquitous'.

However, instead of doing it all at once, it only provides a convenience macro
for enabling `ido-completing-read' on a per-function basis:

(global-set-key (kbd "<f1> f") (with-ido-completion describe-function))
(global-set-key (kbd "<f1> v") (with-ido-completion describe-variable))
(global-set-key (kbd "<f2> i") (with-ido-completion info-lookup-symbol))

The advantage is that you don't get `ido' in places where you don't
want `ido', and you get better control over your completion
methods.  For instance, even if you have `helm-mode' on, with the
setup above, "<f1> f" will still use `ido' for completion.
