;;; ouroboros.el --- Ouroboros network mini-protocol -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Óscar Nájera
;;
;; Author: Oscar Najera <https://oscarnajera.com>
;; Maintainer: Oscar Najera <hi@oscarnajera.com>
;; Version: 0.1.2
;; Package-Version: 20230606.1150
;; Package-Commit: cf85424b305e8f89debb756dc67eebc84639f711
;; Homepage: https://github.com/Titan-C/cardano.el
;; Package-Requires: ((emacs "27.1") (dash "2.19.0") (cbor "0.2.5") (bech32 "0.2.1"))
;;
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
;;  Implements the Ouroboros Network mini-protocols to communicate with Cardano
;;
;;; Code:

(require 'time-date)
(require 'dash)
(require 'cbor)
(require 'bech32)

(defconst ouroboros-protocols '((hand-shake . 0)
                                (chain-sync . 5)
                                (local-tx-submission . 6)
                                (local-state-query . 7)))

(defconst ouroboros-hard-fork-eras
  '(Byron
    Shelley
    Allegra
    Mary
    Alonzo
    Babbage))

(cl-defstruct (ouroboros-network (:constructor ouroboros-network--create)
                                 (:copier nil))
  "A connection to a node."
  process network-magic version type era)

(defun ouroboros-connect (remote network-magic)
  "Create a connection to a node in REMOTE.
Specify the NETWORK-MAGIC."
  (let ((type (pcase remote
                ((pred vectorp) 'node-to-node)
                ((pred stringp) 'client-to-node)
                (_ (user-error "Invalid remote")))))
    (ouroboros-handshake
     (ouroboros-network--create :network-magic network-magic
                                :type type
                                :process
                                (make-network-process
                                 :name (format "Ouroboros-mini %s" type)
                                 :remote remote
                                 :coding '(binary . binary)
                                 :filter (lambda (_process string)
                                           (with-temp-buffer
                                             (set-buffer-multibyte nil)
                                             (insert string)
                                             (goto-char (point-min))
                                             (while (> (point-max) (point))
                                               (ouroboros-collect-reply!))))
                                 :sentinel (lambda (process event)
                                             (message "Process: %s had the event '%s'" process event)))))))

(defun ouroboros-close (connection)
  "Close TCP connection in CONNECTION."
  (when-let ((process (ouroboros-network-process connection))
             (active (process-live-p process)))
    (process-send-eof process)))

(defun ouroboros-send-payload! (connection protocol data)
  "Send over CONNECTION for PROTOCOL the Lisp DATA."
  (let ((proc (ouroboros-network-process connection))
        (msg-protocol (or (cdr (assq protocol ouroboros-protocols))
                          (user-error "Invalid protocol %S" protocol)))
        (payload (cbor<-elisp data))
        (receiving-buffer (get-buffer-create (format "*ouroboros %s*" protocol)))
        (time (-> (get-internal-run-time) (time-to-seconds) (* 1000) (floor))))
    (with-current-buffer receiving-buffer
      (erase-buffer)
      (set-buffer-multibyte nil))
    (with-temp-buffer
      (set-buffer-multibyte nil)
      (insert
       (concat
        (cbor--luint time 4)
        (cbor--luint msg-protocol 2)
        (cbor--luint (length payload) 2)))
      (insert payload)
      (process-send-region proc (point-min) (point-max)))))

(defun ouroboros-collect-reply! ()
  "Filter for PROCESS CONTENT messages from server."
  (let* ((_ts (cbor--get-ints (cbor--consume! 4)))
         (id (cbor--get-ints (cbor--consume! 2)))
         (size (cbor--get-ints (cbor--consume! 2)))
         (protocol (-> (logxor #x8000 id) ;; remove server reply flag
                       (rassq ouroboros-protocols)
                       (car)))
         (payload (buffer-substring (point) (+ (point) size)))
         (buff (get-buffer-create (format "*ouroboros %s*" protocol))))
    (with-current-buffer buff (insert payload))
    (goto-char (+ (point) size))))

(defun ouroboros-parse-reply (buffer)
  "CBOR parse BUFFER."
  (prog1
      (with-current-buffer buffer
        (goto-char (point-min))
        (cbor--get-data-item!))
    (kill-buffer buffer)))

;;; HandShake mini-protocol

(defun ouroboros-handshake (connection)
  "Handle handshake over CONNECTION."
  (let ((proc (ouroboros-network-process connection)))
    (ouroboros-send-payload! connection 'hand-shake
                             (ouroboros-propose-versions connection))
    (accept-process-output proc)
    (when-let* ((rebu (get-buffer-create (format "*ouroboros %s*" 'hand-shake)))
                (reply (ouroboros-handshake-reply (ouroboros-network-type connection)
                                                  (ouroboros-parse-reply rebu))))
      (setf (ouroboros-network-version connection) reply)
      connection)))

(defun ouroboros-handshake-reply (connection-type reply)
  "Process handshake REPLY of CONNECTION-TYPE."
  (cl-flet ((rever (num)
                   (pcase connection-type
                     ('node-to-node num)
                     ('client-to-node (if (= 1 num) 1 (logxor #x8000 num))))))
    (pcase reply
      (`[1 ,version ,_magic] (rever version)) ;; accept
      (`[2 ,reason]
       (->> (pcase reason
              (`[0 ,vers]
               (format "Version Mismatch. Available versions: %S"
                       (seq-map #'rever vers)))
              (`[1 ,version ,str]
               (format "Decode error. Version: %d, Reason: %s" (rever version) str))
              (`[2 ,version ,str]
               (format "Refused. Version: %d, Reason: %s" (rever version) str)))
            (user-error "Handshake Fail: %s"))))))

(defun ouroboros-propose-versions (connection)
  "Propose supported versions CONNECTION."
  (let ((magic (ouroboros-network-network-magic connection))
        (type (ouroboros-network-type connection)))
    (vector 0 ;;Propose Version
            (pcase type
              ('client-to-node
               ;; Non - overlapping between nodes 1.34.1 & 1.35
               `((,(logxor #x8000 10) . ,magic)
                 (,(logxor #x8000 13) . ,magic)))
              ('node-to-node `((10 . [,magic t])))
              (_ (user-error "Wrong connection type %s" type))))))

;;; Local State Query mini-protocol
(defun ouroboros-local (connection msg &optional arg)
  "Handle local state query over CONNECTION using MSG and ARG."
  (let ((proc (ouroboros-network-process connection))
        (parsed-arg (if (eq 'query msg)
                        (car (ouroboros-local-query connection arg))
                      arg)))
    (ouroboros-send-payload!
     connection
     'local-state-query
     (ouroboros-local-state--queries msg parsed-arg))
    (unless (memq msg '(release done))
      (let ((rebu (get-buffer-create (format "*ouroboros %s*" 'local-state-query)))
            (blen 0))
        (cl-loop  do (accept-process-output proc 0.5)
                  until (or (< 0 (buffer-size rebu) 12288) (= blen (buffer-size rebu)))
                  do (setq blen (buffer-size rebu)))
        (when-let ((result (ouroboros-local-reply (ouroboros-parse-reply rebu))))
          (if (eq 'query msg)
              (cdr (ouroboros-local-query connection arg result))
            result))))))

(defun ouroboros-local-reply (reply)
  "Process local state query REPLY."
  (pcase reply
    ('[1] 'Acquired)
    ('[2 0] '(Failure point-too-old))
    ('[2 1] '(Failure point-not-on-chain))
    (`[4 ,result] result)))

(defun ouroboros-local-state--queries (msg &optional arg)
  "Translate MSG to primitive form including ARG."
  (pcase msg
    ('acquire (if (eq arg 'tip) [8] (vector 0 arg))) ;; check arg is of type point on second vector
    ('query (vector 3 arg))
    ('release [5])
    ('reacquire (if (eq arg 'tip) [9] (vector 6 arg)))
    ('done [7])
    (_ (user-error "Invalid message %s" msg))))

(defun ouroboros-local-query (connection query &optional result)
  "Translation table for QUERY and RESULT given CONNECTION."
  (pcase query
    ('system-start
     (cons [1] (pcase result
                 (`[,year ,day ,picosecs]
                  (let ((time (-> (date-ordinal-to-time year day)
                                  (decoded-time-set-defaults 0))))
                    (decoded-time--alter-second time (* picosecs (expt 10 -12)))
                    (format-time-string
                     "%Y-%m-%dT%T%z"
                     (encode-time time) t))))))
    ('block-no
     (cons [2] (pcase result (`[,unk ,block-no] `(:unk ,unk :block-no ,block-no)))))
    ('chain-point
     (cons [3] (pcase result (`[,slot-no ,hash] `(:slot-no ,slot-no :hash ,hash)))))
    ('hard-fork-eras
     (cons [0 [2 [0]]] result))
    ('current-era
     (cons [0 [2 [1]]] (when result (nth result ouroboros-hard-fork-eras))))
    (`(shelley ,target . ,args)
     (cons (ouroboros-wrap-shelley-query connection target args)
           (and result (ouroboros-shelley-response target (aref result 0)))))
    ((and rest (pred vectorp))
     (cons rest result))
    (_ (user-error "Invalid query %S" query))))

(defun ouroboros-wrap-shelley-query (connection query &optional args)
  "Depending on CONNECTION wrap QUERY and ARGS."
  (if-let (era (-elem-index (ouroboros-network-era connection) ouroboros-hard-fork-eras))
      `[0 [0 [,era ,(ouroboros-shelley-query query args)]]]
    (setf (ouroboros-network-era connection) (ouroboros-local connection 'query 'current-era))
    (ouroboros-wrap-shelley-query connection query args)))

(defun ouroboros-shelley-query (query &optional args)
  "Translate QUERY with ARGS into primitives."
  (pcase query
    ('ledger-tip [0])
    ('epoch-no [1])
    ('non-myopic-member-rewards (vector 2 (car args)))
    ('current-params [3])
    ('proposed-params [4])
    ('stake-distribution [5])
    ('utxo-by-address (vector 6 (car args)))
    ('utxo-whole [7])
    ('debug-epoch-state [8])
    ('cbor-wrap (vector 9 (ouroboros-shelley-query (car args) (cdr args))))
    ('filtered-delegations-and-reward-accounts (vector 10 (car args)))
    ('genesis-config [11])
    ('debug-new-epoch-state [12])
    ('debug-chain-dep-state [13])
    ('reward-provenance [14])
    ('utxo-by-tx-in (vector 15 (car args)))
    ('stake-pools [16])
    ('stake-pool-params (vector 17 (car args)))
    ('reward-info-pools [18])
    (_ (user-error "Invalid Shelley query: %s" query))))

(defun ouroboros-shelley-response (query result)
  "Parse QUERY RESULT."
  (pcase query
    ('ledger-tip (pcase result (`[,slot-no ,hash] `(:slot-no ,slot-no :hash ,hash))))
    ('epoch-no result)
    ('filtered-delegations-and-reward-accounts (ouroboros-rewards-collect result))
    (_ result)))

(defun ouroboros-rewards-collect (result)
  "Give readable structure to RESULT of reward-accounts query."
  (-let (([del rw] result))
    (mapcar (-lambda ((stk . poolid))
              (list (cons "address" stk)
                    (cons "delegation" (bech32-encode "pool" (string-to-list (decode-hex-string poolid))))
                    (cons "rewardAccountBalance" (cdr (assoc stk rw)))))
            del)))

(defun ouroboros-serialize-utxo (utxo)
  "Vector serialize UTXO."
  (string-match
   (rx bol (group (= 64 hex)) "#" (group (+ digit)) eol)
   utxo)
  (vector
   (match-string 1 utxo)
   (string-to-number (match-string 2 utxo))))

(defun ouroboros-utxo (utxos)
  "Query UTXOS wrapper."
  (cbor-tag-create
   :number 258
   :content
   (cl-map 'vector
           #'ouroboros-serialize-utxo
           (sort utxos #'string<))))

(defun ouroboros-non-myopic-stake (stake-list)
  "Query STAKE-LIST being each amount of lovelace willing to stake."
  (->> (sort stake-list #'<)
       (cl-map 'vector (lambda (a) (vector 0 a)))
       (cbor-tag-create :number 258 :content)))

(defun ouroboros-reward-addresses (reward-addresses)
  "Query the REWARD-ADDRESSES wrapper."
  (->>
   (sort (mapcar (lambda (stk-addr)
                   (-let (((_hrp type . data) (bech32-decode stk-addr)))
                     (cons
                      (if (bech32-test-bit type 4) 0 1) ;; scripts must rank lower
                      data)))
                 reward-addresses)
         (lambda (a b) (< (cbor--get-ints a) (cbor--get-ints b))))
   (cl-map 'vector
           (lambda (data)
             (vector
              (if (= 0 (car data)) 1 0) ;; flip back scripts to flag with 1
              (-> data (cdr) (concat) (encode-hex-string)))))
   (cbor-tag-create
    :number 258
    :content)))

(defun ouroboros-addr-comp (one two)
  "String comparison of addresses ONE and TWO."
  (cl-flet ((ord-str (str)
                     (let* ((head (string-to-number (substring str 0 2) 16))
                            (netword-id (logand 15 head))
                            (addr-type (ash head -4)))
                       (concat (number-to-string netword-id)
                               (if (bech32-test-bit addr-type 0) "A" "B") ;; Has script first
                               (substring str 2 58)
                               (if (= #b011 (ash addr-type -1)) "D" "C") ;; Is enterprise Second
                               (substring str 58)))))
    (string< (ord-str one) (ord-str two))))

(defun ouroboros-address-query (addresses)
  "Query the UTxOs in ADDRESSES wrapper."
  (cbor-tag-create
   :number 258
   :content
   (apply #'vector
          (sort (mapcar
                 (lambda (address)
                   (-> (bech32-decode address)
                       cdr
                       concat
                       (encode-hex-string)))
                 addresses)
                #'ouroboros-addr-comp))))

(defun ouroboros-display-obj (obj)
  "Display in new buffer the given OBJ pretty printed."
  (with-current-buffer (get-buffer-create "*Lisp Display*")
    (erase-buffer)
    (pp obj (current-buffer))
    (emacs-lisp-mode)
    (display-buffer (current-buffer))))

(provide 'ouroboros)
;;; ouroboros.el ends here
