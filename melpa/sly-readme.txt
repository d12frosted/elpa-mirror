
       _____    __   __  __
      / ___/   / /   \ \/ /               |\      _,,,---,,_
      \__ \   / /     \  /                /,`.-'`'    -.  ;-;;,_
     ___/ /  / /___   / /                |,4-  ) )-,_..;\ (  `'-'
    /____/  /_____/  /_/                '---''(_/--'  `-'\_)


SLY is Sylvester the Cat's Common Lisp IDE.

SLY is a direct fork of SLIME, and contains the following
improvements over it:

* A full-featured REPL based on Emacs's `comint.el`;
* Live code annotations via a new `sly-stickers` contrib;
* Consistent button interface. Every Lisp object can be copied to the REPL;
* flex-style completion out-of-the-box, using  Emacs's completion API.
  Company, Helm, and others supported natively, no plugin required;
* Cleanly ASDF-loaded by default, including contribs, enabled out-of-the-box;
* Multiple inspectors and multiple REPLs;
* An interactive trace dialog with interactive objects.  Copies function calls
  to the REPL;
* "Presentations" replaced by interactive backreferences which
  highlight the object and remain stable throughout the REPL session;

SLY is a fork of SLIME. We track its bugfixes, particularly to the
implementation backends.  All SLIME's familar features (debugger,
inspector, xref, etc...) are still available, with improved overall
UX.

See the NEWS.md file (should be sitting alongside this file) for
more information
