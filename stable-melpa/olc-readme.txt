This program provides basic open location code support in Emacs
Lisp. Recovery of shortened codes uses OpenStreetMap nominatim;
please check the terms of use for the service to ensure that your
use complies with the API terms of use.

All methods required by the open location code specification are
provided in some form.  The implementation passed the tests present
in the open location code github repository at the time of writing
almost cleanly -- there are some minor rounding issues in decode.
