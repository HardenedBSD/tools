#!/bin/csh

git clone git@github.com:HardenedBSD/hardenedBSD.git hardenedBSD.git
if ( $? != 0 ) then
	git clone https://github.com/HardenedBSD/hardenedBSD.git hardenedBSD.git
endif

cd hardenedBSD.git

git remote add freebsd https://github.com/freebsd/freebsd.git
git config --add remote.freebsd.fetch '+refs/notes/*:refs/notes/*'
git fetch freebsd

# FreeBSD upstream repos
git branch --track freebsd/current/master freebsd/master
git branch --track freebsd/10-stable/master freebsd/stable/10
git branch --track freebsd/11-stable/master freebsd/stable/11
git branch --track freebsd/12-stable/master freebsd/stable/12
git branch --track freebsd/10.3-releng/master freebsd/releng/10.3
git branch --track freebsd/11.0-releng/master freebsd/releng/11.0
git branch --track freebsd/11.1-releng/master freebsd/releng/11.1
git branch --track freebsd/11.2-releng/master freebsd/releng/11.2
git branch --track freebsd/12.0-releng/master freebsd/releng/12.0

# HardenedBSD 10-STABLE master branches
git branch --track {,origin/}hardened/10-stable/master
git branch --track {,origin/}hardened/10-stable/master-libressl

# HardenedBSD 10-STABLE topic branches
git branch --track {,origin/}hardened/10-stable/unstable

# HardenedBSD 10.3-RELENG master branches
git branch --track {,origin/}hardened/10.3-releng/master

# HardenedBSD 11.0-RELENG master branch
git branch --track {,origin/}hardened/11.0-releng/master

# HardenedBSD 11.1-RELENG master branch
git branch --track {,origin/}hardened/11.1-releng/master

# HardenedBSD 11.2-RELENG master branch
git branch --track {,origin/}hardened/11.2-releng/master

# HardenedBSD 11-STABLE master branches
git branch --track {,origin/}hardened/11-stable/master
git branch --track {,origin/}hardened/11-stable/master-libressl

# HardenedBSD 11-STABLE topic branches
git branch --track {,origin/}hardened/11-stable/unstable

# HardenedBSD 12-STABLE master branches
git branch --track {,origin/}hardened/12-stable/master
#git branch --track {,origin/}hardened/12-stable/master-libressl

# HardenedBSD 12.0-RELENG master branch
git branch --track {,origin/}hardened/12.0-releng/master

# HardenedBSD master branch
git branch --track {,origin/}hardened/current/master
git branch --track {,origin/}hardened/current/unstable

# HardenedBSD CURRENT topic branches
git branch --track {,origin/}hardened/current/intel-smap
git branch --track {,origin/}hardened/current/segvguard-ng
git branch --track {,origin/}hardened/current/log
