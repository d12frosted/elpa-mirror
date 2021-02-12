Package to help adding information on commits by checking older
commits and extracting a particular substring from each of them.

Useful to follow organisation policies on how to write commits.

The default command presents a searchable list of the previous
commits (more recent first), and lets you select the one you want.
This list of candidates is configurable via
`git-msg-prefix-log-command`.  Once selected, the relevant part
of the commit line will be extracted from the choosen candidate
via the regex in `git-msg-prefix-regex', and the matched text
will be inserted in the current buffer.

example configurations with use-package:

(use-package git-msg-prefix
  :ensure t
  :config
  (setq git-msg-prefix-log-flags " --since='1 week ago' "
        git-msg-prefix-input-method 'helm-comp-read)
  (add-hook 'git-commit-mode-hook 'git-msg-prefix))

bare configuration:

(add-hook 'git-commit-mode-hook 'git-msg-prefix)
(setq git-msg-prefix-input-method 'helm-comp-read)

Otherwise, add a keybinding to that function or run it manually
from the minibuffer.
  (local-set-key
   (kbd "C-c i")
   'git-msg-prefix)

Configure

There are 3 variables to configure:

- ~git-msg-prefix-log-command~: defaults to "git log
  --pretty=format:\"%s\""
- ~git-msg-prefix-log-flags~: defaults to ""

- ~git-msg-prefix-regex~: defaults to  "^\\([^ ]*\\) "

 - ~git-msg-prefix-input-method~: defaults to
   ido-completing-read. Change it to your favourite input
   method. ('completing-read 'ido-completing-read
   'helm-comp-read 'ivy-read)
