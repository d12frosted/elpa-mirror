* company-posframe README                                :README:
** What is company-posframe
company-posframe is a company extension, which let company use
child frame as its candidate menu.

It has the following feature:
1. It is fast enough for daily use.
2. It works well with CJK language.

[[./snapshots/company-posframe.png]]

** How to use company-posframe

#+BEGIN_EXAMPLE
(require 'company-posframe)
(company-posframe-mode 1)
#+END_EXAMPLE

** Tips
*** Work better with desktop.el
The below code let desktop.el not record the company-posframe-mode
#+BEGIN_EXAMPLE
(require 'desktop) ;this line is needed.
(push '(company-posframe-mode . nil)
      desktop-minor-mode-table)
#+END_EXAMPLE

** Note
company-posframe.el is derived from Clément Pit-Claudel's
company-tooltip.el, which can be found at:

[[https://github.com/company-mode/company-mode/issues/745#issuecomment-357138511]]

Some quickhelp functions is come from:

[[https://github.com/company-mode/company-quickhelp][company-quickhelp]]
