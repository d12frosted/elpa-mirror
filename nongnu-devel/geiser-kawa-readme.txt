1 geiser-kawa
═════════════

1.1 Project description
───────────────────────

  `geiser-kawa' adds support for Kawa Scheme to [Geiser].

  It has 2 parts:
  • `geiser-kawa': elisp package inside the `elisp' directory that gives
    the name to the whole project.
  • `kawa-geiser': included maven project written using Kawa's Java
    API. When it's imported from a Kawa scheme REPL, procedures needed
    by `geiser-kawa' are added to the Kawa environment.


[Geiser] <https://gitlab.com/emacs-geiser/geiser/>


1.2 Supported Kawa versions
───────────────────────────

  Only versions of Kawa > 3.1 are supported, mostly due to the fact that
  before the 3.1 release some necessary Kawa classes were private.


1.3 Supported features
──────────────────────

  • geiser-related:
    • eval
    • load-file
    • completions
    • module-completions (very fragile atm)
    • macroexpand
    • autodoc:
      • for scheme procedures
      • for java methods
    • manual lookup:
      • remember to set variable `geiser-kawa-manual-path'
      • should work for both formats:
        • info: using emacs' Info-mode
        • epub: using emacs' eww browser
  • kawa- and java-specific:
    • [Completion for Java package and class members (packages, classes,
      methods, fields)]


[Completion for Java package and class members (packages, classes,
methods, fields)] See section 1.10


1.4 Unsupported features
────────────────────────

  • geiser-related:
    • find-file
    • symbol-location
    • module-location
    • symbol-documentation
    • module-exports
    • callers
    • callees
    • generic-methods


1.5 Try geiser-kawa without modifying your emacs configuration
──────────────────────────────────────────────────────────────

  1. Prerequisites:
     • `java', `emacs' and [cask] available through your `$PATH'
     • `$JAVA_HOME' environment variable set
  2. Clone this repository
     ┌────
     │ git clone "https://gitlab.com/emacs-geiser/kawa.git"
     └────
  3. cd into the cloned dir:
     ┌────
     │ cd geiser-kawa
     └────
  4. Tell cask to install emacs dependencies:
     ┌────
     │ cask install
     └────
  5. Pull `kawa-geiser''s maven dependencies (the first time takes ~1
     minute), compile them and start geiser-kawa's scratch buffer and
     repl:
     ┌────
     │ cask emacs -Q --load quickstart.el
     └────
  6. You should now have an emacs frame containing a scratch buffer in
     `geiser-mode' and a repl buffer, both with geiser-kawa support

  To try geiser-kawa you need neither Maven nor Kawa:
  • `mvnw' ([maven-wrapper]) takes care of downloading a
    project-specific Maven version
  • `kawa-geiser' has [Kawa's master branch] as one of its
    dependencies. When `quickstart.el' calls `./mvnw package' (wrapped
    by `geiser-kawa-deps-mvnw-package'), it produces a jar that includes
    `kawa-geiser' and all its dependencies, including Kawa itself.


[cask] <https://github.com/cask/cask>

[maven-wrapper] <https://github.com/takari/maven-wrapper>

[Kawa's master branch] <https://gitlab.com/groups/kashell/>


1.6 Manual Installation
───────────────────────

  1. Prerequisites:
     • `emacs'
     • `java' available through your `$PATH'
     • `$JAVA_HOME' environment variable set
  2. Install the `geiser' package in Emacs
  3. Clone this repository
     ┌────
     │ git clone "https://gitlab.com/emacs-geiser/kawa.git"
     └────
  4. Package java dependencies:
     1. cd into `geiser-kawa'
     2. run `./mvnw package'
  5. Add the elisp directory inside this project to Emacs' `load-path':
     ┌────
     │ (add-to-list 'load-path "<path-to-geiser-kawa/elisp>")
     └────
  6. Require `geiser-kawa':
     ┌────
     │ (require 'geiser-kawa)
     └────
  7. Either:
     • Set the `geiser-kawa-use-included-kawa' variable to non-nil: to
       use the Kawa version included in `geiser-kawa'
     • [Get Kawa] and either:
       • set the `geiser-kawa-binary' variable
       • add `kawa' to `$PATH'
  8. Run kawa:
     ┌────
     │ M-x run-kawa
     └────


[Get Kawa] <https://www.gnu.org/software/kawa/Getting-Kawa.html>


1.7 Install using MELPA
───────────────────────

  1. Prerequisites:
     • `emacs'
     • `java' available through your `$PATH'
     • `$JAVA_HOME' environment variable set
  2. Install `geiser-kawa' using MELPA
  3. Package java dependencies:
     ┌────
     │ =M-x geiser-kawa-deps-mvnw-package=
     └────
  4. Require `geiser-kawa'
     ┌────
     │ (require 'geiser-kawa)
     └────
  5. Either:
     • Set the `geiser-kawa-use-included-kawa' variable to non-nil: to
       use the Kawa version included in `geiser-kawa'
     • [Get Kawa] and either:
       • set the `geiser-kawa-binary' variable
       • add `kawa' to `$PATH'
  6. Run kawa:
     ┌────
     │ M-x run-kawa
     └────


[Get Kawa] <https://www.gnu.org/software/kawa/Getting-Kawa.html>


1.8 About manual lookup
───────────────────────

  To use the `geiser-doc-lookup-manual' feature you need a copy of the
  Kawa manual. You can either compile it from the Kawa source code or
  extract it from the pre-compiled Kawa release available on the Kawa
  website: <https://www.gnu.org/software/kawa/Getting-Kawa.html>.

  Once you have the manual in `.info' or `.epub' format, set the
  `geiser-kawa-manual-path' elisp variable to the path of the file.


1.9 About Autodoc
─────────────────

  Double quotes around parameters: the reason why the arguments are
  enclosed in double quotes in autodoc is because special characters
  (e.g. `]') aren't read as part of a symbol by the elisp reader that
  geiser relies on to display autodoc data. To work-around this
  limitation parameters are represented by strings instead of symbols.

  Parameter names: parameter names are retrieved using the
  `gnu.bytecode' package (included in Kawa) for reading local variables
  in Java methods' bytecode. Since parameters are not always present in
  bytecode as local variables (especially for methods written in Java),
  when not available the parameter name defaults to `argN', where `N' is
  a number.

  [LangObjType objects]: these are special objects that may behave like
  procedures. When these are called as procedures, a java method that
  returns a new object is called. This method does not have the same
  name as the symbol you insert in Kawa, so I thought it was a good idea
  to show the method name as part of the displayed module, preceded by a
  colon. Maybe I was wrong, in that case the behavior it's easy to
  change.

  Autodoc for macros: not supported. I don't know how get parameters for
  macros in Kawa.


[LangObjType objects]
<https://gitlab.com/kashell/Kawa/-/blob/master/gnu/kawa/lispexpr/LangObjType.java>


1.10 About completion for Java package and class members (packages, classes, methods, fields)
─────────────────────────────────────────────────────────────────────────────────────────────

  The whole project is in a persistent "experimental" state, but this
  part even more so because it's based on assumptions that:
  • I'm not sure about
  • May not hold anymore if/when the Kawa compiler changes how accessing
    packages and class members is represented in its AST/Expression tree

  The main interactive elisp function is
  `geiser-kawa-devutil-complete-at-point'. By default, it's not bound to
  any key.

  Supported forms (with issues) are:
  • completion for package and class names: dot notation, like in java
  • completion for field and method names:
    • `field', `slot-ref'
    • `static-field'
    • `invoke'
    • `invoke-static'
    • colon notation
  Unsupported forms:
  • Kawa's star-colon notation (e.g: `(*:getClass "foobar")')

  How it works:
  1. A region of the current buffer and cursor point inside it are sent
     to a Kawa procedure
  2. `kawa-devutil''s pattern matching is run on the resulting
     Expression tree
  3. If a match is found, the data is returned to Emacs

  You can find some examples and known issues in [kawa-devutil]'s
  README.


[kawa-devutil] <https://gitlab.com/spellcard199/kawa-devutil>


1.11 Extending `geiser-kawa'
────────────────────────────

  Since you can get the result of a Kawa expression through geiser you
  can extend `geiser-kawa' blending both Elisp and Kawa, with the
  limitation that it's always strings that are passed back and
  forth. The rest of this section is an example.

  Let's say we wanted to extend `geiser-kawa' to list all the classes
  available in the default classloaders.

  Since `kawa-geiser' (the java counterpart of `geiser-kawa') has
  [kawa-devutil] in its dependencies, we already have [Classgraph]
  included in `kawa-geiser', shaded to
  `kawadevutil.shaded.io.github.classgraph' by `kawa-devutil'
  itself. This means we can already traverse classpath and classloaders.

  This is some simple Kawa scheme code to get a list of all the classes
  in the default classloaders using the ClassGraph library included in
  `kawa-geiser':

  ┌────
  │ (let* ((cg (kawadevutil.shaded.io.github.classgraph.ClassGraph))
  │        (scanResult (invoke
  │ 		    (invoke
  │ 		     (invoke
  │ 		      cg
  │ 		      "enableSystemJarsAndModules")
  │ 		     "enableClassInfo")
  │ 		    "scan")))
  │   (scanResult:getAllClasses))
  └────

  Now we can write an interactive elisp function that evaluates the code
  above each time it's called and then puts the result into an emacs
  buffer:

  ┌────
  │ (defun my-geiser-kawa-list-all-classes ()
  │   "A simple function that uses `geiser-kawa' to ask Kawa a list of all
  │ the classes in the default classloaders of the current REPL and then
  │ displays them in a dedicated buffer."
  │   (interactive)
  │   ;; Switch to dedicated buffer and create it if it doesn't exist.
  │   (switch-to-buffer-other-window
  │    (get-buffer-create "*geiser-kawa-classlist*"))
  │   ;; Clear buffer in case you already run the command once.
  │   (delete-region (point-min) (point-max))
  │   ;; Eval our Kawa code and insert result of evaluation in the buffer
  │   ;; we switched to above.
  │   (insert
  │    (geiser-kawa-util--eval-get-result
  │      ;; The same kawa code as above, quoted so that it's not evaluated
  │      ;; as elisp.
  │     '(let* ((cg (kawadevutil.shaded.io.github.classgraph.ClassGraph))
  │ 	    (scanResult (invoke
  │ 			 (invoke
  │ 			  (invoke
  │ 			   cg
  │ 			   "enableSystemJarsAndModules")
  │ 			  "enableClassInfo")
  │ 			 "scan")))
  │        (scanResult:getAllClasses)))))
  └────

  Now every time you use `M-x my-geiser-kawa-list-all-classes' and have
  an active Kawa repl associated with the current buffer, after some
  seconds (there may be tenths of thousands of classes) a new buffer
  containing the list of available classes will be displayed.


[kawa-devutil] <https://gitlab.com/spellcard199/kawa-devutil>

[Classgraph] <https://github.com/classgraph/classgraph>


1.12 Adding java dependencies to Kawa / Embedding `kawa-geiser' in your java application
────────────────────────────────────────────────────────────────────────────────────────

  The easiest way is:
  1. Create a new maven project
  2. Add to the `pom.xml':
     • Your dependencies
     • [Jitpack] resolver:
       ┌────
       │ <repositories>
       │   <repository>
       │     <id>jitpack.io</id>
       │     <url>https://jitpack.io</url>
       │   </repository>
       │ </repositories>
       └────
     • `kawa-geiser' dependency (you can replace `-SNAPSHOT' with commit
       SHA):
       ┌────
       │ <dependencies>
       │   <dependency>
       │     <groupId>com.gitlab.emacs-geiser</groupId>
       │     <artifactId>kawa</artifactId>
       │     <version>-SNAPSHOT</version>
       │   </dependency>
       │ </dependencies>
       └────
  3. Start a Kawa REPL from Java (should have all the dependencies
     included now):
     ┌────
     │ String[] kawaArgs = new String[]{"--server", "37146"};
     │ Scheme scheme = new Scheme();
     │ scheme.eval("(require <kawageiser.Geiser>)");
     │ scheme.runAsApplication(kawaArgs);
     └────
  4. Use the `geiser-connect' command from emacs and insert the port
     number we specified in the previous step when prompted


[Jitpack] <https://jitpack.io>


1.13 Is Windows supported?
──────────────────────────

  I don't usually use Windows, but it seems to work.


1.14 Difference from [geiser-kawa-scheme]
─────────────────────────────────────────

  This project (geiser-kawa) is a translation/rewrite of
  [geiser-kawa-scheme], which has been my first attempt at writing
  `geiser-kawa'. After `geiser-kawa-scheme' confirmed me that a
  `geiser-kawa' implementation was possible I decided to rewrite the
  Kawa side using Kawa's Java API, for the several reasons:
  • Easier to add as a scripting language in Java projects: just add the
    jitpack resolver and this project's repository as a dependency
  • Easier to inculde external java libraries via maven central for
    additional functionalities
  • Tooling for Java is excellent, tooling for Kawa is not
  • Fully static type checking: probably it's because I'm bad at
    programming, but it helps me a lot
  • The non-elisp part of `geiser-kawa-scheme' has been split in 2
    projects:
    • [kawa-devutil]: functions that take care of getting data and
      general functionalities (e.g. output-capturing eval)
    • `kawa-geiser':
      • maven project included in `geiser-kawa'
      • uses `kawa-devutil''s features to get relevant data and returns
        it as a scheme structure readable by geiser
  • Possibility to share code between `kawa-devutil' and other software
    written in Java (e.g. Kawa itself)
  • Since `kawa-devutil' is now a project separate from `geiser-kawa',
    one could use it to avoid re-writing the data-getting logic if
    she/he wanted to implement a Kawa server for a tool other than
    Geiser (e.g. nrepl, jupyter, swank/slime) or a standalone Java
    application.

  `geiser-kawa' VS `geiser-kawa-scheme' - recap table:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                   geiser-kawa      geiser-kawa-scheme 
  ─────────────────────────────────────────────────────────────────────
   Kawa side written with          Kawa's Java API  Kawa Scheme        
   I'm going to add more features  Probably yes     Probably not       
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[geiser-kawa-scheme]
<https://gitlab.com/spellcard199/geiser-kawa-scheme>

[kawa-devutil] <https://www.gitlab.com/spellcard199/kawa-devutil>
