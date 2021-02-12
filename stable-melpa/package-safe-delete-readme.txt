Delete package.el packages safely, without leaving unresolved dependencies.

- To delete a package:
    M-x package-safe-delete
- To delete a list of packages:
    (package-safe-delete-packages '(package1 package2 ...))
- To delete a package and all its dependencies not required by other
  installed packages:
    M-x package-safe-delete-recursively
- To delete a list of packages recursively:
    (package-safe-delete-packages-recursively '(package1 package2 ...))
- To delete all packages:
    M-x package-safe-delete-all

To prevent a package from being deleted, even by `package-safe-delete-all',
add its name to `package-safe-delete-required-packages':
    (add-to-list 'package-safe-delete-required-packages 'package1)
