`read-only-cfg' is a GNU Emacs minor mode that can automatically make
 files read-only based on user configuration.  User configuration is
 very simple and only consists of prefix directories or regex patterns.

Installation

The package is available on `MELPA'.  To use the `MELPA' repository,
you can add the following codes to your init.el.

    (require 'package)
    (add-to-list 'package-archives
	    '("melpa" . "https://melpa.org/packages/") t)
    (package-initialize)
    (package-refresh-contents)

Now you can install `read-only-cfg' with:

    M-x package-install RET read-only-cfg RET

And enable with:

    (require 'read-only-cfg)
    (read-only-cfg-mode 1)


Alternatively, you can manually download or clone this repository
locally, and add this to your init.el:

    (add-to-list 'load-path "/path/to/read-only-cfg")
    (autoload 'read-only-cfg "read-only-cfg" nil t)
    (require 'read-only-cfg)
    (read-only-cfg-mode 1)

Usage

Add a read-only directory:

    M-x read-only-cfg-add-dir RET /path/to/you-directory RET

Add a read-only regex pattern:

    M-x read-only-cfg-add-regexp RET <regexp> RET

Or add this into your config:

    (require 'read-only-cfg)
    (read-only-cfg-add-dir "/path/to/your-directory/")
    (read-only-cfg-add-regexp "<regexp>")

And remove a read-only directory:

    M-x read-only-cfg-remove-dir RET /path/to/your-directory RET

Remove a read-only regex pattern:

    M-x read-only-cfg-remove-regexp RET <regexp> RET


Customization

Customize variable `read-only-cfg-update-file-buffer-state' to
determine whether to update the read-only state of all existing
file-buffer when this mode is enabled or disabled.
