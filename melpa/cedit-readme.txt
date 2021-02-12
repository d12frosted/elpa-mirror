Following commands are defined. Call them with "M-x foo", or bind some keys.

o cedit-forward-char / cedit-backward-char
  (in following examples, "|" are cursors)

      fo|o; {bar;} baz;
  =>  foo|; {bar;} baz;
  =>  foo;| {bar;} baz;
  =>  foo; {bar;}| baz;
  =>  foo; {bar;} b|az;

o cedit-beginning-of-statement / cedit-end-of-statement

      else{f|oo;}
  =>  else{|foo;} / else{foo;|}

      els|e{bar;}
  =>  |else{bar;} / else{bar;}|

o cedit-down-block

      wh|ile(cond){foo;}
  =>  while(cond){|foo;}

o cedit-up-block-forward / cedit-up-block-backward

      if(cond){fo|o;}
  =>  |if(cond){foo;} / if(cond){foo;}|

o cedit-slurp

      fo|o; bar;
  =>  fo|o, bar;

      {fo|o;} bar;
  =>  {fo|o; bar;}

o cedit-wrap-brace

      fo|o;
  =>  {fo|o;}

o cedit-barf

      fo|o, bar;
  =>  fo|o; bar;

      {fo|o; bar;}
  =>  {fo|o;} bar;

o cedit-splice-killing-backward

      foo, ba|r, baz;
  =>  |bar, baz;

      {foo; ba|r; baz;}
  =>  |bar; baz;

o cedit-raise

      foo, ba|r, baz;
  =>  |bar;

      {foo; ba|r; baz;}
  =>  |bar;

In addition, if "paredit.el" is installed on your emacs, following
commands are also defined.

o cedit-or-paredit-slurp
o cedit-or-paredit-barf
o cedit-or-paredit-splice-killing-backward
o cedit-or-paredit-raise

They are "dwim" commands that call one of cedit-xxx or paredit-xxx.
