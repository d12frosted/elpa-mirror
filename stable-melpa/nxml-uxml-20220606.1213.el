;;; nxml-uxml.el --- MicroXML support for nXML -*- lexical-binding: t -*-
;;
;;; Version: 0.0
;;; Author: Daphne Preston-Kendal
;;; URL: https://gitlab.com/dpk/nxml-uxml
;;; Keywords: languages, XML, MicroXML
;;; Package-Requires: ((emacs "25"))
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is *NOT* part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs. If not, see <https://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;   MicroXML is a delightful tiny subset of XML, removing everything
;;   that makes XML a nightmare to deal with in practice.
;;   nxml-uxml-mode is a major mode for Emacs that slightly modifies
;;   the XML parser of nxml-mode to forbid most (though, at present,
;;   not quite all) constructs which are allowed in XML 1.0 but
;;   disallowed in MicroXML.
;;
;;; Code:

(require 'nxml-mode)

;;;###autoload
(define-derived-mode nxml-uxml-mode nxml-mode "nµXML"
  "Major mode for editing MicroXML.

Derived from and in most respects identical to nXML mode, but
with a parser that rejects any constructs invalid in nXML."
  ;; TODO: Check the RNC file to make sure it defines a
  ;; MicroXML-compatible schema
  ;;
  ;; TODO: Disallow non-characters and control characters
  ;;
  ;; TODO: Disallow encodings other than UTF-8
  (setq-local nxml-uxml-restrictions-p t)
  (advice-add 'xmltok-forward-prolog :filter-return #'nxml-uxml-disallow-in-prolog)
  (advice-add 'xmltok-forward :filter-return #'nxml-uxml-disallow-in-content)
  ;; To disable:
  ;; (advice-remove 'xmltok-forward-prolog #'nxml-uxml-disallow-in-prolog)
  ;; (advice-remove 'xmltok-forward #'nxml-uxml-disallow-in-content)
  
  ;; I haven't found a better way than this to force nXML to (re)check
  ;; the whole document for errors:
  (rng-after-change-function (point-min) (point-max) (point-max)))

(defvar-local nxml-uxml-restrictions-p nil
  "Whether MicroXML restrictions are in effect in nXML mode.

This variable is set automatically by `nxml-uxml-mode'; there
should be no need to set it manually.")

(defvar-local nxml-uxml-allow-newlines-in-attributes nil
  "Whether to allow newlines in attribute values in MicroXML.

The default is nil out of an abundance of caution, even though
they're technically allowed in MicroXML, because conformant XML
processing tools will treat them differently to conformant
MicroXML parsers.")

(defun nxml-uxml-disallow-in-prolog (prolog)
  "Disallow the XML prolog.

Argument PROLOG is returned unchanged (this is advice for
`xmltok-forward-prolog')."
  (when nxml-uxml-restrictions-p
    (with-demoted-errors "µXML Error: %S"
      (dolist (item prolog)
        (let ((type (aref item 0))
              (start (aref item 1))
              (end (aref item 2)))
          (cond ((eq type 'xml-declaration)
                 (xmltok-add-error "XML declaration not allowed in MicroXML"
                                   start end))
                ((eq type 'markup-declaration-open)
                 (if (string= (buffer-substring start end) "<!DOCTYPE")
                     (xmltok-add-error "DOCTYPE declaration not allowed in MicroXML"
                                       start end)
                   (xmltok-add-error "Declaration not allowed in MicroXML"
                                     start end)))
                ((eq type 'processing-instruction-left)
                 (xmltok-add-error "Processing instruction not allowed in MicroXML"
                                   start end)))))))
  prolog)

(defun nxml-uxml-disallow-gts (start end)
  "Disallow the raw character > between START and END."
  (when (and start end)
    (save-excursion
      (goto-char start)
      (while (re-search-forward ">" end t)
        (xmltok-add-error "`>' that is not markup must be entered as `&gt;'"
                          (1- (point)) (point))))))

(defun nxml-uxml-disallow-newlines (start end)
  "Disallow newline characters between START and END."
  (when (and start end)
    (save-excursion
      (goto-char start)
      (end-of-line)
      (while (<= (point) end)
        (xmltok-add-error "Newlines in attribute values are inadvisable in MicroXML" (point) (1+ (point)))
        (forward-line)
        (end-of-line)))))

(defun nxml-uxml-disallow-in-content (token)
  "Disallow things that aren't allowed in MicroXML content.

Argument TOKEN is returned unchanged (this advice for
`xmltok-forward')."
  (when nxml-uxml-restrictions-p
    (with-demoted-errors "µXML Error: %S"
      (cond ((eq xmltok-type 'start-tag)
             (if xmltok-name-colon
                 (xmltok-add-error "Colons are not allowed in element names in MicroXML"
                                   xmltok-start xmltok-name-end))
             (dolist (attr (append xmltok-attributes xmltok-namespace-attributes))
               (cond ((aref attr 1)
                      (xmltok-add-error "Colons are not allowed in attribute names in MicroXML"
                                        (aref attr 0) (aref attr 2)))
                     ((string= (buffer-substring (aref attr 0) (aref attr 2))
                               "xmlns")
                      (xmltok-add-error "Namespaces are not allowed in MicroXML")))
               (nxml-uxml-disallow-gts (aref attr 3) (aref attr 4))
               (if (not nxml-uxml-allow-newlines-in-attributes)
                   (nxml-uxml-disallow-newlines (aref attr 3) (aref attr 4)))))
            ((eq xmltok-type 'data)
             (nxml-uxml-disallow-gts xmltok-start (point)))
            ((eq xmltok-type 'cdata-section)
             (xmltok-add-error "CDATA sections are not allowed in MicroXML"
                               xmltok-start))
            ((eq xmltok-type 'char-ref)
             (let ((end (point)))
               (save-excursion
                 (goto-char xmltok-start)
                 (cond ((not (looking-at "&#x"))
                        (xmltok-add-error "Only hexadecimal character references are allowed in MicroXML" xmltok-start end))
                       ((looking-at "&#x0*[dD];")
                        (xmltok-add-error "Character reference to `&#xD;' not allowed in MicroXML" xmltok-start end))))))
            ((eq xmltok-type 'entity-ref)
             ;; in practice this should be caught by the fact doctypes are disallowed, but let's be extra careful
             (let ((end (point)))
               (save-excursion
                 (goto-char xmltok-start)
                 (if (not (looking-at "&\\(amp\\|lt\\|gt\\|quot\\|apos\\);"))
                     (xmltok-add-error "Entity reference not allowed in MicroXML" xmltok-start end))))))))
  token)

(provide 'nxml-uxml)

;;; nxml-uxml.el ends here
