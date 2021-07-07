;;; catmacs.el --- Simple CAT interface for Yaesu FT991A

;;
;; Copyright (C) 2017 Frank Singleton
;;
;; Author: Frank Singleton <b17flyboy@gmail.com>
;; Version: 0.1.1
;; Package-Version: 20170803.745
;; Package-Commit: c6e8277bd2aab3f5fbf10d419111110f3b33564f
;; Keywords: catmacs, radio, control, cat, yaesu, ft991a
;; URL: https://pymaximus@bitbucket.org/pymaximus/catmacs.git
;;

;;; The MIT License:

;; http://en.wikipedia.org/wiki/MIT_License
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;;
;; Provides an Emacs CAT client for controlling Yaesu FT991A.
;;
;; Under construction... eventually it will support a catmacs Major Mode
;;
;; Basic stuff works, including ...
;;
;; * Frequency
;; * Mode
;; * RF Gain
;; * AF Gain
;; * RF Attenuator
;; * QMB Recall
;; * Band Select
;; * Band Up/Down
;; * Encorder Up/Down
;; * Channel Up/Down
;; * Noise Blanker
;; * LED/TFT Dimmer
;;

;;; Custom:


(defgroup catmacs nil
  "CAT client for Yaesu FT-991A."
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
  (catmacs-send-serial (format "AG0%03d;" gain))
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
  (catmacs-send-serial "BD0;"))

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
    (setq cmd (format "BS%02d;" p1))
    (catmacs-send-serial cmd)
    )
  )

;;
;; BU
;;

(defun catmacs-bu-set ()
  "BU - Set - Band Up."
  (interactive)
  (catmacs-send-serial "BU0;"))

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
    (message "catmacs: %s" p1)
    (setq cmd (format "CH%1d;" p1))
    (catmacs-send-serial cmd)
    )
  )


;;
;; DA
;;

(defun catmacs-da-set (led_level tft_level)
  "DA - Set - Dimmer.
Sets the LED_LEVEL and TFT_LEVEL brightness level."
  (interactive "nLED Level (1-2): \nnTFT Level (0-15): ")
  (let (cmd)
    (setq cmd (format "DA00%02d%02d;" led_level tft_level))
    (catmacs-send-serial cmd)
    )
  )


;;
;; DN
;;
(defun catmacs-dn-set ()
  "DN - Set - Microphone Down."
  (interactive)
  (let (cmd)
    (setq cmd (format "DN;"))
    (catmacs-send-serial cmd)
    )
  )

;;
;; ED
;;

(defun catmacs-ed-set (encorder steps)
  "ED - Set - Encorder Down.
Sets Main/Sub/Multi ENCORDER down by STEPS"
  (interactive "nEncorder (0-main, 1-sub, 2-multi): \nnSteps: ")
  (let (cmd)
    (setq cmd (format "ED%1d%02d;" encorder steps))
    (catmacs-send-serial cmd)
    )
  )


;;
;; EU
;;

(defun catmacs-eu-set (encorder steps)
  "EU - Set - Encorder Up.
Sets Main/Sub/Multi ENCORDER up by STEPS"
  (interactive "nEncorder (0-main, 1-sub, 2-multi): \nnSteps: ")
  (let (cmd)
    (setq cmd (format "EU%1d%02d;" encorder steps))
    (catmacs-send-serial cmd)
    )
  )


;;
;; FA
;;

(defun catmacs-fa-set (frequency)
  "FA - Set - Frequency VFO-A.
Sets the FREQUENCY (Hz) of VFO-A"
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
  (let (cmd response)
    (setq cmd (format "FA;"))
    (setq response (catmacs-send-serial cmd))
    (string-to-number (substring response 2 -2))
    )
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
    (message "catmacs: %s" p1)
    (setq cmd (format "FS%1d;" p1))
    (catmacs-send-serial cmd)
    )
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
  (let (cmd response)
    (setq cmd (format "IF;"))
    (setq response (catmacs-send-serial cmd))
    (message "catmacs: information [%s]" response)
    (substring response 2 -1)
    )
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
    (message "catmacs: %s" p1)
    (setq cmd (format "LK%1d;" p1))
    (catmacs-send-serial cmd)
    )
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
    (message "catmacs: p1 = %s" p1)
    (message "catmacs: p2 = %s" p2)
    (setq cmd (format "NB%1d%1d" p1 p2))
    (catmacs-send-serial cmd)
    )
  )

;;
;; NL
;;

(defun catmacs-nl-set (level)
  "Set Noise Blanker LEVEL."
  (interactive "nNoise Blanker Level (0-10): ")
  (let (cmd)
    (setq cmd (format "NL0%03d;" level))
    (catmacs-send-serial cmd)
    )
  )

;;
;; QR
;;

(defun catmacs-qr-set ()
  "QR - Set - QMB recall.
Sets QMB Recall command.  This cycles through the 5 QMB memories."
  (interactive)
  (let (cmd)
    (setq cmd (format "QR;" ))
    (catmacs-send-serial cmd)
    )
  )


;;
;; This example shows both interactive and non-interactive
;; functions. Still thinking about this. Low level API should
;; be non interactive ideally, and then we can build interactive function on top
;; of that ?

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
  (let (cmd)
    (setq cmd (format "RG0%03d;" gain))
    (catmacs-send-serial cmd)
    )
  )

(defun catmacs-rg-set-ni (p1 p2)
  "RG - Set - RF GAIN P1 P2."
  (catmacs-send-serial (format "RG%1d%03d;" p1 p2))
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
  ;;
  ;; Sample Read commands
  ;;
  (message (format "catmacs: VFO-A Frequency = %d Hz" (catmacs-fa-read)))

  ;; reset display brightness to lower settings
  (catmacs-da-set 1 0)
  )

;;
;; catmacs key bindings, awesome "C-c m" is free.
;;
(global-set-key (kbd "C-c m f") 'catmacs-fa-set)
(global-set-key (kbd "C-c m m") 'catmacs-md-set)
(global-set-key (kbd "C-c m q") 'catmacs-qr-set)
(global-set-key (kbd "C-c m e d") 'catmacs-ed-set)
(global-set-key (kbd "C-c m e u") 'catmacs-eu-set)
(global-set-key (kbd "C-c m a") 'catmacs-ra-set)
(global-set-key (kbd "C-c m l") 'catmacs-lk-set)
(global-set-key (kbd "C-c m b") 'catmacs-bs-set)
(global-set-key (kbd "C-c m v") 'catmacs-ag-set)
(global-set-key (kbd "C-c m s") 'catmacs-sv-set)


(provide 'catmacs)
;;; catmacs.el ends here
