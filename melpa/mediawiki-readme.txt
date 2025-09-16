This version of mediawiki.el represents a merging of wikipedia-mode.el (maintained by Uwe Brauer <oub at mat.ucm.es>)
from https://www.emacswiki.org/emacs/wikipedia-mode.el for its font-lock code, menu, draft mode, replying and
convenience functions to produce mediawiki.el 2.0.

The package has been reorganized into a modular structure for better maintainability and code organization,
while maintaining full backward compatibility.  The main mediawiki.el file now serves as an entry point that
loads all the modular components.

Package Structure:
- mediawiki-core.el: Core variables, constants, and fundamental utilities
- mediawiki-faces.el: Font-lock face definitions for MediaWiki syntax
- mediawiki-font-lock.el: Font-lock keywords and syntax highlighting rules
- mediawiki-api.el: MediaWiki API interaction and data processing
- mediawiki-auth.el: Authentication and login management
- mediawiki-http.el: HTTP utilities and compatibility functions
- mediawiki-page.el: Page editing, saving, and content management
- mediawiki-draft.el: Draft functionality and temporary editing
- mediawiki-site.el: Site configuration and management
- mediawiki-utils.el: General utility functions
- mediawiki-mode.el: Major mode definition and user interface

; Installation

If you use ELPA, you can install via the M-x package-list-packages interface.  This is preferable as you will have
access to updates automatically.

The modular structure is transparent to users - simply require 'mediawiki as before and all functionality
will be available.
