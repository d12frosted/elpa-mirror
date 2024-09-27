This major mode attempts to port all of the syntax highlighting from
https://dbdiagram.io and build upon it by providing helpers such as
duplicate checking and rendering SVGs directly in Emacs.

For rendering, available as a key binding, it utilizes `dbml-renderer' which
by default is provided by building a Docker image.  Check `dbml'
customization group to adjust this or other functionality.
