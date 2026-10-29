`refactor.el' is a library for adding refactoring support for any
programming language.  A refactoring, or refactor, is any rewrite to
a program that maintains its intended meaning, while (hopefully)
improving it.  It could be extracting a function, inlining a
variable, renaming an identifier, organizing imports, or
automatically fixing a diagnostic.  In `refactor.el' each such
potential rewrite is called an _action_ and embodied by the
`refactor-action' object.

Note that this library is completely agnostic about the programming
language and major mode.  By itself, it has no knowledge of how these
actions are discovered and eventually carried out: that's for other
Elisp programs to define and set up, in the form of `refactor.el'
_backends_.  A very significant part of the code was extracted from
Emacs' LSP client Eglot, which now contains a simpler backend that
makes use of refactor.el.

User interface

In buffers where a working backend is set up, the library provides
some useful UI: a number of interactive commands for selecting
actions -- `refactor', `refactor-rename' and a few more shortcut
commands -- as well as the `refactor-suggestion-mode' minor mode,
which leverages the ElDoc system and endeavors to constantly keep the
user informed of which actions are available.  This minor mode is the
familiar "lightning bolt/lightbulb on the side" that some IDEs
display.  The variable `refactor-indications' is its main point of
customization.

Each action has a "kind", which is used by the aforementioned
shortcut commands.  For example, `refactor-quickfix' restricts
actions at point to the specific kind `quickfix' and ignores are
actions of other kids (like, say `extract' or `inline').  Depending
on the number of actions avaiable and the specific command, actions
are either automatically selected or presented to the user for
selection.

Once an action is selected, it is executed, but its changes aren't
necessarily applied right away.  The variable `refactor-confirmation'
controls whether and how the user confirms them first: as a summary
in the minibuffer, as a diff of the proposed changes, or not at all.
The choice can depend on the command, on the kinds of file
operations involved, and on whether the affected files are visited
in buffers.

Elisp API

The Elisp-facing parts of this library are useful for backend
authors: there are two distinct Elisp-facing interfaces, independent
of each other.  Either is useful alone, though they can and normally
work together.

- Action discovery and selection

  The interactive commands are entry points that communicate with
  "refactor backends", i.e. any object returned by
  `refactor-backend-functions'.  The base `refactor' command asks
  backends via `refactor-backend-actions' what "actions"
  (i.e. potential refactorings) can be carried out for the buffer
  near point.  This is much like `xref-backend-functions' except that
  unlike Xref, every applicable backend contributes.  The backend who
  provided the chosen action (regardless of how it was chosen) is
  asked again to carry it out.  This invokes its implementation of
  the `refactor-backend-execute' method.  Executing an action could
  entail changes to the current buffer or to other buffers, even
  changes to unvisited files, creation or deletion of files: the
  library puts no constraints on the scope of an action.

- Changeset application:

  To simplify and give consistency to the execution of actions,
  we use the concept of _changeset_, an ordered list of
  `refactor-operation' objects.  Though not required, a normal
  implementation of `refactor-backend-execute' would compute such a
  changeset, then offer to apply it by calling
  `refactor-apply-changeset'.  `refactor-apply-changeset' carries out
  each `refactor-operation' -- edits to files, creation of files,
  renaming and deletion of files -- according to certain rules.  For
  example, it may offer a preview to the user as a summarized
  description and ask for confirmation in the minibuffer, or it may
  present the changeset as a diff, or it may skip confirmation
  altogether.  This is according to the user preferences in
  `refactor-confirmation'.  Note that an Elisp program may call this
  directly for applying changes in a consistent and uniform manner
  outside the context of `refactor-backend-execute'.