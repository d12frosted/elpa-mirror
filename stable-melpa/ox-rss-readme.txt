This library implements an RSS 2.0 back-end for Org exporter, based
on the `html' back-end.

It requires Emacs 24.1 at least.

It provides two commands for export, depending on the desired output:
`org-rss-export-as-rss' (temporary buffer) and `org-rss-export-to-rss'
(as a ".xml" file).

This backend understands three new option keywords:

#+RSS_EXTENSION: xml
#+RSS_IMAGE_URL: https://myblog.org/mypicture.jpg
#+RSS_FEED_URL: https://myblog.org/feeds/blog.xml

It uses #+HTML_LINK_HOME: to set the base url of the feed.

Exporting an Org file to RSS modifies each top-level entry by adding a
PUBDATE property.  If `org-rss-use-entry-url-as-guid', it will also add
an ID property, later used as the guid for the feed's item.

The top-level headline is used as the title of each RSS item unless
an RSS_TITLE property is set on the headline.

You typically want to use it within a publishing project like this:

(add-to-list
 'org-publish-project-alist
 '("homepage_rss"
   :base-directory "~/myhomepage/"
   :base-extension "org"
   :rss-image-url "http://lumiere.ens.fr/~guerry/images/faces/15.png"
   :html-link-home "http://lumiere.ens.fr/~guerry/"
   :html-link-use-abs-url t
   :rss-extension "xml"
   :publishing-directory "/home/guerry/public_html/"
   :publishing-function (org-rss-publish-to-rss)
   :section-numbers nil
   :exclude ".*"            ;; To exclude all files...
   :include ("index.org")   ;; ... except index.org.
   :table-of-contents nil))

... then rsync /home/guerry/public_html/ with your server.

By default, the permalink for a blog entry points to the headline.
You can specify a different one by using the :RSS_PERMALINK:
property within an entry.
