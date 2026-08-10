*** Settings ***
Library         AppiumLibrary
Library    String
Library    Process
Resource        ../pages/device_settings_page.resource

*** Keywords ***
Enable Do Not Keep Activities
    [Documentation]    Taps the Developer options switch — the only path that applies DKA to the
    ...    running system. Forces the stored value to 0 first so the tap always turns it on.
    ...    NOTE: because the stored value is forced to the opposite before tapping, a failed tap
    ...    leaves it inverted rather than unchanged. Correct DKA by hand after any failure here.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','0'] }}
    Toggle Do Not Keep Activities Switch
    ${value}=    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['get','global','always_finish_activities'] }}
    Should Be Equal    ${value.strip()}    1
    Activate Application    org.wikipedia.alpha

Toggle Do Not Keep Activities Switch
    [Documentation]    Opens Developer options and taps the "Don't keep activities" row.
    ...    Shared by the enable and disable keywords, which differ only in the stored value
    ...    they force beforehand and the value they assert afterwards.
    Execute Script    mobile: shell    command=am
    ...    args=${{ ['start','-a','android.settings.APPLICATION_DEVELOPMENT_SETTINGS'] }}
    Wait Until Keyword Succeeds    20s    2s    Tap Do Not Keep Activities Row

Tap Do Not Keep Activities Row
    [Documentation]    One attempt at scrolling to the switch and tapping it.
    ...    Waits for a scrollable container first: UiScrollable's scrollIntoView is one-shot and
    ...    throws the moment it runs if the list has not rendered, rather than waiting for it.
    ...    Safe to retry because the locator resolves before the tap — a failed attempt never
    ...    leaves a half-toggled switch behind.
    Wait Until Page Contains Element    ${SETTINGS_SCROLLABLE}    timeout=5s
    Click Element                       ${DKA_ROW}

Disable Do Not Keep Activities
    [Documentation]    Taps the Developer options switch — the only path that applies DKA to the
    ...    running system. Forces the stored value to 0 first so the tap always turns it on.
    ...    NOTE: because the stored value is forced to the opposite before tapping, a failed tap
    ...    leaves it inverted rather than unchanged. Correct DKA by hand after any failure here.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','1'] }}
    Toggle Do Not Keep Activities Switch
    ${value}=    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['get','global','always_finish_activities'] }}
    Should Be Equal    ${value.strip()}    0
    Activate Application    org.wikipedia.alpha

Grant Location Permission
    [Documentation]    Grants fine location without touching the app. Coarse stays denied;
    ...    the bug reproduces with fine alone.
    Execute Script    mobile: shell    command=pm
    ...    args=${{ ['grant','org.wikipedia.alpha','android.permission.ACCESS_FINE_LOCATION'] }}

Revoke Location Permission
    [Documentation]    Revokes fine location. Android kills the app process when a granted
    ...    permission is revoked, so the app must be relaunched after this.
    Execute Script    mobile: shell    command=pm
    ...    args=${{ ['revoke','org.wikipedia.alpha','android.permission.ACCESS_FINE_LOCATION'] }}

Verify App Is Requesting Location
    [Documentation]    Asserts the app holds an active gps request. This is the real signal —
    ...    the map is a SurfaceView, so a working locate-me is invisible to Appium.
    ${output}=    Execute Script    mobile: shell    command=dumpsys    args=${{ ['location'] }}
    ${lines}=    Get Lines Containing String   ${output}    gps: org.wikipedia.alpha
    Should Contain    ${lines}    Currently active

Verify App Is Not Requesting Location
    [Documentation]    Asserts the app holds no active gps request.
    ${output}=    Execute Script    mobile: shell    command=dumpsys    args=${{ ['location'] }}
    ${lines}=    Get Lines Containing String    ${output}    gps: org.wikipedia.alpha
    Should Not Contain    ${lines}    Currently active

Verify App Process Is Gone
    [Documentation]    Asserts the app process is really dead.
    ...    am force-stop returns before the process has actually exited, and the app rewrites
    ...    its shared preferences on the way out — editing the file before then loses the edit,
    ...    or reads it back mid-write.
    ${result}=    Run Process    adb    -s    ${DEVICE}    shell    pidof    org.wikipedia.alpha
    ...    stderr=STDOUT
    Should Be Empty    ${result.stdout.strip()}

Write App Language
    [Documentation]    One attempt at writing the language prefs and reading them back.
    ...    The read-back is the point: sed reports success even when the edit does not land,
    ...    so rc alone would let a suite run against the wrong language and pass for the
    ...    wrong reason.
    [Arguments]    ${code}
    ${script}=    Set Variable
    ...    s|"languageApp">[a-z]*<|"languageApp">${code}<|; s|"homeLanguageCode">[a-z]*<|"homeLanguageCode">${code}<|
    ${result}=    Run Process    adb    -s    ${DEVICE}    shell    sed    -i    "${script}"
    ...    /data/data/org.wikipedia.alpha/shared_prefs/org.wikipedia.alpha_preferences.xml
    ...    stderr=STDOUT
    Should Be Equal As Integers    ${result.rc}    0    msg=${result.stdout}
    ${check}=    Run Process    adb    -s    ${DEVICE}    shell    grep    -o
    ...    "homeLanguageCode..[a-z]*"
    ...    /data/data/org.wikipedia.alpha/shared_prefs/org.wikipedia.alpha_preferences.xml
    ...    stderr=STDOUT
    Should End With    ${check.stdout.strip()}    ${code}

Set App Language
    [Documentation]    Forces the app's own content language. This is separate state from the
    ...    device locale and survives both a new session and a locale change — the app writes
    ...    these prefs to match the device locale on launch and never reverts them, so a suite
    ...    that ran in Arabic leaves every later suite searching ar.wikipedia.
    ...    Run Process rather than mobile: shell, for two reasons. mobile: shell does not quote
    ...    its arguments for the device shell, so the angle brackets are read as redirection and
    ...    /system/bin/sh dies before sed runs. And Run Process needs no Appium session, so this
    ...    can run before one exists.
    ...    The sed script is passed as one argument with literal double quotes: those reach the
    ...    device shell and stop it parsing the pipes and brackets itself.
    ...    The app is force-stopped first — it holds shared preferences in memory and would
    ...    overwrite the file on exit — and the process death is then waited for, because
    ...    force-stop is asynchronous and an edit that lands too early is silently lost.
    ...    The write is retried: the edit intermittently fails to land on the first attempt
    ...    after a cold boot, and the read-back catches that rather than letting it through.
    [Arguments]    ${code}
    Run Process    adb    -s    ${DEVICE}    shell    am    force-stop    org.wikipedia.alpha
    ...    stderr=STDOUT
    Wait Until Keyword Succeeds    10s    1s    Verify App Process Is Gone
    Wait Until Keyword Succeeds    3x    2s    Write App Language    ${code}