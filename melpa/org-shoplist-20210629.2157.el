;;; org-shoplist.el --- Eat the world -*- lexical-binding: t -*-

;; Copyright (C) 2019 lordnik22

;; Author: lordnik22
;; Version: 1.0.0
;; Package-Version: 20210629.2157
;; Package-Commit: 71ea7643e66c97d21df49fb8b600578ca0464f83
;; Keywords: extensions matching
;; URL: https://github.com/lordnik22
;; Package-Requires: ((emacs "25"))

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;; Commentary:
;; An extension to Emacs for operating on org-files who provide
;; food-recipes.  It's meant to generate shopping lists and make
;; eating-plans.  (We talk about delicious food — nothing technical).
;;; Code:
(require 'subr-x)
(require 'seq)
(require 'calc-ext)
(require 'calc-units)
(require 'org)
(require 'org-agenda)
(require 'calendar)
(require 'cl-lib)

(defgroup org-shoplist nil
  "Group which consist of all customizable variables for your personal shoplist."
  :prefix "org-shoplist-"
  :group 'applications)

(defcustom org-shoplist-buffer-name "*Org Shoplist*"
  "Default name of buffer when generating a shopping list."
  :type 'string)

(defcustom org-shoplist-keyword "TOBUY"
  "Keyword to mark recipes for shopping."
  :type 'string)

(defcustom org-shoplist-factor-property-name "FACTOR"
  "Property-name for factor-calculations on headers."
  :type 'string)

(defcustom org-shoplist-additional-units nil
  "Additional personal units which are needed for recipes with special units.
Beaware that the unit can't contain dots. Beaware that the units
are case-sensitive"
  :type '(repeat (list (symbol)
                       (string :tag "Definition")
                       (string :tag "Description"))))

(defcustom org-shoplist-explicit-keyword nil
  "When non-nil, only striclty include ingredients of marked headings.
For example: When a level-1-header is marked, the ingredients
defined in subheadings which aren’t marked don’t get included in
the shoplist."
  :type 'boolean)

(defcustom org-shoplist-aggregate t
  "When non-nil will aggregate the ingredients of the generated shoplist.
When nil won’t aggregate."
  :type 'boolean)

(defcustom org-shoplist-ing-start-char "("
  "Start char which introduces a ingredient."
  :type 'string)

(defcustom org-shoplist-ing-end-char ")"
  "End char which terminats a ingredient."
  :type 'string)

(defcustom org-shoplist-default-format #'org-shoplist-shoplist-as-table
  "Default formatter-function when inserting shoplist.
The formatter-function takes an shoplist as argument."
  :type 'function)

(defcustom org-shoplist-ing-default-separator " "
  "Default separator for ing parts."
  :type 'string)

(defcustom org-shoplist-auto-add-unit nil
  "When non-nil add unknown units to ‘ORG-SHOPLIST-ADDITIONAL-UNITS’.
Else throw an ‘user-error’."
  :type 'boolean)

(defcustom org-shoplist-precision 1
  "A integer defining to how many numbers should be rounded when necessary."
  :type 'integer)

(defcustom org-shoplist-inital-factor 1
  "Default inital factor when no factor set.
When nil and factor is changed, will throw an error in the sense:
‘inital factor not set’"
  :type 'integer)

(defconst org-shoplist--ing-first-part-regex
  '(format "\\([^%s%s]+?[^[:space:]%s%s]?\\)"
           (regexp-quote org-shoplist-ing-start-char)
           (regexp-quote org-shoplist-ing-end-char)
           (regexp-quote org-shoplist-ing-start-char)
           (regexp-quote org-shoplist-ing-end-char))
  "A regex which matches first part of ingredient (the amount).")

(defconst org-shoplist--ing-second-part-regex
  '(format "\\([^[:space:]%s%s]?[^%s%s]+?\\)"
           (regexp-quote org-shoplist-ing-start-char)
           (regexp-quote org-shoplist-ing-end-char)
           (regexp-quote org-shoplist-ing-start-char)
           (regexp-quote org-shoplist-ing-end-char))
  "A regex which matches second part of the ingredient (the name).")

(defconst org-shoplist--ing-content-spliter-regex "\\([[:space:]]+\\)"
  "A regex which matches whitespace that splits the data of ingredient.")

(defconst org-shoplist--ing-optional-content-spliter-regex "\\([[:space:]]*\\)"
  "A regex which matches whitespace that may occur thats splits data of ingredient.")

(defconst org-shoplist-ing-regex
  '(concat (regexp-quote org-shoplist-ing-start-char)
           (eval org-shoplist--ing-first-part-regex)
           (eval org-shoplist--ing-content-spliter-regex)
           (eval org-shoplist--ing-second-part-regex)
           (regexp-quote org-shoplist-ing-end-char))
  "Match an ingredient.")

(defun org-shoplist--calc-unit (amount)
  "Get the unit from AMOUNT by suppling it to calc.
AMOUNT is handled as a string.
When AMOUNT has no unit return nil."
  (let ((unit (calc-eval (math-extract-units (math-read-expr amount)))))
    (unless (string= "1" unit) unit)))

(defun org-shoplist--calc-default-unit (amount)
  "Find the ground unit of ‘AMOUNT’s unit.
When ‘AMOUNT’ has no unit, return 1.
When ‘AMOUNT’ nil, return nil"
  (if (null amount)
      nil
    (calc-eval (math-extract-units (math-to-standard-units (math-read-expr amount) nil)))))

(defun org-shoplist--calc-eval (str round-func &optional separator &rest args)
  "Calc-eval ‘STR’ and apply ‘ROUND-FUNC’ to the final result.
Optional ‘SEPARATOR’ and ‘ARGS’ are supplied to (calc-eval).
When ‘STR’ is nil or 0, return 0.
When ‘ROUND-FUNC’ is nil, result won’t be rounded."
  (if (and str (not (string= str "0")))
      (let ((e-str (save-match-data (ignore-errors (eval (calc-eval str separator args))))))
        (when (or (null e-str) (string-match-p "[<>+*/-]" e-str)) (user-error "Invalid ‘AMOUNT’(%s) for ingredient" str))
        (when (string-match "\\(\\.\\)\\([^0-9]\\|$\\)" e-str) (setq e-str (replace-match "" t t e-str 1)))
        (if (string= "0" e-str)
            (concat e-str (org-shoplist--calc-unit str))
          (if (string-match-p "[^0-9]" (substring e-str 0 1))
              (concat "1" e-str)
            (let* ((split-amount-name (split-string e-str " ")))
              (concat (calc-eval (if (null round-func)
                                     (car split-amount-name)
                                   (funcall round-func (math-read-expr (car split-amount-name)) org-shoplist-precision)))
                      (cadr split-amount-name))))))
    "0"))

(defun org-shoplist--ing-transform-amount (amount &optional round-func)
  "Transform ‘AMOUNT’ to a valid form when possible else throw an error.
Optional ‘ROUND-FUNC’ is a function which is applied to the
result which rounds it.  Default is (math-round)."
  (let ((math-backup math-simplifying-units)
        (unit-backup math-additional-units)
        (str-amount (cond ((numberp amount) (number-to-string amount))
                          ((null amount) "0")
                          (amount))))
    (unwind-protect
        (progn
          (setq math-simplifying-units t)
          (setq math-additional-units org-shoplist-additional-units)
          (let ((e-str-amount
                 (org-shoplist--calc-eval str-amount round-func)))
            (if (and (not (string-match "[<>+*/-]" str-amount))
                     (string-match "[^.0-9<>+*/-]" str-amount)
                     (not (org-shoplist--calc-unit str-amount)))
                (if org-shoplist-auto-add-unit
                    (progn
                      (setq math-additional-units nil)
                      (add-to-list 'org-shoplist-additional-units (list (intern (match-string 0 e-str-amount)) nil "*Auto inserted unit by org-shoplist"))
                      (setq math-additional-units org-shoplist-additional-units)
                      (setq math-units-table nil)
                      (setq e-str-amount (org-shoplist--ing-transform-amount e-str-amount round-func)))
                  (user-error "Unit in ‘AMOUNT’(%s) unknown; Set org-shoplist-auto-add-unit to automatically add these units with a default definiton" amount)))
            e-str-amount))
      (setq math-simplifying-units math-backup)
      (setq math-additional-units unit-backup))))

(defun org-shoplist-ing-name (ing)
  "Get name of ‘ING’."
  (car ing))

(defun org-shoplist-ing-amount (ing)
  "Get amount of ‘ING’."
  (cadr ing))

(defun org-shoplist-ing-unit (ing)
  "Get unit of ‘ING’."
  (let ((unit-backup math-additional-units))
    (unwind-protect
        (progn
          (dolist (i org-shoplist-additional-units) (add-to-list 'math-additional-units i))
          (org-shoplist--calc-unit (org-shoplist-ing-amount ing)))
      (setq math-additional-units unit-backup))))

(defun org-shoplist-ing-group (ing)
  "Get group of ‘ING’."
  (caddr ing))

(defun org-shoplist-ing-separator (ing)
  "Get separator of ‘ING’."
  (cadddr ing))

(defun org-shoplist-ing-create (amount name &optional separator)
  "Create an ingredient.
‘AMOUNT’ can be a string, a number or a valid sequence. It will
be supplied to ‘(calc-eval)’.
‘NAME’ is a string.
‘SEPARATOR’ a string by which ‘NAME’ and ‘AMOUNT’ is separated.
If one constraint isn’t met, throw error."
  (save-match-data
    (unless (stringp name) (user-error "Invalid ‘NAME’(%S) for ingredient" name))
    (let ((transform-amount (org-shoplist--ing-transform-amount amount)))
      (list name
            transform-amount
            (org-shoplist--calc-default-unit transform-amount)
            (if (null separator) org-shoplist-ing-default-separator separator)))))

(defun org-shoplist-ing-content-string (ing)
  "Return ‘ING’ in following format: “amount name”."
  (concat
   (org-shoplist-ing-amount ing)
   (org-shoplist-ing-separator ing)
   (org-shoplist-ing-name ing)))

(defun org-shoplist-ing-content-string-invert (ing)
  "Return ‘ING’ in following format: “name amount”."
  (concat
   (org-shoplist-ing-name ing)
   (org-shoplist-ing-separator ing)
   (org-shoplist-ing-amount ing)))


(defun org-shoplist-ing-full-string (ing)
  "Return ‘ING’ in following format: “(amount name)”."
  (concat org-shoplist-ing-start-char
          (org-shoplist-ing-amount ing)
          (org-shoplist-ing-separator ing)
          (org-shoplist-ing-name ing)
          org-shoplist-ing-end-char))

(defun org-shoplist-ing-+ (&rest amounts)
  "Add ‘AMOUNTS’ together and return the sum."
  (let ((sum-amount
         (mapconcat
          (lambda (x)
            (cond ((stringp x) x)
                  ((integerp x) (number-to-string x))
                  ((null x) "0")
                  ((listp x) (org-shoplist-ing-amount x))
                  (t (user-error "Given ‘AMOUNT’(%S) can’t be converted" x))))
          amounts "+")))
    (let ((t-sum-amount (ignore-errors (org-shoplist--ing-transform-amount sum-amount))))
      (unless t-sum-amount (user-error "Incompatible units while aggregating(%S)" amounts))
      t-sum-amount)))

(defun org-shoplist-ing-* (ing factor &optional round-func)
  "Multiply the amount of ‘ING’ with given ‘FACTOR’.
Return new ingredient with modified amount.  When ‘ROUND-FUNC’
given, round resulting amount with it."
  (org-shoplist-ing-create
   (org-shoplist--ing-transform-amount (concat (number-to-string factor) "*" (org-shoplist-ing-amount ing)) round-func)
   (org-shoplist-ing-name ing)
   (org-shoplist-ing-separator ing)))

(defun org-shoplist-ing-/ (ing divisor &optional round-func)
  "Devide the amount of ‘ING’(dividend) by ‘DIVISOR’.
Return new ingredient with modified amount.  When ‘ROUND-FUNC’
given, round resulting amount(quotient)."
  (org-shoplist-ing-create
   (org-shoplist--ing-transform-amount (concat (org-shoplist-ing-amount ing) "/" (number-to-string divisor)) round-func)
   (org-shoplist-ing-name ing)
   (org-shoplist-ing-separator ing)))

(defun org-shoplist-ing-aggregate (ings)
  "Group ‘INGS’ by there group (ground-unit) and sum the ‘INGS’ which have same name."
  (let ((group-ings (seq-group-by
                     (lambda (x) (list (org-shoplist-ing-name x) (org-shoplist-ing-group x)))
                     ings))
        (aggregate-ings (list)))
    (while (car group-ings)
      (setq aggregate-ings
            (cons (org-shoplist-ing-create
                   (apply #'org-shoplist-ing-+ (cdar group-ings))
                   (org-shoplist-ing-name (caar group-ings))
                   (org-shoplist-ing-separator (caar group-ings)))
                  aggregate-ings))
      (setq group-ings (cdr group-ings)))
    aggregate-ings))

(defun org-shoplist--ing-read-loop (str start-pos ings)
  "Recursive helper-function for ‘(org-shoplist-ing-read)’ to search ings.
‘STR’ is a string to search for ingredients.
‘START-POS’ is where to start searching in ‘STR’.
‘INGS’ is a list found ingredients."
  (if (string-match
       (eval org-shoplist-ing-regex)
       str
       start-pos)
      (org-shoplist--ing-read-loop
       str
       (match-end 0)
       (cons (org-shoplist-ing-create
              (match-string 1 str)
              (match-string 3 str)
              (match-string 2 str))
             ings))
    ings))

(defun org-shoplist--ing-concat-when-broken (str last-pos)
  "Concat broken ing when it’s splitted into two by newline.
‘STR’ is a string which maybe broken
‘LAST-POS’ is position of last match"
  (when (string-match (concat (regexp-quote org-shoplist-ing-start-char) (eval org-shoplist--ing-first-part-regex) (eval org-shoplist--ing-content-spliter-regex) "$")
                      str
                      last-pos)
    (let ((ing-start (match-string 0 str))
          (nl (save-excursion (beginning-of-line 2) (thing-at-point 'line))))
      (when (string-match (concat "^" (eval org-shoplist--ing-optional-content-spliter-regex) (eval org-shoplist--ing-second-part-regex) (regexp-quote org-shoplist-ing-end-char))
                          nl)
        (concat ing-start (match-string 0 nl))))))

(defun org-shoplist-ing-read (&optional aggregate str)
  "Return a list of parsed ingredients in ‘STR’.
When ‘AGGREGATE’ is non-nil, will aggregate ingredients where possible.
When ‘STR’ is nil, read line where point is at."
  (unless str (setq str (thing-at-point 'line)))
  (unless (or (null str) (string= str ""))
    (let ((read-ings (org-shoplist--ing-read-loop str 0 '())))
      (when-let ((breaked-ing (org-shoplist--ing-concat-when-broken str (if (null read-ings) 0 (match-end 0)))))
        (setq read-ings (org-shoplist--ing-read-loop breaked-ing 0 read-ings)))
      (if aggregate
          (org-shoplist-ing-aggregate read-ings)
        (reverse read-ings)))))

(defun org-shoplist-recipe-create (name factor read-func ings)
  "Create a recipe.
‘NAME’ must be a string.
‘FACTOR’ which maybe set on the recipe
‘READ-FUNC’ describe how ‘INGS’ are read from buffer. Can be nil.
‘INGS’ a list of valid ingredients.
Use ‘org-shoplist-ing-create’ to create valid ingredients."
  (when (and (stringp name) (string= name "")) (user-error "Invalid name for recipe: ‘%s’" name))
  (when (and (not (null read-func))
             (or (not (symbolp read-func))
                 (null (symbol-function read-func))))
    (error "ING-READ-FUNC(%s) not a symbol-function!" read-func))
  (unless (or (null factor) (numberp factor))
    (setq factor (if (math-floatp factor)
                     (string-to-number (calc-eval factor))
                   (condition-case nil (cl-parse-integer factor)
                     ('error (user-error "Invalid factor for recipe(%s): ‘%s’" name factor)))) ))
  (when (and name (not (equal ings '(nil))))
    (if (and ings (listp (car ings)))
        (list name factor read-func ings)
      nil)))

(defun org-shoplist-recipe-name (recipe)
  "Get name of ‘RECIPE’."
  (car recipe))

(defun org-shoplist-recipe-factor (recipe)
  "Get factor from ‘RECIPE’."
  (cadr recipe))

(defun org-shoplist-recipe-ing-read-function (recipe)
  "Get function-name of how ings are read of ‘RECIPE’."
  (caddr recipe))

(defun org-shoplist-recipe-get-all-ing (recipe)
  "Get all ingredients of ‘RECIPE’."
  (cadddr recipe))

(defun org-shoplist-recipe-* (recipe factor &optional round-func)
  "Multiply all ingredients of ‘RECIPE’ by given ‘FACTOR’.
When ROUND-FUNC given round resulting amounts with it."
  (if (or (null recipe) (null factor))
      recipe
    (let (f-ing-list)
      (dolist (i (org-shoplist-recipe-get-all-ing recipe) f-ing-list)
        (push (org-shoplist-ing-* i factor round-func) f-ing-list))
      (org-shoplist-recipe-create
       (org-shoplist-recipe-name recipe)
       (when (not (null (org-shoplist-recipe-factor recipe)))
         (if (null round-func)
             (* factor (org-shoplist-recipe-factor recipe))
           (funcall round-func
                    (math-read-expr (number-to-string (* factor (org-shoplist-recipe-factor recipe))))
                    org-shoplist-precision)))
       (org-shoplist-recipe-ing-read-function recipe)
       (reverse f-ing-list)))))

(defun org-shoplist-recipe-/ (recipe divisor &optional round-func)
  "Divide all ingredients (and factor) of ‘RECIPE’ by given ‘DIVISOR’.
When ‘ROUND-FUNC’ given round resulting amounts(quotients) with it."
  (if (or (null recipe) (null divisor))
      recipe
    (let (f-ing-list)
      (dolist (i (org-shoplist-recipe-get-all-ing recipe) f-ing-list)
        (push (org-shoplist-ing-/ i divisor round-func) f-ing-list))
      (org-shoplist-recipe-create
       (org-shoplist-recipe-name recipe)
       (when (not (null (org-shoplist-recipe-factor recipe)))
         (if (null round-func)
             (/ (org-shoplist-recipe-factor recipe) divisor)
           (funcall round-func
                    (math-read-expr (number-to-string (/ (org-shoplist-recipe-factor recipe) divisor)))
                    org-shoplist-precision)))
       (org-shoplist-recipe-ing-read-function recipe)
       (reverse f-ing-list)))))

(defun org-shoplist--recipe-read-factor-upwards (upper-limit)
  "Read factor at current header and go upwords till found.
‘UPPER-LIMIT’ is a org-header-level and it searches till
‘UPPER-LIMIT’ is reached.  When nothing found return nil."
  (let ((found-factor (org-shoplist--recipe-read-factor))
        (heading-star-count (org-current-level)))
    (while (and (not found-factor)
                (not (null heading-star-count))
                (not (= heading-star-count upper-limit))
                (not (= (point) (point-min))))
      (setq heading-star-count (org-up-heading-safe))
      (setq found-factor (org-shoplist--recipe-read-factor)))
    found-factor))

(defun org-shoplist--recipe-read-factor ()
  "Read value with property-name ‘ORG-SHOPLIST-FACTOR-PROPERTY-NAME’.
Must be in a recipe, else throw ‘(user-error)’."
  (unless (ignore-errors (org-back-to-heading t)) (user-error "Recipe not found"))
  (ignore-errors (string-to-number (org-entry-get (point) org-shoplist-factor-property-name))))

(defun org-shoplist--recipe-read-ings-current ()
  "Collect all ingredients but only for current level."
  (save-match-data
    (let ((ing-list nil)
          (current-header (org-get-heading)))
      (beginning-of-line 2)
      (while (and (string= current-header (org-get-heading))
                  (not (>= (point) (point-max))))
        (setq ing-list (append ing-list (org-shoplist-ing-read)))
        (beginning-of-line 2))
      ing-list)))

(defun org-shoplist--recipe-read-ings-marked-tree (mark)
  "Collect all ingredients of recipe and marked tree.
Underlying headers are collected when they have ‘MARK’ as
todo-state.
‘MARK’ must be a string that represent the todo state."
  (save-match-data
    (let ((ing-list nil)
          (h (org-get-heading)) ;current header
          (l (org-current-level)))
      (beginning-of-line 2)
      (while (and (or (string= h (org-get-heading))
                      (> (org-current-level) l))
                  (not (>= (point) (point-max))))
        (if (string= (org-get-todo-state) mark)
            (setq ing-list (append ing-list (org-shoplist-ing-read))))
        (beginning-of-line 2))
      ing-list)))

(defun org-shoplist--recipe-read-ings-tree ()
  "Collect all ingredients of recipe with it’s whole underlying tree.
This means all ingredients in sub-heading and sub-sub-headings and
so on are included in the result."
  (save-match-data
    (let ((ing-list nil)
          (h (org-get-heading)) ;current header
          (l (org-current-level)))
      (beginning-of-line 2)
      (while (and (or (string= h (org-get-heading))
                      (> (org-current-level) l))
                  (not (>= (point) (point-max))))
        (setq ing-list (append ing-list (org-shoplist-ing-read)))
        (beginning-of-line 2))
      ing-list)))

(defun org-shoplist--recipe-read-ings-keyword-tree ()
  "Collect all ingredients of recipe and underlying tree marked with ‘ORG-SHOPLIST-KEYWORD’."
  (org-shoplist--recipe-read-ings-marked-tree org-shoplist-keyword))

(defun org-shoplist-recipe-read (ing-read-func &optional aggregate)
  "Return a recipe structure or throw error.
Assums that at beginning of recipe. Which is
at ‘(beginning-of-line)’ at heading (╹* Nut Salat...). To read a
recipe there must be at least a org-heading (name of the recipe)
and one ingredient.
‘AGGREGATE’ ingredients when non-nil.
‘ING-READ-FUNC’ function which collects the ingedient in that given way.
See ‘(org-shoplist-recipe-create)’ for more details on creating general recipes."
  (unless (functionp ing-read-func) (error "ING-READ-FUNC(%s) not a function!" ing-read-func))
  (save-match-data
    (unless (looking-at org-heading-regexp) (user-error "Not at beginning of recipe"))
    (let ((factor (save-match-data (save-excursion (org-shoplist--recipe-read-factor))))
          (read-ings (funcall ing-read-func)))
      (org-shoplist-recipe-create
       (string-trim (replace-regexp-in-string org-todo-regexp "" (match-string 2)))
       (if (or factor (not org-shoplist-inital-factor)) factor org-shoplist-inital-factor)
       ing-read-func
       (if aggregate (reverse (org-shoplist-ing-aggregate read-ings)) read-ings)))))

(defun org-shoplist-recipe-replace (replacement-recipe)
  "Replace recipe where point is at with ‘REPLACEMENT-RECIPE’.
The position of the ingredients in replacement-recipe is relevant.
When a position is nil in the ingredient-list won’t replace that ingredient.
When ‘REPLACEMENT-RECIPE’ is nil, won’t replace the recipe."
  (unless (null replacement-recipe)
    (let ((current-recipe (save-excursion (org-shoplist-recipe-read (org-shoplist-recipe-ing-read-function replacement-recipe)))))
      (if current-recipe
          (progn (save-excursion
                   (cl-mapc
                    (lambda (new old)
                      (search-forward (org-shoplist-ing-full-string old) nil t 1)
                      (replace-match (org-shoplist-ing-full-string new) t))
                    (org-shoplist-recipe-get-all-ing replacement-recipe)
                    (org-shoplist-recipe-get-all-ing current-recipe)))
                 (unless (null (org-shoplist-recipe-factor replacement-recipe))
                   (org-set-property org-shoplist-factor-property-name (number-to-string (org-shoplist-recipe-factor replacement-recipe)))))
        nil))))


(defun org-shoplist-shoplist-create (&rest recipes)
  "Create a shoplist.
‘RECIPES’ is a sequence of recipes."
  (when (and recipes (car recipes))
    (list (calendar-current-date)
          recipes
          (reverse (org-shoplist-ing-aggregate (apply #'append (mapcar #'org-shoplist-recipe-get-all-ing recipes)))))))

(defun org-shoplist-shoplist-creation-date (shoplist)
  "Get shopdate of ‘SHOPLIST’."
  (car shoplist))

(defun org-shoplist-shoplist-recipes (shoplist)
  "Get recipes of ‘SHOPLIST’."
  (cadr shoplist))

(defun org-shoplist-shoplist-ings (shoplist)
  "Get recipes of ‘SHOPLIST’."
  (caddr shoplist))

(defun org-shoplist-shoplist-read (ing-read-func &optional aggregate)
  "Parse current buffer and return a shoplist.
When something is wrong will throw an error.
‘AGGREGATE’ ingredients when non-nil.
‘ING-READ-FUNC’ function which collects the ingedient in that given way."
  (let ((recipe-list
	 (save-match-data
	   (let ((recipe-list nil))
	     (while (and (not (= (point-max) (point)))
			 (search-forward-regexp org-heading-regexp nil t 1))
	       (when (save-excursion (beginning-of-line 1) (looking-at-p (concat ".+" org-shoplist-keyword)))
		 (beginning-of-line 1)
         (setq recipe-list (append recipe-list (list (org-shoplist-recipe-read ing-read-func aggregate))))))
	     recipe-list))))
    (apply #'org-shoplist-shoplist-create (reverse recipe-list))))

(defun org-shoplist-shoplist-as-table (shoplist)
  "Format ‘SHOPLIST’ as table."
  (concat "|" (mapconcat 'identity (list "Ingredient" "Amount") "|")
          "|\n"
          (mapconcat (lambda (i)
                       (concat "|" (org-shoplist-ing-name i) "|" (org-shoplist-ing-amount i)))
                     (org-shoplist-shoplist-ings shoplist)
                     "|\n")
          "|\n"))

(defun org-shoplist-shoplist-as-todo-list (shoplist)
  "Format ‘SHOPLIST’ as todo-list."
  (concat
   (concat "#+SEQ_TODO:\s" org-shoplist-keyword "\s|\sBOUGHT\n")
   (mapconcat (lambda (i) (concat "*\s" org-shoplist-keyword "\s" (org-shoplist-ing-content-string-invert i)))
              (org-shoplist-shoplist-ings shoplist)
              "\n")))

(defun org-shoplist-shoplist-as-recipe-list (shoplist)
  "Format ‘SHOPLIST’ as recipe-list."
  (concat
   (concat "#+SEQ_TODO:\s" org-shoplist-keyword "\s|\sBOUGHT\n")
   (mapconcat (lambda (r)
                (concat "*\s" org-shoplist-keyword "\s" (org-shoplist-recipe-name r) "\s[0/0]\n"
                        (mapconcat (lambda (i) (concat "-\s[ ]\s" (org-shoplist-ing-content-string i)))
                                   (org-shoplist-recipe-get-all-ing r)
                                   "\n")))
              (org-shoplist-shoplist-recipes shoplist)
              "\n")))

(defun org-shoplist-shoplist-insert (as-format)
  "Insert a shoplist with given format(‘AS-FORMAT’)."
  (save-excursion
    (funcall #'org-mode)
    (insert as-format)
    (goto-char (point-min))
    (org-update-checkbox-count t)
    (when (org-at-table-p) (org-table-align))))

(defun org-shoplist (&optional arg)
  "Generate a shoplist from current buffer.
With a non-default prefix argument ARG, prompt the user for a
formatter; otherwise, just use ‘ORG-SHOPLIST-DEFAULT-FORMAT’."
  (interactive "p")
  (let ((formatter
         (if (= arg 1)
             org-shoplist-default-format
           (intern (completing-read "Formatter-Name: " obarray 'functionp t nil nil "org-shoplist-default-format"))))
        (sl
         (save-excursion
           (goto-char (point-min))
           (org-shoplist-shoplist-read (if org-shoplist-explicit-keyword
                               'org-shoplist--recipe-read-ings-keyword-tree
                             'org-shoplist--recipe-read-ings-tree)
                           org-shoplist-aggregate))))
    (with-current-buffer (switch-to-buffer org-shoplist-buffer-name)
      (when (>= (buffer-size) 0) (erase-buffer))
      (org-shoplist-shoplist-insert (funcall formatter sl)))))

;;;###autoload
(defun org-shoplist-init ()
  "Setting the todo-keywords for current file."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (unless (looking-at-p "#\\+SEQ_TODO:") (insert "#\\+SEQ_TODO: " org-shoplist-keyword))
    (funcall #'org-mode)))

;;;###autoload
(defun org-shoplist-unmark-all ()
  "Unmark all recipes which are marked with ‘ORG-SHOPLIST-KEYWORD’."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (beginning-of-line 2)
    (while (re-search-forward (concat " " org-shoplist-keyword) nil t)
      (replace-match "" nil nil))))

;;;###autoload
(defun org-shoplist-recipe-set-factor (factor)
  "Set ‘FACTOR’ with property-name ‘ORG-SHOPLIST-FACTOR-PROPERTY-NAME’ on current recipe."
  (interactive "NValue: ")
  (org-set-property org-shoplist-factor-property-name (number-to-string factor)))

(defun org-shoplist-recipe-change-factor (modify-factor)
  "Modify factor of current recipe by ‘MODIFY-FACTOR’.
Will change factors of whole tree.
When ‘ORG-SHOPLIST-INITAL-FACTOR’ nil and a recipe has no factor will throw error."
  (unless (ignore-errors (org-back-to-heading t)) (user-error "Recipe not found"))
  (let* ((recipe-list nil)
         (uppest-recipe-level (org-current-level))
         (previous-old-factor nil)
         (previous-new-factor nil))
    (org-map-tree
     (lambda ()
       (let ((recipe (save-excursion (org-shoplist-recipe-read 'org-shoplist--recipe-read-ings-current nil))))
         (if (not (null recipe))
           (let* ((factor-one-recipe (org-shoplist-recipe-/ recipe (org-shoplist-recipe-factor recipe)))
                  (recipe-factor (if (null (org-shoplist-recipe-factor recipe))
                                     (let ((upwards-factor (save-excursion (org-shoplist--recipe-read-factor-upwards uppest-recipe-level))))
                                       (unless upwards-factor (user-error "Property %s not defined" org-shoplist-factor-property-name))
                                       upwards-factor)
                                   (org-shoplist-recipe-factor recipe)))
                  (recipe-new-factor (if (and previous-new-factor previous-old-factor)
                                         (* recipe-factor (/ (float previous-new-factor) previous-old-factor))
                                       (+ recipe-factor modify-factor))))
             (when (< recipe-new-factor 1) (user-error "Can’t decrement under 1"))
             (setq recipe-list (append recipe-list
                                       (list (org-shoplist-recipe-* factor-one-recipe
                                                        recipe-new-factor
                                                        nil))))
             (setq previous-old-factor recipe-factor)
             (setq previous-new-factor recipe-new-factor))
           (setq recipe-list (append recipe-list (list nil)))))))
    (org-map-tree
     (lambda ()
       (unless (null recipe-list)
         (save-excursion (org-shoplist-recipe-replace (car recipe-list))))
       (setq recipe-list (cdr recipe-list))))))

;;;###autoload
(defun org-shoplist-factor-down ()
  "Decrement the factor-property of current header."
  (interactive)
  (save-excursion (org-shoplist-recipe-change-factor -1)))

;;;###autoload
(defun org-shoplist-factor-up ()
  "Increment the factor-property of current header."
  (interactive)
  (save-excursion (org-shoplist-recipe-change-factor 1)))

(provide 'org-shoplist)
;;; org-shoplist.el ends here
