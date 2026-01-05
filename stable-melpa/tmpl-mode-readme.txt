This is a minor mode for Go's `text/template' template system.

This package highlights the `{{ ... }}` constructs used by this
template system.  As this is a minor mode, it can be used in
addition to a suitable major mode.

The following is syntax colored:

* Tmpl keywords like `if' `eq' and `index'.

* The entire `{{ ... }}' is highlighted, to make it stand out
  against the rest of the buffer.

* The `{{-' or `-}}' constructs makes the template engine "eat"
  whitespace before or after the template, respectively.  To
  visualize the effect of this, the whitespace that will be removed
  is also highlighted as part of the template.

Usage:

Install this with an Emacs package manager.

Add this to your init file:

    (tmpl-global-mode)

Example:

This is an example of a Chezmoi init file using tmpl templates.

    [data]
        {{- if eq .chezmoi.os "windows" }}
        my_emacs_bin_dir 	   = "c:/Program Files/emacs/bin"
        {{- else if eq .chezmoi.os "darwin" }}
        my_emacs_bin_dir 	   = "/Applications/Emacs.app/Contents/MacOS"
        {{- else }}
        my_emacs_bin_dir 	   = "/usr/bin"
        {{- end }}
