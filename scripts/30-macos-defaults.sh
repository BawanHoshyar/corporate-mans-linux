#!/usr/bin/env bash
# Opinionated macOS system defaults.
# Re-runnable; some changes need logout to take effect.
set -euo pipefail

# --- Keyboard ----------------------------------------------------------------
# Function keys behave as F1-F12 by default (media keys via Fn).
defaults write -g com.apple.keyboard.fnState -bool true
# Fast key repeat
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
# No press-and-hold accent popup
defaults write -g ApplePressAndHoldEnabled -bool false
# Kill autocorrect / smart quotes / smart dashes / auto-cap
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

# --- Finder ------------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv          # list view
defaults write com.apple.finder FXDefaultSearchScope -string SCcf          # search current folder
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Dock --------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 42
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1

# --- Screenshots -------------------------------------------------------------
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture type -string png
defaults write com.apple.screencapture disable-shadow -bool true

# --- Trackpad ----------------------------------------------------------------
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# --- Misc --------------------------------------------------------------------
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write com.apple.frameworks.diskimages skip-verify -bool true

killall Dock Finder SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Log out + back in for Fn-key + some Finder changes to settle."
