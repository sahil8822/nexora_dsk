import Foundation
import BackgroundTasks

class HardwareTaskManager {
    func scheduleBackgroundTask(taskId: String, intervalSeconds: Int) -> Bool {
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: taskId)
            request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(intervalSeconds))
            
            do {
                try BGTaskScheduler.shared.submit(request)
                return true
            } catch {
                return false
            }
        }
        return false
    }
}
