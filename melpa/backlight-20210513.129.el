;;; backlight.el --- backlight brightness adjustment on GNU/Linux -*- lexical-binding: t -*-

;; Copyright (C) 2018 Michael Schuldt

;; Author: Michael Schuldt <mbschuldt@gmail.com>
;; Version: 1.4
;; Package-Version: 20210513.129
;; Package-Commit: b6826a60440d8bf440618e3cdafb40158de920e6
;; URL: https://github.com/mschuldt/backlight.el
;; Package-Requires: ((emacs "24.3"))
;; Keywords: hardware

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; A simple utility for setting backlight brightness on some
;; GNU/Linux systems using sysfs files.
;;
;; This works like most system provided backlight brightness
;; controls but allows for increased resolution when the
;; brightness percentage nears zero.
;;
;; On some systems a udev rule must be added, in /etc/udev/rules.d/backlight.rules add:
;;      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", GROUP="video", MODE="then"
;; then reload with:
;;     sudo udevadm control --reload-rules && udevadm trigger
;;
;; USAGE
;;
;;  M-x backlight
;;   Then use '<' or '>' to adjust backlight brightness, 'C-g' when done.
;;
;;  M-x backlight-set-raw
;;   prompts for a value to write directly to the device file.


;;; Code:

(defgroup backlight nil
  "Set backlight brightness."
  :group 'backlight)

(defcustom backlight-large-inc-amount 10
  "Adjustment percentage used when brightness is above `backlight-threshold'."
  :type 'number
  :group 'backlight)

(defcustom backlight-small-inc-amount 1
  "Adjustment percentage used when brightness is below `backlight-threshold'."
  :type 'number
  :group 'backlight)

(defcustom backlight-threshold 10
  "Percentage level for using small brightness increments."
  :type 'number
  :group 'backlight)

(defcustom backlight-sys-dir "/sys/class/backlight/"
  "Location of backlight device files."
  :type 'string
  :group 'backlight)

(defcustom backlight-pref-device nil
  "Preferred brightness device if multiple are available"
  :type 'string
  :group 'backlight)

(defvar backlight--device nil
  "Filename of the backlight device.")

(defvar backlight--max-brightness nil
  "Max brightness value as reported by the backlight device.")

(defvar backlight--current-brightness nil
  "Current backlight brightness level.")

(defvar backlight--initialized nil
  "Non-nil when backlight device is found variables initialized.")

(defun backlight--filepath (file)
  "Create full filepath to backlight device attribute FILE."
  (concat backlight-sys-dir backlight--device "/" file))

(defun backlight--set (file value)
  "Write VALUE to backlight device FILE."
  (with-temp-buffer
    (insert (format "%s" value))
    (condition-case err
        (write-region nil nil (backlight--filepath file) nil 'silent)
      (file-error (progn (if (equal (caddr err) "Permission denied")
                             (message "Permission denied. See README for adding required udev rule.")
                           (signal (car x) (cdr x))))))))

(defun backlight--get (file)
  "Read value from backlight device FILE."
  (with-temp-buffer
    (insert-file-contents-literally (backlight--filepath file))
    (string-to-number (buffer-string))))

(defun backlight--read-current-brightness ()
  "Read the current brightness."
  (setq backlight--current-brightness
        (backlight--get "actual_brightness")))

(defun backlight--init ()
  "Find the backlight device file and read initial values."
  (let ((devices (cddr (and (file-exists-p backlight-sys-dir)
                            (directory-files backlight-sys-dir)))))
    (if (null devices)
        (message "Error: Unable to find backlight device")
      (when (and (null backlight-pref-device)
		 (> (length devices) 1))
	(message (concat "Warning: Multiple backlight devices. Using the first, "
			 (car devices))))
      (when (and backlight-pref-device
		 (not (member backlight-pref-device devices)))
	(message (concat "Warning: Preferred backlight device not found, using "
			 (car devices))))
      (if (member backlight-pref-device devices)
	  (setq backlight--device backlight-pref-device)
	(setq backlight--device (car devices)))
      (setq backlight--max-brightness (backlight--get "max_brightness"))
      (backlight--read-current-brightness)
      (setq backlight--initialized t)))
  backlight--initialized)

(defun backlight--begin ()
  "Used to begin a backlight interactive command."
  ;; read brightness again as it may have been changed by another process
  (backlight--read-current-brightness)
  (unless backlight--initialized
    (unless (backlight--init)
      (error "Backlight initialization failed"))))

(defun backlight--current-percentage ()
  "Calculate the current brightness percentage."
  (* (/ backlight--current-brightness
        (* backlight--max-brightness 1.0))
     100))

(defun backlight--set-brightness (value)
  "Set and verify the backlight brightness to raw VALUE."
  (backlight--set "brightness" value)
  (setq backlight--current-brightness (backlight--get "actual_brightness")))

(defun backlight--from-percent (percent)
  "Convert a PERCENT to a brightness value the device accepts."
  (floor (* (/ (* percent 1.0) 100) backlight--max-brightness)))

(defun backlight--get-inc-amount ()
  "Return the amount by which to adjust the brightness."
  (if (< (floor (backlight--current-percentage)) 1)
      1 ;; single step
    (backlight--from-percent
     (if (<= (backlight--current-percentage) backlight-threshold)
            backlight-small-inc-amount
          backlight-large-inc-amount))))

(defun backlight--adjust (amount)
  "Adjust the backlight brightness by signed integer AMOUNT."
  (backlight--begin)
  (let* (;; detect the case in which we step from one brightness
         ;; region down into another region that has increased
         ;; resolution, such a step must not be done with the
         ;; larger step size from the previous region as the
         ;; inverse brightness increment may take several steps
         ;; which can be confusing.
         (threshold (backlight--from-percent backlight-threshold))
         (threshold2 (backlight--from-percent 1))
         (was-above-theshold (>= backlight--current-brightness threshold))
         (was-above-theshold2 (>= backlight--current-brightness threshold2))
         (new (+ backlight--current-brightness amount)))
    (cond ((and was-above-theshold
                (< (- new threshold) 1))
           (setq new (1- threshold)))
          ((and was-above-theshold2
                (< (- new threshold2) 1))
           (setq new (1- threshold2))))
    (setq new (min new backlight--max-brightness))
    (setq new (max new 0))
    (backlight--set-brightness new)))

(defun backlight--minibuf-update (&optional decrement)
  "Do a brightness increment, or DECREMENT, and update minibuffer."
  (if decrement
      (backlight-dec (backlight--get-inc-amount))
    (backlight-inc (backlight--get-inc-amount)))
  (move-beginning-of-line 1)
  (kill-line)
  (insert (backlight--prompt)))

(defvar backlight--minibuffer-keymap
  (let ((map (copy-keymap minibuffer-local-map))
        (inc-keys '("right" ">" "." "+"))
        (dec-keys '("left" "<" "," "-")))
    (dolist (key inc-keys)
      (define-key map (kbd key)
        (lambda ()
          (interactive)
          (backlight--minibuf-update))))
    (dolist (key dec-keys)
      (define-key map (kbd key)
        (lambda ()
          (interactive)
          (backlight--minibuf-update t))))
    map)
  "Key map used for interactive minibuffer brightness adjustment.")

(defun backlight--prompt ()
  "Calculate the backlight prompt string."
  (let ((percent (backlight--current-percentage)))
    (if (< percent 1)
        (format "%%%.2f" percent)
      (format "%%%d" (floor percent)))))

;;;###autoload
(defun backlight ()
  "Interactively adjust the backlight brightness in the minibuffer."
  (interactive)
  (backlight--begin)
  (read-from-minibuffer "brightness: "
                        (backlight--prompt)
                        backlight--minibuffer-keymap))

;;;###autoload
(defun backlight-inc (amount)
  "Increment the backlight brightness by the specified or default AMOUNT."
  (interactive (list (backlight--get-inc-amount)))
  (backlight--adjust amount))

;;;###autoload
(defun backlight-dec (amount)
  "Decrements the backlight brightness by the specified or default AMOUNT."
  (interactive (list (backlight--get-inc-amount)))
  (backlight--adjust (* amount -1)))

;;;###autoload
(defun backlight-set-raw ()
  "Interactively set the raw backlight brightness value."
  (interactive)
  (backlight--begin)
  (let ((new (read-from-minibuffer
              (format "raw brightness (%s max): "
                      backlight--max-brightness)
              (number-to-string backlight--current-brightness))))
    (backlight--set-brightness (string-to-number new))))

(backlight--init)

(provide 'backlight)

;;; backlight.el ends here
