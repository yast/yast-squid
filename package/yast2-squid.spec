#
# spec file for package yast2-squid
#
# Copyright (c) 2015 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-squid
Version:        3.1.5
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Requires:       yast2 >= 2.21.22
BuildRequires:  boost-devel
BuildRequires:  gcc-c++
BuildRequires:  libtool
BuildRequires:  perl-XML-Writer
BuildRequires:  update-desktop-files
BuildRequires:  yast2
BuildRequires:  yast2-core-devel
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  yast2-testsuite

#BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:        Configuration of squid
License:        GPL-2.0
Group:          System/YaST

%description
Configuration of squid

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install

rm -rf %{buildroot}/%{yast_plugindir}/libpy2ag_squid.la

%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/squid
%config /etc/sysconfig/SuSEfirewall2.d/services/squid
%{yast_yncludedir}/squid/*
%{yast_clientdir}/squid.rb
%{yast_clientdir}/squid_*.rb
%{yast_moduledir}/Squid.*
%{yast_moduledir}/SquidACL.*
%{yast_moduledir}/SquidErrorMessages.*
%{yast_desktopdir}/squid.desktop
%{yast_schemadir}/autoyast/rnc/squid.rnc

%{yast_plugindir}/libpy2ag_squid.so*
%{yast_scrconfdir}/*.scr
%doc %{yast_docdir}

%changelog
