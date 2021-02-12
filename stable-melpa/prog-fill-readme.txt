Have you ever hated having really long chained method calls in heavy OOP
languages? or just enjoy avoiding hitting the 80 column margin in any others?

If so, this is the mode for you!

Examples:

Imagine coming across this mess - who wants to try to mentally parse that
out?

    $this->setBlub((Factory::get('some-thing', 'with-args'))->inner())->withChained(1, 2, 3);

Hit M-q on the line (after binding it to `prog-fill' for that mode) and it
becomes:

    $this
        ->setBlub(
            (Factory::get(
                'some-thing',
                'with-args'))
            ->inner())
        ->withChained(
            1,
            2,
            3);

Or maybe you've got a crazy javasript promise chain you're working on?

    superagent.get(someUrl).then(response => response.body).catch(reason => console.log(reason))

Again, press M-q on the line and it becomes:

    superagent.get(someUrl)
      .then(response => response.body)
      .catch(reason => console.log(reason))
