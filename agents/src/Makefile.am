#
# Makefile.am for core/agent-ini/src
#

AM_CXXFLAGS = -DY2LOG=\"agent-squid\" -Wall -DNDEBUG

plugin_LTLIBRARIES = libpy2ag_squid.la
noinst_LTLIBRARIES = liby2ag_squid.la

liby2ag_squid_la_SOURCES =	\
	squid_agent.cpp squid_agent.h		\
	squid_parser.cpp squid_parser.h		\
	squid_file.cpp squid_file.h \
    debug.h

liby2ag_squid_la_LDFLAGS = -version-info 2:0
liby2ag_squid_la_LIBADD = @AGENT_LIBADD@

libpy2ag_squid_la_SOURCES =			\
        $(liby2ag_squid_la_SOURCES)		\
        Y2CCSquidAgent.cc

libpy2ag_squid_la_LDFLAGS = -version-info 2:0 \
                            -lboost_regex
libpy2ag_squid_la_LIBADD =			\
	@AGENT_LIBADD@				\
	${Y2UTIL_LIBS}

INCLUDES = -I$(includedir)
