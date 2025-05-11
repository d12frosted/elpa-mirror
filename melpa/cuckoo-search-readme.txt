cuckoo-search.el is collection of hacks to allow for content-based
search in Elfeed. Requires ripgrep and the Elfeed package, the
latter must be loaded first - see the above URL for more info.



; News

0.2.5
- Breaking changes: the user should now activate `cuckoo-search-global-mode'
prior to running cuckoo-search

0.2.4
- Even more adjustments; added minor-mode `cuckoo-search-mode' and
global mode `cuckoo-search-global-mode'

0.2.3
- More adjustments; added GPL v3 license

0.2.2
- More polishing for intended Melpa release

0.2.1
- Now uses `elfeed-db-directory` to get value for data-folder and
index file; flycheck package hygiene (thanks @sarg for both
suggestions); removed package-lint issues

0.2
- Added `cuckoo-saved-searches'

0.1
- Initial release
