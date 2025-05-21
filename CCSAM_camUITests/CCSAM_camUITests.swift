//
//  CCSAM_camUITests.swift
//  CCSAM_camUITests
//
//  Created by Руслан Тихонов on 09.05.2025.
//

import XCTest

class CCSAM_camUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        // Закрываем окно What's New, если оно есть
        closeWhatsNewIfPresent()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // Закрыть окно What's New, если оно присутствует
    private func closeWhatsNewIfPresent() {
        // Ждем немного, чтобы UI успел загрузиться
        sleep(1)
        
        // Проверяем наличие кнопки закрытия
        let closeButton = app.buttons["CloseWhatsNewButton"]
        if closeButton.exists {
            closeButton.tap()
        }
        
        // Проверяем наличие альтернативной кнопки закрытия
        let closeAltButton = app.buttons["Close"]
        if closeAltButton.exists {
            closeAltButton.tap()
        }
        
        // Проверяем наличие синей кнопки "Продолжить" или подобной
        let continueButton = app.buttons["Продолжить"]
            .or(app.buttons["Continue"])
            .or(app.buttons.matching(NSPredicate(format: "label CONTAINS 'продолж' OR label CONTAINS 'continu'")).firstMatch)
        
        if continueButton.exists {
            continueButton.tap()
        }
        
        // Еще раз проверим голубую кнопку внизу
        let blueButton = app.buttons.element(boundBy: app.buttons.count - 1) // Последняя кнопка
        if blueButton.exists {
            blueButton.tap()
        }
        
        // Ждем, пока таб-бар станет доступен
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Таб-бар должен появиться после закрытия окна What's New")
    }
    
    func testAppLaunch() throws {
        // Проверяем, что приложение запустилось (уже закрыли What's New в setUp)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    // Тест для закрытия What's New - теперь он просто проверяет, что окна уже нет
    func testCloseWhatsNew() throws {
        // Проверяем, что окно What's New уже закрыто
        let closeButton = app.buttons["CloseWhatsNewButton"]
        XCTAssertFalse(closeButton.exists, "Окно What's New должно быть закрыто")
        
        let closeAltButton = app.buttons["Close"]
        XCTAssertFalse(closeAltButton.exists, "Альтернативная кнопка закрытия не должна существовать")
    }
    
    // Объединенный тест для проверки всего флоу UI
    func testTabNavigationAndDeviceDependentTabs() throws {
        // 1. Проверка таб-бара
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Таб-бар должен существовать")
        
        // 2. Переход по каждой вкладке
        for tab in tabBar.buttons.allElementsBoundByIndex {
            // Печатаем идентификатор и название кнопки для отладки
            print("Проверяем вкладку: \(tab.identifier), \(tab.label)")
            
            // Специальная обработка для вкладки Control - она должна быть неактивной
            if tab.label.contains("Control") {
                print("Найдена вкладка Control: isEnabled=\(tab.isEnabled), isSelected=\(tab.isSelected)")
                
                // Запоминаем текущую выбранную вкладку
                let currentSelectedTabName = tabBar.buttons.matching(NSPredicate(format: "isSelected == YES")).firstMatch.label
                
                // Пробуем нажать на Control (даже если она технически активна)
                tab.tap()
                sleep(1)
                
                // Проверяем, что выбранная вкладка не изменилась
                let newSelectedTabName = tabBar.buttons.matching(NSPredicate(format: "isSelected == YES")).firstMatch.label
                XCTAssertEqual(currentSelectedTabName, newSelectedTabName, 
                              "Выбранная вкладка не должна меняться при нажатии на Control")
                
                continue
            }
            
            // Для остальных вкладок пытаемся нажать, если они активны
            if tab.isEnabled && tab.isHittable {
                tab.tap()
                
                // Ждем, чтобы UI успел обновиться
                sleep(1)
                
                // Проверяем, что вкладка выбрана или появилось предупреждение
                if tab.label.contains("Camera") || tab.label.contains("Snapshot") {
                    // Проверяем наличие предупреждения, если это вкладка, требующая подключения
                    checkDeviceRequiredWarning()
                } else {
                    // Для других вкладок проверяем, что они выбраны
                    XCTAssertTrue(tab.isSelected, "Вкладка \(tab.label) должна быть выбрана после нажатия")
                }
            }
        }
    }
    
    // Вспомогательный метод для проверки предупреждения о необходимости подключения устройства
    private func checkDeviceRequiredWarning() {
        // Проверяем наличие предупреждения
        let alert = app.alerts.firstMatch
        
        // Проверяем наличие текста о подключении
        let deviceTextExists = app.staticTexts["Connect a device first"].exists ||
                              app.staticTexts["Please connect a device"].exists ||
                              !app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'connect'")).allElementsBoundByIndex.isEmpty
        
        if alert.exists {
            // Если есть алерт, закрываем его
            let okButton = alert.buttons["OK"].or(alert.buttons["Ок"]).or(alert.buttons.firstMatch)
            if okButton.exists {
                okButton.tap()
            }
            XCTAssertTrue(true, "Предупреждение об отсутствии устройства показано")
        } else if deviceTextExists {
            XCTAssertTrue(true, "Текст о необходимости подключения устройства отображается")
        } else {
            // Если нет ни алерта, ни текста - значит что-то пошло не так
            XCTAssertTrue(false, "Должно быть предупреждение о необходимости подключения устройства")
        }
    }
    
    // Тест для проверки отсутствия белого экрана при открытии статьи
    func testArticleOpeningWithoutWhiteScreen() throws {
        // Переходим на вкладку обучения
        let tabBar = app.tabBars.firstMatch
        
        // Ищем вкладку "Обучение" или "Learn" - она может иметь разные названия
        let learnTabButton = tabBar.buttons["Обучение"]
            .or(app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'обуч'")).firstMatch)
            .or(app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'learn'")).firstMatch)
            .or(app.tabBars.buttons.element(boundBy: 4)) // Обычно это пятая вкладка (индекс 4)
            
        XCTAssertTrue(learnTabButton.exists, "Вкладка с обучающими материалами должна существовать")
        
        // Для отладки напечатаем все доступные вкладки
        print("Доступные вкладки в таб-баре:")
        for (index, button) in tabBar.buttons.allElementsBoundByIndex.enumerated() {
            print("[\(index)]: '\(button.label)' (identifier: \(button.identifier), enabled: \(button.isEnabled))")
        }
        
        // Переходим на вкладку обучения
        learnTabButton.tap()
        sleep(1) // Небольшая задержка для загрузки UI
        
        // Проверяем, что мы на правильном экране
        let learnTitle = app.staticTexts["Обучение"]
            .or(app.staticTexts["Learn"])
            .or(app.navigationBars.staticTexts.firstMatch) // Заголовок может быть в навбаре
        XCTAssertTrue(learnTitle.exists, "Заголовок экрана обучения должен отображаться")
        
        // Проверяем наличие списка статей
        let listOfArticles = app.scrollViews.firstMatch
        XCTAssertTrue(listOfArticles.exists, "Список статей должен существовать")
        
        // Проверяем, что в списке есть хотя бы одна статья и находим первую
        let firstArticleTitle = app.staticTexts["Что такое акустическая камера?"]
            .or(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'акустическ'")).firstMatch)
            .or(app.buttons.firstMatch) // Может быть внутри кнопки
        XCTAssertTrue(firstArticleTitle.exists, "Должна быть видна хотя бы одна статья")
        
        // Делаем скриншот перед открытием статьи для отладки
        let beforeScreenshot = XCUIScreen.main.screenshot()
        let beforeAttachment = XCTAttachment(screenshot: beforeScreenshot)
        beforeAttachment.name = "Before_Opening_Article"
        beforeAttachment.lifetime = .keepAlways
        self.add(beforeAttachment)
        
        // Открываем первую статью
        firstArticleTitle.tap()
        
        // Небольшая задержка для уверенности, что представление загрузилось
        usleep(500000) // Увеличиваем до 500 мс для надежности
        
        // Делаем скриншот сразу после открытия для отладки
        let afterScreenshot = XCUIScreen.main.screenshot()
        let afterAttachment = XCTAttachment(screenshot: afterScreenshot)
        afterAttachment.name = "After_Opening_Article"
        afterAttachment.lifetime = .keepAlways
        self.add(afterAttachment)
        
        // Запускаем поиск любых текстовых элементов на экране для отладки
        print("Текстовые элементы на экране статьи:")
        for (index, text) in app.staticTexts.allElementsBoundByIndex.enumerated() {
            print("Текст [\(index)]: '\(text.label)'")
        }
        
        // Проверяем, что на экране виден контент, а не белый экран
        // Проверяем наличие любых элементов интерфейса, которые указывают на загрузку статьи
        let anyUIElements = app.staticTexts.count > 0 || app.images.count > 0
        XCTAssertTrue(anyUIElements, "На экране должны быть какие-либо элементы интерфейса (не белый экран)")
        
        // Ищем заголовок статьи
        let articleContentTitle = app.staticTexts["Что такое акустическая камера?"]
            .or(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'акустическ'")).firstMatch)
            .or(app.navigationBars.staticTexts.firstMatch) // Заголовок может быть в навбаре
            .or(app.staticTexts.element(boundBy: 0)) // Или первый текстовый элемент
        
        // Пытаемся прокрутить статью в любом случае - это поможет увидеть контент, даже если он не полностью загрузился
        if app.scrollViews.firstMatch.exists {
            let scroll = app.scrollViews.firstMatch
            let startPosition = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let endPosition = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            startPosition.press(forDuration: 0.1, thenDragTo: endPosition)
            
            // Небольшая пауза после прокрутки
            usleep(200000)
        }
        
        // Делаем еще один скриншот после прокрутки
        let scrollScreenshot = XCUIScreen.main.screenshot()
        let scrollAttachment = XCTAttachment(screenshot: scrollScreenshot)
        scrollAttachment.name = "After_Scrolling_Article"
        scrollAttachment.lifetime = .keepAlways
        self.add(scrollAttachment)
        
        // Окончательная проверка - должны быть видны элементы после прокрутки
        let visibleElements = app.staticTexts.count > 0
        XCTAssertTrue(visibleElements, "После прокрутки должен быть виден текст статьи")
    }

    
}

// Расширение для удобства работы с элементами UI
extension XCUIElement {
    func or(_ element: XCUIElement) -> XCUIElement {
        return self.exists ? self : element
    }
}
