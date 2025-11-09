import SwiftUI
import EmojiKit

struct EmojiKeyboardSection: View {
    @ObservedObject var vm: SlangKeyboardViewModel
    let style: KeyStyle
    let keyboardHeight: CGFloat
    let insertText: (String) -> Void
    
    @State private var selectedCategory: EmojiCategory = .smileysAndPeople
    @State private var searchQuery: String = ""
    
    private var categories: [EmojiCategory] {
        [
            .smileysAndPeople,
            .animalsAndNature,
            .foodAndDrink,
            .activity,
            .travelAndPlaces,
            .objects,
            .symbols,
            .flags
        ]
    }
    
    private var filteredEmojis: [Emoji] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return selectedCategory.emojis }
        let all = categories.flatMap { $0.emojis }
        return all.filter { emoji in
            let name = emoji.localizedName.lowercased()
            return name.contains(q) || emoji.char.lowercased().contains(q)
        }
    }
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(minimum: 28, maximum: 40), spacing: 6), count: 8)
    
    var body: some View {
        VStack(spacing: 8) {
            header
            categoryPicker
            searchField
            emojiGrid
        }
        .padding(.vertical, 8)
        .background(style.keyboardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(VStack(spacing: 0) { Divider().opacity(0.6) }, alignment: .top)
        .frame(height: keyboardHeight)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var header: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { vm.changeDisplayMode(.normal) }
            } label: {
                Image(systemName: "keyboard")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.gray)
                    .frame(width: 34, height: 34)
                    .background(style.popupFill)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.10), radius: 1, y: 0.5)
            }
            
            Text("Emoji")
                .foregroundStyle(style.labelText)
                .font(.system(.subheadline, design: .default, weight: .regular))
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(categories, id: \.self) { category in
                    let isSelected = category == selectedCategory
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = category }
                    } label: {
                        Text(category.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(isSelected ? style.labelText : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(AnyShapeStyle(style.keyboardBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(style.keyStroke, lineWidth: 0.4)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search emoji", text: $searchQuery)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(style.keyboardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(style.keyStroke, lineWidth: 0.4)
                )
        )
        .padding(.horizontal, 8)
    }
    
    private var emojiGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(filteredEmojis, id: \.self) { emoji in
                    Button {
                        insertText(emoji.char)
                    } label: {
                        Text(emoji.char)
                            .font(.system(size: 26))
                            .frame(width: 34, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(style.keyboardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(style.keyStroke, lineWidth: 0.4)
                                    )
                                    .shadow(color: style.keyShadow, radius: 0.8, y: 0.6)
                            )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}

private extension EmojiCategory {
    var title: String {
        switch self {
        case .smileysAndPeople: return "Smileys"
        case .animalsAndNature: return "Animals"
        case .foodAndDrink: return "Food"
        case .travelAndPlaces: return "Places"
        case .activity: return "Activities"
        case .objects: return "Objects"
        case .symbols: return "Symbols"
        case .flags: return "Flags"
        default: return "Other"
        }
    }
}
