# unity-desktop-lite

Unity Desktop Lite extends the ["desktop-lite"](https://github.com/devcontainers/features/tree/main/src/desktop-lite) project by the GitHub Devcontainer team, providing a lightweight desktop environment for containerized applications, particularly those involving Unity projects.

This tool facilitates a devcontainer/[codespace](https://github.com/features/codespaces) setup to manage code check-outs for Unity projects more efficiently. It allows users to monitor prefab changes, scene updates, and asset modifications directly in a codespace, bypassing the need for local cloning and potentially reducing PR approval times.

![unity-desktop-lite-demo](./unity-desktop-lite-demo.gif)


## Installation 
> Please note, the prebuilt image dates from December 2023; license activation, the Dockerfile and CI were updated in October 2026. See the [October 2026 assessment](./docs/assessment-2026-10.md) and the [roadmap](./docs/roadmap.md).
>
> **Known issues**
> - The prebuilt image is a private package, so only the repository owner can pull it ([#3](https://github.com/gblikas/unity-desktop-lite/issues/3)). Until that changes, build the image yourself (step 4).
> - Deleting a codespace does not return its Unity license activation. Run `unity-license return` first, or remove old activations at [id.unity.com](https://id.unity.com) (My Account > My Seats).
> - Codespaces has no GPU, so the Editor renders in software. Unity does not officially support running the Editor in a container.

1. Fork the repo
2. Configure User Secrets (These should be user-level, not repository-level secrets), and give them access to your fork:
   - `UNITY_USERNAME`
   - `UNITY_PASSWORD`
   - `UNITY_SERIAL` (leave unset for named-user seats)
   - `VNC_PASSWORD` (optional, defaults to `vscode` - see [.devcontainer](./.devcontainer/devcontainer.json))

   The license is activated when the codespace starts, so these values are never part of the image or its build log.
3. Delete the `.github` folder. Keep the `unity-*` folders if you build the image yourself.
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
unity-license status    # is a license active?
unity-license activate  # activate from the UNITY_* secrets
unity-license return    # free the seat, e.g. before deleting the codespace
```

## Troubleshooting & FAQ

Unity license activation fails; not enough licenses. 
- Ensure your Unity ID has available licenses. If required, deactivate an existing license and retry. Use "vscode" as the username. Each codespace counts as a separate machine; run `unity-license return` before deleting one, and remove stale activations at [id.unity.com](https://id.unity.com) (My Account > My Seats). If activation fails, Unity's log is kept in `~/.cache/unity-license/`.

Unity license activation fails; Unity personal account.
- This tool activates the license from the command line (`-serial`, `-username`, `-password`), which Unity supports for paid plans (Unity Pro, Enterprise or Industry). Unity Plus has been retired, and Unity Personal can only be activated through Unity Hub.

Launching the codespace takes a long time. 
- It can take up to 10 minutes for the codespace to be ready - provisioning a better machine will help with this, and enabling [Github Codespace Prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces), more info [here](https://containers.dev/guide/prebuild). License activation happens when the codespace starts, so it is not part of a prebuild. Never put Unity credentials in repository or organization Codespaces secrets: everyone who creates a codespace from the repository can read those.

What does `unity-desktop-lite` do with my `UNITY_USERNAME` and `UNITY_PASSWORD`?
- When the codespace starts, `unity-license` reads them from the codespace's environment (where Codespaces puts your secrets) and passes them to the Unity command line to activate the license; `unity-license return` uses them to return it. They are not written to the image, the build log or the repository. If activation fails, Unity's own log is kept in `~/.cache/unity-license/`, readable only by you (delete it when done); after a successful activation it is removed.

Does `unity-desktop-lite` work with Unity Personal accounts? 
- Not yet. Unity documents Unity Hub as the only way to activate a Personal license, so this setup currently requires Unity Pro, Enterprise or Industry.

I share a repo with multiple developers. What does this mean for my Unity License and ToS? 
- This project installs Unity into a prebuilt container image. Your `UNITY_USERNAME` and `UNITY_PASSWORD` are used to activate a license per-codespace, under your account. This implies that _you_ must adhere to Unity's license policies: for example, a seat is for one person, on up to two machines, with one Editor running at a time, so don't share your desktop or credentials with people who don't have their own seat. You are responsible for complying with Unity's terms; nothing here is legal advice. It is distributed with no guarantees. 

## Contributing 

Contributions are welcome and greatly appreciated. To contribute, please submit a pull request with your changes for review. For areas requiring immediate attention, refer to our [issues page](https://github.com/gblikas/unity-desktop-lite/issues).
