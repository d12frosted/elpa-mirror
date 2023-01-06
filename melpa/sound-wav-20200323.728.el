;;; sound-wav.el --- Play wav file

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-sound-wav
;; Package-Version: 20160725.1424
;; Version: 0.02
;; Package-Requires: ((deferred "0.3.1") (cl-lib "0.5"))

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

;; Emacs port of vim-sound(https://github.com/osyo-manga/vim-sound)

;;; Code:

(require 'cl-lib)

(require 'deferred)

(when (memq system-type '(windows-nt ms-dos cygwin))
  (require 'powershell nil t))

(defgroup sound-wav nil
  "Play wav file"
  :group 'sound)

(defvar sound-wav--powershell-process nil
  "Not documented.")

(defsubst sound-wav--powershell-sound-player-process-p ()
  "Create a powershell process to play windows files?"
  (and (memq system-type '(windows-nt ms-dos cygwin))
       (fboundp 'powershell)
       (executable-find "powershell")
       (save-excursion
	 (or sound-wav--powershell-process
	     (let ((buf (current-buffer)))
	       (and
		(powershell " *sound-wav-powershell*")
		(pop-to-buffer-same-window buf)
		(setq sound-wav--powershell-process (get-buffer-process (get-buffer " *sound-wav-powershell*")))
		(set-process-query-on-exit-flag sound-wav--powershell-process nil)
		sound-wav--powershell-process))))))

(defun sound-wav--do-play-by-powershell-process (files)
  "Not documented."
  (and sound-wav--powershell-process
       (comint-send-string sound-wav--powershell-process
			   (concat (mapconcat
				    (lambda (file)
				      (format "(New-Object Media.SoundPlayer \"%s\").PlaySync()"
					      (cond
					       ((memq system-type '(cygwin))
						(cygwin-convert-file-name-to-windows file))
					       (t file))))
				    files
				    "\n") "\n"))))

;; Start powershell process to immediately parse sounds..
(sound-wav--powershell-sound-player-process-p)

(defsubst sound-wav--powershell-sound-player-p ()
  "Is powershell available to play windows files?"
  (and (executable-find "powershell")
       (memq system-type '(windows-nt ms-dos cygwin))))

(defun sound-wav--do-play-by-powershell (files)
  "Not documented."
  (deferred:$
    (deferred:process
      "powershell"
      "-c"
      (mapconcat
       (lambda (file)
         (format "(New-Object Media.SoundPlayer \"%s\").PlaySync()"
                 file))
       files
       ";"))))

(defsubst sound-wav--window-media-player-p ()
  "Not documented."
  (and (executable-find "ruby")
       (memq system-type '(windows-nt ms-dos cygwin))))

(defun sound-wav--do-play-by-wmm (files)
  "Not documented."
  (deferred:$
    (deferred:process
      "ruby"
      "-r" "Win32API"
      "-e"
      (mapconcat
       (lambda (file)
         (format "Win32API.new('winmm','PlaySound','ppl','i').call('%s',nil,0)"
                 file))
       files
       ";"))))

(defun sound-wav--do-play-by-afplay (files)
  "Not documented."
  (deferred:$
    (deferred:process-shell
      (format "echo \"%s\" | awk '{ print \"afplay \" $0 }' | bash"
              (mapconcat 'identity files "\n")))))

(defun sound-wav--do-play-by-aplay (files)
  "Not documented."
  (deferred:$
    (apply 'deferred:process "aplay" files)))

(defun sound-wav--do-play (files)
  "Not documented."
  (cond ((sound-wav--powershell-sound-player-process-p)
	 (sound-wav--do-play-by-powershell-process files))
	((sound-wav--powershell-sound-player-p)
	 (sound-wav--do-play-by-powershell files))
	((sound-wav--window-media-player-p)
         (sound-wav--do-play-by-wmm files))
        ((executable-find "afplay")
         (sound-wav--do-play-by-afplay files))
        ((executable-find "aplay")
         (sound-wav--do-play-by-aplay files))
        (t
         (error "Not found wav player on your system!!"))))

(defun sound-wav--validate-files (files)
  "Not documented."
  (cl-loop for file in files
           when (file-exists-p file)
           collect file))

;;;###autoload
(cl-defun sound-wav-play (&rest files)
  (let ((valid-files (sound-wav--validate-files files)))
    (when (null files)
      (error "No valid files!!"))
    (sound-wav--do-play valid-files)))

(provide 'sound-wav)

;;; sound-wav.el ends here
