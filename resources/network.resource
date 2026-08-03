*** Settings ***
Library     Process

*** Variables ***
${DEVICE}    emulator-5554

*** Keywords ***
Disable Network
    [Documentation]    Takes the device offline by disabling both wifi and mobile
    ...    data, then confirms it is really down.
    ...    The confirmation matters: if the disable silently failed, the test
    ...    would pass while online and prove nothing about offline reading.
    Run Process    adb    -s    ${DEVICE}    shell    svc    wifi    disable
    Run Process    adb    -s    ${DEVICE}    shell    svc    data    disable
    ${ping}=    Run Process    adb    -s    ${DEVICE}    shell    ping    -c    1    -W    2    8.8.8.8
    ...    stderr=STDOUT
    Should Not Be Equal As Integers    ${ping.rc}    0
    ...    msg=Network is still reachable - the disable did not take

Enable Network
    [Documentation]    Restores connectivity. Must run in teardown even when the
    ...    test fails, or every test after it runs on a dead network.
    Run Process    adb    -s    ${DEVICE}    shell    svc    wifi    enable
    Run Process    adb    -s    ${DEVICE}    shell    svc    data    enable