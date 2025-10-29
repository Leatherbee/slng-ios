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
    var slangData: SlangDataDummy?
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
    
    func setData(slangData: SlangDataDummy) {
        self.slangData = slangData
    }
    
    func getData() -> SlangDataDummy? {
        return slangData
    }
}
