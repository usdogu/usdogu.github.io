#!/usr/bin/env fish
hugo
cd public
git add -A
git commit -m $argv
git push origin main
