Open a shell buffer in (or relative to) default-directory,
e.g. whatever directory the current buffer is in. If you have
find-file-in-project installed, you can also move around relative
to the root of the current project.

I use Emacs shell buffers for everything, and shell-here is great
for getting where you need to quickly. The =find-file-in-project=
integration makes it very easy to manage multiple shells and
maintain your path / history / scrollback when switching between
projects.

Recommended binding: =C-c !=

  (require 'shell-here)
  (define-key (current-global-map) "\C-c!" 'shell-here)

Usage:

| =C-c !=         | Open a shell in the current directory         |
| =C-1 C-c !=     | Open a shell one level up from current        |
| =C-2 C-c !=     | Open a shell two levels up from current (etc) |
| =C-u C-c !=     | Open a new shell in the current directory     |
| =C-- C-c !=     | Open a shell in the current project root      |
| =C-- C-1 C-c != | Open a shell one level up from root           |
| =C-- C-2 C-c != | Open a shell two levels up from root (etc)    |
| =C-- C-u C-c != | Open a new shell in the project root          |
