#!/bin/bash

source /scripts/lib.sh

export TF_CLI_ARGS_apply="-auto-approve"

# Capture ^C and exit immediately
trap ctrl_c INT

parse_args $*
