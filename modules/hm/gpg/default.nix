{
  config,
  lib,
  user,
  ...
}:
let
  cfg = config.secondfront.gpg;
  inherit (lib) mkIf mkEnableOption;
in
{
  options = {
    secondfront.gpg.enable = mkEnableOption "Enable GPG" // {
      default = true;
    };
  };
  config = mkIf cfg.enable {
    services.gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      enableZshIntegration = true;

      defaultCacheTtl = 1209600;
      defaultCacheTtlSsh = 1209600;
      maxCacheTtl = 1209600;
      maxCacheTtlSsh = 1209600;

      extraConfig = ''
        allow-preset-passphrase
      '';
    };
    programs.gpg = {
      enable = true;
      scdaemonSettings = {
        reader-port = "Yubico Yubi";
        disable-ccid = true;
      };
      # Use an xdg-compliant directory for GnuPG. This
      # should generally work, but some programs still try
      # to create ~/.gnupg.
      homedir = "${config.home.homeDirectory}/.gnupg";

      settings = {
        # Default/trusted key ID to use (helpful with throw-keyids)
        default-key = user.signingkey;
        trusted-key = user.signingkey;

        keyserver = "hkps://keys.openpgp.org";

        # https://github.com/drduh/config/blob/master/gpg.conf
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html
        # Use AES256, 192, or 128 as cipher
        personal-cipher-preferences = "AES256 AES192 AES";
        # Use SHA512, 384, or 256 as digest
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        # Use ZLIB, BZIP2, ZIP, or no compression
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        # Default preferences for new keys
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        # SHA512 as digest to sign keys
        cert-digest-algo = "SHA512";
        # SHA512 as digest for symmetric ops
        s2k-digest-algo = "SHA512";
        # AES256 as cipher for symmetric ops
        s2k-cipher-algo = "AES256";
        # UTF-8 support for compatibility
        charset = "utf-8";
        # Show Unix timestamps
        fixed-list-mode = "";
        # No comments in messages
        no-comments = "";
        # No version in output
        no-emit-version = "";
        # Disable banner
        no-greeting = "";
        # Long hexadecimal key format
        keyid-format = "0xlong";
        # Display UID validity
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        # Display all keys and their fingerprints
        with-fingerprint = "";
        # Cross-certify subkeys are present and valid
        require-cross-certification = "";
        # Disable caching of passphrase for symmetrical ops
        no-symkey-cache = "";
        # Enable smartcard
        use-agent = "";
        # Output ASCII instead of binary
        armor = "";
        # Disable recipient key ID in messages (breaks Mailvelope)
        throw-keyids = "";
      };

      scdaemonSettings.deny-admin = true;
    };
  };
}
