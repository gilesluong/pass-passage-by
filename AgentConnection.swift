import Cocoa
extension Passage {
    var exchangeFolder:URL {saveURL.deletingLastPathComponent().appendingPathComponent("AgentExchange")}
    @objc func copyMCPSetup(){
        do {
            let folder = saveURL.deletingLastPathComponent().appendingPathComponent("AgentKit")
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            for name in ["mcp_server.py","bridge.py","SKILL.md","schema.json"] {
                let source = resourceDirectory.appendingPathComponent("AgentKit/" + name)
                try Data(contentsOf:source).write(to:folder.appendingPathComponent(name),options:.atomic)
            }
            let config:[String:Any] = ["mcpServers":["pass-passage-by":["command":"python3","args":[folder.appendingPathComponent("mcp_server.py").path,"--root",exchangeFolder.path]]]]
            let bytes = try JSONSerialization.data(withJSONObject:config,options:[.prettyPrinted,.sortedKeys])
            NSPasteboard.general.clearContents();NSPasteboard.general.setString((String(data:bytes,encoding:.utf8) ?? ""),forType:.string)
            agentStatus?.stringValue = "MCP configuration copied. Add it in your agent’s MCP settings. Python 3 is required; PPB downloads nothing."
        }catch{agentStatus?.stringValue = error.localizedDescription}
    }
    @objc func shareAgentContext(){
        guard opened else{agentStatus?.stringValue = "Open a document first, then share it here.";return}
        do {
            let folder = exchangeFolder.appendingPathComponent("Shared")
            // Share a bounded text-and-annotation snapshot, without embedded scans.
            var context = data;context.images = nil
            try LibraryStore.save(context,to:folder)
            agentStatus?.stringValue = "Shared a snapshot of “\(data.document.title)” with connected agents. Use Clear shared context when finished."
        }catch{agentStatus?.stringValue = error.localizedDescription}
    }
    @objc func clearAgentContext(){
        let folder = exchangeFolder.appendingPathComponent("Shared")
        do {
            for url in (try? FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil)) ?? [] where url.pathExtension == "json" {try FileManager.default.trashItem(at:url,resultingItemURL:nil)}
            agentStatus?.stringValue = "Shared snapshots moved to Trash. Your writing library is unchanged."
        }catch{agentStatus?.stringValue = error.localizedDescription}
    }
    @objc func openAgentInbox(){
        let folder = exchangeFolder.appendingPathComponent("Inbox")
        do{try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)}catch{showAlert(error.localizedDescription);return}
        let panel = NSOpenPanel();panel.directoryURL = folder;panel.allowedContentTypes = [.json];panel.prompt = "Open writing";panel.title = "Agent Inbox"
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

    @objc func agentHarnessMenu(_ sender: NSButton) {
        let menu = NSMenu(title: "AI Agent")
        let shareItem = NSMenuItem(title: "Share Snapshot to Antigravity (MCP)", action: #selector(shareAgentContext), keyEquivalent: "")
        shareItem.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        menu.addItem(shareItem)

        let inboxItem = NSMenuItem(title: "Open Agent Inbox…", action: #selector(openAgentInbox), keyEquivalent: "")
        inboxItem.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: nil)
        menu.addItem(inboxItem)

        menu.addItem(NSMenuItem.separator())

        let copyItem = NSMenuItem(title: "Copy MCP Configuration", action: #selector(copyMCPSetup), keyEquivalent: "")
        copyItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        menu.addItem(copyItem)

        let clearItem = NSMenuItem(title: "Clear Shared Snapshots", action: #selector(clearAgentContext), keyEquivalent: "")
        clearItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        menu.addItem(clearItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY), in: sender)
    }
}
