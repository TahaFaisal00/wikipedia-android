*** Settings ***
Library         AppiumLibrary
Library    String
Resource        ../pages/device_settings_page.resource

*** Keywords ***
Enable Do Not Keep Activities
    [Documentation]    Taps the Developer options switch — the only path that applies DKA to the
    ...    running system. Forces the stored value to 0 first so the tap always turns it on.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','0'] }}
    Execute Script    mobile: shell    command=am
    ...    args=${{ ['start','-a','android.settings.APPLICATION_DEVELOPMENT_SETTINGS'] }}
    Click Element    ${DKA_ROW}
    ${value}=    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['get','global','always_finish_activities'] }}
    Should Be Equal    ${value.strip()}    1
    Activate Application    org.wikipedia.alpha

Disable Do Not Keep Activities
    [Documentation]    Mirror of the enable keyword. Must run in teardown even on failure, or DKA
    ...    stays live and every later test runs under a different device configuration.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','1'] }}
    Execute Script    mobile: shell    command=am
    ...    args=${{ ['start','-a','android.settings.APPLICATION_DEVELOPMENT_SETTINGS'] }}
    Click Element    ${DKA_ROW}
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