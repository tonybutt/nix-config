{
  pkgs,
  sshKeys,
  apiKey,
  apiSecretHash,
}:
let
  authorizedKeysContent = builtins.concatStringsSep "\n" sshKeys;
in
pkgs.runCommand "opnsense-config" { } ''
  substitute ${./config.xml.template} $out \
    --replace-fail "@SSH_AUTHORIZED_KEYS_BASE64@" "$(echo -n '${authorizedKeysContent}' | ${pkgs.coreutils}/bin/base64 -w0)" \
    --replace-fail "@API_KEY@" "${apiKey}" \
    --replace-fail "@API_SECRET_HASH@" "${apiSecretHash}"
''
