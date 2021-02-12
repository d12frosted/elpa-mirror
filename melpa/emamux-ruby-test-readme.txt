emamux-ruby-test makes you test ruby file with emamux.
This package is inspired by vimux-ruby-test.

To use emamux-ruby-test, add the following code into your init.el or .emacs:

   (require 'emamux-ruby-test)
   (global-emamux-ruby-test-mode)

To use emamux-ruby-test with specific mode only, add folowing:

   (require 'emamux-ruby-test)
   (add-hook 'ruby-mode-hook 'emamux-ruby-test-mode)

emamux-ruby-test provides following commands:

Run all tests/specs in the current project
  C-c r T --- emamux-ruby-test:run-all

Run all tests/specs in the current file
  C-c r t --- emamux-ruby-test:run-current-test

Load ruby console dependent of current project type
  C-c r c --- emamux-ruby-test:run-console

Run focused test/spec in test framework specific tool
  C-c r . --- emamux-ruby-test:run-focused-test

Run focused class/context in test framework specific tool
  C-c r , --- emamux-ruby-test:run-focused-goal

Close test pane
  C-c r k --- emamux:close-runner-pane

Visit test pane in copy mode
  C-c r j --- emamux:inspect-runner
