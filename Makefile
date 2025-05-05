# Makefile for Linux, WSL, macOS

# Tools
AR         = ar
CC         = clang
CXX        = clang++
VALGRIND   = valgrind
PKGCONFIG  = pkg-config
RM         = rm -rf
MKDIR      = mkdir -p

# Project layout
NAME       = reim
OUTDIR     = build
SRCDIR     = src
EXAMDIR    = example
TESTDIR    = test

# Targets
LIBRARY    = $(OUTDIR)/lib$(NAME).a
EXAMBIN    = $(OUTDIR)/$(NAME)_example
TESTBIN    = $(OUTDIR)/$(NAME)_test

# External packages
PKGS       = sndfile portaudio-2.0

# Optional MKL / FFT support (uncomment to use)
# FFTFLAG  = -DREIM_USE_FFTW3
# MKLPATH  = /opt/intel/compilers_and_libraries/linux/mkl/
# MPIPATH  = /opt/intel/compilers_and_libraries/linux/mpi/intel64/
# MKLINC   = -I$(MKLPATH)include -I$(MPIPATH)include
# MKLLIB   = -L$(MKLPATH)lib/intel64 -fopenmp -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -lpthread -lm -ldl
# FFTFLAG  = -DREIM_USE_MKL

# Flags
INCLUDE    = -Iinclude $(MKLINC)
LIBS       = -lm $(shell $(PKGCONFIG) --libs $(PKGS)) $(MKLLIB)
CFLAGS     = -MMD -MP -O3 -Wall -Wextra -std=c99 $(INCLUDE) $(shell $(PKGCONFIG) --cflags $(PKGS)) $(FFTFLAG)
CXXFLAGS   = -MMD -MP -O3 -Wall -Wextra -std=c++11 $(INCLUDE) $(shell $(PKGCONFIG) --cflags $(PKGS)) $(FFTFLAG)
LDFLAGS    = $(LIBS)

# Sources and objects
SRCS       = $(wildcard $(SRCDIR)/*.c)
EXAMSRCS   = $(wildcard $(EXAMDIR)/*.c)
TESTSRCS   = $(wildcard $(TESTDIR)/*.cc)

OBJS       = $(patsubst $(SRCDIR)/%.c, $(OUTDIR)/$(SRCDIR)/%.o, $(SRCS))
EXAMOBJS   = $(patsubst $(EXAMDIR)/%.c, $(OUTDIR)/$(EXAMDIR)/%.o, $(EXAMSRCS))
TESTOBJS   = $(patsubst $(TESTDIR)/%.cc, $(OUTDIR)/$(TESTDIR)/%.o, $(TESTSRCS))

.PHONY: all lib run test memcheck clean check

all: $(LIBRARY) $(EXAMBIN) $(TESTBIN)

lib: $(LIBRARY)

run: $(EXAMBIN)
	$(EXAMBIN)

test check: $(TESTBIN)
	$(TESTBIN)

memcheck: $(EXAMBIN)
	$(VALGRIND) --leak-check=full --track-origins=yes $(EXAMBIN)

clean:
	$(RM) $(OUTDIR)

# Build rules

$(LIBRARY): $(OBJS) | $(OUTDIR)
	$(AR) rcs $@ $^

$(EXAMBIN): $(EXAMOBJS) $(LIBRARY) | $(OUTDIR)
	$(CC) -o $@ $^ $(LDFLAGS)

$(TESTBIN): $(TESTOBJS) $(LIBRARY) | $(OUTDIR)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(OUTDIR)/$(SRCDIR)/%.o: $(SRCDIR)/%.c | $(OUTDIR)/$(SRCDIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(OUTDIR)/$(EXAMDIR)/%.o: $(EXAMDIR)/%.c | $(OUTDIR)/$(EXAMDIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(OUTDIR)/$(TESTDIR)/%.o: $(TESTDIR)/%.cc | $(OUTDIR)/$(TESTDIR)
	$(CXX) -c $< -o $@ $(CXXFLAGS) -Itest/doctest/doctest

# Create output directories
$(OUTDIR):
	$(MKDIR) $@

$(OUTDIR)/$(SRCDIR):
	$(MKDIR) $@

$(OUTDIR)/$(EXAMDIR):
	$(MKDIR) $@

$(OUTDIR)/$(TESTDIR):
	$(MKDIR) $@

# Include dependency files
-include $(OBJS:.o=.d) $(EXAMOBJS:.o=.d) $(TESTOBJS:.o=.d)
