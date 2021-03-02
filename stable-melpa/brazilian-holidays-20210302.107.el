;;; brazilian-holidays.el --- Brazilian holidays                   -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jaguaraquem A. Reinaldo

;; Author: Jaguaraquem A. Reinaldo <jaguar.adler@gmail.com>
;; Version: 2.1.2
;; Package-Version: 20210302.107
;; Package-Commit: 68811fd5f3e9d9c0572995c3ca46ead2c35eb421
;; URL: https://github.com/jadler/brazilian-holidays
;; Keywords: calendar holidays brazilian
;; Package-Requires: ((emacs "26"))

;; This file is not part of GNU Emacs.

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

;; Provides Brazilian holidays as well as for each State.
;; To enable holidays for the desired State, just set a non-nil value for the
;; State variable.
;;
;; E.g.:
;; (require 'brazilian-holidays)
;; (setq brazilian-holidays-rj-holidays t)
;;
;; Or with `use-package`:
;;
;; (use-package brazilian-holidays
;;  :custom
;;  (brazilian-holidays-rj-holidays t)
;;  (brazilian-holidays-sp-holidays t))

;;; Code:

(eval-when-compile
  (require 'calendar)
  (require 'holidays))

(defvar brazilian-holidays--general-holidays nil
  "National brazilian holidays.")
(setq brazilian-holidays--general-holidays
      '((holiday-fixed       1    1 "Confraternização Universal")
        (holiday-fixed       4   21 "Tiradentes")
        (holiday-fixed       5    1 "Dia do Trabalho")
        (holiday-fixed       9    7 "Dia da Pátria")
        (holiday-fixed      11    2 "Finados")
        (holiday-fixed      11   15 "Proclamação da República")))

(defvar brazilian-holidays--christian-holidays nil
  "Christian brazilian holidays.")
(setq brazilian-holidays--christian-holidays
      '((holiday-easter-etc      -2 "Paixão de Cristo")
        (holiday-easter-etc       0 "Páscoa")
        (holiday-fixed      10   12 "Nossa Senhora Aparecida")
        (holiday-fixed      12   25 "Natal")))

(defvar brazilian-holidays--other-holidays nil
  "Other holidays and commemorative brazilian dates.")
(setq brazilian-holidays--other-holidays
      '((holiday-fixed       1    6 "Dia de Reis")
        (holiday-fixed       1    9 "Dia do Fico")
        (holiday-easter-etc     -46 "Início da Quaresma")
        (holiday-fixed       3    8 "Dia Internacional da Mulher")
        (holiday-fixed       4    1 "Dia da Mentira")
        (holiday-fixed       4   19 "Dia do Índio")
        (holiday-easter-etc      -1 "Sábado de Aleluia")
        (holiday-fixed       4   22 "Descobrimento do Brasil")
        (holiday-float       5 0  2 "Dia das Mães")
        (holiday-easter-etc      49 "Pentecostes")
        (holiday-easter-etc      56 "Santíssima Trindade")
        (holiday-easter-etc      60 "Corpus Christi")
        (holiday-fixed       6   12 "Dia dos Namorados")
        (holiday-fixed       6   13 "Dia de Santo Antônio")
        (holiday-fixed       6   24 "Dia de São João")
        (holiday-fixed       6   29 "Dia de São Pedro")
        (holiday-float       7 0  2 "Dia dos Pais")
        (holiday-fixed       8   25 "Dia do Soldado")
        (holiday-fixed      10   12 "Dia das Crianças")
        (holiday-fixed      11   19 "Dia da Bandeira")))

(defvar brazilian-holidays--local-holidays nil
  "A list of regional holidays and commemorative dates for brazilian States.")

(defcustom brazilian-holidays-ac-holidays nil
  "Regional holidays and commemorative dates for Acre State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-ac-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-fixed        1    23 "Dia do Evangélico")
             (holiday-fixed        5    15 "Aniversário do Acre")
             (holiday-float        9     5 "Dia do Comércio")
             (holiday-fixed       11    17 "Assinatura do Tratado de Petrópolis")))))

(defcustom brazilian-holidays-al-holidays nil
  "Regional holidays and commemorative dates for Alagoas State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-al-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-fixed        6    24 "São João")
             (holiday-fixed        6    29 "São Pedro")
             (holiday-fixed        9    16 "Emancipação Política de Alagoas")
             (holiday-fixed       11    20 "Consciência Negra")))))

(defcustom brazilian-holidays-am-holidays nil
  "Regional holidays and commemorative dates for Amazonas State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-am-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-fixed        9     5 "Elevação do Amazonas à categoria de província")
             (holiday-fixed       11    20 "Consciência Negra")
             (holiday-fixed       12     8 "Dia de Nossa Senhora da Conceição")))))

(defcustom brazilian-holidays-ap-holidays nil
  "Regional holidays and commemorative dates for Amapá State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-ap-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-fixed        3    19 "Dia de São José")
             (holiday-fixed        7    25 "São Tiago")
             (holiday-fixed       10     5 "Criação do Estado do Amapá")
             (holiday-fixed       11    20 "Consciência Negra")))))

(defcustom brazilian-holidays-ba-holidays nil
  "Regional holidays and commemorative dates for Bahia State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-ba-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-fixed        7     2 "Independência da Bahia")))))

(defcustom brazilian-holidays-rj-holidays nil
  "Regional holidays and commemorative dates for Rio de Janeiro State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-rj-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-fixed        1    20 "São Sebastião")
             (holiday-easter-etc       -47 "Carnaval")
             (holiday-easter-etc       -46 "Quarta-feira de cinzas")
             (holiday-fixed        4    23 "São Jorge")
             (holiday-float       10 1   3 "Dia do Comércio")
             (holiday-fixed       11    20 "Consciência Negra")))))

(defcustom brazilian-holidays-sp-holidays nil
  "Regional holidays and commemorative dates for São Paulo State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-sp-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-fixed        7     9 "Dia da Revolução Constitucionalista")))))

(defcustom brazilian-holidays-mg-holidays nil
  "Regional holidays and commemorative dates for Minas Gerais State."
  :type 'boolean
  :group 'brazilian-holidays)

(if brazilian-holidays-mg-holidays
    (setq brazilian-holidays--local-holidays
          (append
           brazilian-holidays--local-holidays
           '((holiday-easter-etc       -47 "Carnaval")
             (holiday-fixed        4    21 "Data Magna de Minas Gerais")
             (holiday-fixed        8    15 "Dia da Assunção de Nossa Senhora")
             (holiday-fixed       12     8 "Dia da Imaculada Conceição")))))

;;;###autoload
(define-minor-mode brazilian-holidays-mode
  "Toggle brazilian holidays mode.
Interactively, with a prefix argument, enable
Visual Line mode if the prefix argument is positive,
and disable it otherwise.  If called from Lisp, toggle
the mode if ARG is `toggle', disable the mode if ARG is
a non-positive integer, and enable the mode otherwise
\(including if ARG is omitted or nil or a positive integer).

When brazilian holidays mode is enabled, it will hide
holidays from other countries."
  :init-value t
  :group 'brazilian-holidays
  :global t
  (if brazilian-holidays-mode
      (progn
        (setq holiday-bahai-holidays nil)
        (setq holiday-christian-holidays brazilian-holidays--christian-holidays)
        (setq holiday-general-holidays brazilian-holidays--general-holidays)
        (setq holiday-hebrew-holidays nil)
        (setq holiday-islamic-holidays nil)
        (setq holiday-local-holidays (delete-dups brazilian-holidays--local-holidays))
        (setq holiday-oriental-holidays nil)
        (setq holiday-other-holidays brazilian-holidays--other-holidays)
        (setq holiday-solar-holidays nil)
        (setq calendar-holidays
              (append holiday-bahai-holidays holiday-christian-holidays
                      holiday-general-holidays holiday-hebrew-holidays
                      holiday-islamic-holidays holiday-local-holidays
                      holiday-oriental-holidays holiday-other-holidays
                      holiday-solar-holidays)))
    (custom-reevaluate-setting 'holiday-bahai-holidays)
    (custom-reevaluate-setting 'holiday-christian-holidays)
    (custom-reevaluate-setting 'holiday-general-holidays)
    (custom-reevaluate-setting 'holiday-hebrew-holidays)
    (custom-reevaluate-setting 'holiday-islamic-holidays)
    (custom-reevaluate-setting 'holiday-local-holidays)
    (custom-reevaluate-setting 'holiday-oriental-holidays)
    (custom-reevaluate-setting 'holiday-other-holidays)
    (custom-reevaluate-setting 'holiday-solar-holidays)
    (custom-reevaluate-setting 'calendar-holidays)))

(provide 'brazilian-holidays)
;;; brazilian-holidays.el ends here
