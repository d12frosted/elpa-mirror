This minor mode provides some enhancements to java-mode in order to use maven
test tasks with little effort. It's largely based on the philosophy of
`rspec-mode' by Peter Williams. Namely, it provides the following
capabilities:

 * toggle back and forth between a test and it's class (bound to `\C-c ,t`)

 * verify the test class associated with the current buffer (bound to `\C-c ,v`)

 * verify the test defined in the current buffer if it is a test file (bound
   to `\C-c ,v`)

 * verify the test method defined at the point of the current buffer (bound
   to `\C-c ,s`)

 * re-run the last verification process (bound to `\C-c ,r`)

 * run tests for entire project (bound to `\C-c ,a`)

Check the full list of available keybindings at `maven-test-mode-map'

maven-test-mode defines a derived minor mode `maven-test-compilation' which
allows one to jump from compilation errors to text files.
