This package provides integration between ekg and denote.

During export, for each ekg note, a denote file is created.  Denote
does not allow creation time for two notes within a second whereas
ekg has no such restriction, so it is necessary to ensure that each
ekg note has a unique creation time for export.  Additionally,
denote embeds the title and tags in the filename, which is limited
based on the underlying operating system.  The titles and tags of
ekg notes are trimmed to a configurable length before export.  Ekg
notes can have creation time within a second when trying to bulk
import org-roam files to ekg.
