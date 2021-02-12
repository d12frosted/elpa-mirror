
-*- mode: org -*-
* Description

This utility lets you input math symbols by TeX names
with the following commands.

- M-x toggle-input-method + math-symbols-tex
- M-x math-symbols-from-tex-region
- M-x math-symbols-insert
- M-x math-symbols-ivy

Also, you can convert character to TeX names by the following command.
- M-x math-symbols-to-tex-region
- M-x math-symbols-to-tex-unicode-region

You can also input various styled mathematical symbols by input
methods, or by specifying region or string.

- M-x toggle-input-method + math-symbols-italic (or script, etc.)
- M-x math-symbols-italic-region
- (math-symbols-italic-string "target string")


* Examples:

** TeX to Char Conversion
: "\int g(x^2)dx = \pi e^(ix)" → "∫ 𝑔(𝑥²)𝑑𝑥 = 𝜋 𝑒^(𝑖𝑥)"
: (M-x math-symbols-from-tex-region)
: "f(x+y)" → "𝑓(𝑥+𝑦)" (M-x math-symbols-italic-region)

** Character to Math-Character Conversion
: "Fraktur" → "𝔉𝔯𝔞𝔨𝔱𝔲𝔯" (M-x math-symbols-fraktur-region)
: "black" → "𝒷ℓ𝒶𝒸𝓀" (M-x math-symbols-script-region)
: "Quo Vadis" → "ℚ𝕦𝕠 𝕍𝕒𝕕𝕚𝕤" (M-x math-symbols-double-struck-region)
: "3+(2-1)=4" → "³⁺⁽²-¹⁾⁼⁴" (M-x math-symbols-superscript-region)

* Required Font

You should install Math fonts such as "STIX" to your system, and
then add it to your fontset to fully utilize this tool.  Recent
MacOS includes this font by default.  You can freely download them
from [[STIX website][http://www.stixfonts.org]].

* Licenses

This program incorporates `unimathsymbols.txt' data file which is
licensed under "LaTeX Project Public License".  This program is
GPL.

* Math Symbols Support Table

| styles / scripts         | alphabets | greeks※ | numerals |
|--------------------------+-----------+----------+----------|
| bold                     | yes       | yes      | yes      |
| (bold) italic            | yes       | yes      | yes      |
| (bold) fraktur           | yes       | no       | no       |
| (bold) script            | yes       | no       | no       |
| double-struck            | yes       | partial  | yes      |
| monospace                | yes       | no       | yes      |
| sans-serif (italic)      | yes       | no       | yes      |
| sans-serif bold (italic) | yes       | yes      | yes      |
| subscript                | partial   | no       | yes      |
| superscript              | partial   | no       | yes      |

 ※ `greeks' include greek symbols and nabla (ϵ, ϑ, ϰ, ϕ, ϱ, ϖ, ∇).

* References

- UTR#25 UNICODE SUPPORT FOR MATHEMATICS
  (http://www.unicode.org/reports/tr25/tr25-6.html)
