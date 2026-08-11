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
Resource        network.resource
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
    ...    Waits rather than checking instantly: the balloon renders after the
    ...    list does, and an instant check reports absent and leaves it up.
    ...    It matters more than the other one-shot tips because it opens in its
    ...    own window - while it is up the accessibility tree contains only the
    ...    balloon, so every locator behind it fails as "not found".
    ${present}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    ${SHARE_WITH_OTHER_GOT_IT_BUTTON}    timeout=3s
    IF    ${present}
        Click Element                            ${SHARE_WITH_OTHER_GOT_IT_BUTTON}
        Wait Until Page Does Not Contain Element    ${SHARE_WITH_OTHER_GOT_IT_BUTTON}    3s
    END

Open Saved Article
    [Documentation]    Opens an article from inside a reading list, by title.
    ...    Scoped to the row-title id and the article title together, so it keeps working
    ...    once a list holds more than one article. The row description carries a different
    ...    id, so the two cannot collide.
    ...    Retries the tip-dismissal and the row wait as a pair: the share balloon opens in
    ...    its own window and hides the list from the tree entirely, and it can arrive after
    ...    the dismissal step has already run.
    [Arguments]    ${title}
    ${locator}=    Format String    ${SAVED_ARTICLE_IN_LIST}    ${title}
    Wait Until Keyword Succeeds    20s    2s    Wait For Saved Article Row    ${locator}
    Click Element    ${locator}

Wait For Saved Article Row
    [Documentation]    One attempt at getting the list row visible.
    [Arguments]    ${locator}
    Dismiss Share With Others Tip If Present
    Wait Until Page Contains Element    ${locator}    timeout=5s

Verify Saved Article Is Listed
    [Documentation]    Asserts the article appears in the open reading list.
    ...    Matches the row-title id and the article title in one locator, so the assertion
    ...    is about this article rather than about some row existing. Valid for a list of
    ...    any size.
    [Arguments]    ${title}
    ${locator}=    Format String    ${SAVED_ARTICLE_IN_LIST}    ${title}
    Wait Until Page Contains Element    ${locator}

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
    ...    Deleting the list removes its ReadingListPage rows with it, so this also
    ...    clears the article's membership in that list. The default list is unaffected.
    ...    Only works for user-created lists: the default list has no delete option.
    ...    The confirmation step is conditional - it does not appear on every list,
    ...    and a mandatory wait for it fails the delete that already succeeded.
    [Arguments]    ${list_name}
    ${locator}=    Format String    ${CUSTOM_LIST_ITEM}    ${list_name}
    Wait Until Page Contains Element    ${locator}
    Long Press Element                  ${locator}
    Wait Until Page Contains Element    ${DELETE_LIST_MENU_ITEM}
    Click Element                       ${DELETE_LIST_MENU_ITEM}
    ${confirm}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    ${CONFIRM_DIALOG_OK}    timeout=15s
    IF    ${confirm}
        Click Element    ${CONFIRM_DIALOG_OK}
    END

Go To Saved Screen
    [Documentation]    Puts the app on the Saved screen from any state.
    ...    Restarts only when the bottom nav is not already reachable. Every restart
    ...    is a trigger point for the home survey and this suite was firing three per
    ...    test, so a restart that buys nothing costs stability.
    ...    The navigation is retried for the same reason the restart gate is: the
    ...    survey can arrive after the restart gate passed and swallow the tab tap.
    ${nav_visible}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${SAVED_BAR}
    IF    not ${nav_visible}
        app.Restart App Process
    END
    Wait Until Keyword Succeeds    20s    2s    Reach Saved Screen

Reach Saved Screen
    [Documentation]    One attempt at landing on the Saved screen with nothing on top of it.
    app.Dismiss Home Survey If Present
    search_actions.Navigate To Saved Page
    Dismiss Sync Reading Lists Prompt If Present
    Wait Until Page Contains Element    ${DEFAULT_SAVE_LIST}    timeout=5s

Remove Reading List If Present
    [Documentation]    Deletes the named list when the database says one exists.
    ...    The database is the gate, not the screen - it answers from any state,
    ...    including one the UI cannot be read in. Deleting the list drops its
    ...    ReadingListPage rows with it.
    [Arguments]    ${list_name}
    ${rows}=    db_oracle.Get Reading List Rows    ${list_name}
    IF    len($rows) == 0
        RETURN    ${FALSE}
    END
    Wait Until Keyword Succeeds    3x    2s    Delete Reading List And Verify    ${list_name}
    RETURN    ${TRUE}

Delete Reading List And Verify
    [Documentation]    One attempt at deleting the list, checked against the database.
    ...    Deleting through the UI can silently do nothing - a long press that does not
    ...    register, a confirmation that never renders - and none of that raises. Without
    ...    a check the caller reports success and the teardown leaves the list behind.
    [Arguments]    ${list_name}
    Go To Saved Screen
    Delete Reading List    ${list_name}
    db_oracle.Wait Until Reading List Does Not Exist    ${list_name}

Remove Saved Article If Present
    [Documentation]    Un-saves the article from the default list when a row remains.
    ...    Runs after the custom-list step, so the article is down to one list by now and
    ...    the Save menu takes its simple "remove from saved" branch.
    [Arguments]    ${api_title}
    ${rows}=    db_oracle.Get Saved Article Rows    ${api_title}
    IF    len($rows) == 0
        RETURN    ${FALSE}
    END
    Wait Until Keyword Succeeds    3x    2s    Remove Saved Article And Verify    ${api_title}
    RETURN    ${TRUE}

Remove Saved Article And Verify
    [Documentation]    One attempt at un-saving the article, checked against the database.
    ...    Same reasoning as the list removal: the UI path can fail without raising.
    [Arguments]    ${api_title}
    Go To Saved Screen
    Open Default Saved List
    Open Saved Article    ${api_title}
    article_actions.Remove Article From List
    db_oracle.Wait Until Article Is Not Saved    ${api_title}

Ensure Clean Saved State
    [Documentation]    Setup and teardown for the whole suite. Leaves no custom
    ...    list and no saved article, from any state a test can die in.
    ...    Native context first: a mobile: command issued from a WebView context is
    ...    proxied to chromedriver and fails, which would take the restart with it.
    ...    Network second, because a test that died offline leaves the device
    ...    offline for everything after it.
    ...    Both removals run even when the first one dies, and their errors are
    ...    reported rather than swallowed - a teardown that cannot clean has to say
    ...    which keyword broke.
    ...    Verification only runs for a step that actually removed something. If
    ...    nothing was there, the database read that proved it just ran.
    ...    Conditions use the bare $name form: the FAIL branch carries an error
    ...    message full of quotes and brackets, and ${name} would paste it into the
    ...    expression and break the parse.
    [Arguments]    ${api_title}    ${list_name}
    app.Return To Native Context
    Run Keyword And Ignore Error    network.Enable Network
    ${list_status}    ${list_result}=    Run Keyword And Ignore Error
    ...    Remove Reading List If Present     ${list_name}
    ${page_status}    ${page_result}=    Run Keyword And Ignore Error
    ...    Remove Saved Article If Present    ${api_title}
    IF    '${list_status}' == 'PASS' and $list_result
        db_oracle.Wait Until Reading List Does Not Exist    ${list_name}
    END
    IF    '${page_status}' == 'PASS' and $page_result
        db_oracle.Wait Until Article Is Not Saved    ${api_title}
    END
    IF    '${list_status}' == 'FAIL' or '${page_status}' == 'FAIL'
        Fail    Cleanup failed. List: ${list_status} ${list_result} -- Article: ${page_status} ${page_result}
    END



