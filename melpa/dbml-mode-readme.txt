This major mode attempts to port all of the syntax highlighting from
https://dbdiagram.io and build upon it by providing helpers such as
duplicate checking and rendering SVGs directly in Emacs.

A sample for simple syntax is available at https://i.imgur.com/OpXUUVk.gif

For rendering, available as a key binding, it utilizes `dbml-renderer'
(https://github.com/softwaretechnik-berlin/dbml-renderer) which by default
is provided by building a Docker image (requires `docker').  Check `dbml'
customization group to adjust this or other functionality if you don't have
Docker installed or prefer using the raw binary.
