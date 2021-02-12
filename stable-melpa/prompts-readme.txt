Prompts provides utilities for working with text prompts and read completion.

For an example of prompts' enhanced completing-read,
see `prompts-completing-read-variable', which supports reading any variable
with a predicate, for example to prompt for a keymap with completion, you
could use:

   (prompts-completing-read-variable "Enter keymap: " 'keymapp)
