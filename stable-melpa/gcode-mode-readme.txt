`gcode-mode' performs basic syntax highlighting on G-Code files
(mostly aimed at 3D printers), also providing optional instruction
lookup with ElDoc.

Once installed, all gcode files automatically open in this mode.
To also automatically enable ElDoc in G-Code files use:

(add-hook 'gcode-mode-hook 'eldoc-mode)

ElDoc will provide brief descriptions of the current instruction at
point. Embedded documentation is provided thanks to both the RepRap
Wiki[0] and the Marlin Documentation[1] projects.

[0] https://reprap.org/wiki/G-code
[1] https://github.com/MarlinFirmware/MarlinDocumentation/
