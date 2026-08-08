*** Settings ***
Library     Process
Library     AppiumLibrary
*** Variables ***
${DEVICE}    emulator-5554

*** Keywords ***
Disable Network
    [Documentation]    Takes the device offline, then confirms it is really down.
    ...    If the disable silently failed the test would pass while online and prove nothing.
    Execute Script    mobile: shell    command=svc    args=${{ ['wifi','disable'] }}
    Execute Script    mobile: shell    command=svc    args=${{ ['data','disable'] }}
    ${status}=    Execute Script    mobile: getConnectivity
    Should Not Be True    ${status}[wifi]
    Should Not Be True    ${status}[data]

Enable Network
    [Documentation]    Restores connectivity. Must run in teardown even when the
    ...    test fails, or every test after it runs on a dead network.
    Run Process    adb    -s    ${DEVICE}    shell    svc    wifi    enable
    Run Process    adb    -s    ${DEVICE}    shell    svc    data    enable