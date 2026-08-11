![build](https://github.com/Anoncheg1/pinyin-isearch/workflows/melpazoid/badge.svg)
[![MELPA](https://melpa.org/packages/pinyin-isearch-badge.svg)](http://melpa.org/#/pinyin-isearch)
![build](https://github.com/Anoncheg1/pinyin-isearch/workflows/melpazoid-release/badge.svg)
[![MELPA Stable](https://stable.melpa.org/packages/pinyin-isearch-badge.svg)](https://stable.melpa.org/#/pinyin-isearch)

Eng | [中文](./README_zh.md)

# pinyin-isearch - Emacs package for toneless pinyin search in pinyin and Chinese characters.

Allow to search with pinyin without diacritical marks in pinyin text. With few characters you will find all variants.

Emacs Isearch "submode" that replace isearch-regexp-function to generate regex for search.

For example: to find "Shànghǎi" and "上海" in text you just type: ``` C-s shanghai ```.

Based on Emacs "chinese-sisheng", "chinese-py", "chinese-punct".

# Files
```text
pinyin-isearch.el
 ├─ pinyin-isearch-pinyin.el (→ pinyin-isearch-loaders.el)
 ├─ pinyin-isearch-chars.el (→ pinyin-isearch-loaders.el)
 └─ pinyin-isearch-loaders.el
```

# Demonstation
![Demo](https://codeberg.org/Anoncheg/public-share/raw/branch/main/pinyin-isearch.gif)

# Featurs
- should not conflict with other isearch modes
- fix isearch jumping without return.
- fallback to search for normal latin text by default

## Features of Chinese characters search
- search from the first character entered.
- punctulation Chinese search with ascii charactes: .,[]<>()$-"` and much more.
- accurate dissasemble to all possible variants.

## Features of pinyin search
- white spaces are ignored between syllables
- tone or diacritical mark required only in first syllable in text: Zhēn de ma

# Installation
## from MELPA

1) Add to `~/.emacs`

```elisp
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
```

2) Install via `M-x package-install RET cui RET~ or ~M-x package-list-packages`

## from GitHub or Codeberg
1) `git clone https://repo/user/pinyin-isearch`

2) Add to `~/.emacs`

```elisp
(add-to-list 'load-path "/path-to/pinyin-isearch/")
(require 'pinyin-isearch)
(pinyin-isearch-load) ;; force loading (optional) before mode
```

# Usage
After ```C-s/r``` in isearch mode:
- ```M-s h``` to activate Chinese characters seearch only submode.
- ```M-s p``` to activate pinyin search only  submode.
- ```M-s s``` to activate strict pinyin and Chinese characters submode.
- ```M-s u``` to activate strict Chinese characters isearch submode.
- ```M-s n``` to activate default Pinyin-isearch mode.
- ```M-s r``` to activate standard search.

or with M-x ```pinyin-isearch-forward/backward```

You can set this mode by default per file with:

```;-*- mode: pinyin-isearch; -*-```

# Configuration

`M-x customize-group pinyin-isearch`

Variable `pinyin-isearch-default-mode` used to set default mode for `C-s/r` isearch: pinyin only or Chinese characters only or some strict version.
