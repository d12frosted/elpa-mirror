;;; rcirc-styles.el --- support mIRC-style color and attribute codes

;; Package-Version: 20210414.1712
;; Package-X-Original-Version: 20160206.001
;; Copyright 2016 Aaron Miller <me@aaron-miller.me>
;; Package-Requires: ((cl-lib "0.5"))
;; Package-Commit: dd06ec5fa455131788bbc885fcfaaec16b08f13b

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; The de facto standard for IRC color codes, as originally
;; implemented in mIRC, can be found at
;; http://en.wikichip.org/wiki/irc/colors .

;; As may be expected from the context, it's a bit ad hoc and not the
;; easiest thing in the world to parse correctly, which may explain why a
;; prior attempt to satisfy this use case, under the name of
;; "rcirc-controls.el", attempted to do so with a recondite yet woefully
;; inadequate regexp.

;; Rather than attempt to fix the regexp, and even if successful make
;; it even more incomprehensible than it started out being, I decided
;; it'd be easier and more maintainable to write a string-walking
;; parser.

;; So I did that.  In addition to those cases supported in the previous
;; library, this code correctly handles:
;; * Background colors, including implicit backgrounds when a new code
;;   provides only a foreground color.
;; * Colors at codes between 8 and 15 (and correct colors for codes < 8).
;; * Color specifications implicitly terminated by EOL.
;; * Color specifications implicitly terminated by new color
;;   specifications.
;; * The ^O character terminating color specifications.

;; While I was at it, I noticed some areas in which the both the stock
;; attribute markup function in rcirc, and the one provided in
;; the previous library, could use improving.

;; So I did that too, and the following cases are now correctly handled:
;; * Implicit termination of attribute markup by EOL.
;; * ^V as the specifier for reverse video, rather than italics.
;; * ^] as the specifier for italics.

;; There are a couple of attribute codes which I've only seen
;; mentioned in a few places, and haven't been able to confirm
;; whether or how widely they're used:
;; * ^F for flashing text;
;; * ^K for fixed-width text.
;; Since these appear to be so ill-used, I'm not terribly anxious to
;; support them in rcirc, but they are on my radar. If you want one or
;; both of these, open an issue!

;; As far as I'm aware, this code implements correct and, subject to
;; the preceding caveats, complete support for mIRC colors and
;; attributes. If I've missed something, let me know!

;; Finally, a note: Since this package entirely obsoletes
;; rcirc-controls, it will attempt rather vigorously to disable its
;; predecessor, by removing rcirc-controls' hooks from
;; `rcirc-markup-text-functions' if they are installed.  Not to do so,
;; when both packages are loaded, would result in severely broken
;; style markup behavior.

;;; Usage:

;; Once installed, this package will activate when
;; `package-activate' is called in your init process. If you happen
;; to have rcirc-controls.el installed, and it's already been
;; activated, then rcirc-styles will supersede it at that time.

;; You don't need to do anything to see styled text sent by other IRC
;; users in your channels; it'll Just Work™.

;; If you want to send styled text of your own, you have a couple of
;; methods available.

;; First, you can always just insert color and attribute codes
;; directly: for example, =C-q C-c 1 , 13= to insert the color code
;; for black text on a pink background, or =C-q C-b= to insert the
;; attribute code for bold text.

;; Second, you can use the convenience functions which rcirc-styles
;; provides since version 1.3 for this purpose:
;; `rcirc-styles-insert-color' and
;; `rcirc-styles-insert-attribute'. Both are interactive functions, so
;; can be invoked via M-x, and both provide completion of valid
;; values and will not accept invalid ones.

;; Version 1.3 also introduces a convenience function,
;; `rcirc-styles-toggle-preview', for previewing styled input as it
;; will appear once sent, so that you can see how your text will look
;; before actually sending it. Invoke this function to toggle between
;; editable input with literal style codes, and a read-only preview of
;; the same input with styles applied.

;; All of these convenience functions are also bound to a keymap,
;;  `rcirc-styles-map', which you can attach to a key sequence in
;;  `rcirc-mode-map' for additional convenice. For example, if you
;;  include in your init file

;;     (define-key rcirc-mode-map (kbd "C-c C-s") rcirc-styles-map)

;; then the following keybindings will be available in rcirc buffers:
;; - C-c C-s C-c: insert a color code
;; - C-c C-s C-a: insert an attribute code
;; - C-c C-s C-p: toggle styled preview mode

;; In a future version, I plan to automate the binding to
;; =rcirc-mode-map= and make it customizable; in the meantime, the
;; above snippet should suffice for most purposes. (If you want to see
;; customization implemented faster, comment on the relevant Github
;; issue[1] and ask!)

;; Also in a future version, I plan to add shortcut keybindings for
;; commonly used attributes, so that e.g. C-c C-s b will insert the
;; bold attribute code directly, rather than requiring all of C-c C-s
;; C-a bold RET. (As above, if you want to see it faster, use the
;; relevant Github issue [2] to let me know!)

;; [1] https://github.com/aaron-em/rcirc-styles.el/issues/7
;; [2] https://github.com/aaron-em/rcirc-styles.el/issues/8

;;; Contributing:

;; The canonical version of this package lives in a Git repository
;; [REPO] maintained through Github. To request a feature or report a
;; bug, open an issue there with as much detail as you can provide
;; about what you'd like to see, or what went wrong and how. To
;; contribute a feature or fix a bug, open a pull request with your
;; code. Don't hesitate to do either; if you have an opinion on how to
;; make rcirc-styles better, I want to hear about it!

;;; Code:

(require 'cl-lib)
(require 'rcirc)

;;
;; Functions and variables related to attribute and color markup.
;;

(defalias 'rcirc-styles-set-face-inverse-video
  (symbol-function
   (if (version< emacs-version "24.4.0")
       'set-face-inverse-video-p
       'set-face-inverse-video))
  "Which function we use to set inverse video on a face;
  `set-face-inverse-video-p' was deprecated in 24.4 in favor of
  `set-face-inverse-video', so we need to check the version and
  change which function we call accordingly.")

(defvar rcirc-styles-attribute-alist
  '(("\C-b" . bold)
    ("\C-]" . italic)
    ("\C-_" . underline)
    ("\C-v" . inverse)
    ("\C-o" . default))
  "mIRC text attribute specification characters.")

(defvar rcirc-styles-color-vector ["white"
                            "black"
                            "blue"
                            "green"
                            "red"
                            "brown"
                            "purple"
                            "orange"
                            "yellow"
                            "light green"
                            "cyan"
                            "light cyan"
                            "light blue"
                            "pink"
                            "gray"
                            "light gray"]
  "Vector of color names for the numbers 0-15.")

;; Colors and attributes are actually orthogonal, with the exception
;; of the ^O sequence that turns off both. So we need to handle them
;; accordingly, with one function to mark up attributes, another to
;; mark up colors, and a third which executes after both and cleans up
;; the leftover ^Os.

;; Since these functions are order-dependent (in that things go
;; horribly wrong if the ^Os are removed before both of the markup
;; functions have run), we wrap them all in a single defun, in a safe
;; execution order, and hang that off the
;; `rcirc-markup-text-functions' hook.

(if (not (facep 'inverse))
    (progn
      (make-face 'inverse)
      (funcall 'rcirc-styles-set-face-inverse-video 'inverse t)))

(defun rcirc-styles-markup-colors (&rest ignore)
  "Mark up received messages with foreground and background colors,
according to the de facto IRC standard at
http://en.wikichip.org/wiki/irc/colors.

This function is intended to be hung off `rcirc-styles-markup-styles',
which is rather magical. It probably will not do what you have in
mind when invoked outside that context."
  (let* (;; a list of char ranges we'll want to delete, as (offset . length)
         deletes
         ;; a list of ranges we'll want to facify, as plists (see below)
         ranges
         ;; the current foreground and background colors, if any
         fg bg
         ;; which kind of specification, if any, we found here
         found-fg found-bg)

    ;; begin from the start of the new message
    (goto-char (point-min))

    ;; walk along the message
    (while (not (cl-equalp (point) (point-max)))
      (setq found-fg nil)
      (setq found-bg nil)
      
      ;; ^O means "turn off all formatting"
      (if (looking-at "\C-o")
          (progn
            (setq fg nil)
            (setq bg nil)))

      ;; ^C introduces a color code
      (if (not (looking-at "\C-c"))
          ;; if we're not looking at a color code, just move ahead to the next char
          (forward-char 1)
        ;; otherwise, parse the color code and capture the facification info
        (let ((delete-from (point))
              (delete-length 1)
              range)

          ;; advance past ^C and set a default range to remove it
          (forward-char 1)

          ;; we have a foreground color spec
          (if (looking-at "\\([0-9]\\{1,2\\}\\)")
              (progn
                (setq found-fg t)
                ;; capture the specified color
                (setq fg (string-to-number (match-string 1)))
                ;; extend the delete length to include it
                (setq delete-length (+ delete-length
                                       (length (match-string 1))))
                ;; move point past it
                (forward-char (length (match-string 1)))))

          ;; we have a background color spec
          (if (looking-at ",\\([0-9]\\{1,2\\}\\)")
              (progn
                (setq found-bg t)
                ;; capture it
                (setq bg (string-to-number (match-string 1)))
                ;; extend delete length over it
                (setq delete-length (+ delete-length 1
                                       (length (match-string 1))))
                ;; move point past it
                (forward-char (1+ (length (match-string 1))))))

          ;; if we have a bare ^C, treat it like ^O (discontinue color specs)
          (if (and (not found-fg)
                   (not found-bg))
                   (progn
                     (setq fg nil)
                     (setq bg nil)))

          ;; if we got any color specs, update ranges and deletes
          (and (or found-fg found-bg)
               (setq range `(:from ,(point)
                                   ;; range ends at:
                                   :to ,(save-excursion
                                         ;; either the next relevant control char
                                         (or (re-search-forward "\C-o\\|\C-c" nil t)
                                             ;; or the last char before whitespace to eol
                                             (re-search-forward "[:space:]*$" nil t)
                                             ;; or, failing all else, point-max
                                             (point-max)))
                                   :fg ,fg
                                   :bg ,bg))
               (setq ranges (push range ranges))

               ;; finally, move point to the next unexamined char,
               ;; unless we're already at end of buffer
               (and (not (equal (point) (point-max)))
                    (forward-char 1)))

          (setq deletes (push
                         `(,delete-from . ,delete-length)
                         deletes)))))

    ;; facify all the known ranges, ignoring unspecified or
    ;; out-of-range color values
    (dolist (range ranges)
      (let ((fg (plist-get range :fg))
            (bg (plist-get range :bg))
            face)
        (when (and fg (< fg 16))
          (setq face (push (cons 'foreground-color
                                 (aref rcirc-styles-color-vector fg))
                           face)))
        (when (and bg (< bg 16))
          (setq face (push (cons 'background-color
                                 (aref rcirc-styles-color-vector bg))
                           face)))
        (rcirc-add-face (plist-get range :from) (plist-get range :to)
                        face)))

    ;; delete all the deletion ranges, getting rid of literal control codes
    ;; NB `deletes' is in last-to-first order, so we can just iterate
    ;; NB it like this without needing to adjust as we go
    (dolist (pair deletes)
      (goto-char (car pair))
      (delete-char (cdr pair)))))

(defun rcirc-styles-markup-attributes (&rest ignore)
  "Mark up received messages with text attributes.

This function marks up newly received IRC messages with text
attributes (bold, italic, underline, and reverse video) according to
the de facto IRC standard at http://en.wikichip.org/wiki/irc/colors.

rcirc as shipped in Emacs 24 actually includes a function by this
name, but it does not support reverse video, and it uses the
wrong control character for italics; it also fails to recognize
implicit termination of attributes by EOL, and fails to mark up
such cases.

This function is intended to be hung off `rcirc-styles-markup-styles',
which is rather magical.  It probably will not do what you have in
mind when invoked outside that context."
  (let* (deletes
         ranges
         attrs
         advanced)
    (goto-char (point-min))
    (while (not (cl-equalp (point) (point-max)))
      (setq advanced nil)
      
      ;; ^O means "turn off all formatting"
      (if (looking-at "\C-o")
          (progn
            (setq attrs nil)))

      ;; Check each attribute character in turn, to see if we're
      ;; looking at it.
      (dolist (pair rcirc-styles-attribute-alist)
        (let ((char (car pair))
              (face (cdr pair)))
          ;; If so, and if it's not C-o, toggle that attribute in `attrs'...
          (when (and (not (eq face 'default))
                     (looking-at char))
            (setq deletes (push `(,(point) . 1) deletes))
            (forward-char 1)
            (setq advanced t)
            (setq attrs
                  (if (member face attrs)
                      (cl-remove-if #'(lambda (e) (eq face e)) attrs)
                    (push face attrs)))
            ;; ...and, when there are attributes to apply, push a
            ;; range that does so.
            (when attrs
              (setq ranges (push
                            `(:from ,(point)
                              :to ,(save-excursion
                                     ;; either the next relevant control char
                                     (or (re-search-forward
                                          (concat "\C-o\\|" char) nil t)
                                         ;; or the last char before whitespace to eol
                                         (re-search-forward "[:space:]*$" nil t)
                                         ;; or, failing all else, point-max
                                         (point-max)))
                              :attrs ,attrs)
                            ranges))))))
      (and (not advanced)
           (forward-char 1)))

    ;; As in `rcirc-styles-markup-colors', q.v.
    (dolist (range ranges)
      (let (face)
        (dolist (attr (plist-get range :attrs))
          (setq face (push attr face)))
        (rcirc-add-face (plist-get range :from) (plist-get range :to) face)))
    
    ;; As in `rcirc-styles-markup-colors', q.v.
    (dolist (pair deletes)
      (goto-char (car pair))
      (delete-char (cdr pair)))))

(defun rcirc-styles-markup-remove-control-o (&rest ignore)
  "Remove all the ^O characters from a string.

This function is intended to be hung off `rcirc-styles-markup-styles',
which is rather magical.  It probably will not do what you have in
mind when invoked outside that context."
  (while (re-search-forward "\C-o" nil t)
    (backward-delete-char 1)))

(defun rcirc-styles-markup-styles (&rest ignore)
  "Apply rcirc-styles color/attribute markup.

This function is intended to be hung off
`rcirc-markup-text-functions', which invokes some magic to
constrain point within the bounds of the newly received
message.  It probably will not do what you have in mind when
invoked outside that context."
  (goto-char (point-min))
  (save-excursion
    (rcirc-styles-markup-colors))
  (save-excursion
    (rcirc-styles-markup-attributes))
  (save-excursion
    (rcirc-styles-markup-remove-control-o)))

;;
;; Functions and variables related to convenient attribute and color insertion.
;; 

(defun rcirc-styles--read-color (prompt &optional allow-empty)
  "Prompt for a color name, providing completion over known
values."
  (let ((colors (mapcar #'identity rcirc-styles-color-vector))
        val)
    (while (not (or (and allow-empty (string= val ""))
                    (not (null (member val colors)))))
      (setq val
            (completing-read (concat prompt
                                     (and allow-empty " (RET for none)")
                                     ": ")
                             colors nil (not allow-empty) nil nil "")))
    (if (and (stringp val)
             (not (string= val "")))
        val
        nil)))

(defun rcirc-styles-insert-color (&optional fg bg)
  "Insert at point a color code representing foreground FG and
background BG.

When called interactively, prompt for both values, providing
completion over known values."
  (interactive (list
                (rcirc-styles--read-color "Foreground" t)
                (rcirc-styles--read-color "Background" t)))
  (insert "\C-c")
  (and (not (null fg))
       (insert
          (number-to-string
           (cl-position fg rcirc-styles-color-vector :test #'string=))))
  (and (not (null bg))
       (insert
        ","
        (number-to-string
         (cl-position bg rcirc-styles-color-vector :test #'string=)))))

(defun rcirc-styles--read-attribute nil
  "Prompt for an attribute name, providing completion over known
values."
  (let ((val ""))
    (while (not (rassoc (intern val) rcirc-styles-attribute-alist))
      (setq val (completing-read
                 "Attribute: "
                 (mapcar #'(lambda (pair) (symbol-name (cdr pair)))
                         rcirc-styles-attribute-alist) nil t)))
    val))

(defun rcirc-styles-insert-attribute (attr)
  "Insert at point an attribute code representing the desired
attribute ATTR.

When called interactively, prompt for an attribute name,
  providing completion over known values."
  (interactive (list (rcirc-styles--read-attribute)))
  (insert (car (rassoc (intern attr) rcirc-styles-attribute-alist))))

;;
;; Functions and variables related to previewing styled text.
;;

(defvar rcirc-styles-previewed-input nil
  "Literal input currently under preview with
`rcirc-styles-preview'.")
(defvar rcirc-styles-previewing nil
  "Whether we are currently previewing input in this buffer with
`rcirc-styles-preview'.")
(make-variable-buffer-local 'rcirc-styles-previewed-input)
(make-variable-buffer-local 'rcirc-styles-previewing)

(defun rcirc-styles-toggle-preview nil
  "Switch the current buffer's state between literal input and a
read-only preview of styled input.

  This function has no effect in non-rcirc buffers."
  (interactive)
  (when (eq major-mode 'rcirc-mode)
    (with-silent-modifications
      (if rcirc-styles-previewing
          (rcirc-styles--hide-preview)
          (rcirc-styles--show-preview)))))

(defun rcirc-styles--show-preview nil
  "Put the current rcirc buffer in preview mode.

Calling this function by hand may well hose your buffer
state. Don't do that."
  (when (and (not rcirc-styles-previewing)
             (not rcirc-styles-previewed-input)
             (< rcirc-prompt-end-marker (point-max)))
    (let (input
          preview
          (preview-readonly-message
           (format "Previewing styled input.  Type %s to continue editing."
                   (key-description (this-command-keys)))))
      (goto-char rcirc-prompt-end-marker)
      (setq input (buffer-substring (point) (point-max)))
      (with-temp-buffer
        (insert input)
        (rcirc-styles-markup-styles)
        (setq preview (propertize (buffer-substring (point-min) (point-max))
                                  'read-only preview-readonly-message)))
      (goto-char rcirc-prompt-end-marker)
      (delete-region (point) (point-max))
      (insert preview)
      (setq rcirc-styles-previewed-input input)
      (setq rcirc-styles-previewing t)
      (message "%s" preview-readonly-message))))

(defun rcirc-styles--hide-preview nil
  "Take the current rcirc buffer out of preview mode.

Calling this function by hand may well hose your buffer
state. Don't do that."
  (when (and rcirc-styles-previewing
             rcirc-styles-previewed-input)
    (goto-char rcirc-prompt-end-marker)
    (setq inhibit-read-only t)
    (delete-region (point) (point-max))
    (insert rcirc-styles-previewed-input)
    (setq inhibit-read-only nil)
    (setq rcirc-styles-previewed-input nil)
    (setq rcirc-styles-previewing nil)
    (message "Editing input.  Type %s to preview styles."
             (key-description (this-command-keys)))))

;;
;; Keymap definition and bindings; administrative etc.
;;

(defvar rcirc-styles-map
  (make-sparse-keymap)
  "Keymap binding `rcirc-styles-insert' functions.")

(define-key rcirc-styles-map
    (kbd "C-p") #'rcirc-styles-toggle-preview)
(define-key rcirc-styles-map
    (kbd "C-a") #'rcirc-styles-insert-attribute)
(define-key rcirc-styles-map
    (kbd "C-c") #'rcirc-styles-insert-color)

(defun rcirc-styles-disable-rcirc-controls nil
  "Disable rcirc-controls.el, if it is installed."
  (and (functionp 'rcirc-markup-controls)
       (remove-hook 'rcirc-markup-text-functions #'rcirc-markup-controls))
  (and (functionp 'rcirc-markup-colors)
       (remove-hook 'rcirc-markup-text-functions #'rcirc-markup-colors)))

(defun rcirc-styles-activate nil
  "Activate rcirc-styles.el; if necessary, disable rcirc-controls."
  ;; forcibly supersede broken rcirc-controls.el to avoid broken behavior
  (when (featurep 'rcirc-controls)
    (message "rcirc-styles obsoletes rcirc-controls; disabling rcirc-controls.")
    (rcirc-styles-disable-rcirc-controls))
  
  ;; rcirc.el already added this hook (and defined it, badly) - we need
  ;; to get rid of it...
  (remove-hook 'rcirc-markup-text-functions 'rcirc-markup-attributes)
  ;; ...then add our own hook that does all our markup.
  (add-hook 'rcirc-markup-text-functions 'rcirc-styles-markup-styles))

;; activate package on load
(rcirc-styles-activate)
;; activate package (again, idempotently) once init is complete, to
;; ensure we catch and supersede rcirc-controls if installed
(add-hook 'after-init-hook #'rcirc-styles-activate)
(provide 'rcirc-styles)

;;; rcirc-styles.el ends here
