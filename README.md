# A Management System Implemented in Assembly
This repository contains a simple record-based management system implemented in assembly. We know it's poorly written but hey, it works!

## Useful links
- [NASM Documentation](http://www.nasm.us/xdoc/2.15.05/nasmdoc.pdf)
- [Register Breakdown](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture)
- [Guide to x86 Assembly](https://www.cs.virginia.edu/~evans/cs216/guides/x86.html)
- [GDB Tutorial](http://www.unknownroad.com/rtfm/gdbtut/gdbtoc.html)
- [GDB Applied to Assembly](https://www.csee.umbc.edu/courses/undergraduate/CMPE310/Spring15/cpatel2/nasm/gdb_help.shtml)
- [Linux Syscall Table Info](http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/)
- [i386 Syscall Table](https://github.com/torvalds/linux/blob/master/arch/x86/entry/syscalls/syscall_32.tbl)
- [x64 Syscall Table](https://github.com/torvalds/linux/blob/master/arch/x86/entry/syscalls/syscall_64.tbl)
- [Absolute vs. Relative Addresses](https://en.wikipedia.org/wiki/Addressing_mode#Simple_addressing_modes_for_code)
    + The `rel` keyword in `nasm` assembly, as seen in section `3.3` of its manual tells that effective addresses loaded with `lea` should be relative to the `RIP` (the program counter) instead of absolute which is the default behaviour.
- [Position Independent Code/Executable](https://en.wikipedia.org/wiki/Position_independent_code)
    + This explains why we pass the `-no-pie` flag to `gcc` as we have hardcoded addresses!
