# SwaraGuru - Carnatic Studio

**Carnatic music learning, interactive practice, and web Shruti playback.**

SwaraGuru is a Flutter Material 3 application for exploring Carnatic swaras,
practicing Varisai patterns, and maintaining a reference Shruti. Its adaptive
interface brings together a **Varisai Studio**, **Live Pitch Coach**, and
**Shruti Drone Lab** across mobile, tablet, desktop, and web layouts.

## Current capabilities

The web Shruti drone produces real audio. Lesson transport and vocal coaching
currently use visual simulations: they do not play lesson audio, capture a
microphone, or analyze a singer's voice.

### Carnatic repertoire and custom notation

- Built-in Sarali Varisai 1-3, Janta Varisai 1, and Dhatu Varisai 1 exercises.
- A Sri Gananatha (Lambodara) Pillari Geetham excerpt in Malahari.
- A custom sequence dialog for entering a title, raga, and space-separated
  swaras, such as `S R G M P D N Ṡ` or explicit swarasthanas such as
  `R2 G3 M2 D2 N3`.
- A notation grid and calculated reference frequencies relative to the chosen
  base Sa.

Custom sequences remain in memory for the current app session. The broader
repertoire described in the project concept, including Sarali Varisai 4-6,
Melsthayi Varisai, and Sapta Tala Alankaram, is not yet included.

### Base Sa and fine tuning

Choose a reference pitch from C through B, including sharps and a B# option.
Kattai labels accompany the pitch choices. Fine tuning from **-50 to +50 cents**
adjusts the reference, with swara frequencies calculated relative to the
effective Sa.

### Kaalam and Adi Tala practice

The visual practice transport supports four speeds within an eight-beat
Adi Tala cycle:

| Kaalam | Swaras per beat |
| --- | --- |
| Tempo 1 | 1 |
| Tempo 2 | 2 |
| Tempo 3 | 4 |
| Tempo 4 | 8 |

Set the tempo from **40 to 140 BPM** and follow the active swara and Tala hand
gesture indicators. These controls advance the visual lesson; they do not
synthesize its notes.

### Pitch-coaching simulator

The Live Pitch Coach demonstrates expected-versus-detected pitch feedback
using simulated student mistakes or a simulated pitch-accurate Vidwan:

- **Sruti Suddham:** a matching swarasthana within 25 cents.
- **Apasruti:** pitch drift greater than 25 cents within the expected
  swarasthana family.
- **Wrong Swarasthana:** a different swarasthana from the expected note.

Frequency, cent deviation, and note-level diagnostics illustrate the intended
coaching experience. Real microphone input and live vocal pitch detection
are not implemented.

### Shruti Drone Lab

- **Pure single-note mode:** an isolated sine-tone reference for Sa, M1, M2,
  Pa, N3, or upper Sa.
- **Multi-note mode:** independently mixed lower Pa, lower N3, Sa, M1, M2,
  Pa, N3, and upper Sa.
- Panchama, Madhyama, Nishada, and octave-Sa presets.
- Live pitch, fine-tuning, channel-level, and master-volume controls.
- Quick access through the app bar, right-hand Shruti drawer, and dedicated
  Shruti Drone Lab screen.

## Getting started

### Prerequisites

- Flutter **3.50.0 stable**, matching the CI workflow, with Dart **3.14.0**
  or a compatible SDK satisfying `>=3.14.0 <4.0.0`.
- Chrome for web development, or the appropriate Flutter toolchain for
  another target platform.

Clone this repository rather than creating a new Flutter project or copying
only `main.dart`: the app also needs its audio implementation and declared
dependencies.

```sh
git clone https://github.com/kvedala/swaraguru.git
cd swaraguru
flutter pub get
flutter run -d chrome
```

For other configured targets, use `flutter devices` to find the device ID,
then run `flutter run -d <device-id>`. Shruti audio is currently web-only.

### Development checks

```sh
flutter analyze
flutter test
flutter build web --release --base-href /swaraguru/
```

The widget tests cover drone playback controls, mixer changes during playback,
and visible playback errors.

## Web Shruti playback

Run `flutter run -d chrome`, then click **Play Shruti** (or **Start Drone** in
the Shruti Drone Lab). Playback starts from a user gesture, as required by
browser autoplay policies. Pure mode synthesizes a sine tone; multi-note mode
mixes continuous sine tones, not a sampled tambura. Pitch, fine tuning, channel
levels, and master volume update while playing. Stop ends all active tones.

Shruti audio currently supports web only; other platforms show an unsupported
playback message. Reference lesson playback and vocal coaching remain visual
simulations, not audio playback or microphone input.

## Adaptive interface

`SwaraGuruAdaptiveScaffold` uses `LayoutBuilder` to switch navigation at these
viewport widths (Flutter logical pixels):

| Layout | Width | Primary navigation |
| --- | --- | --- |
| Mobile | Below 600 | Bottom navigation bar |
| Tablet | 600 to below 1024 | Compact navigation rail |
| Desktop / wide web | 1024 and above | Extended navigation rail |

All layouts include a left repertoire drawer, right Shruti drawer, and
app-bar controls. The app bar identifies the current screen; its **Home**
button returns to Varisai Studio without resetting the selected lesson or
tuning. The Veena-and-microphone emblem and mandala hero banner
are drawn with Flutter `CustomPainter`; no raster brand assets are required.

The left navigation drawer also includes **Help**, **Privacy Policy**, and
**License** pages. Help displays this bundled README as selectable Markdown,
so updating the README updates the in-app documentation in the next build.
The privacy policy describes session-only lesson data,
locally generated Shruti audio, and the lack of microphone capture. The app
source is licensed under the [MIT License](LICENSE).

For questions or bug reports, visit
https://github.com/kvedala/swaraguru/issues. Issues are public; do not include
passwords, private recordings, or other sensitive information.

## Project structure

```text
swaraguru/
├── .github/workflows/web.yml  # Web validation, artifacts, and Pages deployment
├── lib/
│   ├── main.dart             # Adaptive UI, repertoire, tuning, and simulation
│   ├── shruti_audio.dart     # Conditional audio implementation export
│   ├── shruti_audio_stub.dart # Unsupported-platform audio implementation
│   └── shruti_audio_web.dart # Browser Web Audio synthesis
├── test/widget_test.dart     # Playback, mixer, and error-path tests
├── pubspec.yaml              # SDK constraints and dependencies
└── README.md
```

The app uses `material_ui` for Material components and `web` for browser audio
APIs. The separate `SwaraGuruApp.jsx` prototype and Figma SVG-export workflow
described in the project concept are not included in this repository.

## Brand palette

The Flutter theme defines these colors in `SwaraColors`:

| Token | Hex | Usage |
| --- | --- | --- |
| `midnightBg` | `#0B0E1D` | Deep-indigo background |
| `indigoSurface` | `#13182E` | App bar, navigation, and drawer surfaces |
| `indigoCard` | `#19203B` | Studio cards |
| `royalGold` | `#E5B869` | Emblem and active accents |
| `brightGold` | `#FDE68A` | Brand typography and swara highlights |
| `cyanWave` | `#38BDF8` | Waveform, frequency, and Kaalam accents |
| `emeraldMatch` | `#10B981` | Matching-pitch feedback |
| `warmAmber` | `#F59E0B` | Pitch-drift warning |
| `crimsonRobes` | `#E11D48` | Wrong-swarasthana feedback |

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
