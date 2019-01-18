#!/usr/bin/env python3.6

# WARNING: this is an experimental PoC script

import os
import os.path
import re

cwd = os.path.basename(os.getcwd())

try:
    with open("CHECKSUM.SHA512", "r") as f:
        checksum = f.read()
    update_checksum = True
except:
    print("missing CHECKSUM.SHA512 file!")
    update_checksum = False

try:
    with open("CHECKSUM.SHA512.asc", "r") as f:
        signature = f.read()
    update_signature = True
except:
    print("missing CHECKSUM.SHA512.asc file!")
    update_signature = False

with open("drupal-{version}.template".format(version=cwd), "r") as f:
    drupal_template = f.read()

with open("github-{version}.template".format(version=cwd), "r") as f:
    github_template = f.read()

github_formatted_lines = []
drupal_formatted_lines = []
f_notes = open("NOTES", "r")
for line in f_notes:
    formatted_line = line.replace("\n", "")
    github_formatted_line = [ " * " + formatted_line ]
    github_formatted_lines += github_formatted_line
    drupal_formatted_line = [ " <li>" + formatted_line + "</li>" ]
    drupal_formatted_lines += drupal_formatted_line
f_notes.close()
github_notes = "\n".join(github_formatted_lines)
drupal_notes = "\n".join(drupal_formatted_lines)

github_formatted_lines = []
drupal_formatted_lines = []
f_shortlog = open("shortlog-{version}.txt".format(version=cwd), "r")
match_committer = re.compile("^\S.*:$")
def decorate_committer(match):
    return "<strong>" + match.group() + "</strong>" + '\n' + "<ul>"
match_commit = re.compile("^\s.*$")
def decorate_commit(match):
    return "  <li>" + match.group().lstrip() + "</li>"
match_empty_line = re.compile("^$")
def decorate_empty_line(match):
    return "</ul>" + '\n' + "<br>"
for line in f_shortlog:
    formatted_line = line.replace("\n", "")
    github_formatted_lines += [ formatted_line ]
    formatted_line = match_committer.sub(decorate_committer, formatted_line)
    formatted_line = match_commit.sub(decorate_commit, formatted_line)
    formatted_line = match_empty_line.sub(decorate_empty_line, formatted_line)
    drupal_formatted_lines += [ formatted_line ]
github_shortlog = "\n".join(github_formatted_lines)
drupal_shortlog = "\n".join(drupal_formatted_lines)

with open("drupal-{version}.txt".format(version=cwd), "w+") as f:
    drupal = drupal_template.replace("%%NOTES%%", drupal_notes)
    drupal = drupal.replace("%%SHORTLOG%%", drupal_shortlog)
    if update_checksum:
        drupal = drupal.replace("%%CHECKSUM%%", checksum)
    if update_signature:
        drupal = drupal.replace("%%SIGNATURE%%", signature)
    f.write(drupal)

with open("github-{version}.txt".format(version=cwd), "w+") as f:
    github = github_template.replace("%%NOTES%%", github_notes)
    github = github.replace("%%SHORTLOG%%", github_shortlog)
    if update_checksum:
        github = github.replace("%%CHECKSUM%%", checksum)
    if update_signature:
        github = github.replace("%%SIGNATURE%%", signature)
    f.write(github)
