*** Variables ***
${SYNC_READING_LIST_ALERT}          id=org.wikipedia.alpha:id/alertTitle
${NO_THANKS_BUTTON}                 id=android:id/button2
${SAVED_PAGE_TITLE}                 android=new UiSelector().text("Saved").instance(0)
${DEFAULT_SAVE_LIST}                android=new UiSelector().resourceId("org.wikipedia.alpha:id/item_title").instance(0)

${SHARE_WITH_OTHER_GOT_IT_BUTTON}       id=org.wikipedia.alpha:id/buttonView

${THE_ONLY_SAVED_ARTICLE_IN_DEFAULT_LIST}           id=org.wikipedia.alpha:id/page_list_item_title