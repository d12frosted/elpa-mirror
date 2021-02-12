Yasnippets for the Buster javascript testing framework

Common snippets

    tc => new testCase (one for node, browser and node+browser)
    tt => additional test
    cx => nested context
    su => setup method
    td => teardown method

Assert and refute snippets follow a common pattern. They start with `as` or `re`
followed by a mnemonic shortcut. Most are simply the 'initials' of the method name, but
the best shortcuts are saved for the most common assertions.

    ase - assert.equals
    asm - assert.match
    ass - assert.same
    asx - assert.exception
    asd - assert.defined
    ast - assert.threw
    asat - assert.alwaysThrew
    asin - assert.isNull
    asio - assert.isObject
    asto - assert.typeOf
    ascn - assert.className
    astn - assert.tagName

Buster also includes Sinon and its assertions:

    asc - assert.called
    asc1 - assert.calledOnce
    asc1w - assert.calledOnceWith
    asc2 - assert.calledTwice
    asc3 - assert.calledThrice
    ascw - assert.calledWith
    ascc - assert.callCount
    asco - assert.callOrder
    asco - assert.calledOn
    asaco - assert.alwaysCalledOn
    asacw - assert.alwaysCalledWith
    asacwe - assert.alwaysCalledWithExactly
    ascwe - assert.calledWithExactly

Refutations mirrors assertions exactly, except that they start with `re` instead of
`as`. It is the beautiful symmetry of the buster assertions package.

Installation

If you haven't, install [yasnippet](http://capitaomorte.github.com/yasnippet/)
then install buster-snippets like so:

    git submodule add https://github.com/magnars/buster-snippets.el.git site-lisp/buster-snippets

Then require buster-snippets at some point after yasnippet.

    (require 'buster-snippets)

Customization

Add `"use strict"`-declarations to the test cases:

    (setq buster-use-strict t)

Declare `assert` and `refute` if you've disabled additional globals:

    (setq buster-exposed-asserts nil)

Set the default global namespace-object on a per-project basis:

    (add-hook 'js2-mode-hook
          (lambda ()
            (when (string-match-p "projects/zombietdd" (buffer-file-name))
              (setq js2-additional-externs '("ZOMBIE"))
              (setq buster-default-global "ZOMBIE"))))

    ;; example from one of my projects

Add the default global to the IIFE (immediately invoked function expression)

    (setq buster-add-default-global-to-iife t)

The global will by default be shortened to a one-letter var, like this:

    (function (Z) {

       // use Z instead of ZOMBIE inside the namespace

    }(ZOMBIE));
