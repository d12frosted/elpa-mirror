			     ━━━━━━━━━━━━━
			      URL-SCGI.EL
			     ━━━━━━━━━━━━━


			       2022-09-22


Table of Contents
─────────────────

1. Installation
2. Usage
3. Contact


This library add support for SCGI URLs to Emacs.  It is based on url.el,
which is shipped with Emacs.

The SCGI specification is available [here].  There is [a copy] in this
repository.


[here] <https://python.ca/scgi/protocol.txt>

[a copy] <file:doc/scgi-protocol.txt>


1 Installation
══════════════

  url-scgi.el is available on [GNU ELPA], which is enabled by default in
  Emacs.

  Find and install url-sgi.el using this command:

  ┌────
  │ M-x list-packages
  └────


[GNU ELPA] <https://elpa.gnu.org/>


2 Usage
═══════

  Usage, with xml-rpc.el:

  ┌────
  │ (require 'url-scgi)
  │ (xml-rpc-method-call "scgi://localhost:5000" "some.method")
  └────


3 Contact
═════════

  You can find the latest version of url-scgi.el here:

  <https://www.github.com/skangas/url-scgi>

  Bug reports, comments, and suggestions are welcome! Send them to
  Stefan Kangas <stefankangas@gmail.com> or report them on GitHub.
