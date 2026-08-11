*** Variables ***
${SYNC_READING_LIST_ALERT}          id=org.wikipedia.alpha:id/alertTitle
${NO_THANKS_BUTTON}                 id=android:id/button2
${DEFAULT_SAVE_LIST}                android=new UiSelector().resourceId("org.wikipedia.alpha:id/item_title").instance(0)

${SHARE_WITH_OTHER_GOT_IT_BUTTON}       id=org.wikipedia.alpha:id/buttonView

${THE_ONLY_SAVED_ARTICLE_IN_DEFAULT_LIST}           id=org.wikipedia.alpha:id/page_list_item_title

${CUSTOM_LIST_NAME}                     QA Test List

${CUSTOM_LIST_ITEM}          android=new UiSelector().text("{}")
${DELETE_LIST_MENU_ITEM}     android=new UiSelector().text("Delete list")
${CONFIRM_DIALOG_OK}         id=android:id/button1