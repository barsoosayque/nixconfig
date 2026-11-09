{ pkgs, ... }:

with pkgs;
let
  version = "1.0.3";
  releaseUrl = "https://projects.blender.org/lab/blender_mcp/releases/download/v${version}";
in
python3Packages.buildPythonApplication {
  pname = "blender-mcp";
  inherit version;
  pyproject = true;

  # The .mcpb bundle is a plain zip of the server, including the docs it serves.
  src = fetchzip {
    url = "${releaseUrl}/blender-${version}.mcpb";
    extension = "zip";
    stripRoot = false;
    hash = "sha256-8ddFxiO9CbsOjIIDtcrHFiqrtcldQkkBYpyDusxUnfw=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies =
    with python3Packages;
    [
      docutils
      # FastMCP is gone in mcp 2.x (renamed MCPServer); upstream still pins mcp<2.
      mcp_1
      pyyaml
    ]
    ++ mcp_1.optional-dependencies.cli;

  pythonImportsCheck = [ "blmcp" ];

  # Companion Blender add-on, installed into Blender itself:
  # blender --command extension install-file -r user_default -e <zip>
  passthru.addon = fetchurl {
    url = "${releaseUrl}/mcp-${version}.zip";
    hash = "sha256-p6nagWGSUC5aCiAqOWRE4ma0fY/E90rUaYBIvUMEBwc=";
  };

  meta = {
    description = "Official Blender Lab MCP server";
    homepage = "https://www.blender.org/lab/mcp-server/";
    license = lib.licenses.gpl3Plus;
    mainProgram = "blender-mcp";
  };
}
