project(qml)

file(GLOB QML_JS_FILES *.qml *.js)

add_custom_target(messaging_app_QMlFiles ALL SOURCES ${QML_JS_FILES})

set(ASSETS_DIR assets)
set(3RD_PARTY_DIR 3rd_party)

install(FILES ${QML_JS_FILES} DESTINATION ${MESSAGING_APP_DIR})
install(DIRECTORY ${ASSETS_DIR} DESTINATION ${MESSAGING_APP_DIR})
install(DIRECTORY ${3RD_PARTY_DIR} DESTINATION ${MESSAGING_APP_DIR})

add_subdirectory(AttachmentDelegates)
add_subdirectory(Dialogs)
add_subdirectory(Stickers)
