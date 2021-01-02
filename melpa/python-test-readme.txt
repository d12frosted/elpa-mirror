
`python-test.el' allows the execution of python tests from Emacs.

Setup:

Python objects:

| objects      | function                 |
| -------------|--------------------------|
| class        | `python-test-class'      |
| method       | `python-test-method'     |
| function     | `python-test-function'   |
| file         | `python-test-file'       |
| project      | `python-test-project'    |

Test frameworks:

+ [nose][]
+ [pytest][]
+ [unittest][]: Needs the command-line interface available since python >=2.7

[nose]: https://nose.readthedocs.org/
[pytest]: https://pytest.org/
[unittest]: https://docs.python.org/library/unittest.html "Unit testing framework"
