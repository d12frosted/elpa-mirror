
Description
-----------

This minor mode adds some useful functionality for running Python unittest
programs from within Emacs.

It allows you to run py.test, nose, or custom test runners within various
buffer types.  py-gnitset knows about the ``virtualenv-workon`` dir-local, in
addition to allowing you to specify explicit paths to any test runner so
it's easy to write custom shell scripts that set up your test environment
however you want -- see `py-gnitset-test-runner' and
`py-gnitset-runner-format' for details.

- Compile buffer, via py-gnitset-compile-*: the shortest to type, because
  it's generally the most useful.  These buffers have the fancy "click an
  error message to go to that line in the file" functionality you expect.
- PDB buffer, via py-gnitset-pdb-*: Runs the tests in a `pdb'-buffer, with
  the "--pdb" flag appended.  This is particularly useful if you "import pdb;
  pdb.set_trace()" within your tests, as the pdb buffer tracks stepping
  through code within the associated Emacs code buffer.
- Ansi-term buffer, via py-gnitset-term-*: this is a generic escape hatch
  for when things aren't working in another buffer type.  I mostly use it for
  debugging py-gnitset-mode at this point, although it is also useful if you
  prefer ipdb to pdb+emacs pdb mode.

In addition to the various buffer types, you can select which funcions to
test via the py-gnitset-*-all, py-gnitset-*-module, py-gnitset-*-class
commands which all do the obvious things.  And the py-gnitset-*-one
commands finds the nearest class *or* def statement and runs that.

Additionally, prefixing any command with C-u will allow you to edit it in
the minibuffer before creating the buffer that you'll interact with your
tests in.  This also gets you M-p/M-n command history navigation for free,
which is nice.

My goal is to make testing Python in Emacs *obviously* the best way to do it,
so if you have ideas for how to improve things please open an issue the github
page or send me an email.  This set of commands came from the fact that I use
both py.test and nose, and the pytest and nose Emacs runners have different but
complementary features, so I kinda hacked them all together, much is owed to
both of them.

The home page is https://github.com/quodlibetor/py-gnitset

Setting Up
----------

Adding `(py-gnitset-global-mode)' to your .emacs will attempt to turn on
py-gnitset-mode in every `python-mode' buffer.

You can try py-gnitset without global installation by just calling "M-x
py-gnitset-mode" in any Python buffer.  `py-gnitset-mode' just adds
some keybindings to the C-c t map, so if you want to do something fancy you
could for example do:

   (add-hook 'python-mode-hook
              (lambda ()
                 (local-set-key (kbd "C-c n") py-gnitset-map)))

To bind the keys to the C-c n map instead, with no loss of functionality.

Default Bindings
----------------

key             binding
---             -------
C-c t a         py-gnitset-compile-all
C-c t c         py-gnitset-compile-class
C-c t m         py-gnitset-compile-module
C-c t o         py-gnitset-compile-one

C-c t p a       py-gnitset-pdb-all
C-c t p c       py-gnitset-pdb-class
C-c t p m       py-gnitset-pdb-module
C-c t p o       py-gnitset-pdb-one

C-c t r a       py-gnitset-term-all
C-c t r c       py-gnitset-term-class
C-c t r m       py-gnitset-term-module
C-c t r o       py-gnitset-term-one
C-c t r t       py-gnitset-term-again

To Do
-----

- macro-ize the py-gnitset-*-all/class/module/function duplication, so that
  it's just a matter of (def-py-gnitset-generic ...) instead of the current
  quadruple replication
- Add the ability to save custom command formulations (basically hack
  py-gnitset-run to look for the function to run based on an alist,
  rather than the static cond list)
- Add a history of test runs, instead of just clearing out test buffers.
- Add a way to run tests associated with the current *non-test* function
- Remove dependency on virtualenv.el-defined variables
- Create a new more versatile `py-gnitset-runners' alist into an alist of
  ("runner" . 'format) pairs that combines `py-gnitset-test-runner' and
  `py-gnitset-runner-format' in a way that doesn't require multiple
  dir-locals in the common case of a bunch of projects that use similar
  conventions.
