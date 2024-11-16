# mespas

A message passing library.

This library implements a multiple producer single consumer FIFO queue.


The `Queue` struct provides a FIFO array-based queue.

The `mpsc` module provides channels to send and receive messages on in an asynchronous
and synchronous manner (through `recv()` and `tryRecv()` in the `Receiver` struct.

See [example.zig](example.zig) for an example on how to use the mpsc channel.
