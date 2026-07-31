{
  imports = [
    ./claude-cognitive.nix
    ./team-skills.nix
    ./superpowers.nix
    ./settings.nix
    ./gitnexus
  ];

  config.home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;
}
