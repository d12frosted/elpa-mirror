
A minor mode that adds some useful commands for navigating around
a grails project

In the root of the grails project (where the grails-app directory is)
add this to your .dir-locals.el file (v23+)
(groovy-mode . ((grails-mode . 1)))
(java-mode . ((grails-mode . 1)))
(html-mode . ((grails-mode . 1)))

This will turn on grails minor mode whenever a groovy, java or gsp file is opened,
this presumes you have gsp files et to use html-mode adjust to whatever mode gsp files use

or just add this to have grails mode with any file in that directory structure

((nil . ((grails-mode . 1))))

The main addition is a view in anything that shows all the grails project files
