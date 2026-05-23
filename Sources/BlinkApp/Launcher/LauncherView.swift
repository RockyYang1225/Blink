import BlinkCore
import SwiftUI

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search commands, clipboard, files...", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.system(size: 26, weight: .regular, design: .default))
                .padding(20)
                .focused($isFocused)
                .onChange(of: viewModel.query) {
                    viewModel.queryDidChange()
                }
                .onSubmit {
                    viewModel.executeSelected()
                }

            Divider()

            if viewModel.results.isEmpty {
                emptyState
            } else {
                resultList
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
            Text(viewModel.query.isEmpty ? "Start typing" : "No results")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var resultList: some View {
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
            .padding(.vertical, 6)
            .listRowBackground(index == viewModel.selectedIndex ? Color.accentColor.opacity(0.16) : Color.clear)
            .onTapGesture {
                viewModel.moveSelection(delta: index - viewModel.selectedIndex)
            }
        }
        .listStyle(.plain)
    }
}
