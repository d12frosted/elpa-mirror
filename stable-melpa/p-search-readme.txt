P-SEARCH is an tool for combining and executing searches in Emacs.
The tool takes its inspiration from Bayesian search theory where it
is assumed that the thing being searched for has a prior
distribution of where it can be found, and that the act of looking
should update our posterior probability distribution.

Terminology: In p-search there are two parts of the search, the
prior and likelihood.  The prior is specified via certain
predicates that reflect your beliefs where the file is located.
For example, you could be 90% sure that a file is in a certain
directory, and 10% elsewhere.  Or you can be very sure that what
you are looking for will contain some form of a search term.  Or
you may believe that the object you are looking for may have a more
active Git log than other files.  Or you think you remember seeing
the file you were looking for in one of your open buffers.  And so
on.  The important thing is that priors have 1) an objective
criteria 2) a subjective belief tied to the criteria.

The second part of the equation is the likelihood.  When looking
for something, the very act of looking for something and not
finding it doesn't mean that the its not there!  Think about when
looking for your keys.  You may check the same place several times
before you actually find them (e.g. hidden under that advertisement
for pizza you have been meaning to throw away).  The act of
observation reduces your probability that the thing being looked
for is there, but it doesn't reduce it all the way to zero.  When
looking for something via p-search, you mark the item with one of
several gradations of certainty that the element being looked for
exists.  After performing the observation, the vector of subjective
probabilities where things exists get following by Bayes rule.
