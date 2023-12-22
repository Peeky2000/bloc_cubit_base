#!/bin/bash

# update hooks
if [ -d ".git/hooks" ]
then
  mv .git/hooks .git/hooks.old
fi
mkdir -p ".git/hooks"
echo "#!/bin/sh

## auto format code
fvm flutter pub get
git add pubspec.lock
format_code=\$(find lib -name \"*.dart\" -not -path \"lib/modules/*\" | xargs fvm dart format)
# Run dart fix and capture the output
fix_output=\$(fvm dart fix --apply 2>&1)

# Check if the output contains \"Nothing to fix!\"
if [[ \$fix_output != *\"Nothing to fix!\"* || \$format_code != *\"(0 changed)\"* ]]; then
    exit 1
fi" > .git/hooks/pre-commit

echo "#!/bin/sh

## check coding conventions
output=\$(fvm flutter analyze | grep -E '^\[error\].*lib/')

# Check if the exit code of the previous command is non-zero (indicating an error)
echo \"\$output\"
if [ \$? -ne 0 ]; then
  exit 1
fi
" > .git/hooks/pre-push

cd .git/hooks/
chmod 755 pre-commit
chmod 755 pre-push

git submodule update --init