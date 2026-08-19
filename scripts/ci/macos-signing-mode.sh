#!/usr/bin/env bash
# Decide whether the current macOS build should be code-signed.
#
# Signing is *requested* for tagged releases and for research-edition builds.
# The Apple secrets only exist on the canonical repo, so a fork that builds a
# research edition would otherwise hard-fail and produce no macOS artifact at
# all. Tagged releases still fail loudly: an unsigned public release is not an
# acceptable degradation, an unsigned study build is.
#
# Prints one of: "sign" | "unsigned" | "skip"   (exit 1 = signing required but
# unavailable). Intended use:
#
#   SIGN_MODE=$(./scripts/ci/macos-signing-mode.sh)
set -euo pipefail

REQUIRED_VARS=(
  APPLE_EMAIL
  APPLE_PASSWORD
  APPLE_TEAMID
  CERTIFICATE_MACOS_P12_BASE64
  CERTIFICATE_MACOS_P12_PASSWORD
)

is_tag_release=false
if [[ "${GITHUB_REF:-}" == refs/tags/v* ]]; then
  is_tag_release=true
fi

if [[ "$is_tag_release" != true && "${AW_RESEARCH_EDITION:-}" != "true" ]]; then
  echo "skip"
  exit 0
fi

missing=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    missing+=("$var")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  echo "sign"
  exit 0
fi

if [[ "$is_tag_release" == true ]]; then
  echo "ERROR: missing macOS signing secrets (${missing[*]}) — required for tagged releases" >&2
  exit 1
fi

echo "::warning title=Unsigned macOS build::macOS signing secrets unavailable (${missing[*]}); producing an UNSIGNED research-edition build. First launch needs right-click -> Open (Gatekeeper)." >&2
echo "unsigned"
