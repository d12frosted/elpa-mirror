This is a minor mode to insert semicolon smartly, like Eclipse does.

When `smart-semicolon-mode' is enabled, typing ";" inserts
semicolon at the end of line if there is no semicolon there.

If there is semicolon at the end of line, typing ";" inserts
semicolon at the point.

After smart semicolon insert, backspace command reverts the behavior
as if ";" is inserted normally.

To enable it, add `smart-semicolon-mode' to some major mode hook.

    (add-hook 'c-mode-common-hook #'smart-semicolon-mode)
