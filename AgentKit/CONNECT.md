# Connect your agent

PPB is a native reader and annotation canvas. It does not sell model access, turn subscriptions into APIs or bypass provider limits.

## Local MCP
In PPB choose **Connect your agent → Copy MCP setup**. This copies the bundled stdio server to Application Support/Passage/AgentKit and copies configuration JSON. Add that server in your existing agent's MCP settings using the host's supported configuration workflow. Python 3 must already be installed; no packages are required. PPB does not edit host settings automatically.

1. Open a document in PPB, then **Share current writing** in the connection window.
2. Ask the connected agent to use `ppb_list_context`, read the selected snapshot with `ppb_read_context`, and return its writing with `ppb_submit_writing`.
3. Open **Inbox** in PPB and choose the result. The original remains unchanged.

Only snapshots deliberately shared through the button are readable. Embedded scan images are excluded. **Clear shared context** moves those snapshots to Trash. Results always get a new ID and are written to AgentExchange/Inbox. Existing drafts cannot be overwritten through these tools. No network listener is started; the host runs the server over stdin/stdout.

The stdio connector has protocol tests for initialization, tool discovery, Unicode offsets, invalid quotes and scoped access. Real integration with every third-party client is not yet verified. A desktop or coding agent must support local MCP; a paid browser chat subscription alone does not imply that support. See https://modelcontextprotocol.io/specification/2025-06-18/basic/transports.

## File exchange
If your AI application does not support local MCP, use **Copy brief** and optionally **Export skill kit**. Paste the brief into the agent you already use, save its validated JSON result, then **Import result**. The current writing is included only when the checkbox is selected. Add skill imports a Markdown instruction file; PPB never executes it itself.

## Showcase
Open a document and choose **View → Pin / Unpin Current Writing on Home**, or use **Pin to Home** in My writing. The homepage carousel uses the actual saved title and excerpt. Pins are local; this does not publish anything or create paid advertisements.
