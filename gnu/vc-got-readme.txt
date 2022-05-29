vc-got is a VC backend for the Game of Trees (got) version control
system.

Backend implementation status

Function marked with `*' are required, those with `-' are optional.

FUNCTION NAME                        STATUS

BACKEND PROPERTIES:
* revision-granularity               DONE
- update-on-retrieve-tag             XXX: what should this do?

STATE-QUERYING FUNCTIONS:
* registered                         DONE
* state                              DONE
- dir-status-files                   DONE
- dir-extra-headers                  DONE
- dir-printer                        DONE
- status-fileinfo-extra              NOT IMPLEMENTED
* working-revision                   DONE
* checkout-model                     DONE
- mode-line-string                   DONE

STATE-CHANGING FUNCTIONS:
* create-repo                        NOT IMPLEMENTED
     I don't think got init does what this function is supposed to
     do.
* register                           DONE
- responsible-p                      DONE
- receive-file                       NOT NEEDED, default `register' is fine
- unregister                         DONE
* checkin                            DONE
* find-revision                      DONE
* checkout                           NOT IMPLEMENTED
     I'm not sure how to properly implement this.  Does filling
     FILE with the find-revision do the trick?  Or use got update?
* revert                             DONE
- merge-file                         NOT IMPLEMENTED
- merge-branch                       DONE
- merge-news                         NOT IMPLEMENTED
- pull                               DONE
- push                               DONE
- steal-lock                         NOT NEEDED, `got' is not using locks
- modify-change-comment              NOT IMPLEMENTED
     can be implemented via histedit, if I understood correctly
     what it is supposed to do.
- mark-resolved                      NOT NEEDED
     got notice by itself when a file doesn't have any pending
     conflicts to be resolved.
- find-admin-dir                     NOT NEEDED

HISTORY FUNCTIONS
* print-log                          DONE
* log-outgoing                       DONE
* log-incoming                       DONE
- log-search                         DONE
- log-view-mode                      DONE
- show-log-entry                     NOT IMPLEMENTED
- comment-history                    NOT IMPLEMENTED
- update-changelog                   NOT IMPLEMENTED
* diff                               DONE
- revision-completion-table          DONE
- annotate-command                   DONE
- annotate-time                      DONE
- annotate-current-time              NOT NEEDED
     the default time handling is enough.
- annotate-extract-revision-at-line  DONE
- region-history                     NOT IMPLEMENTED
- region-history-mode                NOT IMPLEMENTED
- mergebase                          NOT IMPLEMENTED

TAG SYSTEM
- create-tag                         DONE
- retrieve-tag                       DONE

MISCELLANEOUS                        NOT IMPLEMENTED
- make-version-backups-p             NOT NEEDED, `got' works fine locally
- root                               DONE
- ignore                             NOT NEEDED, the default action is good
- ignore-completion-table            NOT NEEDED, the default action is good
- find-ignore-file                   DONE
- previous-revision                  DONE
- next-revision                      DONE
- log-edit-mode                      NOT IMPLEMENTED
- check-headers                      NOT NEEDED, `got' does not use headers
- delete-file                        DONE
- rename-file                        NOT IMPLEMENTED
- find-file-hook                     DONE
- extra-menu                         NOT IMPLEMENTED
- extra-dir-menu                     NOT IMPLEMENTED, same as above
- conflicted-files                   DONE
- repository-url                     DONE