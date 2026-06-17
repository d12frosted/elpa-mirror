This package provides a preset for Eglot to work with TypeScript,
JavaScript, CSS, Astro, Vue, and Svelte files.  It configures LSP servers
and optional linter/formatter integration via rassumfrassum (rass).

Prerequisites:

- Install typescript-language-server, deno, or tsgo (for TS/JS files)
- Install @astrojs/language-server (for Astro files, optional)
- Install @vue/language-server (for Vue files, optional)
- Install svelte-language-server (for Svelte files, optional)
- Optionally install eslint-language-server, biome, oxlint, or oxfmt
- Download this file and add it to the load path

Quick start (package-vc):

  (use-package eglot-typescript-preset
    :vc (:url "https://github.com/mwolson/eglot-typescript-preset"))

After that, opening TypeScript, JavaScript, CSS, Astro, Vue, or Svelte
files will automatically start the LSP server using Eglot.
