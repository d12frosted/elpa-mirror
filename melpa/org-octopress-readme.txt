Basic settings:

(setq org-octopress-directory-top       "~/octopress/source")
(setq org-octopress-directory-posts     "~/octopress/source/_posts")
(setq org-octopress-directory-org-top   "~/octopress/source")
(setq org-octopress-directory-org-posts "~/octopress/source/blog")
(setq org-octopress-setup-file          "~/lib/org-sty/setupfile.org")

M-x org-octopress

Note:
 In octopress/_config.yml, you must set the permelink attribute:
   permalink: /blog/:year-:month-:day-:title.html
