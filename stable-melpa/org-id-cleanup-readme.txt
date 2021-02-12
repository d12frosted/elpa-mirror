Purpose:

 Interactively find and clean up unused IDs of org-id.
 The term 'unused' refers to IDs, that have been created by org-id
 regularly, but are now no longer referenced from anywhere within in org.
 This might e.g. happen by deleting a link, that once referenced such an id.

 Normal usage of org-id does not lead to a lot of such unused IDs, and
 org-id does not suffer much from them.

 However, some usage patterns or packages (like org-working-set) may
 produce a larger number of such unused IDs; in such cases it might be
 helpful to clean up with org-id-cleanup.

Setup:

 org-id-cleanup should be installed with package.el
