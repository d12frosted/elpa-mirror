;;; cern-ldap.el --- Library to interact with CERN's LDAP servers  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Nacho Barrientos

;; Author: Nacho Barrientos <nacho.barrientos@cern.ch>
;; Keywords: tools, convenience
;; Package-Version: 20230321.1439
;; Package-Commit: 01e2798948245316178c392811324c09981a98ee
;; URL: https://git.sr.ht/~nbarrientos/cern-ldap.el
;; Package-Requires: ((emacs "27.1"))
;; Version: 0.0.1

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

;; This package provides some functions allowing to look-up in CERN's
;; LDAP server user accounts (searching by login and full name) and
;; the contents of user groups (also known as e-groups).  The results
;; are normally displayed in dedicated buffers.

;;; Code:

(require 'format-spec)
(require 'ldap)
(require 'seq)
(require 'subr-x)
(require 'subword)
(require 'thingatpt)

(defcustom cern-ldap-server-url "ldap://xldap.cern.ch:389"
  "URL pointing to the LDAP instance to query.

Proven you're in the CERN network the default value should be
good enough.  If you're tunnelling the connection you might have
to change the value of this variable."
  :group 'cern-ldap
  :type 'string)

(defcustom cern-ldap-buffer-name-format "*CERN LDAP %t (%l)*"
  "Format for the buffer names that display results.

%t represents the type of lookup, namely \"user\" or \"group\"
and %l the corresponding search string."
  :group 'cern-ldap
  :type 'string)

(defcustom cern-ldap-finish-hook nil
  "Hook run after the results buffer is prepared."
  :group 'cern-ldap
  :type 'hook)

(defcustom cern-ldap-user-lookup-location-key "physicalDeliveryOfficeName"
  "Field to search in when looking up user accounts by location.

The value of this variable will be used as search field at the
time of querying LDAP when calling `cern-ldap-user-by-location'"
  :group 'cern-ldap
  :type 'string)

(defcustom cern-ldap-user-lookup-login-key "sAMAccountName"
  "Field to search in when looking up user accounts by login.

The value of this variable will be used as search field at the
time of querying LDAP when calling `cern-ldap-user-by-login'"
  :group 'cern-ldap
  :type 'string)

(defcustom cern-ldap-user-lookup-full-name-key "displayName"
  "Field to search in when looking up user accounts by full name.

The value of this variable will be used as search field at the
time of querying LDAP when calling `cern-ldap-user-by-full-name'"
  :group 'cern-ldap
  :type 'string)

(defcustom cern-ldap-user-full-name-matching-type 'relaxed
  "Define how the full name matching is performed when searching.

Accepted values are the symbols: `relaxed' which means that the
provided full name will be prefixed and postfixed by * (allowing
for instance to search by family name only) and `strict' which
searches for users with exactly the provided full name."
  :group 'cern-ldap
  :type '(choice (const :tag "Relaxed" relaxed)
                 (const :tag "Strict" strict)))

(defcustom cern-ldap-user-displayed-attributes
  '("memberOf" "manager" "department" "physicalDeliveryOfficeName"
    "name" "displayName" "cernExternalMail" "seeAlso" "cernAccountType")
  "List of attributes to display when printing discovered users.

Only this selection of attributes will be displayed when a set of
results containing user accounts is displayed.  However, take into
account that some functions like `cern-ldap-user-by-full-name'
and `cern-ldap-user-by-login' have means to ignore this
configuration."
  :group 'cern-ldap
  :type '(repeat string))

(defcustom cern-ldap-user-group-membership-filter ".*"
  "Regular expression restricting the group membership to be shown.

When skimmed results are displayed when looking up user
accounts (which is the default), this regular expression allows
restricting as well what groups the user is member of are
shown.  This is useful if you don't want to clutter the result
list with non-interesting group memberships."
  :group 'cern-ldap
  :type 'regex)

(defcustom cern-ldap-user-sort-key "cernAccountType"
  "LDAP field user entries will be sorted by.

By default results are sorted by account type, aiming to have
primary accounts listed first.

This field must be part of `cern-ldap-user-displayed-attributes'"
  :group 'cern-ldap
  :type 'string)

(defconst cern-ldap--user-base-dn "OU=Users,OU=Organic Units,DC=cern,DC=ch"
  "The base DN when searching for users.")

(defconst cern-ldap--group-base-dn "OU=e-groups,OU=Workgroups,DC=cern,DC=ch"
  "The base DN when searching for groups.")

;;;###autoload
(defun cern-ldap-user-by-login-dwim (arg)
  "Look-up account by login in the active region or the word at point.

Without prefix argument ARG, the number of fields per result user
entry displayed is limited to the selection configured in
`cern-ldap-user-displayed-attributes' and, if \"memberOf\" is
part of that list, the groups the user is member of is filtered
by the regular expression defined in
`cern-ldap-user-group-membership-filter'."
  (interactive "P")
  (and-let* ((login (if (use-region-p)
                        (buffer-substring-no-properties
                         (region-beginning) (region-end))
                      (word-at-point t))))
    (cern-ldap-user-by-login arg login)))

;;;###autoload
(defun cern-ldap-user-by-full-name-dwim (arg)
  "Look-up account by full name in the active region.

See `cern-ldap-user-by-login-dwim' for instructions on how to control
how the results are displayed/filtered using ARG."
  (interactive "P")
  (and-let* ((full-name (when (use-region-p)
                          (buffer-substring-no-properties
                           (region-beginning) (region-end)))))
    (cern-ldap-user-by-full-name arg full-name)))

;;;###autoload
(defun cern-ldap-user-by-login (arg login)
  "Look-up user account with username LOGIN in LDAP.

See `cern-ldap-user-by-login-dwim' for instructions on how to control
how the results are displayed/filtered using ARG."
  (interactive "P\nsLogin: ")
  (cern-ldap--display-user
   arg
   (concat cern-ldap-user-lookup-login-key "=" login)))

(defun cern-ldap-user-by-location (arg building floor room)
  "Look-up primary user accounts in a given physical location in LDAP.

The location to be looked-up is generated by combining the
arguments of the function in the form BUILDING/FLOOR-ROOM.

See `cern-ldap-user-by-login-dwim' for instructions on how to
control how the results are displayed/filtered using ARG."
  (interactive "P\nnBuilding: \nnFloor: \nnRoom: ")
  (let ((location (format "%d %d-%03d" building floor room)))
    (cern-ldap--display-user
     arg
     (format "(&(%s)(%s))"
             (concat cern-ldap-user-lookup-location-key "=" location)
             "cernAccountType=Primary"))))

;;;###autoload
(defun cern-ldap-user-by-full-name (arg full-name)
  "Look-up user account with full name FULL-NAME in LDAP.

How the matching of the full name is performed depends on the
value of the variable `cern-ldap-user-full-name-matching-type'.

See `cern-ldap-user-by-login-dwim' for instructions on how to control
how the results are displayed/filtered using ARG."
  (interactive "P\nsFull name: ")
  (let ((search-value
         (pcase cern-ldap-user-full-name-matching-type
           ('relaxed (format "*%s*" full-name))
           ('strict full-name)
           (_ (user-error "Invalid full name matching type")))))
    (cern-ldap--display-user
     arg
     (concat cern-ldap-user-lookup-full-name-key "=" search-value))))

(defun cern-ldap-users-single-attribute (accounts attribute)
  "Return the values of ATTRIBUTE for all ACCOUNTS.

The elements of ACCOUNTS will be searched for using
`cern-ldap-user-lookup-full-name-key'.

This function is useful for instance to obtain the break-down of
organisational units for a list of accounts, for example:

\(seq-sort-by #'cdr
              #'>
              (-frequencies
               (cern-ldap-users-single-attribute
                '(\"user1\" \"user2\")
                \"department\")))"
  (mapcar (lambda (login)
            (cadr (flatten-list
                   (cern-ldap--lookup-user
                    (concat cern-ldap-user-lookup-login-key "=" login)
                    (list attribute)))))
          accounts))

;;;###autoload
(defun cern-ldap-group-dwim (arg)
  "Expand the group which is in the active region or the word at point.
See `cern-ldap-group' for the meaning of the prefix argument ARG."
  (interactive "P")
  (let* ((previous-superword-mode superword-mode)
         (_dummy (superword-mode 1))
         (group (if (use-region-p)
                    (buffer-substring-no-properties (region-beginning) (region-end))
                  (word-at-point t))))
    (setq superword-mode previous-superword-mode)
    (when group
      (cern-ldap-group arg group))))

;;;###autoload
(defun cern-ldap-group (arg group)
  "Print in a temporary buffer the members of GROUP.

By default the resulting list will be composed exclusively by
user accounts.  However, with prefix argument ARG to disable
recursion, it will be a mix of user accounts and other groups.

The buffer name is controlled by `cern-ldap-buffer-name-format'.

Once in the results buffer, C-<return> on a login name will
automatically lookup information about that username."
  (interactive "P\nsGroup: ")
  (let ((buffer-n (format-spec
                   cern-ldap-buffer-name-format
                   `((?t . "group")
                     (?l . ,group))))
        (members (cern-ldap--expand-group group (not arg))))
    (if members
        (with-temp-buffer-window buffer-n
            #'display-buffer-reuse-window
            nil
          (with-current-buffer buffer-n
            (mapc (lambda (member)
                    (insert member)
                    (newline))
                  members)
            (local-set-key (kbd "q") 'kill-this-buffer)
            (local-set-key (kbd "C-<return>") 'cern-ldap-user-by-login-dwim)
            (sort-lines nil (point-min) (point-max))
            (run-hooks 'cern-ldap-finish-hook)))
      (user-error "%s is an empty or unknown group" group))))

(defun cern-ldap--lookup-user (filter attributes)
  "Return the value of some ATTRIBUTES for users matching FILTER.

The results are sorted alphabetically by `cern-ldap-user-sort-key'."
  (seq-sort-by
   (lambda (e)
     (cadr (assoc cern-ldap-user-sort-key e)))
   #'string<
   (cern-ldap--query
    filter
    attributes
    cern-ldap--user-base-dn)))

(defun cern-ldap--display-user (arg filter)
  "Lookup users in LDAP returning some attributes in a new buffer.

The results will be delivered in a temporary read-only buffer
named using `cern-ldap-buffer-name-format'.

The users returned are the ones satisfying FILTER.  With prefix
argument ARG, return all attributes, else return only a small
selection controlled by `cern-ldap-user-group-membership-filter' and
`cern-ldap-user-displayed-attributes'.

Once in the results buffer, C-<return> on a login name will
automatically lookup information about that username."
  (let* ((buffer-n (format-spec
                    cern-ldap-buffer-name-format
                    `((?t . "user")
                      (?l . ,filter))))
         (attributes (unless arg
                       cern-ldap-user-displayed-attributes))
         (data (cern-ldap--lookup-user filter attributes)))
    (if data
        (with-temp-buffer-window buffer-n
            #'display-buffer-reuse-window
            nil
          (and (< 1 (length data))
               (message "%d results found" (length data)))
          (with-current-buffer buffer-n
            (dolist (result data)
              (dolist (field
                       (cl-remove-if
                        (lambda (e)
                          (and
                           (not arg)
                           (string= "memberOf" (car e))
                           (not (string-match cern-ldap-user-group-membership-filter (cadr e)))))
                        result))
                (insert (format "%s:%s" (car field) (cadr field)))
                (newline))
              (newline))
            (goto-char (point-min))
            (conf-mode)
            (local-set-key (kbd "C-<return>") 'cern-ldap-user-by-login-dwim)
            (local-set-key (kbd "q") 'kill-this-buffer)
            (run-hooks 'cern-ldap-finish-hook)))
      (user-error "No user accounts found"))))

(defun cern-ldap--expand-group (group &optional recurse)
  "Return the members of GROUP.

If RECURSE make the expansion recursive (in other words, groups
inside groups are expanded)."
  (let ((members (car (cern-ldap--query
                       (format "(&(objectClass=group)(CN=%s))" group)
                       '("member")
                       cern-ldap--group-base-dn)))
        (results nil))
    (dolist (member members)
      (and-let* ((dn (car (cdr member)))
                 (match (string-match "^CN=\\(.+?\\),OU=\\(.+?\\),OU=\\(.+?\\),DC=cern,DC=ch" dn))
                 (cn (match-string 1 dn))
                 (ou-1 (match-string 2 dn))
                 (ou-2 (match-string 3 dn)))
        (cond ((and
                recurse
                (string= "e-groups" (downcase ou-1)))
               (setq results (append (cern-ldap--expand-group cn recurse) results)))
              ((string= "users" (downcase ou-1))
               (push cn results))
              ((and
                (= (length ou-1) 1)
                (string= "externals" (downcase ou-2)))
               nil)
              (t
               (push dn results)))))
    (delete-dups results)))

(defun cern-ldap--query (filter attributes basedn)
  "Perform an LDAP search in CERN LDAP servers.

Using FILTER as filter, retrieve only ATTRIBUTES using BASEDN as
base search."
  (let ((ldap-host-parameters-alist
         (list
          `(,cern-ldap-server-url
            base ,basedn
            auth simple scope subtree))))
    (ldap-search
     filter
     cern-ldap-server-url
     attributes)))

(provide 'cern-ldap)
;;; cern-ldap.el ends here
