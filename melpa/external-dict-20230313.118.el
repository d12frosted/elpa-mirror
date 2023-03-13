;;; external-dict.el --- Query external dictionary like goldendict, Bob.app etc

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "25.1"))
;; Package-Commit: 7ef87709c09792dfa6332fb41a6ec1edd917120a
;; Package-Version: 20230313.118
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
    (gnu/linux
     (cond
      ((executable-find "goldendict")
       '(:dict-program "goldendict" :command-p t))))
    (darwin
     (cond
      ((file-exists-p "/Applications/Bob.app")
       '(:dict-program "Bob.app" :command-p nil))
      ((file-exists-p "/Applications/GoldenDict.app")
       '(:dict-program "GoldenDict.app" :command-p t))
      (t '(:dict-program "Dictionary.app" :command-p t)))))
  "Specify external dictionary command."
  :type 'string
  :group 'external-dict)

(defcustom external-dict-read-cmd
  (cl-case system-type
    (gnu/linux
     (cl-case (plist-get external-dict-cmd :dict-program)
       ("goldendict" nil)
       (t
        (cond
         ((executable-find "festival") "festival")
         ((executable-find "espeak") "espeak")))))
    (darwin
     (pcase (plist-get external-dict-cmd :dict-program)
       ("Bob.app" "say")
       ("GoldenDict.app" "say")
       ("Dictionary.app" "say"))))
  "Specify external tool command to read the query word.
If the value is nil, it will let dictionary handle it without invoke the command.
If the value is a command string, it will invoke the command to read the word."
  :type 'string
  :safe #'stringp)

(defun external-dict--get-text ()
  "Get word or text from region selected, thing-at-point, or interactive input."
  (cond
   ((region-active-p)
    (let ((text (buffer-substring-no-properties (mark) (point))))
      (deactivate-mark)
      `(:type :text :text ,text)))
   ((and (thing-at-point 'word)
         (not (string-blank-p (substring-no-properties (thing-at-point 'word)))))
    (let ((word (substring-no-properties (thing-at-point 'word))))
      `(:type :word, :text ,word)))
   (t (let ((word (read-string "[external-dict.el] Query word: ")))
        `(:type :word :text ,word)))))

;;;###autoload
(defun external-dict-read-word (word)
  "Auto pronounce the query word or read the text."
  (interactive)
  (sit-for 1)
  (pcase external-dict-read-cmd
    ("say"
     (shell-command (concat "say " (shell-quote-argument word))))
    ("festival"
     (shell-command (concat "festival --tts " (shell-quote-argument word))))
    ("espeak"
     (shell-command (concat "espeak " (shell-quote-argument word))))))

;;; [ macOS Dictionary.app ]
;;;###autoload
(defun external-dict-Dictionary.app (word)
  "Query TEXT like current symbol/world at point or region selected or input with macOS Dictionary.app."
  (interactive
   (list (cond
          ((region-active-p)
           (buffer-substring-no-properties (mark) (point)))
          ((not (string-blank-p (substring-no-properties (thing-at-point 'word))))
           (substring-no-properties (thing-at-point 'word)))
          (t (read-string "[external-dict.el] Query word in macOS Dictionary.app: ")))))
  (deactivate-mark)
  (shell-command (format "open dict://\"%s\"" word))
  (external-dict-read-word word))

;;; [ Goldendict ]
(defun external-dict-goldendict--ensure-running ()
  "Ensure goldendict program is running."
  (unless (string-match "goldendict" (shell-command-to-string "ps -C 'goldendict' | sed -n '2p'"))
    (start-process-shell-command
     "*goldendict*"
     " *goldendict*"
     "goldendict")))

;;;###autoload
(defun external-dict-goldendict (word)
  "Query current symbol/word at point or region selected with goldendict.
If you invoke command with `RAISE-MAIN-WINDOW' prefix \\<universal-argument>,
it will raise external dictionary main window."
  (interactive (list (plist-get (external-dict--get-text) :text)))
  (external-dict-goldendict--ensure-running)
  (let ((goldendict-cmd (cl-case system-type
                          (gnu/linux (executable-find "goldendict"))
                          (darwin (or (executable-find "GoldenDict") (executable-find "goldendict")))
                          (t (plist-get external-dict-cmd :dict-program)))))
    (if current-prefix-arg
        (save-excursion
          (call-process goldendict-cmd nil nil nil))
      (save-excursion
        ;; pass the selection to shell command goldendict.
        ;; use Goldendict API: "Scan Popup"
        (call-process goldendict-cmd nil nil nil word))
      (external-dict-read-word word)
      (deactivate-mark))))

;;; alias for `external-dict-cmd' property `:dict-program' name under macOS.
(defalias 'external-dict-GoldenDict.app 'external-dict-goldendict)

;;; [ Bob.app ]
;;;###autoload
(defun external-dict-Bob.app-translate (text)
  "Bob.app translate TEXT."
  (let ((path "translate")
        (action "translateText")
        (text text))
    (ns-do-applescript
     (format "use scripting additions
use framework \"Foundation\"
on toJson(recordValue)
(((current application's NSString)'s alloc)'s initWithData:((current application's NSJSONSerialization)'s dataWithJSONObject:recordValue options:1 |error|:(missing value)) encoding:4) as string
end toJson

set theRecord to {|path|: \"%s\", body: {action: \"%s\", |text|: \"%s\", windowLocation: \"center\", inputBoxState: \"alwaysUnfold\"}}
set theParameter to toJson(theRecord)
tell application id \"com.hezongyidev.Bob\" to request theParameter
"
             path action text))))

(defun external-dict-Bob.app-dictionary (word)
  "macOS Bob.app query dictionary for WORD."
  (ns-do-applescript
   (format
    "tell application \"Bob\"
 launch
 translate \"%s\"
 end tell" word))
  (external-dict-read-word word))

(defun external-dict-Bob.app (text)
  "Translate text with Bob.app on macOS."
  (interactive (list (plist-get (external-dict--get-text) :text)))
  (let* ((return-plist (external-dict--get-text))
         (type (plist-get return-plist :type)))
    (cond
     ((eq type :word)
      (external-dict-Bob.app-dictionary text))
     ((eq type :text)
      (external-dict-Bob.app-translate text)))))

;;;###autoload
(defun external-dict-dwim ()
  "Query current symbol/word at point or region selected with external dictionary."
  (interactive)
  (let ((dict-program (plist-get external-dict-cmd :dict-program)))
    (call-interactively (intern (format "external-dict-%s" dict-program)))))



(provide 'external-dict)

;;; external-dict.el ends here
