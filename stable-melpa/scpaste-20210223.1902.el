;;; scpaste.el --- Paste to the web via scp.

;; Copyright © 2008-2020 Phil Hagelberg and contributors

;; Author: Phil Hagelberg
;; URL: https://git.sr.ht/~technomancy/scpaste
;; Package-Version: 20210223.1902
;; Package-Commit: 4ec352fb9fe261ffb8b78449dea986dc34d337b3
;; Version: 0.6.5
;; Created: 2008-04-02
;; Keywords: convenience hypermedia
;; EmacsWiki: SCPaste
;; Package-Requires: ((htmlize "1.39"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This will place an HTML copy of a buffer on the web on a server
;; that the user has shell access on.

;; It's similar in purpose to services such as https://gist.github.com
;; or https://pastebin.com, but it's much simpler since it assumes the user
;; has an account on a publicly-accessible HTTP server. It uses `scp'
;; as its transport and uses Emacs' font-lock as its syntax
;; highlighter instead of relying on a third-party syntax highlighter
;; for which individual language support must be added one-by-one.

;;; Install

;; Requires htmlize; available at
;; https://github.com/hniksic/emacs-htmlize.  If htmlize is not
;; installed, by default it will fall back to Emacs's own htmlfontify.

;; Open the file and run `package-install-from-buffer', or put it on your
;; `load-path' and add these to your config:

;; (autoload 'scpaste "scpaste" nil t)
;; (autoload 'scpaste-region "scpaste" nil t)

;; Set `scpaste-http-destination' and `scpaste-scp-destination' to
;; appropriate values, and add this to your Emacs config:

;; (setq scpaste-http-destination "https://p.hagelb.org"
;;       scpaste-scp-destination "p.hagelb.org:p.hagelb.org")

;; If you have a different keyfile, you can set that, too:
;; (setq scpaste-scp-pubkey "~/.ssh/my_keyfile.pub")

;; If you use a non-standard ssh port, you can specify it by setting
;; `scpaste-scp-port'.

;; If you need to use alternative scp and ssh programs, you can set
;; `scpaste-scp' and `scpaste-ssh'. For example, scpaste works with the Putty
;; suite on Windows if you set these to pscp and plink, respectively.

;; Optionally you can set the displayed name for the footer and where
;; it should link to:

;; (setq scpaste-user-name "Technomancy"
;;       scpaste-user-address "https://technomancy.us/")

;;; Usage

;; M-x scpaste, enter a name, and press return. The name will be
;; incorporated into the URL by escaping it and adding it to the end
;; of `scpaste-http-destination'. The URL for the pasted file will be
;; pushed onto the kill ring.

;; You can autogenerate a splash page that gets uploaded as index.html
;; in `scpaste-http-destination' by invoking M-x scpaste-index. This
;; will upload an explanation as well as a listing of existing
;; pastes. If a paste's filename includes "private" it will be skipped.

;; You probably want to set up SSH keys for your destination to avoid
;; having to enter your password once for each paste. Also be sure the
;; key of the host referenced in `scpaste-scp-destination' is in your
;; known hosts file--scpaste will not prompt you to add it but will
;; simply hang and need you to hit C-g to cancel it.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'url)
(require 'htmlize nil t)

(defvar scpaste-html-converter
  (if (featurep 'htmlize)
      'htmlize-buffer
    'htmlfontify-buffer)
  "Name of the function to use to generate the HTML output.
By default, it will try to use `htmlize-buffer' from htmlize, and
will fall back to `htmlfontify-buffer' from Emacs's `htmlfontify'
if htmlize is not available.")

(defvar scpaste-scp-port
  nil)

(defvar scpaste-scp
  "scp"
  "The scp program to use.")

(defvar scpaste-ssh
  "ssh"
  "The ssh program to use when running remote shell commands.")

(defvar scpaste-http-destination
  "https://p.hagelb.org"
  "Publicly-accessible (via HTTP) location for pasted files.")

(defvar scpaste-scp-destination
  "p.hagelb.org:p.hagelb.org"
  "SSH-accessible directory corresponding to `scpaste-http-destination'.
You must have write access to this directory via `scp'.")

(defvar scpaste-scp-pubkey
  nil
  "Identity file for the server.
Corresponds to ssh’s `-i` option Example: \"~/.ssh/id.pub\".
It's better to set this in ~/.ssh/config than to use this setting.")

(defvar scpaste-user-name
  nil
  "Name displayed under the paste.")

(defvar scpaste-user-address
  nil
  "Link to the user’s homebase (can be a mailto:).")

(defvar scpaste-make-name-function
  'scpaste-make-name-from-buffer-name
  "The function used to generate file names, unless the user provides one.")

(defvar scpaste-el-location (replace-regexp-in-string "\.elc$" ".el"
                                                      (or load-file-name
                                                          (buffer-file-name))))

(defun scpaste-footer ()
  "HTML message to place at the bottom of each file."
  (concat "<p style='font-size: 8pt; font-family: monospace; "
          (mapconcat (lambda (c) (concat c "-select: none"))
                     '("-moz-user" "-webkit-user" "-ms-user" "user") "; ")
          "'>Generated by "
          (let ((user (or scpaste-user-name user-full-name)))
            (if scpaste-user-address
                (concat "<a href='" scpaste-user-address "'>" user "</a>")
              user))
          " using <a href='https://p.hagelb.org'>scpaste</a> at %s. "
          (cadr (current-time-zone)) ". (<a href='%s'>original</a>)</p>"))

(defun scpaste-read-name (&optional suffix)
  "Read the paste name from the minibuffer.

Defaults to the return value of `scpaste-make-name-function'
with SUFFIX as argument."
  (let* ((default (funcall scpaste-make-name-function suffix))
         (input (read-from-minibuffer (format "Name: (defaults to %s) "
                                              default))))
    (if (equal "" input) default input)))

(defun scpaste-make-name-from-buffer-name (&optional suffix)
  "Make a name from buffer name and extension.

If non-nil, SUFFIX is inserted between name and extension."
  (concat (file-name-sans-extension (buffer-name))
          suffix
          (file-name-extension (buffer-name) t)))

(defun scpaste-make-name-from-timestamp (&optional _)
  "Make a name from current timestamp and current buffer's extension."
  (concat (format-time-string "%s") (file-name-extension (buffer-name) t)))

;;;###autoload
(defun scpaste (original-name)
  "Paste the current buffer via `scp' to `scpaste-http-destination'.
If ORIGINAL-NAME is an empty string, then the buffer name is used
for the file name."
  (interactive (list (scpaste-read-name)))
  (let* ((b (generate-new-buffer (generate-new-buffer-name "scpaste")))
         (pre-hl-line (and (featurep 'hl-line) hl-line-mode
                           (progn (hl-line-mode -1) t)))
         (hb (funcall scpaste-html-converter))
         (name (replace-regexp-in-string "[/\\%*:|\"<>  ]+" "_"
                                         original-name))
         (full-url (concat scpaste-http-destination
                           "/" (url-hexify-string name) ".html"))
         (tmp-file (concat temporary-file-directory name))
         (tmp-hfile (concat temporary-file-directory name ".html")))
    (when pre-hl-line
      (hl-line-mode 1))
    ;; Save the files (while adding a footer to html file)
    (save-excursion
      (copy-to-buffer b (point-min) (point-max))
      (switch-to-buffer b)
      (write-file tmp-file)
      (kill-buffer b)
      (switch-to-buffer hb)
      (goto-char (point-min))
      (search-forward "</body>\n</html>")
      (insert (format (scpaste-footer)
                      (current-time-string)
                      (substring full-url 0 -5)))
      (write-file tmp-hfile)
      (kill-buffer hb))

    (let* ((identity (if scpaste-scp-pubkey
                         (concat "-i " scpaste-scp-pubkey) ""))
           (port (if scpaste-scp-port (concat "-P " scpaste-scp-port)))
           (invocation (concat scpaste-scp " -q " identity " " port))
           (command (concat invocation " " tmp-file " " tmp-hfile " "
                            scpaste-scp-destination "/"))
           (error-buffer "*scp-error*")
           (retval (shell-command command nil error-buffer))
           (select-enable-primary t))

      (delete-file tmp-file)
      (delete-file tmp-hfile)
      ;; Notify user and put the URL on the kill ring
      (if (= retval 0)
          (progn (kill-new full-url)
                 (message "Pasted to %s (on kill ring)" full-url))
        (pop-to-buffer error-buffer)
        (help-mode-setup)))))

;;;###autoload
(defun scpaste-region (name)
  "Paste the current region via `scpaste'.
NAME is used for the file name."
  (interactive (list (scpaste-read-name (format "-%s-%s" (region-beginning)
                                                (region-end)))))
  (let ((region-contents (buffer-substring (mark) (point))))
    (with-temp-buffer
      (insert region-contents)
      (scpaste name))))

;;;###autoload
(defun scpaste-index ()
  "Generate an index of all existing pastes on server on the splash page."
  (interactive)
  (let* ((dest-parts (split-string scpaste-scp-destination ":"))
         (files (shell-command-to-string (concat scpaste-ssh " "
                                                 (car dest-parts) " ls "
                                                 (cadr dest-parts))))
         (file-list (split-string files "\n")))
    (save-excursion
      (with-temp-buffer
        (insert-file-contents scpaste-el-location)
        (goto-char (point-min))
        (search-forward ";;; Commentary")
        (forward-line -1)
        (insert "\n;;; Pasted Files\n\n")
        (dolist (file file-list)
          (when (and (string-match "\\.html$" file)
                     (not (string-match "private" file)))
            (insert (concat ";; * <" scpaste-http-destination "/" file ">\n"))))
        (emacs-lisp-mode)
        (if (fboundp 'font-lock-ensure)
            (progn (font-lock-mode nil)
                   (font-lock-ensure)
                   (jit-lock-mode t))
          (with-no-warnings ; fallback for Emacs 24
            (font-lock-fontify-buffer)))
        (rename-buffer "SCPaste")
        (write-file (concat temporary-file-directory "scpaste-index"))
        (scpaste "index")))))

(provide 'scpaste)
;;; scpaste.el ends here
