This minor mode replaces keywords or expressions with SVG tags
that are fully customizable and activable.

Usage example:
--------------

(setq svg-tag-tags '((":TODO:"  ((svg-tag-make "TODO") nil nil))))

Each item has the form '(KEYWORD (TAG COMMAND HELP)) where:
 - KEYWORD is a regular expression including a matched group of
   the form "\\(xxx\\)". If this is not the case the whole
   string will be used a the matched group.
 - TAG is either a SVG image that will be displayed using the
   'display property or a function that accepts a unique string
   argument (match-string 1) and returns an SVG image.
 - COMMAND is a command to be executed when user clicks on the tag.
   It can be nil if no command is associated with the tag.
 - HELP is a string to be displayed when mouse pointer is over
   the tag. It can be nil if no command is associated with the tag.


Examples:
---------

;; This replaces any occurence of ":TODO:" with a static SVG tag
;; displaying "TODO"
(setq svg-tag-tags
      '((":TODO:" . ((svg-tag-make "TODO")))))

;; This replaces any occurence of ":HELLO:" with a static SVG tag that
;; can be clicked to execute the specified command. Help message is
;; displayed when the tag is hovered with the pointer.
(setq svg-tag-tags
      '((":HELLO:" .  ((svg-tag-make "HELLO")
                       (lambda () (interactive) (message "Hello world!"))
                       "Print a greeting message"))))

;; This replaces any occurence of ":TODO:" with a dynamic SVG tag
;; displaying ":TODO:"
(setq svg-tag-tags
      '((":TODO:" . (svg-tag-make))))

;; This replaces any occurence of ":TODO:" with a dynamic SVG tag
;; displaying "TODO"
(setq svg-tag-tags
      '((":TODO:" . ((lambda (tag)
                       (svg-tag-make tag :beg 1 :end -1))))))

;; This replaces any occurence of ":XXX:" with a dynamic SVG tag
;; displaying "XXX"
(setq svg-tag-tags
      '(("\\(:[A-Z]+:\\)" . ((lambda (tag)
                               (svg-tag-make tag :beg 1 :end -1))))))

;; This replaces any occurence of ":XXX|YYY:" with two adjacent
;; dynamic SVG tags displaying "XXX" and "YYY"
(setq svg-tag-tags
      '(("\\(:[A-Z]+\\)\|[a-zA-Z#0-9]+:" . ((lambda (tag)
                                           (svg-tag-make tag :beg 1 :inverse t
                                                          :margin 0 :crop-right t))))
        (":[A-Z]+\\(\|[a-zA-Z#0-9]+:\\)" . ((lambda (tag)
                                           (svg-tag-make tag :beg 1 :end -1
                                                         :margin 0 :crop-left t))))))

;; This replaces any occurence of ":#TAG1:#TAG2:…:$" ($ means end of
;; line) with a dynamic collection of SVG tags. Note the # symbol in
;; front of tags. This is mandatory because Emacs cannot do regex look
;; ahead.
(setq svg-tag-tags
      '(("\\(:#[A-Za-z0-9]+\\)" . ((lambda (tag)
                                     (svg-tag-make tag :beg 2))))
        ("\\(:#[A-Za-z0-9]+:\\)$" . ((lambda (tag)
                                       (svg-tag-make tag :beg 2 :end -1))))))
