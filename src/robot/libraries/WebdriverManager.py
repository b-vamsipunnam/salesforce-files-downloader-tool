from robot.libraries.BuiltIn import BuiltIn
from selenium.webdriver.chrome.options import Options


class WebdriverManager:
    def configure_chrome_browser(
        self,
        download_directory,
        login_url,
        org_domain=None,
        headless=True,
    ):
        """
        Configure and open Chrome with Salesforce-specific download settings.

        Selenium Manager automatically resolves a ChromeDriver compatible
        with the installed Chrome browser.
        """
        selib = BuiltIn().get_library_instance("SeleniumLibrary")
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
                "--unsafely-treat-insecure-origin-as-secure="
                f"https://{org_domain}.file.force.com"
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

        selib.open_browser(
            url=login_url,
            browser="chrome",
            options=options,
        )

        selib.maximize_browser_window()