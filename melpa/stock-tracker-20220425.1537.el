;;; stock-tracker.el --- Track stock price -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2022 Huming Chen

;; Author: Huming Chen <chenhuming@gmail.com>
;; URL: https://github.com/beacoder/stock-tracker
;; Package-Version: 20220425.1537
;; Package-Commit: 1ed9c7464cb0b1f570d60ce22bac876e32bfbd1f
;; Version: 0.1.6
;; Created: 2019-08-18
;; Keywords: convenience, stock, finance
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
;; 0.1.2 Support asynchronous stock fetching with async
;; 0.1.3 Clean hanging subprocesses periodically
;;       Save stock-tracker-list-of-stocks with desktop
;; 0.1.4 Fix can't add and remove stock issue
;;       Colorize stock based on price
;; 0.1.5 Add timestamp to skip outdated data
;;       Fix empty line generated during adding/removing stocks
;;       Restore original position after refreshing stocks
;;       Disable logging by default
;; 0.1.6 Add stock-tracker-stop-refresh
;;       Add refresh state

;;; Code:

(require 'async)
(require 'dash)
(require 'desktop)
(require 'json)
(require 'org)
(require 'seq)
(require 'subr-x)
(require 'text-property-search)
(require 'url)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customizable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup stock-tracker nil
  "Track stock price in Emacs."
  :version "0.1"
  :group 'tools)

(defcustom stock-tracker-refresh-interval 1
  "Refresh stock every N * 10 SECS."
  :type 'integer
  :group 'stock-tracker)

(defcustom stock-tracker-list-of-stocks '("BABA")
  "List of stock to monitor."
  :type 'list
  :group 'stock-tracker)

(defcustom stock-tracker-subprocess-kill-delay 12
  "Kill subprocess in N * 10 SECS."
  :type 'integer
  :group 'stock-tracker)

(defcustom stock-tracker-enable-log nil
  "Display log messages."
  :type 'boolean
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
  (ignore s)
  "https://api.money.126.net/data/feed/%s")

(cl-defmethod stock-tracker--api-url ((s stock-tracker--us-symbol))
  "API to get stock for S from US."
  (ignore s)
  "https://quote.cnbc.com/quote-html-webservice/quote.htm?partnerId=2&requestMethod=quick&exthrs=1&noform=1&fund=1&extendedMask=2&output=json&symbols=%s")

(cl-defgeneric stock-tracker--result-prefix (object)
  "Stock-Tracker result prefix based on OBJECT.")

(cl-defmethod stock-tracker--result-prefix ((s stock-tracker--chn-symbol))
  "Stock-Tracker result prefix for S from CHN."
  (ignore s)
  "_ntes_quote_callback(")

(cl-defmethod stock-tracker--result-prefix ((s stock-tracker--us-symbol))
  "Stock-Tracker result prefix for S from US."
  (ignore s)
  "{\"QuickQuoteResult\":{\"xmlns\":\"http://quote.cnbc.com/services/MultiQuote/2006\",\"QuickQuote\":")

(cl-defgeneric stock-tracker--result-fields (object)
  "Stock-Tracker result fields based on OBJECT.")

(cl-defmethod stock-tracker--result-fields ((s stock-tracker--chn-symbol))
  "Stock-Tracker result fields for S from CHN."
  (ignore s)
  '((code . code)
    (symbol . symbol)
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
  (ignore s)
  '((code . symbol)
    (symbol . symbol)
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

(defconst stock-tracker--buffer-name "*stock-tracker*"
  "Stock-Tracker result Buffer name.")

(defconst stock-tracker--result-header
  "|-\n| symbol | name | price | percent | updown | high | low | volume | open | yestclose |\n"
  "Stock-Tracker result header.")

(defconst stock-tracker--result-item-format
  "|-\n| %s | %s | %s | %.2f %% | %.2f | %s | %s | %s | %s | %.2f |\n"
  "Stock-Tracker result item format.")

(defconst stock-tracker--response-buffer "*api-response*"
  "Buffer name for error report when fail to read server response.")

(defconst stock-tracker--header-string
  "* Refresh stocks at: [ %current-time% ], refresh is: [ %refresh-state% ]"
  "Stock-Tracker header string.")

(defconst stock-tracker--note-string
  (purecopy
   "** Add     stock, use [ *a* ]
** Delete  stock, use [ *d* ]
** Start refresh, use [ *g* ]
** Stop  refresh, use [ *s* ]

** Stocks listed in SH, prefix with [ *0* ], e.g: 0600000
** Stocks listed in SZ, prefix with [ *1* ], e.g: 1002024
** Stocks listed in US,                    e.g: GOOG")
  "Stock-Tracker note string.")

(defvar stock-tracker--refresh-timer nil
  "Stock-Tracker refresh timer.")

(defvar stock-tracker--check-timer nil
  "Stock-Tracker check timer.")

(defvar stock-tracker--data-timestamp (time-to-seconds)
  "Stock-Tracker latest data timestamp.")

(defvar stock-tracker--data nil
  "Stock-Tracker latest data.")

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

(defun stock-tracker--align-colorize-tables ()
  "Align all org tables and do colorization."
  (org-table-map-tables 'org-table-align t)
  (stock-tracker--colorize-content))

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

(defun stock-tracker--kill-hanging-subprocess()
  "Kill hanging *emacs* subprocess."
  (dolist (buffer (mapcar #'buffer-name (buffer-list)))
    (when (string-match "*emacs*" buffer)
      (when-let ((process (get-buffer-process buffer)))
        ;; set the process as killable without query by default
        (set-process-query-on-exit-flag process nil)
        (delete-process process)
        (sit-for 0.5))
      (and (get-buffer buffer)
           (null (get-buffer-process buffer))
           (kill-buffer buffer)))))

(defun stock-tracker--log (message)
  "Log MESSAGE."
  (when stock-tracker-enable-log
    (with-temp-message message
      (sit-for 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun stock-tracker--request-synchronously (stock tag)
  "Get STOCK data with TAG synchronously, return a list of JSON each as alist."
  (let (jsons)
    (ignore-errors
      (with-current-buffer
          (url-retrieve-synchronously
           (format (stock-tracker--api-url tag) (url-hexify-string stock)) t nil 5)
        (set-buffer-multibyte t)
        (goto-char (point-min))
        (when (string-match "200 OK" (buffer-string))
          (re-search-forward (stock-tracker--result-prefix tag) nil 'move)
          (setq
           jsons
           (json-read-from-string (buffer-substring-no-properties (point) (point-max)))))
        (kill-current-buffer)))
    jsons))

(defun stock-tracker--format-json (json tag)
  "Format stock information from JSON with TAG."
  (let ((result-filds (stock-tracker--result-fields tag))
        symbol name price percent (updown 0) color
        high low volume open yestclose code)

    (setq
      code      (assoc-default (map-elt result-filds 'code)      json)
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
      (stock-tracker--log "Invalid data received !!!")
      (throw 'break 0))

    ;; formating
    (and (stringp percent)   (setq percent (string-to-number percent)))
    (and (stringp volume)    (setq volume (string-to-number volume)))
    (and (stringp yestclose) (setq yestclose (string-to-number yestclose)))
    (and (stringp updown)    (setq updown (string-to-number updown)))

    ;; color setting
    (if (> updown 0) (setq color "red") (setq color "green"))

    ;; some extra handling
    (and (cl-typep tag 'stock-tracker--chn-symbol) (setq percent (* 100 percent)))

    ;; construct data for display
    (and symbol
         (propertize
          (format stock-tracker--result-item-format symbol
                  name price percent updown high low
                  (stock-tracker--add-number-grouping volume ",")
                  open yestclose)
          'stock-code  code
          'stock-color color))))

(defun stock-tracker--format-response (response tag &optional asynchronously)
  "Format stock information from RESPONSE with TAG, with optional ASYNCHRONOUSLY."
  (let ((jsons response)
        (result "") result-list)
    (catch 'break
      ;; handle difference in async handling
      (and asynchronously
           (cl-typep tag 'stock-tracker--chn-symbol)
           (setq jsons (car jsons)))

      (dolist (json jsons)
        (if (cl-typep tag 'stock-tracker--chn-symbol)
            (setq json (cdr json))
          ;; for us-stock, there's only one stock data here
          (setq json jsons))

        (when-let ((info (stock-tracker--format-json json tag)))
          (push info result-list))

        ;; for us-stock, there's only one stock data here
        (unless (cl-typep tag 'stock-tracker--chn-symbol)
          (throw 'break t))))
    (and result-list
         (setq result (stock-tracker--list-to-string (reverse result-list) "")))
    result))

(defun stock-tracker--colorize-content ()
  "Colorize stock base on price."
  (let ((ended nil) pos beg end (color "red"))
    (goto-char (point-min))
    ; colorize timestamp
    (re-search-forward "%current-time%" nil 'move)
    (let ((ov (make-overlay (- (point) (length "%current-time%")) (point))))
      (overlay-put ov 'display (current-time-string))
      (overlay-put ov 'face '(:foreground "green"))
      (overlay-put ov 'intangible t))
    ; colorize refresh state
    (re-search-forward "%refresh-state%" nil 'move)
    (let ((ov (make-overlay (- (point) (length "%refresh-state%")) (point))))
      (if stock-tracker--refresh-timer
          (progn
            (overlay-put ov 'face '(:foreground "green"))
            (overlay-put ov 'display "ON")
            (overlay-put ov 'intangible t))
        (overlay-put ov 'face '(:foreground "red"))
        (overlay-put ov 'display "OFF")
        (overlay-put ov 'intangible t)))
    ; colorize table
    (while (not ended)
      (setq pos (next-single-property-change (point) 'stock-code)
            beg pos end beg
            color (and pos (get-text-property pos 'stock-color nil)))
      (if (not pos) (setq ended t) ; done
        (goto-char pos)
        (setq end (line-end-position)))
      (while (and end (<= (point) end) (re-search-forward "|" nil 'move))
        (and beg (1- (point))
             ;; (propertize "Red Text" 'font-lock-face '(:foreground "red"))
             ;; propertize doesn't work in org-table-cell, so use overlay here
             (overlay-put (make-overlay beg (1- (point))) 'face `(:foreground ,color))
             (setq beg (point)))))))

(defun stock-tracker--refresh-content (stocks-info)
  "Refresh stocks with STOCKS-INFO."
  (and stocks-info
       (null (seq-empty-p stocks-info))
       (with-current-buffer (get-buffer-create stock-tracker--buffer-name)
         (let ((inhibit-read-only t)
               (origin (point)))
           (setq stock-tracker--data stocks-info)
           (erase-buffer)
           (stock-tracker-mode)
           (font-lock-mode 1)
           (insert (format "%s\n\n" stock-tracker--header-string))
           (insert (format "%s\n\n" stock-tracker--note-string))
           (insert stock-tracker--result-header)
           (dolist (info stocks-info) (insert info))
           ;; (insert "|-\n")
           (stock-tracker--align-colorize-tables)
           (goto-char origin)))))

(defun stock-tracker--refresh-async (chn-stocks  us-stocks)
  "Refresh list of stocks namely CHN-STOCKS and US-STOCKS."
  (let* ((chn-stocks-string (mapconcat #'identity chn-stocks ","))
         (us-stocks-string (mapconcat #'identity us-stocks ","))
         (chn-symbol (make-stock-tracker--chn-symbol))
         (us-symbol (make-stock-tracker--us-symbol))
         (data-retrieve-timestamp (time-to-seconds)))

    (stock-tracker--log "Fetching stock data async ...")

    ;; start subprocess
    (async-start

     ;; What to do in the child process
     `(lambda ()

        ;; libraries
        (require 'subr-x)
        (require 'url)

        ;; pass params to subprocess, use literal (string, integer, float) here
        (setq subprocess-chn-stocks-string ,chn-stocks-string
              subprocess-us-stocks-string ,us-stocks-string
              subprocess-kill-delay ,stock-tracker-subprocess-kill-delay)

        ;; mininum required functions in subprocess
        (defun stock-tracker--subprocess-api-url (string-tag)
          "API to get stock data."
          (if (equal string-tag "chn-stock")
              "https://api.money.126.net/data/feed/%s"
            "https://quote.cnbc.com/quote-html-webservice/quote.htm?partnerId=2&requestMethod=quick&exthrs=1&noform=1&fund=1&extendedMask=2&output=json&symbols=%s"))

        (defun stock-tracker--subprocess-result-prefix (string-tag)
          "Stock data result prefix."
          (if (equal string-tag "chn-stock")
              "_ntes_quote_callback("
            "{\"QuickQuoteResult\":{\"xmlns\":\"http://quote.cnbc.com/services/MultiQuote/2006\",\"QuickQuote\":"))

        (defun stock-tracker--subprocess-request-synchronously (stock string-tag)
          "Get stock data synchronously, return a list of JSON each as alist."
          (let (jsons)
            (ignore-errors
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
                (kill-current-buffer)))
            jsons))

        ;; make sure subprocess can exit successfully
        (progn
          (setq kill-buffer-query-functions
                (delq 'process-kill-buffer-query-function kill-buffer-query-functions))

          (when (>= emacs-major-version 28)
            (setq backtrace-on-error-noninteractive nil))

          ;; setup self-destruction timer
          (run-with-timer (* 10 subprocess-kill-delay) 10 (lambda () (kill-emacs))))

        ;; do real business here
        (let ((result '((chn-stock . 0) (us-stock . 0)))
              (chn-result nil)
              (us-result nil))

          ;; fetch chn stocks
          (unless (string-empty-p subprocess-chn-stocks-string)
            (push
             (stock-tracker--subprocess-request-synchronously subprocess-chn-stocks-string "chn-stock") chn-result)
            (when chn-result (map-put! result 'chn-stock chn-result)))

          ;; fetch us stocks
          (unless (string-empty-p subprocess-us-stocks-string)
            (dolist (us-stock (split-string subprocess-us-stocks-string ","))
              (push
               (stock-tracker--subprocess-request-synchronously us-stock "us-stock") us-result))
            (when us-result (map-put! result 'us-stock us-result)))

          result))

     ;; What to do when it finishes
     (lambda (result)
       (let ((chn-result (cdr (assoc 'chn-stock result)))
             (us-result (cdr (assoc 'us-stock result)))
             (all-collected-stocks-info nil))

         (if (< data-retrieve-timestamp stock-tracker--data-timestamp)

             (stock-tracker--log "Outdated data received !!!")

           ;; update timestamp
           (setq stock-tracker--data-timestamp data-retrieve-timestamp)

           (stock-tracker--log "Fetching stock done")

           ;; format chn stocks
           (unless (numberp chn-result)
             (push (stock-tracker--format-response chn-result chn-symbol t)
                   all-collected-stocks-info))

           ;; format us stocks
           (unless (numberp us-result)
             (dolist (us-stock us-result)
               (push (stock-tracker--format-response us-stock us-symbol t)
                     all-collected-stocks-info)))

           ;; populate stocks
           (when all-collected-stocks-info
             (stock-tracker--refresh-content (reverse all-collected-stocks-info)))))))))

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
            (stock-tracker--refresh-content (reverse all-collected-stocks-info)))
          (setq stock-tracker--data-timestamp (time-to-seconds)))))))

(defun stock-tracker--run-timers ()
  "Run stock tracker timers."
  (setq stock-tracker--check-timer
        (run-with-timer (* 10 6 3)
                        (* 10 6 3)
                        'stock-tracker--kill-hanging-subprocess)
        stock-tracker--refresh-timer
        (run-with-timer (* 10 stock-tracker-refresh-interval)
                        (* 10 stock-tracker-refresh-interval)
                        'stock-tracker--refresh
                        t)))

(defun stock-tracker--cancel-timers ()
  "Cancel stock tracker timers."
  (when stock-tracker--check-timer
    (cancel-timer stock-tracker--check-timer)
    (setq stock-tracker--check-timer nil))
  (when stock-tracker--refresh-timer
    (cancel-timer stock-tracker--refresh-timer)
    (setq stock-tracker--refresh-timer nil)))

(defun stock-tracker--cancel-timer-on-exit ()
  "Cancel timer when stock tracker buffer is being killed."
  (when (eq major-mode 'stock-tracker-mode)
    (stock-tracker--cancel-timers)))

(defun stock-tracker-stop-refresh ()
  "Stop refreshing stocks."
  (interactive)
  (when (and stock-tracker--data stock-tracker--refresh-timer)
    (with-current-buffer stock-tracker--buffer-name
      (read-only-mode -1)
      (cancel-timer stock-tracker--refresh-timer)
      (setq stock-tracker--refresh-timer nil)
      (stock-tracker--refresh-content stock-tracker--data)
      (read-only-mode 1))))

;;;###autoload
(defun stock-tracker-start ()
  "Start stock-tracker, show result in `stock-tracker--buffer-name' buffer."
  (interactive)
  (when stock-tracker-list-of-stocks
    (stock-tracker--cancel-timers)
    (stock-tracker--run-timers)
    (stock-tracker--refresh)
    (unless (get-buffer-window stock-tracker--buffer-name)
      (switch-to-buffer-other-window stock-tracker--buffer-name))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun stock-tracker-add-stock ()
  "Add new stock in table."
  (interactive)
  (let* ((stock (format "%s" (read-from-minibuffer "stock? ")))
         (tag
          (if (zerop (string-to-number stock))
              (make-stock-tracker--us-symbol)
            (make-stock-tracker--chn-symbol))))
    (when-let* ((is-valid-stock (not (string= "" stock)))
                (is-not-duplicate (not (member stock stock-tracker-list-of-stocks)))
                (recved-stocks-info
                 (stock-tracker--format-response (stock-tracker--request-synchronously stock tag) tag))
                (success (not (string= "" recved-stocks-info))))
      (with-current-buffer stock-tracker--buffer-name
        (read-only-mode -1)
        (goto-char (point-max))
        (insert recved-stocks-info)
        (stock-tracker--align-colorize-tables)
        (setq stock-tracker-list-of-stocks (reverse stock-tracker-list-of-stocks))
        (push stock stock-tracker-list-of-stocks)
        (setq stock-tracker-list-of-stocks (reverse stock-tracker-list-of-stocks))
        (read-only-mode 1)))))

(defun stock-tracker-remove-stock ()
  "Remove STOCK from table."
  (interactive)
  (save-mark-and-excursion
    (with-current-buffer stock-tracker--buffer-name
      (let ((list-of-stocks stock-tracker-list-of-stocks)
            code tmp-stocks)
        (beginning-of-line)
        (when-let (stock-code (text-property-search-forward 'stock-code))
          (while (setq code (pop list-of-stocks))
            (unless (equal (upcase code) (upcase (prop-match-value stock-code)))
              (push code tmp-stocks)))
          (when tmp-stocks
            (setq stock-tracker-list-of-stocks (reverse tmp-stocks))
            (read-only-mode -1)
            (org-table-kill-row)
            (re-search-backward "|-" nil 'move)
            (org-table-kill-row)
            (stock-tracker--align-colorize-tables)
            (read-only-mode 1)))))))

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
    (define-key map (kbd "s") 'stock-tracker-stop-refresh)
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
  (setq desktop-globals-to-save
        (add-to-list 'desktop-globals-to-save 'stock-tracker-list-of-stocks))
  (add-hook 'kill-buffer-hook #'stock-tracker--cancel-timer-on-exit)
  (run-mode-hooks))


(provide 'stock-tracker)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; stock-tracker.el ends here
