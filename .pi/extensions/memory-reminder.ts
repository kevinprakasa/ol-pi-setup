import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Memory Reminder Extension
 *
 * This extension reminds you to update the daily memory folder when you start a session.
 * It checks if today's memory folder exists and prompts you to update it.
 */
export default function (pi: ExtensionAPI) {
  let reminderShown = false;

  pi.on("session_start", async (event, ctx) => {
    // Only show reminder on startup, not on reload
    if (event.reason !== "startup") return;
    if (reminderShown) return;

    reminderShown = true;

    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const todayMemoryPath = `memory/${today}`;

    // Check if today's memory folder exists
    try {
      const fs = await import("node:fs/promises");
      await fs.stat(todayMemoryPath);
      
      // Folder exists - offer to update memory
      const shouldUpdate = await ctx.ui.confirm(
        "Daily Memory",
        `Update today's memory (${today})?`
      );

      if (shouldUpdate) {
        ctx.ui.notify("Opening memory editor...", "info");
        pi.sendUserMessage(`/update-memory ${today}`);
      }
    } catch {
      // Folder doesn't exist - offer to create it
      const shouldCreate = await ctx.ui.confirm(
        "Daily Memory",
        `Create today's memory folder (${today})?`
      );

      if (shouldCreate) {
        ctx.ui.notify("Creating memory folder...", "info");
        pi.sendUserMessage(`Create a new daily memory folder for ${today} using create_daily_memory.sh`);
      }
    }
  });

  // Optional: Show memory status in widget area
  pi.on("agent_start", async (_event, ctx) => {
    const today = new Date().toISOString().split("T")[0];
    try {
      const fs = await import("node:fs/promises");
      const notesPath = `memory/${today}/notes.md`;
      const stats = await fs.stat(notesPath);
      const mtime = new Date(stats.mtime).toLocaleTimeString();
      ctx.ui.setWidget("memory", [
        `📝 Memory: ${today}`,
        `   Updated: ${mtime}`
      ]);
    } catch {
      ctx.ui.setWidget("memory", [`📝 Memory: ${today}`, `   Not created yet`]);
    }
  });
}
