The interactive functions exported by this extension follow a common
protocol: if a region is active, then modify the region; otherwise modify
the entire buffer. If a prefix argument is provided, they read in a buffer
to modify the entirety of. A given region will be expanded to whitespace
boundaries (so if region is around the l characters in he|ll|o, the entirety
of |hello| will be selected).

Requires a "java" binary on the PATH. Downloads a mildly large jar file on
first use (~20.7M), which causes a large pause on the first usage, but none
afterwards. You can customize `speech-tagger-jar-path' to determine where it
looks for the presence of the jar. You can download the jar and hash manually
from `https://cosmicexplorer.github.io/speech-tagger/speech-tagger.jar' and
`https://cosmicexplorer.github.io/speech-tagger/speech-tagger.md5sum'.
