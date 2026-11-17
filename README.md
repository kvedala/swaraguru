# swaraguru

A new Flutter project.

## Web Shruti playback

Run `flutter run -d chrome`, then click **Play Shruti** (or **Start Drone** in
the Shruti Drone Lab). Playback starts from a user gesture, as required by
browser autoplay policies. Pure mode synthesizes a sine tone; multi-note mode
mixes continuous sine tones, not a sampled tambura. Pitch, fine tuning, channel
levels, and master volume update while playing. Stop ends all active tones.

Shruti audio currently supports web only; other platforms show an unsupported
playback message. Reference lesson playback and vocal coaching remain visual
simulations, not audio playback or microphone input.

## GitHub Pages deployment

The [web workflow](.github/workflows/web.yml) uses Flutter 3.50.0 stable
(Dart 3.14.0). Pushes to `main` run analysis, tests, and a release web build,
then deploy to https://kvedala.github.io/swaraguru/. The production build uses
`/swaraguru/` as its base path so assets load correctly on the project site.

One-time repository setup:

1. Open **Settings > Pages > Build and deployment** and select
   **GitHub Actions** as the source.
2. In **Settings > Environments > github-pages**, restrict deployment branches
   to `main`.
3. Merge the workflow into `main`. Subsequent pushes deploy automatically.
   To redeploy manually, run **Web CI and GitHub Pages** from the **Actions**
   tab with `main` selected.

Only the deployment job receives Pages write permissions. Deployments share a
single `github-pages` concurrency group, so they run one at a time and never
cancel an in-progress deployment.

### Development testing

Pull requests targeting `main` run the same analysis, tests, and web build,
but never deploy to production. Successful runs upload a `web-build-<run number>`
artifact, retained for seven days. Manual workflow runs on other branches also
produce downloadable builds without deploying.

To try a development build, download and extract its artifact from the Actions
run, then run this command from the extracted directory:

```sh
python3 -m http.server 8080
```

Open http://localhost:8080 and click **Play Shruti**. Development artifacts use
`/` as their base path and must be served over HTTP, not opened as local files.
Hosted per-PR preview URLs are not configured.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
