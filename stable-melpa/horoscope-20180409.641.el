;;; horoscope.el --- generate horoscopes.      -*- lexical-binding: t -*-

;; Author: Bob Manson <manson@cygnus.com>
;; Maintainer: Noah Friedman <friedman@prep.ai.mit.edu>
;; Keywords: extensions games
;; Package-Version: 20180409.641
;; Package-Commit: f4c683e991adce0a8f9023f15050f306f9b9a9ed
;; Created: 1995-08-02
;; Version: 2.0
;; Package-Requires: ((emacs "24"))
;; URL: https://github.com/mschuldt/horoscope.el

;; Bozoup(P) 1995 The Bozo(tic) Softwar(e) Founda(t)ion, Inc.
;; See the BOZO Antipasto for further information.
;; If this is useful to you, may you forever be blessed by the Holy Lord
;; Patty.  AT&T you will.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Emacs is your astrologer, read its interpretation with:
;;   M-x horoscope
;; No need to tell it your birth date, Emacs already knows you well enough.
;;
;; Bob Manson originally wrote this program in ksh,
;; then later converted it to Emacs Lisp.
;; Noah Friedman rewrote parts of the engine.

;;; Code:

(defconst horoscope--paragraph
  '(("*sentence." "*sentence2." "*sentence." "*sentence2."
     "You'll" "*when" "be" "*state." "*luckynum.")
    ("*sentence." "*sentence2." "*sentence2." "You'll" "*when" "be" "*state.")
    ("*sentence2." "*sentence." "*sentence." "*sentence2."
     "You'll" "*when" "be" "*state.")))

(defconst horoscope--sentence
  '(("!person" "will" "*personverb" "*attime")
    ("!attime" "is not a good time for" "*action")
    ("Your" "*noun" "will" "*verb" "soon")
    ("!thing" "is in the air")
    ("You will discover that" "*discovery")
    ("!attime" "will be a good time for" "*action")
    ("Be sure to" "*verb" "before you find out that" "*discovery")
    ("Your programs will start" "*action")
    ("Look for" "*person" "with one eye")
    ("Don't let" "*person" "*dothing" "with your" "*noun")
    ("Listen to your" "*noun" "*attime")
    ("Your" "*noun" "will be" "*change" "in the next" "*vaguenumber" "*time")
    ("!thingstodo")
    ("You might want to consider" "*action")
    ("!time" "from now" "*action" "may seem" "*likevalue")
    ("Do not" "*verb" "*attime")
    ("!person" "will be a" "*adjective" "*relationship")
    ("!attime" "*person" "will" "*thingstodo")
    ("Don't" "*thingstodo" "*attime")
    ("Put your" "*noun" "on hold" "*attime")
    ("Loaning money to your" "*relationship" "will bring dividends")
    ("*bullshit")))

(defconst horoscope--sentence2
  '(("!person" "will eventually reveal itself to be" "*person")
    ("Your efforts at" "*action" "turn out to be" "*value")
    ("Many people will ask you for advice about" "*action")
    ("!person" "will think of you as" "*person")
    ("Beware of" "*person" "bearing" "*thing")
    ("Loving your" "*noun" "now will turn out to be"
     "*value" "after a few" "*time")
    ("Don't forget to" "*thingstodo")
    ("!thingstodo" "with the help of" "*person")
    ("Never" "*thingstodo" "without" "*action" "first")
    ("Do something nice for" "*person" "*attime")
    ("You will meet" "*person" "this week")
    ("Your" "*noun" "will need to be" "*thingverb" "*attime")
    ("!evilpeople" "will" "*verb" "*attime")
    ("!attime" "*thing" "would be a good thing to" "*consider")
    ("Stealing a" "*noun" "should not be" "*try")
    ("Your finances will become" "*moneystates"
     "in the next several" "*time")
    ("*bullshit")))

(defconst horoscope--personverb
  '(("sit next to you on the bus")
    ("give you good advice")
    ("become pregnant")
    ("kiss you")
    ("make you feel warm and fuzzy")
    ("eat your mail")
    ("lift weights")
    ("hit you")
    ("give you pennies")
    ("share intimate feelings")
    ("throw up") ("splode")))

(defconst horoscope--thingverb
  '(("replaced") ("repaired") ("opened up") ("rewired")
    ("burped") ("kicked") ("bathed") ("kissed") ("petted")
    ("scrubbed") ("rubbed") ("massaged") ("fondled")
    ("excommunicated") ("removed") ("destroyed")
    ("eaten") ("turned")))

(defconst horoscope--bullshit
  '(("As" "*planet" "moves into" "*zodplace,"
     "be careful of your relationship with your" "*relationship")
    ("You will be in conflict with" "*zodiac"
     "since" "*planet" "has moved into" "*zodiac")))

(defconst horoscope--planet
  '(("Mercury") ("Venus") ("Mars") ("Jupiter") ("Saturn")
    ("Uranus") ("Neptune") ("Pluto") ("the Moon")))

(defconst horoscope--zodplace
  '(("*zodiac") ("the" "*number" "house of" "*zodiac")
    ("the" "*side" "of" "*zodiac")))

(defconst horoscope--number
  '(("first") ("second") ("third") ("11th") ("392nd")))

(defconst horoscope--side
  '(("left-hand quadrant") ("right-hand quadrant")
    ("upper half") ("lower half") ("middle")))

(defconst horoscope--zodiac
  '(("Pisces") ("Sagitarius") ("Cancer") ("Leo") ("Gemini")
    ("Taurus") ("Scorpio") ("Aquarius") ("Capricorn") ("Virgo")))

(defconst horoscope--luckynum
  '(("Your lucky number today is 29842924728.  Look for it everywhere")
    ("12 is your lucky number")
    ("Your lucky numbers are 20, 30, and 40")
    ("Don't forget, it's only 366 days at most until Christmas")))

(defconst horoscope--person
  '(("a stranger") ("a friend") ("your" "*relationship")
    ("someone you" "*greeted" "*times" "at" "*event")
    ("your" "*animal") ("your teddy bear")
    ("your mom") ("the mailman") ("the man")
    ("your wonderful pet" "*animal") ("your child")
    ("your spouse") ("God") ("a wallflower") ("a lout")
    ("a warmonger") ("two other people put together")
    ("someone you know")))

(defconst horoscope--animal
  '(("dog") ("cat") ("horse") ("elephant") ("piglet")
    ("mouse") ("rat") ("cheetah") ("giraffe") ("mutant shrimp")
    ("talking fish") ("crustacean") ("moose") ("algae") ("amoeba")))

(defconst horoscope--action
  '(("moving") ("thinking") ("making love")
    ("straining in the toilet")
    ("washing clothes") ("becoming pregnant")
    ("doing something") ("asking for a raise")
    ("starting a revolution") ("becoming paranoid")
    ("reading mail") ("talking with piglet3")
    ("balancing a checkbook") ("talking")
    ("gossiping") ("stealing from the company")
    ("buying a new computer") ("sleeping")
    ("using a Torx \#9 wrench") ("telephoning")
    ("not answering the phone")
    ("staying where you are") ("cleaning the fridge")
    ("wearing clothes")))

(defconst horoscope--thingstodo
  '(("set your clock") ("get married" "*attime")
    ("dye your hair") ("move away") ("exercise")
    ("have your" "*noun" "spayed or neutered")
    ("watch Dr. Who") ("watch Wheel of Fortune")
    ("see your psychologist") ("talk to your plants")
    ("pet piglet") ("clean your apartment")
    ("think about financial concerns")
    ("discuss life with RMS") ("marry the milkperson")
    ("adjust your girdle") ("tune your stereo")
    ("tune your car") ("lift weights") ("paint") ("draw")
    ("play Sam and Max Hit the Road")
    ("play Car Bomb")))

(defconst horoscope--time
  '(("months") ("days") ("years") ("seconds") ("minutes") ("hours")))

(defconst horoscope--attime
  '(("today") ("tomorrow") ("this week") ("this month")))

(defconst horoscope--try
  '(("attempted lightly")
    ("tried without the advice of a doctor")
    ("considered unusual")
    ("done under the influence of alcohol")
    ("achieved with the help of ZenIRC")
    ("done while wearing a girdle") ("stared at")
    ("questioned by" "*person")
    ("performed by a" "*relationship")
    ("shown on TV") ("demonstrated")
    ("shown to small children")))

(defconst horoscope--value
  '(("worthless") ("futile") ("mysterious") ("quite worthwhile")
    ("costly") ("a good idea") ("unhealthy")
    ("a positive step in the right direction")))

(defconst horoscope--likevalue
  '(("worthless") ("futile") ("mysterious")
    ("quite worthwhile") ("expensive")
    ("like a good idea") ("unhealthy")
    ("like a positive step in the right direction")))

(defconst horoscope--noun
  '(("dog") ("cat") ("anteater") ("chicken") ("television")
    ("computer") ("telephone") ("abode") ("vehicle") ("sister")
    ("rhinocerous") ("piglet") ("alien") ("tetrodotoxin")
    ("dinoflagellate") ("endothermic therapsid")
    ("life insurance") ("child")))

(defconst horoscope--dothing
  '(("brush its teeth") ("take a bath") ("make love")
    ("mow the lawn") ("go shopping") ("dig")
    ("rotate the TV antenna") ("eat worms")
    ("genetically engineer your plants")
    ("drink a bath")
    ("get life insurance from a TV ad")))

(defconst horoscope--verb
  '(("become pregnant") ("eat holes in your carpet")
    ("piss on the bed") ("eat watermelon")
    ("sell your house")
    ("give away your" "*relationship" "to" "*evilpeople")
    ("talk to piglet") ("get a" "*noun")
    ("have financial problems")
    ("adjust your girdle") ("sit quietly") ("sleep")
    ("drive") ("put money in the bank") ("play games")))

(defconst horoscope--evilpeople
  '(("Iranians") ("Iraquis") ("Americans")
    ("god-fearing Crustaceans") ("aliens") ("\"Bob\"")
    ("the Doctor") ("Frenchmen") ("Germans")
    ("piglet-haters") ("aliens from Mars")))

(defconst horoscope--evilperson
  '(("Iranian") ("Iraqui") ("American")
    ("god-fearing Crustacean") ("alien") ("bobbie")
    ("loon") ("Frenchman") ("Germans") ("piglet-haters")
    ("alien from Mars") ("Republican") ("Democrat")
    ("Communist") ("Socialist") ("idiot") ("artist")))

(defconst horoscope--thing
  '(("romance") ("nasty body odor")
    ("fortune (good or bad)") ("a gift")
    ("a small bomb") ("a flight recorder")
    ("a large dog") ("a piglet") ("a steering wheel")
    ("a toaster oven with a built-in clock radio")
    ("an egg") ("food") ("ice") ("bad weather")
    ("good weather") ("milk") ("a deadly disease")))

(defconst horoscope--discovery
  '(("you are married") ("you have two left feet")
    ("Nazi Germany is your country of birth")
    ("you do not have a pet")
    ("several Conspiracy members are following you")
    ("the wives are catching colds")
    ("your" "*relationship" "is confused")
    ("your spouse is an alien")
    ("you lost your piglet")
    ("someone thinks of you as Liza Minelli")
    ("you are Murphy Brown's child")
    ("your long-lost brother is lost")
    ("Michael Jackson is abusing your" "*noun")
    ("*relationship" "was responsible for the overthrow of Communist Russia")
    ("your" "*relationship" "is a" "*evilperson")
    ("you're originally from" "*planet")
    ("using a" "*noun" "as a sex toy is" "*value")))

(defconst horoscope--state
  '(("happy") ("unhappy") ("confused") ("sad")
    ("enlightened") ("a Borg") ("fulfilled") ("gay") ("tall")
    ("ill") ("shrunk") ("abused") ("tired") ("broke")))

(defconst horoscope--statenoun
  '(("happiness") ("unhappiness") ("confusion") ("sadness")
    ("enlightenment") ("bogosity") ("fulfillment") ("gaiety") ("tallness")
    ("illness") ("lossage") ("bozosity") ("weariness")))

(defconst horoscope--change
  '(("fluctuating") ("changing")
    ("turning" "*color")
    ("turning") ("*color")))

(defconst horoscope--color
  '(("green") ("red") ("blue") ("black") ("brown")
    ("yellow") ("orange") ("fuscia") ("mauve") ("plaid")))

(defconst horoscope--when
  '(("soon") ("eventually") ("later") ("never") ("someday") ("often")
    ("fall into a state of" "*statenoun," "but eventually")
    ("sometimes") ("perhaps in a few" "*time")
    ("once in a while")))

(defconst horoscope--adjective
  '(("good") ("bad") ("indifferent") ("valuable")
    ("expensive") ("sick") ("unhappy")))

(defconst horoscope--relationship
  '(("friend") ("enemy") ("relative") ("coworker")
    ("slave") ("mother") ("sister") ("spouse") ("owner")
    ("parent") ("child")))

(defconst horoscope--moneystates
  '(("unstable") ("positive") ("financial") ("good")
    ("bad") ("important") ("unimportant") ("exposed")
    ("significant")))

(defconst horoscope--vaguenumber
  '(("few") ("several") ("4 or 9") ("1 or 7")))

(defconst horoscope--greeted
  '(("said hello to") ("shook hands with") ("met")
    ("talked to") ("screwed") ("kissed") ("fondled gently")
    ("blessed") ("gave an organ to")))

(defconst horoscope--times
  '(("once") ("twice") ("a few times") ("5 or 11 times")
    ("3 to 6 times") ("thrice") ("988,122 times")))

(defconst horoscope--event
  '(("a party") ("a gathering of some sort")
    ("a social reception") ("an intimate office party")
    ("Maria Shriver's wedding") ("Michael Jackson's trial")
    ("a bad""frat party") ("Underwear City")))

(defconst horoscope--consider
  '(("ponder") ("think about") ("consider") ("try")
    ("make a stab at") ("meditate upon")
    ("look at deeply")))

;;;###autoload
(defun horoscope (&optional insertp)
  "Generate a random horoscope.
If called interactively, display the resulting horoscope in a buffer.
If called with a prefix argument or the Lisp argument INSERTP non-nil,
insert the resulting horoscope into the current buffer."
  (interactive "P")
  (let ((s (horoscope--iterate-list
            (horoscope--random-member horoscope--paragraph))))
    (and (or insertp (called-interactively-p 'interactive))
         (horoscope--display s "*Horoscope*" insertp))
    s))

(defun horoscope--display (string temp-buffer-name insertp)
  "Display the horoscope in a temporary buffer.
STRING is the horoscope
TEMP-BUFFER-NAME name of buffer
INSERTP when nil use JBW display hacks"
  (let ((temp-buffer-show-hook
         (function (lambda ()
                     (fill-paragraph nil)))))
    (if insertp
        (save-restriction
          (narrow-to-region (point) (point))
          (insert string)
          (fill-paragraph nil))
      (with-output-to-temp-buffer temp-buffer-name
	(princ string))
      (with-current-buffer temp-buffer-name
	(local-set-key (kbd "g") 'horoscope)))))

(defun horoscope--random-member (a)
  "Return a random member of list A."
  (and a
       (listp a)
       (nth (mod (random) (length a)) a)))

(defun horoscope--getlist (listname restoflist)
  "Process entries from list LISTNAME and from RESTOFLIST.
Handle periods and commas at the end of LISTNAME as needed.
LISTNAME, without punctuation, corresponds to an unprefixed
horoscope-- list constant, a member from that list is selected
and is processed with `horoscope--iterate-list', it is then
combined the punctuation and with RESTOFLIST which is
processed in the same way."
  (let* ((lastchar (aref listname (1- (length listname))))
         (punct-char-p (memq lastchar '(?. ?,)))
         (period-p (= lastchar ?.))
         (suffix (if punct-char-p
                     (substring listname 0 -1)
                   listname))
         (prefix "horoscope--"))
    (concat (horoscope--iterate-list
             (horoscope--random-member
              (symbol-value (intern (concat prefix suffix)))))
            (cond (period-p
                   (concat (char-to-string lastchar) " "))
                  (punct-char-p
                   (char-to-string lastchar))
                  (t ""))
            (if restoflist " " "")
            (horoscope--iterate-list restoflist))))

(defun horoscope--iterate-list (a)
  "Iterate over list A, preforming replacements.
Strings beginning with a '*' or '!' are replaced with a random selection
from the appropriate list."
  (cond ((null a) a)
        ((= (aref (car a) 0) ?*)
         (horoscope--getlist (substring (car a) 1) (cdr a)))
        ((= (aref (car a) 0) ?!)
         (capitalize
          (horoscope--getlist (substring (car a) 1) (cdr a))))
        (t
         (concat (car a)
                 (if (cdr a) " " "")
                 (horoscope--iterate-list (cdr a))))))

;;;###autoload
(defun horoscope-psychoanalyze ()
  "The astrologist goes to the analyst."
  (interactive)
  (require 'doctor)
  (doctor)
  (message "")
  (switch-to-buffer "*doctor*")
  (sit-for 0)
  (while (not (input-pending-p))
    (horoscope t)
    (insert "\n")
    (sit-for 0.2)
    (doctor-ret-or-read 1)))

(provide 'horoscope)

;;; horoscope.el ends here
