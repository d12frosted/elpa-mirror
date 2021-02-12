Ruby refactor is inspired by the Vim plugin vim-refactoring-ruby,
currently found at https://github.com/ecomba/vim-ruby-refactoring.

I've implemented 5 refactorings
 - Extract to Method
 - Extract Local Variable
 - Extract Constant
 - Add Parameter
 - Extract to Let

; ## Install
Add this file to your load path.
(require 'ruby-refactor)  ; if not installed from a package
(add-hook 'ruby-mode-hook 'ruby-refactor-mode-launch)

## Extract to Method:
Select a region of text and invoke 'ruby-refactor-extract-to-method'.
You'll be prompted for a method name. The method will be created
above the method you are in with the method contents being the
selected region. The region will be replaced w/ a call to method.

## Extract Local Variable:
Select a region of text and invoke `ruby-refactor-extract-local-variable`.
You'll be prompted for a variable name.  The new variable will
be created directly above the selected region and the region
will be replaced with the variable.

## Extract Constant:
Select a region of text and invoke `ruby-refactor-extract-constant`.
You'll be prompted for a constant name.  The new constant will
be created at the top of the enclosing class or module directly
after any include or extend statements and the regions will be
replaced with the constant.

## Add Parameter:
'ruby-refactor-add-parameter'
This simply prompts you for a parameter to add to the current
method definition. If you are on a text, you can just hit enter
as it will use it by default. There is a custom variable to set
if you like parens on your params list.  Default values and the
like shouldn't confuse it.

## Extract to Let:
This is really for use with RSpec

'ruby-refactor-extract-to-let'
There is a variable for where the 'let' gets placed. It can be
"top" which is top-most in the file, or "closest" which just
walks up to the first describe/context it finds.
You can also specify a different regex, so that you can just
use "describe" if you want.
If you are on a line:
  a = Something.else.doing
    becomes
  let(:a){ Something.else.doing }

If you are selecting a region:
  a = Something.else
  a.stub(:blah)
    becomes
  let :a do
    _a = Something.else
    _a.stub(:blah)
    _a
  end

In both cases, you need the line, first line to have an ' = ' in it,
as that drives conversion.

There is also the bonus that the let will be placed *after* any other
let statements. It appends it to bottom of the list.

Oh, if you invoke with a prefix arg (C-u, etc.), it'll swap the placement
of the let.  If you have location as top, a prefix argument will place
it closest.  I kinda got nutty with this one.


## TODO
From the vim plugin, these remain to be done (I don't plan to do them all.)
 - remove inline temp (sexy!)
