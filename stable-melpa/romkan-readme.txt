
romkan.el provides bidirectional conversion between Japanese Romaji
(ローマ字) and Kana (仮名) scripts. It supports both Hiragana (平仮名)
and Katakana (片仮名), as well as conversion between Hepburn
(ヘボン式) and Kunrei-shiki (訓令式) romanization systems.

Usage:

  (romkan-to-hiragana "konnichiwa")  ;; => "こんにちわ"
  (romkan-to-katakana "konnichiwa")  ;; => "コンニチワ"
  (romkan-to-roma "こんにちは")       ;; => "konnichiha"
  (romkan-to-hepburn "konnitiha")    ;; => "konnichiha"
  (romkan-to-kunrei "konnichiha")    ;; => "konnitiha"

The package uses static conversion tables for efficiency and supports
common Romaji patterns including double consonants (っ/ッ), long vowels,
and special characters.
