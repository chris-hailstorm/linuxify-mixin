### ─────────────────────────────────────────────────────────────────────────────
### Linuxify Initialization
### ─────────────────────────────────────────────────────────────────────────────
###
### USAGE: Drop this file in your ~/.zshrc.d/ folder for automatic linuxify
###        management. Requires a modular zshrc setup that sources ~/.zshrc.d/*
###
### This module will:
### - Clone linuxify-mixin to ~/linuxify-mixin on first run
### - Check for updates on every new shell
### - Auto-install updates when available
### - Source the linuxify environment configuration
###
### ─────────────────────────────────────────────────────────────────────────────

## create a clone at the expected location

LINUXIFY_REPO_URL=git@github-personal:chris-hailstorm/linuxify-mixin.git

if [[ ! -d ~/linuxify-mixin ]]; then
  echo "🔧 Cloning global linuxify..."
  cd ~
  git clone "${LINUXIFY_REPO_URL}" linuxify-mixin
  cd ~/linuxify-mixin
  ./linuxify install
fi

## run the install only if upstream changed

pushd ~/linuxify-mixin >/dev/null || exit 1
git remote update &>/dev/null

if git status -uno | grep -q 'up to date'; then
  echo "✅ linuxify is up to date"
else
  echo "🔄 Pulling linuxify updates..."
  git pull
  ./linuxify install
fi

source ~/.linuxify
popd >/dev/null
