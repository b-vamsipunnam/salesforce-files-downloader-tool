import os

from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from selenium.webdriver.chrome.options import Options


_TRUTHY_ENVIRONMENT_VALUES = {"1", "true", "yes"}


def _environment_flag_enabled(name: str) -> bool:
    """Return whether an environment variable contains a supported truthy value."""
    return os.getenv(name, "").strip().lower() in _TRUTHY_ENVIRONMENT_VALUES


def _configure_chrome_options(
    download_directory: str,
    org_domain: str | None,
    headless: bool,
) -> Options:
    """Build the Chrome options shared by native and container execution."""
    options = Options()

    if headless:
        options.add_argument("--headless=new")

    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--log-level=3")
    options.add_argument("--disable-extensions")
    options.add_argument("--disable-features=InsecureDownloadWarnings")
    options.add_argument("--safebrowsing-disable-download-protection")
    options.add_argument("--allow-running-insecure-content")
    options.add_argument("--disable-dev-shm-usage")

    if _environment_flag_enabled("CHROME_NO_SANDBOX"):
        options.add_argument("--no-sandbox")
        logger.warn(
            "Chrome sandbox has been disabled through CHROME_NO_SANDBOX. "
            "Use this only when the container runtime does not support "
            "Chrome's normal Linux sandbox."
        )

    if org_domain:
        options.add_argument(
            "--unsafely-treat-insecure-origin-as-secure="
            f"https://{org_domain}.file.force.com"
        )

    options.add_experimental_option(
        "prefs",
        {
            "download.default_directory": download_directory,
            "download.prompt_for_download": False,
            "download.directory_upgrade": True,
            "plugins.always_open_pdf_externally": True,
            "safebrowsing.enabled": True,
            "profile.default_content_settings.popups": 0,
        },
    )
    return options


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
        options = _configure_chrome_options(
            str(download_directory),
            str(org_domain) if org_domain else None,
            bool(headless),
        )

        selib.open_browser(
            url=login_url,
            browser="chrome",
            options=options,
        )

        if not headless:
            selib.maximize_browser_window()
