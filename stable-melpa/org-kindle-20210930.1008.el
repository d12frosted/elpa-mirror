;;; org-kindle.el --- Send org link file to ebook reader.

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "25") (cl-lib "0.5") (seq "2.20"))
;; Package-Commit: fdba34a47b670226f46ad7b3a4db4edc7f7907e7
;; Package-Version: 20210930.1008
;; Package-X-Original-Version: 0.1
;; Keywords: org link ebook kindle epub azw3 mobi
;; homepage: https://github.com/stardiviner/org-kindle

;; org-kindle is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; org-kindle is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;;
;; This is package makes an Emacs bridge between Kindle (other ereaders
;; supports could work in theoretically) and Org Mode.
;; In theatrically, this package should work for non-kindle ereaders too. User can
;; set device path in variables. But becaused not tested, so I can't guarantee that
;; package will work correctly. But PR welcome to improve it. I appreciate it.
;;
;; This packages use a command `ebook-convert' which comes from
;; [[https://calibre-ebook.com/][Calibre]]. So if you want to use auto convert
;; functionality, you need to install it manuall.
;;
;; - It support send Org Mode file: link file to Kindle or other ereaders like Nook.

;;; Todos:
;;
;; - Support sync Kindle notes with Org Mode notes file.

;; Usage:
;;
;; [M-x org-kindle]

;;; Code:

(require 'cl-lib) ; for `cl-case'
(require 'seq) ; for `seq-filter'
(require 'org)
(require 'org-element)
(require 'dash) ; for `->>'

(defgroup org-kindle nil
  "Send org-mode ebook file: link to external devices with corresponding formats.."
  :prefix "org-kindle-"
  :group 'org)

(defvar org-kindle-supported-devices-alist
  '(:kindle (:name "Kindle" :device-name "Amazon Kindle"
                   :documents-path "/Kindle/documents/")
            :nook (:name "Nook" :device-name "Nook"
                         :documents-path "" ; FIXME:
                         ))
  "Alist of package supported devices.")

(defvar org-kindle-target-format nil)

(defcustom org-kindle-default-format ".epub"
  "The default target device format used to send."
  :type 'string
  :group 'org-kindle)

;;;###autoload
(defun org-kindle--read-device-info ()
  "Match name in shell command lsusb listed out devices."
  (cl-case system-type
    ('darwin
     (if (file-exists-p "/Volumes/kindle")
         "kindle"
       "unknown"))
    ('gnu/linux
     (cond
      ((seq-filter
        (lambda (usb)
          (string-match (rx "Amazon Kindle") usb))
        (split-string (shell-command-to-string "lsusb") "\n")) "kindle")
      ((seq-filter
        (lambda (usb)
          (string-match (rx "Nook") usb))
        (split-string (shell-command-to-string "lsusb") "\n")) "nook")
      (t
       (progn
         (warn "unknown device, can't detect device correctly,\n
please report to https://github.com/stardiviner/org-kindle/issues")
         "unknown"))))))

;;;###autoload
(defun org-kindle--detect-format ()
  "Detect plugged in device's ebook format."
  (cl-case (intern (org-kindle--read-device-info))
    ('kindle ".azw3")
    ('nook ".epub")
    (t org-kindle-default-format)))

;;;###autoload
(defun org-kindle--mount-path ()
  "Get Linux general mount path."
  (cl-case system-type
    ('gnu/linux
     (directory-file-name (concat "/run/media/" (getenv "USER"))))
    ('darwin
     (directory-file-name "/Volumes/"))
    ('windows-nt ; TODO:
     )))

;;;###autoload
(defun org-kindle--detect-directory ()
  "Detect plugged in device directory of saving ebook."
  (cl-case (intern (org-kindle--read-device-info))
    ('kindle
     (expand-file-name
      (concat (org-kindle--mount-path)
              (plist-get (plist-get org-kindle-supported-devices-alist :kindle)
                         :documents-path))))
    (t
     (read-directory-name "Send to device directory: "))))

(defun org-kindle--file-name-escape-special-chars (filename)
  "Escape special characters like : in filename which invalid in copying filename."
  (->> filename
       (replace-regexp-in-string ":" "\\\\:")
       (replace-regexp-in-string " " "\\\\ ")))

(defun org-kindle--file-name-strim-special-chars (filename)
  "strim some special characters in filename which does not
    supported by Kindle filesystem."
  (->> filename
       (replace-regexp-in-string ":" "-")))

;;;###autoload
(defun org-kindle-send-to-device ()
  "Send `org-mode' ebook file: link to external devices with corresponding formats."
  (interactive)
  ;; get the file path under org-mode link.
  (when (string= (org-element-property :type (org-element-context)) "file")
    (let* ((source-file (expand-file-name (org-link-unescape (org-element-property :path (org-element-context)))))
           (target-file-name (org-kindle--file-name-strim-special-chars
                              (file-name-nondirectory
                               (concat (file-name-sans-extension source-file)
                                       (org-kindle--detect-format)))))
           (default-directory (temporary-file-directory))
           (convert-temp-file (concat (temporary-file-directory) target-file-name))
           (device-directory (org-kindle--detect-directory)))
      ;; device already has this file.
      (unless (or (file-exists-p (concat device-directory target-file-name))
                  (file-exists-p
                   (concat
                    device-directory
                    (file-name-sans-extension target-file-name) ".azw3")))
        ;; converted temp file exist, when previous convert failed.
        (if (file-exists-p convert-temp-file)
            (progn
              (message "org-kindle: converted temp target file exist.")
              (copy-file convert-temp-file device-directory)
              (message (format "org-kindle: %s finished." target-file-name)))
          ;; if source file format is matched for device, copy directly.
          (if (or (string= (file-name-extension source-file)
                           (file-name-extension target-file-name))
                  ;; if source file is .azw3, also suitable for Kindle.
                  (if (equal (org-kindle--read-device-info) "kindle")
                      (string= (file-name-extension source-file) "azw3")))
              (progn
                (copy-file (format "%s" source-file) ; fix filename special characters like : etc in format.
                           (concat device-directory target-file-name))
                (message (format "org-kindle: %s finished." target-file-name)))
            ;; convert ebook to device compatible format.
            (message (format "org-kindle: %s started..." target-file-name))
            ;; actually process to convert ebook
            (async-shell-command
             (concat "ebook-convert"
                     " " (shell-quote-argument source-file)
                     " " (shell-quote-argument convert-temp-file) " ; "
                     "cp"
                     " " (shell-quote-argument convert-temp-file)
                     " " device-directory)
             (format "*org-kindle: %s*" target-file-name)
             (format "*Error org-kindle: %s*" target-file-name))
            ;; write converted target file path to process output buffer.
            (with-current-buffer (format "*org-kindle: %s*" target-file-name)
              (goto-char (point-max))
              (insert (format "%s" (concat device-directory target-file-name))))

            ;; FIXME:
            ;; (make-process
            ;;  :name (format "org-kindle: %s" target-file-name)
            ;;  :command (list
            ;;            "ebook-convert" " "
            ;;            (shell-quote-argument source-file) " "
            ;;            (shell-quote-argument convert-temp-file))
            ;;  :sentinel (lambda (proc event)
            ;;              ;; send converted file to device
            ;;              (if (string= event "finished\n")
            ;;                  (progn
            ;;                    (copy-file convert-temp-file device-directory)
            ;;                    (message "org-kindle: %s finished." target-file-name))
            ;;                (user-error "Error on process: org-kindle.\n%S" event)))
            ;;  :buffer (format "*org-kindle: %s*" target-file-name))
            
            ))))))



(provide 'org-kindle)

;;; org-kindle.el ends here
