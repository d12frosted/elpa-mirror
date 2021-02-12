
CAUTION
=======
THIS LIBRARY IS VERY EXPERIMENTAL, SO YOU MAY HAVE MANY
PROBLEM WITH THIS LIBRARY. AND THIS LIBRARY COMES WITH
NO WARRANTY.


OVERVIEW
========
This library provides a feature, processing regular
expressions in manner of other programming languages
(we call it `foreign regexp' for convenience here),
to Emacs.

In particular, this library provides features corresponds to
such as `isearch-forward-regexp', `query-replace-regexp' and
`occur'.

Currently, regular expressions of Perl, Ruby, JavaScript and
Python can be used as foreign regexp.


THE GUTS OF THIS LIBRARY
========================

This library works like below:

  1. Make a search/replace operation with foreign regexp
     through the user-interface of Emacs.

  2. A search/replace operation will be executed by external
     commands (they are implemented in Perl, Ruby, JavaScript
     or Python).

  3. Apply the result of search/replace operations to the buffer
     through the user-interface of Emacs.


REQUIREMENTS
============
You need to have an Emacs which running on UNIX-like operating
system (*BSD/Linux/MacOSX) or Windows+Cygwin.

perl (>= 5.8), ruby (>= 1.9) node (Node.js, for JavaScript) or
python (only tested on 2.x), choose one of them as your taste,
is required as external command.

Also features `cl', `menu-bar' and `re-builder' are required.

For better multilingual support, Emacs (>= 21) may be required.

NOTE (for Windows users):
  In some cases, virus scanner program makes each `foreign-regexp'
  command running extremely slow.
  On such case, turn off virus scanner program, or exclude the
  path which is specified by a variable `foreign-regexp/tmp-dir'
  from virus scanning.
  This may improve the response of each `foreign-regexp' command.


INSTALLING
==========
To install this library, save this file to a directory in your
`load-path' (you can view the current `load-path' using
`C-h v load-path <RET>' within Emacs), then add following
lines to your `.emacs':

   (require 'foreign-regexp)

   (custom-set-variables
   '(foreign-regexp/regexp-type 'perl) ;; Choose your taste of foreign regexp
                                       ;; from 'perl, 'ruby, 'javascript or
                                       ;; 'python.
   '(reb-re-syntax 'foreign-regexp))   ;; Tell re-builder to use foreign regexp.


USAGE EXAMPLE
=============
In these examples, we suppose the contents of curent buffer are:

   123---789

[Example-1] Query Replace in manner of Perl.

  STEP-1: Set `foreign-regexp/regexp-type' to Perl.

       `M-x foreign-regexp/regexp-type/set <RET> perl <RET>'

       NOTE: Once you choose REGEXP-TYPE, Emacs will remember it
             until exit. You can also set and save REGEXP-TYPE for
             next Emacs session by setting value via customize.
             See "COMMANDS (1) SETTING REGEXP-TYPE" section in
             this document.

  STEP-2: Run query replace

       `M-s M-% (\d+)---(\d+) <RET> ${1}456${2} <RET>'

       This command replaces the text in buffer:

          123---789

       with text:

          123456789

       NOTE: Variables in replacement string are interpolated by Perl.


[Example-2] Query Replace in manner of Ruby.

  STEP-1: Set regexp-type to Ruby.

       `M-x foreign-regexp/regexp-type/set <RET> ruby <RET>'

  STEP-2: Run query replace

       `M-s M-% (\d+)---(\d+) <RET> #{$1}456#{$2} <RET>'

       This command replaces text in buffer:

          123---789

       with text:

          123456789

       Variables in replacement string are interpolated by ruby
       as if they are in the replacement string inside of the
       `String#gsub' method.


[Example-3] Query Replace in manner of JavaScript.

  STEP-1: Set regexp-type to JavaScript.

       `M-x foreign-regexp/regexp-type/set <RET> javascript <RET>'

  STEP-2: Run query replace

       `M-s M-% (\d+)---(\d+) <RET> $1456$2 <RET>'

       This command replaces text in buffer:

          123---789

       with text:

          123456789

       Variables in replacement string are interpolated
       as if they are in `String.prototype.replace' method.


[Example-4] Query Replace in manner of Python.

  STEP-1: Set regexp-type to Python.

       `M-x foreign-regexp/regexp-type/set <RET> python <RET>'

  STEP-2: Run query replace

       `M-s M-% (\d+)---(\d+) <RET> \g<1>456\g<2> <RET>'

       This command replaces text in buffer:

          123---789

       with text:

          123456789

       Backreferences in replacement string are interpolated
       as if they are in `re.sub' method.


COMMANDS(1): SETTING REGEXP-TYPE
================================

`M-x foreign-regexp/regexp-type/set <RET> REGEXP-TYPE <RET>'

     Set type of regexp syntax to REGEXP-TYPE.
     By default, four regexp-types `perl', `ruby', `javascript' and
     `python' are provided.

     You can also set REGEXP-TYPE via customization interface:

     `M-x customize-apropos <RET> foreign-regexp/regexp-type <RET>'


COMMANDS(2): SEARCH AND REPLACEMENT
===================================

NOTE: While editing a regular expression on the minibuffer prompt
      of `foreign-regexp' commands below, you can switch to another
      `foreign-regexp' command without losing current editing state.

`M-s M-o REGEXP <RET>'
`M-x foreign-regexp/occur <RET> REGEXP <RET>'

     Show all lines in the current buffer containing a match
     for foreign REGEXP.

`M-s M-% REGEXP <RET> REPLACEMENT <RET>'
`M-x foreign-regexp/query-replace <RET> REGEXP <RET> REPLACEMENT <RET>'

     Replace some matches for foreign REGEXP with REPLACEMENT.
     Note that notation of REPLACEMENT is different for
     each REGEXP-TYPE.

`M-s M-s'
`M-x foreign-regexp/isearch-forward <RET>'

     Begin incremental search for a foreign regexp.

`M-s M-r'
`M-x foreign-regexp/isearch-backward <RET> REGEXP'

     Begin reverse incremental search for a foreign regexp.

`M-s M-f REGEXP <RET>'
`M-x foreign-regexp/non-incremental/search-forward <RET> REGEXP <RET>'

     Search for a foreign REGEXP.

`M-s M-F REGEXP <RET>'
`M-x foreign-regexp/non-incremental/search-backward <RET> REGEXP <RET>'

     Search for a foreign REGEXP backward.

`M-s M-g'
`M-x nonincremental-repeat-search-forward'

     Search forward for the previous search string or regexp.

`M-s M-G'
`M-x nonincremental-repeat-search-backward'

     Search backward for the previous search string or regexp.


COMMANDS(3): WORKING WITH SEARCH OPTIONS
========================================

NOTE: The status of each search option will be displayed by an
      indicator which is put on the minibuffer prompt of each
      `foreign-regexp' command, or put on the mode-line of a
      buffer `*RE-Builder*'. The indicator will be displayed
      like these: `[isxe]' for Perl, `[imxe]' for Ruby,
      `[ie]' for JavaScript and [ISXe] for Python.

`M-s M-i'
`M-x foreign-regexp/toggle-case-fold <RET>'

     Toggle search option `case-fold-search'.

`M-s M-m'
`M-x foreign-regexp/toggle-dot-match <RET>'

     Toggle search option `foreign-regexp/dot-match-a-newline-p'.

`M-s M-x'
`M-x foreign-regexp/toggle-ext-regexp <RET>'

     Toggle search option `foreign-regexp/use-extended-regexp-p'.

`M-s M-e'
`M-x foreign-regexp/toggle-eval-replacement <RET>'

     Toggle search option `foreign-regexp/eval-replacement-p'.

     When this search option is on, the replacement string for
     a command `foreign-regexp/query-replace' will be evaluated
     as expression. For example, these commands:

       For `Perl':
         `M-s M-% ^ <RET> no strict 'vars';sprintf('%05d: ', ++$LINE) <RET>'
           NOTE:
             Replacement will be evaluated like REPLACEMENT in replacement
             operator with `e' option (like: `s/pattern/REPLACEMENT/e').
             In the replacement string, you can refer to special variables
             `$&', `$1', `&2', ... and so on.

       For `Ruby':
         `M-s M-% ^ <RET> { $LINE||=0;sprintf('%05d: ', $LINE+=1) } <RET>'
           NOTE:
             Replacement will be evaluated like a block passed to
             `String#gsub' method.
             In the block form, the current match string is passed as a
             parameter, and you can refer to built-in variables `$&', `$1',
             `&2', ... and so on.

       For `JavaScript':
         `M-s M-% ^ <RET> function (m) {if(typeof(i)=='undefined'){i=0};return ('0000'+(++i)).substr(-5)+': '} <RET>'
           NOTE:
             Replacement will be evaluated like a function in the 2nd
             argument of the method =String.prototype.replace=.
             In the function, the current match string, captured strings
             (1 .. nth, if exits), the position where the match occurred, and
             the strings to be searched are passed as arguments, and you can
             refer to properties `RegExp.lastMatch', `RegExp.$1', ... and
             so on.

       For `Python':
         `M-s M-% ^ <RET> i = 0  C-q C-j def f (m): C-q C-j <SPC> global i
                    C-q C-j <SPC> i=i+1  C-q C-j <SPC> return '%05d: ' % i <RET>'

           NOTE:
             You can specify a function which takes match object as argument
             and returns replacement string, by `lambda' expression or `def'
             statement.
             And you can refer match and sub groups through match object,
             for example: `lambda m: m.group(0)'.

             When you specify a function by `def' statement, you can use
             arbitrary function name and you can put statements around the
             function.
             In this case, the first `def' statement will be called for each
             matches, and the other statements will be called only once
             before search/replacement operation has began.

             The first implementation of this library accepts only `lambda'
             expression as the replacement.
             Because of inconvenience of =lambda= expression, that it does
             not accept any statement like assignment operation, so we make
             this library to accept =def= statement.
             Additionally, we can't assign to uninitialized global variable
             in function defined by =def= statement, so we make it to accept
             statements around the =def= statement which can initialize
             global variables, for our convenience.

     put line number to beginning of each lines.


COMMANDS(4): CONSTRUCTING REGEXP WITH RE-BUILDER
================================================

`M-x reb-change-syntax <RET> foreign-regexp <RET>'

     Set the syntax used by the `re-builder' to foreign regexp.

`M-s M-l'
`M-x re-builder <RET>'

     Start an interactive construction of a foreign regexp with
     `re-builder'.
     (See also documents of `re-builder')

     NOTE-1: To apply the foreign regexp, which was constructed
             with `re-builder', to the `foreign-regexp' commands,
             call commands below in `*RE-Builder*' buffer:

             `M-s M-o'
             `M-x foreign-regexp/re-builder/occur-on-target-buffer'

                  Run `foreign-regexp/occur' in `reb-target-buffer'
                  with a foreign regexp in the buffer `*RE-Builder*'.

             `M-s M-%'
             `M-x foreign-regexp/re-builder/query-replace-on-target-buffer'

                  Run `foreign-regexp/query-replace' in `reb-target-buffer'
                  with a foreign regexp in the buffer `*RE-Builder*'.

             `M-s M-s'
             `M-x foreign-regexp/re-builder/isearch-forward-on-target-buffer'

                  Run `foreign-regexp/isearch-forward' in `reb-target-buffer'
                  with a foreign regexp in the buffer `*RE-Builder*'.

             `M-s M-r'
             `M-x foreign-regexp/re-builder/isearch-backward-on-target-buffer'

                  Run `foreign-regexp/isearch-backward' in `reb-target-buffer'
                  with a foreign regexp in the buffer `*RE-Builder*'.

             `M-s M-f'
             `M-x foreign-regexp/re-builder/non-incremental-search-forward-on-target-buffer'

                  Run `foreign-regexp/non-incremental/search-forward' in `reb-target-buffer'
                  with a foreign regexp in the buffer `*RE-Builder*'.

             `M-s M-F'
             `M-x foreign-regexp/re-builder/non-incremental-search-backward-on-target-buffer'

                  Run `foreign-regexp/non-incremental/search-backward' in `reb-target-buffer'
                  with a foreign regexp in the buffer `*RE-Builder*'.

     NOTE-2: You can switch search options of the
             `reb-target-buffer' with commands below:

             `M-s M-i'
             `M-x foreign-regexp/re-builder/toggle-case-fold-on-target-buffer'

                  Toggle search option `case-fold-search' of `reb-target-buffer'.

             `M-s M-m'
             `M-x foreign-regexp/re-builder/toggle-dot-match-on-target-buffer'

                  Toggle search option `foreign-regexp/dot-match-a-newline-p'
                  of `reb-target-buffer'.

             `M-s M-x'
             `M-x foreign-regexp/re-builder/toggle-ext-regexp-on-target-buffer'

                  Toggle search option `foreign-regexp/use-extended-regexp-p'
                  of `reb-target-buffer'..

`M-\'
`M-x foreign-regexp/quote-meta-in-region <RET>'

     Escape characters in region, that would have special meaning
     in foreign regexp.


COMMANDS(5): ALIGNMENT USING FOREIGN REGEXP
===========================================

`C-M-|'
`M-x align'

     Align region according to pre-defined alignment rules.

     Foreign regexp can be used in a rule by putting an
     `regexp-type' attribute on the alignment rule.

     Example)

       (add-to-list
        'align-rules-list
        '(perl-and-ruby-hash-form

          ;; This rule will be applied when `regexp-type'
          ;; is `perl' or `ruby'.
          (regexp-type . '(perl ruby))

          (regexp . "([ \\t]*)=>[ \\t]*[^# \\t\\n]") ;; Foreign Regexp
          (group  . 1)
          (repeat . t)
          (modes  . '(perl-mode cperl-mode ruby-mode))))

     See also `align-rules-list' and help document of an advice
     of `align-region' for more information about alignment rules.

`M-s M-a REGEXP <RET>'
`M-x foreign-regexp/align <RET> REGEXP <RET>'

     Align the current region using a partial foreign regexp
     read from the minibuffer.

     The foreign regexp read from the minibuffer will be
     supposed to be placed after whitespaces.

     See also `align-regexp'.

`C-u M-s M-a REGEXP <RET> GROUP <RET> SPACING <RET> REPEAT <RET>'
`C-u M-x foreign-regexp/align <RET> REGEXP <RET> GROUP <RET> SPACING <RET> REPEAT <RET>'

     Align the current region using an ad-hoc rule read from the minibuffer.

     Example)

       < Use perl-style foreign regexp in this example. >

       When texts in region is:

            (one 1)
            (ten 10)
            (hundred 100)
            (thousand 1000)

       Run command on the region with options:

            REGEXP: ([ \t]+)\d
                         |
                         +--- GROUP: 1
                              Alignment will be applied to each
                              lines by inserting white-spaces to
                              the place where the capture group
                              specified by `GROUP' is matched to.
            SPACING: 1
            REPEAT:  y

       Result is:

            (one      1)
            (ten      10)
            (hundred  100)
            (thousand 1000)
                     |
                     +---- Aligned using SPACING spaces.

     See also `align-regexp'.


FOR HACKERS
===========
You can use regexp syntax of your choice of language, if you
write four external commands below with the language:

  `foreign-regexp/replace/external-command'
  `foreign-regexp/occur/external-command'
  `foreign-regexp/search/external-command'
  `foreign-regexp/quote-meta/external-command'

and install these commands with the function
`foreign-regexp/regexp-type/define'.

See help documents of these variables and functions
for more information.


KNOWN PROBLEMS
==============
Codes aside, this document should be rewritten.
My English sucks :-(


WISH LIST
=========
- History for `re-builder'.
- `grep' with foreign regexp?
- `tags-search', `tags-query-replace', `dried-do-search' and
  `dired-do-query-replace-regexp' with foreign regexp?
- `multi-isearch-buffers-regexp', `multi-occur',
  `multi-occur-in-matching-buffers', `how-many', `flush-lines',
  and `keep-lines' with foreign regexp?
- Better error messages.
- Write Tests.
