#! /usr/bin/env bash
#doitlive shell: /bin/zsh
#doitlive env:GITHUB_TOKEN=<your-token>
#doitlive env:COSIGN_EXPERIMENTAL=1
#doitlive env:GITHUB_ORG=<your-org>
#doitlive env:GITHUB_REPO=<your-repo>

docker build -t "$GITHUB_ORG/$GITHUB_REPO" .
docker push "$GITHUB_ORG/$GITHUB_REPO"

cosign generate-key-pair "github://$GITHUB_ORG/$GITHUB_REPO"
cosign sign "$GITHUB_ORG/$GITHUB_REPO"
cosign verify "$GITHUB_ORG/$GITHUB_REPO" -o json | jq .

uuid=$(cosign verify "$GITHUB_ORG/$GITHUB_REPO" -o json | jq '.[-1].optional.Bundle.Payload.logIndex')

rekor-cli get --log-index $uuid --format json | jq .

rekor-cli get --log-index $uuid --format json | jq -r .Body.HashedRekordObj.signature.publicKey.content | base64 -d | openssl x509 -text -in /dev/stdin