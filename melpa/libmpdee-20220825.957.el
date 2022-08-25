;;; libmpdee.el --- Client end library for mpd, a music playing daemon

;; Copyright (C) 2004-2014 Ramkumar R. Aiyengar

;; Author: 	Ramkumar R. Aiyengar <andyetitmoves@gmail.com>
;; Created: 	10 May 2004
;; Version: 	2.2
;; Package-Version: 20220825.957
;; Package-Commit: 9a84e074385cd085622f94e720a968a0e05ceae5
;; Keywords:	music, mpd

;; This file is *NOT* part of GNU Emacs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; A copy of the GNU General Public License can be obtained from this
;; program's author (send electronic mail to andyetitmoves@gmail.com)
;; or from the Free Software Foundation, Inc.,
;; 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;; This package is a client end library to the wonderful music playing daemon by
;; name mpd. Hence, an obvious prerequisite for this package is mpd itself,
;; which you can get at http://www.musicpd.org. For those who haven't heard of
;; mpd, all I can say is that it is definitely worth a try, and is surely
;; different from the rest. This package is aimed at developers, and though
;; there are some interactive functions, much of the power of the library lies
;; away from the user.

;; This package started off to implement libmpdclient.c, which came with mpd, in
;; elisp. But as it stands of now, this package is not an exact translation.
;; Notable amongst the deviations are -
;;
;;      - This package contains quite a bit of higher level functionality as
;;      compared with the original. An action or a query needs only a single
;;      call and the library user can choose to get either the raw response, the
;;      formatted response, or hook on a callback for each logical token of the
;;      response. However, dig deeper, and you will find the lower level
;;      functionality available as well.
;;      - The error throwing scheme consistent with what is expected of elisp
;;      programs.
;;      - Command list mode is transparent in most cases, as wherever
;;      appropriate, functions taking arguments can accept either a single item
;;      or a list of it for each argument.
;;      - Apart from this, command list functionality is limited to actions
;;      rather than queries, as it is anyway not that easy to parse out the
;;      individual responses from command-list queries (it is firstly possible
;;      only from 0.11, which allows for a list_OK to be added at the end of
;;      response for each command in the list).
;;      - command_list_ok_begin isn't implemented. It is still possible to
;;      explicitly use "command_list_(ok)begin\n..\ncommand_list_end" for
;;      `mpd-execute-command' and get the response tokens for queries. A better
;;      interface may be available in the future.
;;      - There is a small interactive interface as well, but this is
;;      intentionally incomplete. The point is that this exists only to the
;;      extent of adding an interactive part to the functions, without modifying
;;      the functions per se.

;; Most of the functions below require a connection object as an argument, which
;; you can create by a call to `mpd-conn-new'. The recommended way to use
;; customization to choose parameters for mpd connections is to use the widget
;; `mpd-connection'.

;; As this package caters to developers, it should be helpful to browse the file
;; in order for atleast the functions and the documentation. The file is well
;; structured and documented, so go for it. The impatient could do a selective
;; display to 3 (C-u 3 C-x $) before proceeding.

;;; Installation:

;; Put this file somewhere on your load-path. Then, you could use
;; (require 'libmpdee) whenever the services of this package are needed.

;; Parameters used for the interactive calls can be customized in the group mpd
;; Use:
;;         M-x customize-group mpd
;; to change the values to your liking.


;;; History: (See the SVN logs/ChangeLog for the list of all changes)

;; v2.1
;; Introducing automatic mode with hooking, for connections.
;; See `mpd-set-automatic-mode'.

;; v2.0
;; The interface has changed since version 1 of this library and there is no
;; backward compatibility. This change applies to functions which returned
;; vector whose descriptions were given `*-data' variables. Such functions have
;; been modified to return property lists, whose keys now describe the values
;; returned. This should hopefully be a much more scalable representation.

;;; Code:

(defvar libmpdee-version "2.1"
  "libmpdee version information.")

;;;; User serviceable variable(s).

(require 'custom)
(require 'wid-edit)

(defun widget-mpd-format-handler (widget esc)
  "Widget format handler for the MPD connection widget."
  (cond
   ((eq esc ?l)
    (widget-create-child-and-convert widget 'documentation-string "\
This variable specifies a MPD connection.
The value is a list of the mpd host name, port number, and the timeout for
server replies. See `mpd-conn-new' for more details.")
    (insert "To know more about libmpdee, read ")
    (widget-create 'emacs-commentary-link :tag "this" "libmpdee"))
   (t (funcall (widget-get (widget-convert 'lazy) :format-handler)
	       widget esc))))

(defun mpd-connection-tidy (val)
  "Initialize unset parameters for a MPD connection.
Replace parameters in the MPD connection VAL with sane defaults and return."
  (or val (setq val '(nil nil nil)))
  (let ((val val))
    (and (listp val)
	 (or (car val)
	     (setcar val (or (getenv "MPD_HOST") "localhost")))
	 (setq val (cdr val))
	 (or (car val) (setcar val 6600))
	 (setq val (cdr val))
	 (or (car val) (setcar val 10.0)))) val)

(define-widget 'mpd-connection 'lazy
  "A widget for a MPD connection."
  :tag "MPD Connection"
  :format "%{%t%}:\n\n%l\n\n%v"
  :format-handler 'widget-mpd-format-handler
  :value-to-internal '(lambda (wid val) (mpd-connection-tidy val))
  :type '(list :format "%v"
	       (string :format "%t: %v\n" :tag "Hostname" :size 15)
	       (integer :format "%t:     %v\n" :tag "Port" :size 5
			:match (lambda (widget value) (> value 0))
			:type-error "Port must be a natural number")
	       (float :format "%t:  %v\n\n" :tag "Timeout" :size 10
		      :match (lambda (widget value) (> value 0))
		      :type-error "Timeout must be a positive number")))

(defgroup mpd nil
  "The client end library for MPD, the music playing daemon."
  :group 'external :group 'multimedia
  :link '(emacs-commentary-link "libmpdee"))

(defcustom mpd-db-root (getenv "MPD_DB_ROOT")
  "*MPD database directory root."
  :type 'directory :group 'mpd)

(defcustom mpd-interactive-connection-parameters (mpd-connection-tidy nil)
  "Parameters for the interactive mpd connection.
These determine the connection used by interactive functions in `libmpdee'."
  :type 'mpd-connection :group 'mpd)

(defface mpd-separator-face '((((background dark)) (:foreground "lightyellow"))
			      (((background light)) (:foreground "darkgreen")))
  "Face for display of separator lines in interactive mpd queries."
  :group 'mpd)

(defface mpd-header-face '((((background dark)) (:foreground "gold"))
			   (((background light)) (:foreground "brown")))
  "Face for display of header lines in interactive mpd queries."
  :group 'mpd)

(defface mpd-first-field-face '((((background dark)) (:foreground "cyan"))
				(((background light)) (:foreground "orange")))
  "Face for display of the first field in interactive mpd queries.
Most lines in interactive displays are split into two fields."
  :group 'mpd)

(defface mpd-second-field-face
  '((((background dark)) (:foreground "lightgreen"))
    (((background light)) (:foreground "blue")))
  "Face for display of the second field in interactive mpd queries.
Most lines in interactive displays are split into two fields."
  :group 'mpd)

;;;; Constants and internal variables.

(eval-and-compile (defconst mpd-welcome-message " MPD "))
(defmacro mpd-welcome-length () (length mpd-welcome-message))
(defconst mpd-ver-string-length 3)

;;;; Package independent helper functions.

(defmacro mpd-assert-type (obj func)
  "Ensure that OBJ succeeds on type checking with predicate FUNC.
The function emits a \"Wrong type argument\" signal on failure.
Note that the arguments are evalled twice in this process."
  `(or (,func ,obj) (signal 'wrong-type-argument (list (quote ,func) ,obj))))

(defmacro mpd-assert-string (obj) `(mpd-assert-type ,obj stringp))
(defmacro mpd-assert-wholenump (obj) `(mpd-assert-type ,obj wholenump))
(defmacro mpd-assert-numberp (obj) `(mpd-assert-type ,obj numberp))

(defun mpd-string-to-number-strict (str &optional allowneg)
  "Convert string STR to a number strictly.
Return nil if there are any unmatched characters.
Allow negative numbers if ALLOWNEG is non-nil."
  (let ((num (string-to-number str)))
    (and (if allowneg (numberp num) (wholenump num))
	 (string-equal str (number-to-string num)) num)))
(put 'mpd-string-to-number-strict 'side-effect-free t)

(defun mpd-get-lines (str)
  "Split STR into newline separated lines.
Differ from `split-string' in that tokens are created
for leading and trailing newlines."
  (let ((packets (split-string str "\n")))
    (when packets
      (if (= (aref str 0) ?\n)
	  (setq packets (cons "" packets)))
      (if (= (aref str (1- (length str))) ?\n)
	  (nconc packets (list ""))
	packets))))

;;; Modified from the pcomplete package.
(defun mpd-sort-uniq-list (l lessp eqp)
  "Sort and remove multiples in list L.
Use LESSP and EQP as predicates for the \"lesser\" and \"equal\" operations."
  (setq l (sort l lessp))
  (let ((m l))
    (while m
      (while (and (cdr m) (funcall eqp (car m) (cadr m)))
	(setcdr m (cddr m)))
      (setq m (cdr m)))) l)

;;; For edebug macro specifications.
(eval-when-compile (require 'edebug))

(defmacro with-mpd-temp-widen (&rest args)
  "Evaluate ARGS while temporarily widening the current buffer."
  `(save-restriction
     (widen)
     ,@args))
(put 'with-mpd-temp-widen 'lisp-indent-function 0)
(def-edebug-spec with-mpd-temp-widen (body))

(defmacro with-mpd-free-buffer (&rest args)
  "Evaluate ARGS with temporary widening and saved excursion."
  `(save-excursion
     (with-mpd-temp-widen ,@args)))
(put 'with-mpd-free-buffer 'lisp-indent-function 0)
(def-edebug-spec with-mpd-free-buffer (body))

(defmacro mpd-safe-nreverse (list)
  "Reverse LIST if it is a list, leave alone otherwise.
Note that LIST is evaluated thrice."
  `(if (listp ,list) (nreverse ,list) ,list))

(defun mpd-seq-add (seq &optional spec &rest args)
  "Operate the sequence SEQ on SPEC depending on its type.
Add a copy of SEQ to SPEC, if it's a list and call it with SEQ as an argument
followed by other ARGS specified, if it is a function. Return SPEC."
  (if (not (functionp spec))
      (cons (copy-sequence seq) spec)
    (apply spec seq args) spec))

(defun mpd-elt-add (elt &optional spec &rest args)
  "Operate the object ELT on SPEC depending on its type.
Add ELT to SPEC, if it's a list and call it with ELT as an argument
followed by other ARGS specified, if it is a function. Return SPEC."
  (if (not (functionp spec))
      (cons elt spec)
    (apply spec elt args) spec))

(defun mpd-parse-line (str)
  "Parse line STR of form \"KEY: VALUE\" to a cons (KEY . VALUE).
Return (STR . nil) on a parse failure."
  (if (string-match "^\\([^:]*\\): ?\\(.*\\)$" str)
      (cons (match-string 1 str) (match-string 2 str))
    (cons str nil)))

(defun mpd-safe-string (str)
  "Quote and escape string STR for sending to the mpd server."
  (if str
      (let ((start 0))
	(while (string-match "[\\\"]" str start)
	  ;; We add an extra character,
	  ;; so place start a character beyond end of match.
	  (setq start (1+ (match-end 0)))
	  (setq str (replace-match "\\\\\\&" t nil str)))
	(concat "\"" str "\""))))

;;; (defun mpd-log (fmt &rest args)
;;;   (write-region (concat (apply 'format fmt args) "\n") nil "~/mpd.log" t 1))

;;; (write-region "" nil "~/mpd.log" nil 1)

;;;; Connection object internals, library users... please close ur eyes ;)

;;; A connection to mpd is represented by the vector whose elements are below:
;;; This is just for the hackers amongst you, and for my reference :)
;;; *WARNING* No program using this package should depend on this description.
;;; 0 : vector of mpd-ver-string-length version numbers
;;; 1 : process object for the connection to the server.
;;; 2 : transaction-buffer used by the process filter to handle partial recvs.
;;; 3 : list-mode - refer `mpd-execute-command'
;;; 4 : connection-status: should be t at the beginning of a command.
;;;     stringp -> Result of command, contains the message after OK/ACK
;;;                till the next end of line. No filtering occurs after this
;;;                stage is reached.
;;;     numberp -> Intermediate state, when OK/ACK has been got
;;;                but no end of line found. Then store start pos of the OK/ACK.
;;;                Hope that eol will come in a subsequent packet.
;;;     listp   -> In commandlist mode, the list is what is to be sent to the
;;;                server after the commandlist gets over.
;;; 5 : last-command-result-flag - t if OK, nil if ACK.
;;; 6 : timeout - The timeout used for replies from server.
;;; 7 : host - The name of the host used to connect to mpd.
;;; 8 : port number - The port number of mpd.
;;; 9 : automode - not of the noauto argument to `mpd-conn-new'.

;; Don't expose these macros, unless required.
(eval-when-compile
  (defmacro _mpdgv () `(aref conn 0))
  (defmacro _mpdsv (val) `(aset conn 0 ,val))
  (defmacro _mpdgo () `(aref conn 1))
  (defmacro _mpdso (val) `(aset conn 1 ,val))
  (defmacro _mpdgb () `(aref conn 2))
  (defmacro _mpdsb (val) `(aset conn 2 ,val))
  (defmacro _mpdgl () `(aref conn 3))
  (defmacro _mpdsl (val) `(aset conn 3 ,val))
  (defmacro _mpdgs () `(aref conn 4))
  (defmacro _mpdss (val) `(aset conn 4 ,val))
  (defmacro _mpdgf () `(aref conn 5))
  (defmacro _mpdsf (val) `(aset conn 5 ,val))
  (defmacro _mpdgt () `(aref conn 6))
  (defmacro _mpdst (val) `(aset conn 6 ,val))
  (defmacro _mpdgh () `(aref conn 7))
  (defmacro _mpdsh (val) `(aset conn 7 ,val))
  (defmacro _mpdgp () `(aref conn 8))
  (defmacro _mpdsp (val) `(aset conn 8 ,val))
  (defmacro _mpdga () `(aref conn 9))
  (defmacro _mpdsa (val) `(aset conn 9 ,val)))

;;;; Sanity check functions.

(defun mpd-connp (conn)
  "Return t if CONN is a connection to the mpd server."
  (and (vectorp conn) (= (length conn) 10)))
(put 'mpd-connp 'side-effect-free 'error-free)

(defun mpd-conn-strongp (conn)
  (and (mpd-connp conn)
       (vectorp (_mpdgv))
       (= (length (_mpdgv)) mpd-ver-string-length)
       (or (not (_mpdgo)) (processp (_mpdgo)))
       (stringp (_mpdgb))
       (or (not (_mpdgt)) (numberp (_mpdgt)))
       (stringp (_mpdgh))
       (wholenump (_mpdgp))))
(put 'mpd-conn-strongp 'side-effect-free 'error-free)

(defmacro mpd-assert-mpd-conn (conn) `(mpd-assert-type ,conn mpd-connp))

(defun mpd-assert-idle (conn)
  "Assert mpd connection CONN to be free to receive a command."
  (mpd-assert-mpd-conn conn)
  (or (stringp (_mpdgs))
      (error (if (listp (_mpdgs)) "Command list mode has not ended"
	       "Not done processing current command"))))

(defun mpd-end-conn (conn fmt &rest args)
  "Abort mpd conection CONN and signal error.
`format' error message using FMT and ARGS."
  (when (_mpdgo)
    (delete-process (_mpdgo))
    (_mpdso nil))
  (signal 'error (list (apply 'format fmt args))))

(defun mpd-end-cmd (conn fmt &rest args)
  "Abort current mpd command for connection CONN and signal error.
`format' error message using FMT and ARGS."
  (_mpdsf nil)
  (_mpdss (apply 'format fmt args))
  (signal 'error (list (apply 'format fmt args))))

;;;; Internal functions.

(defun mpd-process-filter (conn str)
  "Filter replies received from the mpd server.
CONN represents the connection object for which the filter is invoked.
STR is the packet received from the server to be processed.
This is an internal function, do not use this in your code."
  (cond
   ((eq (_mpdgs) t)
    (let ((start (length (_mpdgb))) status (case-fold-search nil))
      ;; Can be 4 if not for the : as mentioned below
      (setq start (if (< start 5) 0 (- start 5)))
      (_mpdsb (concat (_mpdgb) str))
      ;; The optional : in ACK accomodates the ACK: reply to a failed `add'
      ;; given by MPD servers till version 0.10.*
      (setq status (string-match "^\\(ACK:? \\|OK\\)"
				 (substring (_mpdgb) start)))
      (if status (setq status (+ status start)))
      (or (eq (_mpdgl) t)
	  (let ((packets
		 (if (not (equal status 0))
		     (mpd-get-lines (substring (_mpdgb) 0
					       (and status (1- status)))))))
	    (if status
		(progn
		  (_mpdsb (substring (_mpdgb) status))
		  (setq status 0))
	      (if (cdr packets)
		  (let ((last (last packets 2)))
		    (_mpdsb (cadr last))
		    (setcdr last nil))
		(_mpdsb (car packets))
		(setq packets nil)))
	    (cond
	     ((functionp (_mpdgl))
	      (mapcar #'(lambda (str)
			  (funcall (_mpdgl) conn (mpd-parse-line str)))
		      packets))
	     ((listp (_mpdgl))
	      (_mpdsl (nconc (mapcar #'mpd-parse-line packets) (_mpdgl))))
	     (t (error "Invalid line mode filter")))))
      (when status
	(_mpdss status)
	(mpd-process-filter conn ""))))
   ((numberp (_mpdgs))
    (_mpdsb (concat (_mpdgb) str))
    (let* ((resp-end (_mpdgs))
	   (bufend (string-match "\n" (_mpdgb) resp-end)))
      (when bufend
	(_mpdss (substring
		 (_mpdgb)
		 ;; The `4` below should be `5` if ACK: is found, see above.
		 ;; This may then leave a space before the error message.
		 (+ resp-end (if (_mpdsf (eq (aref (_mpdgb) resp-end)?O)) 2 4))
		 bufend))
	(_mpdsb (substring (_mpdgb) 0 resp-end))
	(throw 'mpd-response-over nil))))))

(defun mpd-transact (conn &optional mode input)
  "Do an I/O transacton with the mpd server.
Use connection CONN for contacting the server. MODE is as described in
`mpd-execute-command'. Send INPUT, if non-nil, to the server before waiting for
the response. This is an internal function, do not use this in your code."
  (_mpdsb "")
  (_mpdsl mode)
  (_mpdss t)
  (unwind-protect
      (let ((timeout (_mpdgt)))
	(and input (process-send-string (_mpdgo) input))
	(while (not (stringp (_mpdgs)))
	  (catch 'mpd-response-over
	    (or (accept-process-output
		 (_mpdgo) (and timeout (/ timeout 1000))
		 (and timeout (mod timeout 1000)))
		;; This essentially reduces the probability of timeout due to
		;; program suspension to a really small probability.
		(accept-process-output (_mpdgo) 0 0)
		(error "Timed out getting a response from the mpd server")))))
    (unless (stringp (_mpdgs))
      (_mpdsf nil)
      (_mpdss "")
      (_mpdsb ""))))

;;;; Low level public interface.

(defun mpd-conn-new (host port &optional timeout noauto)
  "Construct a mpd connection object from given parameters.
Connections made using this object are made to host HOST at port number PORT.
TIMEOUT is a floating-point value specifying the number of seconds to wait
before giving up waiting for a reply from the server. Unspecified or zero
TIMEOUT correspond to infinite timeout. Set automatic mode if NOAUTO is nil,
hooked automatic function if NOAUTO is a function, and do not set automatic mode
otherwise. See `mpd-set-automatic-mode' for a description of automatic mode."
  (or (and (stringp host) (wholenump port) (or (not timeout) (numberp timeout)))
      (error "Invalid parameters passed for making new connection"))
  (and timeout
       (if (= timeout 0)
	   (setq timeout nil)
	 (or (> timeout 0) (error "Invalid (negative) timeout value"))))
  ;; Declaration conn object structure dependent.
  (vector (make-vector mpd-ver-string-length nil) nil
	  "" nil "" nil (and timeout (floor (* timeout 1000)))
	  host port (if noauto (if (functionp noauto) noauto nil) t)))

(eval-when-compile
  (or (fboundp 'set-process-query-on-exit-flag)
      (defmacro set-process-query-on-exit-flag (process flag)
	`(process-kill-without-query process flag))))

(defun mpd-connect (conn)
  "Connect to the mpd server using the connection object CONN.
The connection object is constructed using `mpd-conn-new'. Note that this
function doesn't need to be explicitly called when the connection is in
automatic mode (the default). Close the connection using `mpd-close-connection'
when you are done."
  (let (proc rt welc)
    (setq proc (or (open-network-stream "mpd" nil (_mpdgh) (_mpdgp))
		   (error "Unable to open connection with mpd")))
    (and (_mpdgo) (delete-process (_mpdgo)))
    (_mpdso proc)
    (set-process-query-on-exit-flag proc nil)
    (set-process-coding-system proc 'utf-8-unix 'utf-8-unix)
    (set-process-filter proc
			`(lambda (proc str)
			   (mpd-process-filter ,conn str)))
    (unwind-protect
	(mpd-transact conn t)
      (or (_mpdgf)
	  (mpd-end-conn conn "Handshake failed, server returned: %s" (_mpdgs))))
    (setq welc (_mpdgs))
    (or (string-equal (substring welc 0 (mpd-welcome-length))
		      mpd-welcome-message)
	(mpd-end-conn conn "Process mpd not running on port %d in host \"%s\""
		      (_mpdgp) (_mpdgh)))
    (let ((verlist (split-string (substring welc (mpd-welcome-length))
				 "[\\.\n]")))
      (or (= (length verlist) mpd-ver-string-length)
	  (mpd-end-conn conn "Error parsing version information from server"))
      (let ((i 0))
	(while (< i mpd-ver-string-length)
	  (or (aset (_mpdgv) i (mpd-string-to-number-strict
				(pop verlist)))
	      (mpd-end-conn
	       conn "Error parsing version information from server"))
	  (setq i (1+ i))))))
  (message "Opened connection with mpd"))

(make-obsolete 'mpd-new-connection "use `mpd-conn-new' to create a connection \
object. If automatic mode is not used, a call to `mpd-connect' might be \
necessary." "2.1")
(defun mpd-new-connection (host port &optional timeout noauto)
  "Create a new connection and connect using it to the mpd server.
Return a connection object, which could be used for further transactions with
the server. See `mpd-conn-new' for a description of the parameters. Close the
connection using `mpd-close-connection' when you are done.

This function is deprecated since version 2.1.
Use `mpd-conn-new' to create a connection object.
If automatic mode is not used, a call to `mpd-connect' might be necessary."
  (let ((conn (mpd-conn-new host port timeout noauto)))
    (mpd-connect conn) conn))

(defun mpd-conn-wakeup (conn)
  "Try to ensure that the MPD connection is alive, when in automatic mode."
  (mpd-assert-idle conn)
  (when (and (not (and (_mpdgo) (eq (process-status (_mpdgo)) 'open)))
	     (_mpdga) (not (and (functionp (_mpdga))
				(funcall (_mpdga) conn 'pre))))
    (and (_mpdgo) (message "Connection with mpd broken, attempting reconnect"))
    (mpd-connect conn)
    (and (functionp (_mpdga)) (funcall (_mpdga) conn 'post))))

(defun mpd-execute-command (conn cmd &optional mode)
  "Send the command CMD to the mpd server using CONN.
Append a newline to CMD before sending to the server. Use the value of MODE to
decide how the response of the command is processed. MODE could take one of the
following values:
 - A list, usually nil, to which cons-cells got by formatting each line
   of the response, except the last one, using `mpd-parse-line', are appended.
   The new list thus got is the result of the function.
 - t, by which all response before the last line, as a string,
   is the result of the function.
 - A function, by which each cons-cell, got as described above, is sent to
   this function. Two parameters are passed to the function, the connection
   object and this cons-cell. An empty string is the result.
Return a cons-cell, whose car is non-nil if the server succeeds, and cdr is the
result as specified in the description of MODE above."
  (mpd-conn-wakeup conn)
  (mpd-transact conn mode (concat cmd "\n"))
  (prog1
      (cons (_mpdgf)
	    ;; Declaration conn object structure dependent.
	    (aref conn (if (_mpdgf) (if (or (eq (_mpdgl) 't)
					    (functionp (_mpdgl))) 2 3) 4)))
    (_mpdsb "")))

(defun mpd-simple-exec (conn cmd)
  "Execute mpd command CMD using CONN ignoring response.
Note that an OK/ACK message still has to come. Return non-nil iff the command
succeeds. `mpd-get-last-error' gives the server error message in case of
failure. See also `mpd-execute-command'."
  (if (not (listp (_mpdgs)))
      (car (mpd-execute-command conn cmd t))
    (_mpdss (cons cmd (_mpdgs))) t))

(defun mpd-close-connection (conn)
  "Close the mpd server connection given by CONN."
  (mpd-assert-idle conn)
  (when (_mpdgo)
    (delete-process (_mpdgo))
    (_mpdso nil)))

(defvar mpd-inter-conn
  (apply 'mpd-conn-new `(,@(mpd-connection-tidy
			    mpd-interactive-connection-parameters) nil))
  "The global mpd connection used for interactive queries.")

(defsubst mpd-get-version (conn)
  "Get version information for the mpd server CONN is connected to.
Return a vector of three numbers, for the major, minor and patch levels."
  (mpd-assert-mpd-conn conn)
  (or (aref (_mpdgv) 0) (mpd-conn-wakeup conn))
  (_mpdgv))
(put 'mpd-get-version 'side-effect-free t)

(defsubst mpd-get-last-error (conn)
  "Get the last server error message for mpd connection CONN.
Return nil in case of a successful last command."
  (mpd-assert-mpd-conn conn)
  (and (not (_mpdgf)) (_mpdgs)))
(put 'mpd-get-last-error 'side-effect-free t)

(defsubst mpd-get-connection-timeout (conn)
  "Get the timeout of mpd connection CONN.
Return nil if CONN isn't a mpd connection object."
  (mpd-assert-mpd-conn conn)
  (_mpdgt))
(put 'mpd-get-connection-timeout 'side-effect-free t)

;;;###autoload
(defun mpd-set-connection-timeout (conn timeout)
  "Set the timeout of mpd connection object CONN to TIMEOUT.
See also `mpd-new-connection'."
  (interactive
   (list mpd-inter-conn
	 (string-to-number
	  (read-string
	   "Connection timeout (None): "
	   (let ((timeout (mpd-get-connection-timeout mpd-inter-conn)))
	     (and timeout (number-to-string timeout)))))))
  (if (or (not (mpd-connp conn)) (and timeout (not (numberp timeout))))
      (error "Invalid parameters used to set connection timeout")
    (and (= timeout 0) (setq timeout nil))
    (_mpdst timeout)))

(defsubst mpd-get-automatic-mode (conn)
  "Return the automatic mode value for mpd connection CONN.
See `mpd-set-automatic-mode' for a description of automatic mode. Return value
is like the MODE parameter of that function."
  (mpd-assert-mpd-conn conn)
  (_mpdga))
(put 'mpd-get-automatic-mode 'side-effect-free t)

(defsubst mpd-set-automatic-mode (conn mode)
  "Set the automatic mode for mpd connection CONN.
Set automatic mode iff MODE is non-nil. Set to hooked automatic mode if the
non-nil MODE is a function.

The connection is said to be in automatic mode if it connects on demand (usually
as a result of a server request using the connection) and takes care of
reconnecting whenever the connection gets broken. The automatic mode could be
hooked by specifying a function. In this case, the function is called with two
parameters, the connection object and the second parameter being the symbol 'pre
or 'post. The function is called with 'pre when reconnection is needed. If the
function returns a non-nil value, it is assumed that the function has done the
reconnection. Else, the library reconnects by itself, and the function is once
again called after that, with the parameter 'post (Return value is ignored)."
  (mpd-assert-mpd-conn conn)
  (_mpdsa mode))

(make-obsolete 'mpd-get-reconnectible 'mpd-get-automatic-mode "2.1")
(defalias 'mpd-get-reconnectible 'mpd-get-automatic-mode
  "Return t if CONN reconnects when its mpd connection breaks.
This function is deprecated since version 2.1.
Use `mpd-get-automatic-mode' instead.")

(make-obsolete 'mpd-make-reconnectible 'mpd-set-automatic-mode "2.1")
(defsubst mpd-make-reconnectible (conn &optional noreconn)
  "Make CONN reconnectible when its mpd connection breaks.
Unset the reconnectibility on non-nil prefix arg NORECONN.
This function is deprecated since version 2.1.
Use `mpd-set-automatic-mode' instead."
  (mpd-set-automatic-mode conn (not noreconn)))

(defun mpd-force-accept-command (conn)
  "Force the mpd connection CONN to accept the next command.
*WARNING* DON'T use this unless you are really desperate. Shelf this off for
debugging purposes. Normally, the package should signal correctly whether it is
safe to receive the next command. Doing this could mean losing out on the
response of the current command, and worse, the response of the current command
could creep into the next one."
  (if (mpd-command-list-mode-p conn)
      (error "Command list mode has not ended")
    (_mpdsf nil)
    (_mpdss "")
    (_mpdsb "")))

(defun mpd-command-list-begin (conn)
  "Start the command-list mode for CONN.
Only commands that can be used with `mpd-simple-exec' are allowed in
command-list mode. Commands can be issued as they are usually done.
Always return t, as the commands are queued up and not sent to the server.
`mpd-command-list-end' ends the command-list and executes the list built up."
  (mpd-assert-idle conn)
  (_mpdsf nil)				; FIXME: Why is this here ??
  (_mpdss nil))

(defun mpd-command-list-mode-p (conn)
  "Return non-nil if mpd connection CONN is in command list mode."
  (mpd-assert-mpd-conn conn)
  (listp (_mpdgs)))
(put 'mpd-command-list-mode-p 'side-effect-free t)

(defun mpd-command-list-end (conn)
  "End command-list mode for CONN.
This function needs to be preceded by a call to `mpd-command-list-begin'."
  (or (mpd-command-list-mode-p conn)
      (error "The connection is not in command-list mode"))
  (let (str)
    (setq str (concat "command_list_begin\n"
		      (mapconcat #'(lambda (item) item) (nreverse (_mpdgs)) "\n")
		      "\ncommand_list_end"))
    (_mpdss "")
    (mpd-simple-exec conn str)))

(defun mpd-connection-status (conn)
  "Get the status of mpd connection CONN.
Return one of 'busy for being in the midst of a request, 'ready for the ready
state, and 'command-list to indicate being in command-list mode."
  (mpd-assert-mpd-conn conn)
  (cond
   ((listp (_mpdgs)) 'command-list)
   ((stringp (_mpdgs)) 'ready)
   (t 'busy)))
(put 'mpd-connection-status 'side-effect-free t)

(defmacro with-mpd-timeout-disabled (&rest args)
  `(progn
     (mpd-assert-mpd-conn conn)
     (let ((timeout (_mpdgt)))
       (unwind-protect
	   (progn
	     (_mpdst nil)
	     ,@args)
	 (_mpdst timeout)))))
(put 'with-mpd-timeout-disabled 'lisp-indent-function 0)
(def-edebug-spec with-mpd-timeout-disabled (body))

;;; High level public interface helper functions.

;;; Silence the compiler.
(defvar mpd-song-receiver)
(defvar foreach)
(defvar mpd-song-receiver-args)

(defun mpd-song-receiver (conn cell)
  "Handle song data response from the mpd server.
See `mpd-execute-command' for a description of response handlers.
This is an internal function, do not use this in your code."
  (let ((key (car cell)))
    (unless (or (string-equal key "directory")
		(string-equal key "playlist"))
      (when (string-equal key "file")
	(when (plist-get mpd-song-receiver 'file)
	  (setq foreach (apply 'mpd-seq-add mpd-song-receiver
			       foreach mpd-song-receiver-args)))
	(setq mpd-song-receiver nil))
      (setq mpd-song-receiver
	    (plist-put mpd-song-receiver (intern key)
		       (if (member key '("Time" "Pos" "Id"))
			   (string-to-number (cdr cell)) (cdr cell)))))))

(defun mpd-get-songs (conn cmd &optional foreach)
  "Get details of songs from the mpd server using connection CONN.
Use command CMD to get the songs. Call function FOREACH, if specified, for each
song, with the song provided as the argument. Return list of all songs if
FOREACH is not specified and FOREACH otherwise. When a list is returned, each
element of the list is a property list, some known keys being `file', `Pos' and
`Id'. The last two keys, along with `Time' if present, have integers as their
value. `Time' refers to the total length of the song. `Pos' and `Id' are present
only when the song retrieved is a part of a playlist. Other song tag data might
be present as well."
  (or (functionp foreach) (setq foreach nil))
  (let (mpd-song-receiver mpd-song-receiver-args)
    (mpd-execute-command conn cmd 'mpd-song-receiver)
    (and mpd-song-receiver
	 (setq foreach (mpd-seq-add mpd-song-receiver foreach)))
    (mpd-safe-nreverse foreach)))

(defun mpd-make-cmd-concat (cmd arg &optional normal-nil)
  "Make mpd command string using command CMD and argument ARG.
ARG could be a string or a list of strings. If NORMAL-NIL is non-nil, do nothing
if ARG is nil, and return CMD for nil NORMAL-NIL and ARG. Use command list
mode implicitly for lists. Sanitize arguments before composition.
This is an internal function, do not use this in your code."
  (cond
   ((not (or arg normal-nil)) cmd)
   ((listp arg)
    (concat "command_list_begin\n"
	    (mapconcat #'(lambda (item) (concat cmd " " (mpd-safe-string item)))
		       arg "\n") "\ncommand_list_end"))
   (t (concat cmd " " (mpd-safe-string arg)))))
(put 'mpd-make-cmd-concat 'side-effect-free t)

(defun mpd-make-cmd-format (cmd validate arg1 &optional arg2)
  "Make mpd command string with format CMD and arguments ARG1, ARG2.
ARG1/ARG2 could be a list of arguments each. Use command list mode implicitly
for lists. Send each of the arguments pairs to VALIDATE before composition.
This is an internal function, do not use this in your code."
  (if (listp arg1)
      (let ((tail2 arg2))
	(and arg2 (or (= (length arg1) (length arg2))
		      (error "Argument lists are of unequal lengths")))
	(concat "command_list_begin\n"
		(mapconcat #'(lambda (item)
			       (and validate (funcall validate item (car tail2)))
			       (prog1
				   (format cmd item (car tail2))
				 (setq tail2 (cdr tail2)))) arg1 "\n")
		"\ncommand_list_end"))
    (and validate (funcall validate arg1 arg2))
    (format cmd arg1 arg2)))

;;; Helper functions for interactive display.

(defun mpd-line-to-buffer (str)
  "Insert STR as a line to the mpd display buffer."
  (with-current-buffer (get-buffer-create "*mpd-display*")
    (with-mpd-free-buffer
      (goto-char (point-max))
      (insert (concat str "\n"))
      (display-buffer (current-buffer)))))

(defsubst mpd-separator-line (&optional num)
  "Make a separator line for insertion to the mpd display buffer.
The number of columns used is 80, unless specified using NUM."
  (propertize (concat (make-string (or num 80) ?*) "\n")
	      'face 'mpd-separator-face))

(defun mpd-init-buffer (&optional str1 str2 str3)
  "Initialize the mpd display buffer using strings STR1, STR2, STR3.
Layout as follows:
	STR1 		if non-empty
	***...*** 	if STR1 is non-nil
	STR2 		if non-empty
	***...*** 	if STR2 is non-nil
	STR3		if non-empty"
  (let ((max (max (length str1) (length str2) (length str3))))
    (with-current-buffer (get-buffer-create "*mpd-display*")
      (erase-buffer)
      (insert
       (concat "\n" (and str1 (not (string-equal str1 ""))
			 (propertize (concat str1 "\n") 'face 'mpd-header-face))
	       (and str1 (mpd-separator-line max))
	       (and str2 (propertize (concat str2 "\n") 'face 'mpd-header-face))
	       (and str3 (mpd-separator-line max))
	       (and str3 (not (string-equal str3 ""))
		    (propertize (concat str3 "\n")
				'face 'mpd-header-face)) "\n")))))

(defun mpd-render-field (desc val &optional nosep)
  "Format to a colorized line of form \"\\nDESC: VAL\".
Include the separating colon unless NOSEP is non-nil."
  (and val (not (string-equal val ""))
       (concat (propertize desc 'face 'mpd-first-field-face)
	       (and (not nosep) ": ")
	       (propertize val 'face 'mpd-second-field-face) "\n")))
(put 'mpd-render-field 'side-effect-free t)

(defun mpd-render-plist (plist table)
  "Display property list PLIST as a pretty table in the display buffer.
TABLE is a list of entries is used to translate between keys and strings
displayed. Each entry of the table is a list of the key symbol, the
corresponding string to display, and optionally a function to call with the
value to get the string to display as the value. If the string to display is
nil, then those keys are ignored and not displayed at all."
  (when plist
    (let ((ptr plist) (str "") key value entry trans filter)
      (while ptr
	(setq key (car ptr))
	(setq value (cadr ptr))
	(when (and key value)
	  (setq entry (assq key table))
	  (setq trans (if entry (cadr entry) (symbol-name key)))
	  (setq filter (cadr (cdr entry)))
	  (when trans
	    (setq str (concat str (mpd-render-field
				   (format "%-13s" trans)
				   (format "%s" (if filter
						    (funcall filter value)
						  value)))))))
	(setq ptr (cddr ptr)))
      (mpd-line-to-buffer (concat str "\n" (mpd-separator-line))))))

(defconst mpd-display-song-key-table
  '((Time "Length" (lambda (time) (format "%s seconds" time)))
    (file "Filename")
    (Pos)
    (Id)))

(defsubst mpd-display-song (song)
  "Display mpd song data SONG in the mpd display buffer."
  (mpd-render-plist song mpd-display-song-key-table))

(defun mpd-display-playlist-item (title num)
  "Display playlist item with TITLE and index NUM in mpd buffer."
  (mpd-line-to-buffer
   (concat (propertize (format "%4d  " (1+ num)) 'face 'mpd-first-field-face)
	   (propertize title 'face 'mpd-second-field-face))))

(defun mpd-display-dir-info (item type)
  "Display mpd directory information to the mpd display buffer."
  (if (eq type 'file)
      (mpd-display-song item)
    (mpd-line-to-buffer
     (concat (mpd-render-field
	      (if (eq type 'playlist) "Playlist    " "Directory   ") item)
	     "\n" (mpd-separator-line)))))

(defun mpd-display-dir-listing (item dir)
  "Display mpd directory listing to the mpd display buffer."
  (mpd-line-to-buffer
   (concat (mpd-render-field (if dir "Directory " "File      " ) item)
	   "\n" (mpd-separator-line))))

(defsubst mpd-display-bullet (str)
  "Display a bulleted line to the mpd display buffer."
  (mpd-line-to-buffer (mpd-render-field " o " (format "%s" str) t)))

(defconst mpd-display-output-key-table
  '((outputid "ID")
    (outputname "Name")
    (outputenabled "Enabled"
		   (lambda (enabled)
		     (cond
		      ((eq enabled t) "Yes")
		      ((eq enabled nil) "No")
		      (t enabled))))))

(defsubst mpd-display-output (output)
  "Display mpd output OUTPUT in the mpd display buffer."
  (mpd-render-plist output mpd-display-output-key-table))

(defun mpd-read-item (prompt &optional default zero allowneg)
  "Read a number from the minibuffer.
Display PROMPT as the prompt string prefix. Append the DEFAULT value,
if present, in brackets. Return the number read. Unless ZERO is non-nil,
add default value by one before operation, and decrement number read
by 1 before returning. If ALLOWNEG is non-nil, allow negative numbers."
  (let (num str)
    (and default (setq str (number-to-string (if zero default (1+ default)))))
    (setq
     num (mpd-string-to-number-strict
	  (read-string (concat prompt (if default (concat " (" str ")")) ": ")
		       nil nil str) allowneg))
    (if (and num (not zero)) (1- num) num)))

;;;; High level public interface.

;;;  These functions require response, and hence cannot be queued by using the
;;;  command-line mode.

(defun mpd-status-receiver (lsym cell)
  "Handle response for the 'status' command to the mpd server.
See `mpd-execute-command' for a description of response handlers.
This is an internal function, do not use this in your code."
  (let ((sym (car cell)))
    (cond
     ((member sym '("volume" "repeat" "random" "playlist" "playlistlength"
		    "bitrate" "song" "songid" "xfade" "updating_db"))
      (put lsym (intern sym) (string-to-number (cdr cell))))
     ((string-equal sym "state")
      (and (member (cdr cell) '("play" "pause" "stop"))
	   (put lsym (intern sym) (intern (cdr cell)))))
     ((string-equal sym "time")
      (when (string-match "^\\([0-9]*\\):\\([0-9]*\\)$" (cdr cell))
	(put lsym 'time-elapsed (string-to-number (match-string 1 (cdr cell))))
	(put lsym 'time-total (string-to-number (match-string 2 (cdr cell))))))
     ((string-equal sym "audio")
      (when (string-match "^\\([0-9]*\\):\\([0-9]*\\):\\([0-9]*\\)$" (cdr cell))
	(put lsym 'sample-rate (string-to-number (match-string 1 (cdr cell))))
	(put lsym 'bits-per-sample
	     (string-to-number (match-string 2 (cdr cell))))
	(put lsym 'channels (string-to-number (match-string 3 (cdr cell))))))
     ;; currently only "error"
     (t (put lsym (intern sym) (cdr cell))))))

(defun mpd-get-status (conn)
  "Get status of the mpd server, using connection CONN.
Return a property list, the known keys being `volume', `repeat', `random',
`playlist', `playlistlength', `bitrate', `song', `songid', `xfade', `state',
`time-elapsed', `time-total', `sample-rate', `bits-per-sample', `channels'
and `error'. Other keys might be present in the plist depending on the version
of MPD used. Some of the less obvious descriptions are:

+-----------+------------------------------------------------------------------+
| playlist  |The playlist version number - a 'checksum' for the current        |
|           |playlist, guaranteed to change after a change in the playlist.    |
+-----------+------------------------------------------------------------------+
|  xfade    |The crossfade time in seconds between two songs occurs. This value|
|           |could be zero in case of no crossfade.                            |
+-----------+------------------------------------------------------------------+
|   song    |Position of the current song in the playlist.                     |
+-----------+------------------------------------------------------------------+
|  songid   |Song ID of the current song in the playlist.                      |
+-----------+------------------------------------------------------------------+
|  state    |Could be one of 'play, 'pause or 'stop                            |
+-----------+------------------------------------------------------------------+
|updating_db|The updating job id, displayed when there is a update taking      |
|           |place.                                                            |
+-----------+------------------------------------------------------------------+
|  error    |A description of the error, if one occurs. Could be nil, in case  |
|           |there is no error.                                                |
+-----------+------------------------------------------------------------------+

All fields except error and state are whole numbers. `repeat' and `random' are
in addition, bi-state variables (0/1)"
  (setplist 'mpd-get-status-local-sym nil)
  (mpd-execute-command
   conn "status" '(lambda (conn cell)
		    (mpd-status-receiver 'mpd-get-status-local-sym cell)))
  (symbol-plist 'mpd-get-status-local-sym))

(defun mpd-stats-receiver (lsym cell)
  "Handle response for the 'stats' command to the mpd server.
See `mpd-execute-command' for a description of response handlers.
This is an internal function, do not use this in your code."
  (let ((sym (car cell)))
    (cond
     ((member sym '("artists" "albums" "songs" "uptime"
		    "playtime" "db_playtime" "db_update"))
      (put lsym (intern sym) (string-to-number (cdr cell))))
     (t (put lsym (intern sym) (cdr cell))))))

(defun mpd-get-stats (conn)
  "Get statistics for the mpd server connected using CONN.
Return a property list, the known keys being `artists', `albums', `songs',
`db_playtime' corresponding to the number of artists, albums and songs and the
total time in seconds of all songs in the database respectively; `db_update',
the time stamp of the last update to the database; `playtime', the total time
for which music has been played in seconds and `uptime', the server uptime,
in seconds as well. Other keys might be present in the plist depending on the
version of MPD used."
  (setplist 'mpd-get-stats-local-sym nil)
  (mpd-execute-command
   conn "stats" '(lambda (conn cell)
		   (mpd-stats-receiver 'mpd-get-stats-local-sym cell)))
  (symbol-plist 'mpd-get-stats-local-sym))

;;;###autoload
(defun mpd-get-playlist (conn &optional foreach)
  "Get all songs in the current playlist managed by the mpd server.
CONN and FOREACH are as in `mpd-get-songs'."
  (interactive (progn (mpd-init-buffer "" "Current MPD Playlist" "")
		      (list mpd-inter-conn 'mpd-display-playlist-item)))
  (or (functionp foreach) (setq foreach nil))
  (mpd-execute-command
   conn "playlist" '(lambda (conn cell)
		      (setq foreach (mpd-elt-add
				     (cdr cell) foreach
				     (string-to-number (car cell))))))
  (mpd-safe-nreverse foreach))

;;;###autoload
(defun mpd-get-playlist-entry (conn &optional item foreach use-id)
  "Get song data for entr(y/ies) ITEM in the current mpd playlist.
CONN, FOREACH and the return value are as in `mpd-get-songs'.
ITEM is the item position/id or a list of it. Note that ITEM as nil fetches
data for all entries in the current playlist rather than not doing anything.
Interpret ITEM as song id(s) iff USE-ID is non-nil."
  (interactive
   (let ((item (mpd-read-item
		"Enter item number"
		(plist-get (mpd-get-status mpd-inter-conn) 'song))))
     (mpd-init-buffer "" (format "MPD Playlist Item # %d" (1+ item)) "")
     (list mpd-inter-conn item 'mpd-display-song)))
  (setq use-id (if use-id "playlistid" "playlistinfo"))
  (mpd-get-songs
   conn (if item
	    (mpd-make-cmd-format
	     (concat use-id " %d")
	     '(lambda (item item2) (mpd-assert-wholenump item))
	     item) use-id) foreach))

;;;###autoload
(defun mpd-get-current-song (conn &optional foreach)
  "Get song data for the current song in mpd.
CONN and FOREACH are as in `mpd-get-songs'. Return FOREACH if specified, and
the current song (see `mpd-get-songs' for how a song is represented) otherwise."
  (interactive (progn (mpd-init-buffer "" "Current MPD Song" "")
		      (list mpd-inter-conn 'mpd-display-song)))
  (setq foreach (mpd-get-songs conn "currentsong" foreach))
  (or (functionp foreach) (setq foreach (car foreach))) foreach)

(defun mpd-get-playlist-changes (conn version &optional foreach nometa)
  "Get a list of changed song entries in the current mpd playlist.
CONN, FOREACH and the return value are as in `mpd-get-songs'.
Calculate the change between the current playlist and the playlist
with version number VERSION. Do not fetch complete metadata (only position and
song id is returned for each song) if NOMETA is non-nil."
  (mpd-assert-numberp version)
  (mpd-get-songs conn (format "%s %d" (if nometa "plchangesposid" "plchanges")
			      version) foreach))

;;;###autoload
(defun mpd-get-directory-songs (conn &optional directory foreach)
  "Get all songs in a directory of the mpd database.
CONN, FOREACH and the return value are as in `mpd-get-songs'.
DIRECTORY is the relative directory path wrt the database root.
DIRECTORY could be a list as well, the action then corresponds to all songs
in all the directories. Note that the nil value for DIRECTORY corresponds
to the database toplevel rather than an empty list."
  (interactive
   (let ((str (read-string "Enter relative directory: ")))
     (progn (mpd-init-buffer "" (concat "Songs in directory " str) "")
	    (list mpd-inter-conn str 'mpd-display-song))))
  (mpd-get-songs
   conn (mpd-make-cmd-concat "listallinfo" directory) foreach))

;;;###autoload
(defun mpd-get-directory-info (conn &optional directory foreach)
  "Get directory info for DIRECTORY in the mpd database.
Use CONN as the mpd connection for the purpose and call function FOREACH,
if specified, with each information field. The arguments passed to FOREACH is a
song object, directory string or playlist string and one of the symbols 'file,
'playlist or 'directory describing the data sent. DIRECTORY could be a list as
well, the action then corresponds information for all the directories. Note that
a nil for DIRECTORY corresponds to the database toplevel rather than an empty
list. Return FOREACH, if non-nil; else a vector of three elements: a list of
songs in the directory (see `mpd-get-songs' for how a song is represented),
a list of playlists and a list of subdirectories."
  (interactive
   (let ((str (read-string "Enter relative directory: ")))
     (progn (mpd-init-buffer "" (concat "Information on directory " str) "")
	    (list mpd-inter-conn str 'mpd-display-dir-info))))
  (or (functionp foreach) (setq foreach nil))
  (let (filemode (pl foreach) (dir foreach)
		 (mpd-song-receiver-args '(file)) mpd-song-receiver)
    (mpd-execute-command
     conn (mpd-make-cmd-concat "lsinfo" directory)
     '(lambda (conn cell)
	(if (string-equal (car cell) "directory")
	    (setq dir (mpd-elt-add (cdr cell) dir 'directory))
	  (if (string-equal (car cell) "playlist")
	      (setq pl (mpd-elt-add (cdr cell) pl 'playlist))
	    (mpd-song-receiver conn cell)))))
    (and mpd-song-receiver
	 (setq foreach (mpd-seq-add mpd-song-receiver foreach 'file)))
    (if (functionp foreach) foreach
      (vector (nreverse foreach) (nreverse pl) (nreverse dir)))))

;;;###autoload
(defun mpd-list-directory-recursive (conn foreach &optional directory)
  "Get the file-directory hierarchy of a directory in the mpd database.
Use CONN for the connection and use function FOREACH to report each entry,
along with a non-nil second argument if the entry is a directory. DIRECTORY
could be a list as well, the action then corresponds to listing of all the
directories. Note that the nil value for DIRECTORY corresponds to the
database toplevel rather than an empty list."
  (interactive
   (let ((str (read-string "Enter relative directory: ")))
     (progn
       (mpd-init-buffer "" (concat "Recursive listing of directory " str) "")
       (list mpd-inter-conn 'mpd-display-dir-listing str))))
  (mpd-assert-type foreach functionp)
  (mpd-execute-command conn (mpd-make-cmd-concat "listall" directory)
		       '(lambda (conn cell)
			  (funcall foreach (cdr cell)
				   (string-equal (car cell) "directory")))))

;;;###autoload
(defun mpd-search (conn by for &optional foreach)
  "Search for songs in the mpd database.
CONN, FOREACH and the return values are as in `mpd-get-songs'.
The valid values for BY are 'artist, 'album and 'title;
indicating the field to search for; and FOR is the search string.
If FOR is a non-empty list, search by BY for all FOR."
  (interactive
   (let ((reqb (intern-soft
		(completing-read "Search by: "
				 '(("artist") ("album") ("title")) nil t)))
	 (reqf (read-string "Search for: ")))
     (mpd-init-buffer "" (format "Search results for %s %s" reqb reqf) "")
     (list mpd-inter-conn reqb reqf 'mpd-display-song)))
  (or (eq by 'artist) (eq by 'album) (eq by 'title)
      (error "Invalid mpd search field %s" by))
  (mpd-get-songs
   conn
   (mpd-make-cmd-concat (concat "find " (symbol-name by)) for t) foreach))

;;;###autoload
(defun mpd-get-artists (conn &optional foreach)
  "Get the names of all artists whose songs are in the mpd database.
Use CONN for the connection, and call function FOREACH, if specified, with
each name. If FOREACH is a function, return FOREACH, else return a list of
artist names."
  (interactive
   (progn
     (mpd-init-buffer "" "List of artists" "")
     (list mpd-inter-conn 'mpd-display-bullet)))
  (or (functionp foreach) (setq foreach nil))
  (mpd-execute-command
   conn "list artist"
   '(lambda (conn cell)
      (and (string-equal (car cell) "Artist")
	   (setq foreach (mpd-elt-add (cdr cell) foreach)))))
  (mpd-safe-nreverse foreach))

;;;###autoload
(defun mpd-get-artist-albums (conn &optional artist foreach)
  "Get all albums in the mpd database featuring artist(s) ARTIST.
Get all albums if ARTIST is not specified. If ARTIST is a list, find the albums
of all the artists in the list. Use CONN for the connection, and call function
FOREACH, if specified, with each name. If FOREACH is a function, return FOREACH,
else return the list of albums."
  (interactive
   (let ((str (read-string "Name of the artist (All): ")))
     (and (string-equal str "") (setq str nil))
     (mpd-init-buffer "" (if str (concat "Albums of artist " str)
			   "List of albums") "")
     (list mpd-inter-conn str 'mpd-display-bullet)))
  (or (functionp foreach) (setq foreach nil))
  (mpd-execute-command
   conn (mpd-make-cmd-concat "list album" artist)
   '(lambda (conn cell)
      (and (string-equal (car cell) "Album")
	   (setq foreach (mpd-elt-add (cdr cell) foreach)))))
  (mpd-safe-nreverse foreach))

;;;###autoload
(defun mpd-get-handled-remote-url-prefixes (conn &optional foreach)
  "Use CONN to query remote URL prefixes handled by the mpd server.
Call function FOREACH, if specified, with each prefix.
If FOREACH is a function, return FOREACH, else return the URL prefixes."
  (interactive
   (progn
     (mpd-init-buffer "" "List of remote URL prefixes handled" "")
     (list mpd-inter-conn 'mpd-display-bullet)))
  (or (functionp foreach) (setq foreach nil))
  (mpd-execute-command
   conn "urlhandlers"
   '(lambda (conn cell)
      (and (string-equal (car cell) "handler")
	   (setq foreach (mpd-elt-add (cdr cell) foreach)))))
  (mpd-safe-nreverse foreach))

(defvar mpd-output-receiver)

(defun mpd-output-receiver (conn cell)
  "Handle output descriptions from the mpd server.
See `mpd-execute-command' for a description of response handlers.
This is an internal function, do not use this in your code."
  (let ((key (car cell)))
    (when (string-equal key "outputid")
      (when (plist-get mpd-output-receiver 'outputid)
	(setq foreach (apply 'mpd-seq-add mpd-output-receiver foreach)))
      (setq mpd-output-receiver nil))
    (setq mpd-output-receiver
	  (plist-put mpd-output-receiver (intern key)
		     (cond
		      ((string-equal key "outputid")
		       (string-to-number (cdr cell)))
		      ((string-equal key "outputenabled")
		       (cond
			((string-equal (cdr cell) "0") nil)
			((string-equal (cdr cell) "1") t)
			(t (cdr cell))))
		      (t (cdr cell)))))))

;;;###autoload
(defun mpd-get-outputs (conn &optional foreach)
  "Get output descriptions from the mpd server using connection CONN.
Call function FOREACH, if specified, for each output, with the output provided
as the argument. Return list of all outputs if FOREACH is not specified and
FOREACH otherwise. When a list is returned, each element of the list is a
property list, some known keys being `outputid' (integer), `outputname' (string)
and `outputenabled' (boolean)."
  (interactive
   (progn
     (mpd-init-buffer "" "List of outputs" "")
     (list mpd-inter-conn 'mpd-display-output)))
  (or (functionp foreach) (setq foreach nil))
  (let (mpd-output-receiver)
    (mpd-execute-command conn "outputs" 'mpd-output-receiver)
    (and mpd-output-receiver
	 (setq foreach (mpd-seq-add mpd-output-receiver foreach)))
    (mpd-safe-nreverse foreach)))

;;; These are command functions. These functions can be queued by using the
;;; command-list mode. See `mpd-command-list-begin' and `mpd-command-list-end'.

(defun mpd-file-to-mpd-resource (file)
  "Convert FILE to a resource string understood by mpd."
  (let ((prefixes
	 (mpd-get-handled-remote-url-prefixes mpd-inter-conn)) length)
    (catch
	'mpd-enqueue-is-url
      (while prefixes
	(setq length (length (car prefixes)))
	(and (>= (length file) length)
	     (string-equal (substring file 0 length) (car prefixes))
	     (throw 'mpd-enqueue-is-url file))
	(setq prefixes (cdr prefixes)))
      (file-relative-name file mpd-db-root))))

;;;###autoload
(defun mpd-enqueue (conn res)
  "Enqueue resource RES (or list of RES) to the mpd playlist.
Each of RES can be a file or a directory in the mpd database, or an URL."
  (interactive
   (list mpd-inter-conn
	 (if (and (stringp mpd-db-root) (not (string-equal mpd-db-root "")))
	     (mpd-file-to-mpd-resource
	      (read-file-name "Enqueue what: "
			      (file-name-as-directory mpd-db-root)))
	   (read-string "Enqueue what: "))))
  (mpd-simple-exec conn (mpd-make-cmd-concat "add" res)))

;;;###autoload
(defun mpd-delete (conn pos &optional use-id never-sort)
  "Delete song at position/id POS from the mpd playlist.
Interpret POS as a list of song id's if USE-ID is non-nil. POS could be a list
to delete as well. If POS is a list and USE-ID is nil, sort it in descending
order and remove duplicates before proceeding, unless NEVER-SORT is non-nil.
Note that this is necessary for the correctness of the deletion, and NEVER-SORT
is only provided in case the arguments already satisfy the condition."
  (interactive (list mpd-inter-conn (mpd-read-item "Enter item to be deleted")))
  ;; Deletion changes the playlist ordering of all those below the deleted item.
  ;; Hence, sort and uniquify the list in descending order.
  (and (not (or use-id (not (listp pos)) never-sort))
       (setq pos (mpd-sort-uniq-list pos '> '=)))
  (mpd-simple-exec
   conn
   (mpd-make-cmd-format (if use-id "deleteid %d" "delete %d")
			'(lambda (item ig) (mpd-assert-wholenump item)) pos)))

;;;###autoload
(defun mpd-save-playlist (conn file)
  "Save current mpd playlist to FILE (or list of FILE)."
  (interactive (list mpd-inter-conn (read-string "Save playlist to: ")))
  (mpd-simple-exec conn (mpd-make-cmd-concat "save" file t)))

;;;###autoload
(defun mpd-load-playlist (conn plname)
  "Load playlist PLNAME (or list of PLNAME) to the mpd server."
  (interactive (list mpd-inter-conn (read-string "Load playlist: ")))
  (mpd-simple-exec conn (mpd-make-cmd-concat "load" plname t)))

;;;###autoload
(defun mpd-remove-playlist (conn plname)
  "Remove playlist PLNAME from the mpd playlist directory.
PLNAME could as well be a list of playlist names."
  (interactive (list mpd-inter-conn (read-string "Remove playlist: ")))
  (mpd-simple-exec conn (mpd-make-cmd-concat "rm" plname t)))

;;;###autoload
(defun mpd-shuffle-playlist (conn)
  "Shuffle current mpd playlist using connection CONN."
  (interactive (list mpd-inter-conn))
  (mpd-simple-exec conn "shuffle"))

;;;###autoload
(defun mpd-clear-playlist (conn)
  "Clear current mpd playlist using connection CONN."
  (interactive (list mpd-inter-conn))
  (mpd-simple-exec conn "clear"))

;;;###autoload
(defun mpd-play (conn &optional pos use-id)
  "Play song at position/id POS (default first) in the mpd playlist.
Interpret POS as a song id iff USE-ID is non-nil."
  (interactive (list mpd-inter-conn (mpd-read-item "Enter item to play" 0)))
  (and pos (mpd-assert-wholenump pos))
  (mpd-simple-exec
   conn (concat (if use-id "playid" "play")
		(and pos (concat " " (number-to-string pos))))))

;;;###autoload
(defun mpd-stop (conn)
  "Stop playing the current mpd playlist."
  (interactive (list mpd-inter-conn))
  (mpd-simple-exec conn "stop"))

;;;###autoload
(defun mpd-pause (conn &optional arg)
  "Toggle the pause state of the current mpd playlist.
If prefix argument ARG is non-nil, pause iff ARG is positive
and resume playing otherwise."
  (interactive (list mpd-inter-conn current-prefix-arg))
  (mpd-simple-exec
   conn
   (if arg
       (format "pause %d" (if (> (prefix-numeric-value arg) 0) 1 0))
     "pause")))

;;;###autoload
(defun mpd-next (conn)
  "Play next song in the current mpd playlist."
  (interactive (list mpd-inter-conn))
  (mpd-simple-exec conn "next"))

;;;###autoload
(defun mpd-prev (conn)
  "Play previous song in the current mpd playlist."
  (interactive (list mpd-inter-conn))
  (mpd-simple-exec conn "previous"))

;;;###autoload
(defun mpd-move (conn from to &optional use-id)
  "Move item from position/id FROM in the current mpd playlist to TO.
For lists of FROM and TO, do action in that order for each pair of items.
Interpret FROM as a list of song ids iff USE-ID is non-nil. Retain TO as a list
of positions irrespective of the value of USE-ID. If sending a list for FROM and
TO, note that every move changes the order of items in the playlist."
  (interactive (list mpd-inter-conn (mpd-read-item "Source item number")
		     (mpd-read-item "Destination item number")))
  (and from to
       (mpd-simple-exec
	conn (mpd-make-cmd-format
	      (concat (if use-id "moveid" "move") " %d %d")
	      '(lambda (i j)
		 (mpd-assert-wholenump i)
		 (mpd-assert-wholenump j))
	      from to))))

;;;###autoload
(defun mpd-swap (conn first second &optional use-id)
  "Swap positions/ids FIRST and SECOND in the current mpd playlist.
For lists of FROM and TO, do action in that order for each pair of items.
Interpret FIRST and SECOND as song ids iff USE-ID is non-nil.
See also `mpd-move'."
  (interactive (list mpd-inter-conn (mpd-read-item "Swap item at number")
		     (mpd-read-item "With item at number")))
  (and first second
       (mpd-simple-exec
	conn (mpd-make-cmd-format
	      (concat (if use-id "swapid" "swap") " %d %d")
	      '(lambda (i j)
		 (mpd-assert-wholenump i)
		 (mpd-assert-wholenump j))
	      first second))))

;;;###autoload
(defun mpd-seek (conn song &optional time use-id)
  "Seek to song position/id SONG and time TIME in the mpd playlist.
Take TIME to be 0 by default. Interpret SONG as a song id
iff USE-ID is non-nil."
  (interactive
   (let (status)
     (and (eq (mpd-connection-status mpd-inter-conn) 'ready)
	  (setq status (mpd-get-status mpd-inter-conn)))
     (list mpd-inter-conn
	   (mpd-read-item "Seek to song" (and status (plist-get status 'song)))
	   (mpd-read-item "Time in seconds"
			  (and status (plist-get status 'time-elapsed)) t))))
  (mpd-assert-wholenump song)
  (if time (mpd-assert-wholenump time) (setq time 0))
  (mpd-simple-exec conn (format "%s %d %d"
				(if use-id "seekid" "seek") song time)))

;;;###autoload
(defun mpd-toggle-random (conn &optional arg)
  "Change random mode of mpd using connection CONN.
With ARG, set random on iff ARG is positive."
  (interactive (list mpd-inter-conn current-prefix-arg))
  (setq arg (if arg (> (prefix-numeric-value arg) 0)
	      (= (plist-get (mpd-get-status conn) 'random) 0)))
  (mpd-simple-exec conn (concat "random " (if arg "1" "0"))))

;;;###autoload
(defun mpd-toggle-repeat (conn &optional arg)
  "Change repeat mode of mpd using connection CONN.
With ARG, set repeat on iff ARG is positive."
  (interactive (list mpd-inter-conn current-prefix-arg))
  (setq arg (if arg (> (prefix-numeric-value arg) 0)
	      (= (plist-get (mpd-get-status conn) 'repeat) 0)))
  (mpd-simple-exec conn (concat "repeat " (if arg "1" "0"))))

;;;###autoload
(defun mpd-toggle-single (conn &optional arg)
  "Change single mode of mpd using CONN.
With ARG, set single on iff ARG is positive."
  (interactive (list mpd-inter-conn current-prefix-arg))
  (setq arg (if arg (> (prefix-numeric-value arg) 0)
	      (string-equal (plist-get (mpd-get-status conn) 'single) "0")))
  (mpd-simple-exec conn (concat "single " (if arg "1" "0"))))

;;;###autoload
(defun mpd-set-volume (conn vol)
  "Set the volume for the mpd player to volume VOL."
  (interactive
   (list mpd-inter-conn
	 (mpd-read-item
	  "New volume"
	  (and (eq (mpd-connection-status mpd-inter-conn) 'ready)
	       (plist-get (mpd-get-status mpd-inter-conn) 'volume))
	  t)))
  (mpd-assert-wholenump vol)
  (mpd-simple-exec conn (format "setvol %d" vol)))

;;;###autoload
(defun mpd-adjust-volume (conn vol)
  "Adjust the volume for the mpd player by volume VOL.
If VOL is positive, increase the volume, and decrease otherwise."
  (interactive (list mpd-inter-conn
		     (mpd-string-to-number-strict
		      (read-string "Adjust volume by: ") t)))
  (mpd-assert-numberp vol)
  (mpd-simple-exec conn (format "volume %d" vol)))

;;;###autoload
(defun mpd-set-crossfade (conn time)
  "Set cross-fading time for the mpd player to TIME in seconds.
Turn off cross-fading if TIME is 0."
  (interactive (list mpd-inter-conn
		     (mpd-read-item "New crossfade time in seconds"
				    (plist-get (mpd-get-status mpd-inter-conn)
					       'xfade) t)))
  (mpd-assert-wholenump time)
  (mpd-simple-exec conn (format "crossfade %d" time)))

(defvar mpd-inter-password-remember-queried nil)
(defvar mpd-inter-password nil)

;; For temporary binding
(defvar mpd-inter-password-inhibit-update nil)

(defun mpd-inter-password-update (conn when)
  (when (and (eq when 'post) (not mpd-inter-password-inhibit-update))
    (let ((passwd mpd-inter-password)
	  (mpd-inter-password-inhibit-update t))
      (or passwd (setq passwd (read-passwd "Enter MPD password: ")))
      (or (mpd-set-password conn passwd)
	  (message "Unable to set password: %s" (mpd-get-last-error conn))))))

;;;###autoload
(defun mpd-set-password (conn pass)
  "Set the password for access to the mpd server.
*WARNING* The password is sent to the server in plaintext. The processing done
by libmpdee to send the command for setting the password also has its data as
plaintext. When called interactively, offer to store and set the password on
reconnection. Note that this is not done when the call is not interactive.
Use hooked automatic mode (see `mpd-set-automatic-mode') to achieve the same."
  (interactive
   (let ((password (read-passwd "Enter password: ")))
     ;; Prevent password update triggering for this call itself
     ;; in case the connection is dead currently.
     (let ((mpd-inter-password-inhibit-update t))
       (mpd-conn-wakeup mpd-inter-conn))
     (if mpd-inter-password-remember-queried
	 (and mpd-inter-password (setq mpd-inter-password password))
       (when (yes-or-no-p "Do you want the password to be set again \
if we happen to reconnect? ")
	 (mpd-set-automatic-mode mpd-inter-conn 'mpd-inter-password-update)
	 (when (yes-or-no-p "Would you like me to remember your password \
for this session, in case it needs to be set again? ")
	   (setq mpd-inter-password password)))
       (setq mpd-inter-password-remember-queried t))
     (list mpd-inter-conn password)))
  (mpd-assert-string pass)
  (mpd-simple-exec conn (concat "password " (mpd-safe-string pass))))

(defun mpd-update-1 (conn path)
  "Internal function instructing the mpd server to update.
Please use `mpd-update' for updation purposes."
  (let ((response (mpd-execute-command
		   conn (mpd-make-cmd-concat "update" path))))
    (and (car response)
	 (string-to-number (cdr (assoc "updating_db" (cdr response)))))))

;;;###autoload
(defun mpd-update (conn &optional path ignore-timeout)
  "Instruct the mpd server using CONN to update its database.
PATH is the path or a list of paths to be updated. Note that PATH as nil updates
the root directory rather than not updating at all. Ignore connection timeout,
if IGNORE-TIMEOUT is non-nil and the connection is not in command list mode.
Return update job id on success."
  (interactive (list mpd-inter-conn (read-string "Enter relative path: ")))
  (if (or (not ignore-timeout) (mpd-command-list-mode-p conn))
      (mpd-update-1 conn path)
    (with-mpd-timeout-disabled (mpd-update-1 conn path))))

;;;###autoload
(defun mpd-output-enable (conn id)
  "Use connection CONN to enable mpd output ID."
  (interactive (list mpd-inter-conn (mpd-read-item "Output ID" 0 t)))
  (mpd-assert-wholenump id)
  (mpd-simple-exec conn (format "enableoutput %d" id)))

;;;###autoload
(defun mpd-output-disable (conn id)
  "Use connection CONN to disable mpd output ID."
  (interactive (list mpd-inter-conn (mpd-read-item "Output ID" 0 t)))
  (mpd-assert-wholenump id)
  (mpd-simple-exec conn (format "disableoutput %d" id)))

(defun mpd-ping (conn)
  "Use connection CONN to ping the mpd server.
Return non-nil on success."
  (mpd-simple-exec conn "ping"))

(defun mpd-clear-status-error (conn)
  "Use connection CONN to clear the error status of the mpd server.
Return non-nil on success."
  (mpd-simple-exec conn "clearerror"))

;;; Adapted from bbdb.el
;;;###autoload
(defun mpd-libmpdee-submit-bug-report ()
  "Interactively submit a bug report about `libmpdee'."
  (interactive)
  (eval-and-compile
    (require 'reporter)
    (require 'sendmail))
  (delete-other-windows)
  (reporter-submit-bug-report
   "andyetitmoves@gmail.com"
   (concat "libmpdee " libmpdee-version)
   (append
    ;; all mpd connections
    (apropos-internal
     "" '(lambda (sym)
	   (and (boundp sym) (mpd-conn-strongp (symbol-value sym)))))
    ;; some variables
    '(emacs-version features))
   nil nil
   "Please change the Subject header to a concise bug description.
In this report, remember to cover the basics, that is,
what you expected to happen and what in fact did happen.
If you got an error, please enable debugging by
	M-x set-variable debug-on-error t
or if you have `dbfrobs', M-x debug-on-interesting-errors
Then reproduce the error and immediately call
	M-x mpd-libmpdee-submit-bug-report
The backtrace will be automatically included with the report.
Please remove these instructions from your message.")

  ;; insert the backtrace buffer content if present
  (let ((backtrace (get-buffer "*Backtrace*")))
    (when backtrace
      (goto-char (point-max))
      (insert "\nPossible backtrace for libmpdee:\n\n")
      (insert-buffer-substring backtrace)))

  (goto-char (point-min))
  (mail-position-on-field "Subject"))

(provide 'libmpdee)

;;; libmpdee.el ends here
