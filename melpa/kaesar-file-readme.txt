## Install:

Put this file into load-path'ed directory, and byte compile it if
desired.  And put the following expression into your ~/.emacs.

    (require 'kaesar-file)

## Usage:

Simply encrypt or decrypt file using `kaesar-file-encrypt` and `kaesar-file-encrypt`:

```
(kaesar-file-encrypt "/path/to/file.txt")
```

```
(kaesar-file-decrypt "/path/to/file.txt")
```
