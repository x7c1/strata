#!/bin/bash

# Get open pull requests for the current branch
gh pr list --state open --head $(git branch --show-current) --json number,title,url
