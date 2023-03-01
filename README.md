"Shell"
=======

Functions for invoking executables and for running bash in a
subprocess.

Warning: this library is unloved and not actively maintained: consider
using `Async.Process.run` and related functions, instead.
Or if you really need a synchronous process spawning API, use
`Core_unix.create_process`,  or `Spawn.spawn` directly.
