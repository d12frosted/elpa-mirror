;;; stock-ticker.el --- Show stock prices in mode line

;; Copyright (C) 2015 Gunther Hagleitner

;; Author: Gunther Hagleitner
;; Version: 0.1
;; Package-Version: 20150204.1052
;; Package-Commit: 74251cc810604af75f48333d51133326c053dd16
;; Keywords: comms
;; URL: https://github.com/hagleitn/stock-ticker
;; Package-Requires: ((s "1.9.0") (request "0.2.0"))

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
;; Stock-ticker lets you display stock prices in the mode line. You
;; can specify a number of stock symbols to track and their current
;; price, change and change percentage will be rotated in the mode
;; line.
;;
;; The financial data will be retrieved from Yahoo's finance apis via
;; YQL.

;;; Code:
(require 'json)
(require 'request)
(require 's)
(require 'timer)

(defun stock-ticker--query (symbols)
  "Generate yql query string from list of SYMBOLS."
  (let ((query-template "select * from yahoo.finance.quotes where symbol in (\"%s\")")
        (symbol-string (s-join "\",\"" symbols)))
    (format query-template symbol-string)))

(defun stock-ticker--parse (data)
  "Parse financial DATA into list of display strings."
  (let ((qs (assoc-default 'quote (assoc-default 'results (assoc-default 'query data)))))
    (mapcar
     (lambda (q)
       (let ((percent (assoc-default 'PercentChange q))
             (change (assoc-default 'Change q))
             (symbol (assoc-default 'Symbol q))
             (price (assoc-default 'LastTradePriceOnly q))
             (name (assoc-default 'Name q)))
         (format " %s: %s %s (%s) "
                 (if (or
                      (string-match "=" symbol)
                      (string-match "\\^" symbol)) name symbol)
                 (if price price "")
                 (if change change "")
                 (if percent percent ""))))
     qs)))

;;;###autoload
(defgroup stock-ticker nil
  "Stock ticker."
  :group 'applications
  :prefix "stock-ticker-")

;;;###autoload
(defcustom stock-ticker-symbols '("^gspc" "^dji" "^ixic" "^tnx"
				  "^nya" "XAUUSD=X" "EURUSD=X")
  "List of ticker symbols that the mode line will cycle through."
  :type '(string)
  :group 'stock-ticker)

;;;###autoload
(defcustom stock-ticker-update-interval 300
  "Number of seconds between rest calls to fetch data."
  :type 'integer
  :group 'stock-ticker)

;;;###autoload
(defcustom stock-ticker-display-interval 10
  "Number of seconds between refreshing the mode line."
  :type 'integer
  :group 'stock-ticker)

(defvar stock-ticker--current "")
(defvar stock-ticker--current-stocks nil)
(defvar stock-ticker--current-index 0)
(defvar stock-ticker--update-timer nil)
(defvar stock-ticker--display-timer nil)

(defun stock-ticker--update ()
  "Update the global stock-ticker string."
  (request
   "http://query.yahooapis.com/v1/public/yql"
   :params `((q . ,(stock-ticker--query stock-ticker-symbols))
             (env . "http://datatables.org/alltables.env")
             (format . "json"))
   :parser 'json-read
   :success (function*
             (lambda (&key data &allow-other-keys)
               (when data
                 (progn (setq stock-ticker--current-stocks
                              (stock-ticker--parse data))))))))

(defun stock-ticker--next-symbol ()
  "Cycle throug the available ticker symbols and update the mode line."
  (when stock-ticker--current-stocks
    (progn
      (setq stock-ticker--current-index
            (mod (+ stock-ticker--current-index 1)
                 (length stock-ticker--current-stocks)))
      (setq stock-ticker--current
            (nth stock-ticker--current-index stock-ticker--current-stocks))
      (force-mode-line-update))))

;;;###autoload
(define-minor-mode stock-ticker-global-mode
  "Add stock ticker info to the mode line.

Enabeling stock ticker global mode will add stock information in the form
SYMBOL: PRICE CHANGE (PERCENT CHANGE) to the mode line for each stock symbol
listed in 'stock-ticker-symbols'. Only one symbol is displayed at a time and
the mode cycles through the requested symbols at a configurable interval."
  :global t
  :group 'stock-ticker
  (setq stock-ticker--current "")
  (setq stock-ticker--current-index 0)
  (setq stock-ticker--current-stocks nil)
  (when (not global-mode-string) (setq global-mode-string '("")))
  (when stock-ticker--update-timer (cancel-timer stock-ticker--update-timer))
  (when stock-ticker--display-timer (cancel-timer stock-ticker--display-timer))
  (if (not stock-ticker-global-mode)
      (setq global-mode-string
            (delq 'stock-ticker--current global-mode-string))
    (add-to-list 'global-mode-string 'stock-ticker--current t)
    (setq stock-ticker--update-timer
          (run-at-time nil stock-ticker-update-interval
                       'stock-ticker--update))
    (setq stock-ticker--display-timer
          (run-at-time nil stock-ticker-display-interval
                       'stock-ticker--next-symbol))
    (stock-ticker--update)))

(provide 'stock-ticker)
;;; stock-ticker.el ends here
