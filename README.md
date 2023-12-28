# unity-desktop-lite

Unity Desktop Lite extends the ["desktop-lite"](https://github.com/devcontainers/features/tree/main/src/desktop-lite) project by the GitHub Devcontainer team, providing a lightweight desktop environment for containerized applications, particularly those involving Unity projects.

This tool facilitates a devcontainer/[codepsace](https://github.com/features/codespaces) setup to manage code check-outs for Unity projects more efficiently. It allows users to monitor prefab changes, scene updates, and asset modifications directly in a codespace, bypassing the need for local cloning and potentially reducing PR approval times.

![unity-desktop-lite-demo](./unity-desktop-lite-demo.gif)


## Installation 
> Please note, 

1. Fork the repo
2. Configure User Secrets (These should be user-level, not repository-level secrets):
   - `UNITY_USERNAME`
   - `UNITY_PASSWORD`
   - `UNITY_SERIAL`
   - `VNC_PASSWORD` (optional - see [.devcontainer](./.devcontainer/devcontainer.json))
3. Delete `.github` and `unity-*` folders.
4. Select your version of Unity from the [Github Container Registry for the repo](https://github.com/gblikas?tab=packages&repo_name=unity-desktop-lite), and replace `.devcontainer.json.image` with that URI.


## Usage

The current implemention is intended for project managers and coders that want to check thier Unity scenes, prefabs, and other objects. 

To launch Unity, run

```bash
/opt/unity/Editor/Unity --projectPath path/to/projdir
```

## Troubleshooting & FAQ

Unity license activation fails; not enough licenses. 
- Ensure your Unity ID has available licenses. If required, deactivate an existing license and retry. Use "vscode" as the username.

Unity license activation fails; Unity personal account.
- This tool requires an upgrade to Unity Plus or Unity Pro, as it depends on the USERNAME and PASSWORD authentication method.

Launching the codespace takes a long time. 
- It can take up to 10 minutes for the codespace to be ready - provisioning a better machine will help with this, and enabling [Github Codespace Prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces), more info [here](https://containers.dev/guide/prebuild).

What does `unity-desktop-lite` do with my `UNITY_USERNAME` and `UNITY_PASSWORD`?
- `unity-desktop-lite` does not retain your password. It is utilized solely for authentication purposes and to facilitate the creation of a Unity license through the Unity CLI. 

Does `unity-desktop-lite` work with Unity Personal accounts? 
- No. This application currently only works with Unity Plus, or Unity Pro accounts.

I share a repo with multiple developers. What does this mean for my Unity License and ToS? 
- This project installs Unity into a prebuilt container image. Your `UNITY_USERNAME` and `UNITY_PASSWORD` are used to activate a license per-codespace, under your account. This implies that _you_ must adhere to Unity's license policies. Using this software means you agree to do this. And is distributed with no guarntees. 

## Contributing 

Contributions are welcome and greatly appreciated. To contribute, please submit a pull request with your changes for review. For areas requiring immediate attention, refer to our issues page.
