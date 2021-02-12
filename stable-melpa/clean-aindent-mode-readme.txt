=== Description of the features
1. Extension of 'newline-and-indent' that keeps track of the last
auto-indent operation and, if it is abandoned, would take care to
trim down the unused white space characters.

2. Simple indent, if activated, where cursor is aligned with
indent of the lines above.

3. Backspace Unindent. Extension of M-backspace.
When cursor is in the indentation space of a line, or at the first
character and you press M-backspace it will move the entire line to
be aligned to the line above or any other that is with indentation
smaller than the current.

Detailed documentation with example situations and screenshots:
http://www.emacswiki.org/emacs/CleanAutoIndent

=== To activate
'M-x clean-aindent-mode'
or
add this to your init.el:
(clean-aindent-mode t)

By default auto-indent is bound to 'C-j'. Bind it to 'RET' for most
convenient use of the features. Add this to your init.el:
(define-key global-map (kbd "RET") 'newline-and-indent)

In case you installed the extension via MELPA, use this suggested configiration:

 (defun my-pkg-init()
   (electric-indent-mode -1)  ; no electric indent, auto-indent is sufficient
   (clean-aindent-mode t)
   (setq clean-aindent-is-simple-indent t)
   (define-key global-map (kbd "RET") 'newline-and-indent))
 (add-hook 'after-init-hook 'my-pkg-init)

=== Options
M-x customize, search for 'auto indent', toggle to on,
then 'Apply and Save'.
or
add this to your init.el:
(set 'clean-aindent-is-simple-indent t)
