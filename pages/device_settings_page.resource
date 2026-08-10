*** Variables ***
${DKA_ROW}    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().textContains("keep activities"))
${SETTINGS_SCROLLABLE}    android=new UiSelector().scrollable(true)
${DEVICE}               emulator-5554
