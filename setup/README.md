# Dockerfiles
One of the downsides of working with assembly is that the compilation process is not trivial. We have then decided to write a simple `dockerfile` that builds an image suitable for compiling and running the code provided in this repository.

## Building and running the docker image
There are tons of resources online explaining how to build docker images from dockerfiles. We are nonetheless providing the command we used for building ours so that you don't need to surf the web at all. Beware that in order for the command we provide to run you must `cd` into the directory containing the dockerfile (note the trailing dot `.` in the command which stands for the current directory).

Please note that in all the commands we provide below anything in between less-than and greater-than (`<, >`) symbols are parameters that need to be filled by you! Take a look at the dockerfile before building it to tailor it to your needs and filling in the information regarding `git`, especially the user name.

```bash
docker build -t <image_name> --build-arg <arg_name>=<arg_value> [--build-arg ...] .
```

After building the image you can run it with:

```bash
docker run -v /path/to/host/folder:/path/to/container/folder -it --name <container_name> <image_name> bash
```
