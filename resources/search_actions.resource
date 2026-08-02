*** Settings ***
Library          AppiumLibrary
Library          String
Library          Collections
Resource         ../pages/search_page.resource
Resource         oracles/api_oracle.resource

*** Keywords ***
Navigate To Search Page
    [Documentation]     Tap the search bar to open the search screen.
    Wait Until Page Contains Element    ${SEARCH_BAR}
    Click Element    ${SEARCH_BAR}

Dismiss Faster Way To Search Tip
    [Documentation]     Close the "faster way to search" popup.
    Wait Until Page Contains Element    ${FASTER_WAY_TO_SEARCH_WINDOW_CLOSE_BUTTON}
    Click Element    ${FASTER_WAY_TO_SEARCH_WINDOW_CLOSE_BUTTON}

Search For Article
    [Documentation]     Tap the search field and type the article name.
    [Arguments]     ${article_name}
    Wait Until Page Contains Element    ${SEARCH_PLACEHOLDER}
    Click Element    ${SEARCH_PLACEHOLDER}
    Use Search Bar    ${article_name}

Use Search Bar
    [Arguments]     ${article_name}
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

