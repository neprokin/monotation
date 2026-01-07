//
//  LogViewerView.swift
//  monotation Watch App
//
//  View to display and copy debug logs
//

import SwiftUI

struct LogViewerView: View {
    @State private var logContent: String = "Loading..."
    @State private var showingCopyAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Debug Logs")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Text(logContent)
                    .font(.system(size: 10, design: .monospaced))
                    #if !os(watchOS)
                    .textSelection(.enabled)
                    #endif
            }
            .padding()
        }
        .navigationTitle("Logs")
        .onAppear {
            loadLogs()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Copy") {
                    #if os(watchOS)
                    // watchOS doesn't have UIPasteboard, logs are visible in text selection
                    showingCopyAlert = true
                    #else
                    UIPasteboard.general.string = logContent
                    showingCopyAlert = true
                    #endif
                }
            }
        }
        .alert("Copied!", isPresented: $showingCopyAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func loadLogs() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logContent = "Error: Could not access Documents directory"
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent("countdown_debug.log")
        
        if let content = try? String(contentsOf: logFileURL, encoding: .utf8) {
            // Show last 1000 lines
            let lines = content.components(separatedBy: .newlines)
            let recentLines = lines.suffix(1000)
            logContent = recentLines.joined(separator: "\n")
            
            if logContent.isEmpty {
                logContent = "No logs yet. Start countdown to generate logs."
            }
        } else {
            logContent = "No log file found. Start countdown to generate logs."
        }
    }
}

