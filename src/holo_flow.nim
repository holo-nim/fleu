## reader/writer types that use a "dynamic buffer" that can load/flush data immediately or when it becomes available via a callback (which can read from streams etc)
##
## the buffer also shrinks to remove data up to a position marked as read when it needs to resize, although a queue would be better for this, but strings keep compatibility

import holo_flow/[holo_reader, holo_writer]
export holo_reader, holo_writer
