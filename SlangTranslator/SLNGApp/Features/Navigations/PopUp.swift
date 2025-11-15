//
//  PopUp.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 28/10/25.
//
import SwiftUI

@Observable
class PopupManager {
    var isPresented: Bool = false
    var slangData: SlangModel?
    var selectedCanonical: String?
    var variants: [SlangModel] = []
    var popupContent: AnyView = AnyView(EmptyView())

    func show<Content: View>(_ view: Content) {
        withAnimation(.spring()) {
            popupContent = AnyView(view)
            isPresented = true
        }
    }

    func dismiss() {
        withAnimation(.spring()) {
            isPresented = false
        }
    }
    
    func setSlangData(_ slangData: SlangModel) {
        self.slangData = slangData
    }
    
    func getSlangData() -> SlangModel? {
        return slangData
    }
    
    func setData(slangData: SlangModel) {
        self.slangData = slangData
    }
    
    func getData() -> SlangModel? {
        return slangData
    }

    func setCanonicalForm(_ canonical: String) {
        self.selectedCanonical = canonical
    }
    
    func getCanonicalForm() -> String? {
        return selectedCanonical
    }
    
    func setVariants(_ variants: [SlangModel]) {
        self.variants = variants
    }
    
    func getVariants() -> [SlangModel] {
        return variants
    }
}
