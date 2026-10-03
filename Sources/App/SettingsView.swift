import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var showApplicationPicker = false
    @State private var showHelp = false
    @State private var confirmRecovery = false

    var body: some View {
        VStack(spacing: 20) {
            header
            automation
            if let error = model.storageError {
                VStack(alignment: .leading, spacing: 8) {
                    Label(model.text("error.storage"), systemImage: "exclamationmark.triangle")
                        .fontWeight(.medium)
                    Text(error).font(.caption).textSelection(.enabled)
                    Button(model.text("action.recover")) { confirmRecovery = true }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }
            rules
                .disabled(model.storageError != nil)
            general
            footer
        }
        .padding(24)
        .frame(minWidth: 660, minHeight: 640)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, model.interfaceLocale)
        .sheet(isPresented: $showApplicationPicker) {
            ApplicationPickerView(model: model)
                .environment(\.locale, model.interfaceLocale)
        }
        .alert(model.text("recovery.title"), isPresented: $confirmRecovery) {
            Button(model.text("action.cancel"), role: .cancel) {}
            Button(model.text("action.recover"), role: .destructive) { model.recoverSettings() }
        } message: {
            Text(model.text("recovery.message"))
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("AppLayout").font(.system(size: 24, weight: .semibold))
                Text(model.text("settings.subtitle"))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { showHelp.toggle() } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 17))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel(model.text("action.help"))
            .help(model.text("action.help"))
            .popover(isPresented: $showHelp, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(model.text("help.heading")).font(.headline)
                    Text(model.text("rules.explanation"))
                    Divider()
                    Text(model.text("compatibility.documentSources"))
                    Label(model.text("privacy.summary"), systemImage: "lock")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(20)
                .frame(width: 360)
            }
        }
    }

    private var automation: some View {
        HStack(spacing: 12) {
            Image(systemName: model.isPaused ? "pause.circle" : "keyboard")
                .font(.system(size: 19))
                .foregroundStyle(model.isPaused ? Color.secondary : Color.accentColor)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.text("automation.enabled")).fontWeight(.medium)
                Text(model.text(model.isPaused ? "automation.pausedHint" : "automation.activeHint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Toggle(model.text("automation.enabled"), isOn: Binding(
                get: { !model.isPaused }, set: { model.setPaused(!$0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .disabled(model.storageError != nil)
        }
        .padding(14)
        .settingsSurface()
    }

    private var rules: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(model.text("rules.title")).font(.headline)
                if !model.preferences.rules.isEmpty {
                    Text(model.preferences.rules.count, format: .number)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { showApplicationPicker = true } label: {
                    Label(model.text("action.add"), systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help(model.text("action.chooseApplication"))
            }
            Group {
                if model.preferences.rules.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "app.badge")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(model.text("rules.emptyTitle")).font(.headline)
                        Text(model.text("rules.emptyDescription"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 340)
                        Button(model.text("action.chooseApplication")) { showApplicationPicker = true }
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(model.preferences.rules) { rule in
                                RuleRow(model: model, rule: rule)
                                if rule.id != model.preferences.rules.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                    }
                    .accessibilityLabel(model.text("rules.title"))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 190, maxHeight: .infinity)
            .settingsSurface()
            if let key = model.issueKey {
                VStack(alignment: .leading, spacing: 4) {
                    Label(model.text(key), systemImage: "exclamationmark.triangle")
                    Text(model.issueDetail).font(.caption).textSelection(.enabled)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Text(model.text("rules.footnote"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var general: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.text("general.title")).font(.headline)
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "power").frame(width: 24).foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(model.text("login.title"))
                    Spacer()
                    if model.isUpdatingLogin {
                        ProgressView().controlSize(.small)
                    }
                    Toggle(model.text("login.title"), isOn: Binding(
                        get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(model.isUpdatingLogin || model.storageError != nil)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                Divider().padding(.leading, 52)
                HStack(spacing: 12) {
                    Image(systemName: "globe").frame(width: 24).foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(model.text("language.title"))
                    Spacer()
                    Picker(model.text("language.title"), selection: Binding(
                        get: { model.preferences.language }, set: { model.setLanguage($0) }
                    )) {
                        Text(model.text("language.system")).tag(InterfaceLanguage.system)
                        Text("English").tag(InterfaceLanguage.en)
                        Text("Русский").tag(InterfaceLanguage.ru)
                    }
                    .labelsHidden()
                    .frame(width: 185)
                    .disabled(model.storageError != nil)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .settingsSurface()
            if model.loginStatus == .requiresApproval {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.text("login.approval")).font(.caption).foregroundStyle(.secondary)
                    Button(model.text("action.openLoginSettings")) { model.openLoginSettings() }
                        .controlSize(.small)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Label(model.text("privacy.local"), systemImage: "lock")
            Text("·")
            Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
            Spacer()
            Link(model.text("action.sourceCode"), destination: URL(string: "https://github.com/LeshMesh/app-layout")!)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private extension View {
    func settingsSurface() -> some View {
        self
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RuleRow: View {
    @ObservedObject var model: AppModel
    let rule: AppRule

    private var unavailable: Bool {
        guard let source = rule.inputSourceID else { return false }
        return !model.inputSources.contains { $0.id == source }
    }

    private var hasDuplicateName: Bool {
        model.preferences.rules.contains { $0.id != rule.id && $0.displayName == rule.displayName }
    }

    var body: some View {
        HStack(spacing: 12) {
            ApplicationIcon(bundleIdentifier: rule.bundleIdentifier)
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.displayName).fontWeight(.medium).lineLimit(1)
                if hasDuplicateName {
                    Text(rule.bundleIdentifier).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                if unavailable {
                    Label(model.text("source.unavailable"), systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .help(rule.bundleIdentifier)
            Spacer(minLength: 8)
            Picker(model.text("source.forApplication") + " " + rule.displayName, selection: Binding(
                get: { rule.inputSourceID ?? "" },
                set: { model.setInputSource($0.isEmpty ? nil : $0, for: rule.bundleIdentifier) }
            )) {
                Text(model.text("source.unchanged")).tag("")
                Divider()
                ForEach(model.inputSources) { source in
                    Text(source.name).tag(source.id)
                }
                if unavailable, let missing = rule.inputSourceID {
                    Text(model.text("source.unavailable")).tag(missing)
                }
            }
            .labelsHidden()
            .frame(width: 200)
            .help(rule.inputSourceID ?? model.text("source.unchanged"))
            Button(role: .destructive) { model.removeRule(rule.bundleIdentifier) } label: {
                Image(systemName: "minus.circle")
                    .frame(width: 24, height: 28)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel(model.text("action.remove") + " " + rule.displayName)
            .help(model.text("action.remove"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
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
                Image(systemName: "app").resizable().padding(4).foregroundStyle(.secondary)
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
    @State private var applicationError = false

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
            VStack(alignment: .leading, spacing: 5) {
                Text(model.text("picker.title")).font(.title2.weight(.semibold))
                Text(model.text("picker.localOnly")).font(.callout).foregroundStyle(.secondary)
            }
            TextField(model.text("picker.search"), text: $search)
                .textFieldStyle(.roundedBorder)
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if availableApplications.isEmpty {
                    ContentUnavailableView.search(text: search)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(availableApplications, selection: $selection) { app in
                        HStack(spacing: 10) {
                            ApplicationIcon(bundleIdentifier: app.bundleIdentifier)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                if applications.contains(where: { $0.id != app.id && $0.name == app.name }) {
                                    Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .help(app.bundleIdentifier)
                        .padding(.vertical, 4)
                        .tag(app.id)
                    }
                    .listStyle(.inset)
                }
            }
            .settingsSurface()
            HStack {
                Button(model.text("action.browseApplication")) { browseApplication() }
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
        .frame(width: 540, height: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(model.text("error.application"), isPresented: $applicationError) {
            Button(model.text("action.ok"), role: .cancel) {}
        }
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

    private func browseApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = model.text("action.add")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let candidate = ApplicationCatalog.candidate(at: url),
              candidate.bundleIdentifier != AppModel.bundleIdentifier else {
            applicationError = true
            return
        }
        model.addApplication(candidate)
        dismiss()
    }
}
