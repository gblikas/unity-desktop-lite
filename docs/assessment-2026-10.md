# Project assessment: October 2026

Snapshot of `main` at `1ee7c38` (the repository's only commit, 2023-12-28), assessed on 2026-10-28.
The proposed next steps are in the companion document, [roadmap.md](./roadmap.md).

**Contents**

1. [Summary](#1-summary)
2. [Health check](#2-health-check)
3. [Links and references](#3-links-and-references)
4. [Live build and run test](#4-live-build-and-run-test)
5. [Defects](#5-defects)
6. [Dependency freshness](#6-dependency-freshness)
7. [What changed since 2023](#7-what-changed-since-2023)
8. [Alternatives: better, worse, or complementary?](#8-alternatives-better-worse-or-complementary)
9. [Constraints any next step must respect](#9-constraints-any-next-step-must-respect)
10. [Method, limits, and sources](#10-method-limits-and-sources)

---

## 1. Summary

| Question | Answer |
|---|---|
| Can a new user get it working today? | **No.** The image the README points to is a **private** GHCR package. Anonymous pulls are refused, and the README's packages link shows "0 packages" to everyone except the owner. That is what [issue #3](https://github.com/gblikas/unity-desktop-lite/issues/3) reports; the owner sees the package only because they are signed in. |
| Does the image still build? | **No, not as written.** The unpinned base `mcr.microsoft.com/devcontainers/base:ubuntu` now resolves to **Ubuntu 26.04**. The copied desktop script fails there (and on 24.04) at `libasound2`, and Unity 2022.3.11f1 itself cannot start on 26.04. Pinned to Ubuntu 22.04, it builds and the Editor GUI comes up over noVNC (tested with Docker, see [§4](#4-live-build-and-run-test)). This branch pins the base. |
| Is the license flow sound? | **No.** Unity credentials go into a dev container *feature*, which runs at image build time. GitHub documents that Codespaces secrets cannot be used there. The credentials are printed to the build log, the activated license ends up in an image layer, seats are never returned, and the "optional" `VNC_PASSWORD` actually fails the build when unset. |
| Is it up to date? | **No.** Unity 2022.3 is out of public support, and the pinned patch is 51 patch versions behind the last public 2022.3 release. Unity Plus no longer exists. The copied desktop script is upstream v1.0.7 (January 2023); upstream is v1.2.10. noVNC, websockify, the GitHub Actions and the VS Code extension IDs are years old. |
| Has someone, or Unity, built something better? | **Partly.** Unity now ships an official **Unity CLI** (beta) that installs any Editor, activates licenses (including Personal), produces semantic scene/prefab diffs (`vcs diff`) and runs an MCP server for AI agents (`unity mcp`, Unity 6+ only). **Unity Production Pipeline** web gives non-Editor users browser previews of a GitHub repo's assets (closed beta; public from November 2026). **PrefabLens** shows semantic prefab/scene diffs inside GitHub pull requests. Nothing found offers a disposable, PR-scoped **real Editor** in the browser that humans and AI agents can share, or posts **rendered before/after images** of changed scenes and prefabs on a PR. That is where this project can still lead. |

The rest of this document is the evidence. [roadmap.md](./roadmap.md) turns it into a plan.

## 2. Health check

| Area | Status | Evidence |
|---|---|---|
| A new user can pull the prebuilt image | ❌ | `ghcr.io/gblikas/unity-desktop-lite/unity-2022/2022.3.11f1` answers an anonymous token request with `UNAUTHORIZED: authentication required`, while non-existent sibling paths answer `DENIED`, so the package exists but is private. GHCR makes packages in a personal account private on first publish ([docs](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)). The Actions tab shows no workflow runs. |
| The image rebuilds from source | ❌ → ✅ in this branch | `FROM mcr.microsoft.com/devcontainers/base:ubuntu` is now Ubuntu 26.04.1. The tag moved jammy → noble in May 2025 and → 26.04 in April 2026. `apt-get install libasound2` fails with "no installation candidate" on 24.04 and 26.04. The image builds on 22.04. |
| The Unity Editor runs in the desktop | ✅ 22.04 / 24.04, ❌ 26.04 | See [§4](#4-live-build-and-run-test). |
| License activation in Codespaces | ❌ by design | Activation happens in a build-time feature fed by `${localEnv:UNITY_*}`. GitHub: secrets "cannot be used ... during codespace build time ... within a dev container feature", and "prebuilds cannot use any user-level secrets" ([secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces), [prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces/configuring-prebuilds)). |
| Credential hygiene | ❌ (partly fixed here) | `set -x` traced the Unity command lines, including `-password` and `-serial` (removed in this branch). Independently, the dev container CLI echoes every feature option, so the password is still printed while it is passed as an option. Arguments were unquoted (fixed here). A license activated at build time is stored in an image layer. |
| Seat usage | ❌ | `-returnlicense` runs in a fresh build container, where nothing is activated, so it does nothing. Nothing returns a seat when a codespace is deleted, which leads to the README's "not enough licenses" FAQ. |
| CI | ⚠️ | `::set-output` was deprecated and `actions/checkout@v4` / `docker/login-action@v3` are node20-era majors (fixed here). The workflow pushes only `:latest`, and only on push to `main`. The `HEAD^` diff gate misses multi-commit pushes. There is no scheduled rebuild for base-image security updates. |
| Unity version | ⚠️ | 2022.3.11f1 (October 2023). The 2022.3 stream is out of support; its last public patch is 2022.3.62f3 (2025-10-28). Players built with 2022.3.11f1 are affected by [CVE-2025-59489](https://unity.com/security/sept-2025-01). |
| Docs | ⚠️ (fixed here) | The README mentioned Unity Plus, had a wrong config path, used `--projectPath`, said the password is "not retained", called a required secret optional, and had a dangling sentence and typos. |
| Community | ℹ️ | 10 stars, 18 forks, 1 open issue (#3, opened 2026-10-28). |

## 3. Links and references

Every URL and external reference in the README and source was checked on 2026-10-28.

### README

| Reference | Where | Result | Action |
|---|---|---|---|
| desktop-lite feature docs | README.md:3 | ✅ Live. But the repo **vendors a 2023 copy** (v1.0.7) of the feature's script instead of using the feature (now v1.2.10). | Use the feature ([roadmap](./roadmap.md)). |
| Codespaces product page | README.md:5 | ✅ Live. Link text said "codepsace". | Fixed. |
| Demo GIF | README.md:7 | ✅ Live. 17 MB, and it shows the 2023 setup. | Consider a compressed MP4 later. |
| `.devcontainer/devcontainer.json` link | README.md:18 | ✅ Live, but the target contradicted "optional" (see D6). | Fixed. |
| Packages page | README.md:20 | ❌ Shows "0 packages" to anyone but the owner (private package). | Decision D1 in the [roadmap](./roadmap.md#decisions-for-the-owner). |
| "replace `.devcontainer.json.image`" | README.md:20 | ❌ No such file or key. | Fixed: "the `image` property in `.devcontainer/devcontainer.json`". |
| `--projectPath` | README.md:30 | ⚠️ Unity documents `-projectPath` (single dash). | Fixed. |
| Codespaces prebuilds docs | README.md:42 | ✅ Live. Note that prebuilds cannot use user-level secrets, which conflicts with build-time activation. | Caveat added to the FAQ. |
| containers.dev prebuild guide | README.md:42 | ✅ Live. It covers prebuilding *images* with the dev container CLI, not Codespaces prebuilds. | None. |
| "Unity Plus" | README.md:39, :48 | ❌ Plan retired. Plus could not be renewed after 2024-03-27 ([Unity support](https://support.unity.com/hc/en-us/articles/35060816844436-What-happens-when-my-Unity-Plus-subscription-expires)). | Fixed. |
| Issues page | README.md:55 | ⚠️ Mentioned but not linked. | Fixed. |

### Configuration and source

| Reference | Where | Result | Action |
|---|---|---|---|
| `ghcr.io/gblikas/unity-desktop-lite/unity-2022/2022.3.11f1:latest` | .devcontainer/devcontainer.json:2 | ❌ Private; only a mutable `:latest` tag. | D1. |
| `mcr.microsoft.com/devcontainers/base:ubuntu` | Dockerfile:1 | ❌ Floating; now Ubuntu 26.04. | Fixed: pinned to `3-jammy`. |
| Upstream desktop-lite `install.sh` link | Dockerfile:8 | ✅ Live. The copy is about 3 years behind. | Replace the copy with the feature. |
| `go.microsoft.com/fwlink/?linkid=2090316` | install.sh:4 | ✅ Redirects to the MIT LICENSE of `microsoft/vscode-dev-containers` (repo archived 2023-11-30). | None. |
| `vscode-dev-containers/.../desktop-lite.md` | install.sh:7 | ⚠️ Archived repo. The page says desktop-lite moved to `devcontainers/features`. | Goes away with the copy. |
| noVNC `v1.2.0` | install.sh:10, :230 | ⚠️ Downloads, but the latest is 1.7.0 (the feature defaults to 1.6.0). `utils/launch.sh`, which install.sh:369-370 hard-codes, no longer exists in newer noVNC. | Use the feature. |
| websockify `v0.10.0` | install.sh:18, :233 | ⚠️ Downloads; the latest is 0.13.0. | Use the feature. |
| `ppa:webupd8team/terminix` | install.sh:184 | ⚠️ No series after Ubuntu 20.10. Dormant, because tilix is in Ubuntu universe. | Goes away with the copy. |
| `deb.debian.org ... stretch-backports` | install.sh:186 | ❌ 404 (moved to archive.debian.org). Dormant on Ubuntu. | Goes away with the copy. |
| Cascadia Code `v2008.25` | install.sh:220 | ✅ Downloads; the latest is v2407.24. | None. |
| `download.unity3d.com/.../UnitySetup-2022.3.11f1` | unity-install.sh:19 | ✅ Still served, as is the same pattern for 2022.3.62f3 and 6000.x. | Prefer the documented `LinuxEditorInstaller/Unity-<ver>.tar.xz` (roadmap). |
| `github/gitignore` Unity.gitignore | .gitignore:3 | ✅ Live; the copy here is stale. | Optional refresh. |
| `actions/checkout@v4` | workflow:27 | ⚠️ node20 action; Node 20 was removed from runners on 2026-09-23. | Fixed: `@v7`. |
| `docker/login-action@v3` | workflow:32 | ⚠️ node20 action. | Fixed: `@v4`. |
| `devcontainers/ci@v0.3` | workflow:50 | ✅ Current. | None. |
| `::set-output` | workflow:42-46 | ⚠️ Deprecated (flagged by actionlint). | Fixed: `$GITHUB_OUTPUT`. |
| `ms-azuretools.vscode-docker` | .devcontainer/devcontainer.json:14 | ⚠️ Superseded by Container Tools. | Fixed: `ms-azuretools.vscode-containers`. |
| `GitHub.copilot` | .devcontainer/devcontainer.json:14 | ⚠️ Deprecated (VS Code 1.109); Copilot Chat is built in from 1.116. | Fixed: `GitHub.copilot-chat`. |

## 4. Live build and run test

Run on 2026-10-28 with Docker on amd64. The repo's scripts were used byte-for-byte; the Unity 2022.3.11f1 Linux tarball was 3.06 GB and its md5 matched the CDN ETag. No license was used, so "GUI works" means the Editor starts and shows Unity's "No valid Unity Editor license found" dialog.

| Base image | Desktop layer (repo `install.sh`) | `UnitySetup` installer | `Unity -version` | Editor GUI over TigerVNC + noVNC |
|---|---|---|---|---|
| `devcontainers/base:jammy` (Ubuntu 22.04) | ✅ 129 s | ✅ `--help` and `--list-components` work, and the download starts | ✅ | ✅ Splash screen plus the license dialog. noVNC answers `101` + `RFB 003.008`. |
| `devcontainers/base:noble` (24.04) | ❌ `libasound2`. ✅ after renaming it to `libasound2t64`. | not run | ✅ | ✅ Same as 22.04. |
| `devcontainers/base:ubuntu` (now 26.04) | ❌ `libasound2`. ✅ after renaming it. | ❌ `libxml2.so.2` missing | ❌ `libxml2.so.2` missing | ❌ Needs a private libxml2 2.9 **and** `GLIBC_TUNABLES=glibc.rtld.execstack=2`, because glibc 2.43 refuses the Licensing Client's executable-stack `libbindings.so`. |
| GameCI `unityci/editor:ubuntu-2022.3.11f1-base-3.2.2` (22.04) + repo desktop layer (+ `sudo` and a `vscode` user) | ✅ 165 s | n/a (Editor preinstalled) | ✅ | ✅ Same as 22.04. |

Also observed:

- The current upstream desktop-lite script (feature v1.2.10, noVNC 1.6.0) builds and serves on 24.04 and 26.04.
- `UnitySetup` is a GTK3 program. It only runs because the desktop script installs GTK3 first, so the Dockerfile's step order matters.

Not covered by this test: license activation (no credentials were available), opening or importing a real project, Codespaces-specific behaviour (port forwarding, secrets, prebuilds, idle timeout), and the Android module.

## 5. Defects

Ordered by severity. "This branch" means it is fixed on `claude/trusting-ptolemy-3qobu9`.

| ID | Severity | Where | Problem | Fix | Status |
|---|---|---|---|---|---|
| D1 | Critical | .devcontainer/devcontainer.json:2, README.md:20 | The README's image is private, so nobody but the owner can follow the README (issue #3). It also has only a mutable `:latest` tag. | Make the package public, or stop distributing Editor images (see [Decisions](./roadmap.md#decisions-for-the-owner)). Publish immutable version tags. | Open |
| D2 | Critical | Dockerfile:1 | The unpinned base now gives Ubuntu 26.04: the build fails, and Unity 2022.3 cannot run there. | Pin to `mcr.microsoft.com/devcontainers/base:3-jammy`. | This branch |
| D3 | High | local feature install.sh:47; devcontainer.json:5-8 | The Unity password and serial were printed to the build/creation log, by `set -x` and by the dev container CLI's echo of feature options. | `set -x` removed. The option echo only stops once credentials are no longer feature options (runtime activation). | Partly fixed |
| D4 | High | devcontainer.json:4-9; local feature | License activation runs at **image build time**. That contradicts GitHub's secrets model, cannot work with prebuilds (which get no user secrets), and stores the activated license, with a recoverable serial, in an image layer. With repo-level secrets it would share one person's seat with everyone. | Activate at runtime in `postStartCommand` from environment secrets; declare them in a devcontainer.json `secrets` block. | Open (roadmap Phase 0) |
| D5 | High | local feature install.sh:49-56 | Seats are never returned. `-returnlicense` in a fresh container is a no-op, and each new codespace or rebuild consumes an activation (a paid seat allows two machines). | A `return-license` command, documented My Seats cleanup, and floating licenses for teams. | Open |
| D6 | Medium | devcontainer.json:8 | The "optional" `VNC_PASSWORD` was required: `${localEnv:VNC_PASSWORD}` becomes `""`, which overrides the feature's default and makes install.sh exit 1. | `${localEnv:VNC_PASSWORD:vscode}`. | This branch |
| D7 | Medium | local feature install.sh:50-65 | Credentials were unquoted, so a password with a space or glob character was split or expanded. Because the CLI writes options into an env file as `NAME="value"` without escaping, `$`, `"` or a backtick in a password can also break the build or execute. | Quoted in this branch. The env-file part needs runtime activation. | Partly fixed |
| D8 | Medium | unity-2022/.../devcontainer.json:6 | `runArgs` (`--shm-size=6gb`, `--init`) are not part of image metadata, so consumers run with a 64 MB `/dev/shm` and no init. | Put `runArgs` and `"init": true` in the consumer config. | Open |
| D9 | Medium | workflow | Only `:latest` is published, and only on push to `main`; tag and manual runs never publish. There was no `permissions` block, and new personal repos default to a read-only token. | `permissions` added in this branch. Versioned `imageTag` still to do. | Partly fixed |
| D10 | Medium | workflow:40 | `git diff HEAD^ HEAD` only inspects the last commit, cannot be forced, and treats git errors as "changed". There is no schedule for base-image updates. | Path filters or `github.event.before`, a `force` input, a weekly schedule. | Open |
| D11 | Low | workflow | Deprecated `::set-output`; node20-era action majors. | `$GITHUB_OUTPUT`, `checkout@v7`, `login-action@v4`. | This branch |
| D12 | Low | unity-install.sh, install.sh | Downloads are executed as root without checksums; action tags are mutable. | Verify md5/sha256 and pin actions by SHA. | Open |
| D13 | Low | unity-install.sh:25 | The Android module (about 1.3 GB plus SDK/NDK) is installed by default but is not needed to view scenes. | Editor-only by default. | Open |
| D14 | Low | unity-2022/.../install.sh | The vendored desktop script is frozen at v1.0.7. The desktop only starts for consumers because `overrideCommand: false` survives in the image label. | Use `ghcr.io/devcontainers/features/desktop-lite:1`. | Open |
| D15 | Low | local feature install.sh:25 | The VNC password is baked into the image, stored reversibly, and limited to 8 characters. | Rely on private Codespaces ports, or set it at runtime with mode 600. | Open |
| D16 | Low | README.md | Inaccurate or stale statements and typos. | Corrected. | This branch |

## 6. Dependency freshness

| Item | In repo | Current (2026-10-28) | Recommendation |
|---|---|---|---|
| Base image | `devcontainers/base:ubuntu` (floating, now 26.04) | `3-jammy` (22.04), `3-noble` (24.04), `3-resolute` (26.04) | `3-jammy` for 2021.3/2022.3; `3-jammy` or `3-noble` for Unity 6. Never the floating `ubuntu` tag. |
| Desktop | Copy of desktop-lite v1.0.7 (2023-01) | Feature v1.2.10 (2026-07) | Use the feature. |
| noVNC / websockify | 1.2.0 / 0.10.0 | 1.7.0 / 0.13.0 (feature default 1.6.0) | Comes with the feature. |
| Unity | 2022.3.11f1 (`d00248457e15`) | 2022.3.62f3 (last public 2022.3); **6000.3.27f1 LTS** (supported to Dec 2027); 6000.6.7f1 (current Update release); 6000.0 LTS support ends Oct 2026 | Default to 6000.3 LTS and keep 2022.3.62f3 for legacy projects (see roadmap Phase 2). |
| Unity installer | `UnitySetup-<ver>` (GTK3 binary, undocumented) | `LinuxEditorInstaller/Unity-<ver>.tar.xz` (documented, md5 published), or the Unity CLI `unity install` (beta) | Tarball now; the CLI once it is GA. |
| Actions | `checkout@v4`, `login-action@v3`, `ci@v0.3` | `checkout@v7`, `login-action@v4`, `ci@v0.3` | Updated here; add Dependabot. |
| VS Code extensions | `vscode-docker`, `GitHub.copilot` | `vscode-containers`, `GitHub.copilot-chat` (built into VS Code) | Updated here. |
| Licensing tooling | Editor `-serial -username -password` | Same flags (still documented), plus the Unity CLI `unity license activate` (beta) | See roadmap Phase 0/1. |

## 7. What changed since 2023

### Unity

- **Plans.**
  - Unity Plus is gone; non-renewed Plus accounts became Personal after 2024-03-27.
  - Personal is free up to $200K in revenue and funding (from Unity 6).
  - Pro is about $2,310 per seat per year in 2026.
  - A seat is for **one person**, on up to two computers they use exclusively, with one running instance at a time. An organization cannot mix tiers, so **every reviewer who opens the Editor needs a seat on the organization's tier**.
- **Personal licenses.**
  - Unity's manual still says the Hub is the only official way to activate Personal, and command-line `-serial` activation does not apply to it.
  - The new Unity CLI adds `unity license activate` for Personal, serial and floating licenses (beta).
- **Releases.**
  - Unity 6 LTS streams are 6000.0 (support ends October 2026) and 6000.3 (until December 2027).
  - 6000.6 is the current Update release; Unity 7 is in alpha.
  - The Linux Editor is still x86_64-only. Unity 6 officially supports Ubuntu 22.04 and 24.04; 2022.3 lists Ubuntu 18.04 and 20.04.
- **Unity CLI** (public beta since July 2026, 1.0.0-beta.14 on 2026-10-21). It covers:
  - `install` (any version, by changeset)
  - `license`
  - `vcs diff` (scene/prefab by GameObject and component name), `vcs summarize` (text for PR descriptions) and `vcs blame`
  - `mcp` (an MCP server for AI agents) and `command`
  - Driving a running Editor requires the `com.unity.pipeline` package and **Unity 6.0 or later**.
- **AI.**
  - Unity's first MCP server (inside the AI Assistant package, open beta in May 2026) was **deprecated** about three months later in favour of `unity mcp`.
  - Unity says the MCP server and the CLI are free.
  - Unity also ships an official Claude Code plugin (skills that drive the Editor through the CLI).
- **Terms.** Unity's Terms of Service (updated 2026-06-30) restrict access to Unity "Offerings" by AI agents, MCP clients/servers, CLIs or other automated callers to "Authorized Agentic Access" (sections 17.2(ff)/(gg)). How far that reaches is disputed: Unity staff said informally that automation which only touches your own files is fine, while driving the Editor is covered. This matters for the AI plans; see [§9](#9-constraints-any-next-step-must-respect).
- **Unity Production Pipeline (web).** A Unity Cloud dashboard that connects a GitHub or Unity Version Control repo and lets people without the Editor browse approximate 2D/3D previews of project assets, see changed assets against the base branch, and open pull requests. Closed beta now; "public availability begins in November 2026". This overlaps the PM persona of this project.

### Community and open source

- **GameCI** publishes `unityci/editor` images (Ubuntu 22.04, 3.6-5.3 GB) for essentially every final Unity release, usually within days. One of them plus this repo's desktop layer ran the Editor GUI in the test above.
- **PrefabLens** (Apache-2.0, v0.11.0, created June 2026) provides semantic UnityYAML diffs through a CLI with JSON output, a Chrome extension inside GitHub pull requests, and an Editor package. It is young, with a single maintainer.
- **Community MCP servers** that support older Editors:
  - [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp): MIT, about 15k stars, Unity 2021.3+, has screenshots and a headless CI harness.
  - [IvanMurzak/Unity-MCP](https://github.com/IvanMurzak/Unity-MCP): Apache-2.0, Unity 2022.3+, has isolated-object renders.
  - None of these diffs git refs.
- **Look-alikes.** A couple of 2026 hobby repos (`tahasiraj97/simple-unity`, `celino/ksp-moddev`) run GameCI images plus a noVNC desktop with Personal sign-in. Older ones (2021-2023) are abandoned. This repo is still the most complete Codespaces-specific template found.

### Platforms

- **Codespaces** no longer has GPU machines (deprecated by 2025-08-29), so the Editor renders on the CPU.
  - Free personal accounts get 120 core-hours a month, which is 15 hours on the 8-core machine this repo requires.
  - Recommended `secrets` in devcontainer.json now prompt users on the create page.
  - `codespaces.new` deep links can preselect the machine and config.
- **Dev containers.**
  - Features and Templates are published as OCI artifacts and listed on containers.dev, which has no Unity entries.
  - VS Code reads MCP server configuration from `customizations.vscode.mcp`.
  - Lockfiles and Dependabot support exist.
- **Hosts.**
  - Gitpod is now **Ona**.
  - **Coder** supports dev containers.
  - Upstream DevPod has stalled, though a fork is active.
  - Daytona pivoted to AI sandboxes, and Microsoft Dev Box is being retired.
  - The dev container spec is the portable bet.

## 8. Alternatives: better, worse, or complementary?

The verdict is relative to this project's goal: let reviewers and PMs inspect a PR's Unity changes without a local clone or install, and shorten review time.

| Alternative | What it is | Verdict | Why |
|---|---|---|---|
| Unity Production Pipeline web | Unity Cloud dashboard with browser previews of a GitHub/UVCS repo's assets | **Better for PMs** once it is public (Nov 2026), if you are on Unity Cloud | No Editor install, no seat activation, no 10-minute boot. But previews are approximate (custom shaders and lighting may differ), it is hosted, setup needs an Org Owner, and pricing and Editor-version coverage are not published yet. |
| PrefabLens | Semantic YAML diff in GitHub PRs (Chrome extension), CLI, Editor package | **Better for "what changed?"**, complementary overall | Instant, free, no license. Text only, so you cannot see how it looks. Young project. |
| Unity CLI `vcs diff` / `vcs summarize` | Official semantic diff and PR summaries | **Complementary** | Official and free, but beta; whether it needs sign-in is undocumented. Use its output instead of writing a differ. |
| Unity CLI `unity mcp` + Pipeline | Official MCP for agents driving a live Editor | **Complementary** (Unity 6+ only) | The right path for Unity 6 images; it does not support 2022.3. |
| Community MCP servers (CoplayDev, IvanMurzak) | Live-Editor bridges for agents | **Complementary** | Cover 2021.3/2022.3. They drive the Editor, so check the ToS position first. |
| GameCI images and actions | CI Editor images for every version | **Complementary**: build on them | Headless by design, but the GUI works with a desktop layer (tested). Large, run as root, rate-limited on Docker Hub. |
| Unity Version Control code reviews | Review flow inside UVCS | Different use case | Helps UVCS shops, not GitHub PRs; no documented visual scene diff. |
| Unity Asset Manager / Unity Studio | Cloud asset library / browser 3D authoring | Different use case | Upload-based; does not show what a Git PR changed. |
| Unity Build Automation share links | Cloud builds | Complementary | Answers "does it play right?", not "what changed in this prefab?". |
| Anchorpoint, Diversion, Perforce P4 | Asset-aware version control | Different use case | Generic 3D previews and their own review flows; switching VCS. |
| Parsec, Amazon DCV, Vagon, AVD/Windows 365 | Remote GPU desktops | Worse for PR review | Full GPU fidelity, but cost and setup, no per-PR environment, no PR integration. |
| Ona, Coder, DevPod fork | Other dev container hosts | Complementary | The same devcontainer.json can run there, including on GPU nodes. |

**Has Unity built something better?**

- Unity has built most of the *building blocks*: editor install, licensing, semantic diffs and MCP, all in the CLI.
- For PMs on Unity Cloud, Unity has a *viewer* that will likely beat a codespace from November 2026.
- Unity has not built a *disposable, PR-scoped, full-fidelity Editor* that runs anywhere the dev container spec runs, supports pre-Unity-6 projects, and is shared by a human and an AI agent.
- Unity has also not built visual before/after evidence on pull requests. The roadmap recommends focusing there.

## 9. Constraints any next step must respect

**Licensing**

- Every person who opens the Editor needs their own seat on the organization's tier: one person, two machines, one instance at a time. A codespace counts as a machine.
- Activations must be returned, or seats run out. There is no dev container "on delete" hook, so returning needs an explicit command, or floating licenses (Enterprise/Industry), whose leases expire on their own.
- Personal licenses: officially Hub-only. The Unity CLI (beta) adds a command-line path.
- Publishing images that contain the Unity Editor is not clearly covered by Unity's terms, which grant install-and-run rights for authorized users and redistribution rights only for the Runtime. GameCI publishes such images anyway; that is precedent, not permission.
- AI and automation: Unity's 2026-06-30 Terms limit automated, agent and MCP access to Unity offerings to "Authorized Agentic Access". The safest design keeps AI features on **files in git** (YAML diffs) by default, and makes anything that drives the Editor opt-in, preferably through Unity's own CLI.

**Platform**

- Secrets are only available at **runtime** (lifecycle scripts), never at build time or in features, and never in prebuilds.
- Reviewers without write access, and codespaces on fork PRs, get **no secrets**.
- There are no GPUs in Codespaces, and the Linux Editor is x86_64-only (Apple Silicon local Docker is not supported).
- The dev container lifecycle has no stop or delete hook.
- New GHCR packages are private, and making one public cannot be undone.
- Docker Hub rate-limits anonymous pulls (relevant to GameCI bases).

## 10. Method, limits, and sources

**Method.** The assessment used:

- nine parallel research tracks: links, dependencies, a live build test, licensing, multi-version design, alternatives, AI/MCP, code review, and onboarding;
- a second pass of skeptics who tried to refute the load-bearing claims against primary sources;
- an empirical run of the dev container CLI against the repo's consumer config.

Docker tests ran on amd64 with the repo's scripts unmodified.

**Limits.** No Unity credentials were used, and nothing was run inside a real codespace. Statements about Codespaces behaviour come from GitHub's documentation and the dev container CLI's source and behaviour. Market statements, such as "nothing renders before/after images on PRs", are absence-of-evidence findings as of this date.

**Key sources**

- GitHub: [Codespaces secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces), [prebuild configuration](https://docs.github.com/en/codespaces/prebuilding-your-codespaces/configuring-prebuilds), [recommended secrets](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/configuring-dev-containers/specifying-recommended-secrets-for-a-repository), [package visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility), [GPU deprecation](https://github.blog/changelog/2025-08-01-upcoming-deprecation-of-gpu-machine-type-in-codespaces), [Node 20 removal](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/), [`set-output` deprecation](https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/)
- Dev containers: [JSON reference](https://containers.dev/implementors/json_reference/) (`localEnv` defaults, `portsAttributes`), [image metadata merge rules](https://containers.dev/implementors/spec/#merge-logic), [desktop-lite feature](https://github.com/devcontainers/features/tree/main/src/desktop-lite)
- Unity:
  - Releases and support: [release API](https://services.api.unity.com/unity/editor/release/v1/releases?version=6000&limit=25), [Unity 6 support](https://unity.com/releases/unity-6/support), [2022.3 system requirements](https://docs.unity3d.com/2022.3/Documentation/Manual/system-requirements.html)
  - Licensing: [license activation methods](https://docs.unity.com/en-us/engine/6000.3/manual/get-started/install-and-upgrade/licenses-and-activation/license-activation-methods), [command-line licensing](https://docs.unity3d.com/2022.3/Documentation/Manual/ManagingYourUnityLicense.html), [Unity Plus retirement](https://support.unity.com/hc/en-us/articles/35060816844436-What-happens-when-my-Unity-Plus-subscription-expires), [pricing](https://unity.com/products/pricing-updates)
  - Terms: [Editor Software Terms](https://unity.com/legal/editor-terms-of-service/software), [Terms of Service](https://unity.com/legal/terms-of-service)
  - Unity CLI and AI: [CLI reference](https://docs.unity.com/en-us/unity-cli/unity-cli-reference), [CLI release notes](https://docs.unity.com/en-us/unity-cli/release-notes), [MCP replacement](https://docs.unity.com/en-us/unity-cli/replace-mcp-server-unity-cli)
  - Other: [Unity Production Pipeline](https://unity.com/features/unity-production-pipeline), [CVE-2025-59489](https://unity.com/security/sept-2025-01)
- Community: [GameCI images](https://hub.docker.com/r/unityci/editor), [GameCI activation](https://game.ci/docs/github/activation), [PrefabLens](https://github.com/hashiiiii/PrefabLens), [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp), [IvanMurzak/Unity-MCP](https://github.com/IvanMurzak/Unity-MCP)
