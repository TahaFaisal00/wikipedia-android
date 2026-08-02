*** Settings ***
Library          AppiumLibrary
Resource         ../pages/feed_page.resource
*** Keywords ***
Verify Bottom Navigation Is Translated
    [Documentation]      Premise. Confirms the interface really did switch to Arabic,
    ...                 so the untranslated tabs read as a defect and not as a locale
    ...                 that never applied.
    Wait Until Page Contains Element    ${ARABIC_SEARCH_BAR_NAME}
    Wait Until Page Contains Element    ${ARABIC_MORE_BAR_NAME}

Verify Feed Filter Tabs Are Untranslated
    [Documentation]     Asserts the ENGLISH tab labels — this locks BUG 6, it does not
    ...                 describe correct behavior. The tabs should be Arabic; the strings
    ...                 are hardcoded. A failure here means the bug was fixed and this
    ...                 keyword should be inverted.
    Wait Until Page Contains Element    ${ENGLISH_COMMUNITY_FEED_FILTER}
    Wait Until Page Contains Element    ${ENGLISH_FOR_YOU_FEED_FILTER}








