Jetbrains IDEs and Emacs are best friend!

## Support IDEs

- Android Studio: `studio'
- AppCode: `appcode'
- CLion: `clion'
- Gogland: `gogland'
- IntelliJ IDEA: `idea'
- PhpStorm: `pstorm'
- PyCharm: `charm'
- Rider: `rider'
- RubyMine: `mine'
- WebStorm: `wstorm'

## Setup

Please run `Tools > Create Command-line Launcher...' by menu in your IDE.


### .dir-locals.el

I encourage you to create a `.dir-locals.el` file in your project.

    ((nil . (jetbrains-ide "PhpStorm")))

### Interoperability

You can return to Emacs from the IDE.
Please see follows article: "Quick Tip: Getting Emacs and IntelliJ to play together"
https://developer.atlassian.com/blog/2015/03/emacs-intellij/

## FAQ

### Q.  Do you support proprietary software?

A. Partially, yes.

I am a supporter of the Free Software Movement.
However, since I am a lazy programmer, I know that the IDE's support can save
a lot of time and effort.  Proprietary software is unethical, but some of them are
powerful and practical.  The IDEs are a bit lacking in the charm of hacking.
I would like to increase the time we spend lazily away from business
by interoperating them.

When the practical development environment is completed by free softwares,
I will stop recommending you to proprietary software.
