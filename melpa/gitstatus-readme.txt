Common front-end for `gitstatusd'.
Extracts the Git status information and returns it usually fontified and
suitable for end-user presentation, for example, as a part of a prompt.
Additional package for the `eshell' prompt is provided for your convenience.

Note, the package wraps an external executable called "gitstatusd"
(see <https://github.com/romkatv/gitstatus>).  The executable is distributed
under GNU General Public License v3.0 and provides a much faster alternative
to "git status" and "git describe".  It works on Linux, macOS, FreeBSD, Android,
WSL, Cygwin and MSYS2.  The original work includes scripts to be used in
Bash and Zsh shells' prompts.
The executable has to be installed on the end-user machine for the package
to work.
