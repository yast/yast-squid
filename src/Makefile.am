# Makefile.am for squid/src

yncludedir = @yncludedir@/squid

client_DATA =			\
	squid.ycp		\
	squid_auto.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
    popup_dialogs.ycp \
	complex.ycp \
    inits.ycp \
    store_del.ycp \
	SquidACL_local_functions.ycp \
    helper_functions.ycp \
    handlers.ycp

desktop_DATA =			\
	squid.desktop

module_DATA =			\
	Squid.ycp		\
    SquidACL.ycp \
    SquidErrorMessages.ycp

# create a symlink for local build, #145327
squid:
	ln -sf . $@
ycpchook = squid

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
