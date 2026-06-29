Often times, I see people define a function to be used once in a hook.  If
they don’t do this, then it will be an anonymous function.  If the anonymous
function is modified, then the function can’t be removed.  With a function
outside of the `add-hook' call, it looks messy.

Hook Helpers are a solution to this.  A "hook helper" is an anonymous,
modifiable function created for the sole purpose of being attached to a hook.
This combines the two commonly used methods mentioned above.  The functions
don't exist, so they don't get in the way of `describe-function', but they
can be removed or modified as needed.