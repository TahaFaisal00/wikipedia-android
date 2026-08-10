*** Settings ***
Library         AppiumLibrary
Library    String
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