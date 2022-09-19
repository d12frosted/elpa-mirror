# boxquote.el
Quote text with a semi-box.

[![MELPA Stable](http://stable.melpa.org/packages/boxquote-badge.svg)](http://stable.melpa.org/#/boxquote)
[![MELPA](https://melpa.org/packages/boxquote-badge.svg)](https://melpa.org/#/boxquote)
[![NonGNU ELPA](https://elpa.nongnu.org/nongnu/boxquote.svg)](https://elpa.nongnu.org/nongnu/boxquote.html)

## Commentary:

`boxquote.el` provides a set of functions for using a text quoting style
that partially boxes in the left hand side of an area of text, such a
marking style might be used to show externally included text or example
code.

```
,----
| The default style looks like this.
`----
```

A number of functions are provided for quoting a region, a buffer, a
paragraph and a defun. There are also functions for quoting text while
pulling it in, either by inserting the contents of another file or by
yanking text into the current buffer.

The latest version of `boxquote.el` can be found at:

```
  <URL:https://github.com/davep/boxquote.el>
```

## Thanks:

Kai Grossjohann for inspiring the idea of boxquote. I wrote this code to
mimic the "inclusion quoting" style in his Usenet posts. I could have
hassled him for his code but it was far more fun to write it myself.

Mark Milhollan for providing a patch that helped me get the help quoting
functions working with XEmacs. (which, for other reasons, I've needed to
remove as of v2.0 -- hopefully I can get things working on XEmacs again).

Oliver Much for suggesting the idea of having a `boxquote-kill-ring-save`
function.

Reiner Steib for suggesting `boxquote-where-is` and the idea of letting
`boxquote-describe-key` describe key bindings from other buffers. Also
thanks go to Reiner for suggesting `boxquote-insert-buffer`.

[//]: # (README.md ends here)
