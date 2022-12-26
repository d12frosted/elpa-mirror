;;; digitalocean.el --- Create and manipulate digitalocean droplets -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Oliver Marks

;; Author: Oliver Marks <oly@digitaloctave.com>
;; URL: https://github.com/olymk2/emacs-digitalocean
;; Package-Version: 20190607.726
;; Package-Commit: 6c32d3593286e2a62d9afab0057c829407b0d1e8
;; Keywords: Processes tools
;; Version: 0.1
;; Created 27 May 2018
;; Package-Requires: ((request "2.5")(emacs "24.4"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implid warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This provides a set of functions for working with digitalocean droplets.
;; It wraps api v2 and allows creation and control of droplets.
;; It also attempts to build a tramp url to your containers to connect eshell


;;; Code:

(require 'request)
(require 'widget)
(require 'cl-lib)

(eval-when-compile
  (require 'wid-edit))

(defgroup digitalocean nil
  "Digitalocean customization grouping."
  :group 'convenience)

(defcustom digitalocean-default-directory "/"
  "Set the default directory when connecting to a droplet."
  :type 'string
  :group 'digitalocean)

(defun digitalocean-array-or-nil (value)
  "Helper which will return VALUE to a list or nil if empty."
  (when value (list value)))


(defun digitalocean-make-get-request (url)
  "Perform a get request on URL which auto append the header tokens."
  (unless (boundp 'digitalocean-token)
    (error "User variable digitalocean-token not set"))
  (request-response-data
   (request url
	    :parser 'json-read
	    :headers `(
		       ("Content-Type" . "application/json")
		       ("Authorization" . ,(concat "Bearer " digitalocean-token)))
	    :error
	    (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
			   (message "Digitalocean GET request errored: %S %S"
				    args error-thrown)))
	    :sync t)))

(defun digitalocean-make-post-request (url params)
  "Perform a post request on URL with PARAMS data auto append the header tokens."
  (unless (boundp 'digitalocean-token)
    (error "User variable digitalocean-token not set"))
  (request-response-data
   (request url
	    :type "POST"
            :data (json-encode params)
	    :parser 'json-read
	    :headers `(
		       ("Content-Type" . "application/json")
		       ("Authorization" . ,(concat "Bearer " digitalocean-token)))
            :success
            (cl-function (lambda ()
			   (message "Post request complete")
                           (kill-buffer "*DO Form*")))
	    :error
	    (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
			   (message "Digitalocean POST request errored: %S %S"
				    args error-thrown)))
	    :sync t)))


(defun digitalocean-fetch-droplets ()
  "Fetch droplet list endpoint."
  (digitalocean-make-get-request "https://api.digitalocean.com/v2/droplets"))

(defun digitalocean-fetch-images ()
  "Fetch image list endpoint."
  (digitalocean-make-get-request "https://api.digitalocean.com/v2/images"))

(defun digitalocean-fetch-regions ()
  "Fetch region list endpoint."
  (digitalocean-make-get-request "https://api.digitalocean.com/v2/regions"))

(defun digitalocean-fetch-sizes ()
  "Fetch instance sizes endpoint."
  (digitalocean-make-get-request "https://api.digitalocean.com/v2/sizes"))

(defun digitalocean-fetch-account-info ()
  "Fetch account info."
  (digitalocean-make-get-request "https://api.digitalocean.com/v2/account"))

(defun digitalocean-create-droplet (values)
  "Post create droplet data.
Argument VALUES y."
  (digitalocean-make-post-request "https://api.digitalocean.com/v2/droplets" values))

(defun digitalocean-exec-droplet-action (droplet-id action)
  "Give a unique DROPLET-ID Execute the given ACTION on the droplet."
  (interactive "sDroplet Id: \nsAction :")
  (digitalocean-make-post-request
   (concat "https://api.digitalocean.com/v2/droplets/" droplet-id "/actions")
   `(("type" . ,action))))

(defun digitalocean-fetch-droplet-by-id (droplet-id)
  "Return specific droplet details for DROPLET-ID."
  (interactive "sDroplet Id: ")
  (digitalocean-make-get-request
   (concat "https://api.digitalocean.com/v2/droplets/" droplet-id)))

(defun digitalocean-format-results (alist &rest keys)
  "Helper function given ALIST to return only the values matching KEYS."
  (if keys
      (string-join
       (loop for x in keys collect
	     (format "%s " (cdr (assoc x alist)))))
    (string-join
     (loop for item in alist collect
	   (format "%s " (car item))))))

(defun digitalocean-format-response (res head &rest keys)
  "Helper to filter response RES response root HEAD KEYS to match in the reponse."
  (if (consp (cdr (assoc head res)))
      ;; cons list so pass direct to format lsit
      (progn
	(cons head (apply 'digitalocean-format-results (cdr (assoc head res)) keys)))
    ;; vector array so loop over all items
    (mapcar #'(lambda (x)
		(cons
		 (apply 'digitalocean-format-results x keys)
		 x))
	    (cdr (assoc head res)))))

(defun digitalocean-format-response-lines (res head &rest keys)
  "Helper to filter RES response HEAD KEYS into cons format for helm."
  (if (consp (cdr (assoc head res)))
      ;; cons list so pass direct to format lsit
      (progn
	(list (apply 'digitalocean-format-results (cdr (assoc head res)) keys)))
    ;; vector array so loop over all items
    (mapcar #'(lambda (x)
		(apply 'digitalocean-format-results x keys))
	    (cdr (assoc head res)))))


(defun digitalocean-digitalocean-droplet-list ()
  "Return list of droplets with specific attributes."
  (digitalocean-format-response (digitalocean-fetch-droplets) 'droplets 'id 'name 'status))

(defun digitalocean-digitalocean-images-list ()
  "Return list of Image."
  (digitalocean-format-response (digitalocean-fetch-images) 'images 'name))

(defun digitalocean-digitalocean-regions-list ()
  "Return list of region slugs."
  (digitalocean-format-response (digitalocean-fetch-regions) 'regions 'slug))

(defun digitalocean-digitalocean-sizes-list ()
  "Return list of sizes."
  (digitalocean-format-response (digitalocean-fetch-sizes) 'sizes 'slug ))


(defun digitalocean-get-droplet-id-from-name-str (droplet-name)
  "Given DROPLET-NAME try and match and return a droplet id as a string."
  (number-to-string (digitalocean-get-droplet-id-from-name droplet-name)))


(defun digitalocean-get-droplet-id-from-name (droplet-name)
  "Given DROPLET-NAME try and match and return a droplet id."
   (cdr (assoc 'id
	       (cdr (assoc droplet-name
			   (digitalocean-format-response
			    (digitalocean-fetch-droplets)
                            'droplets 'name))))))

(defun digitalocean-build-ssh-path (droplet-id dir)
  "Give a DROPLET-ID and DIR build a tramp ssh path."
  (format "/ssh:root@%s:%s"
	  (digitalocean-get-droplet-ip4-from-id droplet-id) dir))

(defun digitalocean-get-droplet-ip4-from-id (droplet-id)
  "Givne a DROPLET-ID, lookup the droplet and get the ipv4 address."
  (cdr (assoc 'ip_address
	      (elt (cdr (assoc 'v4
			  (cdr (assoc 'networks
				      (cdr (assoc 'droplet
						  (digitalocean-fetch-droplet-by-id droplet-id))))))) 0))))

(defun digitalocean-launch-shell (droplet-name dir)
  "Simple shell wrapper, create a sheel using DROPLET-NAME as the buffer at DIR location."
  (let ((default-directory dir))
    (shell (concat "*do-" droplet-name "*"))))

(defun digitalocean-droplet-shell (droplet-id droplet)
  "Given a DROPLET-ID and DROPLET alist create the dir and sent to launch shell."
  (digitalocean-launch-shell
   (cdr (assoc 'name (first droplet)))
   (digitalocean-build-ssh-path droplet-id digitalocean-default-directory)))


(defun digitalocean-completing-read-friendly (msg res main key reskey)
  "Custom completing read which can handle key value completion.
Given MSG and RES response match the root key MAIN show KEY values.
match RESKEY and return the match and the dropplet response."
  (let ((match
	 (completing-read msg
			      (mapcar #'(lambda (x)
					  (cdr (assoc key x)))
				      (cdr (assoc main res))))))
    (let ((result (seq-filter
			   #'(lambda (x)
			       (if (string= (cdr (assoc key x)) match)
				   t nil))
			   (cdr (assoc main res)))))

      (list (cdr
       (assoc reskey
	      (nth 0 result)))
	    (nth 0 result)))))


(defun digitalocean-completing-read (msg res main key)
  "Custom completing read which filters an api response.
Given MSG and RES response match the root key MAIN show KEY values."
  "helper to generate user selection from api response."
  (completing-read msg
		       (mapcar #'(lambda (x)
				   (cdr (assoc key x)))
			       (cdr (assoc main res)))))

(defun digitalocean-droplet-completing-read ()
  "Completing read for droplets."
  (digitalocean-completing-read-friendly "Select Droplet: " (digitalocean-fetch-droplets) 'droplets 'name 'id))

(defun digitalocean-image-completing-read ()
  "Completing read for images."
  (digitalocean-completing-read "Select Images: " (digitalocean-fetch-images) 'images 'name))

(defun digitalocean-region-completing-read ()
  "Completing read for regions."
  (digitalocean-completing-read "Select Region: " (digitalocean-fetch-regions) 'regions 'slug))

(defun digitalocean-sizes-completing-read ()
  "Completing read for sizes."
  (digitalocean-completing-read "Select Size: " (digitalocean-fetch-sizes) 'sizes 'slug))

(defun digitalocean-align-labels (txt size)
  "Helper which will space out a string TXT to be SIZE in length."
  (let ((num (length txt)))
    (while (< num size)
      (setq txt (concat txt " "))
      (setq num (1+ num)))
    txt))

(defun digitalocean-create-droplet-form ()
  "Implements a form to create a droplet with all options."
  (interactive)
  "Create the widgets from the Widget manual."
  (switch-to-buffer "*DO Form*")
  (kill-all-local-variables)
  (let ((inhibit-read-only t))
    (erase-buffer))
  (let ((digitalocean-widgets ()))
    (widget-insert "Digitalocean droplet creation\n")
    (widget-insert (digitalocean-align-labels "\nName: " 30))
    (push
     (widget-create 'editable-field
		    :size 25
		    "droplet-name")
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nRegion: " 30))
    (push
     (widget-create 'editable-field
		    :size 25
		    "lon1")
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nSize: " 30))
    (push
     (widget-create 'editable-field
		    :size 25
		    "512mb")
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nImage: " 30))
    (push
     (widget-create 'editable-field
		    :size 25
		    "ubuntu-16-04-x64")
     digitalocean-widgets)
    
    (widget-insert "\n\nOptional fields")
    (widget-insert (digitalocean-align-labels "\nSSH Keys: " 30))
    (push
     (widget-create 'editable-field
		    :size 25
		    "")
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nBackups: " 30))
    (push
     (widget-create 'checkbox nil)
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nEnable IPV6: " 30))
    (push
     (widget-create 'checkbox t)
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nPrivate Networking: " 30))
    (push
     (widget-create 'checkbox nil)
     digitalocean-widgets)
    
    (widget-insert "\nUser data can be used to run commands at launch")
    (widget-insert (digitalocean-align-labels "\nUser Commands: " 30))
    (push
     (widget-create 'text
		    :size 25
		    "")
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nMonitoring: " 30))
    (push
     (widget-create 'checkbox t)
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nVolumes: " 30))
    (push
     (widget-create 'editable-field
		    :size 25
		    "")
     digitalocean-widgets)
    
    (widget-insert (digitalocean-align-labels "\nTags: " 30))
    (push
     (widget-create 'editable-field
		    :size 25
		    "from-emacs")
     digitalocean-widgets)
    
    (widget-insert "\n")
    (widget-create 'push-button
		   :notify (lambda (&rest ignore)
			     (let ((values `(("name" . ,(widget-value (nth 11 digitalocean-widgets)))
					     ("region" . ,(widget-value (nth 10 digitalocean-widgets)))
					     ("size" . ,(widget-value (nth 9 digitalocean-widgets)))
					     ("image" . ,(widget-value (nth 8 digitalocean-widgets)))
					     ("ssh_keys" . ,(digitalocean-array-or-nil
							     (widget-value (nth 7 digitalocean-widgets))))
					     ("backups" . ,(widget-value (nth 6 digitalocean-widgets)))
					     ("ipv6" . ,(widget-value (nth 5 digitalocean-widgets)))
					     ("private_networking" . ,(widget-value (nth 4 digitalocean-widgets)))
					     ("user_data" . ,(widget-value (nth 3 digitalocean-widgets)))
					     ("monitoring" . ,(widget-value (nth 2 digitalocean-widgets)))
					     ("volumes" . ,(digitalocean-array-or-nil
							    (widget-value (nth 1 digitalocean-widgets))))
					     ("tags" . ,(digitalocean-array-or-nil
							 (widget-value (nth 0 digitalocean-widgets)))))))
			       (message "Please wait new droplet sent for creation.")
			       (digitalocean-create-droplet values)))
		   "Create droplet")
    (widget-insert "\n")
    (use-local-map widget-keymap)
    (widget-setup)))

;;; User droplet endpoints
;;;###autoload
(defun digitalocean-droplet-open-shell ()
  "Open a shell for selected droplet."
  (interactive)
  (let ((result (digitalocean-completing-read-friendly
		 "Select Droplet: "
                 (digitalocean-fetch-droplets) 'droplets 'name 'id)))
  (digitalocean-droplet-shell
   (number-to-string (first result))
   (last result))))

;;;###autoload
(defun digitalocean-droplet-snapshot ()
  "Create a snapshot of the selected droplet."
  (interactive)
  (digitalocean-exec-droplet-action
   (number-to-string
    (car (digitalocean-completing-read-friendly
	  "Select Droplet: "
          (digitalocean-fetch-droplets) 'droplets 'name 'id)))
   "snapshot"))

;;;###autoload
(defun digitalocean-droplet-restart ()
  "Restart the selected droplet."
  (interactive)
  (digitalocean-exec-droplet-action
   (number-to-string
    (car (digitalocean-completing-read-friendly
	  "Select Droplet: "
          (digitalocean-fetch-droplets) 'droplets 'name 'id)))
   "reboot"))

;;;###autoload
(defun digitalocean-droplet-shutdown ()
  "Shutdown the selected droplet."
  (interactive)
  (digitalocean-exec-droplet-action
   (number-to-string
    (car (digitalocean-completing-read-friendly
	  "Select Droplet: "
          (digitalocean-fetch-droplets) 'droplets 'name 'id)))
   "power_off"))

;;;###autoload
(defun digitalocean-droplet-startup ()
  "Start the selected droplet."
  (interactive)
  (digitalocean-exec-droplet-action
   (number-to-string
    (car (digitalocean-completing-read-friendly
	  "Select Droplet: "
          (digitalocean-fetch-droplets) 'droplets 'name 'id)))
   "power_on"))

;;;###autoload
(defun digitalocean-droplet-destroy ()
  "Destroy the selected droplet."
  (interactive)
  (digitalocean-exec-droplet-action
   (number-to-string
    (car (digitalocean-completing-read-friendly
	  "Select Droplet: "
          (digitalocean-fetch-droplets) 'droplets 'name 'id)))
   "destroy"))

;;;###autoload
(defun digitalocean-droplet-simple-create ()
  "Create a droplet quickly using minimum inputs."
  (interactive)
  (digitalocean-create-droplet
   `(("name" . ,(read-string "Droplet name: "))
     ("region" . ,(car (digitalocean-completing-read-friendly
			"Select Region: "
                        (digitalocean-fetch-regions) 'regions 'name 'slug)))
     ("size" . ,(digitalocean-completing-read
		 "Select Size: "
                 (digitalocean-fetch-sizes) 'sizes 'slug))
     ("image" . ,(car (digitalocean-completing-read-friendly
		       "Select Image: "
                       (digitalocean-fetch-images) 'images 'name 'slug))))))


;;; (Features)
(provide 'digitalocean)
;;; digitalocean.el ends here
