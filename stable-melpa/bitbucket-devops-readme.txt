Work with Bitbucket Cloud Pipelines and pull requests from Emacs.

For Pipelines, this package provides repository-aware history and detail
buffers, completed step logs, background watchers with notifications,
manual triggers driven by bitbucket-pipelines.yml, manual-step
continuation, reruns, and cancellation.

For pull requests, it provides listing and filtering, build summaries,
comments and activity, commits, changed-file summaries, raw diff buffers,
review actions, reviewer management, inline comments and replies, and
pull request creation and decline.

Start from the `bitbucket-devops' transient menu, or call
`bitbucket-devops-pipelines-history' and
`bitbucket-devops-pull-requests-list' directly.

Repository identity is resolved from an SSH Git remote, and credentials
come from auth-source.  Bitbucket Cloud only; Bitbucket Data Center is
not supported.  See the README for setup and authentication.
