#!/usr/bin/env bash

mkdir -p .claude/{systems,modules,integrations,pool}
cp -r ~/.claude-cognitive/templates/* .claude/
echo "Claude Cognitive initialized in $(pwd)/.claude"
echo "Edit .claude/CLAUDE.md with your project info"
