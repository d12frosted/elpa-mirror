
Highlights Text::Xslate files using the Kolon syntax

Some parts of this code originated from two other projects:

https://github.com/yoshiki/tx-mode
https://bitbucket.org/lattenwald/.emacs.d/src/347b18c4f834/site-lisp/kolon-mode.el

Commands (interactive functions):
`kolon-show-version'
`kolon-open-docs'
`kolon-comment-region'
`kolon-uncomment-region'

Other functions:
`kolon-indent-line'
`indent-newline'

TODO: It would be nice to figure out how comment-or-uncomment-region
works so we can get it to work properly. Right now it'll insert
HTML comments, so kolon-(un)comment-region will need to be bound
individually or used from their menu entries.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This code is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0. For details, see
http://www.perlfoundation.org/artistic_license_2_0

This program is distributed in the hope that it will be useful,
but it is provided "as is" and without any express or implied
warranties. For details, see
http://www.perlfoundation.org/artistic_license_2_0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
