
Invoking a C/C++ (and other) build tool-chain from Emacs.

The standard 'compile' machinery is mostly designed for interactive
use, but nowadays, for C/C++ at least, build systems and different
platforms make the process a bit more complicated.
Moreover, it is often desirable to have a slightly higher level API
to programmatically invoke a build system.

The goal of this library is to hide some of these details for Unix
(Linux), Mac OS and Windows.  The 'emc' library interfaces to
'make' and 'nmake' building setup and to 'cmake' (www.cmake.org).

The supported 'Makefile' combinations are:
+--------------------+--------------------+--------------------+
|                    |                    |                    |
| Unix/Linux         | Mac OS             | Windows (10/11)    |
|                    |                    |                    |
+--------------------+--------------------+--------------------+
| make               | make               | nmake              |
| executable         | executable         | executable: .exe   |
| library: .a .so    | library: .a .dylib | library: .obj .dll |
+--------------------+--------------------+--------------------+

On Windows 'emc' assumes the installation of Microsoft Visual
Studio (Community -- provisions are made to handle the Enterprise
or other versions but they are untested).  'MSYS' will be added in the
future, but is will mostly look like UNIX.

There are three main `emc' commands: `emc-run', `emc-make', and
`emc-cmake'.  `emc-run' is the most generic command and allows to
select the build system.  `emc-make' and `emc-cmake' assume instead
'make' or 'nmake' and 'cmake' respectively.

Invoking the command `emc-run' will use the
`emc-*default-build-system*' (defaulting to `:make') on the current
platform supplying hopefully reasonable defaults.  E.g.,
```
   (emc-run)
```
will usually result in a call to
```
   make -f Makefile
```
on UN*X platoforms.


### 'make'

All in all, the easiest way to use this library is to call the `emc-make'
function, which invokes the underlying build system (at the time of this
writing either 'make' or 'nmake'); e.g., the call:

```
   (emc-make)
```

calls `compile' after having constructed a platform dependent "make"
command.  On MacOS and Linux/UNIX system this defaults to:

```
   make -f Makefile
```

On Windows with MSVC this defaults to (assuming MSVC is installed on drive
':C')

```
   (C:\Path\To\MSVC\...\vcvars64.bat) & nmake /F Makefile
```

The 'emc' package gives you several knobs to customize your environment,
especially on Windows, where things are more complicated.  Please refer to
the `emc-make' function for an initial set of arguments you can use.  E.g.,
on Linux/UNIX the call

```
   (emc-make :makefile "FooBar.mk" :build-dir "foobar-build")
```

will result in a call to "make" such as:

```
   cd foobar-build ; make -f Foobar.mk
```

as a result `compile' will do the right thing by intercepting the 'cd' in
the string (the directory name is actually fully expanded by EMC).


### 'cmake'

To invoke 'cmake' the relevant function is `emc-cmake' which takes
the following "subcommands" (the '<bindir>' below is to be
interpreted in the 'cmake' sense).
1. `setup': which is equivalent to 'cmake <srcdir>' issued in a
   `binary' directory.
2. `build': which is equivalent to 'cmake --build <bindir>'.
3. `install': which is equivalent to 'cmake --install <bindir>'.
4. `uninstall': which currently has no `cmake' equivalent.
5. `clean': equivalent to 'cmake --build <bindir> -t clean'.
5. `fresh': equivalent to 'cmake --fresh <bindir>'.

As for `emc-make`, you can invoke the `emc-cmake` command either as
`M-x emc-make` or `C-u M-x emc-cmake`.  In the first case **EMC** will
assume that most parameters are already set; in the second case,
**EMC** will ask for each parameter needed by the sub-command.


### Other Commands

You can use the `emc-run` command which will ask you which
*sub-command* to use.  Again, if you prefix it with `C-u`, it will ask
you for several other variables, including the choice of *build
system* (which, for the time being, is either `make`, or `cmake`).

Other commands (and functions) you can use correspond to `cmake' sub
commands.

1. `emc-setup`: which is equivalent to `cmake <srcdir>` issued in a
   `binary` directory and to a `make setup` issued in the appropriate
   directory as well.  Note that this command usually does not mean
   much in a `make` based setup, unless the `Makefile` contains a
   `setup` target.
2. `emc-build`: which is equivalent to `cmake --build <bindir>` and to
   `make` issued in `<bindir>`; note that `make` will execute the
   recipe associated to the first target.
3. `emc-install`: which is equivalent to `cmake --install <bindir>`
   and to `make install` issued in `<bindir>`; note that `make` must
   provide the `install` target.
4. `emc-uninstall`: which currently has no `cmake` equivalent.  To execute
   this command with `cmake`, `CMakeLists.txt` must make provisions to
   handle and generate the `uninstall` targets.
5. `emc-clean`: equivalent to `cmake --build <bindir> -t clean`,  and to
   `make clean` issued in `<bindir>`; note that `make` must provide
   the `clean` target.
5. `emc-fresh`: equivalent to `cmake --fresh <bindir>`, and to `make
   fresh`.  Note that this command usually does not mean much in a
   `make` based setup, unless the `Makefile` contains a `setup`
   target.


#### **EMC** *GUI*

**EMC** also has a simple user interface that uses Emacs `widget`
library.  It may simplify setting up the build system commands,
especially because it shows the command before executing it.

You can invoke the GUI by invoking the `emc-emc` Emacs command
(`M-x emc-emc`).  Using it should be rather straightforward.
