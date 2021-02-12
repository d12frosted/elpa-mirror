This package is a port of the Nettuts+ Fetch plugin for Sublime Text
(http://net.tutsplus.com/articles/news/introducing-nettuts-fetch/)

This package allows you to quickly download and unpack external resources and
libraries to include in your project.

To add entries to the lookup tables, append the fetch-package-alist like so:

(add-to-list 'fetch-package-alist
             '("name" . "url") t)

After the list is populated, you can fetch the resources using
M-x fetch-resource

The temporary download directory can be adjusted by setting the
fetch-download-location variable.
