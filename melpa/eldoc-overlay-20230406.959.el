;;; eldoc-overlay.el --- Display eldoc with contextual documentation overlay

;; Author: stardiviner <numbchild@gmail.com>
;; Author: Robert Weiner <rsw@gnu.org>
;; Maintainer: stardiviner <numbchild@gmail.com>
;; Keywords: docs, eldoc, overlay
;; Package-Version: 20230406.959
;; Package-Commit: 14a9e141918c2e18a107920e8631e622c580b3ef
;; URL: https://repo.or.cz/eldoc-overlay.git
;; Created:  14th Jan 2017
;; Modified: 18th Dec 2017
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.4") (inline-docs "1.0.1") (quick-peek "1.0"))

;;; Commentary:
;;
;; Eldoc displays the function signature of the closest function call
;; around point either in the minibuffer or in the modeline.
;;
;; This package modifies Eldoc to display this documentation inline
;; using a buffer text overlay.
;;
;;  `eldoc-overlay-mode' is a per-buffer local minor mode.
;;
;; By default, the overlay is not used in the minibuffer, eldoc is shown in the modeline
;; in this case.  Set the option `eldoc-overlay-enable-in-minibuffer' non-nil if you want
;; to enable overlay use in the minibuffer.
;;
;; Finally, see the documentation for `eldoc-overlay-backend' if you want to try
;; a different overlay display package backend.

;;; Code:
;;; ----------------------------------------------------------------------------

(require 'eldoc)
(declare-function 'inline-docs "inline-docs" format-string &rest args)
(declare-function 'inline-docs--clear-overlay "inline-docs")
(declare-function 'quick-peek-show "quick-peek" str &optional pos min-h max-h)
(declare-function 'quick-peek-hide "quick-peek" &optional pos)
(declare-function 'company-box--get-frame "company-box")
(declare-function 'company-tooltip-visible-p "company")

;; User Options
(defgroup eldoc-overlay nil
  "Display Eldoc function signatures using in-buffer text overlays"
  :prefix "eldoc-overlay-"
  :group 'eldoc)

(defcustom eldoc-overlay-enable-in-minibuffer nil
  "Non-nil (default: nil) means enable `eldoc-overlay-mode' in the minibuffer.
When nil and in the minibuffer, if standard `eldoc-mode' is
enabled, it displays function signatures in the modeline."
  :type 'boolean
  :group 'eldoc-overlay)

(defvar eldoc-overlay-delay nil
  "A seconds timer delay with `sleep-for' for eldoc-overlay display.")

;; Variables
(defcustom eldoc-overlay-backend 'quick-peek
  "The backend library that displays eldoc overlays.
Two backends are supported: `inline-docs' and `quick-peek'."
  :type 'function
  :safe #'functionp)

;; Functions
;;; FIXME: the current line font-lock color is messed up by `eldoc-overlay'.
(defun eldoc-overlay-inline-docs (format-string &rest args)
  "Inline-docs backend function to show FORMAT-STRING and ARGS."
  (inline-docs format-string args))

(defun eldoc-overlay-quick-peek (format-string &rest args)
  "Quick-peek backend function to show FORMAT-STRING and ARGS."
  (when format-string
    (quick-peek-show
     (apply 'format format-string args)
     (point)
     1)))

;;; `eldoc-minibuffer-message', `eldoc--message'
(defun eldoc-overlay-message (format-string &rest args)
  "Display eldoc in overlay using backend function from `eldoc-overlay-backend'.
This function used as value of `eldoc-message-function'."
  (unless (or (company-tooltip-visible-p)
              (when (and (featurep 'company-box) (fboundp company-box--get-frame))
                (frame-visible-p (company-box--get-frame)))
              (not format-string))
    (if (and (minibufferp) (not eldoc-overlay-enable-in-minibuffer))
        (apply #'eldoc-minibuffer-message format-string args)
      (when (and (bound-and-true-p eldoc-overlay-delay)
                 (numberp eldoc-overlay-delay))
        (run-with-timer eldoc-overlay-delay nil #'eldoc-overlay-message-backend)
        (eldoc-overlay-message-backend format-string args)
        ;; (apply 'eldoc-overlay-quick-peek (list (funcall eldoc-documentation-function)))
        ))))

(defun eldoc-overlay-message-backend (format-string &rest args)
  (funcall (pcase eldoc-overlay-backend
             ('inline-docs 'eldoc-overlay-inline-docs)
             ('quick-peek 'eldoc-overlay-quick-peek))
           (apply #'format format-string args)))

;; Reference `eldoc-display-in-buffer', `eldoc-display-in-echo-area'
(defun eldoc-overlay-display (docs _interactive) ; the `docs' is a docstring in style of cons ((#(text-property)) . nil).
  (when docs
    (let* ((docs-text-property (caar docs))
           (docs-plain (substring-no-properties docs-text-property)))
      (funcall (pcase eldoc-overlay-backend
                 ('inline-docs 'eldoc-overlay-inline-docs)
                 ('quick-peek 'eldoc-overlay-quick-peek))
               docs-plain))))

(defun eldoc-overlay-enable ()
  ;; adopt for new eldoc mechanism.
  ;; (when (and (boundp 'eldoc-documentation-strategy)
  ;;            (fboundp 'eldoc-documentation-compose))
  ;;   (setq eldoc-documentation-strategy #'eldoc-documentation-compose))
  (if (boundp 'eldoc-documentation-functions)
      (add-to-list 'eldoc-display-functions #'eldoc-overlay-display)
    ;; roll back to old mechanism.
    (setq eldoc-message-function #'eldoc-overlay-message))
  (when (eq eldoc-overlay-backend 'quick-peek)
    (add-hook 'post-command-hook #'quick-peek-hide)))

(defun eldoc-overlay-disable ()
  (pcase eldoc-overlay-backend
    ('quick-peek
     (quick-peek-hide)
     ;; Remove hook when no buffers have any peek overlays
     (unless (delq nil (mapcar (lambda (buf) (buffer-local-value 'quick-peek--overlays buf)) (buffer-list)))
       (remove-hook 'post-command-hook #'quick-peek-hide)))
    ('inline-docs
     (inline-docs--clear-overlay)))
  (when (boundp 'eldoc-documentation-functions)
    (setq eldoc-display-functions
          (delq #'eldoc-overlay-display eldoc-display-functions)))
  (setq eldoc-message-function #'eldoc-minibuffer-message))

;;;###autoload
(define-minor-mode eldoc-overlay-mode
  "Minor mode for displaying eldoc contextual documentation using a text overlay."
  :require 'eldoc-overlay-mode
  :group 'eldoc-overlay
  :init-value nil
  :global t
  :lighter nil
  (if eldoc-overlay-mode
      (eldoc-overlay-enable)
    (eldoc-overlay-disable)))

;;; ----------------------------------------------------------------------------

(provide 'eldoc-overlay)

;;; eldoc-overlay.el ends here
