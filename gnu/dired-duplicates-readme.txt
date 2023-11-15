           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            DIRED-DUPLICATES - FIND DUPLICATE FILES ON LOCAL
                         AND REMOTE FILESYSTEMS
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Description
═════════════

  This Emacs package helps to find duplicate files on local and remote
  filesystems.  It is similar to the fdupes command-line utility but
  written in Emacs Lisp and should also work on every remote filesystem
  that TRAMP supports.  The most common use case for this is probably
  finding and deleting unneeded duplicate files.

  dired-duplicates works by first searching files of the same size, then
  invoking the calculation of the checksum for these files, and finally
  presenting the grouped results in a Dired buffer that the user can
  work with similarly to a regular Dired buffer.  It might be even
  possible to combine this with other Dired extension packages like
  `dired-narrow' for increased productivity.

  By default, the results will be grouped visually by separating them
  using empty lines, but this grouping can also be deactivated by
  setting the custom variable `dired-duplicates-separate-result' to
  `nil'.

  dired-duplicates will silently ignore unreadable directories and
  files.


2 Requirements
══════════════

  For performance reasons, a checksum program like `md5' or `sha256sum'
  will be used for generating checksums of file contents if available
  and executable on the local and/or remote hosts.  That way, no files
  need to be read over possibly slow networks, thus calculating the
  checksum will be much faster when directly executed on remote hosts.
  The name of the checksum program can be customized.  If unavailable,
  the file contents will be inserted into a temp buffer and the checksum
  will be calculated using the `secure-hash' functions with an
  appropriate algorithm.  While this works everywhere, it is generally
  slower and could cause out-of-memory problems so there is a
  customizable `dired-duplicates-internal-checksumming-size-limit'
  setting.  Files bigger than this setting will not be processed, and a
  warning will be issued instead.


3 Installation
══════════════

  The package can be installed from MELPA or GNU ELPA via the Emacs
  package manager, e.g. `package-install'.  Or you use the following
  use-package snippet:
  ┌────
  │ (use-package dired-duplicates)
  └────


4 Usage
═══════

  Call `dired-duplicates' interactively and provide one or more
  directories (usually separated by commas) to search in recursively.


5 Configuration
═══════════════

  You can find all available customization options with
  `customize-group', entering `dired-duplicates' for the desired group.
  These options are described extensively there.


6 Known issues and reporting bugs
═════════════════════════════════

6.1 Known issue with completing-multiple-read
─────────────────────────────────────────────

  At the moment, there is a problem in Emacs 28.1 and perhaps other
  versions with `completing-read-multiple' that makes auto-completion
  fail.  When you try to specify more than one directory separated by
  commas (e.g. `/tmp/1,/tmp/2'), an error /may/ occur depending on the
  completing system.  In such a case, you might just do without
  auto-completion and ignore that error, dired-duplicates will still
  function properly if you provide valid directories.


6.2 Reporting bugs
──────────────────

  Just open an issue at the homepage of this project in case you hit an
  error, and provide proper steps to reproduce the problem.


7 License
═════════

  This package is licensed under GPL-3.  See the `LICENSE' file for more
  information.
