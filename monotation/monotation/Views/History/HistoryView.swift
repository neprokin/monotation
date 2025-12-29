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

// MARK: - Preview
#Preview {
    HistoryView()
}

