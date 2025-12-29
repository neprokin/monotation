//
//  HistoryView.swift
//  monotation
//
//  Meditation history screen with grouped list
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeditation: Meditation?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $selectedMeditation) { meditation in
                MeditationDetailView(meditation: meditation)
            }
        }
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        List {
            // Summary section (if not empty)
            if !viewModel.isEmpty {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Всего медитаций")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(viewModel.totalMeditations)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Общее время")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(viewModel.formattedTotalDuration)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Grouped meditations by date
            ForEach(viewModel.sectionKeys, id: \.self) { sectionKey in
                Section {
                    if let meditations = viewModel.groupedMeditations[sectionKey] {
                        ForEach(meditations) { meditation in
                            MeditationCard(meditation: meditation)
                                .onTapGesture {
                                    selectedMeditation = meditation
                                }
                        }
                    }
                } header: {
                    Text(sectionKey)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("История пуста")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text("Начните медитацию, чтобы\nпоявились записи")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Meditation Detail View

struct MeditationDetailView: View {
    let meditation: Meditation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with icon
                    HStack {
                        Image(systemName: meditation.pose.iconName)
                            .font(.system(size: 48))
                            .foregroundStyle(.primary)
                            .frame(width: 80, height: 80)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meditation.pose.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 4) {
                                Image(systemName: meditation.place.iconName)
                                    .font(.caption)
                                Text(meditation.place.displayName)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Session info
                    VStack(alignment: .leading, spacing: 16) {
                        LabeledContent("Начало") {
                            Text(meditation.startTime.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                        
                        LabeledContent("Окончание") {
                            Text(meditation.endTime.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                        
                        LabeledContent("Длительность") {
                            Text(meditation.formattedDuration)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.body)
                    
                    // Note (if exists)
                    if let note = meditation.note, !note.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Заметка")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Медитация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
}

