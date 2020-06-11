
include config.mk

SRC=src
WLDSRC=$(SRC)/wld

PKGS = fontconfig wayland-client wayland-cursor wayland-protocols wayland-scanner xkbcommon pixman-1

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

CFLAGS += -std=gnu99 -Wall -g -DWITH_WAYLAND_DRM -DWITH_WAYLAND_SHM
CFLAGS += $(shell pkg-config --cflags $(PKGS)) -I include
LDFLAGS =src/wld/libwld.a $(shell pkg-config --libs $(PKGS)) -lm -lutil

ifneq ($(ENABLE_DEBUG),0)
CFLAGS += -g -DENABLE_DEBUG
endif

WAYLAND_HEADERS = include/xdg-shell-client-protocol.h
WAYLAND_SRC = $(WAYLAND_HEADERS:.h=.c)
SOURCES = $(WTERM_SOURCES) $(WAYLAND_SRC)

OBJECTS = $(SOURCES:.c=.o)

BIN_PREFIX = $(PREFIX)
SHARE_PREFIX = $(PREFIX)

.PHONY: all wld clean install-icons install-bin install uninstall-icons
	uninstall-bin uninstall format 
all: wld wterm

include/config.h:
	cp config.def.h include/config.h

xdg_shell_protocol=$(shell pkg-config --variable=pkgdatadir wayland-protocols)/stable/xdg-shell/xdg-shell.xml
include/xdg-shell-client-protocol.c: $(xdg_shell_protocol)
	wayland-scanner private-code < $? > $@

include/xdg-shell-client-protocol.h: $(xdg_shell_protocol)
	wayland-scanner client-header < $? > $@

$(OBJECTS): $(WAYLAND_HEADERS) include/config.h

wterm: $(OBJECTS)
	$(CC) -o wterm $(OBJECTS) $(LDFLAGS)

wld:
	$(MAKE) -C src/wld

clean:
	rm -f $(OBJECTS) $(WAYLAND_HEADERS) $(WAYLAND_SRC) wterm
	$(MAKE) -C src/wld clean

install-icons:
	mkdir -p $(SHARE_PREFIX)/share/icons/hicolor/scalable/apps/
	cp contrib/logo/wterm.svg $(SHARE_PREFIX)/share/icons/hicolor/scalable/apps/wterm.svg
	mkdir -p $(SHARE_PREFIX)/share/icons/hicolor/128x128/apps/
	cp contrib/logo/wterm.png $(SHARE_PREFIX)/share/icons/hicolor/128x128/apps/wterm.png

install-bin: wterm
	tic -s wterm.info
	mkdir -p $(BIN_PREFIX)/bin/
	cp wterm $(BIN_PREFIX)/bin/

install-man:
	install -d $(SHARE_PREFIX)/share/man/man1
	sed -e "s/VERSION/$(VERSION)/g" < wterm.1 | xz -c > $(SHARE_PREFIX)/share/man/man1/wterm.1.xz

install: install-bin install-icons install-man

uninstall-icons:
	rm -f $(SHARE_PREFIX)/share/icons/hicolor/128x128/apps/wterm.png
	rm -f $(SHARE_PREFIX)/share/icons/hicolor/scalable/apps/wterm.svg

uninstall-bin:
	rm -f $(BIN_PREFIX)/bin/wterm

uninstall-man:
	rm -f $(SHARE_PREFIX)/share/man/man1/wterm.1.xz

uninstall: uninstall-bin uninstall-icons uninstall-man

format:
	clang-format -i $(WTERM_SOURCES) $(WTERM_HEADERS)
