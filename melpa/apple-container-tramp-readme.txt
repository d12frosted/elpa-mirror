
`apple-container-tramp.el' offers a TRAMP method for Apple containers.
It relies on the `container exec` command, and is tested with apple
container version 0.10.0 but should work with versions >0.10.0.

## Usage

Offers the TRAMP method `container` to access running containers

    C-x C-f /container:user@container-id:/path/to/file

    where
      user           is the user that you want to use inside the container (optional)
      container-id   is the id or name of the container

### Multi-hop examples

If you container is hosted on `vm.example.net`:

    /ssh:vm-user@vm.example.net|container:user@container:/path/to/file

If you need to run the `container` command as, say, the `root` user:

    /sudo:root@localhost|container:user@container:/path/to/file
