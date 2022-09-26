Table of Contents
─────────────────

1. Introduction
2. Installation
.. 1. ELPA
.. 2. Direct download
3. Usage


1 Introduction
══════════════

  `tramp-nspawn' adds support for `systemd-nspawn' containers with
  Emacs’ TRAMP system.


2 Installation
══════════════

2.1 ELPA
────────

  This package is available on [GNU ELPA] and can be installed with `M-x
  package-install RET tramp-nspawn RET' from within Emacs itself.


[GNU ELPA] <https://elpa.gnu.org/packages/nspawn-tramp.html>


2.2 Direct download
───────────────────

  Download this repository to some location, then add the following to
  your Emacs initialization:
  ┌────
  │ (add-to-list 'load-path "/path/to/tramp-nspawn")
  │ (require 'tramp-nspawn)
  └────


3 Usage
═══════

  Call `tramp-nspawn-setup' to add support:
  ┌────
  │ (add-hook 'after-init-hook 'tramp-nspawn-setup)
  └────


  Use TRAMP as normal to access files on a container:
  ┌────
  │ C-x C-f /nspawn:user@container:/path/to/file
  └────
