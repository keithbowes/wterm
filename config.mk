include src/wld/config.mk

VERSION = 0.7

CFLAGS = -DVERSION=\"$(VERSION)\" -D_XOPEN_SOURCE=700

PREFIX=/usr/local
