;;; egalgo.el --- Genetic algorithm for Emacs        -*- lexical-binding: t; -*-

;; Copyright (C) 2019  ROCKTAKEY

;; Author: ROCKTAKEY <rocktakey@gmail.com>
;; Keywords: data
;; Package-Version: 20190706.1611
;; Package-Commit: e683b16ed4265ddb46efcc8cbf9503301cc39e22

;; Version: 1.0.2

;; URL: https://github.com/ROCKTAKEY/egalgo

;; Package-Requires: ((dash "2.14") (emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides some functions which enable you to run genetic
;; algorithm in Emacs.

;; `egalgo-run' is main function of this package.  See README.org and document of
;; the function.


;;; Code:

(require 'cl-lib)
(require 'dash)

(defgroup egalgo ()
  "Group for egalgo."
  :group 'lisp
  :prefix "egalgo-")

(defvar egalgo-latest nil "Latest result of `egalgo-run'.")



;; Some functions

(defsubst egalgo--rand-bool (probability)
  "Return t with probability of PROBABILITY."
  (< (cl-random 1.0) probability))

(defun egalgo--t-p (object)
  "Return t if OBJECT is t."
  (eq t object))


;; Selectors
;; Selector should not select chromosome rated nil.

(defvar egalgo-selector-alias
  '((roulette . egalgo-roulette-selector))
  "Aliases for selector of egalgo.
each element is cons cell (ALIAS . FUNCTION).  You can use ALIAS
on the argument SELECTOR of `egalgo-run', instead of FUNCTION.

FUNCTION should:
  - take 1 argument, which is list of rate of each chromosome
  - return index of selected chromosome
  - NOT select the chromosome whose rate is nil")

(defun egalgo-roulette-selector (rates)
  "Select 1 chromosome by roulette from RATES.  Return index of the selected.
RATES are list of rate of each chromosome, or nil (means unselectable)."
  (let* ((temp (or (car rates) 0))
         (r-sum
          (--map (setq temp (+ (or it 0) temp))
                 rates))
         (sum (car (last r-sum)))
         (rand (cl-random (float sum)))
         (i 0))
    (--each-while r-sum (< it rand) (setq i (1+ i)))
    i))

(defun egalgo--select-2 (rates selector)
  "Select 2 chromosomes with roulette using RATES by SELECTOR.
Return list of 2 indexes."
  (let* ((first  (funcall selector rates))
         (temp (nth first rates))
         second)
    ;; Selected index is temporarily replaced nil (means unselectable).
    (setf (nth first rates) nil)

    (setq second (funcall selector rates))

    (setf (nth first rates) temp)
    (list first second)))


;; Crossover

(defmacro egalgo--crossover (index chromosome1 chromosome2)
  "Crossover CHROMOSOME1 and CHROMOSOME2 on INDEXth gap.
Do not use 0 (and less) as INDEX.  First gap is indexed 1."
  (declare (debug (form place place)))
  (let ((temp (cl-gensym))
        (i (cl-gensym)))
    `(let ((,i ,index) ,temp)
       (when (<= ,i 0)
        (error "You cannot use 0 or less number as index"))
       (setq ,temp (nthcdr ,i ,chromosome1))
       (setcdr (nthcdr (1- ,i) ,chromosome1) (nthcdr ,i ,chromosome2))
       (setcdr (nthcdr (1- ,i) ,chromosome2) ,temp)
       (list ,chromosome1 ,chromosome2))))


;; Generate genes and a chromosome.

(defvar egalgo--generate-alist
  '((vectorp  . egalgo--generate-range)
    (listp    . egalgo--generate-choose)
    (egalgo--t-p    . egalgo--generate-bool)
    (integerp . egalgo--generate-choose-from-zero-to))
  "Used to determine gene generator from each element of chromosome-definition.
Each element is cons cell (DETECTOR . GENERATOR).
DETECTOR should be a function which takes 1 argument OBJECT, and returns
t if OBJECT determines to use GENERATOR as generator of gene.
GENERATOR should be a function which takes 1 argument OBJECT detected by
DETECTOR, and returns generated gene.")

(defun egalgo--generate-range (arg)
  "Generate continuous gene.  ARG is vector which have 2 integer elements.
Return decimal ranged from the first element to the second one."
  (let* ((bgn (float (aref arg 0)))
         (end (float (aref arg 1)))
         (range (- end bgn)))
    (+ (cl-random range) bgn)))

(defun egalgo--generate-choose (arg)
  "Generate discrete gene.  ARG is list, one of whose elements is returned."
  (nth (cl-random (length arg)) arg))

(defun egalgo--generate-bool (_arg)
  "Generate boolean gene.  Return nil or t."
  (egalgo--rand-bool 0.5))

(defun egalgo--generate-choose-from-zero-to (arg)
  "Generate discrete gene.  Return non-negative integer which is less than ARG."
  (cl-random arg))

(defun egalgo--generate-chromosome-forms (chromosome-definition)
  "Generate chromosome-forms from CHROMOSOME-DEFINITION.
Return vector, each element of which is a form returning gene if evaluated."
  (vconcat
   (--map `(,(cdr (-first
                   (lambda (arg) (funcall (car arg) it))
                   egalgo--generate-alist))
            ',it)
          chromosome-definition)))

(defun egalgo--generate-chromosomes-from-forms (chromosome-forms size)
  "Generate SIZE chromosomes using CHROMOSOME-FORMS.
Each element of chromosome is generated to evaluate each element of
CHROMOSOME-FORMS."
  (let (result)
    (--dotimes size
      (push
       (cl-map 'list 'eval chromosome-forms)
       result))
    result))

(defun egalgo--generate-chromosomes-from-definition (chromosome-definition size)
  "Generate SIZE chromosomes using CHROMOSOME-DEFINITION.
Each element of chromosome is generated to evaluate each element of
CHROMOSOME-FORMS, which is generated from CHROMOSOME-DEFINITION."
  (egalgo--generate-chromosomes-from-forms
   (egalgo--generate-chromosome-forms chromosome-definition) size))


;; For users.

(cl-defun egalgo-run (chromosome-definition
                rater            ;Function returning non-negative float
                &key
                (size 100)       ;non-negative integer
                (crossover 0.9)  ;[0, 1]
                (mutation 0.01)  ;[0, 1]
                (n-point-crossover 1)    ;t ... uniformcrossover
                (selector 'roulette)     ;function or alias
                (termination 1000)       ;integer: generation number.
                (log nil)                ;bool
                (elite 0)                ;non-negative integer
                (show-rates nil)
                ;; arguments showed below are available in the future.
                (_async nil))             ;bool
  "Run genetic algorithm with CHROMOSOME-DEFINITION and RATER.

CHROMOSOME-DEFINITION is the first argument, and the value should be list.
Each element expresses each gene.  Each element should be:

  - t
   Means boolean gene. On the genetic locus, there is t or nil
   in chromosomes.

  - Vector which has 2 elements
   Means spreaded and continuous gene. For example, on the genetic locus
   of [3 5], there is decimal value from 3 to 5 in chromosomes.

  - list
   Means discrete gene. For example, on genetic locus of (1 3 5 foo),
   there is 1, 3, 5 or symbol foo in chromosomes.

  - positive integer
   Also means discrete gene. If the number is n, gene on the genetic locus can
   be integer which is 0 or more, and less than n.
   For example, 5 is same as (0 1 2 3 4).

RATER should be a function which takes 1 argument, and returns non-negative
integer or decimal. The argument is chromosome, which is defined
by CHROMOSOME-DEFINITION. Returned value is rate of the chromosome passed
as the argument.

SIZE is the number of chromosomes in each generation.
It should be positive integer. Default value is 100.

CROSSOVER is probability of crossovering 2 chromosomes.
If determine DO crossover, then select 2 chromosomes, and crossover them.
If not, Select 1 chromosome and push it to next generation.
This should be non-negative decimal which is 1 or less. Default value is 0.9.

MUTATION is probability of each gene being mutated.
This should be non-negative decimal which is 1 or less. Default value is 0.01.

N-POINT-CROSSOVER is number of times crossovering per 1 crossovering process.
If the value is t, it means unicrossover. This should be positive integer or t.

SELECTOR is a function which selects chromosomes used to crossover or take over.
This function should:
   - take 1 argument, which is list of rate of each chromosome
   - return index of selected chromosome
   - NOT select the chromosome whose rate is nil
This can be alias, which is defined in `egalgo-selector-alias'.
Default value is roulette, which means roulette selector.

TERMINATION is the number of maximum generation, or function which determine to
termination the algorithm or not.
If number, finish algorithm when generation become the value.
If function, continue algorithm when the function returns non-nil. The function
take 2 arguments, stack list of rates of all generation and generation number.
First element of the stack list is rates (list of rate of each chromosome) of
latest generation, for example.
Default value is 1000.

If LOG is t, plist returned by `egalgo-run' has value keyed by :chromosomes-log.
This is stack list of chromosomes of each generation. car of it is same as
chromosomes of last generation. Default value is nil.

ELITE is the number of elite chromosomes, which absolutely stays until next
generation. Default value is 0.

If SHOW-RATES is t, display rates of chromosomes of each generation.
Default value is nil.
"
  (let* ((chromosome-forms
          (egalgo--generate-chromosome-forms chromosome-definition))
         (next-chromosomes
          (egalgo--generate-chromosomes-from-forms chromosome-forms size))
         (selector (or (cdr (assq selector egalgo-selector-alias))
                       selector))
         (length (length chromosome-definition))
         (generation 0)
         (size-except-elite (- size elite))
         rates i chromosomes selected-indexes rates-log-stack
         chromosomes-log-stack)
    (while
        (or
         (not rates-log-stack)
         (pcase termination
           ((pred functionp)
            (funcall termination rates-log-stack generation))
           ((pred integerp)
            (< generation termination))
           (_ (error "Wrong type of argument"))))

      (setq chromosomes next-chromosomes)
      (when log (push chromosomes chromosomes-log-stack))
      (setq next-chromosomes nil)
      (setq generation (1+ generation))

      (setq rates (-map rater chromosomes))
      (push rates rates-log-stack)

      ;; Counter which has length of `next-chromosomes'.
      (setq i 0)

      (while (< i size-except-elite)
        (if (and (< 1 (- size-except-elite i))
                 (egalgo--rand-bool crossover))

            ;; Crossover
            (let (selected1 selected2)
              ;; Select 2 chromosomes which will be crossovered.
              (setq selected-indexes (egalgo--select-2 rates selector))
              (setq selected1 (cl-copy-list
                               (nth (car  selected-indexes) chromosomes)))
              (setq selected2 (cl-copy-list
                               (nth (cadr selected-indexes) chromosomes)))

              ;; Crossover chromosomes.
              (if (eq n-point-crossover t)
                  ;; uniformcrossover.
                  (dotimes (n (1- length))
                    (when (egalgo--rand-bool 0.5)
                      (egalgo--crossover (1+ n) selected1 selected2)))
                ;; `n-point-crossover' point crossover.
                (--dotimes n-point-crossover
                  (egalgo--crossover
                   (1+ (cl-random (1- length)))
                   selected1 selected2)))

              ;; Push the 2 crossovered chromosomes to next-chromosomes.
              (push selected1 next-chromosomes)
              (push selected2 next-chromosomes)
              (setq i (+ i 2)))

          ;; Push selected chromosome to the next-chromosomes.
          (push (cl-copy-list (nth (funcall selector rates) chromosomes))
                next-chromosomes)
          (setq i (1+ i))))

      ;; Mutation
      (let (new-ncl now)
        (dolist (c next-chromosomes)
          (dotimes (n length)
            (when (egalgo--rand-bool mutation)
              (setq now (nth n c))
              (while (eq now
                         (setq new-ncl (eval (aref chromosome-forms n)))))
              (setf (nth n c) new-ncl)))))

      ;; Elite
      (unless (eq elite 0)
        (let ((rate-chromosome-alist
               (cl-mapcar #'cons rates chromosomes)))
          (setq rate-chromosome-alist
                (sort rate-chromosome-alist
                      (lambda (arg1 arg2)
                        (> (car arg1) (car arg2)))))
          (--dotimes elite
            (push (cdar rate-chromosome-alist)
                  next-chromosomes)
            (!cdr rate-chromosome-alist))))

      ;; Message
      (message "generation: %d / Max rate: %f / Average rate: %f%s"
               generation (-max rates)
               (/ (-sum rates) size)
               (if show-rates
                   (concat "\n" (prin1-to-string rates))
                 "")))

    ;; Result
    (setq
     egalgo-latest
     (let ((max-rate (-max rates))
           indexes)
       (list :chromosomes chromosomes
             :rates rates
             :rates-log rates-log-stack
             :max-rate max-rate
             :generation generation
             :chromosomes-log chromosomes-log-stack
             :max-chromosomes-indexes
             (dotimes (n size)
               (when (= (nth n rates) max-rate)
                 (push n indexes)))
             :max-chromosomes
             (--map
              (nth it chromosomes)
              indexes))))))

(provide 'egalgo)
;;; egalgo.el ends here
