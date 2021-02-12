Purpose:

 Manage a small subset of org-nodes to visit them with ease.

 On a busy day org-working-set allows to jump quickly between the nodes
 associated with different tasks.  It provides an answer to the question:
 What have I been doing before beeing interrupted in the middle of an
 interruption ?

 The working-set is a small set of nodes; you may add nodes (which
 means: their ids) to your working-set, if you want to visit them
 frequently; the node visited last is called the current node.  The
 working-set is volatile and expected to change each day or even hour.

 Once you have added nodes to your working set, there are two ways to
 traverse them (both accessible through the central function
 `org-working-set'): circling through your working set is the quickest
 way to return to the current node or visit others; alternatively, the
 working-set menu produces a editable list of all working-set nodes,
 allowing visits too.

 Please note, that org-working-set adds an id-property to all nodes in
 the working-set; but it does not move or change the nodes in any other
 way.

 The list of ids from the nodes of your working-set is stored within the
 property-drawer of a distinguished node specified via
 `org-working-set-id'; this node will also collect an ever-growing
 journal of nodes added to the working-set, which may serve as a
 reference later.


Similar Packages:

 Depending on your needs you might find these packages interesting too
 as they provide similar functionality: org-now and org-mru-clock.


User-Story:

 Assume, you come into the office in the morning and start your Emacs
 with org-mode, because you keep all your notes in org.  Yesterday
 evening you only worked within the org-node 'Feature Request';
 therefore your working-set only contains this node (which means: its
 id).

 So, you invoke the working-set menu (or even quicker, the circle) and
 jump to the node 'Feature Request' where you continue to work.  Short
 after that, your Boss asks for an urgent status-report.  You immediately
 stop work on 'Feature Request' and find your way to the neglected node
 'Status Report', The working set cannot help you to find this node
 initially, but then you add it for quicker access from now on.  Your
 working set now contains two nodes.

 Next you attend your scrum-meeting, which means you open the node
 'Daily Scrum'.  You add it to your working set, because you expect to
 make short excursions to other nodes and want to come back quickly.
 After the meeting you remove its node from your working set and
 continue to work on 'Status Report', which you find through your
 working-set quickly.

 When done with the report you have a look at your agenda, and realize
 that 'Organize Team-Event' is scheduled for today.  So you decide to add
 it to your working-set (in case you get interrupted by a phone call)
 and start to work on this for an hour or so.  The rest of the day passes
 like this with work, interruptions and task-switches.

 If this sounds like your typical work-day, you might indeed benefit
 from org-working-set.


Setup:

 - org-working-set can be installed with package.el
 - Invoke `org-working-set', it will explain and assist in setting the
   customizable variable `org-working-set-id'
 - Optional: Bind `org-working-set' to a key, e.g. C-c w
