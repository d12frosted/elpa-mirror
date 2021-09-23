;;; zero-input.el --- Zero Chinese input method framework -*- lexical-binding: t -*-

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;; Version: 2.8.0
;; Package-Version: 20200405.1220
;; Package-Commit: 729da9f4b99acb744ee6974ed7f3d4e252fd19da
;; URL: https://gitlab.emacsos.com/sylecn/zero-el
;; Package-Requires: ((emacs "24.3") (s "1.2.0"))

;;; Commentary:

;; zero-input is a Chinese input method framework for Emacs, implemented as an
;; Emacs minor mode.
;;
;; zero-input-pinyin is bundled with zero, to use pinyin input method, add to
;; ~/.emacs file:
;;
;;   (require 'zero-input)
;;   (zero-input-set-default-im "pinyin")
;;   ;; Now you may bind a key to zero-input-mode to make it easy to
;;   ;; switch on/off the input method.
;;   (global-set-key (kbd "<f5>") 'zero-input-mode)
;;
;; Now in any Emacs buffer, you may press F5 and start typing pinyin string.
;;
;; zero-input supports Chinese punctuation mapping.  There are three modes,
;; none, basic, and full.  The default is basic mode, which only map most
;; essential punctuations.  You can cycle zero-punctuation-level in current
;; buffer by C-c , , You can change default Chinese punctuation level:
;;
;;   (setq-default zero-input-punctuation-level
;;     zero-input-punctuation-level-full)
;;
;; zero-input supports full-width mode.  You can toggle full-width mode in
;; current buffer by C-c , . You can enable full-width mode by default:
;;
;;   (setq-default zero-input-full-width-p t)
;;
;; For other features, you may check README file at
;; https://gitlab.emacsos.com/sylecn/zero-el/
;;
;; zero-input.el is auto-generated from multiple other files.  See
;; zero-input.el.in and build.py for details.  It's created because
;; package-lint doesn't support multi-file package yet.  See issue #111 at
;; https://github.com/purcell/package-lint/issues/111

;;; Code:

(require 'dbus)
(eval-when-compile
  (require 'cl-lib)
  (require 'cl-macs))
(require 'ring)
(require 's)

;; body of zero-input-panel.el

;;================
;; implementation
;;================


(defun zero-input-panel-error-handler (event error)
  "Handle dbus errors.

EVENT and ERROR are error-handler arguments."
  (when (or (string-equal "com.emacsos.zero.Panel"
			  (dbus-event-interface-name event))
	    (s-contains-p "com.emacsos.zero.Panel" (cadr error)))
    (error "Zero-Input-panel dbus failed: %S" (cadr error))))

(add-hook 'dbus-event-error-functions 'zero-input-panel-error-handler)

(defun zero-input-panel-async-call (method _handler &rest args)
  "Call METHOD on zero-input-panel service asynchronously.

This is a wrapper around `dbus-call-method-asynchronously'.
ARGS optional extra args to pass to the wrapped function."
  (apply 'dbus-call-method-asynchronously
	 :session
	 "com.emacsos.zero.Panel1"	; well known name
	 "/com/emacsos/zero/Panel1"	; object path
	 "com.emacsos.zero.Panel1.PanelInterface" ; interface name
	 method nil :timeout 500 args))

;;=========================
;; public utility function
;;=========================

(defun zero-input-alist-to-asv (hints)
  "Convert Lisp alist to dbus a{sv} data structure.

HINTS should be an alist of form '((k1 [v1type] v1) (k2 [v2type] v2)).

For example,
\(zero-input-alist-to-asv
  '((\"name\" \"foo\")
    (\"timeout\" :int32 10)))
=>
'(:array
  (:dict-entry \"name\" (:variant \"foo\"))
  (:dict-entry \"timeout\" (:variant :int32 10)))"
  (if (null hints)
      '(:array :signature "{sv}")
    (let ((result '(:array)))
      (dolist (item hints)
	(push (list :dict-entry (car item) (cons :variant (cdr item))) result))
      (reverse result))))

;;============
;; public API
;;============

(defun zero-input-panel-move (x y)
  "Move panel to specific coordinate (X, Y).
Origin (0, 0) is at screen top left corner."
  (zero-input-panel-async-call "Move" nil :int32 x :int32 y))

(defun zero-input-panel-show-candidates (preedit_str candidate_length candidates &optional hints)
  "Show CANDIDATES.
Argument PREEDIT_STR the preedit string.
Argument CANDIDATE_LENGTH how many candidates are in candidates list."
  (zero-input-panel-async-call "ShowCandidates" nil
			 :string preedit_str
			 :uint32 candidate_length
			 (or candidates '(:array))
			 (zero-input-alist-to-asv hints)))

(defun zero-input-panel-show ()
  "Show panel."
  (zero-input-panel-async-call "Show" nil))

(defun zero-input-panel-hide ()
  "Hide panel."
  (zero-input-panel-async-call "Hide" nil))

(defun zero-input-panel-quit ()
  "Quit panel application."
  (interactive)
  (zero-input-panel-async-call "Quit" nil))

(provide 'zero-input-panel)

;; body of zero-input-framework.el

;;==============
;; dependencies
;;==============


;;=======
;; utils
;;=======

;; this function is from ibus.el
(defun zero-input--ibus-compute-pixel-position (&optional pos window)
  "Return geometry of object at POS in WINDOW as a list like \(X Y H).
X and Y are pixel coordinates relative to top left corner of frame which
WINDOW is in.  H is the pixel height of the object.

Omitting POS and WINDOW means use current position and selected window,
respectively."
  (let* ((frame (window-frame (or window (selected-window))))
	 (posn (posn-at-point (or pos (window-point window)) window))
	 (line (cdr (posn-actual-col-row posn)))
	 (line-height (and line
			   (or (window-line-height line window)
			       (and (redisplay t)
				    (window-line-height line window)))))
	 (x-y (or (posn-x-y posn)
		  (let ((geom (pos-visible-in-window-p
			       (or pos (window-point window)) window t)))
		    (and geom (cons (car geom) (cadr geom))))
		  '(0 . 0)))
	 (ax (+ (car (window-inside-pixel-edges window))
		(car x-y)))
	 (ay (+ (cadr (window-pixel-edges window))
		(or (nth 2 line-height) (cdr x-y))))
	 (height (or (car line-height)
		     (with-current-buffer (window-buffer window)
		       (cond
			;; `posn-object-width-height' returns an incorrect value
			;; when the header line is displayed (Emacs bug #4426).
			((and posn
			      (null header-line-format))
			 (cdr (posn-object-width-height posn)))
			((and (bound-and-true-p text-scale-mode)
			      (not (zerop (with-no-warnings
					    text-scale-mode-amount))))
			 (round (* (frame-char-height frame)
				   (with-no-warnings
				     (expt text-scale-mode-step
					   text-scale-mode-amount)))))
			(t
			 (frame-char-height frame)))))))
    (list ax ay height)))

(defun zero-input-get-point-position ()
  "Return current point's position (x y).
Origin (0, 0) is at screen top left corner."
  (cl-destructuring-bind (x y line-height) (zero-input--ibus-compute-pixel-position)
    (cond
     ((functionp 'window-absolute-pixel-position)
      ;; introduced in emacs 26
      (cl-destructuring-bind (x . y) (window-absolute-pixel-position)
	(list x (+ y line-height))))
     ((functionp 'frame-edges)
      ;; introduced in emacs 25
      (cl-destructuring-bind (frame-x frame-y &rest rest)
	  (frame-edges nil 'inner-edges)
	(list (+ frame-x x) (+ frame-y y line-height))))
     (t
      ;; <= emacs 24, used guessed pixel size for tool-bar, menu-bar, WM title
      ;; bar. Since I can't get that from elisp.
      (list (+ (frame-parameter nil 'left)
	       (if (and (> (frame-parameter nil 'tool-bar-lines) 0)
			(eq (frame-parameter nil 'tool-bar-position) 'left))
		   96 0)
	       x)
	    (+ (frame-parameter nil 'top)
	       (if (and (> (frame-parameter nil 'tool-bar-lines) 0)
			(eq (frame-parameter nil 'tool-bar-position) 'top))
		   42 0)
	       (if (> (frame-parameter nil 'menu-bar-lines) 0) (+ 30 30) 0)
	       line-height
	       y))))))

(defun zero-input-cycle-list (lst item)
  "Return the object next to given ITEM in LST.

If item is the last object, return the first object in lst.
If item is not in lst, return nil."
  (let ((r (member item lst)))
    (cond
     ((null r) nil)
     (t (or (cadr r)
	    (car lst))))))

;;=====================
;; key logic functions
;;=====================

;; zero-input-el version
(defvar zero-input-version nil "Zero package version.")
(setq zero-input-version "2.8.0")

;; FSM state
(defconst zero-input--state-im-off 'IM-OFF)
(defconst zero-input--state-im-waiting-input 'IM-WAITING-INPUT)
(defconst zero-input--state-im-preediting 'IM-PREEDITING)

(defconst zero-input-punctuation-level-basic 'BASIC)
(defconst zero-input-punctuation-level-full 'FULL)
(defconst zero-input-punctuation-level-none 'NONE)

(defvar-local zero-input-im nil
  "Stores current input method.

If nil, the empty input method will be used.  In the empty input
method, only punctuation is handled.  Other keys are pass
through")
(defvar zero-input-ims nil
  "A list of registered input methods.")

(defvar-local zero-input-buffer nil
  "Stores the associated buffer.
this is used to help with buffer focus in/out events")

(defvar-local zero-input-state zero-input--state-im-off)
(defcustom zero-input-full-width-p nil
  "Set to t to enable full-width mode.
In full-width mode, commit ascii char will insert full-width char if there is a
corresponding full-width char.  This full-width char map is
independent from punctuation map.  You can change this via
`zero-input-toggle-full-width'"
  :group 'zero-input
  :safe t
  :type 'boolean)
(make-variable-buffer-local 'zero-input-full-width-p)

(defcustom zero-input-punctuation-basic-map
  '((?, "，")
    (?, "，")
    (?. "。")				; 0x3002
    (?? "？")
    (?! "！")
    (?\\ "、")				; 0x3001
    (?: "："))
  "Punctuation map used when `zero-input-punctuation-level' is not 'NONE."
  :group 'zero-input
  :type '(alist :key-type character :value-type (group string)))

(defcustom zero-input-punctuation-full-map
  '((?_ "——")
    (?< "《")				;0x300A
    (?> "》")				;0x300B
    (?\( "（")
    (?\) "）")
    (?\[ "【")				;0x3010
    (?\] "】")				;0x3011
    (?^ "……")
    (?~ "～")
    (?\; "；")
    (?\` "·")
    (?$ "￥"))
  "Additional punctuation map used when `zero-input-punctuation-level' is 'FULL."
  :group 'zero-input
  :type '(alist :key-type character :value-type (group string)))

(defcustom zero-input-punctuation-level zero-input-punctuation-level-basic
  "Default punctuation level.

Should be one of
`zero-input-punctuation-level-basic'
`zero-input-punctuation-level-full'
`zero-input-punctuation-level-none'"
  :group 'zero-input
  :safe t
  :type `(choice (const :tag "zero-input-punctuation-level-basic"
			,zero-input-punctuation-level-basic)
		 (const :tag "zero-input-punctuation-level-full"
			,zero-input-punctuation-level-full)
		 (const :tag "zero-input-punctuation-level-none"
			,zero-input-punctuation-level-none)))
(make-variable-buffer-local 'zero-input-punctuation-level)
(defvar zero-input-punctuation-levels (list zero-input-punctuation-level-basic
					    zero-input-punctuation-level-full
					    zero-input-punctuation-level-none)
  "Punctuation levels to use when `zero-input-cycle-punctuation-level'.")

(defvar-local zero-input-double-quote-flag nil
  "Non-nil means next double quote insert close quote.

Used when converting double quote to Chinese quote.
If nil, next double quote insert open quote.
Otherwise, next double quote insert close quote.")
(defvar-local zero-input-single-quote-flag nil
  "Non-nil means next single quote insert close quote.

Used when converting single quote to Chinese quote.
If nil, next single quote insert open quote.
Otherwise, next single quote insert close quote.")
(defvar-local zero-input-recent-insert-chars (make-ring 3)
  "Store recent insert characters.

Used to handle Chinese dot in digit input.
e.g. 1。3 could be converted to 1.3.")
(defcustom zero-input-auto-fix-dot-between-numbers t
  "Non-nil means zero should change 1。3 to 1.3, H。264 to H.264."
  :group 'zero-input
  :type 'boolean)
(defvar-local zero-input-preedit-str "")
(defvar-local zero-input-candidates nil)
(defcustom zero-input-candidates-per-page 10
  "How many candidates to show on each page.

Change will be effective only in new `zero-input-mode' buffer."
  :group 'zero-input
  :type 'integer)
(defvar-local zero-input-current-page 0 "Current page number.  count from 0.")
(defvar-local zero-input-initial-fetch-size 21
  "How many candidates to fetch for the first call to GetCandidates.

It's best set to (1+ (* zero-input-candidates-per-page N)) where
N is number of pages you want to fetch in initial fetch.")
;; zero-input-fetch-size is reset to 0 when preedit-str changes.
;; zero-input-fetch-size is set to fetch-size in build-candidates-async
;; complete-func lambda.
(defvar-local zero-input-fetch-size 0 "Last GetCandidates call's fetch-size.")
(defvar zero-input-previous-page-key ?\- "Previous page key.")
(defvar zero-input-next-page-key ?\= "Next page key.")

;;; concrete input method should define these functions and set them in the
;;; corresponding *-func variable.
(defun zero-input-build-candidates-default (_preedit-str _fetch-size)
  "Default implementation for `zero-input-build-candidates-func'."
  nil)
(defun zero-input-can-start-sequence-default (_ch)
  "Default implementation for `zero-input-can-start-sequence-func'."
  nil)
(defun zero-input-get-preedit-str-for-panel-default ()
  "Default implementation for `zero-input-get-preedit-str-for-panel-func'."
  zero-input-preedit-str)
(defvar-local zero-input-build-candidates-func
  'zero-input-build-candidates-default
  "Contains a function to build candidates from preedit-str.  The function accepts param preedit-str, fetch-size, returns candidate list.")
(defvar-local zero-input-build-candidates-async-func
  'zero-input-build-candidates-async-default
  "Contains a function to build candidates from preedit-str.  The function accepts param preedit-str, fetch-size, and a complete-func that should be called on returned candidate list.")
(defvar-local zero-input-can-start-sequence-func
  'zero-input-can-start-sequence-default
  "Contains a function to decide whether a char can start a preedit sequence.")
(defvar-local zero-input-handle-preedit-char-func
  'zero-input-handle-preedit-char-default
  "Contains a function to handle IM-PREEDITING state char insert.
The function should return t if char is handled.
This allow input method to override default logic.")
(defvar-local zero-input-get-preedit-str-for-panel-func
  'zero-input-get-preedit-str-for-panel-default
  "Contains a function that return preedit-str to show in zero-input-panel.")
(defvar-local zero-input-backspace-func
  'zero-input-backspace-default
  "Contains a function to handle <backward> char.")
(defvar-local zero-input-handle-preedit-char-func
  'zero-input-handle-preedit-char-default
  "Hanlde character insert in `zero-input--state-im-preediting' mode.")
(defvar-local zero-input-preedit-start-func 'nil
  "Called when enter `zero-input--state-im-preediting' state.")
(defvar-local zero-input-preedit-end-func 'nil
  "Called when leave `zero-input--state-im-preediting' state.")

(defvar zero-input-enable-debug nil
  "Whether to enable debug.
if t, `zero-input-debug' will output debug msg in *zero-input-debug* buffer")
(defvar zero-input-debug-buffer-max-size 30000
  "Max characters in *zero-input-debug* buffer.  If reached, first half data will be deleted.")

(defun zero-input-debug (string &rest objects)
  "Log debug message in *zero-input-debug* buffer.

STRING and OBJECTS are passed to `format'"
  (if zero-input-enable-debug
      (with-current-buffer (get-buffer-create "*zero-input-debug*")
	(goto-char (point-max))
	(insert (apply 'format string objects))
	(when (> (point) zero-input-debug-buffer-max-size)
	  (insert "removing old data\n")
	  (delete-region (point-min) (/ zero-input-debug-buffer-max-size 2))))))

;; (zero-input-debug "msg1\n")
;; (zero-input-debug "msg2: %s\n" "some obj")
;; (zero-input-debug "msg3: %s\n" 24)
;; (zero-input-debug "msg4: %s %s\n" 24 1)

(defun zero-input-add-recent-insert-char (ch)
  "Insert CH to `zero-input-recent-insert-chars'."
  ;; (cl-assert (and (characterp ch) (not (stringp ch))))
  (zero-input-debug "add char to recent chars ring: %s\n" ch)
  (ring-insert zero-input-recent-insert-chars ch))

(defun zero-input-enter-preedit-state ()
  "Config keymap when enter preedit state."
  (zero-input-enable-preediting-map)
  (if (functionp zero-input-preedit-start-func)
      (funcall zero-input-preedit-start-func)))

(defun zero-input-leave-preedit-state ()
  "Config keymap when leave preedit state."
  (zero-input-disable-preediting-map)
  (if (functionp zero-input-preedit-end-func)
      (funcall zero-input-preedit-end-func)))

(defun zero-input-set-state (state)
  "Set zero state to given STATE."
  (zero-input-debug "set state to %s\n" state)
  (setq zero-input-state state)
  (if (eq state zero-input--state-im-preediting)
      (zero-input-enter-preedit-state)
    (zero-input-leave-preedit-state)))

(defun zero-input-candidates-on-page (candidates)
  "Return candidates on current page for given CANDIDATES list."
  (cl-flet ((take (n lst)
	       "take the first n element from lst. if there is not
enough elements, return lst as it is."
	       (cl-loop
		for lst* = lst then (cdr lst*)
		for n* = n then (1- n*)
		until (or (zerop n*) (null lst*))
		collect (car lst*)))
	    (drop (n lst)
	       "drop the first n elements from lst"
	       (cl-loop
		for lst* = lst then (cdr lst*)
		for n* = n then (1- n*)
		until (or (zerop n*) (null lst*))
		finally (return lst*))))
    (take zero-input-candidates-per-page
	  (drop (* zero-input-candidates-per-page zero-input-current-page) candidates))))

(defun zero-input-show-candidates (&optional candidates)
  "Show CANDIDATES using zero-input-panel via IPC/RPC."
  (let ((candidates-on-page
	 (zero-input-candidates-on-page (or candidates
					    zero-input-candidates))))
    (cl-destructuring-bind (x y) (zero-input-get-point-position)
      (zero-input-panel-show-candidates
       (funcall zero-input-get-preedit-str-for-panel-func)
       (length candidates-on-page)
       candidates-on-page
       `(("in_emacs" t)
	 ("filename" ,(or (buffer-file-name) ""))
	 ("page_number" ,(1+ zero-input-current-page))
	 ("has_next_page" ,(or (> (length (or candidates zero-input-candidates)) (* zero-input-candidates-per-page (1+ zero-input-current-page))) (< zero-input-fetch-size (* zero-input-candidates-per-page (+ 2 zero-input-current-page)))))
	 ("has_previous_page" ,(> zero-input-current-page 0))
	 ("move_x" :int32 ,x)
	 ("move_y" :int32 ,y)))
      (zero-input-debug "candidates: %s\n" (s-join ", " candidates-on-page)))))

(defun zero-input-build-candidates (preedit-str fetch-size)
  "Build candidates list synchronously.

Try to find at least FETCH-SIZE number of candidates for PREEDIT-STR.
Return a list of candidates."
  ;; (zero-input-debug "zero-input-build-candidates\n")
  (unless (functionp zero-input-build-candidates-func)
    (signal 'wrong-type-argument (list 'functionp zero-input-build-candidates-func)))
  ;; Note that zero-input-candidates and zero-input-fetch-size is updated in
  ;; async complete callback. This function only care about building the
  ;; candidates.
  (funcall zero-input-build-candidates-func preedit-str fetch-size))

(defun zero-input-build-candidates-async-default (preedit-str fetch-size complete-func)
  "Build candidate list, when done show it via `zero-input-show-candidates'.

PREEDIT-STR the preedit-str.
FETCH-SIZE try to find at least this many candidates for preedit-str.
COMPLETE-FUNC the function to call when build candidates completes."
  ;; (zero-input-debug "zero-input-build-candidates-async-default\n")
  ;; default implementation just call sync version `zero-input-build-candidates'.
  (let ((candidates (zero-input-build-candidates preedit-str fetch-size)))
    ;; update cache to make SPC and digit key selection possible.
    (funcall complete-func candidates)))

(defvar zero-input-full-width-char-map nil
  "An alist that map half-width char to full-width char.")
(setq zero-input-full-width-char-map
      (cons
       ;; ascii 32 -> unicode 3000
       (cons ?\s ?\u3000)
       ;; ascii [33, 126] -> unicode [FF01, FF5E]
       (cl-loop
	for i from 33 to 126
	collect (cons (make-char 'ascii i)
		      (make-char 'unicode 0 255 (- i 32))))))

(defun zero-input-convert-ch-to-full-width (ch)
  "Convert half-width char CH to full-width.

If there is no full-width char for CH, return it unchanged."
  (let ((pair (assoc ch zero-input-full-width-char-map)))
    (if pair (cdr pair) ch)))

(defun zero-input-convert-str-to-full-width (s)
  "Convert each char in S to their full-width char if there is one."
  (concat (mapcar 'zero-input-convert-ch-to-full-width s)))

(defun zero-input-convert-str-to-full-width-maybe (s)
  "If in `zero-input-full-width-p', convert char in S to their full-width char; otherwise, return s unchanged."
  (if zero-input-full-width-p (zero-input-convert-str-to-full-width s) s))

(defun zero-input-insert-full-width-char (ch)
  "If in `zero-input-full-width-p', insert full-width char for given CH and return true, otherwise just return nil."
  (when zero-input-full-width-p
    (let ((full-width-ch (zero-input-convert-ch-to-full-width ch)))
      (insert full-width-ch)
      (zero-input-add-recent-insert-char full-width-ch)
      full-width-ch)))

(defun zero-input-convert-punctuation-basic (ch)
  "Convert punctuation for `zero-input-punctuation-level-basic'.

Return CH's Chinese punctuation if CH is converted.  Return nil otherwise."
  (cadr (assq ch zero-input-punctuation-basic-map)))

(defun zero-input-convert-punctuation-full (ch)
  "Convert punctuation for `zero-input-punctuation-level-full'.

Return CH's Chinese punctuation if CH is converted.  Return nil otherwise"
  (or (zero-input-convert-punctuation-basic ch)
      (cadr (assq ch zero-input-punctuation-full-map))
      (cl-case ch
	(?\" (setq zero-input-double-quote-flag (not zero-input-double-quote-flag))
	     (if zero-input-double-quote-flag "“" "”"))
	(?\' (setq zero-input-single-quote-flag (not zero-input-single-quote-flag))
	     (if zero-input-single-quote-flag "‘" "’")))))

(defun zero-input-convert-punctuation (ch)
  "Convert punctuation based on `zero-input-punctuation-level'.
Return CH's Chinese punctuation if CH is converted.  Return nil otherwise."
  (cond
   ((eq zero-input-punctuation-level zero-input-punctuation-level-basic)
    (zero-input-convert-punctuation-basic ch))
   ((eq zero-input-punctuation-level zero-input-punctuation-level-full)
    (zero-input-convert-punctuation-full ch))
   (t nil)))

(defun zero-input-handle-punctuation (ch)
  "If CH is a punctuation character, insert mapped Chinese punctuation and return true; otherwise, return false."
  (let ((str (zero-input-convert-punctuation ch)))
    (when str
      (insert str)
      (mapc #'zero-input-add-recent-insert-char str)
      t)))

(defun zero-input-append-char-to-preedit-str (ch)
  "Append char CH to preedit str, update and show candidate list."
  (setq zero-input-preedit-str
	(concat zero-input-preedit-str (make-string 1 ch)))
  (zero-input-debug "appended %c, preedit str is: %s\n" ch zero-input-preedit-str)
  (zero-input-preedit-str-changed))

(defun zero-input-can-start-sequence (ch)
  "Return t if char CH can start a preedit sequence."
  (if (functionp zero-input-can-start-sequence-func)
      (funcall zero-input-can-start-sequence-func ch)
    (error "`zero-input-can-start-sequence-func' is not a function")))

(defun zero-input-page-up ()
  "If not at first page, show candidates on previous page."
  (interactive)
  (when (> zero-input-current-page 0)
    (setq zero-input-current-page (1- zero-input-current-page))
    (zero-input-show-candidates)))

(defun zero-input-just-page-down ()
  "Just page down using existing candidates."
  (let ((len (length zero-input-candidates)))
    (when (> len (* zero-input-candidates-per-page (1+ zero-input-current-page)))
      (setq zero-input-current-page (1+ zero-input-current-page))
      (zero-input-debug "showing candidates on page %s\n" zero-input-current-page)
      (zero-input-show-candidates))))

(defun zero-input-page-down ()
  "If there is still candidates to be displayed, show candidates on next page."
  (interactive)
  (let ((len (length zero-input-candidates))
	(new-fetch-size (1+ (* zero-input-candidates-per-page (+ 2 zero-input-current-page)))))
    (zero-input-debug "decide whether to fetch more candidates, has %s candidates, last fetch size=%s, new-fetch-size=%s\n" len zero-input-fetch-size new-fetch-size)
    (if (and (< len new-fetch-size)
	     (< zero-input-fetch-size new-fetch-size))
	(progn
	  (zero-input-debug "will fetch more candidates")
	  (funcall zero-input-build-candidates-async-func
		   zero-input-preedit-str
		   new-fetch-size
		   #'(lambda (candidates)
		       (setq zero-input-candidates candidates)
		       (setq zero-input-fetch-size (max new-fetch-size
							(length candidates)))
		       (zero-input-just-page-down))))
      (zero-input-just-page-down))))

(defun zero-input-handle-preedit-char-default (ch)
  "Hanlde character insert in `zero-input--state-im-preediting' state.

CH is the char user has typed."
  (cond
   ((= ch ?\s)
    (zero-input-commit-first-candidate-or-preedit-str))
   ((and (>= ch ?0) (<= ch ?9))
    ;; 1 commit the 0th candidate
    ;; 2 commit the 1st candidate
    ;; ...
    ;; 0 commit the 9th candidate
    (unless (zero-input-commit-nth-candidate (mod (- (- ch ?0) 1) 10))
      (zero-input-append-char-to-preedit-str ch)))
   ((= ch zero-input-previous-page-key)
    (zero-input-page-up))
   ((= ch zero-input-next-page-key)
    (zero-input-page-down))
   (t (let ((str (zero-input-convert-punctuation ch)))
	(if str
	    (progn
	      (zero-input-set-state zero-input--state-im-waiting-input)
	      (zero-input-commit-first-candidate-or-preedit-str)
	      (insert str))
	  (zero-input-append-char-to-preedit-str ch))))))

(defun zero-input-self-insert-command (n)
  "Handle character `self-insert-command'.  This includes characters and digits.

N is the argument passed to `self-insert-command'."
  (interactive "p")
  (let ((ch (elt (this-command-keys-vector) 0)))
    (zero-input-debug "user typed: %c\n" ch)
    (cond
     ((eq zero-input-state zero-input--state-im-waiting-input)
      (if (zero-input-can-start-sequence ch)
	  (progn
	    (zero-input-debug "can start sequence, state=IM_PREEDITING\n")
	    (zero-input-set-state zero-input--state-im-preediting)
	    (zero-input-append-char-to-preedit-str ch))
	(zero-input-debug "cannot start sequence, state=IM_WAITING_INPUT\n")
	(unless (zero-input-handle-punctuation ch)
	  (unless (zero-input-insert-full-width-char ch)
	    (self-insert-command n)))))
     ((eq zero-input-state zero-input--state-im-preediting)
      (zero-input-debug "still preediting\n")
      (funcall zero-input-handle-preedit-char-func ch))
     (t
      (zero-input-debug "unexpected state: %s\n" zero-input-state)
      (self-insert-command n)))))

(defun zero-input-get-initial-fetch-size ()
  "Return initial fetch size."
  (cond
   ((<= zero-input-initial-fetch-size zero-input-candidates-per-page)
    (1+ zero-input-candidates-per-page))
   ((zerop (mod zero-input-initial-fetch-size zero-input-candidates-per-page))
    (1+ zero-input-initial-fetch-size))
   (t zero-input-initial-fetch-size)))

(defun zero-input-preedit-str-changed ()
  "Called when preedit str is changed and not empty.  Update and show candidate list."
  (setq zero-input-fetch-size 0)
  (setq zero-input-current-page 0)
  (let ((new-fetch-size (zero-input-get-initial-fetch-size)))
    (funcall zero-input-build-candidates-async-func
	     zero-input-preedit-str new-fetch-size
	     #'(lambda (candidates)
		 (setq zero-input-candidates candidates)
		 (setq zero-input-fetch-size (max new-fetch-size (length candidates)))
		 (zero-input-show-candidates candidates)))))

(defun zero-input-backspace-default ()
  "Handle backspace key in `zero-input--state-im-preediting' state."
  (let ((len (length zero-input-preedit-str)))
    (if (> len 1)
	(progn
	  (setq zero-input-preedit-str
		(substring zero-input-preedit-str 0 (1- len)))
	  (zero-input-preedit-str-changed))
      (zero-input-set-state zero-input--state-im-waiting-input)
      (zero-input-reset))))

(defun zero-input-backspace ()
  "Handle backspace key in `zero-input--state-im-preediting' state."
  (interactive)
  (unless (eq zero-input-state zero-input--state-im-preediting)
    (error "Error: zero-input-backspace called in non preediting state"))
  (zero-input-debug "zero-input-backspace\n")
  (funcall zero-input-backspace-func))

(defun zero-input-commit-text (text)
  "Commit given TEXT, reset preedit str, hide candidate list."
  (zero-input-debug "commit text: %s\n" text)
  (insert text)
  ;; insert last 3 characters (if possible) to zero-input-recent-insert-chars
  (mapc #'zero-input-add-recent-insert-char
	(if (>= (length text) 3) (substring text -3) text))
  (setq zero-input-preedit-str "")
  (setq zero-input-candidates nil)
  (setq zero-input-current-page 0)
  (zero-input-hide-candidate-list))

(defun zero-input-return ()
  "Handle RET key press in `zero-input--state-im-preediting' state."
  (interactive)
  (unless (eq zero-input-state zero-input--state-im-preediting)
    (error "Error: zero-input-return called in non preediting state"))
  (zero-input-debug "zero-input-return\n")
  (zero-input-set-state zero-input--state-im-waiting-input)
  (zero-input-commit-text (zero-input-convert-str-to-full-width-maybe zero-input-preedit-str)))

(defun zero-input-commit-nth-candidate (n)
  "Commit Nth candidate and return true if it exists; otherwise, return false."
  (let ((candidate (nth n (zero-input-candidates-on-page zero-input-candidates))))
    (if candidate
	(progn
	  (zero-input-set-state zero-input--state-im-waiting-input)
	  (zero-input-commit-text candidate)
	  t)
      nil)))

(defun zero-input-commit-preedit-str ()
  "Commit current preedit-str."
  (zero-input-set-state zero-input--state-im-waiting-input)
  (zero-input-commit-text (zero-input-convert-str-to-full-width-maybe zero-input-preedit-str)))

(defun zero-input-commit-first-candidate-or-preedit-str ()
  "Commit first candidate if there is one, otherwise commit preedit str."
  (unless (zero-input-commit-nth-candidate 0)
    (zero-input-commit-preedit-str)))

(defun zero-input-hide-candidate-list ()
  "Hide candidate list."
  (zero-input-panel-hide)
  (zero-input-debug "hide candidate list\n"))

(defun zero-input-reset ()
  "Reset zero states."
  (interactive)
  (zero-input-debug "zero-input-reset\n")
  (zero-input-set-state zero-input--state-im-waiting-input)
  (setq zero-input-preedit-str "")
  (setq zero-input-candidates nil)
  (setq zero-input-current-page 0)
  (while (not (ring-empty-p zero-input-recent-insert-chars))
    (ring-remove zero-input-recent-insert-chars))
  (zero-input-hide-candidate-list))

(defun zero-input-focus-in ()
  "A hook function, run when focus in a buffer."
  (when (eq zero-input-state zero-input--state-im-preediting)
    (zero-input-show-candidates zero-input-candidates)
    (zero-input-enter-preedit-state)))

(defun zero-input-focus-out ()
  "A hook function, run when focus out a buffer."
  (when (eq zero-input-state zero-input--state-im-preediting)
    (zero-input-hide-candidate-list)
    (zero-input-leave-preedit-state)))

(defun zero-input-buffer-list-changed ()
  "A hook function, run when buffer list has changed.  This includes user has switched buffer."
  (if (eq (car (buffer-list)) zero-input-buffer)
      (zero-input-focus-in)))

;;============
;; minor mode
;;============

(defvar zero-input-mode-map
  (let ((map (make-sparse-keymap)))
    ;; build zero-input-prefix-map
    (defvar zero-input-prefix-map (define-prefix-command 'zero-input-prefix-map))
    (let ((bindings '(("," zero-input-cycle-punctuation-level)
		      ("." zero-input-toggle-full-width))))
      (dolist (b bindings)
	(define-key zero-input-prefix-map (car b) (cadr b))))
    ;; mount zero-input-prefix-map in C-c , prefix key.
    (define-key map (kbd "C-c ,") zero-input-prefix-map)

    ;; other keybindings
    (define-key map [remap self-insert-command]
      'zero-input-self-insert-command)
    map)
  "Keymap for `zero-input-mode'.")

(defun zero-input-enable-preediting-map ()
  "Enable preediting keymap in `zero-input-mode-map'."
  (zero-input-debug "zero-input-enable-preediting-map\n")
  (define-key zero-input-mode-map (kbd "<backspace>") 'zero-input-backspace)
  (define-key zero-input-mode-map (kbd "RET") 'zero-input-return)
  (define-key zero-input-mode-map (kbd "<escape>") 'zero-input-reset))

(defun zero-input-disable-preediting-map ()
  "Disable preediting keymap in `zero-input-mode-map'."
  (zero-input-debug "zero-input-disable-preediting-map\n")
  (define-key zero-input-mode-map (kbd "<backspace>") nil)
  (define-key zero-input-mode-map (kbd "RET") nil)
  (define-key zero-input-mode-map (kbd "<escape>") nil))

(defun zero-input-modeline-string ()
  "Build `zero-input-mode' modeline string aka lighter.

If full-width mode is enabled, show ZeroF;
Otherwise, show Zero."
  (if zero-input-full-width-p " ZeroF" " Zero"))

;;;###autoload
(define-minor-mode zero-input-mode
  "a Chinese input method framework written as an emacs minor mode.

\\{zero-input-mode-map}"
  nil
  (:eval (zero-input-modeline-string))
  zero-input-mode-map
  ;; local variables and variable init
  (make-local-variable 'zero-input-candidates-per-page)
  (make-local-variable 'zero-input-full-width-mode)
  (zero-input-reset)
  (zero-input-set-im zero-input-im)
  ;; hooks
  (add-hook 'focus-in-hook 'zero-input-focus-in)
  (add-hook 'focus-out-hook 'zero-input-focus-out)
  (setq zero-input-buffer (current-buffer))
  (add-hook 'post-self-insert-hook #'zero-input-post-self-insert-command nil t)
  (add-hook 'buffer-list-update-hook 'zero-input-buffer-list-changed))

(defun zero-input-post-self-insert-command (&optional ch)
  "Run after a regular `self-insert-command' is run by zero-input.

Argument CH the character that was inserted."
  ;; `zero-input-auto-fix-dot-between-numbers' is the only feature that
  ;; requires this ring, so for now if it is nil, no need to maintain the ring
  ;; for `self-insert-command'.
  (if (and zero-input-mode zero-input-auto-fix-dot-between-numbers)
      (let ((ch (or ch (elt (this-command-keys-vector) 0))))
	(zero-input-add-recent-insert-char ch)
	;; if user typed "[0-9A-Z]。[0-9 ]", auto convert “。” to “.”
	(cl-flet ((my-digit-char-p (ch) (and (>= ch ?0) (<= ch ?9)))
		  (my-capital-letter-p (ch) (and (>= ch ?A) (<= ch ?Z))))
	  ;; ring-ref index 2 is least recent inserted char.
	  (when (and (let ((ch (ring-ref zero-input-recent-insert-chars 2)))
		       (or (my-digit-char-p ch)
			   (my-capital-letter-p ch)))
		     (equal ?。 (ring-ref zero-input-recent-insert-chars 1))
		     (let ((ch (ring-ref zero-input-recent-insert-chars 0)))
		       (or (my-digit-char-p ch)
			   (eq ch ?\s))))
	    (delete-char -2)
	    (insert "." (car (ring-elements zero-input-recent-insert-chars))))))))

;;==================
;; IM developer API
;;==================

(defun zero-input-register-im (im-name im-functions-alist)
  "(Re)register an input method in zero.

After registration, you can use `zero-input-set-default-im' and
`zero-input-set-im' to select input method to use.

IM-NAME should be a symbol.
IM-FUNCTIONS-ALIST should be a list of form
  '((:virtual-function-name . implementation-function-name))

virtual functions                   corresponding variable
===========================================================================
:build-candidates                   `zero-input-build-candidates-func'
:can-start-sequence                 `zero-input-can-start-sequence-func'
:handle-preedit-char                `zero-input-handle-preedit-char-func'
:get-preedit-str-for-panel          `zero-input-get-preedit-str-for-panel-func'
:handle-backspace                   `zero-input-backspace-func'
:init                               nil
:shutdown                           nil
:preedit-start                      `zero-input-preedit-start-func'
:preedit-end                        `zero-input-preedit-end-func'

registered input method is saved in `zero-input-ims'"
  ;; add or replace entry in `zero-input-ims'
  (unless (stringp im-name)
    (signal 'wrong-type-argument (list 'stringp im-name)))
  (setq zero-input-ims (delq (assoc im-name zero-input-ims) zero-input-ims))
  (setq zero-input-ims (push (cons im-name im-functions-alist) zero-input-ims)))

;; Built-in empty input method. It only handles Chinese punctuation.
(zero-input-register-im "empty" nil)

;;============
;; public API
;;============

(defun zero-input-toggle-full-width ()
  "Toggle `zero-input-full-width-p' on/off."
  (interactive)
  (setq zero-input-full-width-p (not zero-input-full-width-p))
  (message (if zero-input-full-width-p
	       "Enabled full-width mode"
	     "Enabled half-width mode")))

(defun zero-input-set-punctuation-level (level)
  "Set `zero-input-punctuation-level'.

LEVEL the level to set to."
  (interactive)
  (if (not (member level (list zero-input-punctuation-level-basic
			       zero-input-punctuation-level-full
			       zero-input-punctuation-level-none)))
      (error "Level not supported: %s" level)
    (setq zero-input-punctuation-level level)))

(defun zero-input-set-punctuation-levels (levels)
  "Set `zero-input-punctuation-levels'.

`zero-input-cycle-punctuation-level' will cycle current
`zero-input-punctuation-level' among defined LEVELS."
  (dolist (level levels)
    (if (not (member level (list zero-input-punctuation-level-basic
				 zero-input-punctuation-level-full
				 zero-input-punctuation-level-none)))
	(error "Level not supported: %s" level)))
  (setq zero-input-punctuation-levels levels))

(defun zero-input-cycle-punctuation-level ()
  "Cycle `zero-input-punctuation-level' among `zero-input-punctuation-levels'."
  (interactive)
  (setq zero-input-punctuation-level
	(zero-input-cycle-list zero-input-punctuation-levels zero-input-punctuation-level))
  (message "punctuation level set to %s" zero-input-punctuation-level))

;;;###autoload
(defun zero-input-set-im (&optional im-name)
  "Select zero input method for current buffer.

IM-NAME (a string) should be a registered input method in zero-input."
  (interactive)
  ;; when switch away from an IM, run last IM's :shutdown function.
  (if zero-input-im
      (let ((shutdown-func (cdr (assq :shutdown (cdr (assoc zero-input-im zero-input-ims))))))
	(if (functionp shutdown-func)
	    (funcall shutdown-func))))
  (cond
   ((null im-name)
    ;; TODO is there an easier way to provide auto complete in mini buffer?
    ;; I used a recursive call to the same function.
    (let ((im-name-str (completing-read "Set input method to: " zero-input-ims)))
      (if (s-blank? im-name-str)
	  (error "Input method name is required")
	(zero-input-set-im im-name-str))))
   ((symbolp im-name)
    ;; symbol is allowed for backward compatibility.
    (zero-input-set-im (symbol-name im-name)))
   (t (let* ((im-slot (assoc im-name zero-input-ims))
	     (im-functions (cdr im-slot)))
	(if im-slot
	    (progn
	      (zero-input-debug "switching to %s input method" im-name)
	      ;; TODO create a macro to reduce code duplication and human
	      ;; error.
	      ;;
	      ;; TODO do some functionp check for the slot functions. if check
	      ;; fail, keep (or revert to) the old IM.
	      (setq zero-input-build-candidates-func
		    (or (cdr (assq :build-candidates im-functions))
			'zero-input-build-candidates-default))
	      (setq zero-input-build-candidates-async-func
		    (or (cdr (assq :build-candidates-async im-functions))
			'zero-input-build-candidates-async-default))
	      (setq zero-input-can-start-sequence-func
		    (or (cdr (assq :can-start-sequence im-functions))
			'zero-input-can-start-sequence-default))
	      (setq zero-input-handle-preedit-char-func
		    (or (cdr (assq :handle-preedit-char im-functions))
			'zero-input-handle-preedit-char-default))
	      (setq zero-input-get-preedit-str-for-panel-func
		    (or (cdr (assq :get-preedit-str-for-panel im-functions))
			'zero-input-get-preedit-str-for-panel-default))
	      (setq zero-input-backspace-func
		    (or (cdr (assq :handle-backspace im-functions))
			'zero-input-backspace-default))
	      (setq zero-input-preedit-start-func
		    (cdr (assq :preedit-start im-functions)))
	      (setq zero-input-preedit-end-func
		    (cdr (assq :preedit-end im-functions)))
	      (unless (functionp zero-input-backspace-func)
		(signal 'wrong-type-argument
			(list 'functionp zero-input-backspace-func)))
	      ;; when switch to a IM, run its :init function
	      (let ((init-func (cdr (assq :init im-functions))))
		(if (functionp init-func)
		    (funcall init-func)))
	      (setq zero-input-im im-name))
	  (error "Input method %S not registered in zero" im-name))))))

;;;###autoload
(defun zero-input-set-default-im (im-name)
  "Set given IM-NAME as default zero input method."
  ;; symbol is allowed for backward compatibility.
  (unless (or (stringp im-name) (symbolp im-name))
    (signal 'wrong-type-argument (list 'string-or-symbolp im-name)))
  (let ((im-name-str (if (symbolp im-name) (symbol-name im-name) im-name)))
    (setq-default zero-input-im im-name-str)
    (unless (assoc im-name-str zero-input-ims)
      (warn "Input method %s is not registered with zero-input" im-name-str))))

;;;###autoload
(defun zero-input-on ()
  "Turn on `zero-input-mode'."
  (interactive)
  (zero-input-mode 1))

(defun zero-input-off ()
  "Turn off `zero-input-mode'."
  (interactive)
  (zero-input-mode -1))

;;;###autoload
(define-obsolete-function-alias 'zero-input-toggle 'zero-input-mode
  "Zero-input v2.0.2" "Toggle `zero-input-mode'.")

(provide 'zero-input-framework)

;; body of zero-input-table.el

;;==============
;; dependencies
;;==============


;;===============================
;; basic data and emacs facility
;;===============================

(defvar zero-input-table-table nil
  "The table used by zero-input-table input method, map string to string.")
(defvar zero-input-table-sequence-initials nil
  "Used in `zero-input-table-can-start-sequence'.")

;;=====================
;; key logic functions
;;=====================

(defun zero-input-table-sort-key (lhs rhs)
  "A predicate function to sort candidates.  Return t if LHS should sort before RHS."
  (string< (car lhs) (car rhs)))

(defun zero-input-table-build-candidates (preedit-str &optional _fetch-size)
  "Build candidates by looking up PREEDIT-STR in `zero-input-table-table'."
  (mapcar 'cdr (sort (cl-remove-if-not #'(lambda (pair) (string-prefix-p preedit-str (car pair))) zero-input-table-table) 'zero-input-table-sort-key)))

;; (defun zero-input-table-build-candidates-async (preedit-str)
;;   "build candidate list, when done show it via `zero-input-table-show-candidates'"
;;   (zero-input-table-debug "building candidate list\n")
;;   (let ((candidates (zero-input-table-build-candidates preedit-str)))
;;     ;; update cache to make SPC and digit key selection possible.
;;     (setq zero-input-table-candidates candidates)
;;     (zero-input-table-show-candidates candidates)))

(defun zero-input-table-can-start-sequence (ch)
  "Return t if char CH can start a preedit sequence."
  (member (make-string 1 ch) zero-input-table-sequence-initials))

;;===============================
;; register IM to zero framework
;;===============================

(zero-input-register-im
 "zero-input-table"
 '((:build-candidates . zero-input-table-build-candidates)
   (:can-start-sequence . zero-input-table-can-start-sequence)))

;;============
;; public API
;;============

(defun zero-input-table-set-table (alist)
  "Set the conversion table.

the ALIST should be a list of (key . value) pairs.  when user type
\(part of) key, the IM will show all matching value.

To use demo data, you can call:
\(zero-input-table-set-table
 \\='((\"phone\" . \"18612345678\")
   (\"mail\" . \"foo@example.com\")
   (\"map\" . \"https://ditu.amap.com/\")
   (\"m\" . \"https://msdn.microsoft.com/en-us\")
   (\"address\" . \"123 Happy Street\")))"
  (setq zero-input-table-table alist)
  (setq zero-input-table-sequence-initials
	(delete-dups (mapcar #'(lambda (pair) (substring (car pair) 0 1))
			     zero-input-table-table))))

(provide 'zero-input-table)

;; body of zero-input-pinyin-service.el

;;================
;; implementation
;;================


(defvar zero-input-pinyin-service-service-name
  "com.emacsos.zero.ZeroPinyinService1")
(defvar zero-input-pinyin-service-path
  "/com/emacsos/zero/ZeroPinyinService1")
(defvar zero-input-pinyin-service-interface
  "com.emacsos.zero.ZeroPinyinService1.ZeroPinyinServiceInterface")
(defvar zero-input-pinyin-fuzzy-flag 0)

(defun zero-input-pinyin-service-error-handler (event error)
  "Handle dbus errors.

EVENT, ERROR are arguments passed to the handler."
  (when (or (string-equal zero-input-pinyin-service-service-name
			  (dbus-event-interface-name event))
	    (s-contains-p zero-input-pinyin-service-service-name (cadr error)))
    (error "`zero-input-pinyin-service' dbus failed: %S" (cadr error))))

(add-hook 'dbus-event-error-functions 'zero-input-pinyin-service-error-handler)

(defun zero-input-pinyin-service-async-call (method handler &rest args)
  "Call METHOD on `zero-input-pinyin-service' asynchronously.
This is a wrapper around `dbus-call-method-asynchronously'.
Argument HANDLER the handler function.
Optional argument ARGS extra arguments to pass to the wrapped function."
  (apply 'dbus-call-method-asynchronously
	 :session zero-input-pinyin-service-service-name
	 zero-input-pinyin-service-path
	 zero-input-pinyin-service-interface
	 method handler :timeout 1000 args))

(defun zero-input-pinyin-service-call (method &rest args)
  "Call METHOD on `zero-input-pinyin-service' synchronously.
This is a wrapper around `dbus-call-method'.
Optional argument ARGS extra arguments to pass to the wrapped function."
  (apply 'dbus-call-method
	 :session zero-input-pinyin-service-service-name
	 zero-input-pinyin-service-path
	 zero-input-pinyin-service-interface
	 method :timeout 1000 args))

;;============
;; public API
;;============

(defun zero-input-pinyin-service-get-candidates (preedit-str fetch-size)
  "Get candidates for pinyin in PREEDIT-STR synchronously.

preedit-str the preedit-str, should be pure pinyin string
FETCH-SIZE try to fetch this many candidates or more"
  (zero-input-pinyin-service-call "GetCandidatesV2" :string preedit-str :uint32 fetch-size :uint32 zero-input-pinyin-fuzzy-flag))

(defun zero-input-pinyin-service-get-candidates-async (preedit-str fetch-size get-candidates-complete)
  "Get candidates for pinyin in PREEDIT-STR asynchronously.

PREEDIT-STR the preedit string, should be pure pinyin string.
FETCH-SIZE try to fetch this many candidates or more.
GET-CANDIDATES-COMPLETE the async handler function."
  (zero-input-pinyin-service-async-call
   "GetCandidatesV2" get-candidates-complete :string preedit-str :uint32 fetch-size :uint32 zero-input-pinyin-fuzzy-flag))

(defun zero-input-pinyin-candidate-pinyin-indices-to-dbus-format (candidate_pinyin_indices)
  "Convert CANDIDATE_PINYIN_INDICES to Emacs dbus format."
  (let (result)
    (push :array result)
    ;; (push :signature result)
    ;; (push "(ii)" result)
    (dolist (pypair candidate_pinyin_indices)
      (push (list :struct :int32 (cl-first pypair) :int32 (cl-second pypair))
	    result))
    (reverse result)))

(defun zero-input-pinyin-service-commit-candidate-async (candidate candidate_pinyin_indices)
  "Commit candidate asynchronously.

CANDIDATE the candidate user selected.
CANDIDATE_PINYIN_INDICES the candidate's pinyin shengmu and yunmu index."
  ;; don't care about the result, so no callback.
  (zero-input-pinyin-service-async-call
   "CommitCandidate" nil
   :string candidate
   (zero-input-pinyin-candidate-pinyin-indices-to-dbus-format candidate_pinyin_indices)))

(defun zero-input-pinyin-service-delete-candidates-async (candidate delete-candidate-complete)
  "Delete CANDIDATE asynchronously.

DELETE-CANDIDATE-COMPLETE the async handler function."
  (zero-input-pinyin-service-async-call
   "DeleteCandidate" delete-candidate-complete :string candidate))

(defun zero-input-pinyin-service-quit ()
  "Quit panel application."
  (zero-input-pinyin-service-async-call "Quit" nil))

(provide 'zero-input-pinyin-service)

;; body of zero-input-pinyin.el

;;==============
;; dependencies
;;==============


;;===============================
;; basic data and emacs facility
;;===============================

(defcustom zero-input-pinyin-fuzzy-flag 0
  "Non-nil means enable fuzzy pinyin when calling zero pinyin service.

Fuzzy pinyin means some shengmu and some yunmu could be used
interchangeably, such as zh <-> z, l <-> n.

For supported values, please see zero-input-pinyin-service dbus
interface xml comment for GetCandidatesV2 method fuzzy_flag param.

You can find the xml file locally at
/usr/share/dbus-1/interfaces/\
com.emacsos.zero.ZeroPinyinService1.ZeroPinyinServiceInterface.xml
or online at
https://gitlab.emacsos.com/sylecn/zero-pinyin-service/\
blob/master/com.emacsos.zero.ZeroPinyinService1.ZeroPinyinServiceInterface.xml"
  :group 'zero-input-pinyin
  :type 'integer)
(defvar zero-input-pinyin-use-async-fetch nil
  "Non-nil means use async dbus call to get candidates.")
(setq zero-input-pinyin-use-async-fetch nil)

(defvar-local zero-input-pinyin-state nil
  "Zero-input-pinyin internal state.  could be nil or
`zero-input-pinyin--state-im-partial-commit'.")
(defconst zero-input-pinyin--state-im-partial-commit 'IM-PARTIAL-COMMIT)

(defvar zero-input-pinyin-used-preedit-str-lengths nil
  "Accompany `zero-input-candidates', marks how many preedit-str chars are used for each candidate.")
(defvar zero-input-pinyin-candidates-pinyin-indices nil
  "Store GetCandidates dbus method candidates_pinyin_indices field.")
(defvar zero-input-pinyin-pending-str "")
(defvar zero-input-pinyin-pending-preedit-str "")
(defvar zero-input-pinyin-pending-pinyin-indices nil
  "Store `zero-input-pinyin-pending-str' corresponds pinyin indices.")

;;=====================
;; key logic functions
;;=====================

(defun zero-input-pinyin-reset ()
  "Reset states."
  (setq zero-input-pinyin-state nil)
  (setq zero-input-pinyin-used-preedit-str-lengths nil)
  (setq zero-input-pinyin-pending-str "")
  (setq zero-input-pinyin-pending-preedit-str ""))

(defun zero-input-pinyin-init ()
  "Called when this im is turned on."
  (zero-input-pinyin-reset))

(defun zero-input-pinyin-preedit-start ()
  "Called when enter `zero-input--state-im-preediting' state."
  (define-key zero-input-mode-map [remap digit-argument] 'zero-input-digit-argument))

(defun zero-input-pinyin-preedit-end ()
  "Called when leave `zero-input--state-im-preediting' state."
  (define-key zero-input-mode-map [remap digit-argument] nil))

(defun zero-input-pinyin-shutdown ()
  "Called when this im is turned off."
  (define-key zero-input-mode-map [remap digit-argument] nil))

(defun zero-input-pinyin-build-candidates (preedit-str fetch-size)
  "Synchronously build candidates list.

PREEDIT-STR the preedit string.
FETCH-SIZE fetch at least this many candidates if possible.

Return candidates list"
  (zero-input-debug "zero-input-pinyin building candidate list synchronously\n")
  (let ((result (zero-input-pinyin-service-get-candidates preedit-str fetch-size)))
    ;; update zero-input-candidates and zero-input-fetch-size is done in async
    ;; complete callback. This function only care about building the
    ;; candidates and updating zero-input-pinyin specific.
    (setq zero-input-pinyin-used-preedit-str-lengths (cl-second result))
    (setq zero-input-pinyin-candidates-pinyin-indices (cl-third result))
    (cl-first result)))

(defun zero-input-pinyin-build-candidates-async (preedit-str fetch-size complete-func)
  "Asynchronously build candidate list, when done call complete-func on it.

PREEDIT-STR the preedit string.
FETCH-SIZE fetch at least this many candidates if possible.
COMPLETE-FUNC the callback function when async call completes.  it's called with
              fetched candidates list as parameter."
  (zero-input-debug "zero-input-pinyin building candidate list asynchronously\n")
  (zero-input-pinyin-service-get-candidates-async
   preedit-str
   fetch-size
   #'(lambda (candidates matched_preedit_str_lengths candidates_pinyin_indices)
       (setq zero-input-candidates candidates)
       (setq zero-input-fetch-size (max fetch-size (length candidates)))
       (setq zero-input-pinyin-used-preedit-str-lengths matched_preedit_str_lengths)
       (setq zero-input-pinyin-candidates-pinyin-indices candidates_pinyin_indices)
       ;; Note: with dynamic binding, this command result in (void-variable
       ;; complete-func) error.
       (funcall complete-func candidates))))

(defun zero-input-pinyin-can-start-sequence (ch)
  "Return t if char CH can start a preedit sequence."
  (and (>= ch ?a)
       (<= ch ?z)
       (not (= ch ?i))
       (not (= ch ?u))
       (not (= ch ?v))))

(defun zero-input-pinyin-build-candidates-unified (preedit-str fetch-size complete-func)
  "Build candidate list, when done call complete-func on it.

This may call sync or async dbus method depending on
`zero-input-pinyin-use-async-fetch'.

PREEDIT-STR the preedit string.
FETCH-SIZE fetch at least this many candidates if possible.
COMPLETE-FUNC the callback function when sync/async call completes.
              it's called with fetched candidates list as parameter."
  (if zero-input-pinyin-use-async-fetch
      (zero-input-pinyin-build-candidates-async
       preedit-str fetch-size complete-func)
    (let ((candidates (zero-input-pinyin-build-candidates
		       preedit-str fetch-size)))
      (setq zero-input-candidates candidates)
      (setq zero-input-fetch-size (max fetch-size (length candidates)))
      (funcall complete-func candidates))))

(defun zero-input-pinyin-pending-preedit-str-changed ()
  "Update zero states when pending preedit string changed."
  (setq zero-input-fetch-size 0)
  (setq zero-input-current-page 0)
  (let ((fetch-size (zero-input-get-initial-fetch-size))
	(preedit-str zero-input-pinyin-pending-preedit-str))
    (zero-input-pinyin-build-candidates-unified
     preedit-str fetch-size
     #'zero-input-show-candidates)))

(defun zero-input-pinyin-commit-nth-candidate (n)
  "Commit Nth candidate and return true if it exists, otherwise, return false."
  (let* ((n-prime (+ n (* zero-input-candidates-per-page zero-input-current-page)))
	 (candidate (nth n-prime zero-input-candidates))
	 (used-len (when candidate
		     (nth n-prime zero-input-pinyin-used-preedit-str-lengths))))
    (when candidate
      (zero-input-debug
       "zero-input-pinyin-commit-nth-candidate\n    n=%s candidate=%s used-len=%s zero-input-pinyin-pending-preedit-str=%S\n"
       n candidate used-len zero-input-pinyin-pending-preedit-str)
      (cond
       ((null zero-input-pinyin-state)
	(if (= used-len (length zero-input-preedit-str))
	    (progn
	      (zero-input-debug "commit in full\n")
	      (zero-input-set-state zero-input--state-im-waiting-input)
	      (zero-input-commit-text candidate)
	      (zero-input-pinyin-service-commit-candidate-async
	       candidate
	       (nth n-prime zero-input-pinyin-candidates-pinyin-indices))
	      t)
	  (zero-input-debug "partial commit, in partial commit mode now.\n")
	  (setq zero-input-pinyin-state zero-input-pinyin--state-im-partial-commit)
	  (setq zero-input-pinyin-pending-str candidate)
	  (setq zero-input-pinyin-pending-preedit-str (substring zero-input-preedit-str used-len))
	  (setq zero-input-pinyin-pending-pinyin-indices
		(nth n-prime zero-input-pinyin-candidates-pinyin-indices))
	  (zero-input-pinyin-pending-preedit-str-changed)
	  t))
       ((eq zero-input-pinyin-state zero-input-pinyin--state-im-partial-commit)
	(if (= used-len (length zero-input-pinyin-pending-preedit-str))
	    (progn
	      (zero-input-debug "finishes partial commit\n")
	      (setq zero-input-pinyin-state nil)
	      (zero-input-set-state zero-input--state-im-waiting-input)
	      (zero-input-commit-text (concat zero-input-pinyin-pending-str candidate))
	      (zero-input-pinyin-service-commit-candidate-async
	       (concat zero-input-pinyin-pending-str candidate)
	       (append zero-input-pinyin-pending-pinyin-indices
		       (nth n-prime zero-input-pinyin-candidates-pinyin-indices)))
	      t)
	  (zero-input-debug "continue partial commit\n")
	  (setq zero-input-pinyin-pending-str (concat zero-input-pinyin-pending-str candidate))
	  (setq zero-input-pinyin-pending-preedit-str (substring zero-input-pinyin-pending-preedit-str used-len))
	  (setq zero-input-pinyin-pending-pinyin-indices
		(append zero-input-pinyin-pending-pinyin-indices
			(nth n-prime zero-input-pinyin-candidates-pinyin-indices)))
	  (zero-input-pinyin-service-commit-candidate-async
	   zero-input-pinyin-pending-str
	   zero-input-pinyin-pending-pinyin-indices)
	  (zero-input-pinyin-pending-preedit-str-changed)
	  t))
       (t (error "Unexpected zero-input-pinyin-state: %s" zero-input-pinyin-state))))))

(defun zero-input-pinyin-commit-first-candidate-or-preedit-str ()
  "Commit first candidate if there is one, otherwise, commit preedit string."
  (unless (zero-input-pinyin-commit-nth-candidate 0)
    (zero-input-commit-preedit-str)))

(defun zero-input-pinyin-commit-first-candidate-in-full ()
  "Commit first candidate and return t if it consumes all preedit-str.
Otherwise, just return nil."
  (let ((candidate (nth 0 (zero-input-candidates-on-page zero-input-candidates)))
	(used-len (nth (* zero-input-candidates-per-page zero-input-current-page) zero-input-pinyin-used-preedit-str-lengths)))
    (when candidate
      (cond
       ((null zero-input-pinyin-state)
	(when (= used-len (length zero-input-preedit-str))
	  (zero-input-set-state zero-input--state-im-waiting-input)
	  (zero-input-commit-text candidate)
	  t))
       ((eq zero-input-pinyin-state zero-input-pinyin--state-im-partial-commit)
	(when (= used-len (length zero-input-pinyin-pending-preedit-str))
	  (setq zero-input-pinyin-state nil)
	  (zero-input-set-state zero-input--state-im-waiting-input)
	  (zero-input-commit-text (concat zero-input-pinyin-pending-str candidate))
	  t))
       (t (error "Unexpected zero-input-pinyin-state: %s" zero-input-pinyin-state))))))

(defun zero-input-pinyin-page-down ()
  "Handle page down for zero-input-pinyin.

This is different from zero-input-framework because I need to support partial commit"
  (let ((len (length zero-input-candidates))
	(new-fetch-size (1+ (* zero-input-candidates-per-page (+ 2 zero-input-current-page)))))
    ;; (zero-input-debug
    ;;  "fetch more candidates? on page %s, has %s candidates, last-fetch-size=%s, new-fetch-size=%s\n"
    ;;  zero-input-current-page len zero-input-fetch-size new-fetch-size)
    (if (and (< len new-fetch-size)
	     (< zero-input-fetch-size new-fetch-size))
	(let ((preedit-str (if (eq zero-input-pinyin-state
				   zero-input-pinyin--state-im-partial-commit)
			       zero-input-pinyin-pending-preedit-str
			     zero-input-preedit-str)))
	  (zero-input-debug
	   "will fetch more candidates new-fetch-size=%s\n" new-fetch-size)
	  (zero-input-pinyin-build-candidates-unified
	   preedit-str
	   new-fetch-size
	   #'(lambda (_candidates)
	       (zero-input-just-page-down))))
      (zero-input-debug "won't fetch more candidates\n")
      (zero-input-just-page-down))))

(defun zero-input-pinyin-handle-preedit-char (ch)
  "Hanlde character insert in `zero-input--state-im-preediting' state.
Override `zero-input-handle-preedit-char-default'.

CH the character user typed."
  (cond
   ((= ch ?\s)
    (zero-input-pinyin-commit-first-candidate-or-preedit-str))
   ((and (>= ch ?0) (<= ch ?9))
    ;; 1 commit the 0th candidate
    ;; 2 commit the 1st candidate
    ;; ...
    ;; 0 commit the 9th candidate
    (unless (zero-input-pinyin-commit-nth-candidate (mod (- (- ch ?0) 1) 10))
      (zero-input-append-char-to-preedit-str ch)
      (setq zero-input-pinyin-state nil)))
   ((= ch zero-input-previous-page-key)
    (zero-input-handle-preedit-char-default ch))
   ((= ch zero-input-next-page-key)
    (zero-input-pinyin-page-down))
   (t (let ((str (zero-input-convert-punctuation ch)))
	;; ?' is used as pinyin substring separator, never auto commit on ?'
	;; insert when pre-editing.
	(if (and str (not (eq ch ?')))
	    (when (zero-input-pinyin-commit-first-candidate-in-full)
	      (zero-input-set-state zero-input--state-im-waiting-input)
	      (insert str))
	  (setq zero-input-pinyin-state nil)
	  (zero-input-append-char-to-preedit-str ch))))))

(defun zero-input-pinyin-get-preedit-str-for-panel ()
  "Return the preedit string that should show in panel."
  (if (eq zero-input-pinyin-state zero-input-pinyin--state-im-partial-commit)
      (concat zero-input-pinyin-pending-str zero-input-pinyin-pending-preedit-str)
    zero-input-preedit-str))

(defun zero-input-pinyin-preedit-str-changed ()
  "Start over for candidate selection process."
  (setq zero-input-pinyin-state nil)
  (zero-input-preedit-str-changed))

(defun zero-input-pinyin-backspace ()
  "Handle backspace key in `zero-input--state-im-preediting' state."
  (if (eq zero-input-pinyin-state zero-input-pinyin--state-im-partial-commit)
      (zero-input-pinyin-preedit-str-changed)
    (zero-input-backspace-default)))

(defun zero-input-pinyin-delete-candidate (digit)
  "Tell backend to delete candidate at DIGIT position.

DIGIT is the digit key used to select nth candidate.
DIGIT 1 means delete 1st candidate.
DIGIT 2 means delete 2st candidate.
...
DIGIT 0 means delete 10th candidate."
  (let ((candidate (nth (mod (- digit 1) 10)
			(zero-input-candidates-on-page zero-input-candidates))))
    (when candidate
      (zero-input-pinyin-service-delete-candidates-async
       candidate 'zero-input-pinyin-preedit-str-changed))))

(defun zero-input-digit-argument ()
  "Allow C-<digit> to DeleteCandidate in `zero-input--state-im-preediting' state."
  (interactive)
  (unless (eq zero-input-state zero-input--state-im-preediting)
    (error "`zero-input-digit-argument' called in non preediting state"))
  (if (memq 'control (event-modifiers last-command-event))
      (let* ((char (if (integerp last-command-event)
		       last-command-event
		     (get last-command-event 'ascii-character)))
	     (digit (- (logand char ?\177) ?0)))
	(zero-input-pinyin-delete-candidate digit))))

;;===============================
;; register IM to zero framework
;;===============================

(defun zero-input-pinyin-register-im ()
  "Register pinyin input method in zero framework."
  (zero-input-register-im
   "pinyin"
   (append
    (if zero-input-pinyin-use-async-fetch
	'((:build-candidates-async . zero-input-pinyin-build-candidates-async))
      nil)
    '((:build-candidates . zero-input-pinyin-build-candidates)
      (:can-start-sequence . zero-input-pinyin-can-start-sequence)
      (:handle-preedit-char . zero-input-pinyin-handle-preedit-char)
      (:get-preedit-str-for-panel . zero-input-pinyin-get-preedit-str-for-panel)
      (:handle-backspace . zero-input-pinyin-backspace)
      (:init . zero-input-pinyin-init)
      (:shutdown . zero-input-pinyin-shutdown)
      (:preedit-start . zero-input-pinyin-preedit-start)
      (:preedit-end . zero-input-pinyin-preedit-end)))))

(zero-input-pinyin-register-im)

;;============
;; public API
;;============

(defun zero-input-pinyin-enable-async ()
  "Use async call to fetch candidates."
  (interactive)
  (setq zero-input-pinyin-use-async-fetch t)
  (zero-input-pinyin-register-im)
  (message "Enabled async mode"))

(defun zero-input-pinyin-disable-async ()
  "Use sync call to fetch candidates."
  (interactive)
  (setq zero-input-pinyin-use-async-fetch nil)
  (zero-input-pinyin-register-im)
  (message "Disabled async mode"))

(provide 'zero-input-pinyin)


(provide 'zero-input)

;;; zero-input.el ends here
