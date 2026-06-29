                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 VECDB: VECTOR SEARCH LIBRARY FOR EMACS
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Introduction
══════════════

  The `vecdb' package provides an interface to a vector database, where
  vectors are vecdbdings representing pieces of text.  These databases
  enable "semantic search", which is a powerful way to search over
  meaning.  This kind of search needs specialized storage and retrieval.

  This package doesn't provide end-user functionality on its own; it is
  designed to be used in other packages that need semantic search.

  The package does not provide vecdbdings, that can be done with the
  [llm] package, or any source of vecdbdings.


[llm] <https://github.com/ahyatt/llm>


2 Configuring the collection
════════════════════════════

  There are two concepts that together define a collection database of
  vecdbdings: the /provider/, and the /collection/.  The provider is
  what kind of backend we are using, right now either `chroma', or
  `qdrant'.  This is a struct defined by the exact provider you want to
  use.

  The collection is, for that provider, what exact database is getting
  used, with each collection having its own separate data.  Collections
  must be created before being used.  The collection is defined by the
  struct `vecdb-collection' which has a `name' (used to identify the
  collection), `vector-size', and `payload-fields'.  The `vector-size'
  will be based on the size of the vecdbding vector from your provider.
  1536 is what Open AI uses.  `payload-fields' is an alist of fields and
  their types that defines other data fields that are inserted and
  retrieved when search happens, and can be queried on as well
  (eventually, in a future iteration of the package).

  An example, putting it all together, is:

  ┌────
  │ (defvar my-vecdb-provider (make-vecdb-provider :api-key my-qdrant-api-key :url my-qdrant-url))
  │ (defvar my-vecdb-collection (make-vecdb-collection :name "my test collection" :vector-size 1536 :payload-fields (('my-id . 'string))))
  └────

  The provider will be supplied by the end-user, specifying how they
  want things stored, and any data necessary for that storage and
  retrieval to function.  The collection is typically partially supplied
  by the application, with the possible exception of vecdbding size,
  which may be dependent on the exact vecdbding provider they are using.

  Collections must be created before they can be used with
  `vecdb-create', and `vecdb-exists' can return whether the collection
  exists.

  ┌────
  │ (unless (vecdb-exists my-vecdb-provider my-vecdb-collection)
  │   (vecdb-create my-vecdb-provider my-vecdb-collection))
  └────

  They can also be deleted with `vecdb-delete'.


3 Adding and replacing data
═══════════════════════════

  Before data is queried, it must be added. This is done via a batch
  operation on a group of data, `vecdb-upsert-items'. This either
  creates an item in the collection or replaces it, based on the `id' of
  the item. `id' should be an integer or a string UUID. Seeing as how
  emacs does not provide a UUID library, probably an integer is the best
  choice.

  ┌────
  │ (vecdb-upsert-items my-vecdb-provider my-vecdb-collection
  │ 		 (list (make-vecdb-item
  │ 			:id 91
  │ 			:vector [0.1 0.2 0.3 0.4]
  │ 			:payload '(:my-id "235913926"))))
  └────

  These can be deleted with `vecdb-delete-item' and retrieved by ID with
  `vecdb-get-item'.

  IDs used in `vecdb' *must* be `uint64' values.  If you have another ID
  you need to use to tie it together with other storage, that should go
  into the `payload'.  Also, each item passed in must set the same
  payload fields.


4 Querying data
═══════════════

  Querying the database can be done with `vecdb-search-by-vector',
  passing it a vector and optionally a number of results to return (10
  is the default).

  ┌────
  │ (vecdb-search-by-vector my-vecdb-provider my-vecdb-collection [0.3 0.1 0.5 -0.9] 20)
  └────

  This will return the specifies number of `vecdb-item' structs, with
  the payloads they were stored with.


5 Providers
═══════════

5.1 qdrant
──────────

  [qdrant] is an open source vector database that concentrates mostly on
  running in the cloud, but can be run locally with a docker container.
  They provide a free tier for your database in the cloud that may be
  garbage collected after a period of inactivity.

  A qdrant provider is defined like:

  ┌────
  │ (defvar my-vecdb-provider (make-vecdb-qdrant-provider :api-key my-qdrant-api-key :url my-qdrant-url))
  └────

  Substitute `my-qdrant-api-key' with your key, and `my-qdrant-url' is
  the URL of the server that is used to serve your data.  This will be
  unique to your collection in the cloud, or a local URL for docker.


[qdrant] <https://qdrant.tech/>


5.2 chroma
──────────

  [chroma] is an open source Python-centric vector database.  It can run
  as a server locally, or offers paid services to host in the cloud.
  Currently this library only supports local running.

  If running locally, before use, you must run `chroma run' to start the
  server.

  The chroma provider has two additional divisions of data above the
  collection, and these are specified in the provider itself: the
  /tenant/ and the /database/.  These will both default to `"default"',
  but can be specifed.  Because the chroma provider is local, my
  default, no configuration is needed:

  ┌────
  │ (defvar my-chroma-provider (make-vecdb-chroma-provider))
  └────

  However, the full set of options, here demonstrating the equivalent
  settings to the defaults are:

  ┌────
  │ (defvar my-chroma-provider (make-vecdb-chroma-provider
  │ 			    :binary "chroma"
  │ 			    :url "http://localhost:8000"
  │ 			    :tenant "default"
  │ 			    :database "default"))
  └────


[chroma] <https://www.trychroma.com/>


5.3 Postgres with pgvector
──────────────────────────

  The popular database Postgres has an extension that allows it to have
  vector database functionality, [pgvector].  This needs the `pg-el'
  library.

  A provider defines a database, and the collection will define a table
  with the collection name in that database.

  For example,
  ┌────
  │ (defvar my-postgres-provider (make-vecdb-psqlprovider :dbname "mydatabase" :username "myuser"))
  └────

  This also takes an optional password as well.  For now, this just uses
  localhost as a default.


[pgvector] <https://github.com/pgvector/pgvector>
