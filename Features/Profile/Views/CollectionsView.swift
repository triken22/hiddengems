import SwiftUI

/// Collections view for organizing saved spots
struct CollectionsView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var collections: [SpotCollection] = []
    @State private var showingCreateCollection = false
    @State private var newCollectionName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if collections.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Collections Yet",
                        message: "Create collections to organize your favorite spots",
                        actionTitle: "Create Collection"
                    ) {
                        showingCreateCollection = true
                    }
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: AppSpacing.md),
                                GridItem(.flexible(), spacing: AppSpacing.md)
                            ],
                            spacing: AppSpacing.lg
                        ) {
                            ForEach(collections) { collection in
                                CollectionCardView(collection: collection)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                    }
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateCollection = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateCollection) {
            CreateCollectionView(
                collectionName: $newCollectionName,
                onCreate: { name in
                    let collection = SpotCollection(
                        id: UUID().uuidString,
                        name: name,
                        description: "",
                        spotIds: [],
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    collections.append(collection)
                    newCollectionName = ""
                }
            )
        }
        .onAppear {
            loadCollections()
        }
    }
    
    private func loadCollections() {
        // In a real app, this would load from a repository
        collections = [
            SpotCollection(
                id: "1",
                name: "Coffee Shops",
                description: "My favorite local coffee spots",
                spotIds: [],
                createdAt: Date(),
                updatedAt: Date()
            ),
            SpotCollection(
                id: "2",
                name: "Hidden Gems",
                description: "Secret spots only locals know about",
                spotIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}

// MARK: - Collection Card View
struct CollectionCardView: View {
    let collection: SpotCollection
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Collection image (placeholder)
            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                .fill(AppColors.surface)
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "folder.fill")
                            .font(.title)
                            .foregroundColor(AppColors.primary)
                        Text("\(collection.spotIds.count)")
                            .appFont(.headline, color: AppColors.textPrimary)
                    }
                )
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(collection.name)
                    .font(AppTypography.cardTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(collection.description)
                    .font(AppTypography.cardSubtitle)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                
                Text("\(collection.spotIds.count) spots")
                    .appFont(.caption, color: AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .shadow(
            color: AppSpacing.cardShadow.color,
            radius: AppSpacing.cardShadow.radius,
            x: AppSpacing.cardShadow.x,
            y: AppSpacing.cardShadow.y
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Create Collection View
struct CreateCollectionView: View {
    @Binding var collectionName: String
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Collection Name")
                        .appFont(.callout, weight: .semibold, color: AppColors.textPrimary)
                    
                    TextField("Enter collection name", text: $collectionName)
                        .appFont(.body, color: AppColors.textPrimary)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding(AppSpacing.lg)
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(collectionName)
                        dismiss()
                    }
                    .disabled(collectionName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Spot Collection Model
struct SpotCollection: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var spotIds: [String]
    let createdAt: Date
    var updatedAt: Date
}

// MARK: - Preview
#if DEBUG
struct CollectionsView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionsView()
            .environmentObject(AppEnvironment().homeViewModel)
    }
}
#endif
