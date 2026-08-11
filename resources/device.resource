*** Settings ***
Library         AppiumLibrary
Library    String
Library    Process
Resource        ../pages/device_settings_page.resource

*** Keywords ***
Enable Do Not Keep Activities
    [Documentation]    Turns DKA on through the Developer options switch — the only path that
    ...    applies it to the running system rather than just storing the value.
    Wait Until Keyword Succeeds    3x    2s    Toggle Do Not Keep Activities To    1
    Activate Application    org.wikipedia.alpha

Disable Do Not Keep Activities
    [Documentation]    Turns DKA off. Must run in teardown even on failure, or DKA stays live
    ...    and every later test runs under a different device configuration.
    Wait Until Keyword Succeeds    3x    2s    Toggle Do Not Keep Activities To    0
    Activate Application    org.wikipedia.alpha

Toggle Do Not Keep Activities To
    [Documentation]    One attempt at driving the switch to ${target}, confirmed by reading the
    ...    value back.
    ...    The stored value is forced to the opposite first, so the switch renders in the state
    ...    where a single tap produces ${target}.
    ...    The read-back is inside the retried attempt, not after it: a tap that lands on the
    ...    row without flipping the switch raises nothing, so an outer guard would fail without
    ...    ever retrying. A failed attempt leaves the value inverted, and the next attempt
    ...    forces it back before tapping again.
    [Arguments]    ${target}
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities', str(1 - int($target))] }}
    Toggle Do Not Keep Activities Switch
    ${value}=    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['get','global','always_finish_activities'] }}
    Should Be Equal    ${value.strip()}    ${target}

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
