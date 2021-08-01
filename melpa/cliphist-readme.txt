Read clipboard items from following clipboard managers,
  - Parcellite (http://parcellite.sourceforge.net) on Linux
  - ClipIt (http://clipit.sourceforge.net) on Linux
  - Greenclip (https://github.com/erebe/greenclip) on Linux
  - Flycut (https://github.com/TermiT/Flycut) on macOS

Usage:
  Make sure clipboard manager is running.
  If you use Flycut on macOS, set up "Preferences > General > Clippings",
  so its value is "Save After each clip".
  "M-x cliphist-paste-item" to paste item from history
  "C-u M-x cliphist-paste-item" rectangle paste item
  "M-x cliphist-select-item" to select item

You can customize `cliphist-select-item',
For example, if you use xclip (https://elpa.gnu.org/packages/xclip.html),

  (require 'xclip)
  (setq cliphist-select-item-callback
     (lambda (num str)
        (xclip-set-selection 'clipboard str)))

If `cliphist-cc-kill-ring' is true, the selected/pasted string
will be inserted into kill-ring.

Set `cliphist-linux-clipboard-managers',  `cliphist-macos-clipboard-managers',
`cliphist-windows-clipboard-managers' to add your own clipboard managers.
Here are steps to support a new clipboard manager named "myclip" on Linux.

Step 1, create a file "cliphist-myclip.el" with below content,

  (require 'cliphist-sdk)
  (defun cliphist-my-read-items ()
    (let (rlt
          (items '("clip1" "clip2")))
      (dolist (item items)
        (cliphist-sdk-add-item-to-cache rlt item))
      rlt))
  (provide 'cliphist-myclip)

Step 2, add "(push "myclip" cliphist-linux-clipboard-managers)" into "~/.emacs".

Set `cliphist-greenclip-program' if greenclip program is not added into
environment variable PATH.
