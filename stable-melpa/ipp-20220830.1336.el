;;; ipp.el --- Implementation of the Internet Printing Protocol  -*- lexical-binding: t -*-
;;;
;;; Author: Eric Marsden <eric.marsden@risk-engineering.org>
;;; Copyright: (C) 2001-2022  Eric Marsden
;;; Keywords: printing, hardware
;;; URL: https://github.com/emarsden/ipp-el
;;; Version: 0.7
;;; Package-Requires: ((cl-lib "0.5") (emacs "24.1"))
;;
;;     This program is free software; you can redistribute it and/or
;;     modify it under the terms of the GNU General Public License as
;;     published by the Free Software Foundation; either version 3 of
;;     the License, or (at your option) any later version.
;;
;;     This program is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;     GNU General Public License for more details.
;;
;;     You should have received a copy of the GNU General Public
;;     License along with this program; if not, write to the Free
;;     Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;;     MA 02111-1307, USA.
;;
;; The latest version of this package should be available from
;;
;;     <https://github.com/emarsden/ipp-el>


;;; Commentary:

;; This Emacs package provides a partial implemention of the client component of
;; the Internet Printing Protocol (IPP). IPP was intended to replace the LPD
;; protocol for interacting with network printers. It specifies mechanisms for
;; “driverless printing” (submitting and cancelling jobs), queue monitoring and
;; querying printer capabilities. More recent versions of the standard are
;; called “IPP Everywhere”.
;;
;; You can find out whether a device is IPP-capable by trying to telnet to port 631. If it
;; accepts the connection it probably understands IPP. You then need to discover the path
;; component of the URI, for example by reading the documentation, by looking through the
;; menus via the front panel or its HTTP interface, or by analyzing DNS Service Discovery
;; (Bonjour) network traffic. Tested or reported to work on the following devices:
;;
;;   * Tektronix Phaser 750, with an URI of the form ipp://host:631/
;;     (empty path component)
;;
;;   * TOSHIBA e-STUDIO3005A, with an URI of the form ipp://host:631/ (empty path
;;     component).
;;
;;   * HP Laserjet 4000, with a path component of /ipp/port1.
;;
;;   * HP Color LaserJet MFP M477fdw
;;
;;   * Lexmark E460dn, with an empty path component
;;
;;   * Lexmark MS312dn with a path component of "/ipp/print" (IPP URL of the form
;;     "ipp://10.0.0.1:631/ipp/print" or "ipps://10.0.0.1:443/ipp/print")
;;
;;   * Xerox Document Centre 460 ST, with empty path component.
;;
;;   * Epson AL-MX300 and AL-M310DN with a path component of "/Epson_IPP_Printer" (so an
;;     IPP URI of the form "ipp://10.0.0.1/Epson_IPP_Printer" or
;;     "ipps://10.0.0.1:443/Epson_IPP_Printer")
;;
;;   * CUPS printer spooler (see <http://www.cups.org/>).
;;
;;
;;
;; Usage: load this package by putting in your ~/.emacs.el
;;
;;    (require 'ipp)
;;
;; then try printing a file using 'M-x ipp-print'. This will prompt you for a
;; file name (which should be in a format understood by the printer, such as
;; PDF), and the URI of the printer. The URI should be of the form
;;
;;    ipp://10.0.0.1:631/ipp/port1   (unencrypted connection on port 631, path="/ipp/port1")
;;    ipps://10.0.0.1/               (TLS connection on port 631, empty path component)
;;
;; There are also two functions for querying the capability of the device
;; `ipp-get-attributes' and examining its queue `ipp-get-jobs'. Until I write
;; display code for these functions you will have to call them from an IELM
;; buffer to examine their return value.
;;
;;    ELISP> (ipp-get-attributes "ipps://127.0.0.1:631/")
;;
;;
;; The IPP network protocol is based on HTTP/1.1 POST requests (or potentially
;; using HTTP/2 in the most recent versions, though we do not support this),
;; using a special "application/ipp" MIME Content-Type. The data is encoded
;; using simple marshalling rules.
;;
;; The Internet Printing Protocol is described in a number of RFCs:
;;   <https://datatracker.ietf.org/doc/rfc8010/>
;;   <http://www.faqs.org/rfcs/rfc2565.html>
;;   <http://www.faqs.org/rfcs/rfc2566.html>
;;   <http://www.faqs.org/rfcs/rfc2568.html>
;;
;; and the Printer Working Group maintain a page at
;;
;;   <https://www.pwg.org/ipp/>
;;
;; See also <https://istopwg.github.io/ipp/ippguide.html>.
;;
;; Eventually it would be nice to modify the Emacs printing API to
;; support this type of direct printing, so that a user could set
;; `ps-printer-name' to "ipp://modern-printer:631/" or
;; "lpd://ancient-printer/queue" (it would be easy to write a package
;; similar to this one implementing the LPD protocol at the network
;; level; the LDP protocol is very simple).
;;
;;
;; Thanks to Vinicius Jose Latorre and Marc Grégoire for patches and to Colin
;; Marquardt and Andrew Cosgriff for help in debugging.

;;; Code:

(require 'cl-lib)


(cl-defstruct ipp-reply
  status
  request-id
  attributes)

(defun ipp-value-tag-p (tag)
  (<= #x10 tag #xFF))

(defun ipp-parse-uri (uri)
  "Parse an IPP URI into values HOST, PORT, TLS, PATH.
URI is of the form ipp://host:631/path or ipps://host:631/path.
TLS is true for an ipps URL (with encryption) and false
otherwise. PORT defaults to 631 if not specified."
  (unless (string-match "^ipp\\(s\\)?://\\([^:/]+\\)\\(:[0-9]+\\)?/\\(.*\\)$" uri)
    (error "Invalid URI %s" uri))
  (cl-values (match-string 2 uri)
             (if (match-string 3 uri)
		 (string-to-number (substring (match-string 3 uri) 1))
	         631)
	     (if (match-string 1 uri) t nil)
             (concat "/" (match-string 4 uri))))

(defun ipp-demarshal-value (value-tag value-length)
  (cl-case value-tag
    ;; Unsupported
    (#x10 (ipp-demarshal-string value-length))
    ;; Unknown
    (#x12 nil)
    ;; NoValue
    (#x13 nil)
    ;; Integer
    (#x21 (ipp-demarshal-int value-length))
    ;; Boolean
    (#x22 (eql (ipp-demarshal-int value-length) 1))
    ;; Enum
    (#x23 (ipp-demarshal-int value-length))
    ;; DateTime, encoded as an OCTET-STRING consisting of eleven octets whose contents are defined
    ;; by "DateAndTime" in RFC 1903
    (#x31 (let ((year (ipp-demarshal-int 2))
                (month (ipp-demarshal-int 1))
                (day (ipp-demarshal-int 1))
                (hour (ipp-demarshal-int 1))
                (minutes (ipp-demarshal-int 1))
                (seconds  (ipp-demarshal-int 1))
                (_deci-seconds (ipp-demarshal-int 1))
                (dir-utc (ipp-demarshal-string 1))
                (hours-utc (ipp-demarshal-int 1))
                (minutes-utc (ipp-demarshal-int 1)))
            (format "%04d-%02d-%02dT%02d:%02d:%02d%s%02d:%02dZ"
                    year month day
                    hour minutes seconds
                    dir-utc hours-utc minutes-utc)))
    ;; The 'resolution' attribute syntax specifies a two-dimensional resolution in the indicated
    ;; units. It consists of 3 values: a cross feed direction resolution (positive integer value), a
    ;; feed direction resolution (positive integer value), and a units value.
    ;;
    ;; Encoding: OCTET-STRING consisting of nine octets of 2 SIGNED-INTEGERs followed by a
    ;; SIGNED-BYTE. The first SIGNED-INTEGER contains the value of cross feed direction resolution.
    ;; The second SIGNED-INTEGER contains the value of feed direction resolution. The SIGNED-BYTE
    ;; contains the units, specified in terms of the printer MIB (RFC1903).
    (#x32 (let ((xres (ipp-demarshal-int 4))
                (yres (ipp-demarshal-int 4))
                (_units (ipp-demarshal-int 1)))
            (format "%dx%d" xres yres)))
    ;; RangeOfInteger
    (#x33 (ipp-demarshal-int value-length))
    (#x37 (ipp-demarshal-string value-length))
    ;; URI
    (#x45 (ipp-demarshal-string value-length))
    ;; Charset
    (#x47 (ipp-demarshal-string value-length))
    ;; NaturalLanguage
    (#x48 (ipp-demarshal-string value-length))
    ;; MimeMediaType
    (#x49 (ipp-demarshal-string value-length))
    (t (ipp-demarshal-string value-length))))


;; attribute = value-tag name-length name value-length value
(defun ipp-demarshal-name-value (reply)
  (let (value-tag name-length name value-length value)
    (setq value-tag (char-after (point)))
    (when (ipp-value-tag-p value-tag)
      (forward-char)
      (setq name-length (ipp-demarshal-int 2)
            name (ipp-demarshal-string name-length)
            value-length (ipp-demarshal-int 2)
            value (ipp-demarshal-value value-tag value-length))
      (when value
	(push (list name value value-tag) (ipp-reply-attributes reply))))))

;; see rfc2565 section 3.2
(defun ipp-demarshal-attribute (reply)
  (let ((tag (char-after (point))))
    (forward-char)
    (cond ((= tag 3)                    ; end-of-attributes-tag
           nil)
          ;; xxx-attributes-tag *(attribute *additional-values)
          ((member tag '(1 2 4 5))
           (ipp-demarshal-name-value reply)
           t)
          ;; we're still in *(attribute *additional-values)
          ((ipp-value-tag-p tag)
           (backward-char)
           (ipp-demarshal-name-value reply)
           t)
          (t (error "Unknown IPP attribute tag %s" tag)))))

(defun ipp-mergeable-attribute-tag (tag)
  (member tag (list 33 35 48 50 65 66 68 69 70 71 72 73 74)))

(defun ipp-demarshal-attributes (reply)
  (while (ipp-demarshal-attribute reply)
    nil)
  ;; merge any BegCollection/setOf name-value attributes
  (let ((attributes (reverse (ipp-reply-attributes reply)))
	(merged (list)))
    (while attributes
      (let ((next (pop attributes)))
	(if (ipp-mergeable-attribute-tag (cl-third next))
	    (let ((name (cl-first next))
		  (current-tag (cl-third next))
		  (enum (list)))
	      (push (cl-second next) enum)
	      (cl-loop for ea = (cl-first attributes)
		       while (and ea (eql current-tag (cl-third ea)))
		       do
		       (push (cl-second ea) enum)
		       (pop attributes))
	      (push (list name enum current-tag) merged))
	  (push next merged))))
    (setf (ipp-reply-attributes reply) merged)))

(defun ipp-demarshal-string (octets)
  (forward-char octets)
  (buffer-substring (- (point) octets) (point)))

(defun ipp-demarshal-int (octets)
  (cl-do ((i octets (- i 1))
          (accum 0))
      ((zerop i) accum)
    (setq accum (+ (* 256 accum) (char-after (point))))
    (forward-char)))

(defun ipp-make-http-header (uri octets)
  (cl-multiple-value-bind (host port _tls path)
      (ipp-parse-uri uri)
    (concat "POST " path " HTTP/1.1\r\n"
          (format "Host: %s:%s\r\n" host port)
          "Content-Type: application/ipp\r\n"
          ;; We wait for the printer to close the connection before parsing the buffer contents
          ;; (would be better to use the content-length)
          "Connection: close\r\n"
          (format "Content-Length: %d\r\n" octets))))

;; a length is two octets
(defun ipp-length (str)
  (let ((octets (length str)))
    (string (/ octets 256) (mod octets 256))))

(defun ipp-attribute (type name value)
  (concat (string type)
          (ipp-length name)
          name
          (ipp-length value)
          value))

(defun ipp-marshal-printer-attributes-request (printer-uri)
  (concat (string 1 0)                  ; version as major/minor
          (string 0 #xB)                ; operation-id
          (string 0 0 0 ?e)             ; request-id as 4 octets
          (string 1)                    ; operation-attributes-tag
          (ipp-attribute #x47 "attributes-charset" "utf-8")
          (ipp-attribute #x48 "attributes-natural-language" "C")
          (ipp-attribute #x45 "printer-uri" printer-uri)
          (ipp-attribute #x42 "requesting-user-name" (user-login-name))
          (string 3)))                  ; end-of-attributes-tag

(defun ipp-marshal-get-jobs-request (printer-uri)
  (concat (string 1 0)                  ; version as major/minor
          (string 0 #xA)                ; operation-id
          (string 0 0 0 ?e)             ; request-id as 4 octets
          (string 1)                    ; operation-attributes-tag
          (ipp-attribute #x47 "attributes-charset" "utf-8")
          (ipp-attribute #x48 "attributes-natural-language" "C")
          (ipp-attribute #x45 "printer-uri" printer-uri)
          (ipp-attribute #x42 "requesting-user-name" (user-login-name))
          (string 3)))                  ; end-of-attributes-tag

(defun ipp-marshal-print-job-header (printer-uri)
  (concat (string 1 0)                  ; version as major/minor
          (string 0 2)                  ; operation-id: 2 == print-job
          (string 0 0 0 ?e)             ; request-id as 4 octets
          (string 1)                    ; operation-attributes-tag
          (ipp-attribute #x47 "attributes-charset" "utf-8")
          (ipp-attribute #x48 "attributes-natural-language" "C")
          (ipp-attribute #x45 "printer-uri" printer-uri)
          (ipp-attribute #x42 "job-name" "My Fine Job")
          (ipp-attribute #x42 "requesting-user-name" (user-login-name))
          (string 3)))                  ; end-of-attributes-tag

(defmacro ipp-marshal-print-job-request (printer &rest body)
  `(let ((buf (get-buffer-create " *ipp-print-job*")))
     (with-current-buffer buf
       (erase-buffer)
       (insert (ipp-marshal-print-job-header ,printer))
       ,@body
       (buffer-string))))

(defun ipp-marshal-print-job-request-file (printer filename)
  (ipp-marshal-print-job-request
   printer
   (insert-file-contents-literally filename)))

(defun ipp-marshal-print-job-request-region (printer buffer
						     &optional start end)
  (ipp-marshal-print-job-request
   printer
   (insert-buffer-substring buffer start end)))

(defun ipp-open (printer-uri)
  (cl-multiple-value-bind (host port tls)
      (ipp-parse-uri printer-uri)
    (let* ((buf (generate-new-buffer " *ipp connection*"))
           (proc (if tls (open-network-stream "ipp" buf host port :type 'tls)
		   (open-network-stream "ipp" buf host port))))
    (buffer-disable-undo buf)
    (when (fboundp 'set-process-coding-system)
      (with-current-buffer buf
        (set-process-coding-system proc 'binary 'binary)
        (set-buffer-multibyte nil)))
    proc)))

(defun ipp-close (connection)
  "Close the IPP connection CONNECTION."
  (delete-process connection))

;; Mostly for debugging use
(defun ipp-kill-all-buffers ()
  "Kill all buffers used for network connections with an IPP printer."
  (interactive)
  (cl-loop for buffer in (buffer-list)
	   for name = (buffer-name buffer)
	   when (and (> (length name) 16)
		     (string= " *ipp connection*" (substring (buffer-name buffer) 0 17)))
	   do (kill-buffer buffer)))

(defun ipp-send (proc &rest args)
  (dolist (arg args)
    (process-send-string proc arg)
    (accept-process-output)))

(defun ipp-decode-reply (conn)
  (let ((buf (if (bufferp conn) conn (process-buffer conn)))
        (reply (make-ipp-reply)))
    ;; wait for the connection to close
    (when (processp conn)
      (cl-loop until (eq (process-status conn) 'closed)
               do (accept-process-output conn 5)))
    (with-current-buffer buf
      (goto-char (point-min))
      (when (re-search-forward "^HTTP/1.[01] 501" nil t)
        (error "Unimplemented IPP request"))
      (goto-char (point-min))
      (when (re-search-forward "^HTTP/1.[01] 403" nil t)
        (error "IPP request: access forbidden"))
      (goto-char (point-min))
      (if (search-forward "HTTP/1.1 100" nil t)
          (end-of-line 2)
        (goto-char (point-min)))
      ;; skip over the HTTP headers
      (goto-char (point-min))
      (or (search-forward (string 13 10 13 10) nil t)
          (progn
            (goto-char (point-min))
            (search-forward (string 10 10) nil t))
          (error "Malformed IPP reply (skipping over HTTP header)"))
      (let ((ipp-major-version (get-byte))
            (ipp-minor-version (get-byte (1+ (point)))))
        ;; We are not fully compliant with IPP version 1.1 and 2.0 (which for example require us to
        ;; support HTTP chunked encoding), but we try our best.
        (unless (member (cons ipp-major-version ipp-minor-version)
                        (list (cons 1 0) (cons 1 1) (cons 2 0)))
          (error "Unknown IPP protocol version %d.%d"
                 ipp-major-version
                 ipp-minor-version))
	(forward-char 2)
	(setf (ipp-reply-status reply) (ipp-demarshal-int 2))
	(setf (ipp-reply-request-id reply) (ipp-demarshal-int 4))
	(ipp-demarshal-attributes reply)))
    reply))

(defun ipp-get (printer request)
  "Get REQUEST from IPP-capable network device PRINTER.
The printer name should be of the form ipp://host:631/ipp/port1."
  (let ((connection (ipp-open printer)))
    (ipp-send connection
	      (ipp-make-http-header printer (length request))
	      "\r\n"
	      request)
    (let ((response (ipp-decode-reply connection)))
      (ipp-close connection)
      response)))

;; these are not autoloaded, since they need some sort of widget-based
;; interface to present the information.
(defun ipp-get-attributes (printer)
  "Get attributes from IPP-capable network device PRINTER.
The printer name should be of the form ipp://host:631/ipp/port1."
  (ipp-get printer
	   (ipp-marshal-printer-attributes-request printer)))

(defun ipp-get-jobs (printer)
  "Get running jobs at IPP-capable network device PRINTER.
The printer name should be of the form ipp://host:631/ipp/port1."
  (ipp-get printer
	   (ipp-marshal-get-jobs-request printer)))

(defun ipp-print (printer content)
  "Print CONTENT to IPP-capable network device PRINTER.
CONTENT must be in a format understood by your printer, such as PDF, Postscript
or PCL.
The printer name should be of the form ipp://host:631/ipp/port1."
  (let ((connection (ipp-open printer)))
    (ipp-send connection
	      (ipp-make-http-header printer (length content))
	      "\r\n"
	      content)
    (ipp-close connection)))

;;;###autoload
(defun ipp-print-file (filename printer)
  "Print FILENAME to the IPP-capable network device PRINTER.
FILENAME must be in a format understood by your printer, such as PDF, Postscript
or PCL.
The printer name should be of the form ipp://host:631/ipp/port1."
  (interactive "fIPP print file: \nsPrinter URI: ")
  (ipp-print printer
	     (ipp-marshal-print-job-request-file printer filename)))

;;;###autoload
(defun ipp-print-region (buffer printer &optional start end)
  "Print BUFFER region from START to END to IPP-capable network device PRINTER.
BUFFER must be in a format understood by your printer, such as PDF, Postscript
or PCL.
If START is nil, it defaults to beginning of BUFFER.
If END is nil, it defaults to end of BUFFER.
The printer name should be of the form ipp://host:631/ipp/port1."
  (interactive "bIPP print buffer (region): \nsPrinter URI: ")
  (ipp-print printer
	     (ipp-marshal-print-job-request-region printer buffer start end)))

;;;###autoload
(defun ipp-print-buffer (buffer printer)
  "Print BUFFER to IPP-capable network device PRINTER.
BUFFER must be in a format understood by your printer, such as PDF, Postscript
or PCL.
The printer name should be of the form ipp://host:631/ipp/port1."
  (interactive "bIPP print buffer: \nsPrinter URI: ")
  (ipp-print-region buffer printer))


(provide 'ipp)

;;; ipp.el ends here
