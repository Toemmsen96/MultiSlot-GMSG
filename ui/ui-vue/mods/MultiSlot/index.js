// MultiSlot Vue mod entry point.
// Registers the pause-menu tab (also done GE-side on extension load — both are idempotent,
// covering both Lua reloads and Vue mod reloads).
import { runRaw } from "@/bridge/libs/Lua"
import store from "./store.js"

export async function onLoad() {
  runRaw("extensions.tommot_modslotGenerator.registerPauseUi()", false)
  store.init()
}

export function onUnload() {
  store.dispose()
}
