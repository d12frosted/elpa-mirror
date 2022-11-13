	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     SCAD-MODE - EMACS MODE TO EDIT OPENSCAD FILES
	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Features
2. Org Babel support
3. Installation





1 Features
══════════

  • Syntax highlighting
  • Basic completion function (press `M-TAB')
  • Preview rendered model in separate window (press `C-c C-c')
  • Open buffer in OpenSCAD (press `C-c C-o')
  • Export buffer with OpenSCAD (press `C-c C-e')
  • Flymake support (enable `flymake-mode' in `scad-mode' buffers)


2 Org Babel support
═══════════════════

  ┌────
  │ for (y=[0:2:20]) {
  │     translate([0,0,y+1])
  │ 	cube([30-2*y,30-2*y,2], true);
  │ }
  └────


3 Installation
══════════════

  Install via `M-x package-install RET scad-mode RET' from MELPA.
