 Requires that the variable `lurk-executable' be set to point to
 the binary build of lurk.  When you execute a babel code block with
 type `lurk', the binary will be called and passed the code block
 as stdin.  There is currently no support for :session or otherwise
 keeping state between execution of different babel code blocks.
