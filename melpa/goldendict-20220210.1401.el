;;; goldendict.el --- query word smartly with goldendict.el

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "24.4") (cl-lib "0.5"))
;; Package-Commit: f3fbe658a8d31dc1bd0ca69e4d2ebaab59e92791
;; Package-Version: 20220210.1401
;; Package-X-Original-Version: 0.1
;; Keywords: dict goldendict
;; homepage: https://repo.or.cz/goldendict.el.git

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; query word smartly with goldendict.el
;;
;; Usage:
;;
;; (global-set-key (kbd "C-x d") 'goldendict-dwim)
;; If invoke with [C-u] prefix, then it will raise the main window.

;;; Code:


(defgroup goldendict nil
  "Use goldendict in Emacs."
  :prefix "goldendict-"
  :group 'dictionary)

(defcustom goldendict-cmd "goldendict"
  "Specify Goldendict command."
  :type 'string
  :group 'goldendict)

(defun goldendict-ensure ()
  "Ensure goldendict is running."
  (unless (string-match "goldendict" (shell-command-to-string "ps -C 'goldendict' | sed -n '2p'"))
    (start-process-shell-command
     "*goldendict*"
     " *goldendict*"
     "goldendict")))

;;;###autoload
(defun goldendict-dwim (&optional raise-main-window)
  "Query current symbol/word at point or region selected with Goldendict.
If you invoke command with `RAISE-MAIN-WINDOW' prefix \\<universal-argument>, it will raise Goldendict main window."
  (interactive "P")
  (goldendict-ensure)
  (if current-prefix-arg
      (save-excursion
        (call-process goldendict-cmd nil nil nil))
    (let ((word (downcase
                 (substring-no-properties
                  (if (region-active-p)
                      (buffer-substring-no-properties (mark) (point))
                    ;; way: get word with `thing-at-point'
                    (thing-at-point 'word))))))
      (save-excursion
        ;; pass the selection to shell command goldendict.
        ;; use Goldendict API: "Scan Popup"
        (call-process goldendict-cmd nil nil nil word)))
    (deactivate-mark)))



(provide 'goldendict)

;;; goldendict.el ends here
