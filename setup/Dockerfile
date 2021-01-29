# Pull a vanilla ubuntu image as a base to build upon
FROM ubuntu

# Install the necessary packages:
	# nasm -> The assembler we are going to use
	# gcc -> We'll use it for linking our object files
	# gdb -> Get the GNU debugger in case we need it
	# make -> It'll let us build things much faster
	# git -> Work with repositories out of the box
RUN \
	apt-get update && \
	apt-get install -y nasm && \
	apt-get install -y gcc && \
	apt-get install -y gdb && \
	apt-get install -y make && \
	apt-get install -y git

# Configure git credentials (docker build doesn't like spaced words...)
# Use 'docker build -t <image_name> --build-arg <arg_name>=<arg_value> [--build-arg ...] .'
	# From the directory containing the image to built it!
ARG email
ARG username

RUN git config --global user.name "Your Name"
RUN git config --global user.email ${email}
RUN git config --global credential.username ${username}

# Set root's home directory
ENV HOME /root

# Get our aliases ready
RUN echo "alias x='exit'\nalias c='clear'" > /root/.bashrc

# Manually clone the repository OR mount a volume with a folder in your machine.
	# You can do so with -> 'docker run -v /path/to/host/folder:/path/to/container/folder -it --name <container_name> <image_name> bash'

# In order to start the container you can do -> 'docker start -ai <container_name>'
	# Or if it's running just do -> 'docker attach <container_name>'

# Default command at startup is to just open a shell
CMD ["bash"]
