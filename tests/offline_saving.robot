*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Resource        ../resources/oracles/db_oracle.resource
Suite Setup    Run Keywords    app.Start Session
Suite Teardown          Close Application

*** Test Cases ***

Saving An Article Offline Persists A Correct Row
    [Documentation]     The database is the oracle. The "saved" snackbar only
    ...    proves the app acknowledged the tap - it says nothing about a row
    ...    reaching disk or any content being downloaded.
    ...    Searching and opening the article are the vehicle, not the claim, so
    ...    they carry sync waits but no business assertions.
    [Tags]      offline     oracle-db
    [Setup]     Run Keywords        search_actions.Reset To Search Page
    ...         AND                 db_oracle.Verify Article Is Not Saved    ${HIST1H1B_ARTICLE_NAME}
    search_actions.Dismiss Faster Way To Search Tip
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article        ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article        ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    article_actions.Verify Snackbar Says             ${SAVED_SNACKBAR_TEXT}
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}
    [Teardown]      article_actions.Remove Article From List