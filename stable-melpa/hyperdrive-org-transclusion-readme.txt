This file contains functionality related to transcluding content over the
hyper:// protocol using hyperdrive.el.  Features include:

- Transclude plain text
  + Transclude only Org headings matching search options
- Transclude HTML converted to Org using Pandoc with `org-transclusion-html'
  + Transclude only HTML headings matching link anchor
- TODO: Support :lines
- TODO: Handle relative links in transcluded content.

For more information, see the `hyperdrive' manual:
(info "(hyperdrive)Org-transclusion integration")
