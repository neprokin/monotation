//
//  MeditationFormView.swift
//  monotation
//
//  Form for saving meditation details
//

import SwiftUI

struct MeditationFormView: View {
    @StateObject private var viewModel: MeditationFormViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(startTime: Date, endTime: Date, defaultPose: MeditationPose = .lotus) {
        _viewModel = StateObject(wrappedValue: MeditationFormViewModel(
            startTime: startTime,
            endTime: endTime,
            defaultPose: defaultPose
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Session info (readonly)
                sessionInfoSection
                
                // Pose picker
                poseSection
                
                // Place picker
                placeSection
                
                // Note field
                noteSection
            }
            .navigationTitle("Сохранить медитацию")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        Task {
                            let success = await viewModel.saveMeditation()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .alert("Ошибка", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Неизвестная ошибка")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }
    
    // MARK: - Session Info Section
    
    private var sessionInfoSection: some View {
        Section("Информация о сессии") {
            LabeledContent("Начало", value: viewModel.formattedStartTime)
            LabeledContent("Окончание", value: viewModel.formattedEndTime)
            LabeledContent("Длительность", value: viewModel.formattedDuration)
        }
    }
    
    // MARK: - Pose Section
    
    private var poseSection: some View {
        Section("Поза") {
            Picker("Поза", selection: $viewModel.selectedPose) {
                ForEach(MeditationPose.allCases) { pose in
                    Label(pose.displayName, systemImage: pose.iconName)
                        .tag(pose)
                }
            }
            .pickerStyle(.inline)
        }
    }
    
    // MARK: - Place Section
    
    private var placeSection: some View {
        Section("Место") {
            // Predefined places
            ForEach(MeditationPlace.predefined, id: \.self) { place in
                Button {
                    viewModel.selectedPlace = place
                } label: {
                    HStack {
                        Label(place.displayName, systemImage: place.iconName)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if viewModel.selectedPlace == place {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            
            // Custom place option
            Button {
                viewModel.selectedPlace = .custom("")
            } label: {
                HStack {
                    Label("Другое место", systemImage: "location.fill")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if case .custom = viewModel.selectedPlace {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // Custom place text field (shown when custom is selected)
            if case .custom = viewModel.selectedPlace {
                TextField("Укажите место", text: $viewModel.customPlace)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }
    
    // MARK: - Note Section
    
    private var noteSection: some View {
        Section {
            TextField("Заметка (опционально)", text: $viewModel.note, axis: .vertical)
                .lineLimit(5...10)
                .textInputAutocapitalization(.sentences)
        } header: {
            Text("Заметка")
        } footer: {
            HStack {
                Text(viewModel.noteCharacterCount)
                    .foregroundStyle(viewModel.isNoteValid ? Color.secondary : Color.red)
                
                Spacer()
                
                if !viewModel.isNoteValid {
                    Text("Слишком длинная заметка")
                        .foregroundStyle(Color.red)
                }
            }
            .font(.caption)
        }
    }
}

// MARK: - Preview
#Preview {
    MeditationFormView(
        startTime: Date().addingTimeInterval(-600),
        endTime: Date()
    )
}

