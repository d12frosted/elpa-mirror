
2025  (updated 24/09/25)

What:
- Russian holidays
- International holidays: Valentine's Day, April Fools' Day, Halloween
- Key Orthodox Christian Holidays
- Old Slavic Fests
- Open source conferences: Emacs, FSF, GNU, FOSDEM
- AI and Russian IT conferences: PyTorh, NeurIPS, IEEE CAI, WAIC,
  AI Journey dec + TAdviser SummIT nov + CNews Forum nov
- common colendar configuration

Why? Because the dates will be updated per year at least.

Not included: regional holidays.

Features:
- Support arbitrary number of years at once
- fix for behavior of `list-holidays' function included
- this package is example of how to set holidays per year

Usage:
(require 'russian-calendar)
(setopt calendar-holidays (append russian-calendar-holidays
                                  ;; - uncomment if you need:
                                  ;; russian-calendar-general-holidays
                                  ;; russian-calendar-orthodox-christian-holidays
                                  ;; russian-calendar-old-slavic-fests
                                  ;; russian-calendar-open-source-confs
                                  ;; russian-calendar-ai-confs
                                  ;; russian-calendar-russian-it-confs
                                  ))
;; optional:
(russian-calendar-localize)
(russian-calendar-set-location-to-moscow)
(russian-calendar-show-diary-holidays-in-calendar)
(russian-calendar-enhance-calendar-movement)
(russian-calendar-fix-list-holidays)
(russian-calendar-check-year-not-obsolate)

Other packages:
- Navigation in Dired, Packages, Buffers modes https://github.com/Anoncheg1/firstly-search
- Search with Mandarin Chinese pinying	https://github.com/Anoncheg1/pinyin-isearch
- Ediff fix					https://github.com/Anoncheg1/ediffnw
- Dired history				https://github.com/Anoncheg1/dired-hist
- Mark selected window with contrast	https://github.com/Anoncheg1/selected-window-contrast
- Org hyperlinks enhanced			https://github.com/Anoncheg1/org-links
- Solution for "callback hell"		https://github.com/Anoncheg1/emacs-async1
- Call LLMs and AI agents from Org-mode ai block. https://github.com/Anoncheg1/emacs-oai

*DONATE MONEY*:
You can sponsor author directly with crypto currencies:
- BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
- USDT (Tether) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
- TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D
