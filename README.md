# unity-desktop-lite

Unity Desktop Lite extends the ["desktop-lite"](https://github.com/devcontainers/features/tree/main/src/desktop-lite) project by the GitHub Devcontainer team, providing a lightweight desktop environment for containerized applications, particularly those involving Unity projects.

This tool facilitates a devcontainer/[codespace](https://github.com/features/codespaces) setup to manage code check-outs for Unity projects more efficiently. It allows users to monitor prefab changes, scene updates, and asset modifications directly in a codespace, bypassing the need for local cloning and potentially reducing PR approval times.

![unity-desktop-lite-demo](./unity-desktop-lite-demo.gif)


## Installation 
> Please note, CI rebuilds the prebuilt image from this repository (Ubuntu 22.04, Unity 2022.3.11f1); the December 2023 build is kept as the tag `2023-12`. License activation, the Dockerfile and CI were reworked in November 2026. See the [October 2026 assessment](./docs/assessment-2026-10.md) and the [roadmap](./docs/roadmap.md).
>
> **Known issues**
> - The prebuilt image is a private package, so only the repository owner can pull it ([#3](https://github.com/gblikas/unity-desktop-lite/issues/3)). The roadmap recommends keeping it private, because Unity's terms give no right to redistribute the Editor, so build the image yourself (step 4).
> - License activation at start-up has not yet been tested with a real Unity seat or inside a real codespace. If it fails for you, please open an issue (leave account details out of any log you attach).
> - Deleting a codespace does not return its Unity license activation. Run `unity-license return` first, or remove old activations at [id.unity.com](https://id.unity.com) (My Account > My Seats).
> - Codespaces has no GPU, so the Editor renders in software. Unity does not officially support running the Editor in a container.

1. Fork the repo
2. Configure User Secrets (These should be user-level, not repository-level secrets), and give them access to your fork:
   - `UNITY_USERNAME`
   - `UNITY_PASSWORD`
   - `UNITY_SERIAL` (leave unset for named-user seats)
   - `VNC_PASSWORD` (optional, defaults to `vscode` - see [.devcontainer](./.devcontainer/devcontainer.json))

   The license is activated when the codespace starts, so these values are never part of the image or its build log.
3. Delete the `.github` folder. Keep the `unity-*` folders: they are what builds the image in step 4.
4. Select your version of Unity from the [Github Container Registry for the repo](https://github.com/gblikas?tab=packages&repo_name=unity-desktop-lite), and set the `image` property in `.devcontainer/devcontainer.json` to that URI.

   To build the image yourself instead, replace the `image` property with the following. Unity is then installed while the codespace is created, which takes a while.

   ```json
   "build": {
       "dockerfile": "../unity-2022/2022.3.11f1/.devcontainer/Dockerfile",
       "context": "../unity-2022/2022.3.11f1/.devcontainer"
   },
   "overrideCommand": false,
   ```


## Usage

The current implementation is intended for project managers and coders that want to check their Unity scenes, prefabs, and other objects. 

To launch Unity, run

```bash
/opt/unity/Editor/Unity -projectPath path/to/projdir
```

The license is activated automatically when the codespace starts. To manage it yourself, run these in a VS Code terminal (terminals opened inside the noVNC desktop don't receive Codespaces secrets):

```bash
unity-license status            # is a license file present?
unity-license activate          # activate from the UNITY_* secrets, unless a license file is present
unity-license activate --force  # activate again, e.g. when the Editor rejects the license it has; a failed attempt keeps the old one
unity-license return            # free the seat, e.g. before deleting the codespace
```

Outside Codespaces (for example VS Code Dev Containers on your own machine) nothing passes the secrets to the container. Set them in a terminal and activate by hand:

```bash
export UNITY_USERNAME='you@example.com'
read -rs UNITY_PASSWORD && export UNITY_PASSWORD   # type the password; it is not shown
# export UNITY_SERIAL='your serial key'            # only if you have one
unity-license activate
```

## Troubleshooting & FAQ

Unity license activation fails; not enough licenses. 
- Ensure your Unity ID has available licenses. If required, deactivate an existing license and retry. Use "vscode" as the username. Deleting a codespace does not return its activation: run `unity-license return` before deleting one, and remove stale activations at [id.unity.com](https://id.unity.com) (My Account > My Seats). If an activation or a return fails, Unity's log is kept in `~/.cache/unity-license/`.
- `unity-license status` only says whether a license file is present. If the Editor still reports no valid license, for example after you removed the activation at id.unity.com, run `unity-license activate --force`.
- Unity cannot read a password that starts with `-` from its command line; `unity-license` warns when it sees one.

The codespace says the Unity license was not activated because `UNITY_USERNAME` or `UNITY_PASSWORD` is not set.
- Check that the secrets exist in your [Codespaces settings](https://github.com/settings/codespaces) and that your repository is in their repository access list, then restart the codespace: secrets are read when it starts. GitHub passes your secrets only to codespaces of repositories you can write to, and not to a codespace created from a fork's pull request. Outside Codespaces, set them by hand (see [Usage](#usage)).

Unity license activation fails; Unity personal account.
- This tool activates the license from the command line (`-serial`, `-username`, `-password`), which Unity supports for paid plans (Unity Pro, Enterprise or Industry). Unity Plus has been retired, and Unity Personal can only be activated through Unity Hub.

Launching the codespace takes a long time. 
- With a prebuilt image it can take up to 10 minutes for the codespace to be ready - provisioning a better machine will help with this. If you build the image yourself (step 4), every new codespace also downloads and installs Unity. That build took about 16 minutes in this repository's CI, and its log shows nothing for several minutes while Unity installs.
- [Github Codespace Prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces) (more info [here](https://containers.dev/guide/prebuild)) move that wait out of codespace creation. A prebuild contains the Unity Editor, though, and is given to everyone who creates a codespace from the repository. So don't enable prebuilds on a public repository, and a fork of this one is always public: Unity's terms give no right to redistribute the Editor (see the [roadmap](./docs/roadmap.md#decisions-for-the-owner)).
- License activation happens when the codespace starts, so it is not part of a prebuild. Never put Unity credentials in repository or organization Codespaces secrets: everyone who creates a codespace from the repository can read those.

What does `unity-desktop-lite` do with my `UNITY_USERNAME` and `UNITY_PASSWORD`?
- When the codespace starts, `unity-license` reads them from the codespace's environment (where Codespaces puts your secrets) and passes them to the Unity command line to activate the license; `unity-license return` uses them to return it. They are not written to the image, the build log or the repository. If an activation or a return fails, Unity's own log is kept in `~/.cache/unity-license/`, readable only by you. Delete it when done: it can contain your Unity ID and most of your serial key. After a success it is removed.

Does `unity-desktop-lite` work with Unity Personal accounts? 
- Not yet. Unity documents Unity Hub as the only way to activate a Personal license, so this setup currently requires Unity Pro, Enterprise or Industry.

I share a repo with multiple developers. What does this mean for my Unity License and ToS? 
- This project installs Unity into a prebuilt container image. Your `UNITY_USERNAME` and `UNITY_PASSWORD` are used to activate a license per-codespace, under your account. This implies that _you_ must adhere to Unity's license policies: for example, a seat is for one person, on up to two machines, with one Editor running at a time, so don't share your desktop or credentials with people who don't have their own seat. You are responsible for complying with Unity's terms; nothing here is legal advice. It is distributed with no guarantees. 

## Contributing 

Contributions are welcome and greatly appreciated. To contribute, please submit a pull request with your changes for review. For areas requiring immediate attention, refer to our [issues page](https://github.com/gblikas/unity-desktop-lite/issues).
