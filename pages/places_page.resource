*** Variables ***
${NAV_MORE}                     accessibility_id=More
${MENU_PLACES}                  android=new UiSelector().text("Places")
${LOCATION_PERMISSION_DENY}     id=com.android.permissioncontroller:id/permission_deny_button
${MY_LOCATION_BUTTON}           id=org.wikipedia.alpha:id/myLocationButton
${PLACES_BACK}                  accessibility_id=Back
${LOCATION_REQUIRED_MESSAGE}    android=new UiSelector().textContains("Location permission is required")