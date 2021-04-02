;;; read-aloud.el --- A simple interface to TTS engines  -*- lexical-binding: t; -*-

;; Author: Alexander Gromnitsky <alexander.gromnitsky@gmail.com>
;; Version: 0.0.2
;; Package-Version: 20160923.500
;; Package-Commit: c662366226abfb07204ab442b4f853ed85438d8a
;; Package-Requires: ((emacs "24.4"))
;; Keywords: multimedia
;; URL: https://github.com/gromnitsky/read-aloud.el

;; This file is not part of GNU Emacs.

;;; License:

;; MIT

;;; Commentary:

;; This package uses an external TTS engine (like flite) to pronounce
;; the word at or near point, the selected region or a whole buffer.

;;; Code:

(defvar read-aloud-engine "speech-dispatcher")
(defvar read-aloud-engines
  '("speech-dispatcher"			; Linux/FreeBSD only
    (cmd "spd-say" args ("-e" "-w") kill "spd-say -S")
    "flite"				; Cygwin?
    (cmd "flite" args nil)
    "jampal"				; Windows
    (cmd "cscript" args ("C:\\Program Files\\Jampal\\ptts.vbs" "-r" "5"))
    "say"				; macOS
    (cmd "say" args nil)
    ))

(defvar read-aloud-max 160)		; chars
(defface read-aloud-text-face '((t :inverse-video t))
  "For highlighting the text that is being read")



(require 'cl-lib)
(require 'subr-x)

(defvar read-aloud-word-hist '())	; (*-current-word) uses it
(defconst read-aloud--logbufname "*Read-Aloud Log*")

;; this should be in cl-defstruct
(defconst read-aloud--c-pr nil)
(defconst read-aloud--c-buf nil)
(defconst read-aloud--c-bufpos nil)
(defconst read-aloud--c-locked nil)
(defconst read-aloud--c-overlay nil)

(defun read-aloud--log(msg &optional args)
  (let ((buf (get-buffer-create read-aloud--logbufname)))
    (with-current-buffer buf
      (goto-char (point-max))
      (insert-before-markers (format (concat msg "\n") args))
      )))

(defun read-aloud-test ()
  "Open a new tmp buffer, insert a string, try to read it."
  (let ((buf (get-buffer-create "*Read-Aloud Test*")))

    (with-current-buffer buf
      (erase-buffer)
      (insert "Here lies the body of William Jay,
Who died maintaining his right of way--
He was right, dead right, as he speed along,
But he's just as dead as if he were wrong."))

    ;; show our logs
    (switch-to-buffer read-aloud--logbufname)
    (goto-char (point-max))

    (read-aloud--u-switch-to-buffer buf)
    (goto-char (point-min))

    (setq read-aloud--c-buf buf)
    (setq read-aloud--c-bufpos 1)
    (read-aloud-buf)))

;;;###autoload
(defun read-aloud-change-engine()
  "Select another TTS engine."
  (interactive)
  (setq read-aloud-engine
	(ido-completing-read
	 "read aloud with: "
	 (cl-loop for (key _) on read-aloud-engines by 'cddr
		  collect key)
	 nil nil nil nil read-aloud-engine
	 )))

(defun read-aloud--cmd ()
  (or (plist-get (lax-plist-get read-aloud-engines read-aloud-engine) 'cmd)
      (user-error "Failed to get the default TTS engine")) )

(defun read-aloud--args ()
  (plist-get (lax-plist-get read-aloud-engines read-aloud-engine) 'args))

(defun read-aloud--valid-str-p (str)
  (and str (not (equal "" (string-trim str)))))

(defun read-aloud--overlay-rm()
  (when read-aloud--c-overlay
    (delete-overlay read-aloud--c-overlay)
    (setq read-aloud--c-overlay nil)))

(defun read-aloud--overlay-make(beg end)
  (when (and beg end)
    (setq read-aloud--c-overlay (make-overlay beg end))
    (overlay-put read-aloud--c-overlay 'face 'read-aloud-text-face) ))

(defun read-aloud--reset()
  "Reset internal state."
  (setq read-aloud--c-pr nil)
  (setq read-aloud--c-buf nil)
  (setq read-aloud--c-bufpos nil)
  (setq read-aloud--c-locked nil)

  (read-aloud--overlay-rm)
  (read-aloud--log "RESET"))

(cl-defun read-aloud--string(str source)
  "Open an async process, feed its stdin with STR. SOURCE is an
arbitual string like 'buffer', 'word' or 'selection'."
  (unless (read-aloud--valid-str-p str) (cl-return-from read-aloud--string))

  (let ((process-connection-type nil)) ; (start-process) requires this

    (if read-aloud--c-locked (error "Read-aloud is LOCKED"))

    (setq read-aloud--c-locked source)
    (condition-case err
	(setq read-aloud--c-pr
	      (apply 'start-process "read-aloud" nil
		     (read-aloud--cmd) (read-aloud--args)))
      (error
       (read-aloud--reset)
       (user-error "External TTS engine failed to start: %s"
		   (error-message-string err))) )

    (set-process-sentinel read-aloud--c-pr 'read-aloud--sentinel)
    (setq str (concat (string-trim str) "\n"))
    (read-aloud--log "Sending: `%s`" str)
    (process-send-string read-aloud--c-pr str)
    (process-send-eof read-aloud--c-pr)
    ))

(defun read-aloud--sentinel (process event)
  (let ((source read-aloud--c-locked))

    (setq event (string-trim event))
    (if (equal event "finished")
	(progn
	  (read-aloud--overlay-rm)
	  (setq read-aloud--c-locked nil)
	  (cond
	   ((equal source "buffer") (read-aloud-buf))
	   ((equal source "word") t)	  ; do nothing
	   ((equal source "selection") t) ; do nothing
	   (t (error "Unknown source: %s" source))) )

      ;; else
      (read-aloud--reset)
      (user-error "%s ended w/ the event: %s" process event)
      )))

;;;###autoload
(defun read-aloud-stop ()
  "Ask a TTS engine to stop."
  (interactive)
  (kill-process read-aloud--c-pr)

  ;; if a tts engine has a separate step to switch itself off, use it
  (let ((c (plist-get (lax-plist-get read-aloud-engines read-aloud-engine) 'kill)))
    (when c
      (start-process-shell-command "read-aloud-kill" read-aloud--logbufname c)))

  (read-aloud--log "INTERRUPTED BY USER"))

;;;###autoload
(cl-defun read-aloud-buf()
  "Read the current buffer, highlighting words along the
read. Run it again to stop reading."
  (interactive)

  (when read-aloud--c-locked
    (read-aloud-stop)
    (cl-return-from read-aloud-buf))

  (unless read-aloud--c-buf (setq read-aloud--c-buf (current-buffer)))
  (unless read-aloud--c-bufpos (setq read-aloud--c-bufpos (point)))

  (let (tb)
    (with-current-buffer read-aloud--c-buf
      (when (eobp)
	(read-aloud--log "END OF BUFFER")
	(read-aloud--reset)
	(cl-return-from read-aloud-buf))

      (setq tb (read-aloud--grab-text read-aloud--c-buf read-aloud--c-bufpos))
      (unless tb
	(progn
	  (read-aloud--log "SPACES AT THE END OF BUFFER")
	  (read-aloud--reset)
	  (cl-return-from read-aloud-buf)))

      ;; highlight text
      (read-aloud--overlay-make (plist-get tb 'beg) (plist-get tb 'end))

      (goto-char (plist-get tb 'end))
      (read-aloud--string (plist-get tb 'text) "buffer")

      (setq read-aloud--c-bufpos (plist-get tb 'end))
      )))

(cl-defun read-aloud--grab-text(buf point)
  "Return (text \"omglol\" beg 10 end 20) plist or nil on
eof. BUF & POINT are the starting location for the job."
  (let (max t2 p pstart chunks pchunk)

    (with-current-buffer buf
      (save-excursion
	(goto-char point)
	(skip-chars-forward "[\\-,.:!;[:space:]\r\n]")

	(setq max (+ (point) read-aloud-max))
	(if (> max (point-max)) (setq max (point-max)))
	(setq t2 (buffer-substring-no-properties (point) max))

	(if (string-empty-p (string-trim-right t2))
	    ;; we have spaces at the end of buffer, there is nothing to grab
	    (cl-return-from read-aloud--grab-text nil))

	(setq pstart (point))

	(unless (= max (point-max))
	  (progn
	    ;; look for the 1st non-space in `t` from the end & cut
	    ;; off that part
	    (setq p (string-match "[[:space:]\r\n]"
				  (read-aloud--u-str-reverse t2)) )
	    (if p (setq t2 (substring t2 0 (- (length t2) p 1))) )))

	(setq chunks
	      (split-string t2 "[,.:!;]\\|\\(-\\|\n\\|\r\n\\)\\{2,\\}" t))
	(if chunks
	    (progn
	      (search-forward (car chunks))
	      (setq pchunk (point))
	      (search-backward (car chunks))
	      (setq pstart (point))
	      (setq t2 (buffer-substring-no-properties pstart pchunk)) ))

	(read-aloud--log "text grab: `%s`" t2)
	`(text ,t2
	       beg ,pstart
	       end ,(+ pstart (length t2)))
	))))

(cl-defun read-aloud--current-word()
  "Pronounce a word under the pointer. If under there is rubbish,
ask user for an additional input."
  (let* ((cw (read-aloud--u-current-word))
	 (word (nth 2 cw)))

    (unless (and word (string-match "[[:alnum:]]" word))
      ;; maybe we should share the hist list w/ `wordnut-completion-hist`?
      (setq word (read-string "read aloud: " word 'read-aloud-word-hist)) )

    (read-aloud--overlay-make (nth 0 cw) (nth 1 cw))
    (read-aloud--string word "word")
    ))

;;;###autoload
(cl-defun read-aloud-this()
  "Pronounce either the selection or a word under the pointer."
  (interactive)

  (when read-aloud--c-locked
    (read-aloud-stop)
    (cl-return-from read-aloud-selection))

  (if (use-region-p)
      (read-aloud--string
       (buffer-substring-no-properties (region-beginning) (region-end))
       "selection")
    (read-aloud--current-word)) )



(defun read-aloud--u-switch-to-buffer(buf)
  (unless (eq (current-buffer) buf)
    (unless (cdr (window-list))
      (split-window-vertically))
    (other-window 1)
    (switch-to-buffer buf)))

;; for emacs < 25
(defun read-aloud--u-str-reverse (str)
  "Reverse the STR."
  (apply #'string (reverse (string-to-list str))))

(defun read-aloud--u-current-word()
  "This is a modified (current-word) that doesn't take any args &
return (beg end word) or nil."
  (save-excursion
    (let* ((oldpoint (point)) (start (point)) (end (point))
	   (syntaxes "w_")
	   (not-syntaxes (concat "^" syntaxes)))
      (skip-syntax-backward syntaxes) (setq start (point))
      (goto-char oldpoint)
      (skip-syntax-forward syntaxes) (setq end (point))
      (when (and (eq start oldpoint) (eq end oldpoint))
	;; Look for preceding word in same line.
	(skip-syntax-backward not-syntaxes (line-beginning-position))
	(if (bolp)
	    ;; No preceding word in same line.
	    ;; Look for following word in same line.
	    (progn
	      (skip-syntax-forward not-syntaxes (line-end-position))
	      (setq start (point))
	      (skip-syntax-forward syntaxes)
	      (setq end (point)))
	  (setq end (point))
	  (skip-syntax-backward syntaxes)
	  (setq start (point))))
      ;; If we found something nonempty, return it as a list.
      (unless (= start end)
	(list start end (buffer-substring-no-properties start end)))
      )))



(provide 'read-aloud)
;;; read-aloud.el ends here
