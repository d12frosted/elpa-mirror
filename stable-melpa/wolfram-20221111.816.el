;;; wolfram.el --- Wolfram Alpha Integration

;; Copyright (C) 2011-2019  Hans Sjunnesson

;; Author: Hans Sjunnesson <hans.sjunnesson@gmail.com>
;; Keywords: math
;; Package-Version: 20221111.816
;; Package-Commit: e3e8bbc70adf544022dfbd3e95b8904d70e71471
;; Version: 1.2

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

;; This package allows you to query Wolfram Alpha from within Emacs.

;; It is required to get a WolframAlpha Developer AppID in order to use this
;; package.
;;  - Create an account at https://developer.wolframalpha.com/portal/signin.html.
;;  - Once you sign in with the Wolfram ID at
;;    https://developer.wolframalpha.com/portal/myapps/, click on "Get an AppID"
;;    to get your Wolfram API or AppID.
;;  - Follow the steps where you put in your app name and description, and
;;    you will end up with an AppID that looks like "ABCDEF-GHIJKLMNOP",
;;    where few of those characters could be numbers too.
;;  - Set the custom variable `wolfram-alpha-app-id' to that AppID.

;; To make a query, run `M-x wolfram-alpha' then type your query. It will show
;; the results in a buffer called `*WolframAlpha*'.

(require 'url)
(require 'xml)
(require 'url-cache)
(require 'org-faces)                    ;For `org-level-1' and `org-level-2' faces

;;; Vars:

(defgroup wolfram-alpha nil
  "Wolfram Alpha customization group"
  :group 'wolfram)

(defcustom wolfram-alpha-app-id ""
  "The Wolfram Alpha App ID."
  :group 'wolfram-alpha
  :type 'string)

(defface wolfram-query
  '((t (:inherit org-level-1)))
  "Face for the query string in the WolframAlpha buffer.")

(defface wolfram-pod-title
  '((t (:inherit org-level-2)))
  "Face for the pod titles in search results in the WolframAlpha buffer.")

(defvar wolfram-alpha-buffer-name "*WolframAlpha*"
  "Name of WolframAlpha search buffer. ")

(defvar wolfram-alpha-query-history nil
  "History for `wolfram-alpha' prompt.")

(defcustom wolfram-alpha-magnification-factor 1.0
  "Set the magnification factor.
See https://products.wolframalpha.com/api/documentation/#width-mag"
  :group 'wolfram-alpha
  :type 'number)

;;; Code:

(defun wolfram--url-for-query (query)
  "Formats a WolframAlpha API url."
  (format "https://api.wolframalpha.com/v2/query?appid=%s&input=%s&format=image,plaintext&parsetimeout=15&scantimeout=15&podtimeout=15&formattimeout=15&mag=%s"
          wolfram-alpha-app-id
          (url-hexify-string query)
          wolfram-alpha-magnification-factor))

(defun wolfram--async-xml-for-query (query callback)
  "Returns XML for a query"
  (let* ((url (wolfram--url-for-query query)))
    (when url (with-current-buffer
                  (url-retrieve url callback)))))

(defun wolfram--append-pod (pod)
  "Appends a pod to the current buffer."
  (let ((title (xml-get-attribute pod 'title))
        (err (equal "true" (xml-get-attribute pod 'error))))
    ;; First insert pod
    (insert
     (when title
       (format "\n## %s%s\n\n"
               (propertize title 'face 'wolfram-pod-title)
               (if err " *error*" ""))))
    ;; Then subpods
    (dolist (subpod (xml-get-children pod 'subpod)) (wolfram--append-subpod subpod))))

(defun wolfram--insert-image (image)
  "Inserts an image xml into the current buffer"
  (let* ((url (xml-get-attribute image 'src))
         (temp-file (make-temp-file "wolfram"))
         (data (url-retrieve-synchronously url)))
    (switch-to-buffer data)
    (goto-char (point-min))
    (search-forward "\n\n")
    (write-region (point-min) (point-max) temp-file)
    (kill-buffer)
    (wolfram--switch-to-wolfram-buffer)
    (insert (format "%s" temp-file))
    (goto-char (point-max))
    ))

(defun wolfram--append-subpod (subpod)
  "Appends a subpod to the current buffer."
  (let ((plaintext (car (xml-get-children subpod 'plaintext)))
        (image (car (xml-get-children subpod 'img))))
    (when (and plaintext image)
      (wolfram--insert-image-from-url (xml-get-attribute image 'src)))
    (when (and plaintext (not image))
      (insert (format "%s\n" (car (last plaintext)))))
    (when (and image (not plaintext))
      (wolfram--insert-image (xml-get-attribute image 'src)))
    (insert "\n")))

(defun wolfram--switch-to-wolfram-buffer ()
  "Switches to (creates if necessary) the wolfram alpha results buffer."
  (let ((buffer (get-buffer-create wolfram-alpha-buffer-name)))
    (unless (eq (current-buffer) buffer)
      (switch-to-buffer buffer))
    (special-mode)
    (when (functionp 'iimage-mode) (iimage-mode))
    buffer))

(defun wolfram--create-wolfram-buffer (query)
  "Creates the buffer to show the pods."
  (wolfram--switch-to-wolfram-buffer)
  (goto-char (point-max))
  (let ((inhibit-read-only t))
    (insert (format "\n# \"%s\" (searching)\n"
                    (propertize query 'face 'wolfram-query)))))

(defun wolfram--delete-in-progress-notification ()
  "Switch to WolframAlpha buffer and delete the \"(searching)\" notification.
That notification indicates that the search is still in progress. This function
removes that notification."
  (wolfram--switch-to-wolfram-buffer)
  (goto-char (point-max))
  (search-backward " (searching)")
  (let ((inhibit-read-only t))
    (replace-match ""))
  (goto-char (point-max)))

(defun wolfram--append-pods-to-buffer (pods)
  "Appends all pods from PODS to WolframAlpha buffer."
  (wolfram--delete-in-progress-notification)
  (let ((inhibit-read-only t))
    (dolist (pod pods)
      (wolfram--append-pod pod))
    (insert "\n")))

(defun wolfram--insert-image-from-url (url)
  "Fetches an image and inserts it in the buffer."
  (unless url (error "No URL."))
  (let ((buffer (url-retrieve-synchronously url)))
    (unwind-protect
        (let ((data (with-current-buffer buffer
                      (goto-char (point-min))
                      (search-forward "\n\n")
                      (buffer-substring (point) (point-max)))))
          (insert-image (create-image data nil t)))
      (kill-buffer buffer))))

(defun wolfram--query-callback (_args)
  "Callback function to run after XML is returned for a query."
  (let* ((data (buffer-string))
         (pods (xml-get-children
                (with-temp-buffer
                  (erase-buffer)
                  (insert data)
                  (car (xml-parse-region (point-min) (point-max))))
                'pod)))
    (if pods                         ;If at least 1 result pod was returned
        (wolfram--append-pods-to-buffer pods)
      (wolfram--delete-in-progress-notification)
      (let ((inhibit-read-only t))
        (insert (propertize "No results for your query.\n\n"
                            'face 'warning))))
    (when (fboundp 'make-separator-line) ; Emacs >= 28.1
      (let ((inhibit-read-only t))
        (insert (make-separator-line))))
    (message "")))                      ;Remove the "Contacting host:.." message

;;;###autoload
(defun wolfram-alpha (query)
  "Sends a query to Wolfram Alpha, returns the resulting data as a list of pods."
  (interactive
   (list
    (if (use-region-p)
        (buffer-substring-no-properties
         (region-beginning) (region-end))
      (read-string "Query: " nil 'wolfram-alpha-history))))
  (unless (and (bound-and-true-p wolfram-alpha-app-id)
               (not (string= "" wolfram-alpha-app-id)))
    (error "Custom variable `wolfram-alpha-app-id' not set."))
  (wolfram--create-wolfram-buffer query)
  (wolfram--async-xml-for-query query #'wolfram--query-callback))

(provide 'wolfram)
;;; wolfram.el ends here
