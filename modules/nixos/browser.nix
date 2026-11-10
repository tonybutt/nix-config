{ lib, ... }:
let
  # The only extensions Chromium may run. Anything else, whether installed
  # from the Web Store or an old profile, is removed. Chromium's own component
  # extensions (PDF viewer, Web Store) are unaffected.
  extensions = {
    # Chromium no longer runs MV2, so full uBlock Origin
    # (cjpalhdlnbpafiamejdnhcphjbkeiagm) is out; Lite is its MV3 build.
    ddkjiahejlhfcafbddmgiahcphecmpfh = "uBlock Origin Lite";
    nngceckbapebfimnlniiiahkandclblb = "Bitwarden";
    pkehgijcmpdhfbdbbnkijodmdjhbjlgp = "Privacy Badger";
    damfoaielhjgnodobkkikiaiikkklejb = "Gather Meetings";
    nmgegmkaijcgdgkfjhlbbaoabldoaehj = "Gather 1.0 Meetings (Classic)";
    iaalpfgpbocpdfblpnhhgllgbdbchmia = "Asciidoctor.js Live Preview";
    callobklhcbilhphinckomhgkigmfocg = "Endpoint Verification (Google Workspace)";
    jlmpjdjjbgclbocgajdjefcidcncaied = "daily.dev";
    idefohglmnkliiadgfofeokcpjobdeik = "Ramp for Chrome";
  };
in
{
  # Declarative Chromium bookmarks via the ManagedBookmarks enterprise
  # policy. programs.chromium is already enabled (Stylix theming) and writes
  # /etc/chromium/policies/managed/extra.json. The policy
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

  # Block everything, then force-install the declared set. Before this, a
  # second uBlock Origin installed from the browser's settings ran beside the
  # declared one and stalled YouTube until a hard refresh.
  programs.chromium.extraOpts.ExtensionSettings = {
    "*".installation_mode = "blocked";
  }
  // lib.mapAttrs (_: _: {
    installation_mode = "force_installed";
    update_url = "https://clients2.google.com/service/update2/crx";
  }) extensions;
}
