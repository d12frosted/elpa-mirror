;;; eldoc-overlay.el --- Display eldoc with contextual documentation overlay.

;; Author: stardiviner <numbchild@gmail.com>
;; Author: Robert Weiner <rsw@gnu.org>
;; Maintainer: stardiviner <numbchild@gmail.com>
;; Keywords: documentation, eldoc, overlay
;; Package-Version: 20220210.1358
;; Package-Commit: b96f5864a47407ec608c807e0d890f62b891ee03
;; URL: https://repo.or.cz/eldoc-overlay.git
;; Created:  14th Jan 2017
;; Modified: 18th Dec 2017
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.3") (inline-docs "1.0.1") (quick-peek "1.0"))

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
  "A timer delay with `sleep-for' for eldoc-overlay display.")

;; Variables
(defcustom eldoc-overlay-backend 'quick-peek
  "The backend library that displays eldoc overlays.
Two backends are supported: `inline-docs' and `quick-peek'."
  :type 'function
  :safe #'functionp)

;; Functions
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

(defun eldoc-overlay-display (format-string &rest args)
  "Display eldoc for the minibuffer when there or call the function indexed by `eldoc-overlay-backend'."
  (unless (or (company-tooltip-visible-p)
              (when (and (featurep 'company-box) (company-box--get-frame))
                (frame-visible-p (company-box--get-frame)))
              (not format-string))
    (if (and (minibufferp) (not eldoc-overlay-enable-in-minibuffer))
        (apply #'eldoc-minibuffer-message format-string args)
      (when (numberp eldoc-overlay-delay)
        (sleep-for eldoc-overlay-delay))
      (funcall (pcase eldoc-overlay-backend
                 (`inline-docs 'eldoc-overlay-inline-docs)
                 (`quick-peek 'eldoc-overlay-quick-peek))
               (apply #'format-message format-string args)))))

(defun eldoc-overlay-enable ()
  (setq-local eldoc-message-function #'eldoc-overlay-display)
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
  (setq-local eldoc-message-function #'eldoc-minibuffer-message))

;;;###autoload
(define-minor-mode eldoc-overlay-mode
  "Minor mode for displaying eldoc contextual documentation using a text overlay."
  :require 'eldoc-overlay-mode
  :group 'eldoc-overlay
  :init-value nil
  :global nil
  :lighter nil
  (if eldoc-overlay-mode
      (eldoc-overlay-enable)
    (eldoc-overlay-disable)))

;;;###autoload
(define-globalized-minor-mode global-eldoc-overlay-mode
  eldoc-overlay-mode eldoc-overlay-mode)

;;; ----------------------------------------------------------------------------

(provide 'eldoc-overlay)

;;; eldoc-overlay.el ends here
