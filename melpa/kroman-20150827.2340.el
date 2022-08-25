;;; kroman.el --- Korean hangul romanization

;; Copyright (C) 2015  Kai Yu

;; Author: Zhang Kai Yu <yeannylam@gmail.com>
;; Keywords: korean, roman
;; Package-Version: 20150827.2340
;; Package-Commit: 431144a3cd629a2812a668a29ad85182368dc9b0

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

;;

;;; Code:

(defconst kroman--head-jamos
  '("g" "gg" "n" "d" "dd" "r" "m" "b" "bb" "s" "ss" "" "j" "jj" "c" "k" "t" "p"
    "h")
  "Korean head jamos.")

(defconst kroman--body-jamos
  '("a" "ae" "ya" "yae" "eo" "e" "yeo" "ye" "o" "wa" "wae" "oe" "yo" "u" "weo"
    "we" "wi" "yu" "eu" "eui" "i")
  "Korean body jamos.")

(defconst kroman--tail-jamos
  '("" "g" "gg" "gs" "n" "nj" "nh" "d" "r" "rk" "rm" "rb" "rs" "rt" "rp" "rh"
    "m" "b" "bs" "s" "ss" "ng" "j" "c" "k" "t" "p" "h")
  "Korean tail jamos.")

(defconst kroman--ga #xac00
  "Korean ga character.")

(defconst kroman--hih #xd7a3
  "Korean hih character.")

(defconst kroman--head-interval 588
  "Head interval.")

(defconst kroman--body-interval 28
  "Body interval.")

(defun kroman-hangul-p (char)
  (and (>= char kroman--ga)
       (<= char kroman--hih)))

(defun kroman-replace (char)
  (let (head head-left body tail)
    (setq head (/ (- char kroman--ga) kroman--head-interval))
    (setq head-left (% (- char kroman--ga) kroman--head-interval))
    (setq body (/ head-left kroman--body-interval))
    (setq tail (% head-left kroman--body-interval))
    (format "%s%s%s"
            (nth head kroman--head-jamos)
            (nth body kroman--body-jamos)
            (nth tail kroman--tail-jamos))))

(defun kroman-romanize (start end buffer)
  "Romanize region from START to END in BUFFER."
  (with-current-buffer buffer
    (let (this-char last-char-is-hangul replace)
      (while (< start end)
        (goto-char start)
        (setq this-char (char-after start))
        (if (kroman-hangul-p this-char)
            (progn
              (setq replace "")
              (if last-char-is-hangul
                  (setq replace "-"))
              (setq replace (concat replace (kroman-replace this-char)))
              (delete-char 1)
              (insert replace)
              (setq last-char-is-hangul t)
              (setq start (point))
              (setq end (+ (- end 1) (length replace))))
          (setq last-char-is-hangul nil)
          (setq start (1+ start)))))))

;;;###autoload
(defun kroman-romanize-region ()
  "Romanize current selected region."
  (interactive)
  (and (region-active-p)
       (kroman-romanize (region-beginning) (region-end) (current-buffer))))

;;;###autoload
(defun kroman-romanize-buffer ()
  "Romanize current buffer."
  (interactive)
  (kroman-romanize (point-min) (point-max) (current-buffer)))

;;;###autoload
(defun kroman-romanize-other-window ()
  "Romanize current buffer and show it other window."
  (interactive)
  (let ((cur-buffer (current-buffer))
        (new-buffer (get-buffer-create "*kroman-romanization*")))
    (copy-to-buffer new-buffer (point-min) (point-max))
    (with-current-buffer new-buffer
      (kroman-romanize-buffer))
    (display-buffer new-buffer)))

(provide 'kroman)
;;; kroman.el ends here
