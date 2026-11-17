import XCTest

@MainActor
final class RickVerseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
    }

    func testBrowseListToDetailToEpisodeAndBack() throws {
        app.launch()

        let rick = row("Rick Sanchez")
        XCTAssertTrue(rick.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Data source: REST"].exists)
        rick.tap()

        XCTAssertTrue(app.staticTexts["Last seen, Citadel of Ricks"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Episodes (6)"].exists)
        let pilot = episodeRow("Pilot")
        XCTAssertTrue(scrollUntilExists(pilot), "episode rows are below the fold, and List builds rows lazily")
        pilot.tap()

        XCTAssertTrue(app.staticTexts["Characters (7)"].waitForExistence(timeout: 5))
        let morty = app.buttons.containing(.staticText, identifier: "Morty Smith").firstMatch
        XCTAssertTrue(morty.exists)
        morty.tap()
        XCTAssertTrue(app.navigationBars["Morty Smith"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Characters"].tap()
        XCTAssertTrue(app.navigationBars["Characters"].waitForExistence(timeout: 5))
    }

    func testSearchFiltersTheList() throws {
        app.launch()
        XCTAssertTrue(row("Rick Sanchez").waitForExistence(timeout: 5))

        let search = app.searchFields["Search characters"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Morty")

        let rickGone = NSPredicate(format: "exists == false")
        expectation(for: rickGone, evaluatedWith: row("Rick Sanchez"))
        waitForExpectations(timeout: 5)
        XCTAssertTrue(row("Morty Smith").exists)
    }

    func testOfflineEveryScreenShowsErrorAndRetry() throws {
        app.launchArguments += ["-uiTestingScenario", "offline"]
        app.launch()

        assertOffline("Characters")
        app.buttons["Retry"].tap()
        assertOffline("Characters, after Retry")

        app.tabBars.buttons["Episodes"].tap()
        assertOffline("Episodes")

        open("rickverse://character/1")
        assertOffline("Character detail")

        open("rickverse://episode/1")
        assertOffline("Episode detail")
    }

    func testEmptyStatesOnEveryScreen() throws {
        app.launchArguments += ["-uiTestingScenario", "empty"]
        app.launch()

        XCTAssertTrue(app.staticTexts["No characters"].waitForExistence(timeout: 5), "Characters: no empty state")

        app.tabBars.buttons["Episodes"].tap()
        XCTAssertTrue(app.staticTexts["No episodes"].waitForExistence(timeout: 5), "Episodes: no empty state")

        open("rickverse://character/1")
        XCTAssertTrue(app.staticTexts["Rick Sanchez"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            scrollUntilExists(app.staticTexts["No episodes"]), "Character detail: no empty episodes state")

        open("rickverse://episode/1")
        XCTAssertTrue(app.staticTexts["No characters"].waitForExistence(timeout: 5), "Episode detail: no empty cast state")
    }

    func testSettingsLinksAndTabRetapPopsToRoot() throws {
        app.launch()
        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(scrollUntilExists(app.buttons["Source code on GitHub"]))
        XCTAssertTrue(app.buttons["Data: rickandmortyapi.com"].exists)

        app.swipeDown()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Network log'")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Network log"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "re-tapping the tab should pop to Settings")
    }

    private func assertOffline(_ screen: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts["You're offline"].waitForExistence(timeout: 5), "\(screen): no offline state", file: file, line: line)
        XCTAssertTrue(app.buttons["Retry"].exists, "\(screen): no Retry button", file: file, line: line)
    }

    private func open(_ link: String) {
        app.open(URL(string: link)!)
        let confirm = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Open"]
        if confirm.waitForExistence(timeout: 2) {
            confirm.tap()
        }
    }

    private func scrollUntilExists(_ element: XCUIElement, maxSwipes: Int = 5) -> Bool {
        for _ in 0..<maxSwipes {
            if element.waitForExistence(timeout: 1), element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists
    }

    private func row(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    private func episodeRow(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", ", \(name)")).firstMatch
    }
}
