This package is a theme for `spaceline' and recreates most of the
segments available in that package using icons from
`all-the-icons'.  Icon fonts allow for more tailored and detailed
information in the mode line.

Currently this package provides segmets for the following functions
without the need for optional dependencies

- `modified'          Whether or not the current buffer has been modified
- `dedicated'         Whether or not the current buffer is dedicated
- `buffer-path'       The Path of the current buffer
- `buffer-id'         The id of the current buffer
- `buffer-size'       The size of the buffer
- `mode-icon'         The Major Mode displayed as an icon
- `process'           The currently running process
- `position'          The Line/Column current position
- `region-info'       Count of lines and words currently in region
- `narrowed'          Whether or not the current buffer is narrowed
- `fullscreen'        An indicator of whether or not window is fullscreen
- `text-scale'        The amount of global text scale
- `vc-icon'           The current Version Control Icon
- `vc-status'         The VC status, e.g. branch or revision
- `git-ahead'         The number of commits ahead of upstream
- `package-updates'   The number of packages available for update
- `hud'               A widget displaying how far through the buffer you are
- `buffer-position'   A percentage or word describing buffer position
- `time'              The Current Time with icon

There are also some segments that require optional dependencies,
this is a list of them and their required packages.

- `bookmark' [`bookmark']                           Whether or not the current buffer has been modified
- `window-number' [`winum' or `window-numbering']   The current window number
- `eyebrowse' [`eyebrowse']                         The Eyebrowse workspace
- `projectile' [`projectile']                       The current project you're working in
- `multiple-cursors' [`multiple-cursors']           Show the number of active multiple cursors in use
- `git-status' [`git-gutter']                       Number of added/removed lines in current buffer
- `flycheck-status' [`flycheck']                    A summary of Errors/Warnings/Info in buffer
- `flycheck-status-info' [`flycheck']               A summary dedicated to Info statuses in buffer
- `which-function' [`which-function']               Display the name of function your point is in
- `weather' [`yahoo-weather']                       Display an icon of the current weather
- `temperature' [`yahoo-weather']                   Display the current temperature with a coloured thermometer
- `sunrise' [`yahoo-weather']                       Display an icon to show todays sunrise time
- `sunset' [`yahoo-weather']                        Display an icon to show todays sunset time
- `battery-status' [`fancy-battery']                Display a colour coded battery with time remaining
- `nyan-mode' [`nyan-mode']                         Display Nyan Cat as a progress meter through the buffer
