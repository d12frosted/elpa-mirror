
ECB stands for "Emacs Code Browser".  While Emacs already has good
*editing* support for many modes, its *browsing* support is somewhat
lacking. That's where ECB comes in: it displays a number of informational
windows that allow for easy source code navigation and overview.

The informational windows can contain:

- A directory tree,
- a list of source files in the current directory,
- a list of functions/classes/methods/... in the current file, (ECB uses
  the Semantic Bovinator, or Imenu, or etags, for getting this list so all
  languages supported by any of these tools are automatically supported by
  ECB too)
- a history of recently visited files,
- the Speedbar and
- output from compilation (the "*compilation*" window) and other modes like
  help, grep etc. or whatever a user defines to be displayed in this
  window.

As an added bonus, ECB makes sure to keep these informational windows visible,
even when you use C-x 1 and similar commands.

It goes without saying that you can configure the layout, ie which
informational windows should be displayed where. ECB comes with a number of
ready-made window layouts to choose from.

Here is an ascii-screenshot of what ECB offers you:

  ------------------------------------------------------------------
  |              |                                                 |
  | Directories  |                                                 |
  |              |                                                 |
  |--------------|                                                 |
  |              |                                                 |
  | Sources      |                                                 |
  |              |                                                 |
  |--------------|                   Edit-area                     |
  |              |    (can be splitted in several edit-windows)    |
  | Methods/Vars |                                                 |
  |              |                                                 |
  |--------------|                                                 |
  |              |                                                 |
  | History      |                                                 |
  |              |                                                 |
  ------------------------------------------------------------------
  |                                                                |
  |                 Compilation-window (optional)                  |
  |                                                                |
  ------------------------------------------------------------------


; Installation

To use the Emacs code browser add the ECB files to your load path and add the
following line to your .emacs file:

If you want autoloading ECB after first start:

   (require 'ecb-autoloads)

or if you want loading the complete ECB:

   (require 'ecb)

Optional: You can byte-compile ECB with `ecb-byte-compile' after the
          ECB-package is loaded


; Requirements

- Semantic, author-version between >= 1.4
  (http://cedet.sourceforge.net/semantic.shtml).
- Eieio, author-version >= 0.17
  (http://cedet.sourceforge.net/eieio.shtml).
- speedbar, author version >= 0.14beta1
  (http://cedet.sourceforge.net/speedbar.shtml)
- Optional: If Java code is edited the ECB works best when the JDEE package
  (http://sunsite.auc.dk/jde) is installed.


; Activation

ECB is either activated and started by calling
   M-x ecb-activate
or
   via the menu "Tools --> Start Code Browser (ECB)"

ECB can also be (de)activated/toggled by M-x ecb-minor-mode.

After activating ECB you should call `ecb-show-help' to get a detailed
description of what ECB offers to you and how to use ECB.


; Availability

The latest version of the ECB is available at http://ecb.sourceforge.net

; History

For the ChangeLog of this file see the CVS-repository. For a complete
history of the ECB-package see the file NEWS.
