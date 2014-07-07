#!/bin/bash

SRC_DIR=$RECIPE_DIR/..
cd $SRC_DIR

$PYTHON setup.py install --single-version-externally-managed --record=record.txt
