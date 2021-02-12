This package provides a way to automatically trigger recompilation
when associated source buffer changes.

; Installation:

The easiest and preferred way to install recompile-on-save is to use
the package available on MELPA.

Manual installation:

Save recompile-on-save.el to a directory on your load-path (e.g.,
~/.emacs.d/elisp), then add the following to your .emacs file:

 (require 'recompile-on-save)


; Using recompile-on-save:

You should have at least one source buffer and one compilation
buffer. When you run M-x recompile-on-save in the source buffer it
will ask you for a compilation buffer which you want to associate
with it. After that, each save of the source buffer will trigger
recompilation in the associated compilation buffer.

To make this process even easier you might advice any compilation
function (e.g., compile) using recompile-on-save-advice.

(recompile-on-save-advice compile)

This way source <-> compilation buffer association will happen
automatically when you run M-x compile.

To (temporarily) disable automatic recompilation turn off
recompile-on-save-mode.

To reset compilation buffers associations for current source buffer
use M-x reset-recompile-on-save
