Org mode export backend for exporting the document syntax tree to JSON.
The main entry points are `ox-json-export-as-json' and
`ox-json-export-to-json'. It can also be used through the built-in
export dispatcher through `org-export-dispatch'.

Export options:

:json-data-type-property (string) - This the name of a property added to all
  JSON objects in export to differentiate between structured data and
  ordinary key-value mappings. Its default value is "$$data_type". Setting
  to nil prevents the property being added altogether.

:json-exporters - plist containing exporter functions for different data
  types. The keys appear in :json-property-types and can also be used with
  `ox-json-encode-with-type'. Functions are called with the value to be
  exported and the export info plist. Default values stored in
  `ox-json-default-type-exporters'.

:json-property-types (plist) - Sets the types of properties of specific
  elements/objects. Nested set of plists - the top level is keyed by element
  type (see `org-element-type') and the second level by property name (used
  with `org-element-property'). Values in 2nd level are keys in the
  :json-exporters plist and are used to pick the function that will export
  the property value. Properties with a type of t will be encoded using
  `ox-json-encode-auto', but this sometimes can produce undesirable
  results. The "all" key contains the default property types for all element
  types. This option overrides the defaults set in
  `ox-json-default-property-types'.

:json-strict (bool) - If true an error will be signaled when problems are encountered
  in exporting a data structure. If nil the data structure will be exported as an
  object containing an error message. Defaults to nil.

:json-include-extra-properties (bool) - Whether to export node properties not listed
  in the :json-property-types option. If true these properties will be exported
  using `ox-json-encode-auto'.
