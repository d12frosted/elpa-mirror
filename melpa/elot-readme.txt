This package is for authoring OWL ontologies using org-mode.

To start an ontology from scratch using ELOT, open an Org file and
use predefined "tempo" templates.

 - insert `<odh' and hit <Tab> to add a header for the document
 - insert `<ods' and hit <Tab> to insert headers for the ontology,
   classes, properties, and individuals.

The ELOT easymenu ("ELOT" in the menu bar when `elot-mode' is
active) gives access to templates and export commands.

Optional external packages.  ELOT loads and `elot-mode' activates
cleanly without any of these; the features that depend on them
degrade to "not available" rather than erroring at load time:

 - `sparql-mode'  -- query-block fontification
 - `ob-sparql'    -- execution of `#+begin_src sparql' blocks
                     (the ELOT prefix-injection / ROBOT advice is
                     installed only when this is present)
 - `ob-plantuml'  -- PlantUML rendering used by `rdfpuml-block'
 - `htmlize'      -- source-block fontification on HTML export
 - `omn-mode'     -- major mode for tangled `.omn' files

Please consult the package Github site for more information:
       <https://github.com/johanwk/elot>
