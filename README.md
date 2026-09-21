# BASH SCRIPTING

A collection of Bash scripting projects focused on Linux automation, system monitoring, and practical DevOps/DevSecOps learning.

## Project 1 — Log Analyzer

A Bash script that analyzes `system.log` and `application.log` by:

* Checking log files
* Detecting `ERROR`, `CRITICAL`, `FATAL`, `WARNING`, and `EXCEPTION` tags
* Counting occurrences
* Displaying the relevant log entries
* Showing visual snapshots for log analysis

**Concepts used:** Variables, Arrays, Loops, Conditions, Functions, `grep`, Command Substitution, and File Handling.

## Project 2 — System Health Checker & Analyzer

A Bash script that checks the current health of a Linux system and generates a timestamped report. It monitors and reports on:

* System information: hostname, OS, kernel, architecture, and uptime
* CPU usage, core count, and load average
* Memory usage and status
* Disk usage for mounted filesystems and root partition
* Top CPU and memory consuming processes
* Network connectivity status and active interfaces
* Service status for `ssh`, `cron`, and `docker`
* Largest directories under `/home`
* Overall health summary with `HEALTHY`, `WARNING`, or `CRITICAL` status

The script automatically creates a `reports/` folder and saves the full output to a file named like:

* `reports/health_report_YYYY-MM-DD_HH-MM-SS.log`

It also prints the same report in the terminal using `tee`, so the output is visible immediately and saved for later review.

**Concepts used:** Variables, Arrays, Loops, Conditional Logic, Functions, Arithmetic, `ps`, `df`, `free`, `top`, `ping`, `ip`, `du`, `awk`, `sed`, `grep`, `tee`, and File/Directory Handling.

## 🚧 More Projects Coming

This repository is an ongoing collection of Bash scripting and automation projects that I will continue building as I progress toward **DevOps and DevSecOps**.
