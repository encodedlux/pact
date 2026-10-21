import { defineConfig } from "vitepress";
import { tabsMarkdownPlugin } from "vitepress-plugin-tabs";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Pact",
  titleTemplate: ":title - A strictly typed buffer networking library for Luau/Roblox",
  description: "A strictly typed buffer networking library for Luau/Roblox",
  base: "/pact/",
  cleanUrls: true,

  vite: {
    ssr: {
      noExternal: [
        '@nolebase/vitepress-plugin-highlight-targeted-heading',
      ]
    }
  },

  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin);
    }
  },

  themeConfig: {
    search: {
      provider: "local"
    },

    nav: [
      { text: "Home", link: "/" },
      { text: "Tutorials", link: "/tut/getting-started/1-overview" },
    ],

    sidebar: {
      "/tut/": [
        {
          text: "Getting Started",
          items: [
            { text: "Overview", link: "/tut/getting-started/1-overview" },
            { text: "Installation", link: "/tut/getting-started/2-installation" },
          ]
        },
        {
          text: "Guide",
          items: [
            { text: "Define", link: "/tut/guide/1-define" },
            { text: "Events", link: "/tut/guide/2-events" },
            { text: "Functs", link: "/tut/guide/3-functs" },
            { text: "States", link: "/tut/guide/4-states" },
            { text: "Scopes", link: "/tut/guide/5-scopes" },
            { text: "Types", link: "/tut/guide/6-types" },
          ]
        }
      ]
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/encodedlux/pact" }
    ]
  }
})
