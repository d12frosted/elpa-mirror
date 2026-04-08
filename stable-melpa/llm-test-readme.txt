llm-test is a testing library that uses LLM agents to interpret
natural-language test specifications (written in YAML) and execute them
against a fresh Emacs process.  Tests are registered as ERT tests, so they
integrate with the standard Emacs test infrastructure.

Usage:
  (require 'llm-test)
  (setq llm-test-provider (make-llm-openai :key "..."))
  ;; or set LLM_TEST_DEBUG=file LLM_TEST_PROVIDER_ELISP in the environment
  (llm-test-register-tests "path/to/testscripts/")
