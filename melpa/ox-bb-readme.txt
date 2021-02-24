This library implements a BBCode back-end for Org exporter.  Source
code snippets are exported for the GeSHi plugin.

ox-bb provides three different commands for export:

- `ox-bb-export-as-bbcode' exports to a buffer named "*Org BBCode
  Export*" and automatically applies `bbcode-mode' if it is
  available.

- `ox-bb-export-to-kill-ring' does the same and additionally copies
  the exported buffer to the kill ring so that the generated BBCode
  is available in the Clipboard.

- `ox-bb-export-to-bbcode' exports to a file with extension
  ".bbcode".
