{
  imports = [
    ./team-skills.nix
    ./superpowers.nix
    ./mattpocock-skills.nix
    ./settings.nix
    ./gitnexus
  ];

  config = {
    home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;

    modules.ai.claude-settings.autoMemoryEnabled = false;

    modules.ai.claude-settings.permissions.allow = [
      "Bash(echo:*)"
      "Bash(cat:*)"
      "Bash(head:*)"
      "Bash(printf:*)"
      "Bash(grep:*)"
      "Bash(nix fmt:*)"
      "Bash(nh os build:*)"
      "Bash(nh os switch:*)"
      "Bash(nh home build:*)"
      "Bash(nh home switch:*)"
      "Bash(git status:*)"
      "Bash(git diff:*)"
      "Bash(git log:*)"
      "Bash(git add:*)"
      "Bash(git commit:*)"
      "Bash(git restore:*)"
      "WebFetch(domain:raw.githubusercontent.com)"
      "mcp__figma__get_design_context"
      "mcp__figma__get_screenshot"
    ];
  };
}
