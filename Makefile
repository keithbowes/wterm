
include config.mk

SRC=src
WLDSRC=$(SRC)/wld

# check_pkg($package, $min_version)
check_pkg=$(if $(shell pkg-config --atleast-version=$2 $1 && echo No),echo "Found $1 $(shell pkg-config --modversion $1)",$(error Couldn't find package $1, version $2 or higher))

PKGS = fontconfig wayland-client wayland-cursor wayland-protocols:1.12 wayland-scanner:1.14.91 xkbcommon pixman-1

WTERM_SOURCES += $(wildcard $(SRC)/*.c)
WTERM_HEADERS += $(wildcard $(SRC)/*.h)

ifneq ($(findstring drm,$(WAYLAND_INTERFACES)),)
PKGS += libdrm
ifneq ($(findstring intel,$(DRM_DRIVERS)),)
PKGS += libdrm_intel
endif
ifneq ($(findstring nouveau,$(DRM_DRIVERS)),)
PKGS += libdrm_nouveau
endif
endif

CFLAGS += -std=gnu99 -Wall
CFLAGS += $(shell pkg-config --cflags $(shell echo $(PKGS) | sed -e 's/:\S\+//g')) -I include
LDFLAGS = $(shell pkg-config --libs $(shell echo $(PKGS) | sed -e 's/:\S\+//g')) -lm -lutil -L src/wld -lwld

ifneq ($(ENABLE_DEBUG),0)
CFLAGS += -g -DENABLE_DEBUG
endif

WAYLAND_HEADERS = include/xdg-shell-client-protocol.h
WAYLAND_SRC = $(WAYLAND_HEADERS:.h=.c)
SOURCES = $(WTERM_SOURCES) $(WAYLAND_SRC)

OBJECTS = $(SOURCES:.c=.o)

BIN_PREFIX = $(PREFIX)
SHARE_PREFIX = $(PREFIX)

.PHONY: all check wld clean install-icons install-bin install uninstall-icons
	uninstall-bin uninstall format 
all: wld wterm

check:
	@$(foreach pkg,$(PKGS),$(call check_pkg,$(shell echo $(pkg) | cut -d ':' -f 1),$(shell echo $(pkg) | cut -d ':' -f 2));)

include/config.h:
	cp config.def.h include/config.h

xdg_shell_protocol=$(shell pkg-config --variable=pkgdatadir wayland-protocols)/stable/xdg-shell/xdg-shell.xml
include/xdg-shell-client-protocol.c: $(xdg_shell_protocol)
	wayland-scanner private-code < $? > $@

include/xdg-shell-client-protocol.h: $(xdg_shell_protocol)
	@$(MAKE) check
	wayland-scanner client-header < $? > $@

$(OBJECTS): $(WAYLAND_HEADERS) include/config.h

wterm: $(OBJECTS)
	$(CC) -o wterm $(OBJECTS) $(LDFLAGS)

wld:
	make -C src/wld

clean:
	rm -f $(OBJECTS) $(WAYLAND_HEADERS) $(WAYLAND_SRC) wterm
	make -C src/wld clean

install-icons:
	mkdir -p $(SHARE_PREFIX)/share/icons/hicolor/scalable/apps/
	cp contrib/logo/wterm.svg $(SHARE_PREFIX)/share/icons/hicolor/scalable/apps/wterm.svg
	mkdir -p $(SHARE_PREFIX)/share/icons/hicolor/128x128/apps/
	cp contrib/logo/wterm.png $(SHARE_PREFIX)/share/icons/hicolor/128x128/apps/wterm.png

install-bin: wterm
	tic -s wterm.info
	mkdir -p $(BIN_PREFIX)/bin/
	cp wterm $(BIN_PREFIX)/bin/

install: install-bin install-icons

uninstall-icons:
	rm -f $(SHARE_PREFIX)/share/icons/hicolor/128x128/apps/wterm.png
	rm -f $(sHARE_PREFIX)/share/icons/hicolor/scalable/apps/wterm.svg

uninstall-bin:
	rm -f $(BIN_PREFIX)/bin/wterm

uninstall: uninstall-bin uninstall-icons

format:
	clang-format -i $(WTERM_SOURCES) $(WTERM_HEADERS)
