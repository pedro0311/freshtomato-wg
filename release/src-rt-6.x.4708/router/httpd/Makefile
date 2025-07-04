include ../common.mak

CFLAGS = -Os -Wall $(EXTRACFLAGS) -Wsign-compare
CFLAGS += -I$(SRCBASE) -I$(SRCBASE)/include -I. -I$(TOP)/shared

ifeq ($(TCONFIG_BCMARM),y)
CFLAGS += -I$(SRCBASE)/shared/bcmwifi/include
CFLAGS += -I$(SRCBASE)/common/include
LIBS += -lgcc_s
endif

ifeq ($(TOMATO_EXPERIMENTAL),1)
export CFLAGS += -DDEBUG_LOGMSG
endif

OBJS = httpd.o cgi.o tomato.o version.o
OBJS += misc.o dhcp.o upgrade.o traceping.o parser.o upnp.o ctnf.o
OBJS += nvram.o log.o webio.o wl.o devlist.o ddns.o config.o bwm.o
OBJS += blackhole.o utf8.o
OBJS += cpuinfo.o

OBJS += iptraffic.o
ifeq ($(TCONFIG_USB),y)
OBJS += usb.o
OBJS += wwan.o
endif

ifeq ($(TCONFIG_NOCAT),y)
OBJS += nocat.o
endif

ifeq ($(TCONFIG_OPENVPN),y)
OBJS += openvpn.o
endif

LIBS += -L$(TOP)/nvram${BCMEX} -lnvram -L$(TOP)/shared -lshared

ifneq ($(TCONFIG_HTTPS),)
LIBS += -L$(TOP)/mssl -lmssl
ifeq ($(TCONFIG_OPENSSL11),y)
CFLAGS += -I$(TOP)/openssl-1.1/include -DUSE_OPENSSL11
LIBS += -L$(TOP)/openssl-1.1 -lssl -lcrypto
ifeq ($(TCONFIG_BCMARM),y)
LIBS += -lpthread
endif
else
CFLAGS += -I$(TOP)/openssl/include
LIBS += -L$(TOP)/openssl -lssl -lcrypto
endif
endif

ifeq ($(TCONFIG_PPTPD),y)
OBJS += pptpd.o
endif

ifeq ($(TCONFIG_WIREGUARD),y)
OBJS += wireguard.o
endif

ifeq ($(TCONFIG_IPERF),y)
OBJS += iperf.o
endif

all: httpd

httpd: $(OBJS)
	@echo " [httpd] CC $@"
	@$(CC) -o $@ $(OBJS) $(LIBS)
ifneq ($(TCONFIG_BCMARM),y)
	$(SIZECHECK)
	$(CPTMP)
endif

install:
	@echo " [httpd] Installing to $(INSTALLDIR)"
	@install -D httpd $(INSTALLDIR)/usr/sbin/httpd
	@$(STRIP) $(INSTALLDIR)/usr/sbin/httpd
	@chmod 0500 $(INSTALLDIR)/usr/sbin/httpd

clean:
	rm -f httpd *.o .*.depend

size: httpd
ifneq ($(TCONFIG_BCMARM),y)
	mipsel-uclibc-nm --print-size --size-sort httpd
endif
	@true

%.o: %.c .%.depend
	@echo " [httpd] CC $@"
	@$(CC) $(CFLAGS) -o $@ -c $<

.%.depend: %.c
	@$(CC) $(CFLAGS) -M $< > $@

-include $(OBJS:%.o=.%.depend)
