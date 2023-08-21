
Yasnippet Completion at Point Function to lookup snippets by name

Simply add to the list of existing `completion-at-point-functions' thus:
   (add-to-list 'completion-at-point-functions #'yasnippet-capf)

If you prefer to have the lookup done by name rather than key, set
`yasnippet-capf-lookup-by'.
