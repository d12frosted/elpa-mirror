;;; android-env.el --- Helper functions for working in android

;; Author: Fernando Jascovich
;; Keywords: android, gradle, java, tools, convenience
;; Package-Version: 20200722.1403
;; Package-Commit: 5c6a6d9449f300eec4f374a5410edc1cbab02e40
;; Version: 0.1
;; Url: https://github.com/fernando-jascovich/android-env.el
;; Package-Requires: ((emacs "24.3"))

;; This file is NOT part of GNU Emacs
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

;; Helper functions for working in android, mainly helps with compiling,
;; launching emulators, deeplinks and common day-to-day tasks of an android
;; developer.

;;; Code:
(require 'compile)
(require 'hydra nil 'noerror)

(defgroup android-env nil
  "Configuration options for android-env.el"
  :group 'convenience)

(defcustom android-env-executable "./gradlew"
  "The android-env gradle exec."
  :type 'string
  :group 'android-env)

(defcustom android-env-test-command "testDev"
  "The android-env default gradle action."
  :type 'string
  :group 'android-env)

(defcustom android-env-emulator-command
  "emulator"
  "Android emulator bin location."
  :type 'string
  :group 'android-env)

(defcustom android-env-unit-test-command "testDevDebug"
  "The android-env default unit test action."
  :type 'string
  :group 'android-env)

(defcustom android-env-adb-buffer-name "*android-adb*"
  "Name used for adb async output."
  :type 'string
  :group 'android-env)

(defcustom android-env-hydra nil
  "A t here will allow hydra initialization when invoking android-env.
Requires 'hydra."
  :type 'boolean
  :group 'android-env)

(defvar android-env-refactor-file nil
  "Path to file to be used by android-env-refactor.")

(add-to-list 'compilation-error-regexp-alist-alist
             '(android-java ":compile.*?\\(/.*?\\):\\([0-9]+\\): " 1 2))
(add-to-list 'compilation-error-regexp-alist-alist
             '(android-java-2 "^\\(/.[^:]*\\):\\([0-9]*\\): +error:" 1 2))
(add-to-list 'compilation-error-regexp-alist-alist
             '(android-kotlin "^e: \\(.[^:]*\\): (\\([0-9]*\\), \\([0-9]*\\)" 1 2 3))

(define-compilation-mode android-env-compile-mode "Android Compile"
  "Compilation mode for android compile."
  (setq-local compilation-error-regexp-alist '(android-java
                                               android-java-2
                                               android-kotlin)))

(defun android-env ()
  "Set compilation error regexps."
  (interactive)
  (when android-env-hydra
    (android-env-hydra-setup)))

(defun android-env-crashlytics (module build)
  "Assemble and upload the MODULE and BUILD to crashlytics."
  (interactive "sModule: \nsBuild: ")
  (android-env-gradle (format "%s:assemble%s %s:crashlyticsUploadDistribution%s"
                              module
                              build
                              module
                              build)))

(defun android-env-gradle (gradle-cmd)
  "Execute GRADLE-CMD."
  (let ((path (locate-dominating-file "." "gradlew")))
    (if (not path)
        (message "Couldn't find a gradle project in ancestors directories")
      (compilation-start (format "cd %s; %s %s"
                                 (shell-quote-wildcard-pattern path)
                                 (shell-quote-argument android-env-executable)
                                 gradle-cmd)
                         'android-env-compile-mode))))

(defun android-env-test ()
  "Execute instrumented test."
  (interactive)
  (android-env-gradle android-env-test-command))

(defun android-env-unit-test ()
  "Execute unit test."
  (interactive)
  (android-env-gradle android-env-unit-test-command))

(defun android-env-unit-test-single (build test)
  "Execute a single unit test from BUILD.
Whose fully qualified jvm name is TEST."
  (interactive "sBuild: \nsTest: ")
  (android-env-gradle (concat "test" build (format " --tests %s" test))))

(defun android-env-avd-list ()
  "Return shell command output as list."
  (let (out out-list avdmanager)
    (setq avdmanager (concat
                      (getenv "ANDROID_SDK_ROOT")
                      "/tools/bin/avdmanager"))
    (setq out (shell-command-to-string
               (concat avdmanager " list avd --compact -0")))
    (setq out-list (split-string out "\0"))
    (delete (pop out-list) out-list)
    (delete "" out-list)))

(defun android-env-avd ()
  "Prompts for avd launch based on current avds."
  (interactive)
  (message "Getting avd list..." )
  (let ((selected (completing-read "Select avd: " (android-env-avd-list))))
    (async-shell-command
     (format "%s @%s" android-env-emulator-command
             (shell-quote-argument selected))
     (format "*android-emulator-%s" selected))))

(defun android-env-adb ()
  "Return adb full path based on ANDROID_SDK_ROOT env var."
  (concat (getenv "ANDROID_SDK_ROOT") "/platform-tools/adb"))

(defun android-env-auto-dhu ()
  "Launches android auto desktop head unit."
  (interactive)
  (let ((cmd1 "$ANDROID_SDK_ROOT/platform-tools/adb forward tcp:5277 tcp:5277")
        (cmd2 "$ANDROID_SDK_ROOT/extras/google/auto/desktop-head-unit")
        (bname "*android-auto-dhu*"))
    (async-shell-command (format "%s && %s" cmd1 cmd2) bname)))

(defun android-env-logcat-clear ()
  "Clear android logcat."
  (interactive)
  (shell-command (concat (android-env-adb) " logcat -c")))

(defun android-env-logcat-buffer (&optional logcat-args)
  "Handles buffer related tasks using LOGCAT-ARGS."
  (let ((bname "*Android Logcat*"))
    (with-current-buffer (get-buffer-create bname)
      (switch-to-buffer bname)
      (let ((inhibit-read-only t)
            (p (get-buffer-process (current-buffer))))
        (erase-buffer)
        (when p
          (delete-process p)
          (setq p (get-buffer-process (current-buffer)))))
      (apply 'start-process
             "Android Logcat"
             bname
             (android-env-adb) "logcat" logcat-args)
      (face-remap-add-relative 'default '(:height 105))
      (view-mode))))

(defun android-env-logcat (&optional tag)
  "Show logcat using TAG for filtering."
  (interactive "sTag: ")
  (let ((args '())
        (args-format ""))
    (when (and tag (not (string= "" tag)))
      (add-to-list 'args "*:S")
      (add-to-list 'args tag t))
    (android-env-logcat-buffer args)))

(defun android-env-logcat-crash ()
  "Show logcat's crash buffer."
  (interactive)
  (android-env-logcat-buffer '("-b" "crash")))

(defun android-env-logcat-pid-assoc (str)
  "Convert STR to assoc list with pid as car and process as cdr."
  (split-string str "\d "))

(defun android-env-logcat-pid ()
  "Start logcat but filtering for a specific pid."
  (interactive)
  (let (pid running-pids cmd map prompt)
    (setq cmd (format "%s shell ps -A -o PID,ARGS=CMD" (android-env-adb)))
    (setq running-pids (split-string (shell-command-to-string cmd) "\n" t " *"))
    (setq map (make-hash-table :size (length running-pids) :test 'equal))
    (setq prompt '())
    (mapc (lambda (x)
            (let* ((x-parts (s-split-up-to " " x 2 t))
                   (key (car (cdr x-parts))))
              (add-to-list 'prompt key)
              (puthash key (car x-parts) map)))
          running-pids)
    (setq pid (gethash (completing-read "Select process: " prompt) map))
    (message "pid: %s" pid)
    (android-env-logcat-buffer (list "--pid" pid))))

(defun android-env-uninstall-app (package)
  "Uninstall application by PACKAGE name."
  (interactive "sPackage: ")
  (shell-command
   (format "%s shell pm uninstall '%s'" (android-env-adb) package)
   android-env-adb-buffer-name))

(defun android-env-deeplink (deeplink)
  "Send DEEPLINK to emulator."
  (interactive "sDeep link: ")
  (let ((command (android-env-adb))
        (args (format "am start -a android.intent.action.VIEW -d \"%s\""
                      deeplink)))
    (shell-command (format "%s shell %s"
                           (shell-quote-wildcard-pattern command)
                           (shell-quote-argument args))
                   android-env-adb-buffer-name)))

(defun android-env-refactor-map (file)
  "Return a list with FILE contents.
FILE should be a comma separated file with pairs of intended replacements.
Take for example this androidx migration mapping file:
https://developer.android.com/topic/libraries/support-library/downloads/androidx-class-mapping.csv"
  (let ((map '()))
    (with-temp-buffer
      (insert-file-contents file)
      (while (not (eobp))
        (let* ((line-start (point))
               (line-end (progn (forward-line 1) (- (point) 1)))
               (line (buffer-substring line-start line-end)))
          (push (split-string line ",") map))))
    map))

(defun android-env-refactor-file-ensure ()
  "Promps for filling ANDROID-ENV-REFACTOR-FILE when not configured."
  (when (or (not android-env-refactor-file) current-prefix-arg)
    (setq android-env-refactor-file (read-file-name "Mappings file: "))))

(defun android-env-refactor ()
  "Perform refactor on current buffer based on mappings file contents.
Mappings file path is stored for further usage at ANDROID-ENV-REFACTOR-FILE.
When called with prefix it will prompt again for Mappings file.
It will return the number of replacements performed."
  (interactive)
  (android-env-refactor-file-ensure)
  (let (map from to point-start replacements)
    (setq point-start (point))
    (setq map (android-env-refactor-map android-env-refactor-file))
    (setq replacements 0)
    (dolist (item map)
      (setq from (car item))
      (setq to (car (cdr item)))
      (goto-char (point-min))
      (while (re-search-forward from nil t)
        (replace-match to)
        (setq replacements (+ replacements 1))))
    (goto-char point-start)
    (message "Refactored %d matches" replacements)
    replacements))

(defun android-env-recursive-refactor (match)
  "Call ANDROID-ENV-REFACTOR for every file matching MATCH recursively."
  (interactive "sMatch regexp: ")
  (android-env-refactor-file-ensure)
  (let ((files (directory-files-recursively default-directory match)))
    (message "%d files matched" (length files))
    (dolist (file files)
      (with-current-buffer (find-file-noselect file)
        (message "Working on: %s..." file)
        (if (> (android-env-refactor) 0)
            (save-buffer))
        (kill-buffer)))))

(defun android-env-compile (task)
  "Execute gradle compilation using TASK."
  (interactive "sTask: ")
  (android-env-gradle task))

(defun android-env-hydra-setup ()
  "Hydra setup."
  (when (require 'hydra nil 'noerror)
    (defhydra hydra-android (:color teal :hint nil)
      "
^Compiling^              ^Devices^       ^Code^                   ^Logcat^           ^Adb^
^^^^^----------------------------------------------------------------------------------------------
_w_: Compile             _e_: Avd        _r_: Refactor            _l_: Logcat        _U_: Uninstall
_s_: Instrumented Test   _d_: Auto DHU   _R_: Recursive refactor  _c_: Logcat crash  _L_: Deep link
_u_: Unit Test           ^ ^             ^ ^                      _p_: Logcat by pid
_t_: Single unit test    ^ ^             ^ ^                      _C_: Logcat clear
_x_: Crashlytics
"
      ("w" android-env-compile)
      ("s" android-env-test)
      ("u" android-env-unit-test)
      ("e" android-env-avd)
      ("d" android-env-auto-dhu)
      ("l" android-env-logcat)
      ("c" android-env-logcat-crash)
      ("C" android-env-logcat-clear)
      ("p" android-env-logcat-pid)
      ("t" android-env-unit-test-single)
      ("x" android-env-crashlytics)
      ("U" android-env-uninstall-app)
      ("L" android-env-deeplink)
      ("r" android-env-refactor)
      ("R" android-env-recursive-refactor)
      ("q" nil "quit"))))


(provide 'android-env)
;;; android-env.el ends here
