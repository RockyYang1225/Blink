import BlinkCore
import SwiftUI

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField(
                viewModel.searchPlaceholder,
                text: Binding(
                    get: { viewModel.query },
                    set: { viewModel.updateQuery($0) }
                )
            )
                .textFieldStyle(.plain)
                .font(.system(size: 26, weight: .regular, design: .default))
                .padding(20)
                .focused($isFocused)
                .onSubmit {
                    viewModel.executeSelected()
                }

            Divider()

            if viewModel.isShowingFeatureOptions {
                featureOptionsList
            } else if viewModel.results.isEmpty {
                emptyState
            } else {
                resultList
            }

            if viewModel.isShowingSecondaryActions {
                secondaryActionsView
            }

            if let statusMessage = viewModel.statusMessage {
                Divider()
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
        .frame(width: 680, height: 420)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            isFocused = true
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text(emptyStateText)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var emptyStateText: String {
        if let feature = viewModel.activeFeature, viewModel.query.isEmpty {
            return "Type to use \(feature.title)"
        }
        return "No results"
    }

    private var featureOptionsList: some View {
        ScrollViewReader { proxy in
            List(Array(viewModel.featureOptions.enumerated()), id: \.element.id) { index, feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.symbolName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(index == viewModel.selectedFeatureIndex ? Color.accentColor : Color.secondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(1)
                        Text(feature.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("Open")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .id(feature.id)
                .padding(.vertical, 7)
                .listRowBackground(index == viewModel.selectedFeatureIndex ? Color.accentColor.opacity(0.16) : Color.clear)
                .onTapGesture {
                    viewModel.activateFeature(at: index)
                }
            }
            .listStyle(.plain)
            .onChange(of: viewModel.selectedFeatureIndex) { _, _ in
                scrollSelectedFeature(with: proxy)
            }
        }
    }

    private var resultList: some View {
        ScrollViewReader { proxy in
            List(Array(viewModel.results.enumerated()), id: \.element.id) { index, result in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(1)
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(result.primaryAction.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .id(result.id)
                .padding(.vertical, 6)
                .listRowBackground(index == viewModel.selectedIndex ? Color.accentColor.opacity(0.16) : Color.clear)
                .onTapGesture {
                    viewModel.moveSelection(delta: index - viewModel.selectedIndex)
                }
            }
            .listStyle(.plain)
            .onChange(of: viewModel.selectedIndex) { _, _ in
                scrollSelectedResult(with: proxy)
            }
        }
    }

    private func scrollSelectedFeature(with proxy: ScrollViewProxy) {
        guard viewModel.featureOptions.indices.contains(viewModel.selectedFeatureIndex) else {
            return
        }

        withAnimation(.easeOut(duration: 0.12)) {
            proxy.scrollTo(viewModel.featureOptions[viewModel.selectedFeatureIndex].id, anchor: .center)
        }
    }

    private func scrollSelectedResult(with proxy: ScrollViewProxy) {
        guard viewModel.results.indices.contains(viewModel.selectedIndex) else {
            return
        }

        withAnimation(.easeOut(duration: 0.12)) {
            proxy.scrollTo(viewModel.results[viewModel.selectedIndex].id, anchor: .center)
        }
    }

    private var secondaryActionsView: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                ForEach(Array(viewModel.secondaryActions.enumerated()), id: \.element.id) { index, action in
                    Text(action.title)
                        .font(.caption)
                        .fontWeight(index == viewModel.selectedActionIndex ? .semibold : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(index == viewModel.selectedActionIndex ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Spacer()
            }
            .padding(12)
        }
    }
}
