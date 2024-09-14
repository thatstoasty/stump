#!/bin/bash

TEMP_DIR=~/tmp
PACKAGE_NAME=stump
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and example binaries."
cp -a examples/. $TEMP_DIR
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg
magic run mojo build $TEMP_DIR/binding_context.mojo -o $TEMP_DIR/binding_context
magic run mojo build $TEMP_DIR/custom.mojo -o $TEMP_DIR/custom
magic run mojo build $TEMP_DIR/default.mojo -o $TEMP_DIR/default
magic run mojo build $TEMP_DIR/json.mojo -o $TEMP_DIR/json
magic run mojo build $TEMP_DIR/logfmt.mojo -o $TEMP_DIR/logfmt
magic run mojo build $TEMP_DIR/loop.mojo -o $TEMP_DIR/loop
magic run mojo build $TEMP_DIR/message_only.mojo -o $TEMP_DIR/message_only
magic run mojo build $TEMP_DIR/turn_off_styler.mojo -o $TEMP_DIR/turn_off_styler

echo "[INFO] Running examples..."
$TEMP_DIR/binding_context
$TEMP_DIR/custom
$TEMP_DIR/default
$TEMP_DIR/json
$TEMP_DIR/logfmt
# $TEMP_DIR/loop
$TEMP_DIR/message_only
$TEMP_DIR/turn_off_styler

echo "[INFO] Cleaning up the example directory."
rm -R $TEMP_DIR
