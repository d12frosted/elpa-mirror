;;; niceify-info.el --- improve usability of Info pages
;; Package-Commit: 38df5062bc3b99d1074cab3e788b5ed66732111c

;; Package-Version: 20160416.1244
;; Package-X-Original-Version: 20160415.001
;; Copyright 2016 Aaron Miller <me@aaron-miller.me>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; Emacs' Info manuals are extremely rich in content, but the user
;; experience isn't all that it could be; an Emacs process contains a
;; lot of information about the same things that Info manuals
;; describe, but vanilla Info mode doesn't really do much to take
;; advantage of that.  Niceify-info remedies this.

;; To improve a single Info page, do M-x niceify-info in that page's
;; buffer.  If you decide you like the effect so much that you want it
;; applied to all Info pages you visit, add the `niceify-info'
;; function to `Info-selection-hook' in your init file.  For example:

;;     (add-hook 'Info-selection-hook #'niceify-info)

;; This function applies a set of changes I call "niceification",
;; because I have a longstanding fondness for terrible names.  This
;; process does the following things:

;; - Applies customizable faces to text surrounded by emphasis
;;   characters * and _.  The default faces for these are bold and
;;   italic, respectively, because that's what the GNU-hosted HTML
;;   versions of the Emacs manuals use, but they can be customized to
;;   suit your taste.

;; - Identifies Emacs Lisp code samples and fontifies them
;;   accordingly.

;; - Identifies references in `ticks', and where they refer to
;;   function or variable bindings, applies the necessary text
;;   properties to link them to the relevant documentation.  References
;;   without a corresponding function or variable binding will be
;;   fontified as Emacs Lisp, by the same method used for code
;;   samples.

;; - Identifies headers for longer-form documentation of several types
;;   of objects, such as: "-- Function: find-file filename &optional
;;   wildcards" and applies text properties making them easier to
;;   identify and parse.  Names for documented things are linked to
;;   their documentation in the same way as for references in
;;   `ticks'.  Functions' argument lists are additionally fontified
;;   with a customizable face, which defaults to italic.

;; Each kind of niceification has a corresponding customization option
;; to enable or disable it.  You can easily access these via M-x
;; customize-group RET niceify-info RET, or as a subgroup of the Info
;; customization group.  The faces used for emphases, and for function
;; argument lists in headers, can also be customized.

;;; Bugs:

;; Little of this is done with perfect accuracy.  Here are the known
;; issues:

;; - Autoloaded libraries not currently loaded will not have
;;   references in `ticks' linked or fontified.  (But if you load such
;;   a library, and then revisit an Info page containing such
;;   references, they will be correctly niceified.)

;; - Code sample identification and fontification is questionable.  Due
;;   to the lack of structural information in Texinfo files, the only
;;   reliable method I've found of identifying a code sample is by
;;   looking for places where indentation is deeper than the usual for
;;   paragraphs on this page, and checking to see whether the first
;;   following non-whitespace character is '(' or ';'.  This will fail
;;   on Emacs Lisp forms which do not start with those characters, and
;;   will have unpredictable and probably ugly results on code samples
;;   not actually in Emacs Lisp which happen to start with one of
;;   those characters.

;;   The former issue I've found to be negligible, since it only
;;   appears to affect printable forms of non-printable objects
;;   (e.g. buffers, hash tables) which wouldn't be affected by
;;   fontification anyway.

;;   The latter issue I actually have yet to run across; in the
;;   non-Emacs-related Texinfo manuals I have on the systems where I
;;   wrote and tested this code, an admittedly brief and unsystematic
;;   search has failed to turn up any code samples or other quotes
;;   which erroneously trigger fontification.  If you find one, let me
;;   hear about it! (See below for details on how.)

;; - For symbols with both a function and a variable binding, the
;;   function binding is always preferred.  This seems to be a fairly
;;   rare case, and handling it (by prompting for which binding's
;;   documentation to display) is surprisingly complex, so I plan to
;;   leave it for a later version of the library.  If you're anxious to
;;   have it before I get around to implementing it, feel free to open
;;   a pull request!

;; - Not all kinds of headers in Info pages are niceified, because for
;;   a lot of them I couldn't figure out how to do anything useful.

;;; Contributing:

;; I welcome bug reports, feature requests, and proposed
;; modifications. You can submit all of these via Github's issue and
;; pull request trackers at
;; https://github.com/aaron-em/niceify-info.el, and that is the method
;; I prefer. Should you prefer not to use Github, or if the concern
;; you wish to raise doesn't fit well into one of those categories,
;; you can also contact me by email at me@aaron-miller.me.

;;; Code:

(defgroup niceify-info nil
  "Customize Info page fontification and hyperlinking."
  :prefix 'niceify-info
  :group 'info)

(defcustom niceify-info t
  "Whether to apply any niceification to Info buffers."
  :type 'boolean
  :group 'niceify-info)

(defcustom niceify-info-with-emphasis t
  "Whether to niceify *bold* and _italic_ emphases."
  :type 'boolean
  :group 'niceify-info)

(defcustom niceify-info-with-headers t
  "Whether to niceify function, variable, and command headers."
  :type 'boolean
  :group 'niceify-info)

(defcustom niceify-info-with-refs t
  "Whether to niceify references in `ticks'."
  :type 'boolean
  :group 'niceify-info)

(defcustom niceify-info-with-code-samples t
  "Whether to niceify Emacs Lisp code samples."
  :type 'boolean
  :group 'niceify-info)

(defcustom niceify-info-bold-emphasis-face 'bold
  "The face used for *asterisk* emphasis."
  :type 'face
  :group 'niceify-info)

(defcustom niceify-info-italic-emphasis-face 'italic
  "The face used for _underscore_ emphasis."
  :type 'face
  :group 'niceify-info)

(defcustom niceify-info-argument-list-face 'italic
  "The face used for function argument lists."
  :type 'face
  :group 'niceify-info)

;;;###autoload
(defun niceify-info nil
  "Apply niceification functions to Info buffers.

This function is intended to be called from
`Info-selection-hook', q.v., but can be safely evaluated by hand
in an Info buffer as well."
  (interactive)
  (unless (eq (keymap-parent niceify-info-map) Info-mode-map)
    (set-keymap-parent niceify-info-map Info-mode-map))
  (if niceify-info
      (unwind-protect
           (let ((inhibit-read-only t))
             (and niceify-info-with-emphasis
                  (niceify-info-emphasis))
             (and niceify-info-with-headers
                  (niceify-info-headers))
             (and niceify-info-with-refs
                  (niceify-info-refs))
             (and niceify-info-with-code-samples
                  (niceify-info-code-samples)))
        (set-buffer-modified-p nil))))

(defvar niceify-info-map (make-sparse-keymap)
  "Keymap applied to links created during niceification.")
(define-key niceify-info-map [mouse-2]
  'niceify-info-follow-link)
(define-key niceify-info-map (kbd "RET")
  'niceify-info-follow-link)
(define-key niceify-info-map [follow-link]
  'mouse-face)

(defun niceify-info-follow-link nil
  "Follow a link produced by Info niceification."
  (interactive)
  (let ((niceify-link-props (get-text-property (point) 'niceify-link-props))
        type name fun)
    (cond
      ((null niceify-link-props)
       (message "Not on a niceified info link"))
      (t
       (setq type (plist-get niceify-link-props :type)
             name (plist-get niceify-link-props :name)
             fun (intern (concat "describe-" (symbol-name type))))
       (let ((help-window-select t))
         (funcall fun name))))))

(defun niceify-info-fontify-as-elisp (from to)
  "Fontify the region between FROM and TO as Emacs Lisp source."
  (let ((content (buffer-substring-no-properties from to))
        fontified)
  (with-temp-buffer
    (insert content)
    (emacs-lisp-mode)
    (font-lock-fontify-buffer)
    (setq fontified (buffer-substring (point-min) (point-max))))
  (goto-char from)
  (delete-region from to)
  (insert fontified)))

(defun niceify-info-add-link (from to type name)
  "Niceify a reference.

Specifically, apply a set of text properties, over the range of
buffer positions between FROM and TO, which together constitute a
niceification link to the documentation for the TYPE binding of
symbol NAME."
  (set-text-properties from to
                       (list 'face 'link
                             'link 't
                             'keymap niceify-info-map
                             'mouse-face 'highlight
                             'niceify-link-props (list :type type
                                                       :name name)
                             'help-echo (concat "mouse-1: visit documentation for this "
                                                (symbol-name type)))))

(defun niceify-info-code-samples nil
  "Find and fontify Emacs Lisp code samples."
  (let ((paragraph-indent-depth 0)
        possible-sample-regex
        sample-start-regex
        sample-start sample-end sample-content sample-fontified)
    (save-excursion
      (save-match-data
        (beginning-of-buffer)
        (while (not (looking-at " +"))
          (next-line)
          (beginning-of-line))
        (while (looking-at " ")
          (setq paragraph-indent-depth
                (1+ paragraph-indent-depth))
          (forward-char 1))
        (setq possible-sample-regex
              (concat "^ \\{"
                      (number-to-string (1+ paragraph-indent-depth))
                      ",\\}")
              sample-start-regex (concat possible-sample-regex "[(;]"))
        (beginning-of-buffer)
        (while (not (eobp))
          (next-line)
          (beginning-of-line)
          (cond
            ((and (null sample-start)
                  (looking-at sample-start-regex))
             (setq sample-start (point)))
            ((and (not (null sample-start))
                  (not (looking-at possible-sample-regex)))
             (setq sample-end (point)
                   sample-content
                   (buffer-substring-no-properties sample-start sample-end))
             (niceify-info-fontify-as-elisp sample-start sample-end)
             (goto-char sample-end)
             (setq sample-start nil
                   sample-end nil))))))))

(defun niceify-info-emphasis nil
  "Fontify *asterisk* and _underscore_ emphases."
  (let ((face-map '(("_" . niceify-info-italic-emphasis-face)
                    ("*" . niceify-info-bold-emphasis-face)))
        emphasis-char)
    (save-match-data
      (save-excursion
        (beginning-of-buffer)
        (while (re-search-forward "[
 ]\\([\\_*]\\)\\([^
 ].*?[^
 ]\\)\\1\\(?:[
 ]\\|$\\)" nil t)
          (setq emphasis-char (match-string 1))
          (add-text-properties (match-beginning 2)
                               (match-end 2)
                               `(face ,(cdr (assoc emphasis-char face-map)))))))))

(defun niceify-info-refs nil
  "Link `tick' references to corresponding documentation."
  (save-match-data
    (save-excursion
      (beginning-of-buffer)
      (while (re-search-forward "`\\(.*?\\)'" nil t)
        (backward-char 1)
        (let* ((name (intern (match-string 1)))
               (to (point))
               (from (- to (length (symbol-name name))))
               (type (cond
                       ((fboundp name) 'function)
                       ((and (boundp name)
                             (not (keywordp name))) 'variable)
                       (t 'unknown))))
          (if (and (not (eq type 'unknown))
                   (not (eq name 'nil))
                   (not (eq name 't)))
              (niceify-info-add-link from to type name)
              (niceify-info-fontify-as-elisp from to)))))))

(defun niceify-info-headers nil
  "Fontify object documentation headers."
  (let* ((args-face niceify-info-argument-list-face)
         (indent-spaces 5) ;; NB this may not be immutable, though seems so
         (further-indent-regex
          (concat " \\{" (number-to-string (* indent-spaces 2)) ",\\}"))
         type
         name
         (type-map '(("command" . function)
                     ("user option" . variable)
                     ("function" . function)
                     ("variable" . variable)
                     ("constant" . constant)
                     ("const" . constant)
                     ("face" . variable)
                     ("hook" . variable)
                     ("macro" . function)
                     ("method" . function)
                     ("option" . variable)))
         (face-map '((function . font-lock-function-name-face)
                     (variable . font-lock-variable-name-face)
                     (constant . font-lock-constant-face))))
    (let (from to line-start)
      (setq inhibit-read-only t)
      (save-match-data
        (save-excursion
          (beginning-of-buffer)
          (while (re-search-forward "^ -- " nil t)
            (save-excursion
              (beginning-of-line)
              (setq line-start (point)))

            (setq from (point))
            (re-search-forward ":" nil t)
            (backward-char 1)
            (setq to (point)
                  type
                  (cdr (assoc
                        (downcase (buffer-substring-no-properties from to))
                        type-map)))
            (add-face-text-property from to
                                    (cdr (assoc type face-map)))

            (re-search-forward " " nil t)
            (setq from (point))
            (while (not (or (looking-at " ")
                            (eolp)))
              (forward-char 1))
            (setq to (point))
            (niceify-info-add-link from to
                                   type
                                   (intern (buffer-substring-no-properties from to)))

            (setq from (point))
            (end-of-line)

            (while (save-excursion
                     (forward-char 1)
                     (looking-at further-indent-regex))
              (forward-char 1)
              (end-of-line))
            
            (niceify-info-fontify-as-elisp from (point))
            (add-face-text-property from (point) args-face)))))))

(provide 'niceify-info)

;;; niceify-info.el ends here
