
Projectile has native support for using ivy as its completion
system. Counsel-projectile provides further ivy integration into
projectile by taking advantage of ivy's support for selecting from
a list of actions and applying an action without leaving the
completion session. Concretely, counsel-projectile defines
replacements for existing projectile commands as well as new
commands that have no projectile counterparts. A minor mode is also
provided that adds key bindings for all these commands on top of
the projectile key bindings.
