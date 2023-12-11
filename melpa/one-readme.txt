
You can find the documentation at https://one.tonyaldon.com.

In `one.el', the following org document defines a website with 3 pages
that we build by calling `one-build' command while we are visiting it:

---------------------------------
* My website
:PROPERTIES:
:ONE: one-default-home
:CUSTOM_ID: /
:END:

Welcome to my website!

* Blog post 1
:PROPERTIES:
:ONE: one-default
:CUSTOM_ID: /blog/page-1/
:END:

My first blog post!

* Blog post 2
:PROPERTIES:
:ONE: one-default
:CUSTOM_ID: /blog/page-2/
:END:

My second blog post!
---------------------------------

Note that if we want to use the default css style sheet we can add it
by calling `one-default-add-css-file' before building the website.

The path `/' in the first `CUSTOM_ID' org property tells `one.el' that the
page "My website" is the home page.  That page is rendered using
`one-default-home' render function, value of `ONE' org property of the
same headline.

The path `/blog/page-1/' in the second `CUSTOM_ID' org property tells
`one.el' that we want to render "Blog post 1" page in such a way
that when we serve our website locally at `http://localhost:3000' for
instance, that page is served at `http://localhost:3000/blog/page-1/'.
How that page is rendered is determined by the value of `ONE' org
property of the same headline which is `one-default', a render
function.

The same goes for the last page "Blog post 2".

As you might have noticed, a `one.el' website is an org file where the
pages are the headlines of level 1 with the org properties `ONE' and
`CUSTOM_ID' set.  Nothing more!

`ONE' is the only org property added by `one.el'.  Its value, an Emacs Lisp
function which returns an HTML string, for a given page determines how
`one.el' renders that page.

Paths of pages are set using `CUSTOM_ID' org property.
