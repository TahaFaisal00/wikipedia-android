# Wikipedia for Android — QA Automation

[![Static validation](../../actions/workflows/dryrun.yml/badge.svg)](../../actions/workflows/dryrun.yml)

Mobile test automation for the **Wikipedia for Android** app, built with Robot
Framework and Appium.

The app under test is a real shipping product with millions of installs, not a
demo application. Twenty-one automated tests across four suites, plus six
documented defects — four of them locked by regression tests.

**[Live test report](https://tahafaisal00.github.io/wikipedia-android/)**

---

## The idea: the UI is the actor, not the oracle

Most mobile suites assert what the screen shows. The screen is the weakest
evidence available — it renders late, it virtualises long lists, and a popup can
hide it entirely.

This suite drives the app through its UI and then verifies the outcome **at the
layer that owns the truth**:

| Claim | Oracle |
|---|---|
| The right articles came back for a query | Wikipedia REST API |
| An article was really saved for offline reading | the app's SQLite database on the device |
| State survived process death | the UI, because that is where the claim lives |
| A permission took effect | the device, via `adb` |

Not every test uses every oracle. Asserting at all three layers on every test is
noise; the oracle is chosen by where the risk actually is.

A concrete example: `Saved Article Is Readable With Network Off` fetches the
expected article text from the API **while still online**, kills connectivity,
then compares the rendered text against it. Nothing could have fetched that
content — so the comparison proves it came from disk.

---

## What is covered

| Suite | Tests | Focus |
|---|---|---|
| `tests/search.robot` | 5 | Search results against the API oracle, result updates, empty state, recent searches |
| `tests/localization_rtl.robot` | 5 | Arabic UTF-8 round-trip, RTL mirroring, Arabic article content, LTR content under an RTL interface |
| `tests/offline_saving.robot` | 5 | Saving and removing articles, offline readability, durability across restart, reading lists — all verified in SQLite |
| `tests/lifecycle.robot` | 6 | Backgrounding, real process death, activity recreation, permission timing, bottom-nav state |

Suites are split **by risk, not by screen**. A test that uses search as a vehicle
to verify Arabic encoding belongs in the localization suite, not the search
suite. Each suite binds one Wikipedia host in its Suite Setup, and the RTL suite
declares its locale as a session capability at launch rather than mutating device
language mid-run.

---

## Defects found

Six confirmed defects — see **[BUGS.md](BUGS.md)** for full reports, evidence and
the candidates that were investigated and rejected.

| # | Defect | Severity | Coverage |
|---|---|---|---|
| [1](../../issues/1) | Expanded section and reading position lost after activity recreation | Minor | Regression test |
| [2](../../issues/2) | Search results refetched instead of restored, and lost when offline | Moderate | Regression test |
| [3](../../issues/3) | Granted location permission not honoured until the screen is recreated | Moderate | Regression test |
| [4](../../issues/4) | Article load failure sometimes offers no retry | Minor | Manual |
| [5](../../issues/5) | Feed tabs, description card and "Today" label hardcoded to English | Minor | Regression test |
| [6](../../issues/6) | Home survey dialog only partially translated | Minor | Manual |

### Bug-lock convention

Tests covering confirmed deterministic defects assert **that the defect exists**.
They pass against the current build and turn red the day the app is fixed.

Each carries the reasoning in its `[Documentation]`, including *"a RED here means
it was fixed"*, so a green is never misread as "this works". Select them with:

```bash
robot --include bug-locked tests/
```

---

## Layout

```
pages/               locators only — zero keywords
resources/           app, network, device, and one actions file per screen
resources/oracles/   api_oracle, db_oracle — read only
tests/               one .robot per suite
log/                 Robot Framework output
```

Three rules hold this together:

**Locators never live beside keywords.** `pages/` holds variables and nothing
else, so a UI change has exactly one edit point.

**Oracles are read-only.** `db_oracle` pulls the device database and queries it.
It never writes. A test that could repair state through the back door is not
testing the app.

**Tests never call Appium primitives directly.** `Background Application`,
`Activate Application` and friends are wrapped in `resources/app.resource`, so a
library rename is one edit rather than twenty.

---

## Design decisions worth reading

These came out of failures, not planning. They are the part of the project that
took the longest.

**Setup must ensure, not check.** A setup that asserts "the article is not saved"
blocks every run after the first failure. A setup that *makes* it not saved
self-heals. `offline_saving` uses one `Ensure Clean Saved State` keyword as both
setup and teardown, gated on the database rather than the screen — so it works
from any state a test can die in, including inside a WebView or a half-open
dialog.

**Popup windows hide the entire accessibility tree.** While a balloon tip,
context menu or card overflow menu is open, the tree root is that popup alone.
Elements plainly visible on screen report as "not found". Several days of
apparent flakiness traced back to this single fact.

**Positional locators only where the app gives no alternative.** `instance(2)` on
a context menu breaks the moment the menu has a different number of items — and
the Save menu genuinely has two shapes, with two different removal labels,
depending on how the article was reached.
`className("android.widget.Button").instance(0)` matched a feed card's overflow
button and silently opened the wrong menu. Locators are keyed on a resource id or
on text wherever the app exposes one. Four positional locators remain where it
does not: the first-run tutorial, the search tip, the Compose result list, and
the default reading list. Each is scoped to a screen where nothing else can
match — and the Compose list is a testability finding in its own right, recorded
in BUGS.md.

**Retry the pair; never guess a timeout.** An onboarding dialog that fires on a
launch cadence cannot be waited out with a fixed number. Dismissal and the launch
gate are retried together until the screen is genuinely clear. The same shape
covers the Save context menu, the Developer options list, and the reading-list row.

**A conditional wait that is too short is worse than no wait.** The delete-list
confirmation is optional — it does not appear for every list — so it was guarded
by a status check. Five seconds was not enough on a loaded emulator, so the guard
reported "no dialog", skipped the click, left the list undeleted, and returned
success. A false failure is loud; a false success is not. Only the database checks
at the end of teardown caught it.

**Verify the premise, not just the claim.** `am kill` only kills a process the
system already treats as cached, so a kill issued too early is a silent no-op —
the app survives and the test asserts against a premise that never held. The
process-death keyword compares the PID across the kill. The same principle guards
the device locale, `adb root`, and the developer settings: a check that reads back
a stored value proves the value is stored, not that the running system applied it.

**Robot Framework continues after failures inside a teardown.** Not a bug in the
suite — by design, so cleanup gets its chance. It does mean a wait is not a gate
in teardown, which is why the cleanup keywords check state instead of relying on
sequencing.

**Failure screenshots are turned off** with
`Register Keyword To Run On Failure  No Operation`. A single capture took 27
seconds on a loaded emulator, and every retry inside a `Wait Until Keyword
Succeeds` triggered another — the screenshots were worsening the flakiness they
were meant to document. The database is the oracle and the failure messages name
the keyword, so little is lost. Re-enable it when you need to see a screen.

---

## Running it

### Prerequisites

- Android emulator with a **Google APIs** image (not Google Play) — `adb root` is
  required to read the app database, and Play images do not allow it
- Appium 3 with the UiAutomator2 driver, running on JDK 17
- Python 3 with the dependencies in `requirements.txt`
- The Wikipedia **alpha** APK installed — the package is `org.wikipedia.alpha`

### Emulator preconditions

**Cold-boot the emulator before a full-suite run.** The UiAutomator2 server
becomes unreliable on a long-lived session, and once its instrumentation process
crashes, every subsequent test fails with a proxy error rather than a real result.

```bash
# animations off — a dialog mid-animation stalls the accessibility tree
adb -s emulator-5554 shell settings put global window_animation_scale 0
adb -s emulator-5554 shell settings put global transition_animation_scale 0
adb -s emulator-5554 shell settings put global animator_duration_scale 0

# root, for the database oracle
adb -s emulator-5554 root
```

The suite asserts root at session start rather than assuming it — losing it turns
every database read into a permission error halfway through a run.

### Appium

```bash
appium --allow-insecure="*:chromedriver_autodownload,*:adb_shell"
```

The article WebView runs Chrome 83 and needs a version-matched Chromedriver, so
autodownload is required. The quotes matter on PowerShell, which otherwise eats
the comma and passes one bogus feature name.

### Run

```bash
# full suite — the order matters, see below
robot --outputdir log tests/lifecycle.robot tests/offline_saving.robot tests/search.robot tests/localization_rtl.robot

robot --outputdir log tests/offline_saving.robot    # one suite
robot --include bug-locked tests/                    # only the bug-locked tests
robot --dryrun tests/                                # resolve keywords, execute nothing
```

### Known limitation: suite order

The app persists its own content language separately from the device locale. The
RTL suite leaves it set to Arabic, and an English search term then returns nothing
from `ar.wikipedia` — so **the RTL suite must run last, and the app's content
language must be English before a run.**

A reset through the app's shared preferences was implemented and abandoned: the
write landed intermittently and reported success either way, which is worse than
not having it at all. The planned fix is a switch through the app's own language
selector — a real user path that depends on no internal file format.

Until then the ordering above is required. Running `robot tests/` in the default
alphabetical order will fail the two suites that follow the RTL one.

---

## Continuous integration

**Static validation** runs on every push: `robot --dryrun` resolves every keyword
and variable without executing anything. It is fast, deterministic, needs no
emulator — and it catches broken keyword references, which is exactly the class of
mistake that hides inside a teardown for days.

The full suites run against a local emulator. Emulator CI is possible on hosted
runners but expensive and flaky, and a badge that goes red from infrastructure
noise stops carrying information.

---

## Not included, deliberately

**Docker and Jenkins.** Both are demonstrated in the
[PetClinic API × database project](https://github.com/TahaFaisal00). Repeating
them here would add a checklist item, not a capability — and containerising an
Android emulator plus an Appium server is a considerable amount of work for no
gain over running them locally.

Tooling should be chosen because a project needs it.
