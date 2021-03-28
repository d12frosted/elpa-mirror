; Rii: Reversible Input Interface for Emacs
  You can read multiple input from users.  Users can go back backward input
  through the buttons in the buffer.

    (rii ((editor (completing-read "Favorite editor: " '("Emacs" "Vim" "VSCode")))
          (fruit  (intern (completing-read "Favorite fruit: " '(apple orange lemon)))))
      (switch-to-buffer "*Welcome-to-Rii*")
      (erase-buffer)
      (insert "Welcome to Rii!\n\n"
              "Your favorite editor is " editor "!\n"
              "Your favorite fruit is " (pp fruit) "!\n"))


; How to Use?
  You can just use macro `rii' for the purpose.  Semantics is almost same as `let',
  but a little expanded.  Buffer is shown to provide backward input.

    (rii (
          ;; You can bind any object, such as string, and symbol.
          (editor (completing-read "Favorite editor: " '("Emacs" "Vim" "VSCode")))
          (fruit  (intern (completing-read "Favorite fruit: " '(apple orange lemon))))
          ;; If you would like to display string in buffer instead of value,
          ;; use `rii-change-display-value'.
          (str-list (let* ((list-list '(("star" . ("Sun" "Vega" "Antares" "Sirius"))
                                        ("planet" . ("Mercury" "Venus" "Earth" "Mars"))))
                           (key (completing-read "Which list do you use: " list-list))
                           (value (cdr (assoc key list-list))))
                      (rii-change-display-value
                       value                ;Actual value
                       key)))               ;Displayed string
          ;; If you want to change string of button, use list instead of symbol as car.
          ;; Cdr the car list is plist.
          ((sport                            ;Symbol bound by value
            :display "Your favorite sports") ;String displayed on the buffer
           (completing-read "Favorite sports: "
                            '("soccer" "baseball" "basketball" "skiing"))))
      (switch-to-buffer "*Welcome-to-Rii*")
      (erase-buffer)
      (insert "Welcome to Rii!\n\n"
              "Your favorite editor is " editor "!\n"
              "Your favorite fruit is " (pp fruit) "!\n"
              "Your favorite sport is " sport "!\n\n")
      (dolist (x str-list)
        (insert x ", "))
      (insert "are very beautiful!\n"))


; Detail of `rii' macro

    (rii ((VAR VALUE) ...)
      BODY...)


;; Basic structure
  Basical smantics is same as `let', except that `VAR' cannot be used instead of
  =(VAR nil)= (because binding by `nil' is unecessary).  Also constant or noninteractive
  sexp can be also accepted as `VALUE', but button is still displayed, so `let' is
  recommended for that case.

    (rii (
          ;;Input string
          (str (read-string "Input some str: "))
          ;; Constant is accepted but not recommended
          (x 1))
      (message "%s / %d" str x))


;; Change button string
  If you want to change button string, use =((VAR :display "something") VALUE)=
  instead of =(VAR VALUE)=, in first argument of `rii'.  By default, string capitalized
  `VAR' and repleced "-" with " " is used.

    (rii (((str :display "My string")       ;Button is shown as "My string" instead of "Str"
           (read-string "Hit some str: "))
          ((num :display "My number")       ;Button is shown as "My number" inttead of "Num"
           (read-number "Hit number: ")))
      (message "%s%d" str num))


;; Change displayed string of each value
   If you want to change string displayed after button instead of value returned by `VALUE',
   use `rii-change-display-value' or `rii-change-display-value-func'.
   First argument is commonly value returned by `VALUE'.
   On `rii-change-display-value', second argument is string displayed instead of `VALUE'.
   On `rii-change-display-value-func', second argument is function which recieves
   first argument and which returns displayed string.

     (rii ((str1 (rii-change-display-value
                  (read-string "String1: ")
                  "xyz"))                    ;Always display "xyz"
           (str2 (let ((s (read-string "String1: ")))
                     (rii-change-display-value
                      s                      ;Actually bound value
                      (concat "xyz" s))))    ;Prefixed by "xyz"
           (num (rii-change-display-value-func
                 (read-number "Number: ")    ;Actually bound value
                 (lambda (x)                 ;x is bound by read number
                   (make-string x ?a)))))    ;display "a" X times.
       (message "%s\n%s\n%d" str1 str2 num))


;; Use custom variables prefixed by =rii-=
   When symbol prefixed by "rii-" is used as `VAR', the =(VAR VALUE)=
   is regarded as special.  While the other `VALUE' s are evaluated
   sequencially, `VALUE' s of "rii-"-prefixed `VAR' are evaluated
   earlier than any others.  These `VAR' is bound buffer-locally
   (not bound dynamically), so accessable only in the buffer.

     (rii ((rii-buffer-name "*Welcome*")     ;Like this
           (str (read-string "str: ")))
       (message str))


; Keybinding in buffer
  | Key            | Function                | Description                   |
  |----------------+-------------------------+-------------------------------|
  | TAB            | forward-button          | Go to next button             |
  | backtab(S-TAB) | backward-button         | Go to previous button         |
  | SPC            | scroll-up-command       | Scroll up the buffer          |
  | S-SPC          | scroll-down-command     | Scroll down the buffer        |
  | M-p            | rii-previous-history    | Load previous history         |
  | M-n            | rii-next-history        | Load next history             |
  | q              | quit-window             | Quit this buffer (not killed) |
  | C-c C-k        | rii-kill-current-buffer | Kill buffer                   |
  | C-c C-c        | rii-apply               | Push apply button             |

; Custom variables
  All custom variables below can use as `VAR' in first argument of `rii'.
  You can change default value by set variable globally.

;; `rii-button-type', `rii-button-apply-type'
   Button type which is used to create input button or application button.
   See document of `define-button-type'.

;; `rii-buffer-name'
   Buffer name used by `rii'.

;; `rii-multiple-buffer'
   Whether create multiple buffers when buffer named `rii-buffer-name'
   is already exist.  when the value is `non-nil' and when buffer named
   `rii-buffer-name' is already exist, `rii' creates buffer named
   `rii-buffer-name' + "<N>" (N is serial number).  When the value is `nil',
   ask whether kill the buffer or not.

;; `rii-separator-after-button'
   Separator string between section.
   (section means pair of button and displayed value).

;; `rii-separator-between-section'
   Separator string between button and value.

;; `rii-confirm-when-apply'
   Whether confirm before apply or not.

;; `rii-header-document'
  Comment inserted on head of the buffer.

;; `rii-ring-history-variable'
   Variable which has history.
   Set this on `rii' if you want to use isolated history.

;; `rii-ring-history-size-default'
   Default size of history saved in `rii-ring-history-variable'.

; License
  This package is licensed by GPLv3. See LICENSE.

