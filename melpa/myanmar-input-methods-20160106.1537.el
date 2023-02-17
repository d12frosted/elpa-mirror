;;; myanmar-input-methods.el --- Emacs Input Method for Myanmar

;; Copyright (C) 2015 Ye Lin Kyaw
;; Author: Ye Lin Kyaw <yelinkyaw@gmail.com>
;; Created: 06 Jul 2015
;; Last-Updated: 16 Jul 2015
;; Version: 0.0.2
;; Package-Version: 20160106.1537
;; Package-Commit: 9d4e0d6358c61bde7a2274e430ef71683faea32e
;; Keywords: Myanmar, Unicode, Keyboard
;; Homepage: http://github.com/yelinkyaw/emacs-myanmar-input-methods

;; This file is not part of Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; Version 3.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides Emacs input methods for Myanmar

;;; Installation:

;; To install, just drop this file into a directory in your
;; `load-path' and (optionally) byte-compile it. And add:
;;
;;    (require 'myanmar-input-methods)
;;
;; to your .emacs file.

(require 'quail)

;; Get Character Item from Characters List
(defun myanmar-input-methods-get-character-item(key character-lists)
  (if (car character-lists)
      (if (assoc key (car character-lists))
	  (assoc key (car character-lists))
	(myanmar-input-methods-get-character-item key (cdr character-lists)))
    nil))

;; Custom Pre to Post Rules Generator
(defun myanmar-input-methods-create-pre-to-post-custom-rules(lists pre post character-lists)
  ;;Generate Prefix String
  (setq pre_key "")
  (setq pre_value "")
  (dotimes (i (length pre))
    (setq char (aref pre i))
    (setq item (myanmar-input-methods-get-character-item char character-lists))
    (if item
	(progn
	  (setq pre_key (concat pre_key (car item)))
	  (setq pre_value (concat pre_value (cdr item))))))
  
  ;; Generate Postfix String
  (setq post_key "")
  (setq post_value "")
  (dotimes (i (length post))
    (setq char (aref post i))
    (setq item (myanmar-input-methods-get-character-item char character-lists))
    (if item
	(progn
	  (setq post_key (concat post_key (car item)))
	  (setq post_value (concat post_value (cdr item))))))

  ;; Create Rules
  (let (rules)
    (while lists
      ;; Get Item
      (setq item (car lists))
      (setq key (car item))
      (setq value (cdr item))
      
      ;; Set Prefix and Postfix
      (setq key (concat key post_key pre_key))
      (setq value (concat pre_value value post_value))

      ;; Create Rules Item
      (add-to-list 'rules `(,key . ,value))
      (setq lists (cdr lists))
      )
    rules
    )
  )

;; Rules Generator
(defun myanmar-input-methods-generate-rules(lists)
  (while lists
    (setq item (car lists))
    (setq key (car item))
    (setq value (cdr item))
    (quail-defrule value (vector key))
    (setq lists (cdr lists)))
  )

;; MyanSan Layout
(quail-define-package
 "myanmar-myansan"
 "Myanmar"
 "မြန်စံ"
 nil
 "Myan San Keyboard Layout"
 nil
 t
 t
 t
 t
 nil
 nil
 nil
 nil
 nil
 t
 )

(defconst myanmar-input-methods-myansan-consonants
 '(
   ("က" . "u")
   ("ခ" . "c")
   ("ဂ" . "*")
   ("ဃ" . "C")
   ("င" . "i")
   ("စ" . "p")
   ("ဆ" . "q")
   ("ဇ" . "Z")
   ("ဈ" . "Q")
   ("ည" . "n")
   ("ဉ" . "N")
   ("ဋ" . "#")
   ("ဌ" . "X")
   ("ဍ" . "!")
   ("ဎ" . "~")
   ("ဏ" . "P")
   ("တ" . "w")
   ("ထ" . "x")
   ("ဒ" . "K")
   ("ဓ" . "L")
   ("န" . "e")
   ("ပ" . "y")
   ("ဖ" . "z")
   ("ဗ" . "A")
   ("ဘ" . "b")
   ("မ" . "r")
   ("ယ" . ",")
   ("ရ" . "&")
   ("လ" . "v")
   ("ဝ" . "W")
   ("သ" . "o")
   ("ဿ" . "O")
   ("ဟ" . "[")
   ("ဠ" . "V")
   ("အ" . "t")))

(defconst myanmar-input-methods-myansan-independent-vowels
 '(
   ("အ" . "t")
   ("ဣ" . "E")
   ("ဤ" . "T")
   ("ဥ" . "U")
   ("ဦ" . "M")
   ("ဧ" . "{")
   ("ဩ" . "]")
   ("ဪ" . "}")))

(defconst myanmar-input-methods-myansan-dependent-vowels
 '(
   ("ါ" . "g")
   ("ာ" . "m")
   ("ိ" . "d")
   ("ီ" . "D")
   ("ု" . "k")
   ("ူ" . "l")
   ("ေ" . "a")
   ("ဲ" . "J")))

(defconst myanmar-input-methods-myansan-various-signs
 '(
   ("ံ" . "H")
   ("့" . "h")
   ("း" . ";")
   ("္" . "F")
   ("်" . "f")
   ("၌" . "Y")
   ("၍" . "I")
   ("၎င်း" . "R")
   ("၏" . "\\")))

(defconst myanmar-input-methods-myansan-consonant-signs
 '(
   ("ျ" . "s")
   ("ြ" . "j")
   ("ွ" . "G")
   ("ှ" . "S")))

(defconst myanmar-input-methods-myansan-digits
 '(
   ("၀" . "0")
   ("၁" . "1")
   ("၂" . "2")
   ("၃" . "3")
   ("၄" . "4")
   ("၅" . "5")
   ("၆" . "6")
   ("၇" . "7")
   ("၈" . "8")
   ("၉" . "9")))

(defconst myanmar-input-methods-myansan-punctuations
 '(
   ("၊" . "?")
   ("။" . "/")))

(defconst myanmar-input-methods-myansan-custom-rules
 '(
   ("" . "B")
   ("/" . "^")
   ("×" . "_")
   ("ဏ္ဍ" . "@")
   ("ုံ" . "Hk")
   ("့်" . "fh")
   ("ဈ" . "ps")
   ("ဦ" . "UD")
   ("ဩ" . "oj")
   ("ဪ" . "aojmf")
   ))

(defconst myanmar-input-methods-myansan-characters
  `(,myanmar-input-methods-myansan-consonants
    ,myanmar-input-methods-myansan-independent-vowels
    ,myanmar-input-methods-myansan-dependent-vowels
    ,myanmar-input-methods-myansan-various-signs
    ,myanmar-input-methods-myansan-consonant-signs
    ,myanmar-input-methods-myansan-digits
    ,myanmar-input-methods-myansan-punctuations)
  )

;; Generate Rules
;; Consonants
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-consonants)

;; Independent Vowels
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-independent-vowels)

;; Dependent Vowels
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-dependent-vowels)

;; Various Signs
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-various-signs)

;; Consonant Signs
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-consonant-signs)

;; Digits
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-digits)

;; Punctuations
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-punctuations)

;; Create Custom Rules for "ေ + consonant"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] [] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ျ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ျ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ြ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ြ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ွ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ှ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ျ" "ွ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ြ" "ွ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ျ" "ှ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ြ" "ှ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ွ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ွ" "ှ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ွ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ျ" "ွ" "ှ"] myanmar-input-methods-myansan-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ွ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myansan-consonants ["ေ"] ["ြ" "ွ" "ှ"] myanmar-input-methods-myansan-characters))

;; Custom Rules
(myanmar-input-methods-generate-rules myanmar-input-methods-myansan-custom-rules)

;; Myanmar3 Layout
(quail-define-package
 "myanmar-myanmar3"
 "Myanmar"
 "မြန်"
 nil
 "Myanmar3 Keyboard Layout"
 nil
 t
 t
 t
 t
 nil
 nil
 nil
 nil
 nil
 t
 )


(defconst myanmar-input-methods-myanmar3-consonants
 '(
   ("က" . "u")
   ("ခ" . "c")
   ("ဂ" . ":")
   ("ဃ" . "C")
   ("င" . "i")
   ("စ" . "p")
   ("ၑ" . "`")
   ("ဆ" . "q")
   ("ဇ" . "Z")
   ("ဈ" . "Q")
   ("ည" . "n")
   ("ဉ" . "N")
   ("ဋ" . "#")
   ("ဌ" . "X")
   ("ဍ" . "!")
   ("ဎ" . "~")
   ("ဏ" . "P")
   ("တ" . "w")
   ("ထ" . "x")
   ("ဒ" . "K")
   ("ဓ" . "L")
   ("န" . "e")
   ("ပ" . "y")
   ("ဖ" . "z")
   ("ဗ" . "A")
   ("ဘ" . "b")
   ("မ" . "r")
   ("ယ" . "B")
   ("ရ" . "&")
   ("လ" . "v")
   ("ဝ" . "W")
   ("သ" . "o")
   ("ဿ" . "O")
   ("ဟ" . "[")
   ("ဠ" . "V")
   ("အ" . "t")))

(defconst myanmar-input-methods-myanmar3-independent-vowels
 '(
   ("အ" . "t")
   ("ဣ" . "E")
   ("ဤ" . "T")
   ("ဥ" . "U")
   ("ဦ" . "M")
   ("ဧ" . "{")
   ("ဩ" . "]")
   ("ဪ" . "}")))

(defconst myanmar-input-methods-myanmar3-dependent-vowels
 '(
   ("ါ" . "g")
   ("ာ" . "m")
   ("ိ" . "d")
   ("ီ" . "D")
   ("ု" . "k")
   ("ူ" . "l")
   ("ေ" . "a")
   ("ဲ" . "J")))

(defconst myanmar-input-methods-myanmar3-various-signs
 '(
   ("ံ" . "H")
   ("့" . "h")
   ("း" . ";")
   ("္" . "F")
   ("်" . "f")
   ("၌" . "Y")
   ("၍" . "I")
   ("၎င်း" . "R")
   ("၏" . "\\")))

(defconst myanmar-input-methods-myanmar3-consonant-signs
 '(
   ("ျ" . "s")
   ("ြ" . "j")
   ("ွ" . "G")
   ("ှ" . "S")))

(defconst myanmar-input-methods-myanmar3-digits
 '(
   ("၀" . "0")
   ("၁" . "1")
   ("၂". "2")
   ("၃" . "3")
   ("၄" . "4")
   ("၅" . "5")
   ("၆" . "6")
   ("၇" . "7")
   ("၈" . "8")
   ("၉" . "9")))

(defconst myanmar-input-methods-myanmar3-punctuations
 '(
   ("၊" . "<")
   ("။" . ">")))

(defconst myanmar-input-methods-myanmar3-custom-rules
 '(
   ("ုံ" . "Hk")
   ("့်" . "fh")
   ("ဈ" . "ps")
   ("ဦ" . "UD")
   ("ဩ" . "oj")
   ("ဪ" . "ojamf")
   ))
   
(defconst myanmar-input-methods-myanmar3-characters
  `(,myanmar-input-methods-myanmar3-consonants
    ,myanmar-input-methods-myanmar3-independent-vowels
    ,myanmar-input-methods-myanmar3-dependent-vowels
    ,myanmar-input-methods-myanmar3-various-signs
    ,myanmar-input-methods-myanmar3-consonant-signs
    ,myanmar-input-methods-myanmar3-digits
    ,myanmar-input-methods-myanmar3-punctuations)
  )

;; Generate Rules
;; Consonants
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-consonants)

;; Independent Vowels
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-independent-vowels)

;; Dependent Vowels
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-dependent-vowels)

;; Various Signs
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-various-signs)

;; Consonant Signs
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-consonant-signs)

;; Digits
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-digits)

;; Punctuations
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-punctuations)

;; Create Custom Rules for "ေ + consonant"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] [] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ျ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ျ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ြ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ြ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ွ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ှ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ျ" "ွ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ြ" "ွ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ျ" "ှ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ြ" "ှ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ွ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ွ" "ှ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ွ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ျ" "ွ" "ှ"] myanmar-input-methods-myanmar3-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ွ + ှ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-myanmar3-consonants ["ေ"] ["ြ" "ွ" "ှ"] myanmar-input-methods-myanmar3-characters))

;; Custom Rules
(myanmar-input-methods-generate-rules myanmar-input-methods-myanmar3-custom-rules)

;; Yunghkio Layout
(quail-define-package
 "myanmar-yunghkio"
 "Myanmar"
 "ယွန်း"
 nil
 "Yunghkio Keyboard Layout"
 nil
 t
 t
 t
 t
 nil
 nil
 nil
 nil
 nil
 t
 )

(defconst myanmar-input-methods-yunghkio-consonants
 '(
   ("ၵ" . "u")
   ("ၶ" . "c")
   ("ၷ" . "U")
   ("င" . "i")
   ("ၸ" . "q")
   ("သ" . "o")
   ("ၺ" . "n")
   ("ၹ" . "Q")
   ("တ" . "w")
   ("ထ" . "x")
   ("ၻ" . "W")
   ("ၼ" . "e")
   ("ပ" . "y")
   ("ၽ" . "z")
   ("ၾ" . "Z")
   ("ၿ" . "Y")
   ("မ" . "r")
   ("ယ" . "N")
   ("ရ" . "&")
   ("လ" . "v")
   ("ဝ" . "O")
   ("ႀ" . "P")
   ("ဂှ" . "P")
   ("ဢ" . "t")))

(defconst myanmar-input-methods-yunghkio-dependent-vowels
 '(
   ("ႃ" . "M")
   ("ၢ" . "m")
   ("ိ" . "d")
   ("ီ" . "D")
   ("ု" . "k")
   ("ူ" . "l")
   ("ေ" . "a")
   ("ဵ" . "A")
   ("ႄ" . "s")
   ("ႅ" . "S")))

(defconst myanmar-input-methods-yunghkio-various-signs
 '(
   ("ံ" . "F")
   ("့" . "H")
   ("း" . ";")
   ("ႇ" . "b")
   ("ႆ" . "B")
   ("ႈ" . "j")
   ("ႉ" . "h")
   ("ႊ" . ":")
   ("္" . "ff")
   ("်" . "f")))

(defconst myanmar-input-methods-yunghkio-consonant-signs
 '(
   ("ျ" . "K")
   ("ြ" . "L")
   ("ႂ" . "G")
   ("ွ" . "g")))

(defconst myanmar-input-methods-yunghkio-digits
 '(
   ("႐" . "0")
   ("႑" . "1")
   ("႒". "2")
   ("႓" . "3")
   ("႔" . "4")
   ("႕" . "5")
   ("႖" . "6")
   ("႗" . "7")
   ("႘" . "8")
   ("႙" . "9")))

(defconst myanmar-input-methods-yunghkio-punctuations
 '(
   ("၊" . "<")
   ("။" . ">")))

(defconst myanmar-input-methods-yunghkio-symbols
 '(
   ("႞" . "R")
   ("႟" . "T")))

(defconst myanmar-input-methods-yunghkio-custom-rules
 '(
   ("ႂ်" . "J")
   ("ုံ" . "Fk")
   ("့်" . "fh")
   ("◌" . "I")
   ("" . "E")
   ("" . "X")
   ("" . "C")
   ("" . "V")
   ))
   
(defconst myanmar-input-methods-yunghkio-characters
  `(,myanmar-input-methods-yunghkio-consonants
    ,myanmar-input-methods-yunghkio-dependent-vowels
    ,myanmar-input-methods-yunghkio-various-signs
    ,myanmar-input-methods-yunghkio-consonant-signs
    ,myanmar-input-methods-yunghkio-digits
    ,myanmar-input-methods-yunghkio-symbols
    ,myanmar-input-methods-yunghkio-punctuations)
  )

;; Generate Rules
;; Consonants
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-consonants)

;; Dependent Vowels
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-dependent-vowels)

;; Various Signs
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-various-signs)

;; Consonant Signs
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-consonant-signs)

;; Digits
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-digits)

;; Symbols
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-symbols)

;; Punctuations
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-punctuations)

;; Create Custom Rules for "ေ + consonant"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] [] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ျ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ျ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ြ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ြ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ွ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ႂ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ႂ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ျ" "ွ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ျ + ႂ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ျ" "ႂ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ြ" "ွ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ေ + consonant + ြ + ႂ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ေ"] ["ြ" "ႂ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] [] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ျ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ျ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ြ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ြ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ွ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ႂ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ႂ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ျ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ျ" "ွ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ျ + ႂ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ျ" "ႂ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ြ + ွ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ြ" "ွ"] myanmar-input-methods-yunghkio-characters))

;; Create Custom Rules for "ႄ + consonant + ြ + ႂ"
(myanmar-input-methods-generate-rules (myanmar-input-methods-create-pre-to-post-custom-rules myanmar-input-methods-yunghkio-consonants ["ႄ"] ["ြ" "ႂ"] myanmar-input-methods-yunghkio-characters))

;; Custom Rules
(myanmar-input-methods-generate-rules myanmar-input-methods-yunghkio-custom-rules)


(provide 'myanmar-input-methods)

;;; myanmar-input-methods.el ends here
