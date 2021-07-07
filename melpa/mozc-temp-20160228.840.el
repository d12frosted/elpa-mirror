;;; mozc-temp.el --- Use mozc temporarily            -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Hiroki YAMAKAWA

;; Author: Hiroki YAMAKAWA <s06139@gmail.com>
;; URL: https://github.com/HKey/mozc-temp
;; Package-Version: 20160228.840
;; Package-Commit: 90a6eb1db8fa1283b944432cfb83739286b37f92
;; Version: 1.0.0
;; Package-Requires: ((emacs "24") (dash "2.10.0") (mozc "0"))
;; Keywords:

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

;; mozc-temp is a wrapper of mozc for modeless input of Japanese.
;; This is inspired by ac-mozc.

;; Please see https://github.com/HKey/mozc-temp/blob/master/README.md
;; (written in Japanese) for more details.

;;; Code:

(require 'mozc)
(require 'dash)


(defgroup mozc-temp nil
  "Temporary `mozc-mode'."
  :group 'mozc
  :prefix "mozc-temp-")

(defcustom mozc-temp-prefix-regexp
  (let ((convertibles "!-~"))
    (format "\\(?:^\\|[^%s]\\)\\([%s]+\\)\\=" convertibles convertibles))
  "A regexp to specify the prefix string for conversion.
The prefix string is used as pre-input of mozc's conversion.

The default value means (\"|\" means the cursor position):
  hogehoge hugahuga|
           ^^^^^^^^
       a prefix string"
  :type 'regexp
  :group 'mozc-temp
  :package-version '(mozc-temp . "0.1.0"))

(defcustom mozc-temp-auto-conversion t
  "Non-nil means that mozc-temp starts conversion when mozc-temp enabled.
This behavior is like that you press the space key to convert preedit characters."
  :type 'boolean
  :group 'mozc-temp
  :package-version '(mozc-temp . "0.1.0"))

(defcustom mozc-temp-remove-pre-space t
  "Non-nil means that mozc-temp removes a pre-space when converting.
A pre-space is a space before a prefix string.

     a pre-space
          |
          v
  hogehoge hugahuga|
           ^^^^^^^^
       a prefix string"
  :type 'boolean
  :group 'mozc-temp
  :package-version '(mozc-temp . "0.1.0"))

(defcustom mozc-temp-pre-space-regexp "[^[:space:]] ?\\( \\)\\="
  "A regexp to detect a pre-space.
The first group in this regexp indicates a pre-space.
See also `mozc-temp-remove-pre-space'."
  :type 'regexp
  :group 'mozc-temp
  :package-version '(mozc-temp . "0.1.0"))

(defvar mozc-temp--minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap mozc-handle-event] #'mozc-temp--handle-event)
    map)
  "A key map for `mozc-temp--minor-mode'.")

(defvar mozc-temp--should-exit nil
  "Non-nil means that `mozc-temp--minor-mode' should exit.")

(defvar mozc-temp--pre-space-overlay nil
  "An overlay which indicates a pre-space.")

(defvar mozc-temp--prefix-overlay nil
  "An overlay which indicates a prefix string.")

(defvar mozc-temp--quietly nil
  "Non-nil means that mozc should not show messages.")


(defun mozc-temp--delete-overlay-region (overlay)
  "Delete the text in the region of OVERLAY."
  (when (overlayp overlay)
    (delete-region (overlay-start overlay)
                   (overlay-end overlay))))

(defun mozc-temp--complete ()
  "Complete the current mozc-temp session."
  (mozc-temp--delete-overlay-region mozc-temp--prefix-overlay)
  (when mozc-temp-remove-pre-space
    (undo-boundary)
    (mozc-temp--delete-overlay-region mozc-temp--pre-space-overlay))
  (mozc-temp--minor-mode -1))

(defun mozc-temp--handle-event (event)
  "A wrapper function for `mozc-handle-event'.
EVENT is an argument for `mozc-handle-event'."
  (interactive (list last-command-event))
  (let ((mozc-temp--should-exit nil))
    (prog1 (mozc-handle-event event)
      (when mozc-temp--should-exit
        (mozc-temp--complete)))))

(defun mozc-temp--cleanup ()
  "Cleanup mozc-temp session."
  (--each (list mozc-temp--pre-space-overlay mozc-temp--prefix-overlay)
    (when (overlayp it)
      (delete-overlay it)))
  (setq mozc-temp--pre-space-overlay nil
        mozc-temp--prefix-overlay nil))

(define-minor-mode mozc-temp--minor-mode
  "Temporary mozc mode"
  :keymap mozc-temp--minor-mode-map
  :group 'mozc-temp
  (if mozc-temp--minor-mode
      (mozc-mode 1)
    (mozc-mode -1)
    (mozc-temp--cleanup)))


(defun mozc-temp--preedit-deleted (mozc-send-key-event-result)
  "Return non-nil if MOZC-SEND-KEY-EVENT-RESULT means that preedit characters have been deleted."
  (null (mozc-protobuf-get mozc-send-key-event-result 'preedit)))

(defun mozc-temp--conversion-completed (mozc-send-key-event-result)
  "Return non-nil if MOZC-SEND-KEY-EVENT-RESULT means that the conversion has been completed."
  (mozc-protobuf-get mozc-send-key-event-result 'result))

(defadvice mozc-send-key-event (after mozc-temp activate)
  "Detect that a mozc-temp session should exit."
  (setq mozc-temp--should-exit
        (or (mozc-temp--conversion-completed ad-return-value)
            (mozc-temp--preedit-deleted ad-return-value))))

(defadvice mozc-fall-back-on-default-binding (after mozc-temp activate)
  "Detect that a mozc-temp session should exit."
  (setq mozc-temp--should-exit t))

(defun mozc-temp--prefix-string ()
  "Get a prefix string just before the current position of the cursor.
If there is no prefix string, this returns nil."
  (save-excursion
    (save-match-data
      (and (re-search-backward mozc-temp-prefix-regexp (point-at-bol) t)
           (match-string 1)))))

(defun mozc-temp--pre-space-position (point)
  "Get a pre-space position just before POINT.
This returns a list like (BEGINNING END).
If there is no pre-space, this returns nil."
  (save-excursion
    (save-match-data
      (goto-char point)
      (when (re-search-backward mozc-temp-pre-space-regexp (point-at-bol) t)
        (list (match-beginning 1) (match-end 1))))))

(defun mozc-temp--send-string (string)
  "Send STRING to mozc session."
  (let ((chars (string-to-list string)))
    (let ((mozc-temp--quietly t))
      (-each (butlast chars) #'mozc-temp--handle-event))
    (mozc-temp--handle-event (-last-item chars))))

(defadvice mozc-cand-echo-area-update (around mozc-temp activate)
  "Make mozc quiet while sending characters to mozc."
  (unless mozc-temp--quietly
    ad-do-it))

(defadvice mozc-cand-overlay-update (around mozc-temp activate)
  "Make mozc quiet while sending characters to mozc."
  (unless mozc-temp--quietly
    ad-do-it))

;;;###autoload
(defun mozc-temp-convert ()
  "Convert the current word with mozc."
  (interactive)
  (unless mozc-temp--minor-mode
    (-when-let* ((tail (point))
                 (prefix (mozc-temp--prefix-string))
                 (head (save-match-data
                         (save-excursion
                           (re-search-backward (regexp-quote prefix) nil t)))))
      (undo-boundary)
      (setq mozc-temp--prefix-overlay (make-overlay head tail))
      (overlay-put mozc-temp--prefix-overlay 'invisible t)
      (save-match-data
        (save-excursion
          (-when-let ((pre-space-beginning pre-space-end)
                      (mozc-temp--pre-space-position head))
            (when mozc-temp-remove-pre-space
              (setq mozc-temp--pre-space-overlay
                    (make-overlay pre-space-beginning pre-space-end))
              (overlay-put mozc-temp--pre-space-overlay 'invisible t)))))
      (mozc-temp--minor-mode 1)
      (mozc-temp--send-string
       (concat prefix
               (if mozc-temp-auto-conversion " " ""))))))

;;;###autoload
(defun mozc-temp-convert-dwim ()
  "Convert the current word or start a mozc-temp session.
If there is a prefix string, this function calls `mozc-temp-convert'.
If not, this function starts a mozc-temp session."
  (interactive)
  (unless mozc-temp--minor-mode
    (if (mozc-temp--prefix-string)
        (mozc-temp-convert)
      (mozc-temp--minor-mode 1))))

(provide 'mozc-temp)
;;; mozc-temp.el ends here

;; Local Variables:
;; eval: (when (fboundp (quote flycheck-mode)) (flycheck-mode 1))
;; eval: (when (fboundp (quote flycheck-package-setup)) (flycheck-package-setup))
;; End:
