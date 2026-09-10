![build](https://github.com/Anoncheg1/pinyin-isearch/workflows/melpazoid/badge.svg)
[![MELPA](https://melpa.org/packages/pinyin-isearch-badge.svg)](http://melpa.org/#/pinyin-isearch)
![build](https://github.com/Anoncheg1/pinyin-isearch/workflows/melpazoid-release/badge.svg)
[![MELPA Stable](https://stable.melpa.org/packages/pinyin-isearch-badge.svg)](https://stable.melpa.org/#/pinyin-isearch)
[![NonGNU ELPA](https://elpa.nongnu.org/nongnu/pinyin-isearch.svg)](https://elpa.nongnu.org/nongnu/pinyin-isearch.html)

Eng | [中文](./README_zh.md)

# pinyin-isearch - Emacs package for toneless pinyin search in pinyin and Chinese characters.

This package allow to search with pinyin without diacritical marks in pinyin text and chinese characters. Accurate regex for search created that match all variants.

Implemented as Emacs Isearch modification.

For example: to find "Shànghǎi" and "上海" in text you just type: ``` C-s shanghai ```.

Based on Emacs "chinese-sisheng", "chinese-py", "chinese-punct".

# Files
```text
pinyin-isearch.el
 ├─ pinyin-isearch-pinyin.el (→ pinyin-isearch-loaders.el)
 ├─ pinyin-isearch-chars.el (→ pinyin-isearch-loaders.el)
 └─ pinyin-isearch-loaders.el
*-tests.el
```

# Emacs versions support
Emacs 28.1 -> 30.2

# Demonstation
![Demo](https://codeberg.org/Anoncheg/public-share/raw/branch/main/pinyin-isearch.gif)

# Featurs
- should not conflict with other isearch modes
- fix isearch jumping without return.
- fallback to search for normal latin text by default
- support for apostraphe ('’), like “zú’ò” 足哦.
- no external dependencies

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

**Activate:** `M-x pinyin-isearch-mode`

**Search:**
- `C-s` / `C-r` — Start forward/backward search
- Type Pinyin (e.g., `beijing`) → highlights: 北京, Běi jīng, beijing
- `C-n` / `C-p` — Navigate matches
- `RET` — Confirm, jump to match

In other words:
1. M-x pinyin-isearch-mode                     [Activate]
2. C-s                                         [Start search]
3. "beijing"                                   [Type pinyin]
   → Highlights: 北京 and Běi jīng and beijing.
4. M-s h                                       [Switch to characters-only]
   → Filter results to exact character matches only
5. M-s s                                       [Enable strict mode]
   → More refined, exact-match-only results
6. C-n / C-p                                   [Navigate matches]
7. RET                                         [Confirm, jump to match]


**Direct functions:** `M-x pinyin-isearch-forward/backward`

**Submode Controls (during search):**
| Key | Effect |
|---------|--------|
| `M-s h` | Characters-only search |
| `M-s p` | Pinyin-only search |
| `M-s b` | Both Pinyin & characters (default) |
| `M-s s` | Toggle strict mode (exact matches only) |
| `M-s <f1>` | Help reference |


**Fallback:** `C-u C-s` at any time → standard Emacs isearch (bypass Pinyin entirely)

For **file-local** activation, add this line at the begining of file:
```elisp
;-*- mode: pinyin-isearch; -*-
```

# Configuration

`M-x customize-group pinyin-isearch`

| Option | Default | Effect |
|--------|---------|--------|
| `pinyin-isearch-default-mode` | `both` | Default search type at mode start |
| `pinyin-isearch-strict` | `nil` | Global strictness setting |
| `pinyin-isearch-full-fallback` | `t` | Include Latin letter fallback |
| `pinyin-isearch-fix-jumping-flag` | `t` | Fix search-restart position behavior |


# Other packages
- Navigation in Dired, Packages, Buffers modes https://github.com/Anoncheg1/firstly-search
- LLM chat blocks for Org-mode	https://github.com/Anoncheg1/emacs-cui
- Ediff fix		https://github.com/Anoncheg1/ediffnw
- Dired history	https://github.com/Anoncheg1/dired-hist
- Selected window contrast	https://github.com/Anoncheg1/selected-window-contrast
- Copy link to clipboard	https://github.com/Anoncheg1/emacs-org-links
- Solution for "callback hell"	https://github.com/Anoncheg1/emacs-async1
- Restore buffer state		https://github.com/Anoncheg1/emacs-unmodified-buffer1
- outline.el usage		https://github.com/Anoncheg1/emacs-outline-it
- hiding password in cafe	https://github.com/Anoncheg1/emacs-hidepass
- TAB key reimplementation	https://github.com/Anoncheg1/emacs-indent
- Dates for Org-mode headers	https://github.com/Anoncheg1/emacs-org-history

# Donate, sponsor the author
You can sponsor author crypto money directly with crypto currencies:
- **BTC (Bitcoin) address:** `1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25`

![](https://raw.githubusercontent.com/Anoncheg1/public-share/refs/heads/main/BTC-1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25.png)

- **USDT (Tether on TRX-TRON) address:** `TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN`

![](https://raw.githubusercontent.com/Anoncheg1/public-share/refs/heads/main/USDT-TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN.png)

- **TON (Telegram Open Network) address:** `UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D`
