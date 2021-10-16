USAGE
=====

A major mode for editing Verilog and SystemVerilog HDL source code (IEEE
1364-2005 and IEEE 1800-2012 standards).  When you have entered Verilog
mode, you may get more info by pressing C-h m. You may also get online
help describing various functions by: C-h f <Name of function you want
described>

KNOWN BUGS / BUG REPORTS
=======================

SystemVerilog is a rapidly evolving language, and hence this mode is
under continuous development.  Please report any issues to the issue
tracker at

   https://www.veripool.org/verilog-mode

Please use verilog-submit-bug-report to submit a report; type C-c
C-b to invoke this and as a result we will have a much easier time
of reproducing the bug you find, and hence fixing it.

INSTALLING THE MODE
===================

An older version of this mode may be already installed as a part of
your environment, and one method of updating would be to update
your Emacs environment.  Sometimes this is difficult for local
political/control reasons, and hence you can always install a
private copy (or even a shared copy) which overrides the system
default.

You can get step by step help in installing this file by going to
<https://www.veripool.org/verilog-mode>

The short list of installation instructions are: To set up
automatic Verilog mode, put this file in your load path, and put
the following in code (please un comment it first!) in your
.emacs, or in your site's site-load.el

  (autoload 'verilog-mode "verilog-mode" "Verilog mode" t )
  (add-to-list 'auto-mode-alist '("\\.[ds]?va?h?\\'" . verilog-mode))

Be sure to examine at the help for verilog-auto, and the other
verilog-auto-* functions for some major coding time savers.

If you want to customize Verilog mode to fit your needs better,
you may add the below lines (the values of the variables presented
here are the defaults).  Note also that if you use an Emacs that
supports custom, it's probably better to use the custom menu to
edit these.  If working as a member of a large team these settings
should be common across all users (in a site-start file), or set
in Local Variables in every file.  Otherwise, different people's
AUTO expansion may result different whitespace changes.

  ;; Enable syntax highlighting of **all** languages
  (global-font-lock-mode t)

  ;; User customization for Verilog mode
  (setq verilog-indent-level             3
        verilog-indent-level-module      3
        verilog-indent-level-declaration 3
        verilog-indent-level-behavioral  3
        verilog-indent-level-directive   1
        verilog-case-indent              2
        verilog-auto-newline             t
        verilog-auto-indent-on-newline   t
        verilog-tab-always-indent        t
        verilog-auto-endcomments         t
        verilog-minimum-comment-distance 40
        verilog-indent-begin-after-if    t
        verilog-auto-lineup              'declarations
        verilog-linter                   "my_lint_shell_command"
        )