# GraphQL.el

[![MELPA](https://melpa.org/packages/graphql-badge.svg)](https://melpa.org/#/graphql)
[![Build Status](https://travis-ci.org/vermiculus/graphql.el.svg?branch=master)](https://travis-ci.org/vermiculus/graphql.el)

GraphQL.el provides a set of generic functions for interacting with
GraphQL web services.

See also the following resources:

- [GraphQL language service][graph-lsp] and [`lsp-mode`][el-lsp]
- [`graphql-mode`][graphql-mode]
- [This brief overview of GraphQL syntax][graphql]

[graph-lsp]: https://github.com/graphql/graphql-language-service
[el-lsp]: https://github.com/emacs-lsp/lsp-mode
[graphql-mode]: https://github.com/davazp/graphql-mode
[graphql]: http://graphql.org/learn

## Syntax Overview
Two macros are provided to express GraphQL *queries* and *mutations*:

- `graphql-query` encodes the graph provided under a root `(query
  ...)` node.
- `graphql-mutation` encodes the graph provided under a root
  `(mutation ...)` node.

Both macros allow special syntax for query/mutation parameters if this
is desired; see the docstrings for details. I will note that backtick
notation usually feels more natural in Lisp code.

### Basic Queries

The body of these macros is the graph of your query/mutation expressed
in a Lispy DSL. Generally speaking, we represent fields as symbols and
edges as nested lists with the edge name being the head of that list.
For example,

```emacs-lisp
(graphql-query
 (myField1 myField2 (myEdges (edges (node myField3)))))
```

will construct a query that retrieves `myField1`, `myField2`, and
`myField3` for every node in `myEdges`. The query is returned as a
string without any unnecessary whitespace (i.e., formatting) added.

## Following Edges

Multiple edges can of course be followed. Here's an example using
GitHub's API:

```emacs-lisp
(graphql-query
 ((viewer login)
  (rateLimit limit cost remaining resetAt)))
```

## Passing Arguments

Usually, queries need explicit arguments. We pass them in an alist set
off by the `:arguments` keyword:

``` emacs-lisp
(graphql-query
 ((repository
   :arguments ((owner . "github")
               (name . ($ repo)))
   (issues :arguments ((first . 20)
                       (states . [OPEN CLOSED]))
           (edges
            (node number title url id))))))
```

As you can see, strings, numbers, vectors, symbols, and variables can
all be given as arguments. The above evaluates to the following
(formatting added):

``` graphql
query {
  repository (owner: "github", name: $repo) {
    issues (first: 20, states: [OPEN, CLOSED]) {
      edges {
        node {
          number title url id
        }
      }
    }
  }
}
```

Objects as arguments work, too, though practical examples seem harder
to come by:

``` emacs-lisp
(graphql-query
 ((object :arguments ((someVariable . ((someComplex . "object")
                                       (with . ($ complexNeeds))))))))
```

gives

``` graphql
query {
  object (
    someVariable: {
      someComplex: "object",
      with: $complexNeeds
    }
  )
}
```

## Working with Responses

- `graphql-simplify-response-edges`

  Simplify structures like

      (field
       (edges
        ((node node1values...))
        ((node node2values...))))

  into `(field (node1values) (node2values))`.

## Keyword Reference

- `:arguments`

  Pass arguments to fields as an alist of parameters (as symbols) to
  values. See `graphql--encode-argument-value`.

- `:op-name`, `:op-params`

  Operation name/parameters. Given to top-level *query* or *mutation*
  operations for later re-use. You should rarely (if ever) need to
  supply these yourself; the `graphql-query` and `graphql-mutation`
  macros give you natural syntax to do this.

## Planned

- `:as` keyword for [aliases][graphql-alias] (`graphql-encode`).

- `...` qualifier for [fragments][graphql-fragment] and [inline
  fragments][graphql-ifragment] (`graphql--encode-object`)

[graphql-alias]: http://graphql.org/learn/queries/#aliases
[graphql-variable]: http://graphql.org/learn/queries/#variables
[graphql-fragment]: http://graphql.org/learn/queries/#fragments
[graphql-ifragment]: http://graphql.org/learn/queries/#inline-fragments
