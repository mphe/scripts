#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This script opens a browser using CEF (Chromium Embedded Framework) on a
# specific URL and closes when an URL contains a certain string.
# Before closing it prints the URL to stdout.
# The main purpose of this script is to ask the user to solve a captcha and
# grab the destination URL afterwards.
# Requires cefpython. To install it run:
#   sudo pip install cefpython3


from cefpython3 import cefpython as cef
import sys
import os

urlfound = False

def OnLoadingStateChange(browser, is_loading, **_):
    global urlfound
    if not urlfound and sys.argv[2] in browser.GetUrl():
        print(browser.GetUrl())
        urlfound = True
        browser.CloseBrowser()

def DoClose(browser):
    cef.QuitMessageLoop()
    return True


def main():
    if len(sys.argv) < 3:
        print("Syntax: cefget.py URL string")
        return 1

    sys.excepthook = cef.ExceptHook
    cef.Initialize({
        "cache_path": os.getenv("HOME") + "/.cache/cefget",
        "multi_threaded_message_loop": False
    })

    browser = cef.CreateBrowserSync(url=sys.argv[1], window_title=sys.argv[1])
    browser.SetClientCallback("OnLoadingStateChange", OnLoadingStateChange)
    browser.SetClientCallback("DoClose", DoClose)
    cef.MessageLoop()
    browser = None

    cef.Shutdown()

    if not urlfound:
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
