{ pkgs, user, ... }:
{
  programs.k9s = {
    enable = true;
    plugins =
      let
        debug-command = pkgs.writeShellApplication {
          name = "debug";
          text = ''
            ${pkgs.kubectl}/bin/kubectl debug -it -n="$NAMESPACE" "$POD" --target="$NAME" --image=nicolaka/netshoot:v0.11 --share-processes -- bash
          '';
        };
        toggle = pkgs.writeShellApplication {
          name = "flux-toggle";
          text = ''
            CONTEXT=$1
            NAMESPACE=$2
            NAME=$3
            RESOURCE=$4
            suspended=$(${pkgs.kubectl}/bin/kubectl --context "$CONTEXT" get helmreleases -n "$NAMESPACE" "$NAME" -o=custom-columns=TYPE:.spec.suspend | tail -1)
            toggle=""
            if [ "$suspended" = "true" ]; then
              toggle="resume"
            else
              toggle="suspend"
            fi
            ${pkgs.fluxcd}/bin/flux "$toggle" --context "$CONTEXT" "$RESOURCE" -n "$NAMESPACE" "$NAME"
          '';
        };
        ssm = pkgs.writeShellApplication {
          name = "ssm";
          runtimeInputs = [ pkgs.ssm-session-manager-plugin ];
          text = ''
            NAME=$1
            CONTEXT=$2
            provider_id=$(${pkgs.kubectl}/bin/kubectl --context "$CONTEXT" get node "$NAME" -o jsonpath='{.spec.providerID}')
            instance_id="''${provider_id##*/}"
            az="''${provider_id%/*}"
            az="''${az##*/}"
            if [[ -z "$instance_id" || "$instance_id" == "None" ]]; then
              echo "⚠️ Could not extract instance ID from providerID"
              read -r -p "Press any key to continue..."
              exit 1
            fi
            # shellcheck disable=SC1091
            source /home/${user.username}/config/2fctl/credentials.sh
            ${pkgs.awscli2}/bin/aws ssm start-session --target "$instance_id"
          '';
        };
        mkToggle = scope: resource: {
          shortCut = "Shift-T";
          description = "Suspend/Resume ${scope}";
          scopes = [ scope ];
          command = "${toggle}/bin/flux-toggle";
          background = true;
          args = [
            "$CONTEXT"
            "$NAMESPACE"
            "$NAME"
            resource
          ];
        };
        mkReconcile = command: resource: force: {
          shortCut = "Shift-${if force != "" then "F" else "R"}";
          confirm = false;
          description = "Flux reconcile";
          scopes = [ "${resource}" ];
          command = "${pkgs.bash}/bin/bash";
          background = true;
          args = [
            "-c"
            "${pkgs.fluxcd}/bin/flux --context $CONTEXT reconcile ${command} -n $NAMESPACE $NAME ${force} |& less"
          ];
        };
      in
      {
        debug = {
          shortCut = "Shift-D";
          description = "Add debug container";
          scopes = [ "containers" ];
          command = "${debug-command}/bin/debug";
          background = false;
          confirm = true;
        };
        dive = {
          shortCut = "d";
          confirm = false;
          description = "Dive Image";
          scopes = [ "containers" ];
          command = "${pkgs.dive}/bin/dive";
          background = false;
          args = [ "$COL-IMAGE" ];
        };
        ssm-shell = {
          shortCut = "s";
          confirm = false;
          description = "Start SSM to EC2";
          scopes = [ "nodes" ];
          background = false;
          command = "${ssm}/bin/ssm";
          args = [
            "$NAME"
            "$CONTEXT"
          ];
        };
        toggle-helmrelease = mkToggle "helmreleases" "hr";
        toggle-ks = mkToggle "kustomizations" "ks";
        reconcile-hr = mkReconcile "hr" "helmreleases" "";
        reconcile-hr-force = mkReconcile "hr" "helmreleases" "--force";
        reconcile-git = mkReconcile "source git" "gitrepositories" "";
        reconcile-helm = mkReconcile "source helm" "helmrepositories" "";
        reconcile-oci = mkReconcile "source oci" "ocirepositories" "";
        reconcile-ks = mkReconcile "ks" "kustomizations" "";
        reconcile-ir = mkReconcile "image repository" "imagerepositories" "";
        reconcile-iua = mkReconcile "image update" "imageupateautomations" "";
      };
  };

}
