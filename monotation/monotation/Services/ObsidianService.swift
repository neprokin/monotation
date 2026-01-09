//
//  ObsidianService.swift
//  monotation
//
//  Service for syncing meditations with Obsidian sessions.md file
//

import Foundation

@MainActor
class ObsidianService {
    static let shared = ObsidianService()
    
    private init() {}
    
    // MARK: - File URL
    
    /// Get the URL to sessions.md file from settings
    private func getSessionsFileURL() -> URL? {
        let settings = AppSettings.shared
        return settings.obsidianSessionsURL
    }
    
    // MARK: - Read File
    
    /// Read existing meditations from sessions.md file
    /// - Parameter accessResource: Whether to start accessing security-scoped resource (default: true)
    func readExistingMeditations(accessResource: Bool = true) async throws -> Set<String> {
        guard let fileURL = getSessionsFileURL() else {
            throw ObsidianError.filePathNotSet
        }
        
        // Start accessing security-scoped resource for iCloud files
        var shouldStopAccessing = false
        if accessResource {
            if fileURL.startAccessingSecurityScopedResource() {
                shouldStopAccessing = true
            }
        }
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // File doesn't exist yet, return empty set
            return []
        }
        
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            throw ObsidianError.fileReadFailed
        }
        
        // Parse file to extract existing meditation keys (date + time)
        return parseExistingMeditations(from: content)
    }
    
    /// Parse existing meditations from markdown content
    /// Returns set of keys in format "YYYY-MM-DD HH:MM"
    private func parseExistingMeditations(from content: String) -> Set<String> {
        var existingKeys = Set<String>()
        let lines = content.components(separatedBy: .newlines)
        
        var currentYear: Int?
        var currentMonth: Int?
        var currentDay: Int?
        
        for line in lines {
            // Parse month header: ## Октябрь 2025
            if line.hasPrefix("## ") {
                let monthPattern = #"## (\w+)\s+(\d{4})"#
                if let regex = try? NSRegularExpression(pattern: monthPattern),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                    if let yearRange = Range(match.range(at: 2), in: line),
                       let monthRange = Range(match.range(at: 1), in: line) {
                        currentYear = Int(line[yearRange])
                        currentMonth = monthNameToNumber(String(line[monthRange]))
                    }
                }
            }
            
            // Parse day header: ### 1 октября or ### **15 ноября 2025**
            if line.hasPrefix("### ") {
                // Try format: ### **15 ноября 2025**
                let dayPattern1 = #"### \*\*(\d{1,2})\s+(\w+)\s+(\d{4})\*\*"#
                if let regex = try? NSRegularExpression(pattern: dayPattern1),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                    if let dayRange = Range(match.range(at: 1), in: line),
                       let monthRange = Range(match.range(at: 2), in: line),
                       let yearRange = Range(match.range(at: 3), in: line) {
                        currentDay = Int(line[dayRange])
                        currentMonth = monthNameToNumber(String(line[monthRange]))
                        currentYear = Int(line[yearRange])
                    }
                } else {
                    // Try format: ### 1 октября
                    let dayPattern2 = #"### (\d{1,2})\s+(\w+)"#
                    if let regex = try? NSRegularExpression(pattern: dayPattern2),
                       let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                        if let dayRange = Range(match.range(at: 1), in: line) {
                            currentDay = Int(line[dayRange])
                            // Month and year from previous month header
                        }
                    }
                }
            }
            
            // Parse time entry: - **22:23** — 15 минут
            if line.contains("**") && line.contains("—") {
                let timePattern = #"- \*\*(\d{1,2}):(\d{2})\*\* —"#
                if let regex = try? NSRegularExpression(pattern: timePattern),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let hourRange = Range(match.range(at: 1), in: line),
                   let minuteRange = Range(match.range(at: 2), in: line),
                   let year = currentYear,
                   let month = currentMonth,
                   let day = currentDay {
                    let hour = Int(line[hourRange]) ?? 0
                    let minute = Int(line[minuteRange]) ?? 0
                    let key = String(format: "%04d-%02d-%02d %02d:%02d", year, month, day, hour, minute)
                    existingKeys.insert(key)
                }
            }
        }
        
        return existingKeys
    }
    
    private func monthNameToNumber(_ month: String) -> Int {
        let months = ["январь": 1, "февраль": 2, "март": 3, "апрель": 4, "май": 5, "июнь": 6,
                     "июль": 7, "август": 8, "сентябрь": 9, "октябрь": 10, "ноябрь": 11, "декабрь": 12,
                     "января": 1, "февраля": 2, "марта": 3, "апреля": 4, "мая": 5, "июня": 6,
                     "июля": 7, "августа": 8, "сентября": 9, "октября": 10, "ноября": 11, "декабря": 12]
        return months[month.lowercased()] ?? 1
    }
    
    // MARK: - Write Meditation
    
    /// Add meditation to sessions.md file
    func addMeditation(_ meditation: Meditation) async throws {
        guard let fileURL = getSessionsFileURL() else {
            throw ObsidianError.filePathNotSet
        }
        
        // Start accessing security-scoped resource for iCloud files
        let hasAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Check if meditation already exists (deduplication)
        // Don't access resource again since we already have access
        let existingKeys = try await readExistingMeditations(accessResource: false)
        let meditationKey = meditation.obsidianKey
        if existingKeys.contains(meditationKey) {
            return // Already synced
        }
        
        // Ensure directory exists
        let fileManager = FileManager.default
        let directoryPath = fileURL.deletingLastPathComponent()
        
        var isDirectory: ObjCBool = false
        let directoryExists = fileManager.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory)
        
        if !directoryExists || !isDirectory.boolValue {
            do {
                try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw ObsidianError.fileWriteFailed(error)
            }
        }
        
        // Read current file content
        var content = ""
        
        if fileManager.fileExists(atPath: fileURL.path) {
            content = try String(contentsOf: fileURL, encoding: .utf8)
        } else {
            // Create new file with header
            content = "# Сессии медитации\n\n"
        }
        
        // Format meditation entry
        let entry = meditation.obsidianFormat
        
        // Find or create the appropriate month and day sections
        let updatedContent = insertMeditationEntry(entry, for: meditation, into: content)
        
        // Write back to file
        guard let data = updatedContent.data(using: .utf8) else {
            throw ObsidianError.fileWriteFailed(NSError(domain: "ObsidianService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode content as UTF-8"]))
        }
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Insert meditation entry into the correct location in markdown content
    private func insertMeditationEntry(_ entry: String, for meditation: Meditation, into content: String) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: meditation.startTime)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            // Fallback: append to end
            return content + "\n" + entry
        }
        
        let monthName = monthNumberToName(month)
        let monthNameGenitive = monthNumberToNameGenitive(month)
        let monthHeader = "## \(monthName) \(year)"
        let dayHeaderPattern = "### \(day) \(monthNameGenitive)"
        let dayHeaderPatternBold = "### **\(day) \(monthNameGenitive) \(year)**"
        
        var lines = content.components(separatedBy: .newlines)
        var insertIndex: Int?
        
        // Find the correct insertion point
        var currentMonthIndex: Int?
        var currentDayIndex: Int?
        
        for (index, line) in lines.enumerated() {
            // Find month section
            if line == monthHeader {
                currentMonthIndex = index
            }
            
            // Find day section (within current month)
            if let monthIdx = currentMonthIndex, index > monthIdx {
                if line == dayHeaderPattern || line == dayHeaderPatternBold {
                    currentDayIndex = index
                }
                
                // Stop if we hit next month
                if line.hasPrefix("## ") && line != monthHeader {
                    break
                }
            }
        }
        
        // Determine insertion point
        if let dayIdx = currentDayIndex {
            // Day exists - find end of entries for this day
            var entryEndIndex = dayIdx + 1
            for i in (dayIdx + 1)..<lines.count {
                let line = lines[i]
                // Stop if we hit next day or month
                if line.hasPrefix("###") || line.hasPrefix("##") {
                    entryEndIndex = i
                    break
                }
                // Count this as part of day entries
                entryEndIndex = i + 1
            }
            insertIndex = entryEndIndex
        } else if let monthIdx = currentMonthIndex {
            // Month exists but day doesn't - insert day header and entry
            var nextMonthIndex = lines.count
            for i in (monthIdx + 1)..<lines.count {
                if lines[i].hasPrefix("## ") {
                    nextMonthIndex = i
                    break
                }
            }
            // Insert day header and entry before next month
            lines.insert(dayHeaderPattern, at: nextMonthIndex)
            lines.insert(entry, at: nextMonthIndex + 1)
            return lines.joined(separator: "\n")
        } else {
            // Month doesn't exist - append at end
            lines.append("")
            lines.append(monthHeader)
            lines.append("")
            lines.append(dayHeaderPattern)
            lines.append(entry)
            return lines.joined(separator: "\n")
        }
        
        // Insert entry at determined index
        if let idx = insertIndex {
            lines.insert(entry, at: idx)
            return lines.joined(separator: "\n")
        }
        
        // Fallback: append to end
        return content + "\n" + entry
    }
    
    private func monthNumberToName(_ month: Int) -> String {
        let months = [1: "Январь", 2: "Февраль", 3: "Март", 4: "Апрель", 5: "Май", 6: "Июнь",
                     7: "Июль", 8: "Август", 9: "Сентябрь", 10: "Октябрь", 11: "Ноябрь", 12: "Декабрь"]
        return months[month] ?? "Январь"
    }
    
    private func monthNumberToNameGenitive(_ month: Int) -> String {
        let months = [1: "января", 2: "февраля", 3: "марта", 4: "апреля", 5: "мая", 6: "июня",
                     7: "июля", 8: "августа", 9: "сентября", 10: "октября", 11: "ноября", 12: "декабря"]
        return months[month] ?? "января"
    }
    
    // MARK: - Sync Status
    
    /// Check if meditation is synced to Obsidian
    func isMeditationSynced(_ meditation: Meditation) async -> Bool {
        do {
            let existingKeys = try await readExistingMeditations()
            return existingKeys.contains(meditation.obsidianKey)
        } catch {
            return false
        }
    }
    
}

// MARK: - Obsidian Errors

enum ObsidianError: LocalizedError {
    case filePathNotSet
    case fileReadFailed
    case fileWriteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .filePathNotSet:
            return "Путь к файлу sessions.md не настроен"
        case .fileReadFailed:
            return "Не удалось прочитать файл sessions.md"
        case .fileWriteFailed(let error):
            return "Не удалось записать в файл sessions.md: \(error.localizedDescription)"
        }
    }
}
