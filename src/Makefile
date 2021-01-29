# Makefile for handling the compilation of ASM programs.

# Selecting the assembler and linker to use
ASSEMBLER = nasm
LINKER = gcc

# Assembler output format
O_FORMAT = elf64

# Assembly and linking flags
	# Assembly macros:
		# DCKR -> Controls whether %include directives are for the docker or lubuntu environments
		# SFRAME -> If defined forces the creation (and removal) of a stack frame on every subroutine but main
		# MSFRAME -> If defined forces the creation (and removal) of a stack frame on main

	# Common flag configurations:
		# All macros defined (default):
			# Flags -> -dDCKR -dSFRAME -dMSFRAME
			# Defined macros -> DCKR SFRAME MSFRAME
			# Behaviour -> Compile for our docker environment and create stack frames everywhere
		# Compile for lubuntu:
			# Flags -> -dSFRAME -dMSFRAME
			# Defined macros -> SFRAME MSFRAME
			# Behaviour -> Compile for our lubuntu environment and create stack frames everywhere
		# Skip stack frame creation everywhere but main:
			# Flags -> -dDCKR -dMSFRAME
			# Defined macros -> DCKR MSFRAME
			# Behaviour -> Compile for our docker environment and create a stack frame only in main
		# Skip stack frame creation everywhere:
			# Flags -> -dDCKR
			# Defined macros -> DCKR
			# Behaviour -> Compile for our docker environment and don't create stack frames
LFLAGS = -no-pie -g
AFLAGS = -g -dDCKR -dSFRAME -dMSFRAME

# Source files to compile (without the extension)
FNAMES = main user_stuff comp_stuff output_msgs

# Adding the suitable extensions
SRCS = $(addsuffix .asm, $(FNAMES))
PROGS = $(addsuffix .ex, $(FNAMES))
OBJS = $(addsuffix .o, $(FNAMES))

# Trash files we want to clean
TRASH = *.o *.ex

# Detect the current Kernel to adjust the output format
# Check possible formats with -> 'nasm -hf'
ifeq ($(OS), WINDOWS_NT)
	$(error Cannot compile on Windows)
else
	k_type = $(shell uname -s)
	ifeq ($(k_type), Darwin)
		O_FORMAT = macho64
	endif
endif

# Avoid make erasing intermediate files as seen below
	# https://stackoverflow.com/questions/15189704/makefile-removes-object-files-for-no-reason
# .PRECIOUS: %.o

# Compile all the programs and inform the user of the options used
all: main.ex
	$(info Compiled for the $(k_type) kernel with the $(O_FORMAT) format)

main.ex: $(OBJS)
	$(LINKER) -o $@ $^ $(LFLAGS)

# Assemble any ASM file into an object file
%.o: %.asm
	$(ASSEMBLER) $(AFLAGS) -f $(O_FORMAT) -o $@ $<

.PHONY: clean respect_specs clean_fixed

clean: clean_fixed
	rm -f $(TRASH)

# Modify the path for the included libraries through the linked script
respect_specs:
	./tidy_up.sh $(SRCS)

# We need to redirect ls's STDERR to /dev/null in case there are no "fixed" files to clean
# as we don't want to mess up make's output that much... In case there are no files to be
# cleaned we'll just issue an 'rm -f' with nothing to delete. 
clean_fixed:
	rm -f $(shell ls *_fixed.asm 2> /dev/null)
