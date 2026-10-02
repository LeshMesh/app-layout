import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var showApplicationPicker = false
    @State private var confirmRecovery = false
    @State private var applicationError = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if let error = model.storageError {
                VStack(alignment: .leading, spacing: 8) {
                    Label(model.text("error.storage"), systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Text(error).font(.caption).textSelection(.enabled)
                    Button(model.text("action.recover")) { confirmRecovery = true }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.quaternary)
            }
            rules
                .disabled(model.storageError != nil)
            footer
        }
        .frame(minWidth: 660, minHeight: 520)
        .sheet(isPresented: $showApplicationPicker) {
            ApplicationPickerView(model: model)
        }
        .alert(model.text("recovery.title"), isPresented: $confirmRecovery) {
            Button(model.text("action.cancel"), role: .cancel) {}
            Button(model.text("action.recover"), role: .destructive) { model.recoverSettings() }
        } message: {
            Text(model.text("recovery.message"))
        }
        .alert(model.text("error.application"), isPresented: $applicationError) {
            Button(model.text("action.ok"), role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "keyboard")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("AppLayout").font(.largeTitle.bold())
                    Text(model.text("settings.subtitle")).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle(model.text("automation.enabled"), isOn: Binding(
                    get: { !model.isPaused }, set: { model.setPaused(!$0) }
                ))
                .toggleStyle(.switch)
                .fixedSize()
                .disabled(model.storageError != nil)
            }
            HStack(spacing: 6) {
                Image(systemName: model.isPaused ? "pause.circle" : "checkmark.circle")
                Text(model.text(model.isPaused ? "status.paused" : "status.active"))
                Spacer()
                Text(model.text("source.current"))
                Text(model.currentSourceName).fontWeight(.medium)
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(24)
    }

    private var rules: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(model.text("rules.title")).font(.headline)
                Spacer()
                Menu {
                    Button(model.text("action.chooseApplication")) { showApplicationPicker = true }
                    Button(model.text("action.browseApplication")) { browseApplication() }
                } label: {
                    Label(model.text("action.add"), systemImage: "plus")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 10)

            if model.preferences.rules.isEmpty {
                ContentUnavailableView {
                    Label(model.text("rules.emptyTitle"), systemImage: "app.badge")
                } description: {
                    Text(model.text("rules.emptyDescription"))
                } actions: {
                    Button(model.text("action.chooseApplication")) { showApplicationPicker = true }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(model.preferences.rules) { rule in
                        RuleRow(model: model, rule: rule)
                            .padding(.vertical, 5)
                    }
                }
                .listStyle(.inset)
                .accessibilityLabel(model.text("rules.title"))
            }

            if let key = model.issueKey {
                VStack(alignment: .leading, spacing: 4) {
                    Label(model.text(key), systemImage: "exclamationmark.triangle")
                    Text(model.issueDetail).font(.caption).textSelection(.enabled)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            Text(model.text("rules.explanation"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
            HStack {
                Toggle(model.text("login.title"), isOn: Binding(
                    get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }
                ))
                .disabled(model.isUpdatingLogin)
                Spacer()
                Picker(model.text("language.title"), selection: Binding(
                    get: { model.preferences.language }, set: { model.setLanguage($0) }
                )) {
                    Text(model.text("language.system")).tag(InterfaceLanguage.system)
                    Text("English").tag(InterfaceLanguage.en)
                    Text("Русский").tag(InterfaceLanguage.ru)
                }
                .frame(width: 240)
                .disabled(model.storageError != nil)
            }
            if model.loginStatus == .requiresApproval {
                HStack {
                    Text(model.text("login.approval")).font(.caption)
                    Button(model.text("action.openLoginSettings")) { model.openLoginSettings() }
                }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.text("privacy.summary"))
                    Text(model.text("compatibility.documentSources"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer(minLength: 18)
                Link(model.text("action.sourceCode"), destination: URL(string: "https://github.com/LeshMesh/app-layout")!)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private func browseApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = model.text("action.add")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let candidate = ApplicationCatalog.candidate(at: url) else {
            applicationError = true
            return
        }
        model.addApplication(candidate)
    }
}

private struct RuleRow: View {
    @ObservedObject var model: AppModel
    let rule: AppRule

    private var unavailable: Bool {
        guard let source = rule.inputSourceID else { return false }
        return !model.inputSources.contains { $0.id == source }
    }

    var body: some View {
        HStack(spacing: 12) {
            ApplicationIcon(bundleIdentifier: rule.bundleIdentifier)
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.displayName).fontWeight(.medium)
                Text(rule.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                if unavailable {
                    Label(model.text("source.unavailable"), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 10)
            Picker(model.text("source.forApplication") + " " + rule.displayName, selection: Binding(
                get: { rule.inputSourceID ?? "" },
                set: { model.setInputSource($0.isEmpty ? nil : $0, for: rule.bundleIdentifier) }
            )) {
                Text(model.text("source.unchanged")).tag("")
                ForEach(model.inputSources) { source in
                    Text(source.name).tag(source.id)
                }
                if unavailable, let missing = rule.inputSourceID {
                    Text(model.text("source.unavailable") + " — " + missing).tag(missing)
                }
            }
            .labelsHidden()
            .frame(width: 225)
            .help(rule.inputSourceID ?? model.text("source.unchanged"))
            Button(role: .destructive) { model.removeRule(rule.bundleIdentifier) } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(model.text("action.remove") + " " + rule.displayName)
            .help(model.text("action.remove"))
        }
        .accessibilityElement(children: .contain)
    }
}

struct ApplicationIcon: View {
    let bundleIdentifier: String

    var body: some View {
        Group {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable()
            } else {
                Image(systemName: "app").resizable().padding(4)
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}

private struct ApplicationPickerView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var applications: [ApplicationCandidate] = []
    @State private var search = ""
    @State private var selection: String?
    @State private var isLoading = true

    private var availableApplications: [ApplicationCandidate] {
        applications.filter { app in
            app.id != AppModel.bundleIdentifier &&
            !model.preferences.rules.contains(where: { $0.id == app.id }) &&
            (search.isEmpty || app.name.localizedCaseInsensitiveContains(search) ||
             app.id.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.text("picker.title")).font(.title2.bold())
            TextField(model.text("picker.search"), text: $search)
                .textFieldStyle(.roundedBorder)
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if availableApplications.isEmpty {
                ContentUnavailableView.search(text: search)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(availableApplications, selection: $selection) { app in
                    HStack(spacing: 10) {
                        ApplicationIcon(bundleIdentifier: app.bundleIdentifier)
                        VStack(alignment: .leading) {
                            Text(app.name)
                            Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                    .tag(app.id)
                }
            }
            HStack {
                Text(model.text("picker.localOnly")).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(model.text("action.cancel")) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(model.text("action.add")) {
                    if let app = availableApplications.first(where: { $0.id == selection }) {
                        model.addApplication(app)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!availableApplications.contains(where: { $0.id == selection }))
            }
        }
        .padding(24)
        .frame(width: 560, height: 480)
        .task {
            let running = ApplicationCatalog.runningApplications()
            let installed = await Task.detached(priority: .userInitiated) {
                ApplicationCatalog.installedApplications()
            }.value
            var unique: [String: ApplicationCandidate] = [:]
            for app in installed + running { unique[app.id] = app }
            applications = unique.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            isLoading = false
        }
    }
}
