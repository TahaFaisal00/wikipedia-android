*** Settings ***
Resource        ../resources/app.resource
Resource      ../resources/article_actions.resource
Resource        ../resources/search_actions.resource
Suite Setup    Run Keywords    app.Start Session
...            AND    search_actions.Navigate To Search Page
...            AND    search_actions.Dismiss Faster Way To Search Tip If Present
Suite Teardown          Close Application

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