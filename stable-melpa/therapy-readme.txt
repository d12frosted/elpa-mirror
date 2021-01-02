
"This is supposed to be torture, not therapy!"  -- Minerva Mayflower

Description:

Therapy is fundamentally a set of hooks which get executed when the major
version of your configured Python interpreter changes. If you regularly need
to switch between Python major version in an Emacs session, this is for you!

A typical situation where therapy can come in handy is if you've got Python2
and Python3 system installations. In this case, certain tools like flake8 and
ipython can have different names depending on the major version of Python
you're using: flake8 vs. flake8-3 and ipython vs. ipython3, respectively.
Since Emacs can use these tools, you need to be able to tell Emacs which
commands to use in which situations. Therapy gives you hooks for doing just
this.

The basic approach is that you add hooks to the `therapy-python2-hooks' and
`therapy-python3-hooks' lists. Your hooks will be called when therapy detects
that the Python major version has changed, and your hook functions can do
things like set the flake8 command, update the `python-shell-interpreter'
variable, and so forth.

But how does therapy know when the Python major version has changed? It
doesn't, really. You have to tell it by calling
`therapy-interpreter-changed'. This tells therapy to run the hooks; it will
detect the configured major version and run the appropriate hooks.
Alternatively, you can call `therapy-set-python-interpreter' which a) sets
`python-shell-interpreter' and b) calls the hooks.
