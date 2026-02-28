# Waybar Process-Compose Status Module — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a per-product Waybar custom module that shows online/degraded/offline status of process-compose dev stacks.

**Architecture:** A reusable shell script (`pc-status`) parameterized by product name, port, and core process list. Each product is a separate `custom/<name>` Waybar module calling this script. Initially only Agility is wired up.

**Tech Stack:** Nix (home-manager), Bash, jq, process-compose CLI, Waybar custom modules, GTK CSS

---

### Task 1: Add the `pcStatus` script to `default.nix`

**Files:**

- Modify: `modules/hm/wms/waybar/default.nix:8-54` (add script in the `let` block after `webcamStatus`)

**Step 1: Add the script definition**

Insert after the `webcamStatus` script (after line 54), before the `in` on line 55:

```nix
  pcStatus = pkgs.writeShellScript "pc-status" ''
    LABEL="$1"
    PORT="$2"
    PROCS="$3"

    # Try to reach process-compose
    OUTPUT=$(${pkgs.process-compose}/bin/process-compose process list -o json -p "$PORT" 2>/dev/null) || {
      echo '{"text": "'"$LABEL"': 󱎘", "tooltip": "'"$LABEL"': process-compose not running", "class": "offline"}'
      exit 0
    }

    IFS=',' read -ra PROC_LIST <<< "$PROCS"
    total=0
    running=0
    lines=""

    for proc in "''${PROC_LIST[@]}"; do
      status=$(echo "$OUTPUT" | ${pkgs.jq}/bin/jq -r --arg name "$proc" '.[] | select(.name == $name) | .status // "Unknown"')
      if [ -z "$status" ]; then
        status="Not Found"
      fi
      total=$((total + 1))
      if [ "$status" = "Running" ]; then
        running=$((running + 1))
        lines="''${lines}  ✓ ''${proc}\n"
      else
        lines="''${lines}  ✗ ''${proc} (''${status})\n"
      fi
    done

    if [ "$running" -eq "$total" ]; then
      class="online"
      icon="󰐾"
    elif [ "$running" -gt 0 ]; then
      class="degraded"
      icon="󰍷"
    else
      class="offline"
      icon="󱎘"
    fi

    tooltip="''${LABEL} [''${running}/''${total}]\n''${lines}"
    # Escape for JSON
    tooltip=$(echo -e "$tooltip" | ${pkgs.jq}/bin/jq -Rs '.')

    echo "{\"text\": \"''${LABEL}: ''${icon}\", \"tooltip\": ''${tooltip}, \"class\": \"''${class}\"}"
  '';
```

**Step 2: Verify the nix expression parses**

Run: `cd /home/anthony/nix-config && nix eval --raw .#homeConfigurations --show-trace 2>&1 | head -5`

If parse errors, fix syntax. The tricky parts are `''${` for bash variable interpolation inside nix strings.

**Step 3: Commit**

```bash
git add modules/hm/wms/waybar/default.nix
git commit -m "feat(waybar): add reusable pc-status script for process-compose monitoring"
```

---

### Task 2: Add the `custom/agility` Waybar module config

**Files:**

- Modify: `modules/hm/wms/waybar/default.nix:85-97` (modules-right list)
- Modify: `modules/hm/wms/waybar/default.nix:149-157` (after webcam module config)

**Step 1: Add `custom/agility` to modules-right**

In the `modules-right` list (line 85), add `"custom/agility"` before `"group/tray-expander"`:

```nix
          modules-right = [
            "custom/agility"
            "group/tray-expander"
            "custom/lock"
            ...
          ];
```

**Step 2: Add the module configuration**

After the `custom/webcam` block (after line 157), add:

```nix
          "custom/agility" = {
            exec = "${pcStatus} AGI 8088 backend,frontend,postgres,zitadel,openfga,rustfs,mailpit";
            return-type = "json";
            interval = 5;
          };
```

**Step 3: Commit**

```bash
git add modules/hm/wms/waybar/default.nix
git commit -m "feat(waybar): wire up custom/agility module for process-compose status"
```

---

### Task 3: Add CSS styling for the process-compose modules

**Files:**

- Modify: `modules/hm/wms/waybar/waybar.css:200-203` (append before `.hidden`)

**Step 1: Add CSS for the three states**

Insert before `.hidden` (line 200):

```css
#custom-agility {
  margin: 0 4px;
}

#custom-agility.online {
  color: @base0B;
}

#custom-agility.degraded {
  color: @base0A;
}

#custom-agility.offline {
  color: @base03;
}
```

**Step 2: Commit**

```bash
git add modules/hm/wms/waybar/waybar.css
git commit -m "feat(waybar): add CSS for process-compose status module states"
```

---

### Task 4: Test end-to-end

**Step 1: Rebuild home config**

Run: `home-manager switch --flake /home/anthony/nix-config` (or however the user rebuilds)

**Step 2: Verify Waybar shows the module**

- With agility process-compose running on port 8088: should show "AGI: 󰐾" in green
- Stop process-compose: should show "AGI: 󱎘" dimmed

**Step 3: Verify tooltip**

Hover over the module — should show per-process breakdown like:

```
AGI [7/7]
  ✓ backend
  ✓ frontend
  ✓ postgres
  ...
```

**Step 4: If all working, final commit with any fixes**

---

### Adding future products

To add Lethality later, only two changes needed:

1. In `modules-right`, add `"custom/lethality"`
2. Add module config:

```nix
"custom/lethality" = {
  exec = "${pcStatus} LTH <port> proc1,proc2,...";
  return-type = "json";
  interval = 5;
};
```

3. Add CSS block for `#custom-lethality` (same pattern as agility)
