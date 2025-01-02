            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             SCAD-MODE - EMACS MODE TO EDIT OPENSCAD FILES
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Features
══════════

  • Syntax highlighting
  • Basic completion function (press `M-TAB')
  • Preview rendered model in separate window (press `C-c C-c')
  • Open buffer in OpenSCAD (press `C-c C-o')
  • Export buffer with OpenSCAD (press `C-c C-e')
  • Flymake support (enable `flymake-mode' in `scad-mode' buffers)
  • Org Babel support (`scad' source blocks)


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

  Install via `M-x package-install RET scad-mode RET' from NonGNU ELPA
  or MELPA.  After the installation `*.scad' files will be opened with
  `scad-mode'.


4 Related packages
══════════════════

  • [scad-dbus]: Interact with a running OpenSCAD instance from Emacs
    via DBUS
  • `lsp-mode', `eglot' or `lsp-bridge': The `openscad-lsp' server can
    be used with `scad-mode'


[scad-dbus] <https://github.com/lenbok/scad-dbus>
