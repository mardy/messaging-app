/*
 * Copyright 2012-2013 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtContacts 5.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0


Page {
    id: messages
    objectName: "messagesPage"
    property string threadId: getCurrentThreadId()
    property alias number: contactWatcher.phoneNumber
    property alias selectionMode: messageList.isInSelectionMode
    flickable: null
    title:  number !== "" ? (contactWatcher.isUnknown ? messages.number : contactWatcher.alias) : i18n.tr("New Message")
    tools: messagesToolbar
    onSelectionModeChanged: messagesToolbar.opened = false

    function getCurrentThreadId() {
        if (number === "")
            return ""
        return eventModel.threadIdForParticipants(telepathyHelper.accountId,
                                                              HistoryThreadModel.EventTypeText,
                                                              messages.number,
                                                              HistoryThreadModel.MatchPhoneNumber)
    }
   
    ContactWatcher {
        id: contactWatcher
    }

    onNumberChanged: {
        threadId = getCurrentThreadId()
    }

    Component {
        id: contactsSheet
        DefaultSheet {
            // FIXME: workaround to set the contact list
            // background to black
            Rectangle {
                anchors.fill: parent
                anchors.margins: -units.gu(1)
                color: "#221e1c"
            }
            id: sheet
            title: "Add Contact"
            doneButton: false
            modal: true
            contentsHeight: parent.height
            contentsWidth: parent.width
            ContactListView {
                anchors.fill: parent
                detailToPick: ContactDetail.PhoneNumber
                onContactClicked: {
                    // FIXME: search for favorite number
                    number = contact.phoneNumber.number
                    textEntry.forceActiveFocus()
                    PopupUtils.close(sheet)
                }
                onDetailClicked: {
                    number = detail.number
                    PopupUtils.close(sheet)
                    textEntry.forceActiveFocus()
                }
            }
            onDoneClicked: PopupUtils.close(sheet)
        }
    }

    ToolbarItems {
        id: messagesToolbar
        ToolbarButton {
            objectName: "selectMessagesButton"
            visible: messageList.count !== 0
            action: Action {
                iconSource: Qt.resolvedUrl("assets/select.png")
                text: i18n.tr("Select")
                onTriggered: messageList.startSelection()
            }
        }
        ToolbarButton {
            visible: contactWatcher.isUnknown && contactWatcher.phoneNumber !== ""
            objectName: "addContactButton"
            action: Action {
                iconSource: Qt.resolvedUrl("assets/new-contact.svg")
                text: i18n.tr("Add contact")
                onTriggered: {
                    applicationUtils.switchToAddressbookApp("create://" + contactWatcher.phoneNumber)
                    messagesToolbar.opened = false
                }
            }
        }
        ToolbarButton {
            visible: !contactWatcher.isUnknown
            objectName: "contactProfileButton"
            action: Action {
                iconSource: Qt.resolvedUrl("assets/contact.svg")
                text: i18n.tr("Contact")
                onTriggered: {
                    applicationUtils.switchToAddressbookApp("contact://" + contactWatcher.contactId)
                    messagesToolbar.opened = false
                }
            }
        }
        ToolbarButton {
            visible: contactWatcher.phoneNumber !== ""
            objectName: "contactCallButton"
            action: Action {
                iconSource: Qt.resolvedUrl("assets/call-start.svg")
                text: i18n.tr("Call")
                onTriggered: {
                    applicationUtils.switchToDialerApp("call://" + contactWatcher.phoneNumber)
                    messagesToolbar.opened = false
                }
            }
        }
        locked: selectionMode
    }

    HistoryEventModel {
        id: eventModel
        type: HistoryThreadModel.EventTypeText
        filter: HistoryIntersectionFilter {
            HistoryFilter {
                filterProperty: "threadId"
                filterValue: threadId
            }
            HistoryFilter {
                filterProperty: "accountId"
                filterValue: telepathyHelper.accountId
            }
        }
        sort: HistorySort {
           sortField: "timestamp"
           sortOrder: HistorySort.DescendingOrder
        }
    }

    SortProxyModel {
        id: sortProxy
        sourceModel: eventModel
        sortRole: HistoryEventModel.TimestampRole
        ascending: false
    }

    Item {
        id: newMessage
        property alias newNumber: newPhoneNumberField.text
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        clip: true
        height: (number === "" && threadId == "") ? units.gu(7) : 0
        focus: true

        Label {
            id: labelTo
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            text: i18n.tr("To:")
            fontSize: "medium"
            opacity: 0.2
        }

        TextField {
            id: newPhoneNumberField
            objectName: "newPhoneNumberField"
            anchors {
                verticalCenter: parent.verticalCenter
                left: labelTo.right
                right: parent.right
                leftMargin: units.gu(2)
                rightMargin: units.gu(1)
            }

            style: null
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("large")
            placeholderText: i18n.tr("Enter number")
            Keys.onReturnPressed: textEntry.forceActiveFocus()
        }

        Image {
            height: units.gu(3)
            width: units.gu(3)
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: labelTo.verticalCenter
            }

            source: Qt.resolvedUrl("assets/new-contact.svg")
            MouseArea {
                anchors.fill: parent
                onClicked: PopupUtils.open(contactsSheet)
            }
        }
    }

    Rectangle {
        anchors.fill: contactSearch
        anchors.leftMargin: -units.gu(2)
        anchors.rightMargin: -units.gu(2)
        color: "black"
        opacity: 0.6
        z: -1
    }

    ContactSearchListView {
        id: contactSearch
        property string searchTerm: {
            if(newMessage.newNumber !== "" && messages.number === "" && newPhoneNumberField.focus) {
                return newMessage.newNumber
            }
            return "some value that won't match"
        }
        clip: false
        anchors {
            top: newMessage.bottom
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }

        states: [
            State {
                name: "empty"
                when: contactSearch.count == 0
                PropertyChanges {
                    target: contactSearch
                    height: 0
                }
            }
        ]

        Behavior on height {
            UbuntuNumberAnimation { }
        }

        filter: UnionFilter {
            DetailFilter {
                detail: ContactDetail.Name
                field: Name.FirstName
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchContains
            }

            DetailFilter {
                detail: ContactDetail.Name
                field: Name.LastName
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchContains
            }

            DetailFilter {
                detail: ContactDetail.PhoneNumber
                field: PhoneNumber.Number
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchPhoneNumber
            }

            DetailFilter {
                detail: ContactDetail.PhoneNumber
                field: PhoneNumber.Number
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchContains
            }

        }

        onDetailClicked: {
            messages.number = detail.number
            textEntry.forceActiveFocus()
        }
        z: 1
    }

    MultipleSelectionListView {
        id: messageList
        clip: true
        acceptAction.text: i18n.tr("Delete")
        anchors {
            top: newMessage.bottom
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
        }
        // TODO: workaround to add some extra space at the bottom and top
        header: Item {
            height: units.gu(2)
        }
        footer: Item {
            height: units.gu(2)
        }
        listModel: threadId !== "" ? sortProxy : null
        verticalLayoutDirection: ListView.BottomToTop
        spacing: units.gu(2)
        listDelegate: MessageDelegate {
            id: messageDelegate
            incoming: senderId != "self"
            selected: messageList.isSelected(messageDelegate)
            removable: !selectionMode
            onClicked: {
                if (messageList.isInSelectionMode) {
                    if (!messageList.selectItem(messageDelegate)) {
                        messageList.deselectItem(messageDelegate)
                    }
                }
            }
            onPressAndHold: {
                messageList.startSelection()
                messageList.selectItem(messageDelegate)
            }
        }
        onSelectionDone: {
            for (var i=0; i < items.count; i++) {
                var event = items.get(i).model
                eventModel.removeEvent(event.accountId, event.threadId, event.eventId, event.type)
            }
        }
    }

    Item {
        id: bottomPanel
        anchors.bottom: keyboard.top
        anchors.bottomMargin: selectionMode ? 0 : units.gu(2)
        anchors.left: parent.left
        anchors.right: parent.right
        height: selectionMode ? 0 : textEntry.height + attachButton.height + units.gu(4)
        visible: !selectionMode
        clip: true
        ListItem.ThinDivider {
            anchors.top: parent.top
        }
        TextArea {
            id: textEntry
            clip: true
            anchors.bottomMargin: units.gu(2)
            anchors.bottom: attachButton.top
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            height: units.gu(5)
            autoSize: true
            placeholderText: i18n.tr("Write a message...")
            focus: false
        }

        Button {
            id: attachButton
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.bottom: parent.bottom
            text: "Attach"
            width: units.gu(17)
            color: "gray"
            visible: false
        }

        Button {
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            anchors.bottom: parent.bottom
            text: "Send"
            width: units.gu(17)
            enabled: textEntry.text != "" && telepathyHelper.connected && (messages.number !== "" || newMessage.newNumber !== "" )
            onClicked: {
                if (messages.number === "" && newMessage.newNumber !== "") {
                    messages.number = newMessage.newNumber
                }

                if (messages.threadId == "") {
                    // create the new thread and get the threadId
                    messages.threadId = eventModel.threadIdForParticipants(telepathyHelper.accountId,
                                                                            HistoryThreadModel.EventTypeText,
                                                                            messages.number,
                                                                            HistoryThreadModel.MatchPhoneNumber,
                                                                            true)
                }

                chatManager.sendMessage(messages.number, textEntry.text)
                textEntry.text = ""
            }
        }
    }

    KeyboardRectangle {
        id: keyboard
    }

    Scrollbar {
        flickableItem: messageList
        align: Qt.AlignTrailing
    }
}