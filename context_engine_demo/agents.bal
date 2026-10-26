import ballerina/ai;
import ballerina/mcp;
import ballerina/time;

# Converts a given UTC time to an RFC 3339 timestamp (e.g., `2007-12-03T10:15:30.00Z`).
@ai:AgentTool
@display {label: "", iconPath: "https://bcentral-packageicons.azureedge.net/images/ballerina_time_2.8.4.png"}
isolated function utcToStringTool() returns string {
    string result = time:utcToString(time:utcNow()).substring(0, 10);
    return result;
}

final ai:Agent aiAgent = check new (
    systemPrompt = {
        role: string `Account assistant for OurCo's team on the Acme Corp account`,
        instructions: string `You are the account team's assistant for Acme Corp. 

You help them prepare for meetings, keep track of what is open and what was promised, and get ready for the renewal.

Your knowledge of the account comes from the context engine. Answer only from what it gives you, and say plainly when you don't know something.

Lead with the answer, then the facts behind it, each with where it came from. Keep it brief.`
    }, model = check ai:getDefaultModelProvider(), tools = [utcToStringTool, contextTool]
);

isolated class McpToolKit {
    *ai:McpBaseToolKit;
    private final mcp:StreamableHttpClient mcpClient;
    private final readonly & ai:ToolConfig[] tools;

    public isolated function init(string serverUrl, mcp:Implementation info = {name: "MCP", version: "1.0.0"},
            *mcp:StreamableHttpClientTransportConfig config) returns ai:Error? {
        do {
            self.mcpClient = check new mcp:StreamableHttpClient(serverUrl, config);
            self.tools = check ai:getPermittedMcpToolConfigs(self.mcpClient, info, self.callTool).cloneReadOnly();
        } on fail error e {
            return error ai:Error("Failed to initialize MCP toolkit", e);
        }
    }

    public isolated function getTools() returns ai:ToolConfig[] => self.tools;

    @ai:AgentTool
    public isolated function callTool(mcp:CallToolParams params) returns mcp:CallToolResult|error {
        return self.mcpClient->callTool(params);
    }
}

