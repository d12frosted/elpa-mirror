           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            PROJECT-NIX-STORE - PROJECT BACKEND FOR NIX-LIKE
                                 STORE
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This package is a `project.el' backend for Nix-like store.  Each store
path, if it is a directory, is a project root.  See `project-root' for
store path definition.

At the time of writing, this package also supports Guix store.

This package eases operations on store files with the help of project
interfaces described in Info node `Projects'.  For example, while
visiting a file under a store path, use `project-find-file' to quickly
visit another file under the same store path.


1 Usage
═══════

  Add `project-nix-store-try' to `project-find-functions'.  To ensure
  good performance, put it before `project-try-vc'.

  It is recommended to also add `project-nix-store-p' to
  `project-list-exclude'.

  See customization group `project-nix-store' for user options.

  To disable this package, remove `project-nix-store-try' from
  `project-find-functions' or call `unload-feature'.


2 Performance
═════════════

  Packages can call project interfaces quite frequently.  For example,
  at the time of writing, `breadcrumb.el' calls `project-current' and
  `project-name' a lot.

  This package aims for good performance.  It includes benchmarks for
  performance-sensitive functions.  Use those benchmarks when hacking
  this package.


3 License
═════════

  This package is [REUSE]-compliant.  To get the license and copyright
  of each file, run `reuse lint --json' or `reuse spdx'.

  As a best-effort summary, this package is licensed under
  GPL-3.0-or-later.


[REUSE] <https://reuse.software>
