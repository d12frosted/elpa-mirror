An exceedingly basic jsp-mode, inheriting from html-mode.

This crappy mode for jsp makes sure indentation sorta works.

## Indentation

It gives you proper indentation when you need to comment out
whitespace with jsp-comments:

    <div class="no-whitespace"><%--
      --%><div class="please"><%--
      --%></div><%--
    --%></div><%--

or maybe not even properly, just nicer than html-mode.

It also indents JavaScript inside `<script>`-tags.

## Highlighting

In addition to that it highlights these `${}` in a horrible yellow
color.
