               ┏━━━━━━━┓
   ╭──────╮    ┃ thick ┣═◁═╗
   │ thin ┝◀━━━┫ box   ┃   ║
   │ box  │    ┗━━━━━━━┛   ║
   ╰───┬──╯         ╔══════╩═╗
       ↓            ║ double ║
       ╰────────────╢ box    ║
                    ╚════╤═══╝
     ▛▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▜   │
     ▌quadrant-blocks▐─◁─╯
     ▙▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▟

UNICODE characters are available to draw nice boxes
and lines.
They come in 4 flavours: thin, thick, double, and quadrant-blocks.
Uniline makes it easy to draw and combine all 4 flavours.
Use the arrows on the keyboard to move around leaving a line behind.

Uniline is a minor mode.  Enter it with:
  M-x uniline-mode
Leave it with:
  C-c C-c

A font able to displays the needed UNICODE characters have to
be used.  It works well with the following families:
- DejaVu Sans Mono
- Unifont
- Hack
- JetBrains Mono
- Cascadia Mono
- Agave
- JuliaMono
- FreeMono
- Iosevka Comfy Fixed

Also, the encoding of the file must support UNICODE.
One way to do that, is to add a line like this one
at the top of your file:
  -*- coding:utf-8; -*-
