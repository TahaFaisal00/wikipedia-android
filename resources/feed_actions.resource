*** Settings ***
Library          AppiumLibrary
Resource         ../pages/feed_page.resource
*** Keywords ***
Verify Bottom Navigation Is Translated
    [Documentation]     Premise. Confirms the interface really did switch to Arabic,
    ...                 so the untranslated tabs read as a defect and not as a locale
    ...                 that never applied.
    ...                 Explicit timeouts because this runs on a freshly launched app under
    ...                 a new locale, which is the slowest render in the suite. The default
    ...                 5s made this intermittent. The locators stay keyed on the Arabic
    ...                 labels — a resource id would be present whether or not the app
    ...                 translated anything, so it could not fail and would prove nothing.
    Wait Until Page Contains Element    ${ARABIC_SEARCH_BAR_NAME}    timeout=20s
    Wait Until Page Contains Element    ${ARABIC_MORE_BAR_NAME}      timeout=20s

Verify Feed Filter Tabs Are Untranslated
    [Documentation]     Asserts the ENGLISH tab labels — this locks BUG 6, it does not
    ...                 describe correct behavior. The tabs should be Arabic; the strings
    ...                 are hardcoded. A failure here means the bug was fixed and this
    ...                 keyword should be inverted.
    Wait Until Page Contains Element    ${ENGLISH_COMMUNITY_FEED_FILTER}
    Wait Until Page Contains Element    ${ENGLISH_FOR_YOU_FEED_FILTER}

Verify Bottom Navigation Is Mirrored
    [Documentation]     Under LTR the Search tab sits left of More. Under Arabic the bar
    ...                 mirrors, so Search must sit to the RIGHT of More. Compares the two
    ...                 x positions against each other rather than absolute coordinates,
    ...                 so it holds on any screen size or density.
    ${search}=    Get Element Location    ${ARABIC_SEARCH_BAR_NAME}
    ${more}=      Get Element Location    ${ARABIC_MORE_BAR_NAME}
    Should Be True    ${search}[x] > ${more}[x]







