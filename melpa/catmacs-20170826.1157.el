;;; catmacs.el --- Simple CAT interface for Yaesu Transceivers.

;;
;; Copyright (C) 2017 Frank Singleton
;;
;; Author: Frank Singleton <b17flyboy@gmail.com>
;; Version: 0.1.1
;; Package-Version: 20170826.1157
;; Package-Commit: 65d3e0563abe6ff9577202cf2278074d4130fbdd
;; Keywords: comm, hardware
;; URL: https://bitbucket.org/pymaximus/catmacs
;; Package-Requires: ((emacs "24"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;
;; Provides a client for controlling Yaesu Transceivers using CAT protocol.
;; Initial capability supports FT-991(A)
;;
;; Basic CAT functions work, including ...
;;
;;    * Frequency
;;    * Mode
;;    * RF Gain
;;    * AF Gain
;;    * RF Attenuator
;;    * QMB Recall
;;    * Band Select
;;    * Band Up/Down
;;    * Encorder Up/Down
;;    * Channel Up/Down
;;    * Noise Blanker
;;    * LED/TFT Dimmer
;;    * and more ...

;;; Custom:


(defgroup catmacs nil
  "CAT client for Yaesu Transceivers."
  :prefix "catmacs-"
  :group 'applications)

(defcustom catmacs-serial-port "/dev/tty.SLAB_USBtoUART"
  "Serial port for CAT communications."
  :type '(string)
  :group 'catmacs)

(defcustom catmacs-baud-rate 38400
  "Baud rate for CAT serial communications."
  :type 'integer
  :group 'catmacs)

(defcustom catmacs-accept-timeout 0.1
  "Sets the timeout for accepting process output.  See `accept-process-output' \
for details."
  :type 'float
  :group 'catmacs)

;;
;;; Code:
;;

(defun catmacs-send-serial (command)
  "Send a COMMAND string over serial port."
  (interactive "sCAT Command:")
  (with-temp-buffer
    (let ( process response)
      (setq process (make-serial-process
                     :port catmacs-serial-port
                     :speed catmacs-baud-rate
                     :name "rig"
                     :flowcontrol 'hw
                     :coding 'no-conversion
                     :buffer (current-buffer))
            )
      (message "catmacs: process = [%s]" process)
      (setq response (catmacs-send-process process command))
      (message "catmacs: process response = [%s]" response)
      (delete-process process)
      response
      )))

(defun catmacs-send-process (process command)
  "Send to a specified PROCESS, a COMMAND string."
  (message "catmacs: process = [%s] command = [%s]" process command)
  (with-current-buffer (process-buffer process)
    (process-send-string process command)
    (accept-process-output process catmacs-accept-timeout)
    (message "catmacs: CAT response = [%s]" (buffer-string))
    (buffer-string)))

;;
;; CAT Commands.
;;
;; Reference: FT-991A Cat Operation Reference Manual
;;
;; NOTE: This is just a useful(?) subset for now.
;;

;;
;; AB
;;

(defun catmacs-ab-set ()
  "AB - Set - VFO-A to VFO-B."
  (interactive)
  (catmacs-send-serial "AB;"))

;;
;; AG
;;

(defun catmacs-ag-set (gain)
  "AF - Set - AF GAIN (0-255)."
  (interactive "nAF Gain (0-255): ")
  (catmacs-ag-set-ni 0 gain)
  )

(defun catmacs-ag-set-ni (p1 p2)
  "AF - Set - AF GAIN P1 P2."
  (catmacs-send-serial (format "AG%1d%03d;" p1 p2))
  )

;;
;; AI
;;

(defun catmacs-ai-set ()
  "AI - Set - Auto Information STATE."
  (interactive)
  (let (cmd choice p1)
    (setq choice (completing-read "Select:" '("on" "off")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"on" (setq p1 1))
      ('"off" (setq p1 0))
      ;; default is off
      (_ (setq p1 0))
      )
    (message "catmacs: p1 = %s" p1)
    (setq cmd (format "AI%1d;" p1))
    (catmacs-send-serial cmd)
    )
  )

;;
;; BD
;;

(defun catmacs-bd-set ()
  "BD - Set - Band Down."
  (interactive)
  (catmacs-bd-set-ni 0)
  )

(defun catmacs-bd-set-ni (p1)
  "BD - Set - Band Down P1."
  (catmacs-send-serial (format "BD%1d;" p1)))

;;
;; BS
;;

(defun catmacs-bs-set ()
  "BS - Set - Band Select."
  (interactive)
  (let (cmd choice p1)
    (setq choice (completing-read
                  "Select Band: " '("1.8MHz" "3.5MHz" "7MHz"
                                    "10MHz" "14MHz" "18MHz"
                                    "21MHz" "24.5MHz" "28MHz"
                                    "50MHz" "GEN" "MW" "AIR"
                                    "144MHz" "430MHz")))

    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"1.8MHz" (setq p1 0))
      ('"3.5Mhz" (setq p1 1))
      ('"7MHz" (setq p1 3))
      ('"10MHz" (setq p1 4))
      ('"14MHz" (setq p1 5))
      ('"18MHz" (setq p1 6))
      ('"21MHz" (setq p1 7))
      ('"24.5MHz" (setq p1 8))
      ('"28MHz" (setq p1 9))
      ('"50MHz" (setq p1 10))
      ('"GEN" (setq p1 11))
      ('"MW" (setq p1 12))
      ('"AIR" (setq p1 14))
      ('"144MHz" (setq p1 15))
      ('"430MHz" (setq p1 16))
      ;; default is MW
      (_ (setq p1 12))
      )
    (message "catmacs: p1 = %s" p1)
    (catmacs-bs-set-ni p1)
    )
  )

(defun catmacs-bs-set-ni (p1)
  "BS - Set - Band Select P1."
  (catmacs-send-serial (format "BS%02d;" p1))
  )

;;
;; BU
;;

(defun catmacs-bu-set ()
  "BU - Set - Band Up."
  (interactive)
  (catmacs-bu-set-ni 0)
  )

(defun catmacs-bu-set-ni (p1)
  "BU - Set - Band Up P1."
  (catmacs-send-serial (format "BU%1d;" p1)))

;;
;; CH
;;

(defun catmacs-ch-set ()
  "CH - Set - Channel Up/Down.
Sets the memory channel up or down."
  (interactive)
  (let (cmd choice p1)
    (setq choice (completing-read "Memory Channel Direction: " '("up" "down")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"up" (setq p1 0))
      ('"down" (setq p1 1))
      ;; default is up
      (_ (setq p1 0))
      )
    (catmacs-ch-set-ni p1)
    )
  )

(defun catmacs-ch-set-ni (p1)
  "CH - Set - Channel Up/Down P1."
  (catmacs-send-serial (format "CH%1d;" p1)))

;;
;; DA
;;

(defun catmacs-da-set (led_level tft_level)
  "DA - Set - Dimmer.
Sets the LED_LEVEL and TFT_LEVEL brightness level."
  (interactive "nLED Level (1-2): \nnTFT Level (0-15): ")
  (catmacs-da-set-ni 0 led_level tft_level)
  )

(defun catmacs-da-set-ni (p1 p2 p3)
  "DA - Set - Dimmer P1 P2 P3."
  (catmacs-send-serial (format "DA%02d%02d%02d;" p1 p2 p3))
  )



;;
;; DN
;;
(defun catmacs-dn-set ()
  "DN - Set - Microphone Down."
  (interactive)
  (catmacs-dn-set-ni)
  )

(defun catmacs-dn-set-ni ()
  "DN - Set - Microphone Down."
  (catmacs-send-serial "DN;")
  )

;;
;; ED
;;

(defun catmacs-ed-set (encoder steps)
  "ED - Set - Encoder Down.
Sets Main/Sub/Multi ENCODER down by STEPS"
  (interactive "nEncoder (0-main, 1-sub, 2-multi): \nnSteps: ")
  (catmacs-ed-set-ni encoder steps)
  )

(defun catmacs-ed-set-ni (p1 p2)
  "ED - Set - Encoder Down P1 P2."
  (catmacs-send-serial (format "ED%1d%02d;" p1 p2))
  )

;;
;; EU
;;

(defun catmacs-eu-set (encoder steps)
  "EU - Set - Encoder Up.
Sets Main/Sub/Multi ENCODER up by STEPS"
  (interactive "nEncoder (0-main, 1-sub, 2-multi): \nnSteps: ")
  (catmacs-eu-set-ni encoder steps)
  )

(defun catmacs-eu-set-ni (p1 p2)
  "EU - Set - Encoder Up P1 P2."
  (catmacs-send-serial (format "EU%1d%02d;" p1 p2))
  )

;;
;; FA
;;

(defun catmacs-fa-set (frequency)
  "FA - Set - Frequency VFO-A.
Sets the FREQUENCY (kHz) of VFO-A"
  (interactive "nVFO-A Frequency: ")
  (let (cmd)
    (setq cmd (format "FA%09d;" (* 1000 frequency)))
    (catmacs-send-serial cmd)
    )
  )

(defun catmacs-fa-set-ni (p1)
  "FA - Set - Frequency VFO-A P1."
  (catmacs-send-serial (format "FA%09d;" p1))
  )


(defun catmacs-fa-read ()
  "FA - Read - Frequency VFO-A.
Reads the FREQUENCY (Hz) of VFO-A"
  (interactive)
  (let (response)
    (setq response (catmacs-fa-read-ni))
    (string-to-number (substring response 2 -2))
    )
  )

(defun catmacs-fa-read-ni ()
  "FA - Read - Frequency VFO-A."
  (catmacs-send-serial "FA;")
  )

;;
;; FS
;;

(defun catmacs-fs-set ()
  "FS - Set - Fast Step.
Sets the state of the VFO-A Fast Key."
  (interactive)
  (let (cmd choice p1)
    (setq choice (completing-read "VFO-A Fast Key: " '("on" "off")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"on" (setq p1 1))
      ('"off" (setq p1 0))
      ;; default is off
      (_ (setq p1 0))
      )
    (catmacs-fs-set-ni p1)
    )
  )

(defun catmacs-fs-set-ni (p1)
  "FS - Set - Fast Step P1."
  (catmacs-send-serial (format "FS%1d;" p1))
  )

;;
;; IF
;;
;; TODO: How to present this data
;;

(defun catmacs-if-read ()
  "IF - Read - Information.
Reads information from the radio."
  (interactive)
  (let (response)
    (setq response (catmacs-if-read-ni))
    (message "catmacs: information [%s]" response)
    (substring response 2 -1)
    )
  )

(defun catmacs-if-read-ni ()
  "IF - Read - Information."
  (catmacs-send-serial "IF;")
  )

;;
;; LK
;;

(defun catmacs-lk-set ()
  "LK - Set - Lock.
Sets the state of the VFO-A Dial Lock."
  (interactive)
  (let (cmd choice p1)
    (setq choice (completing-read "VFO-A Dial Lock: " '("on" "off")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"on" (setq p1 1))
      ('"off" (setq p1 0))
      ;; default is off
      (_ (setq p1 0))
      )
    (catmacs-lk-set-ni p1)
    )
  )

(defun catmacs-lk-set-ni (p1)
  "LK - Set - Lock P1."
  (catmacs-send-serial (format "LK%1d;" p1))
  )

;;
;; MD
;;

(defun catmacs-md-set ()
  "MD - Set - Operating Mode."
  (interactive)
  (let (cmd choice p1 p2)
    (setq choice (completing-read
                  "Select Mode: " '("LSB" "USB" "CW-U"
                                    "FM" "AM" "RTTY-LSB"
                                    "CW-L" "DATA-LSB" "RTTY-USB"
                                    "DATA-FM" "FM-N" "DATA-USB" "AM-N"
                                    "C4FM" )))

    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"LSB" (setq p2 1))
      ('"USB" (setq p2 2))
      ('"CW-U" (setq p2 3))
      ('"FM" (setq p2 4))
      ('"AM" (setq p2 5))
      ('"RTTY-LSB" (setq p2 6))
      ('"CW-L" (setq p2 7))
      ('"DATA-LSB" (setq p2 8))
      ('"RTTY-USB" (setq p2 9))
      ('"DATA-FM" (setq p2 "A"))
      ('"FM-N" (setq p2 "B"))
      ('"DATA-USB" (setq p2 "C"))
      ('"AM-N" (setq p2 "D"))
      ('"C4FM" (setq p2 "E"))
      ;; default is AM
      (_ (setq p2 5))
      )
    (setq p1 0)
    (catmacs-md-set-ni p1 p2)
    )
  )

(defun catmacs-md-set-ni (p1 p2)
  "MD - Set - Operating Mode - P1 P2."
  (catmacs-send-serial (format "MD%1d%s;" p1 p2))
  )



;;
;; NB
;;

(defun catmacs-nb-set ()
  "Set Noise Blanker STATUS."
  (interactive)
  (let (cmd choice p1 p2)
    (setq choice (completing-read "Noise Blanker: " '("on" "off")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"on" (setq p2 1))
      ('"off" (setq p2 0))
      ;; default is off
      (_ (setq p2 0))
      )
    (setq p1 0)
    (catmacs-nb-set-ni p1 p2)
    )
  )

(defun catmacs-nb-set-ni (p1 p2)
  "NB - Set - Noise Blanker - P1 P2."
  (catmacs-send-serial (format "NB%1d%1d;" p1 p2))
  )

(defun catmacs-nb-read-ni (p1)
  "NB - Read - Noise Blanker - P1."
  (catmacs-send-serial (format "NB%1d;" p1))
  )

;;
;; NL
;;

(defun catmacs-nl-set (level)
  "NL - Set - Noise Blanker LEVEL."
  (interactive "nNoise Blanker Level (0-10): ")
  (catmacs-nl-set-ni 0 level)
  )

(defun catmacs-nl-set-ni (p1 p2)
  "NL - Set - Noise Blanker Level - P1 P2."
  (catmacs-send-serial (format "NL%1d%03d;" p1 p2))
  )

(defun catmacs-nl-read-ni (p1)
  "NL - Read - Noise Blanker Level - P1."
  (catmacs-send-serial (format "NL%1d;" p1))
  )

;;
;; NR
;;

(defun catmacs-nr-set ()
  "Set Noise Reduction STATUS."
  (interactive)
  (let (cmd choice p1 p2)
    (setq choice (completing-read "Noise Reduction: " '("on" "off")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"on" (setq p2 1))
      ('"off" (setq p2 0))
      ;; default is off
      (_ (setq p2 0))
      )
    (setq p1 0)
    (catmacs-nr-set-ni p1 p2)
    )
  )

(defun catmacs-nr-set-ni (p1 p2)
  "NR - Set - Noise Reduction - P1 P2."
  (catmacs-send-serial (format "NR%1d%1d;" p1 p2))
  )

(defun catmacs-nr-read-ni (p1)
  "NR - Read - Noise Reduction - P1."
  (catmacs-send-serial (format "NR%1d;" p1))
  )

;;
;; PA
;;
(defun catmacs-pa-set ()
  "Set - Pre-Amp (IPO)."
  (interactive)
  (let (cmd choice p1 p2)
    (setq choice (completing-read "Pre-Amp (IPO): " '("IPO" "AMP1" "AMP2")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"IPO" (setq p2 0))
      ('"AMP1" (setq p2 1))
      ('"AMP2" (setq p2 2))
      ;; default is IPO
      (_ (setq p2 0))
      )
    (setq p1 0)
    (catmacs-pa-set-ni p1 p2)
    )
  )


(defun catmacs-pa-set-ni (p1 p2)
  "PA - Set - Pre-Amp (IPO) - P1 P2."
  (catmacs-send-serial (format "PA%1d%1d;" p1 p2))
  )

;;
;; QR
;;

(defun catmacs-qr-set ()
  "QR - Set - QMB recall.
Sets QMB Recall command.  Repetitive invocation cycles through the 5 QMB
memories."
  (interactive)
  (catmacs-qr-set-ni)
  )

(defun catmacs-qr-set-ni ()
  "NR - Set - QMB Recall."
  (catmacs-send-serial "QR;")
  )

;;
;; This example shows both interactive and non-interactive
;; functions. Still thinking about this. Low level API should
;; be non interactive ideally, and then we can build interactive function on top
;; of that.

;;
;; RA
;;
(defun catmacs-ra-set ()
  "RA - Set - RF Attenuator."
  (interactive)
  (let (cmd choice p1 p2)
    (setq choice (completing-read "RF Attenuator: " '("on" "off")))
    (message "catmacs: choice = [%s]" choice)
    (pcase choice
      ('"on" (setq p2 1))
      ('"off" (setq p2 0))
      ;; default is off
      (_ (setq p2 0))
      )
    (setq p1 0)
    (catmacs-ra-set-ni p1 p2)
    )
  )

(defun catmacs-ra-set-ni (p1 p2)
  "RA - Set - RF Attenuator (P1 P2)."
  (catmacs-send-serial (format "RA%1d%1d;" p1 p2))
  )

;;
;; RG
;;
(defun catmacs-rg-set (gain)
  "RG - Set - RF GAIN."
  (interactive "nRF Gain (0-255): ")
  (catmacs-rg-set-ni 0 gain)
  )

(defun catmacs-rg-set-ni (p1 p2)
  "RG - Set - RF GAIN P1 P2."
  (catmacs-send-serial (format "RG%1d%03d;" p1 p2))
  )


;;
;; RL
;;
(defun catmacs-rl-set (level)
  "RG - Set - NOISE REDUCTION LEVEL."
  (interactive "nNoise Reduction Level (1-15): ")
  (catmacs-rl-set-ni 0 level)
  )


(defun catmacs-rl-set-ni (p1 p2)
  "RG - Set - RL P1 P2."
  (catmacs-send-serial (format "RL%1d%02d;" p1 p2))
  )

;;
;; SQ
;;
(defun catmacs-sq-set (level)
  "SQ - Set - Squelch LEVEL."
  (interactive "nSquelch Level: (0-100): ")
  (let (cmd)
    (setq cmd (format "SQ0%03d;" level))
    (catmacs-send-serial cmd)
    )
  )

;;
;; SV
;;
(defun catmacs-sv-set ()
  "SV - Set - Swap VFO."
  (interactive)
  (let (cmd)
    (setq cmd (format "SV;"))
    (catmacs-send-serial cmd)
    )
  )


;;
;; UP
;;
(defun catmacs-up-set ()
  "UP - Set - Microphone UP."
  (interactive)
  (let (cmd)
    (setq cmd (format "UP;"))
    (catmacs-send-serial cmd)
    )
  )

;;
;; Testing
;;
(defun catmacs-test ()
  ;;
  ;; Sample Set commands
  ;;
  "For test, execute some catmacs-xyz-set-ni commands."
  (interactive)
  ;; set brightness
  (catmacs-da-set 2 15)
  ;; set RF attenuator off
  (catmacs-ra-set-ni 0 0)
  ;; set AF gain to 50 (0-255)
  (catmacs-ag-set-ni 0 50)
  ;; set some frequencies and modes
  (message "catmacs: Setting frequency to 1377 kHz and mode to AM")
  (catmacs-md-set-ni 0 5)
  (catmacs-fa-set-ni 1377000)
  (sleep-for 5)
  (message "catmacs: Setting frequency to 531 kHz")
  (catmacs-fa-set-ni 531000)
  (sleep-for 5)
  (message "catmacs: Setting frequency to 15 MHz, mode to USB, RF Attenuator ON")
  (catmacs-md-set-ni 0 2)
  (catmacs-fa-set-ni 15000000)
  (catmacs-ra-set-ni 0 1)
  (sleep-for 5)
  (message "catmacs: Setting RF Attenuator OFF")
  (catmacs-ra-set-ni 0 0)
  (sleep-for 5)
  (message "catmacs: Setting noise reduction to 15 then 1")
  (catmacs-nr-set-ni 0 1)
  (catmacs-rl-set-ni 0 15)
  (sleep-for 5)
  (catmacs-rl-set-ni 0 1)
  (sleep-for 5)
  (catmacs-nr-set-ni 0 0)
  (message "catmacs: Setting Pre-Amp IPO -> AMP1 -> AMP2")
  (catmacs-pa-set-ni 0 0)
  (sleep-for 5)
  (catmacs-pa-set-ni 0 1)
  (sleep-for 5)
  (catmacs-pa-set-ni 0 2)
  (sleep-for 5)

  ;;
  ;; Sample Read commands
  ;;
  (message (format "catmacs: VFO-A Frequency = %d Hz" (catmacs-fa-read)))

  ;; reset display brightness to lower settings
  (catmacs-da-set 1 0)
  )

;;
;; Minor Mode
;;

(define-minor-mode catmacs-mode
  "CAT client for Yaesu FT991(A) Transceiver"
  :lighter " catmacs"
  :keymap (let ((catmacs-keymap (make-sparse-keymap)))
            ;; prefix command
            (define-prefix-command 'catmacs-keymap)
            ;; keys
            (define-key catmacs-keymap (kbd "f") 'catmacs-fa-set)
            (define-key catmacs-keymap (kbd "m") 'catmacs-md-set)
            (define-key catmacs-keymap (kbd "q") 'catmacs-qr-set)
            (define-key catmacs-keymap (kbd "e d") 'catmacs-ed-set)
            (define-key catmacs-keymap (kbd "e u") 'catmacs-eu-set)
            (define-key catmacs-keymap (kbd "a") 'catmacs-ra-set)
            (define-key catmacs-keymap (kbd "l") 'catmacs-lk-set)
            (define-key catmacs-keymap (kbd "b") 'catmacs-bs-set)
            (define-key catmacs-keymap (kbd "v") 'catmacs-ag-set)
            (define-key catmacs-keymap (kbd "s") 'catmacs-sv-set)
            (define-key catmacs-keymap (kbd "i u") 'catmacs-up-set)
            (define-key catmacs-keymap (kbd "i d") 'catmacs-dn-set)
            (define-key catmacs-keymap (kbd "n b") 'catmacs-nb-set)
            (define-key catmacs-keymap (kbd "n l") 'catmacs-nl-set)
            (define-key catmacs-keymap (kbd "r s") 'catmacs-nr-set)
            (define-key catmacs-keymap (kbd "r l") 'catmacs-rl-set)
            (define-key catmacs-keymap (kbd "p") 'catmacs-pa-set)
            catmacs-keymap)
  )


(provide 'catmacs)
;;; catmacs.el ends here
