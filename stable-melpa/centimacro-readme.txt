
Main function is `centi-assign'.  It's very similar to <f3>, except
`centi-assign' prompts you for a key combination to use, while for
<f3> this key combination is always <f4>.

With `centi-assign' you can have as many macros as you wish, bound to
whatever global keys you wish.

Here's an example, assuming (global-set-key (kbd "<f5>") 'centi-assign)
    <f5><f6>foo<f6>                 ;; Now <f6> inserts "foo".
    <f5><f7><f6>bar<f7>             ;; Now <f7> inserts "foobar".
    <f5><f8><f6>-<f7>-<f6><f8>      ;; Now <f8> inserts "foo-foobar-foo".
    <f5><f6>omg<f6>                 ;; Now <f6> inserts "omg",
                                    ;;     <f7> - "omgbar",
                                    ;;     <f8> - "omgbar-omg-omg".


And here's the result of `centi-summary':
    [f8]: [f6 f7 f6] (was bookmark-bmenu-list)
    [f7]: [f6 98 97 114] (was winner-undo)
    [f6]: foo (was next-error)

`centi-assign' will work with any global binding, i.e. you could even
re-bind "a" to insert "b" if you wanted.

Calling `centi-restore-all' will restore the previous global bindings.
