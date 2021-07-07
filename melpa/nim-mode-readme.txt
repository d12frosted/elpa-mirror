## TL;DR

For regular Emacs users, all you need is below configuration in your
dot Emacs after you installed nim-mode from MELPA and nimsuggest
which you can make by `./koch tools` or `./koch nimsuggest`command in
the Nim repository (or check the official document on Nim website if
this information was outdated):

Activate nimsuggest dedicated mode on `nim-mode':

  (add-hook 'nim-mode-hook 'nimsuggest-mode)

Below configs are can be optional

The `nimsuggest-path` will be set the value of (executable-find "nimsuggest")
automatically.

  (setq nimsuggest-path "path/to/nimsuggest")

You may need to install below package if you haven't installed yet.

-- Auto completion --
You can omit if you configured company-mode on 'prog-mode-hook
  (add-hook 'nimsuggest-mode-hook 'company-mode)  ; auto complete package

-- Auto lint --
You can omit if you configured flycheck-mode on 'prog-mode-hook

  (add-hook 'nimsuggest-mode-hook 'flycheck-mode) ; auto linter package

If you use Emacs 26 or higher, you can also use `flymake' package which
Emacs' builtin standard package for auto lint (it was re written on
Emacs 26) which you can use by below config:

  (add-hook 'nimsuggest-mode-hook 'flymake-mode) ; auto linter package

  Note that currently nim-mode has three choice for the flyXXX's auto
  linter and currently nim-mode repo has `flycheck-nimsuggest' and
  `flymake-nimsuggeset'.  On the future plan, this repo will only ship
  `flymake-nimsuggst' because it is Emacs 26 builtin.

  FYI:
  might be supproted in the future, but not for now
  (add-hook 'nimsuggest-mode-hook 'nimsuggest-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
