# switchy-window.el: A most-recently-used window switcher for Emacs

`switchy-window.el` is a most-recently-used window switcher.  It suits my
personal Emacs layout and workflow where I usually have at most two editing
windows but up to three side-windows which I have to select only seldomly.

The idea of `switchy-window.el` is simple: when you invoke `switchy-window` in
quick succession, it will switch to one window after the other in
most-recently-used order.  Once you stop switching for long enough time
(`switchy-window-delay`, 1.5 seconds by default), the selected window gets
locked in, i.e., its LRU timestamp is updated and this switching sequence is
ended.  Thusly, you can toggle between two windows simply by invoking
`switchy-window`, waiting at least `switchy-window-delay`, and then invoking
`switchy-window` again to switch back to the original window.


## Usage

Activate `switchy-window-minor-mode` which tracks window changes and bind
`switchy-window` to a key of your liking in `switchy-window-minor-mode-map` or
globally.  Here are is a sample configuration:

```elisp
(switchy-window-minor-mode)

;; That's what I use.
(keymap-set switchy-window-minor-mode-map "C-<" #'switchy-window)

;; Or as a substitute for `other-window'.
(keymap-set switchy-window-minor-mode-map
            "<remap> <other-window>" #'switchy-window)
```

**Hint**: Since the order of window switching is not as obvious as it is with
`other-window`, adding a bit visual feedback to window selection changes can be
helpful.  That can be done easily with the stock Emacs `pulse.el`, e.g.:

```elisp
(defun my-pulse-line-on-window-selection-change (frame)
  (when (eq frame (selected-frame))
    (pulse-momentary-highlight-one-line)))

(add-hook 'window-selection-change-functions
          #'my-pulse-line-on-window-selection-change)
```

## Installation

`switchy-window.el` is available as [GNU ELPA
package](https://elpa.nongnu.org/nongnu/switchy-window.html) so that you can
install it simply from `M-x list-packages RET` or using `use-package` like so:

```elisp
(use-package switchy-window
  :ensure t
  :custom (switchy-window-delay 1.5) ;; That's the default value.
  :bind     :bind (:map switchy-window-minor-mode-map
                        ;; Bind to separate key...
                        ("C-<" . switchy-window)
                        ;; ...or as `other-key' substitute (C-x o).
                        ("<remap> <other-window>" . switchy-window))
  :init
  (switchy-window-minor-mode))
```

## Questions & Patches

For asking questions, sending feedback, or patches, refer to [my public inbox
(mailinglist)](https://lists.sr.ht/~tsdh/public-inbox).  Please mention the
project you are referring to in the subject.

## Bugs

Bugs and requests can be reported [here](https://todo.sr.ht/~tsdh/switchy-window).

## License

`switchy-window.el` is licensed under the
[GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) (or later).
