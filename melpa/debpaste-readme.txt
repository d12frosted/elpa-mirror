This package provides an interface for receiving, posting and
deleting pastes from <http://paste.debian.net/>.

You can install the package from MELPA.  If you prefer the manual
installation, the easiest way is to put these lines into your
init-file:
  (add-to-list 'load-path "/path/to/debpaste-dir")
  (require 'debpaste)

Basic interactive commands:
- `debpaste-display-paste',
- `debpaste-paste-region',
- `debpaste-delete-paste'.

The package provides a keymap, that can be bound like this:
  (global-set-key (kbd "M-D") 'debpaste-command-map)

You will probably want to modify a default poster name:
  (setq debpaste-user-name user-login-name)

For full description, see <http://github.com/alezost/debpaste.el>.

For information about features provided by debian paste server,
read <http://paste.debian.net/rpc-interface.html>.
