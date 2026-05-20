Enable WakaTime for the current buffer by invoking
`wakatime-mode'. If you wish to activate it globally, use
`global-wakatime-mode'.

Set variable `wakatime-api-key' to your API key. By default
`wakatime-cli-path' is nil and wakatime-mode will look for an
existing `wakatime-cli' on your $PATH, otherwise auto-downloading the
latest release from
<https://github.com/wakatime/wakatime-cli/releases> into
`wakatime-resources-folder' (~/.wakatime/ by default). Update checks
run at most every `wakatime-update-check-interval' seconds. To pin a
specific binary, set `wakatime-cli-path' to its absolute path.
