This package updates the GPG keys used by the ELPA package manager
(a.k.a `package.el') to verify authenticity of packages downloaded
from the GNU ELPA archive.

Those keys have a limited validity in time (for example, the first key was
valid until Sep 2019 only), so you need to install and keep this package up
to date to make sure signature verification does not spuriously fail when
installing packages.

If your keys are already too old, causing signature verification errors when
installing packages, then in order to install this package you have to
temporarily disable signature verification (see variable
  `package-check-signature') :-(