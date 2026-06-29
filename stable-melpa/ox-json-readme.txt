Org mode export backend for exporting the document syntax tree to JSON.
The main entry points are `ox-json-export-to-buffer' and
`ox-json-export-to-file'.  It can also be used through the built-in
export dispatcher through `org-export-dispatch'.

Export options:

:json-data-type-property (string) - This the name of a property added to all
  JSON objects in export to differentiate between structured data and
  ordinary key-value mappings.  Its default value is "$$data_type".  Setting
  to nil prevents the property being added altogether.

:json-exporters - plist containing exporter functions for different data
  types.  The keys appear in :json-property-types and can also be used with
  `ox-json-encode-with-type'.  Functions are called with the value to be
  exported and the export info plist.  Default values stored in
  `ox-json-default-type-exporters'.

:json-property-types (plist) - Sets the types of properties of specific
  elements/objects.  Nested set of plists - the top level is keyed by element
  type (see `org-element-type') and the second level by property name (used
  with `org-element-property').  Values in 2nd level are keys in the
  :json-exporters plist and are used to pick the function that will export
  the property value.  Properties with a type of t will be encoded using
  `ox-json-encode-auto', but this sometimes can produce undesirable
  results.  The "all" key contains the default property types for all element
  types.  This option overrides the defaults set in
  `ox-json-default-property-types'.

:json-strict (bool) - If true an error will be signaled when problems are encountered
  in exporting a data structure.  If nil the data structure will be exported as an
  object containing an error message.  Defaults to nil.

:json-include-extra-properties (bool) - Whether to export node properties not listed
  in the :json-property-types option.  If true these properties will be exported
  using `ox-json-encode-auto'.

:json-omit-default-property-values (bool) - When non-nil, properties matching their
  default value in `ox-json-default-property-values' are omitted from export.  Set
  to nil to include all properties (backwards-compatible behavior).  Defaults to t.

:json-postprocess (symbol) - How to postprocess the final output.  Values are `pretty'
  (indent properly), `minimal' (remove whitespace), and nil (nothing, maybe faster?).

:json-deterministic-refs (bool) - When non-nil, node refs are derived from
  the element's structural path in the parse tree rather than a random number,
  producing refs that are stable across repeated exports of identical source
  and across Org versions (unlike buffer positions, which can shift between
  parser versions).  Defaults to nil (random refs, original behavior).
