This package provides tools to query Repology API
(<https://repology.org/api>), process results, and display them.

The results of a query revolve around three types of objects:
projects, packages and problems.  Using this library, you can find
projects matching certain criteria, packages in a given project,
and possible problems in some repository.  See `repology-search-projects',
`repology-lookup-project', and `repology-report-problems'.
Projects-related requests are limited to `repology-projects-limit'.
All requests are cached during `repology-cache-duration' seconds.

By default, only projects recognized as free are included in the search
results.  You can control this behavior with the variable
`repology-free-projects-only'.  The function `repology-check-freedom'
is responsible for guessing if a project, or a package, is free.

You can then access data from those various objects using dedicated
accessors.  See, for example, `repology-project-name',
`repology-project-packages', `repology-package-field', or
`repology-problem-field'.

You can also decide to display (a subset of) results in a tabulated
list.  See `repology-display-package', `repology-display-packages',
`repology-display-projects' and `repology-display-problems'.  You
can control various aspects of the display, like the faces used
or the columns shown (see `repology-display-packages-columns',
`repology-display-projects-columns' and `repology-display-problems-columns').
When projects or packages are displayed, pressing <RET> gives you more
information about the item at point, whereas pressing <F> reports their
freedom status.

For example, the following expression displays all outdated projects
named after "emacs" and containing a package in GNU Guix repository
that I do not ignore:

   (repology-display-projects
    (seq-filter (lambda (project)
                  (not (member (repology-project-name project)
                               my-ignored-projects)))
                (repology-search-projects
                 :search "emacs" :inrepo "gnuguix" :outdated "on")))

Eventually, this library provides an interactive function with
a spartan interface wrapping this up: `repology'.  Since it builds
and displays incrementally search filters, you may use it as
a template to create your own queries.

Known issues:

- The library has no notion of distribution "family", since this
  doesn't appear in the API.  As a consequence, display functions
  cannot compute the "spread" of a project.  It falls back to the
  number of packages in the project instead.
- It does not handle "maintainers" queries.
- It is synchronous.  Don't go wild with `repology-projects-limit'!