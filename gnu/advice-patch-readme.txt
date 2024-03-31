This package builds on `advice-add' but instead of letting you add code
before/after/around the body of the advised function, it lets you directly
patch the inside of that function.

This is inspired from [el-patch](https://github.com/raxod502/el-patch),
but stripped down to its barest essentials.  `el-patch' provides many more
features, especially to be notified when the advised function is modified
and to help you update your patches accordingly.

Beware: this can eat your lunch and can misbehave unexpectedly in many
legitimate cases.

TODO:

- Lots of cases to fix and features to add.  See FIXMEs in the code.