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
                
                // Location section
                locationSection
                
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
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        Section("Место") {
            if viewModel.isLocationLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Определение местоположения...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.latitude != nil && viewModel.longitude != nil {
                // Показываем адрес и позволяем редактировать
                VStack(alignment: .leading, spacing: 8) {
                    Text("Адрес")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Укажите адрес (например, ул. Тверская, 1)", text: $viewModel.editableLocationName, axis: .vertical)
                        .textInputAutocapitalization(.words)
                        .lineLimit(2...4)
                }
            } else {
                HStack {
                    Image(systemName: "location.slash")
                        .foregroundStyle(.secondary)
                    Text("Местоположение недоступно")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Button to retry location
            if !viewModel.isLocationLoading {
                Button {
                    Task {
                        await viewModel.requestLocation()
                    }
                } label: {
                    Label("Обновить местоположение", systemImage: "arrow.clockwise")
                }
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

