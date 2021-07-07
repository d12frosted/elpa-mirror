;;; org-runbook.el --- Org mode for runbooks -*- lexical-binding: t -*-

;; Author: Tyler Dodge
;; Version: 1.0
;; Package-Version: 20201229.319
;; Package-Commit: e5d1e30a05552ce1d63d13ada1487643a41b92cb
;; Keywords: convenience, processes, terminals, files
;; Package-Requires: ((emacs "25.1") (seq "2.3") (f "0.20.0") (s "1.12.0") (dash "2.17.0") (mustache "0.24") (ht "0.9"))
;; URL: https://github.com/tyler-dodge/org-runbook
;; Git-Repository: git://github.com/tyler-dodge/org-runbook.git
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;;
;;;
;;; Commentary:
;; org-runbook provides heirarchical runbook commands from org file accessible directly from buffers.
;; Main entry points include `org-runbook-execute', `org-runbook-switch-to-major-mode-file',
;; and `org-runbook-switch-to-projectile-file'
;;
;; org-runbook lets you take org files structured like

;; #### MAJOR-MODE.org
;; ```
;; * Build
;; #+BEGIN_SRC shell
;; cd {{project_root}}
;; #+END_SRC

;; ** Quick
;; #+BEGIN_SRC shell
;; make quick
;; #+END_SRC

;; ** Clean
;; #+BEGIN_SRC shell
;; make clean
;; #+END_SRC

;; ** Prod
;; #+BEGIN_SRC shell
;; make prod
;; #+END_SRC
;; ```
;; and exposes them for easy access in buffers with corresponding major mode.
;; So, the function [org-runbook-execute](org-runbook-execute) has the following completions when the current buffer's major mode is MAJOR-MODE:
;; ```
;; Build >> Quick
;; Build >> Clean
;; Build >> Prod
;; ```
;; Each of these commands is the concatenation of the path of the tree.  So for example, Build >> Quick would resolve to:
;; ```
;; cd {{project_root}}
;; make quick
;; ```
;; If projectile-mode is installed, org-runbook also pulls the file named PROJECTILE-PROJECT-NAME.org.
;; All files in [org-runbook-files] are also pulled.
;; Commands will resolve placeholders before evaluating.  Currently the only available placeholder is {{project_root}}
;; which corresponds to the projectile-project-root of the buffer that called `org-runbook-execute'
;;; Code:

;; External Dependencies
(require 'seq)
(require 'f)
(require 's)
(require 'dash)
(require 'mustache)
(require 'ht)

;; Emacs Dependencies
(require 'pulse)
(require 'rx)
(require 'org)
(require 'ob-core)
(require 'pcase)
(require 'subr-x)
(require 'eshell)
(require 'cl-lib)


;; Optional Dependencies
(require 'projectile nil t)
(declare-function projectile-project-name "ext:projectile.el" (&optional project))
(require 'evil nil t)
(require 'ivy nil t)

(defgroup org-runbook nil "Org Runbook Options" :group 'org)

(defcustom org-runbook-files nil
  "Global files used by org runbook.
When resolving commands for the current buffer, `org-runbook' appends
`org-runbook-files' with the major mode org file and the projectile
org file."
  :group 'org-runbook
  :type 'list)

(defcustom org-runbook-project-directory (expand-file-name (f-join user-emacs-directory "runbook" "projects"))
  "Directory used to lookup the org file corresponding to the current project.
`org-runbook-projectile-file' joins `org-runbook-project-directory'
with the function `projectile-project-name' for the current buffer."
  :group 'org-runbook
  :type 'directory)

(defcustom org-runbook-modes-directory (expand-file-name (f-join user-emacs-directory "runbook" "modes"))
  "Directory used to lookup the org file for the current major mode.
`org-runbook-major-mode-file' joins `org-runbook-modes-directory'
with the `symbol-name' of the `major-mode' for the current buffer."
  :group 'org-runbook
  :type 'directory)

(defcustom org-runbook-view-mode-buffer "*compile-command*"
  "Buffer used for `org-runbook-view-target-action' to display the resolved command."
  :group 'org-runbook
  :type 'string)

(defcustom org-runbook-execute-command-action #'org-runbook-command-execute-shell
  "Function called to handle executing the given runbook.
It is provided as a single argument the plist output of `org-runbook--shell-command-for-target'."
  :type 'function
  :group 'org-runbook)

(defcustom org-runbook-process-connection-type nil
  "The process connection type to default to in org-runbook. 
The pty flag is ignored since it's already enabled if this is t."
  :type 'booleanp
  :group 'org-runbook)

(defvar org-runbook--target-history nil "History for org-runbook completing read for targets.")

(defvar org-runbook--last-command-ht (ht)
  "Mapping from projectile root to the last command.
If projectile is not imported, this uses the default directory.

Used by `org-runbook-repeat-command'.")

(defvar-local org-runbook-view--section nil "Tracks the section point is currently on in org-runbook-view-mode")

(cl-defstruct (org-runbook-command-target (:constructor org-runbook-command-target-create)
                                          (:copier org-runbook-command-target-copy))
  name
  point
  buffer)

(cl-defstruct (org-runbook-subcommand (:constructor org-runbook-subcommand-create)
                                      (:copier org-runbook-subcommand-copy))
  heading
  target
  command)

(cl-defstruct (org-runbook-elisp-subcommand
               (:constructor org-runbook-elisp-subcommand-create)
               (:copier org-runbook-elisp-subcommand-copy))
  heading
  target
  elisp)

(cl-defstruct (org-runbook-command (:constructor org-runbook-command-create)
                                   (:copier org-runbook-command-copy))
  name
  full-command
  target
  subcommands
  pty)

(cl-defstruct (org-runbook-file (:constructor org-runbook-file-create)
                                (:copier org-runbook-file-copy))
  name
  file
  targets)

(defun org-runbook--completing-read ()
  "Prompt user for a runbook command."
  (let ((target-map
         (->> (org-runbook-targets)
              (--map (org-runbook-file-targets it))
              (-flatten)
              (--map (cons (org-runbook-command-target-name it) it))
              (ht<-alist))))
    (when (eq (ht-size target-map) 0) (org-runbook--no-commands-error))
    (when-let (key (completing-read "Runbook:" target-map nil t nil 'org-runbook--target-history))
      (ht-get target-map key))))

;;;###autoload
(defun org-runbook-execute ()
  "Prompt for command completion and execute the selected command."
  (interactive)
  (-some-> (org-runbook--completing-read) org-runbook-execute-target-action))

;;;###autoload
(defun org-runbook-view ()
  "Prompt for command completion and view the selected command."
  (interactive)
  (-some-> (org-runbook--completing-read) org-runbook-view-target-action))

;;;###autoload
(defun org-runbook-goto ()
  "Prompt for command completion and goto the selected command's location."
  (interactive)
  (-some-> (org-runbook--completing-read) org-runbook-goto-target-action))

;;;###autoload
(defun org-runbook-repeat ()
  "Repeat the last command for the current projectile project.

Use `default-directory' if projectile is unavailable."
  (interactive)
  (let ((command (ht-get org-runbook--last-command-ht (org-runbook--project-root))))
    (if command (funcall org-runbook-execute-command-action command)
      (org-runbook-execute))))

;;;###autoload
(defun org-runbook-targets ()
  "Return the runbook commands corresponding to the current buffer."
  (save-excursion
    (let* ((major-mode-file (list (cons (symbol-name major-mode) (org-runbook-major-mode-file t))))
           (current-buffer-file (when (eq major-mode 'org-mode)
                                  (list (cons "*current buffer*"
                                              (buffer-file-name)))))
           (projectile-file (list (when (fboundp 'projectile-project-name)
                                    (cons (concat "*Project " (projectile-project-name) "*")
                                          (org-runbook-projectile-file t)))))
           (global-files (--map (cons it it) org-runbook-files))
           (org-files
            (seq-uniq (-flatten (append major-mode-file current-buffer-file projectile-file global-files))
                      (lambda (lhs rhs) (string= (cdr lhs) (cdr rhs))))))
      (cl-loop for file in org-files
               append
               (save-excursion
                 (-let* (((name . file) file)
                         (targets (when (-some-> file f-exists-p)
                                    (set-buffer (or (find-buffer-visiting file) (find-file-noselect file)))
                                    (org-runbook--targets-in-buffer))))
                   (when targets
                     (-> (org-runbook-file-create
                          :name name
                          :file file
                          :targets targets)
                         list))))))))

;;;###autoload
(defun org-runbook-switch-to-major-mode-file ()
  "Switch current buffer to the file corresponding to the current buffer's major mode."
  (interactive)
  (find-file (org-runbook-major-mode-file)))

;;;###autoload
(defun org-runbook-switch-to-projectile-file ()
  "Switch current buffer to the file corresponding to the current buffer's projectile mode."
  (interactive)
  (find-file (org-runbook-projectile-file)))

;;;###autoload
(defun org-runbook-capture-target-major-mode-file ()
  "Switch current buffer to the file corresponding to the current buffer's major mode."
  (org-runbook-switch-to-major-mode-file)
  (goto-char (point-max)))

;;;###autoload
(defun org-runbook-capture-target-projectile-file ()
  "Target for appending at the end of the runbook corresponding to the current buffer's projectile project."
  (org-runbook-switch-to-projectile-file)
  (goto-char (point-max)))



(defun org-runbook-view-target-action (target)
  "View the selected command from helm.  Expects TARGET to be a `org-runbook-command-target'."
  (unless (org-runbook-command-target-p target) (error "Unexpected type provided: %s" target))
  (pcase-let* ((count 0)
               (displayed-headings (ht))
               ((cl-struct org-runbook-command subcommands) (org-runbook--shell-command-for-target target)))
    (switch-to-buffer (or (get-buffer org-runbook-view-mode-buffer)
                          (generate-new-buffer org-runbook-view-mode-buffer)))

    (org-runbook-view-mode)
    (setq-local inhibit-read-only t)
    (erase-buffer)
    (->> subcommands
         (-map
          (pcase-lambda ((and section (cl-struct org-runbook-subcommand heading command)))
            (setq count (1+ count))
            (--> (concat
                  (when (not (ht-get displayed-headings heading nil))
                    (ht-set displayed-headings heading t)
                    (concat (s-repeat count "*")
                            " "
                            heading
                            "\n\n"))
                  (if (listp command)
                      "(deferred:nextc\n  it\n  (lambda ()\n  "
                    "#+BEGIN_SRC shell\n\n")
                  (format (if (listp command) "%S" "%s") command)
                  (if (listp command)
                      ")"
                    "\n#+END_SRC")
                  "\n")
                 (propertize it 'section section))))
         (s-join "\n")
         (insert))
    (setq-local inhibit-read-only nil)))

(defun org-runbook-execute-target-action (target)
  "Execute the `org-runbook' compile TARGET from helm.
Expects COMMAND to be of the form (:command :name)."
  (let ((command (org-runbook--shell-command-for-target target)))
    (ht-set org-runbook--last-command-ht
            (org-runbook--project-root)
            command)
    (funcall org-runbook-execute-command-action command)))

(defun org-runbook-command-execute-eshell (command)
  "Execute the COMMAND in eshell."
  (org-runbook--validate-command command)
  (pcase-let (((cl-struct org-runbook-command full-command) command))
    ;; Intentionally not shell quoting full-command since it's a script
    (eshell-command full-command)))

(defun org-runbook-command-execute-shell (command)
  "Execute the COMMAND in shell."
  (org-runbook--validate-command command)
  (pcase-let (((cl-struct org-runbook-command full-command name) command))
    ;; Intentionally not shell quoting full-command since it's a script
    (let ((process-connection-type (or org-runbook-process-connection-type
                                       (org-runbook-command-pty command))))
      (async-shell-command full-command (concat "*" name "*")))))

(defun org-runbook-goto-target-action (command)
  "Goto the position referenced by COMMAND.
Expects COMMAND to ether be a `org-runbook-subcommand'
or a `org-runbook-command-target'."
  (--> (pcase command
         ((or (cl-struct org-runbook-subcommand (target (cl-struct org-runbook-command-target point buffer)))
              (cl-struct org-runbook-command-target point buffer))
          (list :buffer buffer :point point)))
       (-let [(&plist :buffer :point) it]
         (switch-to-buffer buffer)
         (goto-char point)
         (pulse-momentary-highlight-one-line (point)))))

(defun org-runbook--targets-in-buffer ()
  "Get all targets by walking up the org subtree in order.
Return `org-runbook-command-target'."
  (save-excursion
    (goto-char (point-min))
    (let* ((known-commands (ht)))
      (cl-loop while (re-search-forward (rx line-start (* whitespace) "#+BEGIN_SRC" (* whitespace) (or "shell" "emacs-lisp")) nil t)
               append
               (let* ((headings (save-excursion
                                  (append
                                   (list (org-runbook--get-heading))
                                   (save-excursion
                                     (cl-loop while (org-up-heading-safe)
                                              append (list (org-runbook--get-heading)))))))
                      (name (->> headings
                                 (-map 's-trim)
                                 (reverse)
                                 (s-join " >> "))))
                 (when (not (ht-get known-commands name nil))
                   (ht-set known-commands name t)
                   (list (org-runbook-command-target-create
                          :name name
                          :buffer (current-buffer)
                          :point (save-excursion
                                   (unless (org-at-heading-p) (re-search-backward (regexp-quote (org-runbook--get-heading))))
                                   (point))))))))))

(defun org-runbook--get-heading ()
  (substring-no-properties (org-get-heading t t t t)))

(defun org-runbook-major-mode-file (&optional no-ensure)
  "Target for appending at the end of the runbook corresponding to the current buffer's major mode.
Ensures the file exists unless NO-ENSURE is non-nil."
  (let ((file (f-join org-runbook-project-directory (concat (symbol-name major-mode) ".org"))))
    (if no-ensure file (org-runbook--ensure-file file))))

(defun org-runbook-projectile-file (&optional no-ensure)
  "Return the path for the org runbook file correspoding to the current projectile project.
Ensures the file exists unless NO-ENSURE is non-nil."
  (unless (fboundp 'projectile-project-name)
    (user-error "Projectile must be installed for org-runbook-projectile-file"))
  (let ((file (f-join org-runbook-project-directory (concat (projectile-project-name) ".org"))))
    (if no-ensure file (org-runbook--ensure-file file))))

(defun org-runbook--ensure-file (file)
  "Create the FILE if it doesn't exist.  Return the fully expanded FILE name."
  (let ((full-file (expand-file-name file)))
    (unless (f-exists-p full-file)
      (mkdir (f-parent full-file) t)
      (f-touch full-file))
    full-file))

(defvar org-runbook-view-mode-map
  (-doto (make-sparse-keymap)
    (define-key (kbd "<return>") #'org-runbook-view--open-at-point)))

(define-derived-mode org-runbook-view-mode org-mode "compile view"
  "Mode for viewing resolved org-runbook commands"
  (read-only-mode 1)
  (view-mode 1))



(defun org-runbook--project-root ()
  "Return the current project root if projectile is defined otherwise `default-directory'."
  (or (and (fboundp 'projectile-project-root) (projectile-project-root))
      default-directory))

(defun org-runbook-view--open-at-point ()
  "Switch buffer to the file referenced at point in `org-runbook-view-mode'."
  (interactive)
  (or (-some-> (get-text-property (point) 'section) org-runbook-goto-target-action)
      (user-error "No known section at point")))

(defun org-runbook--shell-command-for-target (target)
  "Return the `org-runbook-command' for a TARGET.
TARGET is a `org-runbook-command-target'."
  (unless (org-runbook-command-target-p target) (error "Unexpected type passed %s" target))
  (save-excursion
    (pcase-let (((cl-struct org-runbook-command-target name buffer point) target))
      (let* ((start-location (cons (current-buffer) (point)))
             (project-root (org-runbook--project-root))
             (source-buffer-file-name (or (buffer-file-name buffer) default-directory))
             (has-pty-tag nil)
             (subcommands nil))
        (set-buffer buffer)
        (goto-char point)
        (save-excursion
          (let* ((at-root nil))
            (while (not at-root)
              (let* ((start (org-runbook--get-heading))
                     (group nil))
                (save-excursion
                  (end-of-line)
                  (while (and (re-search-forward (rx "#+BEGIN_SRC" (* whitespace) (or "shell" "emacs-lisp")) nil t)
                              (string= (org-runbook--get-heading) start))
                    (setq has-pty-tag (or has-pty-tag (-contains-p (org-get-tags) "PTY")))
                    (let* ((context (org-element-context))
                           (src-block-info (with-current-buffer (car start-location)
                                             (goto-char (cdr start-location))
                                             (org-babel-get-src-block-info nil context))))
                      (pcase (car src-block-info)
                        ((pred (s-starts-with-p "emacs-lisp"))
                         (push
                          (org-runbook-elisp-subcommand-create
                           :heading start
                           :target (org-runbook-command-target-create
                                    :buffer (current-buffer)
                                    :point (point))
                           :elisp
                           (read
                            (concat
                             "(progn "
                             (buffer-substring-no-properties
                              (save-excursion (forward-line 1) (point))
                              (save-excursion (re-search-forward (rx "#+END_SRC")) (beginning-of-line) (point)))
                             ")")))
                          group))
                        ((pred (s-starts-with-p "shell"))
                         (push
                          (org-runbook-subcommand-create
                           :heading start
                           :target (org-runbook-command-target-create
                                    :buffer (current-buffer)
                                    :point (point))
                           :command
                           (s-replace-all
                            '(("&quot;" . "\"")
                              ("&lt;" . "<")
                              ("&apos;" . "'")
                              ("&amp;" . "&")
                              ("&gt;" . ">"))
                            (mustache-render
                             (buffer-substring-no-properties
                              (save-excursion (forward-line 1) (point))
                              (save-excursion (re-search-forward (rx "#+END_SRC")) (beginning-of-line) (point)))
                             (let ((context (org-element-context)))
                               (--doto (ht<-alist (->> (caddr src-block-info)
                                                       (--map (cons (symbol-name (car it)) (format "%s" (cdr it))))
                                                       (--filter (not (s-starts-with-p ":" (car it))))))
                                 (ht-set it "project_root" project-root)
                                 (ht-set it "current_file" source-buffer-file-name)
                                 (ht-set it "context" (format "%s" (ht->plist it))))))))
                          group))))
                    (forward-line 1)))
                (setq subcommands (append (reverse group) subcommands nil)))
              (setq at-root (not (org-up-heading-safe))))))
        (org-runbook-command-create
         :name name
         :pty has-pty-tag
         :target (-some->> subcommands (-filter #'org-runbook-subcommand-p) last car org-runbook-subcommand-target)
         :full-command
         (-some->> subcommands
           (--filter (and it (org-runbook-subcommand-p it)))
           (--map (org-runbook-subcommand-command it))
           (--filter it)
           (--map (s-trim it))
           (s-join ";\n"))
         :subcommands subcommands)))))

(defun org-runbook--no-commands-error ()
  "Error representing that no commands were found for the current buffer."
  (if (fboundp 'projectile-project-name)
      (user-error "No Commands Defined For Runbook.  (Major Mode: %s, Project: %s)"
                  (symbol-name major-mode)
                  (projectile-project-name))
    (user-error "No Commands Defined For Runbook.  (Major Mode: %s)"
                (symbol-name major-mode))))

(defun org-runbook--validate-command (command)
  "Validates COMMAND and throws errors if it doesn't match spec."
  (unless command (error "Command cannot be nil"))
  (unless (org-runbook-command-p command) (error "Unexepected type for command %s" command))
  t)

(when (fboundp 'ivy-read)
  (defun org-runbook-ivy ()
    "Prompt for command completion and execute the selected command.
The rest of the interactive commands are accesible through this via
the extra actions. See `ivy-dispatching-done'"
    (interactive)
    (ivy-read "Command"
              (->> (org-runbook-targets)
                   (--map (->> it (org-runbook-file-targets)))
                   (-flatten)
                   (--map (cons (->> it (org-runbook-command-target-name)) it)))
              :caller 'org-runbook-ivy)))

(when (fboundp 'ivy-set-actions)
  (ivy-set-actions
   'org-runbook-ivy
   `(
     ("o" (lambda (target) (org-runbook-execute-target-action (cdr target))) "Execute Target")
     ("g" (lambda (target) (org-runbook-goto-target-action (cdr target))) "Goto Target")
     ("p" (lambda (&rest arg) (org-runbook-switch-to-projectile-file)) "Switch to Projectile File")
     ("y" (lambda (&rest arg) (org-runbook-switch-to-major-mode-file)) "Switch to Major Mode File")
     ("v" (lambda (target) (org-runbook-view-target-action (cdr target))) "View Target"))))

(when (boundp 'evil-motion-state-modes)
  (add-to-list 'evil-motion-state-modes 'org-runbook-view-mode))

(provide 'org-runbook)
;;; org-runbook.el ends here
