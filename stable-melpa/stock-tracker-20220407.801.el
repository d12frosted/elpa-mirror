;;; stock-tracker.el --- Track stock price -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022 Huming Chen

;; Author: Huming Chen <chenhuming@gmail.com>
;; URL: https://github.com/beacoder/stock-tracker
;; Package-Version: 20220407.801
;; Package-Commit: a00beca4a1526fa85e087c9e67a981c801c4b79a
;; Version: 0.1
;; Created: 2019-08-18
;; Keywords: convenience, chinese, stock
;; Package-Requires: ((emacs "26.1") (dash "2.16.0"))

;; This file is not part of GNU Emacs.

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

;;; Commentary:
;;
;; Tool for tracking stock price in Emacs
;;
;; Below are commands you can use:
;; `stock-tracker-start'
;; Start stock-tracker and display stock information with buffer

;;; Code:
(require 'dash)
(require 'json)
(require 'org)
(require 'subr-x)
(require 'url)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customizable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup stock-tracker nil
  "Track stock price in Emacs."
  :version "0.1"
  :group 'tools)

(defcustom stock-tracker-buffer-name "*stock-tracker*"
  "Result Buffer name."
  :type 'string
  :group 'stock-tracker)

(defcustom stock-tracker-refresh-interval 1
  "Refresh stock every N * 10 SECS."
  :type 'integer
  :group 'stock-tracker)

(defcustom stock-tracker-list-of-stocks nil
  "List of stock to monitor."
  :type 'list
  :group 'stock-tracker)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Definition
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst stock-tracker--api-url
  "https://api.money.126.net/data/feed/%s"
  "Stock-Tracker API template for stocks listed in SS, SZ, HK, US.")

(defconst stock-tracker--result-prefix
  "_ntes_quote_callback("
  "Stock-Tracker result prefix.")

(defconst stock-tracker--result-header
  "|-\n| symbol | name | price | percent | updown | high | low | volume | open | yestclose |\n|-\n"
  "Stock-Tracker result header.")

(defconst stock-tracker--result-item-format
  "| %s | %s | %s | %.2f %% | %s | %s | %s | %s | %s | %.2f |\n|-\n"
  "Stock-Tracker result item format.")

(defconst stock-tracker--response-buffer "*api-response*"
  "Buffer name for error report when fail to read server response.")

(defconst stock-tracker--note-string
  "To add     stock, use `a'
To delete  stock, use `d'
To refresh stock, use `g'

Stocks listed in SH, prefix with ‘0’,   e.g: 0600000
Stocks listed in SZ, prefix with ‘1’,   e.g: 1002024
Stocks listed in HK, prefix with ‘hk0’, e.g: hk00700
Stocks listed in US, prefix with ‘US_’, e.g: US_GOOG"
  "Stock-Tracker note string.")

(defvar stock-tracker--refresh-timer nil
  "Stock-Tracker refresh timer.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; steal from ag/dwim-at-point
(defun stock-tracker--dwim-at-point ()
  "If there's an active selection, return that.
Otherwise, get the symbol at point, as a string."
  (cond ((use-region-p)
         (buffer-substring-no-properties (region-beginning) (region-end)))
        ((symbol-at-point)
         (substring-no-properties
          (symbol-name (symbol-at-point))))))

;;; improved version, based on ag/read-from-minibuffer
(defun stock-tracker--read-from-minibuffer (prompt)
  "Read a value from the minibuffer with PROMPT.
If there's a string at point, use it instead of prompt."
  (let* ((suggested (stock-tracker--dwim-at-point))
         (final-prompt
          (if suggested (format "%s (default %s): " prompt suggested)
            (format "%s: " prompt))))
    (if (or current-prefix-arg (string= "" suggested) (not suggested))
        (read-from-minibuffer final-prompt nil nil nil nil suggested)
      suggested)))

(defun stock-tracker--align-all-tables ()
  "Align all org tables."
  (org-table-map-tables 'org-table-align t))

;;; @see https://www.emacswiki.org/emacs/AddCommasToNumbers
(defun stock-tracker--add-number-grouping (number &optional separator)
  "Add commas to NUMBER and return it as a string.
Optional SEPARATOR is the string to use to separate groups.
It defaults to a comma."
  (let ((num (number-to-string number))
        (op (or separator ",")))
    (while (string-match "\\(.*[0-9]\\)\\([0-9][0-9][0-9].*\\)" num)
      (setq num (concat
                 (match-string 1 num) op
                 (match-string 2 num))))
    num))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; @see copied from anaconda-mode-create-response-handler
(defun stock-tracker--create-response-handler (callback)
  "Create server response handler based on CALLBACK function for STOCK."
  (let ((request-point (point))
        (request-buffer (current-buffer))
        (request-window (selected-window))
        (request-tick (buffer-chars-modified-tick)))
    (lambda (status)
      (let ((http-buffer (current-buffer)))
        (unwind-protect
            (if (or (not (equal request-window (selected-window)))
                    (with-current-buffer (window-buffer request-window)
                      (or (not (equal request-buffer (current-buffer)))
                          (not (equal request-point (point)))
                          (not (equal request-tick (buffer-chars-modified-tick))))))
                nil
              (if (not (string-match "200 OK" (buffer-string)))
                  (message "Problem connecting to the server")
                (let ((response
                       (condition-case nil
                           (progn
                             (set-buffer-multibyte t)
                             (re-search-forward stock-tracker--result-prefix nil 'move)
                             (json-read-from-string (buffer-substring-no-properties (point) (point-max))))
                         (error ;; output error-response to error-buffer
                          (let ((response
                                 (concat (format "# status: %s\n# point: %s\n" status (point)) (buffer-string))))
                            (with-current-buffer (get-buffer-create stock-tracker--response-buffer)
                              (erase-buffer)
                              (insert response)
                              (goto-char (point-min)))
                            nil)))))
                  (if (null response)
                      (message "Cannot read server response")
                    (with-current-buffer request-buffer
                      ;; Terminate `apply' call with empty list so response
                      ;; will be treated as single argument.
                      (apply callback response nil))))))
          (kill-buffer http-buffer))))))

(defun stock-tracker--format-request-url (stock)
  "Format STOCK as a HTTP request URL."
  (format stock-tracker--api-url (url-hexify-string stock)))

(defun stock-tracker--request (stock callback)
  "Perform api call for STOCK.
Apply CALLBACK to the call result when retrieve it."
  (ignore-errors
    (url-retrieve
     (stock-tracker--format-request-url stock)
     (stock-tracker--create-response-handler callback)
     nil
     t)))

(defun stock-tracker--request-synchronously (stock)
  "Request STOCK synchronously, return a list of JSON each as alist if successes."
  (let (jsons)
    (with-current-buffer
        (url-retrieve-synchronously
         (stock-tracker--format-request-url stock) t nil 5)
      (set-buffer-multibyte t)
      (goto-char (point-min))
      (if (not (string-match "200 OK" (buffer-string)))
          (message "Problem connecting to the server")
        (re-search-forward stock-tracker--result-prefix nil 'move)
        (setq jsons
              (json-read-from-string (buffer-substring-no-properties (point) (point-max)))))
      (kill-current-buffer))
    jsons))

(defun stock-tracker--format-response (response)
  "Format stock information from RESPONSE."
  (let ((jsons response)
        (result "") result-list code
        symbol name price percent updown
        high low volume open yestclose)
    (dolist (json jsons)
      (setq
       code      (symbol-name (car json))
       json      (cdr json)
       symbol    (assoc-default 'symbol    json)
       name      (assoc-default 'name      json) ; chinese-word failed to align
       price     (assoc-default 'price     json)
       percent   (assoc-default 'percent   json)
       updown    (assoc-default 'updown    json)
       open      (assoc-default 'open      json)
       yestclose (assoc-default 'yestclose json)
       high      (assoc-default 'high      json)
       low       (assoc-default 'low       json)
       volume    (assoc-default 'volume    json))

      ;; construct data for display
      (when symbol
        (push
         (propertize
          (format stock-tracker--result-item-format symbol name price (* 100 percent) updown
                  high low (stock-tracker--add-number-grouping volume ",") open yestclose)
          'stock-code code)
         result-list)))
    (when result-list
      (setq result (mapconcat #'identity (reverse result-list) "")))
    result))

(defun stock-tracker--refresh-content (stocks-info)
  "Refresh stocks with STOCKS-INFO."
  (when stocks-info
    (with-current-buffer (get-buffer-create stock-tracker-buffer-name)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (stock-tracker-mode)
        (insert (format "%s\n\n" (concat "Refresh list of stocks at: " (current-time-string))))
        (insert (format "%s\n\n" stock-tracker--note-string))
        (insert stock-tracker--result-header)
        (insert stocks-info)
        (stock-tracker--align-all-tables)))))

(defun stock-tracker--refresh-callback (response)
  "Refresh stocks with data from RESPONSE."
  (when-let* (response
              (stocks-info (stock-tracker--format-response response)))
    (stock-tracker--refresh-content stocks-info)))

(defun stock-tracker--refresh (&optional asynchronously)
  "Refresh list of stocks ASYNCHRONOUSLY or not."
  (when-let* ((has-stocks stock-tracker-list-of-stocks)
              (valid-stocks (delq nil (delete-dups has-stocks)))
              (stocks-string (mapconcat #'identity valid-stocks ",")))
    (if asynchronously
        (stock-tracker--request stocks-string 'stock-tracker--refresh-callback)
      (stock-tracker--refresh-content
       (stock-tracker--format-response (stock-tracker--request-synchronously stocks-string))))))

(defun stock-tracker--run-refresh-timer ()
  "Run stock tracker refresh timer."
  (setq stock-tracker--refresh-timer
        (run-with-timer (* 10 stock-tracker-refresh-interval)
                        (* 10 stock-tracker-refresh-interval)
                        'stock-tracker--refresh
                        t)))

(defun stock-tracker--cancel-refresh-timer ()
  "Cancel stock tracker refresh timer."
  (when stock-tracker--refresh-timer
    (cancel-timer stock-tracker--refresh-timer)
    (setq stock-tracker--refresh-timer nil)))

(defun stock-tracker--cancel-timer-on-exit ()
  "Cancel timer when stock tracker buffer is being killed."
  (when (eq major-mode 'stock-tracker-mode)
    (stock-tracker--cancel-refresh-timer)))

(defun stock-tracker--search (stock)
  "Search STOCK and show result in `stock-tracker-buffer-name' buffer."
  (when (and stock (not (string= "" stock)))
    (with-current-buffer (get-buffer-create stock-tracker-buffer-name)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (stock-tracker-mode)
        (insert stock-tracker--result-header)
        (insert (stock-tracker--format-response (stock-tracker--request-synchronously stock)))
        (stock-tracker--align-all-tables)))))

;;;###autoload
(defun stock-tracker-start (&optional stock)
  "Start stock-tracker, search STOCK and show result in `stock-tracker-buffer-name' buffer."
  (interactive
   (unless stock-tracker-list-of-stocks
     (let ((string (stock-tracker--read-from-minibuffer "stock? ")))
       (list (format "%s" string)))))
  (if stock-tracker-list-of-stocks
      (progn
        (stock-tracker--refresh)
        (stock-tracker--cancel-refresh-timer)
        (stock-tracker--run-refresh-timer))
    (and stock (stock-tracker--search stock)))
  (unless (get-buffer-window stock-tracker-buffer-name)
    (switch-to-buffer-other-window stock-tracker-buffer-name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun stock-tracker-add-stock ()
  "Add new stock in table."
  (interactive)
  (let ((orgin-read-only buffer-read-only)
        (stock (format "%s" (read-from-minibuffer "stock? "))))
    (when-let* ((is-valid-stock (not (string= "" stock)))
                (is-not-duplicate (not (member stock stock-tracker-list-of-stocks)))
                (recved-stocks-info
                 (stock-tracker--format-response (stock-tracker--request-synchronously stock)))
                (success (not (string= "" recved-stocks-info))))
      (read-only-mode -1)
      (insert recved-stocks-info)
      (stock-tracker--align-all-tables)
      (setq stock-tracker-list-of-stocks (reverse stock-tracker-list-of-stocks))
      (push stock stock-tracker-list-of-stocks)
      (setq stock-tracker-list-of-stocks (reverse stock-tracker-list-of-stocks)))
    (when orgin-read-only (read-only-mode 1))
    (stock-tracker--refresh)))

(defun stock-tracker-remove-stock ()
  "Remove STOCK from table."
  (interactive)
  (save-mark-and-excursion
    (let ((orgin-read-only buffer-read-only)
          end-of-line-pos)
      (end-of-line)
      (setq end-of-line-pos (point))
      (beginning-of-line)
      (while (and (< (point) end-of-line-pos)
                  (not (get-text-property (point) 'stock-code)))
        (forward-char))
      (when-let (stock-code (get-text-property (point) 'stock-code))
        (read-only-mode -1)
        (org-table-kill-row)
        (setq stock-tracker-list-of-stocks
              (delete stock-code stock-tracker-list-of-stocks)))
      (when orgin-read-only (read-only-mode 1))
      (stock-tracker--refresh))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar stock-tracker-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "q") 'quit-window)
    (define-key map (kbd "p") 'previous-line)
    (define-key map (kbd "n") 'next-line)
    (define-key map (kbd "a") 'stock-tracker-add-stock)
    (define-key map (kbd "d") 'stock-tracker-remove-stock)
    (define-key map (kbd "g") 'stock-tracker-start)
    map)
  "Keymap for `stock-tracker' major mode.")

;;;###autoload
(define-derived-mode stock-tracker-mode org-mode "stock-tracker"
  "Major mode for viewing Stock-Tracker result.
\\{stock-tracker-mode-map}"
  :group 'stock-tracker
  (buffer-disable-undo)
  (setq truncate-lines t
        buffer-read-only t
        show-trailing-whitespace nil)
  (setq-local line-move-visual t)
  (setq-local view-read-only nil)
  (add-hook 'kill-buffer-hook #'stock-tracker--cancel-timer-on-exit)
  (run-mode-hooks))


(provide 'stock-tracker)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; stock-tracker.el ends here
