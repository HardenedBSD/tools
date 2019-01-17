#!/usr/bin/env python3.6

import os
import os.path

cwd = os.path.basename(os.getcwd())

with open("CHECKSUM.SHA512", "r") as f:
    checksum = f.read()

with  open("CHECKSUM.SHA512.asc", "r") as f:
    signature = f.read()

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

github_text = "\n".join(github_formatted_lines)
drupal_text = "\n".join(drupal_formatted_lines)

with open("drupal-{version}.txt".format(version=cwd), "w+") as f:
    drupal = (drupal_template
                .replace("%%NOTES%%", drupal_text)
                .replace("%%CHECKSUM%%", checksum)
                .replace("%%SIGNATURE%%", signature)
                )
    f.write(drupal)

with open("github-{version}.txt".format(version=cwd), "w+") as f:
    github = (github_template
                .replace("%%NOTES%%", github_text)
                .replace("%%CHECKSUM%%", checksum)
                .replace("%%SIGNATURE%%", signature)
                )
    f.write(github)
