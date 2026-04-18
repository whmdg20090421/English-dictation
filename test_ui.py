from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    try:
        page.goto('http://localhost:8081', timeout=10000)
        page.wait_for_load_state('networkidle')
        print("Page loaded successfully.")
        
        # Take a screenshot to inspect
        page.screenshot(path='/workspace/ui_snapshot.png')
        
        # Dump some text content to see if it rendered
        print("Page text content:", page.locator('body').inner_text()[:500])
        
    except Exception as e:
        print(f"Failed to load or test UI: {e}")
    finally:
        browser.close()