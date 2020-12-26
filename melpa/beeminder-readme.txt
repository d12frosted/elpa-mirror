;;; Commentary:

;; beeminder.el provides a simple way for Emacs to interact with the Beeminder
;; API.  It's pretty basic at the moment, but can be used to fetch and submit
;; data.

;; Please set `beeminder-username' and `beeminder-auth-token' before using.

;; You can find your auth token by logging in to Beeminder and then visiting the
;; following URI: https://www.beeminder.com/api/v1/auth_token.json

;; Load beeminder.el with (require 'beeminder) after your Org is set up.

;;; Keyboard bindings:

;; We recommend binding the commands to the C-c b prefix

;; C-c b g    - Insert your goals as an org-mode list
;; C-c b m    - Display username in message line

;; You can use C-c C-x p (org-set-property) to add the beeminder
;; property to projects or tasks that are associated with beeminder
;; goals.  Set it to the identifier of your goal (the short name that's
;; in the URL).
;;
;; By default, completing those tasks will log one point.  You can set
;; the beeminder-value property to "prompt" in order to interactively
;; specify the value whenever you complete the task.  Set
;; beeminder-value to "time-today" in order to log the time you
;; clocked today (see "Clocking work time" in the Org manual).
;;
;; To do so, add these to your init.el:

;; (global-set-key "\C-cba" 'beeminder-add-data)
;; (global-set-key "\C-cbw" 'beeminder-whoami)
;; (global-set-key "\C-cbg" 'beeminder-my-goals-org)
;; (global-set-key "\C-cbr" 'beeminder-refresh-goal)

