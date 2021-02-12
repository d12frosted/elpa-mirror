
# What is project-persist?
Project-persist is a simple, extensible Emacs package to allow persistence of a
list of projects with relevant settings.

# What does it do?
It allows you to create, open, save, close and delete simple projects based on
root directories.

# Is that it?
Pretty much. It also provides hooks around each of these functions so that you
could, for example, load and save an Emacs desktop in tandem with a project,
create and save a tags file, or load another project-management solution such as
[Projectile](https://github.com/bbatsov/projectile).

By default, only a project's name and root directory are saved, but you can
easily add other settings like this:

```lisp
(add-to-list 'project-persist-additional-settings
  '(my-setting . (lambda () (read-from-minibuffer "My setting: "))))
```

Each element of the list is a cons cell with car a symbol naming the new setting
and cdr a function to obtain the value of the setting. The function will be
called during project creation and the setting's value saved as normal.

The setting can be retrieved once a project is loaded by invoking:

```lisp
(pp/settings-get 'my-setting)
```

Project-persist is intentionally lightweight, in the spirit of Emacs, so that it
can be used to build a more complex project-management infrastructure tailored
to your needs. Other packages, like the aforementioned Projectile, handle things
like searching within a project, so there's no need to duplicate such
functionality.

It can be required and enabled as follows:

```lisp
(require 'project-persist)
(project-persist-mode t)
```
