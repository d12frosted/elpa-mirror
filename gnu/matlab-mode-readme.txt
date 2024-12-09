


1 Emacs MATLAB-mode
═══════════════════

  [MathWorks] MATLAB® and [GNU Emacs] integration:

  1. matlab-mode for editing `*.m' files.

     • Edit MATLAB code with syntax highlighting and smart indentation.
     • Lint MATLAB code with fix-it's using the MATLAB Code Analyzer.

  2. `M-x matlab-shell' for running and debugging MATLAB within Emacs
     (Unix-only).

     • matlab-shell uses company-mode for completions.

  3. MATLAB and <http://orgmode.org> for creation of scientific papers,
     theses, and documents.

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

  4. tlc-mode for editing `*.tlc' files. The Target Language Compiler
     (TLC) is part of Simulink® Coder™.


[MathWorks] <https://mathworks.com>

[GNU Emacs] <https://www.gnu.org/software/emacs/>

[literate programming]
<https://en.wikipedia.org/wiki/Literate_programming>

[./examples/matlab-and-org-mode/] <file:examples/matlab-and-org-mode>

[PDF] <file:examples/matlab-and-org-mode/matlab-and-org-mode.pdf>

[./examples/matlab-and-org-mode/matlab-and-org-mode.org]
<file:examples/matlab-and-org-mode/matlab-and-org-mode.org>


2 Installation
══════════════

2.1 Install via MELPA
─────────────────────

  Installing via [MELPA] is recommended because MELPA will contain the
  latest validated release.

  Add to your `~/.emacs':

  ┌────
  │ (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
  └────

  then run

  ┌────
  │ M-x RET package-list-packages RET
  └────


[MELPA] <https://melpa.org>


2.2 Install from this repository
────────────────────────────────

  Build:

  ┌────
  │ cd /path/to/Emacs-MATLAB-mode
  │ 
  │ # Build lisp and run tests (requires MATLAB executable):
  │ make
  │ # Alternatively, build lisp and run tests using a specific MATLAB executable:
  │ make MATLAB_EXE=/path/to/matlab
  │ 
  │ # If desired, you can separate the building of lisp and running tests using:
  │ make lisp
  │ make tests
  │ make tests MATLAB_EXE=/path/to/matlab # if using a specific MATLAB executable
  └────

  Add the following to your `~/.emacs' file:

  ┌────
  │ (add-to-list 'load-path "/path/to/Emacs-MATLAB-mode")
  │ (load-library "matlab-autoload")
  └────


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

6.1 How do I customize matlab-mode?
───────────────────────────────────

  You can configure matlab-emacs using the "matlab" or "matlab-shell"
  customization groups:

  ┌────
  │ Emacs -> Options -> Customize Emacs -> Specific Group
  └────


6.2 How do I customize "edit file.m" behavior?
──────────────────────────────────────────────

  By default when you run

  ┌────
  │ M-x matlab-shell
  │ 
  │ >> edit file.m
  └────

  file.m will open in emacs using 'emacsclient -n'. matlab-shell achieve
  this behavior by instructing MATLAB to use 'emacsclient -n' as the
  external text editor.

  You can customize this by setting `matlab-shell-emacsclient-command'
  in the matlab-shell customization group. You can change this command
  to what's appropriate. If you set it to the empty string, 'edit
  file.m' will use the default MATLAB editor setting.

  The default MATLAB editor setting is controlled in the MATLAB
  preferences, (e.g. R2018a Home tab, Environment section, Preferences)
  where you can select which editor you want to edit a text file. MATLAB
  Editor or an external text editor. If you always want to use Emacs as
  your matlab editor even when running MATLAB outside of emacs, select
  Text editor and set it to the appropriate 'emacsclient -n' command.


6.3 The code-sections are not highlighted properly. What do I do?
─────────────────────────────────────────────────────────────────

  There can be several reasons for this. One reason would be if you are
  using syntax highlighting from a different package (such as
  tree-sitter) which is over-riding the font-lock provided by
  matlab-mode.

  In this case, add the following hook to your config:
  ┌────
  │ (add-hook 'matlab-sections-mode-hook
  │ 	(lambda () (interactive)
  │ 	    (font-lock-add-keywords
  │ 	   nil
  │ 	   `((,matlab-sections-section-break-regexp
  │ 		1 'matlab-sections-section-break-face prepend)))
  │ 	    (font-lock-flush)))
  └────
  Ensure that this is included after matlab-mode as well as your syntax
  highlighter are initialized in your config.


7 History
═════════

  matlab-mode has a history dating back many years. Older contributions
  can be found in [https://sourceforge.net/projects/matlab-emacs/].


[https://sourceforge.net/projects/matlab-emacs/]
<https://sourceforge.net/projects/matlab-emacs/>
