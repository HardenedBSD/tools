#!/bin/csh

git diff origin/master origin/hardened/current/master > /tmp/hbsd-11.diff
git diff origin/stable/10 origin/hardened/10-stable/master > /tmp/hbsd-10.diff

vimdiff /tmp/hbsd-{10,11}.diff
