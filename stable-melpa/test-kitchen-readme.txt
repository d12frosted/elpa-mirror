This minor mode also assumes you have [[https://downloads.chef.io/chef-dk/][ChefDK]] installed.

I'd like to thank [[https://twitter.com/camdez][Cameron Desautels]] for the jump start on this project. /me tips my hat to you sir.

I'd also like to thank [[http://twitter.com/ionrock][Eric Larson]] for pushing me to keep this alive.

This minor mode allows you to run test-kitchen in a separate buffer

 * Run test-kitchen destroy in another buffer
 * Run test-kitchen list in another buffer
 * Run test-kitchen test in another buffer
 * Run test-kitchen verify in another buffer

You'll probably want to define some key bindings to run these.

  (global-set-key (kbd "C-c C-d") 'test-kitchen-destroy)
  (global-set-key (kbd "C-c C-t") 'test-kitchen-test)
  (global-set-key (kbd "C-c l") 'test-kitchen-list)
  (global-set-key (kbd "C-c C-kv") 'test-kitchen-verify)
  (global-set-key (kbd "C-c C-kc") 'test-kitchen-converge)

TODO:

1) Have a way to select the only one suite to run
2) Have a way to select only one os to run
