;;; zone-sl.el --- Zone out with steam locomotives.

;; Filename: zone-sl.el
;; Description: Zone out with steam locomotives
;; Author: KAWABATA, Taichi <kawabata.taichi_at_gmail.com>
;; Created: 2016-01-19
;; Version: 1.160201
;; Package-Version: 20160201.1210
;; Package-Commit: 737b21b4b35c28a487ad8a31598e745bc183b209
;; Package-Requires: ((emacs "24.3"))
;; Keywords: games
;; URL: https://github.com/kawabata/zone-sl

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

;; Zone out with steam locomotives.
;; This code is based on, and inspired by, https://github.com/mtoyoda/sl
;; and its patches.
;;
;; It can be directly invoked by `M-x zone-sl'.
;;
;; Or, it can be added to zone programs by using
;; `zone-select-add-program' of `zone-select' package.

;;; Code:

(require 'cl-lib)
(require 'zone)

(defgroup zone-sl nil
  "Zone out with steam locomotives."
  :group 'games)

(defcustom zone-sl-wait 0.1 "." :group 'zone-sl)

(defcustom zone-sl-trains '(zone-sl-d51-l1    zone-sl-c51-l1    zone-sl-logo-l1
                            zone-sl-d51-l1p2  zone-sl-c51-l1p2  zone-sl-logo-l1p2
                            zone-sl-d51-l3p10 zone-sl-c51-l3p10 zone-sl-logo-l3p10
                            zone-sl-d51-p1l1  zone-sl-c51-p1l1)
  "SL Specs." :group 'zone-sl)

(defcustom zone-sl-directions '((-1 0) (1 0) (-1 -0.2) (1 -0.2)
                                (-3 0) (3 0) (-3 -0.6))
  "SL directions." :group 'zone-sl)

;;; define smokes

(defun zone-sl-smoke (k) "K."
  (elt
   '(("                      (@@) (  ) (@)  ( )  @@    ()    @     O     @     O      @"
      "                 (   )                                                          "
      "             (@@@@)                                                             "
      "          (    )                                                                "
      "                                                                                "
      "        (@@@)                                                                   ")
     ("                      (  ) (@@) ( )  (@)  ()    @@    O     @     O     @      O"
      "                 (@@@)                                                          "
      "             (    )                                                             "
      "          (@@@@)                                                                "
      "                                                                                "
      "        (   )                                                                   "))
   (% (/ k 3) 2)))

(defun zone-sl-smoke-2 (k) "K."
  (elt
   '(("                      (@@) (  )                                                 "
      "                 (   )          (@)  ( )                                        "
      "             (@@@@)                       @@    ()                              "
      "          (    )                                      @     O                   "
      "                                                                  @     O       "
      "        (@@@)                                                                  @")
     ("                      (  ) (@@)                                                 "
      "                 (@@@)          ( )  (@)                                        "
      "             (    )                       ()    @@                              "
      "          (@@@@)                                      O     @                   "
      "                                                                  O     @       "
      "        (   )                                                                  O"))
   (% (/ k 3) 2)))

(defun zone-sl-smoke-logo (k) "K."
  (elt
   '(("                   (@@) (  ) (@)  ( )  @@    ()    @     O     @     O      @"
      "               (  )                                                          "
      "           (@@@)                                                             "
      "        (   )                                                                "
      "                                                                             "
      "      (@@)                                                                   ")
     ("                   (  ) (@@) ( )  (@)  ()    @@    O     @     O     @      O"
      "               (@@)                                                          "
      "           (   )                                                             "
      "        (@@@)                                                                "
      "                                                                             "
      "      (  )                                                                   "))
   (% (/ k 3) 2)))

(defun zone-sl-smoke-logo-2 (k) "K."
  (elt
   '(("                 (@@) (  )                                                 "
      "             (  )          (@)  ( )                                        "
      "         (@@@)                       @@    ()                              "
      "      (   )                                      @     O                   "
      "                                                             @     O       "
      "    (@@)                                                                  @")
     ("                 (  ) (@@)                                                 "
      "             (@@)          ( )  (@)                                        "
      "         (   )                       ()    @@                              "
      "      (@@@)                                      O     @                   "
      "                                                             O     @       "
      "    (  )                                                                  O"))
   (% (/ k 3) 2)))

;;; define cars

(defun zone-sl-d51 (k) "K."
  `("      ====        ________                ___________ "
    "  _D _|  |_______/        \\__I_I_____===__|_________| "
    "   |(_)---  |   H\\________/ |   |        =|___ ___|   "
    "   /     |  |   H  |  |     |   |         ||_| |_||   "
    "  |      |  |   H  |__--------------------| [___] |   "
    "  | ________|___H__/__|_____/[][]~\\_______|       |   "
    "  |/ |   |-----------I_____I [][] []  D   |=======|__ "
    ,@
    (elt
     '(("__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
        " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
        "  \\_/      \\O=====O=====O=====O_/      \\_/            ")
       ("__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
        " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
        "  \\_/      \\_O=====O=====O=====O/      \\_/            ")
       ("__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
        " |/-=|___|=   O=====O=====O=====O|_____/~\\___/        "
        "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            ")
       ("__/ =| o |=-~O=====O=====O=====O\\ ____Y___________|__ "
        " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
        "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            ")
       ("__/ =| o |=-O=====O=====O=====O \\ ____Y___________|__ "
        " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
        "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            ")
       ("__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
        " |/-=|___|=O=====O=====O=====O   |_____/~\\___/        "
        "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            "))
     (% k 6))))

(defun zone-sl-c51 (k) "K."
  `("        ___                                            "
    "       _|_|_  _     __       __             ___________"
    "    D__/   \\_(_)___|  |__H__|  |_____I_Ii_()|_________|"
    "     | `---'   |:: `--'  H  `--'         |  |___ ___|  "
    "    +|~~~~~~~~++::~~~~~~~H~~+=====+~~~~~~|~~||_| |_||  "
    "    ||        | ::       H  +=====+      |  |::  ...|  "
    "|    | _______|_::-----------------[][]-----|       |  "
    ,@
    (elt
     '(("| /~~ ||   |-----/~~~~\\  /[I_____I][][] --|||_______|__"
        "------'|oOo|==[]=-     ||      ||      |  ||=======_|__"
        "/~\\____|___|/~\\_|   O=======O=======O  |__|+-/~\\_|     "
        "\\_/         \\_/  \\____/  \\____/  \\____/      \\_/       ")
       ("| /~~ ||   |-----/~~~~\\  /[I_____I][][] --|||_______|__"
        "------'|oOo|===[]=-    ||      ||      |  ||=======_|__"
        "/~\\____|___|/~\\_|    O=======O=======O |__|+-/~\\_|     "
        "\\_/         \\_/  \\____/  \\____/  \\____/      \\_/       ")
       ("| /~~ ||   |-----/~~~~\\  /[I_____I][][] --|||_______|__"
        "------'|oOo|===[]=- O=======O=======O  |  ||=======_|__"
        "/~\\____|___|/~\\_|      ||      ||      |__|+-/~\\_|     "
        "\\_/         \\_/  \\____/  \\____/  \\____/      \\_/       ")
       ("| /~~ ||   |-----/~~~~\\  /[I_____I][][] --|||_______|__"
        "------'|oOo|==[]=- O=======O=======O   |  ||=======_|__"
        "/~\\____|___|/~\\_|      ||      ||      |__|+-/~\\_|     "
        "\\_/         \\_/  \\____/  \\____/  \\____/      \\_/       ")
       ("| /~~ ||   |-----/~~~~\\  /[I_____I][][] --|||_______|__"
        "------'|oOo|=[]=- O=======O=======O    |  ||=======_|__"
        "/~\\____|___|/~\\_|      ||      ||      |__|+-/~\\_|     "
        "\\_/         \\_/  \\____/  \\____/  \\____/      \\_/       ")
       ("| /~~ ||   |-----/~~~~\\  /[I_____I][][] --|||_______|__"
        "------'|oOo|=[]=-      ||      ||      |  ||=======_|__"
        "/~\\____|___|/~\\_|  O=======O=======O   |__|+-/~\\_|     "
        "\\_/         \\_/  \\____/  \\____/  \\____/      \\_/       "))
     (% k 6))))


(defvar zone-sl-tender
  '("    _________________         "
    "   _|                \\_____A  "
    " =|                        |  "
    " -|                        |  "
    "__|________________________|_ "
    "|__________________________|_ "
    "   |_D__D__D_|  |_D__D__D_|   "
    "    \\_/   \\_/    \\_/   \\_/    "))

(defvar zone-sl-passenger
  '("          _____  _____  _____  _____  _____  _____  _____  _____  _____  _____          "
    " _________|___|__|___|__|___|__|___|__|___|__|___|__|___|__|___|__|___|__|___|_________ "
    "  | ____  _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  ____ |  "
    "  | |  |  |   |  |   |  |   |  |   |  |   |  |   |  |   |  |   |  |   |  |   |  |  | |  "
    "  | |  |  |___|  |___|  |___|  |___|  |___|  |___|  |___|  |___|  |___|  |___|  |  | |  "
    "  | |  |                                                                        |  | |  "
    "  | |  |                                   @@                                   |  | |  "
    "__|_|__|________________________________________________________________________|__|_|__"
    "\\==|_/_\\____/_\\_|  |______|Z          +--|_________________|------+    |_/_\\____/_\\_|==/"
    "     \\_/    \\_/                                       +++~~              \\_/    \\_/     "
    ))

(defvar zone-sl-last-passenger
  '("          _____  _____  _____  _____  _____  _____  _____  _____  _____  _____           "
    " _________|___|__|___|__|___|__|___|__|___|__|___|__|___|__|___|__|___|__|___|________   "
    "  | ____  _____  _____  _____  _____  _____  _____  _____  _____  _____  ____   _____|   "
    "  | |  |  |   |  |   |  |   |  |   |  |   |  |   |  |   |  |   |  |   |  |  |   |   |    "
    "  | |  |  |___|  |___|  |___|  |___|  |___|  |___|  |___|  |___|  |___|  |  |   |   |    "
    "  | |  |                                                                 |  |   |___|    "
    "  | |  |                                   @@                            |  |   |_|_|    "
    "__|_|__|_________________________________________________________________|__|___|_|_|___ "
    "\\==|_/_\\____/_\\_|  |______|XX                    +-|_______|------+    |_/_\\____/_\\_|==/ "
    "     \\_/    \\_/                                                          \\_/    \\_/      "
    ))

(defun zone-sl-logo (k) "K."
  `("     ++      +------  "
    "     ||      |+-+ |   "
    "   /---------|| | |   "
    "  + ========  +-+ |   "
    ,@
    (elt
     '((" _|--O========O~\\-+   "
        "//// \\_/      \\_/     ")
       (" _|--/~\\------/~\\-+   "
        "//// O========O_/     ")
       (" _|--/~\\------/~\\-+   "
        "//// \\O========O/     ")
       (" _|--/~\\------/~\\-+   "
        "//// \\_O========O     ")
       (" _|--/~O========O-+   "
        "//// \\_/      \\_/     ")
       (" _|--/O========O\\-+   "
        "//// \\_/      \\_/     "))
     (% k 6))))

(defvar zone-sl-logo-tender
  '("____                 "
    "|   \\@@@@@@@@@@@     "
    "|    \\@@@@@@@@@@@@@_ "
    "|                  | "
    "|__________________| "
    "   (O)       (O)     "))

(defvar zone-sl-logo-passenger
  '(" ____________________ "
    " |  ___ ___ ___ ___ | "
    " |  |_| |_| |_| |_| | "
    " |__________________| "
    "_|__________________|_"
    "    (O)        (O)    "))

(defvar zone-sl-locomotives '((zone-sl-d51  zone-sl-smoke zone-sl-smoke-2)
                              (zone-sl-c51  zone-sl-smoke zone-sl-smoke-2)
                              (zone-sl-logo zone-sl-smoke-logo zone-sl-smoke-logo-2))
  "List of locomotives and their corresponding smokes.")

;; define trains
(defvar zone-sl-d51-l1     '(zone-sl-d51 zone-sl-tender))
(defvar zone-sl-d51-l1p2   '(zone-sl-d51 zone-sl-tender zone-sl-passenger zone-sl-last-passenger))
(defvar zone-sl-d51-l3p10  '(((zone-sl-d51 zone-sl-tender) . 3) (zone-sl-passenger . 9) zone-sl-last-passenger))
(defvar zone-sl-d51-p1l1   '(zone-sl-passenger zone-sl-d51))
(defvar zone-sl-c51-l1     '(zone-sl-c51 zone-sl-tender))
(defvar zone-sl-c51-l1p2   '(zone-sl-c51 zone-sl-tender zone-sl-passenger zone-sl-last-passenger))
(defvar zone-sl-c51-l3p10  '(((zone-sl-c51 zone-sl-tender) . 3) (zone-sl-passenger . 9) zone-sl-last-passenger))
(defvar zone-sl-c51-p1l1   '(zone-sl-passenger zone-sl-c51))
(defvar zone-sl-logo-l1    '(zone-sl-logo zone-sl-logo-tender))
(defvar zone-sl-logo-l1p2  '(zone-sl-logo zone-sl-logo-tender (zone-sl-logo-passenger . 2)))
(defvar zone-sl-logo-l3p10 '(((zone-sl-logo zone-sl-logo-tender) . 3) (zone-sl-logo-passenger . 10)))

(defvar zone-sl-reverse-char-table
  (let ((table (make-hash-table)))
    (dolist (item '((?\\ . ?/) (?( . ?)) (?[ . ?])))
      (puthash (car item) (cdr item) table)
      (puthash (cdr item) (car item) table))
    table))

;;; Code

(defun zone-sl-train-expand (train)
  "Expand TRAIN symbol to actual train specification."
  (apply
   'append
   (mapcar (lambda (spec)
             (pcase spec
               (`(,(pred listp) . ,(pred integerp))
                (apply 'append (make-list (cdr spec) (car spec))))
               (`(,(pred symbolp) . ,(pred integerp))
                (make-list (cdr spec) (car spec)))
               ((pred symbolp) (list spec))
               (_ (error "Illegal train spec! %s" train))))
           (symbol-value train))))

(defun zone-sl-car-width (car)
  "Width of train CAR."
  (length
   (car (if (functionp car) (funcall car 0) (symbol-value car)))))

(defun zone-sl-car-height (car)
  "Height of train CAR."
  (length
   (if (functionp car) (funcall car 0) (symbol-value car))))

(defun zone-sl-train-height (train)
  "Height of TRAIN."
  (apply 'max (mapcar 'zone-sl-car-height train)))

(defun zone-sl-pad-height (car height)
  "Pad CAR for HEIGHT." ;; CAR cannot be a function!
  (let ((width (length (car car)))
        (h (length car)))
    (if (< h height)
        (nconc (make-list (- height h) (make-string width ? ))
               car)
      car)))

(defun zone-sl-smoke-layout (train)
  "Smoke layout of TRAIN."
  (let (result
        (width 0))
    (dolist (car train)
      (when (assq car zone-sl-locomotives)
        (setq result (nconc result (list width)))
        (setq width 0))
      (cl-incf width (zone-sl-car-width car)))
    (nconc result (list width))))

(defun zone-sl-smoke-strs (train dy step)
  "Find appropriate smoke strings for TRAIN going DY at STEP."
  (while (not (assq (car train) zone-sl-locomotives)) (setq train (cdr train)))
  (let* ((smokes (assq (car train) zone-sl-locomotives))
         (smoke (if (< dy 0) (elt smokes 2) (elt smokes 1))))
    (funcall smoke step)))

(defun zone-sl-ascii-art (train dy step)
  "Generate Ascii Art of TRAIN with direction DY at STEP."
  (let* ((smoke-strs   (zone-sl-smoke-strs train dy step))
         (smoke-layout (zone-sl-smoke-layout train))
         (smoke-width  (length (car smoke-strs)))
         (train-height (zone-sl-train-height train)))
    (append
     ;; smoke
     (mapcar
      (lambda (str)
        (concat
         (make-string (car smoke-layout) ? )
         (mapconcat
          (lambda (smoke-spec)
            (if (< smoke-spec smoke-width)
                (substring str 0 smoke-spec)
              (concat str (make-string (- smoke-spec smoke-width) ? ))))
          (cdr smoke-layout) "")))
      smoke-strs)
     ;; train
     (cl-loop
      for i from 0 below train-height
      collect
      (mapconcat
       (lambda (x) (elt x i))
       (mapcar (lambda (car)
                 (zone-sl-pad-height
                  (if (functionp car) (funcall car step) (symbol-value car))
                  train-height))
               train) "")))))

(defun zone-sl-reverse-ascii-art (str)
  "Reverse STR."
  (apply 'string
         (nreverse
          (mapcar (lambda (char)
                    (or (gethash char zone-sl-reverse-char-table) char))
                  (string-to-list str)))))

;;;###autoload
(defun zone-pgm-sl ()
  "Zone out with steam locomotive."
  (delete-other-windows)
  (let* ((truncate-lines t)
         (window-height (window-height))
         (window-width (window-width)))
    (cl-loop
     for j = (random (* (length zone-sl-trains) (length zone-sl-directions))) then (1+ j)
     for train = (zone-sl-train-expand
                  (elt zone-sl-trains (% j (length zone-sl-trains))))
     for direction = (elt zone-sl-directions (% j (length zone-sl-directions)))
     for dx = (elt direction 0)
     for dy = (elt direction 1)
     for ascii-art = (zone-sl-ascii-art train dy 0)
     for height = (length ascii-art)
     for width  = (length (car ascii-art))
     while (not (input-pending-p))
     do
     (zone-fill-out-screen (window-width) (window-height))
     (cl-loop
      for x-float = (if (< 0 dx) (- width) window-width) then (+ x-float dx)
      for y-float = (random (- window-height height 5)) then (+ y-float dy)
      for x = (floor x-float)
      for y = (floor y-float)
      for k = 0 then (1+ k)
      for ascii-art = (zone-sl-ascii-art train dy k)
      while (and (not (input-pending-p))
                 (<= 0 (+ x width)) (<= x window-width)
                 (<= 0 (+ y height)) (<= y window-height))
      for window-start = (goto-char (window-start))
      do
      (if (< 0 dx) (setq ascii-art (mapcar 'zone-sl-reverse-ascii-art ascii-art)))
      (let (rect-start rect-end)
        (if (< 0 y) (forward-line y))
        (if (< 0 x) (move-to-column x))
        (setq rect-start (point))
        (cl-loop
         for i from (if (< y 0) (- y) 0)
         below (if (< (+ y height) window-height) height (- window-height y))
         for str = (elt ascii-art i)
         do
         (let ((start (if (< x 0) (- x) 0))
               (end   (if (< window-width (+ x width)) (- window-width x))))
           (if (< 0 x) (move-to-column x t))
           (delete-region (point) (min (point-at-eol)
                                       (+ (point) (- start) width (or end 0))))
           (insert (substring str start end))
           (setq rect-end (point))
           (forward-line)))
        (set-window-start (selected-window) window-start)
        (set-window-hscroll (selected-window) 0)
        (sit-for zone-sl-wait)
        (if rect-end
            (clear-rectangle rect-start rect-end)))))))

;;;###autoload
(defun zone-sl ()
  "Zone out with steame locomotive."
  (interactive)
  (let ((zone-programs [zone-pgm-sl]))
    (zone)))

;;(defvar eshell-command-aliases-list)
;;(eval-after-load "em-alias"
;;  '(add-to-list 'eshell-command-aliases-list '("sl" "zone-sl")))

(provide 'zone-sl)
;;; zone-sl.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\\\?[ \t]+1.%02y%02m%02d\\\\?\n"
;; End:
