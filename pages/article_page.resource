*** Variables ***
${WIKIPEDIA_GAMES_AD_CLOSE_BUTTON}              id=org.wikipedia.alpha:id/closeButton
${ARTICLE_BODY_TEXT_LOCATOR}                    xpath=//div[@id="pcs"]/section[1]/p[1]

${SAVE_ARTICLE_BUTTON}                          accessibility_id=Save

${REMOVE_FROM_LIST_BUTTON}    android=new UiSelector().textStartsWith("Remove from")
${LIST_NAME_FIELD}                  id=org.wikipedia.alpha:id/text_input
${ADD_TO_LIST_OK_BUTTON}            id=android:id/button1

${SAVED_SNACKBAR_TEXT}      Do you want to add it to a list?

${RETURN_BUTTON}                    accessibility_id=Navigate up

${ADD_TO_ANOTHER_LIST_MENU_ITEM}    android=new UiSelector().text("Add to another reading list")
${CREATE_NEW_LIST_BUTTON}           android=new UiSelector().text("Create new")

${ARTICLE_SECTION_HEADER}     css=#pcs section[data-mw-section-id="{}"] .pcs-section-hideable-header
${ARTICLE_SECTION_CONTENT_ID}    pcs-section-content-{}
