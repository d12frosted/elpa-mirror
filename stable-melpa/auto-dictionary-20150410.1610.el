;;; auto-dictionary.el --- automatic dictionary switcher for flyspell
;;-*-coding: utf-8;-*-
;;
;; Copyright (C) 2006-2008, 2011, 2013 Nikolaj Schumacher
;;
;; Author: Nikolaj Schumacher <bugs * nschum de>
;; Version: 1.1
;; Package-Version: 20150410.1610
;; Package-Commit: b364e08009fe0062cf0927d8a0582fad5a12b8e7
;; Keywords: wp
;; URL: http://nschum.de/src/emacs/auto-dictionary/
;; Compatibility: GNU Emacs 22.x, GNU Emacs 23.x, GNU Emacs 24.x
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Add the following to your .emacs file:
;; (require 'auto-dictionary)
;; (add-hook 'flyspell-mode-hook (lambda () (auto-dictionary-mode 1)))
;;
;; Then just type.  When you stop for a few moments `auto-dictionary-mode' will
;; start evaluating the content.
;;
;; You can also force a check using `adict-guess-dictionary', whether or not
;; `auto-dictionary-mode' is enabled.
;;
;; If you're unhappy with the results, call `adict-change-dictionary' to
;; change it and stop automatic checks.
;;
;; You can use `adict-change-dictionary-hook' to hook into any of these changes,
;; or `adict-conditional-insert' to insert text (like signatures) that will
;; automatically conform to the language.
;;
;;; Change Log:
;;
;;    Support Esperanto and Slovak.  (thanks to Johannes Mueller)
;;    Support for Catalan.  (thanks to Walter Garcia-Fontes)
;;
;; 2013-06-26 (1.1)
;;    Support for nb, nn, da, hi, el, and grc.  (thanks to Tore Ferner)
;;    `adict-dictionary-list' now has an easier to customize format.
;;    `adict-guess-dictionary' no longer changes the dictionary if aborted.
;;
;; 2013-03-26 (1.0.2)
;;    The initial guess is now triggered without any buffer changes.
;;
;; 2007-05-28 (1.0.1)
;;    Speed improvements.
;;    Defined functions before variables that use them.
;;    Improved Swedish word list.  (thanks to Joakim Verona)
;;    Support for Portuguese.  (thanks to Nelson Ferreira)
;;
;; 2007-05-28 (1.0)
;;    Added support for `flyspell-prog-mode'.
;;    Added `adict-' prefix to functions without.
;;    Support for Hungarian and Romanian.  (thanks to Maria Muschinski).
;;    Support for Slovenian.  (thanks to Gregor Gorjanc)
;;    Bug fixes for Emacs 21.  (thanks to Gregor Gorjanc)
;;    Added `adict-conditional-' functions.
;;
;;; Code:

(require 'flyspell)
(require 'ispell)
(eval-when-compile (require 'cl))

(defgroup auto-dictionary nil
  "Automatic dictionary switcher for Flyspell."
  :group 'wp)

(defcustom adict-idle-time 2
  "*Seconds of idle time before `adict-guess-dictionary-maybe' is run.
If this is nil, it is not never automatically."
  :group 'auto-dictionary
  :type 'number)

(defcustom adict-change-threshold .02
  "*Amount of buffer change required before the dictionary is guessed again.
This is the quotient of changes to `buffer-modified-tick' and the buffer size.
Higher values mean fewer checks."
  :group 'auto-dictionary
  :type 'number)

(defface adict-conditional-text-face
  '((((class color) (background dark))
     (:background "MediumBlue"))
    (((class color) (background light))
     (:background "turquoise")))
  "*Face used for text inserted by `adict-conditional-insert'."
  :group 'auto-dictionary)

(defcustom adict-change-dictionary-hook
  '((lambda () (with-local-quit (when flyspell-mode (flyspell-buffer)))))
  "*List of functions to be called when the buffer language is changed.
This is called when `auto-dictionary-mode' changes its mind or
`adict-change-dictionary' is called."
  :group 'auto-dictionary
  :type 'hook)

(defun adict-guess-dictionary-name (names &optional list)
  "Return the element in NAMES found in `ispell-valid-dictionary-list'."
  (unless list
    (setq list (ispell-valid-dictionary-list)))
  (or (car (member (car names) list))
      (when (cdr names)
        (adict-guess-dictionary-name (cdr names) list))))

(defun adict--guess-dictionary-cons (names)
  (cons (car names) (adict-guess-dictionary-name names)))

(defconst adict-language-list
  '(nil "en" "de" "fr" "es" "sv" "sl" "hu" "ro" "pt" "nb" "da" "grc" "el" "hi"
        "nn" "ca" "eo" "sk")
  "The languages, in order, which `adict-hash' contains.")

(defun adict--dictionary-alist-type ()
  `(repeat (cons (choice . ,(mapcar (lambda (lang) `(const ,lang))
                                    (cdr adict-language-list)))
                 (choice (const :tag "Off" nil)
                         (string :tag "Dictionary name")))))

(defcustom adict-dictionary-list
  ;; we can't be sure of the actual dictionary names
  (mapcar 'adict--guess-dictionary-cons
          '(("en" "english")
            ("de" "deutsch" "german")
            ("fr" "francais" "french")
            ("es" "español" "spanish")
            ("sv" "svenska" "swedish")
            ("sl" "slovenian" "slovene")
            ("hu" "magyar" "hungarian")
            ("ro" "românâ" "româneşte" "romanian")
            ("pt" "português" "portuguese")
            ("nb" "bokmål" "norwegian bokmål")
            ("da" "dansk" "danish")
            ("grc" "ἑλληνικά" "classical greek")
            ("el" "νέα ελληνικά" "modern greek")
            ("hi" "हिन्दी" "hindi")
            ("nn" "nynorsk" "norwegian nynorsk")
            ("ca" "catalan")
            ("eo" "esperanto")
	    ("sk" "slovenčina" "slovak")))
  "The dictionaries `auto-dictionary-mode' uses.
Change the second part of each pair to specify a specific dictionary for
that language. You can use this to specify a different region for your
language (e.g. \"en_US\" or \"american\").  Setting it to nil prevents
that language from being used.

Each pair's car corresponds to a value in `adict-language-list'"
  :group 'auto-dictionary
  :type (adict--dictionary-alist-type))

(defvar adict-lighter nil)
(make-variable-buffer-local 'adict-lighter)

(defvar adict-timer nil)
(make-variable-buffer-local 'adict-timer)

(defvar adict-last-check :never)
(make-variable-buffer-local 'adict-last-check)

(defvar adict-stop-updating-on-dictionary-change t
  "*If this is true, calling `ispell-change-dictionary' will disable checks.")

(defalias 'switch-language-hook 'adict-change-dictionary-hook)

;;;###autoload
(define-minor-mode auto-dictionary-mode
  "A minor mode that automatically sets `ispell-dictionary`."
  nil adict-lighter nil
  (if auto-dictionary-mode
      (progn
        (adict-update-lighter)
        (unless adict-timer
          (setq adict-timer
                (when adict-idle-time
                  (run-with-idle-timer adict-idle-time t
                                       'adict-guess-dictionary-maybe
                                       (current-buffer)))))
        (add-hook 'kill-buffer-hook 'adict--cancel-timer nil t))
    (adict--cancel-timer)
    (remove-hook 'kill-buffer-hook 'adict--cancel-timer t)
    (kill-local-variable 'adict-lighter)
    (kill-local-variable 'adict-last-check)))

(defalias 'adict-mode 'auto-dictionary-mode)

;;;###autoload
(defun adict-guess-dictionary (&optional idle-only)
  "Automatically change ispell dictionary based on buffer language.
Calls `ispell-change-dictionary' and runs `adict-change-dictionary-hook'.  If
BUFFER is nil, the current buffer is used.  If IDLE-ONLY is set, abort
when an input event occurs."
  (interactive)
  (let ((lang (adict--evaluate-buffer-find-dictionary idle-only)))
    (unless (and idle-only (input-pending-p))
      (when lang
        (setq adict-last-check (buffer-modified-tick))
        (unless (or (equal ispell-local-dictionary lang)
                    (and (null ispell-local-dictionary)
                         (equal ispell-dictionary lang)))
          (let (adict-stop-updating-on-dictionary-change)
            (adict-change-dictionary lang)))
        lang))))

(defun adict--cancel-timer ()
  (when adict-timer
    (cancel-timer adict-timer))
  (kill-local-variable 'adict-timer))

(defsubst adict-valid-dictionary-p (lang)
  "Test if LANG is a legal dictionary."
  (member lang
          (if (fboundp 'ispell-valid-dictionary-list)
              (ispell-valid-dictionary-list)
            (mapcar 'car ispell-dictionary-alist))))

;;;###autoload
(defun adict-change-dictionary (&optional lang)
  "Set buffer language to LANG and stop detecting it automatically."
  (interactive)
  (if lang
      (if (adict-valid-dictionary-p lang)
          (progn (message "Buffer dictionary was %s"
                          (or ispell-local-dictionary ispell-dictionary))
                 (ispell-change-dictionary lang)
                 (message "Buffer dictionary is now %s" lang))
        (error "Dictionary \"%s\" not found" lang))
    (call-interactively 'ispell-change-dictionary))
  (adict-update-lighter)
  (run-hook-with-args 'adict-change-dictionary-hook)
  (when (and adict-timer adict-stop-updating-on-dictionary-change)
    (adict--cancel-timer)))

(defun adict-guess-dictionary-maybe (timer-buffer)
  "Call `adict-guess-dictionary' or not based on `adict-change-threshold'."
  (when (and (eq (current-buffer) timer-buffer)
             (> (buffer-modified-tick) (adict--next-guess-tick)))
    (ignore-errors (adict-guess-dictionary t))))

(defun adict--next-guess-tick ()
  "The `buffer-modified-tick' until which the buffer language is not guessed."
  (if (eq adict-last-check :never)
      0
    (+ (* adict-change-threshold (buffer-size)) adict-last-check)))

(defun adict-update-lighter ()
  (setq adict-lighter
        (format " %s" (adict--shorten-dict (or ispell-local-dictionary
                                               ispell-dictionary "??")))))

(defun adict--shorten-dict (dict)
  (if (> (length dict) 3) (substring dict 0 2) dict))

(defun adict-foreach-word (beg end maxlength function &optional idle-only)
  "Execute FUNCTION for every word between BEG and END of length <= MAXLENGTH.
If IDLE-ONLY is set, abort when an input event occurs."
  (save-excursion
    (goto-char beg)
    (while (and (< (point) end)
                (not (and idle-only (input-pending-p))))
      (skip-syntax-forward "^w")
      (if (or (and flyspell-generic-check-word-p
                   (null (funcall flyspell-generic-check-word-p)))
              (memq nil
                    (mapcar (lambda (ov)
                              (not (overlay-get ov 'adict-conditional-list)))
                            (overlays-at (point)))))
          (skip-syntax-forward "w")
        (setq beg (point))
        (when (<= (skip-syntax-forward "w") maxlength)
          (funcall function (buffer-substring-no-properties beg (point))))))))

(defmacro adict-add-word (hash lang &rest words)
  `(dolist (word '(,@words))
     (when (gethash word hash)
       (message "Warning: adict-mode defined %s twice" word))
     (puthash word ,lang ,hash)))

(defvar adict-hash
  ;; Good words are frequent and unique to a language...
  ;; http://www.verbix.com/languages/
  (let ((hash (make-hash-table :test 'equal)))
    ;; all words should be downcase
    (adict-add-word hash 1 "and" "are" "at" "been" "but" "dear" "get" "have"
                    "he" "hello" "it" "me" "my" "not" "on" "of" "off" "put"
                    "regarding" "set" "she" "some" "that" "than" "the" "there"
                    "us" "was" "we" "while" "with" "yes" "you" "your" "yours")
    ;; Don't use these words, because they are also very common in
    ;; Scandinavia: "for" "to" "by"
    (adict-add-word hash 2 "eins" "zwei" "drei" "vier" "fünf" "sechs" "sieben"
                    "acht" "neun" "zehn" "aber" "als" "andere" "anderem"
                    "anderen" "anderes" "auf" "aus" "bei" "beide" "beidem"
                    "beiden" "beides" "beim" "bereits" "bevor" "bis" "bisher"
                    "bzw" "dabei" "dadurch" "dagegen" "daher" "damit" "danach"
                    "dann" "daran" "darauf" "daraus" "darin" "darunter" "das"
                    "davon" "dazu" "demselben" "denen" "denselben" "derart"
                    "deren" "derer" "derselben" "desselben" "dessen" "diese"
                    "diesem" "diesen" "dieser" "dieses" "dir" "doch" "dort"
                    "durch" "eben" "ebenfalls" "einem" "einen" "einer" "eines"
                    "einzeln" "einzelne" "entweder" "erst" "etwa" "etwas"
                    "falls" "freundlichen" "ganz" "gegen" "gemeinsam" "genau"
                    "haben" "hinter" "ich" "ihnen" "ihre" "ihrem" "ihren"
                    "ihrer" "ihres" "im" "immer" "indem" "infolge" "insgesamt"
                    "ist" "jede" "jedem" "jeden" "jeder" "jedes" "jedoch" "kann"
                    "kein" "keine" "keinem" "keinen" "keiner" "keines" "mehr"
                    "mehrere" "mehreren" "mehrerer" "mit" "mittels" "nach"
                    "nacheinander" "neben" "nicht" "noch" "nur" "oberhalb"
                    "oder" "ohne" "schreibe" "sehr" "selbst" "sich" "sie" "sind"
                    "sobald" "sodass" "sofern" "sofort" "solange" "somit"
                    "sondern" "sowie" "sowohl" "statt" "teils" "teilweise" "um"
                    "und" "unter" "unterhalb" "vom" "usw" "von" "vor" "vorher"
                    "warum" "wegen" "weil" "weiter" "weiterhin" "weitgehend"
                    "welche" "welchem" "welchen" "welcher" "welches"
                    "wenigstens" "wenn" "werden" "wie" "wieder" "wird" "wo"
                    "wobei" "wodurch" "worauf" "worden" "worin" "wurde" "zu"
                    "zueinander" "zugleich" "zum" "zumindest" "zur" "zusammen"
                    "zwar" "zwecks" "zwischen" "bezüglich" "dafür" "für"
                    "gegenüber" "gemäß" "schließlich" "über" "während" "würde"
                    "zunächst" "zusätzlich")
    ;; Also common in non-German languages, don't use:
    ;; "dass" "ab" "ob" "er" "der" "dem" "hat" "mal" "ein" "eine" "anders"
    (adict-add-word hash 3 "allez" "allons" "alors" "aux" "avoir" "bonjour"
                    "ces" "cet" "cette" "combien" "comme" "dire" "disent"
                    "disons" "dites" "elle" "faire" "fais" "faisons" "fait"
                    "faites" "il" "ils" "je" "là" "mais" "ne" "oui" "où" "parce"
                    "pas" "plaît" "pour" "pourquoi" "quand" "qui" "revoir" "une"
                    "des" "vais" "voient" "voir" "vois" "voit" "vont" "vous"
                    "voyez" "voyons" "à" "ça" "être")
    ;; Don't use:
    ;;  "dit" "aller" "dans" "dis" "vas" "et" "au" "elles"
    (adict-add-word hash 4 "además" "ahora" "al" "algo" "algunos" "antes"
                    "aquí" "así" "aunque" "año" "años" "bueno" "cada" "casa"
                    "casi" "caso" "como" "con" "contra" "cosas" "creo" "cuando"
                    "cómo" "decimos" "decir" "decis" "desde" "después" "dicen"
                    "dices" "digo" "dijo" "donde" "dos" "día" "días" "ejemplo"
                    "ella" "ellos" "entonces" "entre" "era" "eres" "eso" "esta"
                    "estaba" "estado" "estas" "esto" "estos" "está" "están"
                    "forma" "fue" "gente" "gobierno" "había" "hace" "hacemos"
                    "hacen" "hacer" "haces" "hacia" "hacéis" "hago" "hay"
                    "hecho" "hombre" "hoy" "luego" "mayor" "mejor" "menos"
                    "mientras" "mismo" "momento" "mucho" "mujer" "mundo" "muy"
                    "más" "mí" "nada" "ni" "nos" "nosotros" "otra" "otras"
                    "otro" "otros" "parece" "parte" "país" "pero" "personas"
                    "poco" "poder" "política" "porque" "primera" "puede"
                    "pueden" "qué" "sea" "según" "siempre" "sino" "sois" "somos"
                    "son" "soy" "su" "sus" "sí" "sólo" "también" "tan" "tanto"
                    "tenemos" "tener" "tengo" "tenéis" "tenía" "tiempo" "tiene"
                    "tienen" "tienes" "toda" "todas" "todo" "todos" "trabajo"
                    "una" "uno" "unos" "usted" "vamos" "veces" "veo" "ver" "ves"
                    "vida" "y" "ya" "yo" "él")
    ;; Don't use:
    ;;  "general" "lo" "las" "ven" "ve" "veis" "tal"  "ser" "si" "los" "gran"
    ;;  "del"  "han" "hasta" "no" "time" "tres" "esa" "ese"
    (adict-add-word hash 5
                    ;; Swedish (sv)
                    ;; Many, many of the most frequent words are common
                    ;; in Swedish, Danish and Norwegian. Therefore: word list
                    ;; is made longer since many core words are exluded.
                    ;;
                    ;; Based on:
                    ;; http://sskkii.gu.se/jens/publications/bfiles/B62.pdf
                    ;; http://rl.se/tusen.html
                    ;; More or less listed with descending frequency, some
                    ;; random:
                    "och" "att" "är" "första" "andra"
                    "två" "fyra" "åtta" "nio" "tio" "tålv" "då" "också" "väl"
                    "jag" "inte" "vad" "hej" "bara" "något" "sej" "för" "finns"
                    "från" "ska" "klotter" "sig" "vara" "vill" "konst"
                    "mycket" "måste" "deras" "här" "sina"
                    "hur" "sedan" "någon" "mej" "utan" "när" "tycker" "säga"
                    "kanske" "göra" "gör" "alla" "just" "upp" "sådant"
                    "hon" "menar" "menade" "någonting" "säger" "sade" "väldigt"
                    "sätt" "honom" "ihop" "gick" "kunna" "nog" "fick" "många"
                    "över" "annat" "nä" "fläta" "koppla" "möta" "räkna" "träffa"
                    "väga" "väva" "mina" "alltså" "kunnat" "varit" "avstånd"
                    "rätt" "kuggades" "flagga" "undertryckt" "knuffade" "omkull"
                    "överrumplad" "iväg" "nåt" "tillräckligt" "kostar" "kostade"
                    "halva" "vägen" "glömt" "glömma" "exempel" "liknande"
                    "avskrekkande" "förekomma" "flera" "haft" "senare" "arbete"
                    "arbetet" "arbeten" "arbeta" "läsa" "typ" "motiverad"
                    "erfarenhet" "ungefär" "även" "kronor" "detta" "procent"
                    "svenska" "allt" "mellan" "stora" "enligt" "redan" "inom"
                    "ju" "samma" "själv" "tidigare" "miljoner" "dock" "olika"
                    "plats" "gäller" "därför" "dessutom" "eftersom" "trots"
                    "människor" "bättre" "ändå" "inför" "senaste" "samtidigt"
                    "ännu" "större" "nästa" "pengar" "stället" "tillbaka"
                    "själva" "tillsammans" "nästan" "längre" "förra" "svårt"
                    "bästa" "handlar" "länge" "frågan" "spelar" "fortfarande"
                    "bakom" "berättar" "början" "varför" "företag"
                    "fanns" "egna" "utanför" "långt" "framför" "båda" "behöver"
                    "miljarder" "största" "polisen" "världen" "direkt" "innebär"
                    "bör" "vidare" "håller" "lätt" "ytterligare" "kvinnor"
                    "kvinna" "särskilt" "började" "däremot" "känner" "beslut"
                    "egentligen" "länder" "börjar" "väder" "hjälp" "ordförande"
                    "tilbaka" "medarbetare" "viktiga")
    ;; Don't use for Swedish, because they are also *very* common in
    ;; Norwegian and/or Danish:
    ;;  "barn" "eller" "en" "som" "det" "av" "på" "tre" "fem" "sex" "sju"
    ;;  "om" "du" "har" "kan" "så" "få" "skulle" "kommer" "ett" "jag"
    ;;  "sverige" "nej" "vill" "till" "medan"
    (adict-add-word hash 6
                    ;; (based on http://bos.zrc-sazu.si/a_top2000_si.html)
                    "ali" "ampak" "bi" "biti" "bodo" "bolj" "brez" "čas" "če"
                    "celo" "čeprav" "čez" "dan" "danes" "deset" "dobro" "dolgo"
                    "dovolj" "drugače" "drugi" "dva" "enkrat" "gotovo" "gre"
                    "hitro" "hvala" "ima" "iz" "jasno" "jaz" "jih" "jim" "kaj"
                    "kajti" "kako" "kateri" "kdaj" "kdo" "ker" "kje" "kljub"
                    "kmalu" "ko" "koliko" "konec" "kot" "lahko" "lep" "malo"
                    "manj" "močno" "mogoče" "mu" "nad" "naj" "največ" "nam"
                    "namreč" "naprej" "nas" "naš" "nazaj" "nekaj" "nič" "nihče"
                    "nikoli" "niso" "niti" "nov" "očitno" "od" "okoli" "oziroma"
                    "pa" "pač" "po" "počasi" "pod" "poleg" "potem" "pozdrav"
                    "prav" "pred" "predvsem" "prej" "pri" "prosim" "proti"
                    "prvi" "ravno" "res" "saj" "sam" "še" "sedaj" "šele" "sem"
                    "seveda" "sicer" "skoraj" "skupaj" "smo" "spet" "sploh"
                    "ste" "število" "štiri" "stran" "svoj" "tako" "takoj"
                    "takrat" "tega" "teh" "tem" "težko" "tisoč" "tisto" "tokrat"
                    "toliko" "torej" "treba" "tudi" "tukaj" "več" "vedno"
                    "veliko" "velja" "vendar" "vsaj" "vsak" "vse" "vsi" "za"
                    "zadnji" "zakaj" "zakon" "zaradi" "zato" "zdaj" "že" "zelo"
                    "zgolj")
    ;; Don't use: "bil" "bo" "bom" "do" "ena" "ga" "glede" "kar" "let"
    ;;  "pet" "pol" "primer" "so" "sta" "sto" "ta" "tam"
    (adict-add-word hash 7 "az" "èn" "ti" "ök" "csak" "hogy" "nem" "igen" "és"
                    "így" "úgy" "s" "jól" "van" "nincs" "nekem" "neki" "amely"
                    "ki" "ezek" "azok" "ezen" "azon" "közé" "még" "azaz" "aki"
                    "egyéb" "vagy" "ennek" "annak" "talán")
    ;; "ö" "fel" "meg"  "volt"
    (adict-add-word hash 8 "ea" "noi" "voi" "să" "în" "peste" "şi" "despre"
                    "cele" "dintre" "avem" "vă" "oricare" "acest" "fi" "pe"
                    "care" "dacă" "cum" "numai" "fost" "când" "aţi" "pentru"
                    "acum" "acesta" "ca" "sub" "ani")
    ;; Don't use:
    ;;  "nu" "ei" "se" "mai" "te" "sunt" "am"  "la" "unless" "din"
    (adict-add-word hash 9
                    ;; http://home.unilang.org/main/wiki2/index.php
                    ;; /Portuguese_wordlist
                    "e" "são" "em" "têm" "mas" "querido" "querida" "caro" "cara"
                    "para" "obter" "pegar" "oi" "aquilo" "coisa" "meu" "não"
                    "pôr" "colocar" "acerca" "algum" "alguns" "alguma" "algumas"
                    "lá" "além" "nós" "eles" "ela" "elas" "teu" "enquanto" "com"
                    "contigo" "você" "vosso" "sim" "olá" "tchau" "adeus"
                    "bem-vindo" "obrigado" "obrigada" "já" "também" "sempre"
                    "bonito" "certamente" "claramente" "cedo" "longe" "tarde"
                    "provavelmente" "alto" "talvez" "muito" "perto" "agora"
                    "apenas" "possivelmente" "raramente" "ainda" "acolá" "hoje"
                    "amanhã" "improvável" "bem" "errado" "ontem")
    ;; Don't use because they're ambiguous:
    ;; a i des du bien en es les que se tu un va el le te mi be is az da este
    ;; or ce le o de den ha med na sido para soble eu ele nunca ter lugar
    ;; "meter"
    (adict-add-word hash 10
                    ;; Norwegian bokmål (nb)
                    ;; Look at comment above on Swedish.
                    ;;
                    ;; Based on:
                    ;; http://helmer.aksis.uib.no/nta/ord10000.txt
                    ;; (Some words are just opposed to words in the Swedish or
                    ;; Danish lists.)
                    "nei" "å" "femti" "seksti" "sytti" "åtti" "nitti" "vil"
                    "andre" "annet" "fra" "ble" "hadde" "henne" "hennes"
                    "etter" "bare" "nå" "dette" "være" "opp" "må" "selv" "denne"
                    "før" "vært" "slik" "gikk" "gang" "hele" "sammen"
                    "godt" "måtte" "hvordan" "sier" "fikk" "noen" "kanskje"
                    "meg" "avstand" "skip" "prest" "flagg" "nevnt" "halve"
                    "vegen" "nesten" "måte" "avskrekkende" "forekomme"
                    "utmerket" "arbeid" "arbeide" "arbeidet" "kjøre" "kjørte"
                    "kjører" "lese" "leser" "leste" "omtrent" "gjøre" "ifølge"
                    "gjennom" "disse" "fortsatt" "allerede" "viser" "gamle"
                    "ønsker" "gjort" "likevel" "aldri" "heller" "beste" "svært"
                    "dermed" "bør" "dagbladet" "aftenposten" "løpet" "samtidig"
                    "tillegg" "mennesker" "regjeringen" "selskapet"
                    "funnet" "tilbake" "møte" "vanskelig" "gråte" "kjedelig"
                    "uke" "viktig" "viktige" "siste" "derimot" "betyr" "utsagn"
                    "feil" "medarbeider" "spurt" "spørsmål" "erkjenner"
                    "bakgrunn" "slike" "drept" "skjedde" "akkurat"
                    "optelling" "unnskylte" "flertydighet" "kjennsgjerning"
                    "etterpå" "redd" "språk" "språklig" "språklige"
                    "undersøke" "tekstene" "fått" "unnskyld"
                    "opptelling" "opptellingen" "sist" "innkjøp"
                    "kjøp" "avgrense" "avgrensede" "alminnelig" "alminnelige"
                    "henger" "likegyldig" "vesentlige" "vesentlig")
    ;; Don't use:
    ;;  "ham" "og" "i" "det" "på" "at" "ikke" "jeg"  "også" "bare"
    ;;  "hvor"  "siden" "hun"
    (adict-add-word hash 11
                    ;; Danish (da)
                    ;; Look at comment above on Swedish.
                    ;;
                    ;; Based on:
                    ;; http://korpus.dsl.dk/e-resurser/frekvens150.php?lang=dk
                    ;; Can only use 1 word among the first 37! And so it goes...
                    ;;
                    ;; http://sskkii.gu.se/jens/publications/bfiles/B62.pdf
                    "noget" "af" "hvad" "havde" "nogen" "ud" "lige" "måske"
                    "mig" "lidt" "op" "ind" "gik" "mod" "sagde" "bliver" "os"
                    "gør" "siger" "andet" "cykle" "fælde" "finde" "fløjte"
                    "hænge" "kæde" "knække" "køre" "læse" "opholde" "svejse"
                    "tage" "tager" "træffe" "præst" "lit" "afstand" "skib" "jer"
                    "flag" "generet" "nævnt" "hellere" "børn" "børnene" "uden"
                    "vejen" "næsten" "derinde" "oven" "købet" "måde"
                    "afskrækkende" "udmærket" "ik" "arbejde" "dænske" "udgave"
                    "nogle" "mellem" "sit" "fået" "undskyld" "tres" "firs"
                    "fems" "halvtres" "halvfjers" "halvfems" "undskyldte"
                    "bagefter" "græde" "forkert" "træls" "bange" "uge" "sprog"
                    "vigtig" "vigtige" "undersøge" "teksterne" "tilbage"
                    "optælling" "optællingen" "hendes" "sidste" "sidst" "indkøb"
                    "køb" "niece" "afgrænse" "afgrænsede" "almindelig"
                    "almindelige" "hænger" "kit" "verber" "udsagn" "ligegyldigt"
                    "derimod" "almindeligt" "optræder" "fejl" "beder"
                    "medarbejder" "spurgt" "spørgsmål" "optræden" "erkender"
                    "begået" "modtage" "flertydighed" "streger" "kendsgerning"
                    "læser" "læsere" "væsentlige" "væsentlig" "ægte"
                    "erkendelse" "udkom" "månedligt" "sproglige" "iagttagelse"
                    "iagttagelser" "udgivet" "oprigtigt" "sproglig" "efter")
    ;; Don't use: ;;  "ham" "og" "i" "det" "på" "at" "ikke" "jeg"  "også" "bare"
    ;;  "nej" "ham" "og" "i" "det" "på"  "blev" "sig" "hende"
    ;;  "betyder" "aldrig"
    (adict-add-word hash 12
                    ;; Classical Greek (grc)    (Precomposed letters)
                    ;;
                    ;; Based on (only showing root forms):
                    ;; http://www.perseus.tufts.edu/hopper/vocablist
                    ;;
                    ;; Some Greek speaking person should remove words from here
                    ;; that overlap with modern Greek.  (Got lazy, didn't
                    ;; complete the selected verbs... Feel free...)
                    ;;
                    ;; Need a grc dictionary? See:
                    ;; ftp://ftp.gnu.org/gnu/aspell/dict/0index.html
                    "ὁ" "ἡ" "τὸ" "τὸν" "τὴν" "τοῦ" "τῆς" "τῷ" "τῇ" "οἱ" "αἱ"
                    "τὰ" "τοὺς" "τὰς"  "τά" "τῶν" "τοῖς" "ταῖς" "ὦ" "ἕν" "ἕνα"
                    "μιᾷ" "ἑνί" "ἐγώ" "ἐγώγε" "ἔγωγε" "σύ" "ἕ" "μέν" "οὖν" "τε"
                    "καί" "καὶ" "τίς" "τί" "τίνες" "τίνα" "τίνος" "τίνων" "τίνι"
                    "τίσι" "τίσιν" "τίνας" "ἐν" "ἐπί" "ἐπὶ" "εἰς" "πρός" "πρὸς"
                    "ἐκ" "ἐξ" "μετὰ" "κατὰ" "κατά" "δέ" "δὲ" "ὡς" "δεῖ" "ἄν"
                    "ἀλλά" "ἀλλὰ" "ἄλλα" "ἀνά" "ἀνὰ" "δέω" "ὅστις" "διὰ" "διά"
                    "σοῦ" "ἐμοῦ" "εἰμί" "εἶ" "ἐστί" "ἐστὶ" "ἐστίν" "ἐστὶν"
                    "ἐσμέν" "ἐσμεν" "ἐστέ" "ἐστε" "ἐστὲ" "εἰσί" "εἰσίν" "ἴσθι"
                    "ἔσθε" "εἶναι" "ἔσομαι" "ἔσῃ" "ἔσει" "ἔσται" "ἐσόμεθα"
                    "ἔσεσθε" "ἔσονται" "ἦ" "ἦν" "ἦσθα" "ἦμεν" "ἦτε" "ἦσαν" "ὤν"
                    "οὖσα" "ὄν" "ὄντα" "οὖσαν" "ὄντος" "οὔσης" "ὄντι" "οὔσῃ"
                    "ὄντων" "οὖσι" "οὖσιν" "ὄντας" "οὖσαι" "οὔσας" "οὐσῶν"
                    "οὔσαις" "εἶμι" "εἰσι" "εἰσιν" "ἴμεν" "ἴτε" "ἴασι" "ἴασιν"
                    "ἴθι" "ἰέναι" "ἰών" "ἰοῦσα" "ἰόν" "ἰόντος" "ὅς" "ἥ" "ὅ" "ὅν"
                    "ἥν" "οὗ" "ἧς" "ᾧ" "ᾗ" "οἵ" "αἵ" "ἅ" "οὕς" "ἅς" "ὧν" "οἷς"
                    "αἷς")
    ;; Don't use:
    ;;  "τινες" "τινα" "τινος" "τινων" "τινι" "τισι" "τισιν" "τινας"
    ;;  "μετά"  "τούς" "τις" "τι" "τό" "τόν" "τήν" "τάς"
    (adict-add-word hash 13
                    ;; Modern Greek (el)
                    "έλληνας" "ελληνίδα" "ελληνικά" "ελληνικής" "ελλήνων"
                    "έλληνες" "καλημέρα" "εκείνος" "καλησπέρα" "αυτή" "κείνο"
                    "εκείνο" "αυτό" "αυτής" "αυτά" "ετούτο" "εκείνες" "εκείνη"
                    "καληνύχτα" "και" "ή" "αντίο" "γεια" "σας" "παρακαλώ" "έχει"
                    "έχεις" "έχοντας" "έχουν" "εδώ" "όλη" "έκτη" "ναι" "όχι"
                    "εις" "υγείαν" "μας" "ίσως" "κι" "νερό" "κρασί" "οι" "τα"
                    "σε" "την" "στον" "για" "μη" "στους" "ό" "τη" "της" "στο"
                    "στη" "στις" "των" "ως" "το" "πιο" "είναι" "ένα" "ότι"
                    "ίσοι" "στην" "να" "τους" "μια" "έτσι" "ώστε")
    ;; Don't use:
    ;;  "σε" "νέας" "μου" "σου" "ο" "η" "κυρία" "κύριε" "μέσα" "που"
    ;;  "χυμός" "με" "του"
    (adict-add-word hash 14
                    ;; Hindi (hi)
                    ;; Based on (not authoritative, but looks reasonable):
                    ;; http://kirkkittell.com/language/hindi/common
                    "में" "है" "हैं" "नहीं" "लिए" "गया" "विशेष" "बड़ी" "अथवा"
                    "गए" "गई" "तथा" "अपने" "कुछ" "साथ" "होता" "था" "दिया" "हुए"
                    "कोई" "रूप" "से" "सभी" "मैं" "रहा" "हुआ" "बात" "कहा" "समय"
                    "क्या" "अपनी" "होती" "प्रकार" "बहुत" "तरह" "बाद" "फिर" "रहे"
                    "द्वारा" "अधिक" "रही" "होने" "एवं" "हुई" "थे" "उनके" "थी"
                    "वाले" "चाहिए" "चाहिये" "दिन" "लेकिन" "काम" "हूँ" "होते"
                    "इसके" "उन्हें" "गये" "नाम" "कभी" "आदि" "लोग" "बार" "यहाँ"
                    "दोनों" "उन्होंने" "कार्य" "पास" "वहाँ" "भारत" "लिया"
                    "प्राप्त" "उनकी" "लोगों" "गयी" "लगा" "अन्य" "होगा" "इसी"
                    "देश" "यदि" "वर्ष" "ऐसा" "विकास" "अपना" "ऐसे" "दूसरे" "हाथ"
                    "भाषा" "मेरे" "मैंने" "तुम" "बीच" "वाली" "बड़े" "प्रति"
                    "व्यक्ति" "उनका" "लिये" "इसलिए" "तीन" "इसका" "ऐसी")
    (adict-add-word hash 15 ;; Norwegian nynorsk (nn)
                    ;; Look at comment above on Swedish.
                    ;;
                    ;; Based on (please change if you find a better list):
                    ;; http://www.raudebergskule.no/peiling/OveOrdNyn/Lese100ord
                    ;; /Oversikt.htm
                    ;; https://no.wiktionary.org/wiki/Wiktionary:Frekvenslister
                    ;; /Norsk
                    "sidan" "sjølv" "kva" "berre" "kvar" "kjem" "dykkar" "deira"
                    "fekk" "noko" "desse" "gong" "vere" "ikkje" "nokon" "eit"
                    "mykje" "frå" "bryggje" "dagar" "korleis" "kven" "inkje"
                    "nokre" "leike" "kaffi" "stova" "meir" "sjå" "såg" "dei"
                    "helsar" "kvifor" "garden" "dårleg" "bere" "gjere" "høyre"
                    "blei"  "saum" "låg" "ho" "tek" "spurde" "hundar" "herleg"
                    "hausten" "heiter" "følgje" "gutar" "såleis" "attmed"
                    "gøyme" "ringjer" "trufast" "kyrkja" "skunde" "hugse"
                    "vaknar" "hugsa" "auge" "vore" "seinare" "finst" "medan"
                    "nytta" "kjend" "heile" "aust" "innbyggjarar" "fødd" "dømes"
                    "døydde" "særleg" "songen" "høgaste" "sokn" "kjende" "vatn"
                    "vanleg" "byrja" "inneheld" "artar" "einaste" "øyane"
                    "høyrer" "vanlegvis" "leiar" "nordlege" "kvarandre"
                    "byrjinga" "søraust" "oftast" "difor" "auka" "såkalla"
                    "eigne" "strekkjer" "vestlege" "talet" "hovudstaden"
                    "nyttar" "innbyggjarane" "skil" "austsida" "vitja"
                    "noverande" "mogleg" "umogleg" "tilgjengelig" "brukast"
                    "heilage" "kjelder" "austlege" "vanskeleg" "òg" "noreg"
                    "gjekk" "budde" "utgjer" "vatnet" "tidlegare" "namn" "kvart"
                    "heilt" "framleis" "hovudsakleg" "hennar" "særs" "munnar"
                    "attende" "gut" "gutane" "månadene" "skilnadene" "skilnader"
                    "skilnaden" "føtene" "søner" "sønene" "brør" "brørne"
                    "menner" "venen" "vener" "venene" "føremon" "meining"
                    "meininga" "meiningar" "hending" "hendinga" "øyra" "øyro"
                    "døme" "vori" "skrivi" "lesi"
                    ;; Don't use: ;; "ein" "sidan" "utan" "elles"
                    )
    (adict-add-word hash 16 "més" "ara" "algú" "alguns" "abans" "benvolgut"
                    "així" "any" "anys" "bo" "quasi" "cas" "senyor" "benvolguda"
                    "com" "amb" "contra" "coses" "crec" "quan" "diem" "dir"
                    "sisplau" "dieu" "des" "després" "diuen" "dius" "dic" "dir"
                    "on" "dia" "dies" "exemple" "ells" "llavors" "digues" "dic"
                    "direm" "aquesta" "aquest" "això" "està" "estava" "estat"
                    "aquestes" "aquests" "estigui" "estan" "forma" "ser"
                    "general" "gent" "govern" "gran" "havia" "fa" "fem" "fan"
                    "fer" "fas" "cap" "benvolguda" "feu" "faig" "fan" "fins"
                    "fet" "home" "avui" "les"  "benvolguts" "els" "doncs"
                    "millor" "menys" "mentre" "mateix" "envia" "moment" "molt"
                    "dóna" "món" "més" "mí" "res" "ens" "felicitacions"
                    "nosaltres" "altra" "altres" "altre" "altres" "sembla"
                    "reunió" "reunions" "actes" "acte" "extern" "externs"
                    "externes" "part" "país" "però" "persones" "poc" "poder"
                    "política" "perquè" "pot" "poden" "què" "sigui" "segons"
                    "ser" "escrivint" "escrit" "sempre" "sinó" "sou" "som" "soc"
                    "seu" "seus" "escriure" "escric" "sols" "també" "tant"
                    "tenim" "tenir" "tinc" "tindre" "enhorabona" "teniu" "tenia"
                    "temps" "té" "tenen" "tens" "temps" "tota" "totes" "tot"
                    "tots" "treball" "tres" "una" "un" "uns" "vostè" "anem"
                    "signat" "vegada" "veieu" "veuen" "veig" "veure" "ves" "ja"
                    "jo")
    (adict-add-word hash 17
                    ;; Esperanto (eo)
                    ;;
                    ;; Frequent words, that are most probably unique to
                    ;; Esperanto
                    "kaj" "ĉu" "ĉi" "aŭ" "ankaŭ" "ankaŭa" "baldaŭ"
                    "antaŭ" "antaŭa" "antaŭaj" "antaŭe" "antaŭen"
                    "malantaŭ" "malantaŭa" "malantaŭaj" "malantaŭe"
                    "malantaŭen" "ĝis" "eĉ" "ĉe" "eble" "ankoraŭ" "ajn"
                    "preskaŭ" "pri" "ke" "pliaj" "pliajn" "morgaŭ" "morgaŭa"
                    "hieraŭ" "hieraŭa" "ĉar"
                    ;;
                    ;; Very frequent words, that are probably not quite unique
                    "havi" "havas" "havis" "havos" "havus"
                    "esti" "estas" "estis" "estos" "estus"
                    "povi" "povas" "povis" "povos" "povus"
                    ;;
                    ;; Fairly frequent words, that are most probably unique to
                    ;; Esperanto
                    "kiaj" "kiajn" "tiaj" "tiajn" "iaj" "iajn"
                    "miaj" "miajn" "viaj" "viajn" "liaj" "liajn"
                    "ŝi" "ŝin" "ŝia" "ŝian" "ŝiajn" "siaj" "siajn"
                    "ĝi" "ĝin" "ĝia" "ĝian" "ĝiaj" "ĝiajn" "niaj" "niajn"
                    "iliaj" "iliajn" "ĉiu" "kiu" "ĉiun" "kiun" "tiun"
                    "ĉiuj" "kiuj" "tiujn" "ĉiujn" "kiujn" "ĉio" "ĉion"
                    "nenio" "nenion" "neniu" "neniuj" "neniun" "neniujn"
                    "aliaj" "aliajn" "ĉiam" "ĉie")
    (adict-add-word hash 18
                    ;; slovak (sk)
                    ;;
                    "alebo" "aj"
                    "človek" "rok" "čas" "deň" "svet" "ruka" "voda" "žena"
                    "celý" "veľký" "malý" "nový" "starý" "dobrý"
                    "celá" "veľká" "malá" "nová" "stará" "dobrá"
                    "celé" "veľké" "malé" "nové" "staré" "dobré"
                    "ty" "my" "vy" "ony"
                    "byť" "sme" "ste" "sú"
                    "mať" "mám" "máš" "má" "máme" "máte" "majú"
                    "môcť" "môžem" "môžeš" "môže" "môžeme" "môžete" "môžu"
                    "musieť" "musím" "musíš" "musí" "musíme" "musíte" "musía"
                    "chcieť" "chcem" "chceš" "chce" "chceme" "chcete" "chcú"
                    "prísť" "prídem" "prídeš" "príde"
                    "prídeme" "prídete" "prídu"
                    "vidieť" "vidím" "vidíš" "vidí" "vidíme" "vidíte" "vidia"
                    "bývať" "bývam" "bývaš" "býva" "bývame" "bývate" "bývajú"
                    "bol" "bola" "bolo" "boli"
                    "budem" "budeš" "bude" "budeme" "budete" "budú"
                    "nejaký" "nejaká" "nejaké" "aký" "aká" "aké"
                    "nijaký" "nijaká" "nijaké"
                    "v" "z" "k")
    ;; adding another language? email me to make it available to everyone!
    hash))

(defun adict-evaluate-word (word)
  "Determine language of WORD using ``adict-hash''."
  (gethash (downcase word) adict-hash 0))

(defun adict-evaluate-buffer (&optional idle-only)
  "Evaluate all words in the current buffer to find out the text's language.
If IDLE-ONLY is set, abort when an input event occurs."
  (let ((counts (make-vector (length adict-language-list) 0)))
    (adict-foreach-word
     (point-min) (point-max) 8
     (lambda (word)
       ;; increase language count of WORD by one
       (callf incf (elt counts (adict-evaluate-word word))))
     idle-only)
    counts))

(defun adict--evaluate-buffer-find-max-index (idle-only)
  (let* ((vector (adict-evaluate-buffer idle-only))
         (index (- (length vector) 1))
         (pos index)
         (max (elt vector pos)))
    (decf index)
    (while (> index 0)
      (let ((val (elt vector index)))
        (when (>= val max)
          (setq max val)
          (setq pos index))
        (decf index)))
    pos))

(defun adict--evaluate-buffer-find-dictionary (idle-only)
  (if (consp (car adict-dictionary-list))
      ;; current format
      (cdr (assoc (adict--evaluate-buffer-find-lang idle-only)
                  adict-dictionary-list))
    ;; old format (<= 1.0.2)
    (nth (adict--evaluate-buffer-find-max-index idle-only)
         adict-dictionary-list)))

(defun adict--evaluate-buffer-find-lang (idle-only)
  (nth (adict--evaluate-buffer-find-max-index idle-only)
       adict-language-list))

;;; Conditional Insertion ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar adict-conditional-overlay-list nil)
(make-variable-buffer-local 'adict-conditional-overlay-list)
(defun adict-conditional-insert (&rest language-text-pairs)

  "Insert text based on dictionary and update it on dictionary changes.
LANGUAGE-TEXT-PAIRS is a list of dictionaries and strings.  The correct
string for the currently active dictionary will be used.  Whenever
`auto-dictionary-mode' changes the dictionary the inserted text will be
changed again.

Use `t' as a dictionary in the last place to catch all remaining
dictionaries.

To highlight this volatile text, `adict-conditional-text-face' is used.


You can use this, for instance, to localize the \" writes\" text in Gnus:

  (defun my-message-insert-citation-line ()
    \"Insert a simple citation line in the correct language.\"
    (when message-reply-headers
      (insert (mail-header-from message-reply-headers) \" \")
      (adict-conditional-insert \"nb\" \"skrev\"
                                \"de\" \"schreibt\"
                                \"fr\" \"a écrit\"
                                t \"wrote\")
      (newline)
      (newline)))
  (setq message-citation-line-function 'my-message-insert-citation-line)"
  (let ((overlay (make-overlay 0 0)))
    (adict-conditional-insert-1 language-text-pairs overlay)
    (overlay-put overlay 'evaporate t)
    (overlay-put overlay 'modification-hooks
                 '(adict-conditional-modification))
    (overlay-put overlay 'adict-conditional-list language-text-pairs)
    (overlay-put overlay 'face 'adict-conditional-text-face)
    (add-hook 'adict-change-dictionary-hook
              'adict-conditional-update nil t)
    (push overlay adict-conditional-overlay-list)))

(defun adict-conditional-insert-1 (language-text-pairs overlay)
  (let ((dict (or ispell-local-dictionary ispell-dictionary))
        (beg (point)))
    (while language-text-pairs
      (when (or (eq (car language-text-pairs) t)
                (equal (car language-text-pairs) dict))
        (insert (cadr language-text-pairs))
        (setq language-text-pairs nil))
      (setq language-text-pairs (cddr language-text-pairs)))
    (move-overlay overlay beg (point))))

(defun adict-conditional-modification (overlay afterp beg end
                                               &optional pre-length)
  (when afterp
    (delete-overlay overlay)
    (unless (setq adict-conditional-overlay-list
                  (delq overlay adict-conditional-overlay-list))
      (kill-local-variable 'adict-conditional-overlay-list)
      (remove-hook 'adict-change-dictionary-hook 'adict-conditional-update t))))

(defun adict-conditional-update ()
  (save-excursion
    (let ((inhibit-modification-hooks t))
      (dolist (ov adict-conditional-overlay-list)
        (when (overlay-buffer ov)
          (goto-char (overlay-start ov))
          (delete-region (point) (overlay-end ov))
          (adict-conditional-insert-1 (overlay-get ov 'adict-conditional-list)
                                      ov))))))


;;; Functions for 3rd Party Use ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun adict-guess-word-language (word)
  "Determine language of WORD using ``adict-hash''."
  (elt adict-language-list (adict-evaluate-word word)))

(defun adict-guess-buffer-language (&optional idle-only)
  "Guess the language of the current-buffer using the data in ``adict-hash''.
If IDLE-ONLY is set, abort when an input event occurs."
  (let ((lang (adict--evaluate-buffer-find-lang idle-only)))
    (unless (and idle-only (input-pending-p))
      lang)))

(provide 'auto-dictionary)

;;; auto-dictionary.el ends here
