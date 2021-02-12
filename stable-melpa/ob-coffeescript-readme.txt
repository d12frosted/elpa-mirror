
Org-Babel support for evaluating coffee-script code.

It was created based on the usage of ob-template.
fully implementation:
- Support session(multi-session independent) and external evaluation.
- Support :results value and output .
- Can handle table and list input.


; Requirements:

- node :: https://nodejs.org/en/

- coffee-script :: http://coffeescript.org/

- coffee-mode :: Can be installed through ELPA, or from
  https://raw.githubusercontent.com/defunkt/coffee-mode/master/coffee-mode.el

- inf-coffee :: Can be installed through from
  https://raw.githubusercontent.com/brantou/inf-coffee/master/inf-coffee.el


; TODO


- Provide better error feedback.

- more robust for session evaluation.
