           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            DOC-VIEW-FOLLOW.EL: SYNCHRONIZE WINDOWS SHOWING
                           THE SAME DOCUMENT
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Overview
══════════

  doc-view-follow.el provides a minor mode, `doc-view-follow-mode', that
  automatically synchronizes page navigation between multiple windows
  displaying the same document (PS/PDF/DVI/DjVu, etc.).  This is
  essentially an analogue of Emacs' built-in `follow-mode', but for
  document buffers instead rather than text buffers.

  In particular, this allows for a convenient "book view," with two
  windows showing consecutive pages side-by-side.


2 Installation
══════════════

  `doc-view-follow.el' should soon be available on ELPA, so you can
  install it from there via `M-x packages-install'.

  Alternatively, download the source file and run:
  ┌────
  │ M-x package-install-file RET /path/to/doc-view-follow.el RET
  └────


2.1 PDF-Tools Support (Optional)
────────────────────────────────

  This package supports the built-in `doc-view-mode' as well as
  `pdf-view-mode' from [pdf-tools].  If you use pdf-tools, add the
  following to your init file:

  ┌────
  │ (with-eval-after-load 'pdf-view
  │   (require 'doc-view-follow-pdf-tools))
  └────


[pdf-tools] <https://github.com/vedang/pdf-tools>


3 Usage
═══════

  After installation, you can activate the mode:

  • Globally: `M-x global-doc-view-follow-mode'
  • Locally: `M-x doc-view-follow-mode'

  To enable synchronization by default, add to your Emacs configuration:

  ┌────
  │ (global-doc-view-follow-mode 1)
  └────


3.1 Example workflow:
─────────────────────

  1. Open a supported document in `doc-view-mode' or `pdf-view-mode'.
     (`doc-view-mode' is built-in; `pdf-view-mode' requires
     [pdf-tools].)
  2. Split the frame vertically (with default bindings, via `C-x 3').
  3. Activate `doc-view-follow-mode' if not already enabled.
  4. Navigate pages in either window with standard commands (e.g., `n',
     `p').

  Both windows will automatically stay synchronized.


[pdf-tools] <https://github.com/vedang/pdf-tools>


3.2 Convenience
───────────────

  Since `doc-view-follow-mode' works with document files (PDF, PS, etc.)
  and `follow-mode' works with text buffers, you might want `M-x
  follow-mode' to activate the appropriate mode based on your current
  buffer.  You can do this by customizing the user option
  `doc-view-follow-hijack', or adding `(setopt doc-view-follow-hijack
  t)' to your config.


3.3 Prefix Key Commands
───────────────────────

  When `doc-view-follow-mode' is active, you can use the following
  commands with the prefix key (by default `C-c .', the same as
  `follow-mode''s prefix):

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Key          Function                                 Description                                    
  ──────────────────────────────────────────────────────────────────────────────────────────────────────
   `C-c . 1'    `follow-delete-other-windows-and-split'  Delete other windows and split current one     
   `C-c . b'    `follow-switch-to-buffer'                Switch to another buffer in the current window 
   `C-c . C-b'  `follow-switch-to-buffer-all'            Switch to another buffer in all follow windows 
   `C-c . <'    `follow-first-window'                    Select the first window in the follow chain    
   `C-c . >'    `follow-last-window'                     Select the last window in the follow chain     
   `C-c . n'    `follow-next-window'                     Select the next window in the follow chain     
   `C-c . p'    `follow-previous-window'                 Select the previous window in the follow chain 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  The prefix key can be customized by changing `follow-mode-prefix-key'.


4 Extensibility
═══════════════

  The package uses generic functions, making it straightforward to add
  support for additional document viewing modes.
