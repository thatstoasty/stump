#!/bin/bash
mkdir ./temp
mojo package stump -I ./external -o ./temp/stump.mojopkg

echo -e "Building binaries for all examples...\n"
mojo build examples/custom.mojo -o temp/custom
mojo build examples/default.mojo -o temp/default
mojo build examples/import.mojo -o temp/import
mojo build examples/json.mojo -o temp/json
mojo build examples/logfmt.mojo -o temp/logfmt
mojo build examples/loop.mojo -o temp/loop
mojo build examples/message_only.mojo -o temp/message_only
mojo build examples/turn_off_styler.mojo -o temp/turn_off_styler

echo -e "Executing examples...\n"
cd temp
./custom
./default
./import
./json
./logfmt
./message_only
./turn_off_styler

cd ..
rm -R ./temp
