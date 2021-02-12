Description:

Grails.el is a minor mode that allows an easy
navigation of Gails projects.  It allows jump to a model, to a view,
to a controller or to a service.

Features:
 - Jump to the related Domain (from the current buffer)
 - Jump to the related Controller (from the current buffer)
 - Jump to the related Service (from the current buffer)
 - Jump to the related view(s) (from the current buffer)
 - Open the Bootstrap file
 - Open the UrlMappings file
 - Find file prompt for domain classes
 - Find file prompt for controller classes
 - Find file prompt for service classes
 - Find file prompt for views

For the complete documentation, see the project page at

https://github.com/lifeisfoo/emacs-grails

Installation:

Copy this file to to some location in your Emacs load path.  Then add
"(require 'grails)" to your Emacs initialization (.emacs,
init.el, or something).

Example config:

  (require 'grails)

To auto enable grails minor mode, create a .dir-locals.el file
in the root of the grails project with this configuration:

   ((nil . ((grails . 1))))

In this way, the grails minor mode will be always active inside your project tree.
The first time that this code is executed, Emacs will show a security
prompt: answer "!" to mark code secure and save your decision (a configuration
line is automatically added to your .emacs file).

Otherwise, if you want to have grails mode auto enabled only
when using certain major modes, place this inside your `.dir-locals.el`:

    ((groovy-mode (grails . 1))
    (html-mode (grails . 1))
    (java-mode (grails . 1)))

In this way, the grails mode will be auto enabled when any of
these modes are loaded (only in this directory tree - the project tree)
(you can attach it to other modes if you want).
