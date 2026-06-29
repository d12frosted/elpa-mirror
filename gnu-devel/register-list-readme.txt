This library lets you list and edit registers.  M-x `register-list'
displays a list of currently set registers.

This list is similar to that of `bookmark-bmenu-list': you can set
registers to delete with `d' and delete them with `x'.  If you want
to concatenate the content of registers, mark them with `c' and
process with `x'.

You can also edit the register's key with `k' and its value with `v'
Hitting RET on a value string will jump to the register's location or
add the text to the kill ring.  Hitting RET on a register's type will
restrict the list to registers of this type.

Put this file into your load-path and the following into your ~/.emacs:
  (require 'register-list)