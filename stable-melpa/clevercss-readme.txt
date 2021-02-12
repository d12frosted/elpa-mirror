This is a major mode for editing CleverCSS files.  Much of the
functionality imitates that of `clevercss-mode'.  `clevercss-mode'
provides support for imenu and hideshow.

; Installation:

- Put `clevercss.el' somewhere in your emacs load path
- Add these lines to your .emacs file:
  (autoload 'clevercss-mode "clevercss nil t)
  (add-to-list auto-mode-alist '("\\.pcss\\'" . clevercss-mode))

This mode assumes that CleverCSS files have the suffix ".pcss".
You may use additional suffixes by adding them to
`auto-mode-alist'.  For example, to add the suffix ".ccss" you
would write the following in your .emacs file:

(add-to-list auto-mode-alist '("\\.ccss\\'" . clevercss-mode))

To customize how it works:
 M-x customize-group RET clevercss-mode RET


; Bug Reporting:

Patches welcome.
