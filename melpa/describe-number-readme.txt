Describe arbitrarily large number value at point/region. If value is a number then
binary/octal/decimal/hexadecimal/character values and conversions are shown. For strings each
character is processed in the same way.

Use `describe-number-at-point' on point/region or `describe-number' to input value manually.

Might be preferable to bind `describe-number-at-point' to some key:
  (global-set-key (kbd "M-?") 'describe-number-at-point)
