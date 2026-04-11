FPC      := fpc
FPCFLAGS := -Sd -O2 -gl -Sc -Sm -Sewn -vewnhi

UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
  SDK := $(shell xcrun --show-sdk-path 2>/dev/null)
  ifneq ($(SDK),)
    FPCFLAGS += -XR$(SDK)
  endif
endif

SRCDIR := ../../src
LIBDIR := ../../lib
RUNNER := run_tests

.PHONY: all clean

all: $(RUNNER)
	./$(RUNNER) --all

SRCS := $(wildcard $(SRCDIR)/*.pas) $(wildcard $(LIBDIR)/rv/*.pas) $(wildcard $(LIBDIR)/rv/*.inc)

$(RUNNER): run_tests.pas test_trd.pas test_tap.pas test_scl.pas test_pc.pas test_resize.pas $(SRCS)
	$(FPC) $(FPCFLAGS) -Fu$(SRCDIR) -Fu$(LIBDIR)/rv -FE. run_tests.pas

clean:
	rm -f $(RUNNER) *.o *.ppu *.res ppaslink.sh
