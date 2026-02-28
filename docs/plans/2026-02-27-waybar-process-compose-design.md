# Waybar Process-Compose Status Module

## Problem

Need a Waybar indicator showing whether local dev product stacks (managed by process-compose) are online/offline.

## Design

### Reusable script: `pc-status`

A single shell script parameterized by:

- **Product name** — display label (e.g., "Agility")
- **Port** — process-compose API port (e.g., 8088)
- **Core processes** — comma-separated list of processes to monitor

The script:

1. Calls `process-compose process list -o json -p <port>`
2. If unreachable → output offline state
3. If reachable → filter to core processes, count Running vs total
4. Output Waybar JSON: `{"text": "<label>: <icon>", "tooltip": "<per-process breakdown>", "class": "<status>"}`

### CSS classes

- `online` — all core processes running (green)
- `degraded` — some processes down (yellow)
- `offline` — process-compose not reachable (dim/red)

### Waybar modules

Each product gets its own `custom/<name>` module:

```nix
"custom/agility" = {
  exec = "${pcStatus} Agility 8088 backend,frontend,postgres,zitadel,openfga,rustfs,mailpit";
  return-type = "json";
  interval = 5;
};
```

Adding a new product (e.g., Lethality) is ~5 lines of Nix with a new port and process list.

### Placement

Added to `modules-right` in the bar, near network/system indicators.

### Files changed

- `modules/hm/wms/waybar/default.nix` — script definition, module config, CSS additions

### Products (initial)

| Product   | Port | Core Processes                                                 |
| --------- | ---- | -------------------------------------------------------------- |
| Agility   | 8088 | backend, frontend, postgres, zitadel, openfga, rustfs, mailpit |
| Lethality | TBD  | TBD (added later)                                              |
