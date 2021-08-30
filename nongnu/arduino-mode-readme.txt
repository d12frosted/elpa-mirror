* Screenshots

#+ATTR_ORG: :width 600
#+ATTR_LATEX: :width 6.0in
#+ATTR_HTML: :width 600px
[[file:arduino-mode.png]]

* Install

** MELPA available

* Features

- syntax highlighting
- command-line arduino interface
- org-mode babel support

* Usage

** interactive with Arduino board in arduino-mode

- Upload :: In Arduino source code file, press =[C-c C-c]= to upload to Arduino board.
- Build :: In Arduino source code file, press =[C-c C-v]= to build.

** Arduino code completing

use with package company-arduino to get Arduino code completing.

** Org Mode Babel source block support with ob-arduino.el

You need have Org-mode installed, ~ob-arduino.el~ is in Org-mode contrib/ now.

Like the following src block, press =[C-c C-c]= to upload to Arduino board.

#+begin_src org
,#+begin_src arduino
// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
}

// the loop function runs over and over again forever
void loop() {
  digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(100);                       // wait for 0.1 second
  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off by making the voltage LOW
  delay(100);                       // wait for 0.1 second
}
,#+end_src
#+end_src
