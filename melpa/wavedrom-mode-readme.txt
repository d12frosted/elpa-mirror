Major-mode for editing and rendering WaveJSON files to create timing diagrams
using wavedrom:
 - https://wavedrom.com/

Requirements:
 - `wavedrom-cli': https://github.com/wavedrom/cli
 - Optional: `inkscape' to export to PDF

Usage:
- Create a file with .wjson extension and `wavedrom-mode' will automatically
  be enabled next time it is opened.
- Fill the file with valid WaveJSON syntax and every time it gets saved the
  function `wavedrom-compile' will be run, updating the output file and its
  associated buffer.
- The output file path will be determined from the value of customizable
  variables `wavedrom-output-format' and `wavedrom-output-directory'.

Keybindings:
 - C-c C-c `wavedrom-compile'
 - C-c C-p `wavedrom-preview-browser'

Some WaveDrom documentation and tutorials:
 - https://wavedrom.com/tutorial.html (timing diagram)
 - https://wavedrom.com/tutorial2.html (schematic)
 - https://github.com/wavedrom/schema/blob/master/WaveJSON.md
