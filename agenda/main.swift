// 캘린더 읽기 앱 (adr/006). macOS 캘린더에서 지금부터 오늘 끝까지의 일정을 읽어
// "시작 epoch<TAB>끝 epoch<TAB>제목" 줄로 파일에 쓴다. 판단은 bin/sd agenda가 한다.
// 앱 번들(SDAgenda.app)로 실행해야 캘린더 권한을 자기 이름으로 받는다: open -g SDAgenda.app --args <출력 파일>
import EventKit
import Foundation

guard CommandLine.arguments.count > 1 else {
  FileHandle.standardError.write("사용법: sd-agenda <출력 파일>\n".data(using: .utf8)!)
  exit(2)
}
let out = CommandLine.arguments[1]

func write(_ text: String) {
  do {
    try text.write(toFile: out, atomically: true, encoding: .utf8)
  } catch {
    FileHandle.standardError.write("sd-agenda: \(out) 쓰기 실패: \(error)\n".data(using: .utf8)!)
    exit(1)
  }
}

let store = EKEventStore()
let asked = DispatchSemaphore(value: 0)
var granted = false
store.requestFullAccessToEvents { ok, _ in
  granted = ok
  asked.signal()
}
asked.wait()
guard granted else {
  write("! 캘린더 권한 없음\n")
  exit(1)
}

let now = Date()
let calendar = Calendar.current
let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
let lines = store.events(matching: store.predicateForEvents(withStart: now, end: midnight, calendars: nil))
  .filter { !$0.isAllDay && $0.status != .canceled }
  .filter { !($0.attendees ?? []).contains { $0.isCurrentUser && $0.participantStatus == .declined } }
  .sorted { $0.startDate < $1.startDate }
  .map { event -> String in
    let title = (event.title ?? "").components(separatedBy: .newlines).joined(separator: " ")
      .replacingOccurrences(of: "\t", with: " ")
    return "\(Int(event.startDate.timeIntervalSince1970))\t\(Int(event.endDate.timeIntervalSince1970))\t\(title)"
  }
write(lines.map { $0 + "\n" }.joined())
