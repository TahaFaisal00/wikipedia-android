*** Settings ***
Library         AppiumLibrary
Library          String
Resource        ../pages/search_page.resource

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
    Input Text    ${SEARCH_FIELD}    ${article_name}

Open Searched Article
    [Documentation]     Check the article is in the results, then open it.
    [Arguments]     ${article_name}
    ${search_result_article_title}=       Format String    ${SEARCH_RESULT_ARTICLE_TITLE}         ${article_name}
    Wait Until Page Contains Element    ${search_result_article_title}
    Click Element    ${FIRST_RESULT_ARTICLE}



