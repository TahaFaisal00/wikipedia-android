*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Resource        ../resources/feed_actions.resource

Suite Setup            Run Keywords      app.Start Session     ar  EG  ${WIKI_AR}
...            AND     app.Verify Device Locale Is Arabic
...            AND     search_actions.Navigate To Search Page
...            AND     search_actions.Dismiss Faster Way To Search Tip
Suite Teardown          Close Application

*** Test Cases ***
Arabic Search Reaches The Server Intact
    [Documentation]     Types an Arabic term into the search bar and asserts the
    ...                 article the AR prefixsearch API returns as top hit appears
    ...                 in the results list. Proves Arabic input reaches the server
    ...                 and comes back rendered without encoding damage.
    [Tags]              search      oracle-api
    [Setup]     search_actions.Reset To Search Page
    search_actions.Search For Article                   ${ARABIC_BAGHDAD_ARTICLE_NAME}
    ${api_first_result}=    search_actions.Get Expected First Result            ${ARABIC_BAGHDAD_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article      ${api_first_result}

Feed Filter Tabs Stay In English Under An Arabic Interface
    [Documentation]     BUG. Under an Arabic device locale the bottom navigation
    ...                 translates but the feed filter tabs stay English, because their
    ...                 strings are hardcoded rather than pulled from resources. The two
    ...                 checks together are the evidence: same screen, same locale, one
    ...                 translated and one not.
    [Tags]          bug    feed    localization
    [Setup]         app.Restart App Process
    feed_actions.Verify Bottom Navigation Is Translated
    feed_actions.Verify Feed Filter Tabs Are Untranslated





