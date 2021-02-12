
This package enhances the imenu support in `yaml-mode'.  It
generates an index containing a full list of keys that contain any
child, with key names in the dot-separated path form like
`jobs.build.docker' and `ja.activerecord.attributes.user.nickname'.
It shines great with `which-function-mode' enabled.

; Requirements:

This package depends on Ruby for parsing YAML documents to obtain
location information of each node.  Ruby >=2.5 works out of the box;
if you have an older version of Ruby, run the following command to
install the latest version of `psych', the YAML parser:

  % gem install psych --user

The parser only parses a document without evaluating it, so there
should be no security concerns.

; Configuration:

Add the following line to your init file:

  (yaml-imenu-enable)
