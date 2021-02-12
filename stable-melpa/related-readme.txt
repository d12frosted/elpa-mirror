Related global minor mode helps you to navigate across similarly
named buffers.

You might want to add the following code to your .emacs :

 (require 'related)
 (related-mode)

Then use "C-x <up>" to switch to next related buffer, and "C-x
<down>" to come back.  If you are not happy with those key
bindings, you might want to try something like this :

 (global-set-key (kbd "<your key seq>") 'related-switch-forward)
 (global-set-key (kbd "<your key seq>") 'related-switch-backward)

You might also want to try related-switch-buffer, which prompts you
for the next related buffer to go to, and integrates nicely with
helm or ido (no default key binding here).

Related derives from each buffer a hopefully meaningful "base name"
and buffers with same "base name" form a group.  Related helps you
to navigate those groups.

For example, buffers visiting the following files :

 /path/to/include/foo.h
 /path/to/source/foo.c
 /path/to/doc/foo.org

Would be grouped together (their names reduce to "foo"). Supposing
you have dozens of opened buffers, and are working in "foo.h",
Related helps you to cycle across "foo" buffers :

Cycle "forward" with "C-x <up>" :

 foo.h -> foo.c -> foo.org
    ^                 |
    +-----------------+

And cycle "backward" with ""C-x <down>" :

 foo.h <- foo.c <- foo.org
    |                 ^
    +-----------------+

When deriving a "base name" from a buffer path, the following rules
are applied :

 - Remove directories
 - Remove extensions
 - Remove non-alpha characters
 - Convert remaining characters to lower case

Thus "/another/path/to/FOO-123.bar.baz" would also reduce to "foo".
