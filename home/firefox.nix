{ pkgs, ... }:
{
  programs = {
    firefox = {
      policies = {
        SecurityDevices = {
          Add = {
            "Yubikey/Smartcard" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
          };
        };
        ExtensionSettings =
          with pkgs.nur.repos.rycee.firefox-addons;
          builtins.mapAttrs
            (_: install_url: {
              installation_mode = "force_installed";
              inherit install_url;
            })
            {
              "${vimium.addonId}" = "${vimium.src.url}";
              "${darkreader.addonId}" = "${darkreader.src.url}";
              "${bitwarden.addonId}" = "${bitwarden.src.url}";
              "${ublock-origin.addonId}" = "${ublock-origin.src.url}";
              "${privacy-badger.addonId}" = "${privacy-badger.src.url}";
            };
      };
      profiles.anthony = {
        search = {
          force = true;
          default = "google";
          order = [
            "google"
          ];
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };
            "bing".metaData.hidden = true;
            "google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
          };
        };

        bookmarks = {
          force = true;
          settings = [
            {
              name = "Commercial AWS SSO";
              url = "https://d-9067aa9977.awsapps.com/start";
              tags = [
                "work"
                "sso"
              ];
              keyword = "awscom";
            }
            {
              name = "GovCloud AWS SSO";
              url = "https://start.us-gov-home.awsapps.com/directory/d-c267267895#";
              tags = [
                "work"
                "sso"
              ];
              keyword = "awsgov";
            }
            {
              name = "UK AWS SSO";
              url = "https://d-9c676ba495.awsapps.com/start";
              tags = [
                "work"
                "sso"
              ];
              keyword = "awsuk";
            }
            {
              name = "GW AFWERX Admin Login Console";
              url = "https://login.afwerx.dso.mil/auth/admin/gamewarden/console";
              tags = [
                "work"
                "keycloak"
              ];
              keyword = "login";
            }
            {
              name = "GW Dev AFWERX Admin Login Console";
              url = "https://login.dev.afwerx.dso.mil/auth/admin/gamewarden/console";
              tags = [
                "work"
                "keycloak"
              ];
              keyword = "devlogin";
            }
            {
              name = "GW Commercial Admin Login Console";
              url = "https://login.gamewarden.io/auth/admin/gamewarden/console";
              tags = [
                "work"
                "keycloak"
              ];
              keyword = "comlogin";
            }
          ];
        };
        settings = {
          "extensions.autoDisableScopes" = 0;
          "media.webrtc.capture.allow-pipewire" = true;
        };
      };
    };
  };
}
