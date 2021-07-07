;;; moz-controller.el --- Control Firefox from Emacs

;; Copyright (C) 2014 任文山 (Ren Wenshan)

;; Author: 任文山 (Ren Wenshan) <renws1990 at gmail.com>
;; URL: https://github.com/RenWenshan/emacs-moz-controller
;; Package-Version: 20151209.206
;; Package-Commit: 46f665c03574fa922de767fc29795e0db4a7c5c6
;; Version: 0.0.1
;; Package-Requires: ((moz "0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; With this program and Firefox plugin `MozRepl', you can control your Firefox
;; to scroll up, scroll down, zoom in, zoom out, switch tabs, close current
;; tabs and etc.

;;; Installation: see the Installation section in the README.org

;;; Usage: see the Usage section in the README.org

;;; Code:
(require 'moz)

(defgroup moz-controller nil
  "Control Firefox from Emacs"
  :group 'moz-controller)

(defcustom moz-controller-zoom-step 0.1
  "Zoom step, default to 0.1, it is supposed to be a positive number."
  :group 'moz-controller
  :type 'number)

(defvar moz-controller-mode-map nil
  "Keymap for controlling Firefox from Emacs.")

(defvar moz-controller-mode-hook nil
  "Hook to run upon entry into moz-controller-mode.")

(defvar moz-controller-repl-output ""
  "Output from *MozRepl*.")

(defvar moz-controller-repl-output-tag ""
  "Output tag from *MozRepl*.")

(defun moz-controller-repl-filter (proc string)
  "Filter function of *MozRepl*.

It gets the useful output of *MozRepl*, store it in `moz-controller-repl-output` and `kill-ring`"
  (when (buffer-live-p (process-buffer proc))
    (unless (string= string "repl> ")   ; ignore empty output (page up, page down, etc)
      (setq moz-controller-repl-output
            (replace-regexp-in-string "\"\\(.+\\)\"\nrepl> " "\\1" string))
      (setq moz-controller-repl-output-tag
            (replace-regexp-in-string "^\\(#moz-controller-.+#\\) .*" "\\1" moz-controller-repl-output))
      (if (string= moz-controller-repl-output-tag "#moz-controller-get-current-url#")
          (progn
            (setq moz-controller-repl-output (replace-regexp-in-string
                                              (concat moz-controller-repl-output-tag " ")
                                              "" moz-controller-repl-output))
            (message moz-controller-repl-output)
            (kill-new moz-controller-repl-output) ; append to kill-ring
            ))
      )
    (with-current-buffer (process-buffer proc)
      (let ((moving (= (point) (process-mark proc))))
        (save-excursion
          ;; Insert the text, advancing the process marker.
          (goto-char (process-mark proc))
          (insert string)
          (set-marker (process-mark proc) (point)))
        (if moving (goto-char (process-mark proc)))))))

(defmacro defun-moz-controller-command (name arglist doc &rest body)
  "Macro for defining moz commands.

NAME: function name.
ARGLIST: should be an empty list () .
DOC: docstring for the function.
BODY: the desired JavaScript expression, as a string."
  `(defun ,name ,arglist
     ,doc
     (interactive)
     (comint-send-string
      (inferior-moz-process)
      ,@body)
     )
  )

(defun-moz-controller-command moz-controller-page-refresh ()
  "Refresh current page"
  "setTimeout(function(){content.document.location.reload(true);}, '500');"
  )

(defun-moz-controller-command moz-controller-page-down ()
  "Scroll down the current window by one page."
  "content.window.scrollByPages(1);"
  )

(defun-moz-controller-command moz-controller-page-up ()
  "Scroll up the current window by one page."
  "content.window.scrollByPages(-1);"
  )

(defun-moz-controller-command moz-controller-tab-close ()
  "Close current tab"
  "content.window.close();"
  )

(defun-moz-controller-command moz-controller-zoom-in ()
  "Zoom in"
  (concat "gBrowser.selectedBrowser.markupDocumentViewer.fullZoom += "
          (number-to-string moz-controller-zoom-step) ";")
 )

(defun-moz-controller-command moz-controller-zoom-out ()
  "Zoom out"
  (concat "gBrowser.selectedBrowser.markupDocumentViewer.fullZoom -= "
          (number-to-string moz-controller-zoom-step) ";")
  )

(defun-moz-controller-command moz-controller-zoom-reset ()
  "Zoom in"
  "gBrowser.selectedBrowser.markupDocumentViewer.fullZoom = 1"
  )

(defun-moz-controller-command moz-controller-tab-previous ()
  "Switch to the previous tab"
  "getBrowser().mTabContainer.advanceSelectedTab(-1, true);"
  )

(defun-moz-controller-command moz-controller-tab-next ()
  "Switch to the next tab"
  "getBrowser().mTabContainer.advanceSelectedTab(1, true);"
  )

(defun-moz-controller-command moz-controller-view-page-source ()
  "View current page source code."
  "BrowserViewSourceOfDocument(gBrowser.contentDocument);"
  )

(defun-moz-controller-command moz-controller-get-current-url ()
    "Get the current tab's URL and add to kill-ring."
    "'#moz-controller-get-current-url# ' + gBrowser.contentWindow.location.href;"
    )

(unless moz-controller-mode-map
  (setq moz-controller-mode-map
        (let ((moz-controller-map (make-sparse-keymap)))
          (define-key moz-controller-map (kbd "C-c m R") 'moz-controller-page-refresh)
          (define-key moz-controller-map (kbd "C-c m n") 'moz-controller-page-down)
          (define-key moz-controller-map (kbd "C-c m p") 'moz-controller-page-up)
          (define-key moz-controller-map (kbd "C-c m k") 'moz-controller-tab-close)
          (define-key moz-controller-map (kbd "C-c m b") 'moz-controller-tab-previous)
          (define-key moz-controller-map (kbd "C-c m f") 'moz-controller-tab-next)
          (define-key moz-controller-map (kbd "C-c m +") 'moz-controller-zoom-in)
          (define-key moz-controller-map (kbd "C-c m -") 'moz-controller-zoom-out)
          (define-key moz-controller-map (kbd "C-c m 0") 'moz-controller-zoom-reset)
          (define-key moz-controller-map (kbd "C-c m u") 'moz-controller-view-page-source)
          (define-key moz-controller-map (kbd "C-c m l") 'moz-controller-get-current-url)
          moz-controller-map)))

;;;###autoload
(define-minor-mode moz-controller-mode
  "Toggle moz-controller mode.
With no argument, the mode is toggled on/off.
Non-nil argument turns mode on.
Nil argument turns mode off.

Commands:
\\{moz-controller-mode-map}

Entry to this mode calls the value of `moz-controller-mode-hook'."

  :init-value nil
  :lighter " MozCtrl"
  :group 'moz-controller
  :keymap moz-controller-mode-map

  (if (get-buffer-process "*MozRepl*")
      (set-process-filter (get-buffer-process "*MozRepl*") 'moz-controller-repl-filter))
  (if moz-controller-mode
      (run-mode-hooks 'moz-controller-mode-hook)))

;;;###autoload
(define-globalized-minor-mode moz-controller-global-mode
  moz-controller-mode
  moz-controller-on)

(defun moz-controller-on ()
  "Enable moz-controller minor mode."
  (moz-controller-mode t))

(defun moz-controller-off ()
  "Disable moz-controller minor mode."
  (moz-controller-mode nil))

(defun moz-controller-global-on ()
  "Enable moz-controller global minor mode."
  (moz-controller-global-mode t)
  )

(defun moz-controller-global-off ()
  "Disable moz-controller global minor mode."
  (moz-controller-global-mode nil)
  )

(provide 'moz-controller)
;;; moz-controller.el ends here
