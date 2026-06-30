import { existsSync } from "node:fs";
import { dirname, resolve } from "node:path";

function isExternalOrSpecialUrl(url) {
    return /^(https?:)?\/\//.test(url) || url.startsWith("data:") || url.startsWith("#");
}

function normalizeImageUrl(url) {
    return url.split("#")[0].split("?")[0];
}

function walk(node, onImage, parent = null) {
    if (!node || typeof node !== "object") return;
    if (node.type === "image") {
        onImage(node, parent);
    }
    if (Array.isArray(node.children)) {
        for (const child of node.children) {
            walk(child, onImage, node);
        }
    }
}

/**
 * Replaces missing local markdown images with plain text so content build won't fail.
 */
export function remarkIgnoreMissingImages() {
    return (tree, file) => {
        const sourceDir = file?.path ? dirname(file.path) : process.cwd();

        walk(tree, (imageNode, parent) => {
            const originalUrl = imageNode?.url;
            if (!originalUrl || typeof originalUrl !== "string") return;
            if (isExternalOrSpecialUrl(originalUrl)) return;
            if (originalUrl.startsWith("/")) return;

            const normalized = normalizeImageUrl(originalUrl);
            const decoded = decodeURIComponent(normalized);
            const imagePath = resolve(sourceDir, decoded);

            if (existsSync(imagePath)) return;
            if (!parent || !Array.isArray(parent.children)) return;

            const index = parent.children.indexOf(imageNode);
            if (index === -1) return;

            const fallbackText = imageNode.alt?.trim()
                ? `[missing image: ${imageNode.alt}]`
                : "[missing image]";

            parent.children.splice(index, 1, { type: "text", value: fallbackText });
        });
    };
}
