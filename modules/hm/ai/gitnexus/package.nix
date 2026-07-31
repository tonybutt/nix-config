{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage rec {
  pname = "gitnexus";
  version = "1.6.9";

  # The published npm tarball ships a prebuilt dist/ (with gitnexus-shared
  # inlined) and prebuilt vendored tree-sitter grammar bindings, so we avoid
  # the monorepo TypeScript build entirely.
  src = fetchurl {
    url = "https://registry.npmjs.org/gitnexus/-/gitnexus-${version}.tgz";
    hash = "sha256-Qykvvu3VtXtiWaA6wewk1nK1zP65RVjtAq7IdKqCXbM=";
  };

  # The tarball has no lockfile; vendor the one from the repo tag matching
  # this release (gitnexus/package-lock.json at v${version}).
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-wtUstkRPlwg5cOYXfyBq5l/Ln9V3L8V4Taqhi2x6tAc=";

  # dist/ is already built, and devDependencies include the unpublished
  # monorepo-local gitnexus-shared package.
  dontNpmBuild = true;
  npmFlags = [ "--omit=dev" ];

  env.SCARF_ANALYTICS = "false";
  # onnxruntime-node bundles the linux CPU binaries; its postinstall only
  # downloads CUDA/DML extras from nuget, which the sandbox can't reach.
  env.ONNXRUNTIME_NODE_INSTALL = "skip";

  meta = {
    description = "Client-side code knowledge graph creator with MCP integration for AI agents";
    homepage = "https://github.com/abhigyanpatwari/GitNexus";
    license = lib.licenses.mit;
    mainProgram = "gitnexus";
    platforms = lib.platforms.linux;
  };
}
