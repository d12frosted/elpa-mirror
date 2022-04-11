;;; stock-tracker.el --- Track stock price -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022 Huming Chen

;; Author: Huming Chen <chenhuming@gmail.com>
;; URL: https://github.com/beacoder/stock-tracker
;; Package-Version: 20220411.7
;; Package-Commit: 76e15e4b8bcb08fcae8a669e1ae8df81d0f88fdb
;; Version: 0.1.2
;; Created: 2019-08-18
;; Keywords: convenience, chinese, stock
;; Package-Requires: ((emacs "27.1") (dash "2.16.0") (async "1.9.5"))

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

;;; Change Log:
;;
;; 0.1.1 Removed asynchronous handling to make logic simpler
;;       Added "quote.cnbc.com" api to get US stock information
;;       Remove HK stock, as no available api for now
;;
;; 0.1.2 Support asynchronous stock fetching with async
;;

;;; Code:

(require 'async)
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
;; Interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(cl-defstruct stock-tracker--chn-symbol)

(cl-defstruct stock-tracker--us-symbol)

(cl-defgeneric stock-tracker--api-url (object)
  "Stock-Tracker API template for stocks listed in SS, SZ, HK, US basd on OBJECT.")

(cl-defmethod stock-tracker--api-url ((s stock-tracker--chn-symbol))
  "API to get stock for S from CHN."
  "https://api.money.126.net/data/feed/%s")

(cl-defmethod stock-tracker--api-url ((s stock-tracker--us-symbol))
  "API to get stock for S from US."
  "https://quote.cnbc.com/quote-html-webservice/quote.htm?partnerId=2&requestMethod=quick&exthrs=1&noform=1&fund=1&extendedMask=2&output=json&symbols=%s")

(cl-defgeneric stock-tracker--result-prefix (object)
  "Stock-Tracker result prefix based on OBJECT.")

(cl-defmethod stock-tracker--result-prefix ((s stock-tracker--chn-symbol))
  "Stock-Tracker result prefix for S from CHN."
  "_ntes_quote_callback(")

(cl-defmethod stock-tracker--result-prefix ((s stock-tracker--us-symbol))
  "Stock-Tracker result prefix for S from US."
  "{\"QuickQuoteResult\":{\"xmlns\":\"http://quote.cnbc.com/services/MultiQuote/2006\",\"QuickQuote\":")

(cl-defgeneric stock-tracker--result-fields (object)
  "Stock-Tracker result fields based on OBJECT.")

(cl-defmethod stock-tracker--result-fields ((s stock-tracker--chn-symbol))
  "Stock-Tracker result fields for S from CHN."
  '((symbol . symbol)
    (name . name)
    (price . price)
    (percent . percent)
    (updown . updown)
    (open . open)
    (yestclose . yestclose)
    (high . high)
    (low . low)
    (volume . volume)))

(cl-defmethod stock-tracker--result-fields ((s stock-tracker--us-symbol))
  "Stock-Tracker result fields for S from US."
  '((symbol . symbol)
    (name . name)
    (price . last)
    (percent . change_pct)
    (updown . change)
    (open . open)
    (yestclose . previous_day_closing)
    (high . high)
    (low . low)
    (volume . fullVolume)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Definition
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst stock-tracker--result-header
  "|-\n| symbol | name | price | percent | updown | high | low | volume | open | yestclose |\n|-\n"
  "Stock-Tracker result header.")

(defconst stock-tracker--result-item-format
  "| %s | %s | %s | %.2f %% | %s | %s | %s | %s | %s | %.2f |\n|-\n"
  "Stock-Tracker result item format.")

(defconst stock-tracker--response-buffer "*api-response*"
  "Buffer name for error report when fail to read server response.")

(defconst stock-tracker--note-string
  "** To add     stock, use [ *a* ]
** To remove  stock, use [ *d* ]
** To refresh stock, use [ *g* ]

** Stocks listed in SH, prefix with [ *0* ], e.g: 0600000
** Stocks listed in SZ, prefix with [ *1* ], e.g: 1002024
** Stocks listed in US,                    e.g: GOOG
"
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

(defun stock-tracker--get-us-stocks (stocks)
  "Separate chn stock from us stock with `STOCKS'."
  (let ((us-stocks nil))
    (dolist (stock stocks)
      (when (zerop (string-to-number stock))
        (push stock us-stocks)))
    (setq us-stocks (reverse us-stocks))))

(defun stock-tracker--get-chn-stocks (stocks)
  "Separate chn stock from us stock with `STOCKS'."
  (let ((chn-stocks nil))
    (dolist (stock stocks)
      (unless (zerop (string-to-number stock))
        (push stock chn-stocks)))
    (setq chn-stocks (reverse chn-stocks))))

(defun stock-tracker--list-to-string (string-list separter)
  "Concat STRING-LIST to a string with SEPARTER."
  (mapconcat #'identity string-list separter))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun stock-tracker--format-request-url (stock tag)
  "Format STOCK with TAG as a HTTP request URL."
  (format (stock-tracker--api-url tag) (url-hexify-string stock)))

(defun stock-tracker--request-synchronously (stock tag)
  "Request STOCK with TAG synchronously, return a list of JSON each as alist if successes."
  (let (jsons)
    (with-current-buffer
        (url-retrieve-synchronously
         (stock-tracker--format-request-url stock tag) t nil 5)
      (set-buffer-multibyte t)
      (goto-char (point-min))
      (when (string-match "200 OK" (buffer-string))
        (re-search-forward (stock-tracker--result-prefix tag) nil 'move)
        (setq
         jsons
         (json-read-from-string (buffer-substring-no-properties (point) (point-max)))))
      (kill-current-buffer))
    jsons))

(defun stock-tracker--format-response-async (response tag)
  "Format stock information from RESPONSE with TAG."
  (let ((jsons response)
        (result-filds (stock-tracker--result-fields tag))
        (result "") result-list
        symbol name price percent updown
        high low volume open yestclose)
    (catch 'break
      (when (cl-typep tag 'stock-tracker--chn-symbol)
        (setq jsons (car jsons)))
      (dolist (json jsons)
        (if (cl-typep tag 'stock-tracker--chn-symbol)
            (setq json (cdr json))

          ;; for us-stock, there's only one stock data here
          (setq json jsons))
        (setq
         symbol    (assoc-default (map-elt result-filds 'symbol)    json)
         name      (assoc-default (map-elt result-filds 'name)      json) ; chinese-word failed to align
         price     (assoc-default (map-elt result-filds 'price)     json)
         percent   (assoc-default (map-elt result-filds 'percent)   json)
         updown    (assoc-default (map-elt result-filds 'updown)    json)
         open      (assoc-default (map-elt result-filds 'open)      json)
         yestclose (assoc-default (map-elt result-filds 'yestclose) json)
         high      (assoc-default (map-elt result-filds 'high)      json)
         low       (assoc-default (map-elt result-filds 'low)       json)
         volume    (assoc-default (map-elt result-filds 'volume)    json))

        ;; sanity check
        (unless (and symbol name price percent updown open yestclose high low volume)
          (with-temp-message "Invalid data received !!!"
            (sit-for 1))
          (throw 'break 0))

        ;; formating
        (when (stringp percent)
          (setq percent (string-to-number percent)))
        (when (stringp volume)
          (setq volume (string-to-number volume)))
        (when (stringp yestclose)
          (setq yestclose (string-to-number yestclose)))

        ;; some extra handling
        (when (cl-typep tag 'stock-tracker--chn-symbol)
          (setq percent (* 100 percent)))

        ;; construct data for display
        (when symbol
          (push
           (propertize
            (format stock-tracker--result-item-format symbol name price percent updown
                    high low (stock-tracker--add-number-grouping volume ",") open yestclose)
            'stock-code symbol)
           result-list))

        ;; for us-stock, there's only one stock data here
        (unless (cl-typep tag 'stock-tracker--chn-symbol)
          (throw 'break t))))
    (when result-list
      (setq result (stock-tracker--list-to-string (reverse result-list) "")))
    result))

(defun stock-tracker--format-response (response tag)
  "Format stock information from RESPONSE with TAG."
  (let ((jsons response)
        (result-filds (stock-tracker--result-fields tag))
        (result "") result-list
        symbol name price percent updown
        high low volume open yestclose)
    (catch 'break
      (dolist (json jsons)
        (if (cl-typep tag 'stock-tracker--chn-symbol)
            (setq json (cdr json))

          ;; for us-stock, there's only one stock data here
          (setq json jsons))
        (setq
         symbol    (assoc-default (map-elt result-filds 'symbol)    json)
         name      (assoc-default (map-elt result-filds 'name)      json) ; chinese-word failed to align
         price     (assoc-default (map-elt result-filds 'price)     json)
         percent   (assoc-default (map-elt result-filds 'percent)   json)
         updown    (assoc-default (map-elt result-filds 'updown)    json)
         open      (assoc-default (map-elt result-filds 'open)      json)
         yestclose (assoc-default (map-elt result-filds 'yestclose) json)
         high      (assoc-default (map-elt result-filds 'high)      json)
         low       (assoc-default (map-elt result-filds 'low)       json)
         volume    (assoc-default (map-elt result-filds 'volume)    json))

        ;; sanity check
        (unless (and symbol name price percent updown open yestclose high low volume)
          (with-temp-message "Invalid data received !!!"
            (sit-for 1))
          (throw 'break 0))

        ;; formating
        (when (stringp percent)
          (setq percent (string-to-number percent)))
        (when (stringp volume)
          (setq volume (string-to-number volume)))
        (when (stringp yestclose)
          (setq yestclose (string-to-number yestclose)))

        ;; some extra handling
        (when (cl-typep tag 'stock-tracker--chn-symbol)
          (setq percent (* 100 percent)))

        ;; construct data for display
        (when symbol
          (push
           (propertize
            (format stock-tracker--result-item-format symbol name price percent updown
                    high low (stock-tracker--add-number-grouping volume ",") open yestclose)
            'stock-code symbol)
           result-list))

        ;; for us-stock, there's only one stock data here
        (unless (cl-typep tag 'stock-tracker--chn-symbol)
          (throw 'break t))))
    (when result-list
      (setq result (stock-tracker--list-to-string (reverse result-list) "")))
    result))

(defun stock-tracker--refresh-content (stocks-info)
  "Refresh stocks with STOCKS-INFO."
  (when stocks-info
    (with-current-buffer (get-buffer-create stock-tracker-buffer-name)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (stock-tracker-mode)
        (insert (format "%s\n\n" (concat "* Refresh list of stocks at: [" (current-time-string) "]")))
        (insert (format "%s\n\n" stock-tracker--note-string))
        (insert stock-tracker--result-header)
        (insert stocks-info)
        (stock-tracker--align-all-tables)))))

(defun stock-tracker--refresh-async (chn-stocks  us-stocks)
  "Refresh list of stocks namely CHN-STOCKS and US-STOCKS."
  (let* ((chn-stocks-string (mapconcat #'identity chn-stocks ","))
         (us-stocks-string (mapconcat #'identity us-stocks ","))
         (chn-symbol (make-stock-tracker--chn-symbol))
         (us-symbol (make-stock-tracker--us-symbol)))

    (with-temp-message "Fetching stock data async ..."
      (sit-for 1))

    ;; start subprocess
    (async-start

     ;; What to do in the child process
     `(lambda ()
        (require 'url)
        (require 'subr-x)

        ;; pass params to subprocess, use string here
        (setq subprocess-chn-stocks-string ,chn-stocks-string
              subprocess-us-stocks-string ,us-stocks-string)

        ;; mininum required functions in subprocess
        (defun stock-tracker--subprocess-api-url (string-tag)
          "API to get stock."
          (if (equal string-tag "chn-stock")
              "https://api.money.126.net/data/feed/%s"
            "https://quote.cnbc.com/quote-html-webservice/quote.htm?partnerId=2&requestMethod=quick&exthrs=1&noform=1&fund=1&extendedMask=2&output=json&symbols=%s"))

        (defun stock-tracker--subprocess-result-prefix (string-tag)
          "Stock-Tracker result prefix for S from CHN."
          (if (equal string-tag "chn-stock")
              "_ntes_quote_callback("
            "{\"QuickQuoteResult\":{\"xmlns\":\"http://quote.cnbc.com/services/MultiQuote/2006\",\"QuickQuote\":"))

        (defun stock-tracker--subprocess-request-synchronously (stock string-tag)
          "Request STOCK with TAG synchronously, return a list of JSON each as alist if successes."
          (let (jsons)
            (with-current-buffer
                (url-retrieve-synchronously
                 (format (stock-tracker--subprocess-api-url string-tag) (url-hexify-string stock)) t nil 5)
              (set-buffer-multibyte t)
              (goto-char (point-min))
              (when (string-match "200 OK" (buffer-string))
                (re-search-forward (stock-tracker--subprocess-result-prefix string-tag) nil 'move)
                (setq
                 jsons
                 (json-read-from-string (buffer-substring-no-properties (point) (point-max)))))
              (kill-current-buffer))
            jsons))

        ;; make sure subprocess can exit without query
        (setq kill-buffer-query-functions (delq 'process-kill-buffer-query-function kill-buffer-query-functions))

        ;; do real business here
        (let ((result '((chn-stock . 0) (us-stock . 0)))
              (chn-result nil)
              (us-result nil))
          (when subprocess-chn-stocks-string
            (push
             (stock-tracker--subprocess-request-synchronously subprocess-chn-stocks-string "chn-stock") chn-result))
          (dolist (us-stock (split-string subprocess-us-stocks-string ","))
            (push
             (stock-tracker--subprocess-request-synchronously us-stock "us-stock") us-result))
          (when chn-result (map-put! result 'chn-stock chn-result))
          (when us-result (map-put! result 'us-stock us-result))
          result))

     ;; What to do when it finishes
     (lambda (result)
       (let ((chn-result (cdr (assoc 'chn-stock result)))
             (us-result (cdr (assoc 'us-stock result)))
             (all-collected-stocks-info nil))

         ;; process stock data
         (with-temp-message "Fetching stock done"
           (unless (numberp chn-result)
             (push (stock-tracker--format-response-async chn-result chn-symbol)
                   all-collected-stocks-info))
           (unless (numberp us-result)
             (dolist (us-stock us-result)
               (push (stock-tracker--format-response us-stock us-symbol)
                     all-collected-stocks-info)))
           (when all-collected-stocks-info
             (stock-tracker--refresh-content
              (stock-tracker--list-to-string (reverse all-collected-stocks-info) "")))))))))

(defun stock-tracker--refresh (&optional asynchronously)
  "Refresh list of stocks ASYNCHRONOUSLY or not."
  (when-let* ((has-stocks stock-tracker-list-of-stocks)
              (valid-stocks (delq nil (delete-dups has-stocks))))
    (let* ((chn-stocks (stock-tracker--get-chn-stocks valid-stocks))
           (us-stocks (stock-tracker--get-us-stocks valid-stocks))
           (chn-stocks-string (mapconcat #'identity chn-stocks ","))
           (all-collected-stocks-info nil)
           (chn-symbol (make-stock-tracker--chn-symbol))
           (us-symbol (make-stock-tracker--us-symbol)))
      (if asynchronously
          ;; asynchronously
          (stock-tracker--refresh-async chn-stocks us-stocks)
        ;; synchronously
        (with-temp-message "Fetching stock data ..."
          (when chn-stocks-string
            (push
             (stock-tracker--format-response (stock-tracker--request-synchronously chn-stocks-string chn-symbol) chn-symbol)
             all-collected-stocks-info))
          (dolist (us-stock us-stocks)
            (push
             (stock-tracker--format-response (stock-tracker--request-synchronously us-stock us-symbol) us-symbol)
             all-collected-stocks-info))
          (when all-collected-stocks-info
            (stock-tracker--refresh-content (stock-tracker--list-to-string (reverse all-collected-stocks-info) ""))))))))

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
      (let ((inhibit-read-only t)
            (tag
             (if (zerop (string-to-number stock))
                 (make-stock-tracker--us-symbol)
               (make-stock-tracker--chn-symbol))))
        (erase-buffer)
        (stock-tracker-mode)
        (insert stock-tracker--result-header)
        (insert (stock-tracker--format-response (stock-tracker--request-synchronously stock tag) tag))
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
  (let* ((orgin-read-only buffer-read-only)
         (stock (format "%s" (read-from-minibuffer "stock? ")))
         (tag
          (if (zerop (string-to-number stock))
              (make-stock-tracker--us-symbol)
            (make-stock-tracker--chn-symbol))))
    (when-let* ((is-valid-stock (not (string= "" stock)))
                (is-not-duplicate (not (member stock stock-tracker-list-of-stocks)))
                (recved-stocks-info
                 (stock-tracker--format-response (stock-tracker--request-synchronously stock tag) tag))
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
              (delete stock-code stock-tracker-list-of-stocks))
        (when orgin-read-only (read-only-mode 1))
        (stock-tracker--refresh)))))

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
