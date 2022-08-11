;;; cardano-wallet.el --- Interact with cardano wallet -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Óscar Nájera
;;
;; Author: Oscar Najera <https://github.com/titan>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.2.0
;; Package-Version: 20220718.1434
;; Package-Commit: 5e1bf8b8ffa4c75bece7a93feab9858f0e7d676e
;; Homepage: https://github.com/Titan-C/cardano.el
;; Package-Requires: ((emacs "27.1") (yaml "0.1.0") (dash "2.19.0") (yaml-mode "0.0.15") (readable-numbers "0.1.0") (cardano-tx "0.1.0"))

;; This file is not part of GNU Emacs.
;;
;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Provide an interface to the cardano-wallet service
;;; Code:

(require 'url)
(require 'yaml)
(require 'dash)
(require 'yaml-mode)
(require 'readable-numbers)
(require 'cardano-tx-utils)
(require 'cardano-tx-address)
(require 'cardano-tx-db)
(require 'cardano-tx)

;; Silence byte-compiler.
(defvar url-http-end-of-headers)

(defgroup cardano-wallet nil
  "Wallet service."
  :group 'cardano)

(defcustom cardano-wallet-url nil
  "Cardano wallet URL with port."
  :type 'string)

(defvar-local cardano-wallet-tx--wallet nil
  "Hash-table containing active wallet information.
This is only available on TX preview buffers.")

(defvar-local cardano-wallet-current nil
  "Actively selected wallet.")

(defvar-local cardano-wallet--buffer-response nil
  "Stores the JSON response for a query of wallet.")

(defun cardano-wallet (endpoint callback &optional method json-data)
  "Wallet API call to ENDPOINT.

CALLBACK function that takes a hash-table, which is the parsed JSON of response.
If JSON-DATA default to post unless METHOD is defined."
  (let ((url-request-method method)
        (url-request-extra-headers
         (when json-data '(("Content-Type" . "application/json"))))
        (url-request-data
         (-some-> json-data (json-encode) (encode-coding-string 'utf-8))))
    (url-retrieve
     (concat cardano-wallet-url "/v2/" endpoint)
     #'cardano-tx--parse-response
     `(,callback))))

(defun cardano-wallet-show (json)
  "Show whatever is the response JSON."
  (with-current-buffer (get-buffer-create "*Cardano wallet response*")
    (erase-buffer)
    (insert (yaml-encode json))
    (yaml-mode)
    (readable-numbers-mode)
    (display-buffer (current-buffer))))

;;; Wallet addresses management

(defun cardano-wallet-addresses--refresh ()
  "Refresh the address list."
  (let ((known-addrs
         (emacsql (cardano-tx-db)
                  [:select [raw id monitor note] :from addresses
                   :where (in raw $v1)]
                  (cl-map 'vector (lambda (it) (cardano-tx-get-in it "id"))
                          cardano-wallet--buffer-response))))
    (->> cardano-wallet--buffer-response
         (seq-map (lambda (res)
                    (let* ((deriv (-> (cardano-tx-get-in res "derivation_path")
                                      (seq-drop 2) ;; remove standard 1852H/1815H
                                      (string-join "/")))
                           (state (cardano-tx-get-in res "state"))
                           (address (cardano-tx-get-in res "id"))
                           (db-info (cardano-tx-get-in known-addrs address)))
                      (list (or (car db-info) deriv)
                            (vector
                             (if (elt db-info 1) "YES" "NO")
                             address
                             (substring address -8)
                             (concat
                              (if (string= state "used")
                                  (propertize deriv 'face 'font-lock-keyword-face)
                                deriv)
                              (-some--> db-info (elt it 2)
                                        (string-remove-prefix deriv it)
                                        (cardano-tx-nw-p it)
                                        (format " -- %s" it))))))))
         (setq tabulated-list-entries))))

(defun cardano-wallet-address--refresh-query (&optional _arg _noconfirm)
  "Query for registered addresses and `revert-buffer'."
  (cardano-wallet
   (format "wallets/%s/addresses" (cardano-tx-get-in cardano-wallet-current "id"))
   (lambda (json-response)
     (with-current-buffer (get-buffer "*Cardano Wallet Addresses*")
       (setq cardano-wallet--buffer-response json-response)
       (run-hooks 'tabulated-list-revert-hook)
       (tabulated-list-print 'remember)))))

(defun cardano-wallet-addresses (wallet)
  "Show addresses for WALLET."
  (interactive (list (cardano-wallet--get-row-source)))
  (with-current-buffer (get-buffer-create "*Cardano Wallet Addresses*")
    (cardano-tx-db-addresses-mode)
    (setq-local cardano-wallet-current wallet)
    (add-hook 'tabulated-list-revert-hook #'cardano-wallet-addresses--refresh nil t)
    (setq revert-buffer-function #'cardano-wallet-address--refresh-query)
    (cardano-wallet-address--refresh-query)
    (display-buffer (current-buffer))))

(defun cardano-wallet-readable-number (amount)
  "AMOUNT as an underscore separated readable string."
  (let ((ref (number-to-string amount)))
    (if (> 4 (length ref))
        ref
      (let ((start (if (= 0 (string-match (rx (+ (= 3 digit)) eol) ref))
                       3 (match-beginning 0))))
        (string-join
         (cons
          (substring ref 0 start)
          (--map (substring ref it (+ it +3))
                 (number-sequence start (1- (match-end 0)) 3)))
         "_")))))

(defun cardano-wallet-sort-readable-number (column)
  "Generate a sort function for `tabulated-list' readable number at COLUMN."
  (cl-flet ((value (lambda (entry)
                     (thread-last
                       (aref (cadr entry) column)
                       (replace-regexp-in-string "_" "")
                       (string-to-number)))))
    (lambda (e1 e2) (> (value e1) (value e2)))))

(defun cardano-wallet-print-col (value)
  "Format VALUE for column."
  (pcase value
    ((pred integerp) (cardano-wallet-readable-number value))
    ((pred stringp) value)
    (n (format "%S" n))))

(defun cardano-wallet--balance-row (entry)
  "Extract values from ENTRY to display a balance row."
  (list (cardano-tx-get-in entry "balance" "total" "quantity")
        (cardano-tx-get-in entry "balance" "available" "quantity")
        (cardano-tx-get-in entry "balance" "reward" "quantity")
        (if (seq-empty-p (cardano-tx-get-in entry "assets" "total"))
            "NO" "YES")
        (cardano-tx-get-in entry "delegation" "active" "target")))

(defun cardano-wallet-balances--refresh ()
  "Query Cardano Wallet for wallet balances then refresh buffer with new entries."
  (cardano-wallet
   "wallets"
   (lambda (json-response)
     (with-current-buffer (get-buffer-create "*Cardano Wallet balances*")
       (->> json-response
            (setq cardano-wallet--buffer-response)
            (seq-map
             (lambda (res)
               (let ((name (cardano-tx-get-in res "name"))
                     (id (cardano-tx-get-in res "id")))
                 (list id (cl-map 'vector
                                  #'cardano-wallet-print-col
                                  (append (list name id)
                                          (cardano-wallet--balance-row res)))))))

            (setq tabulated-list-entries))
       (tabulated-list-print 'remember)))))

(defun cardano-wallet--get-row-source ()
  "Find originating data for table row."
  (seq-find (lambda (elt)
              (string=
               (cardano-tx-get-in elt "id")
               (tabulated-list-get-id)))
            cardano-wallet--buffer-response))

(defvar cardano-wallet-balances-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'cardano-wallet-describe)
    (define-key map "s" #'cardano-wallet-tx-new)
    (define-key map "l" #'cardano-wallet-addresses)
    (define-key map "t" #'cardano-wallet-tx-log)
    (define-key map "d" #'cardano-wallet-delete)
    map))

(define-derived-mode cardano-wallet-balances-mode tabulated-list-mode "*Wallet Balances*"
  "Major mode for managing wallets."
  :interactive nil
  (cl-flet ((sorter (lambda (col) (cardano-wallet-sort-readable-number col))))
    (setq tabulated-list-format `[("Name" 10 t)
                                  ("ID" 10 t)
                                  ("Total" 15 ,(sorter 2) :right-align t)
                                  ("Available" 15 ,(sorter 3) :right-align t)
                                  ("Reward" 13 ,(sorter 4) :right-align t)
                                  ("Assets" 6 t)
                                  ("Delegation" 0 t)]))
  (add-hook 'tabulated-list-revert-hook #'cardano-wallet-balances--refresh nil t)
  (tabulated-list-init-header))

(defun cardano-wallet-balances ()
  "Pop a buffer with all watched wallets."
  (interactive)
  (with-current-buffer (get-buffer-create "*Cardano Wallet balances*")
    (cardano-wallet-balances-mode)
    (cardano-wallet-balances--refresh)
    (tabulated-list-print)
    (display-buffer (current-buffer))))

(defun cardano-wallet-helm-pick ()
  "Helm actions on available wallets."
  (interactive)
  (cardano-wallet
   "wallets"
   (lambda (json)
     (helm
      :prompt "Wallet: "
      :sources (helm-build-sync-source
                   "wallet"
                 :candidates (--map (cons (cardano-tx-get-in it "name") it)
                                    json)
                 :action (helm-make-actions
                          "Payment" #'cardano-wallet-tx-new
                          "Get addresses" #'cardano-wallet-addresses
                          "Get transaction log" #'cardano-wallet-tx-log
                          "Describe wallet" #'cardano-wallet-describe
                          "Delete wallet" #'cardano-wallet-delete))))))

(defun cardano-wallet-describe (wallet)
  "Pop buffer describing WALLET."
  (interactive (list (cardano-wallet--get-row-source)))
  (cardano-wallet
   (format "wallets/%s/" (cardano-tx-get-in wallet "id"))
   #'cardano-wallet-show))

;;; Wallet transactions

(defun cardano-wallet-db-tx-annotation (txid)
  "Query annotation for TXID."
  (caar
   (emacsql (cardano-tx-db)
            [:select annotation :from tx-annotation :where (= txid $s1)]
            txid)))

(defun cardano-wallet-tx-annotate (tx-hash)
  "Annotate TX-HASH."
  (interactive
   (list (tabulated-list-get-id)))
  (with-current-buffer (generate-new-buffer "*TX Annotation*")
    (setq-local header-line-format (format "Annotate TX: %s" tx-hash))
    (-some-> (cardano-wallet-db-tx-annotation tx-hash)
      (insert))
    (local-set-key "\C-c\C-c"
                   (lambda ()
                     (interactive)
                     (emacsql (cardano-tx-db)
                              [:insert :or :replace :into tx-annotation :values $v1]
                              (vector tx-hash (buffer-substring-no-properties (point-min) (point-max))))
                     (kill-buffer)))
    (switch-to-buffer (current-buffer))))

(defvar cardano-wallet-tx-log-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'cardano-wallet-tx)
    (define-key map "a" #'cardano-wallet-tx-annotate)
    map))

(define-derived-mode cardano-wallet-tx-log-mode tabulated-list-mode "*Wallet Transaction Log*"
  "Major mode for working with addresses."
  :interactive nil
  (cl-flet ((sorter (lambda (col) (cardano-wallet-sort-readable-number col))))
    (setq tabulated-list-format `[("Date" 20 t)
                                  ("Hash" 10 t)
                                  ("Fee" 13 ,(sorter 2) :right-align t)
                                  ("Amount" 13 ,(sorter 3) :right-align t)
                                  ("Annotation" 20)]))
  (add-hook 'tabulated-list-revert-hook #'cardano-wallet-tx-log--refresh nil t)
  (setq revert-buffer-function #'cardano-wallet-tx-log--refresh-query)
  (tabulated-list-init-header))

(defun cardano-wallet-tx-log--refresh ()
  "Refresh the transaction log entry list."
  (let ((annotations
         (emacsql (cardano-tx-db) [:select * :from tx-annotation :where (in txid $v1)]
                  (vconcat (--map (cardano-tx-get-in it "id")
                                  cardano-wallet--buffer-response)))))
    (->> cardano-wallet--buffer-response
         (seq-map
          (lambda (res)
            (let ((date (cardano-tx-get-in res "inserted_at" "time"))
                  (id (cardano-tx-get-in res "id"))
                  (net-amount (cardano-tx-get-in res "amount" "quantity")))
              (list id
                    (cl-map 'vector
                            #'cardano-wallet-print-col
                            (list date id
                                  (cardano-tx-get-in res "fee" "quantity")
                                  (if (string= "incoming" (cardano-tx-get-in res "direction"))
                                      net-amount
                                    (propertize (cardano-wallet-print-col net-amount)
                                                'face 'font-lock-keyword-face))
                                  (-> (alist-get id annotations '("") nil #'string=)
                                      car (split-string "\n") car)))))))
         (setq tabulated-list-entries))))

(defun cardano-wallet-tx-log--refresh-query (&optional _arg _noconfirm)
  "Query for registered transactions and `revert-buffer'."
  (cardano-wallet
   (format "wallets/%s/transactions"
           (cardano-tx-get-in cardano-wallet-current "id"))
   (lambda (json-response)
     (with-current-buffer (get-buffer "*Cardano Wallet Transactions*")
       (setq cardano-wallet--buffer-response json-response)
       (run-hooks 'tabulated-list-revert-hook)
       (tabulated-list-print 'remember)))))

(defun cardano-wallet-tx-log (wallet)
  "Show Transactions in WALLET."
  (interactive (list (cardano-wallet--get-row-source)))
  (with-current-buffer (get-buffer-create "*Cardano Wallet Transactions*")
    (cardano-wallet-tx-log-mode)
    (setq-local cardano-wallet-current wallet)
    (cardano-wallet-tx-log--refresh-query)
    (tabulated-list-print)
    (display-buffer (current-buffer))))

(defun cardano-wallet-tx (wallet-id tx-hash)
  "Show TX-HASH from WALLET-ID."
  (interactive
   (list
    (cardano-tx-get-in cardano-wallet-current "id")
    (aref (tabulated-list-get-entry) 1)))
  (cardano-wallet
   (format "wallets/%s/transactions/%s" wallet-id tx-hash)
   (lambda (json)
     (with-current-buffer (window-buffer (cardano-wallet-show json))
       (goto-char (point-min))
       (-some-> (cardano-wallet-db-tx-annotation tx-hash)
         (insert "\n"))))))

(defun cardano-wallet-create (name mnemonic passphrase)
  "Register a new wallet under NAME from MNEMONIC secured with PASSPHRASE."
  (interactive
   (list
    (read-from-minibuffer "Name your wallet: ")
    (split-string (f-read
                   (read-file-name "File with your seed phrase: " cardano-tx-db-keyring-dir)))
    (read-passwd "Password for your wallet: " t)))
  (cardano-wallet
   "wallets"
   #'cardano-wallet-show
   "POST"
   (list :name name
         :mnemonic_sentence mnemonic
         :passphrase passphrase)))

(defun cardano-wallet-monitor (name xpub)
  "Register a new wallet under NAME for given XPUB in hex."
  (interactive
   (list
    (read-from-minibuffer "Name your wallet: ")
    (split-string (f-read
                   (read-file-name "File with extended public key: " cardano-tx-db-keyring-dir)))))
  (cl-assert (cbor-hex-p xpub))
  (cardano-wallet
   "wallets"
   #'cardano-wallet-show
   "POST"
   (list :name name
         :account_public_key xpub)))

(defun cardano-wallet-delete (wallet)
  "Delete WALLET."
  (interactive (list (cardano-wallet--get-row-source)))
  (let ((wallet-id (cardano-tx-get-in wallet "id")))
    (when (yes-or-no-p (format "Really delete wallet '%s' with id '%s'?"
                               (upcase (cardano-tx-get-in wallet "name")) wallet-id))
      (cardano-wallet
       (concat "wallets/" wallet-id)
       (lambda (_x) (message "Wallet %s deleted." wallet-id))
       "DELETE"))))

(defun cardano-wallet-tx-finish ()
  "Process buffer into a transaction, sign it and open PREVIEW."
  (interactive)
  (let* ((input-data (cardano-tx--input-buffer))
         (outputs (cardano-tx-get-in input-data 'outputs))
         (tx-buffer (current-buffer)))
    (cardano-wallet
     (concat "wallets/"
             (cardano-tx-get-in cardano-wallet-tx--wallet "id")
             "/transactions")
     (lambda (json) (cardano-wallet-show json) (kill-buffer tx-buffer))
     "POST"
     `(:payments ,(cl-map 'vector #'cardano-wallet-payment outputs)
       :passphrase ,(read-passwd "Password to unlock your wallet: ")))))

(defun cardano-wallet-payment (tx-out)
  "Build payment object from TX-OUT."
  (if-let ((target-addr (cardano-tx-nw-p
                         (cardano-tx-get-in tx-out 'address)))
           (amount  (cardano-tx-get-in tx-out 'amount)))
      `(:address ,target-addr
        :amount (:quantity ,(cardano-tx-get-in tx-out 'amount 'lovelace)
                 :unit "lovelace")
        :assets
        ,(->>
          (cardano-tx-assets-flatten amount)
          (cl-remove-if #'numberp)
          (cl-map 'vector
                  (-lambda ((amount policy tokenname))
                    (list :policy_id policy
                          :asset_name (cbor-string->hexstring tokenname)
                          :quantity amount)))))))

(defun cardano-wallet-tx-new (wallet)
  "Open an editor to create a new transaction for WALLET."
  (interactive (list (cardano-wallet--get-row-source)))
  (with-current-buffer (generate-new-buffer "*Cardano tx*")
    (insert "# -*- mode: cardano-tx; -*-\n\n")
    (cardano-tx-mode)
    (setq-local cardano-wallet-tx--wallet wallet)
    (yas-expand-snippet (yas-lookup-snippet 'wallet-spend))
    (use-local-map (copy-keymap cardano-tx-mode-map))
    (local-set-key (kbd "C-c C-c") #'cardano-wallet-tx-finish)
    (local-set-key (kbd "C-c C-s") nil)
    (message "Press %s to build and send transaction."
             (substitute-command-keys "\\[cardano-wallet-tx-finish]"))
    (switch-to-buffer (current-buffer))))

(defun cardano-wallet-tx-assets-pick ()
  "Load assets available on wallet to `kill-ring'."
  (interactive)
  (->> (cardano-tx-get-in cardano-wallet-tx--wallet "assets" "total")
       (--map
        (concat "      " ;; ident
                (cardano-tx-get-in it "policy_id")
                ":\n        "
                (let ((assetname (cbor-hexstring->ascii
                                  (cardano-tx-get-in it "asset_name"))))
                  (if (cardano-tx-nw-p assetname) assetname "\"\"")) ": "
                (number-to-string
                 (cardano-tx-get-in it "quantity")) "\n"))
       (cardano-tx-pick "Assets")
       (string-join)
       (kill-new)))

(provide 'cardano-wallet)
;;; cardano-wallet.el ends here
