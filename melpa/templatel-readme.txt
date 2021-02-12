
This language compiles templates into Emacs Lisp functions that can
be called with different sets of variables.  This work is inspired
by Jinja and among its main features, it supports if statements,
for loops, and a good amount of expressions that make it simpler to
manipulate data within the template.

(require 'templatel)

(templatel-render-string
 "<h1>{{ title }}</h1>
<ul>
  {% for user in users %}
    <li><a href=\"{{ user.url }}\">{{ user.name }}</a></li>
  {% endfor %}
</ul>"
 '(("title" . "A nice web page")
   ("users" . ((("url" . "http://clarete.li")
                ("name" . "link"))
               (("url" . "http://gnu.org")
                ("name" . "Gnu!!"))))))

This library also provides template in heritance and automatic HTML
entity escaping among other things.  Take a look at the
documentation website for all the features:
https://clarete.li/templatel/doc.
