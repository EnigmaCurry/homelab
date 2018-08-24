<template>
  <div>
   <nav class="navbar is-light">
  <div class="navbar-brand">
    <a class="navbar-item" href="/">
      <icon name="door-open" scale="2.5"></icon>
      <h1 class="title">Homelab</h1>
    </a>
    <div class="navbar-burger burger" data-target="navMenuColorlight-example" v-on:click="showNavMenu = !showNavMenu">
      <span></span>
      <span></span>
      <span></span>
    </div>
  </div>

  <div id="navMenuColorlight-example" class="navbar-menu" v-bind:class="{'is-active': showNavMenu}">
    <div class="navbar-start">
      <div class="navbar-item has-dropdown is-hoverable">
        <a class="navbar-link" href="/">
          Docs
        </a>
        <div class="navbar-dropdown">
          <a class="navbar-item" href="/">
            Overview
          </a>
          <a class="navbar-item" href="/">
            Modifiers
          </a>
          <a class="navbar-item" href="/">
            Columns
          </a>
          <a class="navbar-item" href="/">
            Layout
          </a>
          <a class="navbar-item" href="/">
            Form
          </a>
          <hr class="navbar-divider">
          <a class="navbar-item" href="/">
            Elements
          </a>
          <a class="navbar-item is-active" href="/">
            Components
          </a>
        </div>
      </div>
    </div>

    <div class="navbar-end">
      <div class="navbar-item">
        <div class="field is-grouped">
          <p class="control">
            <a>
              link 1
            </a>
          </p>
          <p class="control">
            <a >
              link 2
            </a>
          </p>
        </div>
      </div>
    </div>
  </div>
</nav> 
   <nuxt/>
  </div>
</template>

<script>
export default {
  data: () => ({
    showNavMenu: false
  })
}
</script>

