;;; crystal-playground.el --- Local crystal playground for short code snippets.

;; Copyright (C) 2018  Jason Howell (jasonrobot)

;; Author: Jason Howell
;; URL: https://github.com/jasonrobot/crystal-playground
;; Package-Version: 20180830.501
;; Package-Commit: 532dc7e4239eb4bdd241bc4347d34760344c1ebb
;; Version: 0.1
;; Keywords: tools, crystal
;; Package-Requires: ((emacs "25") (crystal-mode "0.1.2"))

;; This file is NOT part of GNU Emacs.

;;; License:

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

;; This is port of github.com/grafov/rust-playground for Crystal
;; language.  You can spin up a temporary project to play around with
;; some Crystal code.  It uses 'crystal new app', so the playground can
;; have external deps added in the shard.yml, and it has a git repo
;; initialized, so it isn't too hard to copy a playground into a
;; standalone app.

;;; Code:

(require 'compile)
(require 'time-stamp)
(require 'crystal-mode)

(defgroup crystal-playground nil
  "Options for crystal-playground."
  :group 'crystal-mode)

(defcustom crystal-playground-basedir
  (locate-user-emacs-file "crystal-playground")
  "Base directory for the crystal playground."
  :type 'file
  :group 'crystal-playground)

(defcustom crystal-playground-run-command
  "crystal run playground.cr"
  "Command used to run the playground."
  :type 'string
  :group 'crystal-playground)

(defcustom crystal-playground-confirm-deletion
  t
  "Non-nil means you will be asked for confirmation on deletion.

By default confirmation required."
  :type 'boolean
  :group 'crystal-playground)

(defcustom crystal-playground-main-template
  "module Playground
  def self.main
    # TODO: Put your code here

  end
end

puts \"Result: %s\" % Playground.main"
  "When creating a new playground, this will be used as the playground.cr file."
  :type 'string
  :group 'crystal-playground)

;; (defcustom crystal-playground-source-header-comment
;;   "snippet of code @ 2018-06-26 23:46:23

;; === Crystal Playground ===
;; This snippet is in: %s

;; Execute the snippet: C-x p r
;; Delete the snippet completely: C-x p k
;;   "Header comment that goes in the source file with instructions."
;;   :type 'string
;;   :group 'crystal-playground)

(define-minor-mode crystal-playground-mode
  "A place to play with crystal!"
  :init-value nil
  :lighter "Play(Crystal)"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-x p r") 'crystal-playground-exec)
            (define-key map (kbd "C-x p k") 'crystal-playground-rm)
            map))

(defun crystal-playground-get-current-basedir (&optional path)
  "Get the path of the dir containing this playground.

Start from PATH or the path of the current buffer's file.  Returns
the path to the basedir or NIL if this is not a snippet."
  (unless path
    (setq path (buffer-file-name)))
  ;; need this check incase buffer isn't visiting a file
  (when path
    ;; descend recursively
    (unless (string= path "/")
      (let ((base (expand-file-name crystal-playground-basedir))
            (path-parent (file-name-directory (directory-file-name path))))
        (if (string= (file-name-as-directory base)
                     (file-name-as-directory path-parent))
            path
          (crystal-playground-get-current-basedir path-parent)))
      )))

(defmacro crystal-playground-in-playground (&rest forms)
  "Execute FORMS if current buffer is part of a playground.
Otherwise message the user that they aren't in one."
  `(if (not (crystal-playground-get-current-basedir))
       (message "You aren't in a Crystal playground.")
     ,@forms))

(defun crystal-playground-insert-template-head (basedir)
  "Insert a template about the snippet in BASEDIR into the current buffer."
  (let ((starting-point (point)))
    (insert (format
             "Crystal Playground @ %s

=== Crystal Playground ===

This playground is in: %s

Execute the playground: C-c p r
Delete the playground completely: C-x p k
"
             (time-stamp-string "%:y-%02m-%02d %02H:%02M:%02S")
             basedir))
    (comment-region starting-point (point))))

;;TODO make basedir optional, default to a defcustom
(defun crystal-playground-make-new (basedir)
  "Create a new crystal project in BASEDIR using the 'crystal' command."
  ;; use `crystal` command to fill out the snippet
  ;; (shell-command "crystal init app playground"))
  ;;make a name from a datestamp
  (let ((playground-dir (expand-file-name
                         (file-name-as-directory
                          (concat
                           (file-name-as-directory basedir)
                           (time-stamp-string "at-%:y-%02m-%02d-%02H%02M%02S"))))))
    ;; this makes its target dir automatically.
    ;; in fact it wont work if the dir exists
    (call-process "crystal" nil nil nil "init" "app" "playground" playground-dir)
    ;;return the dir
    playground-dir))

(defun crystal-playground-get-main-cr (basedir)
  "Get the path to the main .cr file in the playground at BASEDIR."
  (concat basedir (file-name-as-directory "src") "playground.cr"))

(defun crystal-playground-get-shard-yml (basedir)
  "Get the path to the main .cr file in the playground at BASEDIR."
  (concat basedir "shard.yml"))

;;;###autoload
(defun crystal-playground ()
  "Start a new crystal playground."
  (interactive)
  (let* ((current-playground-dir
          (crystal-playground-make-new crystal-playground-basedir))
         (main-cr (crystal-playground-get-main-cr current-playground-dir))
         (shard-yml (crystal-playground-get-shard-yml current-playground-dir)))
    ;; open the main file
    (find-file main-cr)
    ;; set all the modes we need
    (crystal-playground-mode)
    ;; just making my own rather than modifying what exists
    (erase-buffer)
    ;; insert the template header
    (crystal-playground-insert-template-head current-playground-dir)
    ;; (insert crystal-playground-source-header-comment)
    (insert crystal-playground-main-template)
    ;; put the point in a nice place
    (forward-line -4)
    (end-of-line)))

(defun crystal-playground-exec ()
  "Run the code of the playground."
  (interactive)
  (crystal-playground-in-playground
   (save-buffer t)
   (compile crystal-playground-run-command)))

(defun crystal-playground-get-all-buffers ()
  "Get all buffers visiting a file in the playground."
  (let* ((basedir (crystal-playground-get-current-basedir)))
    (remove 'nil
            (mapcar 'find-buffer-visiting
                    (append
                     (directory-files-recursively basedir ".cr\\'")
                     (directory-files-recursively basedir ".yml\\'"))))))

;;;###autoload
(defun crystal-playground-rm ()
  "Remove files of the current snippet together with directory of this snippet."
  (interactive)
  (crystal-playground-in-playground
   (let ((current-basedir (crystal-playground-get-current-basedir)))
     (if current-basedir
         (when (or (not crystal-playground-confirm-deletion)
                   (y-or-n-p (format "Do you want delete whole dir %s? "
                                     current-basedir)))
           (dolist (buf (crystal-playground-get-all-buffers))
             (kill-buffer buf))
           (delete-directory current-basedir t t))
       (message "Won't delete this! Because %s is not under the path %s. Remove the snippet manually!"
                (buffer-file-name)
                crystal-playground-basedir)))))

(provide 'crystal-playground)
;;; crystal-playground.el ends here
