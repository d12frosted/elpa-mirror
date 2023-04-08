;;; vcomp.el --- Compare version strings  -*- lexical-binding:t -*-

;; Copyright (C) 2008-2023 Jonas Bernoulli
;; Copyright (C) 2007-2008 Free Software Foundation, Inc.

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/vcomp
;; Keywords: versions
;; Package-Version: 20230407.1426
;; Package-Commit: fdd010e9081d62aa6aaa1b25a2df925efd662d0c

;; Package-Requires: ((emacs "24.1"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Compare version strings.
;; See README.org for more information.

;;; Code:

(defconst vcomp--regexp
  (concat "^\\("
          "\\([0-9]+\\(?:[-_.][0-9]+\\)*\\)"
          "\\([a-z]\\)?"
          "\\(?:[-_]?\\(alpha\\|beta\\|pre\\|rc\\|p\\)\\([0-9]+\\)?\\)?"
          "\\(?:-r\\([0-9]+\\)\\)?"
          "\\)$")
  "The regular expression used to compare version strings.")

(defvar vcomp--fill-number -1
  "Integer used for missing positions in numeric part of versions.
Either -1 or 0.  See the library header of `vcomp.el' for more
information.")

(defun vcomp-version-p (string)
  "Return t if STRING is a valid version string."
  (and (string-match-p vcomp--regexp string) t))

(defun vcomp--intern (version &optional prefix noerror)
  "Convert version string VERSION to the internal format.

If optional PREFIX is non-nil it is a partial regular expression which
matches a prefix VERSION may (but does not need to) begin with, like e.g.
a package name.  PREFIX must not begin with ^ (unless you want to
literally match it) or contain any non-shy grouping constructs.

If VERSION cannot be converted an error is raised unless optional NOERROR
is non-nil in which case nil is returned.

See the library header of `vcomp.el' for more information about
the internal format."
  (if (string-match (if prefix
                        (concat "^" prefix (substring vcomp--regexp 1))
                      vcomp--regexp)
                    version)
      (let ((num (mapcar #'string-to-number
                         (save-match-data
                           (split-string (match-string 2 version) "[-_.]"))))
            (alp (match-string 3 version))
            (tag (match-string 4 version))
            (tnm (string-to-number (or (match-string 5 version) "0")))
            (rev (string-to-number (or (match-string 6 version) "0"))))
        (list num (nconc (list (if (not alp)
                                   0
                                 (setq alp (string-to-char alp))
                                 (if (< alp 97)
                                     (+ alp 32)
                                   alp)))
                         (cond ((equal tag "alpha")
                                (list  100 tnm))
                               ((equal tag "beta")
                                (list  101 tnm))
                               ((equal tag "pre")
                                (list  102 tnm))
                               ((equal tag "rc")
                                (list  103 tnm))
                               ((equal tag nil)
                                (list  104 tnm))
                               ((equal tag "p")
                                (list  105 tnm)))
                         (list rev))))
    (unless noerror
      (error "%S isn't a valid version string" version))))

(defun vcomp-compare (v1 v2 pred)
  "Compare version strings V1 and V2 using PRED."
  (vcomp--compare-interned (vcomp--intern v1)
                           (vcomp--intern v2)
                           pred))

(defun vcomp--compare-interned (v1 v2 pred)
  (let ((l1 (length (car v1)))
        (l2 (length (car v2))))
    (cond ((> l1 l2)
           (nconc (car v2) (make-list (- l1 l2) vcomp--fill-number)))
          ((> l2 l1)
           (nconc (car v1) (make-list (- l2 l1) vcomp--fill-number)))))
  (setq v1 (nconc (car v1) (cadr v1)))
  (setq v2 (nconc (car v2) (cadr v2)))
  (while (and v1 v2 (= (car v1) (car v2)))
    (setq v1 (cdr v1))
    (setq v2 (cdr v2)))
  (if v1
      (if v2
          (funcall pred (car v1) (car v2))
        (funcall pred v1 -1))
    (if v2
        (funcall pred -1 v2)
      (funcall pred 0 0))))

(defun vcomp< (v1 v2)
  "Return t if the version string V1 is smaller than V2."
  (vcomp-compare v1 v2 #'<))

(defun vcomp> (v1 v2)
  "Return t if the version string V1 is greater than V2."
  (vcomp-compare v1 v2 #'>))

(defun vcomp= (v1 v2)
  "Return t if the version string V1 is equal to V2."
  (vcomp-compare v1 v2 #'=))

(defun vcomp<= (v1 v2)
  "Return t if the version string V1 is smaller than or equal to V2."
  (vcomp-compare v1 v2 #'<=))

(defun vcomp>= (v1 v2)
  "Return t if the version string V1 is greater than or equal to V2."
  (vcomp-compare v1 v2 #'>=))

(defun vcomp-max (version &rest versions)
  "Return largest of all the arguments (which must be version strings)."
  (dolist (elt versions)
    (when (vcomp-compare elt version #'>)
      (setq version elt)))
  version)

(defun vcomp-min (version &rest versions)
  "Return smallest of all the arguments (which must be version strings)."
  (dolist (elt versions)
    (when (vcomp-compare elt version #'<)
      (setq version elt)))
  version)

(defun vcomp-normalize (version)
  "Normalize VERSION which has to be a valid version string."
  (if (string-match vcomp--regexp version)
      (let ((num (match-string 2 version))
            (alp (match-string 3 version))
            (tag (match-string 4 version))
            (tnm (match-string 5 version))
            (rev (match-string 6 version)))
        (concat (save-match-data
                  (replace-regexp-in-string "[-_]" "." num))
                (and alp (downcase alp))
                (and tag (concat "_" (downcase tag)))
                (and tnm (not (equal tnm "0")) tnm)
                (and rev (concat "-r" rev))))
    (error "%S isn't a valid version string" version)))

(defun vcomp--prefix-regexp (&optional name)
  (concat "^\\(?:\\(?:"
          (and name (format "%s\\|" name))
          "v\\(?:ersion\\)?\\|r\\(?:elease\\)"
          "?\\)[-_]?\\)?"))

(defun vcomp-prefixed-version-p (string &optional prefix)
  "Return non-nil if STRING is a valid but possibly prefixed version string.

The returned value is the normalized part of STRING which is a valid
version string.

If optional PREFIX is non-nil it has to be a string.  If it begin with
\"^\" it is considered a partial regexp.  It must not end with \"$\" and may
only contain *shy* groups.  In this case STRING is matched against:

  (concat PREFIX (substring vcomp--regexp 1))

Otherwise if PREFIX is nil or does not begin with \"^\" the function
`vcomp--prefix-regexp' is used to create the prefix regexp.  In this
case STRING is matched against:

  (concat (vcomp--prefix-regexp PREFIX) (substring vcomp--regexp 1))

This will detect common prefixes like \"v\" or \"revision-\"."
  (and (string-match (concat (if (and prefix (string-match-p "^^" prefix))
                                 prefix
                               (vcomp--prefix-regexp prefix))
                             (substring vcomp--regexp 1))
                     string)
       (vcomp-normalize (match-string 1 string))))

(provide 'vcomp)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; vcomp.el ends here
