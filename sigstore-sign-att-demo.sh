# Run before the demo
crane cp busybox gcr.io/chainguard-demo/busybox
#crane copy docker.io/library/nginx@sha256:10f14ffa93f8dedf1057897b745e5ac72ac5655c299dade0aa434c71557697ea gcr.io/chainguard-demo/sigstore-demo-nginx
#Demo

#trivy image --format sarif -o /tmp/nginx.trivy.sarif gcr.io/chainguard-demo/sigstore-demo-nginx@sha256:10f14ffa93f8dedf1057897b745e5ac72ac5655c299dade0aa434c71557697ea
trivy image --format sarif -o /tmp/nginx.trivy.sarif gcr.io/chainguard-demo/busybox@sha256:ef320ff10026a50cf5f0213d35537ce0041ac1d96e9b7800bafd8bc9eff6c693
cat /tmp/nginx.trivy.sarif | pygmentize -l json -P style=vice

export TRIVY_SCAN=/tmp/nginx.trivy.sarif
export SCANNER_URI=$(cat $TRIVY_SCAN | jq .runs[0].tool.driver.informationUri)
export SCANNER_VERSION=$(cat $TRIVY_SCAN | jq .runs[0].tool.driver.version)
cat > /tmp/scan.att <<EOF
{
    "invocation": {
      "parameters": null,
      "event_id": "FAKE_EVENT_ID",
      "builder.id": "FAKE_BUILDER_ID"
    },
    "scanner": {
      "uri": $SCANNER_URI,
      "version": $SCANNER_VERSION,
      "result": $(cat $TRIVY_SCAN | jq .)
    },
    "metadata": {
      "scanStartedOn": "$(TZ=Zulu date "+%Y-%m-%dT%H:%M:%SZ")",
      "scanFinishedOn": "$(TZ=Zulu date "+%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOF

# Sign an image and upload the attestation
cosign sign gcr.io/chainguard-demo/busybox

cat $ATTESTATION | head -n 25 | pygmentize -l json -P style=vice
cosign attest --type vuln --predicate /tmp/nginx.trivy.sarif gcr.io/chainguard-demo/busybox

# Verify
cosign verify gcr.io/chainguard-demo/busybox
cosign verify-attestation gcr.io/chainguard-demo/busybox | jq | pygmentize -l json -P style=vice

# Check out the rekor entries created
rekor-cli get --log-index [entry]
rekor-cli get --log-index 3164282 --format=json | jq | pygmentize -l json -P style=rainbow_dash
