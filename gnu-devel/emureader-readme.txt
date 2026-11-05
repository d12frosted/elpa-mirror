                               ━━━━━━━━━━
                                EΜREADER
                               ━━━━━━━━━━


<file:extras/emureader-logo.png>

[Previously] called The Emacs Reader.

An all-in-one document reader for GNU Emacs, supporting all [major
document formats]. This package intends to take from `doc-view',
`nov.el', and `pdf-tools' and make them better. And as such, it is
effectively a *drop-in replacement* for them.


[Previously]
<https://codeberg.org/MonadicSheep/emureader/issues/65#issuecomment-27013757>

[major document formats] See section 2


1 EMuReader at Emacsconf 2025
═════════════════════════════

  <https://media.emacsconf.org/2025/emacsconf-2025-reader--an-introduction-to-the-emacs-reader--divy--main.webm>


2 Supported Formats
═══════════════════

  EMuReader (via MuPDF) can open all the formats below.


2.1 Well-supported Formats
──────────────────────────

  ⁃ PDF
  ⁃ EPUB
  ⁃ MOBI
  ⁃ FB2
  ⁃ XPS/OpenXPS
  ⁃ CBZ


2.2 Office Document Formats
───────────────────────────

  These formats below are not really for document reading, and as such
  while they are supported by MuPDF and can be opened fine, it’s just
  not going to be that good of an experience. It should only be used for
  quickly checking the textual contents of the document, and certainly
  cannot be edited inside Emacs. (You may use LibreOffice for that.)


2.2.1 Open Document Formats (LibreOffice)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ⁃ ODT
  ⁃ ODS
  ⁃ ODP
  ⁃ ODG


2.2.2 Proprietary Formats
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Using these formats is heavily discouraged, you should /always/ prefer
  the above formats from LibreOffice (Which can also you help you edit
  these formats if you need to). But since MuPDF does come with some
  very minimal support for these proprietary formats as well, they can
  also be viewed:

  ⁃ DOCX
  ⁃ PPTX
  ⁃ XLSX


3 Installation
══════════════

  You can install it from [GNU ELPA] via `M-x package-install RET
  emureader RET'.

  Or if you use `use-package',
  ┌────
  │ (use-package emureader)
  └────

  ⁃ Dependencies
    • `mupdf' @ `v1.26.0'
    • `gcc'
    • `GNU Make'


[GNU ELPA] <https://elpa.gnu.org/packages/emureader.html>

3.1 GNU/Linux distribution specific instructions
────────────────────────────────────────────────

3.1.1 GNU Guix
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ guix install emacs-emureader
  └────

  This will get the latest release of emureader. However, if you want to
  get latest features, bug fixes (and bugs!) to help us with testing
  emureader, you should use the master branch. You can instruct Guix to
  get it for you, like so,
  ┌────
  │ guix install emacs-emureader --with-branch=emacs-emureader=master
  └────

  You can also upgrade an already installed package with,
  ┌────
  │ guix upgrade emacs-emureader --with-branch=emacs-emureader=master
  └────

  You may replace the branch name as you need.


3.1.2 Debian GNU/Linux
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Follow this [write up].


[write up]
<https://codeberg.org/monadicsheep/emureader/issues/122#issuecomment-9315806>


3.1.3 Nix
╌╌╌╌╌╌╌╌╌

  Follow the instructions [here].


[here] <https://codeberg.org/monadicsheep/emureader/issues/115>


3.2 MacOS specific instructions
───────────────────────────────

  Install MuPDF using Homebrew,
  ┌────
  │ brew install gcc
  │ brew install make
  │ brew install mupdf
  └────

  Find more information [here].


[here]
<https://codeberg.org/monadicsheep/emureader/issues/142#issuecomment-8854941>


3.3 Manual
──────────

3.3.1 User lisp directory (recommended)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  1. Clone the repository into `~/.emacs.d/user-lisp/',
     ┌────
     │ git clone https://codeberg.org/monadicsheep/emureader ~/.emacs.d/user-lisp/emureader
     └────

     You may also symlink an existing checkout instead.
  2. You may now run `M-x prepare-user-lisp RET' or restart Emacs to
     make Emacs automatically prepare and load emureader.
  3. You also need to build the dynamic module, for this we provide the
     `M-x emureader-build RET'. But you can also run `make' directly
     yourself.


3.3.2 package-vc
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can also utilize `use-package' to do the same, put the following
  in your configuration,
  ┌────
  │ (use-package emureader
  │   :vc t
  │   :load-path "/path/to/emureader")
  └────


3.3.3 In `emacs -Q'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  To test emureader in a default Emacs config, first generate the auto
  loads using `make autoloads'.
  ┌────
  │ emacs -Q -L . -l emureader-autoloads.el
  └────
  This command adds the current directory to path, and loads
  `emureader-autoloads.el'.


4 Key Bindings
══════════════

  • `n' for going to next page
  • `p' for going to previous page
  • `C-n' for scrolling down.
  • `C-p' for scrolling up.
  • `C-b' for scrolling left.
  • `C-f' for scrolling right.
  • `Q' for closing the EMuReader buffer.
  • `M-<' for going to the first page.
  • `M->' for going to the last page.
  • `M-g g' for going to a particular page.
  • `M-v' or `Page Up' for scrolling to the top of the page.
  • `C-v' or `Page Down' for scrolling to the end of the page.
  • `SPC', `S-SPC' , and `DEL' make the above two commands keep
    scrolling the pages.
  • `=', `+', and `C-<wheel-up>' for zooming into the page.
  • `-' and `C-<wheel-down>' for zooming out of the page.
  • `H' to make the page fit the height of the current window.
  • `W' to make the page fit the width of the current window.


5 How It Works
══════════════

  This package is entirely distinct from `DocView' and `pdf-tools' in
  both its architecture and implementation. It leverages Emacs’
  dynamic/native modules which allows it to interoperate with other
  programming languages outside of its Emacs Lisp environment.

  Thus, we rely on the efficient MuPDF library as a shared object with
  which our dynamic modules work. All the tasks that require manual
  memory management, efficiently dealing with the rendered pages, and so
  on are delegated to the C backend, and Emacs takes care of exclusively
  what it’s good at: displaying produced pages, buffer management, and
  all round integration with the rest of Emacs.

  For understanding how dynamic modules work within Emacs, please
  consult the following article I wrote:

  <https://www.phimulambda.org/blog/emacs-dynamic-module.html>


6 Live Streams
══════════════

  I have been streaming the development of this package on [my PeerTube
  channel: (phi (mu (lambda)))].

  [The streams] happen on *Sundays, biweekly at around 2:30 PM
  UTC*. Follow the channel on Peertube or my [Mastodon] to be notified
  when I stream. You can also find some stream notes [here].

  If you wish to join the discussion for the package, you should join
  the IRC channel `#phi-mu-lambda' on [Libera].


[my PeerTube channel: (phi (mu (lambda)))]
<https://tv.dyne.org/c/phimulambda/>

[The streams] <https://tv.dyne.org/w/p/2A6UVt21hayJ3dVj5cU4yA>

[Mastodon] <https://mathstodon.xyz/@divyaranjan>

[here] <file:doc/>

[Libera] <https://libera.chat/>


7 License
═════════

  Unless another license is listed, all files in emureader are licensed
  under the GNU General Public License version 3 (or at your option, any
  later version). See [COPYING] and [CONTRIBUTORS] for further details.

  The logo of the project was made by Divya Ranjan Pattanaik and is
  shared under [CC-BY-SA-4.0]. The logo uses the following artworks from
  GNU:

  • [A Bold GNU Head by Aurélio A. Heckert]
  • [Icon for Emacs 23 by Kentaro Ohkouchi]

  The interesting history of different Emacs logos is outlined by Luis
  Fernandes, in his article on [The Design of the Emacs Logo].


[COPYING] <file:COPYING>

[CONTRIBUTORS] <file:CONTRIBUTORS>

[CC-BY-SA-4.0] <http://creativecommons.org/licenses/by-sa/4.0/>

[A Bold GNU Head by Aurélio A. Heckert]
<https://www.gnu.org/graphics/heckert_gnu.html>

[Icon for Emacs 23 by Kentaro Ohkouchi]
<https://commons.wikimedia.org/wiki/File:Emacs_512.png>

[The Design of the Emacs Logo]
<https://www.ee.torontomu.ca/~elf/emacs/logo/>
