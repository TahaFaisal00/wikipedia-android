*** Settings ***
Library         AppiumLibrary
Library          String
Resource        ../pages/article_page.resource
Resource        ../resources/oracles/api_oracle.resource

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

