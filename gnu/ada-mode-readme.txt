Emacs Ada mode version 8.0.4

Ada mode provides auto-casing, fontification, navigation, and
indentation for Ada source code files.

Cross-reference via Emacs xref can use an xref backend provided by the
gpr-query package, or a language server via the eglot package; they
must be installed separately. Ada mode uses whichever of these is
found on PATH, defaulting to gpr-query.

Ada mode uses a parser to provide fontification, single-file
navigation, and indentation. Ada mode allows using eglot as the
backend for these, but the current version of AdaCore
ada_language_server only supports single and multi-file navigation.
The wisi parser backend supports all Ada mode functions, is
implemented in Ada, is fast enough even for very large files (via
partial or incremental parsing), and recovers from almost all syntax
errors.

The wisi parser is provided as Ada source code that must be compiled and
installed, either directly or via Alire (https://alire.ada.dev/):

cd ~/.emacs.d/elpa/ada-mode-i.j.k
./build.sh
./install.sh

install.sh can take an option "--prefix=<dir>" to set the installation
directory.

Both shell scripts use Alire if the 'alr' executable is found in PATH.

Ada mode will be automatically loaded when you open a file
with a matching extension (default *.ads, *.adb).

Ada mode uses project files to define large (multi-directory)
projects, and to define casing exceptions.

See ada-mode.info for help on using and customizing Ada mode.
