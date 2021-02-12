An intuitive editor mode to make paren management fun and easy without sacrificing power.

How it works:

Parinfer users the state of the buffer combined with the current mode (paren, indent, or smart)
to either balance an s-expression's indentation, paren, or to do both.

Let's go over some light examples to get a sense of how parinfer works. I am going to use `|` to
indicate the cursor and `_` to indicate the a space that's been added either by the user or
parinfer.

Paren Mode gives you full control of parens, while Parinfer corrects indentation.

For example, if we start off with the cursor before `(foo`

```
|(foo
   bar)
```

and the user inserts a space
```
_|(foo
   bar)
```

then parinfer will maintain, infer, that a space is needed in front of `bar)` to maintain
indentation

```
 |(foo
   _bar)
```

Indent Mode gives you full control of indentation, while Parinfer corrects or inserts
close-parens where appropriate.

Now the cursor is before `4`

```
(foo [1 2 3]
    |4 5 6)
```

and the user inserts a space
```
(foo [1 2 3]
    _|4 5 6)
```

then parinfer will adjust the `]` and move it down to the follow line to enclose the 4 5 6

```
(foo [1 2 3
     |4 5 6])
```

Smart Mode is like Indent Mode, but it tries to preserve the structure too. This roughly
translates to it treating everything before the cursor as indent-mode and every after the cursor
as paren-mode.

The cursor is before `(+`

```
(let [x (fn [])]
|(+ 1
    2)
 x)
```

and the user add several spaces to the sexp
```
(let [x (fn [])]
 ________|(+ 1
    2)
x)
```

Smart-Mode will move a ) and a ] to enclose the addition function call and move the 2 to maintain
structure

```
(let [x (fn []
        |(+ 1
   _________2))]
x)
```


To find out more about how parinfer works go to: https://shaunlebron.github.io/parinfer/

`parinfer-rust-mode` provides an interface between the `parinfer-rust` library
and Emacs.  As such it's primary role is to capture meta information about the
buffer and transfer it to the parinfer-rust API.

As such parinfer-rust-mode requires that your version of Emacs supports modules.
