import SwiftUI

/// A custom search bar component with Airbnb-style design
struct SearchBarView: View {
    @Binding var searchText: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    let onTextChanged: ((String) -> Void)?
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search spots...",
        onSearchButtonClicked: (() -> Void)? = nil,
        onTextChanged: ((String) -> Void)? = nil
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onTextChanged = onTextChanged
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isEditing ? AppColors.primary : AppColors.textTertiary)
                .font(.system(size: 16, weight: .medium))
            
            TextField(placeholder, text: $searchText)
                .font(AppTypography.searchText)
                .foregroundColor(AppColors.textPrimary)
                .focused($isFocused)
                .onChange(of: searchText) { newValue in
                    onTextChanged?(newValue)
                }
                .onSubmit {
                    onSearchButtonClicked?()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onTextChanged?("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                        .font(.system(size: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(backgroundColor)
        .cornerRadius(AppSpacing.buttonCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
        .onChange(of: isFocused) { focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = focused
            }
        }
    }
    
    private var backgroundColor: Color {
        isEditing ? AppColors.surfaceElevated : AppColors.surface
    }
    
    private var borderColor: Color {
        if isEditing {
            return AppColors.primary
        } else if !searchText.isEmpty {
            return AppColors.borderDark
        } else {
            return AppColors.border
        }
    }
}

// MARK: - Search Bar with Filters
struct SearchBarWithFilters: View {
    @Binding var searchText: String
    let placeholder: String
    let filterCount: Int
    let onSearchButtonClicked: (() -> Void)?
    let onTextChanged: ((String) -> Void)?
    let onFiltersTapped: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            SearchBarView(
                searchText: $searchText,
                placeholder: placeholder,
                onSearchButtonClicked: onSearchButtonClicked,
                onTextChanged: onTextChanged
            )
            
            Button(action: onFiltersTapped) {
                ZStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                    
                    if filterCount > 0 {
                        Text("\(filterCount)")
                            .appFont(.caption2, color: AppColors.textInverse)
                            .frame(width: 16, height: 16)
                            .background(AppColors.primary)
                            .cornerRadius(8)
                            .offset(x: 8, y: -8)
                    }
                }
            }
            .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Search Suggestions
struct SearchSuggestionsView: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void
    let onClearTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Searches")
                    .appFont(.footnote, weight: .medium, color: AppColors.textSecondary)
                
                Spacer()
                
                Button("Clear") {
                    onClearTapped()
                }
                .appFont(.footnote, color: AppColors.primary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            
            LazyVStack(spacing: 0) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSuggestionTapped(suggestion)
                    }) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(AppColors.textTertiary)
                                .font(.caption)
                            
                            Text(suggestion)
                                .appFont(.body, color: AppColors.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if suggestion != suggestions.last {
                        Divider()
                            .padding(.leading, AppSpacing.xl)
                    }
                }
            }
        }
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppSpacing.buttonCornerRadius)
        .shadow(
            color: AppSpacing.cardShadow.color,
            radius: AppSpacing.cardShadow.radius,
            x: AppSpacing.cardShadow.x,
            y: AppSpacing.cardShadow.y
        )
    }
}

// MARK: - Preview
#if DEBUG
struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SearchBarView(
                searchText: .constant(""),
                placeholder: "Search spots..."
            )
            
            SearchBarView(
                searchText: .constant("Coffee"),
                placeholder: "Search spots..."
            )
            
            SearchBarWithFilters(
                searchText: .constant(""),
                placeholder: "Where to?",
                filterCount: 2
            ) {
                print("Search tapped")
            } onTextChanged: { _ in
                print("Text changed")
            } onFiltersTapped: {
                print("Filters tapped")
            }
            
            SearchSuggestionsView(
                suggestions: ["Coffee shops", "Parks", "Museums"],
                onSuggestionTapped: { _ in },
                onClearTapped: { }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
