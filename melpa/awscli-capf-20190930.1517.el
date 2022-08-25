;;; awscli-capf.el --- Completion at point function for the AWS CLI  -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Sebastian Monia
;;
;; Author: Sebastian Monia <smonia@outlook.com>
;; URL: https://github.com/sebasmonia/awscli-capf.git
;; Package-Version: 20190930.1517
;; Package-Commit: 1a75f88f53a2969fe821c31e6857861d0a0c0a5e
;; Package-Requires: ((emacs "26"))
;; Version: 1.0
;; Keywords: tools convenience abbrev

;; This file is not part of GNU Emacs.

;;; License: MIT

;;; Commentary:

;; Add the function `awscli-capf' to the list of completion functions, for example:
;;
;; (require 'awscli-capf)
;; (add-hook 'shell-mode-hook (lambda ()
;;                             (add-to-list 'completion-at-point-functions 'awscli-capf)))
;;
;; or with use-package:
;;
;; (use-package awscli-capf
;;   :commands (awscli-add-to-capf)
;;   :hook (shell-mode . awscli-add-to-capf))
;;
;; For more details  see https://github.com/sebasmonia/awscli-capf/blob/master/README.md
;;
;;; Code:

(require 'cl-lib)

(defgroup awscli-capf nil
  "Completion at point function for the AWS CLI."
  :group 'extensions)

(defcustom awscli-capf-completion-prefix "aws"
  "Word used to trigger completion via this package.
The function `awscli-capf' will search for this string as the first
\"expression\" in the line to determine if it has to provide completion
candidates."
  :type 'string)

(defcustom awscli-capf-cli-executable "aws"
  "Name of the executable used to get the AWS CLI help via shell calls.
Used when calling `awscli-capf-refresh-data-from-cli'.  Customize this if you
use an alternative tool, and its help format is compatible with the standard
one.  Or for example, if you need to include the full path to the executable."
  :type 'string)

(defconst awscli-capf--script-dir (if load-file-name (file-name-directory load-file-name) default-directory) "The directory from which the package loaded, or `default-directory' if the buffer is evaluated.")
(defconst awscli-capf--data-file (expand-file-name "awscli-capf-docs.data" awscli-capf--script-dir) "Location of the file with the help data.")
(defvar awscli-capf--services-info nil "Names and docs of all services, commands and options of the AWS CLI.")
(defvar awscli-capf--global-options-info nil "Top level options of the AWS CLI.")

(defun awscli-capf-add ()
  "Convenience function to invoke in a mode's hook to get AWS CLI completion.
It adds `awscli-capf' to `completion-at-point-functions'."
  (add-to-list 'completion-at-point-functions
               'awscli-capf))

(defun awscli-capf ()
  "Function for completion at point of AWS CLI services and commands.
Run \"(add-to-list 'completion-at-point-functions 'awscli-capf)\" in a mode's hook to add this completion."
  (unless awscli-capf--services-info
    (awscli-capf--read-data-from-file))
  (save-excursion
    (let* ((line (split-string (thing-at-point 'line t)))
           (bounds (bounds-of-thing-at-point 'sexp)) ;; 'word is delimited by "-" in shell modes, 'sexp is "space delimited" like we want
           (aws-command-start (cl-position awscli-capf-completion-prefix line :test #'string=))
           (service (when aws-command-start (elt line (+ 1 aws-command-start))))
           (command (when aws-command-start (elt line (+ 2 aws-command-start))))
           ;; parameters start with --, we use this to filter parameters already consumed
           (params (when aws-command-start (awscli-capf--param-strings-only (cl-subseq line aws-command-start))))
           (service-names-docs (awscli-capf--service-completion-data)) ;; we always need the service names to confirm we have a good match
           (command-names-docs (awscli-capf--command-completion-data service)) ;; will return data for a "good" service name, or nil for a partial/invalid entry
           (candidates nil)) ;; populated in the cond below
      (message (thing-at-point 'word t))
      (when aws-command-start
        (cond ((and service (member command command-names-docs)) (setq candidates (awscli-capf--parameters-completion-data service command params)))
              ((and service (member service service-names-docs)) (setq candidates command-names-docs))
              ;; if it's an aws command but there's no match for service name, complete service
              (t (setq candidates service-names-docs)))
        (when bounds
          (list (car bounds)
                (cdr bounds)
                candidates
                :exclusive 'no
                :annotation-function #'awscli-capf--annotation
                :company-docsig #'identity
                :company-doc-buffer #'awscli-capf--help-buffer))))))

(cl-defstruct (awscli-capf--service (:constructor awscli-capf--service-create)
                               (:copier nil))
  name commands docs)

(cl-defstruct (awscli-capf--command (:constructor awscli-capf--command-create)
                               (:copier nil))
  name options docs)

(cl-defstruct (awscli-capf--option (:constructor awscli-capf--option-create)
                               (:copier nil))
  name type docs)

(defun awscli-capf--help-buffer (candidate)
  "Extract from CANDIDATE the :awsdoc text property."
  ;; this property is added to the name string in the function that gets
  ;; the completion data for "candidates" list @ func awscli-capf
  (when (fboundp 'company-doc-buffer)
    (company-doc-buffer (get-text-property 0 :awsdoc candidate))))

(defun awscli-capf--annotation (candidate)
  "Extract from CANDIDATE the :awsannotation text property.
Return empty string if not present."
  ;; this property is added to the name string in the function that gets
  ;; the completion data for "candidates" list @ func awscli-capf. So far only present for
  ;; parameters
  (let ((aws-annotation (get-text-property 0 :awsannotation candidate)))
    (or aws-annotation "")))

(defun awscli-capf--store-data-in-file (records)
  "Save RECORDS in `awscli-capf--data-file'."
  (with-temp-buffer
    (insert (prin1-to-string records))
    (write-file awscli-capf--data-file)
    (message "awscli-capf - updated completion data")))

(defun awscli-capf--read-data-from-file ()
  "Load the completion data stored in `awscli-capf--data-file'."
  (unless (file-exists-p awscli-capf--data-file)
    (when (y-or-n-p "Completion data not present (approx 29 MB), download it? ")
      (url-copy-file "https://github.com/sebasmonia/awscli-capf/raw/master/awscli-capf-docs.data"
                     awscli-capf--data-file
                     nil
                     t)))
  (with-temp-buffer
    (insert-file-contents awscli-capf--data-file)
    (let ((all-data (read (buffer-string))))
      (setq awscli-capf--services-info (cl-first all-data))
      (setq awscli-capf--global-options-info (cl-second all-data))
      (message "awscli-capf - loaded completion data"))))

(defun awscli-capf--param-strings-only (strings)
  "Filter the list of STRINGS and keep only the ones starting with \"--\"."
  (cl-remove-if-not (lambda (str) (string-prefix-p "--" str)) strings))

(defun awscli-capf--service-completion-data ()
  "Generate the completion data for services.
The format is a string of the service name, with two extra properties, :awsdoc
and :awsannotation that contain help text for the help buffer and minibuffer, respectively."
  (mapcar (lambda (serv)
            (propertize (awscli-capf--service-name serv)
                        :awsdoc (awscli-capf--service-docs serv)
                        :awsannotation " (aws service)"))
          awscli-capf--services-info))

(defun awscli-capf--command-completion-data (service-name)
  "Generate the completion data for a SERVICE-NAME commands.
The format is a string of the command name, with a property :awsdoc that
contains the help text."
  (let ((service (cl-find service-name
                          awscli-capf--services-info
                          :test (lambda (value item)
                                  (string= (awscli-capf--service-name item) value)))))
    (when service
      (mapcar (lambda (comm)
                (propertize (awscli-capf--command-name comm)
                            :awsdoc (awscli-capf--command-docs comm)
                            :awsannotation " (aws command)"))
              (awscli-capf--service-commands service)))))

(defun awscli-capf--parameters-completion-data (service-name command-name used-params)
    "Generate the completion data for the parameters of COMMAND-NAME.
The command is searched under SERVICE-NAME.  USED-PARAMS are excluded from the
results.  The format is a string with the service name, with a property :awsdoc
that contains the parameter's type and help text."
  (let* ((service (cl-find service-name
                           awscli-capf--services-info
                           :test (lambda (value item)
                                   (string= (awscli-capf--service-name item) value))))
         (command (when service
                    (cl-find command-name
                             (awscli-capf--service-commands service)
                             :test (lambda (value item)
                                     (string= (awscli-capf--command-name item) value))))))
    (when command
      (cl-remove-if (lambda (item) (member item used-params))
                    (mapcar (lambda (opt)
                              (propertize (awscli-capf--option-name opt)
                                          :awsdoc (format "Type: %s\n\n%s"
                                                          (awscli-capf--option-type opt)
                                                          (awscli-capf--option-docs opt))
                                          :awsannotation (format " (aws param - %s)"
                                                                 (awscli-capf--option-type opt))))
                            (cl-concatenate 'list
                                         (awscli-capf--command-options command)
                                         awscli-capf--global-options-info))))))

(defun awscli-capf-refresh-data-from-cli ()
  "Run \"aws help\" in a shell and and parse output to update cached docs.
More functions are invoked from this one to update commands and parameters.
You can customize the executable used via `awscli-capf-cli-executable'."
  (interactive)
  (with-temp-buffer
    ;; replace "" in the output, which happens running the tool under linux/osx in certain conditions
    ;; when this occurs, it's the control char + a repeat of the previous character
    (insert (replace-regexp-in-string ".\\{1\\}" "" (shell-command-to-string (concat awscli-capf-cli-executable " help"))))
    (goto-char (point-min))
    ;; We could search  without case-fold-search but in that case we risk any instance of "options" in any
    ;; phrase to match. Instead let's be specific about Windows headers ("Options") and *nix headers "OPTIONS"
    (let* ((case-fold-search nil)
           (opt-start (or (search-forward-regexp "^Options$" nil t) (search-forward-regexp "^OPTIONS$" nil t)))
           (serv-start (or (search-forward-regexp "^Available Services$" nil t) (search-forward-regexp "^AVAILABLE SERVICES$" nil t)))
           (serv-end (or (search-forward-regexp "^See Also$" nil t) (search-forward-regexp "^SEE ALSO$" nil t)))
           (global-options nil)
           (services nil)
           (linux-re-from-emacs-wiki (concat "\\(--.*?\\) \(\\(.*?\\)\)\n\n"
                                             "\\(.*\\(?:\n.*\\)*?\\)"   ;; definition: to end of line,
                                             ;; then maybe more lines
                                             ;; (excludes any trailing \n)
                                             "\\(?:\n\\s-*\n\\|\\'\\)")))
      ;; from the "Options" title, search for all the occurrences
      ;; of "--something-something", bound to the start of services names
      ;; and retrieve from the line the text between quotes
      (goto-char opt-start)
      (while (or (search-forward-regexp "^\"\\(.*?\\)\" (\\(.*?\\))\n\n\\(.*\\)" serv-start t)
                 (search-forward-regexp linux-re-from-emacs-wiki serv-start t))
        (push (awscli-capf--option-create :name (match-string 1)
                                      :type (match-string 2)
                                      :docs (match-string 3))
              global-options))
      ;; from the "Available Services" title, search for all the occurrences
      ;; of "* something", bound to the start the "See Also" title
      ;; and retrieve from the line the text after "* "
      (goto-char serv-start)
      (while (or (search-forward-regexp "^* \\(.*\\)$" serv-end t)
                 (search-forward-regexp "+ \\(.*\\)$" serv-end t))
        (let ((service-name (match-string 1)))
          (unless (string= service-name "help")
            (push (awscli-capf--service-data-from-cli service-name)
                  services))))
      (awscli-capf--store-data-in-file (list services global-options)))))

(defun awscli-capf--service-data-from-cli (service)
  "Run \"aws [SERVICE] help\" in a shell and parse output to update cached docs.
For each command in the service, more functions are called to parse command and
parameter output."
  (with-temp-buffer
    (message "Service: %s" service)
    ;; replace "" in the output, which happens running the tool under linux/osx in certain conditions
    ;; when this occurs, it's the control char + a repeat of the previous character
    (insert (replace-regexp-in-string
             ".\\{1\\}" ""
             (shell-command-to-string
              (format "%s %s %s" awscli-capf-cli-executable service "help"))))
    (goto-char (point-min))
    (let* ((case-fold-search t)
           (command-start (or (search-forward-regexp "^Available Commands$" nil t)
                              (search-forward-regexp "^AVAILABLE COMMANDS$" nil t)))
           (commands nil))
      ;; from the "Available Commands" title, search for all the occurrences
      ;; of "* something" until the end of the buffer, and retrieve
      ;; from the line the text after "* "
      ;; In non-Windows OS, the starting char is + instead of *, with an extra tab
      ;; so match from that character
      (message "command-start: ---------%s----------" command-start)
      (when command-start
        (goto-char command-start)
        (while (or (search-forward-regexp "^* \\(.*\\)$" nil t)
                   (search-forward-regexp "+ \\(.*\\)$" nil t))
          (let ((command-name (match-string 1)))
            (unless (string= command-name "help") ;; yeah, skip "help"
              (push (awscli-capf--command-data-from-cli service command-name)
                    commands)))))
      ;; return the service, use the entire buffer as help string
      (awscli-capf--service-create :name service
                               :commands commands
                               :docs (buffer-string)))))

(defun awscli-capf--command-data-from-cli (service command-name)
  "Run \"aws [SERVICE] [COMMAND-NAME] help\" to update the cached docs.
This is the last level of output parsing."
  (with-temp-buffer
    (message "Service: %s Command: %s" service command-name)
    ;; replace "" in the output, which happens running the tool under linux/osx in certain conditions
    ;; when this occurs, it's the control char + a repeat of the previous character
    (insert (replace-regexp-in-string
             ".\\{1\\}" ""
             (shell-command-to-string
              (format "%s %s %s help" awscli-capf-cli-executable service command-name))))
    (goto-char (point-min))
    (let* ((case-fold-search t)
           (opt-start (or (search-forward-regexp "^Options$" nil t)
                          (search-forward-regexp "^OPTIONS$" nil t)))
           (options nil)
           (linux-re-from-emacs-wiki (concat "\\(--.*?\\) \(\\(.*?\\)\)\n\n"
                                             "\\(.*\\(?:\n.*\\)*?\\)"   ;; definition: to end of line,
                                             ;; then maybe more lines
                                             ;; (excludes any trailing \n)
                                             "\\(?:\n\\s-*\n\\|\\'\\)")))
      ;; from the "Options" title, search for all the occurrences
      ;; of "--something-something" until the end of the buffer,
      ;; and retrieve from the line the text between quotes
      ;; some commands don't have "Options", for now we ignore them but
      ;; there's a chance that handling will be added later
      ;; The format for options is different in non-Windows OS and we
      ;; account for that in the "(or ...)"
      (when opt-start
        (goto-char opt-start)
        (while (or (search-forward-regexp "^\"\\(.*?\\)\" (\\(.*?\\))\n\n\\(.*\\)" nil t)
                   (search-forward-regexp linux-re-from-emacs-wiki nil t))
          (push (awscli-capf--option-create :name (match-string 1)
                                        :type (match-string 2)
                                        :docs (match-string 3))
                options)))
      (awscli-capf--command-create :name command-name
                               :options options
                               :docs (buffer-string)))))

(provide 'awscli-capf)
;;; awscli-capf.el ends here
