*** Settings ***
Library          AppiumLibrary
Library          String
Library          Collections
Resource         ../pages/search_page.resource
Resource         oracles/api_oracle.resource
Resource         app.resource
Resource        ../pages/reading_list_page.resource
Resource        oracles/db_oracle.resource
Resource        article_actions.resource
Resource        search_actions.resource
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

Long Press Element
    [Documentation]    Long-presses an element. AppiumLibrary only ships a
    ...    keycode long-press, so this drops to the UiAutomator2 gesture.
    [Arguments]    ${locator}    ${duration}=1000
    ${el}=    Get Webelement    ${locator}
    Execute Script    mobile: longClickGesture
    ...    elementId=${el.id}    duration=${duration}

Verify Article Is In Reading List
    [Documentation]    Asserts the article was persisted into a named list while
    ...    remaining in the default one.
    ...    List membership is many-to-many: adding to another list writes a
    ...    second ReadingListPage row rather than moving the existing one. So the
    ...    claim is two rows for one article, one per list, not a single row with
    ...    a changed listId.
    ...    Checking only that the list exists would pass while the article sat in
    ...    the default list alone, which is the bug worth catching.
    ...    Column order - lists: 0 listTitle, 1 id. Pages: 0 apiTitle, 1 offline,
    ...    2 status, 3 sizeBytes, 4 listId.
    [Arguments]    ${api_title}    ${list_title}
    ${lists}=    db_oracle.Get Reading List Rows    ${list_title}
    Length Should Be    ${lists}    1
    ${list_id}=    Set Variable    ${lists}[0][1]
    Should Not Be Equal As Integers    ${list_id}    ${DEFAULT_LIST_ID}
    ...    msg=The named list resolved to the default list
    ${rows}=    db_oracle.Get Saved Article Rows    ${api_title}
    Length Should Be    ${rows}    2
    ${list_ids}=    Evaluate    sorted(r[4] for r in $rows)
    Should Be Equal    ${list_ids}    ${{ sorted([int($DEFAULT_LIST_ID), int($list_id)]) }}

Delete Reading List
    [Documentation]    Deletes a named reading list from the Saved screen.
    ...    Deleting the list removes its ReadingListPage rows with it, so this
    ...    also clears the article's membership in that list. The default list
    ...    is unaffected.
    ...    Only works for user-created lists: the default list has no delete
    ...    option and no usable locator.
    [Arguments]    ${list_name}
    ${locator}=    Set Variable    android=new UiSelector().text("${list_name}")
    Wait Until Page Contains Element    ${locator}
    Long Press Element                          ${locator}
    Wait Until Page Contains Element    ${DELETE_LIST_MENU_ITEM}
    Click Element                       ${DELETE_LIST_MENU_ITEM}
    Wait Until Page Contains Element    ${CONFIRM_DIALOG_OK}
    Click Element                       ${CONFIRM_DIALOG_OK}
    Verify Snackbar Says                ${list_name}

Ensure Reading List Does Not Exist
    [Documentation]    Setup helper. Deletes a named list if a previous run left
    ...    one behind.
    ...    Setup makes the starting state true rather than only checking it,
    ...    otherwise one failed run blocks every run after it.
    ...    Must run from the Saved screen.
    [Arguments]    ${list_name}
    ${rows}=    db_oracle.Get Reading List Rows    ${list_name}
    IF    len($rows) > 0
        Delete Reading List    ${list_name}
    END

Clean Up Saved State
    [Documentation]    Teardown helper. Leaves no custom list and no saved
    ...    article behind, from wherever the test ended.
    ...    Order matters: deleting the custom list first drops the article to a
    ...    single list, so the Save context menu falls back to the simple
    ...    "remove from saved" branch instead of the multi-list checkbox dialog.
    ...    That dialog's shape depends on how many lists the article is in, which
    ...    is unpredictable after a failure.
    ...    Each step is guarded against the state already being clean, since a
    ...    teardown also runs on the unhappy path.
    [Arguments]    ${api_title}    ${list_name}
    Run Keyword And Ignore Error    article_actions.Navigate Back To Search Page
    search_actions.Navigate From Search Page To Saved Page
    Ensure Reading List Does Not Exist    ${list_name}
    ${rows}=    db_oracle.Get Saved Article Rows    ${api_title}
    IF    len($rows) > 0
        Open Default Saved List
        Open Saved Article    ${api_title}
        article_actions.Remove Article From List
    END







