
ELISA (Emacs Lisp Information System Assistant) is a system
designed to generate informative answers to user queries using a
Retrieval Augmented Generation (RAG) approach.  RAG combines the
capabilities of Large Language Models (LLMs) with Information
Retrieval (IR) techniques to enhance the accuracy and relevance of
generated responses.

ELISA addresses limitations inherent in purely LLM-based systems by:

- Leveraging External Knowledge: Unlike LLMs trained on a fixed
dataset, ELISA can access and process information from external
knowledge sources, expanding its knowledge base beyond its initial
training data.

- Reducing Computational Requirements: Instead of
retraining the entire LLM for new information, ELISA focuses on
retrieving relevant data, minimizing computational resources
required for query processing.

- Minimizing Hallucinations: By grounding responses in factual
data retrieved from external sources, ELISA aims to reduce the
likelihood of generating incorrect or nonsensical information
(hallucinations) often associated with LLMs.

The following sections will detail the key components and processes
involved in ELISA's operation: parsing, retrieval, augmentation,
and generation.

Parsing.

Simple solution is split text document into chunks by length with
overlap and save it to storage.  In ELISA we use more advanced
solution.  Instead of split by length we split text by semantic
distances between parts of text document.  To store this chunks we
use sqlite database.

Retrieving.

Simple solution is to extract top K chunks by semantic similarity
from storage.  To improve quality we use more robust solution.

Before going to storage we let LLM rewrite user query to make it
context agnostic.  For example, user ask LLM about llamas, LLM
answer.  Then user ask "where it lives?".  If we try to search for
this query we barely find something useful.  But LLM can rewrite it
to something like "where llamas lives?" and we will find useful
information.

Instead of use simple semantic similarity search only we use hybrid
search.  It means that ELISA search relevant chunks by semantic
similarity and by full text search and then combine results.

To improve relevance even more instead of use top K results from
hybrid search user can enable reranker.  Reranker is a service that
gives user query, top N chunks and feed it to reranker model.  This
model gives pairs of text: user query and text chunk and return
number that means relevance.  Service collect this results and sort
it by relevance.  Also if reranker enabled ELISA filter out
irrelevant results.

Augmentation.

ELISA gets text retrieved in previous step and put it into context.
This context later will be sent to LLM together with user query.

Generation.

To improve generation quality to user query will be added
instructions to LLM how to answer.  We let LLM ability to say "not
enough data" instead of hallucinations.  LLM generates answer based
on context, instructions and user query.
