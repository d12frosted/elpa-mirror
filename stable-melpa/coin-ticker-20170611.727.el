;;; coin-ticker.el --- Show a cryptocurrency price ticker

;; Copyright (C) 2017 Evan Klitzke

;; Author: Evan Klitzke <evan@eklitzke.org>
;; URL: https://github.com/eklitzke/coin-ticker-mode
;; Package-Version: 20170611.727
;; Package-Commit: 45108e239e1d129c0cc1ff37f2870cf73087780b
;; Version: 0.1.0
;; Package-Requires: ((request "0.3.0") (emacs "25"))
;; Keywords: news

;;; Commentary:
;;
;; Provides a ticker of cryptocurrency prices (Bitcoin, Ethereum, etc.) using
;; the coinmarketcap.com API.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'json)
(require 'request)

(defgroup coin-ticker nil
  "coin-ticker extension"
  :group 'comms
  :prefix "coin-ticker-")


;;; Constants

(defconst coin-ticker-version "0.1.0")

(defconst coin-ticker-url "https://api.coinmarketcap.com/v1/ticker/")


;;; Customize variables

(defcustom coin-ticker-api-poll-interval 300
  "Default interval to poll to the coinmarketcap api (in seconds)."
  :type 'number
  :group 'coin-ticker)

(defcustom coin-ticker-api-limit 10
  "Number of cryptocurrencies to fetch price data for (0 for all)."
  :type 'number
  :group 'coin-ticker)

(defcustom coin-ticker-syms '("BTC" "ETH")
  "Coins to show."
  :group 'coin-ticker)

(defcustom coin-ticker-show-syms t
  "If non-nil, symbols will be shown alongside prices."
  :group 'coin-ticker)

(defcustom coin-ticker-price-convert "USD"
  "Used to convert prices to some base unit (USD, EUR, BTC, etc)."
  :group 'coin-ticker)

(defcustom coin-ticker-price-symbol "$"
  "The symbol to show for the price."
  :group 'coin-ticker)


;;; Internal variables

(defvar coin-ticker-timer nil
  "Coin API poll timer.")

(defvar coin-ticker-mode-line ""
  "Displayed on mode-line.")

;; users shouldn't directly modify coin-ticker-mode-line
(put 'coin-ticker-mode-line 'risky-local-variable t)


;;; Methods

(defun coin-ticker-start ()
  "Start the ticker."
  (unless coin-ticker-timer
    (setq coin-ticker-timer
          (run-at-time "0 sec"
                       coin-ticker-api-poll-interval
                       #'coin-ticker-fetch))
    (coin-ticker-fetch)))

(defun coin-ticker-stop()
  "Stop the ticker."
  (when coin-ticker-timer
    (cancel-timer coin-ticker-timer)
    (setq coin-ticker-timer nil)
    (if (boundp 'mode-line-modes)
        (delete '(t coin-ticker-mode-line) mode-line-modes))))

(defun coin-ticker-price-fmt (sym price)
  "Format SYM so that its PRICE is shown."
  (if coin-ticker-show-syms
      (format "%s %s%s" sym coin-ticker-price-symbol price)
    (format "%s%s" coin-ticker-price-symbol price)))

(defun coin-ticker-modeline-update (prices)
  "Update the modeline with a PRICES dictionary."
  (setq coin-ticker-mode-line
        (format "[%s]"
                (string-join
                 (cl-loop for sym in coin-ticker-syms
                          collect
                          (coin-ticker-price-fmt sym (gethash sym prices))) " "))))

(defun coin-ticker-build-params ()
  "Build the HTTP params."
    (let ((params '()))
      (if (/= coin-ticker-api-limit 0)
          (add-to-list 'params `("limit" . ,coin-ticker-api-limit)))
      (if (> (length coin-ticker-price-convert) 0)
          (add-to-list 'params `("convert" . ,coin-ticker-price-convert)))
      params))

(defun coin-ticker-price-key()
  "Get the JSON key to use when accessing a price."
  (if (= (length coin-ticker-price-convert) 0)
      'price_usd
    (intern (concat "price_" (downcase coin-ticker-price-convert)))))

(defun coin-ticker-fetch ()
  "Fetch new price data."
  (request
   coin-ticker-url
   :params (coin-ticker-build-params)
   :parser 'json-read
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (let ((prices (make-hash-table :test 'equal)))
                 (cl-loop for tick across data
                          do (let ((sym (alist-get 'symbol tick))
                                   (price (alist-get (coin-ticker-price-key) tick)))
                               (puthash sym price prices)))
                 (coin-ticker-modeline-update prices))))))


;;; Mode

(define-minor-mode coin-ticker-mode
  "Minor mode to show cryptocurrency prices."
  :init-value nil
  :global t
  :lighter coin-ticker-mode-line
  (if coin-ticker-mode
      (coin-ticker-start)
    (coin-ticker-stop)))

(provide 'coin-ticker)
;;; coin-ticker.el ends here
