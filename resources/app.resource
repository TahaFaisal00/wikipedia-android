*** Settings ***
Library         AppiumLibrary
Library    Process
Resource        oracles/api_oracle.resource

*** Variables ***
${REMOTE_URL}               http://127.0.0.1:4723
${PLATFORM}                 Android
${AUTOMATION}               UiAutomator2
${DEVICE}               emulator-5554
${APP_PACKAGE}                  org.wikipedia.alpha
${APP_ACTIVITY}                 org.wikipedia.DefaultIcon

${SKIP_ARROW}       android=new UiSelector().className("android.widget.Button")
${SKIP_BUTTON}      android=new UiSelector().className("android.widget.Button").instance(0)

${MAIN_SCREEN_ANCHOR}       android=new UiSelector().className("android.view.View").instance(2)

${HOME_SURVEY_CANCEL_BUTTON}    id=org.wikipedia.alpha:id/cancelButton
*** Keywords ***
Open Wikipedia
    [Documentation]         Starts a session with a clean app state (noReset=false).
    ...                     Device language defaults to English.
    ...                     Pass language/country to launch under a different locale — the driver
    ...                     applies it BEFORE the app process starts, which is required because
    ...                     the app resolves its strings at launch.
    [Arguments]         ${language}=en    ${country}=US
    Open Application    ${REMOTE_URL}
    ...         platformName=${PLATFORM}      automationName=${AUTOMATION}
    ...      deviceName=${DEVICE}       appium:udid=${DEVICE}            appPackage=${APP_PACKAGE}
    ...         appActivity=${APP_ACTIVITY}             noReset=${FALSE}
    ...         newCommandTimeout=${300}    appium:chromedriverAutodownload=${True}
    ...       appium:language=${language}    appium:locale=${country}

Start Session
    [Documentation]     Suite Setup. Opens the app under the given device locale,
    ...                 binds the API oracle to the matching Wikipedia host, and
    ...                 clears onboarding. Defaults to English.
    ...                 Onboarding is once-per-session, so it belongs here and not
    ...                 in a test setup.
    [Arguments]    ${language}=en    ${country}=US    ${api_host}=${WIKI_EN}
    Open Wikipedia    language=${language}    country=${country}
    Open Session      ${api_host}
    Skip Tutorial

Verify Device Locale Is Arabic
    [Documentation]    Premise check, not a test assertion. Reads the locale from the
    ...                device rather than the app, so it stays independent of the
    ...                interface-translation claim made by the RTL tests themselves.
    ...                A failure here means the phone never switched — read it as
    ...                "the setup broke", not "the app is wrong".
    ${locale}=    Execute Script    mobile: shell
    ...           command=getprop    args=${{ ['persist.sys.locale'] }}
    Should Start With    ${locale.strip()}    ar
#appium --allow-insecure="*:chromedriver_autodownload,*:adb_shell" is required

Restart App Process
    [Documentation]    Kills and relaunches the app process WITHOUT clearing its data.
    ...                Returns the app to its launch activity with an empty back stack,
    ...                so a test can't inherit whatever screen the previous one abandoned.
    ...                Deliberately not Close Application + Open Wikipedia: that clears
    ...                app data, which resurrects the tutorial and the first-run tips that
    ...                Suite Setup already consumed.
    Execute Script    mobile: terminateApp    appId=${APP_PACKAGE}
    Execute Script    mobile: activateApp     appId=${APP_PACKAGE}
    Dismiss Home Survey If Present
    Wait Until Page Contains Element    ${MAIN_SCREEN_ANCHOR}

Skip Tutorial
    [Documentation]    Click through the 3 intro screens, then hit skip to reach the app.
    FOR    ${i}    IN RANGE    3
        Wait Until Element Is Visible    ${SKIP_ARROW}
        Click Element    ${SKIP_ARROW}
    END
    Wait Until Element Is Visible    ${SKIP_BUTTON}
    Click Element    ${SKIP_BUTTON}

Dismiss Home Survey If Present
    [Documentation]     The "Help improve Home" survey fires on some launch cadence, so
    ...                 it only surfaces during whole-suite runs and lands on whichever
    ...                 test is unlucky. Conditional because the dialog is genuinely
    ...                 nondeterministic — and safe to make conditional because no test
    ...                 asserts anything about it, so a silent no-op hides nothing.
    ...                 Mitigation, not a fix: the deterministic answer is suppressing
    ...                 the dialog at its trigger.
    ${present}=     Run Keyword And Return Status
    ...             Page Should Contain Element    ${HOME_SURVEY_CANCEL_BUTTON}
    IF    ${present}
        Click Element    ${HOME_SURVEY_CANCEL_BUTTON}
        Wait Until Page Does Not Contain Element    ${HOME_SURVEY_CANCEL_BUTTON}        2s
    END

Switch To Article WebView
    [Documentation]    Re-resolves the WebView handle each call — recreation destroys the old one.
    Switch To Context    WEBVIEW_org.wikipedia.alpha

Return To Native Context
    [Documentation]    Teardown safety net — get back to NATIVE_APP so a test that
    ...                dies mid-WebView doesn't strand the next test in the DOM.
    Run Keyword And Ignore Error    Switch To Context    NATIVE_APP

Open Deep Link
    [Documentation]     Opens a URL directly in the app, bypassing in-app navigation.
    ...                 Search is bound to the app's language, so it can only reach the
    ...                 current locale's wiki — this can reach any of them.
    [Arguments]    ${url}
    Execute Script    mobile: deepLink    url=${url}    package=${APP_PACKAGE}

Restart App Cold
    [Documentation]    Kills the app process and relaunches it.
    ...    Uses force-stop rather than a graceful close, which makes the
    ...    durability claim stronger: a killed process gets no chance to flush
    ...    anything, so whatever survives was genuinely on disk already.
    ...    Onboarding prompts can reappear on relaunch, so callers must tolerate
    ...    them the same way they do on a fresh session.
    ${result}=    Run Process    adb    -s    ${DEVICE}    shell    am    force-stop    ${PKG}
    ...    stderr=STDOUT
    Should Be Equal As Integers    ${result.rc}    0    msg=${result.stdout}
    Activate Application    ${PKG}

Background App And Return
    [Documentation]    Backgrounds the app for ${seconds}, then clears anything that fires on resume.
    [Arguments]    ${seconds}=${5}
    Background Application    ${seconds}
    Dismiss Home Survey If Present

Kill App Process
    [Documentation]    Real process death — the app is restored from the saved-instance Bundle on return.
    Background Application    ${-1}
    Execute Script    mobile: shell    command=am
    ...    args=${{ ['kill','org.wikipedia.alpha'] }}
    Activate Application    org.wikipedia.alpha
    Dismiss Home Survey If Present
