`org-vcard' is a package for exporting and importing [vCards](https://en.wikipedia.org/wiki/Vcard) from within [GNU Emacs](https://www.gnu.org/software/emacs/)' [Org mode](http://orgmode.org/).

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [TODO](#todo)
- [Issues](#issues)
- [Testing](#testing)
- [License](#license)

## Features

* _Backwards-compatible with org-contacts.el._

`org-vcard' comes with a built-in contacts style called `flat', which adheres to org-contacts' method of structuring contacts and contact information. It not only supports the properties specified in org-contacts.el, but many other properties as well.

* _Basic support for vCard 4.0, 3.0 and 2.1._

`org-vcard' is working towards full compliance with the vCard 4.0 ([RFC 6350](https://tools.ietf.org/html/rfc6350)), 3.0 ([RFC 2426](https://tools.ietf.org/html/rfc2426) and [RFC 4770](https://tools.ietf.org/html/rfc4770)) and [2.1](https://web.archive.org/web/20120501162958/http://www.imc.org/pdi/vcard-21.doc) specifications.

* _New contacts style: `tree'._

`org-vcard' introduces a new style for Org contacts, called `tree'. More details [below](#tree).

* _Highly customisable, via Emacs' `customize' interface._

Modify existing contact styles; change the labels used to map contact details in `org-mode' to various vCard properties/types, or add new ones. Create completely new contact styles by plugging in your own code to handle export and import.

## Installation

Install `org-vcard' from [MELPA](http://melpa.org/#/org-vcard), [MELPA Stable](http://stable.melpa.org/#/org-vcard), or put the `org-vcard' folder in your load-path and do a `(require 'org-vcard)'.

## Usage

The main user commands are `org-vcard-export' and `org-vcard-import', which are intended to be called interactively; you can press TAB at many of the minibuffer prompts to get a list of the available options for a prompt.

Both `org-vcard-export' and `org-vcard-import' are wrappers around the `org-vcard-transfer-helper' function. `org-vcard-transfer-helper' can be used to export and import programmatically (i.e. via Emacs Lisp).

Enabling `org-vcard-mode' will add an "Org-vCard" menu to the menu bar, from which one can access the various export, import and customisation options.

**Note!** When exporting to vCard using the source `buffer', narrowing is respected. If you wish to export the entire buffer without restriction, remove any narrowing in effect.

For a list of the properties available by default for each contacts style and related vCard versions, visit the "Org Vcard Styles Languages Mappings" setting in the Org Vcard customize group, or examine the value of the `org-vcard-styles-languages-mappings' variable.

**Note!** The default mappings might need to be tweaked for particular use-cases. For example, some systems create vCards with a bare `TEL' property, whereas others use `TEL;TYPE=voice'; but both are mapped to the Org `PHONE' property (for `flat' style) or `phone' FIELDTYPE (for `tree' style). In this case, the `customize' interface could be used to delete whichever of the two mappings is unwanted.

The value of the `org-vcard-include-import-unknowns' (boolean) variable specifies whether the import process should include vCard properties not listed in the mapping being used.

The value of the `org-vcard-append-to-existing-import-buffer' and `org-vcard-append-to-existing-export-buffer' (boolean) variables specify whether the import/export process should append to any existing import/export buffer. If not, a new import/export buffer is created for each import/export.

<a name="tree"></a>

### The `tree' contacts style

The structure of the `tree' contacts style is:

    * [Contact name]
    :PROPERTIES:
    :KIND: individual
    :FIELDTYPE: name
    :END:
    ** [Information type]
    *** [Information value]
    :PROPERTIES:
    :FIELDTYPE: [Field type]
    [:PREFERRED:]
    :END:

Here's an example:

    * Joan Smith
    :PROPERTIES:
    :KIND: individual
    :FIELDTYPE: name
    :END:
    ** Mobile
    *** 0000 999 999
    :PROPERTIES:
    :FIELDTYPE: cell
    :END:
    ** Email
    *** Work
    **** address1@hidden
    :PROPERTIES:
    :FIELDTYPE: email-work
    :PREFERRED:
    :END:
    *** Home
    **** address2@hidden
    :PROPERTIES:
    :FIELDTYPE: email-home
    :END:

As the `tree' style uses a heading's FIELDTYPE property to associate fields with their data, the above hierarchy is only one way to structure contacts; equivalently, one could do:

    * People
    ** Joan Smith
    :PROPERTIES:
    :KIND: individual
    :FIELDTYPE: name
    :END:
    *** Cell
    **** 0000 999 999
    :PROPERTIES:
    :FIELDTYPE: cell
    :END:
    *** Email
    **** address1@hidden
    :PROPERTIES:
    :FIELDTYPE: email-work
    :PREFERRED:
    :END:
    **** address2@hidden
    :PROPERTIES:
    :FIELDTYPE: email-home
    :END:

## TODO

* Add support for one-vCard-per-file export.

* Add support for line folding when exporting.

* Add support for multiple instances of EMAIL property.

* Add support for vCard PREF for style `flat'.

* Add support for vCard KINDs `group' and `org'.

* Add support for per-card version handling on import.

* Improve compliance with each version of the vCard specification.

* Extend test coverage.

<a name="issues"></a>

## Issues / bugs

If you discover an issue or bug in `org-vcard' not already noted:

* as a TODO item, or

* in [the project's "Issues" section on GitHub](https://github.com/flexibeast/org-vcard/issues),

please create a new issue with as much detail as possible, including:

* which version of Emacs you're running on which operating system, and

* how you installed `org-vcard'.

## Testing

A basic test suite is located in the repository `tests' directory, in `org-vcard-tests.el`. To run the suite:

1. Ensure `org-vcard.el' has been loaded, e.g. `(load "~/org-vcard/org-vcard.el")'.
2. Load the test suite: e.g. `(load "~/org-vcard/tests/org-vcard-tests.el")'.
3. Run the tests by evaluating `(ert '(tag org-vcard))'.

## License

[GNU General Public License version 3](http://www.gnu.org/licenses/gpl.html), or (at your option) any later version.
