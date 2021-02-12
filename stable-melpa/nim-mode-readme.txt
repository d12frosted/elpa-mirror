## TL;DR

For regular Emacs users, all you need is below configuration in your
dot Emacs after you installed nim-mode from MELPA and nimsuggest
which you can make by `./koch tools` or `./koch nimsuggest`command in
the Nim repository (or check the official document on Nim website if
this information was outdated):

Activate nimsuggest dedicated mode on `nim-mode':

  (add-hook 'nim-mode-hook 'nimsuggest-mode)

Below configs are can be optional

The `nimsuggest-path' will be set the value of (executable-find "nimsuggest")
automatically.

  (setq nimsuggest-path "path/to/nimsuggest")

You may need to install below packages if you haven't installed yet.

-- Auto completion --
You can omit if you configured company-mode on 'prog-mode-hook
  (add-hook 'nimsuggest-mode-hook 'company-mode)  ; auto complete package

-- Auto lint --
You can omit if you configured flycheck-mode on 'prog-mode-hook

  (add-hook 'nimsuggest-mode-hook 'flycheck-mode) ; auto linter package

See more information at https://github.com/nim-lang/nim-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
