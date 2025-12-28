
macher is a project-aware LLM editing toolset built on gptel.

Key features:
- gptel presets that add read/edit tools and workspace context to requests
- View proposed changes as reviewable patches (potentially spanning multiple
  files)
- Quick workflow via `macher-implement', `macher-revise', and
  `macher-discuss'

Conceptually, when you send a macher request, the LLM receives tools to
read/search/edit files in your "workspace" (typically the current project).
Changes are captured in memory and displayed as patches, never written
directly to disk.

Setup: Call `macher-install' to register presets and tools with gptel.
Optionally call `macher-enable' to apply base infrastructure globally,
allowing use of macher tools and dynamic context in any gptel buffer.

Usage: The action commands (`macher-implement', `macher-revise',
`macher-discuss') provide a quick workflow in dedicated buffers.
Alternatively, use macher presets in any gptel request:

  @macher set up eslint with sensible defaults

Available presets: `@macher' (full editing), `@macher-ro' (read-only),
`@macher-system' (context only), and others - see `macher-presets-alist'.
