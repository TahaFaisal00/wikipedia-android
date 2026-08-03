*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Resource        ../resources/oracles/db_oracle.resource
Resource        ../resources/oracles/api_oracle.resource
Resource        ../resources/network.resource
Resource        ../resources/reading_list_actions.resource
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
    ...         AND                 db_oracle.Wait Until Article Is Not Saved   ${HIST1H1B_ARTICLE_NAME}
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article        ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article        ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    article_actions.Verify Snackbar Says             ${SAVED_SNACKBAR_TEXT}
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}
    [Teardown]      article_actions.Remove Article From List

Removing A Saved Article Deletes Its Row
    [Documentation]     Covers the second branch of the state-dependent Save
    ...    button: on a saved article the tap opens a context menu instead of
    ...    toggling, and the removal lives inside it.
    ...    Saving here is setup, not the claim - test 1 already proves it. The
    ...    claim is that removal leaves no row behind, so the DB is the oracle.
    ...    The snackbar only proves the app acknowledged the tap.
    [Tags]      offline     oracle-db
    [Setup]     Run Keywords        search_actions.Reset To Search Page
    ...         AND                 db_oracle.Wait Until Article Is Not Saved    ${HIST1H1B_ARTICLE_NAME}
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article        ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article        ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    article_actions.Verify Snackbar Says             ${SAVED_SNACKBAR_TEXT}
    article_actions.Remove Article From List
    db_oracle.Wait Until Article Is Not Saved    ${HIST1H1B_ARTICLE_NAME}
    [Teardown]    Run Keyword And Ignore Error
    ...           article_actions.Remove Article From List

Saved Article Is Readable With The Network Off
    [Documentation]    The feature's actual promise: a saved article opens and
    ...    renders with no connectivity.
    ...    The expected text is fetched from the API while still online, because
    ...    the oracle is unreachable once the network is down. Comparing against
    ...    it afterwards proves the body came from disk - nothing could have
    ...    fetched it.
    ...    The body is asserted, not the title: the title is stored as metadata
    ...    in the database and renders even when no content was downloaded.
    ...    The download must finish before the network drops, so the row check
    ...    is a gate here rather than an assertion.
    [Tags]      offline    oracle-db    oracle-api
    [Setup]     Run Keywords        search_actions.Reset To Search Page
    ...         AND                 db_oracle.Wait Until Article Is Not Saved     ${HIST1H1B_ARTICLE_NAME}
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article                ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article             ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    article_actions.Verify Snackbar Says             ${SAVED_SNACKBAR_TEXT}
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}
    ${expected}=     api_oracle.Get Expected Article Extract        ${HIST1H1B_ARTICLE_NAME}
    article_actions.Navigate Back To Search Page
    network.Disable Network
    search_actions.Navigate From Search Page To Saved Page
    reading_list_actions.Open Default Saved List
    reading_list_actions.Open Saved Article          ${HIST1H1B_ARTICLE_NAME}
    article_actions.Verify UI Paragraph Matches Extract   ${expected}
    [Teardown]    Run Keywords
    ...           network.Enable Network
    ...           AND    Run Keyword And Ignore Error    article_actions.Remove Article From List





