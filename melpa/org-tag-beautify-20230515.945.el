;;; org-tag-beautify.el --- Beautify Org mode tags -*- lexical-binding: t; -*-
;; -*- coding: utf-8 -*-

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "26.1") (org-pretty-tags "0.2.2") (nerd-icons "0.0.1"))
;; Package-Version: 20230515.945
;; Package-Commit: 97941eb2322146dd5e2555904a48ac8e1a7519f0
;; Version: 0.1.0
;; Keywords: hypermedia
;; homepage: https://repo.or.cz/org-tag-beautify.git

;; Copyright (C) 2020-2021 Free Software Foundation, Inc.
;; The source code is licensed under GPLv3.
;; The image data is NOT licensed under GPLv3.

;; org-tag-beautify is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; org-tag-beautify is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Usage:
;;
;; (org-tag-beautify-mode 1)

;;; Code:

(require 'org-pretty-tags)
(require 'nerd-icons)

(defgroup org-tag-beautify nil
  "Customize group of `org-tag-beautify-mode'."
  :prefix "org-tag-beautify-"
  :group 'org)

(defcustom org-tag-beautify-data-dir (file-name-directory
                                      (or load-file-name (buffer-file-name)))
  "The org-tag-beautify data directory."
  :type 'string
  :safe #'stringp)

(defcustom org-tag-beautify-icon-height (* (default-font-height) 1)
  "Specify the tag icon height."
  :type 'number
  :safe #'numberp)

(defcustom org-tag-beautify-icon-width (* (default-font-width) 4.5)
  "Specify the tag icon width."
  :type 'number
  :safe #'numberp)

(defcustom org-tag-beautify-auto-add-tags t
  "Whether auto add tags to heading."
  :type 'boolean
  :safe #'booleanp)

(defvar org-tag-beautify--surrogate-strings-original
  (default-value 'org-pretty-tags-surrogate-strings)
  "Store `org-pretty-tags-surrogate-strings' default value for restoring.")

;;; ----------------------------------------------------------------------------
;;; find the available suitable icon for tag.
(defcustom org-tag-beautify-auto-icons t
  "Auto search available icons for tags.

If t, use string-match regexp for tag to find first available
icon then use text-property to replace tag with icon. This will
reduce the hardcoded code of (tag . icon) pair bindings.

If nil, use `org-pretty-tags' with package internal
hardcoded (tag . icon) pair bindings to display icon."
  :type 'boolean
  :safe #'booleanp)

(defvar org-tag-beautify--nerd-icons-icons-list (nerd-icons--read-candidates)
  "Store all nerd-icons list into a variable to avoid repeatedly computing.")

(defun org-tag-beautify--nerd-icons-get-icon-name (icon-plist) ; (#("<icon>" ...))
  "Extract only icon name string from icon plist structure."
  (let ((icon-name-glyph-set
         ;; strip out text-property from icon name -> "nf-md-access_point	[mdicon]"
         (substring-no-properties (car icon-plist))))
    ;; keep only icon name
    (when (string-match
           "\\([-_[:alpha:]]*\\)[\t\w]\\[\\(.*\\)\\]"
           icon-name-glyph-set)
      (match-string 1 icon-name-glyph-set))))

(defvar org-tag-beautify--nerd-icons-icon-names-list
  (mapcar 'org-tag-beautify--nerd-icons-get-icon-name
          org-tag-beautify--nerd-icons-icons-list)
  "Store all icon names list into a variable to avoid repeatedly computing.")

(defcustom org-tag-beautify-tag-icon-cache-alist nil
  "A cache list to store already search found tag and icon pair.")

(defun org-tag-beautify--find-tag-icon (&optional tag)
  "Fuzzy find TAG text in icon names then return icon."
  (interactive)
  (let* ((selection (unless tag (completing-read "Tag: " org-tag-beautify--nerd-icons-icons-list))) ; #("<icon>" ...)
         (tag (or tag
                  (org-tag-beautify--nerd-icons-get-icon-name (list selection))))) ; (#("<icon>" ...))
    ;; try to get tag associated icon from cache list at first to improve performance.
    (or (cdr (assoc tag org-tag-beautify-tag-icon-cache-alist))
        (let* (;; TODO: improve the tag name matching algorithm.
               (tag-regexp-matching-f (apply-partially 'string-match-p
                                                       (regexp-opt (list (substring-no-properties (downcase tag))))))
               (icon-name (seq-find
                           tag-regexp-matching-f
                           org-tag-beautify--nerd-icons-icon-names-list))
               (icon-f (cl-find-if
                        (lambda (f)
                          (ignore-errors (funcall f icon-name)))
                        (mapcar 'nerd-icons--function-name nerd-icons-glyph-sets)))
               (icon (if-let ((found-icon (cdr (assoc tag org-pretty-tags-surrogate-strings))))
                         found-icon
                       (ignore-errors (funcall icon-f icon-name)))))
          ;; cache already search found icon name.
          (push `(,tag . ,icon) org-tag-beautify-tag-icon-cache-alist)
          ;; TODO: save this `org-tag-beautify-tag-icon-cache-alist' into `custom.el' or elisp data file like `save-place-file'.
          (setopt org-tag-beautify-tag-icon-cache-alist org-tag-beautify-tag-icon-cache-alist)
          icon))))

;;; TEST:
;; (org-tag-beautify--find-tag-icon "archlinux")
;; (org-tag-beautify--find-tag-icon "steam")
;; (org-tag-beautify--find-tag-icon "heart")
;; (org-tag-beautify--find-tag-icon "wikipedia")
;; (org-tag-beautify--find-tag-icon "LaTeX")
;; (org-tag-beautify--find-tag-icon "ATTACH")

(defvar org-tag-beautify-overlays nil
  "A list of overlays of org-tag-beautify.")

(defun org-tag-beautify-display-icon-refresh-headline ()
  "Prettify Org mode headline tags with icons."
  ;; (cl-assert (org-at-heading-p))
  (org-match-line org-complex-heading-regexp)
  (if (match-beginning 5)
      (let ((tags-end (match-end 5)))
        ;; move to next tag
        (goto-char (1+ (match-beginning 5)))
        ;; loop over current headline tags.
        (while (re-search-forward (concat "\\(.+?\\):") tags-end t)
          (push (make-overlay (match-beginning 1) (match-end 1))
                org-tag-beautify-overlays)
          ;; replace tag with icon
          (overlay-put (car org-tag-beautify-overlays)
                       'display (list (org-tag-beautify--find-tag-icon
                                       ;; the found tag
                                       (buffer-substring-no-properties
                                        (match-beginning 1) (match-end 1)))))))))

(defun org-tag-beautify-display-icon-refresh-all ()
  "Prettify Org mode buffer tags with icons."
  (when (eq major-mode 'org-mode)
    (org-with-point-at 1
      (unless (org-at-heading-p)
        (outline-next-heading))
      (while (not (eobp))
        (org-tag-beautify-display-icon-refresh-headline)
        (outline-next-heading)))))

(defun org-tag-beautify-delete-overlays ()
  "Delete all icon tags overlays created."
  (while org-tag-beautify-overlays
    (delete-overlay (pop org-tag-beautify-overlays))))

;;; ----------------------------------------------------------------------------

(defun org-tag-beautify-set-common-tag-icons ()
  "Display most common tag as icon."
  (setq org-pretty-tags-surrogate-strings
        (append org-pretty-tags-surrogate-strings
                `(("ARCHIVE" . ,(nerd-icons-mdicon "nf-md-archive" :face 'nerd-icons-silver))
                  ("export" . ,(nerd-icons-mdicon "nf-md-file_export_outline" :face 'nerd-icons-blue))
                  ("noexport" . ,(nerd-icons-faicon "nf-fa-eye_slash" :face 'nerd-icons-dblue))
                  ("on" . ,(nerd-icons-faicon "nf-fa-toggle_on" :face 'nerd-icons-blue))
                  ("off" . ,(nerd-icons-faicon "nf-fa-toggle_off" :face 'nerd-icons-dsilver))
                  ("deprecated" . ,(nerd-icons-mdicon "nf-md-format_strikethrough_variant" :face 'nerd-icons-dsilver))
                  ("block" . ,(nerd-icons-mdicon "nf-md-block_helper" :face 'nerd-icons-red))
                  ("lock" . ,(nerd-icons-mdicon "nf-md-lock_outline" :face 'nerd-icons-dorange))
                  ("unlock" . ,(nerd-icons-mdicon "nf-md-lock_open_variant_outline" :face 'nerd-icons-green))
                  ("key" . ,(nerd-icons-codicon "nf-cod-key" :face 'nerd-icons-green))
                  ("encrypted" . ,(nerd-icons-mdicon "nf-md-lock_outline" :face 'nerd-icons-blue))
                  ("decrypted" . ,(nerd-icons-mdicon "nf-md-lock_open_variant_outline" :face 'nerd-icons-green))
                  ("certificate" . ,(nerd-icons-mdicon "nf-md-certificate_outline" :face 'nerd-icons-green))
                  ("fingerprint" . ,(nerd-icons-mdicon "nf-md-fingerprint" :face 'nerd-icons-green))
                  ("private" . ,(nerd-icons-mdicon "nf-md-folder_heart_outline" :face 'nerd-icons-pink))
                  ("privacy" . ,(nerd-icons-mdicon "nf-md-folder_hidden" :face 'nerd-icons-purple-alt))
                  ("face" . ,(nerd-icons-mdicon "nf-md-face_man" :face 'nerd-icons-blue))
                  ("filter" . ,(nerd-icons-mdicon "nf-md-filter_outline" :face 'nerd-icons-silver))
                  ("sort" . ,(nerd-icons-mdicon "nf-md-sort" :face 'nerd-icons-silver))
                  ("like" . ,(nerd-icons-mdicon "nf-md-thumb_up_outline" :face 'nerd-icons-blue))
                  ("thumbs_up" . ,(nerd-icons-mdicon "nf-md-thumb_up_outline" :face 'nerd-icons-blue))
                  ("thumbs_down" . ,(nerd-icons-mdicon "nf-md-thumb_down_outline" :face 'nerd-icons-blue))
                  ("suggested" . ,(nerd-icons-mdicon "nf-md-star_circle_outline" :face 'nerd-icons-blue))
                  ("recommended" . ,(nerd-icons-mdicon "nf-md-thumb_up_outline" :face 'nerd-icons-yellow))
                  ("favorite" . ,(nerd-icons-sucicon "nf-seti-favicon" :face 'nerd-icons-yellow))
                  ("idea" . ,(nerd-icons-mdicon "nf-md-lightbulb_on" :face 'nerd-icons-yellow))
                  ("encyclopedia" . ,(nerd-icons-mdicon "nf-md-wikipedia" :face 'nerd-icons-silver))
                  ("wiki" . ,(nerd-icons-mdicon "nf-md-wikipedia" :face 'nerd-icons-silver))
                  ("language" . ,(nerd-icons-faicon "nf-fa-language" :face 'nerd-icons-silver))
                  ("translate" . ,(nerd-icons-faicon "nf-fa-language" :face 'nerd-icons-blue))
                  ("schedule" . ,(nerd-icons-mdicon "nf-md-calendar_clock_outline" :face 'nerd-icons-red))
                  ("clock" . ,(nerd-icons-mdicon "nf-md-clock_outline" :face 'nerd-icons-blue-alt))
                  ("timer" . ,(nerd-icons-mdicon "nf-md-timer_outline" :face 'nerd-icons-blue-alt))
                  ("snooze" . ,(nerd-icons-mdicon "nf-md-alarm_snooze" :face 'nerd-icons-orange))
                  ("notify" . ,(nerd-icons-mdicon "nf-md-bell_ring_outline" :face 'nerd-icons-yellow))
                  ("notification" . ,(nerd-icons-mdicon "nf-md-bell_circle_outline" :face 'nerd-icons-yellow))
                  ("alarm" . ,(nerd-icons-mdicon "nf-md-alarm_light_outline" :face 'nerd-icons-yellow))
                  ("LOG" . ,(nerd-icons-octicon "nf-oct-log" :face 'nerd-icons-yellow))
		          ("log" . ,(nerd-icons-octicon "nf-oct-log" :face 'nerd-icons-yellow))
                  ("comment" . ,(nerd-icons-mdicon "nf-md-comment_text_outline" :face 'nerd-icons-orange))
                  ("today" . ,(nerd-icons-mdicon "nf-md-calendar_today_outline" :face 'nerd-icons-green))
                  ("event" . ,(nerd-icons-mdicon "nf-md-calendar_text_outline" :face 'nerd-icons-blue))
                  ("event_available" . ,(nerd-icons-mdicon "nf-md-calendar_multiselect" :face 'nerd-icons-green))
                  ("event_busy" . ,(nerd-icons-mdicon "nf-md-calendar_month_outline" :face 'nerd-icons-orange))
                  ("task" . ,(nerd-icons-octicon "nf-oct-tasklist" :face 'nerd-icons-yellow))
                  ("check" . ,(nerd-icons-mdicon "nf-md-checkbox_marked_outline" :face 'nerd-icons-green))
                  ("alert" . ,(nerd-icons-mdicon "nf-md-alert_outline" :face 'nerd-icons-red-alt))
                  ("important" . ,(nerd-icons-faicon "nf-fa-exclamation_circle" :face 'nerd-icons-red-alt))
                  ("flag" . ,(nerd-icons-mdicon "nf-md-flag_outline" :face 'nerd-icons-red))
                  ("label" . ,(nerd-icons-mdicon "nf-md-label_outline" :face 'nerd-icons-blue))
                  ("info" . ,(nerd-icons-faicon "nf-fa-info_circle" :face 'nerd-icons-blue))
                  ("question" . ,(nerd-icons-mdicon "nf-md-comment_question_outline" :face 'nerd-icons-purple-alt))
                  ("answer" . ,(nerd-icons-mdicon "nf-md-comment_text_outline" :face 'nerd-icons-blue-alt))
                  ("example" . ,(nerd-icons-mdicon "nf-md-information_outline" :face 'nerd-icons-blue))
                  ("error" . ,(nerd-icons-codicon "nf-cod-error" :face 'nerd-icons-red-alt))
                  ("warning" . ,(nerd-icons-faicon "nf-fa-exclamation_triangle" :face 'nerd-icons-red-alt))
                  ("bolt" . ,(nerd-icons-mdicon "nf-md-lightning_bolt" :face 'nerd-icons-yellow))
                  ("bomb" . ,(nerd-icons-mdicon "nf-md-bomb" :face 'nerd-icons-red-alt))
                  ("thunder" . ,(nerd-icons-mdicon "nf-md-lightning_bolt" :face 'nerd-icons-yellow))
                  ("quote" . ,(nerd-icons-mdicon "nf-md-comment_quote_outline" :face 'nerd-icons-orange))
                  ("history" . ,(nerd-icons-mdicon "nf-md-history" :face 'nerd-icons-orange))
                  ("refresh" . ,(nerd-icons-mdicon "nf-md-refresh" :face 'nerd-icons-orange))
                  ("repeat" . ,(nerd-icons-mdicon "nf-md-repeat" :face 'nerd-icons-blue))
                  ("shuffle" . ,(nerd-icons-mdicon "nf-md-shuffle" :face 'nerd-icons-blue))
                  ("random" . ,(nerd-icons-mdicon "nf-md-shuffle_variant" :face 'nerd-icons-blue))
                  ("star" . ,(nerd-icons-mdicon "nf-md-star" :face 'nerd-icons-yellow))
                  ("heart" . ,(nerd-icons-mdicon "nf-md-heart_outline" :face 'nerd-icons-red-alt))
                  ("heart_beat" . ,(nerd-icons-mdicon "nf-md-heart_pulse" :face 'nerd-icons-red-alt))
                  ("brain" . ,(nerd-icons-faicon "nf-fae-brain" :face 'nerd-icons-yellow))
                  ("mind" . ,(nerd-icons-mdicon "nf-md-brain" :face 'nerd-icons-blue-alt))
                  ("thought" . ,(nerd-icons-mdicon "nf-md-head_cog_outline" :face 'nerd-icons-blue))
                  ("smile" . ,(nerd-icons-faicon "nf-fa-smile_o" :face 'nerd-icons-yellow))
                  ("ticket" . ,(nerd-icons-faicon "nf-fa-ticket" :face 'nerd-icons-orange))
                  ("trash" . , (nerd-icons-mdicon "nf-md-trash_can_outline" :face 'nerd-icons-orange))
                  ("delete" . ,(nerd-icons-mdicon "nf-md-delete_forever_outline" :face 'nerd-icons-red))
                  ("clear" . ,(nerd-icons-codicon "nf-cod-clear_all" :face 'nerd-icons-red))
                  ("cancel" . ,(nerd-icons-mdicon "nf-md-cancel" :face 'nerd-icons-orange))
                  ("inprogress" . ,(nerd-icons-mdicon "nf-md-progress_clock" :face 'nerd-icons-cyan))
                  ("screenshot" . ,(nerd-icons-mdicon "nf-md-monitor_screenshot" :face 'nerd-icons-cyan-alt))
                  ("1" . ,(nerd-icons-mdicon "nf-md-numeric_1_box_outline" :face 'nerd-icons-green))
                  ("2" . ,(nerd-icons-mdicon "nf-md-numeric_2_box_outline" :face 'nerd-icons-green))
                  ("3" . ,(nerd-icons-mdicon "nf-md-numeric_3_box_outline" :face 'nerd-icons-green))
                  ("4" . ,(nerd-icons-mdicon "nf-md-numeric_4_box_outline" :face 'nerd-icons-green))
                  ("5" . ,(nerd-icons-mdicon "nf-md-numeric_5_box_outline" :face 'nerd-icons-green))
                  ("6" . ,(nerd-icons-mdicon "nf-md-numeric_6_box_outline" :face 'nerd-icons-green))
                  ("7" . ,(nerd-icons-mdicon "nf-md-numeric_7_box_outline" :face 'nerd-icons-green))
                  ("8" . ,(nerd-icons-mdicon "nf-md-numeric_8_box_outline" :face 'nerd-icons-green))
                  ("9" . ,(nerd-icons-mdicon "nf-md-numeric_9_box_outline" :face 'nerd-icons-green))
                  ("10" . ,(nerd-icons-mdicon "nf-md-numeric_10_box_outline" :face 'nerd-icons-green))
                  
                  ;; -----------------------------------------------------
                  ;; Life
                  ("forum" . ,(nerd-icons-mdicon "nf-md-forum_outline" :face 'nerd-icons-blue))
                  ("talk" . ,(nerd-icons-mdicon "nf-md-chat_processing_outline" :face 'nerd-icons-blue))
                  ("call" . ,(nerd-icons-mdicon "nf-md-phone_in_talk_outline" :face 'nerd-icons-green))
                  ("voice_chat" . ,(nerd-icons-mdicon "nf-md-account_voice" :face 'nerd-icons-green))
                  ("contact" . ,(nerd-icons-mdicon "nf-md-contacts_outline" :face 'nerd-icons-blue))
                  ("person" . ,(nerd-icons-codicon "nf-cod-person" :face 'nerd-icons-blue))
                  ("pin" . ,(nerd-icons-codicon "nf-cod-pinned" :face 'nerd-icons-cyan))
                  ("user" . ,(nerd-icons-faicon "nf-fa-user_circle" :face 'nerd-icons-blue))
                  ("users" . ,(nerd-icons-faicon "nf-fa-users" :face 'nerd-icons-blue))
                  ("group" . ,(nerd-icons-faicon "nf-fa-group" :face 'nerd-icons-orange))
                  ("gift" . ,(nerd-icons-mdicon "nf-md-gift_outline" :face 'nerd-icons-blue-alt))

                  ("girl" . ,(propertize "㊛" 'face '(:foreground "LightPink")))
                  ("boy" . ,(propertize "㊚" 'face '(:foreground "DeepSkyBlue")))
                  ("male" . ,(nerd-icons-mdicon "nf-md-gender_male" :face 'nerd-icons-blue))
                  ("female" . ,(nerd-icons-mdicon "nf-md-gender_female" :face 'nerd-icons-pink))
                  ("beauty" . ,(nerd-icons-mdicon "nf-md-human_female" :face 'nerd-icons-pink))

                  ("love" . ,(nerd-icons-mdicon "nf-md-heart_box_outline" :face 'nerd-icons-pink))

                  ;; Sexual orientation: https://en.wikipedia.org/wiki/Sexual_orientation
                  ;; LGBTQ symbols: https://en.wikipedia.org/wiki/LGBT_symbols
                  ;; ("heterosexual" . ,(nerd-icons-mdicon "nf-md-gender_male_female" :face 'nerd-icons-blue))
                  ;; ("gender_female" . ,(nerd-icons-mdicon "nf-md-gender_female" :face 'nerd-icons-pink))
                  ;; ("gender_man" . ,(nerd-icons-mdicon "nf-md-gender_male" :face 'nerd-icons-blue))
                  ;; ("female_homosexual" . ,(nerd-icons-mdicon "nf-md-human_female_female" :face 'nerd-icons-pink))
                  ;; ("male_homosexual" . ,(nerd-icons-mdicon "nf-md-human_male_male" :face 'nerd-icons-blue))
                  ;; ("lesbian" . ,(nerd-icons-mdicon "nf-md-human_female_female" :face 'nerd-icons-pink))
                  ;; ("gay" . ,(nerd-icons-mdicon "nf-md-human_male_male" :face 'nerd-icons-blue))

                  ("heterosexual" . ,(propertize "⚥" 'face '(:foreground "purple")))
                  ("gender_female" . ,(propertize "♀" 'face '(:foreground "purple")))
                  ("gender_man" . ,(propertize "♂" 'face '(:foreground "purple")))
                  ("female_homosexual" . ,(propertize "⚢" 'face '(:foreground "purple")))
                  ("male_homosexual" . ,(propertize "⚣" 'face '(:foreground "purple")))
                  ("lesbian" . ,(propertize "⚢" 'face '(:foreground "purple")))
                  ("gay" . ,(propertize "⚣" 'face '(:foreground "purple")))
                  ("asexuality" . ,(propertize "○" 'face '(:foreground "purple")))     ; 无性取向
                  ("bisexuality" . ,(propertize "⚤" 'face '(:foreground "purple")))    ; 双性恋取向
                  ("intersexuality" . ,(propertize "☿" 'face '(:foreground "purple"))) ; 中间性
                  ("transsexual" . ,(propertize "⚧" 'face '(:foreground "purple")))    ; 变性取向
                  
                  ;; Gender:
                  ;; ("genderless" . ,(nerd-icons-faicon "nf-fa-genderless" :face 'nerd-icons-purple)) ; 无性别者
                  ("genderless" . ,(propertize "○" 'face '(:foreground "purple"))) ; 无性别者
                  ("agender" . ,(propertize "○" 'face '(:foreground "purple")))
                  ("sexless" . ,(propertize "○" 'face '(:foreground "purple"))) ; 无性别者
                  ("neuter" . ,(propertize "⚲" 'face '(:foreground "purple")))      ; 中性
                  ("intersex" . ,(propertize "⚥" 'face '(:foreground "purple")))    ; 双性者
                  ("transgender" . ,(propertize "⚧" 'face '(:foreground "purple"))) ; 变性者
                  ("bigender" . ,(propertize "⚥" 'face '(:foreground "purple")))
                  ("transgender-female" . ,(propertize "⧬" 'face '(:foreground "purple")))
                  ;; ("transgender-male" . ,(propertize "" 'face '(:foreground "purple")))
                  
                  ("sleep" . ,(nerd-icons-mdicon "nf-md-sleep" :face 'nerd-icons-silver))
                  ("dining" . ,(nerd-icons-mdicon "nf-md-food_variant" :face 'nerd-icons-green))
                  ("home" . ,(nerd-icons-mdicon "nf-md-home" :face 'nerd-icons-blue))
                  ("weekend" . ,(nerd-icons-mdicon "nf-md-calendar_weekend_outline" :face 'nerd-icons-blue-alt))
                  ("birthday" . ,(nerd-icons-faicon "nf-fa-birthday_cake" :face 'nerd-icons-yellow))
                  ("party" . ,(nerd-icons-mdicon "nf-md-party_popper" :face 'nerd-icons-yellow))
                  ("build" . ,(nerd-icons-mdicon "nf-md-office_building_cog_outline" :face 'nerd-icons-silver))
                  ("repair" . ,(nerd-icons-mdicon "nf-md-wrench" :face 'nerd-icons-dsilver))
                  ("store" . ,(nerd-icons-mdicon "nf-md-store" :face 'nerd-icons-blue))
                  ("shopping" . ,(nerd-icons-mdicon "nf-md-shopping_outline" :face 'nerd-icons-orange))
                  ("coupon" . ,(nerd-icons-mdicon "nf-md-ticket_percent" :face 'nerd-icons-orange))
                  ("express" . ,(nerd-icons-mdicon "nf-md-truck_cargo_container" :face 'nerd-icons-silver))
                  ("diamond" . ,(nerd-icons-mdicon "nf-md-diamond_stone" :face 'nerd-icons-silver))
                  ("tag" . ,(nerd-icons-mdicon "nf-md-tag_outline" :face 'nerd-icons-blue))
                  ("tags" . ,(nerd-icons-mdicon "nf-md-tag_multiple" :face 'nerd-icons-blue))
                  ("money" . ,(nerd-icons-faicon "nf-fa-money" :face 'nerd-icons-green))
                  ("usd" . ,(nerd-icons-mdicon "nf-md-currency_usd" :face 'nerd-icons-green))
                  ("eur" . ,(nerd-icons-mdicon "nf-md-currency_eur" :face 'nerd-icons-blue))
                  ("jpy" . ,(nerd-icons-mdicon "nf-md-currency_jpy" :face 'nerd-icons-green))
                  ("rmb" . ,(nerd-icons-mdicon "nf-md-currency_cny" :face 'nerd-icons-green))
                  ("cny" . ,(nerd-icons-mdicon "nf-md-currency_cny" :face 'nerd-icons-green))
                  ("payment" . ,(nerd-icons-mdicon "nf-md-contactless_payment" :face 'nerd-icons-blue))
                  ("donation" . ,(nerd-icons-mdicon "nf-md-charity" :face 'nerd-icons-pink))
                  ("CC" . ,(nerd-icons-faicon "nf-fae-cc_cc" :face 'nerd-icons-silver))
                  ("credit_card" . ,(nerd-icons-faicon "nf-fa-credit_card" :face 'nerd-icons-blue))
                  ("credit_card_visa" . ,(nerd-icons-faicon "nf-fa-cc_visa" :face 'nerd-icons-blue))
                  ("credit_card_mastercard" . ,(nerd-icons-faicon "nf-fa-cc_mastercard" :face 'nerd-icons-blue))
                  ("credit_card_PayPal" . ,(nerd-icons-faicon "nf-fa-paypal" :face 'nerd-icons-blue))
                  ("credit_card_stripe" . ,(nerd-icons-faicon "nf-fa-cc_stripe" :face 'nerd-icons-blue))
                  ("credit_card_amex" . ,(nerd-icons-faicon "nf-fa-cc_amex" :face 'nerd-icons-blue))
                  ("credit_card_jcb" . ,(nerd-icons-faicon "nf-fa-cc_jcb" :face 'nerd-icons-blue))
                  ("credit_card_discover" . ,(nerd-icons-faicon "nf-fa-cc_discover" :face 'nerd-icons-blue))
                  ("gratipay" . ,(nerd-icons-faicon "nf-fa-gratipay" :face 'nerd-icons-blue))
                  ("digital_currency" . ,(nerd-icons-mdicon "nf-md-currency_usd" :face 'nerd-icons-green))
                  ("cryptocurrency" . ,(nerd-icons-mdicon "nf-md-currency_usd" :face 'nerd-icons-yellow))
                  ("bitcoin" . ,(nerd-icons-mdicon "nf-md-currency_btc" :face 'nerd-icons-yellow))
                  ("BTC" . ,(nerd-icons-mdicon "nf-md-currency_btc" :face 'nerd-icons-yellow))
                  ("ethereum" . ,(nerd-icons-sucicon "nf-seti-ethereum" :face 'nerd-icons-blue))
                  ("ETH" . ,(nerd-icons-mdicon "nf-md-ethereum" :face 'nerd-icons-blue-alt))
                  ("watch" . ,(nerd-icons-mdicon "nf-md-eye" :face 'nerd-icons-blue))
                  ("hospital" . ,(nerd-icons-mdicon "nf-md-hospital_building" :face 'nerd-icons-silver))
                  ("university" . ,(nerd-icons-faicon "nf-fa-university" :face 'nerd-icons-silver))
                  ("student" . ,(nerd-icons-faicon "nf-fa-graduation_cap" :face 'nerd-icons-dpurple))
                  ("library" . ,(nerd-icons-codicon "nf-cod-library" :face 'nerd-icons-orange))
                  ("bank" . ,(nerd-icons-mdicon "nf-md-bank_outline" :face 'nerd-icons-silver))
                  ("ATM" . ,(nerd-icons-mdicon "nf-md-atm" :face 'nerd-icons-green))
                  ("hotel" . ,(nerd-icons-faicon "nf-fa-hotel" :face 'nerd-icons-green))
                  ("spa" . ,(nerd-icons-mdicon "nf-md-spa_outline" :face 'nerd-icons-green))
                  ("laundry" . ,(nerd-icons-mdicon "nf-md-washing_machine" :face 'nerd-icons-blue))
                  ("pets" . ,(nerd-icons-mdicon "nf-md-dog" :face 'nerd-icons-orange))
                  ("flower" . ,(nerd-icons-mdicon "nf-md-flower" :face 'nerd-icons-pink))
                  ("florist" . ,(nerd-icons-mdicon "nf-md-flower_tulip_outline" :face 'nerd-icons-pink))
                  ("city" . ,(nerd-icons-mdicon "nf-md-city_variant_outline" :face 'nerd-icons-silver))
                  ("industry" . ,(nerd-icons-faicon "nf-fa-industry" :face 'nerd-icons-silver))
                  ("see_doctor" . ,(nerd-icons-mdicon "nf-md-hospital_box" :face 'nerd-icons-red-alt))
                  ("doctor" . ,(nerd-icons-mdicon "nf-md-doctor" :face 'nerd-icons-silver))
                  ("medical" . ,(nerd-icons-faicon "nf-fa-medkit" :face 'nerd-icons-silver))
                  ("medicine" . ,(nerd-icons-faicon "nf-fae-medicine" :face 'nerd-icons-blue))
                  ("health" . ,(nerd-icons-mdicon "nf-md-medical_cotton_swab" :face 'nerd-icons-green))
                  ("law" . ,(nerd-icons-codicon "nf-cod-law" :face 'nerd-icons-silver))
                  ("court" . ,(nerd-icons-codicon "nf-cod-law" :face 'nerd-icons-silver))
                  ("lawyer" . ,(nerd-icons-mdicon "nf-md-account_tie_hat_outline" :face 'nerd-icons-silver))
                  ("building" . ,(nerd-icons-mdicon "nf-md-office_building_outline" :face 'nerd-icons-silver))
                  ("government" . ,(nerd-icons-mdicon "nf-md-office_building_marker_outline" :face 'nerd-icons-blue))
                  ("school" . ,(nerd-icons-mdicon "nf-md-school_outline" :face 'nerd-icons-silver))
                  ("censorship" . ,(nerd-icons-mdicon "nf-md-monitor_eye" :face 'nerd-icons-red-alt))
                  ("map" . ,(nerd-icons-mdicon "nf-md-map" :face 'nerd-icons-blue))
                  ("map_pin" . ,(nerd-icons-mdicon "nf-md-map_marker" :face 'nerd-icons-blue))
                  ("map_signs" . ,(nerd-icons-faicon "nf-fa-map_signs" :face 'nerd-icons-orange))
                  ("street_view" . ,(nerd-icons-faicon "nf-fa-street_view" :face 'nerd-icons-orange))
                  ("location" . ,(nerd-icons-octicon "nf-oct-location" :face 'nerd-icons-blue))
                  ("navigation" . ,(nerd-icons-faicon "nf-fa-location_arrow" :face 'nerd-icons-blue))
                  ("bar" . ,(nerd-icons-faicon "nf-fa-beer" :face 'nerd-icons-orange))
                  ("drink" . ,(nerd-icons-mdicon "nf-md-beer_outline" :face 'nerd-icons-orange))
                  ("coffee" . ,(nerd-icons-mdicon "nf-md-coffee" :face 'nerd-icons-silver))
                  ("bicycle" . ,(nerd-icons-mdicon "nf-md-bicycle" :face 'nerd-icons-blue))
                  ("motorcycle" . ,(nerd-icons-mdicon "nf-md-motorbike" :face 'nerd-icons-blue))
                  ("car" . ,(nerd-icons-mdicon "nf-md-car" :face 'nerd-icons-silver))
                  ("traffic" . ,(nerd-icons-mdicon "nf-md-traffic_light_outline" :face 'nerd-icons-blue))
                  ("road" . ,(nerd-icons-mdicon "nf-md-road_variant" :face 'nerd-icons-silver))
                  ("parking" . ,(nerd-icons-mdicon "nf-md-car_brake_parking" :face 'nerd-icons-red))
                  ("bus" . ,(nerd-icons-mdicon "nf-md-bus" :face 'nerd-icons-orange))
                  ("taxi" . ,(nerd-icons-mdicon "nf-md-taxi" :face 'nerd-icons-orange))
                  ("railway" . ,(nerd-icons-mdicon "nf-md-subway" :face 'nerd-icons-silver))
                  ("subway" . ,(nerd-icons-mdicon "nf-md-subway_variant" :face 'nerd-icons-silver))
                  ("highway" . ,(nerd-icons-mdicon "nf-md-highway" :face 'nerd-icons-blue))
                  ("train" . ,(nerd-icons-mdicon "nf-md-train" :face 'nerd-icons-green))
                  ("plane" . ,(nerd-icons-mdicon "nf-md-airplane" :face 'nerd-icons-silver))
                  ("rocket" . ,(nerd-icons-mdicon "nf-md-rocket_launch_outline" :face 'nerd-icons-red))
                  ("tram" . ,(nerd-icons-mdicon "nf-md-tram" :face 'nerd-icons-silver))
                  ("ship" . ,(nerd-icons-faicon "nf-fa-ship" :face 'nerd-icons-silver))
                  ("magic" . ,(nerd-icons-mdicon "nf-md-magic_staff" :face 'nerd-icons-green))
                  ("magnet" . ,(nerd-icons-codicon "nf-cod-magnet" :face 'nerd-icons-silver))
                  ("power_off" . ,(nerd-icons-faicon "nf-fa-power_off" :face 'nerd-icons-silver))
                  ("run" . ,(nerd-icons-mdicon "nf-md-run_fast" :face 'nerd-icons-green))
                  ("walk" . ,(nerd-icons-mdicon "nf-md-walk" :face 'nerd-icons-silver))
                  ("travel" . ,(nerd-icons-mdicon "nf-md-wallet_travel" :face 'nerd-icons-silver))
                  ("child" . ,(nerd-icons-mdicon "nf-md-human_child" :face 'nerd-icons-silver))
                  ("recycle" . ,(nerd-icons-mdicon "nf-md-recycle_variant" :face 'nerd-icons-green))
                  
                  ;; weather
                  ("sun" . ,(nerd-icons-wicon "nf-weather-day_sunny" :face 'nerd-icons-yellow))
                  ("moon" . ,(nerd-icons-wicon "nf-weather-moon_waxing_crescent_3" :face 'nerd-icons-silver))
                  
                  ;; -----------------------------------------------------
                  ;; computer
                  ("clone" . ,(nerd-icons-faicon "nf-fa-clone" :face 'nerd-icons-blue))
                  ("clipboard" . ,(nerd-icons-mdicon "nf-md-clipboard_file_outline" :face 'nerd-icons-silver))
                  ("file" . ,(nerd-icons-faicon "nf-fa-file_text" :face 'nerd-icons-silver))
                  ("archive_file" . ,(nerd-icons-codicon "nf-cod-archive" :face 'nerd-icons-orange))
                  ("document" . ,(nerd-icons-mdicon "nf-md-file_document_multiple_outline" :face 'nerd-icons-silver))
                  ("Markdown" . ,(nerd-icons-mdicon "nf-md-language_markdown_outline" :face 'nerd-icons-purple))
                  ("AsciiDoc" . ,(nerd-icons-faicon "nf-fa-file_text_o" :face 'nerd-icons-silver))
                  ("reStructure" . ,(nerd-icons-faicon "nf-fa-file_text_o" :face 'nerd-icons-silver))
                  ("office" . ,(nerd-icons-mdicon "nf-md-microsoft_office" :face 'nerd-icons-red))
                  ("OneNote" . ,(nerd-icons-mdicon "nf-md-microsoft_onenote" :face 'nerd-icons-purple-alt))
                  ("slideshow" . ,(nerd-icons-faicon "nf-fa-slideshare" :face 'nerd-icons-blue))
                  ("Word" . ,(nerd-icons-mdicon "nf-md-microsoft_word" :face 'nerd-icons-dblue))
                  ("Excel" . ,(nerd-icons-mdicon "nf-md-microsoft_excel" :face 'nerd-icons-dgreen))
                  ("PowerPoint" . ,(nerd-icons-mdicon "nf-md-microsoft_powerpoint" :face 'nerd-icons-red))
                  ("Access" . ,(nerd-icons-mdicon "nf-md-microsoft_access" :face 'nerd-icons-red))
                  ("Azure" . ,(nerd-icons-mdicon "nf-md-microsoft_azure" :face 'nerd-icons-silver))
                  ("Visual_Studio" . ,(nerd-icons-mdicon "nf-md-microsoft_visual_studio" :face 'nerd-icons-silver))
                  ("Visual_Studio_Code" . ,(nerd-icons-mdicon "nf-md-microsoft_visual_studio_code" :face 'nerd-icons-silver))
                  ("WordPress" . ,(nerd-icons-mdicon "nf-md-wordpress" :face 'nerd-icons-silver))
                  ("pdf" . ,(nerd-icons-faicon "nf-fa-file_pdf_o" :face 'nerd-icons-red))
                  ("image" . ,(nerd-icons-mdicon "nf-md-image" :face 'nerd-icons-green))
                  ("video" . ,(nerd-icons-mdicon "nf-md-video_box" :face 'nerd-icons-silver))
                  ("audio" . ,(nerd-icons-sucicon "nf-seti-audio" :face 'nerd-icons-blue))
                  ("movie" . ,(nerd-icons-mdicon "nf-md-movie_open_outline" :face 'nerd-icons-silver))
                  ("book" . ,(nerd-icons-mdicon "nf-md-book_outline" :face 'nerd-icons-silver))
                  ("ebook" . ,(nerd-icons-mdicon "nf-md-book_outline" :face 'nerd-icons-blue))
                  ("magazine" . ,(nerd-icons-mdicon "nf-md-book_open_page_variant_outline" :face 'nerd-icons-blue))
                  ("Ezine" . ,(nerd-icons-mdicon "nf-md-book_open" :face 'nerd-icons-purple))
                  ("comic" . ,(nerd-icons-mdicon "nf-md-book_open_variant" :face 'nerd-icons-orange))
                  ("bookmark" . ,(nerd-icons-mdicon "nf-md-bookmark_outline" :face 'nerd-icons-blue))
                  ("plot" . ,(nerd-icons-mdicon "nf-md-chart_bell_curve" :face 'nerd-icons-blue))
                  ("diagram" . ,(nerd-icons-octicon "nf-oct-graph" :face 'nerd-icons-blue))
                  ("line_chart" . ,(nerd-icons-mdicon "nf-md-chart_line" :face 'nerd-icons-blue))
                  ("bar_chart" . ,(nerd-icons-mdicon "nf-md-chart_bar" :face 'nerd-icons-blue))
                  ("bar_stacked_chart" . ,(nerd-icons-mdicon "nf-md-chart_bar_stacked" :face 'nerd-icons-blue))
                  ("area_chart" . ,(nerd-icons-mdicon "nf-md-chart_areaspline" :face 'nerd-icons-blue))
                  ("pie_chart" . ,(nerd-icons-mdicon "nf-md-chart_pie" :face 'nerd-icons-green))
                  ("bell_curve_chart" . ,(nerd-icons-mdicon "nf-md-chart_bell_curve" :face 'nerd-icons-blue))
                  ("gantt_chart" . ,(nerd-icons-mdicon "nf-md-chart_gantt" :face 'nerd-icons-blue))
                  ("histogram_chart" . ,(nerd-icons-mdicon "nf-md-chart_histogram" :face 'nerd-icons-blue))
                  ("scatter_chart" . ,(nerd-icons-mdicon "nf-md-chart_scatter_plot" :face 'nerd-icons-blue))
                  ("timeline_chart" . ,(nerd-icons-mdicon "nf-md-chart_timeline" :face 'nerd-icons-blue))
                  ("tree_chart" . ,(nerd-icons-mdicon "nf-md-chart_tree" :face 'nerd-icons-blue))
                  ("waterfall_chart" . ,(nerd-icons-mdicon "nf-md-chart_waterfall" :face 'nerd-icons-blue))
                  ("sankey_chart" . ,(nerd-icons-mdicon "nf-md-chart_sankey" :face 'nerd-icons-blue))
                  ("ppf_chart" . ,(nerd-icons-mdicon "nf-md-chart_ppf" :face 'nerd-icons-blue))
                  ("box_chart" . ,(nerd-icons-mdicon "nf-md-chart_box_outline" :face 'nerd-icons-blue))
                  ("arc_chart" . ,(nerd-icons-mdicon "nf-md-chart_arc" :face 'nerd-icons-blue))
                  ("areaspline_chart" . ,(nerd-icons-mdicon "nf-md-chart_areaspline" :face 'nerd-icons-blue))
                  ("note" . ,(nerd-icons-codicon "nf-cod-note" :face 'nerd-icons-green))
                  ("notebook" . ,(nerd-icons-mdicon "nf-md-notebook" :face 'nerd-icons-green))
                  ("paperclip" . ,(nerd-icons-mdicon "nf-md-paperclip" :face 'nerd-icons-blue))
                  ("search" . ,(nerd-icons-mdicon "nf-md-search_web" :face 'nerd-icons-blue))
                  ("download" . ,(nerd-icons-mdicon "nf-md-download_outline" :face 'nerd-icons-blue))
                  ("upload" . ,(nerd-icons-mdicon "nf-md-upload_outline" :face 'nerd-icons-green))
                  ("link" . ,(nerd-icons-mdicon "nf-md-link_variant" :face 'nerd-icons-cyan-alt))
                  ("at" . ,(nerd-icons-mdicon "nf-md-at" :face 'nerd-icons-cyan))
                  ("mention" . ,(nerd-icons-octicon "nf-oct-mention" :face 'nerd-icons-cyan-alt))
                  ("email" . ,(nerd-icons-mdicon "nf-md-email_outline" :face 'nerd-icons-blue))
                  ("inbox" . ,(nerd-icons-mdicon "nf-md-inbox_full_outline" :face 'nerd-icons-blue))
                  ("reply" . ,(nerd-icons-mdicon "nf-md-reply" :face 'nerd-icons-silver))
                  ("reply_all" . ,(nerd-icons-mdicon "nf-md-reply_all" :face 'nerd-icons-silver))
                  ("share" . ,(nerd-icons-mdicon "nf-md-share_variant_outline" :face 'nerd-icons-blue))
                  ("screen_share" . ,(nerd-icons-mdicon "nf-md-monitor_share" :face 'nerd-icons-green))
                  ("cast" . ,(nerd-icons-mdicon "nf-md-cast" :face 'nerd-icons-green))
                  ("send" . ,(nerd-icons-mdicon "nf-md-send" :face 'nerd-icons-blue))
                  ("rss" . ,(nerd-icons-mdicon "nf-md-rss_box" :face 'nerd-icons-orange))
                  ("picture" . ,(nerd-icons-faicon "nf-fa-picture_o" :face 'nerd-icons-green))
                  ("photo" . ,(nerd-icons-faicon "nf-fa-photo" :face 'nerd-icons-green))
                  ("music" . ,(nerd-icons-mdicon "nf-md-music_box_outline" :face 'nerd-icons-green))
                  ("headphone" . ,(nerd-icons-mdicon "nf-md-headphones" :face 'nerd-icons-blue))
                  ("hearing" . ,(nerd-icons-mdicon "nf-md-ear_hearing" :face 'nerd-icons-blue))
                  ("film" . ,(nerd-icons-mdicon "nf-md-film" :face 'nerd-icons-blue))
                  ("game" . ,(nerd-icons-mdicon "nf-md-gamepad_variant_outline" :face 'nerd-icons-blue))
                  ("steam" . ,(nerd-icons-mdicon "nf-md-steam" :face 'nerd-icons-dblue))
                  ("camera" . ,(nerd-icons-mdicon "nf-md-camera_outline" :face 'nerd-icons-blue))
                  ("vlog" . ,(nerd-icons-codicon "nf-cod-device_camera_video" :face 'nerd-icons-blue))
                  ("podcast" . ,(nerd-icons-mdicon "nf-md-podcast" :face 'nerd-icons-purple))
                  ("mic" . ,(nerd-icons-mdicon "nf-md-microphone_outline" :face 'nerd-icons-blue))
                  ("mute" . ,(nerd-icons-mdicon "nf-md-volume_mute" :face 'nerd-icons-red))
                  ("play" . ,(nerd-icons-mdicon "nf-md-play_circle_outline" :face 'nerd-icons-blue))
                  ("pause" . ,(nerd-icons-mdicon "nf-md-pause_circle_outline" :face 'nerd-icons-red))
                  ("record" . ,(nerd-icons-mdicon "nf-md-record_circle_outline" :face 'nerd-icons-red))
                  ("news" . ,(nerd-icons-mdicon "nf-md-newspaper_variant_outline" :face 'nerd-icons-silver))
                  
                  ;; human body
                  ("eye" . ,(nerd-icons-codicon "nf-cod-eye" :face 'nerd-icons-blue))
                  ("eye_slash" . ,(nerd-icons-codicon "nf-cod-eye_closed" :face 'nerd-icons-red))
                  ("deaf" . ,(nerd-icons-faicon "nf-fa-deaf" :face 'nerd-icons-red))
                  ("blind" . ,(nerd-icons-faicon "nf-fa-blind" :face 'nerd-icons-red))
                  ("low-vision" . ,(nerd-icons-faicon "nf-fa-low_vision" :face 'nerd-icons-blue))
                  ("braille" . ,(nerd-icons-mdicon "nf-md-braille" :face 'nerd-icons-blue))
                  ("wheelchair" . ,(nerd-icons-mdicon "nf-md-wheelchair" :face 'nerd-icons-blue))
                  
                  ;; create
                  ("design" . ,(nerd-icons-mdicon "nf-md-palette" :face 'nerd-icons-blue))
                  ("paint" . ,(nerd-icons-faicon "nf-fa-paint_brush" :face 'nerd-icons-blue))
                  ("edit" . ,(nerd-icons-mdicon "nf-md-lead_pencil" :face 'nerd-icons-blue))
                  ("write" . ,(nerd-icons-mdicon "nf-md-lead_pencil" :face 'nerd-icons-blue))
                  ("writer" . ,(nerd-icons-mdicon "nf-md-typewriter" :face 'nerd-icons-blue))
                  
                  ;; Family
                  ("@family" . ,(nerd-icons-mdicon "nf-md-family_tree" :face 'nerd-icons-green))
                  
                  ;; Work
                  ("work" . ,(nerd-icons-faicon "nf-fa-black_tie" :face 'nerd-icons-dblue))
                  ("print" . ,(nerd-icons-mdicon "nf-md-printer" :face 'nerd-icons-blue))
                  ("business_trip" . ,(nerd-icons-mdicon "nf-md-bag_suitcase" :face 'nerd-icons-blue))
                  ("business_trip_briefcase" . ,(nerd-icons-codicon "nf-cod-briefcase" :face 'nerd-icons-blue))
                  ("business_trip_suitcase" . ,(nerd-icons-faicon "nf-fa-suitcase" :face 'nerd-icons-blue))
                  
                  ;; Company
                  ("users" . ,(nerd-icons-faicon "nf-fa-users" :face 'nerd-icons-blue))
                  ("marketing" . ,(nerd-icons-mdicon "nf-md-bullhorn" :face 'nerd-icons-blue))
                  
                  ;; Investing & Finance
                  ("accounting" . ,(nerd-icons-mdicon "nf-md-wallet_outline" :face 'nerd-icons-green))
                  ("finance" . ,(nerd-icons-mdicon "nf-md-calculator_variant" :face 'nerd-icons-blue))
                  ("stock" . ,(nerd-icons-mdicon "nf-md-chart_timeline_variant_shimmer" :face 'nerd-icons-blue))

                  ;; Philosophy
                  ("daoism" . ,(nerd-icons-mdicon "nf-md-yin_yang" :face 'nerd-icons-blue))

                  ;; Science
                  ("chemistry" . ,(nerd-icons-mdicon "nf-md-chemical_weapon" :face 'nerd-icons-green))
                  ("bacteria" . ,(nerd-icons-mdicon "nf-md-bacteria_outline" :face 'nerd-icons-green))

                  ;; Society
                  ("forest" . ,(nerd-icons-mdicon "nf-md-tree" :face 'nerd-icons-lgreen))
                  ("empire" . ,(nerd-icons-faicon "nf-fa-empire" :face 'nerd-icons-yellow))
                  ("global" . ,(nerd-icons-faicon "nf-fa-globe" :face 'nerd-icons-blue))))))

(defun org-tag-beautify-set-programming-tag-icons ()
  "Display programming tag as icon."
  (setq org-pretty-tags-surrogate-strings
        (append org-pretty-tags-surrogate-strings
                `(;; programming
                  ("programming" . ,(nerd-icons-mdicon "nf-md-developer_board" :face 'nerd-icons-lblue))
                  ("code" . ,(nerd-icons-codicon "nf-cod-code" :face 'nerd-icons-cyan-alt))
                  ("source_code" . ,(nerd-icons-codicon "nf-cod-file_code" :face 'nerd-icons-cyan))
                  ("bug" . ,(nerd-icons-codicon "nf-cod-bug" :face 'nerd-icons-red-alt))
                  ("vulnerability" . ,(nerd-icons-mdicon "nf-md-bug_check_outline" :face 'nerd-icons-red))
                  ("patch" . ,(nerd-icons-octicon "nf-oct-diff" :face 'nerd-icons-green))
                  ("diff" . ,(nerd-icons-codicon "nf-cod-diff" :face 'nerd-icons-red))
                  ("coding" . ,(nerd-icons-faicon "nf-fa-keyboard_o" :face 'nerd-icons-cyan-alt))
                  ("object_group" . ,(nerd-icons-faicon "nf-fa-object_group" :face 'nerd-icons-blue))
                  ("object_ungroup" . ,(nerd-icons-faicon "nf-fa-object_ungroup" :face 'nerd-icons-blue))
                  ("regex" . ,(nerd-icons-codicon "nf-cod-regex" :face 'nerd-icons-cyan-alt))
                  ("extension" . ,(nerd-icons-codicon "nf-cod-extensions" :face 'nerd-icons-blue))
                  ("vcs" . ,(nerd-icons-codicon "nf-cod-source_control" :face 'nerd-icons-blue))
                  ("vcs_branch" . ,(nerd-icons-mdicon "nf-md-source_branch" :face 'nerd-icons-blue))
                  ("vcs_commit" . ,(nerd-icons-mdicon "nf-md-source_commit" :face 'nerd-icons-blue))
                  ("vcs_fork" . ,(nerd-icons-mdicon "nf-md-source_fork" :face 'nerd-icons-blue))
                  ("vcs_merge" . ,(nerd-icons-mdicon "nf-md-source_merge" :face 'nerd-icons-blue))
                  ("vcs_pull" . ,(nerd-icons-mdicon "nf-md-source_pull" :face 'nerd-icons-blue))
                  ("vcs_branch_sync" . ,(nerd-icons-mdicon "nf-md-source_branch_sync" :face 'nerd-icons-blue))
                  ("git" . ,(nerd-icons-mdicon "nf-md-git" :face 'nerd-icons-orange))
                  ("compile" . ,(nerd-icons-mdicon "nf-md-cog_box" :face 'nerd-icons-blue))
                  ("command" . ,(nerd-icons-codicon "nf-cod-terminal_bash" :face 'nerd-icons-cyan))
                  ("debug" . ,(nerd-icons-codicon "nf-cod-debug_alt" :face 'nerd-icons-blue))
                  ("troubleshooting" . ,(nerd-icons-faicon "nf-fa-crosshairs" :face 'nerd-icons-blue-alt))
                  ("help" . ,(nerd-icons-mdicon "nf-md-help_circle_outline" :face 'nerd-icons-blue-alt))
                  
                  ;; database
                  ("database" . ,(nerd-icons-mdicon "nf-md-database" :face 'nerd-icons-blue))
                  ("database_schema" . ,(nerd-icons-mdicon "nf-md-file_table_box_outline" :face 'nerd-icons-blue))
                  ("database_catalog" . ,(nerd-icons-mdicon "nf-md-grid_large" :face 'nerd-icons-blue))
                  ("database_table" . ,(nerd-icons-mdicon "nf-md-table_large" :face 'nerd-icons-green))
                  ("database_view" . ,(nerd-icons-faicon "nf-fa-th" :face 'nerd-icons-blue))
                  ("database_index" . ,(nerd-icons-faicon "nf-fa-th_list" :face 'nerd-icons-blue))
                  ("database_sort" . ,(nerd-icons-mdicon "nf-md-sort_bool_ascending_variant" :face 'nerd-icons-blue-alt))
                  
                  ;; computer etc hardware
                  ("computer" . ,(nerd-icons-mdicon "nf-md-desktop_mac" :face 'nerd-icons-blue))
                  ("laptop" . ,(nerd-icons-mdicon "nf-md-laptop" :face 'nerd-icons-blue))
                  ("tablet" . ,(nerd-icons-mdicon "nf-md-tablet" :face 'nerd-icons-blue))
                  ("mobile" . ,(nerd-icons-octicon "nf-oct-device_mobile" :face 'nerd-icons-blue))
                  ("smartphone" . ,(nerd-icons-mdicon "nf-md-cellphone" :face 'nerd-icons-blue))
                  ("phone" . ,(nerd-icons-mdicon "nf-md-phone" :face 'nerd-icons-blue))
                  ("iPhone" . ,(nerd-icons-mdicon "nf-md-cellphone" :face 'nerd-icons-blue))
                  ("keyboard" . ,(nerd-icons-mdicon "nf-md-keyboard" :face 'nerd-icons-blue))
                  ("mouse" . ,(nerd-icons-mdicon "nf-md-mouse" :face 'nerd-icons-blue))
                  ;; ("Arduino" . ,())
                  ("Raspberry_Pi" . ,(nerd-icons-flicon "nf-linux-raspberry_pi" :face 'nerd-icons-lred))
                  ("PlatformIO" . ,(nerd-icons-sucicon "nf-seti-platformio" :face 'nerd-icons-orange))
                  ("hardware" . ,(nerd-icons-mdicon "nf-md-devices" :face 'nerd-icons-blue))
                  ("desktop_pc" . ,(nerd-icons-mdicon "nf-md-desktop_tower_monitor" :face 'nerd-icons-blue))
                  ("server" . ,(nerd-icons-mdicon "nf-md-server_network" :face 'nerd-icons-blue))
                  ("NAS" . ,(nerd-icons-mdicon "nf-md-nas" :face 'nerd-icons-blue))
                  ("robot" . ,(nerd-icons-mdicon "nf-md-robot_outline" :face 'nerd-icons-blue))
                  ("USB" . ,(nerd-icons-mdicon "nf-md-usb" :face 'nerd-icons-blue))
                  ("WiFi" . ,(nerd-icons-mdicon "nf-md-wifi" :face 'nerd-icons-blue))
                  ("bluetooth" . ,(nerd-icons-mdicon "nf-md-bluetooth" :face 'nerd-icons-blue))
                  ("microphone" . ,(nerd-icons-mdicon "nf-md-microphone" :face 'nerd-icons-blue))
                  ("router" . ,(nerd-icons-mdicon "nf-md-router_network" :face 'nerd-icons-blue))
                  ("TV" . ,(nerd-icons-mdicon "nf-md-television_classic" :face 'nerd-icons-blue))
                  ("scanner" . ,(nerd-icons-mdicon "nf-md-scanner" :face 'nerd-icons-blue))
                  ("fax" . ,(nerd-icons-mdicon "nf-md-fax" :face 'nerd-icons-blue))
                  ("disk" . ,(nerd-icons-mdicon "nf-md-harddisk" :face 'nerd-icons-blue))
                  ("microscope" . ,(nerd-icons-mdicon "nf-md-microscope" :face 'nerd-icons-blue))
                  ("telescope" . ,(nerd-icons-codicon "nf-cod-telescope" :face 'nerd-icons-blue))
                  ("save" . ,(nerd-icons-mdicon "nf-md-content_save_outline" :face 'nerd-icons-blue))
                  ("sync" . ,(nerd-icons-mdicon "nf-md-sync" :face 'nerd-icons-blue))
                  ("backup" . ,(nerd-icons-mdicon "nf-md-backup_restore" :face 'nerd-icons-blue))
                  ("restore" . ,(nerd-icons-mdicon "nf-md-backup_restore" :face 'nerd-icons-red))
                  ("undo" . ,(nerd-icons-mdicon "nf-md-undo_variant" :face 'nerd-icons-green))
                  
                  ;; network
                  ("network" . ,(nerd-icons-mdicon "nf-md-ip_network" :face 'nerd-icons-blue))
                  ("online" . ,(nerd-icons-mdicon "nf-md-check_network" :face 'nerd-icons-green))
                  ("offline" . ,(nerd-icons-mdicon "nf-md-close_network" :face 'nerd-icons-red))
                  ("CMCC" . ,(nerd-icons-codicon "nf-cod-radio_tower" :face 'nerd-icons-blue)) ; CMCC 中国移动
                  
                  ;; technology
                  ("virtual_reality" . ,(nerd-icons-mdicon "nf-md-virtual_reality" :face 'nerd-icons-blue))
                  
                  ;; system
                  ("shortcut" . ,(nerd-icons-mdicon "nf-md-keyboard_variant" :face 'nerd-icons-green))
                  ("keybinding" . ,(nerd-icons-mdicon "nf-md-keyboard_settings_outline" :face 'nerd-icons-blue))
                  ("universal-access" . ,(nerd-icons-faicon "nf-fa-universal_access" :face 'nerd-icons-blue))
                  
                  ;; softwares & applications
                  ("Emacs" . ,(nerd-icons-sucicon "nf-custom-emacs" :face 'nerd-icons-purple-alt))
                  ("Org_mode" . ,(nerd-icons-sucicon "nf-custom-orgmode" :face 'nerd-icons-dgreen))
                  ("Vim" . ,(nerd-icons-devicon "nf-dev-vim" :face 'nerd-icons-green))
                  ("VSCode" . ,(nerd-icons-mdicon "nf-md-microsoft_visual_studio_code" :face 'nerd-icons-blue-alt))
                  ("Firefox" . ,(nerd-icons-mdicon "nf-md-firefox" :face 'nerd-icons-orange))
                  ("Chromium" . ,(nerd-icons-faicon "nf-fa-chrome" :face 'nerd-icons-blue-alt))
                  ("Chrome" . ,(nerd-icons-faicon "nf-fa-chrome" :face 'nerd-icons-red))
                  ("Edge" . ,(nerd-icons-mdicon "nf-md-microsoft_edge" :face 'nerd-icons-blue))
                  ("Safari" . ,(nerd-icons-mdicon "nf-md-apple_safari" :face 'nerd-icons-blue))
                  ("terminal" . ,(nerd-icons-devicon "nf-dev-terminal" :face 'nerd-icons-green))
                  ("tmux" . ,(nerd-icons-codicon "nf-cod-terminal_tmux" :face 'nerd-icons-green))
                  ("REPL" . ,(nerd-icons-devicon "nf-dev-terminal_badge" :face 'nerd-icons-blue))
                  ("SSH" . ,(nerd-icons-mdicon "nf-md-ssh" :face 'nerd-icons-green))
                  ("powershell" . ,(nerd-icons-mdicon "nf-md-powershell" :face 'nerd-icons-blue))
                  ("dylib" . ,(nerd-icons-codicon "nf-cod-folder_library" :face 'nerd-icons-blue))
                  ("GDB" . ,(nerd-icons-codicon "nf-cod-debug_console" :face 'nerd-icons-orange))
                  ("Make" . ,(nerd-icons-sucicon "nf-seti-makefile" :face 'nerd-icons-red))
                  ("Finder" . ,(nerd-icons-mdicon "nf-md-apple_finder" :face 'nerd-icons-blue))
                  ("cloud" . ,(nerd-icons-mdicon "nf-md-cloud" :face 'nerd-icons-silver))
                  ("DevOps" . ,(nerd-icons-sucicon "nf-seti-pipeline" :face 'nerd-icons-blue))
                  ("package" . ,(nerd-icons-codicon "nf-cod-package" :face 'nerd-icons-orange))
                  ("container" . ,(nerd-icons-flicon "nf-linux-docker" :face 'nerd-icons-blue))
                  ("Docker" . ,(nerd-icons-flicon "nf-linux-docker" :face 'nerd-icons-blue))
                  ("Dockerfile" . ,(nerd-icons-flicon "nf-linux-docker" :face 'nerd-icons-blue))
                  ("Ansible" . ,(nerd-icons-mdicon "nf-md-ansible" :face 'nerd-icons-red))
                  ("Puppet" . ,(nerd-icons-sucicon "nf-custom-puppet" :face 'nerd-icons-purple))
                  ("Terraform" . ,(nerd-icons-sucicon "nf-seti-terraform" :face 'nerd-icons-blue))
                  ("Nix" . ,(nerd-icons-mdicon "nf-md-nix" :face 'nerd-icons-blue))
                  ("settings" . ,(nerd-icons-codicon "nf-cod-settings" :face 'nerd-icons-blue))
                  ("security" . ,(nerd-icons-mdicon "nf-md-security" :face 'nerd-icons-green))
                  ("hacker" . ,(nerd-icons-faicon "nf-fa-user_secret" :face 'nerd-icons-dsilver))
                  ("reverse_engineering" . ,(nerd-icons-octicon "nf-oct-file_binary" :face 'nerd-icons-green))
                  ("cracker" . ,(nerd-icons-faicon "nf-fa-user_secret" :face 'nerd-icons-red-alt))
                  ("forensic" . ,(nerd-icons-mdicon "nf-md-loupe" :face 'nerd-icons-blue))
                  ("computer_forensic" . ,(nerd-icons-mdicon "nf-md-text_box_search_outline" :face 'nerd-icons-blue))
                  ("Godot" . ,(nerd-icons-sucicon "nf-seti-godot" :face 'nerd-icons-blue))
                  ("Nginx" . ,(nerd-icons-devicon "nf-dev-nginx" :face 'nerd-icons-green))
                  ("font" . ,(nerd-icons-faicon "nf-fa-font" :face 'nerd-icons-dsilver))
                  ("Electron" . ,(nerd-icons-mdicon "nf-md-electron_framework" :face 'nerd-icons-green))
                  ("Xamarin" . ,(nerd-icons-mdicon "nf-md-xamarin" :face 'nerd-icons-blue))
                  ("Ionic" . ,(nerd-icons-sucicon "nf-seti-ionic" :face 'nerd-icons-blue))
                  ;; Adobe softwares
                  ("Adobe_Photoshop" . ,(nerd-icons-devicon "nf-dev-photoshop" :face 'nerd-icons-blue))
                  ("Adobe_Illustrator" . ,(nerd-icons-devicon "nf-dev-illustrator" :face 'nerd-icons-orange))
                  ("Blender" . ,(nerd-icons-mdicon "nf-md-blender_software" :face 'nerd-icons-orange))
                  ("CAD" . ,(nerd-icons-mdicon "nf-md-file_cad_box" :face 'nerd-icons-blue))
                  
                  ;; Systems
                  ("Linux" . ,(nerd-icons-devicon "nf-dev-linux" :face 'nerd-icons-silver))
                  ("Ubuntu_Linux" . ,(nerd-icons-flicon "nf-linux-ubuntu_inverse" :face 'nerd-icons-orange))
                  ("Arch_Linux" . ,(nerd-icons-flicon "nf-linux-archlinux" :face 'nerd-icons-blue))
                  ("Kali_Linux" . ,(nerd-icons-flicon "nf-linux-kali_linux" :face 'nerd-icons-blue))
                  ("Alpine_Linux" . ,(nerd-icons-flicon "nf-linux-alpine" :face 'nerd-icons-blue))
                  ("Gentoo_Linux" . ,(nerd-icons-flicon "nf-linux-gentoo" :face 'nerd-icons-purple))
                  ("Apple" . ,(nerd-icons-mdicon "nf-md-apple" :face 'nerd-icons-silver))
                  ("macOS" . ,(nerd-icons-mdicon "nf-md-apple_finder" :face 'nerd-icons-blue))
                  ("Windows" . ,(nerd-icons-mdicon "nf-md-microsoft_windows" :face 'nerd-icons-blue))
                  ("Android" . ,(nerd-icons-devicon "nf-dev-android" :face 'nerd-icons-green))
                  ("iOS" . ,(nerd-icons-mdicon "nf-md-apple_ios" :face 'nerd-icons-silver))
                  ("adb" . ,(nerd-icons-mdicon "nf-md-android" :face 'nerd-icons-green))
                  
                  ;; Programming Languages
                  ("Shell" . ,(nerd-icons-codicon "nf-cod-terminal_bash" :face 'nerd-icons-blue))
                  ("Shell_Script" . ,(nerd-icons-mdicon "nf-md-bash" :face 'nerd-icons-blue))
                  ;; ("LISP" . ,())
                  ;; ("Common_Lisp" . ,())
                  ("Emacs_Lisp" . ,(nerd-icons-icon-for-mode 'emacs-lisp-mode))
                  ("Clojure" . ,(nerd-icons-devicon "nf-dev-clojure" :face 'nerd-icons-green))
                  ("ClojureScript" . ,(nerd-icons-devicon "nf-dev-clojure_alt" :face 'nerd-icons-blue))
                  ;; ("Scheme" . ,())
                  ;; ("Racket" . ,())
                  ("Python" . ,(nerd-icons-mdicon "nf-md-language_python" :face 'nerd-icons-orange))
                  ("Haskell" . ,(nerd-icons-mdicon "nf-md-language_haskell" :face 'nerd-icons-purple))
                  ("Julia" . ,(nerd-icons-sucicon "nf-seti-julia" :face 'nerd-icons-red))
                  ("C" . ,(nerd-icons-mdicon "nf-md-language_c" :face 'nerd-icons-blue))
                  ("C++" . ,(nerd-icons-mdicon "nf-md-language_cpp" :face 'nerd-icons-blue))
                  ("C#" . ,(nerd-icons-mdicon "nf-md-language_csharp" :face 'nerd-icons-blue))
                  ("F#" . ,(nerd-icons-devicon "nf-dev-fsharp" :face 'nerd-icons-blue))
                  ("Java" . ,(nerd-icons-mdicon "nf-md-language_java" :face 'nerd-icons-blue))
                  ("Scala" . ,(nerd-icons-devicon "nf-dev-scala" :face 'nerd-icons-red))
                  ("Kotlin" . ,(nerd-icons-mdicon "nf-md-language_kotlin" :face 'nerd-icons-blue))
                  ("Go" . ,(nerd-icons-mdicon "nf-md-language_go" :face 'nerd-icons-blue))
                  ("Rust" . ,(nerd-icons-mdicon "nf-md-language_rust" :face 'nerd-icons-dsilver))
                  ("Swift" . ,(nerd-icons-mdicon "nf-md-language_swift" :face 'nerd-icons-orange))
                  ("R" . ,(nerd-icons-mdicon "nf-md-language_r" :face 'nerd-icons-blue))
                  ;; ("Octave" . ,())
                  ;; ("Matlab" . ,())
                  ;; ("Mathematica" . ,())
                  ;; ("Delphi" . ,())
                  ("OCaml" . ,(nerd-icons-sucicon "nf-seti-ocaml" :face 'nerd-icons-orange))
                  ("ReasonML" . ,(nerd-icons-sucicon "nf-seti-reasonml" :face 'nerd-icons-orange))
                  ("Elixir" . ,(nerd-icons-sucicon "nf-custom-elixir" :face 'nerd-icons-purple))
                  ("Fortran" . ,(nerd-icons-mdicon "nf-md-language_fortran" :face 'nerd-icons-orange))
                  ("Prolog" . ,(nerd-icons-devicon "nf-dev-prolog" :face 'nerd-icons-blue))
                  ("Erlang" . ,(nerd-icons-devicon "nf-dev-erlang" :face 'nerd-icons-blue))
                  ("Ruby" . ,(nerd-icons-mdicon "nf-md-language_ruby" :face 'nerd-icons-red-alt))
                  ("Ruby_on_Rails" . ,(nerd-icons-mdicon "nf-md-language_ruby_on_rails" :face 'nerd-icons-red))
                  ("PHP" . ,(nerd-icons-mdicon "nf-md-language_php" :face 'nerd-icons-blue))
                  ("Perl" . ,(nerd-icons-sucicon "nf-seti-perl" :face 'nerd-icons-blue))
                  ("Lua" . ,(nerd-icons-mdicon "nf-md-language_lua" :face 'nerd-icons-dblue))
                  ("Web" . ,(nerd-icons-mdicon "nf-md-web" :face 'nerd-icons-blue))
                  ("webpage" . ,(nerd-icons-codicon "nf-cod-preview" :face 'nerd-icons-blue))
                  ("UserScript" . ,(nerd-icons-mdicon "nf-md-script_text_outline" :face 'nerd-icons-blue))
                  ("JavaScript" . ,(nerd-icons-mdicon "nf-md-language_javascript" :face 'nerd-icons-orange))
                  ("nodejs" . ,(nerd-icons-mdicon "nf-md-nodejs" :face 'nerd-icons-green))
                  ("npm" . ,(nerd-icons-mdicon "nf-md-npm" :face 'nerd-icons-red))
                  ("TypeScript" . ,(nerd-icons-mdicon "nf-md-language_typescript" :face 'nerd-icons-blue))
                  ;; ("WebAssembly" . ,())
                  ("HTML" . ,(nerd-icons-mdicon "nf-md-language_html5" :face 'nerd-icons-orange))
                  ("HTML5" . ,(nerd-icons-mdicon "nf-md-language_html5" :face 'nerd-icons-orange))
                  ("CSS" . ,(nerd-icons-mdicon "nf-md-language_css3" :face 'nerd-icons-blue))
                  ("CSS3" . ,(nerd-icons-mdicon "nf-md-language_css3" :face 'nerd-icons-blue))
                  ("SVG" . ,(nerd-icons-mdicon "nf-md-svg" :face 'nerd-icons-blue))
                  ("SQL" . ,(nerd-icons-mdicon "nf-md-database_search_outline" :face 'nerd-icons-blue))
                  ("SQLite" . ,(nerd-icons-devicon "nf-dev-sqllite" :face 'nerd-icons-blue))
                  ("PostgreSQL" . ,(nerd-icons-devicon "nf-dev-postgresql" :face 'nerd-icons-blue))
                  ("Firebase" . ,(nerd-icons-mdicon "nf-md-firebase" :face 'nerd-icons-red))
                  ("TeX" . ,(nerd-icons-sucicon "nf-seti-tex" :face 'nerd-icons-blue))
                  ("LaTeX" . ,(nerd-icons-sucicon "nf-seti-tex" :face 'nerd-icons-dorange))
                  ("Hacklang" . ,(nerd-icons-sucicon "nf-seti-hacklang" :face 'nerd-icons-blue))
                  ;; ("Assembly" . ,())
                  ;; ("VHDL" . ,())
                  ;; ("Verilog" . ,())
                  
                  ;; Development
                  ("API" . ,(nerd-icons-mdicon "nf-md-api" :face 'nerd-icons-lorange))
                  ("AWS" . ,(nerd-icons-mdicon "nf-md-aws" :face 'nerd-icons-orange))
                  ("JSON" . ,(nerd-icons-mdicon "nf-md-code_json" :face 'nerd-icons-yellow))
                  ("GraphQL" . ,(nerd-icons-mdicon "nf-md-graphql" :face 'nerd-icons-lred))
                  ("Flask" . ,(nerd-icons-mdicon "nf-md-flask" :face 'nerd-icons-blue))
                  ("webpack" . ,(nerd-icons-mdicon "nf-md-webpack" :face 'nerd-icons-lblue))
                  ("React" . ,(nerd-icons-devicon "nf-dev-react" :face 'nerd-icons-lblue))
                  ("Vue" . ,(nerd-icons-mdicon "nf-md-vuejs" :face 'nerd-icons-green))
                  ("Svelte" . ,(nerd-icons-sucicon "nf-seti-svelte" :face 'nerd-icons-lred))
                  ("qrcode" . ,(nerd-icons-mdicon "nf-md-qrcode" :face 'nerd-icons-blue))
                  ("barcode" . ,(nerd-icons-mdicon "nf-md-barcode" :face 'nerd-icons-blue))
                  ("AI" . ,(nerd-icons-mdicon "nf-md-head_snowflake_outline" :face 'nerd-icons-blue))
                  
                  ;; Testing
                  ("testing" . ,(nerd-icons-mdicon "nf-md-test_tube" :face 'nerd-icons-blue))
                  ("ab_testing" . ,(nerd-icons-mdicon "nf-md-ab_testing" :face 'nerd-icons-blue))
                  
                  ;; Project
                  ("@project" . ,(nerd-icons-codicon "nf-cod-project" :face 'nerd-icons-blue))
                  
                  ;; Open Source
                  ("GNU" . ,(nerd-icons-devicon "nf-dev-gnu" :face 'nerd-icons-silver))
                  ("license" . ,(nerd-icons-mdicon "nf-md-license" :face 'nerd-icons-green))
                  ("creative-commons" . ,(nerd-icons-mdicon "nf-md-creative_commons" :face 'nerd-icons-silver))
                  
                  ;; Business
                  ("copyright" . ,(nerd-icons-mdicon "nf-md-copyright" :face 'nerd-icons-blue))
                  ("trademark" . ,(nerd-icons-mdicon "nf-md-trademark" :face 'nerd-icons-blue))
                  ("registered" . ,(nerd-icons-mdicon "nf-md-registered_trademark" :face 'nerd-icons-blue))
                  ))))

(defun org-tag-beautify-set-internet-company-tag-icons ()
  "Display internet company name tag as icon."
  (setq org-pretty-tags-surrogate-strings
        (append org-pretty-tags-surrogate-strings
                `(("Internet" . ,(nerd-icons-codicon "nf-cod-globe" :face 'nerd-icons-blue))
                  ("Google" . ,(nerd-icons-mdicon "nf-md-google" :face 'nerd-icons-red))
                  ("Microsoft" . ,(nerd-icons-mdicon "nf-md-microsoft" :face 'nerd-icons-lblue))
                  ("Facebook" . ,(nerd-icons-faicon "nf-fa-facebook_official" :face 'nerd-icons-dblue))
                  ("Twitter" . ,(nerd-icons-mdicon "nf-md-twitter" :face 'nerd-icons-lblue))
                  ("Amazon" . ,(nerd-icons-faicon "nf-fa-amazon" :face 'nerd-icons-orange))
                  ("Yahoo" . ,(nerd-icons-mdicon "nf-md-yahoo" :face 'nerd-icons-orange))
                  ("Reddit" . ,(nerd-icons-mdicon "nf-md-reddit" :face 'nerd-icons-red))
                  ("Mozilla" . ,(nerd-icons-devicon "nf-dev-mozilla" :face 'nerd-icons-red))
                  ("GitHub" . ,(nerd-icons-mdicon "nf-md-github" :face 'nerd-icons-dsilver))
                  ("GitLab" . ,(nerd-icons-mdicon "nf-md-gitlab" :face 'nerd-icons-orange))
                  ("Bitbucket" . ,(nerd-icons-mdicon "nf-md-bitbucket" :face 'nerd-icons-blue))
                  ("stack_exchange" . ,(nerd-icons-mdicon "nf-md-stack_exchange" :face 'nerd-icons-lblue))
                  ("stack_overflow" . ,(nerd-icons-mdicon "nf-md-stack_overflow" :face 'nerd-icons-orange))
                  ("wikipedia" . ,(nerd-icons-mdicon "nf-md-wikipedia" :face 'nerd-icons-dsilver))
                  ("mediawiki" . ,(nerd-icons-mdicon "nf-md-library_outline" :face 'nerd-icons-silver))
                  ("YouTube" . ,(nerd-icons-mdicon "nf-md-youtube" :face 'nerd-icons-red-alt))
                  ("LinkedIn" . ,(nerd-icons-mdicon "nf-md-linkedin" :face 'nerd-icons-blue))
                  ("Instagram" . ,(nerd-icons-mdicon "nf-md-instagram" :face 'nerd-icons-orange))
                  ("Dribbble" . ,(nerd-icons-faicon "nf-fa-dribbble" :face 'nerd-icons-dpink))
                  ("Dropbox" . ,(nerd-icons-mdicon "nf-md-dropbox" :face 'nerd-icons-lblue))
                  ("Baidu" . ,(nerd-icons-mdicon "nf-md-paw" :face 'nerd-icons-blue))
                  ("Tencent" . ,(nerd-icons-mdicon "nf-md-qqchat" :face 'nerd-icons-blue))
                  ("QQ" . ,(nerd-icons-mdicon "nf-md-qqchat" :face 'nerd-icons-blue))
                  ("weixin" . ,(nerd-icons-mdicon "nf-md-wechat" :face 'nerd-icons-green))
                  ("wechat" . ,(nerd-icons-mdicon "nf-md-wechat" :face 'nerd-icons-green))
                  ("weibo" . ,(nerd-icons-mdicon "nf-md-sina_weibo" :face 'nerd-icons-red))
                  ("whatsapp" . ,(nerd-icons-mdicon "nf-md-whatsapp" :face 'nerd-icons-green))
                  ("pocket" . ,(nerd-icons-faicon "nf-fa-get_pocket" :face 'nerd-icons-red))))))

(defun org-tag-beautify-set-countries-tag-icons ()
  "Display countries name tag as flag icon."
  (if-let ((dir (concat org-tag-beautify-data-dir "countries/"))
           (available? (file-exists-p dir)))
      (setq org-pretty-tags-surrogate-strings
            (append org-pretty-tags-surrogate-strings
                    `(("afghanistan" . ,(create-image (concat dir "afghanistan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("aland_islands" . ,(create-image (concat dir "aland-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("albania" . ,(create-image (concat dir "albania.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("algeria" . ,(create-image (concat dir "algeria.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("american_samoa" . ,(create-image (concat dir "american-samoa.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("andorra" . ,(create-image (concat dir "andorra.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("angola" . ,(create-image (concat dir "angola.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("anguilla" . ,(create-image (concat dir "anguilla.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("antigua_and_barbuda" . ,(create-image (concat dir "antigua-and-barbuda.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("argentina" . ,(create-image (concat dir "argentina.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("armenia" . ,(create-image (concat dir "armenia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("aruba" . ,(create-image (concat dir "aruba.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("australia" . ,(create-image (concat dir "australia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("austria" . ,(create-image (concat dir "austria.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("azerbaijan" . ,(create-image (concat dir "azerbaijan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("azores_islands" . ,(create-image (concat dir "azores-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bahamas" . ,(create-image (concat dir "bahamas.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bahrain" . ,(create-image (concat dir "bahrain.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("balearic_islands" . ,(create-image (concat dir "balearic-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bangladesh" . ,(create-image (concat dir "bangladesh.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("barbados" . ,(create-image (concat dir "barbados.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("basque_country" . ,(create-image (concat dir "basque-country.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("belarus" . ,(create-image (concat dir "belarus.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("belgium" . ,(create-image (concat dir "belgium.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("belize" . ,(create-image (concat dir "belize.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("benin" . ,(create-image (concat dir "benin.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bermuda" . ,(create-image (concat dir "bermuda.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bhutan" . ,(create-image (concat dir "bhutan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bolivia" . ,(create-image (concat dir "bolivia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bonaire" . ,(create-image (concat dir "bonaire.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bosnia_and_herzegovina" . ,(create-image (concat dir "bosnia-and-herzegovina.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("botswana" . ,(create-image (concat dir "botswana.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("brazil" . ,(create-image (concat dir "brazil.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("brunei" . ,(create-image (concat dir "brunei.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("bulgaria" . ,(create-image (concat dir "bulgaria.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("burkina_faso" . ,(create-image (concat dir "burkina-faso.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("burundi" . ,(create-image (concat dir "burundi.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cambodia" . ,(create-image (concat dir "cambodia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cameroon" . ,(create-image (concat dir "cameroon.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("canada" . ,(create-image (concat dir "canada.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("canary_islands" . ,(create-image (concat dir "canary-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cape_verde" . ,(create-image (concat dir "cape-verde.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cayman_islands" . ,(create-image (concat dir "cayman-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("central_african_republic" . ,(create-image (concat dir "central-african-republic.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ceuta" . ,(create-image (concat dir "ceuta.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("chad" . ,(create-image (concat dir "chad.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("chile" . ,(create-image (concat dir "chile.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("china" . ,(create-image (concat dir "china.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("christmas_island" . ,(create-image (concat dir "christmas-island.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cocos_island" . ,(create-image (concat dir "cocos-island.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("colombia" . ,(create-image (concat dir "colombia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("comoros" . ,(create-image (concat dir "comoros.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cook_islands" . ,(create-image (concat dir "cook-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("corsica" . ,(create-image (concat dir "corsica.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("costa_rica" . ,(create-image (concat dir "costa-rica.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("croatia" . ,(create-image (concat dir "croatia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cuba" . ,(create-image (concat dir "cuba.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("curacao" . ,(create-image (concat dir "curacao.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("cyprus" . ,(create-image (concat dir "cyprus.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("czech_republic" . ,(create-image (concat dir "czech-republic.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("democratic_republic_of_congo" . ,(create-image (concat dir "democratic-republic-of-congo.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("denmark" . ,(create-image (concat dir "denmark.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("djibouti" . ,(create-image (concat dir "djibouti.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("dominica" . ,(create-image (concat dir "dominica.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("dominican_republic" . ,(create-image (concat dir "dominican-republic.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("east_timor" . ,(create-image (concat dir "east-timor.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ecuador" . ,(create-image (concat dir "ecuador.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("egypt" . ,(create-image (concat dir "egypt.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("el_salvador" . ,(create-image (concat dir "el-salvador.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("england" . ,(create-image (concat dir "england.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("equatorial_guinea" . ,(create-image (concat dir "equatorial-guinea.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("eritrea" . ,(create-image (concat dir "eritrea.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("estonia" . ,(create-image (concat dir "estonia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ethiopia" . ,(create-image (concat dir "ethiopia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("european_union" . ,(create-image (concat dir "european-union.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("falkland_islands" . ,(create-image (concat dir "falkland-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("faroe_islands" . ,(create-image (concat dir "faroe-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("fiji" . ,(create-image (concat dir "fiji.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("finland" . ,(create-image (concat dir "finland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("france" . ,(create-image (concat dir "france.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("french_polynesia" . ,(create-image (concat dir "french-polynesia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("gabon" . ,(create-image (concat dir "gabon.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("galapagos_islands" . ,(create-image (concat dir "galapagos-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("gambia" . ,(create-image (concat dir "gambia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("georgia" . ,(create-image (concat dir "georgia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("germany" . ,(create-image (concat dir "germany.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ghana" . ,(create-image (concat dir "ghana.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("gibraltar" . ,(create-image (concat dir "gibraltar.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("greece" . ,(create-image (concat dir "greece.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("greenland" . ,(create-image (concat dir "greenland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("grenada" . ,(create-image (concat dir "grenada.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("guam" . ,(create-image (concat dir "guam.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("guatemala" . ,(create-image (concat dir "guatemala.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("guernsey" . ,(create-image (concat dir "guernsey.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("guinea_bissau" . ,(create-image (concat dir "guinea-bissau.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("guinea" . ,(create-image (concat dir "guinea.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("haiti" . ,(create-image (concat dir "haiti.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("hawaii" . ,(create-image (concat dir "hawaii.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("honduras" . ,(create-image (concat dir "honduras.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("hong_kong" . ,(create-image (concat dir "hong-kong.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("hungary" . ,(create-image (concat dir "hungary.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("iceland" . ,(create-image (concat dir "iceland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("india" . ,(create-image (concat dir "india.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("indonesia" . ,(create-image (concat dir "indonesia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("iran" . ,(create-image (concat dir "iran.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("iraq" . ,(create-image (concat dir "iraq.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ireland" . ,(create-image (concat dir "ireland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("isle_of_man" . ,(create-image (concat dir "isle-of-man.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("israel" . ,(create-image (concat dir "israel.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("italy" . ,(create-image (concat dir "italy.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ivory_coast" . ,(create-image (concat dir "ivory-coast.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("jamaica" . ,(create-image (concat dir "jamaica.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("japan" . ,(create-image (concat dir "japan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("jersey" . ,(create-image (concat dir "jersey.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("jordan" . ,(create-image (concat dir "jordan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("kazakhstan" . ,(create-image (concat dir "kazakhstan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("kenya" . ,(create-image (concat dir "kenya.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("kiribati" . ,(create-image (concat dir "kiribati.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("kosovo" . ,(create-image (concat dir "kosovo.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("kuwait" . ,(create-image (concat dir "kuwait.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("kyrgyzstan" . ,(create-image (concat dir "kyrgyzstan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("laos" . ,(create-image (concat dir "laos.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("latvia" . ,(create-image (concat dir "latvia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("lebanon" . ,(create-image (concat dir "lebanon.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("lesotho" . ,(create-image (concat dir "lesotho.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("liberia" . ,(create-image (concat dir "liberia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("libya" . ,(create-image (concat dir "libya.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("liechtenstein" . ,(create-image (concat dir "liechtenstein.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("lithuania" . ,(create-image (concat dir "lithuania.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("luxembourg" . ,(create-image (concat dir "luxembourg.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("macao" . ,(create-image (concat dir "macao.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("madagascar" . ,(create-image (concat dir "madagascar.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("madeira" . ,(create-image (concat dir "madeira.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("malawi" . ,(create-image (concat dir "malawi.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("malaysia" . ,(create-image (concat dir "malaysia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("maldives" . ,(create-image (concat dir "maldives.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("mali" . ,(create-image (concat dir "mali.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("malta" . ,(create-image (concat dir "malta.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("marshall_island" . ,(create-image (concat dir "marshall-island.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("martinique" . ,(create-image (concat dir "martinique.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("mauritania" . ,(create-image (concat dir "mauritania.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("mauritius" . ,(create-image (concat dir "mauritius.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("melilla" . ,(create-image (concat dir "melilla.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("mexico" . ,(create-image (concat dir "mexico.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("micronesia" . ,(create-image (concat dir "micronesia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("moldova" . ,(create-image (concat dir "moldova.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("monaco" . ,(create-image (concat dir "monaco.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("mongolia" . ,(create-image (concat dir "mongolia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("montenegro" . ,(create-image (concat dir "montenegro.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("montserrat" . ,(create-image (concat dir "montserrat.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("morocco" . ,(create-image (concat dir "morocco.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("mozambique" . ,(create-image (concat dir "mozambique.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("myanmar" . ,(create-image (concat dir "myanmar.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("namibia" . ,(create-image (concat dir "namibia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("nauru" . ,(create-image (concat dir "nauru.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("nepal" . ,(create-image (concat dir "nepal.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("netherlands" . ,(create-image (concat dir "netherlands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("new_zealand" . ,(create-image (concat dir "new-zealand.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("nicaragua" . ,(create-image (concat dir "nicaragua.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("niger" . ,(create-image (concat dir "niger.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("nigeria" . ,(create-image (concat dir "nigeria.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("niue" . ,(create-image (concat dir "niue.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("norfolk_island" . ,(create-image (concat dir "norfolk-island.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("north_korea" . ,(create-image (concat dir "north-korea.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("northen_cyprus" . ,(create-image (concat dir "northen-cyprus.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("northern_marianas_islands" . ,(create-image (concat dir "northern-marianas-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("norway" . ,(create-image (concat dir "norway.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("oman" . ,(create-image (concat dir "oman.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("orkney_islands" . ,(create-image (concat dir "orkney-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ossetia" . ,(create-image (concat dir "ossetia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("otan" . ,(create-image (concat dir "otan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("pakistan" . ,(create-image (concat dir "pakistan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("palau" . ,(create-image (concat dir "palau.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("palestine" . ,(create-image (concat dir "palestine.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("panama" . ,(create-image (concat dir "panama.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("papua_new_guinea" . ,(create-image (concat dir "papua-new-guinea.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("peru" . ,(create-image (concat dir "peru.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("philippines" . ,(create-image (concat dir "philippines.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("pitcairn_islands" . ,(create-image (concat dir "pitcairn-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("poland" . ,(create-image (concat dir "poland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("portugal" . ,(create-image (concat dir "portugal.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("puerto_rico" . ,(create-image (concat dir "puerto-rico.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("qatar" . ,(create-image (concat dir "qatar.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("rapa_nui" . ,(create-image (concat dir "rapa-nui.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("republic_of_macedonia" . ,(create-image (concat dir "republic-of-macedonia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("republic_of_the_congo" . ,(create-image (concat dir "republic-of-the-congo.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("romania" . ,(create-image (concat dir "romania.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("russia" . ,(create-image (concat dir "russia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("rwanda" . ,(create-image (concat dir "rwanda.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("saba_island" . ,(create-image (concat dir "saba-island.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sahrawi_arab_democratic_republic" . ,(create-image (concat dir "sahrawi-arab-democratic-republic.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("saint_kitts_and_nevis" . ,(create-image (concat dir "saint-kitts-and-nevis.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("samoa" . ,(create-image (concat dir "samoa.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("san_marino" . ,(create-image (concat dir "san-marino.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sao_tome_and_principe" . ,(create-image (concat dir "sao-tome-and-principe.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sardinia" . ,(create-image (concat dir "sardinia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("saudi_arabia" . ,(create-image (concat dir "saudi-arabia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("scotland" . ,(create-image (concat dir "scotland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("senegal" . ,(create-image (concat dir "senegal.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("serbia" . ,(create-image (concat dir "serbia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("seychelles" . ,(create-image (concat dir "seychelles.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sicily" . ,(create-image (concat dir "sicily.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sierra_leone" . ,(create-image (concat dir "sierra-leone.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("singapore" . ,(create-image (concat dir "singapore.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sint_eustatius" . ,(create-image (concat dir "sint-eustatius.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sint_maarten" . ,(create-image (concat dir "sint-maarten.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("slovakia" . ,(create-image (concat dir "slovakia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("slovenia" . ,(create-image (concat dir "slovenia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("solomon_islands" . ,(create-image (concat dir "solomon-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("somalia" . ,(create-image (concat dir "somalia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("somaliland" . ,(create-image (concat dir "somaliland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("south_africa" . ,(create-image (concat dir "south-africa.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("south_korea" . ,(create-image (concat dir "south-korea.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("south_sudan" . ,(create-image (concat dir "south-sudan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("spain" . ,(create-image (concat dir "spain.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sri_lanka" . ,(create-image (concat dir "sri-lanka.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("st_barts" . ,(create-image (concat dir "st-barts.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("st_lucia" . ,(create-image (concat dir "st-lucia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("st_vincent_and_the_grenadines" . ,(create-image (concat dir "st-vincent-and-the-grenadines.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sudan" . ,(create-image (concat dir "sudan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("suriname" . ,(create-image (concat dir "suriname.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("swaziland" . ,(create-image (concat dir "swaziland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("sweden" . ,(create-image (concat dir "sweden.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("switzerland" . ,(create-image (concat dir "switzerland.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("syria" . ,(create-image (concat dir "syria.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("taiwan" . ,(create-image (concat dir "taiwan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("tajikistan" . ,(create-image (concat dir "tajikistan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("tanzania" . ,(create-image (concat dir "tanzania.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("thailand" . ,(create-image (concat dir "thailand.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("tibet" . ,(create-image (concat dir "tibet.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("togo" . ,(create-image (concat dir "togo.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("tokelau" . ,(create-image (concat dir "tokelau.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("tonga" . ,(create-image (concat dir "tonga.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("transnistria" . ,(create-image (concat dir "transnistria.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("trinidad_and_tobago" . ,(create-image (concat dir "trinidad-and-tobago.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("tubalu" . ,(create-image (concat dir "tubalu.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("tunisia" . ,(create-image (concat dir "tunisia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("turkey" . ,(create-image (concat dir "turkey.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("turkmenistan" . ,(create-image (concat dir "turkmenistan.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("turks_and_caicos" . ,(create-image (concat dir "turks-and-caicos.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("uganda" . ,(create-image (concat dir "uganda.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("ukraine" . ,(create-image (concat dir "ukraine.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("united_arab_emirates" . ,(create-image (concat dir "united-arab-emirates.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("united_kingdom" . ,(create-image (concat dir "united-kingdom.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("united_nations" . ,(create-image (concat dir "united-nations.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("united_states_of_america" . ,(create-image (concat dir "united-states-of-america.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("uruguay" . ,(create-image (concat dir "uruguay.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("uzbekistan" . ,(create-image (concat dir "uzbekistn.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("vanuatu" . ,(create-image (concat dir "vanuatu.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("vatican_city" . ,(create-image (concat dir "vatican-city.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("venezuela" . ,(create-image (concat dir "venezuela.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("vietnam" . ,(create-image (concat dir "vietnam.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("virgin_islands" . ,(create-image (concat dir "virgin-islands.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("singapore" . ,(create-image (concat dir "singapore.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("yemen" . ,(create-image (concat dir "yemen.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("zambia" . ,(create-image (concat dir "zambia.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width))
                      ("zimbabwe" . ,(create-image (concat dir "zimbabwe.png") nil nil :ascent 'center :height org-tag-beautify-icon-height :width org-tag-beautify-icon-width)))))))

(defun org-tag-beautify-set-unicode-tag-icons ()
  "Display tag as Unicode emoji."
  (setq org-pretty-tags-surrogate-strings
        (append org-pretty-tags-surrogate-strings
                `(("DIY" . "🧰") ("gene" . "🧬") ("DNA" . "🧬") ("RNA" . "🧬")))))

;;======================== auto add tags based on `org-attach' file types. ========================
(defvar org-attach-attach--smart-tags-alist
  '(;; video formats
    ("mp4" ("video")) ("mkv" ("video")) ("mov" ("video")) ("webm" ("video")) ("flv" ("video")) ("rmvb" ("video")) ("avi" ("video"))
    ;; audio formats
    ("mp3" ("audio")) ("m4a" ("audio")) ("opus" ("audio"))
    ;; image formats
    ;; ("png" ("image")) ("jpg" ("image")) ("jpeg" ("image")) ("webp" ("image"))
    ("gif" ("gif"))
    ;; document file types
    ("org" ("Org_mode")) ("md" ("Markdown")) ("txt" ("document"))
    ("pdf" ("pdf")) ("doc" ("word")) ("docx" ("word")) ("xls" ("excel")) ("ppt" ("powerpoint"))
    ("epub" ("book")) ("mobi" ("book")) ("azw3" ("book"))
    ("cbr" ("comic")) ("cbz" ("comic")) ("cb7" ("comic"))
    ("zip" ("archive_file")) ("rar" ("archive_file")) ("tar" ("archive_file")) ("tar.gz" ("archive_file")) ("tar.bz2" ("archive_file"))
    ;; source code file formats
    ("py" ("Python")) ("rb" ("Ruby"))
    ("el" ("Emacs_Lisp")) ("cl" ("Common_Lisp")) ("clj" ("Clojure")) ("cljs" ("ClojureScript"))
    ("js" ("JavaScript")) ("html" ("HTML")) ("css" ("CSS"))
    ("java" ("Java")) ("c" ("C")) ("cpp" ("cpp"))
    )
  "An alist of file extension and tag name pairs.")

(defun org-attach-attach--auto-add-smart-tag (origin-func file &optional visit-dir method)
  "An advice function which auto add smart Org tag based on `org-attach' command attached file format."
  (apply origin-func file visit-dir method)
  (let* ((file (substring-no-properties file))
         (extension (downcase (file-name-extension file)))
         (tags-list (cadr (assoc extension org-attach-attach--smart-tags-alist))))
    (save-excursion
      (org-back-to-heading)
      ;; append `tags-list' to original tags list and set the new Org tags list.
      (let* ((orig-tags (mapcar 'substring-no-properties (org-get-tags (point) 'local)))
             (new-tags-list (cl-remove-duplicates (append tags-list orig-tags)
                                                  :test (lambda (x y) (or (null y) (equal x y)))
                                                  :from-end t)))
        (org-set-tags new-tags-list)))))

(defun org-tag-beautify-auto-smart-tag-enable ()
  "Enable auto add tags based on `org-attach-commands' attached file types."
  (when org-tag-beautify-auto-add-tags
    ;; for [C-c C-a] `org-attach-commands'
    (advice-add 'org-attach-attach :around #'org-attach-attach--auto-add-smart-tag)))

(defun org-tag-beautify-auto-smart-tag-disable ()
  "Disable auto add tags."
  (advice-remove 'org-attach-attach #'org-attach-attach--auto-add-smart-tag))

;;========================================== org-tag-alist ==========================================

(defun org-tag-beautify-append-org-tags-alist--with-org-pretty-tags ()
  "Append `org-pretty-tags-surrogate-strings' tags to `org-tag-alist' for `org-set-tags-command' completion."
  (setq org-tag-alist
        (append org-tag-alist
                (append
                 '((:startgrouptag)) '(("icons"))
                 '((:grouptags)) (mapcar 'list (mapcar 'car org-pretty-tags-surrogate-strings))
                 '((:endgrouptag))))))

(org-tag-beautify-append-org-tags-alist--with-org-pretty-tags)

(defun org-tag-beautify-append-org-tags-alist--with-nerd-icons ()
  "Append `nerd-icons' icon names into the `org-tag-alist' for `org-set-tags-command' completion."
  (let ((icon-names (mapcar
                     'org-tag-beautify--nerd-icons-get-icon-name
                     org-tag-beautify--nerd-icons-icons-list)))
    (setq org-tag-alist
          (append org-tag-alist
                  `((:startgrouptag)
                    ("@nerd-icons")
                    (:grouptags)
                    ,@(mapcar 'list icon-names)
                    (:endgrouptag))))))

;;; NOTE: Don't enable this because nerd-icons icon names are not valid Org tags.
;; (org-tag-beautify-append-org-tags-alist--with-nerd-icons)

;;============================================ minor mode ===========================================
;;;###autoload
(defun org-tag-beautify-enable ()
  "Enable `org-tag-beautify'."
  (if org-tag-beautify-auto-icons
      (progn
        ;; add hardcoded (tag . icon) pair bindings to
        ;; `org-pretty-tags-surrogate-strings' for
        ;; `org-tag-beautify--find-tag-icon' query.
        (org-tag-beautify-set-common-tag-icons)
        (org-tag-beautify-set-programming-tag-icons)
        (org-tag-beautify-set-internet-company-tag-icons)
        (org-tag-beautify-set-countries-tag-icons)
        (org-tag-beautify-set-unicode-tag-icons)
        
        (org-tag-beautify-display-icon-refresh-all)
        (add-hook 'org-mode-hook #'org-tag-beautify-display-icon-refresh-all)
        (add-hook 'org-after-tags-change-hook #'org-tag-beautify-display-icon-refresh-headline)
        ;; (add-hook 'org-ctrl-c-ctrl-c-hook #'org-tag-beautify-display-icon-refresh-headline)
        )
    (progn
      (org-tag-beautify-set-common-tag-icons)
      (org-tag-beautify-set-programming-tag-icons)
      (org-tag-beautify-set-internet-company-tag-icons)
      (org-tag-beautify-set-countries-tag-icons)
      (org-tag-beautify-set-unicode-tag-icons)
      (org-pretty-tags-global-mode 1)
      (org-tag-beautify-auto-smart-tag-enable))))

;;;###autoload
(defun org-tag-beautify-disable ()
  "Disable `org-tag-beautify'."
  (if org-tag-beautify-auto-icons
      (progn
        (org-tag-beautify-delete-overlays)
        (remove-hook 'org-mode-hook #'org-tag-beautify-display-icon-refresh-all)
        (remove-hook 'org-after-tags-change-hook #'org-tag-beautify-display-icon-refresh-headline)
        ;; (remove-hook 'org-ctrl-c-ctrl-c-hook #'org-tag-beautify-display-icon-refresh-headline)
        )
    (progn
      (setq org-pretty-tags-surrogate-strings org-tag-beautify--surrogate-strings-original)
      (org-pretty-tags-global-mode -1)
      (org-tag-beautify-auto-smart-tag-disable))))

;;;###autoload
(define-minor-mode org-tag-beautify-mode
  "A minor mode that beautify Org tags with icons and images."
  :init-value nil
  :lighter nil
  :group 'org-tag-beautify
  :global t
  (if org-tag-beautify-mode
      (org-tag-beautify-enable)
    (org-tag-beautify-disable)))



(provide 'org-tag-beautify)

;;; org-tag-beautify.el ends here
