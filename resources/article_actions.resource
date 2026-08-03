*** Settings ***
Library         AppiumLibrary
Library          String
Resource        ../pages/article_page.resource
Resource        oracles/api_oracle.resource
Resource        reading_list_actions.resource

*** Keywords ***
Normalize Article Text
    [Documentation]    Kill the [1][2] markers and squash whitespace so UI and API compare clean.
    [Arguments]    ${text}
    ${text}=    Replace String Using Regexp    ${text}    \\[\\d+\\]    ${EMPTY}
    ${text}=    Replace String Using Regexp    ${text}    \\s+    ${SPACE}
    ${text}=    Strip String    ${text}
    RETURN    ${text}

Read Article Body Text
    [Documentation]     Switch to WebView, read the first paragraph, clean out the
    ...                [1] refs and extra spaces, switch back to Native.
    Switch To Context    WEBVIEW_org.wikipedia.alpha
    ${raw_body}=        Get Text    ${ARTICLE_BODY_TEXT_LOCATOR}
    ${clean_body}=      Normalize Article Text      ${raw_body}
    Switch To Context    NATIVE_APP
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
    Switch To Context    WEBVIEW_org.wikipedia.alpha
    ${direction}=    Execute Script
    ...    return getComputedStyle(document.querySelector('p')).direction
    Should Be Equal    ${direction}    ${expected}
    Switch To Context    NATIVE_APP

Save Article
    [Documentation]     Taps Save on an UNSAVED article.
    ...    The Save control is state dependent: on an already-saved article the
    ...    same tap opens a context menu instead. The caller must guarantee the
    ...    unsaved starting state, because this keyword does not check it.
    Wait Until Page Contains Element    ${SAVE_ARTICLE_BUTTON}
    Click Element                       ${SAVE_ARTICLE_BUTTON}

Verify Snackbar Says
    [Documentation]     Asserts the snackbar carries the expected message.
    ...    Save, move and remove all use the same snackbar id, so waiting for the
    ...    element alone would pass for any of them. The text is the only
    ...    discriminator. Also acts as the sync gate before a DB snapshot.
    [Arguments]    ${expected_text}
    Wait Until Page Contains Element    ${SNACKBAR_TEXT}
    Element Should Contain Text         ${SNACKBAR_TEXT}    ${expected_text}
    
Remove Article From List
    [Documentation]     Un-saves an article that is currently SAVED.
    ...    Un-saving is not a second tap on Save: that tap opens a context menu
    ...    and the removal lives inside it. Used as teardown so the next test
    ...    starts unsaved.
    Wait Until Page Contains Element    ${SAVE_ARTICLE_BUTTON}
    Click Element                       ${SAVE_ARTICLE_BUTTON}
    Wait Until Page Contains Element    ${REMOVE_FROM_LIST_BUTTON}
    Click Element                       ${REMOVE_FROM_LIST_BUTTON}
    Verify Snackbar Says                ${REMOVED_SNACKBAR_TEXT}

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


