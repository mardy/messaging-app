# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Messaging App"""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from messaging_app.tests import MessagingAppTestCase


class TestMessaging(MessagingAppTestCase):
    """Tests for the communication panel."""

    def setUp(self):
        super(TestMessaging, self).setUp()

    def test_click_new_message_button(self):
        self.main_view.open_toolbar()
        toolbar = self.main_view.get_toolbar()
        toolbar.click_button("newMessageButton")

    def test_write_new_message(self):
        self.test_click_new_message_button()
        self.assertThat(self.main_view.get_pagestack().depth, Eventually(Equals(2)))
        self.assertThat(self.main_view.get_messages_page().visible, Eventually(Equals(True)))
        text_entry = self.main_view.get_newmessage_textfield()
        self.pointing_device.click_object(text_entry)
        text_entry.activeFocus.wait_for(True)
        self.keyboard.type("123")
        self.assertThat(text_entry.text, Eventually(Equals("123")))
