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
Arabic Article Content Renders In Arabic Script
    [Documentation]      [Documentation]     Opens an Arabic article and asserts its first paragraph matches
    ...                 the AR API extract. The claim is the WebView content path under
    ...                 Arabic — that the script survives rendering and the oracle is
    ...                 bound to ar.wikipedia. Search is transport to the article here,
    ...                 not the thing being tested; test 1 owns that claim.
    [Tags]      article    oracle-api    localization
    [Setup]     app.Restart App Process
    search_actions.Navigate To Search Page
    search_actions.Search For Article    ${ARABIC_BAGHDAD_ARTICLE_NAME}
    search_actions.Open Searched Article    ${ARABIC_BAGHDAD_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    article_actions.Verify Article Page Loaded    ${ARABIC_BAGHDAD_ARTICLE_TITLE}
    article_actions.Verify UI Paragraph Matches API Paragraph    ${ARABIC_BAGHDAD_ARTICLE_NAME}
    [Teardown]    Run Keyword And Ignore Error    app.Return To Native Context

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

Arabic Interface Mirrors Layout Right To Left
    [Documentation]     Translation and mirroring are separate things — an app can
    ...                 translate every string and still lay the screen out left to right.
    ...                 The first line is the premise, the second is the claim.
    [Tags]      feed    localization    rtl
    [Setup]     app.Restart App Process
    feed_actions.Verify Bottom Navigation Is Translated
    feed_actions.Verify Bottom Navigation Is Mirrored

English Article Under Arabic Interface Keeps LTR Content Direction
    [Documentation]     Content direction follows the ARTICLE's language, not the
    ...                 interface's. An English article inside a mirrored Arabic app
    ...                 stays left to right — correct behavior, locked as a passing test
    ...                 rather than filed as a defect.
    ...                 Reached by deep link because in-app search is bound to the app's
    ...                 language and can only return Arabic results under this locale.
    [Tags]              article     localization
    [Setup]             app.Restart App Process
    app.Open Deep Link    ${ENGLISH_HIST1H1B_ARTICLE_URL}
    article_actions.Dismiss Games Promo If Present
    article_actions.Verify Article Page Loaded    ${HIST1H1B_ARTICLE_TITLE}
    article_actions.Verify Article Content Direction    ltr
    [Teardown]          Run Keyword And Ignore Error    app.Return To Native Context

