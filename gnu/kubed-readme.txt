This library defines commands for interacting with Kubernetes
resources, such as Kubernetes pods, services, deployments, and more.

Use `kubed-display-pod' to display a Kubernetes pod,
`kubed-edit-pod' to edit it, `kubed-delete-pods' to delete it, and
`kubed-list-pods' to see a menu of all pods.  You can create new pods
from YAML or JSON files with `kubed-create-pod'.

Similar commands are defined for other types of resources as well.

This library interacts with Kubernetes via `kubectl', and uses the
current `kubectl' context and namespace by default.  To change your
current context or namespace, use commands `kubed-use-context' and
`kubed-set-namespace' respectively; you can also interact with
resources in other namespaces without changing your default
namespace, for example you can call `kubed-list-pods' with a prefix
argument to choose another namespace for listing pods.  The prefix
keymap `kubed-prefix-map' gives you quick access to these and other
useful commands, you may want to bind it globally to a convenient key
with `keymap-global-set':

  (keymap-global-set "C-c k" 'kubed-prefix-map)

In addition, the command `kubed-transient' lets you explore various
Kubernetes operations with a transient menu interface.  You may also
want to enable `kubed-menu-bar-mode', which add a "Kubernetes" menu
to your menu-bar with many useful entries.

If you want to work with more or different types of Kubernetes
resources, use the macro `kubed-define-resource'.  This macro defines
some common functions and commands that'll get you started with ease.

For more information, see the Kubed manual at (info "(kubed)Top"), or
online at https://eshelyaron.com/kubed.html