*** Variables ***
${SEARCH_BAR}     android=new UiSelector().resourceId("org.wikipedia.alpha:id/navigation_bar_item_content_container").instance(2)
${FASTER_WAY_TO_SEARCH_WINDOW_CLOSE_BUTTON}         android=new UiSelector().className("android.widget.Button").instance(0)

${SEARCH_PLACEHOLDER}         id=org.wikipedia.alpha:id/search_text_view
${SEARCH_FIELD}             id=org.wikipedia.alpha:id/search_src_text
${FIRST_RESULT_ARTICLE}     android=new UiSelector().className("android.view.View").instance(3)
${HIST1H1B_ARTICLE_TITLE}            android=new UiSelector().text("HIST1H1B")

${SEARCH_RESULT_ARTICLE_TITLE}          android=new UiSelector().text("{}")

${HIST1H1B_ARTICLE_NAME}         HIST1H1B
${HIST1_ARTICLE_PREFIX_NAME}         HIST1

${ENGLISH_HIST1H1B_ARTICLE_URL}         https://en.wikipedia.org/wiki/HIST1H1B

${NO_RESULTS_MESSAGE}       android=new UiSelector().text("No results")
${NON_EXISTENT_ARTICLE}         gvnahpfxfcas

${CLEAR_QUERY_BUTTON}           accessibility_id=Clear query
${RECENT_SEARCHES_HEADER}         id=org.wikipedia.alpha:id/list_title

${ARABIC_BAGHDAD_ARTICLE_NAME}          بغداد
${ARABIC_BAGHDAD_ARTICLE_TITLE}          android=new UiSelector().text("بغداد")

${SAVED_BAR}                        accessibility_id=Saved