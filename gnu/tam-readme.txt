Table Allocation Manager
Provides an interface to managing the usage of the slots in a fixed size
table.  All allocation is done during initialization to avoid triggering
garbage collection during allocation/free operations.

 API:

 (tam-create-table N) => table of size N
 (tam-table-fullp TABLE) => nil unless TABLE is full
 (tam-table-emptyp TABLE) => nil unless TABLE is empty
 (tam-table-size TABLE) => number of slots in TABLE
 (tam-table-used TABLE) => number of slots of TABLE in use
 (tam-table-get TABLE IDX) => contents of TABLE slot at index IDX
 (tam-allocate TABLE OBJ) =>
     if not full, assigns OBJ to contents of a free slot in TABLE,
                  and returns the index of the slot
     if full, returns nil
 (tam-free TABLE INDEX) =>
     if slot at INDEX of TABLE is in use, move to the free list and
             return the object formerly held by the slot
     if slot is already free, signal an error
 (tam-table-free-list TABLE) => list of free indices in TABLE
 (tam-table-live-list TABLE) => list of in-use indices in TABLE