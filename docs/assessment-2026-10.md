# Project assessment: October 2026

Snapshot of `main` at `1ee7c38` (then the repository's only commit, 2023-12-28), assessed on 2026-10-28.
Updated on 2026-11-13 with the results of [pull request #4](https://github.com/gblikas/unity-desktop-lite/pull/4), which fixes part of what is listed here.
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
| Does the image still build? | **No, not as written.** The unpinned base `mcr.microsoft.com/devcontainers/base:ubuntu` now resolves to **Ubuntu 26.04**. The copied desktop script fails there (and on 24.04) at `libasound2`, and Unity 2022.3.11f1 itself cannot start on 26.04. Pinned to Ubuntu 22.04 (pull request #4), the full Dockerfile builds, including UnitySetup installing Unity and Android, and the Editor starts and reaches Unity's license dialog over noVNC (tested with Docker, see [§4](#4-live-build-and-run-test)). |
| Is the license flow sound? | **No, and pull request #4 replaces it.** Unity credentials went into a dev container *feature*, which runs at image build time. GitHub documents that Codespaces secrets cannot be used there. A test with the dev container CLI showed the password printed to the build log 3 times per build (5 on failure). A password containing `$(…)` ran as a command as root. Seats were never returned, and the "optional" `VNC_PASSWORD` failed the build when unset. Pull request #4 activates at container start instead. That was tested with a stand-in Unity binary ([§4](#4-live-build-and-run-test)), not yet with a real Unity seat. |
| Is it up to date? | **No.** Unity 2022.3 is out of public support, and the pinned patch is 51 patch versions behind the last public 2022.3 release. Unity Plus no longer exists. The copied desktop script is upstream v1.0.7 (January 2023); upstream is v1.2.10. noVNC, websockify, the GitHub Actions and the VS Code extension IDs are years old. |
| Has someone, or Unity, built something better? | **Partly.** <ul><li>Unity now ships an official **Unity CLI** (beta). It installs any Editor, activates licenses (including Personal), produces semantic scene/prefab diffs (`vcs diff`, `vcs summarize`, `vcs affected`) and runs an MCP server for AI agents (`unity mcp`, Unity 6+ only).</li><li>**Unity Production Pipeline** web (closed beta; public from November 2026) lets people without the Editor browse a GitHub repo's assets. Unity markets "real game renders" and agents working alongside people, though its docs describe the 3D previews as approximations.</li><li>**PrefabLens** shows semantic prefab/scene diffs inside GitHub pull requests.</li><li>We found nothing that posts **rendered before/after images** of changed scenes and prefabs on a PR. Building blocks exist.</li></ul>What remains distinctive about this project: your project in the real Editor (software-rendered, no GPU) in any dev container host, including Unity versions older than 6. Licensing and support constraints apply (see [§9](#9-constraints-any-next-step-must-respect)). |

The rest of this document is the evidence. [roadmap.md](./roadmap.md) turns it into a plan.

## 2. Health check

| Area | Status | Evidence |
|---|---|---|
| A new user can pull the prebuilt image | ❌ | `ghcr.io/gblikas/unity-desktop-lite/unity-2022/2022.3.11f1` answers an anonymous token request with `UNAUTHORIZED: authentication required`, while non-existent sibling paths answer `DENIED`, so the package exists but is private. GHCR makes packages in a personal account private on first publish ([docs](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)). Codespaces in this repository can still pull it, because it is linked to the repository, but nobody else can. |
| The image rebuilds from source | ❌ → ✅ in pull request #4 | `FROM mcr.microsoft.com/devcontainers/base:ubuntu` is now Ubuntu 26.04.1. The tag moved jammy → noble in May 2025 and → 26.04 in April 2026. `apt-get install libasound2` fails with "no installation candidate" on 24.04 and 26.04. The image builds on 22.04. |
| The Unity Editor runs in the desktop | ✅ 22.04 / 24.04, ❌ 26.04 | Up to Unity's license dialog; no project was opened. See [§4](#4-live-build-and-run-test). |
| Vendor support | ⚠️ | Unity's system requirements say the Editor "is supported on workstations or laptop form factors running without emulation, container, or compatibility layer", with an Nvidia/AMD GPU. 2022.3 lists only Ubuntu 18.04/20.04. Every dev container setup, this one included, is outside Unity's support statement. It works, as tested, but without recourse if Unity changes something. |
| License activation in Codespaces | ❌ by design → ⚠️ reworked in pull request #4, not yet tested with a real seat or in a codespace | Activation happened in a build-time feature fed by `${localEnv:UNITY_*}`. GitHub says secrets "cannot be used ... during codespace build time ... within a dev container feature", and that prebuilds "cannot use any user-level secrets" ([secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces), [prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces/configuring-prebuilds)). Pull request #4 activates in `postStartCommand`, which GitHub documents as able to read secrets. That this also holds for a `postStartCommand` contributed by a feature follows from the dev container CLI's code; it has not yet been observed in a codespace. |
| Credential hygiene | ❌ → ✅ in pull request #4 | Before pull request #4, the dev container CLI echoed every feature option and `set -x` traced the Unity command lines, so the password appeared 3 times per build. Its option env file also executed `$(…)` in values as root, and the file stayed world-readable in the build host's temp directory. The credentials are no longer feature options, so none of this applies now. |
| Seat usage | ❌ (helper added) | `-returnlicense` ran in a fresh build container, where nothing was activated, so it did nothing. Nothing returns a seat when a codespace is deleted, hence the README's "not enough licenses" FAQ. Pull request #4 adds `unity-license return`, which you have to run yourself, since dev containers have no "on delete" hook. |
| CI | ⚠️ | `::set-output` was deprecated, and `actions/checkout@v4` / `docker/login-action@v3` are node20-era majors (fixed in pull request #4). The workflow publishes only `:latest`, and only on push to `main`; since pull request #4 a manual run can also copy a published tag, which is how the December 2023 image got its `:2023-12` tag. The `HEAD^` diff gate misses multi-commit pushes. There is no scheduled rebuild for base-image security updates. Run history from 2023 has been deleted under GitHub's retention rules, but a test run on 2026-11-13 (run number 21) confirmed that the workflow's token can write to the package. |
| Unity version | ⚠️ | 2022.3.11f1 (October 2023). The 2022.3 stream is out of support; its last public patch is 2022.3.62f3 (2025-10-28). Players built with 2022.3.11f1 are affected by [CVE-2025-59489](https://unity.com/security/sept-2025-01). |
| Docs | ⚠️ (fixed in pull request #4) | The README mentioned Unity Plus, had a wrong config path, used `--projectPath`, said the password is "not retained", called a required secret optional, and had a dangling sentence and typos. |
| Community | ℹ️ | 10 stars, 18 forks, 1 open issue (#3, opened 2026-10-28). |

## 3. Links and references

Every URL and external reference in the README and source was checked on 2026-10-28.

### README

| Reference | Where | Result | Action |
|---|---|---|---|
| desktop-lite feature docs | README.md:3 | ✅ Live. But the repo **vendors a 2023 copy** (v1.0.7) of the feature's script instead of using the feature (now v1.2.10). | Use the feature ([roadmap](./roadmap.md)). |
| Codespaces product page | README.md:5 | ✅ Live. Link text said "codepsace". | Fixed. |
| Demo GIF | README.md:7 | ✅ Live. 17 MB, and it shows the 2023 setup. | Consider a compressed MP4 later. |
| `.devcontainer/devcontainer.json` link | README.md:18 | ✅ Live, but the target contradicted "optional" (see defect D6). | Fixed. |
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
| `ghcr.io/gblikas/unity-desktop-lite/unity-2022/2022.3.11f1:latest` | .devcontainer/devcontainer.json:2 | ❌ Private; only a mutable `:latest` tag (plus `:2023-12` since 2026-11-13). | Decision D1 in the [roadmap](./roadmap.md#decisions-for-the-owner). |
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
| `ms-azuretools.vscode-docker` | .devcontainer/devcontainer.json:14 | ⚠️ Superseded by Container Tools; there is no Docker in the image anyway. | Removed. |
| `GitHub.copilot` | .devcontainer/devcontainer.json:14 | ⚠️ Deprecated (VS Code 1.109); Copilot Chat is built in from 1.116. | Removed (built into VS Code). |

## 4. Live build and run test

### 4.1 Image and Editor

Run on 2026-10-28 with Docker on amd64. The repo's scripts were used byte-for-byte; the Unity 2022.3.11f1 Linux tarball was 3.06 GB and its md5 matched the CDN ETag. No license was used, so "GUI works" means the Editor starts and shows Unity's "No valid Unity Editor license found" dialog.

| Base image | Desktop layer (repo `install.sh`) | `UnitySetup` installer | `Unity -version` | Editor GUI over TigerVNC + noVNC |
|---|---|---|---|---|
| `devcontainers/base:jammy` (Ubuntu 22.04) | ✅ 129 s | ✅ `--help` and `--list-components` work, and the download starts | ✅ | ✅ Splash screen plus the license dialog. noVNC answers `101` + `RFB 003.008`. |
| `devcontainers/base:noble` (24.04) | ❌ `libasound2`. ✅ after renaming it to `libasound2t64`. | not run | ✅ | ✅ Same as 22.04. |
| `devcontainers/base:ubuntu` (now 26.04) | ❌ `libasound2`. ✅ after renaming it. | ❌ `libxml2.so.2` missing | ❌ `libxml2.so.2` missing | ❌ Needs a private libxml2 2.9 **and** `GLIBC_TUNABLES=glibc.rtld.execstack=2`, because glibc 2.43 refuses the Licensing Client's executable-stack `libbindings.so`. |
| GameCI `unityci/editor:ubuntu-2022.3.11f1-base-3.2.2` (22.04) + the repo's desktop script, with `sudo` and a `vscode` user added by hand (GameCI images run as root) | ✅ 165 s | n/a (Editor preinstalled) | ✅ | ✅ Same as 22.04. Not tested: the `common-utils` + `desktop-lite` feature combination. |

Also observed:

- **Full Dockerfile, as in pull request #4** (pinned `3-jammy`, the repo's UnitySetup step with `--components=Unity,Android`). Every build step completed. In October the final image export ran out of the test machine's disk; on 2026-11-13 the pull request's CI run and a local run both built and exported the complete image (9.8 GB). The Unity layer is about 8.5 GB uncompressed: 6.3 GB of Editor and 2.2 GB of Android Build Support. UnitySetup also moves about 630 MB of installer leftovers to `/root/.local/share/Trash` instead of deleting them; pull request #4 deletes those, and CI now frees runner disk before building.

- The current upstream desktop-lite script (feature v1.2.10, noVNC 1.6.0) builds and serves on 24.04 and 26.04.
- `UnitySetup` is a GTK3 program. It only runs because the desktop script installs GTK3 first, so the Dockerfile's step order matters.

Not covered by this test: license activation (no credentials were available), opening or importing a real project, Codespaces-specific behaviour (port forwarding, secrets, prebuilds, idle timeout), and the Android module.

### 4.2 The consumer config, run through the dev container CLI

The original `.devcontainer` from `main` was run through `devcontainer build`, with only the private image swapped for `base:jammy`. Two CLI versions were used: 0.90.0 (current) and 0.55.0 (December 2023). Dummy credentials were set in the host environment.

| Check | Result |
|---|---|
| `VNC_PASSWORD` unset | ❌ The build fails with "VNC_PASSWORD is not set". The empty `${localEnv:VNC_PASSWORD}` overrides the feature default. It happens with both CLI versions. |
| Credentials in the build log | ❌ The password is printed 3 times per build: once in the CLI's "Options" banner and once in each of the two `set -x` traces. On failure BuildKit repeats them, for 5 in total. The serial and username are printed too. |
| Password with a space | ❌ Split into two arguments for Unity. |
| Password containing `$(…)` | ❌ **Executed as root during the build.** The CLI writes options to an env file as `NAME="value"` and sources it. A password containing `"` breaks the build. |
| Files left behind | ❌ The generated env file, with the credentials in clear text, stays world-readable under the build host's `/tmp/devcontainercli-*/`. |
| `runArgs` in the image's config | ❌ Not carried into image metadata, so consumers got a 64 MB `/dev/shm` and no init process. `forwardPorts` and `overrideCommand` are carried. |

### 4.3 Runtime activation (pull request #4)

`.devcontainer` from pull request #4 was run with `devcontainer up` against a stand-in image: the real devcontainers base plus fake `Unity` and `vncpasswd` binaries that record their arguments. Codespaces secrets were simulated with `--remote-env`.

| Check | Result |
|---|---|
| Activation when the container starts | ✅ Runs as the `vscode` user. The password reaches Unity as a single argument. The license file is mode 600, in a directory with mode 700. Unity's log is removed after a successful activation and kept (mode 600) after a failed one. |
| Credentials in build or start-up logs | ✅ None. The feature has no options, and image metadata and history hold no secret. |
| Restart | ✅ "A Unity license file is already present", with no second activation. `unity-license activate --force` replaces the file and activates again; if that fails, the old file is put back. |
| `unity-license return` / `status` | ✅ With the stand-in, the seat is returned and the status reflects it. `return` goes by Unity's log rather than its exit status: GameCI's logs of real seats and the Editor's own code show that the Editor exits with an error after it has returned a named-user license. The stand-in imitates that. |
| No secrets set | ✅ The codespace still starts, with a message naming the missing secrets. `return` names the missing secrets and exits 1. |
| `VNC_PASSWORD` | ✅ Applied at start (mode 600, owned by the desktop user). Without it, the image default is kept. |
| `/dev/shm` and init | ✅ 6 GB and `--init`, from the consumer config. |

A separate check against a real TigerVNC server (the repo's desktop layer) found that it offers only VNC password authentication (RFB security type 2). A `VNC_PASSWORD` set at runtime was accepted on the next connection without restarting the server, and the old password was rejected.

On 2026-11-13 the same config was also run against the real image, built from this repository's Dockerfile, with made-up credentials. The real Editor ran and the activation failed, as it should:

- the container still started, and `unity-license return` and `activate --force` reported the failure;
- nothing secret appeared in the output or in Unity's log (mode 600);
- `/dev/shm` was 6 GB, with an init process;
- a `VNC_PASSWORD` set at start was accepted by the desktop's own VNC server, and the image's default password was rejected;
- started by hand, the Editor's window reached Unity's "No valid Unity Editor license found" dialog.

A real Unity activation was not tested (no Unity seat in this environment).

## 5. Defects

Ordered by severity. "PR #4" means it is fixed by [pull request #4](https://github.com/gblikas/unity-desktop-lite/pull/4). These defect numbers (D1-D20) are separate from the decision numbers (D0-D7) in the roadmap.

| ID | Severity | Where | Problem | Fix | Status |
|---|---|---|---|---|---|
| D1 | Critical | .devcontainer/devcontainer.json:2, README.md:20 | The README's image is private, so nobody but the owner can follow the README (issue #3). It also had only a mutable `:latest` tag; the December 2023 image is now tagged `:2023-12` as well. | Do **not** make it public: Unity's terms grant no right to redistribute the Editor (see [§9](#9-constraints-any-next-step-must-respect)). Install the Editor from Unity per user instead ([roadmap](./roadmap.md)). Meanwhile the README gives a self-build workaround. | Workaround documented |
| D2 | Critical | Dockerfile:1 | The unpinned base now gives Ubuntu 26.04: the build fails, and Unity 2022.3 cannot run there. | Pin to `mcr.microsoft.com/devcontainers/base:3-jammy`. | PR #4 |
| D3 | High | local feature install.sh:47; devcontainer.json:5-8 | The Unity password (3 times per build) and serial were printed to the build/creation log, by `set -x` and by the dev container CLI's echo of feature options. | Credentials are no longer feature options; activation reads them at runtime. | PR #4 |
| D4 | High | devcontainer.json:4-9; local feature | License activation ran at **image build time**. That contradicts GitHub's secrets model, cannot work with prebuilds (which get no user secrets), and would store the activated license, with a recoverable serial, in an image layer. With repo-level secrets it would share one person's seat with everyone. | Activate in `postStartCommand` from environment secrets, declared in a devcontainer.json `secrets` block. | PR #4 (tested with a stand-in) |
| D5 | High | local feature install.sh:49-56 | Seats are never returned. `-returnlicense` in a fresh container is a no-op, and each new codespace or rebuild may consume an activation (a paid seat allows two machines; but see D20). | `unity-license return`, documented My Seats cleanup, and one long-lived codespace per person. For teams, floating licenses. | Helper added; the user must run it |
| D6 | Medium | devcontainer.json:8 | The "optional" `VNC_PASSWORD` was required: `${localEnv:VNC_PASSWORD}` becomes `""`, which overrides the feature's default and makes install.sh exit 1. | Read at runtime; the image default is used when unset. | PR #4 |
| D7 | High | local feature install.sh:50-65; dev container CLI env file | Credentials were unquoted, so a password with a space was split into two arguments. Worse, the CLI writes feature options to an env file as `NAME="value"` without escaping and sources it, so `$(…)` in a password **ran as root** during the build (tested), and `"` broke the build. | Credentials are no longer feature options; all expansions are quoted. | PR #4 |
| D8 | Medium | unity-2022/.../devcontainer.json:6 | `runArgs` (`--shm-size=6gb`, `--init`) are not part of image metadata, so consumers ran with a 64 MB `/dev/shm` and no init. | `"init": true` and `runArgs` in the consumer config. | PR #4 |
| D9 | Medium | workflow | Only `:latest` is published, and only on push to `main`; tag and manual runs never publish. There was no `permissions` block, and new personal repos default to a read-only token. | `permissions` added in pull request #4, plus a manual re-tag option that keeps rollback points (the 2023 image is kept as `:2023-12`). Versioned `imageTag` still to do. | Partly fixed |
| D10 | Medium | workflow:40 | `git diff HEAD^ HEAD` only inspects the last commit, cannot be forced, and treats git errors as "changed". There is no schedule for base-image updates. | Path filters or `github.event.before`, a `force` input, a weekly schedule. | Open |
| D11 | Low | workflow | Deprecated `::set-output`; node20-era action majors. | `$GITHUB_OUTPUT`, `checkout@v7`, `login-action@v4`. | PR #4 |
| D12 | Low | unity-install.sh, install.sh | Downloads are executed as root without checksums; action tags are mutable. | Verify md5/sha256 and pin actions by SHA. | Open |
| D13 | Low | unity-install.sh:25 | The Android module (0.66 GB download, 2.2 GB in the image) is installed by default but is not needed to view scenes. | Editor-only by default. | Open |
| D14 | Low | unity-2022/.../install.sh | The vendored desktop script is frozen at v1.0.7. The desktop only starts for consumers because `overrideCommand: false` survives in the image label. | Use `ghcr.io/devcontainers/features/desktop-lite:1`. | Open |
| D15 | Low | local feature install.sh:25 | The VNC password was baked into the image and world-readable. TigerVNC uses only the first 8 characters and stores it reversibly. | Set at runtime, mode 600, owned by the desktop user. The 8-character limit remains (TigerVNC). | PR #4 |
| D16 | Low | README.md | Inaccurate or stale statements and typos. | Corrected; known issues and a self-build workaround added. | PR #4 |
| D17 | Low | unity-install.sh:25 | `yes \|` accepts Unity's license agreement on the user's behalf. | Let each user accept Unity's terms, for example via an explicit opt-in. | Open |
| D18 | Low | Dockerfile (`VNC_RESOLUTION=1440x768x16`) | The desktop uses 16-bit colour, which bands gradients and is unsuitable for judging art. | 24-bit (`…x24`), after measuring the bandwidth cost. | Open |
| D19 | Medium | unity-install.sh; workflow | UnitySetup leaves about 630 MB of installer files in `/root/.local/share/Trash`. The Unity layer (about 8.5 GB uncompressed without them) needs roughly twice that free disk to build and export. GitHub documents 14 GB of disk for its standard runners, although the runner that built pull request #4 had 110 GB free after the cleanup. | Delete the leftovers in the same `RUN`; free runner disk before building. The step prints the free space before and after, to show whether it is still needed. | PR #4 |
| D20 | Medium | Dockerfile (desktop layer) | The image contains `/var/lib/dbus/machine-id`, created when the image is built, and its `/etc/machine-id` is empty. Unity's licensing client takes its machine id from that file, so every container started from the same image reports the same machine (seen in two containers on 2026-11-13; the December 2023 image was built the same way). How Unity's servers treat this is not known: several codespaces may count as one machine, and a return in one may end the activation of the others. It also bears on [§9](#9-constraints-any-next-step-must-respect)'s point about reusing machine identities. | Decide first (roadmap, seat-accounting spike). To give each container its own identity, delete the file at the end of the build; dbus creates a new one when the desktop starts. | Open |

## 6. Dependency freshness

| Item | In repo | Current (2026-10-28) | Recommendation |
|---|---|---|---|
| Base image | `devcontainers/base:ubuntu` (floating; jammy until May 2025, noble until May 2026, now 26.04) | `3-jammy` (22.04), `3-noble` (24.04), `3-resolute` (26.04) | `3-jammy` for 2021.3/2022.3 (Ubuntu 22.04 support ends May 2027); `3-jammy` or `3-noble` for Unity 6. Never the floating `ubuntu` tag. |
| Desktop | Copy of desktop-lite v1.0.7 (2023-01) | Feature v1.2.10 (2026-07) | Use the feature. |
| noVNC / websockify | 1.2.0 / 0.10.0 | 1.7.0 / 0.13.0 (feature default 1.6.0) | Comes with the feature. |
| Unity | 2022.3.11f1 (`d00248457e15`) | 2022.3.62f3 is the last public 2022.3; later 2022.3 patches are Enterprise/Industry-only. **6000.3.27f1 LTS** (supported to Dec 2027); 6000.6.7f1 (current Update release); 6000.0 LTS public support ends Oct 2026. | Install the Editor version the project uses (roadmap Phase 1). Test 6000.3 LTS and 2022.3.62f3. |
| Unity installer | `UnitySetup-<ver>` (GTK3 binary, undocumented; `yes \|` accepts the license) | `LinuxEditorInstaller/Unity-<ver>.tar.xz` (documented, md5 published), or Unity's own CLI `unity install <ver> --changeset …` (beta) | Prefer Unity's own tooling; fall back to the documented tarball. |
| Actions | `checkout@v4`, `login-action@v3`, `ci@v0.3` | `checkout@v7`, `login-action@v4`, `ci@v0.3` | Updated in pull request #4; add Dependabot. |
| VS Code extensions | `vscode-docker`, `GitHub.copilot` | Container Tools replaced the Docker extension; Copilot Chat is built into VS Code | Removed in pull request #4: the image has no Docker, and Copilot is built in. |
| Licensing tooling | Editor `-serial -username -password`, at build time | Same flags (still documented), plus the Unity CLI `unity license activate` (beta) | Runtime activation in pull request #4. |

## 7. What changed since 2023

### Unity

- **Plans** ([pricing](https://unity.com/products/pricing-updates)):
  - Unity Plus is gone: Plus could not be renewed after 2024-03-27, and accounts converted to Personal at the end of their term.
  - Personal is free up to $200K in revenue and funding (since Unity 6).
  - Pro costs $2,310 per seat per year from 2026-01-12.
  - A named or serial seat is for **one person**, on a primary and a secondary computer, with one running instance at a time (Editor Software Terms §2.8). An organization cannot have members on tiers with different thresholds at the same time (§1.1).
  - So, outside floating licenses (Enterprise/Industry, served by an on-premises Licensing Server), every reviewer who opens the Editor needs their own seat on the organization's tier. Nobody can run their seat locally and in a codespace at the same time.
- **Personal licenses.**
  - Unity's manual says the Hub is the only way to activate or return Personal. Command-line `-serial` activation does not apply to it, and manual `.ulf` activation is closed to Personal.
  - The Unity CLI (beta) added `unity license activate` for Personal, serial and floating licenses (2026-06-16). Its sign-in is browser-based or uses a service account.
  - A Unity support article (2026-09-01) warns that 2022.3 and older Editors launched without the Hub may not load newly issued manual named-user licenses, and points to Licensing Client 1.18.3 as the workaround. This is relevant because this project launches the Editor without the Hub.
- **Releases.**
  - Unity 6 LTS streams are 6000.0 (public support ends October 2026) and 6000.3 (until December 2027).
  - 6000.6 is the current Update release; Unity 7 is in alpha.
  - The Linux Editor is still x86_64-only.
  - Unity's system requirements exclude containers and emulation, and call for an Nvidia/AMD GPU: Ubuntu 22.04/24.04 for Unity 6, 18.04/20.04 for 2022.3.
- **Unity CLI** (public beta since July 2026; 1.0.0-beta.14 on 2026-10-21; free):
  - `install` (any version, by changeset; `--download-directory`) and `terms accept`
  - `license`
  - `vcs diff` (scene/prefab by GameObject and component name; needs Force Text serialization; prefab overrides are flagged rather than attributed), `vcs summarize` (text for PR descriptions), `vcs affected` and `vcs blame`
  - `mcp` (an MCP server for AI agents) and `command`
  - Driving a running Editor requires the `com.unity.pipeline` package (experimental) and **Unity 6.0 or later**.
  - It sends a usage ping on every run that cannot be disabled.
- **AI.**
  - Unity's first MCP server (in the AI Assistant package, open beta in May 2026) was **deprecated** about three months later in favour of `unity mcp`.
  - Unity says the MCP server and the CLI are free, with no AI credits.
  - There is an official Claude Code plugin: skills that drive the Editor through the CLI, on Unity 6+.
- **Terms.** Unity's [Terms of Service](https://unity.com/legal/terms-of-service), updated 2026-06-30, add restrictions that bear directly on this project. "Offerings" include Unity's software, so the Editor and the Unity CLI are covered.
  - **§17.2(ff)** forbids accessing or instructing any Offering through an AI agent, LLM, *command line interface*, MCP client or server, or any other automated caller, unless via "Authorized Agentic Access". That requires *all* of: routing through a gateway operated or designated by Unity; an agent, model and MCP client/server each authorized by Unity (for example on a published allowlist); and compliance with the Terms. Unity can revoke an authorization at any time.
  - **§17.2(gg)**, a separate rule, forbids developing, distributing or using any plugin or integration that interfaces with an Offering without Unity's prior written authorization, which can include authorization through its Documentation or Policies.
  - **The lead-in** to §17.2 exempts what the Terms, Policies or Documentation expressly authorize. It also says an automated caller acting on a third party's instructions counts as making the Offering available to that third party.
  - **Other clauses:** §17.2(b) bars uploading the Software to a network or file-sharing service, or offering it through hosting or SaaS. §17.2(l) bars automated downloading. §17.2(d) bars defeating Unity's technical protections.
  - **Staff comments are informal.** In a [Unity Discussions thread](https://discussions.unity.com/t/new-terms-of-service-is-unity-restricting-local-ai-tools-and-ai-training/1724661/21) (July 2026), Unity's Principal Advocate wrote that automation which only touches your own files is fine, that driving the Editor is "where the terms come into play", and that third-party tools would be vetted before enforcement. He also said these posts are not legal guidance. No formal clarification was found.
  - *This document is not legal advice.*
- **Unity Production Pipeline (web).**
  - A Unity Cloud dashboard that connects a GitHub (Personal Access Token) or Unity Version Control repo. It lets people without the Editor browse project assets with 2D/3D previews, see changed assets against the base branch, and create pull requests from edits made in the web UI.
  - Unity's product page promises "real game renders ... not proxy screenshots" and "a producer, an artist, and an agent" working on the same project. Its docs call the 3D previews "an approximation", where custom shaders, materials and lighting may differ.
  - Setup needs an Organization Owner and a Build Profile path, a Unity 6 feature, so 2022.3 projects may not qualify (undocumented).
  - It is not a way to review an existing PR.
  - It is a closed beta "not yet supported for production use", with public availability from November 2026 and unannounced pricing (subscription plus cloud consumption). Unity Cloud processes the repository's assets.

### Community and open source

- **GameCI** publishes `unityci/editor` images (Ubuntu 22.04; base images about 3-5.3 GB compressed) for every final release of 2021.3, 2022.3 and 6000.x.
  - About half appear within a day, 87% within a week, with occasional multi-week gaps.
  - One of them, plus this repo's desktop layer, ran the Editor GUI in the test above.
  - No permission from Unity to redistribute the Editor was found; GameCI's practice is precedent, not permission.
  - Docker Hub's documented anonymous limit is 100 pulls per 6 hours per IP.
- **PrefabLens** (Apache-2.0, v0.11.0, created June 2026) provides semantic UnityYAML diffs through a local CLI with JSON output, a Chrome extension inside GitHub pull requests, and an Editor package.
  - The extension asks for the classic `repo` OAuth scope, which is read/write access to all your private repositories, so prefer the CLI for studio code.
  - It is young and has a single maintainer.
- **Community MCP servers** that support older Editors:
  - [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp): MIT, about 15k stars, Unity 2021.3+, screenshots, and a headless CI harness that runs Claude Code against Unity.
  - [IvanMurzak/Unity-MCP](https://github.com/IvanMurzak/Unity-MCP): Apache-2.0, Unity 2022.3+, isolated-object renders.
  - None of these diffs git refs, and all of them drive the Editor (see §17.2(ff)/(gg) above).
- **Rendering building blocks.** [hatayama/unity-cli-loop](https://github.com/hatayama/unity-cli-loop) (`uloop screenshot --prefab-path`, MIT) renders a prefab to a PNG through the real Editor. No tool was found that posts before/after renders on PRs.
- **Look-alikes.** A couple of 2026 hobby repos (`tahasiraj97/simple-unity`, `celino/ksp-moddev`) run GameCI images plus a noVNC desktop with Personal sign-in. Older ones (2021-2023) are abandoned.
- **Who uses this repo.** The 18 forks show three patterns:
  - several dropped `hostRequirements` to 4 CPUs;
  - several replaced the private image or removed the license feature, or self-built another 2022.3 version;
  - one followed README step 3 and deleted the only way to get the Editor.

  The users who showed up look like hobbyists and students, not studio PMs.

### Platforms

- **Codespaces** no longer has GPU machines (deprecated by 2025-08-29), so the Editor renders on the CPU.
  - Free personal accounts get 120 core-hours a month, which is 15 hours on the 8-core machine this repo requires.
  - Free accounts also get only 15 GB-month of storage. A custom image counts toward it, and the Editor alone installs at 6-9 GB.
  - Recommended `secrets` in devcontainer.json (available since April 2023) prompt users on the create page.
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
| Status quo: local clone or worktree in a second Editor | What reviewers with a seat do today | **The baseline to beat** | Free for seat holders, GPU-rendered, warm `Library/`. A fresh codespace must download the Editor and import the whole project first. |
| Unity Production Pipeline web | Unity Cloud dashboard with browser previews of a GitHub/UVCS repo's assets | **Better for browsing assets** if you are on Unity Cloud and Unity 6; not for reviewing existing PRs | No Editor install and no 10-minute boot. But it is closed beta until November 2026, previews are approximate per its docs, setup needs an Org Owner plus a Personal Access Token, Unity Cloud processes your assets, and pricing and seat rules are unannounced. |
| PrefabLens | Semantic YAML diff: local CLI, a Chrome extension in GitHub PRs, and an Editor package | **Better for "what changed?"**, complementary overall | Free, and the CLI needs no license or token. Text only, so you cannot see how it looks. The extension needs the broad `repo` OAuth scope. Young project. |
| Unity CLI `vcs diff` / `summarize` / `affected` | Official semantic diff and PR summaries | **Complementary** | Official and free, but beta. It is a Unity Offering, so automated use falls under §17.2(ff), and whether it needs sign-in is undocumented. Prefer it over writing a differ once that is clear. |
| Unity CLI `unity mcp` + Pipeline | Official MCP for agents driving a live Editor | **Complementary** (Unity 6+ only) | Unity's sanctioned path for agents, but beta/experimental, and it does not support 2022.3. |
| Community MCP servers (CoplayDev, IvanMurzak) | Live-Editor bridges for agents | **Complementary**, with legal risk | Cover 2021.3/2022.3, but they drive the Editor without Unity's authorization (§17.2(ff)/(gg)). |
| GameCI images and actions | CI Editor images for every version | **Complementary** | Headless by design, but the GUI works with a desktop layer (tested). Large, run as root, rate-limited on Docker Hub. Redistribution permission unknown. |
| Unity Version Control code reviews | Review flow inside UVCS | Different use case | Helps UVCS shops, not GitHub PRs; no documented visual scene diff. |
| Unity Asset Manager / Unity Studio | Cloud asset library / browser 3D authoring | Different use case | Upload-based; does not show what a Git PR changed. |
| Unity Build Automation share links | Cloud builds | Complementary | Answers "does it play right?", not "what changed in this prefab?". |
| Anchorpoint, Diversion, Perforce P4 | Asset-aware version control | Different use case | Generic 3D previews and their own review flows; switching VCS. |
| Parsec (Unity-owned), Amazon DCV, Vagon, AVD/Windows 365 | Remote GPU desktops | **A different trade-off** | Real GPU rendering, but cost and setup, no disposable per-PR environment, and no PR integration. |
| Ona, Coder, DevPod fork | Other dev container hosts | Complementary | The same devcontainer.json can run there, including on GPU nodes. |

**Has Unity built something better?**

- Unity has built most of the *building blocks*, all in its CLI: Editor install, licensing, semantic diffs and MCP.
- Unity's Production Pipeline aims squarely at "people without the Editor see the project". From November 2026 it is likely to beat a codespace for browsing a Unity 6 project, if its pricing works for you.
- We found nothing, from Unity or anyone else, that:
  - gives you your own project in the real Editor, inside any dev container host;
  - covers projects older than Unity 6;
  - is open source;
  - or posts visual before/after evidence on pull requests.
- Those are the openings left for this project. They come with real constraints: software rendering, per-seat licensing, and Unity's 2026 Terms.

## 9. Constraints any next step must respect

*This is not legal advice; ask Unity, or a lawyer, before relying on any reading below.*

**Licensing (Unity Editor Software Terms and Terms of Service, both updated 2026-06-30)**

- **What the terms grant.** They grant install-and-run rights for internal use by Authorized Users (people with a seat), plus one backup copy. The only distribution right covers the *Runtime*, not the Editor.
  - §17.2(b) bars uploading the Software to a network or file-sharing service.
  - §2.8 bars third-party providers from running the Editor in the cloud, except on behalf of an Authorized User.
- **What follows.**
  - A public image containing the Editor, or a public-repo prebuild that copies one to every visitor, is outside the grant.
  - A seat holder's own codespace is the reading most consistent with the terms, but it is still worth confirming with Unity.
- **Seats.** A named or serial seat covers one person, two machines and one running instance.
  - A codespace should count as a machine. At present every container started from one image reports the same machine id (defect D20).
  - Nobody should share the desktop with anyone who lacks a seat.
  - Do not reuse one machine identity across codespaces to save activations; that may count as circumventing license limits (§17.2(d), §17.2(i)).
  - Floating licenses (Enterprise/Industry) suit teams. The codespace must be able to reach the on-premises Licensing Server, which usually means a VPN.
- **Returning activations.** Activations must be returned, or seats run out. Dev containers have no "on delete" hook, so this needs an explicit `unity-license return` or the My Seats page.
- **Personal licenses.** Officially Hub-only; the Unity CLI (beta) adds a path. Personal is only for individuals or organizations under $200K, and cannot be mixed with Pro inside one organization.
- **CI rendering.** No license clearly fits. A seat is for one person, the Build License covers "publishing and distributing, but not creating", and Build Server covers builds. Ask Unity first.
- **Automation and AI.**
  - §17.2(ff) covers CLIs and any automated caller, not only AI.
  - §17.2(gg) covers third-party integrations.
  - The safest design keeps AI features on **files in git**, for example YAML diffs with a non-Unity parser.
  - Anything that drives the Editor should be opt-in, used by the seat holder in their own environment, and preferably go through Unity's own CLI once its status is clear.
- **Installing the Editor.** Scripted downloads touch §17.2(l). Using Unity's own documented installers or CLI, and letting each user accept Unity's terms, is the conservative path.
- **Names.** Unity's [trademark guidelines](https://unity.com/legal/branding-trademarks) discourage using "Unity" in the names of your products. That matters before publishing features or templates, and for the repository name itself.

**Platform**

- Codespaces **user** secrets are available only at **runtime** (lifecycle scripts after start), never at build time, in features, or in prebuilds.
- Repository and organization Codespaces secrets *are* available to prebuilds, but anyone who creates a codespace from the repository can read them. Never put Unity credentials there.
- Reviewers without write access, and codespaces created from fork PRs, get **no secrets**.
- There are no GPUs in Codespaces. HDRP needs Vulkan (it does not support OpenGL), so HDRP projects need software Vulkan, which is untested. The Linux Editor is x86_64-only (Apple Silicon local Docker is not supported).
- Unity does not support running the Editor in containers, so anything here is best effort.
- The dev container lifecycle has no stop or delete hook.
- Library import is not cached: `Library/` is not committed, and importing needs a license, which prebuilds cannot hold safely.
- New GHCR packages are private, and making one public cannot be undone.
- Docker Hub rate-limits anonymous pulls (relevant to GameCI bases).

## 10. Method, limits, and sources

**Method.** The assessment used:

- nine parallel research tracks: links, dependencies, a live build test, licensing, multi-version design, alternatives, AI/MCP, code review, and onboarding;
- a verification round in which skeptics tried to refute 35 load-bearing claims against primary sources. Seven needed corrections, which are reflected here, and none was refuted;
- empirical runs of the dev container CLI (versions 0.90.0 and 0.55.0) against the old and new consumer configs;
- a completeness critique and three adversarial reviews of these documents (maintainer realism, user value and risk, technical feasibility).

Docker tests ran on amd64, with the repo's scripts unmodified except for clearly marked sandbox proxy settings.

**Limits.**

- No Unity credentials were used, and nothing was run inside a real codespace.
- Statements about Codespaces behaviour come from GitHub's documentation and the dev container CLI's source and behaviour.
- Market statements such as "we found nothing that ..." are absence-of-evidence findings as of this date.

**Key sources**

- GitHub: [Codespaces secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces), [prebuild configuration](https://docs.github.com/en/codespaces/prebuilding-your-codespaces/configuring-prebuilds), [recommended secrets](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/configuring-dev-containers/specifying-recommended-secrets-for-a-repository), [security in Codespaces](https://docs.github.com/en/codespaces/reference/security-in-github-codespaces), [Codespaces billing](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces), [package visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility), [GPU deprecation](https://github.blog/changelog/2025-08-01-upcoming-deprecation-of-gpu-machine-type-in-codespaces), [Node 20 removal](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/), [`set-output` deprecation](https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/)
- Dev containers: [JSON reference](https://containers.dev/implementors/json_reference/) (`localEnv` defaults, `portsAttributes`), [image metadata merge rules](https://containers.dev/implementors/spec/#merge-logic), [desktop-lite feature](https://github.com/devcontainers/features/tree/main/src/desktop-lite)
- Unity:
  - Releases and requirements: [release API](https://services.api.unity.com/unity/editor/release/v1/releases?version=6000&limit=25), [Unity 6 support](https://unity.com/releases/unity-6/support), [2022.3 system requirements](https://docs.unity3d.com/2022.3/Documentation/Manual/system-requirements.html), [6.3 system requirements](https://docs.unity.com/en-us/engine/6000.3/manual/get-started/install-and-upgrade/getting-started-installing-unity/system-requirements)
  - Licensing: [license activation methods](https://docs.unity.com/en-us/engine/6000.3/manual/get-started/install-and-upgrade/licenses-and-activation/license-activation-methods), [command-line licensing](https://docs.unity3d.com/2022.3/Documentation/Manual/ManagingYourUnityLicense.html), [legacy Editors and manual licenses](https://support.unity.com/hc/en-us/articles/52670753024404), [Unity Plus retirement](https://support.unity.com/hc/en-us/articles/35060816844436-What-happens-when-my-Unity-Plus-subscription-expires), [pricing](https://unity.com/products/pricing-updates)
  - Terms and trademarks: [Editor Software Terms](https://unity.com/legal/editor-terms-of-service/software), [Terms of Service](https://unity.com/legal/terms-of-service), [trademark guidelines](https://unity.com/legal/branding-trademarks)
  - Unity CLI and AI: [CLI reference](https://docs.unity.com/en-us/unity-cli/unity-cli-reference), [CLI release notes](https://docs.unity.com/en-us/unity-cli/release-notes), [MCP replacement](https://docs.unity.com/en-us/unity-cli/replace-mcp-server-unity-cli)
  - Other: [Unity Production Pipeline](https://unity.com/features/unity-production-pipeline), [CVE-2025-59489](https://unity.com/security/sept-2025-01)
- Community: [GameCI images](https://hub.docker.com/r/unityci/editor), [GameCI activation](https://game.ci/docs/github/activation), [PrefabLens](https://github.com/hashiiiii/PrefabLens), [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp), [IvanMurzak/Unity-MCP](https://github.com/IvanMurzak/Unity-MCP), [unity-cli-loop](https://github.com/hatayama/unity-cli-loop)
