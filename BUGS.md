# Bugs

Defects found in **Wikipedia for Android (alpha)** during exploratory and
automated testing. Each entry links to a GitHub issue carrying the full report:
environment, steps, expected/actual, evidence, frequency and severity.

Four of the six are locked by regression tests in this repository. Those tests
**assert that the defect exists**, so they run green today and turn red the day
the app is fixed — see [Bug-lock convention](#bug-lock-convention).

## Environment

| | |
|---|---|
| App | Wikipedia for Android (alpha), `org.wikipedia.alpha` |
| Build | versionCode 50598, minSdk 23, targetSdk 37 |
| Device | Pixel 5 AVD — Android 11 (API 30), x86_64, Google APIs image |
| Locales exercised | English, Arabic (ar), Spanish (es) |

## Summary

| # | Defect | Severity | Type | Coverage |
|---|---|---|---|---|
| [1](../../issues/1) | Expanded section and reading position lost after activity recreation | Minor | Functional — state restoration | Regression test |
| [2](../../issues/2) | Search results refetched instead of restored, and lost when offline | Moderate | Functional — state restoration | Regression test |
| [3](../../issues/3) | Granted location permission not honoured until the screen is recreated | Moderate | Functional — permissions | Regression test |
| [4](../../issues/4) | Article load failure sometimes offers no retry | Minor | Functional — error recovery | Manual |
| [5](../../issues/5) | Feed filter tabs, description card and "Today" label hardcoded to English | Minor | Localization — i18n | Regression test |
| [6](../../issues/6) | Home survey dialog only partially translated | Minor | Localization — i18n | Manual |

---

## The argument

Every defect here is an inconsistency in the app's **own** behaviour, not a
platform limitation. The app demonstrably can do the right thing — it restores
scroll position, it reacts to permission changes after recreation, it offers
retry on the search error screen, it localises numerals and layout direction
inside the very dialog that fails to translate its title.

That framing is deliberate. It is what makes each report hard to close as
"working as designed."

---

## 1. Expanded section and reading position lost after activity recreation

**Severity** Minor · **Regression test** `Expanded Section And Reading Position Are Lost After Recreation` (`tests/lifecycle.robot`)

A section the user expanded collapses after activity recreation, and if the
reading anchor sat inside it the article also returns to the top. One defect
with two manifestations: re-expanding the section jumps straight back to the
prior reading position, which proves the scroll offset **is** saved — what is
lost is the expanded state, leaving the saved offset pointing into hidden
content.

Reproduces under both Don't Keep Activities and real process death, which
distinguishes it from #2.

**Dev pointer** — survives configuration-change recreation but not activity
destruction, the signature of state held in a retained in-memory holder and
never written to the saved-instance `Bundle`.

## 2. Search results refetched instead of restored, and lost when offline

**Severity** Moderate · **Regression test** `Search Results Are Refetched Instead Of Restored After Recreation` (`tests/lifecycle.robot`)

The results list re-runs its query on activity recreation instead of restoring
saved state. Online this is a needless network round trip; offline the results
do not come back at all.

The app is not failing to save them. Under full process death the results are
restored with no fetch, even with the HTTP cache cleared — so they reach the
`Bundle` and are read back correctly. The restore path is simply not wired to
plain activity recreation.

**Test design** — asserting "it refetched" by timing would be flaky, so the test
disables the network before forcing recreation. Restored state survives a dead
network; a refetch cannot. That converts a timing observation into a
deterministic state assertion.

## 3. Granted location permission not honoured until the screen is recreated

**Severity** Moderate · **Regression test** `Location Permission Does Not Take Effect Until Places Screen Is Recreated` (`tests/lifecycle.robot`)

Granting location permission while the Places screen is open has no effect on
the running screen. Locate-me stays dead until the screen is left and re-entered.

The app registers the grant — the "permission needed" error stops appearing —
but never re-initialises the location feature. Identical whether the permission
is granted through system Settings or `adb shell pm grant`.

**Confound ruled out** — an emulator with no location fix would also produce a
dead locate-me. The paired second half of the test rules that out: same device,
same session, same permission, working immediately once the screen is recreated.

**Dev pointer** — permission checked in `onCreate`, never re-checked in
`onResume`.

## 4. Article load failure sometimes offers no retry

**Severity** Minor · **Manual**

Under poor or absent connectivity an article load failure produces one of two
error screens: a timeout error **with** a retry button that recovers in place, or
a generic "An error occurred" screen offering only go-back.

Which one appears is not predictable. An attempt-count hypothesis was tested and
ruled out — the generic screen appeared after three failures, after one, and
immediately. Go-back returns to the search results with the query intact, so
nothing is lost; the article simply cannot be retried in place. Pull-to-refresh
does reload it, but nothing on the screen indicates that.

Not automated: the claim is the absence of a control on a nondeterministic path.

## 5. Feed filter tabs, description card and "Today" label hardcoded to English

**Severity** Minor · **Regression test** test 3 in `tests/localization_rtl.robot`

Three strings on the home feed render in English regardless of device language:

- the filter tabs, "For you" and "Community"
- the Community description card, "Content and resources selected by and about
  the Wikimedia community"
- the word "Today" in the date line, concatenated onto a date that **is**
  correctly formatted for the locale — `Today - 10 أغسطس 2026`,
  `Today - 10 ago. 2026`

Confirmed byte-identical in Arabic and Spanish. Two unrelated locales rule out a
missing translation for one language: these strings are hardcoded rather than
externalised, so no locale can ever display them translated. Every non-English
locale is affected.

The rest of the same screen — bottom navigation, section headings, date
formatting, Arabic-Indic numerals — localises correctly, which is what isolates
these three as the exception.

## 6. Home survey dialog only partially translated

**Severity** Minor · **Manual**

The "Help improve Home" dialog renders in two languages at once under Arabic.
The title and the question stay in English; all five options, the feedback
placeholder, the character counter (in Arabic-Indic numerals) and both buttons
are correctly translated, and the layout is correctly mirrored for RTL.

So the localisation pipeline reaches this dialog and does sophisticated work
inside it. Two strings are the exception.

Related to #5 — the untranslated question quotes "Community" and "For you" by
name, the same two labels hardcoded on the feed itself.

**Testability note** — the dialog's trigger appears to be a persisted counter or
flag. If it can be located in shared preferences it could be forced
deterministically, which would make this assertable rather than manual-only. The
suite currently dismisses the dialog rather than making any claim about it.

---

## Bug-lock convention

Tests covering confirmed deterministic defects assert **that the defect exists**.
They run green against the current build; when the app is fixed they turn red and
the change is noticed immediately.

Every such test carries the reasoning in its `[Documentation]`, including the
line *"a RED here means it was fixed"*, so a passing test is never misread as
"this works correctly."

The alternative — asserting correct behaviour and excluding the test from CI —
produces a suite that silently stops covering the defect. Selecting them is one
command:

```
robot --include bug-locked tests/
```

---

## Testability findings

Not defects in the product, but limits on what can be asserted about it. They
shaped the suite's design and are recorded here because they are part of the
result.

**The search results list is Jetpack Compose.** Rows expose no resource-ids and
the `LazyColumn` virtualises, so only on-screen rows exist in the accessibility
tree at all. A full-list comparison against the API is therefore impossible — the
UI is the weakest available oracle because it literally cannot see the whole
truth. The suite inverts the direction instead: take the expected title from the
API and assert its presence in the UI.

**Popup windows hide everything behind them.** While a balloon tip, a context
menu or a card overflow menu is open, the accessibility tree root is that popup
alone. Elements plainly visible on screen report as "not found". Any locator
failure on an element you can see is a popup, not a missing element.

**The empty-search state renders one identical element per configured search
language** — three on this device, all with the same English text, no id, no
discriminator. Only positional indices separate them, so the assertion is scoped
to "the empty state appeared" rather than to a specific instance.

**Section collapse is not readable from a CSS class.** The `<section>` element's
own `className` is empty in both the collapsed and expanded state. Collapse is
measured as `offsetHeight` on the content div instead.

**AppiumLibrary's visibility check is unreliable in WebView context.**
`Element Should Not Be Visible` passed on an element measuring 1191px tall. That
false pass was caught only because a paired second assertion disagreed with it.

---

## Observed, not reproduced

**Article renders with full chrome over a blank content area.** Under poor
connectivity, after repeated re-entry, the article screen once rendered with its
top toolbar and the complete bottom bar (Save / Language / Find in article /
Theme / Contents) over an entirely empty content area — no error, no loading
state, no retry, no affordance of any kind. Pull-to-refresh restored the loading
state and the usual error sequence followed.

Observed once on 2026-08-09. Not reproduced despite repeated attempts, so it is
recorded rather than filed.

---

## Candidates investigated and rejected

Rejecting false positives is what makes the confirmed findings credible. Each of
these was investigated by differential isolation — change one variable, repeat
with fixed steps, count the ratio — and dismissed on the evidence.

| Candidate | Why it is not a defect |
|---|---|
| Partial theme application | Re-verified against build 50598: match-system-theme had been left on during the original observation. The app theme is applied correctly throughout. |
| Up button returns to the main page | Up is not Back. Documented Android behaviour. |
| Back skips nested search screens | Search is a transient tool, not a navigation destination. |
| Black screen and restart on permission revoke | The OS kills the process on revoke. Platform behaviour. |
| Data loss when downgrading the app | Platform-default wipe on downgrade, not reachable by a user through normal use. |
| Content language change affects only the feed | Content language and interface language are distinct settings. |
| English article stays LTR under a forced-RTL interface | Direction follows the content language. Force-flipping it would be the defect. This is now covered by a passing regression test. |
| Article lead image disappears in landscape | Reproduces in a desktop browser too — Wikipedia's own responsive web content, not the app. |

---

## Prior art

Each defect was searched on Wikimedia Phabricator before filing
(`Wikipedia-Android-App-Backlog` and `Android-app-Bugs`, all statuses). No
matching task surfaced. This is a best-effort check rather than proof of
novelty — the tracker is large and inconsistently tagged.
