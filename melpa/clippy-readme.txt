This library implements rendering of pop-up box with "Clippy, the
paper clip".  You can make him say various things by calling
`clippy-say' function.  To hide the pop-up, simply invoke any
command (move forward/backward, type, `C-g` etc., any event is
recognized).

As inspiration, three functions are provided:
`clippy-describe-function', `clippy-describe-variable' and
`clippy-describe-symbol'.  Bind any of these functions to a key,
then while point is over a function/variable, call it.  A popup
with helpfull clippy will appear, telling you about the
function/variable (using `describe-function' and
`describe-variable' ).
