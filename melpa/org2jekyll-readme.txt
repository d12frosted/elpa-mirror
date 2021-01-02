Functions to ease publishing jekyll posts from org-mode file

Providing you have a working `'jekyll`' and `'org-publish`'
This will permit you to simply export an org-mode file with the right jekyll
format to the right folder

M-x org2jekyll-create-draft create a draft with the necessary metadata

M-x org2jekyll-publish publish the current post (or page) to the jekyll folder

M-x org2jekyll-publish-pages to publish all pages (layout 'default')

M-x org2jekyll-publish-posts to publish all post pages (layout 'post')

M-x org2jekyll-mode to activate org2jekyll's minor mode

You can customize using M-x customize-group RET org2jekyll RET

More information on https://github.com/ardumont/org2jekyll
