# unity-desktop-lite

Unity Desktop Lite extends the ["desktop-lite"](https://github.com/devcontainers/features/tree/main/src/desktop-lite) project by the GitHub Devcontainer team, providing a lightweight desktop environment for containerized applications, particularly those involving Unity projects.

This tool facilitates a devcontainer/[codespace](https://github.com/features/codespaces) setup to manage code check-outs for Unity projects more efficiently. It allows users to monitor prefab changes, scene updates, and asset modifications directly in a codespace, bypassing the need for local cloning and potentially reducing PR approval times.

![unity-desktop-lite-demo](./unity-desktop-lite-demo.gif)


## Installation 
> Please note, this setup was last updated in December 2023. See the [October 2026 assessment](./docs/assessment-2026-10.md) for known issues and the [roadmap](./docs/roadmap.md) for planned changes.

1. Fork the repo
2. Configure User Secrets (These should be user-level, not repository-level secrets):
   - `UNITY_USERNAME`
   - `UNITY_PASSWORD`
   - `UNITY_SERIAL`
   - `VNC_PASSWORD` (optional, defaults to `vscode` - see [.devcontainer](./.devcontainer/devcontainer.json))
3. Delete `.github` and `unity-*` folders.
4. Select your version of Unity from the [Github Container Registry for the repo](https://github.com/gblikas?tab=packages&repo_name=unity-desktop-lite), and set the `image` property in `.devcontainer/devcontainer.json` to that URI.


## Usage

The current implementation is intended for project managers and coders that want to check their Unity scenes, prefabs, and other objects. 

To launch Unity, run

```bash
/opt/unity/Editor/Unity -projectPath path/to/projdir
```

## Troubleshooting & FAQ

Unity license activation fails; not enough licenses. 
- Ensure your Unity ID has available licenses. If required, deactivate an existing license and retry. Use "vscode" as the username.

Unity license activation fails; Unity personal account.
- This tool activates the license from the command line (`-serial`, `-username`, `-password`), which Unity supports for paid plans (Unity Pro, Enterprise or Industry). Unity Plus has been retired, and Unity Personal can only be activated through Unity Hub.

Launching the codespace takes a long time. 
- It can take up to 10 minutes for the codespace to be ready - provisioning a better machine will help with this, and enabling [Github Codespace Prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces), more info [here](https://containers.dev/guide/prebuild). Note that prebuilds cannot use user-level secrets, so the current license-activation feature cannot run in a prebuild (see the [roadmap](./docs/roadmap.md)).

What does `unity-desktop-lite` do with my `UNITY_USERNAME` and `UNITY_PASSWORD`?
- They are used only to activate (and return) a Unity license through the Unity command line while the container is created. They are not stored in the repository, but the dev container CLI prints feature options to the codespace creation log, so treat that log as sensitive. Moving activation to container start-up, which removes this, is on the [roadmap](./docs/roadmap.md).

Does `unity-desktop-lite` work with Unity Personal accounts? 
- Not yet. Unity documents Unity Hub as the only way to activate a Personal license, so this setup currently requires Unity Pro, Enterprise or Industry.

I share a repo with multiple developers. What does this mean for my Unity License and ToS? 
- This project installs Unity into a prebuilt container image. Your `UNITY_USERNAME` and `UNITY_PASSWORD` are used to activate a license per-codespace, under your account. This implies that _you_ must adhere to Unity's license policies. Using this software means you agree to do this. It is distributed with no guarantees. 

## Contributing 

Contributions are welcome and greatly appreciated. To contribute, please submit a pull request with your changes for review. For areas requiring immediate attention, refer to our [issues page](https://github.com/gblikas/unity-desktop-lite/issues).
