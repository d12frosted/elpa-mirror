Add/remove line breaks between function arguments and similar constructs

Put point inside the brackets and call `fill-function-arguments-dwim` to convert

frobinate_foos(bar, baz, a_long_argument_just_for_fun, get_value(x, y))

to

frobinate_foos(
               bar,
               baz,
               a_long_argument_just_for_fun,
               get_value(x, y)
               )

and back.

Also works with arrays (`[x, y, z]`) and dictionary literals (`{a: b, c: 1}`).

If no function call is found `fill-function-arguments-dwim` will call `fill-paragraph`,
so you can replace an existing `fill-paragraph` keybinding with it.
