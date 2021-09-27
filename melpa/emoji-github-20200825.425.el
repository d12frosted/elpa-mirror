;;; emoji-github.el --- Display list of GitHub's emoji.  (cheat sheet)  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-03-05 10:58:18

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Display list of GitHub's emoji.  (cheat sheet)
;; Keyword: list github emoji display handy
;; Version: 0.2.3
;; Package-Version: 20200825.425
;; Package-Commit: 23a0cf469999854fa681d02e3122840864fd4c65
;; Package-Requires: ((emacs "24.4") (emojify "1.0") (request "0.3.0"))
;; URL: https://github.com/jcs-elpa/emoji-github

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Display list of GitHub's emoji.  (cheat sheet)
;;

;;; Code:

(require 'subr-x)
(require 'tabulated-list)

(require 'emojify)
(require 'request)

(defgroup emoji-github nil
  "Display list of GitHub's emoji.  (cheat sheet)"
  :prefix "emoji-github-"
  :group 'convenience
  :group 'tools
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/emoji-github"))

(defcustom emoji-github-columns 3
  "Columns to display in each row."
  :type 'integer
  :group 'emoji-github)

(defconst emoji-github--buffer-name "*GitHub Emoji*"
  "Name of the GitHub emoji buffer.")

(defconst emoji-github--api-url "https://api.github.com/emojis"
  "Store GitHub emoji's URL.")

(defconst emoji-github--constant-list
  '(;; --- People -----------------------------------------------------------
    "##==-- People --==##"
    "bowtie" "smile" "laughing"
    "blush" "smiley" "relaxed"
    "smirk" "heart_eyes" "kissing_heart"
    "kissing_closed_eyes" "flushed" "relieved"
    "satisfied" "grin" "wink"
    "stuck_out_tongue_winking_eye" "stuck_out_tongue_closed_eyes" "grinning"
    "kissing" "kissing_smiling_eyes" "stuck_out_tongue"
    "sleeping" "worried" "frowning"
    "anguished" "open_mouth" "grimacing"
    "confused" "hushed" "expressionless"
    "unamused" "sweat_smile" "sweat"
    "disappointed_relieved" "weary" "pensive"
    "disappointed" "confounded" "fearful"
    "cold_sweat" "persevere" "cry"
    "sob" "joy" "astonished"
    "scream" "neckbeard" "tired_face"
    "angry" "rage" "triumph"
    "sleepy" "yum" "mask"
    "sunglasses" "dizzy_face" "imp"
    "smiling_imp" "neutral_face" "no_mouth"
    "innocent" "alien" "yellow_heart"
    "blue_heart" "purple_heart" "heart"
    "green_heart" "broken_heart" "heartbeat"
    "heartpulse" "two_hearts" "revolving_hearts"
    "cupid" "sparkling_heart" "sparkles"
    "star" "star2" "dizzy"
    "boom" "collision" "anger"
    "exclamation" "question" "grey_exclamation"
    "grey_question" "zzz" "dash"
    "sweat_drops" "notes" "musical_note"
    "fire" "hankey" "poop"
    "shit" "+1" "thumbsup"
    "-1" "thumbsdown" "ok_hand"
    "punch" "facepunch" "fist"
    "v" "wave" "hand"
    "raised_hand" "open_hands" "point_up"
    "raised_hands" "pray" "point_up_2"
    "clap" "muscle" "metal"
    "fu" "walking" "runner"
    "running" "couple" "family"
    "two_men_holding_hands" "two_women_holding_hands" "dancer"
    "dancers" "ok_woman" "no_good"
    "information_desk_person" "raising_hand" "bride_with_veil"
    "person_with_pouting_face" "person_frowning" "bow"
    "couplekiss" "couple_with_heart" "massage"
    "haircut" "nail_care" "boy"
    "girl" "woman" "man"
    "baby" "older_woman" "older_man"
    "person_with_blond_hair" "man_with_gua_pi_mao" "man_with_turban"
    "construction_worker" "cop" "angel"
    "princess" "smiley_cat" "smile_cat"
    "heart_eyes_cat" "kissing_cat" "smirk_cat"
    "scream_cat" "crying_cat_face" "joy_cat"
    "pouting_cat" "japanese_ogre" "japanese_goblin"
    "see_no_evil" "hear_no_evil" "speak_no_evil"
    "guardsman" "skull" "feet"
    "lips" "kiss" "droplet"
    "ear" "eyes" "nose"
    "tongue" "love_letter" "bust_in_silhouette"
    "busts_in_silhouette" "speech_balloon" "thought_balloon"
    "feelsgood" "finnadie" "goberserk"
    "godmode" "hurtrealbad" "rage1"
    "rage2" "rage3" "rage4"
    "suspect" "trollface"
    ;; --- Nature -----------------------------------------------------------
    "##==-- Nature --==##"
    "sunny" "umbrella" "cloud"
    "snowflake" "snowman" "zap"
    "cyclone" "foggy" "ocean"
    "cat" "dog" "mouse"
    "hamster" "rabbit" "wolf"
    "frog" "tiger" "koala"
    "bear" "pig" "pig_nose"
    "cow" "boar" "monkey_face"
    "monkey" "horse" "racehorse"
    "camel" "sheep" "elephant"
    "panda_face" "snake" "bird"
    "baby_chick" "hatched_chick" "hatching_chick"
    "chicken" "penguin" "turtle"
    "bug" "honeybee" "ant"
    "beetle" "snail" "octopus"
    "tropical_fish" "fish" "whale"
    "whale2" "dolphin" "cow2"
    "ram" "rat" "water_buffalo"
    "tiger2" "rabbit2" "dragon"
    "goat" "rooster" "dog2"
    "pig2" "mouse2" "ox"
    "dragon_face" "blowfish" "crocodile"
    "dromedary_camel" "leopard" "cat2"
    "paw_prints" "paw_prints" "bouquet"
    "cherry_blossom" "tulip" "four_leaf_clover"
    "rose" "sunflower" "hibiscus"
    "maple_leaf" "leaves" "fallen_leaf"
    "herb" "mushroom" "cactus"
    "palm_tree" "evergreen_tree" "deciduous_tree"
    "chestnut" "seedling" "blossom"
    "ear_of_rice" "shell" "globe_with_meridians"
    "sun_with_face" "full_moon_with_face" "new_moon_with_face"
    "new_moon" "waxing_crescent_moon" "first_quarter_moon"
    "waxing_gibbous_moon" "full_moon" "waning_gibbous_moon"
    "last_quarter_moon" "waning_crescent_moon" "last_quarter_moon_with_face"
    "first_quarter_moon_with_face" "moon" "earth_africa"
    "earth_americas" "earth_asia" "volcano"
    "milky_way" "partly_sunny" "octocat"
    "squirrel"
    ;; --- Objects -----------------------------------------------------------
    "##==-- Objects --==##"
    "bamboo" "gift_heart" "dolls"
    "school_satchel" "mortar_board" "flags"
    "fireworks" "sparkler" "wind_chime"
    "rice_scene" "jack_o_lantern" "ghost"
    "santa" "christmas_tree" "gift"
    "bell" "no_bell" "tanabata_tree"
    "tada" "confetti_ball" "balloon"
    "crystal_ball" "cd" "dvd"
    "floppy_disk" "camera" "video_camera"
    "movie_camera" "computer" "tv"
    "iphone" "phone" "telephone"
    "telephone_receiver" "pager" "fax"
    "minidisc" "vhs" "sound"
    "speaker" "mute" "loudspeaker"
    "mega" "hourglass" "hourglass_flowing_sand"
    "alarm_clock" "watch" "radio"
    "satellite" "loop" "mag"
    "mag_right" "unlock" "lock"
    "lock_with_ink_pen" "closed_lock_with_key" "key"
    "bulb" "flashlight" "high_brightness"
    "low_brightness" "electric_plug" "battery"
    "calling" "email" "mailbox"
    "postbox" "bath" "bathtub"
    "shower" "toilet" "wrench"
    "moneybag" "yen" "dollar"
    "pound" "euro" "credit_card"
    "money_with_wings" "e-mail" "inbox_tray"
    "outbox_tray" "envelope" "incoming_envelope"
    "postal_horn" "mailbox_closed" "mailbox_with_mail"
    "mailbox_with_no_mail" "door" "smoking"
    "bomb" "gun" "hocho"
    "pill" "syringe" "page_facing_up"
    "page_with_curl" "bookmark_tabs" "bar_chart"
    "chart_with_upwards_trend" "chart_with_downwards_trend" "scroll"
    "clipboard" "calendar" "date"
    "card_index" "file_folder" "open_file_folder"
    "scissors" "pushpin" "paperclip"
    "black_nib" "pencil2" "straight_ruler"
    "triangular_ruler" "closed_book" "green_book"
    "blue_book" "orange_book" "notebook"
    "notebook_with_decorative_cover" "ledger" "books"
    "bookmark" "name_badge" "microscope"
    "telescope" "newspaper" "football"
    "basketball" "soccer" "baseball"
    "tennis" "8ball" "rugby_football"
    "tennis" "golf" "mountain_bicyclist"
    "bowling" "golf" "mountain_bicyclist"
    "bicyclist" "horse_racing" "snowboarder"
    "swimmer" "surfer" "ski"
    "spades" "hearts" "clubs"
    "diamonds" "gem" "ring"
    "trophy" "musical_score" "musical_keyboard"
    "violin" "space_invader" "video_game"
    "black_joker" "flower_playing_cards" "game_die"
    "dart" "mahjong" "clapper"
    "memo" "pencil" "book"
    "art" "microphone" "headphones"
    "trumpet" "saxophone" "guitar"
    "shoe" "sandal" "high_heel"
    "lipstick" "boot" "shirt"
    "tshirt" "necktie" "womans_clothes"
    "dress" "running_shirt_with_sash" "jeans"
    "kimono" "bikini" "ribbon"
    "tophat" "crown" "womans_hat"
    "mans_shoe" "closed_umbrella" "briefcase"
    "handbag" "pouch" "purse"
    "eyeglasses" "fishing_pole_and_fish" "coffee"
    "tea" "sake" "baby_bottle"
    "beer" "beers" "cocktail"
    "tropical_drink" "wine_glass" "fork_and_knife"
    "pizza" "hamburger" "fries"
    "poultry_leg" "meat_on_bone" "spaghetti"
    "curry" "fried_shrimp" "bento"
    "sushi" "fish_cake" "rice_ball"
    "rice_cracker" "rice" "ramen"
    "stew" "oden" "dango"
    "egg" "bread" "doughnut"
    "custard" "icecream" "ice_cream"
    "shaved_ice" "birthday" "cake"
    "cookie" "chocolate_bar" "candy"
    "lollipop" "honey_pot" "apple"
    "green_apple" "tangerine" "lemon"
    "cherries" "grapes" "watermelon"
    "strawberry" "peach" "melon"
    "banana" "pear" "pineapple"
    "sweet_potato" "eggplant" "tomato"
    "corn"
    ;; --- Places -----------------------------------------------------------
    "##==-- Places --==##"
    "house" "house_with_garden" "school"
    "office" "post_office" "love_hotel"
    "hotel" "wedding" "church"
    "department_store" "european_post_office" "city_sunrise"
    "city_sunset" "japanese_castle" "european_castle"
    "tent" "factory" "tokyo_tower"
    "japan" "mount_fuji" "sunrise_over_mountains"
    "sunrise" "stars" "statue_of_liberty"
    "bridge_at_night" "carousel_horse" "rainbow"
    "ferris_wheel" "fountain" "roller_coaster"
    "ship" "speedboat" "boat"
    "sailboat" "rowboat" "anchor"
    "rocket" "airplane" "helicopter"
    "steam_locomotive" "tram" "mountain_railway"
    "bike" "aerial_tramway" "suspension_railway"
    "mountain_cableway" "tractor" "blue_car"
    "oncoming_automobile" "car" "red_car"
    "taxi" "oncoming_taxi" "articulated_lorry"
    "bus" "oncoming_bus" "rotating_light"
    "police_car" "oncoming_police_car" "fire_engine"
    "ambulance" "minibus" "truck"
    "train" "station" "train2"
    "bullettrain_front" "bullettrain_side" "light_rail"
    "monorail" "railway_car" "trolleybus"
    "ticket" "fuelpump" "vertical_traffic_light"
    "traffic_light" "warning" "construction"
    "beginner" "atm" "slot_machine"
    "busstop" "barber" "hotsprings"
    "checkered_flag" "crossed_flags" "izakaya_lantern"
    "moyai" "circus_tent" "performing_arts"
    "round_pushpin" "triangular_flag_on_post" "jp"
    "kr" "cn" "us"
    "fr" "es" "it"
    "ru" "gb" "uk"
    "de"
    ;; --- Symbols -----------------------------------------------------------
    "##==-- Symbols --==##"
    "one" "two" "three"
    "four" "five" "six"
    "seven" "eight" "nine"
    "keycap_ten" "1234" "zero"
    "hash" "symbols" "arrow_backward"
    "arrow_down" "arrow_forward" "arrow_left"
    "capital_abcd" "abcd" "abc"
    "arrow_lower_left" "arrow_lower_right" "arrow_right"
    "arrow_up" "arrow_upper_left" "arrow_upper_right"
    "arrow_double_down" "arrow_double_up" "arrow_down_small"
    "arrow_heading_down" "arrow_heading_up" "leftwards_arrow_with_hook"
    "arrow_right_hook" "left_right_arrow" "arrow_up_down"
    "rewind" "fast_forward" "information_source"
    "ok" "twisted_rightwards_arrows" "repeat"
    "repeat_one" "new" "top"
    "up" "cool" "free"
    "ng" "cinema" "koko"
    "signal_strength" "u5272" "u5408"
    "u55b6" "u6307" "u6708"
    "u6709" "u6e80" "u7121"
    "u7533" "u7a7a" "u7981"
    "sa" "restroom" "mens"
    "womens" "baby_symbol" "no_smoking"
    "parking" "wheelchair" "metro"
    "baggage_claim" "accept" "wc"
    "potable_water" "put_litter_in_its_place" "secret"
    "congratulations" "m" "passport_control"
    "left_luggage" "customs" "ideograph_advantage"
    "cl" "sos" "id"
    "no_entry_sign" "underage" "no_mobile_phones"
    "do_not_litter" "non-potable_water" "no_bicycles"
    "no_pedestrians" "children_crossing" "no_entry"
    "eight_spoked_asterisk" "eight_pointed_black_star" "heart_decoration"
    "vs" "vibration_mode" "mobile_phone_off"
    "chart" "currency_exchange" "aries"
    "taurus" "gemini" "cancer"
    "leo" "virgo" "libra"
    "scorpius" "sagittarius" "capricorn"
    "aquarius" "pisces" "ophiuchus"
    "six_pointed_star" "negative_squared_cross_mark" "a"
    "b" "ab" "o2"
    "diamond_shape_with_a_dot_inside" "recycle" "end"
    "on" "soon" "clock1"
    "clock130" "clock10" "clock1030"
    "clock11" "clock1130" "clock12"
    "clock1230" "clock2" "clock230"
    "clock3" "clock330" "clock4"
    "clock430" "clock5" "clock530"
    "clock6" "clock630" "clock7"
    "clock730" "clock8" "clock830"
    "clock9" "clock930" "heavy_dollar_sign"
    "copyright" "registered" "tm"
    "x" "heavy_exclamation_mark" "bangbang"
    "interrobang" "o" "heavy_multiplication_x"
    "heavy_plus_sign" "heavy_minus_sign" "heavy_division_sign"
    "white_flower" "100" "heavy_check_mark"
    "ballot_box_with_check" "radio_button" "link"
    "curly_loop" "wavy_dash" "part_alternation_mark"
    "trident" "black_square" "white_square"
    "white_check_mark" "black_square_button" "white_square_button"
    "black_circle" "white_circle" "red_circle"
    "large_blue_circle" "large_blue_diamond" "large_orange_diamond"
    "small_blue_diamond" "small_orange_diamond" "small_red_triangle"
    "small_red_triangle_down" "shipit"
    ;; --- Others -----------------------------------------------------------
    "##==-- Others --==##")
  "List of GitHub's emoji that we are going to displayed.")

(defvar emoji-github--api-list '()
  "Get the full list of GitHub emoji using GitHub request.")

(defvar emoji-github--full-list '()
  "Mixed of the GitHub Emoji API list and the local constant list.")

(defvar emoji-github--column-size 30
  "Character size for each column.")

;;; Utils

(defun emoji-github--is-contain-list-string (in-list in-str)
  "Check if IN-STR contain in any string in the IN-LIST."
  (cl-some (lambda (lb-sub-str) (string= lb-sub-str in-str)) in-list))

;;; Core

(defun emoji-github--revert-table ()
  "Revert the `tabulated-list' table."
  (tabulated-list-revert)
  (tabulated-list-print-fake-header))

(defun emoji-github--format ()
  "Return the list format from the display emoji."
  (let ((title "List %s") (lst '()) (cnt 1))
    (while (<= cnt emoji-github-columns)
      (push (list (format title cnt) emoji-github--column-size t) lst)
      (setq cnt (1+ cnt)))
    (setq lst (reverse lst))
    (vconcat lst)))

(defun emoji-github--is-title-p (str)
  "Check if STR the title string."
  (string-match-p "##==--" str))

(defun emoji-github--format-item (item)
  "Return the string form by ITEM (emoji)."
  (if (not (string-empty-p item))
      (cond ((emoji-github--is-title-p item) item)  ; For title.
            (t (format ":%s: %s" item item)))      ; For emoji.
    ""))

(defun emoji-github--get-github-emoji ()
  "Get the GitHub emoji by `emoji-github--api-url'."
  (setq emoji-github--api-list '())  ; Clean before use.
  (message "Getting emoji data from '%s'" emoji-github--api-url)
  (request
    emoji-github--api-url
    :type "GET"
    :parser 'json-read
    :success
    (cl-function
     (lambda (&key data  &allow-other-keys)
       (dolist (item data)
         (push (symbol-name (car item)) emoji-github--api-list))
       (emoji-github--filter-list)
       (save-selected-window
         (when (get-buffer emoji-github--buffer-name)
           (with-current-buffer emoji-github--buffer-name
             (setq tabulated-list-entries (emoji-github--get-entries))
             (emoji-github--revert-table))))))
    :error
    ;; NOTE: Accept, error.
    (cl-function
     (lambda (&rest args &key _error-thrown &allow-other-keys)
       (user-error "[ERROR] Error while getting GitHub Emoji API")))))

(defun emoji-github--filter-list ()
  "Filter all the emoji from the local constant list.
To remove missing or add new emoji from GitHub Emoji API.  To ensure we will
always display all the emoji that are supported by GitHub."
  (setq emoji-github--full-list '())  ; Clean up before refresh.
  (let ((index 0) (len (length emoji-github--constant-list))
        (other-list '())
        (local-emoji ""))
    (while (< index len)
      (setq local-emoji (nth index emoji-github--constant-list))
      (when (or (emoji-github--is-title-p local-emoji)
                (emoji-github--is-contain-list-string emoji-github--api-list local-emoji))
        (push local-emoji emoji-github--full-list))
      (setq index (1+ index)))
    ;; Supply missing emoji that GitHub supported.
    (dolist (missing-emoji emoji-github--api-list)
      (unless (emoji-github--is-contain-list-string emoji-github--constant-list missing-emoji)
        (push missing-emoji other-list)))
    (setq emoji-github--full-list (reverse emoji-github--full-list))
    (setq emoji-github--full-list (append emoji-github--full-list other-list))))

(defun emoji-github--get-entries ()
  "Get all GitHub's emoji as list entry."
  (let* ((entries '()) (len (length emoji-github--full-list)) (index 0))
    (while (< index len)
      (let ((new-entry '()) (new-entry-value '())
            (current-title "") (meet-title-index 0)
            (is-title nil) (col-cnt 0) (col-val nil)
            (already-on-newline nil))
        (while (and (not is-title) (< col-cnt emoji-github-columns))
          (setq col-val (nth (+ index col-cnt) emoji-github--full-list))
          (if (not col-val)
              (push "" new-entry-value)  ; For the very last.
            (setq is-title (emoji-github--is-title-p col-val))
            (if (not is-title)  ; Prepare title variables.
                (push (emoji-github--format-item col-val) new-entry-value)
              (setq current-title col-val)
              (setq already-on-newline (= col-cnt 0))
              (setq meet-title-index (- emoji-github-columns (1+ col-cnt)))

              (if already-on-newline
                  (progn
                    (push current-title new-entry-value)
                    (while (< col-cnt emoji-github-columns)
                      (push "" new-entry-value)
                      (setq col-cnt (1+ col-cnt))))
                (setq index (- index (1- col-cnt)))
                (while (< col-cnt emoji-github-columns)
                  (push "" new-entry-value)
                  (setq col-cnt (1+ col-cnt))))))
          (setq col-cnt (1+ col-cnt)))

        (setq new-entry-value (reverse new-entry-value))
        (push (vconcat new-entry-value) new-entry)  ; Turn into vector.
        (push (number-to-string index) new-entry)
        (push new-entry entries)

        (setq index (+ index emoji-github-columns))
        (setq index (- index meet-title-index))))

    (reverse entries)))

(define-derived-mode emoji-github-mode tabulated-list-mode
  "emoji-github-mode"
  "Major mode for displaying GitHub's emoji."
  :group 'emoji-github
  (setq emoji-github--full-list '())
  (emoji-github--get-github-emoji)
  (setq tabulated-list-format (emoji-github--format))
  (setq tabulated-list-padding 1)
  (setq-local tabulated-list--header-string "URL: https://gist.github.com/rxaviers/7360908")
  (tabulated-list-init-header)
  (setq tabulated-list-entries (emoji-github--get-entries))
  (tabulated-list-print t)
  (tabulated-list-print-fake-header)
  (emojify-mode 1))

;;;###autoload
(defun emoji-github ()
  "List of GitHub's emoji."
  (interactive)
  (pop-to-buffer emoji-github--buffer-name nil)
  (emoji-github-mode))

(provide 'emoji-github)
;;; emoji-github.el ends here
