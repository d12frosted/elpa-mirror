Emacs Ada mode version 7.2.0

Ada mode provides auto-casing, fontification, navigation, and
indentation for Ada source code files.

Cross-reference information output by the compiler is used to provide
powerful code navigation (jump to definition, find all uses, show
overriding, etc). By default, only the AdaCore GNAT compiler is
supported; other compilers can be supported. Ada mode uses gpr_query
to query compiler-generated cross reference information. 

Ada mode uses a parser to provide fontification, navigation, and
indentation. The parser is implemented in Ada, is fast enough even for very 
large files (via partial parsing), and recovers from almost all syntax
errors.

gpr_query and the parser are provided as Ada source code that must be
compiled and installed:

cd ~/.emacs.d/elpa/ada-mode-i.j.k
./build.sh
./install.sh

install.sh can take an option "--prefix=<dir>" to set the installation
directory.

See ada-mode.info section Installation for more information on
installing; you may need additional packages.

Ada mode will be automatically loaded when you open a file
with a matching extension (default *.ads, *.adb).

Ada mode uses project files to define large (multi-directory)
projects, and to define casing exceptions.

See ada-mode.info for help on using and customizing Ada mode.
