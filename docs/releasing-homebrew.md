---
summary: "Homebrew Cask release steps for LimitBar (Sparkle-disabled builds)."
read_when:
  - Publishing a LimitBar release via Homebrew
  - Updating the Homebrew tap cask definition
---

# LimitBar Homebrew Release Playbook

Homebrew is for the UI app via Cask. When installed via Homebrew, LimitBar disables Sparkle, checks `Casks/limitbar.rb` in the tap for a newer version, and offers a one-click update that runs `brew upgrade --cask steipete/tap/limitbar`. Users are only prompted once the tap cask is bumped.

## In-app updates
- Automatic checks read the tap on launch and daily; turning them off still permits manual checks in About. Checking never installs anything.
- Detection follows the `Caskroom/limitbar/<version>/LimitBar.app` artifact link under `/opt/homebrew` or `/usr/local`, or a legacy app inside its cask directory. An unrelated copy of the app does not inherit Homebrew ownership. If multiple prefixes claim the same app, Sparkle remains disabled and the helper refuses to choose an owner; resolve the duplicate installation in Terminal.
- Clicking **Update to …** runs the owning prefix's `bin/brew update`, then `bin/brew upgrade --cask steipete/tap/limitbar`, directly with fixed arguments. Refreshing first avoids Homebrew's auto-update interval leaving the local tap behind the offered version. The app shows progress and disables duplicate installs. No shell evaluates the cask version or command arguments.
- The helper sets `NONINTERACTIVE=1`, `HOMEBREW_NO_SUDO=1`, and `HOMEBREW_NO_UPGRADE_QUIT_CASKS=1`. A permissions failure is shown in About; the app does not request elevated privileges. It relaunches only after a successful command and an on-disk version at least as new as the offered update.
- Missing brew, network errors, and failed or incomplete upgrades appear in About alongside a copyable Terminal command. If the local tap is stale, run `brew update`, then the displayed upgrade command. A tap version older than the installed app is never offered as an update.
- Homebrew remains responsible for both the cask receipt and the app bundle; Sparkle does not install updates for these apps.

## Prereqs
- Homebrew installed.
- Access to the tap repo: `../homebrew-tap`.

## 1) Release LimitBar normally
Follow `docs/RELEASING.md` to publish `LimitBar-macos-universal-<version>.zip` to GitHub Releases.

## 2) Let the Release CLI workflow update the tap
After the GitHub release is published, `.github/workflows/release-cli.yml` builds the standalone CLI assets and dispatches `steipete/homebrew-tap`'s `update-formula.yml`. That tap workflow updates both:
- `Casks/limitbar.rb` for the app zip.
- `Formula/limitbar.rb` for the standalone CLI tarballs.

If dispatch fails or is rate-limited, update the files manually.

## 2a) Manual cask update
In `../homebrew-tap`, update the cask at `Casks/limitbar.rb`:
- `url` points at the GitHub release asset: `.../releases/download/v<version>/LimitBar-macos-universal-<version>.zip`
- Update `sha256` to match that zip.
- Keep `depends_on macos: ">= :sonoma"` (LimitBar is macOS 14+). Do not add an architecture restriction; the app zip is universal.

## 2b) Manual formula update
In `../homebrew-tap`, update the formula at `Formula/limitbar.rb`:
- `url` points at the GitHub release assets:
  - macOS: `.../releases/download/v<version>/LimitBarCLI-v<version>-macos-arm64.tar.gz`
  - macOS: `.../releases/download/v<version>/LimitBarCLI-v<version>-macos-x86_64.tar.gz`
  - Linux: `.../releases/download/v<version>/LimitBarCLI-v<version>-linux-aarch64.tar.gz`
  - Linux: `.../releases/download/v<version>/LimitBarCLI-v<version>-linux-x86_64.tar.gz`
- Static musl tarballs are also published for manual Linux installs as `linux-musl-aarch64` and `linux-musl-x86_64`; keep the formula on the glibc assets unless intentionally changing its runtime contract.
- Update all `sha256` values to match those tarballs.

## 3) Verify install
```sh
brew uninstall --cask limitbar || true
brew untap steipete/tap || true
brew tap steipete/tap
brew install --cask steipete/tap/limitbar
open -a LimitBar
```

## 4) Push tap changes
Commit + push in the tap repo.
