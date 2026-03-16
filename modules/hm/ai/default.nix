{
  imports = [
    ./claude-cognitive.nix
    ./team-skills.nix
    ./superpowers.nix
    ./settings.nix
  ];

  config.home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;
}
