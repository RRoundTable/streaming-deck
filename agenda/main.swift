// 캘린더 읽기 앱 (adr/006, adr/009). macOS 캘린더에서 읽어 파일에 쓴다. 판단은 bin/sd agenda가 한다.
//   "시작 epoch<TAB>끝 epoch<TAB>제목"   지금부터 오늘 끝까지의 일정
//   "holiday<TAB>YYYY-MM-DD<TAB>이름"   오늘부터 HOLIDAY_DAYS일 동안의 공휴일 (이름에 "휴일"·"Holiday"가 든 캘린더의 종일 일정)
//   "! 문구"                            읽지 못함 (권한 없음, 공휴일 캘린더 없음)
// 읽을 때마다 macOS에 원격(Google 등) 동기화를 요청한다. 동기화는 몇 초 걸리므로 그 결과는 다음에 읽을 때 보인다.
// [기다릴 초]를 주면 그만큼 기다렸다 읽어서 이번에 바로 보인다(캘린더 키를 눌렀을 때).
// 앱 번들(SDAgenda.app)로 실행해야 캘린더 권한을 자기 이름으로 받는다: open -g SDAgenda.app --args <출력 파일> [기다릴 초]
import EventKit
import Foundation

guard CommandLine.arguments.count > 1 else {
  FileHandle.standardError.write("사용법: sd-agenda <출력 파일> [기다릴 초]\n".data(using: .utf8)!)
  exit(2)
}
let out = CommandLine.arguments[1]
let syncWait = CommandLine.arguments.count > 2 ? TimeInterval(CommandLine.arguments[2]) ?? 0 : 0

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

store.refreshSourcesIfNecessary()
if syncWait > 0 { Thread.sleep(forTimeInterval: syncWait) }

let HOLIDAY_DAYS = 14  // 다음 근무일을 찾는 범위. 이보다 긴 연휴는 없다

let now = Date()
let calendar = Calendar.current
let today = calendar.startOfDay(for: now)
let midnight = calendar.date(byAdding: .day, value: 1, to: today)!
let holidayCalendars = store.calendars(for: .event).filter {
  $0.title.contains("휴일") || $0.title.localizedCaseInsensitiveContains("holiday")
}
guard !holidayCalendars.isEmpty else {
  write("! 공휴일 캘린더 없음\n")
  exit(1)
}
let day = DateFormatter()
day.dateFormat = "yyyy-MM-dd"
let holidays = store.events(matching: store.predicateForEvents(
  withStart: today, end: calendar.date(byAdding: .day, value: HOLIDAY_DAYS, to: today)!, calendars: holidayCalendars))
  .filter { $0.isAllDay }
  .flatMap { event -> [String] in  // 여러 날짜에 걸친 일정은 날짜마다 한 줄. 종일 일정의 끝은 마지막 날 다음 자정이다
    var lines: [String] = []
    var d = calendar.startOfDay(for: event.startDate)
    while d < event.endDate {
      lines.append("holiday\t\(day.string(from: d))\t\(event.title ?? "")")
      d = calendar.date(byAdding: .day, value: 1, to: d)!
    }
    return lines
  }
let events = store.events(matching: store.predicateForEvents(withStart: now, end: midnight, calendars: nil))
  .filter { !$0.isAllDay && $0.status != .canceled }
  .filter { !($0.attendees ?? []).contains { $0.isCurrentUser && $0.participantStatus == .declined } }
  .sorted { $0.startDate < $1.startDate }
  .map { event -> String in
    let title = (event.title ?? "").components(separatedBy: .newlines).joined(separator: " ")
      .replacingOccurrences(of: "\t", with: " ")
    return "\(Int(event.startDate.timeIntervalSince1970))\t\(Int(event.endDate.timeIntervalSince1970))\t\(title)"
  }
write((events + holidays).map { $0 + "\n" }.joined())
