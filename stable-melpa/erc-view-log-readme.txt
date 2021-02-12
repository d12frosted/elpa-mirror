Set colors on an ERC log file
Will not work with erc-fill-mode

Installation:
   (require 'erc-view-log)
   (add-to-list 'auto-mode-alist `(,(format "%s/.*\\.log" (regexp-quote (expand-file-name erc-log-channels-directory))) . erc-view-log-mode))

Recommended:
   (add-hook 'erc-view-log-mode-hook 'turn-on-auto-revert-tail-mode)

Options:
- erc-view-log-nickname-face-function:
   A function that returns a face, given a nick, to colorize nicks.
   Can be nil to use standard ERC face.
- erc-view-log-my-nickname-match:
   Either a regexp or a list of nicks, to match the user's nickname.
   For the list, each nick should be unique and should not contain any regexps.

TODO:
- use vlf.el for large logs? has to be adapted (no more major mode, and handle full lines...)
