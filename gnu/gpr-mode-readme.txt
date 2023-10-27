Emacs gpr mode version 1.0.4

gpr mode provides auto-casing, fontification, navigation, and
indentation for gpr source code files.

gpr mode uses a parser to provide fontification, navigation, and
indentation. 

The parser is provided as Ada source code that must be compiled and
installed:

cd ~/.emacs.d/elpa/gpr-mode-i.j.k
./build.sh
./install.sh

install.sh can take an option "--prefix=<dir>" to set the installation
directory.

gpr mode will be automatically loaded when you open a file
with a matching extension (default *.gpr).

gpr mode uses wisi project files to define large (multi-directory)
projects, and to define casing exceptions.

See gpr-mode.info for help on using and customizing gpr mode.
