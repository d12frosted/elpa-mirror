;;; helm-dired-recent-dirs.el --- Show recent dirs with helm.el support.

;; Copyright (C) 2013  akisute3 <akisute3@gmail.com>

;; Author: Akisute <akisute3@gmail.com>
;; Version: 0.1
;; Package-Version: 20131228.1414
;; Package-Commit: 3bcd125b44f5a707588ae3868777d91192351523
;; Package-Requires: ((helm "1.0"))
;; Keywords: helm, dired, zsh

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

;;; Installation:

;; (setq shell-file-name "/bin/zsh")
;; (require 'helm-dired-recent-dirs)

;;; Code:


(require 'helm)
(require 'dired)

(defvar helm-dired-recent-dirs-max 5000)


(defun helm-dired-recent-dirs-init-script ()
  (format "autoload -Uz chpwd_recent_dirs cdr add-zsh-hook &&
add-zsh-hook chpwd chpwd_recent_dirs &&
zstyle \":chpwd:*\" recent-dirs-max %d"
          helm-dired-recent-dirs-max))


(defun helm-dired-recent-dirs-cd()
  (call-process-shell-command
   (format "%s && cd %s && cdr -r"
           (helm-dired-recent-dirs-init-script)
           (dired-current-directory))))

(add-hook 'dired-after-readin-hook 'helm-dired-recent-dirs-cd)


(defun helm-dired-internal (dir)
  (dired dir))


(defvar helm-source-dired-recent-dirs
  '((name . "Dired History:")
    (init .  (lambda ()
               (call-process-shell-command
                (format "%s && cdr -l | sed 's/[0-9]*[[:space:]]*//'"
                        (helm-dired-recent-dirs-init-script))
                nil
                (helm-candidate-buffer 'global))))
    (candidates-in-buffer)
    (action . (("Go" . (lambda (candidate) (helm-dired-internal candidate)))))))

;;;###autoload
(defun helm-dired-recent-dirs-view ()
  (interactive)
  (let ((shell-file-name (executable-find "zsh"))
        (helm-execute-action-at-once-if-one t)
        (helm-quit-if-no-candidate
         (lambda () (message "No recent dirs.")))
        (buf (get-buffer-create "*helm guideline*")))
    (helm
     :sources '(helm-source-dired-recent-dirs)
     :buffer buf)))


(provide 'helm-dired-recent-dirs)
;;; helm-dired-recent-dirs.el ends here
