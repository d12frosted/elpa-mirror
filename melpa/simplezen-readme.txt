A simple subset of zencoding-mode for Emacs.

It completes these types:

    div        --> <div></div>
    input      --> <input>
    .article   --> <div class="article"></div>
    #logo      --> <div id="logo"></div>
    ul.items   --> <ul class="items"></ul>
    h2#tagline --> <h2 id="tagline"></h2>

So why not just use zencoding-mode for a much richer set of features?

- this covers 98% of my usage of zencoding-mode
- this is simple enough to be predictable

The original had a way of surprising me. Like when I just wanted to
add a quick <code></code> tag inside some prose, and it garbled the
entire sentence. That doesn't happen here, since this subset does not
look past whitespace.

It also will not try to expand anything that is not a known html-tag,
reducing the number of errors when I just want to indent the line.
Yes, I have it on TAB.

## Setup

You can bind `simplezen-expand` to any button of your choosing.

    (require 'simplezen)
    (define-key html-mode-map (kbd "C-c C-z") 'simplezen-expand)

If you want it bound to `tab` you can do this:

    (define-key html-mode-map (kbd "TAB") 'simplezen-expand-or-indent-for-tab)

Then it will still indent the line, except in cases where you're
looking back at a valid simplezen-expression (see above).

To get it working with yasnippet aswell, I did this:

    (defun --setup-simplezen ()
      (set (make-local-variable 'yas/fallback-behavior)
           '(apply simplezen-expand-or-indent-for-tab)))

    (add-hook 'sgml-mode-hook '--setup-simplezen)

Which will give yasnippet first priority, then simplezen gets it
chance, and if neither of those did anything it will indent the line.
