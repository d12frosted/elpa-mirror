;;; xah-elisp-mode.el --- Major mode for editing emacs lisp. -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2013-2021, by Xah Lee

;; Author: Xah Lee ( http://xahlee.info/ )
;; Version: 3.10.20210208125542
;; Package-Version: 20210208.2056
;; Package-Commit: 3ae341944297d59bf33f5580364af2858198781e
;; Created: 23 Mar 2013
;; Package-Requires: ((emacs "24.3"))
;; Keywords: lisp, languages
;; License: GPL v3
;; Homepage: http://ergoemacs.org/emacs/xah-elisp-mode.html

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Major mode for editing emacs lisp code.
;; This is alternative to GNU Emacs emacs-lisp-mode.

;; Major features different from emacs-lisp-mode:

;; • Syntax coloring of ALL elisp symbols documented in elisp manual, and ONLY those. If a symbol is not colored, it's either a typo or not documented in elisp manual.

;; • Symbols are colored by their technical type: function, special form, macro, command, user option, variable.

;; • Completion for function names with `ido-mode' interface, for ALL symbols in obarray (this means, including any package you've loaded.). (press TAB after word)

;; • Function param template for 340+ functions. (press space after function name.)

;; • Command to format entire sexp expression unit. (press TAB before a word or paren.)

;; • 1 to 4 letters abbrevs for top 100 most used functions. e.g. “d” → expands to defun.

;; abbrev or template are not expanded when in comment or string.

;; Call `xah-elisp-mode' to activate the mode.
;; Files ending in “.el” will open in `xah-elisp-mode'.

;; Single letter abbrevs are:
;; d → defun
;; i → insert
;; l → let
;; m → message
;; p → point
;; s → setq

;; Call `list-abbrevs' to see the full list.

;; put this in your init to turn on abbrev
;; (abbrev-mode 1)

;; home page: http://ergoemacs.org/emacs/xah-elisp-mode.html

;; This mode is designed to be very different from the usual paredit/smartparens approach.
;; The focus of this mode is to eliminate any concept of {manual formatting, format “style”, “indentation”, “line of code”} from programer. Instead, pretty-print/rendering should be automated, as part of display system. ({Matematica, XML, HTML} are examples.)
;; The goal of this mode is for it to become 100% semantic lisp code editor, such that it is impossible to create mis-formed elisp expressions, yet being practical.

;; If you like the idea, please help fund the project. Buy Xah Emacs Tutorial http://ergoemacs.org/emacs/buy_xah_emacs_tutorial.html or make a donation. See home page. Thanks.

;; 2016-12-02 compatible with company-mode

;; equires emacs 24.3 because of using setq-local

;;; INSTALL:

;; manual install.

;; Place the file at ~/.emacs.d/lisp/
;; Then put the following in ~/.emacs.d/init.el
;; (add-to-list 'load-path "~/.emacs.d/lisp/")
;; (autoload 'xah-elisp-mode "xah-elisp-mode" "xah emacs lisp major mode." t)


;;; Code:

(require 'lisp-mode)

(defvar xah-elisp-mode-hook nil "Standard hook for `xah-elisp-mode'")

(defvar xah-elisp-ampersand-words nil "List of elisp special syntax, just &optional and &rest,")
(setq xah-elisp-ampersand-words '( "&optional" "&rest" "t" "nil"))

(defvar xah-elisp-functions nil "List of elisp functions, those in elisp doc marked as function. (basically, all functions that's not command, macro, special forms.)")
(setq xah-elisp-functions '(
"mouse-on-link-p"
"macrop"
"run-hooks"
"run-hook-with-args"
"run-hook-with-args-until-failure"
"run-hook-with-args-until-success"
"define-fringe-bitmap"
"destroy-fringe-bitmap"
"set-fringe-bitmap-face"
"file-name-directory"
"file-name-nondirectory"
"file-name-sans-versions"
"file-name-extension"
"file-name-sans-extension"
"file-name-base"
"buffer-file-name"
"get-file-buffer"
"find-buffer-visiting"
"make-xwidget"
"xwidgetp"
"xwidget-plist"
"set-xwidget-plist"
"xwidget-buffer"
"get-buffer-xwidgets"
"xwidget-webkit-goto-uri"
"xwidget-webkit-execute-script"
"xwidget-webkit-execute-script-rv"
"xwidget-webkit-get-title"
"xwidget-resize"
"xwidget-size-request"
"xwidget-info"
"set-xwidget-query-on-exit-flag"
"xwidget-query-on-exit-flag"
"split-window"
"window-total-height"
"window-total-width"
"window-total-size"
"window-pixel-height"
"window-pixel-width"
"window-full-height-p"
"window-full-width-p"
"window-body-height"
"window-body-width"
"window-body-size"
"window-mode-line-height"
"window-header-line-height"
"window-max-chars-per-line"
"window-min-size"
"window-edges"
"window-body-edges"
"window-at"
"coordinates-in-window-p"
"window-pixel-edges"
"window-body-pixel-edges"
"window-absolute-pixel-edges"
"window-absolute-body-pixel-edges"
"window-absolute-pixel-position"
"buffer-modified-p"
"set-buffer-modified-p"
"restore-buffer-modified-p"
"buffer-modified-tick"
"buffer-chars-modified-tick"
"decode-time"
"encode-time"
"marker-position"
"marker-buffer"
"create-fontset-from-fontset-spec"
"set-fontset-font"
"char-displayable-p"
"custom-add-frequent-value"
"custom-reevaluate-setting"
"custom-variable-p"
"custom-theme-set-variables"
"custom-theme-set-faces"
"custom-theme-p"
"add-to-list"
"add-to-ordered-list"
"sin"
"cos"
"tan"
"asin"
"acos"
"atan"
"exp"
"log"
"expt"
"sqrt"
"get-char-code-property"
"char-code-property-description"
"put-char-code-property"
"prepare-change-group"
"activate-change-group"
"accept-change-group"
"cancel-change-group"
"active-minibuffer-window"
"minibuffer-window"
"set-minibuffer-window"
"window-minibuffer-p"
"minibuffer-window-active-p"
"define-category"
"category-docstring"
"get-unused-category"
"category-table"
"category-table-p"
"standard-category-table"
"copy-category-table"
"set-category-table"
"make-category-table"
"make-category-set"
"char-category-set"
"category-set-mnemonics"
"modify-category-entry"
"memory-limit"
"memory-use-counts"
"memory-info"
"smie-rule-bolp"
"smie-rule-hanging-p"
"smie-rule-next-p"
"smie-rule-prev-p"
"smie-rule-parent-p"
"smie-rule-sibling-p"
"smie-rule-parent"
"smie-rule-separator"
"lookup-key"
"local-key-binding"
"global-key-binding"
"minor-mode-key-binding"
"user-ptrp"
"gui-get-selection"
"point"
"point-min"
"point-max"
"buffer-end"
"buffer-size"
"foo"
"add-to-history"
"car"
"cdr"
"car-safe"
"cdr-safe"
"nth"
"nthcdr"
"last"
"safe-length"
"caar"
"cadr"
"cdar"
"cddr"
"butlast"
"nbutlast"
"macroexpand"
"macroexpand-all"
"string-to-syntax"
"syntax-after"
"syntax-class"
"make-finalizer"
"unsafep"
"set-buffer-multibyte"
"string-as-unibyte"
"string-as-multibyte"
"tabulated-list-init-header"
"tabulated-list-print"
"ffloor"
"fceiling"
"ftruncate"
"fround"
"assoc"
"rassoc"
"assq"
"alist-get"
"rassq"
"assoc-default"
"copy-alist"
"assq-delete-all"
"rassq-delete-all"
"make-serial-process"
"serial-process-configure"
"make-temp-file"
"make-temp-name"
"current-time-zone"
"key-description"
"single-key-description"
"text-char-description"
"vectorp"
"vector"
"make-vector"
"vconcat"
"create-file-buffer"
"after-find-file"
"buffer-live-p"
"transpose-regions"
"number-to-string"
"string-to-number"
"char-to-string"
"string-to-char"
"makunbound"
"boundp"
"consp"
"atom"
"listp"
"nlistp"
"null"
"buffer-base-buffer"
"charsetp"
"charset-priority-list"
"set-charset-priority"
"char-charset"
"charset-plist"
"put-charset-property"
"get-charset-property"
"decode-char"
"encode-char"
"map-charset-chars"
"x-list-fonts"
"x-family-fonts"
"momentary-string-display"
"frame-char-height"
"frame-char-width"
"abbrev-symbol"
"abbrev-expansion"
"abbrev-insert"
"setcdr"
"fill-context-prefix"
"position-bytes"
"byte-to-position"
"bufferpos-to-filepos"
"filepos-to-bufferpos"
"multibyte-string-p"
"string-bytes"
"unibyte-string"
"split-window-sensibly"
"same-window-p"
"get-text-property"
"get-char-property"
"get-pos-property"
"get-char-property-and-overlay"
"text-properties-at"
"color-defined-p"
"defined-colors"
"color-supported-p"
"color-gray-p"
"color-values"
"scroll-bar-event-ratio"
"scroll-bar-scale"
"get-register"
"set-register"
"register-read-with-preview"
"button-start"
"button-end"
"button-get"
"button-put"
"button-activate"
"button-label"
"button-type"
"button-has-type-p"
"button-at"
"button-type-put"
"button-type-get"
"button-type-subtype-p"
"buffer-list"
"other-buffer"
"last-buffer"
"current-frame-configuration"
"set-frame-configuration"
"funcall"
"apply"
"apply-partially"
"identity"
"ignore"
"file-name-as-directory"
"directory-name-p"
"directory-file-name"
"abbreviate-file-name"
"delete-and-extract-region"
"map-y-or-n-p"
"message"
"message-or-box"
"message-box"
"display-message-or-buffer"
"current-message"
"ding"
"beep"
"x-popup-dialog"
"network-interface-list"
"network-interface-info"
"format-network-address"
"floatp"
"integerp"
"numberp"
"natnump"
"zerop"
"imagemagick-types"
"completion-table-dynamic"
"completion-table-with-cache"
"mouse-position"
"set-mouse-position"
"mouse-pixel-position"
"set-mouse-pixel-position"
"mouse-absolute-pixel-position"
"set-mouse-absolute-pixel-position"
"frame-pointer-visible-p"
"tool-bar-add-item"
"tool-bar-add-item-from-menu"
"tool-bar-local-item-from-menu"
"send-string-to-terminal"
"insert-and-inherit"
"insert-before-markers-and-inherit"
"completing-read"
"minibuffer-prompt"
"minibuffer-prompt-end"
"minibuffer-prompt-width"
"minibuffer-contents"
"minibuffer-contents-no-properties"
"windowp"
"window-live-p"
"window-valid-p"
"selected-window"
"selected-window-group"
"window-resizable"
"window-resize"
"adjust-window-trailing-edge"
"edebug-trace"
"frame-live-p"
"window-frame"
"window-list"
"frame-root-window"
"window-parent"
"window-top-child"
"window-left-child"
"window-child"
"window-combined-p"
"window-next-sibling"
"window-prev-sibling"
"frame-first-window"
"window-in-direction"
"window-tree"
"tty-top-frame"
"font-family-list"
"bitmap-spec-p"
"region-active-p"
"region-beginning"
"region-end"
"use-region-p"
"default-value"
"default-boundp"
"set-default"
"put-text-property"
"add-text-properties"
"remove-text-properties"
"remove-list-of-text-properties"
"set-text-properties"
"add-face-text-property"
"propertize"
"not"
"error"
"signal"
"user-error"
"set-marker"
"move-marker"
"frame-current-scroll-bars"
"frame-scroll-bar-width"
"frame-scroll-bar-height"
"set-window-scroll-bars"
"window-scroll-bars"
"window-current-scroll-bars"
"window-scroll-bar-width"
"window-scroll-bar-height"
"window-hscroll"
"set-window-hscroll"
"create-image"
"find-image"
"image-load-path-for-library"
"make-byte-code"
"field-beginning"
"field-end"
"field-string"
"field-string-no-properties"
"delete-field"
"constrain-to-field"
"insert-for-yank"
"insert-buffer-substring-as-yank"
"get-internal-run-time"
"eq"
"equal"
"equal-including-properties"
"define-package"
"print"
"princ"
"prin1"
"terpri"
"write-char"
"pp"
"set-process-sentinel"
"process-sentinel"
"waiting-for-user-input-p"
"make-char-table"
"char-table-p"
"char-table-subtype"
"char-table-parent"
"set-char-table-parent"
"char-table-extra-slot"
"set-char-table-extra-slot"
"char-table-range"
"set-char-table-range"
"map-char-table"
"string-match"
"string-match-p"
"looking-at"
"looking-back"
"looking-at-p"
"make-syntax-table"
"copy-syntax-table"
"char-syntax"
"set-syntax-table"
"syntax-table"
"face-remap-add-relative"
"face-remap-remove-relative"
"face-remap-set-base"
"face-remap-reset-base"
"keymap-parent"
"set-keymap-parent"
"make-composed-keymap"
"define-key"
"substitute-key-definition"
"suppress-keymap"
"plist-get"
"plist-put"
"lax-plist-get"
"lax-plist-put"
"plist-member"
"libxml-parse-html-region"
"shr-insert-document"
"libxml-parse-xml-region"
"recenter-window-group"
"called-interactively-p"
"keywordp"
"compare-buffer-substrings"
"notifications-notify"
"notifications-close-notification"
"notifications-get-capabilities"
"notifications-get-server-information"
"sequencep"
"length"
"elt"
"copy-sequence"
"reverse"
"nreverse"
"sort"
"seq-elt"
"seq-length"
"seqp"
"seq-drop"
"seq-take"
"seq-take-while"
"seq-drop-while"
"seq-do"
"seq-map"
"seq-mapn"
"seq-filter"
"seq-remove"
"seq-reduce"
"seq-some"
"seq-find"
"seq-every-p"
"seq-empty-p"
"seq-count"
"seq-sort"
"seq-contains"
"seq-position"
"seq-uniq"
"seq-subseq"
"seq-concatenate"
"seq-mapcat"
"seq-partition"
"seq-intersection"
"seq-difference"
"seq-group-by"
"seq-into"
"seq-min"
"seq-max"
"stringp"
"string-or-null-p"
"char-or-string-p"
"ewoc-create"
"ewoc-buffer"
"ewoc-get-hf"
"ewoc-set-hf"
"ewoc-enter-first"
"ewoc-enter-last"
"ewoc-enter-before"
"ewoc-enter-after"
"ewoc-prev"
"ewoc-next"
"ewoc-nth"
"ewoc-data"
"ewoc-set-data"
"ewoc-locate"
"ewoc-location"
"ewoc-goto-prev"
"ewoc-goto-next"
"ewoc-goto-node"
"ewoc-refresh"
"ewoc-invalidate"
"ewoc-delete"
"ewoc-filter"
"ewoc-collect"
"ewoc-map"
"indirect-function"
"set-network-process-option"
"face-spec-set"
"substitute-command-keys"
"make-progress-reporter"
"progress-reporter-update"
"progress-reporter-force-update"
"progress-reporter-done"
"current-buffer"
"set-buffer"
"minibufferp"
"minibuffer-selected-window"
"minibuffer-message"
"this-command-keys"
"this-command-keys-vector"
"clear-this-command-keys"
"markerp"
"integer-or-marker-p"
"number-or-marker-p"
"make-translation-table"
"make-translation-table-from-vector"
"make-translation-table-from-alist"
"sit-for"
"sleep-for"
"read-from-minibuffer"
"read-string"
"read-regexp"
"read-no-blanks-input"
"frame-visible-p"
"make-process"
"make-pipe-process"
"start-process"
"start-file-process"
"start-process-shell-command"
"start-file-process-shell-command"
"find-file-name-handler"
"file-local-copy"
"file-remote-p"
"unhandled-file-name-directory"
"match-data"
"set-match-data"
"overlay-get"
"overlay-put"
"overlay-properties"
"file-name-absolute-p"
"file-relative-name"
"hack-dir-local-variables"
"hack-dir-local-variables-non-file-buffer"
"dir-locals-set-class-variables"
"dir-locals-set-directory-class"
"make-button"
"insert-button"
"make-text-button"
"insert-text-button"
"insert-image"
"insert-sliced-image"
"put-image"
"remove-images"
"image-size"
"insert-file-contents"
"insert-file-contents-literally"
"format"
"format-message"
"run-mode-hooks"
"cl-call-next-method"
"cl-next-method-p"
"char-equal"
"string-equal"
"string-collate-equalp"
"string-prefix-p"
"string-suffix-p"
"string-lessp"
"string-greaterp"
"string-collate-lessp"
"compare-strings"
"assoc-string"
"display-popup-menus-p"
"display-graphic-p"
"display-mouse-p"
"display-color-p"
"display-grayscale-p"
"display-supports-face-attributes-p"
"display-selections-p"
"display-images-p"
"display-screens"
"display-pixel-height"
"display-pixel-width"
"display-mm-height"
"display-mm-width"
"display-backing-store"
"display-save-under"
"display-planes"
"display-visual-class"
"display-color-cells"
"x-server-version"
"x-server-vendor"
"define-prefix-command"
"insert"
"insert-before-markers"
"insert-buffer-substring"
"insert-buffer-substring-no-properties"
"replace-match"
"match-substitute-replacement"
"set-input-mode"
"current-input-mode"
"tty-color-define"
"tty-color-clear"
"tty-color-alist"
"tty-color-approximate"
"tty-color-translate"
"call-process"
"process-file"
"call-process-region"
"call-process-shell-command"
"process-file-shell-command"
"shell-command-to-string"
"process-lines"
"current-kill"
"kill-new"
"kill-append"
"symbol-function"
"fboundp"
"fmakunbound"
"fset"
"hack-local-variables"
"safe-local-variable-p"
"risky-local-variable-p"
"keymapp"
"select-safe-coding-system"
"read-coding-system"
"read-non-nil-coding-system"
"current-time-string"
"current-time"
"float-time"
"seconds-to-time"
"set-default-file-modes"
"default-file-modes"
"read-file-modes"
"file-modes-symbolic-to-number"
"set-file-times"
"set-file-extended-attributes"
"set-file-selinux-context"
"set-file-acl"
"current-left-margin"
"current-fill-column"
"delete-to-left-margin"
"indent-to-left-margin"
"sort-subr"
"backup-file-name-p"
"make-backup-file-name"
"find-backup-file-name"
"file-newest-backup"
"locate-user-emacs-file"
"convert-standard-filename"
"add-hook"
"remove-hook"
"error-message-string"
"window-point"
"set-window-point"
"quit-restore-window"
"x-parse-geometry"
"process-list"
"get-process"
"process-command"
"process-contact"
"process-id"
"process-name"
"process-status"
"process-live-p"
"process-type"
"process-exit-status"
"process-tty-name"
"process-coding-system"
"set-process-coding-system"
"process-get"
"process-put"
"process-plist"
"set-process-plist"
"keyboard-translate"
"execute-kbd-macro"
"date-to-time"
"format-time-string"
"format-seconds"
"make-ring"
"ring-p"
"ring-size"
"ring-length"
"ring-elements"
"ring-copy"
"ring-empty-p"
"ring-ref"
"ring-insert"
"ring-remove"
"ring-insert-at-beginning"
"set-window-combination-limit"
"window-combination-limit"
"regexp-quote"
"regexp-opt"
"regexp-opt-depth"
"regexp-opt-charset"
"provide"
"require"
"featurep"
"backup-buffer"
"event-modifiers"
"event-basic-type"
"mouse-movement-p"
"event-convert-list"
"read-key-sequence"
"read-key-sequence-vector"
"file-truename"
"file-chase-links"
"file-equal-p"
"file-in-directory-p"
"eval"
"frame-parameter"
"frame-parameters"
"modify-frame-parameters"
"set-frame-parameter"
"modify-all-frames-parameters"
"process-datagram-address"
"set-process-datagram-address"
"current-window-configuration"
"set-window-configuration"
"window-configuration-p"
"compare-window-configurations"
"window-configuration-frame"
"window-state-get"
"window-state-put"
"charset-after"
"find-charset-region"
"find-charset-string"
"abbrev-table-put"
"abbrev-table-get"
"coding-system-list"
"coding-system-p"
"check-coding-system"
"coding-system-eol-type"
"coding-system-change-eol-conversion"
"coding-system-change-text-conversion"
"find-coding-systems-region"
"find-coding-systems-string"
"find-coding-systems-for-charsets"
"check-coding-systems-region"
"detect-coding-region"
"detect-coding-string"
"coding-system-charset-list"
"iter-next"
"iter-close"
"locate-file"
"executable-find"
"symbol-name"
"make-symbol"
"intern"
"intern-soft"
"mapatoms"
"unintern"
"current-column"
"special-variable-p"
"accessible-keymaps"
"map-keymap"
"where-is-internal"
"window-display-table"
"set-window-display-table"
"redisplay"
"force-window-update"
"window-start"
"window-group-start"
"window-end"
"window-group-end"
"set-window-start"
"set-window-group-start"
"pos-visible-in-window-p"
"pos-visible-in-window-group-p"
"window-line-height"
"fringe-bitmaps-at-pos"
"buffer-name"
"get-buffer"
"generate-new-buffer-name"
"jit-lock-register"
"jit-lock-unregister"
"file-notify-add-watch"
"file-notify-rm-watch"
"file-notify-valid-p"
"local-variable-p"
"local-variable-if-set-p"
"buffer-local-value"
"buffer-local-variables"
"kill-all-local-variables"
"eventp"
"skip-chars-forward"
"skip-chars-backward"
"window-parameter"
"window-parameters"
"set-window-parameter"
"recent-keys"
"terminal-parameters"
"terminal-parameter"
"set-terminal-parameter"
"memq"
"delq"
"remq"
"memql"
"member"
"delete"
"remove"
"member-ignore-case"
"delete-dups"
"parse-partial-sexp"
"get-buffer-create"
"generate-new-buffer"
"current-global-map"
"current-local-map"
"current-minor-mode-maps"
"use-global-map"
"use-local-map"
"set-transient-map"
"accept-process-output"
"skip-syntax-forward"
"skip-syntax-backward"
"backward-prefix-chars"
"vertical-motion"
"count-screen-lines"
"move-to-window-group-line"
"compute-motion"
"file-exists-p"
"file-readable-p"
"file-executable-p"
"file-writable-p"
"file-accessible-directory-p"
"access-file"
"file-ownership-preserved-p"
"file-modes"
"open-network-stream"
"undo-boundary"
"undo-auto-amalgamate"
"primitive-undo"
"keyboard-coding-system"
"terminal-coding-system"
"symbolp"
"booleanp"
"functionp"
"subrp"
"byte-code-function-p"
"subr-arity"
"char-width"
"string-width"
"truncate-string-to-width"
"window-text-pixel-size"
"documentation-property"
"documentation"
"face-documentation"
"Snarf-documentation"
"match-string"
"match-string-no-properties"
"match-beginning"
"match-end"
"coding-system-priority-list"
"set-coding-system-priority"
"x-popup-menu"
"-"
"mod"
"symbol-file"
"command-line"
"get-load-suffixes"
"defalias"
"define-button-type"
"custom-set-variables"
"custom-set-faces"
"interactive-form"
"encode-coding-string"
"decode-coding-string"
"decode-coding-inserted-region"
"make-hash-table"
"secure-hash"
"frame-geometry"
"frame-edges"
"buffer-narrowed-p"
"locale-info"
"keymap-prompt"
"set-window-margins"
"window-margins"
"try-completion"
"all-completions"
"test-completion"
"completion-boundaries"
"add-to-invisibility-spec"
"remove-from-invisibility-spec"
"invisible-p"
"char-after"
"char-before"
"following-char"
"preceding-char"
"bobp"
"eobp"
"bolp"
"eolp"
"coding-system-get"
"coding-system-aliases"
"defvaralias"
"make-obsolete-variable"
"indirect-variable"
"read-file-name"
"read-directory-name"
"read-shell-command"
"select-window"
"frame-selected-window"
"set-frame-selected-window"
"window-use-time"
"make-glyph-code"
"glyph-char"
"glyph-face"
"command-remapping"
"help-buffer"
"help-setup-xref"
"downcase"
"upcase"
"capitalize"
"upcase-initials"
"redraw-frame"
"characterp"
"max-char"
"get-byte"
"float"
"truncate"
"floor"
"ceiling"
"round"
"window-vscroll"
"set-window-vscroll"
"selected-frame"
"select-frame-set-input-focus"
"redirect-frame-focus"
"image-multi-frame-p"
"image-current-frame"
"image-show-frame"
"image-animate"
"image-animate-timer"
"replace-regexp-in-string"
"perform-replace"
"current-idle-time"
"subst-char-in-region"
"derived-mode-p"
"dom-node"
"face-attribute"
"face-attribute-relative-p"
"face-all-attributes"
"merge-face-attribute"
"set-face-attribute"
"set-face-bold"
"set-face-italic"
"set-face-underline"
"set-face-inverse-video"
"face-font"
"face-foreground"
"face-background"
"face-stipple"
"face-bold-p"
"face-italic-p"
"face-underline-p"
"face-inverse-video-p"
"file-name-all-completions"
"file-name-completion"
"make-string"
"string"
"substring"
"substring-no-properties"
"concat"
"split-string"
"window-buffer"
"set-window-buffer"
"get-buffer-window"
"get-buffer-window-list"
"process-query-on-exit-flag"
"set-process-query-on-exit-flag"
"process-send-string"
"process-send-region"
"process-send-eof"
"process-running-child-p"
"frame-position"
"set-frame-position"
"frame-pixel-height"
"frame-pixel-width"
"frame-text-height"
"frame-text-width"
"frame-height"
"frame-width"
"set-frame-size"
"set-frame-height"
"set-frame-width"
"recursion-depth"
"buffer-substring"
"buffer-substring-no-properties"
"buffer-string"
"filter-buffer-substring"
"current-word"
"thing-at-point"
"bufferp"
"random"
"processp"
"case-table-p"
"set-standard-case-table"
"standard-case-table"
"current-case-table"
"set-case-table"
"set-case-syntax-pair"
"set-case-syntax-delims"
"set-case-syntax"
"window-prev-buffers"
"set-window-prev-buffers"
"window-next-buffers"
"set-window-next-buffers"
"read-passwd"
"bindat-unpack"
"bindat-get-field"
"bindat-length"
"bindat-pack"
"bindat-ip-to-string"
"frame-list"
"visible-frame-list"
"next-frame"
"previous-frame"
"face-list"
"face-id"
"face-equal"
"face-differs-from-default-p"
"file-symlink-p"
"file-directory-p"
"file-regular-p"
"find-file-noselect"
"event-click-count"
"fontp"
"font-at"
"font-spec"
"font-put"
"find-font"
"list-fonts"
"font-get"
"font-face-attributes"
"font-xlfd-name"
"font-info"
"query-font"
"default-font-width"
"default-font-height"
"window-font-width"
"window-font-height"
"kbd"
"terminal-name"
"terminal-list"
"get-device-terminal"
"delete-terminal"
"x-display-list"
"x-open-connection"
"x-close-connection"
"display-monitor-attributes-list"
"frame-monitor-attributes"
"read-event"
"read-char"
"read-char-exclusive"
"read-key"
"read-char-choice"
"backtrace-debug"
"backtrace-frame"
"directory-files"
"directory-files-recursively"
"directory-files-and-attributes"
"file-expand-wildcards"
"insert-directory"
"scan-lists"
"scan-sexps"
"forward-comment"
"tq-create"
"tq-enqueue"
"tq-close"
"set-window-fringes"
"window-fringes"
"commandp"
"call-interactively"
"funcall-interactively"
"command-execute"
"make-bool-vector"
"bool-vector"
"bool-vector-p"
"bool-vector-exclusive-or"
"bool-vector-union"
"bool-vector-intersection"
"bool-vector-set-difference"
"bool-vector-not"
"bool-vector-subsetp"
"bool-vector-count-consecutive"
"bool-vector-count-population"
"current-active-maps"
"key-binding"
"byte-compile"
"batch-byte-compile"
"tooltip-mode"
"tooltip-event-buffer"
"gap-position"
"gap-size"
"fetch-bytecode"
"define-key-after"
"set-process-filter"
"process-filter"
"read-minibuffer"
"eval-minibuffer"
"edit-and-eval-command"
"verify-visited-file-modtime"
"clear-visited-file-modtime"
"visited-file-modtime"
"set-visited-file-modtime"
"ask-user-about-supersession-threat"
"string-to-multibyte"
"string-to-unibyte"
"byte-to-string"
"multibyte-char-to-unibyte"
"unibyte-char-to-multibyte"
"syntax-ppss"
"syntax-ppss-flush-cache"
"smie-config-local"
"read"
"read-from-string"
"set-binary-mode"
"event-start"
"event-end"
"posnp"
"posn-window"
"posn-area"
"posn-point"
"posn-x-y"
"posn-col-row"
"posn-actual-col-row"
"posn-string"
"posn-image"
"posn-object"
"posn-object-x-y"
"posn-object-width-height"
"posn-timestamp"
"posn-at-point"
"posn-at-x-y"
"image-flush"
"clear-image-cache"
"sentence-end"
"system-name"
"parse-colon-path"
"load-average"
"emacs-pid"
"y-or-n-p"
"y-or-n-p-with-timeout"
"yes-or-no-p"
"hash-table-p"
"copy-hash-table"
"hash-table-count"
"hash-table-test"
"hash-table-weakness"
"hash-table-rehash-size"
"hash-table-rehash-threshold"
"hash-table-size"
"custom-initialize-delay"
"dump-emacs"
"define-error"
"set-auto-mode"
"set-buffer-major-mode"
"next-window"
"previous-window"
"walk-windows"
"one-window-p"
"get-lru-window"
"get-mru-window"
"get-largest-window"
"get-window-with-predicate"
"list-system-processes"
"process-attributes"
"define-abbrev"
"find-auto-coding"
"set-auto-coding"
"find-operation-coding-system"
"listify-key-sequence"
"input-pending-p"
"discard-input"
"messages-buffer"
"set"
"auto-save-file-name-p"
"make-auto-save-file-name"
"recent-auto-save-p"
"set-buffer-auto-saved"
"delete-auto-save-file-if-necessary"
"rename-auto-save-file"
"abbrev-put"
"abbrev-get"
"forward-word-strictly"
"backward-word-strictly"
"advice-add"
"advice-remove"
"advice-member-p"
"advice-mapc"
"store-substring"
"clear-string"
"user-login-name"
"user-real-login-name"
"user-full-name"
"user-real-uid"
"user-uid"
"group-gid"
"group-real-gid"
"system-users"
"system-groups"
"play-sound"
"overlays-at"
"overlays-in"
"next-overlay-change"
"previous-overlay-change"
"next-property-change"
"previous-property-change"
"next-single-property-change"
"previous-single-property-change"
"next-char-property-change"
"previous-char-property-change"
"next-single-char-property-change"
"previous-single-char-property-change"
"text-property-any"
"text-property-not-all"
"symbol-value"
"make-abbrev-table"
"abbrev-table-p"
"clear-abbrev-table"
"copy-abbrev-table"
"define-abbrev-table"
"insert-abbrev-table-description"
"advice-function-member-p"
"advice-function-mapc"
"advice-eval-interactive-spec"
"display-buffer-same-window"
"display-buffer-reuse-window"
"display-buffer-pop-up-frame"
"display-buffer-use-some-frame"
"display-buffer-pop-up-window"
"display-buffer-below-selected"
"display-buffer-in-previous-window"
"display-buffer-at-bottom"
"display-buffer-use-some-window"
"display-buffer-no-window"
"isnan"
"frexp"
"ldexp"
"copysign"
"logb"
"file-newer-than-file-p"
"file-attributes"
"file-nlinks"
"barf-if-buffer-read-only"
"file-acl"
"file-selinux-context"
"file-extended-attributes"
"zlib-available-p"
"zlib-decompress-region"
"window-preserve-size"
"window-preserved-size"
"load"
"arrayp"
"aref"
"aset"
"fillarray"
"delete-process"
"image-mask-p"
"interrupt-process"
"kill-process"
"quit-process"
"stop-process"
"continue-process"
"minibuffer-depth"
"gethash"
"puthash"
"remhash"
"clrhash"
"maphash"
"read-quoted-char"
"eql"
"max"
"min"
"abs"
"framep"
"frame-terminal"
"terminal-live-p"
"image-type-available-p"
"mapcar"
"mapc"
"mapconcat"
"purecopy"
"current-bidi-paragraph-direction"
"move-point-visually"
"bidi-string-mark-left-to-right"
"bidi-find-overridden-directionality"
"buffer-substring-with-bidi-context"
"special-form-p"
"type-of"
"syntax-ppss-toplevel-pos"
"shell-quote-argument"
"split-string-and-unquote"
"combine-and-quote-strings"
"posix-looking-at"
"posix-string-match"
"smie-setup"
"define-hash-table-test"
"sxhash"
"window-system"
"setcar"
"read-buffer"
"read-command"
"read-variable"
"force-mode-line-update"
"file-locked-p"
"lock-buffer"
"unlock-buffer"
"ask-user-about-lock"
"make-display-table"
"display-table-slot"
"set-display-table-slot"
"describe-display-table"
"get"
"put"
"symbol-plist"
"setplist"
"function-get"
"function-put"
"process-buffer"
"process-mark"
"set-process-buffer"
"get-buffer-process"
"set-process-window-size"
"current-indentation"
"read-input-method-name"
"make-obsolete"
"set-advertised-calling-convention"
"suspend-tty"
"resume-tty"
"controlling-tty-p"
"overlayp"
"make-overlay"
"overlay-start"
"overlay-end"
"overlay-buffer"
"delete-overlay"
"move-overlay"
"remove-overlays"
"copy-overlay"
"overlay-recenter"
"nconc"
"expand-file-name"
"substitute-in-file-name"
"prefix-numeric-value"
"lsh"
"ash"
"logand"
"logior"
"logxor"
"lognot"
"display-warning"
"lwarn"
"warn"
"next-button"
"previous-button"
"font-lock-add-keywords"
"font-lock-remove-keywords"
"current-justification"
"display-completion-list"
"make-sparse-keymap"
"make-keymap"
"copy-keymap"
"window-right-divider-width"
"window-bottom-divider-width"
"autoload"
"autoloadp"
"autoload-do-load"
"syntax-table-p"
"standard-syntax-table"
"throw"
"facep"
"x-get-resource"
"set-marker-insertion-type"
"marker-insertion-type"
"format-mode-line"
"quietly-read-abbrev-file"
"window-dedicated-p"
"set-window-dedicated-p"
"cancel-timer"
"make-network-process"
"time-less-p"
"time-subtract"
"time-add"
"time-to-days"
"time-to-day-in-year"
"date-leap-year-p"
"buffer-swap-text"
"mark"
"mark-marker"
"set-mark"
"push-mark"
"pop-mark"
"deactivate-mark"
"handle-shift-selection"
"cons"
"list"
"make-list"
"append"
"copy-tree"
"number-sequence"
"line-beginning-position"
"line-end-position"
"count-lines"
"line-number-at-pos"
"completion-in-region"
"make-marker"
"point-marker"
"point-min-marker"
"point-max-marker"
"copy-marker"
))

(defvar xah-elisp-special-forms nil "List of elisp special forms.")
(setq xah-elisp-special-forms '(
"catch"
"function"
"setq"
"eval-and-compile"
"eval-when-compile"
"defvar"
"defconst"
"if"
"cond"
"track-mouse"
"save-restriction"
"with-no-warnings"
"interactive"
"save-excursion"
"while"
"condition-case"
"quote"
"save-current-buffer"
"let"
"let*"
"and"
"or"
"setq-default"
"unwind-protect"
"count-loop"
"progn"
"prog1"
"prog2"
))

(defvar xah-elisp-macros nil "List of elisp macros.")
(setq xah-elisp-macros '(
"defcustom"
"deftheme"
"provide-theme"
"push"
"save-match-data"
"pop"
"defsubst"
"define-alternatives"
"with-output-to-temp-buffer"
"with-temp-buffer-window"
"with-current-buffer-window"
"with-displayed-buffer-window"
"pcase"
"pcase-defmacro"
"with-temp-message"
"declare-function"
"edebug-tracing"
"defimage"
"setf"
"with-output-to-string"
"with-syntax-table"
"seq-doseq"
"seq-let"
"with-eval-after-load"
"defface"
"dotimes-with-progress-reporter"
"with-current-buffer"
"with-temp-buffer"
"delay-mode-hooks"
"cl-defgeneric"
"cl-defmethod"
"gv-define-simple-setter"
"gv-define-setter"
"defmacro"
"with-file-modes"
"condition-case-unless-debug"
"ignore-errors"
"with-demoted-errors"
"easy-menu-define"
"save-window-excursion"
"iter-defun"
"iter-lambda"
"iter-yield"
"iter-yield-from"
"iter-do"
"setq-local"
"defvar-local"
"define-generic-mode"
"with-local-quit"
"dolist"
"dotimes"
"save-mark-and-excursion"
"with-coding-priority"
"defun"
"define-inline"
"inline-quote"
"inline-letevals"
"inline-const-p"
"inline-const-val"
"inline-error"
"define-minor-mode"
"define-globalized-minor-mode"
"lazy-completion-table"
"define-obsolete-variable-alias"
"save-selected-window"
"with-selected-window"
"declare"
"with-help-window"
"make-help-screen"
"define-derived-mode"
"when"
"unless"
"combine-after-change-calls"
"with-case-table"
"define-obsolete-face-alias"
"noreturn"
"def-edebug-spec"
"while-no-input"
"define-advice"
"add-function"
"remove-function"
"lambda"
"define-obsolete-function-alias"
"with-temp-file"
"defgroup"
"with-timeout"
))

(defvar xah-elisp-commands nil "List of elisp commands.")
(setq
 xah-elisp-commands
 '(
   "Helper-describe-bindings"
   "Helper-help"
   "abbrev-prefix-mark"
   "abort-recursive-edit"
   "add-name-to-file"
   "append-to-file"
   "apropos"
   "async-shell-command"
   "auto-save-mode"
   "back-to-indentation"
   "backtrace"
   "backward-button"
   "backward-char"
   "backward-delete-char-untabify"
   "backward-list"
   "backward-sexp"
   "backward-to-indentation"
   "backward-up-list"
   "backward-word"
   "balance-windows"
   "balance-windows-area"
   "base64-decode-region"
   "base64-encode-region"
   "beginning-of-buffer"
   "beginning-of-defun"
   "beginning-of-line"
   "blink-matching-open"
   "buffer-disable-undo"
   "buffer-enable-undo"
   "bury-buffer"
   "byte-compile-file"
   "byte-recompile-directory"
   "cancel-debug-on-entry"
   "capitalize-region"
   "capitalize-word"
   "clone-indirect-buffer"
   "compile-defun"
   "copy-directory"
   "copy-file"
   "copy-region-as-kill"
   "count-words"
   "debug"
   "debug-on-entry"
   "decode-coding-region"
   "delete-backward-char"
   "delete-blank-lines"
   "delete-char"
   "delete-directory"
   "delete-file"
   "delete-frame"
   "delete-horizontal-space"
   "delete-indentation"
   "delete-minibuffer-contents"
   "delete-other-windows"
   "delete-region"
   "delete-trailing-whitespace"
   "delete-window"
   "delete-windows-on"
   "describe-bindings"
   "describe-buffer-case-table"
   "describe-categories"
   "describe-current-display-table"
   "describe-mode"
   "describe-prefix-bindings"
   "describe-syntax"
   "digit-argument"
   "disable-command"
   "disable-theme"
   "disassemble"
   "display-buffer"
   "do-auto-save"
   "down-list"
   "downcase-region"
   "downcase-word"
   "edebug-display-freq-count"
   "edebug-set-initial-mode"
   "emacs-init-time"
   "emacs-uptime"
   "emacs-version"
   "enable-command"
   "enable-theme"
   "encode-coding-region"
   "end-of-buffer"
   "end-of-defun"
   "end-of-line"
   "erase-buffer"
   "eval-buffer"
   "eval-region"
   "execute-extended-command"
   "exit-minibuffer"
   "exit-recursive-edit"
   "expand-abbrev"
   "fill-individual-paragraphs"
   "fill-paragraph"
   "fill-region"
   "fill-region-as-paragraph"
   "find-file"
   "find-file-literally"
   "find-file-other-window"
   "find-file-read-only"
   "fit-frame-to-buffer"
   "fit-window-to-buffer"
   "fixup-whitespace"
   "format-find-file"
   "format-insert-file"
   "format-write-file"
   "forward-button"
   "forward-char"
   "forward-line"
   "forward-list"
   "forward-sexp"
   "forward-to-indentation"
   "forward-word"
   "fundamental-mode"
   "garbage-collect"
   "getenv"
   "global-set-key"
   "global-unset-key"
   "goto-char"
   "gui-set-selection"
   "handle-switch-frame"
   "iconify-frame"
   "imenu-add-to-menubar"
   "indent-according-to-mode"
   "indent-code-rigidly"
   "indent-for-tab-command"
   "indent-region"
   "indent-relative"
   "indent-relative-maybe"
   "indent-rigidly"
   "indent-to"
   "insert-buffer"
   "insert-char"
   "insert-register"
   "invert-face"
   "just-one-space"
   "justify-current-line"
   "keyboard-quit"
   "kill-buffer"
   "kill-emacs"
   "kill-local-variable"
   "kill-region"
   "list-charset-chars"
   "list-load-path-shadows"
   "list-processes"
   "load-file"
   "load-library"
   "load-theme"
   "local-set-key"
   "local-unset-key"
   "locate-library"
   "lower-frame"
   "make-directory"
   "make-frame"
   "make-frame-invisible"
   "make-frame-on-display"
   "make-frame-visible"
   "make-indirect-buffer"
   "make-local-variable"
   "make-symbolic-link"
   "make-variable-buffer-local"
   "maximize-window"
   "minibuffer-complete"
   "minibuffer-complete-and-exit"
   "minibuffer-complete-word"
   "minibuffer-completion-help"
   "minibuffer-inactive-mode"
   "minimize-window"
   "modify-syntax-entry"
   "move-to-column"
   "move-to-left-margin"
   "move-to-window-line"
   "narrow-to-page"
   "narrow-to-region"
   "negative-argument"
   "newline"
   "newline-and-indent"
   "next-complete-history-element"
   "next-history-element"
   "next-matching-history-element"
   "normal-mode"
   "not-modified"
   "open-dribble-file"
   "open-termscript"
   "other-window"
   "package-initialize"
   "package-upload-buffer"
   "package-upload-file"
   "play-sound-file"
   "pop-to-buffer"
   "posix-search-backward"
   "posix-search-forward"
   "previous-complete-history-element"
   "previous-history-element"
   "previous-matching-history-element"
   "prog-mode"
   "push-button"
   "quit-window"
   "raise-frame"
   "re-search-backward"
   "re-search-forward"
   "read-color"
   "read-kbd-macro"
   "read-only-mode"
   "recenter"
   "recenter-top-bottom"
   "recursive-edit"
   "redraw-display"
   "reindent-then-newline-and-indent"
   "rename-buffer"
   "rename-file"
   "replace-buffer-in-windows"
   "revert-buffer"
   "run-at-time"
   "run-with-idle-timer"
   "save-buffer"
   "save-some-buffers"
   "scroll-down"
   "scroll-down-command"
   "scroll-left"
   "scroll-other-window"
   "scroll-right"
   "scroll-up"
   "scroll-up-command"
   "search-backward"
   "search-forward"
   "select-frame"
   "self-insert-and-exit"
   "self-insert-command"
   "serial-term"
   "set-face-background"
   "set-face-font"
   "set-face-foreground"
   "set-face-stipple"
   "set-file-modes"
   "set-frame-font"
   "set-input-method"
   "set-keyboard-coding-system"
   "set-left-margin"
   "set-right-margin"
   "set-terminal-coding-system"
   "set-visited-file-name"
   "setenv"
   "shell-command"
   "shrink-window-if-larger-than-buffer"
   "signal-process"
   "smie-close-block"
   "smie-config-guess"
   "smie-config-save"
   "smie-config-set-indent"
   "smie-config-show-indent"
   "smie-down-list"
   "sort-columns"
   "sort-fields"
   "sort-lines"
   "sort-numeric-fields"
   "sort-pages"
   "sort-paragraphs"
   "sort-regexp-fields"
   "special-mode"
   "split-window-below"
   "split-window-right"
   "strong>help-command"
   "suspend-emacs"
   "suspend-frame"
   "switch-to-buffer"
   "switch-to-buffer-other-frame"
   "switch-to-buffer-other-window"
   "switch-to-next-buffer"
   "switch-to-prev-buffer"
   "tab-to-tab-stop"
   "text-mode"
   "top-level"
   "translate-region"
   "unbury-buffer"
   "undefined"
   "universal-argument"
   "unload-feature"
   "up-list"
   "upcase-region"
   "upcase-word"
   "view-register"
   "widen"
   "word-search-backward"
   "word-search-backward-lax"
   "word-search-forward"
   "word-search-forward-lax"
   "write-abbrev-file"
   "write-file"
   "write-region"
   "yank"
   "yank-pop"
   ))

(defvar xah-elisp-user-options nil "List of user options.")
(setq xah-elisp-user-options '(
"switch-to-buffer-in-dedicated-window"
"switch-to-buffer-preserve-window-point"
"transient-mark-mode"
"mark-even-if-inactive"
"mark-ring-max"
"timer-max-repeats"
"abbrev-file-name"
"save-abbrevs"
"custom-unlispify-remove-prefixes"
"tab-always-indent"
"completion-auto-help"
"fill-individual-varying-indent"
"default-justification"
"sentence-end-double-space"
"sentence-end-without-period"
"sentence-end-without-space"
"debug-on-quit"
"default-input-method"
"indent-tabs-mode"
"window-adjust-process-window-size-function"
"create-lockfiles"
"completion-styles"
"completion-category-overrides"
"read-buffer-function"
"read-buffer-completion-ignore-case"
"before-save-hook"
"after-save-hook"
"file-precious-flag"
"require-final-newline"
"warning-minimum-level"
"warning-minimum-log-level"
"warning-suppress-types"
"warning-suppress-log-types"
"inhibit-startup-screen"
"initial-buffer-choice"
"inhibit-startup-echo-area-message"
"initial-scratch-message"
"enable-recursive-minibuffers"
"delete-exited-processes"
"initial-frame-alist"
"minibuffer-frame-alist"
"default-frame-alist"
"indicate-empty-lines"
"indicate-buffer-boundaries"
"overflow-newline-into-fringe"
"backup-by-copying"
"backup-by-copying-when-linked"
"backup-by-copying-when-mismatch"
"backup-by-copying-when-privileged-mismatch"
"case-fold-search"
"case-replace"
"user-mail-address"
"words-include-escapes"
"version-control"
"kept-new-versions"
"kept-old-versions"
"delete-old-versions"
"dired-kept-versions"
"auto-save-visited-file-name"
"auto-save-interval"
"auto-save-timeout"
"auto-save-default"
"delete-auto-save-files"
"auto-save-list-file-prefix"
"message-log-max"
"auto-coding-regexp-alist"
"file-coding-system-alist"
"auto-coding-alist"
"auto-coding-functions"
"only-global-abbrevs"
"package-archives"
"package-archive-upload-base"
"initial-major-mode"
"major-mode"
"mail-host-address"
"page-delimiter"
"paragraph-separate"
"paragraph-start"
"sentence-end"
"smie-config"
"edebug-eval-macro-args"
"echo-keystrokes"
"double-click-fuzz"
"double-click-time"
"find-file-wildcards"
"find-file-hook"
"switch-to-visible-buffer"
"frame-resize-pixelwise"
"completion-ignored-extensions"
"focus-follows-mouse"
"no-redraw-on-reenter"
"help-char"
"help-event-list"
"three-step-help"
"read-file-name-completion-ignore-case"
"insert-default-directory"
"revert-without-query"
"face-font-family-alternatives"
"face-font-selection-order"
"face-font-registry-alternatives"
"scalable-fonts-allowed"
"load-prefer-newer"
"selective-display-ellipses"
"inhibit-eol-conversion"
"display-buffer-alist"
"display-buffer-base-action"
"kill-ring-max"
"void-text-area-pointer"
"exec-suffixes"
"exec-path"
"max-lisp-eval-depth"
"edebug-sit-for-seconds"
"make-backup-files"
"backup-directory-alist"
"make-backup-file-name-function"
"edebug-setup-hook"
"edebug-all-defs"
"edebug-all-forms"
"edebug-save-windows"
"edebug-save-displayed-buffer-points"
"edebug-initial-mode"
"edebug-trace"
"edebug-test-coverage"
"edebug-continue-kbd-macro"
"edebug-unwrap-results"
"edebug-on-error"
"edebug-on-quit"
"edebug-global-break-condition"
"window-combination-limit"
"window-combination-resize"
"edebug-print-length"
"edebug-print-level"
"edebug-print-circle"
"frame-auto-hide-function"
"sort-fold-case"
"sort-numeric-base"
"fill-prefix"
"fill-column"
"left-margin"
"fill-nobreak-predicate"
"enable-local-variables"
"safe-local-variable-values"
"enable-local-eval"
"safe-local-eval-forms"
"frame-inhibit-implied-resize"
"display-mm-dimensions-alist"
"remote-file-name-inhibit-cache"
"read-regexp-defaults-function"
"max-mini-window-height"
"mode-line-format"
"eval-expression-print-length"
"eval-expression-print-level"
"scroll-margin"
"scroll-conservatively"
"scroll-down-aggressively"
"scroll-up-aggressively"
"scroll-step"
"scroll-preserve-screen-position"
"next-screen-context-lines"
"scroll-error-top-bottom"
"recenter-redisplay"
"recenter-positions"
"byte-compile-dynamic-docstrings"
"yank-handled-properties"
"yank-excluded-properties"
"max-specpdl-size"
"term-file-prefix"
"term-file-aliases"
"image-load-path"
"scroll-bar-mode"
"horizontal-scroll-bar-mode"
"blink-matching-paren"
"blink-matching-paren-distance"
"blink-matching-delay"
"underline-minimum-offset"
"x-bitmap-file-path"
"minibuffer-auto-raise"
"window-resize-pixelwise"
"fit-window-to-buffer-horizontally"
"fit-frame-to-buffer"
"fit-frame-to-buffer-margins"
"fit-frame-to-buffer-sizes"
"baud-rate"
"imagemagick-enabled-types"
"imagemagick-types-inhibit"
"visible-bell"
"ring-bell-function"
"site-run-file"
"inhibit-default-init"
"backward-delete-char-untabify-method"
"cursor-in-non-selected-windows"
"x-stretch-cursor"
"blink-cursor-alist"
"truncate-lines"
"truncate-partial-width-windows"
"kill-read-only-ok"
"pop-up-windows"
"split-window-preferred-function"
"split-height-threshold"
"split-width-threshold"
"even-window-sizes"
"pop-up-frames"
"pop-up-frame-function"
"pop-up-frame-alist"
"same-window-buffer-names"
"same-window-regexps"
"debug-on-error"
"debug-ignored-errors"
"eval-expression-debug-on-error"
"debug-on-signal"
"debug-on-event"
"adaptive-fill-mode"
"adaptive-fill-regexp"
"adaptive-fill-first-line-regexp"
"adaptive-fill-function"
"glyphless-char-display-control"
"abbrev-all-caps"
"temp-buffer-show-function"
"temp-buffer-resize-mode"
"temp-buffer-max-height"
"temp-buffer-max-width"
"tab-stop-list"
"buffer-offer-save"
"temporary-file-directory"
"small-temporary-file-directory"
"undo-limit"
"undo-strong-limit"
"undo-outer-limit"
"undo-ask-before-discard"
"parse-sexp-ignore-comments"
"ctl-arrow"
"tab-width"
"defun-prompt-regexp"
"open-paren-in-column-0-is-defun-start"
"history-length"
"history-delete-duplicates"
"selection-coding-system"
"meta-prefix-char"
"garbage-collection-messages"
"gc-cons-threshold"
"gc-cons-percentage"
"resize-mini-windows"
"max-mini-window-height"
"window-min-height"
"window-min-width"
"split-window-keep-point"
))

(defvar xah-elisp-variables nil "List elisp variables names (excluding user options).")
(setq xah-elisp-variables '(

"abbrev-expand-function"
"abbrev-minor-mode-table-alist"
"abbrev-start-location"
"abbrev-start-location-buffer"
"abbrev-table-name-list"
"abbrevs-changed"
"activate-mark-hook"
"after-change-functions"
"after-change-major-mode-hook"
"after-focus-change-function"
"after-init-hook"
"after-insert-file-functions"
"after-load-functions"
"after-make-frame-functions"
"after-revert-hook"
"ascii-case-table"
"auto-fill-chars"
"auto-fill-function"
"auto-mode-alist"
"auto-raise-tool-bar-buttons"
"auto-resize-tool-bars"
"auto-save-hook"
"auto-save-list-file-name"
"auto-window-vscroll"
"backup-enable-predicate"
"backup-inhibited"
"before-change-functions"
"before-hack-local-variables-hook"
"before-init-hook"
"before-make-frame-hook"
"before-revert-hook"
"beginning-of-defun-function"
"bidi-display-reordering"
"bidi-paragraph-direction"
"blink-paren-function"
"buffer-access-fontified-property"
"buffer-access-fontify-functions"
"buffer-auto-save-file-format"
"buffer-auto-save-file-name"
"buffer-backed-up"
"buffer-display-count"
"buffer-display-table"
"buffer-display-time"
"buffer-file-coding-system"
"buffer-file-format"
"buffer-file-name"
"buffer-file-number"
"buffer-file-truename"
"buffer-invisibility-spec"
"buffer-list-update-hook"
"buffer-name-history"
"buffer-read-only"
"buffer-save-without-query"
"buffer-saved-size"
"buffer-stale-function"
"buffer-substring-filters"
"buffer-undo-list"
"byte-boolean-vars"
"byte-compile-dynamic"
"change-major-mode-after-body-hook"
"change-major-mode-hook"
"char-property-alias-alist"
"char-script-table"
"char-width-table"
"charset-list"
"coding-system-for-read"
"coding-system-for-write"
"command-debug-status"
"command-error-function"
"command-history"
"command-line-args"
"command-line-args-left"
"command-line-functions"
"command-line-processed"
"command-switch-alist"
"comment-end-can-be-escaped"
"completing-read-function"
"completion-at-point-functions"
"completion-extra-properties"
"completion-ignore-case"
"completion-regexp-list"
"completion-styles-alist"
"cons-cells-consed"
"current-input-method"
"current-prefix-arg"
"cursor-in-echo-area"
"cursor-type"
"custom-known-themes"
"customize-package-emacs-version-alist"
"data-directory"
"deactivate-mark"
"deactivate-mark-hook"
"debug-on-message"
"debug-on-next-call"
"debugger"
"default-directory"
"default-minibuffer-frame"
"default-process-coding-system"
"default-text-properties"
"defining-kbd-macro"
"delayed-warnings-hook"
"delayed-warnings-list"
"delete-terminal-functions"
"desktop-buffer-mode-handlers"
"desktop-save-buffer"
"dir-locals-class-alist"
"dir-locals-directory-cache"
"disable-point-adjustment"
"disabled-command-function"
"display-buffer-overriding-action"
"doc-directory"
"dynamic-library-alist"
"echo-area-clear-hook"
"electric-future-map"
"emacs-build-time"
"emacs-major-version"
"emacs-minor-version"
"emacs-save-session-functions"
"emacs-startup-hook"
"emacs-version"
"emulation-mode-map-alists"
"enable-dir-local-variables"
"enable-multibyte-characters"
"end-of-defun-function"
"exec-directory"
"executing-kbd-macro"
"extended-command-history"
"extra-keyboard-modifiers"
"face-font-rescale-alist"
"face-name-history"
"face-remapping-alist"
"features"
"file-local-variables-alist"
"file-name-coding-system"
"file-name-history"
"fill-forward-paragraph-function"
"fill-paragraph-function"
"filter-buffer-substring-function"
"filter-buffer-substring-functions"
"find-file-literally"
"find-file-not-found-functions"
"find-word-boundary-function-table"
"first-change-hook"
"float-e"
"float-output-format"
"float-pi"
"floats-consed"
"focus-in-hook"
"focus-out-hook"
"font-lock-defaults"
"font-lock-ensure-function"
"font-lock-extend-after-change-region-function"
"font-lock-extra-managed-props"
"font-lock-flush-function"
"font-lock-fontify-buffer-function"
"font-lock-fontify-region-function"
"font-lock-keywords"
"font-lock-keywords-case-fold-search"
"font-lock-keywords-only"
"font-lock-mark-block-function"
"font-lock-multiline"
"font-lock-syntactic-face-function"
"font-lock-syntax-table"
"font-lock-unfontify-buffer-function"
"font-lock-unfontify-region-function"
"fontification-functions"
"format-alist"
"frame-inherited-parameters"
"frame-title-format"
"fringe-cursor-alist"
"fringe-indicator-alist"
"fringes-outside-margins"
"fundamental-mode-abbrev-table"
"gc-elapsed"
"gcs-done"
"generate-autoload-cookie"
"generated-autoload-file"
"global-abbrev-table"
"global-disable-point-adjustment"
"global-map"
"global-mode-string"
"glyph-table"
"glyphless-char-display"
"hack-local-variables-hook"
"header-line-format"
"help-form"
"help-map"
"history-add-new-input"
"horizontal-scroll-bar"
"icon-title-format"
"ignore-window-parameters"
"ignored-local-variables"
"image-cache-eviction-delay"
"image-format-suffixes"
"image-types"
"imenu-case-fold-search"
"imenu-create-index-function"
"imenu-extract-index-name-function"
"imenu-generic-expression"
"imenu-prev-index-position-function"
"imenu-syntax-alist"
"indent-line-function"
"indent-region-function"
"inhibit-field-text-motion"
"inhibit-file-name-handlers"
"inhibit-file-name-operation"
"inhibit-iso-escape-detection"
"inhibit-local-variables-regexps"
"inhibit-message"
"inhibit-modification-hooks"
"inhibit-null-byte-detection"
"inhibit-point-motion-hooks"
"inhibit-quit"
"inhibit-read-only"
"inhibit-x-resources"
"init-file-user"
"initial-environment"
"initial-window-system"
"input-decode-map"
"input-method-alist"
"input-method-function"
"insert-directory-program"
"installation-directory"
"interpreter-mode-alist"
"interprogram-cut-function"
"interprogram-paste-function"
"intervals-consed"
"invocation-directory"
"invocation-name"
"kbd-macro-termination-hook"
"key-translation-map"
"keyboard-translate-table"
"kill-buffer-hook"
"kill-buffer-query-functions"
"kill-emacs-hook"
"kill-emacs-query-functions"
"kill-ring"
"kill-ring-yank-pointer"
"last-abbrev"
"last-abbrev-location"
"last-abbrev-text"
"last-coding-system-used"
"last-command"
"last-command-event"
"last-event-frame"
"last-input-event"
"last-kbd-macro"
"last-nonmenu-event"
"last-prefix-arg"
"last-repeatable-command"
"left-fringe-width"
"left-margin-width"
"lexical-binding"
"line-prefix"
"lisp-mode-abbrev-table"
"list-buffers-directory"
"load-file-name"
"load-file-rep-suffixes"
"load-history"
"load-in-progress"
"load-path"
"load-read-function"
"load-suffixes"
"local-abbrev-table"
"local-function-key-map"
"locale-coding-system"
"magic-fallback-mode-alist"
"magic-mode-alist"
"mark-active"
"mark-ring"
"max-image-size"
"memory-full"
"menu-bar-final-items"
"menu-bar-update-hook"
"menu-prompt-more-char"
"message-truncate-lines"
"minibuffer-allow-text-properties"
"minibuffer-completion-confirm"
"minibuffer-completion-predicate"
"minibuffer-completion-table"
"minibuffer-confirm-exit-commands"
"minibuffer-exit-hook"
"minibuffer-help-form"
"minibuffer-history"
"minibuffer-local-completion-map"
"minibuffer-local-filename-completion-map"
"minibuffer-local-map"
"minibuffer-local-must-match-map"
"minibuffer-local-ns-map"
"minibuffer-local-shell-command-map"
"minibuffer-scroll-window"
"minibuffer-setup-hook"
"minor-mode-alist"
"minor-mode-list"
"minor-mode-map-alist"
"minor-mode-overriding-map-alist"
"misc-objects-consed"
"mode-line-buffer-identification"
"mode-line-client"
"mode-line-end-spaces"
"mode-line-frame-identification"
"mode-line-front-space"
"mode-line-misc-info"
"mode-line-modes"
"mode-line-modified"
"mode-line-mule-info"
"mode-line-position"
"mode-line-process"
"mode-line-remote"
"mode-name"
"module-file-suffix"
"most-negative-fixnum"
"most-positive-fixnum"
"mouse-position-function"
"multi-query-replace-map"
"multibyte-syntax-as-symbol"
"multiple-frames"
"network-coding-system-alist"
"noninteractive"
"normal-auto-fill-function"
"num-input-keys"
"num-nonmacro-input-events"
"obarray"
"other-window-scroll-buffer"
"overlay-arrow-position"
"overlay-arrow-string"
"overlay-arrow-variable-list"
"overriding-local-map"
"overriding-local-map-menu-flag"
"overriding-terminal-local-map"
"overwrite-mode"
"parse-sexp-lookup-properties"
"path-separator"
"play-sound-functions"
"post-command-hook"
"post-gc-hook"
"pre-command-hook"
"pre-redisplay-function"
"pre-redisplay-functions"
"prefix-arg"
"prefix-help-command"
"print-circle"
"print-continuous-numbering"
"print-escape-multibyte"
"print-escape-newlines"
"print-escape-nonascii"
"print-gensym"
"print-length"
"print-level"
"print-number-table"
"print-quoted"
"printable-chars"
"process-adaptive-read-buffering"
"process-coding-system-alist"
"process-connection-type"
"process-environment"
"process-file-side-effects"
"pure-bytes-used"
"purify-flag"
"query-replace-history"
"query-replace-map"
"quit-flag"
"read-circle"
"read-expression-history"
"read-file-name-function"
"real-last-command"
"regexp-history"
"register-alist"
"replace-re-search-function"
"replace-search-function"
"revert-buffer-function"
"revert-buffer-in-progress-p"
"revert-buffer-insert-file-contents-function"
"right-fringe-width"
"right-margin-width"
"save-buffer-coding-system"
"scroll-bar-height"
"scroll-bar-width"
"search-spaces-regexp"
"selective-display"
"shell-command-history"
"show-help-function"
"special-event-map"
"split-string-default-separators"
"standard-display-table"
"standard-input"
"standard-output"
"standard-translation-table-for-decode"
"standard-translation-table-for-encode"
"string-chars-consed"
"strings-consed"
"suspend-hook"
"suspend-resume-hook"
"symbols-consed"
"syntax-propertize-extend-region-functions"
"syntax-propertize-function"
"system-configuration"
"system-key-alist"
"system-messages-locale"
"system-time-locale"
"system-type"
"tabulated-list-entries"
"tabulated-list-format"
"tabulated-list-printer"
"tabulated-list-revert-hook"
"tabulated-list-sort-key"
"temp-buffer-setup-hook"
"temp-buffer-show-hook"
"text-mode-abbrev-table"
"text-property-default-nonsticky"
"text-quoting-style"
"this-command"
"this-original-command"
"tool-bar-border"
"tool-bar-button-margin"
"tool-bar-button-relief"
"tool-bar-map"
"tooltip-frame-parameters"
"tooltip-functions"
"translation-table-for-input"
"tty-erase-char"
"tty-setup-hook"
"undo-auto-current-boundary-timer"
"undo-in-progress"
"unicode-category-table"
"unload-feature-special-hooks"
"unread-command-events"
"use-hard-newlines"
"user-emacs-directory"
"user-init-file"
"values"
"vc-mode"
"vector-cells-consed"
"vertical-scroll-bar"
"warning-fill-prefix"
"warning-levels"
"warning-prefix-function"
"warning-series"
"warning-type-format"
"window-configuration-change-hook"
"window-persistent-parameters"
"window-point-insertion-type"
"window-scroll-functions"
"window-setup-hook"
"window-size-change-functions"
"window-size-fixed"
"window-system"
"wrap-prefix"
"write-contents-functions"
"write-file-functions"
"write-region-annotate-functions"
"write-region-post-annotation-function"
"x-alt-keysym"
"x-hyper-keysym"
"x-meta-keysym"
"x-pointer-shape"
"x-resource-class"
"x-resource-name"
"x-sensitive-text-pointer-shape"
"x-super-keysym"
"yank-undo-function"
))

(defvar xah-elisp-all-symbols nil "List of all elisp symbols.")
(setq xah-elisp-all-symbols nil)

;; (setq xah-elisp-all-symbols
;;       (append
;;        xah-elisp-ampersand-words
;;        xah-elisp-functions
;;        xah-elisp-special-forms
;;        xah-elisp-macros
;;        xah-elisp-commands
;;        xah-elisp-user-options
;;        xah-elisp-variables ))

(mapatoms (lambda (x) (push (symbol-name x) xah-elisp-all-symbols)) obarray )

;; (length xah-elisp-all-symbols )
;; 46694. on gnu emacs sans init, about 15k
;; 81516 typical xah session

(defun xah-elisp-display-page-break-as-line ()
  "Display the formfeed ^L char as line.
Version 2017-01-27"
  (interactive)
  ;; 2016-10-11 thanks to Steve Purcell's page-break-lines.el
  (progn
    (when (not buffer-display-table)
      (setq buffer-display-table (make-display-table)))
    (aset buffer-display-table ?\^L
          (vconcat (make-list 70 (make-glyph-code ?─ 'font-lock-comment-face))))
    (redraw-frame)))



;; emacs 24.4 or 24.3 change fix

(defun xah-elisp-up-list (arg1 &optional arg2 arg3)
  "Backward compatibility fix for emacs 24.4's `up-list'.
emacs 25.x changed `up-list' to take up to 3 args. Before, only 1."
  (interactive)
  (if (>= emacs-major-version 25)
      (up-list arg1 arg2 arg3)
    (up-list arg1)))


;; completion

(defun xah-elisp-complete-symbol ()
  "Perform keyword completion on current symbol.
This uses `ido-mode' user interface for completion.
version 2017-01-27"
  (interactive)
  (let* (
         ($bds (bounds-of-thing-at-point 'symbol))
         ($p1 (car $bds))
         ($p2 (cdr $bds))
         ($current-sym
          (if  (or (not $p1) (not $p2) (equal $p1 $p2))
              ""
            (buffer-substring-no-properties $p1 $p2)))
         $result-sym)
    (when (not $current-sym) (setq $current-sym ""))
    (setq $result-sym
          (ido-completing-read "" xah-elisp-all-symbols nil nil $current-sym ))
    (delete-region $p1 $p2)
    (insert $result-sym)))

(defun xah-elisp-completion-function ()
  "This is the function to be used for the hook `completion-at-point-functions'."
  (interactive)
  (let* (
         ($bds (bounds-of-thing-at-point 'symbol))
         ($p1 (car $bds))
         ($p2 (cdr $bds)))
    (list $p1 $p2 xah-elisp-all-symbols nil )))

(defun xah-elisp-start-with-left-paren-p ()
  "Returns t or nil"
  (interactive)
  (save-excursion
    (forward-symbol -1) (backward-char 1)
    (if (looking-at "(")
        t
      nil)))

(defun xah-elisp-add-paren-around-symbol ()
  "Add paren around symbol before cursor and add a space before closing paren, place cursor there.
 Example:
 my-xyz▮
becomes
 (my-xyz ▮)"
  (interactive)
  (forward-symbol -1) (insert "(") (forward-symbol 1) (insert " )")
  (backward-char 1))

(defun xah-elisp-remove-paren-pair ()
  "Remove closest left outer paren around cursor or remove string quote and activate the region.
Cursor is moved to the left deleted paren spot, mark is set to the right deleted paren spot.
Call `exchange-point-and-mark' \\[exchange-point-and-mark] to highlight them."
  (interactive)
  (let ($pos)
    (atomic-change-group
      (xah-elisp-up-list -1 "ESCAPE-STRINGS" "NO-SYNTAX-CROSSING")
      (while (not (char-equal (char-after) ?\( ))
        (xah-elisp-up-list -1 "ESCAPE-STRINGS" "NO-SYNTAX-CROSSING"))
      (setq $pos (point))
      (forward-sexp)
      (delete-char -1)
      (push-mark (point) t t)
      (goto-char $pos)
      (delete-char 1))))

(defun xah-elisp-abbrev-enable-function ()
  "Return t if not in string or comment. Else nil.
This is for abbrev table property `:enable-function'.
Version 2016-10-24"
  (let (($syntax-state (syntax-ppss)))
    (not (or (nth 3 $syntax-state) (nth 4 $syntax-state)))))

(defun xah-elisp-expand-abbrev ()
  "Expand the symbol before cursor,
if cursor is not in string or comment.
Returns the abbrev symbol if there's a expansion, else nil.
Version 2017-01-13"
  (interactive)
  (when (xah-elisp-abbrev-enable-function) ; abbrev property :enable-function doesn't seem to work, so check here instead
    (let ( $p1 $p2
               $abrStr
               $abrSymbol
               )

      ;; (save-excursion
      ;;   (forward-symbol -1)
      ;;   (setq $p1 (point))
      ;;   (goto-char $p0)
      ;;   (setq $p2 $p0))

      (save-excursion
        ;; 2017-01-16 note: we select the whole symbol to solve a problem. problem is: if “aa”  is a abbrev, and “▮bbcc” is existing word with cursor at beginning, and user wants to type aa-bbcc. Normally, aa immediately expands. This prevent people editing bbcc to become aa-bbcc. This happens for example in elisp “search-forward” to get “re-search-forward”. The downside of this is that, people cannot type a abbrev when in middle of a word.
        (forward-symbol -1)
        (setq $p1 (point))
        (forward-symbol 1)
        (setq $p2 (point)))

      (setq $abrStr (buffer-substring-no-properties $p1 $p2))
      (setq $abrSymbol (abbrev-symbol $abrStr))
      (if $abrSymbol
          (progn
            (abbrev-insert $abrSymbol $abrStr $p1 $p2 )
            (xah-elisp--abbrev-position-cursor $p1)
            $abrSymbol)
        nil))))

(defun xah-elisp--abbrev-position-cursor (&optional @pos)
  "Move cursor back to ▮ if exist, else put at end.
Return true if found, else false.
Version 2016-10-24"
  (interactive)
  (let (($found-p (search-backward "▮" (if @pos @pos (max (point-min) (- (point) 100))) t )))
    (when $found-p (delete-char 1))
    $found-p
    ))

(defun xah-elisp--ahf ()
  "Abbrev hook function, used for `define-abbrev'.
 Our use is to prevent inserting the char that triggered expansion. Experimental.
 the “ahf” stand for abbrev hook function.
Version 2016-10-24"
  t)

(put 'xah-elisp--ahf 'no-self-insert t)


;; indent/reformat related

(defun xah-elisp-complete-or-indent ()
  "Do keyword completion or indent/prettify-format.

If char before point is letters and char after point is whitespace or punctuation, then do completion, except when in string or comment. In these cases, do `xah-elisp-prettify-root-sexp'."
  (interactive)
  ;; consider the char to the left or right of cursor. Each side is either empty or char.
  ;; there are 4 cases:
  ;; space▮space → do indent
  ;; space▮char → do indent
  ;; char▮space → do completion
  ;; char ▮char → do indent
  (let ( ($syntax-state (syntax-ppss)))
    (if (or (nth 3 $syntax-state) (nth 4 $syntax-state))
        (progn
          (xah-elisp-prettify-root-sexp))
      (progn (if
                 (and (looking-back "[-_a-zA-Z]" 1)
                      (or (eobp) (looking-at "[\n[:blank:][:punct:]]")))
                 (xah-elisp-complete-symbol)
               (xah-elisp-prettify-root-sexp))))))

(defun xah-elisp-prettify-root-sexp ()
  "Prettify format current root sexp group.
Root sexp group is the outmost sexp unit.

Version 2016-10-13"
  (interactive)
  (save-excursion
    (let ($p1 $p2)
      (xah-elisp-goto-outmost-bracket)
      (setq $p1 (point))
      (setq $p2 (scan-sexps (point) 1))
      (save-excursion
        (save-restriction
          (narrow-to-region $p1 $p2)
          (progn
            (goto-char (point-min))
            (indent-sexp)
            (xah-elisp-compact-parens-region (point-min) (point-max))
            (xah-elisp-compact-blank-lines (point-min) (point-max))
            (delete-trailing-whitespace (point-min) (point-max))))))))

(defun xah-elisp-compact-blank-lines (&optional @begin @end @n)
  "Replace repeated blank lines to just 1.
Works on whole buffer or text selection, respects `narrow-to-region'.

@N is the number of newline chars to use in replacement.
If 0, it means lines will be joined.
By befault, @N is 2. It means, 1 visible blank line.

Version 2017-01-27"
  (interactive
   (if (region-active-p)
       (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (when (not @begin)
    (setq @begin (point-min) @end (point-max)))
  (save-excursion
    (save-restriction
      (narrow-to-region @begin @end)
      (progn
        (goto-char (point-min))
        (while (search-forward-regexp "\n\n\n+" nil "noerror")
          (replace-match (make-string (if @n @n 2) 10)))))))

(defun xah-elisp-goto-outmost-bracket (&optional @pos)
  "Move cursor to the beginning of outer-most bracket, with respect to @pos.
Returns true if point is moved, else false."
  (interactive)
  (let (($i 0)
        ($p0 (if (number-or-marker-p @pos)
                 @pos
               (point))))
    (goto-char $p0)
    (while
        (and (< (setq $i (1+ $i)) 20)
             (not (eq (nth 0 (syntax-ppss (point))) 0)))
      (xah-elisp-up-list -1 "ESCAPE-STRINGS" "NO-SYNTAX-CROSSING"))
    (if (equal $p0 (point))
        nil
      t
      )))

(defun xah-elisp-compact-parens (&optional @begin @end)
  "Remove whitespaces in ending repetition of parenthesises.
If there's a text selection, act on the region, else, on defun block.
Version 2017-01-27"
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (save-excursion
       (xah-elisp-goto-outmost-bracket)
       (list (point) (scan-sexps (point) 1)))))
  (let (($p1 @begin) ($p2 @end))
    (when (not @begin)
      (save-excursion
        (xah-elisp-goto-outmost-bracket)
        (setq $p1 (point))
        (setq $p2 (scan-sexps (point) 1))))
    (xah-elisp-compact-parens-region $p1 $p2)))

(defun xah-elisp-compact-parens-region (@begin @end)
  "Remove whitespaces in ending repetition of parenthesises in region."
  (interactive "r")
  (let ($syntax-state)
    (save-restriction
      (narrow-to-region @begin @end)
      (goto-char (point-min))
      (while (search-forward-regexp ")[ \t\n]+)" nil t)
        (setq $syntax-state (syntax-ppss (match-beginning 0)))
        (if (or (nth 3 $syntax-state ) (nth 4 $syntax-state))
            (progn (search-forward ")"))
          (progn (replace-match "))")
                 (search-backward ")")))))))


;; abbrev

(defvar xah-elisp-mode-abbrev-table nil "abbrev table" )
;; wanted to start clean, for development. eventually, prob not
(setq xah-elisp-mode-abbrev-table nil)

(define-abbrev-table 'xah-elisp-mode-abbrev-table
  '(
    ("c" "concat" xah-elisp--ahf)
    ("d" "defun" xah-elisp--ahf)
    ("f" "format" xah-elisp--ahf)
    ("i" "insert" xah-elisp--ahf)
    ("l" "let" xah-elisp--ahf)
    ("m" "message" xah-elisp--ahf)
    ("o" "&optional " xah-elisp--ahf)
    ("p" "point" xah-elisp--ahf)
    ("s" "setq" xah-elisp--ahf)
    ("w" "when" xah-elisp--ahf)

    ("ah" "add-hook" xah-elisp--ahf)
    ("bc" "backward-char" xah-elisp--ahf)
    ("bs" "buffer-substring" xah-elisp--ahf)
    ("bw" "backward-word" xah-elisp--ahf)
    ("ca" "char-after" xah-elisp--ahf)
    ("cb" "current-buffer" xah-elisp--ahf)
    ("cc" "condition-case" xah-elisp--ahf)
    ("cd" "copy-directory" xah-elisp--ahf)
    ("ce" "char-equal" xah-elisp--ahf)
    ("cf" "copy-file" xah-elisp--ahf)
    ("cp" "call-process" xah-elisp--ahf)
    ("cw" "current-word" xah-elisp--ahf)
    ("dc" "delete-char" xah-elisp--ahf)
    ("dd" "delete-directory" xah-elisp--ahf)
    ("df" "delete-file" xah-elisp--ahf)
    ("dk" "define-key" xah-elisp--ahf)
    ("dr" "delete-region" xah-elisp--ahf)
    ("dv" "defvar" xah-elisp--ahf)
    ("eb" "erase-buffer" xah-elisp--ahf)
    ("fa" "fillarray" xah-elisp--ahf)
    ("fc" "forward-char" xah-elisp--ahf)
    ("ff" "find-file" xah-elisp--ahf)
    ("fl" "forward-line" xah-elisp--ahf)
    ("fw" "forward-word" xah-elisp--ahf)
    ("gb" "get-buffer" xah-elisp--ahf)
    ("gc" "goto-char" xah-elisp--ahf)
    ("kb" "kill-buffer" xah-elisp--ahf)
    ("kr" "kill-region" xah-elisp--ahf)
    ("la" "looking-at" xah-elisp--ahf)
    ("lb" "looking-back" xah-elisp--ahf)
    ("lc" "left-char" xah-elisp--ahf)
    ("mb" "match-beginning" xah-elisp--ahf)
    ("mc" "mapcar" xah-elisp--ahf)
    ("md" "make-directory" xah-elisp--ahf)
    ("me" "match-end" xah-elisp--ahf)
    ("ml" "make-list" xah-elisp--ahf)
    ("ms" "match-string" xah-elisp--ahf)
    ("mv" "make-vector" xah-elisp--ahf)
    ("ns" "number-sequence" xah-elisp--ahf)
    ("pm" "point-min" xah-elisp--ahf)
    ("pn" "progn" xah-elisp--ahf)
    ("px" "point-max" xah-elisp--ahf)
    ("rb" "region-beginning" xah-elisp--ahf)
    ("rc" "right-char" xah-elisp--ahf)
    ("re" "region-end" xah-elisp--ahf)
    ("rf" "rename-file" xah-elisp--ahf)
    ("rm" "replace-match" xah-elisp--ahf)
    ("rn" "read-number" xah-elisp--ahf)
    ("rq" "regexp-quote" xah-elisp--ahf)
    ("rr" "replace-regexp" xah-elisp--ahf)
    ("rs" "read-string" xah-elisp--ahf)
    ("sb" "search-backward" xah-elisp--ahf)
    ("sc" "shell-command" xah-elisp--ahf)
    ("asc" "async-shell-command" xah-elisp--ahf)
    ("sd" "setq-default" xah-elisp--ahf)
    ("se" "save-excursion" xah-elisp--ahf)
    ("sf" "search-forward" xah-elisp--ahf)
    ("sm" "string-match" xah-elisp--ahf)
    ("sp" "start-process" xah-elisp--ahf)
    ("sr" "save-restriction" xah-elisp--ahf)
    ("ss" "split-string" xah-elisp--ahf)
    ("vc" "vconcat" xah-elisp--ahf)
    ("wg" "widget-get" xah-elisp--ahf)
    ("wr" "write-region" xah-elisp--ahf)

    ("atf" "append-to-file" xah-elisp--ahf)
    ("bfn" "buffer-file-name" xah-elisp--ahf)
    ("bmp" "buffer-modified-p" xah-elisp--ahf)
    ("bol" "beginning-of-line" xah-elisp--ahf)
    ("botap" "bounds-of-thing-at-point" xah-elisp--ahf)
    ("bsnp" "buffer-substring-no-properties" xah-elisp--ahf)
    ("cdr" "cdr" xah-elisp--ahf)
    ("cpa" "current-prefix-arg" xah-elisp--ahf)
    ("daer" "delete-and-extract-region" xah-elisp--ahf)
    ("dfr" "directory-files-recursively" xah-elisp--ahf)
    ("efn" "expand-file-name" xah-elisp--ahf)
    ("eol" "end-of-line" xah-elisp--ahf)
    ("fep" "file-exists-p" xah-elisp--ahf)
    ("fnd" "file-name-directory" xah-elisp--ahf)
    ("fne" "file-name-extension" xah-elisp--ahf)
    ("fnn" "file-name-nondirectory" xah-elisp--ahf)
    ("fnse" "file-name-sans-extension" xah-elisp--ahf)
    ("frn" "file-relative-name" xah-elisp--ahf)
    ("gbc" "get-buffer-create" xah-elisp--ahf)
    ("gnb" "generate-new-buffer" xah-elisp--ahf)
    ("gsk" "global-set-key" xah-elisp--ahf)
    ("gtp " "get-text-property" xah-elisp--ahf)
    ("ifc" "insert-file-contents" xah-elisp--ahf)
    ("lam" "lambda" xah-elisp--ahf)
    ("lbp" "(line-beginning-position)" xah-elisp--ahf)
    ("len" "length" xah-elisp--ahf)
    ("lep" "(line-end-position)" xah-elisp--ahf)
    ("mlv" "make-local-variable" xah-elisp--ahf)
    ("ntr" "narrow-to-region" xah-elisp--ahf)
    ("nts" "number-to-string" xah-elisp--ahf)
    ("opt" "&optional " xah-elisp--ahf)
    ("ptp" "put-text-property" xah-elisp--ahf)
    ("rap" "region-active-p" xah-elisp--ahf)
    ("rdn" "read-directory-name" xah-elisp--ahf)
    ("rfn" "read-file-name" xah-elisp--ahf)
    ("rris" "replace-regexp-in-string" xah-elisp--ahf)
    ("rsb" "re-search-backward" xah-elisp--ahf)
    ("rsf" "re-search-forward" xah-elisp--ahf)
    ("sbr" "search-backward-regexp" xah-elisp--ahf)
    ("scb" "skip-chars-backward" xah-elisp--ahf)
    ("scf" "skip-chars-forward" xah-elisp--ahf)
    ("sfm" "set-file-modes" xah-elisp--ahf)
    ("sfr" "search-forward-regexp" xah-elisp--ahf)
    ("sqa" "shell-quote-argument" xah-elisp--ahf)
    ("stb" "switch-to-buffer" xah-elisp--ahf)
    ("ste" "(string-equal str1▮ str2)" xah-elisp--ahf)
    ("stn" "string-to-number" xah-elisp--ahf)
    ("tap" "thing-at-point" xah-elisp--ahf)
    ("urp" "use-region-p" xah-elisp--ahf)
    ("wcb" "with-current-buffer" xah-elisp--ahf)
    ("wots" "with-output-to-string" xah-elisp--ahf)
    ("wtb" "with-temp-buffer" xah-elisp--ahf)
    ("wtf" "with-temp-file" xah-elisp--ahf)
    ("yonp" "yes-or-no-p" xah-elisp--ahf)

    ("abbreviate-file-name" "(abbreviate-file-name ▮)" xah-elisp--ahf)
    ("add-hook" "(add-hook 'HOOK▮ 'FUNCTION)" xah-elisp--ahf)
    ("add-text-properties" "(add-text-properties p1▮ p2 PROPS &optional OBJECT)" xah-elisp--ahf)
    ("add-to-list" "(add-to-list LIST-VAR▮ ELEMENT &optional APPEND COMPARE-FN)" xah-elisp--ahf)
    ("alist-get" "(alist-get key▮ value &optional default)" xah-elisp--ahf)
    ("and" "(and ▮)" xah-elisp--ahf )
    ("append" "(append ▮)" xah-elisp--ahf)
    ("append-to-file" "(append-to-file p1▮ p2 FILENAME)" xah-elisp--ahf)
    ("apply" "(apply ▮)" xah-elisp--ahf)
    ("aref" "(aref ARRAY▮ INDEX)" xah-elisp--ahf)
    ("aset" "(aset ARRAY▮ IDX NEWELT)" xah-elisp--ahf)
    ("ask-user-about-supersession-threat" "(ask-user-about-supersession-threat FILENAME▮)" xah-elisp--ahf)
    ("assoc" "(assoc KEY▮ LIST)" xah-elisp--ahf)
    ("assoc-default" "(assoc-default key▮ alist &optional test default)" xah-elisp--ahf)
    ("assoc-string" "(assoc-string key▮ alist &optional case-fold)" xah-elisp--ahf)
    ("assq" "(assq key▮ alist)" xah-elisp--ahf)
    ("assq-delete-all" "(assq-delete-all key▮ alist)" xah-elisp--ahf)
    ("autoload" "(autoload 'FUNCNAME▮ \"FILENAME\" &optional \"DOCSTRING\" INTERACTIVE TYPE)" xah-elisp--ahf)
    ("backward-char" "(backward-char ▮)" xah-elisp--ahf)
    ("backward-up-list" "(backward-up-list &optional ARG▮ 'ESCAPE-STRINGS 'NO-SYNTAX-CROSSING)" xah-elisp--ahf)
    ("backward-word" "(backward-word ▮)" xah-elisp--ahf)
    ("barf-if-buffer-read-only" "(barf-if-buffer-read-only)" xah-elisp--ahf)
    ("beginning-of-line" "(beginning-of-line)" xah-elisp--ahf)
    ("boundp" "(boundp '▮)" xah-elisp--ahf)
    ("bounds-of-thing-at-point" "(bounds-of-thing-at-point 'symbol▮ 'filename 'word 'whitespace 'line)" xah-elisp--ahf)
    ("buffer-base-buffer" "(buffer-base-buffer &optional BUFFER▮)" xah-elisp--ahf)
    ("buffer-chars-modified-tick" "(buffer-chars-modified-tick &optional BUFFER▮)" xah-elisp--ahf)
    ("buffer-file-name" "(buffer-file-name)" xah-elisp--ahf)
    ("buffer-list" "(buffer-list &optional FRAME▮)" xah-elisp--ahf)
    ("buffer-live-p" "(buffer-live-p OBJECT▮)" xah-elisp--ahf)
    ("buffer-modified-p" "(buffer-modified-p BUFFER▮)" xah-elisp--ahf)
    ("buffer-modified-p" "(buffer-modified-p ▮)" xah-elisp--ahf)
    ("buffer-modified-tick" "(buffer-modified-tick &optional BUFFER▮)" xah-elisp--ahf)
    ("buffer-name" "(buffer-name BUFFER▮)" xah-elisp--ahf)
    ("buffer-substring" "(buffer-substring p1▮ p2)" xah-elisp--ahf)
    ("buffer-substring-no-properties" "(buffer-substring-no-properties p1▮ p2)" xah-elisp--ahf)
    ("buffer-swap-text" "(buffer-swap-text BUFFER▮)" xah-elisp--ahf)
    ("bufferp" "(bufferp ▮)" xah-elisp--ahf)
    ("bury-buffer" "(bury-buffer &optional BUFFER-OR-NAME▮)" xah-elisp--ahf)
    ("call-interactively" "(call-interactively 'FUNCTION▮ &optional RECORD-FLAG KEYS)" xah-elisp--ahf)
    ("call-process" "(call-process PROGRAM▮ &optional INFILE DESTINATION DISPLAY &rest ARGS)" xah-elisp--ahf)
    ("called-interactively-p" "(called-interactively-p 'interactive▮)" xah-elisp--ahf)
    ("car" "(car ▮)" xah-elisp--ahf)
    ("catch" "(catch 'TAG▮ BODY)" xah-elisp--ahf)
    ("cdr" "(cdr ▮)" xah-elisp--ahf)
    ("ceiling" "(ceiling ▮)" xah-elisp--ahf)
    ("char-after" "(char-after &optional ▮POS)" xah-elisp--ahf)
    ("char-before" "(char-before &optional ▮POS)" xah-elisp--ahf)
    ("char-equal" "(char-equal char1▮ char1)" xah-elisp--ahf)
    ("char-to-string" "(char-to-string CHAR▮) " xah-elisp--ahf)
    ("clear-image-cache" "(clear-image-cache &optional FILTER▮)" xah-elisp--ahf)
    ("clear-visited-file-modtime" "(clear-visited-file-modtime)" xah-elisp--ahf)
    ("clone-indirect-buffer" "(clone-indirect-buffer NEWNAME▮ DISPLAY-FLAG &optional NORECORD)" xah-elisp--ahf)
    ("clrhash" "(clrhash ▮)" xah-elisp--ahf)
    ("compare-strings" "(compare-strings string1▮ start1 end1 string2 start2 end2)" xah-elisp--ahf)
    ("concat" "(concat \"▮\" \"▮\")" xah-elisp--ahf)
    ("cond" "(cond\n(CONDITION▮ BODY)\n(CONDITION BODY)\n)" xah-elisp--ahf)
    ("condition-case" "(condition-case ▮)" xah-elisp--ahf)
    ("cons" "(cons CAR▮ CDR)" xah-elisp--ahf)
    ("consp" "(consp ▮)" xah-elisp--ahf)
    ("constrain-to-field" "(constrain-to-field NEW-POS▮ OLD-POS &optional ESCAPE-FROM-EDGE ONLY-IN-LINE INHIBIT-CAPTURE-PROPERTY)" xah-elisp--ahf)
    ("copy-alist" "(copy-alist alist▮)" xah-elisp--ahf)
    ("copy-directory" "(copy-directory ▮ NEWNAME &optional KEEP-TIME PARENTS)" xah-elisp--ahf)
    ("copy-file" "(copy-file FILE▮ NEWNAME &optional OK-IF-ALREADY-EXISTS KEEP-TIME PRESERVE-UID-GID)" xah-elisp--ahf)
    ("create-image" "(create-image FILE-OR-DATA▮ &optional TYPE DATA-P &rest)" xah-elisp--ahf)
    ("cts" "(char-to-string CHAR▮) " xah-elisp--ahf)
    ("current-buffer" "(current-buffer)" xah-elisp--ahf)
    ("current-word" "(current-word)" xah-elisp--ahf)
    ("custom-autoload" "(custom-autoload ▮ SYMBOL LOAD &optional NOSET)" xah-elisp--ahf)
    ("defalias" "(defalias 'SYMBOL▮ 'DEFINITION &optional DOCSTRING)" xah-elisp--ahf)
    ("defconst" "(defconst ▮ INITVALUE \"DOCSTRING\")" xah-elisp--ahf)
    ("defcustom" "(defcustom ▮ VALUE \"DOC\" &optional ARGS)" xah-elisp--ahf)
    ("defface" "(defface FACE▮ SPEC \"DOC\" &rest ARGS)" xah-elisp--ahf)
    ("defimage" "(defimage SYMBOL▮ SPECS &optional DOC)" xah-elisp--ahf)
    ("define-key" "(define-key KEYMAPNAME▮ (kbd \"M-b\") 'FUNCNAME)" xah-elisp--ahf)
    ("define-minor-mode" "(define-minor-mode MODE▮ \"DOC\" &optional INIT-VALUE LIGHTER KEYMAP &rest BODY)" xah-elisp--ahf)
    ("defsubst" "(defsubst ▮)" xah-elisp--ahf)
    ("defun" "(defun f▮ ()\n  \"DOCSTRING\"\n  (interactive)\n  (let ()\n3\n ))" xah-elisp--ahf)
    ("defvar" "(defvar ▮ &optional INITVALUE \"DOCSTRING\")" xah-elisp--ahf)
    ("delete" "(delete OBJECT▮ SEQUENCE)" xah-elisp--ahf)
    ("delete-and-extract-region" "(delete-and-extract-region ▮ pos2)" xah-elisp--ahf)
    ("delete-char" "(delete-char 1▮)" xah-elisp--ahf)
    ("delete-directory" "(delete-directory ▮ &optional RECURSIVE)" xah-elisp--ahf)
    ("delete-dups" "(delete-dups LIST▮)" xah-elisp--ahf)
    ("delete-field" "(delete-field &optional POS▮)" xah-elisp--ahf)
    ("delete-file" "(delete-file ▮)" xah-elisp--ahf)
    ("delete-region" "(delete-region p1▮ p2)" xah-elisp--ahf)
    ("delq" "(delq ELT▮ LIST)" xah-elisp--ahf)
    ("directory-file-name" "(directory-file-name ▮)" xah-elisp--ahf)
    ("directory-files" "(directory-files ▮ &optional FULL MATCH NOSORT)" xah-elisp--ahf)
    ("directory-files-recursively" "(directory-files-recursively DIR▮ REGEXP &optional INCLUDE-DIRECTORIES)" xah-elisp--ahf)
    ("directory-name-p" "(directory-name-p ▮)" xah-elisp--ahf)
    ("dolist" "(dolist (x LIST▮ [RESULT]) BODY)" xah-elisp--ahf)
    ("dotimes" "(dotimes (i COUNT▮ [RESULT]) BODY)" xah-elisp--ahf)
    ("elt" "(elt SEQUENCE▮ N)" xah-elisp--ahf)
    ("end-of-line" "(end-of-line ▮&optional N)" xah-elisp--ahf)
    ("eq" "(eq ▮)" xah-elisp--ahf)
    ("equal" "(equal ▮)" xah-elisp--ahf)
    ("erase-buffer" "(erase-buffer)" xah-elisp--ahf)
    ("error" "(error \"%s\" ▮)" xah-elisp--ahf)
    ("expand-file-name" "(expand-file-name ▮ &optional relativedir)" xah-elisp--ahf)
    ("fboundp" "(fboundp '▮)" xah-elisp--ahf)
    ("fceiling" "(fceiling ▮)" xah-elisp--ahf)
    ("featurep" "(featurep 'FEATURE▮)" xah-elisp--ahf)
    ("ffloor" "(ffloor ▮)" xah-elisp--ahf)
    ("field-beginning" "(field-beginning &optional POS▮ ESCAPE-FROM-EDGE LIMIT)" xah-elisp--ahf)
    ("field-end" "(field-end &optional POS▮ ESCAPE-FROM-EDGE LIMIT)" xah-elisp--ahf)
    ("field-string" "(field-string &optional POS▮)" xah-elisp--ahf)
    ("field-string-no-properties" "(field-string-no-properties &optional POS▮)" xah-elisp--ahf)
    ("file-directory-p" "(file-directory-p ▮)" xah-elisp--ahf)
    ("file-exists-p" "(file-exists-p ▮)" xah-elisp--ahf)
    ("file-name-absolute-p" "(file-name-absolute-p ▮)" xah-elisp--ahf)
    ("file-name-as-directory" "(file-name-as-directory ▮)" xah-elisp--ahf)
    ("file-name-directory" "(file-name-directory ▮)" xah-elisp--ahf)
    ("file-name-extension" "(file-name-extension ▮ &optional PERIOD)" xah-elisp--ahf)
    ("file-name-nondirectory" "(file-name-nondirectory ▮)" xah-elisp--ahf)
    ("file-name-sans-extension" "(file-name-sans-extension ▮)" xah-elisp--ahf)
    ("file-regular-p" "(file-regular-p ▮)" xah-elisp--ahf)
    ("file-relative-name" "(file-relative-name ▮)" xah-elisp--ahf)
    ("fillarray" "(fillarray ARRAY▮ 0)" xah-elisp--ahf)
    ("find-buffer-visiting" "(find-buffer-visiting FILENAME▮ &optional PREDICATE)" xah-elisp--ahf)
    ("find-file" "(find-file ▮)" xah-elisp--ahf)
    ("find-image" "(find-image SPECS▮)" xah-elisp--ahf)
    ("floor" "(floor ▮)" xah-elisp--ahf)
    ("font-lock-add-keywords" "(font-lock-add-keywords MODE▮ KEYWORDS &optional HOW)" xah-elisp--ahf)
    ("font-lock-fontify-buffer" "(font-lock-fontify-buffer ▮)" xah-elisp--ahf)
    ("format" "(format \"%s\" ▮)" xah-elisp--ahf)
    ("forward-char" "(forward-char ▮)" xah-elisp--ahf)
    ("forward-line" "(forward-line ▮)" xah-elisp--ahf)
    ("forward-word" "(forward-word ▮)" xah-elisp--ahf)
    ("fround" "(fround ▮)" xah-elisp--ahf)
    ("ftruncate" "(ftruncate ▮)" xah-elisp--ahf)
    ("funcall" "(funcall 'FUNCTION▮ &rest ARGUMENTS)" xah-elisp--ahf)
    ("function" "(function ▮)" xah-elisp--ahf)
    ("gap-position" "(gap-position)" xah-elisp--ahf)
    ("gap-size" "(gap-size)" xah-elisp--ahf)
    ("generate-new-buffer" "(generate-new-buffer NAME▮)" xah-elisp--ahf)
    ("generate-new-buffer" "(generate-new-buffer ▮)" xah-elisp--ahf)
    ("generate-new-buffer-name" "(generate-new-buffer-name STARTING-NAME▮ &optional IGNORE)" xah-elisp--ahf)
    ("get" "(get SYMBOL▮ 'PROPNAME)" xah-elisp--ahf)
    ("get-buffer" "(get-buffer BUFFER-OR-NAME▮)" xah-elisp--ahf)
    ("get-buffer-create" "(get-buffer-create BUFFER-OR-NAME▮)" xah-elisp--ahf)
    ("get-char-code-property" "(get-char-code-property CHAR▮ PROPNAME)" xah-elisp--ahf)
    ("get-char-property" "(get-char-property POSITION▮ PROP &optional OBJECT)" xah-elisp--ahf)
    ("get-char-property-and-overlay" "(get-char-property-and-overlay POSITION▮ PROP &optional)" xah-elisp--ahf)
    ("get-file-buffer" "(get-file-buffer FILENAME▮)" xah-elisp--ahf)
    ("get-pos-property" "(get-pos-property POSITION▮ PROP &optional OBJECT)" xah-elisp--ahf)
    ("get-text-property" "(get-text-property POS▮ PROP &optional OBJECT)" xah-elisp--ahf)
    ("gethash" "(gethash KEY▮ TABLE &optional DFLT)" xah-elisp--ahf)
    ("global-set-key" "(global-set-key (kbd \"C-▮\") 'COMMAND)" xah-elisp--ahf)
    ("goto-char" "(goto-char ▮)" xah-elisp--ahf)
    ("if" "(if ▮\n    (progn )\n  (progn )\n)" xah-elisp--ahf)
    ("image-flush" "(image-flush SPEC▮ &optional FRAME)" xah-elisp--ahf)
    ("image-load-path-for-library" "(image-load-path-for-library LIBRARY▮ IMAGE &optional PATH)" xah-elisp--ahf)
    ("image-size" "(image-size SPEC▮ &optional PIXELS FRAME)" xah-elisp--ahf)
    ("insert" "(insert ▮)" xah-elisp--ahf)
    ("insert-and-inherit" "(insert-and-inherit ▮)" xah-elisp--ahf)
    ("insert-before-markers-and-inherit" "(insert-before-markers-and-inherit ▮)" xah-elisp--ahf)
    ("insert-char" "(insert-char CHARACTER▮ &optional COUNT INHERIT)" xah-elisp--ahf)
    ("insert-file-contents" "(insert-file-contents ▮ &optional VISIT p1▮ p2 REPLACE)" xah-elisp--ahf)
    ("insert-image" "(insert-image IMAGE▮ &optional STRING AREA SLICE)" xah-elisp--ahf)
    ("insert-sliced-image" "(insert-sliced-image IMAGE▮ &optional STRING AREA ROWS COLS)" xah-elisp--ahf)
    ("interactive" "(interactive)" xah-elisp--ahf)
    ("kbd" "(kbd \"▮\")" xah-elisp--ahf)
    ("kill-append" "(kill-append STRING▮ BEFORE-P)" xah-elisp--ahf)
    ("kill-buffer" "(kill-buffer &optional BUFFER-OR-NAME▮)" xah-elisp--ahf)
    ("kill-buffer" "(kill-buffer ▮)" xah-elisp--ahf)
    ("kill-region" "(kill-region p1▮ p2 &optional REGION)" xah-elisp--ahf)
    ("lambda" "(lambda (x▮) BODY)" xah-elisp--ahf)
    ("last-buffer" "(last-buffer &optional BUFFER▮ VISIBLE-OK FRAME)" xah-elisp--ahf)
    ("left-char" "(left-char ▮)" xah-elisp--ahf)
    ("length" "(length ▮)" xah-elisp--ahf)
    ("let" "(let (▮)\n x\n)" xah-elisp--ahf)
    ("let*" "(let* (▮)\n x\n)" xah-elisp--ahf)
    ("line-beginning-position" "(line-beginning-position)" xah-elisp--ahf)
    ("line-end-position" "(line-end-position)" xah-elisp--ahf)
    ("list" "(list ▮)" xah-elisp--ahf)
    ("load" "(load FILE▮ &optional NOERROR NOMESSAGE NOSUFFIX MUST-SUFFIX)" xah-elisp--ahf)
    ("load-file" "(load-file FILE▮)" xah-elisp--ahf)
    ("looking-at" "(looking-at \"REGEXP▮\")" xah-elisp--ahf)
    ("looking-back" "(looking-back \"REGEXP▮\" LIMIT &optional GREEDY)" xah-elisp--ahf)
    ("make-directory" "(make-directory ▮ &optional PARENTS)" xah-elisp--ahf)
    ("make-hash-table" "(make-hash-table :test 'equal ▮ &rest KEYWORD-ARGS)" xah-elisp--ahf)
    ("make-indirect-buffer" "(make-indirect-buffer BASE-BUFFER▮ NAME &optional CLONE)" xah-elisp--ahf)
    ("make-list" "(make-list LENGTH▮ INIT)" xah-elisp--ahf)
    ("make-local-variable" "(make-local-variable ▮)" xah-elisp--ahf)
    ("make-string" "(make-string count character)" xah-elisp--ahf)
    ("make-vector" "(make-vector 5▮ 0)" xah-elisp--ahf)
    ("mapc" "(mapc \n(lambda (x▮) BODY)\n SEQUENCE)" xah-elisp--ahf)
    ("mapcar" "(mapcar \n(lambda (x▮) BODY)\n SEQUENCE)" xah-elisp--ahf)
    ("mapconcat" "(mapconcat FUNCTION▮ SEQUENCE SEPARATOR)" xah-elisp--ahf)
    ("maphash" "(maphash FUNCTION▮ TABLE)" xah-elisp--ahf)
    ("match-beginning" "(match-beginning N▮)" xah-elisp--ahf)
    ("match-data" "(match-data &optional INTEGERS▮ REUSE RESEAT)" xah-elisp--ahf)
    ("match-end" "(match-end N▮)" xah-elisp--ahf)
    ("match-string" "(match-string NUM▮ &optional STRING)" xah-elisp--ahf)
    ("max" "(max ▮)" xah-elisp--ahf)
    ("member" "(member ELT▮ LIST)" xah-elisp--ahf)
    ("member" "(member OBJECT▮ LIST)" xah-elisp--ahf)
    ("member-ignore-case" "(member-ignore-case OBJECT▮ LIST)" xah-elisp--ahf)
    ("memq" "(memq ELT▮ LIST)" xah-elisp--ahf)
    ("memql" "(memql OBJECT▮ LIST)" xah-elisp--ahf)
    ("message" "(message \"%s▮\" ARGS)" xah-elisp--ahf)
    ("narrow-to-region" "(narrow-to-region p1▮ p2)" xah-elisp--ahf)
    ("next-char-property-change" "(next-char-property-change POS &optional LIMIT)" xah-elisp--ahf)
    ("next-property-change" "(next-property-change POS &optional OBJECT LIMIT)" xah-elisp--ahf)
    ("next-single-char-property-change" "(next-single-char-property-change POS PROP &optional OBJECT LIMIT)" xah-elisp--ahf)
    ("next-single-property-change" "(next-single-property-change POS PROP &optional OBJECT LIMIT)" xah-elisp--ahf)
    ("not" "(not ▮)" xah-elisp--ahf)
    ("not-modified" "(not-modified &optional ARG▮)" xah-elisp--ahf)
    ("nth" "(nth N▮ LIST)" xah-elisp--ahf)
    ("null" "(null ▮)" xah-elisp--ahf)
    ("number-sequence" "(number-sequence FROM▮ &optional TO INC)" xah-elisp--ahf)
    ("number-to-string" "(number-to-string ▮)" xah-elisp--ahf)
    ("or" "(or ▮)" xah-elisp--ahf)
    ("other-buffer" "(other-buffer &optional BUFFER▮ VISIBLE-OK FRAME)" xah-elisp--ahf)
    ("point" "(point)" xah-elisp--ahf)
    ("point-max" "(point-max)" xah-elisp--ahf)
    ("point-min" "(point-min)" xah-elisp--ahf)
    ("pop" "(pop ▮)" xah-elisp--ahf)
    ("previous-char-property-change" "(previous-char-property-change POS &optional LIMIT)" xah-elisp--ahf)
    ("previous-property-change" "(previous-property-change POS &optional OBJECT LIMIT)" xah-elisp--ahf)
    ("previous-single-char-property-change" "(previous-single-char-property-change POS PROP &optional OBJECT LIMIT)" xah-elisp--ahf)
    ("previous-single-property-change" "(previous-single-property-change POS PROP &optional OBJECT LIMIT)" xah-elisp--ahf)
    ("prin1" "(prin1 ▮)" xah-elisp--ahf)
    ("prin1-to-string" "(prin1-to-string▮ OBJECT &optional NOESCAPE)" xah-elisp--ahf)
    ("princ" "(princ ▮)" xah-elisp--ahf)
    ("print" "(print ▮)" xah-elisp--ahf)
    ("prog1" "(prog1\n▮)" xah-elisp--ahf)
    ("prog2" "(prog2\n▮)" xah-elisp--ahf)
    ("progn" "(progn\n▮)" xah-elisp--ahf)
    ("propertize" "(propertize STRING▮ &rest PROPERTIES)" xah-elisp--ahf)
    ("push" "(push NEWELT▮ PLACE)" xah-elisp--ahf)
    ("push-mark" "(push-mark ▮&optional LOCATION NOMSG ACTIVATE)" xah-elisp--ahf)
    ("put" "(put 'SYMBOL▮ 'PROPNAME VALUE)" xah-elisp--ahf)
    ("put-image" "(put-image IMAGE▮ POS &optional STRING AREA)" xah-elisp--ahf)
    ("put-text-property" "(put-text-property p1▮ p2 PROP VALUE &optional OBJECT)" xah-elisp--ahf)
    ("puthash" "(puthash KEY▮ VALUE TABLE)" xah-elisp--ahf)
    ("random" "(random ▮)" xah-elisp--ahf)
    ("rassoc" "(rassoc KEY▮ LIST)" xah-elisp--ahf)
    ("rassoc" "(rassoc value▮ alist)" xah-elisp--ahf)
    ("rassq" "(rassq value▮ alist)" xah-elisp--ahf)
    ("rassq-delete-all" "(rassq-delete-all value▮ alist)" xah-elisp--ahf)
    ("re-search-backward" "(re-search-backward \"REGEXP▮\" &optional BOUND NOERROR COUNT)" xah-elisp--ahf)
    ("re-search-forward" "(re-search-forward \"REGEXP▮\" &optional BOUND NOERROR COUNT)" xah-elisp--ahf)
    ("read-directory-name" "(read-directory-name \"Dir▮:\" &optional DIR DEFAULT-DIRNAME MUSTMATCH INITIAL)" xah-elisp--ahf)
    ("read-file-name" "(read-file-name \"▮\" &optional DIR DEFAULT-FILENAME MUSTMATCH INITIAL PREDICATE)" xah-elisp--ahf)
    ("read-number" "(read-number \"Number▮:\" DEFAULT?)" xah-elisp--ahf)
    ("read-regexp" "(read-regexp \"Type regex▮:\" &optional DEFAULT-VALUE)" xah-elisp--ahf)
    ("read-string" "(read-string \"What▮:\" &optional INITIAL-INPUT HISTORY DEFAULT-VALUE INHERIT-INPUT-METHOD)" xah-elisp--ahf)
    ("regexp-opt" "(regexp-opt STRINGS▮ &optional PAREN)" xah-elisp--ahf)
    ("regexp-quote" "(regexp-quote ▮)" xah-elisp--ahf)
    ("region-active-p" "(region-active-p)" xah-elisp--ahf)
    ("region-beginning" "(region-beginning)" xah-elisp--ahf)
    ("region-end" "(region-end)" xah-elisp--ahf)
    ("remhash" "(remhash KEY▮ TABLE)" xah-elisp--ahf)
    ("remove" "(remove OBJECT▮ SEQUENCE)" xah-elisp--ahf)
    ("remove-images" "(remove-images p1▮ p2 &optional BUFFER)" xah-elisp--ahf)
    ("remove-list-of-text-properties" "(remove-list-of-text-properties p1▮ p2 LIST OF PROPERTIES &optional OBJECT)" xah-elisp--ahf)
    ("remove-text-properties" "(remove-text-properties p1▮ p2 PROPS &optional OBJECT)" xah-elisp--ahf)
    ("remq" "(remq OBJECT▮ LIST)" xah-elisp--ahf)
    ("rename-buffer" "(rename-buffer NEWNAME▮ &optional UNIQUE)" xah-elisp--ahf)
    ("rename-file" "(rename-file FILE▮ NEWNAME &optional OK-IF-ALREADY-EXISTS)" xah-elisp--ahf)
    ("repeat" "(repeat ▮)" xah-elisp--ahf)
    ("replace-match" "(replace-match NEWTEXT▮ &optional FIXEDCASE LITERAL \"STRING\" SUBEXP)" xah-elisp--ahf)
    ("replace-regexp" "(replace-regexp \"REGEXP▮\" TO-STRING &optional DELIMITED START END)" xah-elisp--ahf)
    ("replace-regexp-in-string" "(replace-regexp-in-string \"REGEXP▮\" REP \"STRING\" &optional FIXEDCASE LITERAL SUBEXP START)" xah-elisp--ahf)
    ("require" "(require ▮)" xah-elisp--ahf)
    ("restore-buffer-modified-p" "(restore-buffer-modified-p FLAG▮)" xah-elisp--ahf)
    ("reverse" "(reverse ▮)" xah-elisp--ahf)
    ("right-char" "(right-char ▮)" xah-elisp--ahf)
    ("round" "(round ▮)" xah-elisp--ahf)
    ("run-with-timer" "(run-with-timer SECS▮ REPEAT FUNCTION &rest ARGS)" xah-elisp--ahf)
    ("save-buffer" "(save-buffer &optional ARG▮)" xah-elisp--ahf)
    ("save-current-buffer" "(save-current-buffer ▮)" xah-elisp--ahf)
    ("save-excursion" "(save-excursion ▮)" xah-elisp--ahf)
    ("save-restriction" "(save-restriction ▮)" xah-elisp--ahf)
    ("search-backward" "(search-backward \"▮\" &optional BOUND NOERROR COUNT)" xah-elisp--ahf)
    ("search-backward-regexp" "(search-backward-regexp \"▮\" &optional BOUND NOERROR COUNT)" xah-elisp--ahf)
    ("search-forward" "(search-forward \"▮\" &optional BOUND NOERROR COUNT)" xah-elisp--ahf)
    ("search-forward-regexp" "(search-forward-regexp \"▮\" &optional BOUND NOERROR COUNT)" xah-elisp--ahf)
    ("set-buffer" "(set-buffer ▮)" xah-elisp--ahf)
    ("set-buffer-modified-p" "(set-buffer-modified-p FLAG▮)" xah-elisp--ahf)
    ("set-file-modes" "(set-file-modes ▮ MODE)" xah-elisp--ahf)
    ("set-mark" "(set-mark ▮)" xah-elisp--ahf)
    ("set-syntax-table" "(set-syntax-table ▮)" xah-elisp--ahf)
    ("set-text-properties" "(set-text-properties p1▮ p2 PROPS &optional OBJECT)" xah-elisp--ahf)
    ("set-visited-file-modtime" "(set-visited-file-modtime &optional TIME▮)" xah-elisp--ahf)
    ("set-visited-file-name" "(set-visited-file-name FILENAME▮ &optional NO-QUERY ALONG-WITH-FILE)" xah-elisp--ahf)
    ("setq" "(setq ▮)" xah-elisp--ahf)
    ("setq-default" "(setq-default x▮ VAL)" xah-elisp--ahf)
    ("shell-command" "(shell-command ▮ &optional OUTPUT-BUFFER ERROR-BUFFER)" xah-elisp--ahf)
    ("async-shell-command" "(async-shell-command ▮ &optional OUTPUT-BUFFER ERROR-BUFFER)" xah-elisp--ahf)

    ("shell-quote-argument" "(shell-quote-argument ▮)" xah-elisp--ahf)
    ("skip-chars-backward" "(skip-chars-backward \"▮\" &optional LIM)" xah-elisp--ahf)
    ("skip-chars-forward" "(skip-chars-forward \"▮\" &optional LIM)" xah-elisp--ahf)
    ("split-string" "(split-string ▮ &optional SEPARATORS OMIT-NULLS)" xah-elisp--ahf)
    ("start-process" "(start-process NAME BUFFER PROGRAM▮ &rest PROGRAM-ARGS)" xah-elisp--ahf)
    ("stc" "(string-to-char \"▮\")" xah-elisp--ahf)
    ("string-collate-equalp" "(string-collate-equalp string1▮ string2 &optional locale)" xah-elisp--ahf)
    ("string-collate-lessp" "(string-collate-lessp string1▮ string2 &optional locale)" xah-elisp--ahf)
    ("string-equal" "(string-equal str1▮ str2)" xah-elisp--ahf)
    ("string-greaterp" "(string-greaterp string1▮ string2)" xah-elisp--ahf)
    ("string-lessp" "(string-lessp string1▮ string2)" xah-elisp--ahf)
    ("string-match" "(string-match \"REGEXP▮\" \"STRING\" &optional START)" xah-elisp--ahf)
    ("string-match-p" "(string-match-p \"REGEXP▮\" \"STRING\" &optional START)" xah-elisp--ahf)
    ("string-prefix-p" "(string-prefix-p prefixstr▮ string2 &optional ignore-case)" xah-elisp--ahf)
    ("string-prefix-p" "(string-prefix-p string1▮ string2 &optional ignore-case)" xah-elisp--ahf)
    ("string-suffix-p" "(string-suffix-p suffix▮ string &optional ignore-case)" xah-elisp--ahf)
    ("string-suffix-p" "(string-suffix-p suffix▮ string &optional ignore-case)" xah-elisp--ahf)
    ("string-to-char" "(string-to-char \"▮\")" xah-elisp--ahf)
    ("string-to-number" "(string-to-number \"▮\")" xah-elisp--ahf)
    ("string=" "(string-equal str1▮ str2)" xah-elisp--ahf)
    ("stringp" "(stringp ▮)" xah-elisp--ahf)
    ("substring" "(substring STRING▮ FROM &optional TO)" xah-elisp--ahf)
    ("substring-no-properties" "(substring-no-properties ▮ FROM TO)" xah-elisp--ahf)
    ("switch-to-buffer" "(switch-to-buffer ▮ &optional NORECORD FORCE-SAME-WINDOW)" xah-elisp--ahf)
    ("terpri" "(terpri ▮)" xah-elisp--ahf)
    ("text-properties-at" "(text-properties-at POSITION▮ &optional OBJECT)" xah-elisp--ahf)
    ("text-property-any" "(text-property-any p1▮ p2 PROP VALUE &optional OBJECT)" xah-elisp--ahf)
    ("text-property-not-all" "(text-property-not-all p1▮ p2 PROP VALUE &optional OBJECT)" xah-elisp--ahf)
    ("thing-at-point" "(thing-at-point 'word▮ 'symbol 'list 'sexp 'defun 'filename 'url 'email 'sentence 'whitespace 'line 'number 'page)" xah-elisp--ahf)
    ("throw" "(throw 'TAG▮ VALUE)" xah-elisp--ahf)
    ("toggle-read-only" "(toggle-read-only &optional ARG▮)" xah-elisp--ahf)
    ("truncate" "(truncate ▮)" xah-elisp--ahf)
    ("unbury-buffer" "(unbury-buffer)" xah-elisp--ahf)
    ("unless" "(unless ▮)" xah-elisp--ahf)
    ("use-region-p" "(use-region-p)" xah-elisp--ahf)
    ("user-error" "(user-error \"%s▮\" &rest ARGS)" xah-elisp--ahf)
    ("vconcat" "(vconcat SEQUENCES▮)" xah-elisp--ahf)
    ("vector" "(vector ▮)" xah-elisp--ahf)
    ("verify-visited-file-modtime" "(verify-visited-file-modtime BUFFER▮)" xah-elisp--ahf)
    ("version<" "(version< \"27.1\" emacs-version)" xah-elisp--ahf )
    ("version<=" "(version<= \"27.1\" emacs-version)" xah-elisp--ahf )
    ("visited-file-modtime" "(visited-file-modtime)" xah-elisp--ahf)
    ("when" "(when ▮)" xah-elisp--ahf)
    ("while" "(while (< i▮ 9)\n  (setq i (1+ i)))" xah-elisp--ahf)
    ("widen" "(widen)" xah-elisp--ahf)
    ("widget-get" "(widget-get ▮)" xah-elisp--ahf)
    ("with-current-buffer" "(with-current-buffer BUFFER-OR-NAME▮ BODY)" xah-elisp--ahf)
    ("with-output-to-string" "(with-output-to-string BODY▮)" xah-elisp--ahf)
    ("with-output-to-temp-buffer" "(with-output-to-temp-buffer BUFNAME▮ &rest BODY)" xah-elisp--ahf)
    ("with-temp-buffer" "(with-temp-buffer ▮)" xah-elisp--ahf)
    ("with-temp-file" "(with-temp-file FILE▮ BODY)" xah-elisp--ahf)
    ("with-temp-file" "(with-temp-file FILE▮ BODY)" xah-elisp--ahf)
    ("write-char" "(write-char CHARACTER▮ &optional STREAM)" xah-elisp--ahf)
    ("write-file" "(write-file FILENAME▮ &optional CONFIRM)" xah-elisp--ahf)
    ("write-region" "(write-region (point-min) (point-max) FILENAME▮ &optional APPEND VISIT LOCKNAME MUSTBENEW)" xah-elisp--ahf)
    ("y-or-n-p" "(y-or-n-p \"PROMPT▮ \")" xah-elisp--ahf)
    ("yes-or-no-p" "(yes-or-no-p \"PROMPT▮ \")" xah-elisp--ahf)
    ;;
    )

  "Abbrev table for `xah-elisp-mode'"
  )

(abbrev-table-put xah-elisp-mode-abbrev-table :regexp "\\([_-*0-9A-Za-z]+\\)")
(abbrev-table-put xah-elisp-mode-abbrev-table :case-fixed t)
(abbrev-table-put xah-elisp-mode-abbrev-table :system t)
(abbrev-table-put xah-elisp-mode-abbrev-table :enable-function 'xah-elisp-abbrev-enable-function)


;; syntax coloring related

(defface xah-elisp-command-face
  ;; font-lock-type-face
  '((((class grayscale) (background light)) :foreground "Gray90" :weight bold)
    (((class grayscale) (background dark))  :foreground "DimGray" :weight bold)
    (((class color) (min-colors 88) (background light)) :foreground "ForestGreen")
    (((class color) (min-colors 88) (background dark))  :foreground "PaleGreen")
    (((class color) (min-colors 16) (background light)) :foreground "ForestGreen")
    (((class color) (min-colors 16) (background dark))  :foreground "PaleGreen")
    (((class color) (min-colors 8)) :foreground "green")
    (t :weight bold :underline t))
  "Font Lock mode face used to highlight type and classes."
  :group 'xah-elisp-mode)

;; (face-spec-set
;;  'xah-elisp-command-face
;;  '((((class grayscale) (background light)) :foreground "Gray90" :weight bold)
;;     (((class grayscale) (background dark))  :foreground "DimGray" :weight bold)
;;     (((class color) (min-colors 88) (background light)) :foreground "ForestGreen")
;;     (((class color) (min-colors 88) (background dark))  :foreground "PaleGreen")
;;     (((class color) (min-colors 16) (background light)) :foreground "ForestGreen")
;;     (((class color) (min-colors 16) (background dark))  :foreground "PaleGreen")
;;     (((class color) (min-colors 8)) :foreground "green")
;;     (t :weight bold :underline t))
;;  'face-defface-spec
;;  )

(defface xah-elisp-at-symbol
  '((t :foreground "red" :weight bold))
  "Face for @word."
  :group 'xah-elisp-mode )

(face-spec-set
 'xah-elisp-at-symbol
 '((t :foreground "red" :weight bold))
 'face-defface-spec
 )

(defface xah-elisp-dollar-symbol
  '((t :foreground "dark green" :weight bold))
   "Face for ξsymbol."
  :group 'xah-elisp-mode )

(face-spec-set
 'xah-elisp-dollar-symbol
 '((t :foreground "dark green" :weight bold))
 'face-defface-spec
 )

(defface xah-elisp-cap-variable
  '((t :foreground "firebrick" :weight bold))
  "Face for capitalized word."
  :group 'xah-elisp-mode )

(setq xah-elisp-font-lock-keywords
      (let (
            (dollarSymbol "\\_<$[-_?0-9A-Za-z]+" )
            (atSymbol "\\_<@[-_?0-9A-Za-z]+" )
            (capVars "\\_<[A-Z][-_?0-9A-Za-z]+" ))
        `(
          (,(regexp-opt xah-elisp-ampersand-words 'symbols) . font-lock-builtin-face)
          (,(regexp-opt xah-elisp-functions 'symbols) . font-lock-function-name-face)
          (,(regexp-opt xah-elisp-special-forms 'symbols) . font-lock-keyword-face)
          (,(regexp-opt xah-elisp-macros 'symbols) . font-lock-keyword-face)
          (,(regexp-opt xah-elisp-commands 'symbols) . 'xah-elisp-command-face)
          (,(regexp-opt xah-elisp-user-options 'symbols) . font-lock-variable-name-face)
          (,(regexp-opt xah-elisp-variables 'symbols) . font-lock-variable-name-face)
          (,dollarSymbol . 'xah-elisp-dollar-symbol)
          (,atSymbol . 'xah-elisp-at-symbol)
          (,capVars . 'xah-elisp-cap-variable)
          (":[a-z]+\\b" . font-lock-builtin-face))))


;; syntax table
(defvar xah-elisp-mode-syntax-table nil "Syntax table for `xah-elisp-mode'.")

(setq xah-elisp-mode-syntax-table
      (let ((synTable (make-syntax-table emacs-lisp-mode-syntax-table)))

        (modify-syntax-entry ?\* "w" synTable)
        (modify-syntax-entry ?\- "_" synTable)

        ;; (modify-syntax-entry ?\; "<" synTable)
        ;; (modify-syntax-entry ?\n ">" synTable)
        ;; (modify-syntax-entry ?` "'   " synTable)
        ;; (modify-syntax-entry ?' "'   " synTable)
        ;; (modify-syntax-entry ?, "'   " synTable)
        ;; (modify-syntax-entry ?@ "'   " synTable)

        synTable))


;; keybinding

(defvar xah-elisp-mode-map nil "Keybinding for `xah-elisp-mode'")
(progn
  (setq xah-elisp-mode-map (make-sparse-keymap))

  ;; painful to stick with emacs convention of not defining the key and get what i want
  (define-key xah-elisp-mode-map (kbd "TAB") 'xah-elisp-complete-or-indent)

  (progn
    (define-prefix-command 'xah-elisp-mode-no-chord-map)
    (define-key xah-elisp-mode-no-chord-map (kbd "u") 'xah-elisp-add-paren-around-symbol)
    (define-key xah-elisp-mode-no-chord-map (kbd "t") 'xah-elisp-prettify-root-sexp)
    (define-key xah-elisp-mode-no-chord-map (kbd "h") 'xah-elisp-remove-paren-pair)
    (define-key xah-elisp-mode-no-chord-map (kbd "p") 'xah-elisp-compact-parens)
    (define-key xah-elisp-mode-no-chord-map (kbd "c") 'xah-elisp-complete-symbol)
    )

  ;; define separate, so that user can override the lead key
  (define-key xah-elisp-mode-map (kbd "C-c C-c") xah-elisp-mode-no-chord-map)
  )


;; imenu
(defvar xah-elisp-imenu-generic-expression
  (list
   (list nil
	 (purecopy (concat "^\\s-*("
			   (eval-when-compile
			     (regexp-opt
			      '("defun" "defmacro"
                                ;; Elisp.
                                "defun*" "defsubst" "define-inline"
				"define-advice" "defadvice" "define-skeleton"
				"define-compilation-mode" "define-minor-mode"
				"define-global-minor-mode"
				"define-globalized-minor-mode"
				"define-derived-mode" "define-generic-mode"
				"ert-deftest"
				"cl-defun" "cl-defsubst" "cl-defmacro"
				"cl-define-compiler-macro" "cl-defgeneric"
				"cl-defmethod"
                                ;; CL.
				"define-compiler-macro" "define-modify-macro"
				"defsetf" "define-setf-expander"
				"define-method-combination"
                                ;; CLOS and EIEIO
				"defgeneric" "defmethod")
                              t))
			   "\\s-+\\(" lisp-mode-symbol-regexp "\\)"))
	 2)
   (list (purecopy "Variables")
	 (purecopy (concat "^\\s-*("
			   (eval-when-compile
			     (regexp-opt
			      '(;; Elisp
                                "defconst" "defcustom"
                                ;; CL
                                "defconstant"
				"defparameter" "define-symbol-macro")
                              t))
			   "\\s-+\\(" lisp-mode-symbol-regexp "\\)"))
	 2)
   ;; For `defvar'/`defvar-local', we ignore (defvar FOO) constructs.
   (list (purecopy "Variables")
	 (purecopy (concat "^\\s-*(defvar\\(?:-local\\)?\\s-+\\("
                           lisp-mode-symbol-regexp "\\)"
			   "[[:space:]\n]+[^)]"))
	 1)
   (list (purecopy "Types")
	 (purecopy (concat "^\\s-*("
			   (eval-when-compile
			     (regexp-opt
			      '(;; Elisp
                                "defgroup" "deftheme"
                                "define-widget" "define-error"
				"defface" "cl-deftype" "cl-defstruct"
                                ;; CL
                                "deftype" "defstruct"
				"define-condition" "defpackage"
                                ;; CLOS and EIEIO
                                "defclass")
                              t))
			   "\\s-+'?\\(" lisp-mode-symbol-regexp "\\)"))
	 2))

  "Imenu generic expression for Xah lisp mode.  See `imenu-generic-expression'.")



;;;###autoload
(define-derived-mode xah-elisp-mode prog-mode "∑elisp"
  "A major mode for emacs lisp.

Most useful command is `xah-elisp-complete-or-indent'.

Press TAB before word to pretty format current lisp expression tree.
Press TAB after word to complete.
Press SPACE to expand function name to template.

I also recommend the following setup:
 URL `http://ergoemacs.org/emacs/emacs_navigating_keys_for_brackets.html'
 URL `http://ergoemacs.org/emacs/modernization_mark-word.html'
 URL `http://ergoemacs.org/emacs/elisp_insert_brackets_by_pair.html'
 URL `http://ergoemacs.org/emacs/emacs_delete_backward_char_or_bracket_text.html'

home page:
URL `http://ergoemacs.org/emacs/xah-elisp-mode.html'

\\{xah-elisp-mode-map}"
  ;; (set-syntax-table emacs-lisp-mode-syntax-table)
  (setq font-lock-defaults '((xah-elisp-font-lock-keywords)))

  (setq-local comment-start "; ")
  (setq-local comment-end "")
  (setq-local comment-start-skip ";+ *")
  (setq-local comment-add 1) ;default to `;;' in comment-region
  (setq-local comment-column 2)
  (setq-local imenu-generic-expression xah-elisp-imenu-generic-expression)

  (setq-local indent-line-function 'lisp-indent-line)
  (setq-local tab-always-indent 'complete)

  ;; (add-function :before-until (local 'eldoc-documentation-function)
  ;;               #'elisp-eldoc-documentation-function)

  ;; when calling emacs's complete-symbol, follow convention. When pressing TAB, do xah way.
  (if (version< emacs-version "25.1.1")
      nil
    (progn
      ;; between GNU Emacs 24.5.1 and GNU Emacs 25.1.1, new is a elisp-mode.el at ~/apps/emacs-25.1/lisp/progmodes/elisp-mode.el
      ;; it seems it's extracted from lisp-mode.el at ~/apps/emacs-25.1/lisp/emacs-lisp/lisp-mode.el
      ;; however, there's no command named elisp-mode
      ;; 'elisp-completion-at-point is new, not in 24.5.1
      (require 'elisp-mode)
      (add-hook 'completion-at-point-functions 'elisp-completion-at-point nil 'local)))

  (make-local-variable 'abbrev-expand-function)
  (if (version< emacs-version "24.4")
      (add-hook 'abbrev-expand-functions 'xah-elisp-expand-abbrev nil t)
    (setq abbrev-expand-function 'xah-elisp-expand-abbrev))

  (abbrev-mode 1)

  (xah-elisp-display-page-break-as-line)
  (setq prettify-symbols-alist '(("lambda" . 955)))

  (if (version< emacs-version "25")
      (progn
        (make-local-variable 'ido-separator)
        (setq ido-separator "\n"))
    (progn
      (make-local-variable 'ido-decorations)
      (setf (nth 2 ido-decorations) "\n")))

  :group 'xah-elisp-mode
  )

(add-to-list 'auto-mode-alist '("\\.el\\'" . xah-elisp-mode))

(provide 'xah-elisp-mode)

;;; xah-elisp-mode.el ends here
