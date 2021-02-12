Org Dashboard provides a visual summary of progress on projects and
tasks.

For example, if an org file (known by `org-dashboard-files') contains
the following:

    * Project: Better Health
    :PROPERTIES:
    :CATEGORY: health
    :END:

    ** Milestones
    *** [66%] run 10 km/week
    **** TODO learn proper warmup
    **** DONE look for a jogging partner
    **** DONE run 10 minutes on monday

    * Project: Super Widget
    :PROPERTIES:
    :CATEGORY: widget
    :END:

    ** Milestones
    *** [1/6] release 0.1
    **** DONE git import
    **** TODO create github project
    **** TODO add readme
    **** TODO publish

Then `M-x org-dashboard-display' generates the following report and
displays it in a new buffer:

    health                run 10 km/week [||||||||||||||||||||||           ]  66%
    widget                   0.1 release [||||||                           ]  18%

A dynamic block form is also supported. Writing the following in an
org file and then running `org-dblock-update', or placing the
cursor on the first line of the block and then typing `C-c C-c',
will insert the same report shown above into the block:

    #+BEGIN: block-dashboard
    #+END:

Configuration:

You can customize the following variables:

- `org-dashboard-files': list of files to search for progress entries; defaults to `org-agenda-files'
- `org-dashboard-show-category': whether to show or not the project category
- `org-dashboard-filter': a function that decides whether an entry should be displayed or not

For example, to avoid displaying entries that are finished
(progress = 100), not started (progress = 0), or are tagged with
"archive", use the following:

   (defun my/org-dashboard-filter (entry)
     (and (> (plist-get entry :progress-percent) 0)
          (< (plist-get entry :progress-percent) 100)
          (not (member "archive" (plist-get entry :tags)))))

   (setq org-dashboard-filter 'my/org-dashboard-filter)

Notes:

Labels link back to the trees where they were found.

The color of the progress bar is (naively, for now) chosen based on
the progress value, from dark red to bright green.

If not set per-tree through a property or per-file through a
keyword, the category defaults to the file name without extension.
To set category on a per-file basis, you can add the following at
the bottom of the org file:

   #+CATEGORY: xyz

Related work:

This module was inspired by Zach Peter's [A Dashboard for your
Life](http://thehelpfulhacker.net/2014/07/19/a-dashboard-for-your-life-a-minimal-goal-tracker-using-org-mode-go-and-git/).

Contributions:

- one feature or fix per pull request
- provide an example of the problem it addresses
- please adhere to the existing code style
