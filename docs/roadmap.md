# Roadmap (proposed, October 2026)

This roadmap follows from the [October 2026 assessment](./assessment-2026-10.md). It covers the four directions the owner asked about:

- smoother onboarding;
- more Unity versions;
- how other solutions compare, and whether Unity has built something better;
- MCP/AI support so an agent can capture the diffs.

It is a proposal: the decisions in [Decisions for the owner](#decisions-for-the-owner) come first. It was revised after a completeness critique and three adversarial reviews.

**Capacity assumption.** One part-time maintainer, about 6 focused hours a week. Estimates are in focused hours. At that pace the core (Phases 0-1) is roughly 2-4 months, and Stage A of the AI work another 1-2 months.

*Nothing here is legal advice. Where Unity's terms matter, the plan says what to ask Unity.*

## Decide first: how big should this be? (D0)

| Option | What it means | Upkeep |
|---|---|---|
| **A. A small, maintained template** (recommended) | One dev container setup that installs the Editor your project uses, activates your own license at start-up, gives you a browser desktop, and adds license-free diff tools for people and agents. | A few hours a month: keep up with Unity releases, base images and the desktop feature. |
| B. A platform | Everything in A, plus published templates, a PR bot that renders before/after images in CI, Editor-driving MCP and a version matrix. | Much more. It also adds legal and security surface: CI seats, untrusted PR code, agents. |
| C. Archive | Point people to GameCI, the desktop-lite feature, the Unity CLI, Unity Production Pipeline and PrefabLens. | None. |

Option A answers all four asks within a fixed budget. B's extra pieces depend on answers from Unity (see [Questions for Unity](#questions-to-ask-unity-in-writing)) and on spikes that may fail. C is the honest fallback if the Phase 0 gates fail.

## Who it is for

- **The original intent** was PMs and coders reviewing Unity changes from a PR without a local clone.
- **The evidence from the 18 forks** is different:
  - several dropped to 4-core machines;
  - several replaced the private image, removed the license feature, or self-built another 2022.3 version;
  - one followed README step 3 and was left with no way to get the Editor;
  - one fork belongs to a school.

  The people who actually showed up look like **hobbyists and students**: Free GitHub accounts, Personal or Student Unity licenses, no local Unity install.
- **Studio PMs** need their own Unity seat to open the Editor here (or floating licenses). Unity Production Pipeline (if they are on Unity Cloud and Unity 6) or PrefabLens may serve them better for a quick look.
- **AI agents** benefit most from *license-free* diffs of Unity files. Driving the Editor is where Unity's 2026 Terms bite.

**Recommendation (D2):** design for "anyone who needs a Unity Editor in a browser, with their own license": students, hobbyists, small teams, and reviewers away from their workstation. Then add PR-review and AI conveniences on top. Validate this before investing: ask the issue #3 reporter and the fork owners what they use it for.

**What the project can honestly claim:**

- your project, in the real Unity Editor, in a browser;
- any Editor version (including 2021.3/2022.3);
- on any dev container host (Codespaces, Ona, Coder, local Docker);
- open source;
- your own account and seat.

**What it should not claim:**

- "full fidelity". Rendering is in software with no GPU. URP and Built-in use llvmpipe; HDRP needs Vulkan (lavapipe) and is untested.
- "nobody else does this". This is absence of evidence, and Unity is moving quickly.

## Phase 0: Make it work again, safely (10-20 h remaining)

### Done in pull request #4

[Pull request #4](https://github.com/gblikas/unity-desktop-lite/pull/4) contains everything in this list.

- [x] **Pinned base image.** `devcontainers/base:3-jammy`: the floating `ubuntu` tag is now 26.04, where the build fails and Unity 2022.3 cannot start.
  - The full Dockerfile (UnitySetup with Unity + Android) builds end to end on it: the pull request's CI run and a local run on 2026-11-13 both built and exported the complete image (9.8 GB).
- [x] **No Trash leftovers in the image.** UnitySetup moves its temporary files (~630 MB) to the Trash, so they are now deleted in the same `RUN`.
- [x] **CI frees runner disk before building.** The Unity layer is about 8.5 GB uncompressed. The runner that built the pull request had 110 GB free after the cleanup, so the step may not be needed on current runners; it now also prints the free space before cleaning up, which will tell.
- [x] **Rollback point, and proof the workflow can write to the package.** Run manually with `retag_from` and `retag_to`, the image workflow copies a tag of the published image instead of building.
  - A run on 2026-11-13 tagged the December 2023 image as `:2023-12`. Its digest is `sha256:f03607d7cc94b0b27b2017b6bcef02c8d76cfef30323d90664b6338171b11000`.
  - That run used the workflow's own token, so it also showed that the token may write to the package.
  - To roll back after a publish, run the workflow manually (*Actions* > *devcontainer build and push release* > *Run workflow*) with `retag_from=2023-12` and `retag_to=latest`, or run `gh workflow run devcontainer-build-and-push-release.yml -f retag_from=2023-12 -f retag_to=latest`. The run prints the digest `latest` had before, and `retag_from` also accepts such a digest, so a rollback can itself be undone.
  - Only `latest` can be moved. A tag such as `2023-12` is never moved to a different image, so running the workflow again with the same inputs cannot destroy a rollback point.
  - Do not use *Re-run* on the run of 2026-11-13 that created `:2023-12`. A re-run uses the workflow file of its own commit, which had no such check, and after a publish it would move `:2023-12` to the new image. The December 2023 image would then only be reachable by the digest above.
  - Publishes and re-tags run one at a time, and a run that is in progress always finishes first. A rollback requested while a publish is running therefore takes effect after it; cancel the publish to roll back sooner.
- [x] **Runtime license activation.** The local feature now installs a `unity-license` helper and runs it in `postStartCommand`, reading `UNITY_*` from the environment.
  - Credentials are no longer feature options, so:
    - nothing reaches the build log;
    - nothing can execute through the dev container CLI's env file;
    - prebuilds can work (private repositories only, see D1).
  - `unity-license return` frees the seat, `status` says whether a license file is present, and `activate --force` activates again when the Editor rejects the file it has. If the forced activation fails, the old files are put back.
  - After returning a named-user license the Editor still exits with an error, so `return` goes by Unity's log rather than its exit status.
  - `VNC_PASSWORD` is applied at start; TigerVNC picks it up without a restart.
  - Tested with a stand-in Unity binary, with real TigerVNC and, using made-up credentials, with the real Editor ([assessment §4.3](./assessment-2026-10.md#43-runtime-activation-pull-request-4)). **Not yet tested with a real Unity seat.**
- [x] **Consumer config.** A `secrets` block (Codespaces offers to set these on its *New with options* page), `"init": true` and `--shm-size=6gb` (which the published image's config never passed on). Credentials are no longer read from the local environment (`${localEnv:…}`); outside Codespaces, export them in a terminal and run `unity-license activate`.
- [x] **CI and extensions.** `$GITHUB_OUTPUT`, an explicit `permissions` block, `checkout@v7`, `login-action@v4`. Stale VS Code extension entries removed.
- [x] **README.** Known issues (private image, seat return, no GPU), a self-build workaround for issue #3, accurate credential and licensing text, and a not-legal-advice note.

### To do

0. **Confirm which Unity license you can test with.** A Pro seat, or Personal? Every later gate depends on it. If you have no seat this flow can activate, say so in the README rather than promise paid-seat support.
   - The quickest test needs no merge: create a codespace from the pull request's branch (*New with options*), or from `main` afterwards. Until the new image is published it uses the December 2023 image with the new start-up activation. Expect `[unity-license] Unity license activated` in the creation log, then try `unity-license status` and `unity-license return`.
   - The README's known issues say that activation has not been tested with a real seat. Once it has, remove that line and restore the check mark in the assessment's health check.
1. **Merge.**
   - `main` is protected: one approving review, resolved conversations, and a ruleset that restricts updates. GitHub therefore shows *Merging is blocked*, and you cannot approve your own pull request. As the repository's administrator, answer or resolve the open review conversations, then tick *Merge without waiting for requirements to be met*.
   - Wait for the pull request's build check; GitHub does not enforce this, because the check is not a required one. The `pull_request` run builds the full image but cannot publish (`push: filter` only publishes on pushes to `main`).
   - Use *Squash and merge*, the only method this repository allows. A squash triggers the rebuild; the `HEAD^` change check would skip it after a rebase-merge. GitHub proposes the list of commit messages as the squash message; some describe intermediate states, so replace it with the pull request's summary.
   - Afterwards, check the run on `main`. Its log should say `found changes` and should not say `Image push skipped`, and the package page should show `latest` on a new digest with `2023-12` unchanged. If the run fails, use *Re-run failed jobs*: a manual *Run workflow* builds but never publishes.
   - Then keep the new image as a rollback point too: run the workflow manually with `retag_from=latest` and a new `retag_to`, such as `2026-11`.
   - If the new image misbehaves, roll back as described above.
2. **Reply on issue #3.** The package is private. The README's self-build option is the workaround, and an install-from-Unity option is planned. **Do not make the package public**: Unity's terms grant no right to redistribute the Editor, and public visibility cannot be undone.
3. **Time-boxed spikes in a real codespace** (about a day each), which decide gate G1:
   - **(a) License.** Try 2022.3.62f3 and 6000.3 with a Pro serial, a named-user seat (`-serial` without a key) and Personal. Include `unity-license return` for each.
     - GameCI's logs of real seats show a Personal seat granted to a 2020.3 Editor started with only `-username` and `-password`. That is close to what `unity-license` does when `UNITY_SERIAL` is unset, so try that first.
     - Personal can go through the Unity CLI's `unity auth login` then `unity license activate`, or Unity Hub inside the desktop. The Hub needs `--no-sandbox`, a non-snap browser and a `unityhub://` handler.
     - Unity's 2026-09 support article says Editors up to 2022.3 launched without the Hub may not load newer manual named-user licenses; test Licensing Client 1.18.3 if so.
     - Check accounts with 2FA. Never advise disabling 2FA.
   - **(b) Time to first scene.** Use a real URP project on 4-core and 8-core machines, with no cached `Library/`. Then try an HDRP sample with `mesa-vulkan-drivers` and `-force-vulkan`.
   - **(c) Seat accounting.** Does an activation survive stop/start? Does a rebuild (home is wiped) consume a new one? Do not try to reuse machine identities to save seats; that may breach the Terms.
     - Settle assessment defect D20 first: the image contains a machine id created at build time, so every container started from it reports the same machine to Unity's licensing client. Until that is decided, no seat count from a codespace means much.
4. **README "Use something else when…".** Unity Production Pipeline for browsing a Unity 6 project on Unity Cloud; the PrefabLens CLI for "what changed?"; a local worktree if you already have a seat and a warm `Library/`. The content is in [assessment §8](./assessment-2026-10.md#8-alternatives-better-worse-or-complementary).
5. **Decide D6 (repository license) and D7 (naming) from [Decisions for the owner](#decisions-for-the-owner) now, before publishing anything.** Relicensing is easy while you are the only author. Unity's trademark guidelines discourage "Unity" in product names, which is cheap to fix before packages exist and costly after.

**Gate G1 (end of Phase 0):**

- If no license path works in a codespace, stop the Editor work. Keep the license-free diff tools (Stage A below) and point users to alternatives.
- If time to first scene is far worse than switching branches locally, aim at people without a local install (students, hobbyists), not at reviewers who already have a seat and a warm `Library/`.

## Phase 1: The right Editor for your project, in one click (40-80 h)

1. **Install the Editor the project uses**, instead of publishing one image per version.
   - **Version.** Read `ProjectSettings/ProjectVersion.txt`; `m_EditorVersionWithRevision` holds both the version and the changeset. Validate both against strict patterns (`^[0-9]{4}\.[0-9]+\.[0-9]+[abfp][0-9]+$`, `^[0-9a-f]{12}$`) before using them, because the file is PR-controlled.
   - **Installer.** Prefer Unity's own CLI (`unity install <version> --changeset <cs>`, beta). Fall back to the documented `LinuxEditorInstaller/Unity-<version>.tar.xz`, checked against the md5 in `unity-<version>-linux.ini`.
   - **Scope.** Editor only by default. Other modules (Android, Windows, macOS) are `.pkg` archives that need Unity's installer.
   - **Unity's terms.** Never accept them on the user's behalf. Use an explicit `acceptUnityTerms` option, or leave Unity's own dialog to the user. Drop `yes |`.
   - **When.** Run it in `onCreateCommand`, where the workspace exists and prebuilds capture the result. Re-check in `postCreateCommand`, removing the old Editor before installing another.
   - **Base image.** `3-jammy` for 2021.3/2022.3; `3-noble` (or jammy) for Unity 6.
   - **Disk and time.**

     | | Installed | Download | Extraction |
     |---|---|---|---|
     | 2022.3 | 6.4-7.5 GB | 3-4.6 GB | single-threaded |
     | Unity 6 | 8.5-9.2 GB | 3-4.6 GB | multi-threaded only with xz ≥ 5.4 (noble) |

     Stream the download rather than storing the tarball. Refuse to install when free space is short. Recommend 8-core / 64 GB machines for real projects.
2. **Desktop.**
   - Move to `ghcr.io/devcontainers/features/desktop-lite:1` (noVNC 1.6+), but note upstream issue #1168: its `password` option is not enforced, so access control then rests on Codespaces port privacy alone. Either keep VNC authentication (set `VNC_PASSWORD` in `containerEnv` or keep a custom entrypoint), or document plainly that the desktop is protected only by private ports. Add a test that reads the RFB security types on port 5901.
   - 24-bit colour.
   - `portsAttributes` 6080 → `openBrowser`, plus an `index.html` that redirects to `vnc.html?autoconnect=true&resize=remote`.
   - `otherPortsAttributes: ignore`.
   - Warn never to make 6080 public or organization-visible.
3. **Launcher.** Wait for the activation-done flag and the X display. Then start `Unity -projectPath …` with `nohup setsid`; processes started directly from a lifecycle command are killed when it ends. Refuse to open a project whose Editor version doesn't match, since Unity would upgrade its assets.
4. **README quick start.**
   - A `codespaces.new/OWNER/REPO` badge. It opens the options page, where recommended secrets are shown.
   - The secrets list.
   - Costs, compute **and** storage: Free accounts get 120 core-hours (15 h on 8 cores) and only 15 GB-month of storage, while a Unity codespace is 15-30 GB.
   - Seat lifecycle: one long-lived codespace per person rather than one per PR; `unity-license return` before deleting.
   - Known limits: no GPU, and Unity doesn't support containers.
5. **Publish the feature** (and the editor installer) to GHCR with `devcontainers/action`.
   - Set each package to **public** once. These are config-only, with no Unity binaries.
   - Add a CI check that every published artifact resolves anonymously.
   - Test on PRs with a stub `Unity`, as pull request #4's tests did, plus a canary-secret check. Run a real Editor install monthly or manually.

**Deferred** until users ask:

- a published template and a containers.dev listing;
- desktop menu items;
- GameCI images as a fast base (the user's own choice; caveats: redistribution, root user, Docker Hub limits, needs `remoteUser`);
- `lts`/`latest` aliases;
- a generated `versions.json`;
- private warm images;
- floating licenses. These need `services-config.json` and network reach to an on-premises Licensing Server; document them as community-supported.

## Phase 2: AI, so agents can capture the diff, license-free first (20-40 h for Stage A)

### Stage A: works for every Unity version, needs no Unity license (do first)

1. **Diff tools in the image.**
   - The PrefabLens CLI, version-pinned with a sha256. It is non-Unity software, so it is clearly outside §17.2(ff). Its `--json` mode diffs two git refs with GUIDs resolved.
   - Optionally the Unity CLI's `vcs diff/summarize/affected` (needs Force Text serialization), once it is confirmed not to need sign-in and Unity's position on automated use is clear.
2. **Agent instructions.** An `AGENTS.md` or Claude Code skill: "to see what changed in a scene or prefab between two refs, run …". Any agent that can run shell commands can then capture diffs, with no new server.
3. **`editor_screenshot`**. `import -window root -display :1` lets an agent see the same desktop as the human, in the user's own codespace and under their own seat. Combined with switching refs, this gives before/after views without CI rendering.
4. **Optional thin MCP server** wrapping 1-3, read-only, configured in a project `.mcp.json` / `.vscode/mcp.json`. Register Claude Code in a feature `postCreateCommand` as the remote user, not at build time. The Copilot cloud agent ignores dev container features; it needs its repository MCP settings and `copilot-setup-steps.yml`.
5. **PR comment Action, same-repo PRs first.**
   - It posts the semantic summary plus a `codespaces.new/OWNER/REPO/pull/<n>` link.
   - It treats PR content as untrusted: escape names, cap length, keep permissions minimal, and never give an LLM step a write token.
   - Fork PRs come later, through `workflow_run`, handling the artifact strictly as data.
   - Compare refs (`merge-base..head`), never the working tree. The Editor rewrites `packages-lock.json` and `ProjectSettings`.

### Agent safety (applies to every stage)

- Codespaces exports `UNITY_USERNAME`/`UNITY_PASSWORD`/`UNITY_SERIAL` into every VS Code terminal, so any agent or MCP server started there can read them.
  - Strip them in agent and MCP launch wrappers: `env -u UNITY_PASSWORD -u UNITY_SERIAL …`.
  - Recommend a dedicated Unity ID for codespaces, and named-user seats over serials.
- Keep tools read-only by default. Require human confirmation for anything that changes files or drives the Editor.
- Opening a PR's project runs code the PR author wrote: `[InitializeOnLoad]`, package dependencies, analyzers, asset postprocessors. Never open untrusted PRs with secrets present.
- Document which data goes where: YAML and screenshots to the model provider, assets to Unity Cloud if you use Production Pipeline. Studios can then approve each flow.

### Stage B: rendered before/after images in CI (spike only, gated)

Do not build this until all three hold:

1. **A license.** Unity confirms in writing which license covers CI rendering. A seat is for one person, the Build License excludes "creating", and Build Server covers builds.
2. **Unity's position on automation.** Unity's answer on §17.2(ff) for batchmode automation.
3. **A passing spike.** Render a URP sample scene at two refs on a hosted runner, with a warm `Library/`, in about 20 minutes, with acceptable quality. HDRP needs lavapipe.

If it goes ahead:

- only same-repo PRs;
- one serialized job, with the seat returned under `if: always()`;
- the render job holds no write token;
- never `pull_request_target` combined with a checkout of the PR head.

### Stage C: an Editor-driving MCP (deferred)

- **Unity 6+:** Unity's own `unity mcp` with `com.unity.pipeline`, for the seat holder, in their own codespace, with clients Unity documents. Wait until the CLI is generally available.
- **2021.3/2022.3:** community bridges (CoplayDev, IvanMurzak) drive the Editor without Unity's authorization (§17.2(gg)). Wait for Unity's vetting.
  - If you do use one, keep it out of the project diff: add the package folder to `.git/info/exclude` and mark `Packages/packages-lock.json` skip-worktree for the session.

## Phase 3: Reach (optional, ongoing)

- Templates and a containers.dev listing.
- Other hosts (Ona, Coder, local Docker with a mode-600 env file). The `secrets` prompt only exists in Codespaces.
- GPU hosts.
- KasmVNC or Selkies instead of noVNC.
- Issue templates with useful fields: Unity version, host, machine type, redacted creation log.
- A new demo video instead of the 17 MB GIF.
- Re-evaluate when Unity Production Pipeline (November 2026) and the Unity CLI reach general availability.

## Decisions for the owner

These decision numbers (D0-D7) are separate from the defect numbers (D1-D20) in the assessment.

| # | Decision | Recommendation |
|---|---|---|
| D0 | Scope: template, platform or archive | **Template** (option A), with gate G1 after Phase 0. |
| D1 | How users get the Unity Editor | **Install it from Unity, per user**: Unity CLI or documented tarball, in the user's own container. Never publish public images containing the Editor, and don't use public-repo prebuilds that copy it to everyone. GameCI bases only as the user's own choice, with the caveats. |
| D2 | Primary persona | **People who need a browser Editor with their own license** (students, hobbyists, small teams, reviewers away from their workstation). Validate with users first. |
| D3 | Unity versions | **Whatever `ProjectVersion.txt` says.** Test 6000.3 LTS and 2022.3.62f3. Drop the 2022.3.11f1-only image. |
| D4 | License types | **Paid seats** (serial or named-user) first. Personal if the Phase 0 spike works. Floating documented as untested. |
| D5 | AI scope | **File-level diffs and desktop screenshots by default.** Editor-driving tools and CI rendering only after Unity answers in writing. |
| D6 | Repository license | **Decide now** whether files users copy into their own repos (features, templates) should be MIT or Apache-2.0 instead of GPL-3.0. |
| D7 | Naming | **Decide before publishing anything** whether to keep "Unity" in package and repository names (Unity's trademark guidelines). |

## Questions to ask Unity (in writing)

1. May a seat holder run their own licensed Editor in a cloud dev environment (GitHub Codespaces) and view it through a browser (noVNC)? This concerns Editor Software Terms §2.8, the cloud clause.
2. Is a scripted install from Unity's CDN acceptable (§17.2(l)), or should installs go through the Unity CLI?
3. Which license covers rendering scene/prefab previews of PR changes in CI: a seat, the Build License or Build Server?
4. How do §17.2(ff) and §17.2(gg) apply to:
   - CLI and batchmode automation of the user's own Editor;
   - file-only tools;
   - third-party MCP bridges?

   Which clients are authorized?
5. May community dev container features and templates include "Unity" in their names?

Separately, ask GameCI whether they hold Unity's permission to distribute Editor images.

## Threat model (summary)

- **Assets to protect:** Unity credentials and seats; the codespace's GitHub token; unreleased game code and art.
- **Who could misuse them:**
  - authors of fork PRs;
  - same-repo collaborators;
  - prompt-injected agents;
  - anyone who can reach a public or organization-visible port 6080;
  - browser extensions holding broad tokens (the PrefabLens extension asks for the classic `repo` scope);
  - a compromised CI seat.
- **Rules:**
  - secrets only at runtime, never in images or logs;
  - no Editor on untrusted PRs while secrets are present;
  - agents read-only by default, with credentials stripped;
  - no LLM step with write tokens reading PR content;
  - private ports;
  - data flows documented.

## Success metrics and stop criteria

**Metrics:**

- time from badge click to first scene, with and without a prebuild;
- activation success rate, and seats left behind per user;
- issues opened and closed;
- what the people interviewed say.

**Stop or archive (option C) when any of these holds:**

- gate G1 fails;
- Unity says cloud-streamed Editors or this kind of automation need a separate grant;
- Unity Production Pipeline at general availability covers PR review for most users at an acceptable price.

## Open questions

These still need a real codespace or Unity's answer:

- License behaviour of standalone Editors (no Hub) in containers, with 2FA, SSO and the newer license types.
- Whether Codespaces' creation log redacts secrets. This no longer matters after pull request #4, but it does for anyone still on the old config.
- Whether interacting only with the noVNC tab keeps the codespace from idling out (30-minute default).
- Library import times, and whether Unity Accelerator helps.
- HDRP on lavapipe.
- Whether the Unity CLI's `vcs diff` works signed out and on 2022.3 projects.

## Suggested first steps

At about 6 focused hours a week, this is roughly three weeks.

1. Test the start-up activation with your own seat, in a codespace from the pull request's branch.
2. Merge once the pull request's build check is green (see [To do](#to-do)), and check the publish run on `main`. Then reply on #3.
3. License spike (about 1 day).
4. Time-to-first-scene spike (about 1 day).
5. Decide D0, D6 and D7.
