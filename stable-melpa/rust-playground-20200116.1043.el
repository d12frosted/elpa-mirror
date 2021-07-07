;;; rust-playground.el --- Local Rust playground for short code snippets.

;; Copyright (C) 2016-2017  Alexander I.Grafov (axel)

;; Author: Alexander I.Grafov <grafov@gmail.com> + all the contributors (see git log)
;; URL: https://github.com/grafov/rust-playground
;; Package-Version: 20200116.1043
;; Package-Commit: 5a117781dcb66065bea7830dd73618008fc34949
;; Version: 0.2.1
;; Keywords: tools, rust
;; Package-Requires: ((emacs "24.3"))

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

;; Local playground for the Rust programs similar to play.rust-lang.org.
;; `M-x rust-playground` and type you rust code then make&run it with `C-c C-c`.
;; Toggle between Cargo.toml and main.rs with `C-c b`
;; Delete the current playground and close all buffers with `C-c k`

;; Playground requires preconfigured environment for Rust language.

;; It is port of github.com/grafov/go-playground for Go language.

;;; Code:

(require 'compile)
(require 'time-stamp)

(defgroup rust-playground nil
  "Options specific to Rust Playground.")

;; I think it should be defined in rust-mode.
(defcustom rust-playground-run-command "cargo run"
  "The ’rust’ command."
  :type 'string
  :group 'rust-playground)

(defcustom rust-playground-confirm-deletion t
  "Non-nil means you will be asked for confirmation on the snippet deletion with `rust-playground-rm'.

By default confirmation required."
  :type 'boolean
  :group 'rust-playground)

(defcustom rust-playground-basedir (locate-user-emacs-file "rust-playground")
  "Base directory for playground snippets."
  :type 'file
  :group 'rust-playground)

(defcustom rust-playground-cargo-toml-template
  "[package]
name = \"foo\"
version = \"0.1.0\"
authors = [\"Rust Example <rust-snippet@example.com>\"]
edition = \"2018\"

[dependencies]"
  "When creating a new playground, this will be used as the Cargo.toml file")

(defcustom rust-playground-main-rs-template
  "fn main() {
    
    println!(\"Results:\")
}"
  "When creating a new playground, this will be used as the body of the main.rs file")

(define-minor-mode rust-playground-mode
  "A place for playing with Rust code and export it in short snippets."
  :init-value nil
  :lighter "Play(Rust)"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-c") 'rust-playground-exec)
            (define-key map (kbd "C-c b") 'rust-playground-switch-between-cargo-and-main)
            (define-key map (kbd "C-c k") 'rust-playground-rm)
            map))

(defun rust-playground-dir-name (&optional snippet-name)
  "Get the name of the directory where the snippet will exist, with SNIPPET-NAME as part of the directory name."
  (file-name-as-directory (concat (file-name-as-directory rust-playground-basedir)
                                  (time-stamp-string "at-%:y-%02m-%02d-%02H%02M%02S"))))

(defun rust-playground-snippet-main-file-name (basedir)
  "Get the snippet main.rs file from BASEDIR."
  (concat basedir (file-name-as-directory "src") "main.rs"))

(defun rust-playground-toml-file-name (basedir)
  "Get the cargo.toml filename from BASEDIR."
  (concat basedir "Cargo.toml"))

(defun rust-playground-get-snippet-basedir (&optional path)
  "Get the path of the dir containing this snippet.
Start from PATH or the path of the current buffer's file, or NIL if this is not a snippet."
  (unless path
    (setq path (buffer-file-name)))
  (if (not path)
      nil
    (if (not (string= path "/"))
        (let ((base (expand-file-name rust-playground-basedir))
              (path-parent (file-name-directory (directory-file-name path))))
          (if (string= (file-name-as-directory base)
                       (file-name-as-directory path-parent))
              path
            (rust-playground-get-snippet-basedir path-parent)))
      nil)))

;; I think the proper way to check for this is to test if the minor mode is active
;; TODO base this check off the minor mode, once that mode gets set on all files
;; in a playground
(defmacro in-rust-playground (&rest forms)
  "Execute FORMS if current buffer is part of a rust playground.
Otherwise message the user that they aren't in one."
  `(if (not (rust-playground-get-snippet-basedir))
       (message "You aren't in a Rust playground.")
     ,@forms))

(defun rust-playground-exec ()
  "Save the buffer then run Rust compiler for executing the code."
  (interactive)
  (in-rust-playground
   (save-buffer t)
   (compile rust-playground-run-command)))

;;;###autoload
(defun rust-playground ()
  "Run playground for Rust language in a new buffer."
  (interactive)
  ;; get the dir name
  (let* ((snippet-dir (rust-playground-dir-name))
         (snippet-file-name (rust-playground-snippet-main-file-name snippet-dir))
         (snippet-cargo-toml (rust-playground-toml-file-name snippet-dir)))
    ;; create a buffer for Cargo.toml and switch to it
    (make-directory snippet-dir t)
    (set-buffer (create-file-buffer snippet-cargo-toml))
    (set-visited-file-name snippet-cargo-toml t)
    (rust-playground-mode)
    (rust-playground-insert-template-head "snippet of code" snippet-dir)
    (insert rust-playground-cargo-toml-template)
    (save-buffer)
    ;;now do src/main.rs
    (make-directory (concat snippet-dir "src"))
    (switch-to-buffer (create-file-buffer snippet-file-name))
    (set-visited-file-name snippet-file-name t)
    (rust-playground-insert-template-head "snippet of code" snippet-dir)
    (insert rust-playground-main-rs-template)
    ;; back up to a good place to edit from
    (backward-char 27)
    (rust-playground-mode)))

(defun rust-playground-switch-between-cargo-and-main ()
  "Change buffers between the main.rs and Cargo.toml files for the current snippet."
  (interactive)
  (in-rust-playground
   (let ((basedir (rust-playground-get-snippet-basedir)))
     ;; If you're in a rust snippet, but in some file other than main.rs,
     ;; then just switch to main.rs
     (cond
      ;; how to switch to existing or create new, given filename?
      ((string= "main.rs" (file-name-nondirectory buffer-file-name))
       (find-file (rust-playground-toml-file-name basedir)))
      (t
       (find-file (rust-playground-snippet-main-file-name basedir)))))))

(defun rust-playground-insert-template-head (description basedir)
  "Inserts a template about the snippet into the file."
  (let ((starting-point (point)))
    (insert (format
             "%s @ %s

=== Rust Playground ===
This snippet is in: %s

Execute the snippet: C-c C-c
Delete the snippet completely: C-c k
Toggle between main.rs and Cargo.toml: C-c b

" description (time-stamp-string "%:y-%02m-%02d %02H:%02M:%02S") basedir))
    (comment-region starting-point (point))))

(defun rust-playground-get-all-buffers ()
  "Get all the buffers visiting Cargo.toml or any *.rs file under src/."
  (in-rust-playground
   (let* ((basedir (rust-playground-get-snippet-basedir))
          (srcdir (concat basedir (file-name-as-directory "src"))))
     ;; now get the fullpath of cargo.toml, and the fullpath of every file under src/
     (remove 'nil (mapcar 'find-buffer-visiting
                           (cons (concat basedir "Cargo.toml")
                                 (directory-files srcdir t ".*\.rs")))))))

;;;###autoload
(defun rust-playground-rm ()
  "Remove files of the current snippet together with directory of this snippet."
  (interactive)
  (in-rust-playground
   (let ((playground-basedir (rust-playground-get-snippet-basedir)))
     (if playground-basedir
         (when (or (not rust-playground-confirm-deletion)
                   (y-or-n-p (format "Do you want delete whole snippet dir %s? "
                                     playground-basedir)))
           (dolist (buf (rust-playground-get-all-buffers))
             (kill-buffer buf))
           (delete-directory playground-basedir t t))
       (message "Won't delete this! Because %s is not under the path %s. Remove the snippet manually!" (buffer-file-name) rust-playground-basedir)))))

(provide 'rust-playground)
;;; rust-playground.el ends here
