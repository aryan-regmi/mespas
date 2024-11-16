# mespas

A message passing library.

This library implements a multiple producer single consumer FIFO queue.

This library provides a FIFO array-based `Queue`.

The `mpsc` module provides channels to send and receive messages on in an asynchronous
and synchronous manner (through `recv()` and `tryRecv()` in the `Receiver` struct.
