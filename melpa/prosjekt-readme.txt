
Description:

prosjekt is a simple software project management tool. A project
in prosjekt comprises 1) a top-level directory, 2) a collection
of files belonging to the project, and 3) a set of commands that
can be executed.

For more details, see the project page at
https://github.com/abingham/prosjekt.

Installation:

Copy prosjekt.el to some location in your emacs load path. Then add
"(require 'prosjekt)" to your emacs initialization (.emacs,
init.el, or something).

Installation (anything integration):

Prosjekt comes with integration with anything
(http://emacswiki.org/emacs/Anything). To enable this, copy
anything-prosjekt.el to your emacs load path. Then add "(require
'anything-prosjekt)" to you emacs initialization. This provides the
anything sources "anything-c-source-prosjekt-files" and
"anything-c-source-prosjekt-projects".

Example config:

  (require 'prosjekt)
  (require 'anything-prosjekt)

  (require 'anything)
  (add-to-list 'anything-sources 'anything-c-source-prosjekt-files t)
  (add-to-list 'anything-sources 'anything-c-source-prosjekt-projects t)

Tool descriptions:

The ":tools" section of a project defines commands which are
associated with the project. Each tool has a name, a function run
for the tool, an optional sequence of keybindings. A tool description looks like this:
  ((:name . "name of tool")
   (:command ...tool function...))
   (:keys ...list of keybinding...))

for example:

  ((:name . "git status")
   (:command git-status)
   (:keys "[f5]"))
