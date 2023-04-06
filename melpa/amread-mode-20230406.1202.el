;;; amread-mode.el --- A minor mode helper user speed-reading -*- lexical-binding: t; -*-

;;; Time-stamp: <2020-06-23 23:44:49 stardiviner>

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "24.3") (cl-lib "0.6.1") (pyim "5.2.8"))
;; Package-Commit: f5b46f83ce205b1f6c1cf54e99da3e46ad17dfad
;; Package-Version: 20230406.1202
;; Package-X-Original-Version: 0.1
;; Keywords: wp
;; homepage: https://repo.or.cz/amread-mode.git

;; amread-mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; amread-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;;
;;; Usage
;;;
;;; 1. Launch amread-mode with command `amread-mode'.
;;; 2. Stop amread-mode by pressing [q].

;;; Code:
(require 'cl-lib)
(require 'pyim)


(defcustom amread-word-speed 3.0
  "Read words per second."
  :type 'float
  :safe #'floatp
  :group 'amread-mode)

(defcustom amread-line-speed 4.0
  "Read one line using N seconds in average."
  :type 'float
  :safe #'floatp
  :group 'amread-mode)

(defcustom amread-scroll-style nil
  "Set amread auto scroll style by word or line."
  :type '(choice (const :tag "scroll by word" word)
                 (const :tag "scroll by line" line))
  :safe #'symbolp
  :group 'amread-mode)

(defcustom amread-voice-reader-enabled nil
  "The initial state of voice reader."
  :type 'boolean
  :safe #'booleanp
  :group 'amread-mode)

(defcustom amread-voice-reader-command
  (cl-case system-type
    (darwin "say")
    (gnu/linux (or (executable-find "espeak") (executable-find "festival")))
    (windows-nt ))                      ; TODO
  "The command for reading text."
  :type 'string
  :safe #'stringp
  :group 'amread-mode)

(defcustom amread-voice-reader-command-options ""
  "Specify options for voice reader command."
  :type 'string
  :safe #'stringp
  :group 'amread-mode)

(defcustom amread-voice-reader-language 'chinese
  "Specifiy default language for voice reader."
  :type 'symbol
  :safe #'symbolp
  :group 'amread-mode)

(defface amread-highlight-face
  '((t :foreground "black" :background "ForestGreen"))
  "Face for amread-mode highlight."
  :group 'amread-mode)

(defvar amread--timer nil)
(defvar amread--current-position nil)
(defvar amread--overlay nil)

(defvar amread--voice-reader-proc-finished nil
  "A process status variable indicate whether voice reader finished reading.
It has three status values:
- \='not-started :: process not started
- \='running     :: process still running
- \='finished    :: process finished")

(defmacro amread--voice-reader-status-wrapper (body)
  "A wrapper macro for detecting voice reader process status and execute BODY."
  `(if amread-voice-reader-enabled
       ;; wait for process finished, then jump to next word.
       (cl-case amread--voice-reader-proc-finished
         (not-started ,body)
         (running (ignore))
         (finished ,body)
         (t (setq amread--voice-reader-proc-finished 'not-started)))
     ,body))

;; (macroexpand-1
;;  '(amread--voice-reader-status-wrapper (amread--word-update)))

(defun amread--voice-reader-read-text (text)
  "Read TEXT with voice command-line tool."
  (when (and amread-voice-reader-enabled
             (not (null text))
             (not (string-empty-p text)))
    (setq amread--voice-reader-proc-finished 'running)
    (cl-case system-type
      (darwin
       (or (amread--voice-reader-read-text-with-tts text)
           (amread--voice-reader-read-text-with-say text)))
      (t (amread--voice-reader-read-text-with-tts text)))))

(defun amread--voice-reader-run-python-code-to-string (&rest python-code-lines)
  "Run PYTHON-CODE-LINES through Python interpreter result to string."
  (let ((python-interpreter (or (executable-find "python3") python-interpreter)))
    (shell-command-to-string
     (format "%s %s"
             python-interpreter
             (concat " -c "
                     ;; solve double quote character issue.
                     "\"" (string-replace "\"" "\\\"" (string-join python-code-lines "\n")) "\"")))))

;; (print
;;  (amread--voice-reader-run-python-code-to-string
;;   "import numpy as np"
;;   "print(np.arange(6))"
;;   "print(\"blah blah\")"
;;   "print('{}'.format(3))"))

(defun amread--voice-reader-run-python-file-to-string (python-code-file)
  "Run PYTHON-CODE-FILE through Python interpreter result to string."
  (let ((python-interpreter (or (executable-find "python3") python-interpreter)))
    (shell-command-to-string
     (format "%s %s" python-interpreter python-code-file))))

(defun amread--voice-reader-run-python-code-in-repl (&rest python-code-lines)
  "Run PYTHON-CODE-LINES through Python REPL process result to strings list."
  (let ((python-interpreter (or (executable-find "python3") python-interpreter)))
    (run-python)
    ;; `process-send-string' alias `send-string'
    ;; `python-shell-send-string', `python-shell-internal-send-string', `python-shell-send-string-no-output'
    (dolist (line python-code-lines
                  result)
      ;; assign last eval result to `dolist' binding `result'.
      (setf result (python-shell-send-string-no-output line)))))

;; (amread--voice-reader-run-python-code-in-repl
;;  "import sys"
;;  "print(sys.path)"
;;  "sys.path")

(defvar amread--voice-reader-engine-initialized nil)

;; invoke cross-platform TTS Speech API through Python library "pyttsx3".
(defun amread--voice-reader-read-text-with-tts (text)
  "Read TEXT with cross-platform TTS Speech API through Python library \"pyttsx3\"."
  ;; keep instance of engine to avoid repeat creating performance issue.
  (unless (string-equal amread--voice-reader-engine-initialized "True")
    (setq amread--voice-reader-engine-initialized
          (amread--voice-reader-run-python-code-in-repl
           "import pyttsx3"
           "engine = pyttsx3.init()"
           "True")))
  (amread--voice-reader-run-python-code-in-repl
   (format "engine.say(\"%s\")" text)
   "engine.runAndWait()"))

;; (amread--voice-reader-read-text-with-tts "happy")

(defun amread--voice-reader-read-text-with-say (text)
  "Read TEXT with macOS command `say'."
  ;; detect language and switch language/voice.
  (let ((language (amread-voice-reader-switch-language-voice)))
    (cl-case language
      (chinese
       (setq amread-voice-reader-command-options "--voice=Ting-Ting")
       (message "[amread] voice reader switched to Chinese language/voice."))
      (english
       (setq amread-voice-reader-command-options "--voice=Ava")
       (message "[amread] voice reader switched to English language/voice."))
      (t
       (let ((voice (completing-read "[amread] Select language/voice: " '("Ting-Ting" "Ava"))))
         (setq amread-voice-reader-command-options (format "--voice=%s" voice))
         (message "[amread] voice reader switched to language/voice <%s>." voice)))))

  ;; Synchronous Processes
  ;; (call-process-shell-command
  ;;  amread-voice-reader-command
  ;;  nil nil nil
  ;;  amread-voice-reader-command-options
  ;;  (shell-quote-argument text))

  ;; Async Process
  (make-process
   :name "amread-voice-reader"
   :command (list amread-voice-reader-command amread-voice-reader-command-options text)
   :sentinel (lambda (_proc event)
               (if (string= event "finished\n")
                   (setq amread--voice-reader-proc-finished 'finished)))
   :buffer " *amread-voice-reader*"
   :stderr " *amread-voice-reader*"))

(defun amread--word-update ()
  "Scroll forward by word as step."
  (let* ((begin (point))
         ;; move point forward. NOTE This forwarding must be here before moving overlay forward.
         (_length (+ (skip-chars-forward "^\s\t\n—") (skip-chars-forward "—")))
         (end (point))
         (word (buffer-substring-no-properties begin end)))
    (if (eobp)
        (progn
          (amread-mode -1)
          (setq amread--current-position nil))
      ;; create the overlay if does not exist
      (unless amread--overlay
        (setq amread--overlay (make-overlay begin end)))
      ;; move overlay forward
      (when amread--overlay
        (move-overlay amread--overlay begin end))
      (setq amread--current-position (point))
      (overlay-put amread--overlay 'face 'amread-highlight-face)
      ;; read word text
      (amread--voice-reader-read-text word)
      (skip-chars-forward "\s\t\n—")
      ;; when in nov.el ebook, auto navigate to next page.
      (when (and (eobp) (eq major-mode 'nov-mode))
        (nov-next-document)
        (message "[amread] nov.el next page.")))))

(defun amread--line-update ()
  "Scroll forward by line as step."
  (let* ((line-begin (line-beginning-position))
         (line-end (line-end-position))
         (line-text (buffer-substring-no-properties line-begin line-end)))
    (if (eobp) ; reached end of buffer.
        (progn
          (amread-mode -1)
          (setq amread--current-position nil))
      ;; create line overlay to highlight current reading line.
      (unless amread--overlay
        (setq amread--overlay (make-overlay line-begin line-end)))
      ;; scroll down line
      (when amread--overlay
        (move-overlay amread--overlay line-begin line-end))
      (overlay-put amread--overlay 'face 'amread-highlight-face)
      ;; read line text
      (amread--voice-reader-read-text line-text)
      (forward-line 1)
      ;; when in nov.el ebook, auto navigate to next page.
      (when (and (eobp) (eq major-mode 'nov-mode))
        (nov-next-document)
        (message "[amread] nov.el next page.")))))

(defun amread--update ()
  "Update and scroll forward under Emacs timer."
  (cl-case amread-scroll-style
    (word
     (amread--voice-reader-status-wrapper (amread--word-update)))
    (line
     (amread--voice-reader-status-wrapper (amread--line-update))
     ;; Auto modify the running timer REPEAT seconds based on next line words length.
     (let* ((next-line-words (amread--get-next-line-words)) ; for English
            ;; TODO: Add Chinese text logic.
            ;; (next-line-length (amread--get-next-line-length)) ; for Chinese
            (amread--next-line-pause-secs (truncate (/ next-line-words amread-word-speed))))
       (when (> amread--next-line-pause-secs 0)
         (setf (timer--repeat-delay amread--timer) amread--next-line-pause-secs))))
    (t (user-error "Seems amread-mode is not normally started or not running."))))

(defun amread--scroll-style-ask ()
  "Ask which scroll style to use."
  (let ((style (intern (completing-read "amread-mode scroll style: " '("word" "line")))))
    (setq amread-scroll-style style)
    style))

(defun amread--get-line-words (&optional pos)
  "Get the line words of position."
  (save-excursion
    (and pos (goto-char pos))
    (beginning-of-line)
    (count-words (line-end-position) (line-beginning-position))))

(defun amread--get-next-line-words ()
  "Get the next line words."
  (amread--get-line-words (save-excursion (forward-line) (point))))

(defun amread--get-line-length (&optional pos)
  "Get the line length of position."
  (save-excursion
    (and pos (goto-char pos))
    (- (line-end-position) (line-beginning-position))))

(defun amread--get-next-line-length ()
  "Get the next line length."
  (amread--get-line-words (save-excursion (forward-line) (point))))

;;;###autoload
(defun amread-start ()
  "Start / resume amread."
  (interactive)
  (read-only-mode 1)
  ;; if quit `amread--scroll-style-ask', then don't enable `amread-mode'.
  (or amread-scroll-style (amread--scroll-style-ask))
  (setq amread--voice-reader-proc-finished 'not-started)
  ;; select language
  (setq amread-voice-reader-language
        (intern
         (completing-read "[amread] Select language: " '("chinese" "english"))))
  ;; select scroll style
  (if (null amread-scroll-style)
      (user-error "User quited entering amread-mode.")
    ;; resume from paused position
    (cl-case amread-scroll-style
      (word
       (when amread--current-position
         (goto-char amread--current-position))
       (setq amread--timer
             (run-with-timer 0 (/ 1.0 amread-word-speed) #'amread--update)))
      (line
       (when amread--current-position
         (goto-char (point-min))
         (forward-line amread--current-position))
       (setq amread--timer
             (run-with-timer 1 amread-line-speed #'amread--update)))
      (t (user-error "Seems amread-mode is not normally started because of not selecting scroll style OR just not running.")))
    ;; enable hydra
    (hydra-amread/body)
    (message "[amread] start reading...")))

;;;###autoload
(defun amread-stop ()
  "Stop amread."
  (interactive)
  (when amread--timer
    (cancel-timer amread--timer)
    (setq amread--timer nil)
    (when amread--overlay
      (delete-overlay amread--overlay)))
  (setq amread-scroll-style nil)
  (read-only-mode -1)
  (hydra-keyboard-quit)
  (message "[amread] stopped."))

;;;###autoload
(defun amread-pause-or-resume ()
  "Pause or resume amread."
  (interactive)
  (if amread--timer
      (amread-stop)
    (amread-start)))

;;;###autoload
(defun amread-mode-quit ()
  "Disable `amread-mode'."
  (interactive)
  (amread-mode -1)
  (hydra-keyboard-quit))

;;;###autoload
(defun amread-speed-up ()
  "Speed up `amread-mode'."
  (interactive)
  (setq amread-word-speed (cl-incf amread-word-speed 0.2))
  (message "[amread] word speed increased -> %s" amread-word-speed))

;;;###autoload
(defun amread-speed-down ()
  "Speed down `amread-mode'."
  (interactive)
  (setq amread-word-speed (cl-decf amread-word-speed 0.2))
  (message "[amread] word speed decreased -> %s" amread-word-speed))

;;;###autoload
(defun amread-voice-reader-toggle ()
  "Toggle text voice reading."
  (interactive)
  (if amread-voice-reader-enabled
      (progn
        (setq amread-voice-reader-enabled nil)
        (message "[amread] voice reader disabled."))
    (setq amread-voice-reader-enabled t)
    (message "[amread] voice reader enabled.")))

(defun amread--voice-reader-detect-language (&optional string)
  "Detect text language."
  ;; Return t if STRING is a Chinese string.
  (if-let ((string (or string (word-at-point))))
      (cond
       ;; `pyim-probe-auto-english'
       ((null (pyim-probe-dynamic-english))
        'chinese)
       ((pyim-probe-dynamic-english)
        'english)
       ((string-match (format "\\cC\\{%s\\}" (length string)) string)
        'chinese))
    nil))

;; (amread--voice-reader-detect-language "测试")
;; (amread--voice-reader-detect-language "测试test")

;;;###autoload
(defun amread-voice-reader-switch-language-voice (&optional language)
  "Switch voice reader LANGUAGE or voice."
  (interactive "P")
  (let ((language (or language
                      (when (called-interactively-p 'interactive)
                        (intern (completing-read "[amread] Select language: " '("chinese" "english"))))
                      amread-voice-reader-language
                      (amread--voice-reader-detect-language))))
    language))

;;;###autoload
(defun amread-voice-reader-read-buffer ()
  "Read current buffer text without timer highlight updating."
  (interactive)
  ;; loop over all lines of buffer.
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((line-begin (line-beginning-position))
               (line-end (line-end-position))
               (line-text (buffer-substring-no-properties line-begin line-end)))
          ;; line processiqng
          (let ((amread-voice-reader-enabled t))
            (amread--voice-reader-status-wrapper
             (amread--voice-reader-read-text line-text)))
          (forward-line 1))))))

(defvar amread-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q")             #'amread-mode-quit)
    (define-key map (kbd "SPC")           #'amread-pause-or-resume)
    (define-key map [remap keyboard-quit] #'amread-mode-quit)
    (define-key map (kbd "+")             #'amread-speed-up)
    (define-key map (kbd "-")             #'amread-speed-down)
    (define-key map (kbd "v")             #'amread-voice-reader-toggle)
    (define-key map (kbd "L")             #'amread-voice-reader-switch-language-voice)
    (define-key map (kbd ".")             #'hydra-amread/body)
    map)
  "Keymap for `amread-mode' buffers.")

(defhydra hydra-amread (:color green :hint nil :exit nil)
  "
^Control^                ^Adjust When Reading^
^------------------^     ^-------------------------^
_SPC_: pause/resume      _+_: speed up
_q_: quit                _-_: speed down
^ ^                      _v_: toggle voice reader
^ ^                      _L_: switch language/voice
"
  ("SPC" amread-pause-or-resume :color blue)
  ("q" amread-mode-quit :color red)
  ("+" amread-speed-up :color blue)
  ("-" amread-speed-down :color blue)
  ("v" amread-voice-reader-toggle :color pink)
  ("L" amread-voice-reader-switch-language-voice :color pink))

;;;###autoload
(define-minor-mode amread-mode
  "I'm reading mode."
  :init nil
  :lighter " amreading"
  :keymap amread-mode-map
  (if amread-mode
      (amread-start)
    (amread-stop)))



(provide 'amread-mode)

;;; amread-mode.el ends here
