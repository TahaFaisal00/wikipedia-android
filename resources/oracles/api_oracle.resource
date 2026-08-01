*** Settings ***
Library   Collections
Library    RequestsLibrary
Library    String

*** Variables ***
${WIKI_UA}    WikipediaQA-Suite/1.0 (https://github.com/TahaFaisal00)

${WIKI_EN}          https://en.wikipedia.org
${WIKI_AR}          https://ar.wikipedia.org

${ALIAS}            wiki
${GET_SEARCH_RESULTS_API}       /w/api.php
${GET_ARTICLE_FIRST_PARAGRAPH_API}      /api/rest_v1/page/summary/{}
${OK_CODE}          200
*** Keywords ***
Open Session
    [Documentation]     Starts the HTTP session which is shared between all the APIs.
    [Arguments]     ${host}
    &{headers}=     Create Dictionary       User-Agent=${WIKI_UA}
    Create Session    ${ALIAS}    ${host}       headers=${headers}

Get Expected Search Titles
    [Documentation]     Oracle. Read-only. Returns what the server says the results are.
    ...                 Never asserts. Only reports
    [Arguments]     ${search_term}
    &{params}=      Create Dictionary       action=query        list=prefixsearch
    ...             pssearch=${search_term}        format=json     pslimit=10
    ${response}=        GET On Session      ${ALIAS}        ${GET_SEARCH_RESULTS_API}   params=${params}
    Status Should Be        ${OK_CODE}      ${response}
    Log    ${response.json()}
    ${titles}=      Evaluate    [h['title'] for h in $response.json()['query']['prefixsearch']]
    RETURN      ${titles}

Get Expected Article Extract
    [Documentation]     Oracle. Read-only. The article's first paragraph,
    ...                 get the article intro from the API. Already clean plain text.
    [Arguments]     ${title}
    ${get_article_first_paragraph_api_with_title}=      Format String       ${GET_ARTICLE_FIRST_PARAGRAPH_API}      ${title}
    ${response}=        GET On Session      ${ALIAS}        ${get_article_first_paragraph_api_with_title}
    Status Should Be    ${OK_CODE}      ${response}
    Log    ${response.json()}
    RETURN      ${response.json()}[extract]
