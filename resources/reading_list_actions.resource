*** Settings ***
Library          AppiumLibrary
Library          String
Library          Collections
Resource         ../pages/search_page.resource
Resource         oracles/api_oracle.resource
Resource         app.resource
Resource        ../pages/reading_list_page.resource
*** Keywords ***
Dismiss Sync Reading Lists Prompt If Present
    [Documentation]    Declines the "sync your reading lists" prompt if it shows.
    ...    The prompt appears unpredictably - on entering Saved and on returning
    ...    to search - so it cannot be handled at a fixed point in a test.
    ...    Declines rather than accepts: syncing would need an account and would
    ...    put the reading list under server control instead of the app's.
    ${present}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${SYNC_READING_LIST_ALERT}
    IF    ${present}
        Click Element    ${NO_THANKS_BUTTON}
    END

Open Default Saved List
    [Documentation]    Opens the default list from the Saved screen.
    ...    Dismisses the sync prompt first: it renders over the list and would
    ...    swallow the tap.
    Dismiss Sync Reading Lists Prompt If Present
    Wait Until Page Contains Element    ${DEFAULT_SAVE_LIST}
    Click Element                       ${DEFAULT_SAVE_LIST}
    Dismiss Share With Others Tip If Present

Dismiss Share With Others Tip If Present
    [Documentation]    Closes the reading-list sharing tip if it shows.
    ...    One-shot onboarding state, same shape as the other promo dismissals.
    ${present}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${SHARE_WITH_OTHER_GOT_IT_BUTTON}
    IF    ${present}
        Click Element    ${SHARE_WITH_OTHER_GOT_IT_BUTTON}
    END

Open Saved Article
    [Documentation]    Opens an article from inside a reading list, by title.
    ...    Matches on the title rather than list position, so it keeps working
    ...    once a list holds more than one article.
    [Arguments]    ${title}
    ${locator}=    Format String    ${THE_ONLY_SAVED_ARTICLE_IN_DEFAULT_LIST}    ${title}
    Wait Until Page Contains Element    ${locator}
    Click Element                       ${locator}

Verify Saved Article Is Listed
    [Documentation]    Asserts the article appears in the open reading list.
    ...    Matches the row by id and checks the title as text. A text-based
    ...    selector is not usable here - the title does not appear in the tree
    ...    until the list holds more than one article.
    ...    Because the id is not unique once a second article is added, this
    ...    keyword is only valid for a single-article list.
    [Arguments]    ${title}
    Wait Until Page Contains Element    ${THE_ONLY_SAVED_ARTICLE_IN_DEFAULT_LIST}
    Element Should Contain Text         ${THE_ONLY_SAVED_ARTICLE_IN_DEFAULT_LIST}    ${title}









