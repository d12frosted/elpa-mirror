This package provides utilities to manipulate colors. Compared to the
built-in color.el, chroma.el uses provides a consistent interface, always
accepting and returning colors as lists. It also uses commonly used
representation for components: 8 bit values for RGB colors, 0-360 hue for
HSL colors.

RGB colors are represented as lists of three elements for the red, green
and blue components. RGB components are represented as 8 bit integer.

HSL colors are represented as lists of three elements for the hue,
saturation and lightness. Hue is represented as an integer in [0, 360].
Saturation and lightness are represented as floating point numbers in [0.0,
1.0] rounded to two decimal places.
