//
//  PowerScheduleApp.swift
//  PowerScheduleIos
//
//  Created by Taras Buhra on 28.11.2025.
//
//
import SwiftUI
import BackgroundTasks
import UserNotifications

// MARK: - Main App
@main
struct PowerScheduleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        Task {
            await NotificationService.shared.requestAuthorization()
        }
        
        registerBackgroundTasks()
        
        return true
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.powerschedule.refresh",
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        let operation = BackgroundUpdateOperation()
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        queue.addOperation(operation)
        
        scheduleAppRefresh()
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.powerschedule.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 хвилин
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}

// MARK: - Notification Center Delegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - Background Update Operation
class BackgroundUpdateOperation: Operation {
    override func main() {
        guard !isCancelled else { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            let queues = StorageService.shared.loadQueues()
            let minutesBefore = StorageService.shared.loadNotificationMinutes()
            
            for queue in queues where queue.isAutoUpdateEnabled {
                do {
                    let scheduleData = try await APIService.shared.fetchSchedule(for: queue.queueNumber)
                    
                    if let jsonData = try? JSONEncoder().encode(scheduleData),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        
                        let savedJSON = StorageService.shared.loadScheduleJSON(for: queue.id)
                        
                        let hasChanges = savedJSON != nil && savedJSON != jsonString
                        
                        if hasChanges {
                            StorageService.shared.saveScheduleJSON(jsonString, for: queue.id)
                            await NotificationService.shared.showScheduleUpdateNotification(queueName: queue.name)
                            
                            if queue.isNotificationsEnabled {
                                await NotificationService.shared.scheduleShutdownNotifications(
                                    shutdowns: scheduleData.shutdowns,
                                    queueName: queue.name,
                                    minutesBefore: minutesBefore
                                )
                            }
                        } else if savedJSON == nil {
                            StorageService.shared.saveScheduleJSON(jsonString, for: queue.id)
                        }
                    }
                } catch {
                    print("Error updating queue \(queue.name): \(error)")
                }
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
    }
}
