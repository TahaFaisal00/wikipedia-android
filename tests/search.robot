*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Suite Setup         Run Keywords        Open Wikipedia      AND          Open Session       ${WIKI_EN}
Suite Teardown          Close Application

*** Test Cases ***
Search Returns The Requested Article
    [Documentation]     Search for an article by its exact name, open it from the results,
    ...                and check the article body matches what the API returns.
    ...                Steps: type the exact title, confirm that result shows up, tap the
    ...                first row to open it, close the games promo if it pops up, then read
    ...                the article's first paragraph from the WebView.
    ...                The check: the UI paragraph has to be inside the API intro text. UI
    ...                acts, API observes. We strip the [1][2] refs off the UI side first so
    ...                the two compare clean.
    ...                Note: clicking the first row is safe here because exact-name search
    ...                puts the article on top — that's a different endpoint from prefix search.
    [Tags]      search          oracle-api
    [Setup]     app.Skip Tutorial
    search_actions.Navigate To Search Page
    search_actions.Dismiss Faster Way To Search Tip
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article        ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article        ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    article_actions.Verify Article Page Loaded    ${HIST1H1B_ARTICLE_TITLE}
    article_actions.Verify UI Paragraph Matches API Paragraph        ${HIST1H1B_ARTICLE_NAME}
    [Teardown]        Run Keyword And Ignore Error         app.Return To Native Context

Search Results Match What The Server Returned
    [Documentation]     Type a prefix, ask the API for its top result, and check that
    ...                same result shows up in the search list on screen.
    ...                UI acts, API observes.
    [Tags]              search      oracle-api
    [Setup]     app.Skip Tutorial
    search_actions.Navigate To Search Page
    search_actions.Dismiss Faster Way To Search Tip
    search_actions.Search For Article                   ${HIST1_ARTICLE_PREFIX_NAME}
    ${api_first_result}=    search_actions.Get Expected First Result            ${HIST1_ARTICLE_PREFIX_NAME}
    search_actions.Verify Search List Shows Article      ${api_first_result}







