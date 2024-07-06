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
