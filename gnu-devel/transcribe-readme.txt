REQUIRES:
-----------------------------
This module works without any requires, but in order to use the audio 
functions, you need to install the Emacs package "emms", by Joe Drew,
and the external program "mpg321", by Jorgen Schafer and Ulrik Jensen,
both under GPL licenses.

USAGE:
-------------------------
Transcribe is a tool to make audio transcriptions for discourse analysis
in the classroom.
It allows the transcriber to control the audio easily while typing, as well as
automate the insertion of xml tags, in case the transcription protocol
include them.
The analysis functions will search for a specific structure
of episodes that can be automatically added with the macro NewEpisode.
The function expects the speech acts to be transcribed inside a turn xml
tag with the identifier of the speaker with optional move attribute.
Each speech act is spected inside a <l1> or <l2> tag, depending
on the language used by the person. The attributes expected are the
number of clauses that form the utterance, the number of errors the
transcriber observes, and the function of the speech act. The parser will
work even if some attributes are missing.


AUDIO COMMANDS
------------------------------
    C-x C-p ------> Play audio file. You will be prompted for the name
                    of the file. The recommended format is mp2.
    <f5> ---------> Pause or play audio.
    C-x <right> --> seek audio 10 seconds forward.
    C-x <left> --->seek audio 10 seconds backward.
    <f8> ---------> seek interactively: positive seconds go forward and
                      negative seconds go backward

XML TAGGING COMMANDS
--------------------------------------------------
    C-x C-n ------> Create new episode structure. This is useful in case your
                xml file structure requires it.
    <f2> ---------> Interactively insert a function attribute in a speech act
                (l1 or l2) tag.
    <f3> ---------> Interactively insert a move attribute in a turn (person) tag
    <f4> ---------> Interactively insert an attribute (any kind)
    <f9> ---------> Insert turn (person) tag. Inserts a move attribute.
    <f10> --------> Insert a custom tag. Edit the function to adapt to your needs.
    <f11> --------> Insert speech act tag in L1, with clauses, errors and function
                    attributes.
    <f12> --------> Insert speech act tag in L2, with clauses, errors and function
                    attributes.

AUTOMATIC PARSING
-----------------------------------------------------
    C-x C-a ------> Analyses the text for measurements of performance.