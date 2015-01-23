/*
 * Copyright 2012-2015 Canonical Ltd.
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

import QtQuick 2.2
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import Ubuntu.History 0.1
import "dateUtils.js" as DateUtils

ListItemWithActions {
    id: delegate

    property var participant: participants ? participants[0] : {}
    property bool groupChat: participants.length > 1
    property string searchTerm
    property string phoneNumber: delegateHelper.phoneNumber
    property bool unknownContact: delegateHelper.isUnknown
    property string threadId: model.threadId
    property var displayedEvent: null
    property var displayedEventTextAttachments: displayedEvent ? displayedEvent.textMessageAttachments : eventTextAttachments
    property var displayedEventTimestamp: displayedEvent ? displayedEvent.timestamp : eventTimestamp
    property var displayedEventTextMessage: displayedEvent ? displayedEvent.textMessage : eventTextMessage
    property string groupChatLabel: {
        var firstRecipient
        if (unknownContact) {
            firstRecipient = delegateHelper.phoneNumber
        } else {
            firstRecipient = delegateHelper.alias
        }

        if (participants.length > 1) {
            // TRANSLATORS: %1 is the first recipient the message is sent to, %2 is the count of remaining recipients
            return i18n.tr("%1 + %2").arg(firstRecipient).arg(String(participants.length-1))
        }
        return firstRecipient
    }

    property string textMessage: {
        // check if this is an mms, if so, search for the actual text
        var imageCount = 0
        var videoCount = 0
        var contactCount = 0
        var attachmentCount = 0
        for (var i = 0; i < displayedEventTextAttachments.length; i++) {
            if (startsWith(displayedEventTextAttachments[i].contentType, "text/plain")) {
                return application.readTextFile(displayedEventTextAttachments[i].filePath)
            } else if (startsWith(displayedEventTextAttachments[i].contentType, "image/")) {
                imageCount++
            } else if (startsWith(displayedEventTextAttachments[i].contentType, "video/")) {
                videoCount++
            } else if (startsWith(displayedEventTextAttachments[i].contentType, "text/vcard") ||
                      startsWith(displayedEventTextAttachments[i].contentType, "text/x-vcard")) {
                contactCount++
            }
        }
        attachmentCount = imageCount + videoCount + contactCount

        if (imageCount > 0 && attachmentCount == imageCount) {
            return i18n.tr("Attachment: %1 image", "Attachments: %1 images").arg(imageCount)
        }
        if (videoCount > 0 && attachmentCount == videoCount) {
            return i18n.tr("Attachment: %1 video", "Attachments: %1 videos").arg(videoCount)
        }
        if (contactCount > 0 && attachmentCount == contactCount) {
            return i18n.tr("Attachment: %1 contact", "Attachments: %1 contacts").arg(contactCount)
        }
        if (attachmentCount > 0) {
            return i18n.tr("Attachment: %1 file", "Attachments: %1 files").arg(attachmentCount)
        }
        return displayedEventTextMessage
    }
    anchors.left: parent.left
    anchors.right: parent.right
    height: units.gu(10)

    leftSideAction: Action {
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: {
            threadModel.removeThreads(model.threads);
        }
    }

    Component.onCompleted: {
        if (searchTerm !== "") {
            delegateHelper.updateSearch()
        }
    }

    ContactAvatar {
        id: avatar

        fallbackAvatarUrl: {
            if (groupChat) {
                return "image://theme/contact-group"
            } else if (delegateHelper.avatar !== "") {
                return delegateHelper.avatar
            } else {
                return "image://theme/contact"
            }
        }
        fallbackDisplayName: delegateHelper.alias
        showAvatarPicture: groupChat || (delegateHelper.avatar !== "") || (initials.length === 0)
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        height: units.gu(6)
        width: units.gu(6)
    }

    Label {
        id: contactName
        anchors {
            top: avatar.top
            topMargin: units.gu(0.5)
            left: avatar.right
            leftMargin: units.gu(1)
        }
        color: UbuntuColors.lightAubergine
        text: groupChat ? groupChatLabel : unknownContact ? delegateHelper.phoneNumber : delegateHelper.alias
    }

    Label {
        id: time

        anchors {
            verticalCenter: contactName.verticalCenter
            right: parent.right
        }

        text: {
            if (!displayedEvent) {
                Qt.formatTime(displayedEventTimestamp, Qt.DefaultLocaleShortDate)
            } else {
                DateUtils.friendlyDay(Qt.formatDate(displayedEventTimestamp, "yyyy/MM/dd"))
            }
        }
        fontSize: "small"
    }

    UbuntuShape {
        id: unreadCountIndicator
        height: units.gu(2)
        width: height
        anchors {
            top: time.bottom
            topMargin: units.gu(1)
            right: parent.right
            rightMargin: units.gu(2)
        }
        visible: unreadCount > 0
        color: "#38b44a"
        Label {
            anchors.centerIn: parent
            text: unreadCount
            color: "white"
            fontSize: "x-small"
            font.weight: Font.Light
        }
    }

    // This is currently not being used in the new designs, but let's keep it here for now
    /*
    Label {
        id: phoneType
        anchors {
            top: contactName.bottom
            left: contactName.left
        }
        text: delegateHelper.phoneNumberSubTypeLabel
        color: "gray"
        fontSize: "x-small"
    }*/

    Label {
        id: latestMessage

        anchors {
            top: contactName.bottom
            topMargin: units.gu(0.5)
            left: contactName.left
            right: time.left
            rightMargin: units.gu(3)
            bottom: avatar.bottom
        }
        elide: Text.ElideRight
        fontSize: "x-small"
        text: textMessage
    }

    Item {
        id: delegateHelper
        property string phoneNumber: participant.phoneNumber
        property string alias: participant.alias ? participant.alias : ""
        property string avatar: participant.avatar ? participant.avatar : ""
        property string contactId: participant.contactId ? participant.contactId : ""
        property alias subTypes: phoneDetail.subTypes
        property alias contexts: phoneDetail.contexts
        property bool isUnknown: contactId === ""
        property string phoneNumberSubTypeLabel: ""
        property var searchHistoryFilter: HistoryIntersectionFilter {
            HistoryFilter { filterProperty: "threadId"; filterValue: model.threadId }
            HistoryFilter { filterProperty: "accountId"; filterValue: model.accountId }
            HistoryFilter { filterProperty: "message"; filterValue: searchTerm; matchFlags: HistoryFilter.MatchContains }
        }

        function updateSearch() {
            var found = false
            var searchTermLowerCase = searchTerm.toLowerCase()
            if (searchTerm !== "") {
                if ((delegateHelper.phoneNumber.toLowerCase().search(searchTermLowerCase) !== -1)
                || (!unknownContact && delegateHelper.alias.toLowerCase().search(searchTermLowerCase) !== -1)) {
                    found = true
                } else {
                    searchEventModelLoader.active = true
                }
            } else {
                delegate.displayedEvent = null
                searchEventModelLoader.active = false
                found = true
            }

            delegate.height = found ? units.gu(8) : 0
        }

        // WORKAROUND: history-service can't filter by contact names
        Connections {
            target: delegate
            onSearchTermChanged: {
                delegateHelper.updateSearch()
            }
        }

        Loader {
            id: searchEventModelLoader
            active: false
            asynchronous: true
            sourceComponent: searchEventModelComponent
        }

        Component {
            id: searchEventModelComponent
            HistoryEventModel {
                id: eventModel
                type: HistoryThreadModel.EventTypeText
                filter: delegateHelper.searchHistoryFilter
                onCountChanged: {
                    if (count > 0) {
                        delegate.height = units.gu(8)
                        delegate.displayedEvent = eventModel.get(0)
                    } else if (searchTerm == "") {
                        delegate.height = units.gu(8)
                        delegate.displayedEvent = null
                    } else {
                        delegate.displayedEvent = null
                        delegate.height = 0
                    }
                }
            }
        }

        function updateSubTypeLabel() {
            var subLabel = "";
            if (participant && participant.phoneNumber) {
                var typeInfo = phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail))
                if (typeInfo) {
                    subLabel = typeInfo.label
                }
            }
            phoneNumberSubTypeLabel = subLabel
        }

        onSubTypesChanged: updateSubTypeLabel();
        onContextsChanged: updateSubTypeLabel();
        onIsUnknownChanged: updateSubTypeLabel();

        PhoneNumber {
            id: phoneDetail
            contexts: participant.phoneContexts ? participant.phoneContexts : []
            subTypes: participant.phoneSubTypes ? participant.phoneSubTypes : []
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
        }
    }
}
