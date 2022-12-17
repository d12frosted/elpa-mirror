;;; srv.el --- perform SRV DNS requests

;; Copyright (C) 2005, 2007, 2018  Magnus Henoch

;; Author: Magnus Henoch <magnus.henoch@gmail.com>
;; Keywords: comm
;; Package-Version: 20180715.1959
;; Package-Commit: 714387d5a5cf34d8d8cd96bdb1f9cb8ded823ff7
;; Version: 0.2
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/legoscia/srv.el

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This code implements RFC 2782 (SRV records).  It was originally
;; written for jabber.el <http://emacs-jabber.sf.net>, but is now a
;; separate package.
;;
;; It is used to look up hostname and port for a service at a specific
;; domain.  There might be multiple results, and the caller is supposed
;; to attempt to connect to each hostname+port in turn.  For example,
;; to find the XMPP client service for the domain gmail.com:
;;
;; (srv-lookup "_xmpp-client._tcp.gmail.com")
;; -> (("xmpp.l.google.com" . 5222)
;;     ("alt3.xmpp.l.google.com" . 5222)
;;     ("alt4.xmpp.l.google.com" . 5222)
;;     ("alt1.xmpp.l.google.com" . 5222)
;;     ("alt2.xmpp.l.google.com" . 5222))


;;; Code:

(require 'dns)

;;;###autoload
(defun srv-lookup (target)
  "Perform SRV lookup of TARGET and return list of connection candidiates.
TARGET is a string of the form \"_Service._Proto.Name\".

Returns a list with elements of the form (HOST . PORT), where HOST is
a hostname and PORT is a numeric port.  The caller is supposed to
make connection attempts in the order given, starting from the beginning
of the list.  The list is empty if no SRV records were found."
  (let* ((result (srv--dns-query target))
	 (answers (mapcar #'(lambda (a)
			      (cadr (assq 'data a)))
			  (cadr (assq 'answers result))))
	 answers-by-priority weighted-result)
    (if (or (null answers)
	    ;; Special case for "service decidedly not available"
	    (and (eq (length answers) 1)
		 (string= (cadr (assq 'target (car answers))) ".")))
	nil
      ;; Sort answers into groups of same priority.
      (dolist (a answers)
	(let* ((priority (cadr (assq 'priority a)))
	       (entry (assq priority answers-by-priority)))
	  (if entry
	      (push a (cdr entry))
	    (push (cons priority (list a)) answers-by-priority))))
      ;; Sort by priority.
      (setq answers-by-priority
	    (sort answers-by-priority
		  #'(lambda (a b) (< (car a) (car b)))))
      ;; Randomize by weight within priority groups.  See
      ;; algorithm in RFC 2782.
      (dolist (p answers-by-priority)
	(let ((weight-acc 0)
	      weight-order)
	  ;; Assign running sum of weight to each entry.
	  (dolist (a (cdr p))
	    (cl-incf weight-acc (cadr (assq 'weight a)))
	    (push (cons weight-acc a) weight-order))
	  (setq weight-order (nreverse weight-order))

	  ;; While elements remain, pick a random number between 0 and
	  ;; weight-acc inclusive, and select the first entry whose
	  ;; running sum is greater than or equal to this number.
	  (while weight-order
	    (let* ((r (random (1+ weight-acc)))
		   (next-entry (cl-dolist (a weight-order)
				 (if (>= (car a) r)
				     (cl-return a)))))
	      (push (cdr next-entry) weighted-result)
	      (setq weight-order
		    (delq next-entry weight-order))))))
      ;; Extract hostnames and ports
      (mapcar #'(lambda (a) (cons (cadr (assq 'target a))
			     (cadr (assq 'port a))))
	      (nreverse weighted-result)))))

(defun srv--dns-query (target)
  "Perform DNS query for TARGET.
On Windows, call `srv--nslookup'; on all other systems, call `dns-query'."
  ;; dns-query uses UDP, but that is not supported on Windows...
  (if (featurep 'make-network-process '(:type datagram))
      (dns-query target 'SRV t)
    ;; ...so let's call nslookup instead.
    (srv--nslookup target)))

(defun srv--nslookup (target)
  "Call the `nslookup' program to make an SRV query for TARGET."
  (with-temp-buffer
    (call-process "nslookup" nil t nil "-type=srv" target)
    (goto-char (point-min))
    (let (results)
      ;; This matches what nslookup prints on Windows.  It's unlikely
      ;; to work for other systems, but on those systems we use DNS
      ;; directly.
      (while (search-forward-regexp
              (concat "[\s\t]*priority += \\(.*\\)\r?\n"
                      "[\s\t]*weight += \\(.*\\)\r?\n"
                      "[\s\t]*port += \\(.*\\)\r?\n"
                      "[\s\t]*svr hostname += \\(.*\\)\r?\n")
              nil t)
        (push
         (list
          (list 'data
                (list
                 (list 'priority (string-to-number (match-string 1)))
                 (list 'weight (string-to-number (match-string 2)))
                 (list 'port (string-to-number (match-string 3)))
                 (list 'target (match-string 4)))))
         results))
      (list (list 'answers results)))))

(provide 'srv)
;;; srv.el ends here
