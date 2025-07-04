include ../common.mak

CFLAGS	= -Os -Wall $(EXTRACFLAGS) -Wsign-compare
CFLAGS	+= -I$(SRCBASE)/include -I$(TOP)/shared -ffunction-sections -fdata-sections
LDFLAGS	= -ffunction-sections -fdata-sections -Wl,--gc-sections

ifeq ($(TOMATO_EXPERIMENTAL),1)
export CFLAGS += -DDEBUG_LOGMSG
endif

ifeq ($(TCONFIG_BCMARM),y)
LIBS += -lgcc_s
endif

OBJS = rstats.o

all: rstats

rstats: $(OBJS)
	@echo " [rstats] CC -o $@"
ifeq ($(TCONFIG_BCMARM),y)
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS) -L../nvram${BCMEX} -lnvram -L../shared -lshared $(LIBS)
else
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS) -L../nvram -lnvram -L../shared -lshared
endif

	$(SIZECHECK)
	$(CPTMP)

clean:
	rm -f rstats .*.depend
	rm -f *.o

install: all
	@echo " [rstats] Installing..."
	install -D rstats $(INSTALLDIR)/bin/rstats
	$(STRIP) $(INSTALLDIR)/bin/rstats
	chmod 0500 $(INSTALLDIR)/bin/rstats

%.o: %.c .%.depend
	@echo " [rstats] CC $@"
	@$(CC) $(CFLAGS) -c $<

.depend: $(OBJS:%.o=%.c)
	@$(CC) $(CFLAGS) -M $^ > .depend

.%.depend: %.c
	@$(CC) $(CFLAGS) -M $< > $@

-include $(OBJS:%.o=.%.depend)
