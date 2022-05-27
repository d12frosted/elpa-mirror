Table of Contents
─────────────────

1. shellcop
2. Install
3. Usage
4. Contact me
5. License


1 shellcop
══════════

  [https://github.com/redguardtoo/shellcop/actions/workflows/test.yml/badge.svg]
  [file:https://elpa.nongnu.org/nongnu/shellcop.svg]
  [file:http://melpa.org/packages/shellcop-badge.svg]
  [file:http://stable.melpa.org/packages/shellcop-badge.svg]

  Analyze info&error in shell-mode.


[https://github.com/redguardtoo/shellcop/actions/workflows/test.yml/badge.svg]
<https://github.com/redguardtoo/shellcop/actions/workflows/test.yml>

[file:https://elpa.nongnu.org/nongnu/shellcop.svg]
<https://elpa.nongnu.org/nongnu/shellcop.html>

[file:http://melpa.org/packages/shellcop-badge.svg]
<http://melpa.org/#/shellcop>

[file:http://stable.melpa.org/packages/shellcop-badge.svg]
<http://stable.melpa.org/#/shellcop>


2 Install
═════════

  shellcop is already uploaded to <http://melpa.org>. The best way to
  install is Emacs package manager.


3 Usage
═══════

  Insert below code into `~/.emacs',
  ┌────
  │ (add-hook 'shell-mode-hook 'shellcop-start)
  └────

  Start `shell-mode' by `M-x shell'.

  Run any command line program in `shell-mode'. Move the focus inside
  the output of the program.

  Press `Enter' key or `M-x shellcop-goto-location-near-point'. The file
  path and line number information is extracted and you can open
  corresponding file. The cursor is not required to be on the same line
  containing file path.

  <file:demo.png>

  Run `shellcop-reset-with-new-command' to,
  • kill current running process
  • erase the content in shell buffer
  • If `shellcop-sub-window-has-error-function' return nil in all
    sub-windows, run `shellcop-insert-shell-command-function'

  Run `shellcop-erase-buffer' to erase current buffer in `shell-mode'
  and `message-buffer-mode'. Or else it erases content in message
  buffer.

  Run `shellcop-jump-around' to jump to directories recorded by
  <https://github.com/rupa/z>,
  • If shell is visible, \"cd dest-dir\" is inserted into shell
  • Or else, the directory is opened in `dired-mode'

  Run `shellcop-search-in-shell-buffer-of-other-window'. Use current
  word or selected text to search in *shell* buffer of the other window.


4 Contact me
════════════

  Report bug at <https://github.com/redguardtoo/shellcop>.


5 License
═════════

  This program is free software: you can redistribute it and/or modify
  it under the terms of the [GNU General Public License] as published by
  the Free Software Foundation, either version 3 of the License, or (at
  your option) any later version.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU
  General Public License] for more details.


[GNU General Public License] <file:LICENSE>
