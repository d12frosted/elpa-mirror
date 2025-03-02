![Screenshot of a C example](screenshot-c.png)

![Screenshot of a Fortran example](screenshot-fortran.png)

Disaster lets you press `C-c d` to see the compiled assembly code for the
C, C++ or Fortran file you're currently editing. It even jumps to and
highlights the line of assembly corresponding to the line beneath your cursor.

It works in the following manner:

- If there is a `Makefile`, creating a `.o` file using `make`
- If there is a `compile_commands.json` file, use it to get the compilation
  command for the file.
- If none of the above files is presnet, use the default system compiler.

After compiling the source to a `.o` file, `disaster' runs that file through
`objdump` to generate the human-readable assembly.
