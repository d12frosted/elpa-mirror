This package provides the `cycle-quotes' command to cycle between
different string quote styles.  For instance, in JavaScript,
there's three string quote characters: ", ` and '.  In a JavaScript
buffer, with point located someplace within the string,
`cycle-quotes' will cycle between the following quote styles each
time it's called:

   --> "Hi, it's me!" --> `Hi, it's me!` --> 'Hi, it\'s me!' --
  |                                                            |
   ------------------------------------------------------------

As seen in the above example, `cycle-quotes' tries to escape and
unescape quote characters intelligently.