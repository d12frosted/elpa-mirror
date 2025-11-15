


1 Emacs MATLAB-mode
═══════════════════

  [MathWorks] MATLAB® and [GNU Emacs] integration:

  1. MATLAB mode, *matlab-ts-mode* or *matlab-mode*, for editing `*.m'
     files.

     • Edit MATLAB code with syntax highlighting and smart indentation.
     • Lint MATLAB code with fix-it's using the MATLAB Code Analyzer.

     The *matlab-ts-mode* is a more capable, performant, and accurate
     than *matlab-mode*.

  2. *Code navigation and more*

     • The [MATLAB Language Server with Emacs], matlabls, provides code
       navigation, code completion, go to definition, find references,
       and more.

     • Imenu support for quickly jumping to function declarations in the
       current `*.m' or `*.tlc' file.  See [doc/matlab-imenu.org].

  3. *M-x matlab-shell* for running and debugging MATLAB within Emacs
      (Unix only).

     • MATLAB command window errors are hyper-linked and files open in
       Emacs
     • Debugging support is available from the MATLAB menu.
     • matlab-shell uses company-mode for completions.

     See [doc/matlab-shell-for-unix.org]

  4. *M-x matlab-shell* to run remote Unix MATLAB within your local
      Emacs session.

     ┌────
     │ +----------------+                 +-----------------+
     │ | Local Computer |                 | Remote Computer |
     │ |                |<===============>|                 |
     │ |     Emacs      |      ssh        |      MATLAB     |
     │ +----------------+                 +-----------------+
     └────

     You use Emacs on your local computer to edit files on the remote
     computer, run and debug remote MATLAB in a matlab-shell in your
     local Emacs.  See [doc/remote-matlab-shell.org].

  5. *M-x matlab-netshell* for running MATLAB code on Microsoft Windows
     within Emacs using an attached MATLAB.

     ┌────
     │ +--------------- Emacs ----------------+         +------------  MATLAB  ------------+
     │ |                                      |         |                                  |
     │ | (1) M-x matlab-netshell-server-start |         | (2) connect to Emacs             |
     │ |                                      |<=======>| >> addpath <matlab-mode>/toolbox |
     │ | (3) Visit script *.m files and use   |         | >> emacsinit                     |
     │ |     "MATLAB -> Code Sections" menu   |         | >>                               |
     │ |     or the key bindings              |         |                                  |
     │ +--------------------------------------+         +----------------------------------+
     └────

  6. *Code sections* support for MATLAB script files. See
      [doc/matlab-code-sections.org].

     • After visiting a MATLAB script, you have a *"MATLAB -> Code
       Sections"* menu and key bindings which lets you navigate, run,
       and move code sections.

     • Try out code sections using:
       [./examples/matlab-sections/tryout_matlabsection.m].

  7. *Creation of scientific papers, theses, and documents* using MATLAB
      and <http://orgmode.org>.

     • Org enables [literate programming] which directly supports
       reproducible research by allowing scientists and engineers to
       write code along with detailed explanations in natural language.

     • You author code plus natural language descriptive text in `*.org'
       files. When you evaluate MATLAB or other language code blocks
       within the `*.org' files, org inserts the results back into the
       `*.org' file.

     • You can combine multiple `*.org' files into one final document,
       thus enabling larger scientific documents.

     • See [./examples/matlab-and-org-mode/] to get started. This
       directory contains a [PDF] generated from
       [./examples/matlab-and-org-mode/matlab-and-org-mode.org].

  8. *tlc-mode* for editing `*.tlc' files. The Target Language Compiler
     (TLC) is part of Simulink® Coder™.


[MathWorks] <https://mathworks.com>

[GNU Emacs] <https://www.gnu.org/software/emacs/>

[MATLAB Language Server with Emacs]
<file:doc/matlab-language-server-lsp-mode.org>

[doc/matlab-imenu.org] <file:doc/matlab-imenu.org>

[doc/matlab-shell-for-unix.org] <file:doc/matlab-shell-for-unix.org>

[doc/remote-matlab-shell.org] <file:doc/remote-matlab-shell.org>

[doc/matlab-code-sections.org] <file:doc/matlab-code-sections.org>

[./examples/matlab-sections/tryout_matlabsection.m]
<file:examples/matlab-sections/tryout_matlabsection.m>

[literate programming]
<https://en.wikipedia.org/wiki/Literate_programming>

[./examples/matlab-and-org-mode/] <file:examples/matlab-and-org-mode>

[PDF] <file:examples/matlab-and-org-mode/matlab-and-org-mode.pdf>

[./examples/matlab-and-org-mode/matlab-and-org-mode.org]
<file:examples/matlab-and-org-mode/matlab-and-org-mode.org>


2 Installation
══════════════

  1. Install the MATLAB package via [MELPA] or [ELPA]. MELPA contains
     the latest version.  To install from MELPA, add to your `~/.emacs'

     ┌────
     │ (require 'package)
     │ (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
     └────

     Restart Emacs and then

     ┌────
     │ M-x package-install RET matlab-mode RET
     └────


     Note: to see all available packages, `M-x RET list-packages RET'

  2. [Optional] Install the `company' package which is used for TAB
     completions.

     ┌────
     │ M-x package-install RET company RET
     └────

  3. [Optional] Install MATLAB tree-sitter for matlab-ts-mode, which
     provides improved editing capabilities and improved performance.

     After installing `matlab-mode'

     ┌────
     │ M-x matlab-ts-grammar-install
     └────


     The MATLAB tree-sitter leverages [Tree-sitter] to create a parse
     tree for MATLAB code.  The parse tree is updated incrementally and
     is robust to syntax errors. It is highly performant and achieves
     this by being implemented in C to create a shared object that is
     loaded into the Emacs process.  *matlab-ts-mode* leverages the
     MATLAB tree-sitter to give an improved MATLAB editing experience
     when compared with matlab-mode.

     See [doc/install-matlab-tree-sitter-grammar.org]

  4. [Optional] Install lsp-mode and the [MATLAB Language Server] for an
     improved editing experience.

  5. [Optional] Check your installation setup.

     If you are using *matlab-ts-mode*, visit a `*.m' MATLAB file and
     select the menu item:

     ┌────
     │ MATLAB -> Check setup
     └────


[MELPA] <https://melpa.org>

[ELPA] <https://elpa.gnu.org/>

[Tree-sitter] <https://tree-sitter.github.io/tree-sitter/>

[doc/install-matlab-tree-sitter-grammar.org]
<file:doc/install-matlab-tree-sitter-grammar.org>

[MATLAB Language Server] <file:doc/matlab-language-server-lsp-mode.org>

2.1 Install from this repository
────────────────────────────────

  If you are contributing to the Emacs MATLAB Mode package, see
  [contributing/install-emacs-matlab-from-git.org]


[contributing/install-emacs-matlab-from-git.org]
<file:contributing/install-emacs-matlab-from-git.org>


3 MathWorks Products ([https://www.mathworks.com])
══════════════════════════════════════════════════

  Emacs MATLAB-mode is designed to be compatible with the last six years
  of MathWorks products and may support even older versions of MathWorks
  products.


[https://www.mathworks.com] <https://www.mathworks.com>


4 License
═════════

  GPL3, <https://www.gnu.org/licenses/gpl-3.0.en.html> (see
  [License.txt])


[License.txt] <file:License.txt>


5 Community Support
═══════════════════

  [MATLAB Central]


[MATLAB Central] <https://www.mathworks.com/matlabcentral>


6 FAQ
═════

  See [doc/faq.org]


[doc/faq.org] <file:doc/faq.org>


7 Mailing list
══════════════

  <mailto:matlab-emacs-discuss@lists.sourceforge.net>

  <https://sourceforge.net/projects/matlab-emacs/>


8 Releases
══════════

  See [NEWS.org]


[NEWS.org] <file:NEWS.org>
