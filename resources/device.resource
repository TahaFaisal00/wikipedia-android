*** Settings ***
Library     AppiumLibrary

*** Keywords ***
Enable Do Not Keep Activities
    [Documentation]    Stores the DKA setting, applies it to the running system, and verifies it stuck.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','1'] }}
    Execute Script    mobile: shell    command=service
    ...    args=${{ ['call','activity','43','i32','1'] }}
    ${value}=    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['get','global','always_finish_activities'] }}
    Should Be Equal    ${value.strip()}    1

Disable Do Not Keep Activities
    [Documentation]    Restores the DKA setting to off.
    Execute Script    mobile: shell    command=settings
    ...    args=${{ ['put','global','always_finish_activities','0'] }}