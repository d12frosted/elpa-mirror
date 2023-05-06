This package builds atop standard Emacs project.el by providing various
utility commands and support for individual project types.

Different projects are interacted with in different ways but many have
common tasks such as configuring, building or testing. Projection aims
to be a generic wrapper around these project types such that you can
configure (or use the builtin) commands for various project types and
invoke them seamlessly through a common command like
`projection-configure-project'.

Beyond just project specific commands projection also maintains utility
commands or integrations between projection and other packages such as
`projection-multi' or `projection-ibuffer'.

Projection takes heavy inspiration from `projectile'.
