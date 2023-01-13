Emacs gpr-query version 1.0.2

gpr-query provides an emacs xref backend using the cross-reference
information output by the AdaCore GNAT compiler.

gpr-query uses a separate executable provided as Ada source code that
must be compiled and installed, either directly or using the Alire
package tool:

cd ~/.emacs.d/elpa/gpr-query-i.j.k
./build.sh
./install.sh

install.sh can take an option "--prefix=<dir>" to set the installation
directory.

Both shell scripts use Alire if the 'alr' executable is found in PATH.

See gpr-query.info section Installation for more information on
installing; if not using Alire, you may need additional packages.
