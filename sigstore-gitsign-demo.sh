#!/bin/bash

# One-time instructions
cd /path/to/my/repository
git config --local commit.gpgsign true  # Sign all commits
git config --local gpg.x509.program gitsign  # Use Gitsign for signing
git config --local gpg.format x509  # Gitsign expects x509 args

# for the second one, i had already installed gitsign & enabled it by default onto a test repo.
# gitsign demo

touch hello
git add .
git commit -m "This is a signed commit!"

# Do the verification
git log --show-signature -1

# Do the same verification manually by grabbing the info from Rekor
uuid=$(rekor-cli search --artifact <(git rev-parse HEAD | tr -d '\n') | tail -n 1)
rekor-cli get --uuid=$uuid --format=json | jq .

sig=$(rekor-cli get --uuid=$uuid --format=json | jq -r .Body.HashedRekordObj.signature.content)
cert=$(rekor-cli get --uuid=$uuid --format=json | jq -r .Body.HashedRekordObj.signature.publicKey.content)

echo $sig
echo $cert

cosign verify-blob --cert <(echo $cert | base64 --decode) --signature <(echo $sig | base64 --decode) <(git rev-parse HEAD | tr -d '\n')

git push

