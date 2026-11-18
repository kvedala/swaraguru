# SwaraGuru - Carnatic Studio

**Carnatic music learning, interactive practice, live pitch identification,
and instrument playback.**

SwaraGuru is a Flutter Material 3 application for exploring Carnatic swaras,
practicing Varisai patterns in any raga, and singing against a reference
Shruti. Its adaptive interface brings together a **Varisai Studio**, **Live
Pitch Coach**, and **Practice Audio** across mobile, tablet, desktop, and
web layouts.

## Current capabilities

- **Listen & Identify:** the microphone names the swarasthana you sing or
  play, in any octave, with its frequency and whether it
  belongs to the session raga.
- **Sing & Match:** the Varisai grid advances in tala while the microphone
  grades every step as Sruti Suddham, Apasruti, Wrong Swarasthana, or No
  Voice.
- **Instrument playback:** lessons play on a synthesized **harmonium**,
  **piano**, or **tampura**. The Shruti box starts with a single Sa on
  harmonium.
- **Session raga:** any of the 72 melakartas or 25 common janya ragas
  re-tunes the lesson grid, the note identifier, and the suggested tampura
  tuning.

Instrument audio is synthesized with the Web Audio API and is available on
the web build. Microphone pitch detection runs on the web, Android, iOS, and
macOS. On platforms without instrument audio, playback is visual only and the
app shows a notice.

### Base Sa and tuning

The header always shows the current raga and base Sa. Open the **Sa** picker
to choose from twelve pitches, matching the iSruthi reference table:

| Pitch | Kattai | Hz | Pitch | Kattai | Hz |
| --- | --- | --- | --- | --- | --- |
| A | 6 | 110.00 | D# | 2½ | 155.56 |
| A# | 6½ | 116.54 | E | 3 | 164.81 |
| B | 7 | 123.47 | F | 4 | 174.61 |
| C (B#) | 1 | 130.81 | F# | 4½ | 185.00 |
| C# | 1½ | 138.59 | G | 5 | 196.00 |
| D | 2 | 146.83 | G# | 5½ | 207.65 |

The default is C# (1½ Kattai). B# is another name for C at the same pitch
in this picker, not an extra pitch.

Sa, Shuddha Madhyamam (4:3), Panchamam (3:2), and Tara Shadjam (2:1) are pure
intervals. The other swarasthanas are spaced evenly (geometrically) between
these anchors. All sixteen
swara names are supported; enharmonic pairs such as R2/G1 and D3/N2 share a
pitch.

### Ragas and repertoire

Open **Library** in the main navigation to browse Sarali, Janta, Dhatu, and
Geetams. Choose a combo number or song title to open it in the studio.
Session-only custom songs and practiced raga scales appear under
**Custom Songs & Scales**.

- All 72 melakartas plus 25 popular janya ragas (Mohanam, Hamsadhwani,
  Hindolam, Abhogi, Madhyamavati, and more), searchable by name, alias such
  as "Kalyani" or "Todi", or melakarta number.
- All 14 Sarali, 15 Janta, and 8 Dhatu Varisai combos from the Foundation
  notes. Each combo has one notation pattern; the app controls practice tempo.
- Devi Sthuthi (Sree Saraswathi) in Arabhi with lyric syllables aligned to
  notation, plus the Sri Gananatha (Lambodara) excerpt in Malahari. Devi
  Sthuthi keeps the source's scale and tala as reference and uses the app's
  Arabhi pitches and existing practice transport.
- Changing the session raga re-resolves unnumbered letters: `R` in a lesson
  becomes R1 in Mayamalavagowla and R2 in Kalyani. Swaras a janya raga omits
  come from its parent melakarta.
- **Practice Raga Scale** loads the arohanam and avarohanam of the session
  raga as a lesson.
- A custom song dialog accepts a title, a raga, and space-separated swaras
  such as `S R G M P D N Ṡ`, explicit swarasthanas such as `R2 G3 M2`, octave
  marks (`Ṡ` or `S'` above, `Ṇ` or `N.` below), and `,` for karvai.

Ragas live in [`ragas.json`](assets/data/ragas.json). Lesson files are
[`sarali_varisai.json`](assets/data/sarali_varisai.json),
[`janta_varisai.json`](assets/data/janta_varisai.json),
[`dhatu_varisai.json`](assets/data/dhatu_varisai.json), and
[`geetams.json`](assets/data/geetams.json). Exercise `notationRows` preserve the
source's cell boundaries; upper Sa is inferred where the Foundation notes do
not mark the register. A Geetam `score` groups rows by section and sangathi,
with notation and a lyric syllable in each cell. Legacy excerpts can still use
flat `notation`. Custom songs remain in memory for the current session.

### Kaalam and Adi Tala practice

The practice transport supports four speeds within an eight-beat Adi Tala
cycle:

| Kaalam | Swaras per beat |
| --- | --- |
| Tempo 1 | 1 |
| Tempo 2 | 2 |
| Tempo 3 | 4 |
| Tempo 4 | 8 |

The beat starts at **60 BPM**. Use **−** and **+** to adjust it in **10 BPM**
steps up to **200 BPM**. Kaalam sets how many swaras fit in each beat.
The swara grid starts each written score row on a fresh line and spaces out
its notation cells. This shows the beat groups even in single-row Sarali
exercises. On narrow screens the grid wraps between groups when they fit,
with extra space between written rows. Scale practice
separates arohanam and avarohanam. For flat notation, the grid starts a new row
each talam cycle when the beat count is known, using the selected kaalam.
Sri Gananatha uses the eight-beat Adi practice grid. Long scores load as you
scroll. Tap a swara to hear it.
**Play Varisai** plays each swara on
the selected instrument and holds it through any karvai. The grid highlights
the active swara, and the compact beat strip highlights the beat and shows
the current clap, finger count, or wave. Each beat marker has a tooltip
with its full tala instruction.

Open **Practice audio** from the headphones button in the header to start
or stop the audible metronome. Its tempo uses the same BPM as the lesson.
The metronome runs independently of the lesson, including in a background
browser tab or while the Android or iOS app is minimized. Mobile playback
can also be paused from system media controls. Browsers and operating
systems may still interrupt audio, for example during calls or if an app or
tab is force-closed.

### Live Pitch Coach

- **Listen & Identify** shows the nearest swara to a steady note, based on
  your chosen Sa. It waits for about a quarter second of consistent
  readings before updating the display. Start by holding one swara steadily.
- **Sing & Match** compares each grid step with the median of the steady
  pitches heard during that step. Singing an octave higher or lower is
  accepted.
  - **Matched (Sruti Suddham):** the pitch was within the selected tolerance
    above or below the expected frequency in the octave you sang. Use
    **Pitch tolerance** in **Live Pitch Coach → Sing & Match** to set it
    from 0% to 3%. The default is 1.5%; changes apply to new evaluations.
  - **Pitch drift (Apasruti):** the swara was right but a little high or low.
  - **Wrong Swarasthana:** a different swarasthana from the expected note.
  - **No Voice:** no steady pitch during the step.
- **Coach Input** switches between the microphone and two demo singers, a
  student with typical mistakes and a pitch-perfect Vidwan.

Use headphones so the drone and reference notes do not leak into the
microphone.

### Audio and microphone

On the web, click **Play Shruti** (or **Start Drone** in the Shruti Drone
Lab). Audio starts from a user gesture, as required by browser autoplay
policies. Each instrument is an additive-synthesis voice with its own
harmonics, envelope, and filter. The tampura plucks its lowest string first,
then the remaining strings from the top down, repeating the cycle like a
traditional tampura. Pitch, instrument, channel levels, and
volume update while playing.

The first time you use **Listen & Identify** or start **Sing & Match** with
microphone input, your browser asks for microphone permission. The web app
requires a secure context (HTTPS or `localhost`).

The microphone stream is analysed on the device with the YIN pitch detection
algorithm. Microphone audio is never recorded, stored, or uploaded, and the
microphone is released as soon as listening and coaching stop.

### Practice Audio

- **Single note:** starts with a sustained Sa on harmonium. Choose Piano,
  Tampura, or Harmonium under **Sound**, then select Sa, M1, M2, Pa, N3,
  or upper Sa as the reference swara.
- **Multi note:** mix lower Pa, lower N3, Sa, M1, M2, Pa, N3, and upper Sa
  independently. Choose Tampura, Harmonium, or Piano.
- Pa, Ma, Ni, and Sa-only tampura tunings, with the tuning that suits the
  session raga highlighted.
- The **Shared volume** slider adjusts Shruti and the metronome together.
- Open the panel from the header or the **Audio** tab.

<!-- end-of-app-help: the in-app Help page shows only the content above. -->

## Getting started

### Prerequisites

- Flutter **3.50.0 stable**, matching the CI workflow, with Dart **3.14.0**
  or a compatible SDK satisfying `>=3.14.0 <4.0.0`.
- Chrome for web development, or the appropriate Flutter toolchain for
  another target platform.

```sh
git clone https://github.com/kvedala/swaraguru.git
cd swaraguru
flutter pub get
flutter run -d chrome
```

For other configured targets, use `flutter devices` to find the device ID,
then run `flutter run -d <device-id>`.

### Microphone permissions

The browser asks for microphone access the first time you press **Listen &
Identify** or start **Sing & Match** with microphone input. Native builds
declare the permission in `ios/Runner/Info.plist`,
`macos/Runner/Info.plist` plus the macOS entitlements, and
`android/app/src/main/AndroidManifest.xml`. The web build needs a secure
context (HTTPS or `localhost`).

### Development checks

```sh
flutter analyze
flutter test
flutter build web --release --base-href /swaraguru/
```

Model classes use `json_serializable`. After changing a class annotated with
`@JsonSerializable`, regenerate and commit the `*.g.dart` files:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The tests cover tuning, notation parsing, JSON round-trips, all 72
melakartas, pitch detection, swara identification and grading, the studio
controller, and the main UI flows with fake audio and microphone sources.

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
**License** pages. Help renders the user guide portion of this bundled README,
everything above the end-of-app-help marker, as formatted, selectable
Markdown. This includes the audio and microphone guidance; developer
documentation below the marker appears only in the repository. Updating the
guide updates the in-app documentation in the next build.
The privacy policy describes session-only lesson data, locally generated
audio, and on-device microphone analysis. The app source is licensed under
the [MIT License](LICENSE).

For questions or bug reports, visit
https://github.com/kvedala/swaraguru/issues. Issues are public; do not include
passwords, private recordings, or other sensitive information.

## Project structure

```text
swaraguru/
├── .github/workflows/web.yml   # Web validation, artifacts, and Pages deployment
├── assets/data/                # Raga and lesson catalogs (JSON)
├── lib/
│   ├── main.dart               # Loads the catalog and starts the app
│   ├── app.dart                # MaterialApp and theme
│   ├── models/                 # json_serializable models, swara extensions
│   ├── audio/                  # Instrument timbres and Web Audio engine
│   ├── pitch/                  # Microphone source, YIN detector, identifier
│   ├── studio/                 # StudioController session state
│   ├── theme/                  # SwaraColors and Material theme
│   └── ui/                     # Scaffold, screens, drawers, dialogs, widgets
├── test/                       # Model, pitch, controller, and widget tests
├── build.yaml                  # json_serializable options
├── pubspec.yaml                # SDK constraints and dependencies
└── README.md
```

The app uses `material_ui` for Material components, `web` for browser audio,
`record` for microphone capture, `json_annotation` with `json_serializable`
for models, and `markdown` with `url_launcher` for the Help page.

## Brand palette

The in-app emblem, favicon, and web install icons are derived from
[`swaraguru_logo3.png`](assets/images/swaraguru_logo3.png). Use the full
square artwork for standard icons and add padding only to the maskable variants.
Keep the Flutter-bundled emblem in `assets/images/` and standalone browser
icons in `web/`.

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

The build stamps the workflow run number into `pubspec.yaml` temporarily and
restores the original file afterward. The web app shows the running version
in the bottom-right corner and offers a reload when a newer build is available.

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
