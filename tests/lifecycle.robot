*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Resource        ../resources/network.resource
Resource        ../resources/device.resource
Suite Setup    Run Keywords    app.Start Session
...            AND    search_actions.Navigate To Search Page
...            AND    search_actions.Dismiss Faster Way To Search Tip If Present
Suite Teardown          Close Application
Library             AppiumLibrary

*** Test Cases ***

Article Survives Backgrounding And Returning
    [Documentation]    Control case for the process-death tests —
    ...                plain background/resume must not lose the article.
    [Tags]      lifescycle     oracle-ui
    [Setup]     search_actions.Reset To Search Page
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article       ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article        ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article        ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    app.Background App And Return    ${5}
    article_actions.Verify Article Title Is   ${HIST1H1B_ARTICLE_TITLE}     ${HIST1H1B_ARTICLE_NAME}

Article Survives Process Death
    [Documentation]    Paired with the backgrounding control — same steps, real process death.
    ...    The article itself is restored; section and scroll state are not (see test 3).
    [Tags]    lifecycle    oracle-ui
    [Setup]    search_actions.Reset To Search Page
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article    ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article    ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article    ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    app.Kill App Process
    article_actions.Verify Article Title Is   ${HIST1H1B_ARTICLE_TITLE}     ${HIST1H1B_ARTICLE_NAME}

Expanded Section And Reading Position Are Lost After Recreation
    [Documentation]    Bug — a RED here means it was fixed.
    ...    One defect, two manifestations: the section collapses, and the anchor inside it takes the scroll position with it.
    [Tags]    lifecycle    oracle-ui    bug
    [Setup]    search_actions.Reset To Search Page
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article    ${HIST1H1B_ARTICLE_NAME}
    search_actions.Open Searched Article    ${HIST1H1B_ARTICLE_NAME}
    article_actions.Dismiss Games Promo If Present
    article_actions.Expand Article Section    ${REFERENCES_SECTION_ID}
    ${height_before}=    article_actions.Get Article Section Height    ${REFERENCES_SECTION_ID}
    Should Be True    ${height_before} > 0
    article_actions.Scroll To End Of Article Section    ${REFERENCES_SECTION_ID}
    ${position_before}=    article_actions.Get Article Scroll Position
    Should Be True    ${position_before} > 0
    app.Kill App Process
    ${height_after}=    article_actions.Get Article Section Height    ${REFERENCES_SECTION_ID}
    Should Be Equal As Integers    ${height_after}    0
    ${position_after}=    article_actions.Get Article Scroll Position
    Should Be Equal As Integers    ${position_after}    0
    [Teardown]    Run Keyword And Ignore Error    app.Return To Native Context

Search Results Are Refetched Instead Of Restored After Recreation
    [Documentation]    Bug — a RED here means it was fixed. See BUGS.md #2.
    ...    Results are re-queried on activity recreation instead of restored, so with the network down they vanish.
    [Tags]    lifecycle    oracle-ui    bug
    [Setup]    Run Keywords    device.Enable Do Not Keep Activities
    ...    AND                 search_actions.Reset To Search Page
    search_actions.Dismiss Faster Way To Search Tip If Present
    search_actions.Search For Article    ${HIST1H1B_ARTICLE_NAME}
    search_actions.Verify Search List Shows Article    ${HIST1H1B_ARTICLE_NAME}
    network.Disable Network
    app.Background App And Return    ${5}
    search_actions.Verify Search List Does Not Show Article    ${HIST1H1B_ARTICLE_NAME}
    [Teardown]    Run Keywords    network.Enable Network
    ...    AND    device.Disable Do Not Keep Activities

Selected Bottom Nav Tab Survives Process Death
    [Documentation]    Regression guard — the selected tab is restored, unlike section and scroll state.
    [Tags]    lifecycle    oracle-ui
    [Setup]    search_actions.Reset To Search Page
    search_actions.Navigate To Saved Page
    article_actions.Verify Bottom Nav Tab Is Selected    ${SAVED_BAR}
    app.Kill App Process
    article_actions.Verify Bottom Nav Tab Is Selected    ${SAVED_BAR}