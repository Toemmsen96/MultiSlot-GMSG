<template>
  <div class="ms-card" v-bng-scoped-nav>
    <BngCardHeading class="block-heading" type="ribbon">MultiSlot Mods</BngCardHeading>
    <div class="ms-button-row">
      <BngButton accent="attention" :disabled="store.state.busy" @click="store.generateMultiSlot()">
        Generate
      </BngButton>
      <BngButton accent="outlined" :disabled="store.state.busy" @click="store.generateMultiSlotConcurrent()">
        Generate concurrently
      </BngButton>
    </div>

    <BngCardHeading class="block-heading" type="ribbon">SingleSlot Mods</BngCardHeading>
    <div class="ms-button-row">
      <BngButton accent="attention" :disabled="store.state.busy" @click="store.generateSeparate()">
        Generate
      </BngButton>
      <BngButton accent="outlined" :disabled="store.state.busy" @click="store.generateSeparateConcurrent()">
        Generate concurrently
      </BngButton>
    </div>

    <BngCardHeading class="block-heading" type="ribbon">MultiSlot from Additional Mods</BngCardHeading>
    <div class="ms-button-row">
      <BngButton accent="attention" :disabled="store.state.busy" @click="store.generateAdditionalToMultiSlot()">
        Generate
      </BngButton>
      <BngButton accent="outlined" :disabled="store.state.busy" @click="store.generateAdditionalToMultiSlotConcurrent()">
        Generate concurrently
      </BngButton>
    </div>
  </div>
</template>

<script setup>
import { BngCardHeading, BngButton } from "@/common/components/base"
import { vBngScopedNav } from "@/common/directives"
import store from "../store.js"
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

.ms-button-row {
  display: flex;
  gap: 0.5em;
  flex-wrap: wrap;
}
</style>
