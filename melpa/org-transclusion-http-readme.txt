This file extends the `org-transclusion' package to allow for transcluding
content over HTTP.  Features include:

- Transclude plain text
  + Transclude only Org headings matching search options
- Transclude HTML converted to Org using Pandoc, a lá `org-web-tools'
  + Transclude only HTML headings matching link anchor
- TODO: Support :lines
