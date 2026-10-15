{ ... }:
{
  # Declarative Brave/Chromium bookmarks via the ManagedBookmarks enterprise
  # policy. programs.chromium is already enabled (Stylix theming) and writes
  # /etc/brave/policies/managed/extra.json, which Brave honors. The policy
  # renders as a single read-only "Managed" folder on the bookmarks bar;
  # add sibling entries beside Equity for more folders (nesting supported).
  programs.chromium.extraOpts.ManagedBookmarks = [
    { toplevel_name = "Managed"; }
    {
      name = "Tiberius";
      children = [
        {
          name = "Carta";
          url = "https://app.carta.com/";
        }
        {
          name = "TriNet";
          url = "https://identity.trinet.com";
        }
      ];
    }
  ];

  # The Chrome Web Store no longer ships MV2 updates, so its uBlock Origin is
  # frozen; home/home.nix declares Brave's re-hosted build instead. Running
  # both injected the same YouTube scriptlets twice and videos stalled until a
  # hard refresh. Blocklisting the store copy removes it from the profile and
  # keeps it from coming back.
  programs.chromium.extraOpts.ExtensionInstallBlocklist = [
    "cjpalhdlnbpafiamejdnhcphjbkeiagm"
  ];
}
