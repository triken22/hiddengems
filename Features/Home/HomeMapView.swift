import SwiftUI
import MapKit

struct HomeMapView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.mapSpots) { spot in
                    Annotation(spot.title, coordinate: spot.coordinate) {
                        SpotAnnotationView(spot: spot)
                            .onTapGesture {
                                viewModel.selectedSpot = spot
                            }
                    }
                }
            }
            .task {
                await viewModel.centerOnUser()
            }

            FloatingActionButton(icon: "camera.fill") {
                viewModel.openQuickAdd()
            }
            .padding(24)
        }
        .sheet(isPresented: $viewModel.isQuickAddPresented) {
            QuickAddView(viewModel: viewModel.quickAddViewModel())
        }
        .onAppear { viewModel.onAppear() }
    }
}

private struct SpotAnnotationView: View {
    let spot: Spot

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(.accentColor)
            Text(spot.title)
                .font(.caption)
                .padding(4)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(8)
        }
    }
}
