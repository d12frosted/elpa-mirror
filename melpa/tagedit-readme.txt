A collection of paredit-like functions for editing in html-mode.

## Installation

I highly recommended installing tagedit through elpa.

It's available on [marmalade](http://marmalade-repo.org/) and
[melpa](http://melpa.milkbox.net/):

    M-x package-install tagedit

You can also install the dependencies on your own, and just dump
tagedit in your path somewhere:

 - <a href="https://github.com/magnars/s.el">s.el</a>
 - <a href="https://github.com/magnars/dash.el">dash.el</a>

## Functions

This is it at the moment:

 - `tagedit-forward-slurp-tag` moves the next sibling into this tag.
 - `tagedit-forward-barf-tag` moves the last child out of this tag.
 - `tagedit-raise-tag` replaces the parent tag with this tag.
 - `tagedit-splice-tag` replaces the parent tag with its contents.
 - `tagedit-kill` kills to the end of the line, while preserving the structure.

Not part of paredit:

 - `tagedit-kill-attribute` kills the html attribute at point.

## Setup

If you want tagedit to bind to the same keys as paredit, there's this:

```cl
(eval-after-load 'sgml-mode
  '(progn
     (require 'tagedit)
     (tagedit-add-paredit-like-keybindings)
     (add-hook 'html-mode-hook (lambda () (tagedit-mode 1)))))
```

Or you can cherry-pick functions and bind them however you want:

```cl
(define-key tagedit-mode-map (kbd "C-<right>") 'tagedit-forward-slurp-tag)
(define-key tagedit-mode-map (kbd "C-<left>") 'tagedit-forward-barf-tag)
(define-key tagedit-mode-map (kbd "M-r") 'tagedit-raise-tag)
(define-key tagedit-mode-map (kbd "M-s") 'tagedit-splice-tag)
(define-key tagedit-mode-map (kbd "C-k") 'tagedit-kill)
(define-key tagedit-mode-map (kbd "s-k") 'tagedit-kill-attribute)
```

## Experimental tag editing

I am currently working on automatically updating the closing tag when
you edit the starting tag. It is an experimental feature, since it is quite new
and I'm sure it breaks some things.

This also inserts `<></>` when you type `<`, and expands it to
`<div></div>` as you type.

You can turn on experimental features using:

```cl
(tagedit-add-experimental-features)
```

## Other conveniences

It also expands one-line tags into multi-line tags for you, when you
press refill-paragraph. Like this:

```html
<p>My one very long text inside a tag that I'd like to refill</p>
```

then after `M-q`:

```html
<p>
  My one very long text inside a tag that
  I'd like to refill
</p>
```

You can disable this behavior by setting
`tagedit-expand-one-line-tags` to nil.
