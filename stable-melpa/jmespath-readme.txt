A simple jmespath parser that uses jp underneath to query the json file.  All
you need to do is run the `jmespath-query-and-show' function and enter your jmespath
query.  The queried result will be displayed in the *JMESPath Result* buffer
To run the query on a file, run `C-u M-x jmespath-query-and-show`.

This package depends on the jp utility: https://github.com/jmespath/jp
