;;; org-capture-pop-frame.el --- Run org-capture in a new pop frame

;; * Header
;; Copyright (c) 2016, Feng Shu

;; Author: Feng Shu <tumashu@163.com>
;; URL: https://github.com/tumashu/org-capture-pop-frame.git
;; Package-Version: 20230516.236
;; Package-Commit: d88b75cc02fc53716701051dbdd906db0515de8c
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4"))

;; This file is not part of GNU Emacs.

;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; * README                                                 :README:

;; org-capture-pop-frame is an extension of org-capture, when it is enabled,
;; org-capure will capture things in a new pop frame, after capture finish or abort.
;; the poped frame will be delete.

;; NOTE:

;; 1. This extension is suitable for capturing links and text in firefox.
;; 2. You can click with mouse in emacs header-line to finish or abort capture.

;; [[./snapshots/org-capture-pop-frame.gif]]

;; ** Installation

;; org-capture-pop-frame is now available from the famous emacs package repo
;; [[http://melpa.milkbox.net/][melpa]], so the recommended way is to install it
;; through emacs package management system.

;; ** Configuration
;; *** Config org-capture and org-capture-pop-frame
;; #+BEGIN_EXAMPLE
;; (require 'org-capture)
;; (require 'org-capture-pop-frame)
;; (setq org-capture-templates
;;       '(("f" "org-capture-from-web" entry  (file+headline "~/note.org" "Notes-from-web")
;;          "** %a

;; %i
;; %?
;; "
;;          :empty-lines 1)))
;; #+END_EXAMPLE

;; *** Config firefox
;; You need install *one* of the following firefox extensions, then config it.
;; 1. AppLauncher
;;    1. Download links
;;       1. https://addons.mozilla.org/zh-CN/firefox/addon/applauncher/?src=api
;;       2. https://github.com/nobuoka/AppLauncher
;;    2. Applauncher config
;;       1. Name: org-capture(f) (Edit it)
;;       2. Path: /home/feng/emacs/bin/emacsclient (Edit it)
;;       3. Args: org-protocol://capture://f/&eurl;/&etitle;/&etext; ("f" is org-capture's key)

;;       [[./snapshots/applauncher.gif]]
;; 2. org-mode-capture
;;    1. Download links
;;       1. https://addons.mozilla.org/fr/firefox/addon/org-mode-capture/
;;       2. http://chadok.info/firefox-org-capture
;;       3. https://github.com/tumashu/firefox-org-capture (tumashu modify version)
;;    2. Config it (Very simple, just change emacsclient path.)

;;    NOTE: The official org-mode-capture extension can not set some emacsclient options,
;;    for example: "--socket-name", you can download and install tumashu's modify [[https://github.com/tumashu/firefox-org-capture/blob/master/org-capture-0.3.0.xpi?raw=true][org-mode-capture's xpi]]
;;    instead.

;;    Firefox (version >= 41) may block this xpi for signature reason, user can set
;;    "xpinstall.signatures.required" to "false" in about:config to deal with this problem.

;;    [[./snapshots/firefox-org-capture.gif]]

;; *** Other userful tools
;; 1. trayit (search in google)
;; 2. [[https://sourceforge.net/projects/minime-tool/][Minime]]
;; 3. [[http://moitah.net/][RBtray]]

;;; Code:
;; * Code                                                                 :code:
;; #+BEGIN_SRC emacs-lisp
(require 'org-capture)

(defgroup org-capture-pop-frame nil
  "Run org-capture in a new pop frame."
  :group 'org-capture)

(defcustom ocpf-frame-parameters
  '((name . "org-capture-pop-frame")
    (width . 80)
    (height . 20)
    (tool-bar-lines . 0)
    (menu-bar-lines . 1))
  "The frame's parameters poped by org-capture-pop-frame.
Don't add window-system parameter in this place, for it it
set by `ocpf---org-capture'."
  :group 'org-capture-pop-frame
  :type '(alist :key-type symbol))

(defun ocpf--delete-frame (&rest args)
  "Close capture frame"
  (if (equal (cdr (assoc 'name ocpf-frame-parameters))
             (frame-parameter nil 'name))
      (delete-frame)))

(defun ocpf--delete-other-windows (&rest args)
  "Delete the extra window if we're in a capture frame"
  (if (equal (cdr (assoc 'name ocpf-frame-parameters))
             (frame-parameter nil 'name))
      (delete-other-windows)))

(defun ocpf--org-capture (orig-fun &optional goto keys)
  "Create a new frame and run org-capture."
  (interactive)
  (let ((frame-window-system
         (cond ((eq system-type 'darwin) 'ns)
               ((eq system-type 'gnu/linux) 'x)
               ((eq system-type 'windows-nt) 'w32)))
        (after-make-frame-functions
         #'(lambda (frame)
             (progn
               (select-frame frame)
               (setq word-wrap nil)
               (setq truncate-lines nil)

               ;; Close the popup frame after pressing "q" or "C-g".
               ;; https://github.com/malb/emacs.d/blame/197be098ad50d8d7aca4513d63db8705b30017e4/malb.org#L3196-L3198.
               (condition-case nil
                   (funcall orig-fun goto keys)
                 ((debug error) (ocpf--delete-frame)))

               (setq header-line-format
                     (list "Capture buffer. "
                           (propertize (substitute-command-keys "Finish \\[org-capture-finalize], ")
                                       'mouse-face 'mode-line-highlight
                                       'keymap
                                       (let ((map (make-sparse-keymap)))
                                         (define-key map [header-line mouse-1] 'org-capture-finalize)
                                         map))
                           (propertize (substitute-command-keys "abort \\[org-capture-kill]. ")
                                       'mouse-face 'mode-line-highlight
                                       'keymap
                                       (let ((map (make-sparse-keymap)))
                                         (define-key map [header-line mouse-1] 'org-capture-kill)
                                         map))))))))
    (make-frame
     `((window-system . ,frame-window-system)
       ,@ocpf-frame-parameters))))

(advice-add 'org-capture :around #'ocpf--org-capture)
(advice-add 'org-capture-finalize :after #'ocpf--delete-frame)
(advice-add 'org-switch-to-buffer-other-window :after #'ocpf--delete-other-windows)
;; #+END_SRC

;; * Footer
;; #+BEGIN_SRC emacs-lisp
(provide 'org-capture-pop-frame)

;; Local Variables:
;; coding: utf-8-unix
;; End:

;;; org-capture-pop-frame.el ends here
;; #+END_SRC
