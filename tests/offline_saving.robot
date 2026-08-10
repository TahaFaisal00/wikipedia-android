*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Resource        ../resources/oracles/db_oracle.resource
Resource        ../resources/oracles/api_oracle.resource
Resource        ../resources/network.resource
Resource        ../resources/reading_list_actions.resource
Resource        ../resources/device.resource
Suite Setup    Run Keywords      app.Start Session      AND      app.Ensure Adb Root
#...            AND            device.Set App Language    en
Suite Teardown          Close Application
Test Setup       Run Keywords
...              reading_list_actions.Ensure Clean Saved State    ${HIST1H1B_ARTICLE_NAME}    ${CUSTOM_LIST_NAME}
...              AND    search_actions.Reset To Search Page
Test Teardown    reading_list_actions.Ensure Clean Saved State    ${HIST1H1B_ARTICLE_NAME}    ${CUSTOM_LIST_NAME}

*** Test Cases ***

Saving Article Offline Persists Correct Row
    [Documentation]     The database is the oracle. The "saved" snackbar only
    ...    proves the app acknowledged the tap - it says nothing about a row
    ...    reaching disk or any content being downloaded.
    ...    Searching and opening the article are the vehicle, not the claim, so
    ...    they carry sync waits but no business assertions.
    [Tags]      offline     oracle-db       positive
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article        ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open First Search Result
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    article_actions.Verify Snackbar Says             ${SAVED_SNACKBAR_TEXT}
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}

Removing Saved Article Deletes Its Row
    [Documentation]     Covers the second branch of the state-dependent Save
    ...    button: on a saved article the tap opens a context menu instead of
    ...    toggling, and the removal lives inside it.
    ...    Saving here is setup, not the claim - test 1 already proves it. The
    ...    claim is that removal leaves no row behind, so the DB is the oracle.
    ...    The snackbar only proves the app acknowledged the tap.
    [Tags]      offline     oracle-db       positive
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article        ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open First Search Result
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    article_actions.Verify Snackbar Says             ${SAVED_SNACKBAR_TEXT}
    article_actions.Remove Article From List
    db_oracle.Wait Until Article Is Not Saved    ${HIST1H1B_ARTICLE_NAME}

Saved Article Is Readable With Network Off
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
    [Tags]      offline    oracle-db    oracle-api      positive
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article                ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open First Search Result
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}
    ${expected}=     api_oracle.Get Expected Article Extract        ${HIST1H1B_ARTICLE_NAME}
    article_actions.Navigate Back To Search Page
    network.Disable Network
    search_actions.Navigate To Saved Page
    reading_list_actions.Open Default Saved List
    reading_list_actions.Open Saved Article          ${HIST1H1B_ARTICLE_NAME}
    article_actions.Verify UI Paragraph Matches Extract   ${expected}

Saved Articles Survive App Restart
    [Documentation]    Durability. A save must outlive the process that made it.
    ...    Two separate claims, both needed: the row is still on disk, and the
    ...    app still surfaces it in the Saved list. A row nobody can reach is
    ...    not a working save, and a list entry with no row would be a stale view.
    ...    The app is killed with force-stop, so it gets no chance to flush on
    ...    shutdown - anything that survives was already persisted.
    [Tags]      offline    oracle-db        positive
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article                ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open First Search Result
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}
    app.Restart App Cold
    search_actions.Navigate To Saved Page
    reading_list_actions.Open Default Saved List
    reading_list_actions.Verify Saved Article Is Listed    ${HIST1H1B_ARTICLE_NAME}
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}

Adding Saved Article To New Reading List Persists List
    [Documentation]    Covers the third Save context-menu branch and a second
    ...    table.
    ...    List membership is many-to-many: adding to another list writes a
    ...    second ReadingListPage row rather than moving the existing one, so the
    ...    article ends up in both lists at once.
    ...    The claim spans two tables - the named list exists, and the article
    ...    has a row pointing at it. Checking only that the list was created
    ...    would pass while the article stayed in the default list alone.
    [Tags]      offline    oracle-db        positive
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article                ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open First Search Result
    article_actions.Dismiss Games Promo If Present
    article_actions.Save Article
    db_oracle.Wait Until Saved Article Row Is Correct    ${HIST1H1B_ARTICLE_NAME}
    article_actions.Add Article To New Reading List    ${CUSTOM_LIST_NAME}
    Wait Until Keyword Succeeds    30s    2s
    ...    reading_list_actions.Verify Article Is In Reading List
    ...    ${HIST1H1B_ARTICLE_NAME}    ${CUSTOM_LIST_NAME}
