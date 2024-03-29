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
  files, and also unregular files, such as sockets.


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

  Call `dired-duplicates' interactively using M-x and provide one or
  more directories to search in recursively.  If not customized
  otherwise, the key shortcut M-n usually gets you the default directory
  in the minibuffer prompt.  For some completion systems like vertico
  and depending on how it is set up, remember to hit M-RET to confirm
  the completion if you are not at the end of the line.

  If you provide a prefix, using C-u M-x `dired-duplicates', then this
  behaves similar but will search for files which do _NOT_ have any
  duplicates.  This might be more helpful than listing all the duplicate
  files when comparing directories that have mostly the same contents
  except a few files.


5 Configuration
═══════════════

  You can find all available customization options with
  `customize-group', entering `dired-duplicates' for the desired group.
  These options are described extensively there.


6 Reporting bugs
════════════════

  If checksumming or accessing a file fails, it should be reported in
  the minibuffer (interrupting the operation), or in the *Messages*
  buffer.

  Just open an issue at the homepage of this project in case you hit an
  error that you think should not happen, but please provide proper
  steps to reproduce the problem.


7 License
═════════

  This package is licensed under GPL-3.  See the `LICENSE' file for more
  information.
