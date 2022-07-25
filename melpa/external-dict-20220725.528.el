;;; external-dict.el --- Query external dictionary like goldendict, Bob.app etc

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "25.1"))
;; Package-Commit: c364895f27c7b5a6421a7bf159851390bfc95642
;; Package-Version: 20220725.528
;; Package-X-Original-Version: 0.1
;; Keywords: wp processes
;; homepage: https://repo.or.cz/external-dict.el.git
;; SPDX-License-Identifier: GPL-2.0-or-later

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Usage:
;;
;; (global-set-key (kbd "C-x d") 'external-dict-dwim)
;; If invoke with [C-u] prefix, then it will raise the main window.

;;; Code:

(declare-function ns-do-applescript "nsfns.m" t)

(defgroup external-dict nil
  "Use external dictionary in Emacs."
  :prefix "external-dict-"
  :group 'dictionary)

(defcustom external-dict-cmd
  (cl-case system-type
    ('gnu/linux
     (cond
      ((executable-find "goldendict")
       '(:dict-program "goldendict" :command-p t))))
    ('darwin
     (cond
      ((file-exists-p "/Applications/Bob.app")
       '(:dict-program "Bob" :command-p nil))
      ((executable-find "goldendict")
       '(:dict-program "goldendict" :command-p t)))))
  "Specify external dictionary command."
  :type 'string
  :group 'external-dict)

(defun external-dict-goldendict--ensure ()
  "Ensure goldendict program is running."
  (unless (string-match "goldendict" (shell-command-to-string "ps -C 'goldendict' | sed -n '2p'"))
    (start-process-shell-command
     "*goldendict*"
     " *goldendict*"
     "goldendict")))

;;;###autoload
(defun external-dict-goldendict (&optional raise-main-window)
  "Query current symbol/word at point or region selected with goldendict.
If you invoke command with `RAISE-MAIN-WINDOW' prefix \\<universal-argument>,
it will raise external dictionary main window."
  (interactive "P")
  (external-dict-goldendict--ensure)
  (let ((goldendict-cmd (cl-case system-type
                          ('gnu/linux (executable-find "goldendict"))
                          ('darwin (or (executable-find "GoldenDict") (executable-find "goldendict")))
                          (t (plist-get external-dict-cmd :dict-program)))))
    (if current-prefix-arg
        (save-excursion
          (call-process goldendict-cmd nil nil nil))
      (let ((word (downcase
                   (substring-no-properties
                    (if (region-active-p)
                        (buffer-substring-no-properties (mark) (point))
                      (thing-at-point 'word))))))
        (save-excursion
          ;; pass the selection to shell command goldendict.
          ;; use Goldendict API: "Scan Popup"
          (call-process goldendict-cmd nil nil nil word)))
      (deactivate-mark))))

;;;###autoload
(defun external-dict-Bob ()
  "Query current symbol/word at point or region selected with Bob.app under macOS."
  (interactive)
  (let ((text (if (region-active-p)
                  (buffer-substring-no-properties (mark) (point))
                (thing-at-point 'symbol))))
    (ns-do-applescript
     (format
      "tell application \"Bob\"
 launch
 translate \"%s\"
 end tell" text))))

;;;###autoload
(defun external-dict-dwim ()
  "Query current symbol/word at point or region selected with external dictionary."
  (interactive)
  (let ((dict-program (plist-get external-dict-cmd :dict-program)))
    (funcall-interactively (intern (format "external-dict-%s" dict-program)))))



(provide 'external-dict)

;;; external-dict.el ends here
