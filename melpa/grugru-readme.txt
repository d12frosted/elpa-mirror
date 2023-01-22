Table of Contents
_________________

1. Grugru: Rotate text at point.
2. How to Use?
.. 1. Examples
3. Interactive Functions
.. 1. `grugru'
.. 2. `grugru-select'
.. 3. `grugru-edit'
4. Functions Defining grugru
.. 1. `(grugru-define-global GETTER STRINGS-OR-FUNCTION)'
.. 2. `(grugru-define-on-major-mode MAJOR GETTER STRINGS-OR-FUNCTION)'
.. 3. `(grugru-define-local GETTER STRINGS-OR-FUNCTION)'
.. 4. `(grugru-define-multiple &rest CLAUSES)'
.. 5. `(grugru-define-function NAME () &optional DOCSTRING &rest BODY)'
5. Utilities to define grugru
.. 1. `(grugru-utils-lisp-exchange-args LIST-STRING PERMUTATION)'
..... 1. Usage
6. Custom Variables
.. 1. `grugru-getter-alist'
.. 2. `grugru-edit-save-file'
.. 3. `grugru-completing-function'
.. 4. `grugru-select-function-generate-number'
.. 5. `grugru-local-interactively-default-getter'
.. 6. `grugru-point-after-rotate'
.. 7. `grugru-indent-after-rotate'
.. 8. `grugru-strings-metagenerator'
7. leaf-keyword `:grugru'
8. License


<https://raw.githubusercontent.com/ROCKTAKEY/images/4524403fbcdd9abe6d88197eddb1c4d241046e72/grugru.png>
[https://img.shields.io/github/tag/ROCKTAKEY/grugru.svg?style=flat-square]
[https://img.shields.io/github/license/ROCKTAKEY/grugru.svg?style=flat-square]
[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/grugru/CI.yml.svg?style=flat-square]
[https://img.shields.io/codecov/c/github/ROCKTAKEY/grugru/master.svg?style=flat-square]
[file:https://melpa.org/packages/grugru-badge.svg]


[https://img.shields.io/github/tag/ROCKTAKEY/grugru.svg?style=flat-square]
<https://github.com/ROCKTAKEY/grugru>

[https://img.shields.io/github/license/ROCKTAKEY/grugru.svg?style=flat-square]
<file:LICENSE>

[https://img.shields.io/github/actions/workflow/status/ROCKTAKEY/grugru/CI.yml.svg?style=flat-square]
<https://github.com/ROCKTAKEY/grugru/actions>

[https://img.shields.io/codecov/c/github/ROCKTAKEY/grugru/master.svg?style=flat-square]
<https://codecov.io/gh/ROCKTAKEY/grugru?branch=master>

[file:https://melpa.org/packages/grugru-badge.svg]
<https://melpa.org/#/grugru>


1 Grugru: Rotate text at point.
===============================

  With this package, you can rotate things at point.

  <https://raw.githubusercontent.com/ROCKTAKEY/images/7baf9507a8fb9c20eda7395be1c9d91d0ae61c51/emacs-lisp-mode.gif>
                     Fig.  1 demo on `emacs-lisp-mode'

  <https://raw.githubusercontent.com/ROCKTAKEY/images/35e323db33f4da1545c289f2741782c4ac04968b/c++-mode.gif>
                        Fig.  2 demo on `c++-mode'

  <https://raw.githubusercontent.com/ROCKTAKEY/images/698f33489645a6e7b0c29d879771dbb15fa3fcd9/grugru-define-local.gif>
              Fig.  3 Use `grugru-define-local' interactively


2 How to Use?
=============

  You can interactively use the function `grugru'.  This function rotate
  the thing at point if assigned.  You can assign rotated things with
  `grugru-define-on-major-mode', `grugru-define-on-local-major-mode',
  and `grugru-define-local'.  If you use `grugru', you should assign
  `grugru' to 1 stroke key like `C-;', or `M-g'.
  ,----
  | (global-set-key (kbd "C-;") #'grugru)   ; Or other key.
  `----

  If you want use default grugru, eval `grugru-default-setup'.  In the
  other words, add to your init.el:
  ,----
  | (grugru-default-setup)
  `----

  If you want `grugru' to highlight gurgruable thing, add to your
  init.el:
  ,----
  | (grugru-highlight-mode)
  `----

  If you want to change default action at point, you can use
  `grugru-edit', with which you can edit grugrus at point
  interactively.  The change edited by this function is saved in
  `grugru-edit-save-file', and loaded by run `grugru-edit-load'.  So to
  load the change, you can write on init.el after
  `(grugru-default-setup)':
  ,----
  | (grugru-edit-load)
  `----

  If you want to use ivy or ido as completing-read, set
  `grugru-edit-completing-function'.  Or, you can use
  `grugru-redefine-\*' or `grugru-remove-\*' for non-interactive editing
  of default setup.


2.1 Examples
~~~~~~~~~~~~

  ,----
  |   1  ;; Define grugru on major-mode.
  |   2  (grugru-define-on-major-mode 'c-mode 'symbol '("unsigned" "signed"))
  |   3  (grugru-define-on-major-mode 'c-mode 'word '("get" "set"))
  |   4  ;; Now, you can toggle unsigned <=> signed and get <=> set
  |   5  ;; by running the command grugru in c-mode.
  |   6
  |   7  ;; You can pass a list of symbol major-mode instead of one.
  |   8  (grugru-define-on-major-mode '(java-mode c++-mode) 'word '("get" "set"))
  |   9
  |  10  ;; Define grugru on current major-mode.
  |  11  ;; Same as (grugru-define-on-major-mode major-mode 'symbol '("red" "green" "yellow"))
  |  12  ;; This should be run in some hook or function,
  |  13  ;; because major-mode is not confirmed if in init.el.
  |  14  (add-hook 'c-mode-common-hook
  |  15   (lambda ()
  |  16    (grugru-define-on-local-major-mode 'symbol '("red" "green" "yellow"))))
  |  17
  |  18  ;; Define grugru on local.  Should be defined in some hook or function,
  |  19  ;; because it is saved buffer local.
  |  20  (add-hook 'text-mode-hook
  |  21            (lambda ()
  |  22             (grugru-define-local 'word '("is" "was"))
  |  23             (grugru-define-local 'word '("I" "my" "me" "mine"))))
  |  24
  |  25  ;; Define grugru globally.  This is applied in all buffers.
  |  26  (grugru-define-global 'symbol '("yes" "no"))
  |  27
  |  28  ;; Define grugru keeping case:
  |  29  (grugru-define-global 'symbol (grugru-metagenerator-keep-case '("yes" "no")))
  |  30
  |  31  ;; If you want grugru to define grugru defaultly keeping case:
  |  32  (customize-set-variable 'grugru-strings-metagenerator #'grugru-metagenerator-simple)
  |  33
  |  34  ;; You can use function instead of list of strings.
  |  35  (grugru-define-on-major-mode
  |  36   'c-mode 'symbol
  |  37   ;; Optional argument `rev' is flag for backward rotation.
  |  38   ;; If the second argument `rev' is ignoreable (for example, rotate two strings),
  |  39   ;; you can just use the function receiving only 1 argument.
  |  40   (lambda (arg &optional rev)
  |  41     (if rev
  |  42         ;; backward
  |  43         (cond
  |  44          ((string-match "a\\(.*\\)b" arg)
  |  45           ;; Rotate axyzb to cxyzd
  |  46           (concat "c" (match-string 1 arg) "d"))
  |  47          ((string-match "b\\(.*\\)c" arg)
  |  48           ;; Rotate bxyzc to axyzb
  |  49           (concat "a" (match-string 1 arg) "b"))
  |  50          ((string-match "c\\(.*\\)d" arg)
  |  51           ;; Rotate cxyzd to bxyzc
  |  52           (concat "b" (match-string 1 arg) "c")))
  |  53       ;; forward
  |  54       (cond
  |  55        ((string-match "a\\(.*\\)b" arg)
  |  56         ;; Rotate axyzb to bxyzc
  |  57         (concat "b" (match-string 1 arg) "c"))
  |  58        ((string-match "b\\(.*\\)c" arg)
  |  59         ;; Rotate bxyzc to cxyzd
  |  60         (concat "c" (match-string 1 arg) "d"))
  |  61        ((string-match "c\\(.*\\)d" arg)
  |  62         ;; Rotate cxyzd to axyzb
  |  63         (concat "a" (match-string 1 arg) "b"))))))
  |  64
  |  65  ;; You can indicate which position is valid to grugru in strings.
  |  66  ;; The function can return not only string but also cons cell (BOUNDS . STRING).
  |  67  ;; BOUNDS is a list of cons cell (BEG . END), which is pair of numbers indicating
  |  68  ;; range valid to rotate.
  |  69  (defun grugru-default@emacs-lisp+nth!aref (str)
  |  70    "Return STR exchanged `nth' and `aref' with argument permutation."
  |  71    (cond
  |  72     ((string-match "^(\\_<\\(nth\\)\\_>" str)
  |  73      (cons
  |  74       (cons (match-beginning 1) (match-end 1))
  |  75       ;; This function permutate arguments on Lisp.
  |  76       (grugru-utils-lisp-exchange-args
  |  77       (replace-match "aref" nil nil str 1)
  |  78       '(2 1))))
  |  79     ((string-match "^(\\_<\\(aref\\)\\_>" str)
  |  80      (cons
  |  81       (cons (match-beginning 1) (match-end 1))
  |  82       (grugru-utils-lisp-exchange-args
  |  83       (replace-match "nth" nil nil str 1)
  |  84       '(2 1))))))
  |  85
  |  86  ;; You can also write like:
  |  87  (grugru-define-multiple
  |  88   (fundamental-mode
  |  89    . ((word . ("aaa" "bbb" "ccc"))
  |  90       ;; (symbol "xxx" "yyy" "zzz") is same as below.
  |  91       ;; You can use both.
  |  92       (symbol . ("xxx" "yyy" "zzz"))
  |  93       (word . ("abc" "def" "ghi"))))
  |  94    (word . ("aaaa" "bbbb" "cccc"))
  |  95    (symbol . ("xxxx" "yyyyy" "zzzzz"))
  |  96    (word . ("abcd" "defd" "ghid")))
  |  97  ;; or
  |  98  (grugru-define-multiple
  |  99   (fundamental-mode
  | 100     (word "aaa" "bbb" "ccc")
  | 101     (symbol "xxx" "yyy" "zzz")
  | 102     (word "abc" "def" "ghi"))
  | 103    (word "aaaa" "bbbb" "cccc")
  | 104    (symbol "xxxx" "yyyyy" "zzzzz")
  | 105    (word "abcd" "defd" "ghid"))
  | 106
  | 107  ;; Above two examples are both expanded to:
  | 108  (progn
  | 109    (progn
  | 110       (grugru-define-on-major-mode 'fundamental-mode 'word '("aaa" "bbb" "ccc"))
  | 111       (grugru-define-on-major-mode 'fundamental-mode 'symbol '("xxx" "yyy" "zzz"))
  | 112       (grugru-define-on-major-mode 'fundamental-mode 'word '("abc" "def" "ghi")))
  | 113     (grugru-define-global 'word '("aaaa" "bbbb" "cccc"))
  | 114     (grugru-define-global 'symbol '("xxxx" "yyyyy" "zzzzz"))
  | 115     (grugru-define-global 'word '("abcd" "defd" "ghid")))
  | 116
  | 117
  | 118  ;; You can define function which rotate pre-specified texts.
  | 119  ;; For example, three-state can rotate only 2 tuples,
  | 120  ;; ("water" "ice" "vapor") and ("solid" "liquid" "gas"),
  | 121  ;; not any other tuples defined by grugru-define-global and so on.
  | 122  (grugru-define-function three-state ()
  | 123   "Docstring.  This is optional."
  | 124   (symbol . ("water" "ice" "vapor"))
  | 125   (symbol . ("solid" "liquid" "gas")))
  | 126  ;; If you want to find the functions defined by `grugru-define-function'
  | 127  ;; with `describe-function', execute this:
  | 128  (grugru-find-function-integration-mode +1)
  `----


3 Interactive Functions
=======================

3.1 `grugru'
~~~~~~~~~~~~

  This function rotates text at point.  Rotated text is defined by
  `grugru-define-*' functions.  If prefix argument is passed, repeatedly
  executed.  Negative prefix arguments means backward rotation.  Also,
  `grugru-backward' can be used for backward rotation.


3.2 `grugru-select'
~~~~~~~~~~~~~~~~~~~

  This function replace text at point.  You can select grugru and string
  replaced to.

  You can assign completing function to `grugru-completing-function'.


3.3 `grugru-edit'
~~~~~~~~~~~~~~~~~

  This function edits grugru at point defined by default.

  First, select grugru from grugrus available at point.  Then, edit the
  list in minibuffer.

  The change is saved to file `grugru-edit-save-file' if it is not
  `local' one.  You can assign completing function to
  `grugru-completing-function'.


4 Functions Defining grugru
===========================

4.1 `(grugru-define-global GETTER STRINGS-OR-FUNCTION)'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Define global grugru with GETTER and STRINGS-OR-FUNCTION.

  GETTER is a function, or a symbol which is alias defined in
  `grugru-getter-alist'.  GETTER also can be positive or negative
  number, which means the number of characters after point.  By default,
  symbol, word, char is available.  If it is a function, it should
  return cons cell `(begin . end)' which express things at point, and
  with no argument.

  STRINGS-OR-FUNCTION is list of string or function.

  List of string: If it includes string gotten by GETTER, the things
  gotten by GETTER is replaced to next string.

  Function: It is passed things gotten by GETTER, and should return
  string to replace the things to.

  You can use like:
  ,----
  | ;; Replace "yes" at point, to "no".
  | ;; Or replace "no" at point, to "yes".
  | (grugru-define-global 'symbol '("yes" "no"))
  `----


4.2 `(grugru-define-on-major-mode MAJOR GETTER STRINGS-OR-FUNCTION)'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Define major-mode local grugru with GETTER and STRINGS-OR-FUNCTION.

  Same as `grugru-define-global', but grugru defined with this is
  applied only in buffer on MAJOR major-mode.  MAJOR can be list of
  major-modes.
  ,----
  | ;; Replace "yes" at point, to "no", or replace "no" at point, to "yes",
  | ;; only in lisp-interaction-mode.
  | (grugru-define-on-major-mode lisp-interaction-mode 'symbol '("yes" "no"))
  `----


4.3 `(grugru-define-local GETTER STRINGS-OR-FUNCTION)'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Define buffer-local grugru with GETTER and STRINGS-OR-FUNCTION.

  Same as `grugru-define-global', but grugru defined with this is
  applied only in buffer where eval this expression.
  ,----
  | ;; This should be used in hook or others.
  | ;; Because this definition is buffer-local.
  | (add-hook 'text-mode-hook
  |            (lambda ()
  |             (grugru-define-local 'word '("is" "was"))
  |             (grugru-define-local 'word '("I" "my" "me" "mine"))))
  `----

  Also, you can run it interactively (though cannot set
  STRINGS-OR-FUNCTION to a function).  On interactive usage, by default,
  GETTER is the length of car of STRINGS-OR-FUNCTION, and
  STRINGS-OR-FUNCTION is a list which has 2 elements, constructed
  interactively.  With prefix argument, you can select GETTER and length
  of STRINGS-OR-FUNCTION.  Default GETTER is set by
  `grugru-local-interactively-default-getter'.


4.4 `(grugru-define-multiple &rest CLAUSES)'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This function define multiple grugru.

  Each `CLAUSE' is:
  - `(GETTER . STRINGS-OR-FUNCTION)': means `(grugru-define-global
    GETTER STRINGS-OR-FUNCTION)'.
  - `(MAJOR (GETTER . STRINGS-OR-FUNCTION)...)': means
    `(grugru-define-on-major-mode MAJOR GETTER STRINGS-OR-FUNCTION)...'.
  - List of above.

  ,----
  | (grugru-define-multiple
  |  (fundamental-mode
  |   . ((word . ("aaa" "bbb" "ccc"))
  |      ;; (symbol "xxx" "yyy" "zzz") is same as below.
  |      ;; You can use both.
  |      (symbol . ("xxx" "yyy" "zzz"))
  |      (word . ("abc" "def" "ghi"))))
  |   (word . ("aaaa" "bbbb" "cccc"))
  |   (symbol . ("xxxx" "yyyyy" "zzzzz"))
  |   (word . ("abcd" "defd" "ghid")))
  | ;; or
  | (grugru-define-multiple
  |  (fundamental-mode
  |    (word "aaa" "bbb" "ccc")
  |    (symbol "xxx" "yyy" "zzz")
  |    (word "abc" "def" "ghi"))
  |   (word "aaaa" "bbbb" "cccc")
  |   (symbol "xxxx" "yyyyy" "zzzzz")
  |   (word "abcd" "defd" "ghid"))
  |
  | ;; Above two examples are both expanded to:
  | (progn
  |   (progn
  |      (grugru-define-on-major-mode 'fundamental-mode 'word '("aaa" "bbb" "ccc"))
  |      (grugru-define-on-major-mode 'fundamental-mode 'symbol '("xxx" "yyy" "zzz"))
  |      (grugru-define-on-major-mode 'fundamental-mode 'word '("abc" "def" "ghi")))
  |    (grugru-define-global 'word '("aaaa" "bbbb" "cccc"))
  |    (grugru-define-global 'symbol '("xxxx" "yyyyy" "zzzzz"))
  |    (grugru-define-global 'word '("abcd" "defd" "ghid")))
  `----


4.5 `(grugru-define-function NAME () &optional DOCSTRING &rest BODY)'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Define function which can roate only grugru defined by BODY.  Each
  element of BODY is `(GETTER . STRINGS-OR-FUNCTION)', which meaning is
  same as `grugru-define-*' functions.
  ,----
  | ;; The function `three-state' rotate like "water"=>"ice"=>"vapor"=>"water",
  | ;; or "solid"=>"liquid"=>"gas"=>"solid".
  | (grugru-define-function three-state ()
  |  "Docstring.  This is optional."
  |  (symbol . ("water" "ice" "vapor"))
  |  (symbol . ("solid" "liquid" "gas")))
  |
  | ;; This sentense do NOT affect to the function `three-state'.
  | (grugru-define-global 'symbol '("yes" "no"))
  `----


5 Utilities to define grugru
============================

5.1 `(grugru-utils-lisp-exchange-args LIST-STRING PERMUTATION)'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Permute argument of sexp read from `LIST-STRING' according to
  `PERMUTATION'.

  For example, `(grugru-utils-lisp-exchange-args \"(nth 1 '(x y z))\"
  '(2 1))' returns `(nth '(x y z) 1)'.  Newlines and whitespaces are
  also kept.

  This function is defined for user to define the function for grugru
  which rotate not only fuction's name but also arguments' order.


5.1.1 Usage
-----------

  ,----
  | (defun grugru-rotate-nth-aref (str)
  |   (cond
  |    ((string-match "^(\\(\\_<nth\\_>\\)" str) ;match to "(nth"
  |     (grugru-utils-lisp-exchange-args
  |      (replace-match "aref" nil nil str 1) ;replace function's name to "aref"
  |      '(2 1)))                             ;exchange arguments' order
  |    ((string-match "^(\\(\\_<aref\\_>\\)" str) ;match to "(aref"
  |     (grugru-utils-lisp-exchange-args
  |      (replace-match "nth" nil nil str 1) ;replace function's name to "nth"
  |      '(2 1)))))                          ;exchange arguments' order
  | (grugru-define-on-major-mode
  |  'emacs-lisp-mode
  |  'list
  |  #'grugru-rotate-nth-aref)
  |
  | ;; Then,
  | (nth 3 '(foo bar))
  | ;; is rotated to:
  | (aref '(foo bar) 3)
  `----


6 Custom Variables
==================

6.1 `grugru-getter-alist'
~~~~~~~~~~~~~~~~~~~~~~~~~

  Alist of getter.

  Each key (car) of element is a symbol, which is regarded as `GETTER'.

  Each value (cdr) of element is a function or sexp.  It should return
  things at point.


6.2 `grugru-edit-save-file'
~~~~~~~~~~~~~~~~~~~~~~~~~~~

  The name of file saved the information by `grugru-edit'.  Default
  value is "~/.emacs.d/.grugru".


6.3 `grugru-completing-function'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Completing function. Default value is `completing-read'.  If you would
  like to use ivy or ido, write:
  ,----
  | ;; For ivy:
  | (setq grugru-completing-function #'ivy-completing-read)
  | ;; For ido:
  | (setq grugru-completing-function #'ido-completing-read)
  `----


6.4 `grugru-select-function-generate-number'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This variable have how many strings are generated from function in
  `STRINGS-OR-FUNCTION', on `grugru-select'.


6.5 `grugru-local-interactively-default-getter'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Indicate default getter on interactive usage of `grugru-define-local'.
  0 means If 0, gets number from first string, otherwise it should be
  symbol in `grugru-getter-alist' or a function which gets things at
  point.


6.6 `grugru-point-after-rotate'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Where the point is after rotation by `grugru'.
  - `as-is' means keeping first position.
  - `beginning' means beginning of rotated things.
  - `end' means end of rotated things.


6.7 `grugru-indent-after-rotate'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Indent rotated text after `grugru' or not.  Indent happens only if
  text after rotation has a newline.
  ,----
  | (grugru-define-local 'list '("(abc def)" "(ghi\njkl)"))
  | ;; If `grugru-indent-after-rotate' is nil,
  | (abc def)
  | ;; is rotated to:
  | (ghi
  | jkl)
  |
  | ;; If `grugru-indent-after-rotate' is t,
  | (abc def)
  | ;; is rotated to:
  | (ghi
  |  jkl)
  `----


6.8 `grugru-strings-metagenerator'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Function which generates default generator from strings on
  `grugru-define-*'.  The function should recieve `STRINGS', list of
  string, as one argument, and return function.  Returned function
  should recieve one or two argument(s), string `STRING' as first one,
  boolean `REVERSE' as second one.

  STRING means current string.  Returned function (generator) returns
  string next to STRING.  If REVERSE is non-nil, it returns previous one
  instead.


7 leaf-keyword `:grugru'
========================

  You can use `:grugru' keyword on [leaf.el], if you use
  [leaf-keywords.el].

  By default, `leaf--name' is used as major-mode.  Or you can write
  major-mode obviously.
  ,----
  | (leaf lisp-mode
  |  :grugru
  |  (symbol "nil" "t")
  |  (emacs-lisp-mode
  |   (word "add" "remove"))
  |  ...)
  | ;; The section of `:grugru' means:
  | (grugru-define-multiple
  |  (lisp-mode
  |   (symbol "nil" "t"))
  |  (emacs-lisp-mode
  |   (word "add" "remove")))
  `----


[leaf.el] <https://github.com/conao3/leaf.el>

[leaf-keywords.el] <https://github.com/conao3/leaf-keywords.el>


8 License
=========

  This package is licensed by GPLv3. See [LICENSE].


[LICENSE] <file:LICENSE>
