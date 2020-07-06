#!/bin/bash
HASH1="5ea94227ae43149be434ad2a30a99a385c91c66a"
HASH2="0bfba84c66a7441ba1a12d51efa7b190e93cc75a"

# prepare
bundle && yarn install --check-files
rm -rf public/packs/*
rm -rf artifacts
mkdir -p artifacts/${HASH1}
mkdir -p artifacts/${HASH2}

for HASH in ${HASH1} ${HASH2}; do
  git checkout $HASH && bin/rails webpacker:compile && cp -r public/packs/* artifacts/${HASH}
  rm -rf public/packs/*
done

# finish
git checkout master

./diff.sh
