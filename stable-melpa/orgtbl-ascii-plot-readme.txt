                             □
╭╴Extend Org Mode bar plots╶──╯
│ The standard Org Mode key-binding C-c " a
│ is extended with new Unicode styles of plots,
│ using Unicode block characters.
│ The new plots add visual vertical lines at selected coordinates
│ to better make sense of the graphic.
╰─────────────────────────────╮
╭╴Legacy usage╶───────────────╯
│ With out-of-the-box Org Mode, put the cursor in a column containing
│ numerical values, then type C-c " a
│ A new column is added with a bar plot.
│ When the table is refreshed (C-u C-c *),
│ the plot is updated to reflect the new values.
╰─────────────────────────────╮
╭╴New usage╶──────────────────╯
│ This package does not change:
│ - the key-binding: C-c " a
│ - the 3 legacy plots
│ This package changes:
│ - after C-c " a, asks for the type of plot (including legacy ones)
│ - gives the opportunity to change the min & max, and round them
╰─────────────────────────────╮
╭╴Zero dependencies╶──────────╯
│ As those plots are pure text, they do not require external
│ graphic formats (like JPG, GIF, PNG, SVG and so on).
│ The package itself is pure Emacs, it does not pull extra packages.
│ The only requirements are:
│ - to use a monospaced font able to display block characters.
│ - to encode the file in Unicode, for instance in UTF-8
╰─────────────────────────────╮
╭╴Example╶────────────────────╯
│
│ |  x | sin(x/7) | ascii legacy | new unicode  |
│ |----+----------+--------------+--------------|
│ |  0 |        1 | WWWWWW       | █████▉▏      |
│ |  1 | 1.142372 | WWWWWWH      | █████▉▊      |
│ |  2 | 1.281843 | WWWWWWWh     | █████▉█▋     |
│ |  3 | 1.415572 | WWWWWWWW!    | █████▉██▍    |
│ |  4 | 1.540834 | WWWWWWWWW:   | █████▉███▏   |
│ |  5 | 1.655078 | WWWWWWWWWH   | █████▉███▉   |
│ |  6 | 1.755975 | WWWWWWWWWW!  | █████▉████▌  |
│ |  7 | 1.841471 | WWWWWWWWWWW  | █████▉█████  |
│ |  8 | 1.909823 | WWWWWWWWWWW! | █████▉█████▍ |
│ |  9 | 1.959639 | WWWWWWWWWWWV | █████▉█████▊ |
│ | 10 | 1.989903 | WWWWWWWWWWWH | █████▉█████▉ |
│ | 11 | 2.000000 | WWWWWWWWWWWW | █████▉██████ |
│ | 12 | 1.989723 | WWWWWWWWWWWH | █████▉█████▉ |
│ | 13 | 1.959282 | WWWWWWWWWWWV | █████▉█████▊ |
│ | 14 | 1.909297 | WWWWWWWWWWW! | █████▉█████▍ |
│ | 15 | 1.840787 | WWWWWWWWWWW  | █████▉█████  |
│ | 16 | 1.755147 | WWWWWWWWWW!  | █████▉████▌  |
│ | 17 | 1.654122 | WWWWWWWWWH   | █████▉███▉   |
│ | 18 | 1.539770 | WWWWWWWWW:   | █████▉███▏   |
│ | 19 | 1.414421 | WWWWWWWW!    | █████▉██▍    |
│ | 20 | 1.280629 | WWWWWWWh     | █████▉█▋     |
│ | 21 | 1.141120 | WWWWWWV      | █████▉▊      |
│ | 22 | 0.998736 | WWWWWW       | █████▉▏      |
│ | 23 | 0.856377 | WWWWW.       | █████▏▏      |
│ | 24 | 0.716944 | WWWW;        | ████▎ ▏      |
│ | 25 | 0.583278 | WWW!         | ███▍  ▏      |
│ | 26 | 0.458103 | WWh          | ██▋   ▏      |
│ | 27 | 0.343967 | WW.          | ██    ▏      |
│ | 28 | 0.243198 | W!           | █▍    ▏      |
│ | 29 | 0.157846 | H            | ▉     ▏      |
│ | 30 | 0.089653 | !            | ▌     ▏      |
│ | 31 | 0.040007 | :            | ▏     ▏      |
│ #+TBLFM: $2=sin($1/7)+1;Rf6::$3='(orgtbl-ascii-draw $2 0.0 2.0 12)::$4='(orgtbl-ascii-plot-with-vert $2 0.0 2.0 12 6)
│                                       ▲
│ A vertical line here╶─────────────────╯
╰─────────────────────────────╮
╭╴Fonts╶──────────────────────╯
│ A font able to display the needed Unicode characters is required
│ Here is a list of recommended fonts:
│ - DejaVu Sans Mono
│ - Unifont
│ - Hack
│ - JetBrains Mono
│ - Cascadia Mono
│ - Agave
│ - JuliaMono
│ - FreeMono
│ - Iosevka Comfy Fixed, Iosevka Comfy Wide Fixed
│ - Aporetic Sans Mono, Aporetic Serif Mono
│ - Source Code Pro
│ Type for example:
│ M-x set-default-font DejaVu Sans Mono RET
╰─────────────────────────────╮
                             □
