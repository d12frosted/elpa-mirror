# evil-indent-plus

[![MELPA](https://melpa.org/packages/evil-indent-plus-badge.svg)](https://melpa.org/#/evil-indent-plus)

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [evil-indent-plus](#evil-indent-plus)
    - [Introduction](#introduction)
    - [Usage](#usage)
    - [Differences from evil-indent-textobject](#differences-from-evil-indent-textobject)

<!-- markdown-toc end -->

## Introduction

This is a continuation of
[evil-indent-textobject](https://github.com/cofi/evil-indent-textobject). It
provides six new text objects to evil based on indentation:

* `ii`: A block of text with the same or higher indentation.
* `ai`: The same as `ii`, plus whitespace.
* `iI`: A block of text with the same or higher indentation, including the first
line above with less indentation.
* `aI`: The same as `iI`, plus whitespace.
* `iJ`: A block of text with the same or higher indentation, including the first
line above *and* below with less indentation.
* `aJ`: The same as `iJ`, plus whitespace.

## Usage

You can install the package and bind the auto-loadable text objects yourself:

- `evil-indent-plus-i-indent`
- `evil-indent-plus-a-indent`
- `evil-indent-plus-i-indent-up`
- `evil-indent-plus-a-indent-up`
- `evil-indent-plus-i-indent-up-down`
- `evil-indent-plus-a-indent-up-down`

Or you can call `(evil-indent-plus-default-bindings)` to use the default
bindings (listed above). They are:

```elisp
(define-key evil-inner-text-objects-map "i" 'evil-indent-plus-i-indent)
(define-key evil-outer-text-objects-map "i" 'evil-indent-plus-a-indent)
(define-key evil-inner-text-objects-map "I" 'evil-indent-plus-i-indent-up)
(define-key evil-outer-text-objects-map "I" 'evil-indent-plus-a-indent-up)
(define-key evil-inner-text-objects-map "J" 'evil-indent-plus-i-indent-up-down)
(define-key evil-outer-text-objects-map "J" 'evil-indent-plus-a-indent-up-down)
```

## Differences from evil-indent-textobject

The `evil-indent-textobject` package provides text objects that select lines
with the *exact* same indentation as the current line. Lines that are either
indented *more*, or which are empty, will interrupt the selection, contrary to
expected behaviour. This package correctly handles these cases.
