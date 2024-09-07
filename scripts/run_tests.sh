#!/bin/bash
mkdir -p tmp

echo -e "Building stump package and copying tests."
./scripts/build.sh package
mv stump.mojopkg tmp/
cp -R tests/ tmp/tests/
pytest tmp/tests

echo -e "Cleaning up the test directory."
rm -R tmp
