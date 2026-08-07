*** Settings ***
Library     AppiumLibrary

*** Keywords ***
Enable Do Not Keep Activities
    [Documentation]    Turns on the DKA developer setting and verifies it stuck.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','1'] }}
    ${value}=    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['get','global','always_finish_activities'] }}
    Should Be Equal    ${value.strip()}    1

Disable Do Not Keep Activities
    [Documentation]    Restores the DKA setting to off.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','0'] }}