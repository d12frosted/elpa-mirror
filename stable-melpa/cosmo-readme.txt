Cosmological calculator for Lambda-CDM models.

The package provides interactive commands for handy computation of
cosmological distance measures.  For instance, to display a summary
table, type:

  M-x cosmo-calculator

All cosmological quantities are computed at a given value of the
gravitational `redshift' of photons frequency due to the expansion
of the Universe.

To set the cosmological parameters, type:

  M-x cosmo-set-params

The Lambda-CDM model is characterized by the following parameters:

- `H0': Hubble parameter (expansion rate) today (e.g., 70 km/s/Mpc).
- `omatter': Matter density parameter today (e.g., 0.3).
- `olambda': Cosmological constant density parameter (e.g., 0.7).
- `orel': Relativistic species density parameter today (e.g., 0.0001).

The curvature density parameter today is derived from the others
above according to Friedmann's equation.

Definitions follow Hogg (1999)
<https://arxiv.org/abs/astro-ph/9905116>.

Names with "--" are for functions and variables that are meant to
be for internal use only.
