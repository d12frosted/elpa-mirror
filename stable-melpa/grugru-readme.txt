; How to Use?
  You can interactively use the function `grugru'.  This function rotate the thing at point
  if assigned.  You can assign rotated things with
  `grugru-define-on-major-mode', `grugru-define-on-local-major-mode', and `grugru-define-local'.
  If you use ~grugru~, you should assign ~grugru~ to 1 stroke key like ~C-;~, or ~M-g~.

    (global-set-key (kbd "C-;") #'grugru)   ; Or other key.


  If you want use default grugru, eval ~grugru-default-setup~.  In the other words,
  add to your init.el:

  (grugru-default-setup)

  If you want to change default action at point, you can use ~grugru-edit~,
  with which you can edit grugrus at point interactively.  The change edited by this
  function is saved in ~grugru-edit-save-file~,
  and loaded by run ~grugru-edit-load~.  So to load the change, you can write
  on init.el after ~(grugru-default-setup)~:

  (grugru-edit-load)


  If you want to use ivy or ido as completing-read, set ~grugru-edit-completing-function~.
  Or, you can use ~grugru-redefine-\*~ or ~grugru-remove-\*~
  for non-interactive editing of default setup.
;; Examples

    ;; Define grugru on major-mode.
    (grugru-define-on-major-mode 'c-mode 'symbol '("unsigned" "signed"))
    (grugru-define-on-major-mode 'c-mode 'word '("get" "set"))
    ;; Now, you can toggle unsigned <=> signed and get <=> set
    ;; by running the command grugru in c-mode.

    ;; You can pass a list of symbol major-mode instead of one.
    (grugru-define-on-major-mode '(java-mode c++-mode) 'word '("get" "set"))

    ;; Define grugru on current major-mode.
    ;; Same as (grugru-define-on-major-mode major-mode 'symbol '("red" "green" "yellow"))
    ;; This should be run in some hook or function,
    ;; because major-mode is not confirmed if in init.el.
    (add-hook 'c-mode-common-hook
     (lambda ()
      (grugru-define-on-local-major-mode 'symbol '("red" "green" "yellow"))))

    ;; Define grugru on local.  Should be defined in some hook or function,
    ;; because it is saved buffer local.
    (add-hook 'text-mode-hook
              (lambda ()
               (grugru-define-local 'word '("is" "was"))
               (grugru-define-local 'word '("I" "my" "me" "mine"))))

    ;; Define grugru globally.  This is applied in all buffers.
    (grugru-define-global 'symbol '("yes" "no"))

    ;; You can use function instead of list of strings.
    (grugru-define-on-major-mode
     'c-mode 'symbol
     (lambda (arg)
      (cond
       ((string-match "a\\(.*\\)b" arg)
        (concat "b" (match-string 1 arg) "c"))
       ((string-match "b\\(.*\\)c" arg)
        (concat "a" (match-string 1 arg) "b")))))

    ;; You can also write like:
    (grugru-define-multiple
     (fundamental-mode
      . ((word . ("aaa" "bbb" "ccc"))
         ;; (symbol "xxx" "yyy" "zzz") is same as below.
         ;; You can use both.
         (symbol . ("xxx" "yyy" "zzz"))
         (word . ("abc" "def" "ghi"))))
      (word . ("aaaa" "bbbb" "cccc"))
      (symbol . ("xxxx" "yyyyy" "zzzzz"))
      (word . ("abcd" "defd" "ghid")))
    ;; or
    (grugru-define-multiple
     (fundamental-mode
       (word "aaa" "bbb" "ccc")
       (symbol "xxx" "yyy" "zzz")
       (word "abc" "def" "ghi"))
      (word "aaaa" "bbbb" "cccc")
      (symbol "xxxx" "yyyyy" "zzzzz")
      (word "abcd" "defd" "ghid"))

    ;; Above two examples are both expanded to:
    (progn
      (progn
         (grugru-define-on-major-mode 'fundamental-mode 'word '("aaa" "bbb" "ccc"))
         (grugru-define-on-major-mode 'fundamental-mode 'symbol '("xxx" "yyy" "zzz"))
         (grugru-define-on-major-mode 'fundamental-mode 'word '("abc" "def" "ghi")))
       (grugru-define-global 'word '("aaaa" "bbbb" "cccc"))
       (grugru-define-global 'symbol '("xxxx" "yyyyy" "zzzzz"))
       (grugru-define-global 'word '("abcd" "defd" "ghid")))


    ;; You can define function which rotate pre-specified texts.
    ;; For example, three-state can rotate only 2 tuples,
    ;; ("water" "ice" "vapor") and ("solid" "liquid" "gas"),
    ;; not any other tuples defined by grugru-define-global and so on.
    (grugru-define-function three-state ()
     "Docstring.  This is optional."
     (symbol . ("water" "ice" "vapor"))
     (symbol . ("solid" "liquid" "gas")))
    ;; If you want to find the functions defined by `grugru-define-function'
    ;; with `describe-function', execute this:
    (grugru-find-function-integration-mode +1)

; Interactive Functions
;; ~grugru~
   This function rotates text at point.
   Rotated text is defined by ~grugru-define-*~ functions.
   If prefix argument is passed, repeatedly executed.  Negative prefix arguments means
   backward rotation.  Also, ~grugru-backward~ can be used for backward rotation.
;; ~grugru-select~
   This function replace text at point.
   You can select grugru and string replaced to.

   You can assign completing function to ~grugru-completing-function~.
;; ~grugru-edit~
   This function edits grugru at point defined by default.

   First, select grugru from grugrus available at point.
   Then, edit the list in minibuffer.

   The change is saved to file ~grugru-edit-save-file~.
   You can assign completing function to ~grugru-completing-function~.
; Functions Defining grugru
;; ~(grugru-define-global GETTER STRINGS-OR-FUNCTION)~
   Define global grugru with GETTER and STRINGS-OR-FUNCTION.

   GETTER is a function, or a symbol which is alias defined in ~grugru-getter-alist~.
   GETTER also can be positive or negative number, which means the number of characters.
   By default, symbol, word, char is available.
   If it is a function, it should return cons cell ~(begin . end)~
   which express things at point, and with no argument.

   STRINGS-OR-FUNCTION is list of string or function.

   List of string: If it includes string gotten by GETTER,
   the things gotten by GETTER is replaced to next string.

   Function: It is passed things gotten by GETTER, and should return string
   to replace the things to.

   You can use like:

     ;; Replace "yes" at point, to "no".
     ;; Or replace "no" at point, to "yes".
     (grugru-define-global 'symbol '("yes" "no"))

;; ~(grugru-define-on-major-mode MAJOR GETTER STRINGS-OR-FUNCTION)~
   Define major-mode local grugru with GETTER and STRINGS-OR-FUNCTION.

   Same as ~grugru-define-global~, but grugru defined with this is applied
   only in buffer on MAJOR major-mode.  MAJOR can be list of major-modes.

     ;; Replace "yes" at point, to "no", or replace "no" at point, to "yes",
     ;; only in lisp-interaction-mode.
     (grugru-define-on-major-mode lisp-interaction-mode 'symbol '("yes" "no"))

;; ~(grugru-define-local GETTER STRINGS-OR-FUNCTION)~
   Define buffer-local grugru with GETTER and STRINGS-OR-FUNCTION.

   Same as ~grugru-define-global~, but grugru defined with this is applied
   only in buffer where eval this expression.

     ;; This should be used in hook or others.
     ;; Because this definition is buffer-local.
     (add-hook 'text-mode-hook
                (lambda ()
                 (grugru-define-local 'word '("is" "was"))
                 (grugru-define-local 'word '("I" "my" "me" "mine"))))


   Also, you can run it interactively (though cannot set STRINGS-OR-FUNCTION to a function).
   On interactive usage, by default, GETTER is the length of car of STRINGS-OR-FUNCTION,
   and STRINGS-OR-FUNCTION is a list which has 2 elements, constructed interactively.
   With prefix argument, you can select GETTER and length of STRINGS-OR-FUNCTION.
   Default GETTER is set by ~grugru-local-interactively-default-getter~.

;; ~(grugru-define-multiple &rest CLAUSES)~
   This function define multiple grugru.

   Each ~CLAUSE~ is:
   - ~(GETTER . STRINGS-OR-FUNCTION)~: means ~(grugru-define-global GETTER  STRINGS-OR-FUNCTION)~.
   - ~(MAJOR (GETTER . STRINGS-OR-FUNCTION)...)~: means ~(grugru-define-on-major-mode MAJOR GETTER  STRINGS-OR-FUNCTION)...~.
   - List of above.


    (grugru-define-multiple
     (fundamental-mode
      . ((word . ("aaa" "bbb" "ccc"))
         ;; (symbol "xxx" "yyy" "zzz") is same as below.
         ;; You can use both.
         (symbol . ("xxx" "yyy" "zzz"))
         (word . ("abc" "def" "ghi"))))
      (word . ("aaaa" "bbbb" "cccc"))
      (symbol . ("xxxx" "yyyyy" "zzzzz"))
      (word . ("abcd" "defd" "ghid")))
    ;; or
    (grugru-define-multiple
     (fundamental-mode
       (word "aaa" "bbb" "ccc")
       (symbol "xxx" "yyy" "zzz")
       (word "abc" "def" "ghi"))
      (word "aaaa" "bbbb" "cccc")
      (symbol "xxxx" "yyyyy" "zzzzz")
      (word "abcd" "defd" "ghid"))

    ;; Above two examples are both expanded to:
    (progn
      (progn
         (grugru-define-on-major-mode 'fundamental-mode 'word '("aaa" "bbb" "ccc"))
         (grugru-define-on-major-mode 'fundamental-mode 'symbol '("xxx" "yyy" "zzz"))
         (grugru-define-on-major-mode 'fundamental-mode 'word '("abc" "def" "ghi")))
       (grugru-define-global 'word '("aaaa" "bbbb" "cccc"))
       (grugru-define-global 'symbol '("xxxx" "yyyyy" "zzzzz"))
       (grugru-define-global 'word '("abcd" "defd" "ghid")))

;; ~(grugru-define-function NAME () &optional DOCSTRING &rest BODY)~
   Define function which can roate only grugru defined by BODY.
   Each element of BODY is ~(GETTER . STRINGS-OR-FUNCTION)~,
   which meaning is same as ~grugru-define-*~ functions.

     ;; The function `three-state' rotate like "water"=>"ice"=>"vapor"=>"water",
     ;; or "solid"=>"liquid"=>"gas"=>"solid".
     (grugru-define-function three-state ()
      "Docstring.  This is optional."
      (symbol . ("water" "ice" "vapor"))
      (symbol . ("solid" "liquid" "gas")))

     ;; This sentense do NOT affect to the function `three-state'.
     (grugru-define-global 'symbol '("yes" "no"))

; leaf-keyword ~:grugru~
  You can use ~:grugru~ keyword on [[https://github.com/conao3/leaf.el][leaf.el]], if you use [[https://github.com/conao3/leaf-keywords.el][leaf-keywords.el]].

  By default, ~leaf--name~ is used as major-mode.
  Or you can write major-mode obviously.

    (leaf lisp-mode
     :grugru
     (symbol "nil" "t")
     (emacs-lisp-mode
      (word "add" "remove"))
     ...)
    ;; The section of `:grugru' means:
    (grugru-define-multiple
     (symbol "nil" "t")
     (emacs-lisp-mode
      (word "add" "remove")))

; Custom Variables
;; ~grugru-getter-alist~
   Alist of getter.

   Each key (car) of element is a symbol, which is regarded as ~GETTER~.

   Each value (cdr) of element is a function or sexp.
   It should return things at point.

;; ~grugru-edit-save-file~
   The name of file saved the information by ~grugru-edit~.
   Default value is "~/.emacs.d/.grugru".

;; ~grugru-completing-function~
   Completing function.  Default value is ~completing-read~.
   If you would like to use ivy or ido, write:

     ;; For ivy:
     (setq grugru-completing-function #'ivy-completing-read)
     ;; For ido:
     (setq grugru-completing-function #'ido-completing-read)


;; ~grugru-select-function-generate-number~
   This variable have how many strings are generated from function
   in ~STRINGS-OR-FUNCTION~, on ~grugru-select~.

;; ~grugru-local-interactively-default-getter~
   Indicate default getter on interactive usage of ~grugru-define-local~.
   0 means If 0, gets number from first string, otherwise it should be
   symbol in ~grugru-getter-alist~ or a function which gets things at point.
; License
  This package is licensed by GPLv3. See [[file:LICENSE][LICENSE]].
