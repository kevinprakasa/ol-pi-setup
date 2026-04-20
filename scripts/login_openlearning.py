"""
Playwright script to log in to http://openlearning.test as a learner,
navigate to the course page, and click the first Start exam button.
"""

from playwright.sync_api import sync_playwright
import time


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=300)
        context = browser.new_context()
        page = context.new_page()

        # ── Login ────────────────────────────────────────────────────────────
        print("→ Navigating to http://openlearning.test …")
        page.goto("http://openlearning.test", wait_until="load")

        print("→ Clicking the LOGIN button …")
        page.get_by_role("button", name="LOGIN").click()
        page.wait_for_selector("input[type='password']", state="visible", timeout=10_000)

        print("→ Filling in credentials …")
        page.get_by_label("Email or profile name").fill("learner1@test.com")
        page.get_by_label("Password").fill("Passw0rd!")

        print("→ Submitting …")
        page.locator("button[type='submit'].login-signup-submit-button").click()
        page.wait_for_load_state("load", timeout=15_000)
        print(f"✅  Logged in! URL: {page.url}")
        page.screenshot(path="/tmp/s1_loggedin.png")

        # ── Navigate to course page ──────────────────────────────────────────────
        # page.goto() doesn't work on this SPA (ERR_ABORTED) — use JS navigation instead
        print("→ Navigating to course homepage …")
        page.evaluate("window.location.href = 'http://openlearning.test/institutiontestpath/courses/second-course/homepage/'")
        page.wait_for_url("**/second-course/homepage/**", timeout=20_000)
        page.wait_for_load_state("domcontentloaded", timeout=15_000)
        time.sleep(3)
        print(f"✅  Course page loaded: {page.url}")
        page.screenshot(path="/tmp/s2_coursepage.png")

        # ── Click Start exam ─────────────────────────────────────────────────
        print("→ Looking for 'Start exam' button …")
        start_btn = page.locator("button", has_text="Start exam").first
        start_btn.wait_for(state="visible", timeout=15_000)
        print("→ Clicking 'Start exam' …")
        start_btn.click()
        page.wait_for_load_state("domcontentloaded", timeout=15_000)
        time.sleep(2)
        print(f"✅  Clicked! URL: {page.url}")
        page.screenshot(path="/tmp/s3_examstarted.png")

        # ── Keep browser open ────────────────────────────────────────────────
        print("\nBrowser is open. Close this terminal to exit.")
        time.sleep(3600)

        context.close()
        browser.close()


if __name__ == "__main__":
    main()
