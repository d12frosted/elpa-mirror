Conner allows you to define custom commands tailored to your
projects' needs.  Whether it's compiling, running, testing,
prettifying, monitoring changes, debugging, installing, or any
other task specific to your workflow, Conner makes it easy to
integrate with Emacs.

Commands are configured in a .conner file, typically located at the
root of your project.  Inside this file, you'll define a Lisp object
containing a list of command names, their respective commands, and
their types.

Integration with project.el enables seamless execution of these
commands within Emacs, either on arbitrary directories or
automatically detecting the current project's root.

Additionally, Conner also has support for .env files.  By default,
Conner will look in the root directory of your project for a .env
file and load any environment variables found within.  These
variables are then accessible to Conner commands, and won't pollute
the regular Emacs session.

Conner is configurable, so you can add your own command types if
what's available doesn't quite suit your needs.
