Dumb Jump is an Emacs "jump to definition" package with support for 50+ programming languages that favors
"just working" over speed or accuracy.  This means minimal -- and ideally zero -- configuration with absolutely
no stored indexes (TAGS) or persistent background processes.

Dumb Jump provides a xref-based interface for jumping to
definitions. It is based on tools such as grep, the silver searcher
(https://geoff.greer.fm/ag/), ripgrep
(https://github.com/BurntSushi/ripgrep) or git-grep
(https://git-scm.com/docs/git-grep).

To enable Dumb Jump, add the following to your initialisation file:

   (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)

Now pressing M-. on an identifier should open a buffer at the place
where it is defined, or a list of candidates if uncertain. This
list can be navigated using M-g M-n (next-error) and M-g M-p
(previous-error).
