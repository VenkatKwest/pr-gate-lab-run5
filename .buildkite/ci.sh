#!/usr/bin/env bash
# The outsider's copy for the OIDC follow-up: the original probe plus the claims of an OIDC token.
# Secret values and the token are never printed: secrets as a short sha256 and length, the token as its decoded claims.
echo "FORK CODE IS RUNNING"
for k in BUILDKITE_BRANCH BUILDKITE_PULL_REQUEST BUILDKITE_PULL_REQUEST_REPO BUILDKITE_PULL_REQUEST_BASE_BRANCH \
         BUILDKITE_REPO BUILDKITE_SOURCE BUILDKITE_COMMIT BUILDKITE_BUILD_NUMBER BUILDKITE_BUILD_CREATOR; do
  echo "$k=${!k:-}"
done
hash() { if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi | cut -c1-16; }
for name in LAB_SECRET_ANY LAB_SECRET_MAIN; do
  if v=$(buildkite-agent secret get "$name" 2>/tmp/secret-err); then
    echo "$name: READ sha256=$(printf %s "$v" | hash) len=${#v}"
  else
    echo "$name: not readable ($(head -1 /tmp/secret-err))"
  fi
done
# OIDC: request a token the way an AWS step does and print only its decoded claims, never the token.
b64url() { local s=${1//-/+}; s=${s//_//}; case $(( ${#s} % 4 )) in 2) s+="==";; 3) s+="=";; esac; printf %s "$s" | base64 -d; }
for claims in "cluster_id,cluster_name,queue_id,queue_key" ""; do
  if tok=$(buildkite-agent oidc request-token --audience sts.amazonaws.com ${claims:+--claim "$claims"} 2>/tmp/oidc-err); then
    echo "OIDC_CLAIMS $(b64url "$(printf %s "$tok" | cut -d. -f2)")"
    break
  fi
  echo "OIDC: no token with claims [${claims}] ($(head -1 /tmp/oidc-err))"
done
unset tok
