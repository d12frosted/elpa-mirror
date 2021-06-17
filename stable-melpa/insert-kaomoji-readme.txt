
Kaomojis are eastern/Japanese emoticons, which are usually displayed
horizontally, as opposed to the western vertical variants (":^)",
";D", "XP", ...).

To achieve this they make much more use of more obscure and often
harder to type unicode symbols, which often makes it more difficult
to type, or impossible if you don't know the symbols names/numbers.

This package tries to make it easier to use kaomojis, by using
`completing-read' and different categories.  The main user
functions are therefore `insert-kaomoji' to insert a kaomoji at
point, and `insert-kaomoji-into-kill-ring' to push a kaomoji onto
the kill ring.

The emoticons aren't stored in this file, but (usually) in the
KAOMOJIS file that should be in the same directory as this source
file.  This file is parsed during byte-compilation and then stored
in `insert-kaomoji-alist'.

The kaomojis in KAOMOJIS have been selected and collected from these
sites:
- https://wikileaks.org/ciav7p1/cms/page_17760284.html
- http://kaomoji.ru/en/
- https://en.wikipedia.org/wiki/List_of_emoticons
