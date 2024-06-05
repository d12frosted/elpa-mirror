test-cockpit aims to be a unified user interface for test runners of different
programming languages resp. their testing tools.  There are excellent user interfaces
for running tests like python-pytest, but thy are usually special solutions for a
specific programming language resp testing tool.  People working with multiple
programming languages in their various projects have to deal with different user
interfaces to run tests.  That can be annoying.

test-cockpit uses transient.el to provide a user interface like the well known git
frontend magit does.  There are general commands to run tests that are the same for
all programming languages.  Furthermore there are switches or settings, that are
specific to some programming language.  test-cockpit uses projectile to guess the
type of project and chooses the user interface variant for the specific programming
language accordingly.  That way the basic testing commands can be called by the same
keybindings for all the supported project types.

Each language has its own package to implement the testing of a project.
Such packages can be added locally, i. e. without modifying the code of
test-cockpit.el.

It is suggested that you bind the following two commands to keybindings that
suit you best.

* `test-cockpit-repeat-test-or-projectile-test'
  This should be bound to a quickly reachable keybinding, that you can find
  easily and quickly.  It tries to the last test that the current project
  has been tested with.  If in the current session the project has not been
  tested yet, a dialog is opened for you to choose the way the testing should
  be performed.

  If the project type is not supported it falls back to
  `projectile-test-project'.

  In either way, the test command that you give is remembered.  Next time you
  hit your key binding, the exact same test command for the project is
  repeated.

* `test-cockpit-test-or-projectile-test'
  This does open the test dialog for you to setup the test command.  If the
  project type is not supported, it falls back to `projectile-test-command`.  So
  use this if you don't want to repeat the last test, but run a different one.

You can also use the following commands to run tests in a more manual way

* `test-cockpit-test-project' to run the whole test suite.
* `test-cockpit-test-module' runs only the tests of the current module.
* `test-cockpit-test-function' runs only the test of the function at point.
* `test-cockpit-repeat-test' repeats exactly the *previous* test run.

If the current function at point or the current module cannot be determined,
the last tested module resp. last tested function are tested.  If there are no
last tests, an error message is thrown.

There is experimental state support of the Dape package to run DAP debug sessions.
