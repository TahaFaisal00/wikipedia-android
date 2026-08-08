*** Settings ***
Library         AppiumLibrary
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