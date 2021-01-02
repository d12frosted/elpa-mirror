
Use to make random decisions. Roll various types of dice, generate
random numbers from ranges, or generate random text from
tables.

Enable decide-mode minor-mode. Pressing ? ? will insert a YES
or NO (possibly with a + or - modifier to be interpreted
any way you wish).

If the answer is unlikely to be yes, press ? -
a more unlikely (difficult) query that has only a 33 % chance of being
yes. For a liklier/easier test press ? + (67 % chance).

To roll generic dice, use the function decide-roll-dice. It will
ask for what roll to make, something like 2d6 or 3d10+2 or 2d12-1.
The default if nothing is input, or nothing that can be parsed
properly as a dice specification, 1d6 is rolled.
M-p and M-n can be used to navigate history to re-roll.
Rolling dice is bound to ? d when decide-mode is active.
Some common and less common die-rolls have their own key-bindings
enabled per default in decide-mode:

? 3 -> 1d3
? 4 -> 1d4
? 5 -> 1d5
? 6 -> 1d6
? 7 -> 1d7
? 8 -> 1d8
? 9 -> 1d9
? 1 0 -> 1d10
? 1 2 -> 1d12
? 2 0 -> 1d20
? % -> 1d100
? D -> 2d6

Custom dice can be defined in the decide-custom-dice alist. By default it
contains configuration for dA (average-dice, d6 numbered 2, 3, 3, 4, 4, 5)
and dF (Fudge/FATE dice, d6 labeled +, +, 0, 0, -, -). Custom dice names
are not case sensitive (avoid having dice with the same name only differing
in case). Each custom dice side has a string
label and an optional value that is used (if it exists) to calculate the sum
of rolling multiple dice of that type. There are some pre-defined
key-bindings in decide-mode for the included custom dice:

? f -> 4dF
? a -> 1dA
? A -> 2dA

To pick a random number in any range press ? r (decide-random-range),
then input range to get number from, in one of the following formats:
3-17
3--17
3---17
(even more dashes are allowed)
3<<17
3<<<17
3>>17
3>>>17
All ranges are inclusive (ie the two given numbers may be choosen).
The start of a range must be lower than the end of the range.
The end of a range can not be a negative number.
When having more than one dash between numbers, that means you will get
an average of that many random draws, meaning the result is more likely
to be close to the middle of the range. Adding more dashes makes it
increasingly unlikely to get results close to the extremes of the range.
Using << (or <<< etc) will instead result in the lowest of multiple
draws, tending towards the lower end of the range,
and the opposite is true when using >> (or >>> etc).

To decide from a given list of possible choices press
? c (decide-random-choice)
and input a comma-separated list of things to choose from.
There are also some pre-defined lists of choices that can be
accessed with the following shortcuts (and it should be obvious from
a quick look in decide.el how to define your own for frequently used lists!):

? w 4 -> decide-whereto-compass-4 (N,S,W,E)
? w 6 -> decide-whereto-compass-6 (N,S,W,E,U,D)
? w 8 -> decide-whereto-compass-8 (N,S,E,W,NE,NW,SE,SW)
? w 1 0 -> decide-whereto-compass-10 (N,S,E,W,NE,NW,SE,SW,U,D)
? W 2 -> decide-whereto-relative-2 (left,right)
? W 3 -> decide-whereto-relative-3 (forward,left,right)
? W 4 -> decide-whereto-relative-4 (forward,left,right,back)
? W 6 -> decide-whereto-relative-6 (forward,left,right,back,up,down)

It is also possible to pick random combinations of words taken from the
variable decide-tables using ? t (decide-from-table). decide-table is
an alist that gives lists of possible values for each 'table'. If one of
the strings is the name of another table in the alist a random from that
list will be substituted. A word that is a valid dice-spec
is rolled with the result inserted. A word that is a valid range (as for
decide-random-range) will result in a random value from that range
being inserted. If a word matches the name of a
table that table will be used to insert something at that position.
A tilde (~) can be used anywhere in a table string to insert nothing, to
prevent the parser from recognizing some word, or to glue together words
or dice-specifiers without a space to separate them.
A possible expansion for a table name can have a weight added to make
it more likely to be choosen like ("dragon" . 3) (making it three times
as likely to be choosen as an expansion that has no weight given).
The default-value for decide-tables contains some examples to hopefully
make all this a bit less confusing.

Example of globally binding a keyboard combination to roll dice:
(global-set-key (kbd "C-c r") 'decide-roll-dice)

Results of decisions or dice will be input in current buffer at point,
or in the minibuffer if current buffer is read-only.

To just type a question-mark (?) press ? immediately followed by
space or enter. (Or quote the ? key normally, ie C-q ?).
