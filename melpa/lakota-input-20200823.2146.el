;;; lakota-input.el --- Input modes for Lakota language orthographies -*- lexical-binding: t; -*-

;; Author: Grant Shangreaux (shshoshin@protonmail.com)
;; URL: https://git.sr.ht/~shoshin/lakota-input.git
;; Package-Version: 20200823.2146
;; Package-Commit: b74b9de284a0404a120bb15340def4dd2f9a4779
;; Version: 1.0

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

;; A set of quail packages defining input modes of various orthographies
;; for the Lakota language.  I'd like to acknowledge the elders and
;; ancestors who fought to keep the language and culture alive.

;;; Code:

(quail-define-package
 "white-hat" "Lakota" "Lak " t
 "Input method for the White Hat orthography."
nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("f" ?ŋ)
 ("r" #x307)                            ; COMBINING DOT ABOVE
 ("v" #x304)                            ; COMBINING MACRON
 )

(quail-define-package
 "lakota-slo" "Lakota" "SLO " t
 "Input method for the Suggested Lakota Orthography.
Uses a postfix modifier key for adding accent diacritics. To add stress
to a vowel, simply type the single quote ' after the vowel. All other characters
are bound to a single key. Mitákuyepi philámayaye ló. "
nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ;; accented vowels
 ("a'" ?á) ("A'" ?Á)
 ("e'" ?é) ("E'" ?É)
 ("i'" ?í) ("I'" ?Í)
 ("o'" ?ó) ("O'" ?Ó)
 ("u'" ?ú) ("U'" ?Ú)
 ;; consonants with hacek (wedges)
 ("c" ?č) ("C" ?Č)
 ("j" ?ȟ) ("J" ?Ȟ)
 ("q" ?ǧ) ("Q" ?Ǧ)
 ("x" ?ž) ("X" ?Ž)
 ("r" ?š) ("R" ?Š)
 ;; velar nasal n
 ("f" ?ŋ)
;; glottal stop
 ("''" ?’))

(provide 'lakota-input)

;;; lakota-input.el ends here
