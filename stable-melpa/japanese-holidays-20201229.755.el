;;; japanese-holidays.el --- Calendar functions for the Japanese calendar -*- lexical-binding: t; -*-

;; Filename: japanese-holidays.el
;; Description: Calendar functions for the Japanese calendar
;; Author: Takashi Hattori <hattori@sfc.keio.ac.jp>
;;	Hiroya Murata <lapis-lazuli@pop06.odn.ne.jp>
;; Created: 1999-04-20
;; Version: 1.190317
;; Package-Version: 20201229.755
;; Package-Commit: 324b6bf2f55ec050bef49e001caedaabaf4fa35d
;; Keywords: calendar
;; URL: https://github.com/emacs-jp/japanese-holidays
;; Package-Requires: ((emacs "24.1") (cl-lib "0.3"))

;; Copyright (C) 1999 Takashi Hattori <hattori@sfc.keio.ac.jp>
;; Copyright (C) 2005 Hiroya Murata <lapis-lazuli@pop06.odn.ne.jp>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This utility defines Japanese holiday for calendar function.
;; This also enables to display weekends or any weekday with
;; preferred face.
;;
;; Following is an example of using this utility.

;; (eval-after-load "calendar"
;;   '(progn
;;      (require 'japanese-holidays)
;;      (setq calendar-holidays ; 他の国の祝日も表示させたい場合は適当に調整
;;            (append japanese-holidays holiday-local-holidays holiday-other-holidays))
;;      (setq calendar-mark-holidays-flag t) ; 祝日をカレンダーに表示
;;      ;; 土曜日・日曜日を祝日として表示する場合、以下の設定を追加します。
;;      ;; 変数はデフォルトで設定済み
;;      (setq japanese-holiday-weekend '(0 6)     ; 土日を祝日として表示
;;            japanese-holiday-weekend-marker     ; 土曜日を水色で表示
;;            '(holiday nil nil nil nil nil japanese-holiday-saturday))
;;      (add-hook 'calendar-today-visible-hook 'japanese-holiday-mark-weekend)
;;      (add-hook 'calendar-today-invisible-hook 'japanese-holiday-mark-weekend)
;;      ;; “きょう”をマークするには以下の設定を追加します。
;;      (add-hook 'calendar-today-visible-hook 'calendar-mark-today)))

;;; Change Log:

;; Original program created by T. Hattori 1999/4/20
;;      http://www.meadowy.org/meadow/netinstall/export/799/branches/3.00/pkginfo/japanese-holidays/japanese-holidays.el
;;
;; 2013/9/1
;;	* 関数・変数名を "japanese-holiday-" prefix に統一
;;      * obosolete化された変数名を最新の名前に更新
;;      * 文字コードを UTF-8 に変更
;;      * 土曜日・日曜日で異なるfaceを設定できるように変更
;;        (idea from http://blog.livedoor.jp/tek_nishi/archives/3027665.html)
;;      * calendar-weekend-marker を japanese-holiday-weekend-marker に変更
;;      * ドキュメントの調整
;;      (Modified by kawabata.taichi_at_gmail.com)

;;; Code:

(require 'cl-lib)
(require 'holidays)
(defvar displayed-month)
(defvar displayed-year)

(autoload 'solar-equinoxes/solstices "solar")

(defgroup japanese-holidays nil
  "Japanese Holidays"
  :prefix "japanese-holiday-"
  :group 'calendar)

(defcustom japanese-holidays
  '(;; 明治6年太政官布告第344号
    (japanese-holiday-range
     (holiday-fixed 1 3 "元始祭") '(10 14 1873) '(7 20 1948))
    (japanese-holiday-range
     (holiday-fixed 1 5 "新年宴会") '(10 14 1873) '(7 20 1948))
    (japanese-holiday-range
     (holiday-fixed 1 30 "孝明天皇祭") '(10 14 1873) '(9 3 1912))
    (japanese-holiday-range
     (holiday-fixed 2 11 "紀元節") '(10 14 1873) '(7 20 1948))
    (japanese-holiday-range
     (holiday-fixed 4 3 "神武天皇祭") '(10 14 1873) '(7 20 1948))
    (japanese-holiday-range
     (holiday-fixed 9 17 "神嘗祭") '(10 14 1873) '(7 5 1879))
    (japanese-holiday-range
     (holiday-fixed 11 3 "天長節") '(10 14 1873) '(9 3 1912))
    (japanese-holiday-range
     (holiday-fixed 11 23 "新嘗祭") '(10 14 1873) '(7 20 1948))
    ;; 明治11年太政官布告23号
    (let* ((equinox (solar-equinoxes/solstices 0 displayed-year))
	   (m (calendar-extract-month equinox))
	   (d (truncate (calendar-extract-day equinox))))
      (japanese-holiday-range
       (holiday-fixed m d "春季皇霊祭") '(6 5 1878) '(7 20 1948)))
    (let* ((equinox (solar-equinoxes/solstices 2 displayed-year))
	   (m (calendar-extract-month equinox))
	   (d (truncate (calendar-extract-day equinox))))
      (japanese-holiday-range
       (holiday-fixed m d "秋季皇霊祭") '(6 5 1878) '(7 20 1948)))
    ;; 明治12年太政官布告27号
    (japanese-holiday-range
     (holiday-fixed 10 17 "神嘗祭") '(7 5 1879) '(7 20 1948))
    ;; 休日ニ関スル件 (大正元年勅令第19号)
    (japanese-holiday-range
     (holiday-fixed 7 30 "明治天皇祭") '(9 3 1912) '(3 3 1927))
    (japanese-holiday-range
     (holiday-fixed 8 31 "天長節") '(9 3 1912) '(3 3 1927))
    ;; 大正2年勅令259号
    (japanese-holiday-range
     (holiday-fixed 10 31 "天長節祝日") '(10 31 1913) '(3 3 1927))
    ;; 休日ニ関スル件改正ノ件 (昭和2年勅令第25号)
    (japanese-holiday-range
     (holiday-fixed 4 29 "天長節") '(3 3 1927) '(7 20 1948))
    (japanese-holiday-range
     (holiday-fixed 11 3 "明治節") '(3 3 1927) '(7 20 1948))
    (japanese-holiday-range
     (holiday-fixed 12 25 "大正天皇祭") '(3 3 1927) '(7 20 1948))
    ;; 国民の祝日に関する法律の一部を改正する法律 (昭和60年法律第103号)
    (japanese-holiday-national
     ;; 国民の祝日に関する法律の一部を改正する法律 (昭和48年法律第10号)
     (japanese-holiday-substitute
      (nconc
       ;; 国民の祝日に関する法律 (昭和23年法律第178号)
       (japanese-holiday-range
	(holiday-fixed 1 1 "元日") '(7 20 1948))
       (japanese-holiday-range
	(holiday-fixed 1 15 "成人の日") '(7 20 1947) '(1 1 2000))
       (let* ((equinox (solar-equinoxes/solstices 0 displayed-year))
	      (m (calendar-extract-month equinox))
	      (d (truncate (calendar-extract-day equinox))))
	 ;; 春分の日は、厳密には前年2月の官報により決定される
	 (japanese-holiday-range
	  (holiday-fixed m d "春分の日") '(7 20 1948)))
       (japanese-holiday-range
	(holiday-fixed 4 29 "天皇誕生日") '(7 20 1948) '(2 17 1989))
       (japanese-holiday-range
	(holiday-fixed 5 3 "憲法記念日") '(7 20 1948))
       (japanese-holiday-range
	(holiday-fixed 5 5 "こどもの日") '(7 20 1948))
       (let* ((equinox (solar-equinoxes/solstices 2 displayed-year))
	      (m (calendar-extract-month equinox))
	      (d (truncate (calendar-extract-day equinox))))
	 ;; 秋分の日は、厳密には前年2月の官報により決定される
	 (japanese-holiday-range
	  (holiday-fixed m d "秋分の日") '(7 20 1948)))
       (japanese-holiday-range
	(holiday-fixed 11 3 "文化の日") '(7 20 1948))
       (japanese-holiday-range
	(holiday-fixed 11 23 "勤労感謝の日") '(7 20 1948))
       ;; 国民の祝日に関する法律の一部を改正する法律 (昭和41年法律第86号)
       ;;   建国記念の日となる日を定める政令 (昭和41年政令第376号)
       (japanese-holiday-range
	(holiday-fixed 2 11 "建国記念の日") '(6 25 1966))
       (japanese-holiday-range
	(holiday-fixed 9 15 "敬老の日") '(6 25 1966) '(1 1 2003))
       (japanese-holiday-range
	(holiday-fixed 10 10 "体育の日") '(6 25 1966) '(1 1 2000))
       ;; 国民の祝日に関する法律の一部を改正する法律 (平成元年法律第5号)
       (japanese-holiday-range
	(holiday-fixed 4 29 "みどりの日") '(2 17 1989) '(1 1 2007))
       (japanese-holiday-range
	(holiday-fixed 12 23 "天皇誕生日") '(2 17 1989) '(5 1 2019))
       ;; 国民の祝日に関する法律の一部を改正する法律 (平成7年法律第22号)
       (japanese-holiday-range
	(holiday-fixed 7 20 "海の日") '(1 1 1996) '(1 1 2003))
       ;; 国民の祝日に関する法律の一部を改正する法律 (平成10年法律第141号)
       (japanese-holiday-range
	(holiday-float 1 1 2 "成人の日") '(1 1 2000))
       (japanese-holiday-range
	(holiday-float 10 1 2 "体育の日") '(1 1 2000) '(1 1 2020))
       ;; 国民の祝日に関する法律及び老人福祉法の一部を改正する法律 (平成13年法律第59号)
       (japanese-holiday-range
	(holiday-float 7 1 3 "海の日") '(1 1 2003) '(1 1 2020))
       (japanese-holiday-range
	(holiday-float 7 1 3 "海の日") '(1 1 2022))
       (japanese-holiday-range
	(holiday-float 9 1 3 "敬老の日") '(1 1 2003))
       ;; 国民の祝日に関する法律の一部を改正する法律 (平成17年法律第43号)
       (japanese-holiday-range
	(holiday-fixed 4 29 "昭和の日") '(1 1 2007))
       (japanese-holiday-range
	(holiday-fixed 5 4 "みどりの日") '(1 1 2007))
       ;; 国民の祝日に関する法律の一部を改正する法律 (平成26年法律第43号)
       (japanese-holiday-range
	(holiday-fixed 8 11 "山の日") '(1 1 2016) '(1 1 2020))
       (japanese-holiday-range
        (holiday-fixed 8 11 "山の日") '(1 1 2022))
       ;; 天皇の退位等に関する皇室典範特例法 (平成29年法律第63号)
       (japanese-holiday-range
	(holiday-fixed 2 23 "天皇誕生日") '(5 1 2019))
       ;; 天皇の即位の日及び即位礼正殿の儀の行われる日を休日とする法律 (平成30年法律第99号)
       (japanese-holiday-range
	(holiday-fixed 5 1 "即位の日") '(12 14 2018) '(1 1 2020))
       (japanese-holiday-range
	(holiday-fixed 10 22 "即位礼正殿の儀") '(12 14 2018) '(1 1 2020))
       ;; 平成三十二年東京オリンピック競技大会・東京パラリンピック競技大会特別措置法及び 平成三十一年ラグビーワールドカップ大会特別措置法の一部を改正する法律（平成30年法律第55号）
       (japanese-holiday-range
	(holiday-fixed 7 23 "海の日") '(1 1 2020) '(1 1 2021))
       (japanese-holiday-range
	(holiday-fixed 7 24 "スポーツの日") '(1 1 2020) '(1 1 2021))
       (japanese-holiday-range
	(holiday-fixed 8 10 "山の日") '(1 1 2020) '(1 1 2021))
       ;; 国民の祝日に関する法律の一部を改正する法律（平成30年法律第57号）
       (japanese-holiday-range
        (holiday-float 10 1 2 "スポーツの日") '(1 1 2022))
       ;; 東京オリンピック競技大会・東京パラリンピック競技大会特別措置法等の一部を改正する法律(令和2年法律第68号)
       (japanese-holiday-range
	(holiday-fixed 7 22 "海の日") '(1 1 2021) '(1 1 2022))
       (japanese-holiday-range
	(holiday-fixed 7 23 "スポーツの日") '(1 1 2021) '(1 1 2022))
       (japanese-holiday-range
	(holiday-fixed 8 8 "山の日") '(1 1 2021) '(1 1 2022)))))
    (holiday-filter-visible-calendar
     '(;; 皇太子明仁親王の結婚の儀の行われる日を休日とする法律 (昭和34年法律第16号)
       ((4 10 1959) "明仁親王の結婚の儀")
       ;; 昭和天皇の大喪の礼の行われる日を休日とする法律 (平成元年法律第4号)
       ((2 24 1989) "昭和天皇の大喪の礼")
       ;; 即位礼正殿の儀の行われる日を休日とする法律 (平成2年法律第24号)
       ((11 12 1990) "即位礼正殿の儀")
       ;; 皇太子徳仁親王の結婚の儀の行われる日を休日とする法律 (平成5年法律第32号)
       ((6 9 1993) "徳仁親王の結婚の儀"))))
  "*Japanese holidays.
See the documentation for `calendar-holidays' for details."
  :type 'sexp
  :group 'japanese-holidays)

(defcustom japanese-holiday-substitute-name "振替休日"
  "*Name of Japanese substitute holiday."
  :type 'string
  :group 'japanese-holidays)

(defcustom japanese-holiday-national-name "国民の休日"
  "*Name of Japanese national holiday."
  :type 'string
  :group 'japanese-holidays)

(defcustom japanese-holiday-weekend '(0 6)
  "*List of days of week to be marked as weekend.
e.g. 0 is Sunday and 6 is Saturday."
  :type '(repeat integer)
  :options '((0) (0 6))
  :group 'japanese-holidays)

(defcustom japanese-holiday-weekend-marker
  '(holiday nil nil nil nil nil japanese-holiday-saturday)
  "*Faces to mark Weekends.  `holiday' and `diary' is possible marker.
It can be face face, or list of faces for corresponding weekdays."
 :type '(choice face
                (repeat (choice (const nil) face)))
 :options '(holiday diary)
 :group 'japanese-holidays)

(defface japanese-holiday-saturday
  '((((class color) (background light))
     :background "sky blue")
    (((class color) (background dark))
     :background "blue")
    (t
     :inverse-video t))
  "Face to display in Japanese Saturday."
  :group 'calendar-faces)

(eval-and-compile
  (defun japanese-holiday-make-sortable (date)
    (+ (* (nth 2 date) 10000) (* (nth 0 date) 100) (nth 1 date))))

(defun japanese-holiday-range (holidays &optional from to)
  (let ((from (and from (japanese-holiday-make-sortable from)))
	(to   (and to   (japanese-holiday-make-sortable to))))
    (delq nil
	  (mapcar
	   (lambda (holiday)
	     (let ((date (japanese-holiday-make-sortable (car holiday))))
	       (when (and (or (null from) (<= from date))
			  (or (null to) (< date to)))
		 holiday)))
	   holidays))))

(defun japanese-holiday-find-date (date holidays)
  (let ((sortable-date (japanese-holiday-make-sortable date))
	matches)
    (dolist (holiday holidays)
      (when (= sortable-date (japanese-holiday-make-sortable (car holiday)))
	(setq matches (cons holiday matches))))
    matches))

(defun japanese-holiday-add-days (date days)
  (calendar-gregorian-from-absolute
   (+ (calendar-absolute-from-gregorian date) days)))

(defun japanese-holiday-subtract-date (from other)
  (- (calendar-absolute-from-gregorian from)
     (calendar-absolute-from-gregorian other)))

(defun japanese-holiday-substitute (holidays)
  (let (substitutes substitute)
    (dolist (holiday holidays)
      (let ((date (car holiday)))
	(when (and (>= (japanese-holiday-make-sortable date)
		       (eval-when-compile
			 (japanese-holiday-make-sortable '(4 12 1973))))
		   (= (calendar-day-of-week date) 0))
	  (setq substitutes
		(cons
		 (list (japanese-holiday-add-days date 1)
		       (format "%s (%s)"
			       japanese-holiday-substitute-name
			       (cadr holiday)))
		 substitutes)))))
    (when (setq substitutes
		(holiday-filter-visible-calendar substitutes))
      (setq substitutes (sort substitutes
			      (lambda (l r)
				(< (japanese-holiday-make-sortable (car l))
				   (japanese-holiday-make-sortable (car r))))))
      (while (setq substitute (car substitutes))
	(setq substitutes (cdr substitutes))
	(if (japanese-holiday-find-date (car substitute) holidays)
	    (let* ((date (car substitute))
		   (sortable-date (japanese-holiday-make-sortable date)))
	      (when (>= sortable-date
			(eval-when-compile
			  (japanese-holiday-make-sortable '(1 1 2007))))
		(setq substitutes
		      (cons
		       (list (japanese-holiday-add-days date 1) (cadr substitute))
		       substitutes))))
	  (setq holidays (cons substitute holidays)))))
    (holiday-filter-visible-calendar holidays)))

(defun japanese-holiday-national (holidays)
  (when holidays
    (setq holidays (sort holidays
			 (lambda (l r)
			   (< (japanese-holiday-make-sortable (car l))
			      (japanese-holiday-make-sortable (car r))))))
    (let* ((rest holidays)
	   (curr (pop rest))
	   prev nationals)
      (while (setq prev curr
		   curr (pop rest))
	(when (= (japanese-holiday-subtract-date (car curr) (car prev)) 2)
	  (let* ((date (japanese-holiday-add-days (car prev) 1))
		 (sortable-date (japanese-holiday-make-sortable date)))
	    (when (cond
		   ((>= sortable-date
			(eval-when-compile
			  (japanese-holiday-make-sortable '(1 1 2007))))
		    (catch 'found
		      (dolist (holiday (japanese-holiday-find-date date holidays))
			(unless (string-match
				 (regexp-quote japanese-holiday-substitute-name)
				 (cadr holiday))
			  (throw 'found nil)))
		      t))
		   ((>= sortable-date
			(eval-when-compile
			  (japanese-holiday-make-sortable '(12 27 1985))))
		    (not (or (= (calendar-day-of-week date) 0)
			     (japanese-holiday-find-date date holidays)))))
	      (setq nationals (cons (list date japanese-holiday-national-name)
				    nationals))))))
      (setq holidays (nconc holidays
			    (holiday-filter-visible-calendar nationals)))))
  holidays)

(defun japanese-holiday-mark-weekend ()
  (let ((m displayed-month)
	(y displayed-year))
    (calendar-increment-month m y -1)
    (cl-loop
     repeat 3 do
     (let ((sunday (- 1 (calendar-day-of-week (list m 1 y))))
           (last (calendar-last-day-of-month m y)))
       (while (<= sunday last)
         (mapc (lambda (x)
                 (let ((d (+ sunday x)))
                   (and (<= 1 d)
                        (<= d last)
                        (calendar-mark-visible-date
                         (list m d y)
                         (if (listp japanese-holiday-weekend-marker)
                             (nth x japanese-holiday-weekend-marker)
                           japanese-holiday-weekend-marker)))))
               japanese-holiday-weekend)
         (setq sunday (+ sunday 7))))
     (calendar-increment-month m y 1))))

(provide 'japanese-holidays)
;;; japanese-holidays.el ends here
