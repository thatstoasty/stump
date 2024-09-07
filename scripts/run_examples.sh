#!/bin/bash
mkdir ./tmp
./scripts/build.sh package
mv stump.mojopkg tmp/

echo -e "Building binaries for all examples...\n"
mojo build examples/custom.mojo -o tmp/custom
mojo build examples/default.mojo -o tmp/default
mojo build examples/import.mojo -o tmp/import
mojo build examples/json.mojo -o tmp/json
mojo build examples/logfmt.mojo -o tmp/logfmt
mojo build examples/loop.mojo -o tmp/loop
mojo build examples/message_only.mojo -o tmp/message_only
mojo build examples/turn_off_styler.mojo -o tmp/turn_off_styler

echo -e "Executing examples...\n"
cd tmp
./custom
./default
./import
./json
./logfmt
./message_only
./turn_off_styler

cd ..
rm -R ./tmp
