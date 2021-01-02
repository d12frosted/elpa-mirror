; ----------------------------------------------------------------------
; Description:
;
; Provides the command shell-toggle which toggles between the
; shell buffer and whatever buffer you are editing.
;
; This is done in an "intelligent" way.  Features are:
; o Starts a shell if none is existent.
; o Minimum distortion of your window configuration.
; o When done in the shell-buffer you are returned to the same window
;   configuration you had before you toggled to the shell.
; o If you desire, you automagically get a "cd" command in the shell to the
;   directory where your current buffers file exists; just call
;   shell-toggle-cd instead of shell-toggle.
; o You can conveniently choose if you want to have the shell in another
;   window or in the whole frame.  Just invoke shell-toggle again to get the
;   shell in the whole frame.
;
; This file has been tested under Emacs 20.2.
;
; This file can be obtained from http://www.docs.uu.se/~mic/emacs.html

; ----------------------------------------------------------------------
; Installation:
;
; o Place this file in a directory in your 'load-path.
; o Put the following in your .emacs file:
;   (autoload 'shell-toggle "shell-toggle"
;    "Toggles between the shell buffer and whatever buffer you are editing."
;    t)
;   (autoload 'shell-toggle-cd "shell-toggle"
;    "Pops up a shell-buffer and insert a \"cd <file-dir>\" command." t)
;   (global-set-key [M-f1] 'shell-toggle)
;   (global-set-key [C-f1] 'shell-toggle-cd)
; o Restart your Emacs.  To use shell-toggle just hit M-f1 or C-f1
;
; For a list of user options look in code below.
;

; ----------------------------------------------------------------------
