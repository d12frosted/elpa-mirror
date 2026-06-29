1 Intro
═══════

  Arduino IDE for Emacs developer.


2 Screenshots
═════════════

  <file:arduino-mode.png>


3 Install
═════════

3.1 MELPA available
───────────────────


4 Features
══════════

  • syntax highlighting
  • command-line arduino interface
  • org-mode babel support


5 Usage
═══════

5.1 interactive with Arduino board in arduino-mode
──────────────────────────────────────────────────

  Upload
        In Arduino source code file, press `[C-c C-c]' to upload to
        Arduino board.
  Build
        In Arduino source code file, press `[C-c C-v]' to build.


5.2 Arduino code completing
───────────────────────────

  use with package company-arduino to get Arduino code completing.


5.3 flycheck support
────────────────────

  ┌────
  │ (require 'flycheck-arduino)
  │ (add-hook 'arduino-mode-hook #'flycheck-arduino-setup)
  └────


5.4 Org Mode Babel source block support with ob-arduino.el
──────────────────────────────────────────────────────────

  You need have Org-mode installed, `ob-arduino.el' is in arduino-mode
  by default now.

  ┌────
  │ (require 'ob-arduino)
  │ (add-to-list 'org-babel-load-languages '(arduino . t))
  │ (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
  └────

  Like the following src block, press `[C-c C-c]' to upload to Arduino
  board.

  ┌────
  │ #+begin_src arduino
  │ // the setup function runs once when you press reset or power the board
  │ void setup() {
  │   // initialize digital pin LED_BUILTIN as an output.
  │   pinMode(LED_BUILTIN, OUTPUT);
  │ }
  │ 
  │ // the loop function runs over and over again forever
  │ void loop() {
  │   digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
  │   delay(100);                       // wait for 0.1 second
  │   digitalWrite(LED_BUILTIN, LOW);    // turn the LED off by making the voltage LOW
  │   delay(100);                       // wait for 0.1 second
  │ }
  │ #+end_src
  └────
