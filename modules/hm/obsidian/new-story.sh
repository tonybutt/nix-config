#!/usr/bin/env bash
if [ $# -lt 1 ]; then
  echo 'usage: new-story "Title" ["one-line premise"]' >&2
  exit 1
fi

title="$1"
premise="${2:-}"
vault="$HOME/Documents/writing"
created=$(date +%F)

slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')
slug="${slug#-}"
slug="${slug%-}"
if [ -z "$slug" ]; then
  echo "error: title produced an empty folder name" >&2
  exit 1
fi

story="$vault/$slug"
if [ -e "$story" ]; then
  echo "error: $story already exists" >&2
  exit 1
fi

mkdir -p "$story"/{Manuscript,Characters,Locations,Events,Factions,Systems,Research}

cat >"$story/$title.md" <<EOF
---
title: $title
premise: "$premise"
created: $created
status: idea
tags: [story]
---

# $title

## Premise

$premise

## Structure

- [[Manuscript]] — scenes and chapters
- Characters, Locations, Events, Factions, Systems — one note per entity
  (create from the templates in \`Templates/\`)
- Research — sources and reference material
EOF

templates="$vault/Templates"
mkdir -p "$templates"

seed() {
  local target="$templates/$1"
  if [ ! -f "$target" ]; then
    cat >"$target"
    echo "seeded template: $target"
  else
    cat >/dev/null
  fi
}

seed "Character.md" <<'EOF'
---
tags: [character]
story:
role:
status: alive
affiliations: []
locations: []
created: <% tp.date.now("YYYY-MM-DD") %>
---

# <% tp.file.title %>

## Appearance

## Personality

## Goals & Motivations

## Secrets

## History

## Relationships
EOF

seed "Location.md" <<'EOF'
---
tags: [location]
story:
region:
type:
factions: []
created: <% tp.date.now("YYYY-MM-DD") %>
---

# <% tp.file.title %>

## Description

## History

## Notable Inhabitants

## Points of Interest
EOF

seed "Event.md" <<'EOF'
---
tags: [event]
story:
aat-event-start-date:
aat-event-end-date:
aat-render-enabled: true
locations: []
characters: []
created: <% tp.date.now("YYYY-MM-DD") %>
---

# <% tp.file.title %>

## What Happened

## Causes

## Consequences
EOF

seed "Scene.md" <<'EOF'
---
tags: [scene]
story:
pov:
setting:
status: draft
plotlines: []
created: <% tp.date.now("YYYY-MM-DD") %>
---

# <% tp.file.title %>

**Goal:**
**Conflict:**
**Outcome:**

---
EOF

echo "created story: $story"
echo "index note:    $story/$title.md"
