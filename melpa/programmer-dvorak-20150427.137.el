;;; programmer-dvorak.el --- Input method for Programmer Dvorak.
;;
;; Copyright © 2015 Chenyun Yang
;;
;; Author: Chenyun Yang <yangchenyun@gmail.com>
;; URL: https://github.com/yangchenyun/programmer-dvorak
;; Package-Version: 20150427.137
;; Package-Commit: 3288a8f058eca4cab390a564babbbcb17cfa0350
;; Version: 0.0.1
;; Keywords: dvorak programmer-dvorak input-method

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Programmer Dvorak keyboard layout is based on ANSI Dvorak layout
;; with modification to ease the typing of symbols in program code.
;; see http://www.kaufmann.no/roland/dvorak/

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'quail)

(quail-define-package
 "programmer-dvorak" "English" "PDV@" t
 "English (ASCII) input method simulating Programmer Dvorak keyboard"
 nil t t t t nil nil nil nil nil t)

;; &%  [7  {5  }3  (1  =9  *0  )2  +4  ]6  !8  #`  $~
;;  ;:  ,<  .>  pP  yY  fF  gG  cC  rR  lL  /?  @^
;;   aA  oO  eE  uU  iI  dD  hH  tT  nN  sS  -_  \|
;;    '"  qQ  jJ  kK  xX  bB  mM  wW  vV  zZ

(quail-define-rules
 ;; first row
 ("1" ?&)
 ("2" ?\[)
 ("3" ?{)
 ("4" ?})
 ("5" ?\()
 ("6" ?=)
 ("7" ?*)
 ("8" ?\))
 ("9" ?+)
 ("0" ?\])
 ("-" ?!)
 ("=" ?#)
 ("`" ?$)

 ("!" ?%)
 ("@" ?7)
 ("#" ?5)
 ("$" ?3)
 ("%" ?1)
 ("^" ?9)
 ("&" ?0)
 ("*" ?2)
 ("(" ?4)
 (")" ?6)
 ("_" ?8)
 ("+" ?`)
 ("~" ?~)

 ;; second row
 ("q" ?\;)
 ("w" ?,)
 ("e" ?.)
 ("r" ?p)
 ("t" ?y)
 ("y" ?f)
 ("u" ?g)
 ("i" ?c)
 ("o" ?r)
 ("p" ?l)
 ("[" ?/)
 ("]" ?@)

 ("Q" ?:)
 ("W" ?<)
 ("E" ?>)
 ("R" ?P)
 ("T" ?Y)
 ("Y" ?F)
 ("U" ?G)
 ("I" ?C)
 ("O" ?R)
 ("P" ?L)
 ("{" ??)
 ("}" ?^)

 ;; home row
 ("a" ?a)
 ("s" ?o)
 ("d" ?e)
 ("f" ?u)
 ("g" ?i)
 ("h" ?d)
 ("j" ?h)
 ("k" ?t)
 ("l" ?n)
 (";" ?s)
 ("'" ?-)
 ("\\" ?\\)

 ("A" ?A)
 ("S" ?O)
 ("D" ?E)
 ("F" ?U)
 ("G" ?I)
 ("H" ?D)
 ("J" ?H)
 ("K" ?T)
 ("L" ?N)
 (":" ?S)
 ("\"" ?_)
 ("|" ?|)

 ;; bottom row
 ("z" ?')
 ("x" ?q)
 ("c" ?j)
 ("v" ?k)
 ("b" ?x)
 ("n" ?b)
 ("m" ?m)
 ("," ?w)
 ("." ?v)
 ("/" ?z)

 ("Z" ?\")
 ("X" ?Q)
 ("C" ?J)
 ("V" ?K)
 ("B" ?X)
 ("N" ?B)
 ("M" ?M)
 ("<" ?W)
 (">" ?V)
 ("?" ?Z))

(provide 'programmer-dvorak)
;;; programmer-dvorak.el ends here
