;;; auto-sudoedit.el --- Auto sudo edit by tramp -*- lexical-binding: t -*-

;; Author: ncaq <ncaq@ncaq.net>
;; Version: 1.1.0
;; Package-Version: 20210522.612
;; Package-Commit: 0dec9e632f1f3208f0da2f94b57efa1aae9ce2ab
;; Package-Requires: ((emacs "26.1")(f "0.19.0"))
;; URL: https://github.com/ncaq/auto-sudoedit

;;; Commentary:

;; when find-file-hook and dired-mode-hook, and current path not writable
;; re-open tramp sudo edit automatic

;;; Code:

(require 'f)
(require 'tramp)

(defun auto-sudoedit-path (curr-path)
  "To convert path to tramp using sudo path.
Argument CURR-PATH is current path.
The result is string or nil.
The nil when will be not able to connect by sudo."
  ;; trampのpathに変換します
  (let ((tramp-path
         (if (tramp-tramp-file-p curr-path)
             (auto-sudoedit-path-from-tramp-ssh-like curr-path)
           (concat "/sudo::" curr-path))))
    (if (and
         ;; Current path may not exist; back up to the first existing parent
         ;; and see if it's writable
         (let ((first-existing-path (f-traverse-upwards #'f-exists? curr-path)))
           (not (and first-existing-path (f-writable? first-existing-path))))
         ;; 変換前のパスと同じでなく(2回めの変換はしない)
         (not (equal curr-path tramp-path))
         ;; sudoで開ける場合は変換したものを返します
         (f-writable? tramp-path))
        tramp-path
      nil)))

(defun auto-sudoedit-path-from-tramp-ssh-like (curr-path)
  "Argument CURR-PATH is tramp path(that use protocols such as ssh)."
  (let* ((file-name (tramp-dissect-file-name curr-path))
         (method (tramp-file-name-method file-name))
         (user (tramp-file-name-user file-name))
         (host (tramp-file-name-host file-name))
         (port (tramp-file-name-port file-name))
         (localname (tramp-file-name-localname file-name))
         (hop (tramp-file-name-hop file-name))
         (new-method "sudo")
         (new-user "root")
         (new-host host)
         (new-port port)
         (new-localname localname)
         (new-hop (format "%s%s%s:%s%s|" (or hop "") method (if user (concat user "@") "") host (if port (concat port "#") ""))))
    ;; 最終メソッドがsudoである場合それ以上の変換は無意味なので行わない。
    (if (equal method "sudo")
        curr-path
      (tramp-make-tramp-file-name
       (make-tramp-file-name
        :method new-method
        :user new-user
        :host new-host
        :port new-port
        :localname new-localname
        :hop new-hop)))))

(defun auto-sudoedit-current-path ()
  "Current path file or dir."
  (or (buffer-file-name) list-buffers-directory))

(defun auto-sudoedit-sudoedit (curr-path)
  "Open sudoedit.  Argument CURR-PATH is path."
  (interactive (list (auto-sudoedit-current-path)))
  (find-file (auto-sudoedit-path curr-path)))

(defun auto-sudoedit (orig-func &rest args)
  "`auto-sudoedit' around-advice.
Argument ORIG-FUNC is original function.
Argument ARGS is original function arguments."
  (let* ((curr-path (car args))
         (tramp-path (auto-sudoedit-path curr-path)))
    (when curr-path
      (if tramp-path
          (apply orig-func tramp-path (cdr args))
        (apply orig-func args)))))

;;;###autoload
(define-minor-mode
  auto-sudoedit-mode
  "automatic do sudo by tramp when need root file"
  :init-value 0
  :lighter " ASE"
  (if auto-sudoedit-mode
      (progn
        (advice-add 'find-file :around 'auto-sudoedit)
        (advice-add 'dired :around 'auto-sudoedit))
    (advice-remove 'find-file 'auto-sudoedit)
    (advice-remove 'dired 'auto-sudoedit)))

(provide 'auto-sudoedit)

;;; auto-sudoedit.el ends here
