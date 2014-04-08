#!/bin/csh

git clone git@github.com:hardenedBSD/hardenedBSD.git hardenedBSD.git
cd hardenedBSD.git
git remote add freebsd https://github.com/freebsd/freebsd.git
git fetch freebsd
git checkout -b stable/10 freebsd/stable/10
git checkout -b hardened/10/aslr stable/10
git checkout -b hardened/10/paxctl stable/10
git checkout -b hardened/current/aslr master
git checkout -b hardened/current/paxctl master
