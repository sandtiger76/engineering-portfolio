#!/usr/bin/env bash
set -e

sync_repo () {
  local name="$1"
  local path="$2"
  local msg="$3"

  echo ""
  echo "=============================="
  echo "🔄 Syncing: $name"
  echo "📁 Path:   $path"
  echo "=============================="

  cd "$path"

  echo "➡️  Pulling latest from origin/main..."
  git pull origin main

  echo "➡️  Staging changes..."
  git add .

  # Only commit if there are changes staged or unstaged
  if git diff --cached --quiet && git diff --quiet; then
    echo "ℹ️  No changes to commit for $name"
  else
    echo "➡️  Committing..."
    git commit -m "$msg"
  fi

  echo "➡️  Pushing to origin/main..."
  git push origin main

  echo "✅ $name synced"
}

DATE_TAG="$(date +%Y-%m-%d)"

# ✅ az-104-study-journey (public)
sync_repo \
  "az-104-study-journey" \
  "/home/quintin/Documents/IT/GitHub/az-104-study-journey" \
  "Updated AZ Documentation (${DATE_TAG})"

# ✅ personal-sysadmin (private - Wiki.js repo)
sync_repo \
  "personal-sysadmin (Wiki.js)" \
  "/home/quintin/Documents/IT/GitHub/personal-sysadmin" \
  "Updated Personal IT Documentation (${DATE_TAG})"

# ✅ engineering-portfolio (public)
sync_repo \
  "engineering-portfolio" \
  "/home/quintin/Documents/IT/GitHub/engineering-portfolio" \
  "Portfolio updates (${DATE_TAG})"

echo ""
echo "🎉 === All repos synced! ==="
echo "ℹ️  Note: Wiki.js will pull personal-sysadmin on its next sync schedule."

