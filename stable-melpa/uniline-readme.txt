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

╭─Pure text────────────────□
│ UNICODE characters are available to draw nice boxes and lines.
│ They come in 4 flavours: thin, thick, double, and quadrant-blocks.
│ Uniline makes it easy to draw and combine all 4 flavours.
│ Use the arrows on the keyboard to move around leaving a line behind.
╰──────────────────────────╮
╭─Minor mode───────────────╯
│ Uniline is a minor mode.  Enter it with:
│   M-x uniline-mode
│ Leave it with:
│   C-c C-c
╰──────────────────────────╮
╭─Fonts────────────────────╯
│ A font able to displays the needed UNICODE characters have to
│ be used.  It works well with the following families:
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
╰──────────────────────────╮
╭─UTF-8────────────────────╯
│ Also, the encoding of the file must support UNICODE.
│ One way to do that, is to add a line like this one
│ at the top of your file:
│   -*- coding:utf-8; -*-
╰──────────────────────────╮
╭─Hydra or Transient───────╯
│ Uniline comes with two flavours of user interfaces:
│ Hydra and Transient.
│ Both versions are compiled when installing the package.
│
│ Then one or the other packages must be loaded (not both)
│ for example with:
│   (require 'uniline-hydra)
│ or
│   (use-package uniline-hydra
│     :bind ("C-<insert>" . uniline-mode))
│
│ This file, uniline-core.el, is the largest one, the one
│ implementing all the core functions independent from
│ Hydra or Transient
╰──────────────────────────□
