*** Settings ***
Library         AppiumLibrary

*** Variables ***
${REMOTE_URL}               http://127.0.0.1:4723
${PLATFORM}                 Android
${AUTOMATION}               UiAutomator2
${DEVICE}               emulator-5554
${APP_PACKAGE}                  org.wikipedia.alpha
${APP_ACTIVITY}                 org.wikipedia.DefaultIcon

${SKIP_ARROW}       android=new UiSelector().className("android.widget.Button")
${SKIP_BUTTON}      android=new UiSelector().className("android.widget.Button").instance(0)
*** Keywords ***
Open Wikipedia
    [Documentation]         Starts a session with a clean app state (noReset=false)
    Open Application    ${REMOTE_URL}
    ...         platformName=${PLATFORM}      automationName=${AUTOMATION}
    ...     deviceName=${DEVICE}      appPackage=${APP_PACKAGE}
    ...         appActivity=${APP_ACTIVITY}             noReset=${FALSE}
    ...         newCommandTimeout=${300}    appium:chromedriverAutodownload=${True}

Skip Tutorial
    [Documentation]    Click through the 3 intro screens, then hit skip to reach the app.
    FOR    ${i}    IN RANGE    3
        Wait Until Element Is Visible    ${SKIP_ARROW}
        Click Element    ${SKIP_ARROW}
    END
    Wait Until Element Is Visible    ${SKIP_BUTTON}
    Click Element    ${SKIP_BUTTON}

Return To Native Context
    [Documentation]    Teardown safety net — get back to NATIVE_APP so a test that
    ...                dies mid-WebView doesn't strand the next test in the DOM.
    Run Keyword And Ignore Error    Switch To Context    NATIVE_APP


