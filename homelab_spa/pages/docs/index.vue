<template>
  <div class="content">
    <div v-html="README"></div>
  </div>
</template>

<script>
import readme from '../../../README.md'

export default {
  computed: {
    README() {
      return readme
    }
  }
}
</script>