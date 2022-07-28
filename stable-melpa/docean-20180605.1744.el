;;; docean.el --- Interact with DigitalOcean from Emacs. -*- lexical-binding: t -*-

;; Copyright © 2014 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/docean.el
;; Package-Version: 20180605.1744
;; Package-Commit: bbe2298fd21f7876fc2d5c52a69b931ff59df979
;; Keywords: convenience
;; Version: 0.0.1
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (request "0.2.0"))

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
;;
;; > Note: `docean.el' uses the [API v2.0](https://developers.digitalocean.com/v2/) of DigitalOcean.
;;
;; `docean.el' enables an easy interaction with DigitalOcean from
;; Emacs.
;;
;;; Features:
;;  + Show list of droplets.
;;  + Perform [droplet actions].
;;  + Show actions performed by an account.
;;
;;; Usage:
;; In order to use docean.el you need to generate API key for your Digital
;; Ocean account. Go to https://cloud.digitalocean.com/settings/applications to
;; generate your API key. docean.el can find your API key in the following
;; ways:
;;
;;  + Add a `.authinfo.gpg` entry with the host set to "api.digitalocean.com"
;;  and password set to the API key.
;;  + Add `(setq docean-oauth-token "mytoken")` to your `init.el'
;;  + Set the environment variable `DO_API_TOKEN'.
;;
;; To show your droplets you can use `M-x docean-droplet-list`.
;;
;;; TODO:
;; + [ ] Handle `meta' and `links' in API responses.
;;
;; [droplet actions]: https://developers.digitalocean.com/#droplet-actions

;;; Code:

(eval-when-compile (require 'cl-lib))

(require 'json)
(require 'auth-source)
(require 'request)

(defgroup docean nil
  "Interact with digitalocean from Emacs."
  :prefix "docean-"
  :group 'applications)

(defcustom docean-oauth-token nil
  "Oauth bearer token to interact with DigitalOcean api."
  :type 'string
  :group 'docean)

;;; 200 is the max per_page allowed
(defcustom docean-default-per-page 200
  "Default `per_page' argument used in list requests."
  :type 'integer
  :group 'docean)

(defconst docean-api-baseurl "https://api.digitalocean.com/"
  "Base url for the DigitalOcean api.")

(defvar docean-debug-buffer-name "*docean-response*"
  "Buffer name used for api responses.")

(defvar docean-action-buffer-name "*docean-actions*"
  "Buffer name used for logging actions responses.")

(defvar docean-droplets-buffer-name "*docean-droplets*"
  "Buffer name used for api responses.")

(defvar docean-actions nil
  "An alist containing the information of all the droplets by account.")

(defvar docean-actions-already-fetched nil)

(defvar docean-droplets nil
  "An alist containing the information of all the droplets by account.")

(defvar docean-droplets-already-fetched nil)

(cl-defstruct (docean-action (:constructor docean-action--create))
  "A structure holding all the information of an action."
  id status type started_at completed_at resource_id resource_type region)

(defun docean--action-create (data)
  "Create a `docean-action' struct from an api response DATA."
  (apply 'docean-action--create (cl-loop for (key . value)
                                         in data
                                         append (list (intern (format ":%s" key)) value))))

(cl-defstruct (docean-droplet (:constructor docean-droplet--create))
  "A structure holding all the information of a droplet."
  id name memory vcpus disk region image size locked created_at status networks
  kernel backup_ids snapshot_ids features size_slug next_backup_window)

(defun docean--droplet-create (data)
  "Create a `docean-droplet' struct from an api response DATA."
  (apply 'docean-droplet--create
         :allow-other-keys t
         (cl-loop for (key . value)
                  in data
                  append (list (intern (format ":%s" key)) value))))

(defun docean-oauth-token ()
  "Return the configured DigitalOcean token."
  (or docean-oauth-token
      (getenv "DO_API_TOKEN") ; XXX: Used by dopy, and by extension Ansible.
      (let* ((docean-auth-info
              (car (auth-source-search :max 1
                                       :host "api.digitalocean.com"
                                       :require '(:host))))
             (docean-oauth-token-fn (getf docean-auth-info :secret)))
        (setq docean-oauth-token
              (funcall docean-oauth-token-fn))
        docean-oauth-token)
      (Error "You need to generate a personal access token.  https://cloud.digitalocean.com/settings/applications")))

(defun docean--endpoint-url (endpoint)
  "Return a DigitalOcean absolure url of an ENDPOINT."
  (let ((urlobj (url-generic-parse-url docean-api-baseurl)))
    (setf (url-filename urlobj) endpoint)
    (url-recreate-url urlobj)))

(cl-defun docean-request (endpoint
                          &key
                          (type "GET")
                          (params nil)
                          (data nil)
                          (parser 'buffer-string)
                          (error 'docean-default-callback)
                          (success 'docean-default-callback)
                          (headers nil)
                          (timeout nil)
                          (sync nil)
                          (status-code nil))
  "Process a request to a DigitalOcean api endpoint.

All the calls to the DigitalOcean api requiere to send the key."
  (let ((headers (append headers
                         `(("Content-Type" . "application/json")
                           ("Authorization". ,(format "Bearer %s" (docean-oauth-token)))))))
    (request (docean--endpoint-url endpoint)
             :type type
             :data data
             :params params
             :headers headers
             :data data
             :parser parser
             :success success
             :error error
             :timeout timeout
             :status-code status-code
             :sync sync)))

(cl-defun docean-default-callback (&key data response error-thrown &allow-other-keys)
  (with-current-buffer (get-buffer-create docean-debug-buffer-name)
    (erase-buffer)
    (when error-thrown
      (message "Error: %s" error-thrown))
    (when (stringp data)
      (insert data))
    (let ((hstart (point))
          (raw-header (request-response--raw-header response))
          (comment-start (or comment-start "//")))
      (unless (string= "" raw-header)
        (insert "\n" raw-header)
        (comment-region hstart (point))))))

(defun docean--create-droplet-item (data)
  "Create an droplet item from an response DATA."
  (cons (cdr-safe (assq 'id data))
        (docean--droplet-create data)))

(defun docean--generate-table-droplet-entry (item)
  "Return a table entry from a ITEM."
  (cl-destructuring-bind (id . droplet) item
    (list id (vector (number-to-string (docean-droplet-id droplet))
                     (docean-droplet-name droplet)
                     (docean-droplet-status droplet)
                     (if (eq (docean-droplet-locked droplet) json-false) "" "●")))))

(defun docean--generate-table-droplet-entries ()
  "Generate droplets table entries."
  (mapcar #'docean--generate-table-droplet-entry (docean-droplets)))

(cl-defun docean-action-callback (&key data &allow-other-keys)
  (let ((action (cdr (assq 'action data))))
    (message "%s action started at %s with id %s"
             (cdr-safe (assq 'type action))
             (cdr-safe (assq 'started_at action))
             (cdr-safe (assq 'id action)))))

(defun docean--droplet-action (id data)
  "Perform a post request droplet ID actions endpoint with DATA."
  (docean-request (format "/v2/droplets/%s/actions" id)
                  :type "POST"
                  :data data
                  :parser 'json-read
                  :success 'docean-action-callback))

(defun docean--read-droplet-id ()
  "Read a DigitalOcean droplet id."
  (list (if (and (eq major-mode 'docean-droplet-list-mode) (tabulated-list-get-id))
            (number-to-string (tabulated-list-get-id))
          (completing-read "droplet id: "
                           (mapcar (lambda (e) (number-to-string (car e))) (docean-droplets))
                           nil nil nil nil
                           (tabulated-list-get-id)))))

;;;###autoload
(defun docean-reboot-droplet (id)
  "Reboot a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "reboot")))))

;;;###autoload
(defun docean-power-cicle-droplet (id)
  "Power cicle a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "power_cycle")))))

;;;###autoload
(defun docean-shutdown-droplet (id)
  "Shutdown a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "shutdown")))))

;;;###autoload
(defun docean-power-off-droplet (id)
  "Power off a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "power_off")))))

;;;###autoload
(defun docean-power-on-droplet (id)
  "Reboot a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "power_on")))))

;;;###autoload
(defun docean-password-reset-droplet (id)
  "Reset password a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "password_reset")))))

;;;###autoload
(defun docean-enable-ipv6-droplet (id)
  "Enable ipv6 to a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "enable_ipv6")))))

;;;###autoload
(defun docean-disable-backups-droplet (id)
  "Disable backups a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "disable_backups")))))

;;;###autoload
(defun docean-enable-private-networking-droplet (id)
  "Enable private networking a droplet identified by ID."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode '(("type" . "enable_private_networking")))))

;;;###autoload
(defun docean-rename-droplet (id &optional name)
  "Rename a droplet with ID and NAME."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode `(("type" . "rename")
                                            ("name" . ,(or name (read-string "New droplet name: ")))))))

;;;###autoload
(defun docean-snapshot-droplet (id &optional name)
  "Snapshot a droplet with ID and NAME."
  (interactive (docean--read-droplet-id))
  (docean--droplet-action id (json-encode `(("type" . "snapshot")
                                            ("name" . ,(or name (read-string "Snapshot name: ")))))))

(defvar docean-droplet-list-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "R") #'docean-reboot-droplet)
    (define-key map (kbd "C") #'docean-power-cicle-droplet)
    (define-key map (kbd "S") #'docean-shutdown-droplet)
    (define-key map (kbd "H") #'docean-power-off-droplet)
    (define-key map (kbd "U") #'docean-power-on-droplet)
    (define-key map (kbd "P") #'docean-password-reset-droplet)
    (define-key map (kbd "I") #'docean-enable-ipv6-droplet)
    (define-key map (kbd "B") #'docean-disable-backups-droplet)
    (define-key map (kbd "N") #'docean-enable-private-networking-droplet)
    (define-key map (kbd "r") #'docean-rename-droplet)
    (define-key map (kbd "s") #'docean-snapshot-droplet)
    map)
  "Keymap for docean-droplet-list-mode.")

(define-derived-mode docean-droplet-list-mode tabulated-list-mode "Droplet list"
  "List droplets.

\\{docean-droplet-list-mode-map}"
  (setq tabulated-list-format [("id" 20 nil)
                               ("name" 15 nil)
                               ("status" 15 nil)
                               ("locked" 6 nil)])
  (add-hook 'tabulated-list-revert-hook #'docean-refetch-droplets nil t)
  (tabulated-list-init-header))

(cl-defun docean-droplets (&key
                           (page nil)
                           (per-page docean-default-per-page))
  "Fetch the available user droplets."
  (if docean-droplets-already-fetched
      docean-droplets
    (let* ((params (append (and page `((page . ,(number-to-string page))))
                           (and per-page `((per_page . ,(number-to-string per-page)))))))
      (docean-request "/v2/droplets"
                      :parser 'json-read
                      :params params
                      :success (cl-function
                                (lambda (&key data &allow-other-keys)
                                  (message "docean request complete")
                                  (setq docean-droplets-already-fetched t
                                        docean-droplets (mapcar #'docean--create-droplet-item (cdr-safe (assq 'droplets data))))
                                  (with-current-buffer (get-buffer-create docean-droplets-buffer-name)
                                    (setq tabulated-list-entries (docean--generate-table-droplet-entries))
                                    (tabulated-list-print t))))))))

;;;###autoload
(defun docean-droplet-list ()
  "Show user droplets."
  (interactive)
  (with-current-buffer (get-buffer-create docean-droplets-buffer-name)
    (docean-droplet-list-mode)
    (docean-droplets)
    (pop-to-buffer (current-buffer))))

;;;###autoload
(defun docean-refetch-droplets ()
  "Refetch droplets information."
  (interactive)
  (setq docean-droplets-already-fetched nil)
  (docean-droplets))

(define-derived-mode docean-action-list-mode tabulated-list-mode "Action list"
  "List DigitalOcean actions."
  (setq tabulated-list-format [("id" 10 nil)
                               ("status" 15 nil)
                               ("type" 15 nil)
                               ("started_at" 25 nil)
                               ("completed_at" 25 nil)
                               ("resource_id" 10 nil)
                               ("resource_type" 15 nil)
                               ("region" 10 nil)])
  (add-hook 'tabulated-list-revert-hook #'docean-refetch-actions nil t)
  (tabulated-list-init-header))

(cl-defun docean-actions (&key
                          (page nil)
                          (per-page docean-default-per-page))
  "Fetch the actions executed on the current account."
  (if docean-actions-already-fetched
      docean-actions
    (let* ((params (append (and page `((page . ,(number-to-string page))))
                           (and per-page `((per_page . ,(number-to-string per-page)))))))
      (docean-request "/v2/actions"
                      :parser 'json-read
                      :params params
                      :success (cl-function
                                (lambda (&key data &allow-other-keys)
                                  (message "docean request complete")
                                  (setq docean-actions-already-fetched t
                                        docean-actions (mapcar #'docean--create-action-item (cdr-safe (assq 'actions data))))
                                  (with-current-buffer (get-buffer-create docean-action-buffer-name)
                                    (setq tabulated-list-entries (docean--generate-table-action-entries))
                                    (tabulated-list-print t))))))))

(defun docean--create-action-item (data)
  "Create an action item from an response DATA."
  (cons (cdr-safe (assq 'id data))
        (docean--action-create data)))

(defun docean--generate-table-action-entries ()
  "Generate droplets table entries."
  (mapcar #'docean--generate-table-action-entry (docean-actions)))

(defun docean--generate-table-action-entry (item)
  "Return a table entry from a action ITEM."
  (cl-destructuring-bind (id . action) item
    (list id (vector (number-to-string (docean-action-id action))
                     (docean-action-status action)
                     (docean-action-type action)
                     (docean-action-started_at action)
                     (docean-action-completed_at action)
                     (if (numberp (docean-action-resource_id action)) (number-to-string (docean-action-resource_id action)) "")
                     (docean-action-resource_type action)
                     (or (docean-action-region action) "")))))

;;;###autoload
(defun docean-action-list ()
  "Show user actions."
  (interactive)
  (with-current-buffer (get-buffer-create docean-action-buffer-name)
    (docean-action-list-mode)
    (docean-actions)
    (pop-to-buffer (current-buffer))))

;;;###autoload
(defun docean-refetch-actions ()
  "Refetch actions information."
  (interactive)
  (setq docean-actions-already-fetched nil)
  (docean-actions))

(provide 'docean)

;;; docean.el ends here
