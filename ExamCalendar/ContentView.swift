import SwiftUI

// 1. 시험 일정 데이터 구조체 (날짜 데이터 포함)
struct ExamEvent: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
    let date: Date
}

struct ContentView: View {
    // 앱 전원에서 공유할 일정 리스트와 현재 선택된 월 상태
    @State private var events: [ExamEvent] = []
    
    var body: some View {
        TabView {
            CalendarTabView(events: $events)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("달력")
                }
            SearchAndAddTabView(events: $events)
                .tabItem {
                    Image(systemName: "plus.magnifyingglass")
                    Text("검색/추가")
                }
            TimerTabView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("타이머")
                }
            ProfileTabView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("프로필")
                }
        }
        .tint(.blue)
    }
}

// --- 1. 커스텀 달력 화면 ---
struct CalendarTabView: View {
    @Binding var events: [ExamEvent]
    @State private var displayedMonth = Date() // 현재 보고 있는 년/월
    @State private var showingAddAlert = false // 일정 추가 화면 팝업 여부
    
    // 새 일정 입력용 상태값
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var selectedColorIndex = 0
    let colors: [Color] = [.blue, .purple, .orange, .pink, .green]
    
    let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                // 상단 년/월 이동 바
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text(monthString(from: displayedMonth))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    Spacer()
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 5)
                
                // 요일 헤더
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(day == "일" ? .red : .gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // 달력 날짜 그리드
                let days = fetchDaysInMonth(for: displayedMonth)
                
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(days, id: \.self) { date in
                        if let date = date {
                            CellView(date: date, events: events)
                        } else {
                            // 빈 칸
                            Color.clear
                                .frame(height: 80)
                        }
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
            }
            .navigationTitle("시험 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 우측 상단 '+' 버튼으로 홈화면에서 바로 일정 추가
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAlert = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
            }
            // 일정 추가 팝업창
            .sheet(isPresented: $showingAddAlert) {
                NavigationView {
                    Form {
                        Section(header: Text("시험 정보 입력")) {
                            TextField("시험 이름 (예: 정보처리기사)", text: $newTitle)
                            DatePicker("시험 날짜", selection: $newDate, displayedComponents: .date)
                            
                            // 색상 선택
                            HStack {
                                Text("블록 색상")
                                Spacer()
                                ForEach(0..<colors.count, id: \.self) { index in
                                    Circle()
                                        .fill(colors[index])
                                        .frame(width: 25, height: 25)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: selectedColorIndex == index ? 2 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColorIndex = index
                                        }
                                }
                            }
                        }
                    }
                    .navigationTitle("새 일정 추가")
                    .navigationBarItems(
                        leading: Button("취소") { showingAddAlert = false },
                        trailing: Button("추가") {
                            if !newTitle.isEmpty {
                                let newEvent = ExamEvent(title: newTitle, color: colors[selectedColorIndex], date: newDate)
                                events.append(newEvent)
                                newTitle = ""
                                showingAddAlert = false
                            }
                        }.fontWeight(.bold)
                    )
                }
            }
        }
    }
    
    // 월 변경 함수
    func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    // 날짜를 "2026년 9월" 형태로 변환
    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
    
    // 해당 월의 빈칸을 포함한 날짜 배열 생성 로직
    func fetchDaysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) // 1: 일요일 ~ 7: 토요일
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in range {
            if let specificDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(specificDate)
            }
        }
        return days
    }
}

// --- 달력의 네모 칸 하나 ---
struct CellView: View {
    let date: Date
    let events: [ExamEvent]
    
    var body: some View {
        let calendar = Calendar.current
        let dayNumber = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        
        // 해당 날짜에 맞는 일정 필터링
        let matchedEvents = events.filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(weekday == 1 ? .red : .primary)
                .padding(.leading, 5)
                .padding(.top, 5)
            
            ForEach(matchedEvents) { event in
                Text(event.title)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(event.color)
                    .cornerRadius(4)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 85)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(10)
    }
}

// --- 2. 검색 및 추가 화면 ---
struct SearchAndAddTabView: View {
    @Binding var events: [ExamEvent]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("이곳에서 공인 시험을 검색하고 간편하게 추가할 수 있습니다.")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            }
            .navigationTitle("시험 검색 및 추가")
        }
    }
}

// --- 3. 타이머 화면 ---
struct TimerTabView: View {
    var body: some View {
        NavigationView { Text("공부 시간 측정 화면").navigationTitle("타이머") }
    }
}

// --- 4. 프로필 화면 ---
struct ProfileTabView: View {
    var body: some View {
        NavigationView { Text("내 프로필 화면").navigationTitle("프로필") }
    }
}

#Preview {
    ContentView()
}
