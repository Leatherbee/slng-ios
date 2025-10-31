//
//  DictionaryView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import SwiftUI
import UIKit
import AVFoundation


struct DictionaryView: View {
    @State private var selectedIndex: Int = 0
    @State private var searchText: String = ""
    @StateObject private var viewModel = DictionaryViewModel()
    
    // Ambil semua slang, urut abjad
    let allSlangs: [SlangDataDummy] = Array(SlangDictionaryDummy.shared.slangs.values)
        .sorted { $0.slang.lowercased() < $1.slang.lowercased() }
    
    @Environment(PopupManager.self) private var popupManager
    @State private var scrollTarget: String? = nil
    @State private var currentIndexLetter: String? = nil
    private let indexWord = "abcdefghijklmnopqrstuvwxyz"
    @State private var dragActiveLetter: String? = nil
    
    // Filtered array
    var filteredSlangs: [SlangData] {
        viewModel.getFilteredSlangs()
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                
                // Wheel + Index letters
                HStack(alignment: .center) {
                    
                    // Wheel Picker
                    if !filteredSlangs.isEmpty {
                        LargeWheelPickerWithButton(
                            selection: $selectedIndex,
                            data: filteredSlangs.map { $0.slang }
                        ) {
                            // Set data ke PopupManager saat arrow di-tap
                            if let slangData = viewModel.getSlang(at: selectedIndex) {
                                popupManager.setSlangData(slangData)
                                popupManager.isPresented.toggle()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 600)
                    } else {
                        Text("No results")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: 600)
                    }
                    
                    VStack(spacing: 0) {
                        ForEach(Array(indexWord), id: \.self) { letter in
                            let stringLetter = String(letter)
                            let isActive = filteredSlangs.indices.contains(selectedIndex) &&
                            (filteredSlangs[selectedIndex].slang.lowercased().first == letter || dragActiveLetter == stringLetter)
                            
                            Text(stringLetter.uppercased())
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(isActive ? Color.btnTextPrimary : Color.txtSecondary)
                                .frame(width: 20, height: 18)
                                .background(
                                    Circle()
                                        .fill(isActive ? Color.txtPrimary : .clear)
                                )
                                .scaleEffect(dragActiveLetter == stringLetter ? 2.0 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: dragActiveLetter)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let y = value.location.y
                                let letterHeight: CGFloat = 21 + 4
                                let index = max(0, min(Int(y / letterHeight), indexWord.count - 1))
                                let letter = Array(indexWord)[index]
                                dragActiveLetter = String(letter)
                                
                                if let newIndex = filteredSlangs.firstIndex(where: { $0.slang.lowercased().first == letter }) {
                                    selectedIndex = newIndex
                                }
                            }
                            .onEnded { _ in
                                dragActiveLetter = nil
                            }
                    )
                    
                }
                .padding(0)
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 17)
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    
                    TextField("Search", text: $viewModel.searchText)
                        .autocapitalization(.none)
                        .padding()
                        .font(.caption)
                        .frame(height: 22)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                .padding(11)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.47, green: 0.47, blue: 0.5).opacity(0.16))
                .cornerRadius(100)
                
            }
            .padding()
        }
        .padding(.top, -20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
        .onChange(of: filteredSlangs) { oldValue, newValue in
            if selectedIndex >= newValue.count {
                selectedIndex = max(0, newValue.count - 1)
            }
        }
        
    }
    
    
    private func handleLetterTap(_ letter: Character) {
        guard !filteredSlangs.isEmpty else { return }
        let targetLetter = String(letter).uppercased()
        currentIndexLetter = String(letter)
        
        if let index = filteredSlangs.firstIndex(where: {
            $0.slang.uppercased().hasPrefix(targetLetter)
        }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = index
            }
        }
    }
}

// MARK: - LargeWheelPickerWithButton

struct LargeWheelPickerWithButton: View {
    @Binding var selection: Int
    let data: [String]
    var onArrowTap: () -> Void
    
    var body: some View {
        ZStack {
            if !data.isEmpty {
                LargeWheelPicker(selection: $selection, data: data)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    onArrowTap()
                }) {
                    Color.clear
                        .frame(width: 64, height: 64)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 40)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            }
            .zIndex(9999)
            .offset(x: 20, y: 0)
        }
    }
}

// MARK: - LargeWheelPicker

struct LargeWheelPicker: UIViewRepresentable {
    @Binding var selection: Int
    let data: [String]
    var onArrowTap: ((Int) -> Void)? = nil
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = TallPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        
        picker.subviews.forEach { $0.backgroundColor = .clear }
        picker.setValue(UIColor.clear, forKey: "magnifierLineColor")
        
        DispatchQueue.main.async {
            removeSelectionBar(from: picker)
        }
        
        return picker
    }
    
    private func removeSelectionBar(from picker: UIPickerView) {
        for subview in picker.subviews {
            if subview.frame.height <= 1 {
                subview.isHidden = true
            }
            subview.backgroundColor = .clear
        }
        picker.layer.sublayers?.forEach { $0.backgroundColor = UIColor.clear.cgColor }
    }
    
    func updateUIView(_ uiView: UIPickerView, context: Context) {
        uiView.reloadAllComponents()
        if selection < data.count {
            uiView.selectRow(selection, inComponent: 0, animated: true)
        }
        DispatchQueue.main.async {
            uiView.delegate?.pickerView?(uiView, didSelectRow: selection, inComponent: 0)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var parent: LargeWheelPicker
        
        init(_ parent: LargeWheelPicker) { self.parent = parent }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { parent.data.count }
        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 75 }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            label.text = parent.data[row]
            label.textAlignment = .center
            let distance = abs(parent.selection - row)
            if distance == 0 {
                if let descriptor = UIFont.systemFont(ofSize: 64).fontDescriptor.withDesign(.serif) {
                    label.font = UIFont(descriptor: descriptor, size: 64)
                }
                label.textColor = .textPrimary.withAlphaComponent(1.0)
            } else if distance == 1 {
                if let descriptor = UIFont.systemFont(ofSize: 48).fontDescriptor.withDesign(.serif) {
                    label.font = UIFont(descriptor: descriptor, size: 48)
                }
                label.textColor = .textPrimary.withAlphaComponent(0.8)
            } else if distance == 2 {
                if let descriptor = UIFont.systemFont(ofSize: 40).fontDescriptor.withDesign(.serif) {
                    label.font = UIFont(descriptor: descriptor, size: 40)
                }
                label.textColor = .textPrimary.withAlphaComponent(0.6)
            } else {
                if let descriptor = UIFont.systemFont(ofSize: 34).fontDescriptor.withDesign(.serif) {
                    label.font = UIFont(descriptor: descriptor, size: 34)
                }
                label.textColor = .textPrimary.withAlphaComponent(0.4)
            }
            let arrowImage = UIImageView(image: UIImage(named: "arrowHome"))
            arrowImage.tintColor = .textPrimary
            arrowImage.contentMode = .scaleAspectFit
            arrowImage.translatesAutoresizingMaskIntoConstraints = false
            arrowImage.widthAnchor.constraint(equalToConstant: 64).isActive = true
            arrowImage.heightAnchor.constraint(equalToConstant: 18).isActive = true
            let stackView = UIStackView(arrangedSubviews: [arrowImage])
            stackView.axis = .vertical
            stackView.spacing = 0
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
            if parent.selection == row {
                let stackView = UIStackView(arrangedSubviews: [label, stackView])
                stackView.axis = .horizontal
                stackView.alignment = .center
                stackView.spacing = 0
                stackView.translatesAutoresizingMaskIntoConstraints = false
                let container = UIView()
                container.addSubview(stackView)
                NSLayoutConstraint.activate([
                    stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor) ])
                return container
            } else { return label } }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selection = row
            pickerView.reloadAllComponents()
            
            UIDevice.current.playInputClick()
            
        }
    }
}

class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    var parent: LargeWheelPicker
    var audioPlayer: AVAudioPlayer?
    
    init(_ parent: LargeWheelPicker) {
        self.parent = parent
        super.init()
        setupAudioSession()
        prepareSound()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowAirPlay])
            try session.overrideOutputAudioPort(.none)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }
    }
    
    private func prepareSound() {
        if let soundURL = Bundle.main.url(forResource: "wheel_click", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.volume = 1.0 // Ubah volume di sini (0.0 - 1.0)
            } catch {
                print("Failed to load sound: \(error.localizedDescription)")
            }
        }
    }
    
    
    
    private func playSound() {
        guard let player = audioPlayer else { return }
        
        // Reset ke awal dan paksa volume maksimal
        player.currentTime = 0
        player.volume = 1.0
        
        // Paksa output ke route aktif (misal AirPods/headset)
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        } catch {
            print("Audio override error: \(error.localizedDescription)")
        }
        
        player.play()
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { parent.data.count }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 75 }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = parent.data[row]
        label.textAlignment = .center
        
        let distance = abs(parent.selection - row)
        if distance == 0 {
            if let descriptor = UIFont.systemFont(ofSize: 64).fontDescriptor.withDesign(.serif) {
                label.font = UIFont(descriptor: descriptor, size: 64)
            }
            label.textColor = .textPrimary.withAlphaComponent(1.0)
        } else if distance == 1 {
            if let descriptor = UIFont.systemFont(ofSize: 48).fontDescriptor.withDesign(.serif) {
                label.font = UIFont(descriptor: descriptor, size: 48)
            }
            label.textColor = .textPrimary.withAlphaComponent(0.8)
        } else if distance == 2 {
            if let descriptor = UIFont.systemFont(ofSize: 40).fontDescriptor.withDesign(.serif) {
                label.font = UIFont(descriptor: descriptor, size: 40)
            }
            label.textColor = .textPrimary.withAlphaComponent(0.6)
        } else {
            if let descriptor = UIFont.systemFont(ofSize: 34).fontDescriptor.withDesign(.serif) {
                label.font = UIFont(descriptor: descriptor, size: 34)
            }
            label.textColor = .textPrimary.withAlphaComponent(0.4)
        }
        
        let arrowImage = UIImageView(image: UIImage(named: "arrowHome"))
        arrowImage.tintColor = .black
        arrowImage.contentMode = .scaleAspectFit
        arrowImage.translatesAutoresizingMaskIntoConstraints = false
        arrowImage.widthAnchor.constraint(equalToConstant: 64).isActive = true
        arrowImage.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [arrowImage])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        
        if parent.selection == row {
            let stackView = UIStackView(arrangedSubviews: [label, stackView])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 0
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            let container = UIView()
            container.addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            return container
        } else {
            return label
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        parent.selection = row
        pickerView.reloadAllComponents()
        
        // Ganti dari UIDevice.current.playInputClick() ke custom sound
        playSound()
    }
}




// MARK: - TallPickerView

class TallPickerView: UIPickerView {
    var customHeight: CGFloat = 1200
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: customHeight)
    }
}

// MARK: - Preview

#Preview {
    DictionaryView()
        .environment(PopupManager())
}
