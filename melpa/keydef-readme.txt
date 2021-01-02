; The macro keydef provides a simplified interface to define-key that
; smoothly handles a number of common complications.

; The global-set-key command isn't ideal for novices because of its
; relatively complex syntax. And I always found it a little
; inconvenient to have to quote the name of the command---that is, I
; tend to forget the quote every once in a while and then have to go
; back and fix it after getting a load error.

; One of the best features is that you can give an Emacs lisp form (or
; even a series of forms) as the key definition argument, instead of a
; command name, and the keydef macro will automatically add an
; interactive lambda wrapper. I use this to get, for example, a more
; emphatic kill-buffer command (no confirmation query) by writing
;
;   (keydef "<S-f11>" (kill-buffer nil))
;
; For keydef the key sequence is expected to be given uniformly in the
; form of a string for the 'kbd' macro, with one or two refinements
; that are intended to conceal from users certain points of confusion,
; such as (for those whose keyboards lack a Meta key) the whole
; Meta/ESC/escape muddle.

; I have had some trouble in the past regarding the distinction
; between ESC and [escape] (in a certain combination of circumstances
; using the latter form caused definitions made with the other form to
; be masked---most puzzling when I wasn't expecting it). Therefore the
; ESC form is actually preprocessed a bit to ensure that the binding
; goes into esc-map.

; There is one other special feature of the key sequence syntax
; expected by the keydef macro: You can designate a key definition for
; a particular mode-map by giving the name of the mode together with
; the key sequence string in list form, for example
;
;   (keydef (latex "C-c %") comment-region)
;
; This means that the key will be defined in latex-mode-map. [The
; point of using this particular example will be made clear below.] I
; arranged for the mode name to be given in symbol form just because I
; didn't want to have to type extra quotes if I could get away with
; it. For the same reason this kind of first arg is not written in
; dotted pair form.

; If the given mode-map is not defined, keydef "does the right thing"
; using eval-after-load. In order to determine what library the
; mode-map will be loaded from, it uses the following algorithm:
;
; First check if foo-mode has autoload information. If not, check
; whether "foo-mode" is the name of a library that can be found
; somewhere in the load-path (using locate-library); otherwise check
; whether "foo" is the name of a locatable library. Failing that, give
; up and return nil.
;
; There is a fall-back mechanism, however, to handle exceptional
; cases. If foo-mode-map is undefined but the list mode-map-alist
; contains an entry of the form (foo-mode-map foo-other-name-map),
; then foo-other-name-map is used as the name of the
; keymap.
;
; If the mode-map is not loaded yet AND the command being bound to a
; key is undefined at the time of the keydef assignment, it presents
; further problems. The simplest solution is to assume that after the
; package is loaded that defines the mode-map, the given command will
; be defined and satisfy commandp. With some extra effort it should be
; possible to determine more accurately whether the command will be
; defined or not, but I'm not sure I want to go to that extreme, since
; as far as I can see it would require opening the package file and
; searching through it for a matching defun/defalias/fset statement.
;
; If the mode name matches the mode map name, but foo-mode is not
; autoloaded, then some autoload information may need to be provided.
; For example, the following line allows definitions to be made for
; debugger-mode-map even before debug.el is loaded.
;
;  (autoload 'debugger-mode "debug" "Autoloaded." 'interactive)
;
; Although there is no easy way provided by keydef for
; gnus-summary-limit-map to be accessed directly, because
; its name does not include "mode", you can get a binding into
; such a map by writing
;
;   (keydef (gnus-summary "/ z") gnus-summary-limit-to-zapped)
;
; which binds /z in gnus-summary-mode-map, which is equivalent to
; binding z in gnus-summary-limit-map.
;
; You might need to add an autoload statement for gnus-summary-mode
; in order for this to work, so that keydef knows that it should use
; eval-after-load and that the file the mode function will be loaded
; from is called "gnus-sum" rather than "gnus-summary-mode". (If it
; were the latter, keydef would be able to resolve everything
; automatically.)

; We COULD HAVE just put the definitions into the mode hook in the
; standard way, instead of using eval-after-load, but that would mean
; the key definitions get executed repetitiously every time the mode
; function gets called, which seems better to avoid, if only for
; esthetic reasons (if it can be done without too much trouble).

; The following examples show some typical keydef lines followed by the
; results of the macro expansion.

; Simplest kind of definition:
;
; (keydef "C-x m" gnus-group-mail)
;
;   -->(define-key global-map (kbd "C-x m") (quote gnus-group-mail))

; What if the command name is misspelled?
;
; (keydef "C-x m" gnus-gruop-mail)
;
;   -->(message "keydef: gnus-gruop-mail unknown \
;                \(perhaps misspelled, or not loaded yet\)")

; A leading ESC gets special handling to go through esc-map.
;
; (keydef "ESC &" query-replace-regexp)
;
;   -->(define-key esc-map (kbd "&") (quote query-replace-regexp))

; Undefine a key:
;
; (keydef "ESC `")
;
;   -->(define-key esc-map (kbd "`") nil)

; If the second arg is a string, keydef defines the given key sequence
; as a keyboard macro. The following macro puts in TeX-style double
; quotes and then moves the cursor backward to leave it in the middle:
;
; (keydef "\"" "``''\C-b\C-b")
;
;   -->(define-key global-map (kbd "\"") "``''\002\002")

; Reset a key to self-insert
;
; (keydef "\"" "\"")
;
;   -->(define-key global-map (kbd "\"") (quote self-insert-command))

; If the second arg is a list, wrap it in an interactive lambda form.
;
; (keydef "C-z"
;   (message "Control-Z key disabled---redefine it if desired."))
;
;   -->(define-key global-map
;       (kbd "C-z")
;       (lambda (arg)
;         "anonymous keydef function"
;         (interactive "p")
;         (message "Control-Z key disabled---redefine it if desired.")))
;
; Note that the interactive lambda wrapper added by keydef, when the
; CMD does not satisfy commandp, always takes a single prefix argument
; named "arg", which is read in the usual way with (interactive "p");
; so this could be used in the body of the function if need be.

; This shows the notation for F-keys.
;
; (keydef "<C-f17>" (kill-buffer nil))
;
;   -->(define-key global-map
;       (kbd "<C-f17>")
;       (lambda (arg)
;         "*Anonymous function created by keydef."
;         (interactive "p")
;         (kill-buffer nil)))

; Because of the confusing Meta/Escape complications, I recommend to
; the users that I support that they use the ESC notation
; consistently if that is what they type from their keyboard, even
; for F-key definitions that might normally be written with <M-...>
; notation.
;
; (keydef "ESC <f3>" find-file-read-only)
;
;   -->(define-key esc-map (kbd "<f3>") (quote find-file-read-only))

; The next two definitions go together. The second one shows how to
; write a mode-specific definition.
;
; (keydef "<f5>" isearch-forward)
;
;   -->(define-key global-map (kbd "<f5>") (quote isearch-forward))
;
; (keydef (isearch "<f5>") isearch-repeat-forward)
;
;   -->(define-key isearch-mode-map (kbd "<f5>")
;                                   (quote isearch-repeat-forward))

; Making a definition for a mode-map that is not loaded yet.
;
; (keydef (latex "C-c %") comment-region)
;
;   -->(eval-after-load "tex-mode"
;        (quote
;         (define-key latex-mode-map
;           (kbd "C-c %")
;           (quote comment-region))))
