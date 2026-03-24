"""
Adds functionality to Robot Framework SeleniumLibrary Browser Management.
E.g. from https://github.com/robotframework/SeleniumLibrary/blob/master/docs/extending/extending/InheritSeleniumLibrary.py
"""
import platform
import selenium
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities


class SalesforceSupport:

    def patch_salesforce_chrome(self):
        """
        Patches salesforce chrome browser by adding an extra option
        """
        if platform.system() == "Linux":
            old_init = selenium.webdriver.chrome.options.Options.__init__
            def new_init(self, *args, **kwargs):
                old_init(self, *args, **kwargs)
                self.add_argument("--no-sandbox")
            selenium.webdriver.chrome.options.Options.__init__ = new_init
