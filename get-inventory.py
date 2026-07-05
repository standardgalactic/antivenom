#!/usr/bin/env python3

from pathlib import Path

ROOT = Path(".")

git_projects = 0
non_git_projects = 0

report = []

for project in sorted(ROOT.iterdir()):

    if not project.is_dir():
        continue

    file_count = 0

    for f in project.rglob("*"):

        if ".git" in f.parts:
            continue

        if f.is_file():
            file_count += 1

    is_git = (project / ".git").exists()

    if is_git:
        git_projects += 1
    else:
        non_git_projects += 1

    report.append(
        (
            file_count,
            project.name,
            is_git
        )
    )

report.sort(reverse=True)

print()
print("PROJECT SUMMARY")
print("================")
print()

print("Git repositories:", git_projects)
print("Non-git directories:", non_git_projects)

print()
print("Largest directories")
print("-------------------")

for files, name, is_git in report[:50]:

    kind = "Git" if is_git else "Non-Git"

    print(
        f"{files:>10,} files   {kind:7}   {name}"
    )