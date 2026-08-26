<template>
  <div class="ms-card" v-bng-scoped-nav>
    <BngCardHeading class="block-heading" type="ribbon">Generation</BngCardHeading>
    <BngSwitch :model-value="!!cfg.MULTISLOT_MODS" @update:modelValue="v => store.setSetting('MultiSlotMods', v)">
      Generate MultiSlot Mods
    </BngSwitch>
    <BngSwitch :model-value="!!cfg.SEPARATE_MODS" @update:modelValue="v => store.setSetting('SeparateMods', v)">
      Generate SingleSlot Mods
    </BngSwitch>
    <BngSwitch :model-value="!!cfg.ADDITIONAL_TO_MULTISLOT" @update:modelValue="v => store.setSetting('AdditionalToMultiSlot', v)">
      Generate Additional as MultiSlot-Mods
    </BngSwitch>
    <BngSwitch :model-value="!!cfg.USE_COROUTINES" @update:modelValue="v => store.setSetting('UseCoroutines', v)">
      Generate Mods concurrently (less of a lag spike)
    </BngSwitch>
    <BngSwitch :model-value="!!cfg.AUTOPACK" @update:modelValue="v => store.setSetting('Autopack', v)">
      Autopack all generated Mods (WIP, buggy!)
    </BngSwitch>
    <BngSwitch :model-value="!!cfg.CACHE_GENERATED_MODS" @update:modelValue="v => store.setSetting('CacheGeneratedMods', v)">
      Cache Generated Mods (skip regenerating on next launch)
    </BngSwitch>

    <BngCardHeading class="block-heading" type="ribbon">Vehicle</BngCardHeading>
    <BngSwitch :model-value="!!cfg.QUEUE_VEHICLE_RELOADING" @update:modelValue="v => store.setSetting('QueueVehicleReloading', v)">
      Queue Vehicle Reloading (Same as CTRL+R, but automatic after generation)
    </BngSwitch>

    <BngCardHeading class="block-heading" type="ribbon">Logging</BngCardHeading>
    <BngSwitch :model-value="!!cfg.DET_DEBUG" @update:modelValue="v => store.setSetting('DetailedDebug', v)">
      Detailed Debug
    </BngSwitch>
    <div class="ms-field">
      <span class="ms-field-label">Log Level</span>
      <BngDropdown :items="logLevelItems" :model-value="cfg.LOGLEVEL" @update:modelValue="v => store.setSetting('LogLevel', v)" />
    </div>

    <BngButton class="ms-self-start" accent="destructive" @click="store.resetSettingsToDefaults()">
      Reset Settings to Default
    </BngButton>
  </div>
</template>

<script setup>
import { computed } from "vue"
import { BngCardHeading, BngSwitch, BngDropdown, BngButton } from "@/common/components/base"
import { vBngScopedNav } from "@/common/directives"
import store from "../store.js"

const cfg = computed(() => store.state.cfg || {})
const logLevelItems = [
  { value: 0, label: "No Logs" },
  { value: 1, label: "Info & Warnings" },
  { value: 2, label: "All Logs" },
]
</script>

<style scoped lang="scss">
.ms-card {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  width: 100%;
  padding: 0.5rem;
  color: var(--bng-off-white);
}

.block-heading {
  margin-top: 0.5em;
  margin-bottom: 0;
  margin-left: -0.4em;

  &:first-child {
    margin-top: 0;
  }
}

.ms-field {
  display: flex;
  flex-direction: column;
  gap: 0.25em;
}

.ms-field-label {
  font-size: 0.85em;
  opacity: 0.75;
}

.ms-self-start {
  align-self: flex-start;
}
</style>
