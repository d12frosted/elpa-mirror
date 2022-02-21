Table of Contents
─────────────────

1. Introduction
2. Installation
.. 1. ELPA
.. 2. Direct download
3. Usage


1 Introduction
══════════════

  `nspawn-tramp' adds support for `systemd-nspawn' containers with
  Emacs’ TRAMP system.


2 Installation
══════════════

2.1 ELPA
────────

  This package is available on [GNU ELPA] and can be installed with `M-x
  package-install RET nspawn-tramp RET' from within Emacs itself.


[GNU ELPA] <https://elpa.gnu.org/packages/nspawn-tramp.html>


2.2 Direct download
───────────────────

  Download this repository to some location, then add the following to
  your Emacs initialization:
  ┌────
  │ (add-to-list 'load-path "/path/to/nspawn-tramp")
  │ (require 'nspawn-tramp)
  └────


3 Usage
═══════

  Call `nspawn-tramp-setup' to add support:
  ┌────
  │ (add-hook 'after-init-hook 'nspawn-tramp-setup)
  └────


  Use TRAMP as normal to access files on a container:
  ┌────
  │ C-x C-f /nspawn:user@container:/path/to/file
  └────
