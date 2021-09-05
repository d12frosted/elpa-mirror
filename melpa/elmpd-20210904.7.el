;;; elmpd.el --- A tight, ergonomic, async client library for mpd  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Michael Herstine <sp1ff@pobox.com>

;; Author: Michael Herstine <sp1ff@pobox.com>
;; Version: 0.2.3
;; Package-Version: 20210904.7
;; Package-Commit: c9e413fcb6c526c86e1a64d45c7ea94aceca4e6e
;; Keywords: comm
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/sp1ff/elmpd

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; "Music Player Daemon (MPD) is a flexible, powerful, server-side
;; application for playing music." <https://www.musicpd.org/>.
;; `elmpd' is a tight, ergonomic, asynchronous MPD client library in
;; Emacs Lisp.

;; See also `libmpdel' <https://gitea.petton.fr/mpdel/libmpdel>,
;; `libmpdee' <https://github.com/andyetitmoves/libmpdee> and the
;; `mpc' package which ships with Emacs beginning with version 23.2.

;; Create an MPD connection by calling `elmpd-connect'; this will
;; return an `elmpd-connection' instance immediately.  Asynchronously,
;; it will be parsing the MPD greeting message, perhaps sending an
;; initial password, and if so requested, sending the "idle" command.

;; There are two idioms I've seen in MPD client libraries for sending
;; commands while receiving notifications of server-side changes:

;;     1. just maintain two connections (e.g. mpdfav
;;        <https://github.com/vincent-petithory/mpdfav>); issue the
;;        "idle" command on one, send commands on the other

;;     2. use one connection, issue the "idle" command, and when asked
;;        to issue another command, send "noidle", issue the
;;        requested command, collect the response, and then send
;;        "idle" again (e.g. `libmpdel').  Note that this is not a
;;        race condition per
;;        https://www.musicpd.org/doc/html/protocol.html#idle -- any
;;        server-side changes that took place while processing the
;;        command will be saved & returned on "idle"

;; Since `elmpd' is a library, I do not make that choice here, but
;; rather support both styles.

;; The implementation is callback-based; each connection comes at the
;; cost of a single socket plus whatever memory is needed to do the
;; text processing in handling command responses.  In particular, I
;; declined to use `tq' despite the natural fit because I didn't want
;; to use a buffer for each connection, as well.


;;; Code:

(require 'cl-lib)

(defconst elmpd-version "0.2.3")

;;; Logging-- useful for debugging asynchronous functions

(defvar elmpd-log-buffer-name "*elmpd-log*"
  "Name of buffer used for logging `elmpd' events.")

(defvar elmpd-log-level 'info
  "Level at which `elmpd' shall log; may be one of 'debug, 'info, 'warn, or 'error.")

(defvar elmpd-max-log-buffer-size 750
  "Maximum length (in lines) of the log buffer.  nil means unlimited.")

(defun elmpd--log-level-number (level)
  "Return a numeric value for log level LEVEL."
  (cl-case level
    (debug -10)
    (info 0)
    (warn 10)
    (error 20)
    (otherwise 0)))

(defun elmpd-log-buffer ()
  "Return the `elmpd' log buffer, creating it if needed."
  (let ((buffer (get-buffer elmpd-log-buffer-name)))
    (if buffer
        buffer
      (with-current-buffer (generate-new-buffer elmpd-log-buffer-name)
        (special-mode)
        (current-buffer)))))

(defun elmpd--truncate-log-buffer ()
  "Truncate the log buffer to `elmpd-max-log-buffer-size lines."
  (with-current-buffer (elmpd-log-buffer)
    (goto-char (point-max))
    (forward-line (- elmpd-max-log-buffer-size))
    (beginning-of-line)
    (let ((inhibit-read-only t))
      (delete-region (point-min) (point)))))

(defun elmpd--pp-truncate-string (s n)
  "Truncate S to max length N with ellipses."
  (let ((len (length s)))
    (cond
     ((<= len n) s)
     ((> n 3) (concat (substring s 0 (- n 3)) "..."))
     (t (substring s 0 n)))))

(defvar elmpd--log-idle-cb-len 24
  "Max length of the idle callback while pretty-printing connection instances.")

(defvar elmpd--log-queue-cb-len 18
  "Max length of queue command callbacks while pretty-printing connection instances.")

(defun elmpd-log (level facility fmt &rest objects)
  "Log message FMT from FACILITY at level LEVEL.

Log the message formed my FMT & replacement parameters OBJECTS
to the elmpd log buffer at `elmpd-log-buffer-name'.  The FACILITY
parameter is meant to enable code built on top of `elmpd' to
use the same logging facility.  This package logs with FACILITY
'elmpd."

  (when (>= (elmpd--log-level-number level)
            (elmpd--log-level-number elmpd-log-level))
    (let ((inhibit-read-only t))
      (with-current-buffer (elmpd-log-buffer)
        (goto-char (point-max))
        (insert
         (format "[%s][%s][%s] %s\n"
                 (format-time-string "%Y-%m-%d %H:%M:%S")
                 facility
                 level
                 (apply #'format fmt objects)))
        (if (and elmpd-max-log-buffer-size
                 (> (line-number-at-pos) elmpd-max-log-buffer-size))
            (elmpd--truncate-log-buffer))))))

(defun elmpd--log (level fmt &rest objects)
  "Log message FMT a level LEVEL from facility 'elmpd."
  (apply #'elmpd-log level 'elmpd fmt objects))

(defun elmpd-clear-log ()
  "Clear the `elmpd' log buffer."
  (interactive)
  (let ((inhibit-read-only t))
    (with-current-buffer (elmpd-log-buffer)
      (erase-buffer))))


(define-obsolete-variable-alias 'elmpd--sym-to-string
  'elmpd--subsys-to-string "0.1.3" "Use to more specific name.")

(defvar elmpd--subsys-to-string
 '((database . "database")
   (update . "update")
   (stored . "stored_playlist")
   (playlist . "playlist")
   (player . "player")
   (mixer . "mixer")
   (output . "output")
   (options . "options")
   (partition . "partition")
   (sticker . "sticker")
   (subscription . "subscription")
   (message . "message")
   (neighbor . "neighbor")
   (mount . "mount"))
 "Association list from symbols to textual names of MPD sub-systems.")

(defvar elmpd--string-to-subsys
 '(("database" . database)
   ("update" . update)
   ("stored_playlist" . stored)
   ("playlist" . playlist)
   ("player" . player)
   ("mixer" . mixer)
   ("output" . output)
   ("options" . options)
   ("partition" . partition)
   ("sticker" . sticker)
   ("subscription" . subscription)
   ("message" . message)
   ("neighbor" . neighbor)
   ("mount" . mount))
 "Association list from textual names of MPD sub-systems to symbols.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;          `elmpd-connection -- the MPD connection entity          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Application-layer connections to MPD need to be "built-up" beyond
;; the initial socket connection:

;;     1. the MPD greeting sent in response to the initial connection
;;        needs to be parsed (`elmpd-connection' makes the protocol
;;        version therein available)

;;     2. if the caller supplied an initial password, the "password"
;;        command must be sent and the response processed

;;     3. if the caller requested that the connection "idle", the
;;        "idle" command must be sent

;; Only then is the connection ready for commands.

;; Construct instances with `elmpd-connect'-- when that returns the
;; connection is in the process of being built-up asynchronously, but
;; you can still issue commands on it; they'll just get queued up &
;; sent as soon as possible. The point is, the ctor won't block.

;; Type invariants:

;;     1. prior to being ready to handle commands, `init' shall be
;;        nil; once ready `init' shall be t

;;     2. post-init, "idling" connections are handled differently than
;;        "regular" connections:

;;        a. idling connections will either:

;;           i. have an empty queue and be listening for notifications
;;              (i.e. have issued the "idle" command)

;;           ii. have a non-empty queue, have issued the command at
;;               the head of their queue, and be waiting for a response

;;        b. regular connections will either:

;;           i. have an empty queue and have no command outstanding

;;           ii. have a non-empty queue, have issued the command at
;;               the head of their queue, and be waiting for a response

;; Open questions:

;;     1. what if the server (for whatever reason) closes the
;;        connection underneath us?
;;        - do we offer a "keepalive" option, say send a "ping"
;;          command once every n seconds, just to keep the
;;          connection open?

;;     2. tear-down: if the connection object it GC'd, we'll close the
;;        socket & delete the process, but what if the user
;;        issues a "close"?  Do we want to offer an explicit dtor of
;;        some kind?

(cl-defstruct
    (elmpd-command
     (:constructor nil) ; no default constructor
     (:constructor elmpd--make-command)
     (:conc-name elmpd-command--))
  simple-command   ; single command
  compound-command ; command-list only one of these two may be non-nil
  callback         ; optional callback-- signature depends on the style
  callback-style)  ; 'default, 'list or 'stream

(defun elmpd--pp-cmd (cmd)
  "Pretty-print CMD to string."
  (format
   "(%s%s)"
   (if (elmpd-command--simple-command cmd)
       (elmpd-command--simple-command cmd)
     (elmpd-command--compound-command cmd))
   (let ((cb (elmpd-command--callback cmd)))
	   (if cb
	       (format
          " => %s [%s]"
          (elmpd--pp-truncate-string
           (prin1-to-string
            (if (byte-code-function-p cb) ; byte-compiled code looks ugly
                (aref cb 2)               ; when printed
              cb))
           elmpd--log-queue-cb-len)
          (elmpd-command--callback-style cmd))
	     ""))))

(defun elmpd--new-command (command &rest args)
  "Construct an `elmpd-command' instance with COMMAND & ARGS.

COMMAND may be either a string or a list of strings.  The second argument is
an optional callback.  The (optional) third is the callback style; one of
'default, 'list or 'stream."
  (let ((cb (nth 0 args))     ; may be nil
        (style (nth 1 args))) ; may be nil
    (cond
     ((stringp command)
      (if (and style (not (eq style 'default)))
          (error "A non-default style may not be given with a simple command"))
      (elmpd--make-command :simple-command command :compound-command nil
                           :callback cb :callback-style style))
     ((listp command)
      (elmpd--make-command :simple-command nil :compound-command command
                           :callback cb :callback-style style))
     (t
      (error "Cannot make an elmpd command out of %s" command)))))

(defun elmpd-command--send (cmd fd)
  "Send `elmpd-command' CMD to FD."
  (let ((simple-command (elmpd-command--simple-command cmd)))
    (if simple-command
        (process-send-string fd (concat simple-command "\n"))
      (process-send-string
       fd
       (if (eq (elmpd-command--callback-style cmd) 'default)
           "command_list_begin\n"
         "command_list_ok_begin\n"))
      (cl-mapc
       (lambda (x)
         (process-send-string fd (concat x "\n")))
       (elmpd-command--compound-command cmd))
      (process-send-string fd "command_list_end\n"))))

(cl-defstruct
    (elmpd-connection
     (:constructor nil) ; no default constructor
     (:constructor elmpd--make-connection)
     (:conc-name elmpd-connection--))
  fd        ;; process representing our socket
  inbuf     ;; string in which MPD output is collected as it becomes
            ;; available
  proto-ver ;; MPD protocol version; only available after the greeting
            ;; has been harvested
  init      ;; nil initially, t when ready to take commands
  finalize  ;; finalizer
  idle      ;; idle configuration-- cf. `elmpd-connect' for format
  q         ;; command queue: this is a list of elmpd-command
  rsp-list) ;; accumulated command_ok_list sub-responses

(defun elmpd--pp-conn (conn)
  "Pretty-print CONN to string."
  (format
   "#elmpd{%s %s %s}"
   (process-name (elmpd-connection--fd conn))
   (format
    "(%s . %s)"
    (prin1-to-string (car (elmpd-connection--idle conn)))
    (elmpd--pp-truncate-string
     (prin1-to-string (cdr (elmpd-connection--idle conn)))
   elmpd--log-idle-cb-len))
   (mapconcat
    #'elmpd--pp-cmd
    (elmpd-connection--q conn)
    " ")))

(defun elmpd--process-sentinel (process event)
  "Callback invoked when PROCESS experiences EVENT."
  (elmpd--log 'info "Process: %s saw the event '%s'." (process-name process) (substring event 0 -1)))

(defun elmpd--kick-queue (conn)
  "Move CONN's queue forward.

Issue the next command in the queue.  If there is none, and CONN
is an \"idling\" connection, issue the \"idle\" command.  Else do
nothing."

  (elmpd--log 'debug "Kicking the queue for %s." (elmpd--pp-conn conn))
  (let ((idle (elmpd-connection--idle conn))
        (q (elmpd-connection--q conn)))
    (if q
        ;; Regardless of the connection type, if we have commands in
        ;; the queue; we need to kick 'em off at this point.  NB. we
        ;; leave the command at the head of the queue; it will be
        ;; popped when the command response has been completely
        ;; received & processed.
        (progn
          (elmpd--log 'info "Sending the command ``%s'' on %s."
                      (elmpd--pp-cmd (car q)) (elmpd--pp-conn conn))
          (elmpd-command--send (car q) (elmpd-connection--fd conn)))
      ;; Otherwise, our next action depends on the connection type.
      (if idle
          ;; `idle' is a cons cell:
          ;;     - car is 'all, a symbol, or a list of symbols
          ;;     - cdr is the callback
          (let* ((subsys (car idle))
                 (cmd
                  (format
                   "idle%s\n"
                   (cond
                    ((eq 'all subsys) "")
                    ((symbolp subsys)
                     (format " %s" (alist-get subsys elmpd--subsys-to-string)))
                    (t
                     (format
                      " %s"
                      (mapconcat
                       #'identity
                       (cl-mapcar (lambda (x) (alist-get x elmpd--subsys-to-string)) subsys)
                       " ")))))))
            (elmpd--log 'info "Issuing ``%s'' on %s." (substring cmd 0 -1) (elmpd--pp-conn conn))
            (process-send-string (elmpd-connection--fd conn) cmd))))))

(defun elmpd--fast-find-ack (buf)
  "Quickly find an ACK response in BUF.

A complete MPD error response is one which matches the follwoing
regexp:

   \"^ACK \\[\\([0-9]+\\)@\\([0-9]+\\)\\] {\\([^}]*\\)} \\(.*\\)\n\"

Unfortunately, matching a regular expression against a large
block of text can be expensive.  This function searches BUF for
the string \"ACK\" at either the beginning of BUF or just after a
newline.  It is used as a helper function for `elmpd--is-ack'.

In performance testing over moderately large strings tens of
kilobytes in length) I found this approach to be two orders of
magnitude faster than regexp matching."
  (let* ((n (length buf))
	       (i (cl-search "ACK" buf :from-end t :end2 n)))
    (cl-loop while i
	     if (or (eq i 0) (string-equal (substring buf (- i 1) i) "\n")) return i
	     do
	     (setq n i i (cl-search "ACK" buf :from-end t :end2 n)))))

(defun elmpd--is-ack (buf)
  "Check BUF for an ACK result.

Return nil if not found, else return a list of length five:

  0. error number
  1. command list number
  2. current command
  3. error message
  4. response text up to the ACK line"

  (let ((i (elmpd--fast-find-ack buf)))
    (if i
        (let* ((line (substring buf i))
               (j
                (string-match
                 "ACK \\[\\([0-9]+\\)@\\([0-9]+\\)\\] {\\([^}]*\\)} \\(.*\\)\n"
                 line)))
          (unless j
            (error "Unexpected ACK response %s" line))
          (list
           (substring line (match-beginning 1) (match-end 1))
           (substring line (match-beginning 2) (match-end 2))
           (substring line (match-beginning 3) (match-end 3))
           (substring line (match-beginning 4) (match-end 4))
           (substring buf 0 i))))))

(defun elmpd--parse-sub-responses (buf)
  "Parse command_ok_list sub-responses from BUF.  Return (list . remainder)."

  (let ((lines '())
        (i 0)
	      (j (cl-search "list_OK\n" buf)))
    (cl-loop while j
	           do
	           (if (or (eq j 0) (string-equal (substring buf (- j 1) j) "\n"))
		             (setq lines (cons (substring
				                            buf
				                            i
				                            (if (> j i) (- j 1) j))
				                           lines)))
	           (setq
	            i (+ j 8)
	            j (cl-search "list_OK\n" buf :start2 i)))
    (cons (reverse lines) (substring buf i))))

(defun elmpd--truncate-text (text)
  "Truncate TEXT."
  (truncate-string-to-width text 512 nil nil t))

(defun elmpd-connection--filter (conn output)
  "General process filter; CONN has received output OUTPUT."

  ;; This method could be invoked for two reasons:
  ;;
  ;;   1. this connection was "idling", something changed on the
  ;;      server, and we are being informed of that change in OUTPUT
  ;;      (OUTPUT may be the complete response, the first chunk of a
  ;;      larger response, an intermediate chunk in a larger response,
  ;;      or the final chunk of a response that arrived in multiple
  ;;      chunks; given the request/response nature of the MPD
  ;;      protocol, we know that OUTPUT will always be some or all of
  ;;      the response to the most recent "idle" command)
  ;;
  ;;   2. there is a request outstanding on CONN and some or all of
  ;;      the response has arrived in OUTPUT (again OUTPUT may be the
  ;;      complete response, the first chunk of a larger response, &c;
  ;;      given the request/response nature of the MPD protocol, we
  ;;      know that OUTPUT will always be some or all of the response
  ;;      to the currently outstanding command)
  ;;
  ;; The algorithm:
  ;;
  ;;   1. let `buf' be the un-parsed response so far, icnluding OUTPUT
  ;;      (i.e.  the remnants of previous response chunks if any with
  ;;      OUTPUT appended thereto)
  ;;
  ;;   2. determine whether we have an outstanding command, whether
  ;;      there is a callback associated with it if we do, and the
  ;;      style of that callback if there is ('default, 'list, or
  ;;      'stream).
  ;;
  ;;   3. if the response is complete
  ;;
  ;;      3.1. clear-out the connection's buffer, pop its queue, and
  ;;           "kick" it
  ;;
  ;;      3.2. if the response is complete (i.e. "OK" or "ACK")
  ;;
  ;;        3.2.1. if we have an outstanding response with a callback
  ;;               whose style is 'list or 'stream:
  ;;
  ;;               decompose `buf' into sub-responses & invoke the
  ;;               callback
  ;;
  ;;               if the response is "ACK", invoke the callback a final
  ;;               time with the error information
  ;;
  ;;        3.2.2. if we have an outstanding response with a callback
  ;;               whose style is 'default
  ;;
  ;;               if the response is "OK", strip the trailing "OK\n"
  ;;               from `buf' & invoke the callback
  ;;
  ;;               else invoke the callback with the error information
  ;;
  ;;        3.2.3. if we do not have an outstanding response, then
  ;;               we were invoke in response to a prior "idle"
  ;;               command; parse `buf' accordingly & invoke the
  ;;               "idle" callback
  ;;
  ;;    4. else, the current response is not complete
  ;;
  ;;      4.1. if we have an outstanding response
  ;;
  ;;        4.1.1. if it has a callback whose style is 'list or
  ;;               'stream
  ;;
  ;;               parse & remove any complete sub-responses from `buf' &
  ;;               invoke the callback
  ;;
  ;;               4.1.1.1. if the style is 'list, update the connection's
  ;;                        running list
  ;;
  ;;               4.1.1.2. else, invoke the callback for each sub-response
  ;;
  ;;        4.1.2. update the connection's buffer with `buf'

  (let* ((buf (concat (elmpd-connection--inbuf conn) output))
         (q (elmpd-connection--q conn))
         (q-cb (if q (elmpd-command--callback (car q))))
         (cb-style (if q-cb (elmpd-command--callback-style (car q))))
         (err (elmpd--is-ack buf))
         (ok (unless err (string= (substring buf -3) "OK\n"))))
    (if (or err ok)
        (progn
          (elmpd--log 'debug "%s processing a response of \"%s\"."
                      (elmpd--pp-conn conn) (elmpd--truncate-text buf))
          ;; Clear out the connection's buffer,
          (setf (elmpd-connection--inbuf conn) "")
          ;; pop the queue,
          (if q (setf (elmpd-connection--q conn) (cdr q)))
          ;; & send next command; if no more commands & CONN is an
          ;; "idle" connection, send "idle"; else do nothing.
          (elmpd--kick-queue conn)
          (cond
           ((and cb-style (not (eq cb-style 'default)))
            (let ((sub-rsp (elmpd--parse-sub-responses buf))) ;; (list . remainder)
              ;; NB `(cdr sub-rsp)' should be empty/nil or "OK\n"
	      (elmpd--log 'debug "sub-rsp is ``%s'' & style is ``%s''." sub-rsp cb-style)
	      (if (and (cdr sub-rsp)
		       (not (string= (cdr sub-rsp) "OK\n"))
		       (not (string-prefix-p "ACK" (cdr sub-rsp))))
		  (error "Internal error: failed to parse response: ``%s''" sub-rsp))
              (if (eq cb-style 'list)
                  (let ((final-arg (append (elmpd-connection--rsp-list conn) (car sub-rsp))))
		    (elmpd--log 'debug "Final arg to 'list cb: %s" final-arg)
                    (funcall q-cb conn t final-arg)
                    (setf (elmpd-connection--rsp-list conn) nil))
		(elmpd--log 'debug "Invoking as stream.")
                (cl-mapc
                 (lambda (rsp)
                   (funcall q-cb conn t rsp))
                 (car sub-rsp)))
              (if err (funcall q-cb conn nil (nth 3 err)))))
           ((and cb-style (eq cb-style 'default))
            (if ok
                (let ((rsp (substring buf 0 -3)))
                  (funcall q-cb conn t rsp)
                  (elmpd--log 'debug "cb done."))
              (funcall q-cb conn nil (nth 3 err))))
           ((and ok (not q))
            (funcall
             (cdr (elmpd-connection--idle conn))
             conn
             (cl-mapcar
              (lambda (line)
                (cdr (assoc (substring line 9) elmpd--string-to-subsys)))
              (split-string (substring buf 0 -3) "\n" t))))))
      (if (and cb-style (not (eq cb-style 'default)))
          (let ((sub-rsp (elmpd--parse-sub-responses buf))) ;; (list . remainder)
            (if (eq cb-style 'list)
                (setf
                 (elmpd-connection--rsp-list conn)
                 (append (elmpd-connection--rsp-list conn) (car sub-rsp)))
              (cl-mapc
               (lambda (rsp)
                 (funcall q-cb conn t rsp))
               (car sub-rsp)))
            (elmpd--log 'debug "%s input buffer is now \"%s\"."
                        (elmpd--pp-conn conn) (car sub-rsp))
            (setq buf (cdr sub-rsp)))
        (setf (elmpd-connection--inbuf conn) buf)
        (elmpd--log 'debug "%s input buffer is now \"%s\"."
                    (elmpd--pp-conn conn) buf)))))

(defun elmpd--start-processing (conn)
  "Begin regular processing on CONN once the connection has been stood-up.

At this point, CONN has been built-up & is ready to take
commands.  Its creator may have requested that we idle, and
commands may have built up in its queue."

  ;; Check our precondition...
  (if (elmpd-connection--init conn)
      (error "Connection %s has already been initialized" (elmpd--pp-conn conn)))
  ;; update our state...
  (elmpd--log 'info "elmpd-connection %s ready for command processing." (elmpd--pp-conn conn))
  (set-process-filter
   (elmpd-connection--fd conn)
   (lambda (_proc output)
     (elmpd-connection--filter conn output)))
  (setf (elmpd-connection--init conn) t)
  ;; & get to work.
  (elmpd--kick-queue conn))

(defun elmpd--constructing-filter (conn output password)
  "Process filter to construct CONN on OUTPUT with MPD password PASSWORD.

This is the process filter used by `elmpd-connection' instances
until they are ready to handle command traffic.  It is invoked
whenever MPD output is available for processing, and will move
`conn' through the buildup process in the style of a Finite
State Machine."

  (let ((buf (concat (elmpd-connection--inbuf conn) output)))
    (if (not (elmpd-connection--proto-ver conn))
        ;; We are waiting for the MPD greeting message.
        (if (string-match "OK MPD \\([0-9]+\\)\\.\\([0-9]+\\)\\.\\([0-9]+\\)\n" buf)
	          (progn
              ;; We got it...
	            (elmpd--log 'info "%s" (substring buf 0 -1))
              ;; harvest the protocol version...
	            (setf
	             (elmpd-connection--proto-ver conn)
	             (list
	              (string-to-number (substring buf (match-beginning 1) (match-end 1)))
	              (string-to-number (substring buf (match-beginning 2) (match-end 2)))
	              (string-to-number (substring buf (match-beginning 3) (match-end 3)))))
              ;; clear out our input buffer...
	            (setf (elmpd-connection--inbuf conn) "")
              ;; and change state: if the creator of this connection
              ;; specified a password...
              (if password
                  (progn
                    ;; send it,
                    (elmpd--log 'info "Sending initial password")
                    (process-send-string (elmpd-connection--fd conn) (format "password %s\n" password)))
                ;; failing that, start regular processing on the connection.
                (elmpd--start-processing conn)))
          ;; response not complete; accumulate & wait for more.
          (setf (elmpd-connection--inbuf conn) buf))
      ;; We are awaiting the results of the "password" command
      (cond
       ((string-match "OK\n" buf)
        ;; Password accepted; clear out our input buffer...
        (elmpd--log 'info "Initial password accepted")
	      (setf (elmpd-connection--inbuf conn) "")
        ;; start regular processing on this connection.
        (elmpd--start-processing conn))
       ((string-match "ACK \\[\\([0-9]+\\)@\\([0-9]+\\)\\] {\\([^}]+\\)} \\(.*\\)\n" buf)
        ;; password rejected; signal error...
        (elmpd--log 'error "Initial password rejected (%s); continuing."
                   (substring buf (match-beginning 4) (match-end 4)))
        ;; clear out our input buffer...
	      (setf (elmpd-connection--inbuf conn) "")
        ;; start regular processing on this connection.
        (elmpd--start-processing conn))
       ;; response not complete; accumulate & wait for more.
       (t (setf (elmpd-connection--inbuf conn) buf))))))

;;;###autoload
(defun elmpd-connect (&rest args)
  "Connect to an MPD server according to ARGS.  Return an `elmpd-connection'.

ARGS shall be in the form of keyword arguments.  The keywords may
be any of the following:

          :name The name by which to refer to the underlying
                socket (AKA network process); it will be modified
                as necessary to make it unique; defaults to
                \"*elmpd-connection*\"

          :host The host on which the MPD server resides;
                defaults first to the environment variable
                \"MPD_HOST\", then to \"localhost\"

          :port The port on which MPD is listening; defaults
                first to the environment variable \"MPD_PORT\",
                then to 6600

         :local Path to the Unix socket on which MPD is
                listening; mutually exclusive with :host & :port;
                this option is preferred, so to force a TCP
                connection, pass this explicitly as nil

      :password If given, the \"password\" command shall be
                issued after the initial connection is made; this
                should only be done over an encrypted connection,
                such as port forwarding over SSH

    :subsystems If given, this connection will perpetually idle;
                whenever a command is issued on this connection,
                a \"noidle\" command shall be given, followed by
                the command.  When that command completes,
                \"idle\" will be re-issued.  This argument shall
                be a cons cell whose car is either the keyword
                'all, the symbol representing the subsystem of
                interest, or a list of symbols naming the
                subsystems of interest (e.g. '(player mixer
                output) and whose cdr is a callback to be invoked
                when any of those subsystems change; the callback
                shall take two parameters the first of which will
                be the `elmpd-connection' which saw the state
                change & the second of which will be either a
                single symbol or a list of symbols naming the
                changed subsystems

The connection object will still be in the process of
construction on return; we need to collect the greeting & parse
the protocol version, we may need to send the \"password\"
command & we may need to send the \"idle\" command, if requested.
This is all handled asynchronously; the caller is free to send
commands through the connection & they will be queued up & sent
as soon as possible."

  ;; If the caller fat-fingered a keyword argument, tell them rather
  ;; than fail silently.
  (let ((args-copy args))
    (while args-copy
      (unless (memq (car args-copy) '(:name :host :port :local :password :subsystems))
        (error "Unknown argument %s" (car args-copy)))
      (setq args-copy (cddr args-copy))))

  (let* ((name
          (let ((from-arg (plist-get args :name)))
            (if from-arg from-arg "*elmpd-connection*")))
         (local
          (let ((from-arg (plist-get args :local)))
            (if from-arg from-arg "/var/run/mpd/socket")))
         (host
          (let ((from-arg (plist-get args :host)))
            (if from-arg
                from-arg
              (let ((from-env (getenv "MPD_HOST")))
                (if from-env from-env "localhost")))))
         (port
          (let ((from-arg (plist-get args :port)))
            (if from-arg
               from-arg
              (let ((from-env (getenv "MPD_PORT")))
                (if from-env from-env 6600)))))
         ;; All connection parameters have been defaulted, so we can't
         ;; tell (here) which were given & which were not. Of course,
         ;; the server could well be listening on a Unix *and* a TCP
         ;; socket.  We prefer the Unix socket.
         (fd
          (if (and local (file-exists-p local))
              (make-network-process :name name :remote local :nowait t)
            ;; (make-network-process :name name :host host :service port :nowait t)
            (make-network-process
             :name name
             :host host
             :service port
             :nowait t)))
         (dtor
          (make-finalizer
           (lambda ()
             (elmpd--log 'info "Finalizing `%s'" fd)
             (delete-process fd))))
         (conn (elmpd--make-connection :fd fd :inbuf "" :finalize dtor :idle (plist-get args :subsystems))))
    (set-process-coding-system fd 'utf-8-unix 'utf-8-unix)
    (set-process-query-on-exit-flag fd nil)
    (set-process-sentinel fd 'elmpd--process-sentinel)
    (set-process-filter
     fd
     (lambda (_proc output)
       (elmpd--constructing-filter conn output (plist-get args :password))))
    conn))

(defun elmpd-send (conn cmd &optional cb &rest args)
  "Send command CMD with callback CB on connection CONN.

CMD may be either a string representing a single command, or a
list of strings representing a command list.  The optional
argument CB is a callback which will be invoked in response to
the command in a manner determined by the keyword argument
:response:

    - 'default: if unspecified, or if CMD is a string, the
      callback style is 'default; the callback will be invoked
      with three parameters, the connection, a boolean indicating
      success or failure of the command and either the server
      response (on success) or error message (on failure).  If
      CMD is a list, it will be invoked via
      \"command_list_begin\".

    - 'list: this style is only applicable to command lists; the
      callback will be invoked with three parameters: the
      connection, a boolean, and a list of responses to each
      individual command in the list.  The command list will be
      invoked via \"command_list_ok_begin\".

    - 'stream: this style is only applicable to command lists;
      the callback will be invoked repeatedly, once for each
      completed sub-command.  It will be invoked with three
      parameters: the connection, a boolean indicating success or
      failure, and the sub-command response (on success) or the
      sub-command error message (on failure).  The command list
      will be invoked via \"command_list_ok_begin\".

For example, sending a command list of (\"ping\", \"ping\",
\"ping\") with each of the three styles would result in:

    - 'default: a single invocation of the callback with
      parameters `conn', 't', and \"pong\npong\npong\n\"

    - 'list: a single invocation of the callback with parameters
      `conn', 't', and '(\"pong\", \"pong\", \"pong\")

    - 'stream: three invocations of the callback, each with
      parameters `conn', 't', and \"pong\"; the timing of each
      callback depends on receipt of the response at the client,
      each invocation will be made as soon as the corresponding
      response is available.

If you need to send multiple commands where subsequent commands
depend on the responses to prior commands, consider
`elmpd-chain'."

  (let* ((q (elmpd-connection--q conn))
         (cb-style (plist-get args :response))
         (cmd (elmpd--new-command cmd cb (if cb-style cb-style 'default))))
    ;; Regardless; append this command to the queue.
    (setf
     (elmpd-connection--q conn)
     (if q
         (append q (list cmd))
       (list cmd)))
    (elmpd--log 'info "Queued command \"%s\" on %s." (elmpd--pp-cmd cmd)
                (elmpd--pp-conn conn))
    ;; *If* the connection is ready...
    (if (elmpd-connection--init conn)
        ;; switch based on whether it's a "idle" connection:
        (if (elmpd-connection--idle conn)
            ;; We have a fully constructed, "idling" connection-- that
            ;; means that either:
            ;;
            ;;     1. `q' is empty and we're listening for notifications
            ;;     2. `q' is non-empty & we're waiting for the result
            ;;        of the command at its head
            (unless q
              ;; We're idling-- issue the noidle & kick off this command.
              (elmpd--log 'debug "Cancelling idle mode.")
              (setf
               (elmpd-connection--q conn)
               (cons (elmpd--new-command "noidle") (elmpd-connection--q conn)))
              (elmpd--kick-queue conn))
          ;; We have a fully constructed, "regular" connection-- that
          ;; means that either:
          ;;
          ;;     1. `q' is empty & we're not expecting any MPD output
          ;;
          ;;      2. `q' is non-empty & we're waiting for the result
          ;;         of the command at its head
          (unless q
            ;; We're idling-- kick off this command.
            (elmpd--kick-queue conn))))))

(defun elmpd-conn-queue-size (conn)
  "Return the present length of CONN's queue."
  (length (elmpd-connection--q conn)))

(defmacro elmpd-chain (conn &rest chain)
  "Chain multiple MPD commands on CONN conveniently.  See below for CHAIN.

Sending multiple, un-connected commands to MPD is simple: use a
command list:

    (elmpd-send conn '(\"foo\" \"bar\" \"splat\")...)

But what if you need to send a command, process the response, and
send another command whose contents depends upon the response to
the first? Then you're reduced to writing things like:

    (elmpd-send
      conn
      \"whatever\"
      (lambda (conn ok rsp)
        (if ok
            ;; do some stuff with `rsp'
            (elmpd-send
              conn
              \"something new\")
          (message \"Oops!\"))))

`elmpd-chain' is a macro that automates the generation of such nested code.

Call it like so:

    (elmpd-chain
      conn
      CMD
      [:or-else ELSE-HANDLER]
      [:and-then
        [CMD OR-ELSE? AND-THEN...])

CMD may be any of:

    1. a single value `cmd'
    2. a list with two elements (`cmd' `cb')
    3. a list with three elements (`cmd' `cb' `style')

In any case, `cmd' may be either a string or a list of strings.
In case 3, if `cmd' is a string, then `style' must be 'default.
Note that the callback will be invoked with just two
arguments (the connection and the response), since it will only
be invoked on success (you can place failure logic in an :or-else
clause).  Similarly, :or-else handlers are also invoked with
just two arguments, since it will only be invoked on failure."

  ;; Let us destructure `chain' into (`cmd' `chain').
  (if chain
      (let* ((cmd (car chain))
	           (chain (cdr chain))
	           ;; Now, `cmd' may be:
	           ;; 1. a single value `arg'         => send arg, no cb
	           ;; 2. a list (`arg' `cb')          => send arg with cb & style 'default
	           ;; 3. a list (`arg' `cb' `style')  => send arg with cb & style `style'
	           ;; In any case, `arg' may be either a string or a list of
	           ;; strings.
	           ;; In case 3., if `arg' is a string, then `style' *must* be 'default.
	           (arg (if (listp cmd) (nth 0 cmd) cmd))
	           (cb (if (listp cmd) (nth 1 cmd)))
	           (style (if (and (listp cmd) (> (length cmd) 2)) (nth 2 cmd) 'default))
	           ;; We next need to know if there's an `:or-else' clause next
	           ;; on `chain'; pull it off if there is
	           (or-else
	            (if (and chain
		                   (symbolp (car chain))
		                   (eq ':or-else (car chain))
		                   (> (length chain) 1))
		              (prog1
		                  (nth 1 chain)
		                (setq chain (last chain (- (length chain) 2))))))
	           ;; And finally-- is there an `:and-then' clause coming?
	           (and-then
	            (if (and chain
		                   (symbolp (car chain))
		                   (eq ':and-then (car chain))
		                   (> (length chain) 1))
		              (prog1
		                  t
		                (setq chain (cdr chain))))))
	      ;; Wheh! We now have everything we need for this level in this let
	      ;; form's variables, and the recursion is setup in `chain'.
        (if (and (eq style 'stream) chain)
            (error "'stream may only be used as the last step in the chain"))
        (let ((out
	             (list
		            'elmpd-send
		            conn
                arg
                ;; This is where we both construct the callback for
                ;; the preceeding `elmpd-send' invocation *and*
                ;; recurse.
		            (if (or cb or-else and-then)
		                (list 'lambda (list 'conn 'ok 'text)
			                    `(if ok
			                         (progn
				                         ,(if cb (list 'funcall cb 'conn 'text))
				                         (elmpd-chain conn ,@chain))
			                       ,(if or-else `(funcall ,or-else conn text))))))))
          ;; At this point `out' is the form that when interpreted as
          ;; code will invoke `elmpd-send'.  Append the keyword
          ;; argument, but only in case there's actually a callback
          ;; (it would do no harm either way, without a callback the
          ;; :response argument would just be ignored, I just think
          ;; it's little neater this way)
          (if cb (append out (list :response (list 'quote style))) out)))))

(provide 'elmpd)

;;; elmpd.el ends here
