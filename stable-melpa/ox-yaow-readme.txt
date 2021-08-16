This package adds another org html export option which aims to provide a
lightweight wiki.

Example usage:

Assuming you have some org files in ~/org, first register a new project
using `org-publish-project-alist':

(setq rto-css '("https://fniessen.github.io/org-html-themes/src/readtheorg_theme/css/htmlize.css"
                  "https://fniessen.github.io/org-html-themes/src/readtheorg_theme/css/readtheorg.css")
        rto-js '("https://fniessen.github.io/org-html-themes/src/lib/js/jquery.stickytableheaders.min.js"
                 "https://fniessen.github.io/org-html-themes/src/readtheorg_theme/js/readtheorg.js")
        extra-js '("https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"
                   "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js" )
        ox-yaow-html-head (concat (mapconcat (lambda (url) (concat "<link rel=\"stylesheet\" type=\"text/css\" href=\"" url "\"/>\n")) rto-css "")
                                  (mapconcat (lambda (url) (concat "<script src=\"" url "\"></script>\n")) (append rto-js extra-js) ""))
        org-publish-project-alist (cons
                                   `("wiki"
                                     ;;-------------------------------
                                     ;; Standard org publish options
                                     ;;-------------------------------
                                     :base-directory "~/org/"
                                     :base-extension "org"
                                     :publishing-directory "~/wiki/"
                                     :html-head ,ox-yaow-html-head
                                     :html-preamble t
                                     :recursive t
                                     :publishing-function ox-yaow-publish-to-html
                                     ;; Auto generates indexing files
                                     :preparation-function ox-yaow-preparation-fn
                                     ;; Removes auto-generated files
                                     :completion-function ox-yaow-completion-fn
                                     ;;------------------------------
                                     ;; Options specific to ox-yaow
                                     ;;------------------------------
				     ;; Page to be regarded as the "homepage"
				     :ox-yaow-wiki-home-file "~/org/wiki.org"
                                     ;; Don't generate links for these files
                                     :ox-yaow-file-blacklist ("~/org/maths/answers.org")
                                     ;; Max depths of sub links on indexing files
                                     :ox-yaow-depth 2)
                                   org-publish-project-alist))

The project can then be published via `org-export-dispatch'
