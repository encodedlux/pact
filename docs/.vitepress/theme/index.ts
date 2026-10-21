import { h } from "vue";
import { DividePage } from "vitepress-theme-api";
import { Theme } from "vitepress";
import DefaultTheme, { VPButton } from "vitepress/theme";
import {
  NolebaseHighlightTargetedHeading
} from '@nolebase/vitepress-plugin-highlight-targeted-heading/client'
import { enhanceAppWithTabs } from 'vitepress-plugin-tabs/client'
import "./style.css";
export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      'layout-top': () => [
        h(NolebaseHighlightTargetedHeading),
      ],
    })
  },
  enhanceApp({ app, router, siteData }) {
    // ...
    app.component("DividePage", DividePage);
    app.component("Button", VPButton)
    enhanceAppWithTabs(app);
  },
} satisfies Theme;
