;;; buffer-flip.el --- Cycle through buffers like Alt-Tab in Windows

;; Author: Russell Black (killdash9@github)
;; Keywords: convenience
;; Package-Version: 20180307.2251
;; Package-Commit: b8ecbf0251a59c351a3e44607ee502af343da64b
;; URL: https://github.com/killdash9/buffer-flip.el
;; Created: 10th November 2015
;; Version: 2.0

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
;; Inspired by Alt-Tab.  Quickly flip through recently-used buffers.

;;; Code:
(eval-when-compile (require 'cl))

(defvar buffer-flip-map '(keymap)
  "The transient map which is active during cycling.
This must be explicitly configured by the user with keys mapped
to the three buffer flipping commands, as shown in the following
example.

;; key to begin cycling buffers.  Global key.
\(global-set-key (kbd \"M-<tab>\") 'buffer-flip)

;; transient keymap used once cycling starts
\(setq buffer-flip-map
      (let ((map (make-sparse-keymap)))
        (define-key map (kbd \"M-<tab>\")   'buffer-flip-forward)
        (define-key map (kbd \"M-S-<tab>\") 'buffer-flip-backward)
        (define-key map (kbd \"M-ESC\")     'buffer-flip-abort)
        map))")

(defun buffer-flip-check-map-configuration ()
  "Ensures that `buffer-flip-map' has been configured properly."
  (mapc
   (lambda (func)
     (or (where-is-internal func (list (or buffer-flip-map '(keymap))) )
         (user-error
          "%s not bound to a key in buffer-flip-map.  See documentation" func)))
   (list 'buffer-flip-forward 'buffer-flip-backward 'buffer-flip-abort)))

(defvar buffer-flip-exit-function nil
  "Called by `buffer-flip-abort' to exit the transient map.")

(defvar buffer-flip-original-window-configuration nil
  "Saves the current window configuration when flipping begins.
Used by `buffer-flip-abort' to restore the original buffer.")

(defcustom buffer-flip-skip-patterns nil
  "A list of regular expressions.
Buffers with names matching these patterns will be skipped when
flipping through buffers."
  :type '(repeat string) :group 'buffer-flip)

;;;###autoload
(defun buffer-flip (&optional arg original-configuration)
  "Begin cycling through buffers.
With prefix ARG, invoke `buffer-flip-other-window'.
ORIGINAL-CONFIGURATION is used internally by
`buffer-flip-other-window' to specify the window configuration to
be restored upon abort."
  (interactive "P")
  (buffer-flip-check-map-configuration)
  ;; ensure current buffer is on the top of the stack at outset.  It's
  ;; rare, but this happens sometimes, particularly with the help
  ;; buffer.
  (switch-to-buffer (current-buffer))
  (if arg
      (buffer-flip-other-window)    ; C-u calls buffer-flip-other-window
    (setq buffer-flip-original-window-configuration ;restored in abort
          (or original-configuration (current-window-configuration)))
    (buffer-flip-cycle 'forward)    ; flip forward
    (setq buffer-flip-exit-function ; set up transient key map for cycling
          (set-transient-map buffer-flip-map t
                             (lambda () (switch-to-buffer (current-buffer)))))))

;;;###autoload
(defun buffer-flip-other-window ()
  "Switch to another window and begin cycling through buffers in that window.
If there is no other window, one is created first."
  (interactive)
  (let ((original-window-configuration (current-window-configuration)))
    (when (= 1 (count-windows))
      (split-window-horizontally))
    (other-window 1)
    (buffer-flip nil original-window-configuration)))

(defun buffer-flip-cycle (&optional direction)
  "Cycle in the direction indicated by DIRECTION.
DIRECTION can be 'forward or 'backward"
  (let ((l (buffer-list)))
    (switch-to-buffer            ; Switch to next/prev buffer in stack
     (do ((buf (current-buffer)  ; Using the current buffer as a
               (nth (mod (+ (cl-position buf l) ; reference point to cycle
                            (if (eq direction 'backward) -1 1)) ; fwd or back
                         (length l)) l)))                ; Mod length to wrap
         ((not (buffer-flip-skip-buffer buf)) buf)) t))) ; skipping some buffers

(defun buffer-flip-skip-buffer (buf)
  "Return non-nil if BUF should be skipped."
  (or (get-buffer-window buf)         ; already visible?
      (= ? (elt (buffer-name buf) 0)) ; internal?
      (let ((name (buffer-name buf))) ; matches regex?
        (cl-find-if (lambda (rex) (string-match-p rex name) )
                    buffer-flip-skip-patterns))))

(defun buffer-flip-forward ()
  "Switch to previous buffer during cycling.
This command should be bound to a key inside of
`buffer-flip-map'."
  (interactive)
  (buffer-flip-cycle 'forward))

(defun buffer-flip-backward ()
  "Switch to previous buffer during cycling.
This command should be bound to a key inside of
`buffer-flip-map'."
  (interactive)
  (buffer-flip-cycle 'backward))

(defun buffer-flip-abort ()
  "Abort buffer cycling process and return to original buffer.
This command should be bound to a key inside of
`buffer-flip-map'."
  (interactive)
  (set-window-configuration buffer-flip-original-window-configuration)
  (funcall buffer-flip-exit-function))

;;; Backwards compatibility and migration instructions for users on
;;; old version

(defun buffer-flip-set-keys (symbol value)
  "Depcrecated.  Kept for backward compatibility.
Prints upgrade instructions if it is called.
Called from variable customization.  Sets the value of
`buffer-flip-keys' to VALUE.  SYMBOL is ignored."
  (set-default 'buffer-flip-keys value)
  (when (not (string-equal value "u8*"))
    (buffer-flip-upgrade-instructions)))

(defcustom buffer-flip-keys "u8*"
  "Deprecated.  Kept for backward compatibility.
See online documentation for new way to configure."
  :set 'buffer-flip-set-keys :type '(string) :group 'buffer-flip)

(defun buffer-flip-mode (&rest args)
  "Deprecated.  Kept for backward compatibility.
ARGS is ignored."
  (interactive)
  (buffer-flip-upgrade-instructions))

(defun buffer-flip-upgrade-instructions ()
  "Print upgrade instructions, and migrate old configuration."
  (when (not (and (stringp buffer-flip-keys) (= 3 (length buffer-flip-keys))))
    (setq buffer-flip-keys "u8*"))
  
  (let* ((new-config
          `((key-chord-define-global ,(substring buffer-flip-keys 0 2)
                                     'buffer-flip)
            (setq buffer-flip-map
                  (let ((map (make-sparse-keymap)))
                    (define-key map ,(substring buffer-flip-keys 1 2)
                      'buffer-flip-forward)
                    (define-key map ,(substring buffer-flip-keys 2 3)
                      'buffer-flip-backward)
                    (define-key map (kbd "C-g") 'buffer-flip-abort)
                    map
                    ))))
         (new-config-string (concat (mapconcat 'pp-to-string new-config "\n") "
;; In addtion, remove the following.
;; REMOVE: (buffer-flip-mode)
;; REMOVE: (buffer-flip-set-keys ...)
;; REMOVE: (custom-set-variables ... '(buffer-flip-keys ...))")))
    (display-warning 'buffer-flip
                     (format "Configuration requires upgrading.

Buffer-flip has been updated and its old configuration is being
phased out.  Change your configuration as follows for an updated
configuration with your current key bindings.


%s


The above code has automatically been run so buffer-flip should
continue to work with the same key bindings as before, but you
will continue to see this message on startup until you update
your configuration as shown above.

Sorry for the inconvenience.  The main reason for the change is
to add support for normal (non-chord) key bindings.  Backwards
compatibility with old configuration will be removed in a future
version.
" new-config-string) :warning)
    (put 'buffer-flip-keys 'variable-documentation (concat "
         Deprecated.  This property should not be used to
         configure your key bindings.  The following
         configuration will give you the same key bindings.  It
         is recommended that you update your configuration as
         follows, and remove any configuration you have for this
         variable.\n\n" new-config-string))
    (mapc 'eval new-config))) ; run the new configuration

(provide 'buffer-flip)
;;; buffer-flip.el ends here
