# SAS for Clinical Programmers: the lab

Learn clinical SAS programming in your browser, with the programs of the free book
[SAS for Clinical Programmers](https://sas-for-clinical-programmers.pages.dev/) and **DataStep Studio**: step through
a DATA step and watch every variable change, stop inside a macro, and explore the CDISC pilot study data like in
VIEWTABLE.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/datastep-labs/sas-for-clinical-programmers?quickstart=1)

1. Click the button and sign in to GitHub (a free account is enough).
2. Wait a minute or two. VS Code opens in your browser with DataStep Studio, the book's programs and the lab
   [START-HERE.md](START-HERE.md).
3. Connect to your free [SAS OnDemand for Academics](https://welcome.oda.sas.com) account and follow the lab.

You install nothing on your computer. Each free GitHub account includes a monthly amount of codespace time, and
without a payment method you are never charged.

## What is in here

| Folder or file | What |
|---|---|
| [START-HERE.md](START-HERE.md) | The lab: eight stops, about 30 minutes |
| [programs/](programs/) | Every program of the book, named by chapter (`04_first_last.sas` is chapter 4) |
| `.devcontainer/` | The setup of the codespace: Python, Java, SASPy and DataStep Studio |

The study data is not in this repository: [programs/00_setup.sas](programs/00_setup.sas) downloads the CDISC pilot
study (SAS transport files from the [PHUSE scripts repository](https://github.com/phuse-org/phuse-scripts), MIT
licence) into your SAS OnDemand home folder.

## On your own computer

Install [VS Code](https://code.visualstudio.com/) and the extension **DataStep Studio for SAS** from the Extensions
view, then download the programs. The book's [setup chapter](https://sas-for-clinical-programmers.pages.dev/start/setup/)
explains each step.
