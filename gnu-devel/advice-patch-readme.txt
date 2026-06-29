This package builds on `advice-add' but instead of letting you add code
before/after/around the body of the advised function, it lets you directly
patch the inside of that function.

This is inspired from [el-patch](https://github.com/raxod502/el-patch),
but stripped down to its barest essentials.  `el-patch' provides many more
features, especially to be notified when the advised function is modified
and to help you update your patches accordingly.

Beware: this can eat your lunch and can misbehave unexpectedly in many
legitimate cases.

Use it is as follows:

    (advice-patch 'foo (my new code)
                  [(some old code)
                   (some (other version) (of the old) code))])

This will fetch the source code of `foo', look for an occurrence
of one of the old code chunks listed, replace it with
`(my new code)', compile the result, and finally ask `advice-add' to use it
to override the original definition.

TODO:

- Lots of cases to fix and features to add.  See FIXMEs in the code.