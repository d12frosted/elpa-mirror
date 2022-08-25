;;; http-twiddle.el --- send & twiddle & resend HTTP requests

;; This program belongs to the public domain.

;; Author: Luke Gorrie <luke@synap.se>
;; Maintainer: Hasan Veldstra <h@vidiowiki.com>
;; Created: 1 Feb 2006
;; Adapted-By: Hasan Veldstra
;; Version: 1.0
;; Package-Version: 20160801.1911
;; Package-Commit: 46da2dbc40209925aa88ab19014ca982bcf9ac70
;; URL: https://github.com/hassy/http-twiddle/blob/master/http-twiddle.el
;; Keywords: HTTP, REST, SOAP

;;; Commentary:
;;
;; This is a program for testing hand-written HTTP requests. You write
;; your request in an Emacs buffer (using http-twiddle-mode) and then
;; press `C-c C-c' each time you want to try sending it to the server.
;; This way you can interactively debug the requests. To change port or
;; destination do `C-u C-c C-c'.
;;
;; The program is particularly intended for the POST-"500 internal
;; server error"-edit-POST loop of integration with SOAP programs.
;;
;; The mode is activated by `M-x http-twiddle-mode' or automatically
;; when opening a filename ending with .http-twiddle.
;;
;; The request can either be written from scratch or you can paste it
;; from a snoop/tcpdump and then twiddle from there.
;;
;; See the documentation for the `http-twiddle-mode' and
;; `http-twiddle-mode-send' functions below for more details and try
;; `M-x http-twiddle-mode-demo' for a simple get-started example.
;;
;; Tested with GNU Emacs 21.4.1 and not tested/ported on XEmacs yet.
;;
;; Example buffer:
;;
;; POST / HTTP/1.0
;; Connection: close
;; Content-Length: $Content-Length
;;
;; <The request body goes here>

;;; Code:

(require 'font-lock)                    ; faces

(defgroup http-twiddle nil
  "HTTP Request Twiddling"
  :prefix "http-twiddle"
  :group 'communication)

(eval-when-compile
  (unless (fboundp 'define-minor-mode)
    (require 'easy-mmode)
    (defalias 'define-minor-mode 'easy-mmode-define-minor-mode))
  (require 'cl))

(define-minor-mode http-twiddle-mode
  "Minor mode for twiddling around with HTTP requests and sending them.
Use `http-twiddle-mode-send' (\\[http-twiddle-mode-send]) to send the request."
  nil
  " http-twiddle"
  '(("\C-c\C-c" . http-twiddle-mode-send)))

(defcustom http-twiddle-show-request t
  "*Show the request in the transcript."
  :type '(boolean)
  :group 'http-twiddle)

(defcustom http-twiddle-tls nil
  "Use a TLS (https) connection instead of regular http, and default to port 443 instead of 80."
  :type '(boolean)
  :group 'http-twiddle)

(add-to-list 'auto-mode-alist '("\\.http-twiddle$" . http-twiddle-mode))

(defvar http-twiddle-endpoint nil
  "Cache of the (HOST PORT) to send the request to.")

(defvar http-twiddle-process nil
  "Socket connected to the webserver.")

(defvar http-twiddle-port-history '()
  "History of port arguments entered in the minibuffer.
\(To make XEmacs happy.)")

(defvar http-twiddle-host-history '()
  "History of port arguments entered in the minibuffer.
\(To make XEmacs happy.)")

(defconst http-twiddle-font-lock-keywords
  (list
   '("^X-[a-zA-Z0-9-]+:" . font-lock--face)
   '("^[a-zA-Z0-9-]+:" . font-lock-keyword-face)
   '("HTTP/1.[01] [45][0-9][0-9] .*" . font-lock-warning-face)
   '("HTTP/1.[01] [23][0-9][0-9] .*" . font-lock-type-face)
   '("HTTP/1.[01]?$" . font-lock-constant-face)
   (cons (regexp-opt '("GET" "POST" "HEAD" "PUT" "DELETE" "TRACE" "CONNECT"))
         font-lock-constant-face))
  "Keywords to highlight in http-twiddle-response-mode.")

(defconst http-twiddle-response-mode-map
  (make-sparse-keymap)
  "Keymap for http-twiddle-response-mode.")

(define-generic-mode http-twiddle-response-mode
  nil nil http-twiddle-font-lock-keywords
  nil
  '((lambda ()
      (use-local-map http-twiddle-response-mode-map)))
  "Major mode for interacting with HTTP responses.")

(defun http-twiddle-connection-type ()
  "The type of network connection, either 'plain or 'tls."
  (if http-twiddle-tls
      'tls
    'plain))

(defun http-twiddle-hide-dos-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (if (not buffer-display-table)
      (setq buffer-display-table (make-display-table)))
  (aset buffer-display-table ?\^M []))

(defun http-twiddle-mode-send (host port)
  "Send the current buffer to the server.
Linebreaks are automatically converted to CRLF (\\r\\n) format and any
occurences of \"$Content-Length\" are replaced with the actual content
length. Any elisp code between $|...code...| is evaluated and the match
is substituted with the evaluated value formatted as string."
  (interactive (http-twiddle-read-endpoint))
  ;; close any old connection
  (when (and http-twiddle-process
             (buffer-live-p (process-buffer http-twiddle-process)))
    (with-current-buffer (process-buffer http-twiddle-process)
      (let ((inhibit-read-only t))
        (widen)
        (delete-region (point-min) (point-max)))))

  (let ((content (buffer-string)))
    (with-temp-buffer
      (set (make-local-variable 'font-lock-keywords)
           http-twiddle-font-lock-keywords)
      (insert content)
      (http-twiddle-expand-template)
      (http-twiddle-convert-cr-to-crlf)
      (http-twiddle-expand-content-length)
      (let ((request (buffer-string))
            (inhibit-read-only t))
        (setq http-twiddle-process
              (open-network-stream "http-twiddle" "*HTTP Twiddle*" host port :type (http-twiddle-connection-type)))
        (set-process-filter http-twiddle-process 'http-twiddle-process-filter)
        (set-process-sentinel http-twiddle-process 'http-twiddle-process-sentinel)
        (process-send-string http-twiddle-process request)
        (with-current-buffer (process-buffer http-twiddle-process)
          (http-twiddle-hide-dos-eol))
        (save-selected-window
          (pop-to-buffer (process-buffer http-twiddle-process))
          (unless (eq major-mode 'http-twiddle-response-mode)
            (http-twiddle-response-mode))
          (setq buffer-read-only t)
          (let ((inhibit-read-only t))
          (when http-twiddle-show-request
            (insert request)
            (set-window-start (selected-window) (point))))
          (set-mark (point)))))))

(defun http-twiddle-default-port ()
  "The port to connect to on the server, if no port is specified. Uses 80 or
   443, depending on http-twiddle-tls"
  (if http-twiddle-tls
      443
    80))

(defun http-twiddle-read-endpoint ()
  "Return the endpoint (HOST PORT) to send the request to.
   Uses values specified in Host header, or prompts if it's not written out."

  (let ((rx "\\(^Host: \\)\\([^\r\n]+\\)")
        (str (buffer-string)))
    (if (null (string-match rx str))
        ;; ask
        (setq http-twiddle-endpoint
              (list (read-string "Host: (default localhost) "
                                 nil 'http-twiddle-host-history "localhost")
                    (let ((input (read-from-minibuffer "Port: " nil nil t 'http-twiddle-port-history)))
                      (if (integerp input)
                          input
                        (error "Not an integer: %S" input)))))
      ;; try to parse headers
      (let ((tokens (split-string (match-string 2 str) ":")))
        (if (= (length tokens) 1)
            (list (car tokens) (http-twiddle-default-port))
          (list (car tokens) (string-to-number (car (cdr tokens)))))))))

(defun http-twiddle-convert-cr-to-crlf ()
  "Convert \\n linebreaks to \\r\\n in the whole buffer."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "[^\r]\n" nil t)
      (backward-char)
      (insert "\r"))))

(defun http-twiddle-expand-content-length ()
  "Replace any occurences of $Content-Length with the actual Content-Length. Insert one if needed."
  (save-excursion
    (goto-char (point-min))
    (let ((content-length
           (save-excursion (when (search-forward "\r\n\r\n" nil t)
                             (- (point-max) (point))))))

      (let ((got-content-length-already
             (save-excursion
               (goto-char (point-min))
               (let ((case-fold-search t))
                 (when (search-forward "content-length" (- (point-max) content-length 2) t)
                   t)))))

        (unless got-content-length-already
          (save-excursion
            (goto-char (- (point-max) content-length 2))
            (insert "Content-Length: $Content-Length\r\n")))

        (unless (null content-length)
          (let ((case-fold-search t))
            (while (search-forward "$content-length" nil t)
              (replace-match (format "%d" content-length) nil t))))))))

(defun http-twiddle-expand-template ()
  "Replace any occurences of $|...code...| with the evaluation of ...code..."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\\$|[^|]+|" nil t)
      (let ((d (substring-no-properties (match-string 0) 2)))
	(replace-match (format "%s" (eval (car (read-from-string d)))))))))

(defun http-twiddle--mime-charset->coding-system (mime-charset)
  "Convert a MIME standard charset name like UTF-8 or
   ISO-8859-1 (a string) into an Emacs coding system
   name (Symbol). Based on
   epa--find-coding-system-for-mime-charset"
  (let ((mime-charset (intern (downcase mime-charset))))
    (if (featurep 'xemacs)
        (if (fboundp 'find-coding-system)
            (find-coding-system mime-charset))
      ;; Find the first coding system which corresponds to MIME-CHARSET.
      (let ((pointer (coding-system-list)))
        (while (and pointer
                    (not (eq (coding-system-get (car pointer) 'mime-charset)
                             mime-charset)))
          (setq pointer (cdr pointer)))
        (car pointer)))))

(defun http-twiddle-change-coding-system (encoding)
  "Change the encoding of the process and output buffer once we
   figure out what it's supposed to be."
  (with-current-buffer (process-buffer http-twiddle-process)
    (set-buffer-process-coding-system encoding encoding)
    (set-buffer-file-coding-system encoding)))

(defun http-twiddle-process-filter (process string)
  "Process data from the socket by inserting it at the end of the
   buffer. If this encounters a Content-Type header it will set the
   buffer's encoding accordingly"
  (with-current-buffer (process-buffer process)
    (when (string-match "Content-Type:[^\n]*charset=\\([^\r]*\\)\\(\r\\|\\)" string)
      (let* ((mime-encoding (match-string 1 string))
             (coding-system (http-twiddle--mime-charset->coding-system mime-encoding)))
        (http-twiddle-change-coding-system coding-system)
        ;; This chunk of output might already contain non-US-ASCII characters,
        ;; which emacs will have decoded incorrectly, so reinterpret them
        (setq string (decode-coding-string string coding-system))))
    (let ((inhibit-read-only t))
      (goto-char (point-max))
      (insert string))))

(defun http-twiddle-process-sentinel (process what)
  (with-current-buffer (process-buffer process)
    (goto-char (point-max))
    (let ((start (point))
          (inhibit-read-only t))
      (insert "\nConnection closed\n")
      (set-buffer-modified-p nil))))

(defun http-twiddle-mode-demo ()
  (interactive)
  (pop-to-buffer (get-buffer-create "*http-twiddle demo*"))
  (http-twiddle-mode 1)
  (erase-buffer)
  (insert "POST / HTTP/1.0\nContent-Length: $Content-Length\nConnection: close\n\nThis is the POST body.\n")
  (message "Now press `C-c C-c' and enter a webserver address (e.g. google.com port 80)."))

(provide 'http-twiddle)

;;; http-twiddle.el ends here
