A way to insert text snippets from an org-mode file.  The org-mode file in
question is defined in `yankpad-file' and is set to "yankpad.org" in your
`org-directory' by default.  In this file, each heading specifies a snippet
category and each subheading of that category defines a snippet.  This way
you can have different yankpads for different occasions.

You can open your `yankpad-file' by using `yankpad-edit' (or just open it in
any other way).  Another way to add new snippets is by using
`yankpad-capture-snippet', which will add a snippet to the current
`yankpad-category'.

If you have yasnippet installed, yankpad will try to use it when pasting
snippets.  This means that you can use the features that yasnippet provides
(tab stops, elisp, etc).  You can use yankpad without yasnippet, and then the
snippet will simply be inserted as is.

You can also add keybindings to snippets, by setting an `org-mode' tag on the
snippet.  The last tag will be interpreted as a keybinding, and the snippet
can be run by using `yankpad-map' followed by the key.  `yankpad-map' is not
bound to any key by default.

Another functionality is that snippets can include function calls, instead of
text.  In order to do this, the snippet heading should have a tag named
"func".  The snippet name could either be the name of the elisp function that
should be executed (will be called without arguments), or the content of the
snippet could be an `org-mode' src-block, which will then be executed when
you use the snippet.

If you name a category to a major-mode name, that category will be switched
to when you change major-mode.  If you have projectile installed, you can also
name a categories to the same name as your projecile projects, and they will
be switched to when using `projectile-find-file'.  These snippets will be
appended to your active snippets if you change category.

To insert a snippet from the yankpad, use `yankpad-insert' or
`yankpad-expand'.  `yankpad-expand' will look for a keyword at point, and
expand a snippet with a name starting with that word, followed by
`yankpad-expand-separator' (a colon by default).  If you need to change the
category, use `yankpad-set-category'.  If you want to append snippets from
another category (basically having several categories active at the same
time), use `yankpad-append-category'.  If you have company-mode enabled,
you can also use `company-yankpad`.

A quick way to add short snippets with a keyword is to add a descriptive list
to the category in your `yankpad-file'.  The key of each item in the list will be
the keyword, and the description will be the snippet.  You can turn off this
behaviour by setting `yankpad-descriptive-list-treatment' to nil, or change
descriptive lists to use `abbrev-mode' by setting the variable to 'abbrev
instead.

For further customization, please see the Github page: https://github.com/Kungsgeten/yankpad

Here's an example of what yankpad.org could look like:

; Yankpad example:

* Category 1
** Snippet 1

   This is a snippet.

** snip2: Snippet 2

   This is another snippet.  This snippet can be expanded by first typing "snip2" and
   then executing the `yankpad-expand' command.
   \* Org-mode doesn't like lines beginning with *
   Typing \* at the beginning of a line will be replaced with *

   If yanking a snippet into org-mode, this will respect the
   current tree level by default.  Set the variable
   `yankpad-respect-current-org-level' to nil in order to change that.

* Category 2

  Descriptive lists will be treated as snippets.  You can set them to be
  treated as `abbrev-mode' abbrevs instead, by setting
  `yankpad-descriptive-list-treatment' to abbrev.  If a heading could be considered
  to be a snippet, add the `snippetlist' tag to ignore the snippet and scan
  it for descriptive lists instead.

  - name :: Erik Sjöstrand
  - key :: Typing "key" followed by `yankpad-expand' will insert this snippet.

** Snippet 1

   This is yet another snippet, in a different category.
** Snippet 2        :s:

   This snippet will be bound to "s" when using `yankpad-map'.  Let's say you
   bind `yankpad-map' to f7, you can now press "f7 s" to insert this snippet.

** magit-status          :func:
** Run magit-status      :func:m:
   #+BEGIN_SRC emacs-lisp
   (magit-status)
   #+END_SRC

* org-mode
** Snippet 1
   This category will be switched to automatically when visiting an org-mode buffer.

* Category 3
  :PROPERTIES:
  :INCLUDE:  Category 1|Category 2
  :END:
** A snippet among many!
   This category will include snippets from Category 1 and Category 2.
   This is done by setting the INCLUDE property of the category.

* Global category       :global:
** Always available
   Snippets in a category with the :global: tag are always available for expansion.
* Default                                           :global:
** Fallback for major-mode categories

If you open a file, but have no category named after its major-mode, a
category named "Default" will be used instead (if you have it defined in your
                                                  Yankpad). It is probably a good idea to make this category global. You can
change the name of the default category by setting the variable
yankpad-default-category.
