Setup:

1. Download yasnippet from https://github.com/capitaomorte/yasnippet
   and set it up.

2. Put this file into your elisp folder.

3. In your .emacs file:
    (require 'auto-yasnippet)
    (global-set-key (kbd "H-w") 'aya-create)
    (global-set-key (kbd "H-y") 'aya-expand)

Usage:
e.g. in JavaScript write:

field~1 = document.getElementById("field~1");

Since this just one line,
just call `aya-create' (from anywhere on this line).
The ~ chars disappear, yielding valid code.
`aya-current' becomes:
"field$1 = document.getElementById(\"field$1\");"
Now by calling `aya-expand' multiple times, you get:

field1 = document.getElementById("field1");
field2 = document.getElementById("field2");
field3 = document.getElementById("field3");
fieldFinal = document.getElementById("fieldFinal");

e.g. in Java write:

class Light~On implements Runnable {
  public Light~On() {}
  public void run() {
    System.out.println("Turning ~on lights");
    light = ~true;
  }
}

This differs from the code that you wanted to write only by 4 ~ chars.
Since it's more than one line, select the region and call `aya-create'.
Again, the ~ chars disappear, yielding valid code.
`aya-current' becomes:
"class Light$1 implements Runnable {
  public Light$1() {}
  public void run() {
    System.out.println(\"Turning $2 lights\");
    light = $3;
  }
}"

Now by calling `aya-expand', you can quickly fill in:
class LightOff implements Runnable {
  public LightOff() {}
  public void run() {
    System.out.println("Turning off lights");
    light = false;
  }
}

e.g. in C++ write:
const Point<3> curl(grad[~2][~1] - grad[~1][~2],

select the region between the paren and the comma and call `aya-create'.

You can easily obtain the final code:

const Point<3> curl(grad[2][1] - grad[1][2],
                    grad[0][2] - grad[2][0],
                    grad[1][0] - grad[0][1]);

Note how annoying it would be to triple check that the indices match.
Now you just have to check for one line.
