This package adds YAML syntax checker yamllint.
Make sure 'yamllint' binary is on your path.
Installation instructions https://github.com/adrienverge/yamllint#installation

flymake-yamllint expect `yamllint' to produce stdout like:
test.yml:2:4: [error] wrong indentation: expected 2 but found 3 (indentation)

Example above should be matched by regex used in code like this:
0: stdin:79:81: [warning] line too long (117 > 80 characters) (line-length)
1: 79
2: 81
3: [warning]
4: line too long (117 > 80 characters) (line-length)
