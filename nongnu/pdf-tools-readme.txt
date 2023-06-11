			   ━━━━━━━━━━━━━━━━━━
			    PDF TOOLS README
			   ━━━━━━━━━━━━━━━━━━


[https://circleci.com/gh/vedang/pdf-tools.svg?style=svg]
[http://elpa.nongnu.org/nongnu/pdf-tools.svg]
[http://stable.melpa.org/packages/pdf-tools-badge.svg]
[http://melpa.org/packages/pdf-tools-badge.svg]
[https://ci.appveyor.com/api/projects/status/yqic2san0wi7o5v8/branch/master?svg=true]

The `pdf-tools' Wiki is maintained at <https://pdftools.wiki>. Head to
the site if you find it easier to navigate a website for reading a
manual. All the topics on the site are listed at
<https://pdftools.wiki/impulse>.


[https://circleci.com/gh/vedang/pdf-tools.svg?style=svg]
<https://app.circleci.com/pipelines/github/vedang/pdf-tools>

[http://elpa.nongnu.org/nongnu/pdf-tools.svg]
<https://elpa.nongnu.org/nongnu/pdf-tools.html>

[http://stable.melpa.org/packages/pdf-tools-badge.svg]
<https://stable.melpa.org/#/pdf-tools>

[http://melpa.org/packages/pdf-tools-badge.svg]
<https://melpa.org/#/pdf-tools>

[https://ci.appveyor.com/api/projects/status/yqic2san0wi7o5v8/branch/master?svg=true]
<https://ci.appveyor.com/project/vedang/pdf-tools>


1 About PDF Tools
═════════════════

  PDF Tools is, among other things, a replacement of DocView for PDF
  files. The key difference is that pages are not pre-rendered by, say,
  `ghostscript' and stored in the file-system, but rather created
  on-demand and stored in memory.

  This rendering is performed by a special library named, for whatever
  reason, `poppler', running inside a server program. This program is
  called `epdfinfo' and its job is to successively read requests from
  Emacs and produce the proper results, i.e. the PNG image of a PDF
  page.

  Actually, displaying PDF files is just one part of `pdf-tools'. Since
  `poppler' can provide us with all kinds of information about a
  document and is also able to modify it, there is a lot more we can do
  with it. [Watch this video for a detailed demo!]


[Watch this video for a detailed demo!]
<https://www.dailymotion.com/video/x2bc1is>


2 Installing pdf-tools
══════════════════════

  Installing this package via NonGNU ELPA or MELPA or any of the other
  package managers is straightforward and should just work! You should
  not require any manual changes. The documentation below is *only if
  you are installing from source*, or for troubleshooting / debugging
  purposes.

  `pdf-tools' requires a server `epdfinfo' to run against, which it will
  try to compile and build when it is activated for the first time. The
  following steps need to be followed *in this order*, to install
  `pdf-tools' and `epdfinfo' correctly:

  • 
  • 


2.1 Installing the epdfinfo server
──────────────────────────────────

  If you install `pdf-tools' via NonGNU ELPA or MELPA, *you don't need
  to worry about this separate server installation at all*.

  Note: You'll need GNU Emacs ≥ 26.3 and some form of a GNU/Linux
  OS. Other operating systems are not officially supported, but
  `pdf-tools' is known to work on many of them.

  The `epdfinfo' install script takes care of installing all the
  necessary pre-requisites on supported operating systems (see list
  below). See the section on to learn how to add your favorite Operating
  System to this list.

  Similarly, package-managers are not officially supported, but
  `pdf-tools' is known to be available on some of them. See the section
  on to avoid manual installation of server / server prerequisites.

  Installation Instructions for `epdfinfo':
  ┌────
  │ $ git clone https://github.com/vedang/pdf-tools
  │ $ cd /path/to/pdf-tools
  │ $ make -s # If you don't have make installed, run ./server/autobuild and it will install make
  └────

  This should give you no error and should compile the `epdfinfo'
  server. If you face a problem, please report on the issue tracker!

  The following Operating Systems / package managers are
  supported. *Note*: The package manager used to install pre-requisites
  should be installed on your OS for the script to work:

  • Debian-based systems (`debian', `ubuntu'): `apt-get'
  • Fedora: `dnf'
  • macOS: `brew'
  • Windows (MSYS2/ MingW): `pacman'
  • NixOS: `nix-shell'
  • openSUSE (Tumbleweed and Leap): `zypper'
  • Void Linux: `xbps-install'
  • Apline Linux: `apk'
  • FreeBSD: `pkg'
  • OpenBSD: `pkg_add'
  • NetBSD: `pkgin'
  • Arch Linux: `pacman'
  • Gentoo: `emerge'
  • CentOS: `yum'


2.1.1 Installing the epdfinfo server from package managers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `pdf-tools' can be directly installed from the package manager on some
  operating systems. Note that the packages available on these package
  managers are not maintained by the author and might be outdated.

  • Debian: <https://packages.debian.org/buster/elpa-pdf-tools-server>
  • Ubuntu: <https://packages.ubuntu.com/impish/elpa-pdf-tools-server>
  • MSYS2 / MINGW (Windows):
    <https://packages.msys2.org/package/mingw-w64-x86_64-emacs-pdf-tools-server?repo=mingw64>
  • FreeBSD:
    <https://repology.org/metapackages/?search=pdf-tools&inrepo=freebsd>


2.1.2 Installing the epdfinfo server from source on Windows (+ Gotchas)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If using the GNU binaries for Windows, support for PNG and `zlib' must
  first be installed by copying the appropriate dlls into emacs' `bin/'
  directory. Most third-party binaries come with this already done.

  1. [install MSYS2] and update the package database and core packages
     using the instructions provided.
  2. Open `mingw64' shell (*Note:* You must use `mingw64.exe' and not
     `msys2.exe')
  3. Compile the `epdfinfo' server using Installation steps described in
  4. This should produce a file `server/epdfinfo.exe'. Copy this file
     into the `pdf-tools/' installation directory in your Emacs.
  5. Make sure Emacs can find `epdfinfo.exe'. Either add the MINGW
     install location (e.g. `C:/msys2/mingw64/bin') to the system path
     with `setx PATH "C:\msys2\mingw64\bin;%PATH%"' or set Emacs's path
     with `(setenv "PATH" (concat "C:\\msys64\\mingw64\\bin;" (getenv
     "PATH")))'. Note that libraries from other GNU utilities, such as
     Git for Windows, may interfere with those needed by
     `pdf-tools'. `pdf-info-check-epdinfo' will succeed, but errors
     occur when trying to view a PDF file. This can be fixed by ensuring
     that the MSYS libraries are always preferred.
  6. `pdf-tools' will successfully compile using Cygwin, but it will not
     be able to open PDFs properly due to the way binaries compiled with
     Cygwin handle file paths. Please use MSYS2.


[install MSYS2] <https://www.msys2.org/>


2.1.3 Installing the epdfinfo server from source on macOS (+ Gotchas)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  On macOS, `autobuild' adjusts `PKG_CONFIG_PATH' so that `pdf-tools'
  can find some of the keg-only packages installed by `brew'. It is
  recommended that you review the output logs printed by `brew' during
  the installation process to also export the relevant paths to the
  appropriate ENV variables.


2.1.4 Common installation gotchas
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  In case you decide to install `libpoppler' from source, make sure to
  run its configure script with the `--enable-xpdf-headers' option.


2.1.5 Installing optional features
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  One feature – following links of a PDF document by plain keystrokes –
  requires `imagemagick''s convert utility. This requirement is
  optional, the installation process will detect if you have
  `imagemagick' installed or not.


2.2 Installing pdf-tools elisp code
───────────────────────────────────

  `pdf-tools' requires `tablist' package (>= version 0.70) to be
  installed, for it to work correctly. Please make sure that the latest
  version of `tablist' is installed.

  We have already run the steps necessary to install `pdf-tools' as part
  of ! These are:
  ┌────
  │ $ git clone https://github.com/vedang/pdf-tools
  │ $ cd /path/to/pdf-tools
  │ $ make -s
  └────

  If the `make' command produced the ELP file `pdf-tools-${VERSION}.tar'
  you are fine! This package contains all the necessary files for Emacs
  and may be installed by either using
  ┌────
  │ $ make install-package
  └────
  or executing the Emacs command
  ┌────
  │ M-x package-install-file RET pdf-tools-${VERSION}.tar RET
  └────

  You can test if the package has been installed correctly, by running
  ┌────
  │ M-x pdf-info-check-epdfinfo RET
  └────

  To complete the installation process, you need to activate the package
  by putting the code below somewhere in your `.emacs'.  Alternatively,
  and if you care about startup time, you may want to use the loader
  version instead.
  ┌────
  │ (pdf-tools-install)  ; Standard activation command
  │ (pdf-loader-install) ; On demand loading, leads to faster startup time
  └────

  Once the Installation process is complete, check out and to get
  started!


2.3 Updating pdf-tools
──────────────────────

  Some day you might want to update this package via `git pull' and then
  reinstall it. Sometimes this may fail, especially if Lisp-Macros are
  involved and the version hasn't changed. To avoid this kind of
  problems, you should delete the old package via `list-packages',
  restart Emacs, run `make distclean' and then reinstall the
  package. Follow the steps described in .

  This also applies when updating via MELPA / NonGNU ELPA (except for
  running the `make distclean' step).


3 Features
══════════

  View
        View PDF documents in a buffer with DocView-like bindings. .
  Isearch
        Interactively search PDF documents like any other buffer, either
        for a string or a PCRE.
  Occur
        List lines matching a string or regexp in one or more PDF
        documents.
  Follow
        Click on highlighted links, moving to some part of a different
        page, some external file, a website or any other URI. Links may
        also be followed by keyboard commands.
  Annotations
        Display and list text and markup annotations (like underline),
        edit their contents and attributes (e.g. color), move them
        around, delete them or create new ones and then save the
        modifications back to the PDF file. .
  Attachments
        Save files attached to the PDF-file or list them in a dired
        buffer.
  Outline
        Use `imenu' or a special buffer (`M-x pdf-outline') to examine
        and navigate the PDF's outline.
  SyncTeX
        Jump from a position on a page directly to the TeX source and
        vice versa.
  Virtual
        Use a collection of documents as if it were one, big single PDF.
  Misc
        • Display PDF's metadata.
        • Mark a region and kill the text from the PDF.
        • Keep track of visited pages via a history.
        • Apply a color filter for reading in low light conditions.


3.1 View and Navigate PDFs
──────────────────────────

  PDFView Mode is an Emacs PDF viewer. It displays PDF files as PNG
  images in Emacs buffers. PDFs are navigable using DocView-like
  bindings. Once you have installed `pdf-tools', opening a PDF in Emacs
  will automatically trigger this mode.


3.1.1 Keybindings for navigating PDF documents
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Navigation                                                             
  ────────────────────────────────────────────────────────────────────────
   Scroll Up / Down by Page-full                  `space' / `backspace'   
   Scroll Up / Down by Line                       `C-n' / `C-p'           
   Scroll Right / Left                            `C-f' / `C-b'           
   First Page / Last Page                         `<', `M-<' / `>', `M->' 
   Next Page / Previous Page                      `n' / `p'               
   Incremental Search Forward / Backward          `C-s' / `C-r'           
   Occur (list all lines containing a phrase)     `M-s o'                 
   Jump to Occur Line                             `RETURN'                
   Pick a Link and Jump                           `F'                     
   Incremental Search in Links                    `f'                     
   History Back / Forwards                        `l' / `r'               
   Display Outline                                `o'                     
   Jump to Section from Outline                   `RETURN'                
   Jump to Page                                   `M-g g'                 
   Store position / Jump to position in register  `m' / `''               
  ────────────────────────────────────────────────────────────────────────
                                                                        
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Note that `pdf-tools' renders the PDF as images inside Emacs. This
  means that all the keybindings of `image-mode' work on individual PDF
  pages as well.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Image Mode                                                          
  ─────────────────────────────────────────────────────────────────────
   image-scroll-right      `C-x >' / `<remap> <scroll-right>'          
   image-scroll-left       `C-x <' / `<remap> <scroll-left>'           
   image-scroll-up         `C-v' / `<remap> <scroll-up>'               
   image-scroll-down       `M-v' / `<remap> <scroll-down>'             
   image-forward-hscroll   `C-f' / `right' / `<remap> <forward-char>'  
   image-backward-hscroll  `C-b' / `left'  / `<remap> <backward-char>' 
   image-bob               `<remap> <beginning-of-buffer>'             
   image-eob               `<remap> <end-of-buffer>'                   
   image-bol               `<remap> <move-beginning-of-line>'          
   image-eol               `<remap> <move-end-of-line>'                
   image-scroll-down       `<remap> <scroll-down>'                     
   image-scroll-up         `<remap> <scroll-up>'                       
   image-scroll-left       `<remap> <scroll-left>'                     
   image-scroll-right      `<remap> <scroll-right>'                    
  ─────────────────────────────────────────────────────────────────────
                                                                     
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.1.2 Keybindings for manipulating display of PDF
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Display                                                   
  ───────────────────────────────────────────────────────────
   Zoom in / Zoom out                        `+' / `-'       
   Fit Height / Fit Width / Fit Page         `H' / `W' / `P' 
   Trim Margins (set slice to bounding box)  `s b'           
   Reset Margins                             `s r'           
   Reset Zoom                                `0'             
   Rotate Page                               `R'             
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.2 Annotations
───────────────

  `pdf-tools' supports working with PDF Annotations. You can display and
  list text and markup annotations (like squiggly, highlight), edit
  their contents and attributes (e.g. color), move them around, delete
  them or create new ones and then save the modifications back to the
  PDF file.


3.2.1 Keybindings for working with Annotations
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Annotations                                                                             
  ─────────────────────────────────────────────────────────────────────────────────────────
   List Annotations                      `C-c C-a l'                                       
   Jump to Annotations from List         `SPACE'                                           
   Mark Annotation for Deletion          `d'                                               
   Delete Marked Annotations             `x'                                               
   Unmark Annotations                    `u'                                               
   Close Annotation List                 `q'                                               
   Enable/Disable Following Annotations  `C-c C-f'                                         
  ─────────────────────────────────────────────────────────────────────────────────────────
   Add and Edit Annotations              Select region via Mouse selection.                
                                         Then left-click context menu OR keybindings below 
  ─────────────────────────────────────────────────────────────────────────────────────────
   Add a Markup Annotation               `C-c C-a m'                                       
   Add a Highlight Markup Annotation     `C-c C-a h'                                       
   Add a Strikeout Markup Annotation     `C-c C-a o'                                       
   Add a Squiggly Markup Annotation      `C-c C-a s'                                       
   Add an Underline Markup Annotation    `C-c C-a u'                                       
   Add a Text Annotation                 `C-c C-a t'                                       
  ─────────────────────────────────────────────────────────────────────────────────────────
                                                                                         
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.3 Working with AUCTeX
───────────────────────

3.3.1 Keybindings for working with AUCTeX
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Syncing with AUCTeX                                        
  ────────────────────────────────────────────────────────────
   Refresh File (e.g., after recompiling source)  `g'         
   Jump to PDF Location from Source               `C-c C-g'   
   Jump Source Location from PDF                  `C-mouse-1' 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


3.4 Miscellaneous features
──────────────────────────

3.4.1 Keybindings for miscellaneous features in PDF tools
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━
   Miscellaneous            
  ──────────────────────────
   Print File     `C-c C-p' 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━


3.5 Easy Help for PDF Tools features
────────────────────────────────────

  ┌────
  │ M-x pdf-tools-help RET
  └────

  Run `M-x pdf-tools-help' inside Emacs, as shown above. It will list
  all the features provided by `pdf-tools' as well as the key-bindings
  for these features.


3.6 Configuring PDF Tools features
──────────────────────────────────

  Once you have read through the features provided by `pdf-tools', you
  probably want to customize the behavior of the features as per your
  requirements. Full customization of features is available by running
  the following:
  ┌────
  │ M-x pdf-tools-customize RET
  └────


4 Known problems
════════════════

4.1 linum-mode
──────────────

  `pdf-tools' does not work well together with `linum-mode' and
  activating it in a `pdf-view-mode', e.g. via `global-linum-mode',
  might make Emacs choke.


4.2 display-line-numbers-mode
─────────────────────────────

  This mode is an alternative to `linum-mode' and is available since
  Emacs 26. `pdf-tools' does not work well with it. For example, it
  makes horizontal navigation (such as `C-f', `C-b', `C-x <' or `C-x >'
  ) in a document impossible.


4.3 auto-revert
───────────────

  Autorevert works by polling the file-system every
  `auto-revert-interval' seconds, optionally combined with some
  event-based reverting via [file notification]. But this currently does
  not work reliably, such that Emacs may revert the PDF-buffer while the
  corresponding file is still being written to (e.g. by LaTeX), leading
  to a potential error.

  With a recent [AUCTeX] installation, you might want to put the
  following somewhere in your dotemacs, which will revert the PDF-buffer
  *after* the TeX compilation has finished.
  ┌────
  │ (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)
  └────


[file notification]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/File-Notifications.html>

[AUCTeX] <https://www.gnu.org/software/auctex/>


4.4 sublimity
─────────────

  L/R scrolling breaks while zoomed into a pdf, with usage of sublimity
  smooth scrolling features


4.5 Text selection is not transparent in PDFs OCRed with Tesseract
──────────────────────────────────────────────────────────────────

  In such PDFs the selected text becomes hidden behind the selection;
  see [this issue], which also describes the workaround in detail. The
  following function, which depends on the [qpdf.el] package, can be
  used to convert such a PDF file into one where text selection is
  transparent:
  ┌────
  │ (defun my-fix-pdf-selection ()
  │   "Replace pdf with one where selection shows transparently."
  │   (interactive)
  │   (unless (equal (file-name-extension (buffer-file-name)) "pdf")
  │     (error "Buffer should visit a pdf file."))
  │   (unless (equal major-mode 'pdf-view-mode)
  │     (pdf-view-mode))
  │   ;; save file in QDF-mode
  │   (qpdf-run (list
  │ 	     (concat "--infile="
  │ 		     (buffer-file-name))
  │ 	     "--qdf --object-streams=disable"
  │ 	     "--replace-input"))
  │   ;; do replacements
  │   (text-mode)
  │   (read-only-mode -1)
  │   (while (re-search-forward "3 Tr" nil t)
  │     (replace-match "7 Tr" nil nil))
  │   (save-buffer)
  │   (pdf-view-mode))
  └────
  Note that this overwrites the PDF file visited in the buffer from
  which it is run! To avoid this replace the `--replace-input' with
  `(concat "--outfile=" (file-truename (read-file-name "Outfile: ")))'.


[this issue] <https://github.com/vedang/pdf-tools/issues/149>

[qpdf.el] <https://github.com/orgtre/qpdf.el>


5 Key-bindings in PDF Tools
═══════════════════════════

  • 
  • 
  • 
  • 
  • 


6 Tips and Tricks for Developers
════════════════════════════════

6.1 Turn on debug mode
──────────────────────

  ┌────
  │ M-x pdf-tools-toggle-debug RET
  └────
  Toggling debug mode prints information about various operations in the
  `*Messages*' buffer, and this is useful to see what is happening
  behind the scenes


6.2 Run Emacs lisp tests locally
────────────────────────────────

  You can go to the `pdf-tools' folder and run `make test' to run the
  ERT tests and check if the changes you have made to the code break any
  of the tests.

  The tests are written in ERT, which is the built-in testing system in
  Emacs. However, they are run using `Cask' which you will have to
  install first, if you don't have it already. You can install `Cask' by
  following the instructions on their site at
  <https://github.com/cask/cask>


6.3 Run server compilation tests locally
────────────────────────────────────────

  You can go to the `pdf-tools' folder and run `make server-test' to
  check if the changes you have made to the server code break
  compilation on any of the supported operating systems.

  The tests build `Podman' images for all supported operating systems,
  so you will have to install `Podman' first, if you don't have
  already. You can install `Podman' by following the instructions on
  their site at <https://podman.io/getting-started/installation>

  Podman is compatible with Docker, so if you already have `docker'
  installed, you should be able to `alias podman=docker' on your shell
  and run the tests, without having to install Docker. (Note: I have not
  tested this)


6.4 Add a Dockerfile to automate server compilation testing
───────────────────────────────────────────────────────────

  The `server/test/docker' folder contains Dockerfile templates used for
  testing that the `epdfinfo' server compiles correctly on various
  operating systems ().

  To see the list of operating systems where compilation testing is
  supported, run `make server-test-supported'. To see the list of
  operating systems where testing is unsupported, run `make
  server-test-unsupported'. To add support, look into the
  `server/test/docker/templates' folder (`ubuntu' files are a good
  example to refer to)


6.5 Issue Template for Bug Reports
──────────────────────────────────

  Please use the 'Bug Report' issue template when reporting bugs. The
  template is as follows:


6.5.1 Describe the bug
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A clear and concise description of what the bug is.


6.5.2 Steps To Reproduce the behaviour:
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  1. Go to '…'
  2. Click on '….'
  3. Scroll down to '….'
  4. See error


6.5.3 What is the expected behaviour?
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  A clear and concise description of what you expected to happen.


6.5.4 Desktop
╌╌╌╌╌╌╌╌╌╌╌╌╌

  Please complete the following information:

  • OS: [eg: MacOS Catalina]
  • Emacs Version: [This should be the output of `M-x emacs-version' ]
  • Poppler Version: [eg: output of `brew info poppler' and similarly
    for other OSs]


6.5.5 Your pdf-tools install
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Please complete the following information:
  • `pdf-tools' Version: [ `M-x package-list-packages' -> Search for
    `pdf-tools' -> Hit Enter and copy all the details that pop up in the
    Help buffer]
  • `pdf-tools' customization / configuration that you use:


6.5.6 Additional context
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • If you are reporting a crash, please try and add the Backtrace /
    Stacktrace of the crash.
  • If you are reporting a bug, please try and attach an example PDF
    file where I can reproduce the bug.
  • If you can attach screenshots or recordings, that is a great help
  • Please try reproducing the bug yourself on Vanilla Emacs before
    reporting the problem.


7 FAQs
══════

7.1 PDFs are not rendering well!
────────────────────────────────

  `pdf-tools' version `1.1.0' release changed the default value of
  `pdf-view-use-scaling' to `t' (previously, it was `nil'). This has
  been done keeping in mind that most modern monitors are HiDPI screens,
  so the default configuration should cater to this user. If you are not
  using a HiDPI screen, you might have to change this value to `nil' in
  your configuration

  ┌────
  │ (setq pdf-view-use-scaling nil)
  └────

  to scale the images correctly when rendering them.


7.2 What Emacs versions does pdf-tools support?
───────────────────────────────────────────────

  `pdf-tools' supports the 3 latest versions of Emacs major releases. At
  the moment of this writing, this means that the minimum supported
  Emacs version is `26.3'.


7.3 I want to add support for pdf-tools on "My Fav OS". How do I do that?
─────────────────────────────────────────────────────────────────────────

  I'm working on automating `pdf-tools' installation as much as
  possible, in order to improve the installation experience. If you want
  to add support for a new / currently unsupported Operating System,
  please modify the `server/autobuild' script. Say you want to support a
  new Operating System called MyFavOS. You need to do the following
  work:

  1. Search for the `Figure out where we are' section. Here, add a call
     to `os_myfavos' right below `handle_options' at the end of the
     existing call chain. Here we try and pick up the correct Operating
     System and install the relevant dependencies.
  2. Add handling for the `--os' argument in `os_argument' for
     `myfavos', so that the appropriate function can be called to
     install pre-requisites. `--os' is the argument that we pass to the
     script from the command-line to indicate which OS we are on.
  3. Create a `os_myfavos' function. This function checks if we are
     running on MyFavOS. If we are running on MyFavOS, it sets up
     `PKGCMD', `PKGARGS' and `PACKAGES' variables so that the
     appropriate package manager can install the dependencies as part of
     the rest of the `autobuild' script.
  4. If you are adding support for your favorite operating system,
     consider adding automated testing support as well, to help me
     ensure that `epdfinfo' continues to compile correctly. See for more
     details.

  The idea here is to make the `server/autobuild' file the single place
  from which installation can happen on any Operating System. This makes
  building `pdf-tools' dead simple via the `Makefile'.

  This seems like a lot of work, but it is not. If you need a reference,
  search for `os_gentoo' or `os_debian' in the `server/autobuild' file
  and see how these are setup and used. The functions are used to
  install dependencies on Gentoo and Debian respectively, and are simple
  to copy / change.

  When you make your changes, please be sure to test as well as as
  described in the linked articles.


7.4 I am on a Macbook M1 and pdf-tools installation fails with a stack-trace
────────────────────────────────────────────────────────────────────────────

  There have been a number of issues around `pdf-tools' installation
  problems on M1. `M-x pdf-tools-install' throws the following stack
  trace:
  ┌────
  │ 1 warning generated.
  │ ld: warning: ignoring file /opt/homebrew/opt/gettext/lib/libintl.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ ld: warning: ignoring file /opt/homebrew/Cellar/glib/2.72.1/lib/libglib-2.0.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ ld: warning: ignoring file /opt/homebrew/Cellar/poppler/22.02.0/lib/libpoppler-glib.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ ld: warning: ignoring file /opt/homebrew/Cellar/glib/2.72.1/lib/libgobject-2.0.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ ld: warning: ignoring file /opt/homebrew/Cellar/poppler/22.02.0/lib/libpoppler.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ ld: warning: ignoring file /opt/homebrew/Cellar/cairo/1.16.0_5/lib/libcairo.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ ld: warning: ignoring file /opt/homebrew/Cellar/libpng/1.6.37/lib/libpng16.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ ld: warning: ignoring file /opt/homebrew/Cellar/zlib/1.2.11/lib/libz.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  │ Undefined symbols for architecture x86_64:
  └────

  This happens because M1 architecture is `ARM64', whereas the Emacs App
  you are using has been compiled for the `x86_64' architecture. The way
  to solve this problem is to install a version of Emacs which has been
  compiled for the M1. As of today, [2022-05-09 Mon], the latest version
  of Emacs available on <https://emacsformacosx.com/> is natively
  compiled and you will not face these issues on it. Please remove your
  current Emacs App and install it from <https://emacsformacosx.com/>.

  Thank you.

  PS: How do I know if the Emacs I'm running has been compiled
  correctly?

  You can see this by opening the `Activity Monitor', selecting `Emacs',
  clicking on the `Info' key, and then clicking on `Sample'. The `Code
  Type' field in the Sample output will show you how your Application
  has been compiled. Here is the output for EmacsForMacOSX (you can see
  that it's `ARM64'):
  ┌────
  │ Sampling process 61824 for 3 seconds with 1 millisecond of run time between samples
  │ Sampling completed, processing symbols...
  │ Analysis of sampling Emacs-arm64-11 (pid 61824) every 1 millisecond
  │ Process:         Emacs-arm64-11 [61824]
  │ Path:            /Applications/Emacs.app/Contents/MacOS/Emacs-arm64-11
  │ Load Address:    0x1007f0000
  │ Identifier:      org.gnu.Emacs
  │ Version:         Version 28.1 (9.0)
  │ Code Type:       ARM64
  │ Platform:        macOS
  └────

  If your Emacs is compiled for x86, the `Code Type' will be `x86_64'.


7.5 I am a developer, making changes to the pdf-tools source code
─────────────────────────────────────────────────────────────────

  Thank you for taking the time to contribute back to the code. You may
  find some useful notes in the section. Please be sure to check it out!
