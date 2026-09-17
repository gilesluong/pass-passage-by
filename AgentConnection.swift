import Cocoa

extension Passage {
    var exchangeFolder: URL { saveURL.deletingLastPathComponent().appendingPathComponent("AgentExchange") }

    @objc func copyMCPSetup() {
        do {
            let folder = saveURL.deletingLastPathComponent().appendingPathComponent("AgentKit")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for name in ["mcp_server.py", "bridge.py", "SKILL.md", "schema.json"] {
                let source = resourceDirectory.appendingPathComponent("AgentKit/" + name)
                try Data(contentsOf: source).write(to: folder.appendingPathComponent(name), options: .atomic)
            }
            let config: [String: Any] = [
                "mcpServers": [
                    "pass-passage-by": [
                        "command": "python3",
                        "args": [folder.appendingPathComponent("mcp_server.py").path, "--root", exchangeFolder.path]
                    ]
                ]
            ]
            let bytes = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(String(data: bytes, encoding: .utf8) ?? "", forType: .string)
            let msg = "Đã sao chép cấu hình MCP vào Clipboard!\n\nDán đoạn JSON này vào cài đặt MCP của Antigravity/Codex để kết nối."
            agentStatus?.stringValue = msg
            showAlert(msg)
        } catch {
            agentStatus?.stringValue = error.localizedDescription
            showAlert(error.localizedDescription)
        }
    }

    @objc func shareAgentContext() {
        guard opened else {
            showAlert("Hãy mở một tài liệu trước khi chia sẻ với Agent.")
            return
        }
        do {
            let folder = exchangeFolder.appendingPathComponent("Shared")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var context = data
            context.images = nil
            try LibraryStore.save(context, to: folder)
            let msg = "Đã chia sẻ bản chụp “\(data.document.title)” cho AI Agent qua MCP!\n\nTài liệu được lưu tại:\nAgentExchange/Shared"
            agentStatus?.stringValue = msg
            showAlert(msg)
        } catch {
            agentStatus?.stringValue = error.localizedDescription
            showAlert(error.localizedDescription)
        }
    }

    @objc func clearAgentContext() {
        let folder = exchangeFolder.appendingPathComponent("Shared")
        do {
            for url in (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [] where url.pathExtension == "json" {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            }
            let msg = "Đã dọn dẹp các bản chụp chia sẻ trong AgentExchange/Shared."
            agentStatus?.stringValue = msg
            showAlert(msg)
        } catch {
            agentStatus?.stringValue = error.localizedDescription
            showAlert(error.localizedDescription)
        }
    }

    @objc func openAgentInbox() {
        let folder = exchangeFolder.appendingPathComponent("Inbox")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            showAlert(error.localizedDescription)
            return
        }
        let panel = NSOpenPanel()
        panel.directoryURL = folder
        panel.allowedContentTypes = [.json]
        panel.prompt = "Open writing"
        panel.title = "Agent Inbox"
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }
            do {
                if self.opened { self.saveDraft() }
                try self.loadJSON(Data(contentsOf: url))
                self.infoWindow?.close()
                self.openWorkspace()
            } catch {
                self.showAlert(error.localizedDescription)
            }
        }
    }

    @objc func revealExchangeFolder() {
        do {
            try FileManager.default.createDirectory(at: exchangeFolder, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: exchangeFolder.appendingPathComponent("Shared"), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: exchangeFolder.appendingPathComponent("Inbox"), withIntermediateDirectories: true)
            NSWorkspace.shared.open(exchangeFolder)
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    @objc func generateAIFeedback() {
        guard opened else {
            showAlert("Hãy mở một bài viết hoặc tài liệu trước khi phân tích.")
            return
        }
        let text = data.document.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showAlert("Tài liệu đang trống. Hãy nhập hoặc kéo thả file PDF vào để phân tích.")
            return
        }
        let isVN = text.range(of: "[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]", options: .regularExpression) != nil
        let lang = isVN ? "Vietnamese" : "English"
        snapshot()
        do {
            let notes = try LocalFeedback.generateOffline(data.document.text, language: lang)
            if notes.isEmpty {
                showAlert("Không tìm thấy đề xuất chú thích mới cho văn bản này.")
                return
            }
            var addedCount = 0
            for n in notes {
                if !data.annotations.contains(where: { $0.quote == n.quote && $0.label == n.label }) {
                    data.annotations.append(n)
                    addedCount += 1
                }
            }
            renderNotes()
            updateConnectors()
            saveDraft()
            if addedCount > 0 {
                showAlert("✦ Đã tạo xong \(addedCount) ghi chú phân tích đọc sâu trên văn bản!")
            } else {
                showAlert("Các vị trí gợi ý đều đã có ghi chú.")
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    @objc func agentHarnessMenu(_ sender: NSButton) {
        let menu = NSMenu(title: "AI Agent")
        menu.autoenablesItems = false

        let analyzeItem = NSMenuItem(title: "✦ Phân tích & Tạo chú thích (AI Notes)", action: #selector(generateAIFeedback), keyEquivalent: "")
        analyzeItem.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        analyzeItem.target = self
        menu.addItem(analyzeItem)

        menu.addItem(NSMenuItem.separator())

        let shareItem = NSMenuItem(title: "Gửi Snapshot cho Antigravity (Share MCP)", action: #selector(shareAgentContext), keyEquivalent: "")
        shareItem.image = NSImage(systemSymbolName: "arrow.up.forward.app", accessibilityDescription: nil)
        shareItem.target = self
        menu.addItem(shareItem)

        let inboxItem = NSMenuItem(title: "Mở Hộp Thư Agent (Open Agent Inbox)…", action: #selector(openAgentInbox), keyEquivalent: "")
        inboxItem.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: nil)
        inboxItem.target = self
        menu.addItem(inboxItem)

        let folderItem = NSMenuItem(title: "Mở Thư Mục Cục Bộ trong Finder…", action: #selector(revealExchangeFolder), keyEquivalent: "")
        folderItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        folderItem.target = self
        menu.addItem(folderItem)

        menu.addItem(NSMenuItem.separator())

        let copyItem = NSMenuItem(title: "Sao Chép Cấu Hình MCP (Copy MCP Setup)", action: #selector(copyMCPSetup), keyEquivalent: "")
        copyItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        copyItem.target = self
        menu.addItem(copyItem)

        let clearItem = NSMenuItem(title: "Dọn Dẹp Snapshot Tạm (Clear Shared)", action: #selector(clearAgentContext), keyEquivalent: "")
        clearItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        clearItem.target = self
        menu.addItem(clearItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY), in: sender)
    }
}
