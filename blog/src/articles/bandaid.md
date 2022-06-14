#### introduction
systemd has a unique feature called socket activation, which listens on a socket on behave of a particular service, and lauches the service on demand when the first connection comes in. This might not sound like particularly useful apart from saving a little bit of resource, but a second thought would reveal it's full potential: inter-service dependencies done right and easily. However all magic comes with a price, with socket activation, that means you have to write your program in a specific way to be compatible.

#### the protocol
A full specification of the socket activation protocol can be found at [sd_listen_fds](https://www.freedesktop.org/software/systemd/man/sd_listen_fds.html). In short, the sockets are injected into the service process as plain nice file descriptors.

#### the bandaid
What if we want to slap socket activation onto unmodified programs? We known that when a program would like to listen on a socket, it has to create one first with the `socket` syscall. By replacing the implementation of `socket`, we can, instead of creating a new file descriptor for the socket, just return the one passed by systemd.

But how to modified the behavior of a syscall, if you are nothing but a powerless usermode application? On Linux, there's a framework called seccomp, well-known for filtering syscalls available to processes, it has a less known feature named seccomp unotify, allowing the decision for whether to allow or reject a syscall or even to modify it's behavior to be done by another usermode process.

Let's recap how far we have gone: 
- systemd launches our wrapper, which in turn lauches the target program. 
- the target programs calls `socket` to start listening on a socket on its own.
- a seccomp policy installed by our wrapper pauses the handling of the syscall, kernel passes relavent informations back to our wrapper and waits for a final decision.
- our wrapper loops through the list of file descriptors passed by systemd to find a matching one.
- then what?

Our wrapper and the target program are two separate processes, we still have to inject the file descriptor into the target process in one way or another. The authors of seccomp appearently had been on the same page as me, there's another subtle feature within seccomp unitify: addfd, which as the name suggests, does exactly the job of inserting a file descriptor without cooperation.

- call addfd to inject the matching file desctiptor into the target process.
- set the return value of the hijacked `socket` call to the file desctiptor number.

Mission complete. The above is exactly how [bandaid](https://github.com/NickCao/bandaid) works, to make *some* programs work with systemd socket activation.

#### the limitation
The solution works, most of the times, but still has a large numbers of limitations. The most prominent one is to **find a matching file descriptor**. It might sound like a easy task, but given that the `socket` syscall really has a small number of parameters, ambiguities are unavoidable, thus bandaid only works on programs with a small number of sockets that listens on varying families and types.
