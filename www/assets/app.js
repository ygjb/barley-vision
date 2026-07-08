const bytes = new Intl.NumberFormat(undefined, {
  style: "unit",
  unit: "byte",
  unitDisplay: "narrow",
});

function formatBytes(value) {
  if (!Number.isFinite(value)) return "Unknown";
  const units = ["B", "KB", "MB", "GB", "TB"];
  let size = value;
  let index = 0;
  while (size >= 1024 && index < units.length - 1) {
    size /= 1024;
    index += 1;
  }
  return `${size.toFixed(size >= 10 || index === 0 ? 0 : 1)} ${units[index]}`;
}

function setText(id, value) {
  const node = document.getElementById(id);
  if (node) node.textContent = value;
}

async function loadStatus() {
  const response = await fetch("/api/status.json", { cache: "no-store" });
  if (!response.ok) throw new Error("status unavailable");
  const status = await response.json();

  setText("last-updated", `Updated ${new Date(status.generatedAt).toLocaleString()}`);
  setText("camera-status", status.camera.present ? "Present" : "Not detected");
  setText("motion-status", status.motion.running ? "Running" : "Not running");
  setText("recording-count", `${status.storage.recordingCount} clips, ${status.storage.snapshotCount} snapshots`);
  setText("storage-used", formatBytes(status.storage.recordingsBytes));
  setText("drive-free", formatBytes(status.storage.freeBytes));
}

async function loadRecordings() {
  const response = await fetch("/api/recordings.json", { cache: "no-store" });
  if (!response.ok) throw new Error("recordings unavailable");
  const files = await response.json();
  const events = files.filter((item) => item.kind === "recording").slice(0, 8);
  const container = document.getElementById("recent-events");
  container.innerHTML = "";

  if (events.length === 0) {
    container.innerHTML = '<p class="muted">No recordings yet.</p>';
    return;
  }

  for (const event of events) {
    const row = document.createElement("article");
    row.className = "event";
    const when = new Date(event.mtime * 1000);
    row.innerHTML = `
      <div>
        <a href="/recordings/${event.path}">${when.toLocaleString()}</a>
        <p class="muted">${event.path}</p>
      </div>
      <span>${formatBytes(event.size)}</span>
    `;
    container.appendChild(row);
  }
}

async function refresh() {
  try {
    await Promise.all([loadStatus(), loadRecordings()]);
  } catch (error) {
    setText("last-updated", "Status unavailable");
    console.error(error);
  }
}

refresh();
setInterval(refresh, 30000);
