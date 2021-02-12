Usage:

- M-x `cdnjs-install-gocdnjs'

  Install `gocdnjs` command.

    `wget` and `unzip` commands are required to use this function.

- M-x `cdnjs-list-packages'

  List packages that are retrieved from cdnjs.

- M-x `cdnjs-describe-package'

  Describe the package information.

- M-x `cdnjs-insert-url'

  Insert URL of a JavaScript or CSS package.

- M-x `cdnjs-select-and-insert-url'

  Select version and file of a JavaScript or CSS package, then insert URL.

- M-x `cdnjs-update-package-cache'

  Update the package cache file.


Customization:

- `cdnjs-completing-read-function' (default `ido-completing-read')

  Function to be called when requesting input from the user.

- `cdnjs-gocdnjs-program' (default `~/.gocdnjs/bin/gocdnjs')

  Name of `gocdnjs' command.
