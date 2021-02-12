Generate a TOC from a markdown file: M-x markdown-toc-generate-toc
This will compute the TOC at insert it at current position.
Update existing TOC: C-u M-x markdown-toc-generate-toc

Here is a possible output:
<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [some markdown page title](#some-markdown-page-title)
- [main title](#main-title)
    - [Sources](#sources)
        - [Marmalade (recommended)](#marmalade-recommended)
        - [Melpa-stable](#melpa-stable)
        - [Melpa (~snapshot)](#melpa-~snapshot)
    - [Install](#install)
        - [Load org-trello](#load-org-trello)
    - [Alternative](#alternative)
        - [Git](#git)
        - [Tar](#tar)
- [another title](#another-title)
    - [with](#with)
    - [some](#some)
- [heading](#heading)

<!-- markdown-toc end -->

Install - M-x package-install RET markdown-toc RET
