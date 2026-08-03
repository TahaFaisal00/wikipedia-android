*** Variables ***
${WIKIPEDIA_GAMES_AD_CLOSE_BUTTON}              id=org.wikipedia.alpha:id/closeButton
${ARTICLE_BODY_TEXT_LOCATOR}                    xpath=//div[@id="pcs"]/section[1]/p[1]

${SAVE_ARTICLE_BUTTON}                          accessibility_id=Save
${SNACKBAR_TEXT}                    id=org.wikipedia.alpha:id/snackbar_text
${SNACKBAR_ACTION}                  id=org.wikipedia.alpha:id/snackbar_action
${REMOVE_FROM_LIST_BUTTON}          android=new UiSelector().resourceId("org.wikipedia.alpha:id/content").instance(2)
${LIST_NAME_FIELD}                  id=org.wikipedia.alpha:id/text_input
${ADD_TO_LIST_OK_BUTTON}            id=android:id/button1

${SAVED_SNACKBAR_TEXT}      Do you want to add it to a list?
${REMOVED_SNACKBAR_TEXT}    removed from Saved