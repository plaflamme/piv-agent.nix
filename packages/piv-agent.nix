{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  pcsclite,
}:
buildGoModule (finalAttrs: {
  pname = "piv-agent";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "smlx";
    repo = "piv-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-j8u6/Hn6v2OMCTks6O/r4SpBoTvaOl/M7r6GYgECUpw=";
  };

  vendorHash = "sha256-RezpLJzSL6TfS60DJOdznLKLPUdFcqTBZBQxw5UWavM=";

  subPackages = [
    "cmd/age-plugin-piv-agent"
    "cmd/piv-agent"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X main.projectName=piv-agent"
    "-X main.version=${finalAttrs.version}"
    "-X main.commit=${finalAttrs.src.rev}"
  ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pcsclite ];

  meta = {
    description = "SSH and age agent for PIV hardware security devices (e.g. a Yubikey)";
    homepage = "https://github.com/smlx/piv-agent";
    changelog = "https://github.com/smlx/piv-agent/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "piv-agent";
  };
})
