
`kubernetes-tramp.el' offers a TRAMP method for Docker containers deployed in a Kubernetes cluster.

> **NOTE**: `kubernetes-tramp.el' relies on the `kubectl exec` command. Tested
> with version 1.7.3


This project is just a minor adaptation of [*docker-tramp.el*](https://github.com/emacs-pe/docker-tramp.el)
to allow connections through kubernetes client.

All the merits should go to [*Mario Rodas*](marsam@users.noreply.github.com) while the errors are just mine.

## Usage

Offers the TRAMP method `kubectl` to access running containers

    C-x C-f /kubectl:container:/path/to/file

    where
      container      is the name of the container

## Caveats

At the moment this tool takes for granted that the `kubectl` client is already correctly configured.

It's not possible to pass the configuration file (or others options) to the client as a command line parameter.
