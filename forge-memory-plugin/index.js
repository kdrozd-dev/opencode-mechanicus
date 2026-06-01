import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const id = "forge-memory-plugin";

const HOOK_SCRIPT = join(
  homedir(),
  ".config/opencode/forge-memory-plugin/hooks/journal-check.sh",
);

function runHook(toolCalls, sessionID, cwd) {
  return new Promise((resolve) => {
    const child = spawn("bash", [HOOK_SCRIPT], {
      env: { ...process.env, FORGE_TOOL_CALLS: String(toolCalls) },
      stdio: ["pipe", "pipe", "ignore"],
    });
    let out = "";
    child.stdout.on("data", (chunk) => {
      out += chunk.toString();
    });
    child.on("error", () => resolve(null));
    child.on("close", () => {
      try {
        resolve(JSON.parse(out.trim() || "{}"));
      } catch {
        resolve(null);
      }
    });
    child.stdin.end(JSON.stringify({ session_id: sessionID, cwd }));
  });
}

async function countToolCalls(client, sessionID) {
  const res = await client.session.messages({ path: { id: sessionID } });
  const messages = res?.data ?? res ?? [];
  let count = 0;
  for (const entry of messages) {
    const parts = entry?.parts ?? [];
    for (const part of parts) {
      if (part?.type === "tool") count++;
    }
  }
  return count;
}

const server = async ({ client, directory }) => {
  const seen = new Set();
  return {
    event: async ({ event }) => {
      if (event?.type !== "session.idle") return;
      const sessionID = event.properties?.sessionID;
      if (!sessionID || seen.has(sessionID)) return;
      seen.add(sessionID);

      let toolCalls = 0;
      try {
        toolCalls = await countToolCalls(client, sessionID);
      } catch {
        return;
      }

      const result = await runHook(toolCalls, sessionID, directory);
      if (result?.decision === "block" && result?.inject_prompt) {
        try {
          await client.tui.showToast({
            body: {
              title: "Forge Memory",
              message: result.inject_prompt,
              variant: "warning",
              duration: 12000,
            },
          });
        } catch {
          /* toast surface unavailable (headless run); reminder is best-effort */
        }
      }
    },
  };
};

export default { id, server };
