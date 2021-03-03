#!/bin/bash
set -Eeuo pipefail

psql -a -f test_extensions.sql