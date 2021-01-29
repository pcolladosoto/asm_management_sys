# The Source Code
This folder contains the source code for the management system implementation.

## Compiling the program
As we have provided a `Makefile` for running the program you can just run `make` from within this directory to generate the final executable. We encourage you to take a look at the `Makefile` as it's entirely commented. We are not good at writing them but hey, it works!

## Trying to debug stuff
After going almost mad with the `SASM` IDE when debugging (that thing hangs up quite easily and takes down the graphical interface of the **whole** system with it and we were tired of rebooting the VM every 15 minutes) we tried to use `gdb` for debugging. Just don't dislike us for being so cheap when using `gdb`...

Once we got past the "suicidal" tendencies provoked by our first impression with `gdb` we found that the best workflow for debugging the program was not to use any breakpoints. We would input the data normally and then halt the execution with `^C` once in the main menu. The `SIGINT` signal hanged the program and that let us inspect the memory contents as well as the registers freely.

In order to move around our variables area we had to fiddle with `gdb`'s `x` command quite a lot. The general syntax is:
```
x/<n_data_units><format><data_unit> <address>
```

Now, as we are mostly concerned with showing strings we used `cb` for the format and data units respectively which lets us specify the number of `b`ytes we want to show and they'll be printed with an AS`c`II format. Now, let's say we want to show the data at the `user_data` address. As we don't need to do any arithmetic we could just use:
```
x/<n_bytes>cb &user_data
```

But if we want to move around using `user_data` as the origin we need to specify it's indeed a `char*`. If we want to show the position `<offset>` bytes away from `user_data` we would then issue:
```
x/<n_bytes>cb (char* ) &user_data + <offset>
```

Even though it's not elegant by any means this let's us inspect our program's memory freely.

If we just want to show a number, say the current number of users with label `curr_users` we cold just issue:
```
x/1db &curr_users
```

As we just want one byte (we know the number is small) and we would like to see it in a `d`ecimal format.
