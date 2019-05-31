# Sources for squid

module_DATA = \
  modules/Squid.rb \
  modules/SquidErrorMessages.rb \
  modules/SquidACL.rb

client_DATA = \
  clients/squid.rb \
  clients/squid_auto.rb

yncludedir = @yncludedir@/squid
ynclude_DATA = \
  include/squid/store_del.rb \
  include/squid/wizards.rb \
  include/squid/SquidACL_local_functions.rb \
  include/squid/inits.rb \
  include/squid/popup_dialogs.rb \
  include/squid/helper_functions.rb \
  include/squid/dialogs.rb \
  include/squid/complex.rb \
  include/squid/handlers.rb \
  include/squid/helps.rb

scrconf_DATA = \
  scrconf/squid.scr

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/squid.rnc

desktop_DATA = \
  desktop/org.openSUSE.YaST.Squid.desktop

scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-squid.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(schemafiles_DATA) $(desktop_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
