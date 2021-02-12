This package provides an elisp implementation of the HSLUV colorspace
conversions as created by Alexei Boronine, and documented on
http://www.hsluv.org/

HSLuv is a human-friendly alternative to HSL.

CIELUV is a color space designed for perceptual uniformity based on human
experiments. When accessed by polar coordinates, it becomes functionally
similar to HSL with a single problem: its chroma component doesn't fit into
a specific range.

HSLuv extends CIELUV with a new saturation component that allows you to span
all the available chroma as a neat percentage.

The reference implementation is written in Haxe and released under
the MIT license. It can be found at https://github.com/hsluv/hsluv
The math is available under the public domain.

The following functions provide the conversions
from RGB to/from HSLUV and HPLUV:

  (hsluv-hsluv-to-rgb (list H S Luv))
  (hsluv-hpluv-to-rgb (list H P Luv))
  (hsluv-rgb-to-hsluv (list R G B))
  (hsluv-rgb-to-hpluv (list R G B))

; Changelog

2017/04/15 v1.0  First version
2018/08/07       Split off testing
2018/10/13       Cleanup for package release in the wild
