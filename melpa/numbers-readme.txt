
numbers.el is a little wrapper around http://numbersapi.com/ that can be
used to display maths information and trivia about numbers.

Two main commands are provided:

`numbers-math' - Shows/inserts a maths-related fact about a number.

`numbers-trivia' - Shows/inserts some trivia about a number.

In both cases calling the command will prompt for a number. If there
appears to be a number in the current buffer, near the current point,
that number will be used as the default.

If `universal-argument' is invoked first the result will be inserted into
the current buffer, otherwise it is displayed in the message area. On the
other hand, if number is provided as the prefix argument it is looked up
and the result is displayed.

In addition, a couple of commands are provided for getting facts and
trivia about a random number:

`numbers-random-math' - Shows/inserts a maths-related fact about a random
number.

`numbers-random-trivia' - Shows/inserts some trivia about a random
number.
