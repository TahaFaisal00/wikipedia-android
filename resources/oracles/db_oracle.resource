*** Settings ***
Library         DatabaseLibrary
Library         OperatingSystem
Library         Process

*** Variables ***
${DEVICE}           emulator-5554
${PKG}              org.wikipedia.alpha
${DEVICE_DB_DIR}    /data/data/${PKG}/databases
${SNAPSHOT_DIR}     ${CURDIR}/../../.tmp
${LOCAL_DB}         ${SNAPSHOT_DIR}/wikipedia.db

${DEFAULT_LIST_ID}                  1
*** Keywords ***
Snapshot Device Database
    [Documentation]     Oracle plumbing. Pulls a fresh copy of the app database
    ...    into a scratch folder. The copy is a point-in-time snapshot, so retake
    ...    it after any action whose effect you want to read.
    ...    The folder is wiped first - a leftover file would make the oracle
    ...    report stale data as current.
    ...    The -wal file holds most recent writes and must sit beside the .db
    ...    under its exact name. Its pull is unchecked because after a checkpoint
    ...    it legitimately does not exist. The -shm file is scratch and is skipped.
    Remove Directory    ${SNAPSHOT_DIR}    recursive=True
    Create Directory    ${SNAPSHOT_DIR}
    ${db}=    Run Process    adb    -s    ${DEVICE}    pull
    ...    ${DEVICE_DB_DIR}/wikipedia.db    ${SNAPSHOT_DIR}    stderr=STDOUT
    Should Be Equal As Integers    ${db.rc}    0    msg=adb pull failed: ${db.stdout}
    Run Process    adb    -s    ${DEVICE}    pull
    ...    ${DEVICE_DB_DIR}/wikipedia.db-wal    ${SNAPSHOT_DIR}    stderr=STDOUT
    File Should Exist    ${LOCAL_DB}

Get Saved Article Rows
    [Documentation]    Oracle. Reads the local snapshot, never the device.
    ...    Returns every ReadingListPage row for an article, as a list.
    ...    Matches on apiTitle, not displayTitle: displayTitle stores the title
    ...    wrapped in HTML spans and never equals a plain title.
    ...    Returns the full list so callers can assert a count - one row after a
    ...    save, zero after a removal, still one after a duplicate save attempt.
    [Arguments]    ${api_title}
    Snapshot Device Database
    Connect To Database    sqlite3    ${LOCAL_DB}
    ${rows}=    Query
    ...    SELECT apiTitle, offline, status, sizeBytes, listId FROM ReadingListPage WHERE apiTitle = ?
    ...    parameters=${{ ($api_title,) }}
    RETURN    ${rows}
    [Teardown]    Disconnect From Database

Verify Article Is Not Saved
    [Documentation]    Premise guard. Asserts the article has no persisted row.
    ...    A leftover row from a crashed run turns the test's first tap into a
    ...    context menu, and the failure then shows up far from the real cause.
    [Arguments]    ${api_title}
    ${rows}=    db_oracle.Get Saved Article Rows    ${api_title}
    Should Be Empty    ${rows}

Verify Saved Article Row Is Correct
    [Documentation]    Asserts the persisted row describes a real offline save:
    ...    exactly one row, the right article, the offline flag set, content
    ...    actually on disk, and saved to the default list.
    ...    sizeBytes matters because the flag can be set with nothing downloaded.
    ...    status is not asserted - its values are undocumented.
    ...    Column order from the oracle: 0 apiTitle, 1 offline, 2 status,
    ...    3 sizeBytes, 4 listId.
    [Arguments]    ${api_title}
    ${rows}=    db_oracle.Get Saved Article Rows    ${api_title}
    Length Should Be                ${rows}          1
    ${row}=    Set Variable         ${rows}[0]
    Should Be Equal                 ${row}[0]        ${api_title}
    Should Be Equal As Integers     ${row}[1]        1
    Should Be True                  ${row}[3] > 0
    Should Be Equal As Integers     ${row}[4]        ${DEFAULT_LIST_ID}

Wait Until Saved Article Row Is Correct
    [Documentation]    Polls the DB until the saved row reports real content.
    ...    The row is written the instant Save is tapped, but the article
    ...    downloads asynchronously, so sizeBytes sits at zero for a moment.
    ...    Each retry retakes the snapshot, so every attempt reads fresh state.
    [Arguments]    ${api_title}
    Wait Until Keyword Succeeds    30s    2s
    ...    Verify Saved Article Row Is Correct    ${api_title}


