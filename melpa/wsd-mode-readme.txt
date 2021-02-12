
This is a major-mode for modelling and editing sequence-diagrams
using the syntax employed by the online service
www.websequencediagrams.com.

The mode supports inline rendering the diagrams through the API
provided through the website and persisting these to image-files next
to the files used to generate them.

It will automatically activate for files with a WSD-extension.


Features:

- syntax higlighting of reccognized keywords
- automatic indentation of block-statements
- generating and saving diagrams generated through WSD's online API.
- support for WSD premium features (svg-export, etc) if API-key is
  provided.
- rendering diagrams inline in Emacs, or in external OS viewer if image
  format is not supported by Emacs.


Customization:

To create mode-specific emacs-customizations, please use the
wsd-mode-hook.

A short summary of customizable variables:

- wsd-api-key (default blank. required for premium-features.)
- wsd-format (default png. svg requires premium, thus api-key.)
- wsd-style (default modern-blue)
- wsd-indent-offset (default 4)
- wsd-font-lock-keywords
