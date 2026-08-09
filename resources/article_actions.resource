*** Settings ***
Library         AppiumLibrary
Library          String
Resource        ../pages/article_page.resource
Resource        oracles/api_oracle.resource
Resource        reading_list_actions.resource
Resource        oracles/db_oracle.resource
*** Keywords ***
Normalize Article Text
    [Documentation]    Kill the [1][2] markers and squash whitespace so UI and API compare clean.
    [Arguments]    ${text}
    ${text}=    Replace String Using Regexp    ${text}    \\[\\d+\\]    ${EMPTY}
    ${text}=    Replace String Using Regexp    ${text}    \\s+    ${SPACE}
    ${text}=    Strip String    ${text}
    RETURN    ${text}

Open Article WebView
    [Documentation]    Switches to the WebView and waits for the article body to render.
    ...    The context can exist before the page has content, so both waits are needed.
    app.Switch To Article WebView
    Wait Until Page Contains Element    ${ARTICLE_BODY_TEXT_LOCATOR}

Read Article Body Text
    [Documentation]     Switch to WebView, read the first paragraph, clean out the
    ...                [1] refs and extra spaces, switch back to Native.
    Open Article WebView
    ${raw_body}=        Get Text    ${ARTICLE_BODY_TEXT_LOCATOR}
    ${clean_body}=      Normalize Article Text      ${raw_body}
    Return To Native Context
    RETURN      ${clean_body}

Dismiss Games Promo If Present
    [Documentation]     Close the games promo if it pops up. Skip it if it's not there.
    ${present}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    ${WIKIPEDIA_GAMES_AD_CLOSE_BUTTON}    5s
    Run Keyword If    ${present}    Click Element    ${WIKIPEDIA_GAMES_AD_CLOSE_BUTTON}

Verify Article Page Loaded
    [Documentation]     Wait for the article title so the page is ready.
    [Arguments]     ${article_title}
    Wait Until Page Contains Element    ${article_title}

Verify UI Paragraph Matches API Paragraph
    [Documentation]     Read the first paragraph and check it's inside the API intro.
    ...                UI acts, API observes.
    [Arguments]     ${article_name}
    ${ui_article_paragraph}=        Read Article Body Text
    ${api_article_paragraph}=       api_oracle.Get Expected Article Extract     ${article_name}
    Should Contain       ${api_article_paragraph}          ${ui_article_paragraph}

Verify Article Content Direction
    [Documentation]     Switch to WebView, Reads the CSS direction the WebView actually computed for the
    ...                 article body. Content direction follows the ARTICLE's language,
    ...                 not the interface's — an English article stays LTR inside a
    ...                 mirrored Arabic app, and that is correct behavior, not a defect.
    ...                 switch back to Native.
    [Arguments]    ${expected}
    Open Article WebView
    ${direction}=    Execute Script
    ...    return getComputedStyle(document.querySelector('p')).direction
    Should Be Equal    ${direction}    ${expected}
    Return To Native Context

Save Article
    [Documentation]     Taps Save on an UNSAVED article.
    ...    The Save control is state dependent: on an already-saved article the
    ...    same tap opens a context menu instead. The caller must guarantee the
    ...    unsaved starting state, because this keyword does not check it.
    Wait Until Page Contains Element    ${SAVE_ARTICLE_BUTTON}
    Click Element                       ${SAVE_ARTICLE_BUTTON}

Verify Snackbar Says
    [Documentation]    Waits for the snackbar text itself rather than the element
    ...    and then the text: the snackbar auto-dismisses, and a two-call check
    ...    can lose it in the gap between the calls.
    ...    Text is the only discriminator anyway - save, move and remove share one
    ...    snackbar id - so matching on text alone gives up nothing.
    [Arguments]    ${expected_text}
    Wait Until Page Contains    ${expected_text}    timeout=10s
    
Remove Article From List
    [Documentation]     Un-saves an article that is currently SAVED.
    ...    Un-saving is not a second tap on Save: that tap opens a context menu
    ...    and the removal lives inside it. Used as teardown so the next test
    ...    starts unsaved.
    Open Save Context Menu
    Click Element           ${REMOVE_FROM_LIST_BUTTON}

Verify UI Paragraph Matches Extract
    [Documentation]    Reads the first paragraph on screen and checks it sits
    ...    inside the given API extract. UI acts, API observes.
    ...    Takes the extract as an argument rather than fetching it, so callers
    ...    that cannot reach the API - the offline test - can fetch it earlier
    ...    and still use the same comparison.
    [Arguments]    ${expected_extract}
    ${ui_article_paragraph}=    Read Article Body Text
    Should Contain    ${expected_extract}    ${ui_article_paragraph}

Navigate Back To Search Page
    [Documentation]    Returns from an article to the search screen.
    ...    Waits for the search screen rather than counting back taps: the depth
    ...    of the back stack depends on how the article was reached, and blind
    ...    consecutive taps race the screen transition.
    ...    The sync prompt can appear on the way back and is dismissed if seen.
    Wait Until Page Contains Element    ${RETURN_BUTTON}
    Click Element                       ${RETURN_BUTTON}
    reading_list_actions.Dismiss Sync Reading Lists Prompt If Present
    ${on_search}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${SAVED_BAR}
    IF    not ${on_search}
        Click Element    ${RETURN_BUTTON}
    END
    Wait Until Page Contains Element    ${SAVED_BAR}

Add Article To New Reading List
    [Documentation]    Creates a named reading list from the article screen and
    ...    adds the current article to it.
    ...    Goes through the Save context menu rather than the snackbar's action
    ...    button: the snackbar is on a timer and would race the test. The menu
    ...    is also the branch this test exists to cover.
    ...    The confirmation asserts the list name, which the snackbar includes -
    ...    that is what distinguishes this message from the plain save one.
    [Arguments]    ${list_name}
    Open Save Context Menu
    Wait Until Page Contains Element    ${ADD_TO_ANOTHER_LIST_MENU_ITEM}
    Click Element                       ${ADD_TO_ANOTHER_LIST_MENU_ITEM}
    Wait Until Page Contains Element    ${CREATE_NEW_LIST_BUTTON}
    Click Element                       ${CREATE_NEW_LIST_BUTTON}
    Wait Until Page Contains Element    ${LIST_NAME_FIELD}
    Input Text                          ${LIST_NAME_FIELD}    ${list_name}
    Click Element                       ${ADD_TO_LIST_OK_BUTTON}

Verify Article Title Is
    [Documentation]    Asserts the article header still shows the expected title.
    [Arguments]   ${actial_article}         ${expected_title}
    Wait Until Page Contains Element    ${actial_article}    timeout=20s
    Element Should Contain Text         ${actial_article}    ${expected_title}

Expand Article Section
    [Documentation]    Clicks the section header, firing the app's own toggle handler.
    [Arguments]    ${section_id}
    ${locator}=    Format String    ${ARTICLE_SECTION_HEADER}    ${section_id}
    Open Article WebView
    Click Element    ${locator}
    app.Return To Native Context


Get Article Section Height
    [Documentation]    Rendered height of the section body — 0 while collapsed. JS, since the library's visibility check misreports in WebView.
    [Arguments]    ${section_id}
    ${element_id}=    Format String    ${ARTICLE_SECTION_CONTENT_ID}    ${section_id}
    Open Article WebView
    ${height}=    Execute Script    script=var e=document.getElementById('${element_id}'); return e ? e.offsetHeight : -1;
    app.Return To Native Context
    RETURN    ${height}

Scroll To End Of Article Section
    [Documentation]    Scrolls until the section's bottom edge is in view. JS, since WebDriver has no scrollIntoView.
    [Arguments]    ${section_id}
    ${element_id}=    Format String    ${ARTICLE_SECTION_CONTENT_ID}    ${section_id}
    Open Article WebView
    Execute Script    script=document.getElementById('${element_id}').scrollIntoView(false); return true;
    app.Return To Native Context

Get Article Scroll Position
    [Documentation]    Returns the page scroll offset in pixels. JS, since WebDriver has no page-scroll concept.
    Open Article WebView
    ${position}=    Execute Script    script=return Math.round(window.scrollY);
    app.Return To Native Context
    RETURN    ${position}

Verify Bottom Nav Tab Is Selected
    [Documentation]    Reads the selected attribute — every tab is always on screen, so presence proves nothing.
    [Arguments]    ${tab_locator}
    ${selected}=    Get Element Attribute    ${tab_locator}    selected
    Should Be Equal    ${selected}    true

Open Save Context Menu
    [Documentation]    Taps Save on a SAVED article and waits for the context menu.
    ...    The tap and the wait are retried as a pair: opening an article from the
    ...    Saved list is slower than from search, so the Save button can be drawn
    ...    before it is bound and the first tap does nothing at all - no menu and
    ...    no snackbar, which is what makes the failure so hard to read.
    ...    Retrying the tap is safe because the control is state-aware: on a saved
    ...    article it can only ever open this menu, never save a second time.
    Wait Until Keyword Succeeds    15s    2s    Tap Save And Wait For Menu

Tap Save And Wait For Menu
    [Documentation]    One attempt at opening the Save context menu.
    Wait Until Page Contains Element    ${SAVE_ARTICLE_BUTTON}
    Click Element                       ${SAVE_ARTICLE_BUTTON}
    Wait Until Page Contains Element    ${REMOVE_FROM_LIST_BUTTON}    timeout=5s
