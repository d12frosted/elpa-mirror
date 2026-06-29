Paced (Predictive Abbreviation Completion and Expansion using Dictionaries)
scans a group of files (determined by "population commands") to construct a
usage table (dictionary).  Words (or symbols) are sorted by their usage, and
may be later presented to the user for completion.  A dictionary can then be
saved to a file, to be loaded later.

Population commands determine how a dictionary should be filled with words or
symbols.  A dictionary may have multiple population commands, and population
may be performed asynchronously.  Once population is finished, the contents
are sorted, with more commonly used words at the front.  Dictionaries may be
edited through EIEIO's customize-object interface.

Completion is done through `completion-at-point'.  The dictionary to use for
completion can be customized.