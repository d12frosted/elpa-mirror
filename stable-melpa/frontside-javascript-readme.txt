Modern JavaScript development can be complex.  With the rise of
transpilers such as Babel and TypeScript, the needs for editing,
testing, and building JavaScript are more difficult than ever.
While editors like VSCode come out of the box being robust tools
for working with JavaScript.  Emacs on the other hand is just flat
out broken by default.  The builitin js2-mode cannot even handle
modern syntax, and as a result it sprays errors and red underlines
all over the place.  To make matters worse, modern JS syntax is
extensible with tools like babel, and so it will never be able to
catch up with a one-size-fits-all solution.  Throw on top of
_that_, the fact that in the course of your average JS project,
you're likely to encounter not just `.js' files, but also `.jsx',
`.ts', and `.tsx' as well.  You don't want to have to wonder why
your editor is broken or stop to google for 2 hours just in order
to work with a JS project you just cloned from github.  What you
need is a setup that can handle whatever the JS ecosystem throws
at you.

Enter `frontside-javascript'.  The goal is simple: any JavaScript
project you care to download you should just work straight away, no
matter if it contains TypeScript, React, Node, ES6, Deno, or
whatever; now and going forward.  By work, it means it should:

  1. Be able to understand the syntax as defined by the project
     itself, not a global concept of JavaScript syntax.
  2. Highlight errors based ond the configured style of the
     project itself.
  3. Have completions, documentations, and refactoring at the
     current point based on the sources of the current project.
  4. find and navigate to symbolic references

Usage:

(frontside-javascript)
