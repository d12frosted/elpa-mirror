thinks.el is a little bit of silliness inspired by the think bubbles you
see in cartoons. It allows you to

. o O ( insert text that looks like this )

into a buffer. This could possibly be handy for use in email and usenet
postings.

Note that the code can handle multiple lines

. o O ( like this. That is, a body of text where the number of characters )
      ( exceeds the bounds of what you might consider to be a acceptable  )
      ( line length (he says, waffling on to fill a couple of lines).     )

You can also control how the bubble looks with `thinks-from'. The above
had it set to `top'. You can have `middle':

      ( like this. That is, a body of text where the number of characters )
. o O ( exceeds the bounds of what you might consider to be a acceptable  )
      ( line length (he says, waffling on to fill a couple of lines).     )

`bottom':

      ( like this. That is, a body of text where the number of characters )
      ( exceeds the bounds of what you might consider to be a acceptable  )
. o O ( line length (he says, waffling on to fill a couple of lines).     )

and `bottom-diagonal':

      ( like this. That is, a body of text where the number of characters )
      ( exceeds the bounds of what you might consider to be a acceptable  )
      ( line length (he says, waffling on to fill a couple of lines).     )
    O
  o
.

By default all of the thinking functions will fill (word wrap) the text
taking into account the value of `fill-column' minus the space required
for the bubble. Prefix a call to any of the functions with C-u to turn
off this behaviour.

The latest thinks.el is always available from:

  <URL:https://github.com/davep/thinks.el>
