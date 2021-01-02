# spdx.el

`spdx.el` provides SPDX license header and copyright insertion.

## Installation

Put `spdx.el` in your Emacs system. Add the following to your `.emacs`:

```elisp
(require 'spdx)
(define-key prog-mode-map (kbd "C-c i l") #'spdx-insert-spdx)
```

Or Use [use-package](https://github.com/jwiegley/use-package) with
[straight.el](https://github.com/raxod502/straight.el)

``` emacs-lisp
(use-package spdx
:ensure t
:straight (:host github :repo "condy0919/spdx.el")
:bind (:map prog-mode-map
("C-c i l" . spdx-insert-spdx))
:custom
(spdx-copyright-holder 'auto)
(spdx-project-detection 'auto))
```

Then you can press `C-c i l` to trigger `spdx-insert-spdx`

Or manual run:

M-x spdx-insert-spdx

Then, `spdx.el` will ask you to select a license. It's done by
`completing-read'.

After that, the license header will be written. An example follows.

`;; SPDX-License-Identifier: AGPL-1.0-only`

## Customization

- `spdx-copyright-holder'
- `spdx-project-detection'
