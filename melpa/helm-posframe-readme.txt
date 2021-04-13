* helm-posframe README                                :README:
** Need new maintainer !!!
I do not use helm and hard to maintain this package, for I
do not know the details of helm. need a new maintainer !!!

** What is helm-posframe
helm-posframe is a helm extension, which let helm use posframe
to show its candidate menu.

NOTE: helm-posframe requires Emacs 26

** How to enable and disable helm-posframe
   #+BEGIN_EXAMPLE
   (helm-posframe-enable)
   (helm-posframe-disable)
   #+END_EXAMPLE

** Tips

*** How to show fringe to helm-posframe
;; #+BEGIN_EXAMPLE
(setq helm-posframe-parameters
      '((left-fringe . 10)
        (right-fringe . 10)))
;; #+END_EXAMPLE

By the way, User can set *any* parameters of helm-posframe with
the help of `helm-posframe-parameters'.
