Display text or image surrogates for Org mode tags.

In Org mode only a small set of characters is allowed in tags.  A
wider range of symbols might increase readability and joy.

In an Org mode buffer:

- Toggle the mode with {M-x org-pretty-tags-mode RET}.
- Activate the mode with {C-u M-x org-pretty-tags-mode RET}.
- Deactivate the mode with {C-u -1 M-x org-pretty-tags-mode RET}.

- Toggle the global-mode with {M-x org-pretty-tags-global-mode RET}.
- Activate the global-mode in every buffer with {C-u M-x
  org-pretty-tags-global-mode RET}.
- Deactivate the global-mode in every buffer with {C-u -1 M-x
  org-pretty-tags-global-mode RET}.

Refresh agenda buffers (key =g= or =r=) to follow the latest setting
of pretty tags in the buffers.

- Turn the mode on by default by configuring in {M-x
  customize-variable RET org-pretty-tags-global-mode RET}.

Use {M-x customize-variable RET org-pretty-tags-surrogate-strings RET} to
define surrogate strings for tags.  E.g. add the pair "money", "$$$".

If you don't like the predefined surrogates then just delete them.

Use {M-x customize-variable RET org-pretty-tags-surrogate-images RET}
to define surrogate images for tags.  The definition of the image is
expected to be a path to an image.  E.g. add the pair "org",
"/home/foo/media/images/icons/org-unicorn.png".

Customize description-customize-org-pretty-tags-mode-lighter to define
the lighter, i.e. the indicator that the mode is active in the mode
line.

In the org agenda pretty tags can distroy the allignment of the habit
table.  Customize org-pretty-tags-agenda-unpretty-habits to avoid
this.

See also the literate source file.  E.g. see https://gitlab.com/marcowahl/org-pretty-tags.
