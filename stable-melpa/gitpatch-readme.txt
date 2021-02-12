* What is gitpatch                                      :README:
Gitpatch is git-format patch toolkit, which let user easy handle
git-format patch without exit Emacs.

1. Send patch with `gitpatch-mail'

   `gitpatch-mail' can quick send a git-format patch file from magit,
   dired or ibuffer buffer.

** Installation

1. Config melpa source, please read: [[http://melpa.org/#/getting-started]]
2. M-x package-install RET gitpatch RET

** Configure

#+BEGIN_EXAMPLE
(require 'gitpatch)
(setq gitpatch-mail-attach-patch-key "C-c i")
#+END_EXAMPLE

** Usage
*** gitpatch-mail
1. Move the point to the patch-name in magit-status, dired or ibuffer buffer.
2. M-x gitpatch-mail
3. Select an email address as TO Field, if you set `gitpatch-mail-database'.
4. Add another patch with "C-c i" by default (Optional).
5. Edit and send email.

NOTE: User can config `gitpatch-mail' in other type buffer with the help of
`gitpatch-mail-get-patch-functions'
