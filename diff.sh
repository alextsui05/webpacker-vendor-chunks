#!/bin/bash

if [[ $# < 2 ]]; then
  HASH1="5ea94227ae43149be434ad2a30a99a385c91c66a"
  HASH2="0bfba84c66a7441ba1a12d51efa7b190e93cc75a"
else
  HASH1=$1
  HASH2=$2
fi

if [[ $# < 3 ]]; then
  ls artifacts/$HASH1/js/*chunk.js | xargs -n1 basename | sort > a
  ls artifacts/$HASH2/js/*chunk.js | xargs -n1 basename | sort > b
  diff -u a b
fi

if [[ $# == 3 ]]; then
  diff -u artifacts/$HASH1/js/$3*.js artifacts/$HASH2/js/$3*.js
fi

rm -rf a b
