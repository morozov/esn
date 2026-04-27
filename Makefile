FPC      := fpc
export COMPILE_DATE := $(shell date '+%a, %d %b %Y at %H:%M:%S %Z')
export VERSION      ?= 1.15-dev
# -Fcutf8: source codepage is UTF-8 (literals tagged CP_UTF8).
# -vm4104,4105: silence implicit AnsiString<->UnicodeString
# conversion warnings. TUI procedures take UnicodeString; many
# callers still hold AnsiString-CP_UTF8 (filenames, panel data).
# The conversions are byte-correct on all supported platforms;
# the warnings would otherwise drown out genuine issues.
FPCFLAGS := -Sd -O2 -gl -Sc -Sm -Sewn -vewnhi -Fcutf8 -vm4104,4105

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
SOURCES  := $(wildcard $(SRCDIR)/*.pas) \
            $(wildcard $(LIBDIR)/rv/*.pas) \
            $(wildcard $(LIBDIR)/rv/*.inc) \
            $(wildcard $(LIBDIR)/fpc/rtl-console/src/inc/*.inc) \
            $(wildcard $(LIBDIR)/fpc/rtl-console/src/inc/*.pp) \
            $(wildcard $(LIBDIR)/fpc/rtl-console/src/unix/*.pp) \
            $(wildcard $(LIBDIR)/fpc/rtl-console/src/win/*.pp) \
            $(wildcard $(LIBDIR)/fpc/rtl-unicode/src/inc/*.pp) \
            $(wildcard $(LIBDIR)/fpc/rtl-unicode/src/inc/*.inc)

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

.PHONY: all clean test unit-test integration-test

all: $(BINARY)

$(BINARY): $(SOURCES)
	@mkdir -p $(BINDIR)
	$(FPC) $(FPCFLAGS) -B -FU$(BINDIR) -FE$(BINDIR) -Fu$(LIBDIR)/rv $(FPCVIDEO) $(MAIN)

test: unit-test integration-test

unit-test: $(BINARY)
	$(MAKE) -C tests/unit

integration-test: $(BINARY)
	bash tests/integration/run_tests.sh

clean:
	rm -f $(BINDIR)/esn $(BINDIR)/esn.exe $(BINDIR)/*.o $(BINDIR)/*.ppu $(BINDIR)/*.res \
	     $(BINDIR)/ppaslink.sh
	$(MAKE) -C tests/unit clean
