#!/bin/csh

git clone git@github.com:HardenedBSD/hardenedBSD.git hardenedBSD.git
cd hardenedBSD.git
git remote add freebsd https://github.com/freebsd/freebsd.git
git fetch freebsd
git branch --track master freebsd/master
git branch --track stable/10 freebsd/stable/10
git branch --track hardened/10/aslr origin/hardened/10/aslr
git branch --track hardened/10/paxctl origin/hardened/10/paxctl
git branch --track hardened/current/aslr origin/hardened/current/aslr
git branch --track hardened/current/paxctl origin/hardened/current/paxctl
