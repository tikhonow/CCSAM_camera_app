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
    
}

// Расширение для удобства работы с элементами UI
extension XCUIElement {
    func or(_ element: XCUIElement) -> XCUIElement {
        return self.exists ? self : element
    }
}
