N Λ N O theme is a consistent theme that comes in two flavors:
 - a light theme that is based on Material (https://material.io/)
 - a dark theme that is based on Nord (https://www.nordtheme.com/).

A theme is fully defined by a set of (1+6) faces as
explained in this paper https://arxiv.org/abs/2008.06030:

- Default face is the face for regular information.

- Critical face is for information that requires immediate action.

    It should be of high constrast when compared to other
    faces. This can be realized (for example) by setting an intense
    background color, typically a shade of red. It must be used
    scarcely.

- Popout face is used for information that needs attention.

    To achieve such effect, the hue of the face has to be
    sufficiently different from other faces such that it attracts
    attention through the popout effect.

- Strong face is used for information of a structural nature.

    It has to be the same color as the default color and only the
    weight differs by one level (e.g., light/regular or
    regular/bold). IT is generally used for titles, keywords,
    directory, etc.

- Salient face is used for information that are important.

    To suggest the information is of the same nature but important,
    the face uses a different hue with approximately the same
    intensity as the default face. This is typically used for
    links.

- Faded face is for information that are less important.

    It is made by using the same hue as the default but with a
    lesser intensity than the default. It can be used for comments,
    secondary information and also replace italic (which is
    generally abused anyway

- Subtle face is used to suggest a physical area on the screen.

    It is important to not disturb too strongly the reading of
    information and this can be made by setting a very light
    background color that is barely perceptible.


Usage example:

You can use the theme as a regular theme or you can call
(nano-light) / (nano-dark) explicitely to install the light or dark
version.

With GUI, you can mix frames with light and dark mode. Just call
(nano-new-frame 'light) or (nano-new-frame 'dark)

Optionally, you can use (nano-mode) to setup recommended settings for
the theme. Be careful since it will modify your configuration and
requires a set of specific fonts. This needs to be called before
setting the theme

Recommended font is "Roboto Mono" or "Roboto Mono Nerd" if you want
to benefit from all the fancy glyphs. See https://www.nerdfonts.com.