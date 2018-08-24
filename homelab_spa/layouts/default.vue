<template>
  <div>
    <nav class="navbar is-light">
      <div class="navbar-brand">
        <a class="navbar-item" href="/">
          <h1 class="title"><icon name="door-open" scale="2.5" />Homelab</h1>
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
            <a class="navbar-link" href="/docs">
              Docs
            </a>
           </div>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <div class="field is-grouped">
              <p class="control">
                <a class="button" target="_blank" href="http://github.com/EnigmaCurry/homelab"><icon name="brands/github"/>Github</a>
              </p>
              <p class="control">
                <nuxt-link class="button" to="/about">About</nuxt-link>
              </p>
            </div>
          </div>
        </div>
      </div>
    </nav>
    <div id="content" class="container">
      <nuxt/>
    </div>
  </div>
</template>

<script>
export default {
  data: () => ({
    showNavMenu: false
  }),
};
</script>

<style scoped>
.navbar-brand .title {
  font-family: 'Source Code Pro'
}

div#content {
  margin: 1.5em;
}
.navbar-end .navbar-item .fa-icon {
  margin-right: 0.5em;
}
</style>
