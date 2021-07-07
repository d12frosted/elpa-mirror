;;; kaesar.el --- Another AES algorithm encrypt/decrypt string with password.

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: data
;; Package-Version: 20160128.1008
;; Package-Commit: d087075cb1a46c2c85cd075220e09b2eaef9b86e
;; URL: https://github.com/mhayashi1120/Emacs-kaesar
;; Emacs: GNU Emacs 23 or later
;; Version: 0.9.3
;; Package-Requires: ((cl-lib "0.3"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; AES (Rijndael) implementations for Emacs

;; This package provides AES algorithm to encrypt/decrypt Emacs
;; string. Supported algorithm desired to get interoperability with
;; openssl command. You can get decrypted text by that command if
;; you won't forget password.

;; ## Install:

;; Put this file into load-path'ed directory, and
;; ___!!!!!!!!!!!!!!! BYTE COMPILE IT !!!!!!!!!!!!!!!___
;; And put the following expression into your .emacs.

;;     (require 'kaesar)

;; ## Usage:

;; * To encrypt a well encoded string (High level API)
;; `kaesar-encrypt-string' <-> `kaesar-decrypt-string'

;; * To encrypt a unibyte string with algorithm (Middle level API)
;; `kaesar-encrypt-bytes' <-> `kaesar-decrypt-bytes'

;; * To encrypt a unibyte with algorithm (Low level API)
;; `kaesar-encrypt' <-> `kaesar-decrypt'

;; ## Sample:

;; * To encrypt my secret
;;   Please ensure that do not forget `clear-string' you want to hide.

;;     (defvar my-secret nil)

;;     (let ((raw-string "My Secret"))
;;       (setq my-secret (kaesar-encrypt-string raw-string))
;;       (clear-string raw-string))

;; * To decrypt `my-secret'

;;     (kaesar-decrypt-string my-secret)

;; ## NOTE:

;; Why kaesar?
;; This package previously named `cipher/aes` but ELPA cannot handle
;; such package name.  So, I had to change the name but `aes` package
;; already exists. (That is faster than this package!)  I continue to
;; consider the new name which contains "aes" string. There is the
;; ancient cipher algorithm caesar
;; http://en.wikipedia.org/wiki/Caesar_cipher
;;  K`aes`ar is change the first character of Caesar. There is no
;; meaning more than containing `aes` word.

;; How to suppress password prompt?
;; There is no official way to suppress that prompt. If you want to
;; know more information, please read `kaesar-password` doc string.

;;; TODO:
;; * about algorithm
;; http://csrc.nist.gov/archive/aes/rijndael/wsdindex.html
;; Rijndael algorithm

;; * Block mode (OpenSSL 1.0.1e support followings)
;; done: ecb, cbc, ctr, ofb, cfb
;; todo: cfb1, cfb8, gcm

;; * validation -> AESAVS.pdf

;; * consider threshold of encrypt size

;; * cleanup raw key and expanded key

;;; Code:

(require 'cl-lib)

(defgroup kaesar nil
  "Encrypt/Decrypt string with password"
  :prefix "kaesar-"
  :group 'data)

(defcustom kaesar-algorithm "aes-256-cbc"
  "Cipher default algorithm to encrypt/decrypt a message.
Following algorithms are supported.

aes-256-ecb, aes-192-ecb, aes-128-ecb,
aes-256-cbc, aes-192-cbc, aes-128-cbc,
aes-256-ofb, aes-192-ofb, aes-128-ofb,
aes-256-ctr, aes-192-ctr, aes-128-ctr
"
  :group 'kaesar
  :type '(choice
          (const "aes-128-ecb")
          (const "aes-192-ecb")
          (const "aes-256-ecb")
          (const "aes-128-cbc")
          (const "aes-192-cbc")
          (const "aes-256-cbc")
          (const "aes-128-ofb")
          (const "aes-192-ofb")
          (const "aes-256-ofb")
          (const "aes-128-ctr")
          (const "aes-192-ctr")
          (const "aes-256-ctr")))

(defcustom kaesar-encrypt-prompt nil
  "Password prompt when read password to encrypt. This variable
intend to use with locally bound."
  :group 'kaesar
  :type 'string)

(defcustom kaesar-decrypt-prompt nil
  "Password prompt when read password to decrypt.This variable
intend to use with locally bound."
  :group 'kaesar
  :type 'string)

(defvar kaesar--encoder)
(defvar kaesar--decoder)
(defvar kaesar--check-before-decrypt)

(defvar kaesar-password nil
  "Hold the password temporarily to suppress the minibuffer
prompt with locally bound. This value will be erased immediately
from memory after creating AES key. This is a hiding parameter,
so intentionally make hard to use.")

(defun kaesar--read-passwd (prompt &optional confirm)
  "Read password as a vector which hold byte and clear raw password
from memory."
  (let (source)
    (cond
     ((and (vectorp kaesar-password)
           (ignore-errors (kaesar--check-unibyte-vector kaesar-password)))
      ;; do not clear external password.
      (setq source kaesar-password))
     ((and (stringp kaesar-password)
           ;; only accept ascii
           (string-match "\\`[\000-\177]+\\'" kaesar-password))
      (setq source kaesar-password))
     (t
      (setq source (read-passwd prompt confirm))))
    (prog1
        (vconcat source)
      (fillarray source 0)
      ;; reset the hiden parameter too.
      ;; if not clear, password may be a NULL filled text
      ;; unconciously.
      (setq kaesar-password nil))))

;; Basic utilities

(eval-when-compile
  (defsubst kaesar--word-xor! (word1 word2)
    (aset word1 0 (logxor (aref word1 0) (aref word2 0)))
    (aset word1 1 (logxor (aref word1 1) (aref word2 1)))
    (aset word1 2 (logxor (aref word1 2) (aref word2 2)))
    (aset word1 3 (logxor (aref word1 3) (aref word2 3)))))

(eval-when-compile
  (defun kaesar--byte-rot (byte count)
    (let ((v (lsh byte count)))
      (logior
       (logand ?\xff v)
       (lsh (logand ?\xff00 v) -8)))))

;; Algorithm specifications

;; AES-128: Nk 4 Nb 4 Nr 10
;; AES-192: Nk 6 Nb 4 Nr 12
;; AES-256: Nk 8 Nb 4 Nr 14
(defconst kaesar--cipher-algorithm-alist
  '(
    (aes-128 4 4 10)
    (aes-192 6 4 12)
    (aes-256 8 4 14)
    ))

;; Block size
(eval-and-compile
  (defconst kaesar--Nb 4
    "kaesar support only 4 Number of Blocks"))

;; Key length
(defvar kaesar--Nk 8)

;; Number of rounds
(defvar kaesar--Nr 14)

;; count of row in State
(eval-and-compile
  (defconst kaesar--Row 4))

;; size of State
(eval-and-compile
  (defconst kaesar--Block
    (* kaesar--Nb kaesar--Row)))

;; size of IV (Initial Vector)
(defvar kaesar--IV kaesar--Block)

(eval-and-compile
  (defconst kaesar--block-algorithm-alist
    `(
      ;; Electronic CodeBook
      (ecb
       kaesar--ecb-encrypt kaesar--ecb-decrypt
       kaesar--check-block-bytes 0)
      ;; Cipher Block Chaining
      (cbc
       kaesar--cbc-encrypt kaesar--cbc-decrypt
       kaesar--check-block-bytes ,kaesar--Block)
      ;; Output FeedBack
      (ofb
       kaesar--ofb-encrypt kaesar--ofb-encrypt
       nil ,kaesar--Block)

      ;; CounTeR (Other word, `KAK' Key Auto-Key)
      (ctr
       kaesar--ctr-encrypt kaesar--ctr-encrypt
       nil ,kaesar--Block)

      ;; Cipher FeedBack
      (cfb
       kaesar--cfb-encrypt kaesar--cfb-decrypt
       nil ,kaesar--Block)
      )))

(eval-and-compile
  (defconst kaesar--pkcs5-salt-length 8))

(defconst kaesar--algorithm-regexp
  (eval-when-compile
    (concat
     "\\`"
     "\\("
     "aes-"
     (regexp-opt '("128" "192" "256"))
     "\\)"
     "-"
     (regexp-opt
      (mapcar
       (lambda (p)
         (symbol-name (car p)))
       kaesar--block-algorithm-alist) t)
     "\\'")))

(defun kaesar--parse-algorithm (name)
  (unless (string-match kaesar--algorithm-regexp name)
    (error "%s is not supported" name))
  (list (intern (match-string 1 name))
        (intern (match-string 2 name))))

(defmacro kaesar--cipher-algorithm (algorithm &rest form)
  (declare (indent 1))
  (let ((cell (make-symbol "cell")))
    `(let ((,cell (assq ,algorithm kaesar--cipher-algorithm-alist)))
       (unless ,cell
         (error "%s is not supported" ,algorithm))
       (let* ((kaesar--Nk (nth 1 ,cell))
              ;; kaesar--Nb is constant
              ;; (kaesar--Nb (nth 2 ,cell))
              (kaesar--Nr (nth 3 ,cell))
              ;; kaesar--Block is constant
              ;; (kaesar--Block (* kaesar--Nb kaesar--Row))
              )
         ,@form))))

(defmacro kaesar--block-algorithm (algorithm &rest form)
  (declare (indent 1))
  (let ((cell (make-symbol "cell")))
    `(let ((,cell (assq ,algorithm kaesar--block-algorithm-alist)))
       (unless ,cell
         (error "%s is not supported" ,algorithm))
       (let* ((kaesar--encoder (nth 1 ,cell))
              (kaesar--decoder (nth 2 ,cell))
              (kaesar--check-before-decrypt (nth 3 ,cell))
              (kaesar--IV (nth 4 ,cell)))
         ,@form))))

(defmacro kaesar--with-algorithm (algorithm &rest form)
  (declare (indent 1))
  (let ((cipher (make-symbol "cipher"))
        (block-mode (make-symbol "block-mode"))
        (algo-var (make-symbol "algo-var")))
    `(let ((,algo-var (or ,algorithm kaesar-algorithm)))
       (cl-destructuring-bind (,cipher ,block-mode)
           (kaesar--parse-algorithm ,algo-var)
         (kaesar--cipher-algorithm ,cipher
           (kaesar--block-algorithm ,block-mode
             ,@form))))))

;;
;; bit/byte/number operation for Emacs
;;

(defun kaesar--construct-state ()
  (cl-loop for r from 0 below kaesar--Row
           with state = (make-vector kaesar--Row nil)
           do (cl-loop repeat kaesar--Row
                       with word = (make-vector kaesar--Nb nil)
                       do (aset state r word))
           finally return state))

(defun kaesar--unibytes-to-state (unibytes start)
  (cl-loop for r from 0 below kaesar--Row
           with state = (make-vector kaesar--Row nil)
           with i = start
           with len = (length unibytes)
           do (cl-loop for c from 0 below kaesar--Nb
                       with word = (make-vector kaesar--Nb nil)
                       initially (aset state r word)
                       ;; word in unibytes
                       ;; if unibytes are before encrypted,
                       ;;  state suffixed by length of rest of State
                       do (cond
                           ((= i len)
                            (aset word c (- kaesar--Block (- i start))))
                           (t
                            (aset word c (aref unibytes i))
                            (setq i (1+ i)))))
           finally return state))

(eval-when-compile
  (defsubst kaesar--load-state! (state unibytes start)
    (cl-loop for word across state
             with i = start
             with len = (length unibytes)
             do (cl-loop for b from 0 below (length word)
                         do (progn
                              (cond
                               ((= i len)
                                (aset word b (- kaesar--Block (- i start))))
                               (t
                                (aset word b (aref unibytes i))
                                (setq i (1+ i))))))
             finally return state)))

(eval-when-compile
  (defsubst kaesar--load-unibytes! (state unibyte-string pos)
    (let* ((len (length unibyte-string))
           (end-pos (min len (+ pos kaesar--Block)))
           (state (kaesar--load-state! state unibyte-string pos))
           (rest (if (and (= len end-pos)
                          (< (- end-pos pos) kaesar--Block))
                     nil end-pos)))
      rest)))

(eval-when-compile
  (defsubst kaesar--load-encbytes! (state unibyte-string pos)
    (let* ((len (length unibyte-string))
           (end-pos (min len (+ pos kaesar--Block)))
           (state (kaesar--load-state! state unibyte-string pos))
           (rest (if (= len end-pos) nil end-pos)))
      rest)))

(eval-when-compile
  (defsubst kaesar--state-to-bytes (state)
    (let (res)
      (mapc
       (lambda (word)
         (setq res (nconc res (append word nil))))
       state)
      res)))

(eval-when-compile
  (defsubst kaesar--state-copy! (dst src)
    (cl-loop for sr across src
             for dr across dst
             do (cl-loop for s across sr
                         for i from 0
                         do (aset dr i s)))))

(defun kaesar--create-salt ()
  (cl-loop for i from 0 below kaesar--pkcs5-salt-length
           with salt = (make-vector kaesar--pkcs5-salt-length nil)
           do (aset salt i (random ?\x100))
           finally return salt))

(defun kaesar--key-md5-digest (hash data)
  (cl-loop with unibytes = (apply 'kaesar--unibyte-string data)
           with md5-hash = (md5 unibytes)
           for v across (kaesar--hex-to-vector md5-hash)
           for i from 0
           do (aset hash i v)))

(defun kaesar--hex-to-vector (hex-string)
  (cl-loop for i from 0 below (length hex-string) by 2
           collect (string-to-number (substring hex-string i (+ i 2)) 16)
           into res
           finally return (vconcat res)))

(if (fboundp 'unibyte-string)
    (defalias 'kaesar--unibyte-string 'unibyte-string)
  (defun kaesar--unibyte-string (&rest bytes)
    (concat bytes)))

(defun kaesar--destroy-word-vector (key)
  (cl-loop for v across key
           do (fillarray v nil)))

;;
;; Interoperability with openssl
;;

(eval-and-compile
  (defconst kaesar--openssl-magic-word "Salted__"))

(defconst kaesar--openssl-magic-salt-regexp
  (eval-when-compile
    (format "\\`%s\\([\000-\377]\\{%d\\}\\)"
            kaesar--openssl-magic-word kaesar--pkcs5-salt-length)))

(defun kaesar--openssl-parse-salt (unibyte-string)
  (let ((regexp kaesar--openssl-magic-salt-regexp))
    (unless (string-match regexp unibyte-string)
      (signal 'kaesar-decryption-failed (list "No salted")))
    (list
     (vconcat (match-string 1 unibyte-string))
     (substring unibyte-string (match-end 0)))))

(defun kaesar--openssl-prepend-salt (salt encrypt-string)
  (concat
   (string-as-unibyte kaesar--openssl-magic-word)
   (apply 'kaesar--unibyte-string (append salt nil))
   encrypt-string))

;; Emulate openssl EVP_BytesToKey function
(defun kaesar--openssl-evp-bytes-to-key (iv-length key-length data salt)
  (let ((key (make-vector key-length nil))
        (iv (make-vector iv-length nil))
        ;;md5 hash size
        (hash (make-vector 16 nil))
        (ii 0)
        (ki 0))
    (cl-loop while (or (< ki key-length)
                       (< ii iv-length))
             do
             (let (context)
               ;; After first loop
               (when (or (> ii 0) (> ki 0))
                 (setq context (append hash nil)))
               (setq context (append context data nil))
               (when salt
                 (setq context (append context salt nil)))
               (kaesar--key-md5-digest hash context))
             (let ((i 0))
               (cl-loop for j from ki below (length key)
                        while (< i (length hash))
                        do (progn
                             (aset key j (aref hash i))
                             (cl-incf i))
                        finally (setq ki j))
               (cl-loop for j from ii below (length iv)
                        while (< i (length hash))
                        do (progn
                             (aset iv j (aref hash i))
                             (cl-incf i))
                        finally (setq ii j))))
    ;; Destructive clear password area.
    (fillarray data nil)
    (list key iv)))

;;
;; AES Algorithm defined functions
;;

;; 4.1 Addition
(eval-when-compile
  (defun kaesar--add (&rest numbers)
    (apply 'logxor numbers)))

;; 4.2 Multiplication
;; 4.2.1 xtime
(eval-and-compile
  (defconst kaesar--xtime-cache
    (cl-loop for byte from 0 below ?\x100
             with table = (make-vector ?\x100 nil)
             do (aset table byte
                      (if (< byte ?\x80)
                          (lsh byte 1)
                        (logand (logxor (lsh byte 1) ?\x11b) ?\xff)))
             finally return table)))

(eval-and-compile
  (defun kaesar--xtime (byte)
    (aref kaesar--xtime-cache byte)))

(eval-and-compile
  (defconst kaesar--multiply-log
    (cl-loop for i from 0 to ?\xff
             with table = (make-vector ?\x100 nil)
             do
             (cl-loop for j from 1 to 7
                      with l = (make-vector 8 nil)
                      with v = i
                      initially (progn
                                  (aset table i l)
                                  (aset l 0 i))
                      do (let ((n (kaesar--xtime v)))
                           (aset l j n)
                           (setq v n)))
             finally return table)))

(eval-when-compile
  (defun kaesar--multiply-0 (byte1 byte2)
    (let ((table (aref kaesar--multiply-log byte1)))
      (apply 'kaesar--add
             (cl-loop for i from 0 to 7
                      unless (zerop (logand byte2 (lsh 1 i)))
                      collect (aref table i))))))

(eval-and-compile
  (defconst kaesar--multiply-cache
    (eval-when-compile
      (cl-loop for b1 from 0 to ?\xff
               collect
               (cl-loop for b2 from 0 to ?\xff
                        collect (kaesar--multiply-0 b1 b2) into res
                        finally return (vconcat res))
               into res
               finally return (vconcat res)))))

(eval-when-compile
  (defun kaesar--multiply (byte1 byte2)
    (aref (aref kaesar--multiply-cache byte1) byte2)))

(eval-and-compile
  (defconst kaesar--S-box
    (eval-when-compile
      (cl-loop with inv-cache =
               (cl-loop with v = (make-vector 256 nil)
                        for byte from 0 to 255
                        do (aset v byte
                                 (cl-loop for b
                                          across (aref kaesar--multiply-cache byte)
                                          for i from 0
                                          if (= b 1)
                                          return i
                                          finally return 0))
                        finally return v)
               with boxing = (lambda (byte)
                               (let* ((inv (aref inv-cache byte))
                                      (s inv)
                                      (x inv))
                                 (cl-loop repeat 4
                                          do (progn
                                               (setq s (kaesar--byte-rot s 1))
                                               (setq x (logxor s x))))
                                 (logxor x ?\x63)))
               for b from 0 to ?\xff
               with box = (make-vector ?\x100 nil)
               do (aset box b (funcall boxing b))
               finally return box))))

(eval-when-compile
  (defsubst kaesar--sub-word! (word)
    (aset word 0 (aref kaesar--S-box (aref word 0)))
    (aset word 1 (aref kaesar--S-box (aref word 1)))
    (aset word 2 (aref kaesar--S-box (aref word 2)))
    (aset word 3 (aref kaesar--S-box (aref word 3)))
    word))

(eval-when-compile
  (defsubst kaesar--rot-word! (word)
    (let ((b0 (aref word 0)))
      (aset word 0 (aref word 1))
      (aset word 1 (aref word 2))
      (aset word 2 (aref word 3))
      (aset word 3 b0)
      word)))

(defconst kaesar--Rcon
  (eval-when-compile
    (cl-loop repeat 10
             for v = 1 then (kaesar--xtime v)
             collect (vector v 0 0 0) into res
             finally return (vconcat res))))

(defun kaesar--key-expansion (key)
  (let (res)
    (cl-loop for i from 0 below kaesar--Nk
             do
             (setq res
                   (cons
                    (cl-loop for j from 0 below kaesar--Nb
                             with w = (make-vector kaesar--Nb nil)
                             do (aset w j (aref key (+ j (* kaesar--Nb i))))
                             finally return w)
                    res)))
    (cl-loop for i from kaesar--Nk below (* kaesar--Nb (1+ kaesar--Nr))
             do (let ((word (vconcat (car res))))
                  (cond
                   ((= (mod i kaesar--Nk) 0)
                    (kaesar--rot-word! word)
                    (kaesar--sub-word! word)
                    (kaesar--word-xor!
                     word
                     ;; `i' is start from 1
                     (aref kaesar--Rcon (1- (/ i kaesar--Nk)))))
                   ((and (> kaesar--Nk 6)
                         (= (mod i kaesar--Nk) 4))
                    (kaesar--sub-word! word)))
                  (kaesar--word-xor!
                   word
                   (nth (1- kaesar--Nk) res))
                  (setq res (cons word res))))
    (nreverse res)))

(eval-when-compile
  (defsubst kaesar--add-round-key! (state key)
    (kaesar--word-xor! (aref state 0) (aref key 0))
    (kaesar--word-xor! (aref state 1) (aref key 1))
    (kaesar--word-xor! (aref state 2) (aref key 2))
    (kaesar--word-xor! (aref state 3) (aref key 3))
    state))

(eval-when-compile
  (defsubst kaesar--round-key (key n)
    (aref key n)))

(defconst kaesar--2time-table
  (eval-when-compile
    (cl-loop for i from 0 to ?\xff
             collect (kaesar--multiply i 2) into res
             finally return (vconcat res))))

(defconst kaesar--4time-table
  (eval-when-compile
    (cl-loop for i from 0 to ?\xff
             collect (kaesar--multiply i 4) into res
             finally return (vconcat res))))

(defconst kaesar--8time-table
  (eval-when-compile
    (cl-loop for i from 0 to ?\xff
             collect (kaesar--multiply i 8) into res
             finally return (vconcat res))))

;; MixColumn and AddRoundKey
(eval-when-compile
  (defsubst kaesar--mix-column-with-key! (word key)
    (let ((w1-0 (aref word 0))
          (w1-1 (aref word 1))
          (w1-2 (aref word 2))
          (w1-3 (aref word 3))
          (w2-0 (aref kaesar--2time-table (aref word 0)))
          (w2-1 (aref kaesar--2time-table (aref word 1)))
          (w2-2 (aref kaesar--2time-table (aref word 2)))
          (w2-3 (aref kaesar--2time-table (aref word 3))))
      ;; Coefficients of word Matrix
      ;; 2 3 1 1
      ;; 1 2 3 1
      ;; 1 1 2 3
      ;; 3 1 1 2
      (aset word 0 (logxor w2-0
                           w2-1 w1-1
                           w1-2
                           w1-3
                           (aref key 0)))
      (aset word 1 (logxor w1-0
                           w2-1
                           w1-2 w2-2
                           w1-3
                           (aref key 1)))
      (aset word 2 (logxor w1-0
                           w1-1
                           w2-2
                           w1-3 w2-3
                           (aref key 2)))
      (aset word 3 (logxor w1-0 w2-0
                           w1-1
                           w1-2
                           w2-3
                           (aref key 3)))
      word)))

;; Call mix-column and `kaesar--add-round-key!'
(eval-when-compile
  (defsubst kaesar--mix-columns-with-key! (state keys)
    (kaesar--mix-column-with-key! (aref state 0) (aref keys 0))
    (kaesar--mix-column-with-key! (aref state 1) (aref keys 1))
    (kaesar--mix-column-with-key! (aref state 2) (aref keys 2))
    (kaesar--mix-column-with-key! (aref state 3) (aref keys 3))
    state))

;; InvMixColumn and AddRoundKey
(eval-when-compile
  (defsubst kaesar--inv-key-with-mix-column! (key word)
    ;; AddRoundKey
    (kaesar--word-xor! word key)
    (let ((w1-0 (aref word 0))
          (w1-1 (aref word 1))
          (w1-2 (aref word 2))
          (w1-3 (aref word 3))
          (w2-0 (aref kaesar--2time-table (aref word 0)))
          (w2-1 (aref kaesar--2time-table (aref word 1)))
          (w2-2 (aref kaesar--2time-table (aref word 2)))
          (w2-3 (aref kaesar--2time-table (aref word 3)))
          (w4-0 (aref kaesar--4time-table (aref word 0)))
          (w4-1 (aref kaesar--4time-table (aref word 1)))
          (w4-2 (aref kaesar--4time-table (aref word 2)))
          (w4-3 (aref kaesar--4time-table (aref word 3)))
          (w8-0 (aref kaesar--8time-table (aref word 0)))
          (w8-1 (aref kaesar--8time-table (aref word 1)))
          (w8-2 (aref kaesar--8time-table (aref word 2)))
          (w8-3 (aref kaesar--8time-table (aref word 3))))
      ;; Coefficients of word Matrix
      ;; 14 11 13  9
      ;;  9 14 11 13
      ;; 13  9 14 11
      ;; 11 13  9 14

      ;;  9 <- 8     1
      ;; 11 <- 8   2 1
      ;; 13 <- 8 4   1
      ;; 14 <- 8 4 2

      (aset word 0 (logxor
                    w8-0 w4-0 w2-0      ; 14
                    w8-1 w2-1 w1-1      ; 11
                    w8-2 w4-2 w1-2      ; 13
                    w8-3 w1-3))         ;  9
      (aset word 1 (logxor
                    w8-0 w1-0           ;  9
                    w8-1 w4-1 w2-1      ; 14
                    w8-2 w2-2 w1-2      ; 11
                    w8-3 w4-3 w1-3))    ; 13
      (aset word 2 (logxor
                    w8-0 w4-0 w1-0      ; 13
                    w8-1 w1-1           ;  9
                    w8-2 w4-2 w2-2      ; 14
                    w8-3 w2-3 w1-3))    ; 11
      (aset word 3 (logxor
                    w8-0 w2-0 w1-0      ; 11
                    w8-1 w4-1 w1-1      ; 13
                    w8-2 w1-2           ;  9
                    w8-3 w4-3 w2-3))    ; 14
      word)))

(eval-when-compile
  (defsubst kaesar--inv-key-with-mix-columns! (keys state)
    (kaesar--inv-key-with-mix-column! (aref keys 0) (aref state 0))
    (kaesar--inv-key-with-mix-column! (aref keys 1) (aref state 1))
    (kaesar--inv-key-with-mix-column! (aref keys 2) (aref state 2))
    (kaesar--inv-key-with-mix-column! (aref keys 3) (aref state 3))
    state))

(eval-when-compile
  (defsubst kaesar--adapt/sub/shift-row! (state row columns box)
    (let ((r0 (aref box (aref (aref state (aref columns 0)) row)))
          (r1 (aref box (aref (aref state (aref columns 1)) row)))
          (r2 (aref box (aref (aref state (aref columns 2)) row)))
          (r3 (aref box (aref (aref state (aref columns 3)) row))))
      (aset (aref state 0) row r0)
      (aset (aref state 1) row r1)
      (aset (aref state 2) row r2)
      (aset (aref state 3) row r3))
    state))

(eval-when-compile
  (defsubst kaesar--sub/shift-row! (state)
    ;; FIXME: first row only S-box
    (kaesar--adapt/sub/shift-row! state 0 [0 1 2 3] kaesar--S-box)
    (kaesar--adapt/sub/shift-row! state 1 [1 2 3 0] kaesar--S-box)
    (kaesar--adapt/sub/shift-row! state 2 [2 3 0 1] kaesar--S-box)
    (kaesar--adapt/sub/shift-row! state 3 [3 0 1 2] kaesar--S-box)
    state))

(eval-and-compile
  (defconst kaesar--inv-S-box
    (eval-when-compile
      (cl-loop for s across kaesar--S-box
               for b from 0
               with ibox = (make-vector ?\x100 nil)
               do (aset ibox s b)
               finally return ibox))))

(eval-when-compile
  (defsubst kaesar--inv-sub/shift-row! (state)
    ;; FIXME: first row only inv-S-box
    (kaesar--adapt/sub/shift-row! state 0 [0 1 2 3] kaesar--inv-S-box)
    (kaesar--adapt/sub/shift-row! state 1 [3 0 1 2] kaesar--inv-S-box)
    (kaesar--adapt/sub/shift-row! state 2 [2 3 0 1] kaesar--inv-S-box)
    (kaesar--adapt/sub/shift-row! state 3 [1 2 3 0] kaesar--inv-S-box)
    state))

(eval-when-compile
  (defsubst kaesar--inv-sub-word! (word)
    (aset word 0 (aref kaesar--inv-S-box (aref word 0)))
    (aset word 1 (aref kaesar--inv-S-box (aref word 1)))
    (aset word 2 (aref kaesar--inv-S-box (aref word 2)))
    (aset word 3 (aref kaesar--inv-S-box (aref word 3)))
    word))

;; No longer used, integrated to `kaesar--inv-sub/shift-row!'
;;  `kaesar--sub/shift-row!'
;; (defsubst kaesar--sub-bytes! (state)
;;   (mapc 'kaesar--sub-word! state))
;;
;; (defsubst kaesar--inv-sub-bytes! (state)
;;   (mapc 'kaesar--inv-sub-word! state))
;;
;; (defsubst kaesar--shift-rows! (state)
;;   ;; ignore first row
;;   (kaesar--shift-row! state 1 '(1 2 3 0))
;;   (kaesar--shift-row! state 2 '(2 3 0 1))
;;   (kaesar--shift-row! state 3 '(3 0 1 2)))
;;
;; (defsubst kaesar--inv-shift-rows! (state)
;;   ;; ignore first row
;;   (kaesar--shift-row! state 1 '(3 0 1 2))
;;   (kaesar--shift-row! state 2 '(2 3 0 1))
;;   (kaesar--shift-row! state 3 '(1 2 3 0)))
;;
;; (defsubst kaesar--shift-row! (state row columns)
;;   (let ((new-rows (mapcar
;;                    (lambda (col)
;;                      (aref (aref state col) row)) columns)))
;;     (cl-loop for col from 0
;;           for new-val in new-rows
;;           do (aset (aref state col) row new-val))))


(eval-when-compile
  (defsubst kaesar--sub-shift-mix! (key state)
    (cl-loop for round from 1 to (1- kaesar--Nr)
             do (let ((part-key (kaesar--round-key key round)))
                  (kaesar--sub/shift-row! state)
                  (kaesar--mix-columns-with-key! state part-key)))
    state))

(eval-when-compile
  (defsubst kaesar--cipher! (state key)
    (kaesar--add-round-key! state (kaesar--round-key key 0))
    (kaesar--sub-shift-mix! key state)
    (kaesar--sub/shift-row! state)
    (kaesar--add-round-key! state (kaesar--round-key key kaesar--Nr))
    state))

(eval-when-compile
  (defsubst kaesar--inv-shift-sub-mix! (state key)
    (cl-loop for round downfrom (1- kaesar--Nr) to 1
             do (let ((part-key (kaesar--round-key key round)))
                  (kaesar--inv-sub/shift-row! state)
                  (kaesar--inv-key-with-mix-columns! part-key state)))
    state))

(eval-when-compile
  (defsubst kaesar--inv-cipher! (state key)
    (kaesar--add-round-key! state (kaesar--round-key key kaesar--Nr))
    (kaesar--inv-shift-sub-mix! state key)
    (kaesar--inv-sub/shift-row! state)
    (kaesar--add-round-key! state (kaesar--round-key key 0))
    state))

;;
;; Block mode Algorithm
;;

(put 'kaesar-decryption-failed
     'error-conditions '(kaesar-decryption-failed error))
(put 'kaesar-decryption-failed
     'error-message "Bad decrypt")

(eval-when-compile
  (defsubst kaesar--state-xor! (state0 state-1)
    (cl-loop for w0 across state0
             for w-1 across state-1
             do (kaesar--word-xor! w0 w-1)
             finally return state0)))

;; check End-Of-Block bytes
(defun kaesar--check-decrypted (rbytes)
  (let ((pad (car rbytes)))
    (unless (and (<= 1 pad)
                 (<= pad kaesar--Block))
      (signal 'kaesar-decryption-failed nil))
    ;; check non padding byte exists
    ;; o aaa => '(97 97 97 13 13 .... 13)
    ;; x aaa => '(97 97 97 13 10 .... 13)
    (cl-loop repeat pad
             for c in rbytes
             unless (eq c pad)
             do (signal 'kaesar-decryption-failed nil))
    (nreverse (nthcdr pad rbytes))))

(defun kaesar--finish-truncate-bytes (input-bytes reverse-output-list)
  (let ((trash-len (- (length reverse-output-list) (length input-bytes))))
    (nreverse (nthcdr trash-len reverse-output-list))))

;; Encrypt: C0 = IV, Ci = Ek(Mi + Ci-1)
;; Decrypt: C0 = IV, Mi = Ci-1 + Ek^(-1)(Ci)
(defun kaesar--cbc-encrypt (unibyte-string key iv)
  (cl-loop with pos = 0
           with state-1 = (kaesar--unibytes-to-state iv 0)
           with state = (kaesar--construct-state)
           ;; state-1 <-> state is swapped in this loop to decrease
           ;; allocating the new vector.
           append (let* ((rest (kaesar--load-unibytes!
                                state unibyte-string pos))
                         (_ (kaesar--state-xor! state state-1))
                         (_ (kaesar--cipher! state key))
                         (bytes (kaesar--state-to-bytes state))
                         (swap state-1))
                    (setq pos rest)
                    (setq state-1 state)
                    (setq state swap)
                    bytes)
           while pos))

(defun kaesar--cbc-decrypt (encbyte-string key iv)
  (cl-loop with pos = 0
           with state-1 = (kaesar--unibytes-to-state iv 0)
           ;; create state as empty table
           with state = (kaesar--construct-state)
           with state0 = (kaesar--construct-state)
           with res = '()
           do (let* ((rest (kaesar--load-encbytes! state encbyte-string pos))
                     (_ (kaesar--state-copy! state0 state))
                     ;; Clone state cause of `kaesar--inv-cipher!'
                     ;; have side-effect
                     (_ (kaesar--inv-cipher! state key))
                     (_ (kaesar--state-xor! state state-1))
                     (bytes (kaesar--state-to-bytes state))
                     (swap state-1))
                (setq pos rest)
                (setq state-1 state0)
                (setq state0 swap)
                (setq res (nconc (nreverse bytes) res)))
           while pos
           finally return (kaesar--check-decrypted res)))

;; Encrypt: Ci = Ek(Mi)
;; Decrypt: Mi = Ek^(-1)(Ci)
(defun kaesar--ecb-encrypt (unibyte-string key _dummy)
  (cl-loop with pos = 0
           with state = (kaesar--construct-state)
           append (let* ((rest (kaesar--load-unibytes!
                                state unibyte-string pos))
                         (_ (kaesar--cipher! state key))
                         (bytes (kaesar--state-to-bytes state)))
                    (setq pos rest)
                    bytes)
           while pos))

(defun kaesar--ecb-decrypt (encbyte-string key _dummy)
  (cl-loop with pos = 0
           with res = '()
           with state = (kaesar--construct-state)
           do (let* ((rest (kaesar--load-encbytes! state encbyte-string pos))
                     (_ (kaesar--inv-cipher! state key))
                     (bytes (kaesar--state-to-bytes state)))
                (setq pos rest)
                (setq res (nconc (nreverse bytes) res)))
           while pos
           finally return (kaesar--check-decrypted res)))

;; Encrypt: H0 = IV, Hi = Ek(Hi-1), Ci = Mi + Hi
;; Decrypt: H0 = IV, Hi = Ek(Hi-1), Mi = Ci + Hi
(defun kaesar--ofb-encrypt (unibyte-string key iv)
  (cl-loop with pos = 0
           with h = (kaesar--unibytes-to-state iv 0)
           with res = '()
           with state = (kaesar--construct-state)
           do (let* ((rest (kaesar--load-unibytes! state unibyte-string pos))
                     (_ (kaesar--cipher! h key))
                     (_ (kaesar--state-xor! state h)))
                (setq pos rest)
                (setq res (nconc
                           (nreverse (kaesar--state-to-bytes state))
                           res)))
           while pos
           finally return
           (kaesar--finish-truncate-bytes unibyte-string res)))

(defconst kaesar--ctr-increment-byte-table
  (eval-when-compile
    (cl-loop with vec = (make-vector ?\x100 nil)
             for i from 0 to ?\xff
             do (aset vec i (% (1+ i) ?\x100))
             finally return vec)))

(defun kaesar--ctr-increment! (state)
  (catch 'done
    (cl-loop with table = kaesar--ctr-increment-byte-table
             for wordidx downfrom (1- (length state)) downto 0
             do
             (cl-loop with word = (aref state wordidx)
                      for idx downfrom (1- (length word)) downto 0
                      do
                      (let ((inc (aref table (aref word idx))))
                        (aset word idx inc)
                        (when (/= inc 0)
                          (throw 'done t)))))))

;; Encrypt: Ci = Mi + Ek(Ri), Ri+1 = Ri + 1
;; Decrypt: Mi = Ci + Ek(Ri), Ri+1 = Ri + 1
(defun kaesar--ctr-encrypt (unibyte-string key iv)
  (cl-loop with pos = 0
           with r = (kaesar--unibytes-to-state iv 0)
           with res = '()
           with state = (kaesar--construct-state)
           with save-r = (kaesar--construct-state)
           do (let* ((rest (kaesar--load-unibytes! state unibyte-string pos))
                     (_ (kaesar--state-copy! save-r r))
                     (_ (kaesar--cipher! r key))
                     (_ (kaesar--state-xor! state r))
                     (bytes (kaesar--state-to-bytes state))
                     (swap save-r))
                (kaesar--ctr-increment! save-r)
                (setq save-r r)
                (setq r swap)
                (setq pos rest)
                (setq res (nconc (nreverse bytes) res)))
           while pos
           finally return
           (kaesar--finish-truncate-bytes unibyte-string res)))

;; Encrypt: C0 = IV, Ci = Mi + Ek(Ci-1)
;; Decrypt: C0 = IV, Mi = Ci + Ek(Ci-1)
(defun kaesar--cfb-encrypt (unibyte-string key iv)
  (cl-loop with pos = 0
           with res = '()
           with state-1 = (kaesar--unibytes-to-state iv 0)
           with state = (kaesar--construct-state)
           do (let* ((rest (kaesar--load-unibytes! state unibyte-string pos))
                     (_ (kaesar--cipher! state-1 key))
                     (_ (kaesar--state-xor! state state-1))
                     (swap state))
                (setq res (nconc
                           (nreverse (kaesar--state-to-bytes state))
                           res))
                (setq state state-1)
                (setq state-1 swap)
                (setq pos rest))
           while pos
           finally return
           (kaesar--finish-truncate-bytes unibyte-string res)))

(defun kaesar--cfb-decrypt (unibyte-string key iv)
  (cl-loop with pos = 0
           with res = '()
           with state-1 = (kaesar--unibytes-to-state iv 0)
           with state = (kaesar--construct-state)
           do (let* ((rest (kaesar--load-unibytes! state unibyte-string pos))
                     (_ (kaesar--cipher! state-1 key))
                     (_ (kaesar--state-xor! state-1 state))
                     (swap state))
                (setq state state-1)
                (setq res (nconc
                           (nreverse (kaesar--state-to-bytes state))
                           res))
                (setq state-1 swap)
                (setq pos rest))
           while pos
           finally return
           (kaesar--finish-truncate-bytes unibyte-string res)))

;;
;; inner functions
;;

(defun kaesar--key-make-block (expanded-key)
  (cl-loop for xs on expanded-key by (lambda (x) (nthcdr 4 xs))
           collect (vector (nth 0 xs) (nth 1 xs) (nth 2 xs) (nth 3 xs))
           into res
           finally return (vconcat res)))

(defun kaesar--expand-to-block-key (key)
  (let ((raw-key (kaesar--key-expansion key)))
    (kaesar--key-make-block raw-key)))

(defun kaesar--encrypt-0 (unibyte-string raw-key iv)
  "Encrypt UNIBYTE-STRING and return encrypted text as unibyte string."
  (let* ((key (kaesar--expand-to-block-key raw-key))
         (_ (fillarray raw-key nil))
         (encrypted (funcall kaesar--encoder unibyte-string key iv)))
    (prog1
        (apply 'kaesar--unibyte-string encrypted)
      (kaesar--destroy-word-vector key))))

(defun kaesar--decrypt-0 (encbyte-string raw-key iv)
  "Decrypt ENCBYTE-STRING and return decrypted text as unibyte string."
  (let* ((key (kaesar--expand-to-block-key raw-key))
         (_ (fillarray raw-key nil))
         (decrypted (funcall kaesar--decoder encbyte-string key iv)))
    (prog1
        (apply 'kaesar--unibyte-string decrypted)
      (kaesar--destroy-word-vector key))))

(defun kaesar--check-block-bytes (string)
  (when (/= (mod (length string) kaesar--Block) 0)
    (signal 'kaesar-decryption-failed
            (list "Invalid length of encryption"))))

(defun kaesar--check-unibytes (unibytes)
  (cond
   ((stringp unibytes)
    (when (multibyte-string-p unibytes)
      (error "Not a unibyte string")))
   ((vectorp unibytes))))

(defun kaesar--check-encrypted (encbyte-string)
  (cond
   ((stringp encbyte-string)
    (when (multibyte-string-p encbyte-string)
      (error "Not a encrypted string"))))
  (when kaesar--check-before-decrypt
    (funcall kaesar--check-before-decrypt encbyte-string)))

(defun kaesar--check-unibyte-vector (vector)
  (mapc
   (lambda (x)
     (unless (and (numberp x) (<= 0 x) (<= x 255))
       (error "Invalid unibyte vector")))
   vector))

(defun kaesar--validate-input-bytes (bytes require-length)
  (cond
   ;; string hex and string unibytes is not exclusive but
   ;; almost case no problem cause unibyte string should be
   ;; a binary which hold non hexchar bytes.
   ((and (stringp bytes)
         ;; Check bytes have sufficient hex
         (string-match "\\`[0-9a-fA-F]*\\'" bytes))
    (let* ((vec (kaesar--hex-to-vector
                 (if (zerop (% (length bytes) 2))
                     bytes
                   (concat "0" bytes))))
           (lack (- require-length (length vec))))
      (when (< lack 0)
        (error "Supplied bytes are too long %s" bytes))
      (vconcat (make-vector lack 0) vec)))
   ((and (stringp bytes)
         (= (length bytes) require-length))
    (kaesar--check-unibyte-vector (vconcat bytes)))
   ((and (vectorp bytes)
         (= (length bytes) require-length))
    (kaesar--check-unibyte-vector (vconcat bytes)))
   ((eq nil bytes)
    (make-vector require-length 0))
   (t
    (error "Not supported unibytes format %s" bytes))))

(defun kaesar--validate-key (key)
  (let* ((keylength (* kaesar--Nk 4))
         (veckey (kaesar--validate-input-bytes key keylength)))
    veckey))

(defun kaesar--validate-iv (iv)
  (let ((veciv (kaesar--validate-input-bytes iv kaesar--IV)))
    veciv))

(defun kaesar--password-to-key (data &optional salt)
  (kaesar--openssl-evp-bytes-to-key
   kaesar--IV (* kaesar--Nk kaesar--Nb) data salt))

;;;
;;; User level API
;;;

;;
;; Low level API (To encrypt/decrypt special way)
;;

(defmacro kaesar-special-algorithm (Nk Nr &rest form)
  (declare (indent 2) (debug t))
  `(let* ((kaesar--Nk ,Nk)
          (kaesar--Nr ,Nr))
     ,@form))

(defun kaesar-cipher! (state key)
  (kaesar--cipher! state key))

(defun kaesar-inv-cipher! (state key)
  (kaesar--inv-cipher! state key))

(defun kaesar-expand-to-block-key (key)
  (kaesar--expand-to-block-key key))

(defun kaesar-unibytes-to-state (unibytes start)
  (kaesar--unibytes-to-state unibytes start))

(defun kaesar-state-to-bytes (state)
  (kaesar--state-to-bytes state))

;;
;; High level API
;;

;;;###autoload
(defun kaesar-encrypt-bytes (unibyte-string &optional algorithm)
  "Encrypt a UNIBYTE-STRING with ALGORITHM.
If no ALGORITHM is supplied, default value is `kaesar-algorithm'.
See `kaesar-algorithm' list of the supported ALGORITHM .

Do not forget do `clear-string' to UNIBYTE-STRING to keep privacy.

To suppress the password prompt, set password to `kaesar-password' as
 a vector."
  (kaesar--with-algorithm algorithm
    (kaesar--check-unibytes unibyte-string)
    (let* ((salt (kaesar--create-salt))
           (pass (kaesar--read-passwd
                  (or kaesar-encrypt-prompt
                      "Password to encrypt: ") t)))
      (cl-destructuring-bind (raw-key iv)
          (kaesar--password-to-key pass salt)
        (let ((body (kaesar--encrypt-0 unibyte-string raw-key iv)))
          (kaesar--openssl-prepend-salt salt body))))))

;;;###autoload
(defun kaesar-decrypt-bytes (encrypted-string &optional algorithm)
  "Decrypt a ENCRYPTED-STRING which was encrypted by `kaesar-encrypt-bytes'"
  (kaesar--with-algorithm algorithm
    (kaesar--check-encrypted encrypted-string)
    (cl-destructuring-bind (salt encbytes)
        (kaesar--openssl-parse-salt encrypted-string)
      (let ((pass (kaesar--read-passwd
                   (or kaesar-decrypt-prompt
                       "Password to decrypt: "))))
        (cl-destructuring-bind (raw-key iv)
            (kaesar--password-to-key pass salt)
          (kaesar--decrypt-0 encbytes raw-key iv))))))

;;;###autoload
(defun kaesar-encrypt-string (string &optional coding-system algorithm)
  "Encrypt a well encoded STRING to encrypted string
which can be decrypted by `kaesar-decrypt-string'.

Do not forget do `clear-string' to STRING to keep privacy.

This function is a wrapper function of `kaesar-encrypt-bytes'
to encrypt string."
  (let ((unibytes (encode-coding-string
                   string
                   (or coding-system default-terminal-coding-system))))
    (kaesar-encrypt-bytes unibytes algorithm)))

;;;###autoload
(defun kaesar-decrypt-string (encrypted-string &optional coding-system algorithm)
  "Decrypt a ENCRYPTED-STRING which was encrypted by `kaesar-encrypt-string'.

This function is a wrapper function of `kaesar-decrypt-bytes'
to decrypt string"
  (let ((unibytes (kaesar-decrypt-bytes encrypted-string algorithm)))
    (decode-coding-string
     unibytes (or coding-system default-terminal-coding-system))))

;;;###autoload
(defun kaesar-encrypt (unibyte-string key-input &optional iv-input algorithm)
  "Encrypt a UNIBYTE-STRING with KEY-INPUT (Before expansion).
KEY-INPUT arg expects valid length of hex string or vector (0 - 255).
See `kaesar-algorithm' list the supported ALGORITHM .
IV-INPUT may be required if ALGORITHM need this.

Do not forget do `clear-string' or `fillarray' to UNIBYTE-STRING and
  KEY-INPUT to keep privacy.

This is a low level API to create the data which can be decrypted
 by other implementation."
  (kaesar--with-algorithm algorithm
    (kaesar--check-unibytes unibyte-string)
    (let ((key (kaesar--validate-key key-input))
          (iv (kaesar--validate-iv iv-input)))
      (kaesar--encrypt-0 unibyte-string key iv))))

;;;###autoload
(defun kaesar-decrypt (encrypted-string key-input &optional iv-input algorithm)
  "Decrypt a ENCRYPTED-STRING was encrypted by `kaesar-encrypt' with KEY-INPUT.
IV-INPUT may be required if ALGORITHM need this.

Do not forget do `clear-string' or `fillarray' to KEY-INPUT to keep privacy.

This is a low level API to decrypt data that was encrypted
 by other implementation."
  (kaesar--with-algorithm algorithm
    (kaesar--check-encrypted encrypted-string)
    (let ((key (kaesar--validate-key key-input))
          (iv (kaesar--validate-iv iv-input)))
      (kaesar--decrypt-0 encrypted-string key iv))))

;;;###autoload
(defun kaesar-change-password (encrypted-bytes &optional algorithm callback)
  "Utility function to change ENCRYPTED-BYTES password to new one.
ENCRYPTED-BYTES will be cleared immediately after decryption is done.
CALLBACK is a function accept one arg which indicate decrypted bytes.
  This bytes will be cleared after creating the new encrypted bytes."
  (let ((old (let ((kaesar-decrypt-prompt "Old password: "))
               (kaesar-decrypt-bytes encrypted-bytes algorithm))))
    (when callback
      (funcall callback old))
    ;; Clear after CALLBACK is succeeded.
    ;; if clear before CALLBACK and CALLBACK was fail,
    ;; encrypted bytes may eternally lost.
    (clear-string encrypted-bytes)
    (let ((new (let ((kaesar-encrypt-prompt "New password: "))
                 (kaesar-encrypt-bytes old algorithm))))
      (clear-string old)
      new)))

(provide 'kaesar)

;;; kaesar.el ends here
