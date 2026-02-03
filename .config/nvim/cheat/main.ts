// deno-lint-ignore-file no-explicit-any
// Import HTML escaping from Deno standard library
// deno-lint-ignore no-import-prefix
import { escape } from "https://deno.land/std@0.208.0/html/mod.ts";

// This simple deno script is used to sync cheat.csv to anki using the
// anki-connect API.

interface AnkiNote {
  deckName: string;
  modelName: string;
  fields: {
    Front: string;
    Back: string;
  };
  tags?: string[];
}

interface AnkiConnectRequest {
  action: string;
  version: number;
  params?: any;
}

interface AnkiConnectResponse {
  result: any;
  error: string | null;
}

async function callAnkiConnect(
  request: AnkiConnectRequest,
): Promise<AnkiConnectResponse> {
  try {
    const response = await fetch("http://localhost:8765", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return await response.json();
  } catch (error: any) {
    throw new Error(`Failed to connect to AnkiConnect: ${error.message}`);
  }
}

async function ensureDeckExists(deckName: string): Promise<void> {
  const request: AnkiConnectRequest = {
    action: "createDeck",
    version: 6,
    params: {
      deck: deckName,
    },
  };

  const response = await callAnkiConnect(request);
  if (response.error) {
    console.log(
      `Note: ${response.error} (this is normal if deck already exists)`,
    );
  }
}

async function noteExists(note: AnkiNote): Promise<boolean> {
  try {
    const request: AnkiConnectRequest = {
      action: "findNotes",
      version: 6,
      params: {
        query: `deck:"${note.deckName}" "${note.fields.Front}"`,
      },
    };

    const response = await callAnkiConnect(request);
    return response.result && response.result.length > 0;
  } catch {
    // If we can't check, assume it doesn't exist
    return false;
  }
}

async function addNoteToAnki(note: AnkiNote): Promise<boolean> {
  // Check if note already exists
  const exists = await noteExists(note);
  if (exists) {
    console.log(
      `⚠️  Skipped (duplicate): ${note.fields.Front.split("?")[0]}...`,
    );
    return true; // Consider this a success since the note exists
  }

  const request: AnkiConnectRequest = {
    action: "addNote",
    version: 6,
    params: {
      note,
    },
  };

  // Add retry logic for connection issues
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const response = await callAnkiConnect(request);
      if (response.error) {
        if (response.error.includes("duplicate")) {
          console.log(
            `⚠️  Skipped (duplicate): ${note.fields.Front.split("?")[0]}...`,
          );
          return false;
        }
        console.error(`Failed to add note: ${response.error}`);
        return false;
      }
      return true;
    } catch (error: any) {
      if (attempt === 3) {
        console.error(`Failed to add note after 3 attempts: ${error.message}`);
        return false;
      }
      console.log(`⚠️  Connection issue (attempt ${attempt}/3), retrying...`);
      await new Promise((resolve) => setTimeout(resolve, 1000 * attempt)); // Exponential backoff
    }
  }
  return false;
}

function escapeForAnki(text: string): string {
  // Use Deno standard library's HTML escape function
  return escape(text);
}

async function readCheatSheet(
  path: string,
): Promise<Array<{ command: string; description: string; section: string }>> {
  try {
    const content = await Deno.readTextFile(path);
    const lines = content.split("\n").filter((line) => line.trim());

    const entries = [];
    let currentSection = "General";

    for (const line of lines) {
      if (line.startsWith("# ")) {
        // This is a section header
        currentSection = line.replace(/^#\s*/, "").trim();
        continue;
      }

      const parts = line.split("|");
      if (parts.length >= 2) {
        entries.push({
          command: parts[0].trim(),
          description: parts[1].trim(),
          section: currentSection,
        });
      }
    }

    return entries;
  } catch (error: any) {
    throw new Error(`Failed to read cheat sheet: ${error.message}`);
  }
}

export async function sync(csvPath?: string): Promise<void> {
  const path = csvPath || "./cheat.csv";
  const deckName = "Programming::NVim";

  console.log(`Syncing cheat sheet from ${path} to Anki deck "${deckName}"...`);

  try {
    // Check if AnkiConnect is available
    console.log("Checking AnkiConnect availability...");
    await callAnkiConnect({ action: "version", version: 6 });
    console.log("✓ AnkiConnect is available");

    // Ensure deck exists
    console.log(`Ensuring deck "${deckName}" exists...`);
    await ensureDeckExists(deckName);
    console.log("✓ Deck ready");

    // Read cheat sheet
    console.log("Reading cheat sheet...");
    const entries = await readCheatSheet(path);
    console.log(`✓ Found ${entries.length} entries`);

    // Add notes to Anki
    console.log("Adding notes to Anki...");
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      // Escape all potentially problematic characters for Anki
      const escapedCommand = escapeForAnki(entry.command);
      const escapedDescription = escapeForAnki(entry.description);
      const escapedSection = escapeForAnki(entry.section);

      const note: AnkiNote = {
        deckName,
        modelName: "Basic (and reversed card)",
        fields: {
          Front: `<code>${escapedCommand}</code> (${escapedSection}) #${i + 1}`,
          Back: `${escapedDescription} (${escapedSection})`,
        },
        tags: ["vim", "cheatsheet"],
      };

      const success = await addNoteToAnki(note);
      if (success) {
        successCount++;
        console.log(`✓ Added: ${entry.command} -> ${entry.description}`);
      } else {
        failureCount++;
        console.log(`✗ Failed: ${entry.command}`);
      }

      // Add a small delay between requests to avoid overwhelming AnkiConnect
      if (i < entries.length - 1) {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    console.log(`\n🎉 Sync complete!`);
    console.log(`   Successfully added: ${successCount} notes`);
    console.log(`   Failed: ${failureCount} notes`);
  } catch (error: any) {
    console.error(`❌ Error during sync: ${error.message}`);
    console.error("\nMake sure:");
    console.error("1. Anki is running");
    console.error("2. AnkiConnect add-on is installed");
    console.error("3. The CSV file exists and is properly formatted");
    Deno.exit(1);
  }
}

// Learn more at https://docs.deno.com/runtime/manual/examples/module_metadata#concepts
if (import.meta.main) {
  sync(Deno.args[0]);
}
