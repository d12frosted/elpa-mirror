SKK-MODE is a mode for inputting Japanese to a current buffer which is
composed of four minor modes described below.

     +---------------+-------- skk-mode -----+--------------------+
     |               |                       |                    |
     |               |                       |                    |
 skk-j-mode   skk-latin-mode   skk-jisx0208-latin-mode   skk-abbrev-mode
                 ASCII               JISX0208 LATIN         ABBREVIATION
(C-j wakes up skk-j-mode)      (ZEN'KAKU EIMOJI)

skk-j-mode-map               skk-jisx0208-latin-mode-map
             skk-latin-mode-map                        skk-abbrev-mode-map

skk-katakana: nil
  HIRAKANA

skk-katakana: t
  KATAKANA
