cmake_minimum_required(VERSION 3.16)
project(utmeshcore C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Required: bluetoothmanager.h contains Q_OBJECT classes.
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# DBus is needed to read device names straight from org.bluez - Qt 5.12's
# QBluetoothDeviceDiscoveryAgent drops names that BlueZ resolves late.
find_package(Qt5 COMPONENTS Core Gui Qml Quick Bluetooth DBus REQUIRED)

# ---------------------------------------------------------------------------
# Translations: i18n/utmeshcore_<lang>.ts -> .qm, embedded as :/i18n/*.qm.
# main.cpp loads the one matching the phone's system language.
# ---------------------------------------------------------------------------
find_package(Qt5LinguistTools REQUIRED)
file(GLOB UTMESHCORE_TS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/i18n/utmeshcore_*.ts)
qt5_add_translation(UTMESHCORE_QM_FILES ${UTMESHCORE_TS_FILES})
set(UTMESHCORE_I18N_QRC ${CMAKE_CURRENT_BINARY_DIR}/i18n.qrc)
set(_i18n_entries "")
foreach(_qm ${UTMESHCORE_QM_FILES})
    get_filename_component(_qm_name ${_qm} NAME)
    string(APPEND _i18n_entries "    <file alias=\"i18n/${_qm_name}\">${_qm}</file>\n")
endforeach()
file(WRITE ${UTMESHCORE_I18N_QRC}
     "<RCC>\n  <qresource prefix=\"/\">\n${_i18n_entries}  </qresource>\n</RCC>\n")
# The .qrc references generated .qm files, so they must exist before rcc runs.
add_custom_target(utmeshcore_translations DEPENDS ${UTMESHCORE_QM_FILES})

add_executable(utmeshcore
    src/main.cpp
    src/bluetoothmanager.cpp
    src/bluetoothmanager_mesh.cpp
    src/bluetoothmanager_nearby.cpp
    src/bluetoothmanager_import.cpp
    src/bluetoothmanager.h
    src/companionprotocol.cpp
    src/companionprotocol_rx.cpp
    src/companionprotocol.h
    src/contactmodel.cpp
    src/contactmodel.h
    src/devicelistmodel.cpp
    src/devicelistmodel.h
    src/messagestore.cpp
    src/messagestore.h
    src/systemtheme.cpp
    src/systemtheme.h
    src/qrcodeitem.cpp
    src/qrcodeitem.h
    src/qrcodegen/qrcodegen.cpp
    src/qrcodegen/qrcodegen.hpp
    src/qrscanner.cpp
    src/qrscanner.h
    src/quirc/decode.c
    src/quirc/identify.c
    src/quirc/quirc.c
    src/quirc/quirc.h
    src/quirc/quirc_internal.h
    src/quirc/version_db.c
    qml.qrc
    ${UTMESHCORE_I18N_QRC})
add_dependencies(utmeshcore utmeshcore_translations)

target_include_directories(utmeshcore PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(utmeshcore
    Qt5::Core Qt5::Gui Qt5::Qml Qt5::Quick Qt5::Bluetooth Qt5::DBus)

# QML files are compiled into the binary via qml.qrc, so they are deliberately
# NOT installed separately - that only bloated the click package with a second,
# easily stale copy.
install(TARGETS utmeshcore RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES utmeshcore.desktop DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES utmeshcore.apparmor DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES utmeshcore.png DESTINATION ${CMAKE_INSTALL_PREFIX})
