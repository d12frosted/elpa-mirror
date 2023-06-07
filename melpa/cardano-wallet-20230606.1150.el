;;; cardano-wallet.el --- Interact with cardano wallet -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Óscar Nájera
;;
;; Author: Oscar Najera <https://github.com/titan>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.2.2
;; Package-Version: 20230606.1150
;; Package-Commit: cf85424b305e8f89debb756dc67eebc84639f711
;; Homepage: https://github.com/Titan-C/cardano.el
;; Package-Requires: ((emacs "27.1") (yaml "0.1.0") (dash "2.19.0") (yaml-mode "0.0.15") (readable-numbers "0.1.0") (cardano-tx "0.1.2"))

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

(require 'dash)
(require 'hex-util)
(require 'subr-x)
(require 'url)
(require 'yaml)
(require 'yaml-mode)
(require 'readable-numbers)
(require 'cardano-tx-utils)
(require 'cardano-tx-assets)
(require 'cardano-tx-address)
(require 'cardano-tx-db)
(require 'cardano-tx-hw)
(require 'cardano-tx)

;; Silence byte-compiler.
(defvar url-http-end-of-headers)

(defgroup cardano-wallet nil
  "Wallet service."
  :group 'cardano)

(defcustom cardano-wallet-url nil
  "Cardano wallet URL with port."
  :type 'string)

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
    (yaml-mode)
    (insert (yaml-encode json))
    (readable-numbers-mode)
    (display-buffer (current-buffer))))

(defun cardano-wallet-readable-number (amount)
  "AMOUNT as an underscore separated readable string."
  (let ((ref (number-to-string amount)))
    (if (<= (length ref) 4)
        ref
      (let ((start (if (= 0 (string-match (rx (+ (= 3 digit)) eol) ref))
                       3 (match-beginning 0))))
        (string-join
         (cons
          (substring ref 0 start)
          (--map (substring ref it (+ it +3))
                 (number-sequence start (1- (match-end 0)) 3)))
         "_")))))

(defun cardano-wallet-print-col (value)
  "Format VALUE for column."
  (pcase value
    ((pred integerp) (cardano-wallet-readable-number value))
    ((pred stringp) value)
    (n (format "%S" n))))

;;; Wallet addresses management
(defun cardano-wallet--derive-files-for-keys (key-list)
  "Derive for KEY-LIST."
  (thread-last
    key-list
    (emacsql (cardano-tx-db)
             [:with used-keys [fingerprint path-tail desc] :as [:values $v1]
              :select [data path-tail] :from used-keys
              :join master-keys mk
              :where (and (not (in desc [:select description :from typed-files]))
                          (= mk:fingerprint used-keys:fingerprint))
              :order-by [(asc data)]])
    (mapc (-lambda ((key path-tail))
            (cardano-tx-address--new-hd-key key path-tail)))))

(defun cardano-wallet--derive-and-load (fingerprint key-list)
  "Derive for KEY-LIST and load account of FINGERPRINT."
  (when (cardano-wallet--derive-files-for-keys key-list)
    (cardano-tx-address-hw-load
     (format "[%s]%%" fingerprint)
     (if (string= "--testnet-magic" (car cardano-tx-cli-network-args)) 0 1))))

(defun cardano-wallet-addresses--refresh ()
  "Refresh the address list."
  (thread-last
    cardano-wallet--buffer-response
    (mapcar
     (-lambda ((&alist 'id 'derivation_path))
       (vector id (string-join (seq-drop derivation_path 3) "/"))))
    (emacsql (cardano-tx-db)
             [:with wallet [addr path] :as [:values $v1]
              :select [monitor addr note path] :from wallet
              :left-join addresses :on (= addr raw)])
    (seq-map
     (-lambda ((monitor address note path))
       (list path
             (vector
              (if monitor "YES" "NO")
              address
              (substring address -8)
              (or note path)))))
    (setq tabulated-list-entries)))

(defun cardano-wallet-address--refresh-query (&optional _arg _noconfirm)
  "Query for registered addresses and `revert-buffer'."
  (cardano-wallet
   (format "wallets/%s/addresses" (cardano-wallet-id cardano-wallet-current))
   (lambda (json-response)
     (with-current-buffer (get-buffer "*Cardano Wallet Addresses*")
       (setq cardano-wallet--buffer-response json-response)
       (run-hooks 'tabulated-list-revert-hook)
       (tabulated-list-print 'remember)))))

(defun cardano-wallet-derive-files-for-address ()
  "For address in line, derive and save verification key.  Register address."
  (interactive)
  (when-let ((fingerprint
              (-some-> cardano-wallet-current
                (cardano-wallet-id)
                (substring 0 8))))
    (cardano-wallet--derive-and-load
     fingerprint
     (list (cardano-tx-hw--key-spec fingerprint (tabulated-list-get-id))))
    (forward-line)
    (cardano-wallet-addresses--refresh)
    (tabulated-list-print t)))

(defun cardano-wallet-addresses (wallet)
  "Show addresses for WALLET."
  (interactive (list (tabulated-list-get-id)))
  (with-current-buffer (get-buffer-create "*Cardano Wallet Addresses*")
    (cardano-tx-db-addresses-mode)
    (setq-local cardano-wallet-current wallet)
    (use-local-map (copy-keymap cardano-tx-db-addresses-mode-map))
    (local-set-key "i" #'cardano-wallet-derive-files-for-address)
    (add-hook 'tabulated-list-revert-hook #'cardano-wallet-addresses--refresh nil t)
    (setq revert-buffer-function #'cardano-wallet-address--refresh-query)
    (cardano-wallet-address--refresh-query)
    (display-buffer (current-buffer))))

(defun cardano-wallet-addresses--keys-left-to-register (wallet-id)
  "Register missing the keys for used addresses from WALLET-ID."
  (cardano-wallet
   (format "wallets/%s/addresses" wallet-id)
   (lambda (json)
     (let ((fingerprint (substring wallet-id 0 8)))
       (thread-last
         json
         (mapcar
          (-lambda ((&alist 'state 'derivation_path))
            (when (string= state "used")
              (cardano-tx-hw--key-spec fingerprint (string-join (seq-drop derivation_path 3) "/")))))
         (delq nil)
         (cardano-wallet--derive-and-load fingerprint))))))

;;; Wallet Main Control
(defun cardano-wallet-sort-readable-number (column)
  "Generate a sort function for `tabulated-list' readable number at COLUMN."
  (cl-flet ((value (entry)
                   (thread-last
                     (aref (cadr entry) column)
                     (replace-regexp-in-string "_" "")
                     (string-to-number))))
    (lambda (e1 e2) (> (value e1) (value e2)))))

(cl-defstruct (cardano-wallet (:constructor cardano-wallet--create)
                              (:copier nil))
  "Wallet information"
  id
  name
  balance
  rewards
  assets
  delegation)

(defun cardano-wallet-total (entry)
  "Total available balance of ENTRY."
  (+ (cardano-wallet-balance entry)
     (cardano-wallet-rewards entry)))

(defun cardano-wallet-parse (entry)
  "Extract from json ENTRY into struct."
  (cardano-wallet--create
   :id (cardano-tx-get-in entry "id")
   :name (cardano-tx-get-in entry "name")
   :balance (cardano-tx-get-in entry "balance" "available" "quantity")
   :rewards (cardano-tx-get-in entry "balance" "reward" "quantity")
   :assets     (cardano-tx-get-in entry "assets" "total")
   :delegation (cardano-tx-get-in entry "delegation" "active" "target")))

(defun cardano-wallet-sort (slot)
  "Return function to sort entries by SLOT."
  (cl-flet ((vals (entry) (funcall (cl-ecase slot
                                     (balance #'cardano-wallet-balance)
                                     (rewards #'cardano-wallet-rewards)
                                     (total #'cardano-wallet-total))
                                   (car entry))))
    (lambda (e1 e2)
      (< (vals e1) (vals e2)))))

(defun cardano-wallet--balance-row (entry)
  "Extract values from ENTRY to display a balance row."
  (let ((balance (cardano-wallet-balance entry))
        (rewards (cardano-wallet-rewards entry)))
    (vector
     (cardano-wallet-name entry)
     (cardano-wallet-id entry)
     (cardano-wallet-readable-number (+ balance rewards))
     (cardano-wallet-readable-number balance)
     (cardano-wallet-readable-number rewards)
     (if (seq-empty-p (cardano-wallet-assets entry))
         "NO" "YES")
     (or (cardano-wallet-delegation entry) "None"))))

(defun cardano-wallet-balances--refresh ()
  "Query Cardano Wallet for wallet balances then refresh buffer with new entries."
  (cardano-wallet
   "wallets"
   (lambda (json-response)
     (with-current-buffer (get-buffer-create "*Cardano Wallet balances*")
       (->> json-response
            (seq-map #'cardano-wallet-parse)
            (seq-map
             (lambda (entry)
               (list entry (cardano-wallet--balance-row entry))))
            (setq tabulated-list-entries))
       (tabulated-list-print 'remember)))))

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
  (setq tabulated-list-format `[("Name" 26 t)
                                ("ID" 10 t)
                                ("Total" 15 ,(cardano-wallet-sort 'total) :right-align t)
                                ("Available" 15 ,(cardano-wallet-sort 'balance) :right-align t)
                                ("Reward" 13 ,(cardano-wallet-sort 'rewards) :right-align t)
                                ("Assets" 6 t)
                                ("Delegation" 0 t)])
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
                 :candidates (--map (cons (cardano-tx-get-in it "name")
                                          (cardano-wallet-parse it))
                                    json)
                 :action (helm-make-actions
                          "Payment" #'cardano-wallet-tx-new
                          "Get addresses" #'cardano-wallet-addresses
                          "Get transaction log" #'cardano-wallet-tx-log
                          "Describe wallet" #'cardano-wallet-describe
                          "Delete wallet" #'cardano-wallet-delete))))))

(defun cardano-wallet-describe (wallet)
  "Pop buffer describing WALLET."
  (interactive (list (tabulated-list-get-id)))
  (cardano-wallet
   (format "wallets/%s/" (cardano-wallet-id wallet))
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
  (cl-flet ((sorter (col) (cardano-wallet-sort-readable-number col)))
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
  (->> cardano-wallet--buffer-response
       (seq-map
        (lambda (res)
          (vector
           (cardano-tx-get-in res "id")
           (cardano-tx-get-in res "inserted_at" "time")
           (cardano-wallet-readable-number (cardano-tx-get-in res "fee" "quantity"))
           (apply #'propertize
                  (cardano-wallet-readable-number (cardano-tx-get-in res "amount" "quantity"))
                  (unless (string= "incoming" (cardano-tx-get-in res "direction"))
                    (list 'face 'font-lock-keyword-face))))))
       (emacsql (cardano-tx-db)
                [:with log [id date fee amount] :as [:values $v1]
                 :select [id date fee amount (funcall ifnull annotation "")] :from tx-annotation
                 :right-join log :on (= id txid)
                 :order-by [(desc date)]])
       (seq-map
        (-lambda ((id date fee amount annotation))
          (list id
                (vector date id fee amount (car (split-string annotation "\n"))))))
       (setq tabulated-list-entries)))

(defun cardano-wallet-tx-log--refresh-query (&optional _arg _noconfirm)
  "Query for registered transactions and `revert-buffer'."
  (cardano-wallet
   (format "wallets/%s/transactions"
           (cardano-wallet-id cardano-wallet-current))
   (lambda (json-response)
     (with-current-buffer (get-buffer "*Cardano Wallet Transactions*")
       (setq cardano-wallet--buffer-response json-response)
       (run-hooks 'tabulated-list-revert-hook)
       (tabulated-list-print 'remember)))))

(defun cardano-wallet-tx-log (wallet)
  "Show Transactions in WALLET."
  (interactive (list (tabulated-list-get-id)))
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
    (cardano-wallet-id cardano-wallet-current)
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

(defun cardano-wallet-hw-register ()
  "Register a new wallet from the known extended public key accounts."
  (interactive)
  (seq-let (name _id _fingerprint _note data) (cardano-tx-hw--master-keys)
    (cardano-tx-address--new-hd-key data "2/0")
    (thread-last
      data
      (bech32-decode)
      (cdr)
      (apply #'unibyte-string)
      (encode-hex-string)
      (cardano-wallet-monitor (car (split-string name))))))

(defun cardano-wallet-delete (wallet)
  "Delete WALLET."
  (interactive (list (tabulated-list-get-id)))
  (let ((wallet-id (cardano-wallet-id wallet)))
    (when (yes-or-no-p (format "Really delete wallet '%s' with id '%s'?"
                               (upcase (cardano-wallet-name wallet)) wallet-id))
      (cardano-wallet
       (concat "wallets/" wallet-id)
       (lambda (_x)
         (message "Wallet %s deleted." wallet-id)
         (cardano-wallet-balances--refresh)
         (tabulated-list-print))
       "DELETE"))))

(defun cardano-wallet-process-tx (wallet json)
  "From HW WALLET and JSON response of wallet-tx constructor sign all inputs."
  (interactive
   (list cardano-wallet-current cardano-wallet--buffer-response))
  (let ((filename (cardano-wallet--write-tx (cardano-tx-get-in json 'transaction))))
    (thread-last
      (cardano-tx-get-in json 'coin_selection 'inputs)
      (mapcar
       (-lambda ((&alist 'derivation_path))
         (cardano-tx-hw--key-spec
          (substring (cardano-wallet-id wallet) 0 8)
          (string-join (seq-drop derivation_path 3) "/"))))
      (cardano-tx-hw--signing-files)
      (list nil)
      (cardano-tx-sign filename)
      (cardano-tx-submit)
      (run-at-time 30 nil #'cardano-wallet-addresses--keys-left-to-register (cardano-wallet-id wallet)))))

(defun cardano-wallet-tx-finish ()
  "Process buffer into a transaction, sign it and open PREVIEW."
  (interactive)
  (let* ((wallet cardano-wallet-current)
         (input-data (cardano-tx--input-buffer))
         (outputs (cardano-tx-get-in input-data 'outputs))
         (hw-p (when (string-match (rx "[" (= 8 hex) "]HW") (cardano-wallet-name cardano-wallet-current))
                 "Hardware Wallet")))
    (cardano-wallet
     (format "wallets/%s/transactions%s"
             (cardano-wallet-id wallet)
             (if hw-p "-construct" ""))
     (lambda (json)
       (let ((window (cardano-wallet-show json)))
         (when hw-p
           (with-current-buffer (window-buffer window)
             (setq-local cardano-wallet--buffer-response json)
             (setq-local cardano-wallet-current wallet)
             (local-set-key (kbd "C-c C-s") #'cardano-wallet-process-tx)))))
     "POST"
     `(:payments ,(cl-map 'vector #'cardano-wallet-payment outputs)
       :encoding "base16"
       :passphrase ,(or hw-p (read-passwd "Password to unlock your wallet: "))))))

(defun cardano-wallet--write-tx (cborHex)
  "Write CBORHEX as transaction file."
  (let ((type "Unwitnessed Tx BabbageEra")
        (description "Ledger Cddl Format")
        (filename (make-temp-file "cardano-tx-")))
    (cardano-tx-write-json (cardano-tx-alist type description cborHex) filename)
    filename))

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
                          :asset_name (encode-hex-string tokenname)
                          :quantity amount)))))))

(defun cardano-wallet-tx-new (wallet)
  "Open an editor to create a new transaction for WALLET."
  (interactive (list (tabulated-list-get-id)))
  (with-current-buffer (generate-new-buffer "*Cardano tx*")
    (insert "# -*- mode: cardano-tx; -*-\n\n")
    (cardano-tx-mode)
    (setq-local cardano-wallet-current wallet)
    (yas-expand-snippet (yas-lookup-snippet 'wallet-spend))
    (use-local-map (copy-keymap cardano-tx-mode-map))
    (local-set-key (kbd "C-c C-c") #'cardano-wallet-tx-finish)
    (message "Press %s to build and send transaction."
             (substitute-command-keys "\\[cardano-wallet-tx-finish]"))
    (switch-to-buffer (current-buffer))))

(defun cardano-wallet-tx-assets-pick ()
  "Load assets available on wallet to `kill-ring'."
  (interactive)
  (->> (cardano-wallet-assets cardano-wallet-current)
       (--map
        (let ((policy (cardano-tx-get-in it "policy_id"))
              (assetname (decode-hex-string (cardano-tx-get-in it "asset_name")))
              (quantity (cardano-tx-get-in it "quantity")))
          (list (format "%s:\n%S: %d" policy assetname quantity)
                policy assetname quantity)))
       (cardano-tx-pick "Assets")
       (cardano-tx-assets-group-tokens)
       (cardano-tx-assets-format-tokens)
       (replace-regexp-in-string "^" "      ")
       (kill-new)))

(provide 'cardano-wallet)
;;; cardano-wallet.el ends here
