1 Overview
══════════

  Geiser is a generic Emacs/Scheme interaction mode, featuring an
  enhanced REPL and a set of minor modes improving Emacs' basic scheme
  major mode. The main functionalities provided are:

  • Evaluation of forms in the namespace of the current module.
  • Macro expansion.
  • File/module loading.
  • Namespace-aware identifier completion (including local bindings,
    names visible in the current module, and module names).
  • Autodoc: the echo area shows information about the signature of the
    procedure/macro around point automatically.
  • Jump to definition of identifier at point.
  • Access to documentation (including docstrings when the
    implementation provides it).
  • Listings of identifiers exported by a given module.
  • Listings of callers/callees of procedures.
  • Rudimentary support for debugging (list of evaluation/compilation
    error in an Emacs' compilation-mode buffer).
  • Support for inline images in schemes, such as Racket, that treat
    them as first order values.

  If you're not in a hurry, [Geiser's website] contains a much nicer
  manual.


[Geiser's website] <http://www.nongnu.org/geiser/>


2 Supported schemes
═══════════════════

  Geiser needs Emacs 27.1 or better, and installing also at least one of
  the supported scheme implementations.

  The following schemes are supported via an independent package,
  installable from either NonGNU ELPA or MELPA:

  • Chez 9.4 or better, via [geiser-chez]
  • Chibi 0.7.3 or better, via [geiser-chibi]
  • Chicken 4.8.0 or better, via [geiser-chicken]
  • Gambit 4.9.3 or better, via [geiser-gambit]
  • Gauche 0.9.6 or better, via [geiser-gauche]
  • Guile 2.2 or better, via [geiser-guile]
  • Kawa 3.1, via [geiser-kawa]
  • MIT/GNU Scheme, via [geiser-mit]
  • Racket 6.0 or better, via [geiser-racket]
  • Stklos 1.50, via [geiser-stklos]


[geiser-chez] <https://gitlab.com/emacs-geiser/chez>

[geiser-chibi] <https://gitlab.com/emacs-geiser/chibi>

[geiser-chicken] <https://gitlab.com/emacs-geiser/chicken>

[geiser-gambit] <https://gitlab.com/emacs-geiser/gambit>

[geiser-gauche] <https://gitlab.com/emacs-geiser/gauche>

[geiser-guile] <https://gitlab.com/emacs-geiser/guile>

[geiser-kawa] <https://gitlab.com/emacs-geiser/kawa>

[geiser-mit] <https://gitlab.com/emacs-geiser/mit>

[geiser-racket] <https://gitlab.com/emacs-geiser/racket>

[geiser-stklos] <https://gitlab.com/emacs-geiser/stklos>


3 Installation
══════════════

3.0.1 Using ELPA
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Geiser is available in the ELPA repositories [NonGNU ELPA]
  (pre-configured by default as a source starting in Emacs 28) and
  MELPA. So the easiest way is to use the ELPA package, and just type

  `M-x package-install RET geiser-<implementation>'

  inside emacs, or the corresponding `use-package' stanza, for, say

  ┌────
  │ (use-package geiser-mit :ensure t)
  └────

  All the concrete implementation packages depend on the base `geiser'
  package, so it'll be installed for you.


[NonGNU ELPA] <https://elpa.nongnu.org/nongnu/geiser.html>


3.0.2 From a repository checkout
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you are not using MELPA, just put this repository's `elisp'
  directory and the target's scheme directory in your load path and
  require the latter:

  ┌────
  │ (add-to-list 'load-path "<geiser checkout dir>/elisp")
  │ (add-to-list 'load-path "<geiser-mit checkout dir>")
  │ (require 'geiser-mit)
  └────

  Some scheme implementations need additional installation steps to
  fully support all geiser operations, so please do check their
  corresponding web pages.


4 Basic configuration
═════════════════════

  When opening a scheme file, Geiser will try to guess its Scheme,
  defaulting to the first in the list
  `geiser-active-implementations'. If you've installed more than one
  geiser package, you can also use `C-c C-s' to select the
  implementation by hand (on a per file basis).

  Check the geiser customization group for some other options with:

  ┌────
  │ M-x customize-group RET geiser RET
  └────

  In particular, customize `geiser-<impl>-binary', which should point to
  an executable in your path.

  To start a REPL, run `M-x geiser'.


4.1 Completion at point
───────────────────────

  Geiser offers identifier and module name completion, bound to `M-TAB'
  and `M-`' respectively. Only names visible in the current module are
  offered.

  While that is cool and all, things are even better: if you have
  [Company] or [Corfu] installed, Geiser's completion will integrate
  with it. Just enable global-company-mode/corfu-global-mode and, from
  then on, any new scheme buffer or REPL will use it. Alternatively you
  can activate company-mode or corfu-mode individually only in some
  buffers.


[Company] <http://company-mode.github.io/>

[Corfu] <https://github.com/minad/corfu>


4.2 Macro expansion with macrostep-geiser
─────────────────────────────────────────

  Geiser offers basic macro expansion in a dedicated buffer.  If you
  prefer in-buffer, step by step expansion, please take a look at Nikita
  Bloshchanevich's [macrostep-geiser].


[macrostep-geiser] <https://github.com/nbfalcon/macrostep-geiser>


5 Quick key reference
═════════════════════

  (See also [the user's manual cheat sheet]')


[the user's manual cheat sheet]
<http://geiser.nongnu.org/geiser_5.html#Cheat-sheet>

5.1 In Scheme buffers:
──────────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   C-c C-s      Specify Scheme implementation for buffer         
   C-c C-z      Switch to REPL                                   
   C-c C-a      Switch to REPL and current module                
   M-.          Go to definition of identifier at point          
   M-,          Go back to where M-. was last invoked            
   C-c C-e m    Ask for a module and open its file               
   C-c C-e C-l  Add a given directory to Scheme's load path      
   C-c C-e [    Toggle between () and [] for current form        
   c-c C-e \    Insert λ                                         
   C-c C-i      Interrupt on-going evaluation                    
   C-M-x        Eval definition around point                     
   C-c C-c      Eval definition around point                     
   C-c M-e      Eval definition around point and switch to REPL  
   C-x C-e      Eval sexp before point                           
   C-c C-r      Eval region                                      
   C-c M-r      Eval region and switch to REPL                   
   C-c C-b      Eval buffer                                      
   C-c M-b      Eval buffer and switch to REPL                   
   C-c C-m x    Macro-expand definition around point             
   C-c C-m e    Macro-expand sexp before point                   
   C-c C-m r    Macro-expand region                              
   C-c C-k      Compile and load current buffer                  
   C-c C-l      Load scheme file                                 
   C-u C-c C-k  Compile and load current buffer, restarting REPL 
   C-c C-d d    See documentation for identifier at point        
   C-c C-d s    See short documentation for identifier at point  
   C-c C-d i    Look up manual for identifier at point           
   C-c C-d m    See a list of a module's exported identifiers    
   C-c C-d a    Toggle autodoc mode                              
   C-c <        Show callers of procedure at point               
   C-c >        Show callees of procedure at point               
   M-TAB        Complete identifier at point                     
   M-`, C-.     Complete module name at point                    
   TAB          Complete identifier at point or indent           
                (If geiser-mode-smart-tab-p is t)                
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


5.2 In the REPL
───────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   C-c C-z      Start Scheme REPL, or jump to previous buffer      
   C-c M-o      Clear scheme output                                
   C-c C-q      Kill Scheme process                                
   C-c C-l      Load scheme file                                   
   C-c C-k      Nuke REPL: use it if the REPL becomes unresponsive 
   M-.          Edit identifier at point                           
   TAB, M-TAB   Complete identifier at point                       
   M-`, C-.     Complete module name at point                      
   M-p, M-n     Prompt history, matching current prefix            
   C-c \        Insert λ                                           
   C-c [        Toggle between () and [] for current form          
   C-c C-m      Set current module                                 
   C-c C-i      Import module into current namespace               
   C-c C-r      Add a given directory to scheme's load path        
   C-c C-d C-d  See documentation for symbol at point              
   C-c C-d C-m  See documentation for module                       
   C-c C-d C-a  Toggle autodoc mode                                
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


5.3 In the documentation browser:
─────────────────────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   f         Next page                                    
   b         Previous page                                
   TAB, n    Next link                                    
   S-TAB, p  Previous link                                
   N         Next section                                 
   P         Previous section                             
   k         Kill current page and go to previous or next 
   g, r      Refresh page                                 
   c         Clear browsing history                       
   ., M-.    Edit identifier at point                     
   z         Switch to REPL                               
   q         Bury buffer                                  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


5.4 In backtrace (evaluation/compile result) buffers:
─────────────────────────────────────────────────────

  • `M-g n', `M-g p', `C-x `' for error location navigation.
  • `n', `p' for moving among errors in the buffer.
  • `,' to pop-up the debugger actions menu.
  • `q' to bury buffer.


6 How to support a new scheme implementation
════════════════════════════════════════════

  Geiser works by running an instance of a REPL, or remotely connecting
  to one, and evaluating the scheme code it sees there. Then, every time
  it needs to perform some operation (like, say, printing autodoc,
  jumping to a source location or expanding a macro), it asks the
  running scheme instance for that information.

  So supporting a new scheme usually means writing a small scheme
  library that provides that information on demand, and then some
  standard elisp functions that invoke the procedures in that library.

  To see what elisp functions one needs to implement, just execute the
  command `M-x geiser-implementation-help` inside emacs with a recent
  version of geiser installed. And then take a look at, say,
  [geiser-guile.el] for examples of how those functions are implemented
  for concrete schemes.

  Not all schemes can provide introspective information to implement all
  the functionality that geiser tries to offer.  That is okay: you can
  leave as many functions unimplemented as you see fit (there is even an
  explicit list of unsupported features), and geiser will still know how
  to use the ones that are implemented.


[geiser-guile.el]
<https://gitlab.com/emacs-geiser/guile/-/blob/master/geiser-guile.el>
