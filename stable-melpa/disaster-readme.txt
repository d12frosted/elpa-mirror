![Screenshot of a C example](screenshot-c.png)

![Screenshot of a Fortran example](screenshot-fortran.png)

Disaster lets you press `C-c d` to see the compiled assembly code for the
C, C++ or Fortran file you're currently editing. It even jumps to and
highlights the line of assembly corresponding to the line beneath your cursor.

It works by creating a `.o` file using `make` (if you have a Makefile), or
`cmake` (if you have a `compile_commands.json` file) or the default system
compiler. It then runs that file through `objdump` to generate the
human-readable assembly.
