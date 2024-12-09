This mode provides Emacs functionality for running tests using GoTest
and Treesitter.

It supports running test functions and subtests in .go files with Treesitter
support.

Bug:
When you have different structure inside a subtest that has a Name: it would
pick up the wrong one.You just need to place yourself in the right struct
where the name is.
