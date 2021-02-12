This package is a set of configuration to let you auto-completion
by using `irony-mode', `company-irony' and `company-c-headers' on arduino-mode.

Prerequisite:
This package need irony-mode, company-irony and company-c-headers
packages. Please install those packages first. But if you are using
MELPA, package.el will install dependencies automatically when you install
this package. Also, you need irony-mode's setting, so please follow
the irony-mode's instruction (https://github.com/Sarcasm/irony-mode).

Although you may prepared Arduino environment, you need it as well to
refer to Arduino's header files. You can download from Arduino's web site
(http://www.arduino.cc/en/Main/Software)

Usage:
Set $ARDUINO_HOME environment variable as Arduino IDE's installed directory.
(i.e., export ARDUINO_HOME=$HOME/share/devkit/arduino-1.6.3 on zsh)

Then put following configurations to your .emacs or somewhere.

  ;; Emacs configuration
  ;; If you installed this package from without MELPA, you may need
  ;; `(require 'company-arduino)'.

  ;; Configuration for irony.el
  ;; Add arduino's include options to irony-mode's variable.
  (add-hook 'irony-mode-hook 'company-arduino-turn-on)

  ;; Configuration for company-c-headers.el
  ;; The `company-arduino-append-include-dirs' function appends
  ;; Arduino's include directories to the default directories
  ;; if `default-directory' is inside `company-arduino-home'. Otherwise just
  ;; returns the default directories.
  ;; Please change the default include directories accordingly.
  (defun my-company-c-headers-get-system-path ()
    "Return the system include path for the current buffer."
    (let ((default '("/usr/include/" "/usr/local/include/")))
      (company-arduino-append-include-dirs default t)))
  (setq company-c-headers-path-system 'my-company-c-headers-get-system-path)

  ;; Activate irony-mode on arudino-mode
  (add-hook 'arduino-mode-hook 'irony-mode)

  ;; If you are already using ‘company-irony’ and ‘company-c-headers’,
  ;; you might have same setting. That case, you can omit below setting.
  (add-to-list 'company-backends 'company-irony)
  (add-to-list 'company-backends 'company-c-headers)

Note:
This package's default configuration is set for Linux environment,
which I'm currently using, so if you are using different
environment (Mac or Windows), please change the Arduino's directory paths accordingly.
Related variables: `company-arduino-sketch-directory-regex', `company-arduino-home',
`company-arduino-header', `company-arduino-includes-dirs' and `irony-arduino-includes-options'.
