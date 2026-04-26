FPC      := fpc
# See top-level Makefile for -Fcutf8 / -vm4104,4105 rationale.
FPCFLAGS := -Sd -O2 -gl -Sc -Sm -Sewn -vewnhi -Fcutf8 -vm4104,4105

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

# Vendored UnicodeVideo unit (lib/fpc/) — pick the platform driver.
FPCVIDEO := -Fi$(LIBDIR)/fpc/rtl-console/src/inc \
            -Fu$(LIBDIR)/fpc/rtl-unicode/src/inc \
            -Fi$(LIBDIR)/fpc/rtl-unicode/src/inc
ifeq ($(UNAME),Darwin)
  FPCVIDEO += -Fu$(LIBDIR)/fpc/rtl-console/src/unix
else ifeq ($(UNAME),Linux)
  FPCVIDEO += -Fu$(LIBDIR)/fpc/rtl-console/src/unix
else
  FPCVIDEO += -Fu$(LIBDIR)/fpc/rtl-console/src/win
endif

.PHONY: all clean

all: $(RUNNER)
	./$(RUNNER) --all

TESTS := $(wildcard test_*.pas)
SRCS  := $(wildcard $(SRCDIR)/*.pas) $(wildcard $(LIBDIR)/rv/*.pas) $(wildcard $(LIBDIR)/rv/*.inc)

$(RUNNER): run_tests.pas $(TESTS) $(SRCS)
	$(FPC) $(FPCFLAGS) -Fu$(SRCDIR) -Fu$(LIBDIR)/rv $(FPCVIDEO) -FE. run_tests.pas

clean:
	rm -f $(RUNNER) *.o *.ppu *.res ppaslink.sh
