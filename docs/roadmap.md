# Roadmap (proposed, October 2026)

This roadmap follows from the [October 2026 assessment](./assessment-2026-10.md). It covers the four directions the owner asked about:

- smoother onboarding;
- more Unity versions;
- how the project compares with other solutions;
- MCP/AI support, so an agent can capture the diffs.

It also takes into account that Unity and others have shipped related tools since 2023.

## Where to aim

**From** "a PM viewer for Unity scenes in a codespace" **to** "open a pull request's Unity project in a real Editor in the browser, together with an AI agent, and put the evidence (semantic diff plus before/after images) on the PR."

Why:

- **The PM-viewer niche is being taken.**
  - Unity Production Pipeline web gives non-Editor users browser previews of a repo's assets (public from November 2026).
  - PrefabLens shows semantic prefab and scene diffs inside GitHub PRs for free.
  - Both avoid this project's two biggest frictions: a roughly 10-minute boot, and a paid Unity seat for every viewer.
- **What nobody offers yet:**
  - a disposable, PR-scoped, full-fidelity Editor that runs wherever the dev container spec runs, including for projects older than Unity 6;
  - that same Editor shared by a human and an AI agent;
  - rendered before/after images of changed scenes and prefabs posted on the PR.

Personas, in priority order:

1. **Reviewers and tech leads** who need to *see* a scene or prefab change without switching branches locally. They already have seats.
2. **AI agents** (Claude Code, Copilot and others) reviewing or working on Unity PRs. They need structured diffs, images, and sometimes a live Editor.
3. **PMs, artists and QA.** Still supported, but the README should point them to Unity Production Pipeline (if they use Unity Cloud) or PrefabLens for quick looks, and here when they need full fidelity (and have a seat).

Design principles:

- **Ship installers and configuration, not Unity binaries.** Each user downloads the Editor from Unity and accepts Unity's terms.
- **Secrets only at runtime.** Never in a Dockerfile, a feature, a prebuild, or a log.
- **License-free by default.** Do as much as possible from the files in git; start the Editor only when needed.
- **Stay on the dev container spec.** The same config should run on Codespaces, Ona, Coder, the DevPod fork, and local Docker.
- **Build on maintained pieces:** the desktop-lite feature, GameCI images, the Unity CLI, and PrefabLens. Re-implement nothing they already do.

## Phase 0: Unblock and stop the leaks (days)

**Done in this branch:**

- [x] Pin the base image to `mcr.microsoft.com/devcontainers/base:3-jammy`. The floating `ubuntu` tag is now 26.04, where the build fails and Unity 2022.3 cannot run. *Merging this rebuilds the image, because the Dockerfile changed.*
- [x] Remove `set -x` from the license feature and quote all credential arguments.
- [x] Make `VNC_PASSWORD` really optional: `${localEnv:VNC_PASSWORD:vscode}`.
- [x] CI: `$GITHUB_OUTPUT` instead of `::set-output`, an explicit `permissions` block, `actions/checkout@v7`, `docker/login-action@v4`.
- [x] Update the VS Code extension IDs (`ms-azuretools.vscode-containers`, `GitHub.copilot-chat`).
- [x] README corrections: plan names, config path, `-projectPath`, the credential-handling FAQ, the prebuild caveat, typos, links.

**Still to do:**

1. **Decide how users get the Editor (decision D1 below), then answer issue #3.** Today only the owner can pull the image.
   - *Stopgap:* make the package public (Package settings → Change visibility; this cannot be undone), add `LABEL org.opencontainers.image.source="https://github.com/gblikas/unity-desktop-lite"` to the Dockerfile, and publish a versioned tag (for example `:2022.3.11f1-<sha>`) besides `:latest`.
   - *Recommended:* skip publishing Editor images and go straight to Phase 1/2. Until then, tell users how to build the image themselves, and keep the `unity-*` and `.github` folders instead of deleting them.
2. **Move license activation to runtime.** This removes the remaining credential leak (the dev container CLI prints every feature option), makes Codespaces secrets and prebuilds work as GitHub documents, and keeps license files out of image layers. Sketch:

   ```jsonc
   // .devcontainer/devcontainer.json (consumer)
   {
     "image": "…",
     "secrets": {                       // Codespaces prompts for these on the create page
       "UNITY_USERNAME": { "description": "Unity ID email used to activate the Editor" },
       "UNITY_PASSWORD": { "description": "Unity ID password; read at container start, never logged" },
       "UNITY_SERIAL":   { "description": "Serial key; leave empty for named-user (assigned) seats" }
     },
     "postStartCommand": "bash .devcontainer/unity-license.sh activate",
     "runArgs": ["--shm-size=2g"],      // runArgs are not inherited from the image
     "init": true,
     "forwardPorts": [6080],
     "portsAttributes": { "6080": { "label": "Unity desktop (noVNC)", "onAutoForward": "openBrowser" } },
     "hostRequirements": { "cpus": 4 }
   }
   ```

   `unity-license.sh` should:
   - read credentials from the environment;
   - never enable xtrace;
   - build the command with a bash array;
   - pass `-serial` with no key when `UNITY_SERIAL` is empty (named-user seats);
   - write Unity's log to a mode-600 file;
   - skip activation if a license file already exists;
   - print a clear "add these secrets" message instead of failing when credentials are missing;
   - provide a `return` sub-command for freeing the seat.
3. **Credential hygiene for past users.** If the old flow ran with real credentials and creation logs were shared or kept, rotate the Unity password and remove stale activations at id.unity.com → My Seats.

*Done when:* a non-owner creates a working codespace by following the README; a canary secret never appears in creation or prebuild logs; and a prebuild succeeds.

## Phase 1: Smoother onboarding (1-2 weeks)

**Goal:** add one file to an existing Unity repo, set secrets once, click a badge, and a browser tab opens with the Unity Editor and the project already loaded.

1. **Publish a feature,** `ghcr.io/gblikas/unity-desktop-lite/features/unity-desktop`, using [`devcontainers/action`](https://github.com/devcontainers/action). It replaces `.devcontainer/local-features`. Its contents:
   - runtime license activation (from Phase 0);
   - a launcher that finds `ProjectSettings/ProjectVersion.txt`, refuses to auto-open on an Editor/project version mismatch (Unity would upgrade the assets), and starts `Unity -projectPath …`;
   - noVNC auto-connect, via a `defaults.json` with `autoconnect`/`resize: remote`, which needs noVNC 1.6 or later;
   - a `unity-doctor` script that checks CPU/RAM/disk/`/dev/shm`, display and noVNC, which secrets are present (names only), license state and version match;
   - Fluxbox menu items: *Open project*, *Doctor*, *Return license*.
2. **Compose maintained features** instead of vendoring:
   - `ghcr.io/devcontainers/features/desktop-lite:1` with `password: noPassword`. The port stays private behind GitHub authentication; or set a password at runtime.
   - `ghcr.io/devcontainers/features/git-lfs:1`, since most Unity repos use LFS.
   - Then delete the copied 400-line `install.sh`.
3. **Publish a template,** `ghcr.io/gblikas/unity-desktop-lite/templates/unity-codespace`, with options for the Unity version and project path. Users can then use VS Code's *Add Dev Container Configuration Files…* or `devcontainer templates apply`. Submit the collection to the [containers.dev index](https://containers.dev/collections), which currently has no Unity entries.
4. **README, badge first.** Add a `codespaces.new` deep link with `devcontainer_path` and a suggested machine, the recommended secrets, a cost table (Free accounts get 120 core-hours a month: 30 h on 4-core, 15 h on 8-core), troubleshooting, and "when to use something else".
5. **Defaults:** `hostRequirements.cpus: 4` as the minimum, with 8 recommended through the deep link; `--shm-size=2g`; `init: true`; do not forward 5901 by default.
6. **Personal-license spike.** Try Unity Hub sign-in inside the noVNC desktop (the only path Unity documents) and the Unity CLI (`unity auth login`, then `unity license activate`, beta). If either works in Codespaces, document it as the free "try it" path.
7. **Tests in CI:**
   - `devcontainer features test` scenarios (`3-jammy` + 2022.3, `3-noble` + 6000.3);
   - smoke checks: noVNC answers, `Unity -version` runs, the launcher finds a fixture project;
   - a **canary test** that fails if a dummy secret appears in any build log.

*Done when:* a first-time user needs at most 3 clicks plus build time, never types a port or VNC password, and gets an actionable message for missing secrets, an exhausted seat limit, or a version mismatch.

## Phase 2: Any Unity version (1-2 weeks, can overlap Phase 1)

**Recommendation: install the Editor with a feature, not with one prebuilt image per version.**

- **Feature `unity-editor`.** Its `version` option accepts:
  - an exact version (`6000.3.27f1`);
  - a stream alias (`6000.3`, `2022.3`, `lts`, `latest`), resolved with the [Unity release API](https://services.api.unity.com/unity/editor/release/v1/releases?version=6000&limit=25);
  - `auto`, which reads `ProjectSettings/ProjectVersion.txt`. That file already contains the changeset, for example `m_EditorVersionWithRevision: 6000.0.52f1 (9e4086222921)`.
- **Install.**
  - Download `https://download.unity3d.com/download_unity/<changeset>/LinuxEditorInstaller/Unity-<version>.tar.xz`. This pattern answered for every release sampled, from 2018.4 to the 7000.x alphas, and the release API lists a Linux x86_64 tarball for each release.
  - Verify the md5 published in `unity-<version>-linux.ini`.
  - Extract with `xz -T0`.
  - Install the Editor only by default; `.tar.xz` modules are optional.
  - This drops the undocumented GTK3 `UnitySetup` installer.
- **`auto` mode.** Install in `onCreateCommand`, where the workspace is available and prebuilds capture the result. Re-check in `postCreateCommand` for PR branches that change the Unity version.
- **Base image per family.**
  - `3-jammy` for 2021.3/2022.3 (in practice; Unity lists only 18.04/20.04 for 2022.3).
  - `3-noble` or `3-jammy` for 6000.x (officially supported).
  - Never the floating `ubuntu` tag.
- **Optional fast base.**
  - GameCI `unityci/editor:ubuntu-<version>-base-3.2.2`, plus `common-utils` (non-root user) and `desktop-lite`. This combination ran the GUI in our test.
  - The feature detects the preinstalled Editor and skips the download.
  - Caveats: Docker Hub rate limits, Ubuntu 22.04 only, images run as root.
- **CI.**
  - A scheduled job regenerates `versions.json` from the release API and opens a PR.
  - A weekly matrix tests the newest patch of each supported stream: 6000.3 LTS, 6000.6, and 2022.3.62f3 as legacy.
  - PRs run two smoke scenarios.
- **Optional private warm images.** A reusable `workflow_call` workflow lets an organization build a **private** prebuilt image for its version with the same feature.
- **Later:** switch the download step to `unity install <version> --download-directory` once the Unity CLI is generally available.

Why this design:

- no Unity binaries are redistributed;
- new Unity releases, Unity 7 included, need no code changes;
- the Editor matches `ProjectVersion.txt` exactly;
- it works with prebuilds.

The trade-off: without a prebuild, the first codespace downloads 3-4.6 GB, about the same as pulling today's image.

**Support policy:**

- *Tier 1:* currently supported Unity streams, with the full feature set (including the official Unity CLI/MCP, which needs Unity 6).
- *Tier 2:* 2021.3 and 2022.3. Install, view and community MCP, best effort.
- Linux x86_64 only; Unity ships no Linux arm64 Editor, so Apple Silicon local Docker is not supported.

## Phase 3: MCP/AI, so agents can capture the diff (2-4 weeks, staged)

### Stage A: license-free, every Unity version (do first)

1. **`unity-diff`**, a small CLI and MCP server with read-only tools:

   | Tool | Input | Output |
   |---|---|---|
   | `list_changed_unity_assets` | `base`, `head` | Changed `.unity`/`.prefab`/`.asset`/`.mat`/... paired with their `.meta`, plus LFS flags |
   | `semantic_diff` | `path`, `base`, `head` | GameObject, component and property changes and prefab overrides, as JSON or markdown |
   | `resolve_reference` | `guid`, `ref` | Asset path (looked up via `.meta` at that ref) |
   | `pr_report` | `base`, `head` | Markdown summary for bots and humans |

   - **Engine:** PrefabLens `--json`, with a pinned version and checksum. Alternatively the Unity CLI's `vcs diff` once it is GA and confirmed not to need sign-in. A small Python fallback covers the rest.
   - **Why YAML, not raw diffs:** Unity YAML (fileIDs, stripped placeholders, `m_Modifications`) makes raw diffs misleading. A prototype turned 63 changed lines into 4 semantic changes.
   - **Packaging:** ship it as a dev container feature that registers the MCP server for VS Code (`customizations.vscode.mcp`), Claude Code (`claude mcp add --scope user`) and the Copilot agent.
2. **PR bot** (GitHub Action). On PRs that touch Unity YAML, it posts or updates one comment with the semantic summary and an "Open this PR in a browser Unity Editor" codespace link. It needs no secrets and no Unity. For PRs from forks, post through a `workflow_run` follow-up.
3. **Zero-effort win now:** point reviewers to the PrefabLens Chrome extension.

### Stage B: visual evidence (needs the Editor, a license and software OpenGL)

4. **Spike.** Render a prefab and a scene with `-batchmode`, *without* `-nographics`, under Xvfb with Mesa llvmpipe, on 2022.3 and 6000.3. Check image quality (URP/HDRP) and timing. `-nographics` produces no images.
5. **Tools `render_snapshot(asset, ref)` and `visual_diff(asset, base, head)`.**
   - A small C# Editor helper renders the scene or prefab, auto-framed, at base and at head.
   - ImageMagick produces a diff image and a side-by-side.
   - The images are added to the PR comment, hosted on an orphan branch or as artifacts.
6. **Security.**
   - Opening a PR in Unity runs code the PR author wrote (`[InitializeOnLoad]`), so render only same-repo PRs, or after a maintainer adds a label.
   - Use a dedicated CI seat and always return it.
   - Never combine `pull_request_target` with a checkout of the PR head.
7. **Terms.** Unity's 2026-06-30 Terms restrict automated and agent access to "Authorized Agentic Access". Before shipping Editor-driving automation, get Unity's position on it, or route it through Unity's own CLI (`unity open --batchmode`, then `unity command`) on Unity 6 projects.

### Stage C: a live Editor for agents in the codespace (opt-in)

8. **`editor_screenshot()`** captures the VNC desktop (xdotool and ImageMagick on `DISPLAY=:1`), so an agent sees what the human sees.
9. **Unity 6+:** preconfigure the Unity CLI's `unity mcp` with `com.unity.pipeline` (official, free, still beta). Do not build on the AI Assistant's in-Editor MCP server; Unity deprecated it.
10. **2021.3/2022.3:** optionally add [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp) (MIT, supports 2021.3+), injected as an embedded package so the project's manifest and diff stay clean. Keep it opt-in because of the Terms question.

*Done when:* an agent in a codespace can answer "what changed in `Level01.unity` in this PR, and what does it look like?" with structured data and before/after images, and the PR comment appears within minutes of a push.

## Phase 4: Reach and upkeep (ongoing)

- Lead the README with the reviewer-and-agent story. Add a "use something else when…" section (Unity Production Pipeline, PrefabLens, GameCI).
- Use Dependabot for GitHub Actions, dev container features (with a committed `devcontainer-lock.json`) and the Docker base.
- Replace the 17 MB GIF with a short video of the new flow.
- Replace the default issue templates (the bug template asks about smartphones) with fields that matter: Unity version, host, machine type, and a redacted creation-log excerpt.
- Consider a permissive license (MIT or Apache-2.0) for the features and templates. They get copied into proprietary game repositories, where GPL-3.0 may deter adoption. Get advice; this is not legal advice.
- Re-evaluate positioning when Unity Production Pipeline (November 2026) and the Unity CLI reach general availability.

## Decisions for the owner

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | How users get the Unity Editor | (a) make the GHCR image public; (b) install from Unity's CDN with a feature; (c) use GameCI images as the base | **(b)** as the backbone, (c) as an optional fast path. (a) only as a stopgap, accepting that Unity's terms do not clearly permit redistributing the Editor. |
| D2 | Primary persona | PMs; reviewers/developers; AI agents | Reviewers and agents first. Send PMs to Unity Production Pipeline or PrefabLens unless they need full fidelity. |
| D3 | Unity versions | which streams | 6000.3 LTS as the default, 6000.6 as latest, 2022.3.62f3 as legacy. Drop 2022.3.11f1. |
| D4 | License types | Pro serial or named-user; floating; Personal | All three. Personal depends on the Phase 1 spike. |
| D5 | AI scope under Unity's Terms | file-only; Editor-driving | File-only by default; Editor-driving opt-in after clarifying with Unity or via the Unity CLI. |
| D6 | Repository license | keep GPL-3.0; permissive for features and templates | Consider permissive for anything users copy into their repos. |

## Open questions to settle in a real codespace

- Do Codespaces user secrets still reach `${localEnv:…}` inside features? GitHub says no; the 2023 demo suggests it once worked. Either way, runtime activation is the documented path.
- Does `onAutoForward: openBrowser`, combined with noVNC's `defaults.json`, auto-connect through Codespaces' private-port authentication?
- Does using only the noVNC tab reset the 30-minute idle timeout?
- How responsive is the Editor on 4 versus 8 cores with software rendering, and how long is the first asset import? `Library/` is not committed, so every new codespace re-imports.
- Seat counting: does a stopped and restarted codespace keep its activation? Does a stable `/etc/machine-id` help?
- Does Personal sign-in work inside the container, through the Hub or the CLI?
- Does `unity vcs diff` need sign-in or a license, and is its JSON output stable?
- How good is llvmpipe rendering for URP and HDRP projects?

## Suggested first week

1. Merge this branch (pinned base, leak and CI fixes, README corrections) and let CI rebuild the image.
2. Decide D1. Then either flip the package to public and reply on #3, or reply on #3 that a self-build path or feature is coming.
3. Implement runtime activation (Phase 0, item 2) and test it in a real codespace with a canary secret.
4. Start the Phase 1 feature and template skeleton with `devcontainers/action`, and the `unity-editor` installer with `version: auto`.
