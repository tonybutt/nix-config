#!/usr/bin/env bash

mkdir -p .claude/{systems,modules,integrations,pool}
cp -rL ~/.claude-cognitive/templates/* .claude/
chmod -R u+w .claude/
echo "Claude Cognitive initialized in $(pwd)/.claude"
echo "Edit .claude/CLAUDE.md with your project info"
