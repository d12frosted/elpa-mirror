;;; hyperkitty.el --- Emacs interface for Hyperkitty archives -*- lexical-binding: t; -*-

;; Copyright (c) 2020 Abhilash Raj
;;
;; Author: Abhilash Raj <maxking@asynchronous.in>
;; URL: https://github.com/maxking/hyperkitty.el
;; Package-Version: 20200927.106
;; Package-Commit: ad65766fee2675bf123491544707b056b89b52ce
;; Version: 0.0.1
;; Keywords: mail hyperkitty mailman
;; Package-Requires: ((request "0.3.2") (emacs "25.1"))
;; Prefix: hyperkitty
;; Separator: -

;; SPDX-License-Identifier: Apache-2.0

;;; License: Apache-2.0


;;; Commentary:
;;
;; This package provides an Emacs interface for reading Mailman 3 archives
;; hosted via Hyperkitty.
;;
;; To use it, you need to set `hyperkitty-mlists' variable to a list of pairs
;; of Mailinglist and base url for the hyperkitty's hosted instance.  For
;; example:
;;
;;     (setq
;;        hyperkitty-mlists
;;        ((cons "test@mailman3.org" "https://lists.mailman3.org/archives")))
;;
;; Then, you can simply use `M-x hyperkitty' to start using.

;;; Code:

(require 'cl-lib)
(require 'request)
(require 'outline)

(setf debug-on-error t)
(setf lexical-binding t)

(defvar hyperkitty-mlists nil
  "A list of MailingLists configured for the current instance.
Each entry in this list is a tuple, one the posting address for
the MailingList and other is the Base URL of the server.
For example:

    (setq
        hyperkitty-mlists
        ((\"test@mailman3.org\" . \"https://lists.mailman3.org/archives\")))")


;;; HTTP fetch utilities.
(defun hyperkitty--get-json (url success-func)
  "Call the given `URL' and call provided call function on success.
We currently don't have a good error handling.
Argument URL to fetch json response for.
Argument SUCCESS-FUNC Response handler for the json from URL."
  (request
   url
   :parser 'json-read
   :success
   (cl-function (lambda (&key response &allow-other-keys)
                  (funcall success-func response)))))


(defun hyperkitty--get-response-entries (response)
  "Get entries from the paginated response.
Argument RESPONSE HTTP response to get object entries from."
  (assoc-default 'results (request-response-data response)))


;;; Test function to print all the mailing list.
(defun hyperkitty-print-mailinglist-response (response)
  "Print each element MailingLists from the RESPONSE.
Handler for HTTP response for all the lists API.  It simply prints
the list of MailingList."
  (with-current-buffer "*scratch*"
    (insert (format "URL: %s, Status: %s, Data: %s"
                    (request-response-url response)
                    (request-response-status-code response)
                    (mapcar #'hyperkitty--print-mailinglist (hyperkitty--get-response-entries response))))))


(defun hyperkitty--print-mailinglist (mlist)
  "Get an association lists and prints the details to buffer.
Argument MLIST the mailinglist object from the API to print."
  (format "\nName: %s \nAddress: %s \nDescription: %s \n"
          (assoc-default 'display_name mlist)
          (assoc-default 'name mlist)
          (assoc-default 'description mlist)))


(defun hyperkitty--choose-mailinglist ()
  "Ask user to choose a Mailinglist from the /lists API."
  (funcall
   completing-read-function
   "Select from list: "
   hyperkitty-mlists))


(defun hyperkitty--choose-mailinglist-and-get-threads ()
  "Choose mailinglist and get their threads."
  (let* ((mlist (hyperkitty--choose-mailinglist))
         (base-url (assoc-default mlist hyperkitty-mlists))
         (threads-url (hyperkitty-threads-url base-url mlist)))
    (hyperkitty--get-json threads-url (apply-partially #'hyperkitty--print-threads-table mlist base-url))))


;;;###autoload
(defun hyperkitty ()
  "This is the primary entrypoint to hyperkitty.el.
It fetches the Hyperkitty API from the `hyperkitty-base-url'
variable and let's user choose one of the mailing list and then
opens a new buffer with a list of threads for that MailingList."
  (interactive)
  (hyperkitty--choose-mailinglist-and-get-threads))

;; threads related.

(defvar hyperkitty-page-size 25
  "Page size for Hyperkitty's pagination.
This affects how is this package able to recoginize if there are
more threads and print the [More Threads] button.")

;; Keyboard map for hyperkitty-threads-mode.
(defvar hyperkitty-threads-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<RET>") #'hyperkitty--get-thread-emails)
    map)
  "Keymap for 'hyperkitty-threads-mode-map'.")


(define-derived-mode hyperkitty-threads-mode tabulated-list-mode "hyperkitty-threads-mode"
  "Major mode for MailingList threads.
It presents a list of threads in a tabular format with three
columns, Subject, Reply and Last Active date.
"
  (setq tabulated-list-format [("Subject" 80 nil)
                               ("Reply" 5 nil)
                               ("Last Active" 15 t)])
  (setq tabulated-list-sort-key (cons "Last Active" t))
  (tabulated-list-init-header))


(defvar hyperkitty-page-num nil
  "Current page number in the threads page.")

(defvar hyperkitty-current-mlist nil
  "Current mailinglist in the threads page.")

(defvar hyperkitty-current-threadurl nil
  "Thread id of the current thread.")

(defvar hyperkitty-base-url nil
  "Base URL of Hyperkitty hosting the `current-mmlist' mailinglist.")

(defun hyperkitty--print-threads-table (mlist base-url response)
  "Print the whole threads table for a given MailingList.
Create a new buffer, named after the MailingList and switch to
`hyperkitty-threads-mode'.  Finally, display all the threads from the RESPONSE.
Argument MLIST Posting address for the MailingList.
Argument BASE-URL base-url for the hyperkitty instance.
Argument RESPONSE HTTP response for MLIST's threads."
  (interactive)
  (pop-to-buffer (format "*%s*" mlist) nil)
  (hyperkitty-threads-mode)
  (setq hyperkitty-page-num 1
        hyperkitty-current-mlist mlist
        hyperkitty-base-url base-url
        tabulated-list-entries (hyperkitty--get-threads-response-with-more-button response))
  (tabulated-list-print t))


(defun hyperkitty--get-threads-response (response)
  "Given a HTTP RESPONSE, return a list that tablulated-list-mode.
It expects data in the form of:
\(<thread-url> [(<subject> <date>)
               (<subject2> <date2>)
               ...])

It also expects the list to be paginated with simple
PageNumberPagination from Django Rest Framework.
Argument RESPONSE HTTP json response to get threads from."
  (mapcar (lambda (arg) (list (assoc-default 'url arg)
                              (vector (assoc-default 'subject arg)
                                      (number-to-string (assoc-default 'replies_count arg))
                                      (assoc-default 'date_active arg))))
          (hyperkitty--get-response-entries response)))



(defun hyperkitty--get-threads-response-with-more-button (response)
  "Get the list of threads from the response.
Also, add a [More Threads] button in the last line.
Argument RESPONSE HTTP json response for threads."
  (let ((threads (hyperkitty--get-threads-response response)))
    (message "Length of threads is: %s and page-size is: %s" (length threads) hyperkitty-page-size)
    (if (= (length threads) hyperkitty-page-size)
        (cons
         (list "more-threads"
               (vector
                (cons
                 "[More Threads]"
                 (list 'action #'hyperkitty--button-fetch-more-threads
                       'type 'hyperkitty-more-threads-button )) "" ""))
         threads)
      threads)))


(defun hyperkitty--button-fetch-more-threads (_button)
  "Get more threads for the current thread.
Argument BUTTON The button which this is a handler for."
  (setq hyperkitty-page-num (1+ hyperkitty-page-num))
  (let ((threads-url (hyperkitty-threads-url hyperkitty-base-url hyperkitty-current-mlist hyperkitty-page-num)))
    (hyperkitty--get-json threads-url #'hyperkitty--update-threads)))


(defun hyperkitty--update-threads (response)
  "Handler for [More Threads] button in threads view.
Argument RESPONSE for the json response for more threads."
  (setq tabulated-list-entries (append tabulated-list-entries (hyperkitty--get-threads-response response)))
  (tabulated-list-print t))

(define-button-type 'hyperkitty-more-threads-button
  'action #'hyperkitty--button-fetch-more-threads
  'follow-link t
  'help-echo "Fetch More threads"
  'help-args "Get more threads.")

;; message stuff.
(defun hyperkitty--get-thread-emails ()
  "Get Emails for the thread of current line."
  (interactive)
  (hyperkitty--get-json
   (hyperkitty-thread-emails-url (tabulated-list-get-id))
   (apply-partially
    #'hyperkitty--print-emails-response (elt (tabulated-list-get-entry) 0) (tabulated-list-get-id))))


(defun hyperkitty--print-emails-response (subject threads-url response)
  "Print all the Emails of a thread in a new Buffer.
Create a new buffer, named after the SUBJECT of the email and
print all the emails in that new buffer.  Each Email's content is
fetched individual since the entries only contain the metadata
about the Email.
Argument RESPONSE HTTP response to print in the current buffer.
Argument THREADS-URL API url for the current thread."
  (pop-to-buffer (format "*%s*" subject))
  (erase-buffer)
  (read-only-mode)
  (hyperkitty-emails-mode)
  (setq outline-regexp "From: "
        hyperkitty-current-threadurl threads-url)
  (let ((inhibit-read-only t))
    (insert (propertize
             (format "%s\n" subject)
             'font-lock-face 'bold
             'height 200)))
  (mapcar #'hyperkitty--print-email (reverse (hyperkitty--get-response-entries response))))

(defun hyperkitty--print-email (email)
  "Fetch and print a single EMAIL to the current buffer.
Given a metadata object for Email, fetch the actual contents of
the Email and print it to the current buffer."
  (hyperkitty--get-json
   (assoc-default 'url email)
   (lambda (response)
     (let ((anemail (request-response-data response))
           (inhibit-read-only t))
       (insert (hyperkitty--print-email-headers anemail))
       (hyperkitty--maybe-print-email-attachments anemail)
       (hyperkitty--reply-button email)
       ;; Insert some space between the two buttons.
       (insert "    ")
       (hyperkitty--open-browser-button email)
       (insert (format "\n%s\n\n" (assoc-default 'content anemail))))
     (outline-hide-entry))))


(defun hyperkitty--reply-button (email)
  "Print a reply button with mailto: link for the `EMAIL'."
  (insert-button
   "[Reply]"
   'action (apply-partially
            #'hyperkitty--attachments
            (format "mailto:%s?subject=%s&In-Reply-To=<%s>"
                    hyperkitty-current-mlist
                    (assoc-default 'subject email)
                    (assoc-default 'message_id email)))))


(defun hyperkitty--open-browser-button (email)
  "Print a reply button with mailto: link for the `EMAIL'."
  (insert-button
   "[Open in browser]"
   'action (apply-partially
            #'hyperkitty--open-message email)))


(defun hyperkitty--open-message (email _button)
  "Open the `EMAIL' in browser."
  (browse-url (format "%s/list/%s/message/%s"
                      hyperkitty-base-url
                      hyperkitty-current-mlist
                      (assoc-default 'message_id_hash email))))


(defun hyperkitty--print-email-headers (anemail)
  "Print ANEMAIL's headers in the current buffer."
  (format
   "From: %s <%s>\nMessage-ID: %s\nSubject: %s\nDate: %s:\n"
   (assoc-default 'sender_name anemail)
   (assoc-default 'address (assoc-default 'sender anemail))
   (assoc-default 'message_id anemail)
   (assoc-default 'subject anemail)
   (assoc-default 'date anemail)))

(defun hyperkitty--maybe-print-email-attachments (anemail)
  "If ANEMAIL has attachments, print them as clickable text."
  (let ((attachments (assoc-default 'attachments anemail)))
    (when (> (length attachments) 0)
          (insert "Attachments: ")
          (mapc
           (lambda (arg)
             (insert-button
              (format "%s(%sKB)" (assoc-default 'name arg) (assoc-default 'size arg))
              'action (apply-partially #'hyperkitty--attachments (assoc-default 'download arg)))
             (insert " "))
           attachments)
          (insert "\n"))))


(defun hyperkitty--attachments (url _button)
  "Fetch the attachments in a browser.
This exists as a separate function so that we can use
`apply-partially' to create a function that acts like a click
handler.  Using this in a lambda function would evaluate it before
we want it to be evaluated.
Argument URL URL to open in browser.
Argument BUTTON Button object for this handler."
  (browse-url url))


(defvar hyperkitty-emails-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<RET>") #'hyperkitty-outline-toggle)
    (define-key map (kbd "TAB") #'hyperkitty-outline-toggle)
    (define-key map (kbd "q") #'kill-buffer-and-window)
    (define-key map (kbd "o") #'hyperkitty-open-thread-in-browser)
    map)
  "Keymap for 'hyperkitty-thread-emails-mode'.")

(define-derived-mode hyperkitty-emails-mode outline-mode "hyperkitty-emails-mode"
  "Minor mode to simulate buffer local keybindings."
  (setq font-lock-defaults '(hyperkitty-email-highlights)))


(defun hyperkitty-outline-toggle ()
  "Show/Hide the current outline entry we are on."
  (interactive)
  (if (outline-invisible-p (line-end-position))
      (outline-show-entry)
    (outline-hide-entry)))

(defun hyperkitty-open-thread-in-browser ()
  "Open the current thread in browser."
  (interactive)
  (browse-url (hyperkitty-get-weburl-from-apiurl hyperkitty-current-threadurl)))


(defun hyperkitty-get-weburl-from-apiurl (apiurl)
  "Convert the `APIURL' to web url for HTML page to open in browser."
  (replace-regexp-in-string "/api/" "/" apiurl))


(defvar hyperkitty-email-highlights
  '(("From:\\|Date:\\|Subject:\\|Message-ID:\\|Attachments:" . font-lock-keyword-face)
    (">.*" . font-lock-comment-face))
  "Regex to highlight words in email headers.")

;; url stuff.
(defun hyperkitty-lists-url (base-url)
  "Get a list of all MailingLists from API.
Currently, this does not handle pagination and simply returns the
default URL without pagination.
Argument BASE-URL Base URL for Hyperkitty instnace."
  (concat base-url "/api/lists/"))

(defun hyperkitty-threads-url (base-url mlist &optional page)
  "Get a list of all threads for a MailingList.
Currently, this does not handle pagination and simply returns the
default URL without pagination.
Argument BASE-URL Base URL for hyperkitty instance.
Argument MLIST MailingList's posting address.
Optional argument PAGE The page number for the paginated response."
  (let ((thread-url (concat base-url "/api/list/" mlist "/threads")))
    (if page
        (concat thread-url (format "?page=%s" page))
      thread-url)))

(defun hyperkitty-thread-emails-url (threads-url)
  "Get all emails for the given thread URL.
This does not handle pagination currently.
Argument THREADS-URL URL to the current thread."
  (concat threads-url "/emails"))


(defun hyperkitty-get-base-url ()
  "Prompt User to get the base URL for hyperkitty."
  (read-string "Enter Hyperkitty URL: "))


;; caching utilities.


(provide 'hyperkitty)

;;; hyperkitty.el ends here
