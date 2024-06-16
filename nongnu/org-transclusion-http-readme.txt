


org-transclusion-http
═════════════════════

  Transclude content over HTTP in Org mode with [org-transclusion]!


[org-transclusion] <https://nobiot.github.io/org-transclusion/>

Dependencies
────────────

  `org-transclusion-http' uses [Pandoc] to render HTML content as Org
  mode, so to make full use of this package please ensure that the
  `pandoc' command is installed and in your `PATH'.


[Pandoc] <https://pandoc.org/>


Installation
────────────

  Install `org-transclusion-http' with `M-x package-install RET
  org-transclusion-http' and then add the following snippet to your
  configuration:

  ┌────
  │ (with-eval-after-load 'org-transclusion
  │   (add-to-list 'org-transclusion-extensions 'org-transclusion-http)
  │   (require 'org-transclusion-http))
  └────


Usage
─────

  Add an `org-transclusion' link to an Org mode buffer:

  ┌────
  │ #+transclude: [[https://ushin.org/software.html]]
  └────

  Then move point onto the link, and run `M-x org-transclusion-add'.
  Emacs will download the webpage and convert its HTML content to Org
  mode with Pandoc before displaying as an Org subtree in the same
  buffer.

  `org-transclusion-http' also handles non-HTML content, which will be
  rendered as-is.

  For more information on `org-transclusion', please see the
  [`org-transclusion' manual].


[`org-transclusion' manual] <https://nobiot.github.io/org-transclusion/>

Transclude only content at HTML link fragment
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  When the `#+transclude:' link contains a link fragment, also known as
  an anchor or target, `org-transclusion-http' attempts to guess which
  HTML element(s) to transclude:

  ┌────
  │ #+transclude: [[https://ushin.org/needs-list.html#care]] # Just "Care" subtree
  │ #+transclude: [[https://ushin.org/needs-list.html]]      # Whole file
  └────

  To improve `org-transclusion''s ability to determine which HTML
  elements to transclude based on the element its link fragment points
  to, please patch the `org-transclusion-html.el' file in
  `org-transclusion' itself.

  For more usage examples, please see the tests.


Limitations
───────────

  Certain features of `org-transclusion', such as live-syncing and
  opening source buffers, are not supported.

  `:lines' are not yet supported.  Patches welcome!


Bugs and Patches
────────────────

  Bugs can be submitted to the [ushin issue tracker].  Patches, comments
  or questions can be submitted to the [ushin public inbox].


[ushin issue tracker] <https://todo.sr.ht/~ushin/ushin>

[ushin public inbox] <https://lists.sr.ht/~ushin/ushin>


Acknowledgments
───────────────

  • [Adam Porter] for code review and bug fixes.
  • [Philip Kaludercic] for code review.


[Adam Porter] <https://github.com/alphapapa/>

[Philip Kaludercic] <https://amodernist.com/>


Changelog
─────────

0.3
╌╌╌

◊ Internal

  • Prepare for NonGNU ELPA submission.


0.2
╌╌╌

◊ Change

  • Better error message when `pandoc' is not available.


◊ Fix

  • Don't prompt to stop HTTP transclusion process when killing Emacs.


◊ Internal

  • Better recognition of Org and HTML documents.
  • Update to match upstream `org-transclusion' API.
  • More tests.


0.1
╌╌╌

  Initial release.
