# Library/BrowserConfig.py

from selenium.webdriver.chrome.options import Options
from robot.libraries.BuiltIn import BuiltIn
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service as ChromeService


class WebdriverManager:
    def configure_chrome_browser(self, download_directory, login_url, org_domain=None, headless=True):
        """
        Robot Framework keyword to configure and open Chrome browser with Salesforce-specific settings.

        This keyword:
        - Sets up ChromeOptions with headless mode and Salesforce file download preferences
        - Uses webdriver-manager to automatically download the correct ChromeDriver
        - Opens the browser via SeleniumLibrary

        Usage in Robot Framework:
            Configure Chrome Browser    ${download_dir}    ${login_url}    ${org_domain}

        Args:
            download_directory (str): Full path where files should be downloaded
            login_url (str): Salesforce login URL (e.g. https://login.salesforce.com)
            org_domain (str, optional): Your org's domain (e.g. mycompany) for insecure origin allowance
            headless (bool): Whether to run in headless mode (default: True)
        """
        selib = BuiltIn().get_library_instance('SeleniumLibrary')

        options = Options()

        if headless:
            options.add_argument("--headless=new")
        options.add_argument("--disable-gpu")
        options.add_argument("--log-level=3")
        options.add_argument("--disable-extensions")
        options.add_argument("--disable-features=InsecureDownloadWarnings")
        options.add_argument("--safebrowsing-disable-download-protection")
        options.add_argument("--allow-running-insecure-content")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        if org_domain:
            options.add_argument(
                f"--unsafely-treat-insecure-origin-as-secure=https://{org_domain}.file.force.com"
            )
        prefs = {
            "download.default_directory": download_directory,
            "download.prompt_for_download": False,
            "download.directory_upgrade": True,
            "plugins.always_open_pdf_externally": True,
            "safebrowsing.enabled": True,
            "profile.default_content_settings.popups": 0,
        }
        options.add_experimental_option("prefs", prefs)

        driver_path = ChromeDriverManager().install()
        service = ChromeService(executable_path=driver_path)
        selib.open_browser(
            url=login_url,
            browser="chrome",
            options=options,
            service=service
        )
        selib.maximize_browser_window()

        return options
