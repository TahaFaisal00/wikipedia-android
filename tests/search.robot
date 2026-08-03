*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Suite Setup    Run Keywords    app.Start Session
...            AND    search_actions.Navigate To Search Page
...            AND    search_actions.Dismiss Faster Way To Search Tip If Present
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
    [Setup]     search_actions.Reset To Search Page
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
    [Setup]     search_actions.Reset To Search Page
    search_actions.Search For Article                   ${HIST1_ARTICLE_PREFIX_NAME}
    ${api_first_result}=    search_actions.Get Expected First Result            ${HIST1_ARTICLE_PREFIX_NAME}
    search_actions.Verify Search List Shows Article      ${api_first_result}

Search Results Update When The Query Changes
    [Documentation]     Runs one query, then replaces it with a different one and
    ...                confirms the results list follows the new query instead of
    ...                showing stale results from the previous one. Both states are
    ...                verified against the prefixsearch API oracle.
    [Tags]              search      oracle-api
    [Setup]     search_actions.Reset To Search Page
    search_actions.Search For Article                   ${HIST1_ARTICLE_PREFIX_NAME}
    ${api_first_result}=    search_actions.Get Expected First Result            ${HIST1_ARTICLE_PREFIX_NAME}
    search_actions.Verify Search List Shows Article      ${api_first_result}
    search_actions.Use Search Bar       ${HIST1H1B_ARTICLE_NAME}
    ${api_first_result}=    search_actions.Get Expected First Result            ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article      ${api_first_result}

Search With No Matches Shows The Empty State
    [Documentation]     Searches a term with no matches and confirms the search
    ...                screen shows its empty state, with the prefixsearch oracle
    ...                verifying that zero results is the server's actual answer
    ...                and not a failure to render results that were returned.
    [Tags]              search      oracle-api
    [Setup]      search_actions.Reset To Search Page
    search_actions.Search For Article                   ${NON_EXISTENT_ARTICLE}
    search_actions.Verify Server Returns No Suggestions        ${NON_EXISTENT_ARTICLE}
    search_actions.Verify Search List Shows No Article

Clearing The Search Field Restores The Recent Searches View
    [Documentation]     Searches an article, then clears the field with the clear
    ...                button and confirms the screen returns to the recent
    ...                searches view with the searched term recorded in it.
    [Tags]      search          oracle-ui
    [Setup]      search_actions.Reset To Search Page
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Clear Search Field
    search_actions.Verify Recent Searches Shows Article       ${HIST1H1B_ARTICLE_NAME}


