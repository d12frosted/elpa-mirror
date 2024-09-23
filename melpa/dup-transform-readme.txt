A package for graphics coders, to duplicate a line or region,
handling rgb(a), xyz(w), [0]-[2] etc.
To use, place point on a line to be duplicated & transformed.
That line should have a pattern
like the following:
* .x (will be transformed to .y .z .w)
* ->x (similar)
* .r (will be transformed to .g .b .a)
* ->r (similar)
* red (to green blue alpha)
* [0] (to [1] [2] [3])
Use C-u (repeat count) to set total number of repeats.
Defaults to 3 if the line/region contains rgb-type text,
otherwise 2.
