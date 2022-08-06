Allows to manage Java import statements in Maven / Gradle projects,
plus some editing and navigation support.  This package does not
add all needed imports automatically!  It only helps you to quickly
add imports when stepping through compilation errors.

In addition, this package provides `javaimp-minor-mode' which
enables decent Imenu support (with nesting and abstract methods in
interfaces and abstract classes), xref support (finding definition
is implemented; finding references is left at default) and some
navigation functions, like beginning-of-defun.

  Quick start

- Put something like this in your .emacs:

(require 'javaimp)
(add-to-list 'javaimp-import-group-alist
  '("\\`my.company\\." . 80))
(keymap-global-set "C-c J v" #'javaimp-visit-project)
(add-hook 'java-mode-hook #'javaimp-minor-mode)

- Call `javaimp-visit-project', giving it the top-level build file
of your project.  If called within a project, supplies useful
default candidates in minibuffer input (topmost build file in the
current directory hierarchy, then nested ones).  If you don't visit
a project, then Javaimp will try to determine current source root
directory from the 'package' directive in the current file, and
will still offer some functions.

- Then in a Java buffer visiting a file under that project or one
of its submodules call `javaimp-organize-imports' or
`javaimp-add-import'.


  Visiting projects & managing imports

Lists of classes in archive and source files, and Maven / Gradle
project structures are cached, so usually only the first command
should take a considerable amount of time to complete.  Project
structure is re-read if a module's build file or any of its
parents' build files (within visited tree) was modified since last
check.

`javaimp-flush-cache': command to clear jar / source cache.

`javaimp-forget-visited-projects': command to forget all visited
projects.

Project structure and dependency information is retrieved from the
corresponding build tool, see functions `javaimp-maven-visit' and
`javaimp-gradle-visit' for details (and generally, all handlers
mentioned in `javaimp-handler-regexp-alist').  The output from the
build tool can be inspected in the buffer named by
`javaimp-output-buf-name' variable.  If there exists Maven / Gradle
wrapper in the project directory, as it is popular these days, it
will be used in preference to `javaimp-mvn-program' /
`javaimp-gradle-program'.

`javaimp-java-home': defcustom giving location of JDK to use.
Classes from JDK are included into import completion candidates.
Also, when invoking a Java program, JAVA_HOME environment variable
is added to the subprocess environment.  The variable is
initialized from JAVA_HOME environment variable, so typically you
won't need to customize it.

If you get jar reading errors with Gradle despite following
recommendation which is shown (text from
`javaimp--jar-error-header' followed by offending jars), then it
might be the case that Gradle reordered build in such a way that
those jars are really not built yet.  In this case, just build them
manually, like: './gradlew :project1:build :project2:build'.

`javaimp-add-import': command to add an import statement in the
current file.  See its docstring for how completion candidates are
collected.  When it is called for the first time in a given project
/ module, it parses dependency archives, as well as JDK ones, and
it may take quite a while.

`javaimp-organize-imports': command to organize imports in the
current buffer, sorting and deleting duplicates.

If you don't visit a project, then Javaimp tries to determine
current source root directory (see
`javaimp--get-current-source-dir'), dependency information of
course will not be available, and you'll get completions only from
your current sources (and from JDK).


  Source parsing

Parsing is implemented in javaimp-parse.el using `syntax-ppss',
generally is simple (we do not try to parse the source completely -
just the interesting pieces), but can be time-consuming for large
projects (to be improved).  Currently, on the author's machine,
source for java.util.Collections from JDK 11 (~ 5600 lines and >
1000 "scopes") parses in ~1.5 seconds, which is not that bad...

`javaimp-show-scopes': command to list all parsed "scopes" (blocks
of code in braces) in the current buffer, with support for
`next-error'.

Parsing is also used for Imenu support, for xref support and for
navigation commands, these are installed by `javaimp-minor-mode'.

`javaimp-imenu-use-sub-alists': if non-nil then Imenu items are
presented in a nested fashion, instead of a flat list (default is
flat list).