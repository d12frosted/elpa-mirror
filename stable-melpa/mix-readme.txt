Add a hook to the mode that you're using with Elixir, for example, `elixir-mode`:

(add-hook 'elixir-mode-hook 'mix-minor-mode)


; C-c d e - mix-execute-task - List all available tasks and execute one of them.  It starts in the root of the umbrella app.  As a bonus, you'll get a documentation string because mix.el parses shell output of mix help directly.  Starts in the umbrella root directory.
; C-c d d e - mix-execute-task in an umbrella subproject - The same as mix-execute-task but allows you choose a subproject to execute a task in.
; C-c d t - mix-test - Run all test in the app.  It starts in the umbrella root directory.
; C-c d d t - mix-test in an umbrella subproject - The same as mix-test but allows you to choose a subproject to run tests in.
; C-c d o - mix-test-current-buffer - Run all tests in the current buffer.  It starts in the umbrella root directory.
; C-c d d o - mix-test-current-buffer in an umbrella subproject - The same as mix-test-current-buffer but runs tests directly from subproject directory.
; C-c d f - mix-test-current-test - Run the current test where pointer is located.  It starts in the umbrella root directory.
; C-c d d f - mix-test-current-test in an umbrella subproject - The same as mix-test-current-test but runs a test directly from subproject directory.
; C-c d l - mix-last-command - Execute the last mix command.
;
; Prefixes to modify commands before execution
; Add these prefixes before commands described in the previous section.
;
; C-u - Choose MIX_ENV env variable.
; C-u C-u - Add extra params for mix task.
; C-u C-u C-u - Choose MIX_ENV and add extra params.
;
; For example, to create a migration in a subproject you should press:
;
; C-u C-u C-c d d e:
;
; C-u C-u - to be prompted for migration name
; C-c d d e - to select a mix project and ecto.gen.migration task
