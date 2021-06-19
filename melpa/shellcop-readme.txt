 Open the file from command line error report,
  - Insert "(add-hook 'shell-mode-hook 'shellcop-start)" into ~/.emacs
  - Start shell-mode by "M-x shell"
  - Run any command line program in shell
  - Press ENTER in the program's output containing file and line number
  - Cursor is NOT required to be on the same line containing file path.

`shellcop-reset-with-new-command' will,
  - kill current running process
  - erase the content in shell buffer
  - If `shellcop-sub-window-has-error-function' return nil in all sub-windows,
    run `shellcop-insert-shell-command-function'.

`shellcop-erase-buffer' erases the content buffer with below names,
  - "*Messages*" (default)
  - "*shell*" (if parameter 1 is passed)
  - "*Javascript REPL*" (if parameter 2 is passed)
  - "*eshell*" (if parameter 3 is passed)

`shellcop-search-in-shell-buffer-of-other-window' uses current word or selected text
to search in *shell* buffer of the other window.
