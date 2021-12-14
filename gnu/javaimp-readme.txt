Allows to manage Java import statements in Maven/Gradle projects.
This module does not add all needed imports automatically!  It only
helps you to quickly add imports when stepping through compilation
errors.  In addition, this module provides good Imenu support for
Java source files - with nesting and abstract methods in interfaces
and abstract classes.


  Quick start:

- Customize `javaimp-import-group-alist'.

- Call `javaimp-visit-project', giving it the top-level build file
of your project.  If called within a project, supplies useful
default candidates in minibuffer input (topmost build file in the
current directory hierarchy, then nested ones).

- Then in a Java buffer visiting a file under that project or one
of its submodules call `javaimp-organize-imports' or
`javaimp-add-import'.


  Some details:

Contents of jar files, list of classes in source files, and
Maven/Gradle project structures are cached, so usually only the
first command should take a considerable amount of time to
complete.  Project structure is re-read if a module's build file or
any of its parents' build files (within visited tree) was modified
since last check.  `javaimp-flush-cache' clears jar / source cache.

To forget visited projects structure eval this:
(setq javaimp-project forest nil)

Project structure and dependency information is retrieved from the
build tool, see `javaimp--maven-visit' and `javaimp--gradle-visit',
and the `javaimp-handler-regexp-alist' variable.  The output from
the build tool can be inspected in buffer named by
`javaimp-tool-output-buf-name' variable.  If there exists
Maven/Gradle wrapper in the project directory, as it is popular
these days, it will be used in preference to `javaimp-mvn-program'
/ `javaimp-gradle-program'.

See docstring of `javaimp-add-import' for how import completion
alternative are collected.

If you get jar reading errors with Gradle despite following
recommendation which is shown (text from
`javaimp--jar-error-header' followed by offending jars), then it
might be the case that Gradle reordered build in such a way that
those jars are really not built yet.  In this case, just build them
manually, like: './gradlew :project1:build :project2:build'.

Important defcustoms are:

- `javaimp-java-home' - used to obtain classes in the JDK, and also
the build tool is invoked with JAVA_HOME environment variable set
to it.  It's initialized from JAVA_HOME env var, so typically it's
not required to set it explicitly in Lisp.

- `javaimp-parse-current-module' - determines whether we parse the
current module for the list of classes.  Parsing is implemented in
javaimp-parse.el using `syntax-ppss', generally is simple (we do
not try to parse the source completely - just the interesting
pieces), but can be time-consuming for large projects (to be
improved).  Currently, on the author's machine, source for
java.util.Collections from JDK 11 (~ 5600 lines and > 1000
"scopes") parses in ~1.5 seconds, which is not that bad...

Parsing is also used for Imenu support.  A simple debug command,
`javaimp-help-show-scopes', lists all parsed "scopes" (blocks of
code in braces).  As there's no minor/major mode (yet), you have to
set `imenu-create-index-function' in major mode hook yourself.  See
example below.

- `javaimp-imenu-use-sub-alists' - if non-nil then Imenu items are
presented in a nested fashion, instead of a flat list (the
default).

See other defcustoms via 'M-x customize-group javaimp'.


Configuration example:

(require 'javaimp)
(add-to-list 'javaimp-import-group-alist
  '("\\`\\(my\\.company\\.\\|my\\.company2\\.\\)" . 80))
(global-set-key (kbd "C-c J v") 'javaimp-visit-project)


And in `java-mode-hook':

(local-set-key (kbd "C-c i") #'javaimp-add-import)
(local-set-key (kbd "C-c o") #'javaimp-organize-imports)
(local-set-key (kbd "C-c s") #'javaimp-help-show-scopes)

To enable Imenu (overriding Imenu support from cc-mode):

(setq imenu-create-index-function #'javaimp-imenu-create-index)