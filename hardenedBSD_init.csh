#!/bin/csh

git clone git@github.com:HardenedBSD/hardenedBSD.git hardenedBSD.git
cd hardenedBSD.git

git remote add freebsd https://github.com/freebsd/freebsd.git
git fetch freebsd

# FreeBSD upstream repos
git branch --track {,freebsd/}master
git branch --track {,freebsd/}stable/10

# HardenedBSD master branch
git branch --track {,origin/}hardened/current/master

# HardenedBSD 10-STABLE topic branches
git branch --track {,origin/}hardened/10/aslr
git branch --track {,origin/}hardened/10/paxctl

# HardenedBSD CURRENT topic branches
git branch --track {,origin/}hardened/current/aslr
git branch --track {,origin/}hardened/current/hardening
git branch --track {,origin/}hardened/current/intel-smap
git branch --track {,origin/}hardened/current/paxctl
git branch --track {,origin/}hardened/current/segvguard
git branch --track {,origin/}hardened/current/upstream
git branch --track {,origin/}hardened/current/unstable
git branch --track {,origin/}hardened/current/ptrace
