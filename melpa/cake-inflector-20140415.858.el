;;; cake-inflector.el --- Lazy porting CakePHP infrector.php to el
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2008-2014 by 101000code/101000LAB
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
;;
;; Version: 1.1.1
;; Package-Version: 20140415.858
;; Package-Commit: a1d338ec4840b1b1bc14f7f9298c07e2c1d2d8fc
;; Author: k1LoW (Kenichirou Oyama), <k1lowxb [at] gmail [dot] com> <k1low [at] 101000lab [dot] org>
;; URL: https://github.com/k1LoW/emacs-cake-inflector
;; Package-Requires: ((s "1.9.0"))

;; -------------The license of inflector.php is displayed as follows. ------------------------------------------------------
;;
;; Pluralize and singularize English words.
;;
;; Used by Cake's naming conventions throughout the framework.
;;
;; PHP versions 4 and 5
;;
;; CakePHP(tm) :  Rapid Development Framework <http://www.cakephp.org/>
;; Copyright 2005-2008, Cake Software Foundation, Inc.
;;                                                              1785 E. Sahara Avenue, Suite 490-204
;;                                                              Las Vegas, Nevada 89104
;;
;; Licensed under The MIT License
;; Redistributions of files must retain the above copyright notice.
;;
;; @filesource
;; @copyright           Copyright 2005-2008, Cake Software Foundation, Inc.
;; @link                                http://www.cakefoundation.org/projects/info/cakephp CakePHP(tm) Project
;; @package                     cake
;; @subpackage          cake.cake.libs
;; @since                       CakePHP(tm) v 0.2.9
;; @version                     $Revision: 6311 $
;; @modifiedby          $LastChangedBy: phpnut $
;; @lastmodified        $Date: 2008-01-02 00:33:52 -0600 (Wed, 02 Jan 2008) $
;; @license                     http://www.opensource.org/licenses/mit-license.php The MIT License
;; -------------------------------------------------------------------------------------------------------------

;;; Code:

(require 's)

(defvar cake-plural-rules
  '(("atlas$" "atlases")
    ("beef$" "beefs")
    ("brother$" "brothers")
    ("child$" "children")
    ("corpus$" "corpuses")
    ("cows$" "cows")
    ("ganglion$" "ganglions")
    ("genie$" "genies")
    ("genus$" "genera")
    ("graffito$" "graffiti")
    ("hoof$" "hoofs")
    ("loaf$" "loaves")
    ("man$" "men")
    ("money$" "monies")
    ("mongoose$" "mongooses")
    ("move$" "moves")
    ("mythos$" "mythoi")
    ("numen$" "numina")
    ("occiput$" "occiputs")
    ("octopus$" "octopuses")
    ("opus$" "opuses")
    ("ox$" "oxen")
    ("penis$" "penises")
    ("person$" "people")
    ("sex$" "sexes")
    ("soliloquy$" "soliloquies")
    ("testis$" "testes")
    ("trilby$" "trilbys")
    ("turf$" "turfs")

    ("\\(.*[nrlm]ese\\)$" "\\1")
    ("\\(.*deer\\)$" "\\1")
    ("\\(.*fish\\)$" "\\1")
    ("\\(.*measles\\)$" "\\1")
    ("\\(.*ois\\)$" "\\1")
    ("\\(.*pox\\)$" "\\1")
    ("\\(.*sheep\\)$" "\\1")
    ("\\(Amoyese\\)$" "\\1")
    ("\\(bison\\)$" "\\1")
    ("\\(Borghese\\)$" "\\1")
    ("\\(bream\\)$" "\\1")
    ("\\(breeches\\)$" "\\1")
    ("\\(britches\\)$" "\\1")
    ("\\(buffalo\\)$" "\\1")
    ("\\(cantus\\)$" "\\1")
    ("\\(carp\\)$" "\\1")
    ("\\(chassis\\)$" "\\1")
    ("\\(clippers\\)$" "\\1")
    ("\\(cod\\)$" "\\1")
    ("\\(coitus\\)$" "\\1")
    ("\\(Congoese\\)$" "\\1")
    ("\\(contretemps\\)$" "\\1")
    ("\\(corps\\)$" "\\1")
    ("\\(debris\\)$" "\\1")
    ("\\(diabetes\\)$" "\\1")
    ("\\(djinn\\)$" "\\1")
    ("\\(eland\\)$" "\\1")
    ("\\(elk\\)$" "\\1")
    ("\\(equipment\\)$" "\\1")
    ("\\(Faroese\\)$" "\\1")
    ("\\(flounder\\)$" "\\1")
    ("\\(Foochowese\\)$" "\\1")
    ("\\(gallows\\)$" "\\1")
    ("\\(Genevese\\)$" "\\1")
    ("\\(Genoese\\)$" "\\1")
    ("\\(Gilbertese\\)$" "\\1")
    ("\\(graffiti\\)$" "\\1")
    ("\\(headquarters\\)$" "\\1")
    ("\\(herpes\\)$" "\\1")
    ("\\(hijinks\\)$" "\\1")
    ("\\(Hottentotese\\)$" "\\1")
    ("\\(information\\)$" "\\1")
    ("\\(innings\\)$" "\\1")
    ("\\(jackanapes\\)$" "\\1")
    ("\\(Kiplingese\\)$" "\\1")
    ("\\(Kongoese\\)$" "\\1")
    ("\\(Lucchese\\)$" "\\1")
    ("\\(mackerel\\)$" "\\1")
    ("\\(Maltese\\)$" "\\1")
    ("\\(media\\)$" "\\1")
    ("\\(mews\\)$" "\\1")
    ("\\(moose\\)$" "\\1")
    ("\\(mumps\\)$" "\\1")
    ("\\(Nankingese\\)$" "\\1")
    ("\\(news\\)$" "\\1")
    ("\\(nexus\\)$" "\\1")
    ("\\(Niasese\\)$" "\\1")
    ("\\(Pekingese\\)$" "\\1")
    ("\\(Piedmontese\\)$" "\\1")
    ("\\(pincers\\)$" "\\1")
    ("\\(Pistoiese\\)$" "\\1")
    ("\\(pliers\\)$" "\\1")
    ("\\(Portuguese\\)$" "\\1")
    ("\\(proceedings\\)$" "\\1")
    ("\\(rabies\\)$" "\\1")
    ("\\(rice\\)$" "\\1")
    ("\\(rhinoceros\\)$" "\\1")
    ("\\(salmon\\)$" "\\1")
    ("\\(Sarawakese\\)$" "\\1")
    ("\\(scissors\\)$" "\\1")
    ("\\(sea[- ]bass\\)$" "\\1")
    ("\\(series\\)$" "\\1")
    ("\\(Shavese\\)$" "\\1")
    ("\\(shears\\)$" "\\1")
    ("\\(siemens\\)$" "\\1")
    ("\\(species\\)$" "\\1")
    ("\\(swine\\)$" "\\1")
    ("\\(testes\\)$" "\\1")
    ("\\(trousers\\)$" "\\1")
    ("\\(trout\\)$" "\\1")
    ("\\(tuna\\)$" "\\1")
    ("\\(Vermontese\\)$" "\\1")
    ("\\(Wenchowese\\)$" "\\1")
    ("\\(whiting\\)$" "\\1")
    ("\\(wildebeest\\)$" "\\1")
    ("\\(Yengeese\\)$" "\\1")

    ("\\(s\\)tatus$" "statuses")
    ("\\(quiz\\)$" "quizzes")
    ("^\\(ox\\)$" "oxen")
    ("\\([m\\|l]\\)ouse$" "\\1ice")
    ("\\(matr\\|vert\\|ind\\)\\(ix\\|ex\\)$" "\\1ices")
    ("\\(x\\|ch\\|ss\\|sh\\)$" "\\1es")
    ("\\([^aeiouy]\\|qu\\)y$" "\\1ies")
    ("\\(hive\\)$" "hives")
    ("\\(\\([^f]\\)fe\\|\\([lr]\\)f\\)$" "\\1\\3ves")
    ("sis$" "ses")
    ("\\([ti]\\)um$" "\\1a")
    ("\\(p\\)erson$" "\\1eople")
    ("\\(m\\)an$" "\\1en")
    ("\\(c\\)hild$" "\\1hildren")
    ("\\(buffal\\|tomat\\)o$" "\\1\\2oes")
    ("\\(alumn\\|bacill\\|cact\\|foc\\|fung\\|nucle\\|radi\\|stimul\\|syllab\\|termin\\|vir\\)us$" "\\1")
    ("us$" "uses")
    ("\\(alias\\)$" "\\1es")
    ("\\(ax\\|cri\\|test\\)is$" "\\1es")
    ("s$" "s")
    ("$" "s"))
  "cakePluralRules")

(defvar cake-singular-rules
  '(("atlases$" "atlas")
    ("beefs$" "beef")
    ("brothers$" "brother")
    ("children$" "child")
    ("corpuses$" "corpus")
    ("cows$" "cow")
    ("ganglions$" "ganglion")
    ("genies$" "genie")
    ("genera$" "genus")
    ("graffiti$" "graffito")
    ("hoofs$" "hoof")
    ("loaves$" "loaf")
    ("men$" "man")
    ("monies$" "money")
    ("mongooses$" "mongoose")
    ("moves$" "move")
    ("mythoi$" "mythos")
    ("numina$" "numen")
    ("occiputs$" "occiput")
    ("octopuses$" "octopus")
    ("opuses$" "opus")
    ("oxen$" "ox")
    ("penises$" "penis")
    ("people$" "person")
    ("sexes$" "sex")
    ("soliloquies$" "soliloquy")
    ("testes$" "testis")
    ("trilbys$" "trilby")
    ("turfs$" "turf")

    ("\\(.*[nrlm]ese\\)$" "\\1")
    ("\\(.*deer\\)$" "\\1")
    ("\\(.*fish\\)$" "\\1")
    ("\\(.*measles\\)$" "\\1")
    ("\\(.*ois\\)$" "\\1")
    ("\\(.*pox\\)$" "\\1")
    ("\\(.*sheep\\)$" "\\1")
    ("\\(Amoyese\\)$" "\\1")
    ("\\(bison\\)$" "\\1")
    ("\\(Borghese\\)$" "\\1")
    ("\\(bream\\)$" "\\1")
    ("\\(breeches\\)$" "\\1")
    ("\\(britches\\)$" "\\1")
    ("\\(buffalo\\)$" "\\1")
    ("\\(cantus\\)$" "\\1")
    ("\\(carp\\)$" "\\1")
    ("\\(chassis\\)$" "\\1")
    ("\\(clippers\\)$" "\\1")
    ("\\(cod\\)$" "\\1")
    ("\\(coitus\\)$" "\\1")
    ("\\(Congoese\\)$" "\\1")
    ("\\(contretemps\\)$" "\\1")
    ("\\(corps\\)$" "\\1")
    ("\\(debris\\)$" "\\1")
    ("\\(diabetes\\)$" "\\1")
    ("\\(djinn\\)$" "\\1")
    ("\\(eland\\)$" "\\1")
    ("\\(elk\\)$" "\\1")
    ("\\(equipment\\)$" "\\1")
    ("\\(Faroese\\)$" "\\1")
    ("\\(flounder\\)$" "\\1")
    ("\\(Foochowese\\)$" "\\1")
    ("\\(gallows\\)$" "\\1")
    ("\\(Genevese\\)$" "\\1")
    ("\\(Genoese\\)$" "\\1")
    ("\\(Gilbertese\\)$" "\\1")
    ("\\(graffiti\\)$" "\\1")
    ("\\(headquarters\\)$" "\\1")
    ("\\(herpes\\)$" "\\1")
    ("\\(hijinks\\)$" "\\1")
    ("\\(Hottentotese\\)$" "\\1")
    ("\\(information\\)$" "\\1")
    ("\\(innings\\)$" "\\1")
    ("\\(jackanapes\\)$" "\\1")
    ("\\(Kiplingese\\)$" "\\1")
    ("\\(Kongoese\\)$" "\\1")
    ("\\(Lucchese\\)$" "\\1")
    ("\\(mackerel\\)$" "\\1")
    ("\\(Maltese\\)$" "\\1")
    ("\\(media\\)$" "\\1")
    ("\\(mews\\)$" "\\1")
    ("\\(moose\\)$" "\\1")
    ("\\(mumps\\)$" "\\1")
    ("\\(Nankingese\\)$" "\\1")
    ("\\(news\\)$" "\\1")
    ("\\(nexus\\)$" "\\1")
    ("\\(Niasese\\)$" "\\1")
    ("\\(Pekingese\\)$" "\\1")
    ("\\(Piedmontese\\)$" "\\1")
    ("\\(pincers\\)$" "\\1")
    ("\\(Pistoiese\\)$" "\\1")
    ("\\(pliers\\)$" "\\1")
    ("\\(Portuguese\\)$" "\\1")
    ("\\(proceedings\\)$" "\\1")
    ("\\(rabies\\)$" "\\1")
    ("\\(rice\\)$" "\\1")
    ("\\(rhinoceros\\)$" "\\1")
    ("\\(salmon\\)$" "\\1")
    ("\\(Sarawakese\\)$" "\\1")
    ("\\(scissors\\)$" "\\1")
    ("\\(sea[- ]bass\\)$" "\\1")
    ("\\(series\\)$" "\\1")
    ("\\(Shavese\\)$" "\\1")
    ("\\(shears\\)$" "\\1")
    ("\\(siemens\\)$" "\\1")
    ("\\(species\\)$" "\\1")
    ("\\(swine\\)$" "\\1")
    ("\\(testes\\)$" "\\1")
    ("\\(trousers\\)$" "\\1")
    ("\\(trout\\)$" "\\1")
    ("\\(tuna\\)$" "\\1")
    ("\\(Vermontese\\)$" "\\1")
    ("\\(Wenchowese\\)$" "\\1")
    ("\\(whiting\\)$" "\\1")
    ("\\(wildebeest\\)$" "\\1")
    ("\\(Yengeese\\)$" "\\1")

    ("\\(s\\)tatuses$" "\\1\\2tatus")
    ("^\\(.*\\)\\(menu\\)s$" "\\1\\2")
    ("\\(quiz\\)zes$" "\\1")
    ("\\(matr\\)ices$" "\\1ix")
    ("\\(vert\\|ind\\)ices$" "\\1ex")
    ("^\\(ox\\)en" "\\1")
    ("\\(alias\\)\\(es\\)*$" "\\1")
    ("\\(alumn\\|bacill\\|cact\\|foc\\|fung\\|nucle\\|radi\\|stimul\\|syllab\\|termin\\|viri?\\)i$" "\\1us")
    ("\\(cris\\|ax\\|test\\)es$" "\\1is")
    ("\\(shoe\\)s$" "\\1")
    ("\\(o\\)es$" "\\1")
    ("ouses$" "ouse")
    ("uses$" "us")
    ("\\([m\\|l]\\)ice$" "\\1ouse")
    ("\\(x\\|ch\\|ss\\|sh\\)es$" "\\1")
    ("\\(m\\)ovies$" "\\1\\2ovie")
    ("\\(s\\)eries$" "\\1\\2eries")
    ("\\([^aeiouy]\\|qu\\)ies$" "\\1y")
    ("\\([lr]\\)ves$" "\\1f")
    ("\\(tive\\)s$" "\\1")
    ("\\(hive\\)s$" "\\1")
    ("\\(drive\\)s$" "\\1")
    ("\\([^f]\\)ves$" "\\1fe")
    ("\\(^analy\\)ses$" "\\1sis")
    ("\\(\\(a\\)naly\\|\\(b\\)a\\|\\(d\\)iagno\\|\\(p\\)arenthe\\|\\(p\\)rogno\\|\\(s\\)ynop\\|\\(t\\)he\\)ses$" "\\1\\2sis")
    ("\\([ti]\\)a$" "\\1um")
    ("\\(p\\)eople$" "\\1\\2erson")
    ("\\(m\\)en$" "\\1an")
    ("\\(c\\)hildren$" "\\1\\2hild")
    ("\\(n\\)ews$" "\\1\\2ews")
    ("^\\(.*us\\)$" "\\1")
    ("s$" "")
    ("$" ""))
  "cakeSingularRules")

(defun cake-singularize (str)
  "Singularize string"
  (let ((result str))
    (loop for rule in cake-singular-rules do
          (unless (not (string-match (nth 0 rule) str))
            (setq result (replace-match (nth 1 rule) nil nil str))
            (return result)))))

(defun cake-pluralize (str)
  "Pluralize string"
  (let ((result str))
    (loop for rule in cake-plural-rules do
          (unless (not (string-match (nth 0 rule) str))
            (setq result (replace-match (nth 1 rule) nil nil str))
            (return result)))))

(defun cake-camelize (str)
  "Camelize snake_case str"
  (s-upper-camel-case str))

(defun cake-lower-camelize (str)
  "lowerCamelize snake_case str"
  (s-lower-camel-case str))

(defun cake-snake (str)
  "Change snake_case."
  (s-snake-case str))

;; Tests
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (expect "Lib/Admin/App"
        (cake-singularize "Lib/Admin/App"))
      (expect "Lib/Admin/Post"
        (cake-singularize "Lib/Admin/Posts"))
      (expect "View/Post"
        (cake-singularize "View/Posts"))
      (expect "posts"
        (cake-pluralize "post"))
      (expect "post"
        (cake-singularize "post"))
      (expect "Post"
        (cake-camelize "post"))
      (expect "PostComment"
        (cake-camelize "postComment"))
      (expect "PostComment"
        (cake-camelize "post_comment"))
      )))

(provide 'cake-inflector)

;;; end
;;; cake-inflector.el ends here
