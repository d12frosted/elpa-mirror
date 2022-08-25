;;; idle-org-agenda.el --- Shows your agenda when editor is idle.

;; Copyright (C) 2010 John Wiegley

;; Author: John Wiegley <jwiegley@gmail.com>
;; Maintainer: Enis Özgen <mail@enisozgen.com>
;; Created: 18 Mar 2010
;; Modified: 24 Dec 2018
;; Version: 1.0
;; Package-Version: 20190106.1844
;; Package-Commit: bfdf1b4f4096acdd081b3549d6b838f4ca4f7d0d
;; Keywords: org, org-mode, org-agenda, calendar
;; URL: https://github.com/enisozgen/idle-org-agenda

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;  Basically, if you don't touch Emacs `idle-org-agenda' will display your
;;  org-agenda after certain time.
;;  That can be useful to remember tasks after come back to work.
;;  This project is comes from John Wiegley's mail at the gmane mailing list
;;  http://article.gmane.org/gmane.emacs.orgmode/23047
;;
;; Please see README.md from the same repository for documentation.

;;; Code:

(require 'org-agenda)

(defgroup idle-org nil
  "Tool that displays org-agenda when emacs is idle"
  :group 'org-agenda)

(defcustom idle-org-agenda-interval 300
  "Period of idle time period to run functions."
  :type 'integer
  :group 'idle-org-agenda)

(defcustom idle-org-agenda-key "a"
  "Org-agenda key to choose spesific agenda."
  :type 'string
  :group 'idle-org-agenda)

(defun idle-org-agenda--jump-to-agenda ()
  "Main functions show your defined agenda."
  (let ((buf (get-buffer org-agenda-buffer-name))
        wind)
    (if buf
        (if (setq wind (get-buffer-window buf))
            (select-window wind)
          (if (called-interactively-p)
              (progn
                (select-window (display-buffer buf t t))
                (org-fit-window-to-buffer))
            (with-selected-window (display-buffer buf)
              (org-fit-window-to-buffer))))
      (org-agenda nil idle-org-agenda-key))))

(defun idle-org-agenda--stop ()
  "Stop idle-org-agenda."
  (cancel-function-timers 'idle-org-agenda--jump-to-agenda))

(defun idle-org-agenda--start ()
  "Start idle-org-agenda."
  (run-with-idle-timer idle-org-agenda-interval  t 'idle-org-agenda--jump-to-agenda))

(define-minor-mode idle-org-agenda-mode
  "Toggle `idle-org-agenda-mode'

When it's enabled. If you don't touch emacs, after certain time emacs will show
your org-agenda"
  nil
  :lighter ""
  :global t
  :require 'idle-org-agenda
  (if idle-org-agenda-mode
      (idle-org-agenda--start)
    (idle-org-agenda--stop)))


(provide 'idle-org-agenda)

;;; idle-org-agenda.el ends here
