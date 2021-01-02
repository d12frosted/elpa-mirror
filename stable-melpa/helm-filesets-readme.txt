
Given an emacs fileset called e.g. "Public HTML", this call will
define a variable representing a helm source from that fileset:

(defvar my/helm-source-public-html (helm-make-source-filesets "Public HTML"))

Then my/helm-source-public-html can be added to helm-for-files-preferred-list, for example, to provide candidate completion with the helm-for-files
function.
