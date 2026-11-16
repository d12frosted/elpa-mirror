Admin Delux lets you run workflows in Clojure interactively from the comfort of
your Emacs.

Request user-input for any admin function and execute it.

`admin-delux-run` starts a loop collecting input from the user, accumulating a
history. On every iteration it calls your step-fn for the next interaction,
finally calling an `exec-fn` with the collected inputs.

Run interactive, guided, admin routines with a single pure and data-driven
function 😌

Usage:
Add `((clojure-mode . ((admin-delux-step-fn . "your.fully.qualified/step-fn"))))`
to your project's .dir-locals.el-file.

Implement `your.fully.qualified/step-fn` somewhere in your project.

The step-fn should return any of the following maps:
  {:type :select  :prompt "Action: "   :options ["add" "rename"] :require-match true}
  {:type :input   :prompt "New name: " :initial "foo"}
  {:type :message :message "Creating..."}
  {:type :error   :message "Name already taken"}
  {:type :submit  :exec-fn "some.namespace/function"}
