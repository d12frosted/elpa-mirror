
Generate static websites off of Org Mode sources.

The API is modeled as a simplified version of a generic HTTP
framework.  Simplified in the meaning that it doesn't give access
to the request and response objects, but allow interacting with the
input throughout a few different points of a defined pipeline.

Aiming to find balance between flexibility and simplicity, the
general principle of this software is to be designed as a set of
modular components with default configuration that is ready to go
for valuable use cases.

1. Use-case: transform a list of Org-Mode files in HTML:

   (weblorg-route
    :input-pattern "*.org"
    :template "post.html"
    :url "/{{ slug }}.html")
   (weblorg-export)

2. Use-case: Link documents from different routes

   a. publish.el looks like this:

      (weblorg-route
       :name "docs"
       :input-pattern "*.org"
       :input-exclude "index.org$"
       :template "post.html"
       :url "/{{ slug }}.html")
      (weblorg-route
       :name "index"
       :input-pattern "index.org"
       :template "index.html"
       :url "/index.html")
      (weblorg-export)

   b. a-post.org looks something like this:

      #+TITLE: A Post
      #+DATE: <2020-08-30>
      * Intro
        If you liked this, make sure you also check out
        [[url_for:docs,slug=another-post][Another Post]].

   c. post.html could looks something like this

      <h1>{{ post.title }}</h1>
      {{ post.html|safe }}
      <hr>
      <a href="{{ url_for("index") }}">Home</a>

   Behind the scenes, there's a global variable `weblorg--sites' that
   contains a hash-table with all the weblorg-sites, indexed by the
   `:base-url' parameter.  A default weblorg site instance is created
   if `weblorg-route' doesn't receive an explicit `:site' parameter.
