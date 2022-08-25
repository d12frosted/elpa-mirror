;;; org-redmine.el --- Redmine tools using Emacs OrgMode

;; Author: Wataru MIYAGUNI <gonngo@gmail.com>
;; URL: https://github.com/gongo/org-redmine
;; Package-Version: 20160711.1114
;; Package-Commit: a526c3ac802634486bf10de9c2283ccb1a30ec8d
;; Keywords: redmine org
;; Version: 0.1.0

;; Copyright (c) 2015 Wataru MIYAGUNI
;;
;; MIT License
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; This program is a client for Redmine using `org-mode'.
;; In the Emacs, uses can show list of issue (responsible, recent, all, etc..).

;;; Code:

(eval-when-compile
  (require 'cl))
(require 'org)
(require 'json)

(declare-function helm "helm")
(declare-function helm-make-source "helm-source")
(declare-function anything "anything")

(defconst org-redmine-config-default-limit 25
  "Default value the number of items to be present in the response.
default is 25, maximum is 100.

see http://www.redmine.org/projects/redmine/wiki/Rest_api#Collection-resources-and-pagination")

(defconst org-redmine-property-id-name "issue_id")
(defconst org-redmine-property-updated-name "updated_on")
(defconst org-redmine-template-header-default "#%i% %s% :%t_n%:")
(defconst org-redmine-template-%-sequences
  '(("%as_i%"    "assigned_to" "id")
    ("%as_n%"    "assigned_to" "name")
    ("%au_i%"    "author" "id")
    ("%au_n%"    "author" "name")
    ("%c_i%"     "category" "id")
    ("%c_n%"     "category" "name")
    ("%c_date%"  "created_on")
    ("%d%"       "description")
    ("%done%"    "done_ratio")
    ("%d_date%"  "due_date")
    ("%i%"       "id")
    ("%pr_i%"    "priority" "id")
    ("%pr_n%"    "priority" "name")
    ("%p_i%"     "project" "id")
    ("%p_n%"     "project" "name")
    ("%s_date%"  "start_date")
    ("%s_i%"     "status" "id")
    ("%s_n%"     "status" "name")
    ("%s%"       "subject")
    ("%t_i%"     "tracker" "id")
    ("%t_n%"     "tracker" "name")
    ("%u_date%"  "updated_on")
    ("%v_n%"     "fixed_version" "name")
    ("%v_i%"     "fixed_version" "id")))


(defvar org-redmine-uri "http://redmine120.dev"
  "Target Redmine URI")

(defvar org-redmine-auth-api-key nil)
(defvar org-redmine-auth-username nil)
(defvar org-redmine-auth-password nil)
(defvar org-redmine-auth-netrc-use nil)

(defvar org-redmine-limit org-redmine-config-default-limit
  "The number of items to be present in the response.")
(defvar org-redmine-curl-buffer "*Org redmine curl buffer*"
  "Buffer curl output")
(defvar org-redmine-template-header nil
  "")
(defvar org-redmine-template-property-use t
  "Whether to insert properties")
(defvar org-redmine-template-property nil
  "")
(defvar org-redmine-template-anything-source "#%i% [%p_n%] %s% / %as_n%")
(defvar org-redmine-template-set
  '(nil
    nil
    "%d"))

;;------------------------------
;; org-redmine error signals
;;------------------------------
(put 'org-redmine-exception-not-retrieved 'error-message "OrgRedmine - Not retrieved")
(put 'org-redmine-exception-not-retrieved 'error-conditions '(org-redmine-exception-not-retrieved error))
(put 'org-redmine-exception-no-date-format 'error-message "OrgRedmine - No date format")
(put 'org-redmine-exception-no-date-format 'error-conditions '(org-redmine-exception-no-date-format error))

;;------------------------------
;; org-redmine utility functions
;;------------------------------
(defun orutil-join (list &optional sep func)
  "Join list with a string

Example:
  (orutil-join '(\"a\" \"b\" \"c\"))
      ;; => \"a,b,c\"
  (orutil-join '(\"a\" \"b\" \"c\") \"-\")
      ;; => \"a-b-c\"
  (orutil-join '(3 \"2\" 1) \"%\")
      ;; => \"3%2%1\"
  (orutil-join '(3 2 1) \"/\" '(lambda (x) (number-to-string (* x 2))))
      ;; => \"6/4/2\"
"
  (mapconcat (lambda (x) (if func (funcall func x)
                           (format "%s" x))) list (or sep ",")))

(defun orutil-http-query (alist)
  (orutil-join alist "&"
                  (lambda (x)
                    (format "%s=%s"
                            (url-hexify-string (car x))
                            (url-hexify-string (cdr x))))))

(defun orutil-gethash (table k &rest keys)
  "Execute `gethash' recursive to TABLE.

Example:
  hashtable = {
                \"a\" : 3 ,
                \"b\" : {
                          \"c\" : \"12\",
                          \"d\" : { \"e\" : \"31\" }
                      }
              } ;; => pseudo hash table like json format
  (orutil-gethash hashtable \"a\")
      ;; => 3
  (orutil-gethash hashtable \"b\")
      ;; => { \"c\" : \"12\", \"d\" : { \"e\" : \"31\" } }
  (orutil-gethash hashtable \"b\" \"c\")
      ;; => \"12\"
  (orutil-gethash hashtable \"b\" \"d\" \"e\")
      ;; => \"31\"
  (orutil-gethash hashtable \"b\" \"a\")
      ;; => nil
  (orutil-gethash hashtable \"a\" \"c\")
      ;; => nil
"
  (save-match-data
    (let ((ret (gethash k table)))
      (while (and keys ret)
        (if (hash-table-p ret)
            (progn
              (setq ret (gethash (car keys) ret))
              (setq keys (cdr keys)))
          (setq ret nil)))
      ret)))

(defun orutil-date-to-float (s)
  "Transform date format string to float.

Format is
  %Y/%m/%d %H:%M:%S (+|-)%z
  ;; eg. 2011/07/06 21:22:01 +0900

Example.

  (orutil-date-to-float \"2011/07/06 21:22:01 +0900\")
  ;; => 1309954921.0

  (orutil-date-to-float \"2011/07/06 2a:22:01 ?0900\")
  ;; => nil
"
  (unless (string-match "^\\([0-9]+\\)/\\([0-9]+\\)/\\([0-9]+\\) \\([0-9]+\\):\\([0-9]+\\):\\([0-9]+\\) \\([+\\-]\\)\\([0-9][0-9]\\)\\([0-9][0-9]\\)$" s)
    (signal 'org-redmine-exception-no-date-format "No date format"))
  (let ((year          (string-to-number (match-string 1 s)))
        (month         (string-to-number (match-string 2 s)))
        (day           (string-to-number (match-string 3 s)))
        (hour          (string-to-number (match-string 4 s)))
        (minutes       (string-to-number (match-string 5 s)))
        (seconds       (string-to-number (match-string 6 s)))
        (zone-sign     (string-to-number (match-string 7 s)))
        (zone-hour     (string-to-number (match-string 8 s)))
        (zone-minutes (string-to-number (match-string 9 s)))
        zone)
    (setq zone (* (if (eq zone-sign "-") -1 1)
                  (+ zone-minutes (* 3600 zone-hour))))
    (float-time (encode-time seconds minutes hour day month year nil nil zone))))

(defun orutil-date-cmp (date1 date2)
  "Return t if DATE1 is before DATE2, nil otherwise.

DATE1 and DATE2 formatted defined by `orutil-date-to-float'

Example.

  (orutil-date-cmp \"2011/07/06 21:22:01 +0900\" \"2011/07/07 21:22:01 +0900\")
  ;; => t

  (orutil-date-cmp \"2011/07/06 21:22:01 +0900\" \"2011/07/06 21:22:01 +0800\")
  ;; => t
"
  (< (orutil-date-to-float date1) (orutil-date-to-float date2)))

(defun orutil-format-with-issue (fstr issue)
  "Format a string out of a format string and issue attribute hash"
  (with-temp-buffer
    (erase-buffer)
    (insert fstr)
    (goto-char (point-min))
    (while (re-search-forward "\\(%[a-z_]+%\\)" nil t)
      (let ((attr (org-redmine-template-%-to-attrkey (match-string 1))))
        (if attr (replace-match (org-redmine-issue-attrvalue issue attr) t t))))
    (buffer-string)))

(defun orutil-print-error (msg)
  (message msg)
  (list msg))

;;------------------------------
;; org-redmine connection functions
;;------------------------------
(defun org-redmine-curl-get (uri)
  ""
  (ignore-errors (kill-buffer org-redmine-curl-buffer))
  (unless (eq 0 (apply 'call-process "curl" nil `(,org-redmine-curl-buffer nil) nil
                       (org-redmine-curl-args uri)
                       ))
    (signal 'org-redmine-exception-not-retrieved "The requested URL returned error"))
  (save-current-buffer
    (set-buffer org-redmine-curl-buffer)
    (let ((json-object-type 'hash-table)
          (json-array-type 'list))
      (condition-case err
          (json-read-from-string (buffer-string))
        (json-readtable-error
         (message "%s: Non JSON data because of a server side exception. See %s"
                  (error-message-string err) org-redmine-curl-buffer))))))

(defun org-redmine-curl-args (uri)
  (let ((args '("-X" "GET" "-s" "-f")))
    (append
     args
     (cond (org-redmine-auth-api-key
            `("-G" "-d"
              ,(format "key=%s" org-redmine-auth-api-key)))
           (org-redmine-auth-username
            `("-u"
              ,(format "%s:%s"
                       org-redmine-auth-username (or org-redmine-auth-password ""))))
           (org-redmine-auth-netrc-use '("--netrc"))
           (t ""))
     `(,uri))))

;;------------------------------
;; org-redmine template functions
;;------------------------------
(defun org-redmine-template-%-to-attrkey (sequence)
  "Transform %-sequence to issue attribute list (see `org-redmine-template-%-sequences').

Example.
  (setq org-redmine-template-%-sequences
        '((\"%as_i%\"  \"assigned_to\" \"id\")
          (\"%s%\"     \"subject\")
          (\"%au_n%\"  \"author\" \"name\")))

  (org-redmine-template-%-to-attrkey \"%as_i%\") ;; => '(\"assigned_to\" \"id\")
  (org-redmine-template-%-to-attrkey \"%s%\")    ;; => '(\"subject\")
"
  (cdr (assoc sequence org-redmine-template-%-sequences)))

;;------------------------------
;; org-redmine issue function
;;------------------------------
(defun org-redmine-issue-attrvalue (issue attrkey)
  "Get attribute value for ATTRKEY of ISSUE

Example:
  issue = {
           \"subject\" : \"Subject\",
           \"project\" : {
                    \"id\"   : 1,
                    \"name\" : \"PrijectName\"
                   }
          } ;; => pseudo issue like json format

  (org-redmine-issue-attrvalue issue '(\"subject\"))      ;; => \"Subject\"
  (org-redmine-issue-attrvalue issue '(\"project\" \"id\")) ;; => 1
"
  (format "%s" (apply 'orutil-gethash issue attrkey)))

(defun org-redmine-issue-attrvalue-from-% (issue seq)
  "Get attribute value of ISSUE using %-sequence SEQ

Example:
  issue = {
           \"subject\" : \"Subject\",
           \"project\" : {
                    \"id\"   : 1,
                    \"name\" : \"PrijectName\"
                   }
          } ;; => pseudo issue like json format

  (setq org-redmine-template-%-sequences
        '((\"%p_i%\"  \"project\" \"id\")
          (\"%p_i%\"  \"project\" \"name\")
          (\"%s%\"    \"subject\")))

  (org-redmine-issue-attrvalue issue \"%s%\"))   ;; => \"Subject\"
  (org-redmine-issue-attrvalue issue \"%p_i%\")) ;; => 1
"
  (org-redmine-issue-attrvalue issue (org-redmine-template-%-to-attrkey seq)))


(defun org-redmine-issue-uri (issue)
  "Return uri of ISSUE with `org-redmine-uri'.

Example.
  (setq org-redmine-uri \"http://redmine.org\")
  (org-redmine-issue-uri issue) ;; => \"http://redmine.org/issues/1\"

  (setq org-redmine-uri \"http://localhost/redmine\")
  (org-redmine-issue-uri issue) ;; => \"http://localhost/redmine/issues/1\""
  (format "%s/issues/%s" org-redmine-uri (orutil-gethash issue "id")))

;;------------------------------
;; org-redmine entry function
;;------------------------------
(defun org-redmine-entry-get-update-info ()
  "Get property values that necessary to issue update.

Return cons (issue_id . updated_on)"
  (let ((properties (org-entry-properties)))
    (cons
     (cdr (assoc org-redmine-property-id-name properties))
     (cdr (assoc org-redmine-property-updated-name properties)))))


;;------------------------------
;; org-redmine buffer function
;;------------------------------
(defun org-redmine-insert-header (issue level)
  ""
  (let ((template (or org-redmine-template-header
                      (nth 0 org-redmine-template-set)
                      org-redmine-template-header-default))
        (stars (make-string level ?*)))
    (insert
     (concat stars " " (orutil-format-with-issue template issue)))))

(defun* org-redmine-insert-property (issue)
  ""
  (unless org-redmine-template-property-use
    (return-from org-redmine-insert-property))
  (let* ((properties (or org-redmine-template-property
                         (nth 1 org-redmine-template-set)
                         '()))
         property key value)
    (org-set-property org-redmine-property-id-name (int-to-string (orutil-gethash issue "id")))
    (org-set-property org-redmine-property-updated-name (orutil-gethash issue "updated_on"))
    (while properties
      (setq property (car properties))
      (org-set-property (car property)
                        (org-redmine-issue-attrvalue-from-% issue (cdr property)))
      (setq properties (cdr properties)))
  ))

(defun org-redmine-escaped-% ()
  "Check if % was escaped - if yes, unescape it now."
  (if (equal (char-before (match-beginning 0)) ?\\)
      (progn
        (delete-region (1- (match-beginning 0)) (match-beginning 0))
        t)
    nil))

(defun org-redmine-insert-subtree (issue)
  ""
  (if (hash-table-p issue)
      (let ((level (or (org-current-level) 1)))
        (outline-next-visible-heading 1)
        (org-redmine-insert-header issue level)
        (insert "\n")
        (outline-previous-visible-heading 1)
        (org-redmine-insert-property issue))))

;;------------------------------
;; org-redmine sources for user function
;;------------------------------
(defun org-redmine-get-issue-all (me)
  "Return the recent issues (list of hash-table).
When error occurs, return list of error message.

if ME is t, return issues are assigned to user.
"
  (let ((querylist (list (cons "limit" (org-redmine-config-get-limit t))))
        query issue-all)

    (condition-case err
        (progn
          (if me (add-to-list 'querylist (cons "assigned_to_id" "me")))
          (setq query (orutil-http-query querylist))
          (setq issue-all (org-redmine-curl-get
                           (concat org-redmine-uri "/issues.json?" query)))
          (orutil-gethash issue-all "issues"))
      (org-redmine-exception-not-retrieved
       (orutil-print-error (format "%s: Can't get issues on %s"
                                   (error-message-string err) org-redmine-uri))))))

(defun org-redmine-transformer-issues-source (issues)
  "Transform issues to `anything' source.

First, string that combined issue id, project name, subject, and member assinged to issue.
Second, issue (hash table).

Example.
  (setq issues '(issue1 issue2 issue3)) ;; => issue[1-3] is hash table
  (org-redmine-transformer-issues-source issues)
  ;; => '((issue1-string . issue1) (issue2-string . issue2) (issue3-string . issue3))
"
  (mapcar
   (lambda (issue)
     (cond ((stringp issue)
            (cons issue nil))
           ((hash-table-p issue)
            (cons (orutil-format-with-issue org-redmine-template-anything-source
                                            issue)
                  issue))))
   issues))

;;------------------------------
;; org-redmine config function
;;------------------------------
(defun org-redmine-config-get-limit (&optional toStr)
  (let ((limit org-redmine-limit))
    (if (integerp limit)
        (when (or (< limit 1) (> limit 100))
          (message (format "Warning: org-redmine-limit is out of range. return default value %s"
                           org-redmine-config-default-limit))
          (setq limit org-redmine-config-default-limit))
      (progn
        (message (format "Warning: org-redmine-limit isn't integer. return default value %s"
                         org-redmine-config-default-limit))
        (setq limit org-redmine-config-default-limit)))
    (if toStr (int-to-string limit) limit)))

;;------------------------------
;; org-redmine user function
;;------------------------------
;;;###autoload
(defun org-redmine-get-issue (issue-id)
  ""
  (interactive "sIssue ID: ")
  (let (issue)
    (condition-case err
        (progn
          (setq issue (org-redmine-curl-get
                       (format "%s/issues/%s.json" org-redmine-uri issue-id)))
          (org-redmine-insert-subtree (orutil-gethash issue "issue")))
      (org-redmine-exception-not-retrieved
       (orutil-print-error
        (format "%s: Can't find issue #%s on %s"
                (error-message-string err) issue-id org-redmine-uri))))))

;;;###autoload
(defun org-redmine-anything-show-issue-all (&optional me)
  "Display recent issues using `anything'"
  (interactive "P")
  (if (require 'anything nil t)
      (anything
       `(((name . "Issues")
          (candidates . ,(org-redmine-get-issue-all me))
          (candidate-transformer . org-redmine-transformer-issues-source)
          (volatile)
          (action . (("Open Browser"
                      . (lambda (issue) (browse-url (org-redmine-issue-uri issue))))
                     ("Insert Subtree"
                      . (lambda (issue) (org-redmine-insert-subtree issue))))))))
    (message "`anything` is not available. Please install it.")))

;;;###autoload
(defun org-redmine-helm-show-issue-all (&optional me)
  "Display recent issues using `helm'"
  (interactive "P")
  (if (require 'helm nil t)
      (helm :sources (helm-make-source "Issues" 'helm-source-sync
                       :candidates (lambda () (org-redmine-get-issue-all me))
                       :candidate-transformer '(org-redmine-transformer-issues-source)
                       :volatile t
                       :action '(("Open Browser"
                                  . (lambda (issue) (browse-url (org-redmine-issue-uri issue))))
                                 ("Insert Subtree"
                                  . (lambda (issue) (org-redmine-insert-subtree issue))))))
    (message "`helm` is not available. Please install it.")))

(provide 'org-redmine)

;;; org-redmine.el ends here
