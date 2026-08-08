*** Settings ***
Library         AppiumLibrary
Resource        ../pages/places_page.resource

*** Keywords ***
Open Places Screen
    [Documentation]    More tab, then Places. Stops before the screen settles — the
    ...    permission dialog may be on top, so the caller handles it next.
    Wait Until Page Contains Element    ${NAV_MORE}
    Click Element    ${NAV_MORE}
    Wait Until Page Contains Element    ${MENU_PLACES}
    Click Element    ${MENU_PLACES}

Deny Location Permission If Prompted
    [Documentation]    Conditional — the dialog only appears while permission is missing,
    ...    and Android stops showing it after repeated denials.
    ${prompted}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    ${LOCATION_PERMISSION_DENY}    timeout=3s
    Run Keyword If    ${prompted}    Click Element    ${LOCATION_PERMISSION_DENY}

Verify Places Screen Loaded
    Wait Until Page Contains Element    ${MY_LOCATION_BUTTON}

Leave And Reopen Places Screen
    Wait Until Page Contains Element    ${PLACES_BACK}
    Click Element    ${PLACES_BACK}
    Open Places Screen
    Deny Location Permission If Prompted
    Verify Places Screen Loaded

Tap Locate Me
    Wait Until Page Contains Element    ${MY_LOCATION_BUTTON}
    Click Element    ${MY_LOCATION_BUTTON}