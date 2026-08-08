*** Settings ***
Library          AppiumLibrary
Library          String
Library          Collections
Resource         ../pages/search_page.resource
Resource         oracles/api_oracle.resource
Resource         app.resource
*** Keywords ***
Reset To Search Page
    [Documentation]    Test Setup. Puts the test on the search page from an unknown
    ...                starting screen. Restarts the process rather than pressing back,
    ...                because a test that ends inside a WebView, a dialog, or a dead
    ...                network state can't be walked back reliably.
    app.Restart App Process
    Navigate To Search Page

Navigate To Search Page
    [Documentation]     Tap the search bar to open the search screen.
    Wait Until Page Contains Element    ${SEARCH_BAR}
    Click Element    ${SEARCH_BAR}

Dismiss Faster Way To Search Tip If Present
    [Documentation]    Closes the "faster way to search" tip if it is showing.
    ...    The tip is one-shot session state: it appears once and never again,
    ...    so a hard wait would fail on every test after the first.
    ...    Uses Page Should Contain Element rather than a Wait, so an absent tip
    ...    costs no timeout.
    ${present}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${FASTER_WAY_TO_SEARCH_WINDOW_CLOSE_BUTTON}
    IF    ${present}
        Click Element    ${FASTER_WAY_TO_SEARCH_WINDOW_CLOSE_BUTTON}
    END

Search For Article
    [Documentation]     Tap the search field and type the article name.
    [Arguments]     ${article_name}
    Wait Until Page Contains Element    ${SEARCH_PLACEHOLDER}
    Click Element    ${SEARCH_PLACEHOLDER}
    Use Search Bar    ${article_name}

Use Search Bar
    [Arguments]     ${article_name}
    Wait Until Page Contains Element        ${SEARCH_FIELD}
    Input Text    ${SEARCH_FIELD}    ${article_name}

Open Searched Article
    [Documentation]     Check the article is in the results, then open it.
    [Arguments]     ${article_name}
    Wait Until Page Contains Element    ${FIRST_RESULT_ARTICLE}
    Click Element    ${FIRST_RESULT_ARTICLE}

Get Expected First Result
    [Documentation]     Get the top title the API returns for the prefix.
    [Arguments]     ${article_name}
    @{api_titles}=       Get Expected Search Titles    ${article_name}
    ${api_first_result}=     Get From List    ${api_titles}    0
    RETURN        ${api_first_result}

Verify Server Returns No Suggestions
    [Documentation]    Asserts the prefixsearch API returns no suggestions for
    ...                the given term, confirming an empty UI is correct and not
    ...                a client-side failure to render results.
    [Arguments]    ${article_name}
    ${titles}=    api_oracle.Get Expected Search Titles    ${article_name}
    Should Be Empty    ${titles}

Verify Search List Shows Article
    [Documentation]     Check the article title is in the search results on screen.
    [Arguments]             ${article_name}
    ${search_result_article_title}=       Format String    ${SEARCH_RESULT_ARTICLE_TITLE}         ${article_name}
    Page Should Contain Element    ${search_result_article_title}

Verify Search List Shows No Article
    [Documentation]     Asserts the search screen shows the no-results message.
    ...                The app renders one such message per configured search
    ...                language, all with identical text, so this matches any.
    Wait Until Page Contains Element    ${NO_RESULTS_MESSAGE}

Verify Search List Does Not Show Article
    [Documentation]    Asserts the article is absent from the results list.
    ...    Deliberately does not assert which screen replaced it — the empty state,
    ...    an error screen, and a blank list all satisfy the claim.
    [Arguments]    ${article_name}
    ${locator}=    Format String    ${SEARCH_RESULT_ARTICLE_TITLE}    ${article_name}
    Page Should Not Contain Element    ${locator}

Clear Search Field
    [Documentation]    Taps the clear button to empty the search field.
    Wait Until Page Contains Element    ${CLEAR_QUERY_BUTTON}
    Click Element    ${CLEAR_QUERY_BUTTON}

Verify Recent Searches Shows Article
    [Documentation]    Asserts the recent searches view is displayed and lists
    ...                the given article as a previously searched term.
    [Arguments]             ${article_name}
    Wait Until Page Contains Element    ${RECENT_SEARCHES_HEADER}
    ${recent_searched_article_title}=       Format String    ${SEARCH_RESULT_ARTICLE_TITLE}          ${article_name}
    Wait Until Page Contains Element    ${recent_searched_article_title}

Navigate From Search Page To Saved Page
    [Documentation]    Moves to the Saved screen via the bottom navigation bar.
    Wait Until Page Contains Element    ${SAVED_BAR}
    Click Element                       ${SAVED_BAR}
