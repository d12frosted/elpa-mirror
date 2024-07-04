
This package provides a tree-sitter based major mode for SDML.


        ___          _____          ___
       /  /\        /  /::\        /__/\
      /  /:/_      /  /:/\:\      |  |::\
     /  /:/ /\    /  /:/  \:\     |  |:|:\    ___     ___
    /  /:/ /::\  /__/:/ \__\:|  __|__|:|\:\  /__/\   /  /\
   /__/:/ /:/\:\ \  \:\ /  /:/ /__/::::| \:\ \  \:\ /  /:/
   \  \:\/:/~/:/  \  \:\  /:/  \  \:\~~\__\/  \  \:\  /:/
    \  \::/ /:/    \  \:\/:/    \  \:\         \  \:\/:/
     \__\/ /:/      \  \::/      \  \:\         \  \::/
       /__/:/        \__\/        \  \:\         \__\/
       \__\/          Domain       \__\/          Language
        Simple                      Modeling



Installing

`(use-package sdml-mode
   :ensure t)'


Usage

Once installed the major mode should be used for any file ending in `.sdm'
or `.sdml' with highlighting and indentation support.

Debug

`\\[tree-sitter-debug-mode]' -- open tree-sitter debug view
`\\[tree-sitter-query-builder]' -- open tree-sitter query builder

Abbreviations and Skeletons

This package creates a new `abbrev-table', named `sdml-mode-abbrev-table', which
provides a number of useful skeletons for the following.  `abbrev-mode' is enabled
by `sdml-mode' and when typing one of the abbreviations below type space to
expand.

Typing `d t SPC' will prompt for a name and expand into the SDML declaration
`datatype MyName ← opaque _' where the underscore character represents the new
cursor position.

Declarations: mo=module, dt=datatype, en=enum, ev=event, pr=property,
  st=structure, un=union

Annotation Properties: pal=skos:altLabel, pdf=skos:definition,
  ped=skos:editorialNote, ppl=skos:prefLabel, pco=rdfs:comment

Constraints: ci=informal, cf=formal, all=universal, any=existential

Datatypes: db=boolean, dd=decimal, df=double, dh=binary, di=integer,
  sd=string, du=unsigned


Interactive Commands


`sdml-mode-validate-current-buffer' (\\[sdml-mode-validate-current-buffer]) to
validate and show errors for the buffer's current module.

Adding this as a save-hook allows  validation on every save of a buffer.

`(add-hook 'after-save-hook 'sdml-validate-current-buffer)'

`sdml-mode-current-buffer-dependencies' (\\[sdml-mode-current-buffer-dependencies])
to display the dependencies of the curtent buffer's module.


Extensions

`flycheck-sdml' -- Integrate the lisp-based linter with sdml-mode.
`ob-sdml' -- Support SDML org-mode Babel blocks
`sdml-fold' -- Provide code-folding for SDML source.
`sdml-ispell' -- Provide spell checking for specific SDML Tree-Sitter nodes.
