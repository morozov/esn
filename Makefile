FPC      := fpc
export COMPILE_DATE := $(shell date '+%a, %d %b %Y at %H:%M:%S %Z')
export VERSION      := 1.14
FPCFLAGS := -Sd -O2 -gl -Sc -Sm -Sewn -vewnhi

# On macOS, point FPC at the active SDK so the linker can find libSystem.
UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
  SDK := $(shell xcrun --show-sdk-path 2>/dev/null)
  ifneq ($(SDK),)
    FPCFLAGS += -XR$(SDK)
  endif
endif
SRCDIR   := src
BINDIR   := bin
BINARY   := $(BINDIR)/esn
MAIN     := $(SRCDIR)/esn.pas
LIBDIR   := lib
SOURCES  := $(wildcard $(SRCDIR)/*.pas) $(wildcard $(LIBDIR)/rv/*.pas) $(wildcard $(LIBDIR)/rv/*.inc)

.PHONY: all clean test unit-test integration-test

all: $(BINARY)

$(BINARY): $(SOURCES)
	@mkdir -p $(BINDIR)
	$(FPC) $(FPCFLAGS) -B -FU$(BINDIR) -FE$(BINDIR) -Fu$(LIBDIR)/rv $(MAIN)

test: unit-test integration-test

unit-test: $(BINARY)
	$(MAKE) -C tests/unit

integration-test: $(BINARY)
	bash tests/integration/run_tests.sh

clean:
	rm -f $(BINDIR)/esn $(BINDIR)/esn.exe $(BINDIR)/*.o $(BINDIR)/*.ppu $(BINDIR)/*.res \
	     $(BINDIR)/ppaslink.sh
	$(MAKE) -C tests/unit clean
