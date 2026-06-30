// @ts-check
import { defineConfig } from "astro/config";
import mdx from "@astrojs/mdx";
import { unified } from "@astrojs/markdown-remark";
import tailwindcss from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";
import svelte from "@astrojs/svelte";
import { remarkIgnoreMissingImages } from "./src/remark/remark-ignore-missing-images.js";

import cloudflare from "@astrojs/cloudflare";

// https://astro.build/config
export default defineConfig({
    // UPDATE THIS FOR PRODUCTION – This will also be used in the sitemap
    site: process.env.PRODUCTION_DOMAIN || "http://localhost:4321",

    integrations: [
        mdx(),
        sitemap({
            customPages: [
                process.env.PRODUCTION_DOMAIN || "http://localhost:4321", // home page - priority 1.0
                (process.env.PRODUCTION_DOMAIN || "http://localhost:4321") +
                    "/ru/", // Slovenian home - priority 1.0
            ],
            changefreq: "monthly",
            priority: 0.7,
            lastmod: new Date(),
        }),
        svelte(),
    ],
    markdown: {
        processor: unified({
            remarkPlugins: [remarkIgnoreMissingImages],
        }),
    },

    vite: {
        plugins: [tailwindcss()],
    },

    adapter: cloudflare(),
});
