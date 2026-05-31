Phony is a framework for defining voice commands in Emacs.  It
bridges Emacs with speech recognition backends to allow you to
control Emacs by voice.

Quick example:

  (phony-defun say-hello "hello world"
    (message "Hello!"))

After defining this function, saying "hello world" will display
"Hello!" in the message area.

Phony provides three types of rules for mapping utterances to values
and side effects:

  1. Procedure rules (`phony-defun') - Map utterances to code with
     optional arguments bound from other rules.

  2. Dictionaries (`phony-define-dictionary') - Map utterances to
     values (e.g., numbers, symbols).

  3. Open rules (`phony-define-open-rule') - Match any of multiple
     alternatives, allowing extensible grammars.

Rules can reference other rules to compose complex speech patterns.
The module system (`phony-module') allows you to organize and
enable/disable groups of rules.

See README.org for setup instructions and detailed usage examples.
