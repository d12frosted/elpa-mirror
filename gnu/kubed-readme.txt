This library defines commands for interacting with Kubernetes
resources, such as Kuberenetes pods, services, deployments, and more.

Use `kubed-display-pod' to display a Kuberenetes pod,
`kubed-edit-pod' to edit it, `kubed-delete-pods' to delete it, and
`kubed-list-pods' to see a menu of all pods.  You can create new pods
from YAML or JSON files with `kubed-create-pod'.

Similar commands are defined for other types of resources as well.

This library interacts with Kuberenetes via `kubectl', and uses the
current `kubectl' context and namespace.  To change your current
Kuberenetes context or namespace, use `kubed-use-context' and
`kubed-set-namespace'; all resource lists are updated automatically
after you do so.  The prefix keymap `kubed-prefix-map' gives you
quick access to these and other useful commands, you may want to bind
it globally to a convenient key with `keymap-global-set':

  (keymap-global-set "C-c k" 'kubed-prefix-map)

If you want to work with more or different types of Kubernetes
resources, use the macro `kubed-define-resource'.  This macro defines
some common functions and commands that'll get you started with ease.

You may also want to try out the companion library `kubed-transient',
which provides transient menus for some of the commands defined here.