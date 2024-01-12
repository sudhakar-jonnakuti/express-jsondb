const fs = require("node:fs");
const { build, analyzeMetafile } = require("esbuild");
const { copy } = require("esbuild-plugin-copy");
const pkg = require("./package.json");

appBuild = async () => {
  try {
    const result = await build({
      entryPoints: ["src/**/*.ts"],
      outdir: "dist",
      minify: true,
      platform: "node",
      format: "cjs",
      treeShaking: true,
      bundle: true,
      metafile: true,
      external: [
        ...Object.keys(pkg.dependencies || {}),
        ...Object.keys(pkg.peerDependencies || {})
      ],
      plugins: [
        copy({
          resolveFrom: "cwd",
          assets: {
            from: ["src/database/post.database.json"],
            to: ["dist/database/post.database.json"]
          },
          watch: true
        })
      ]
    });

    if (result.metafile) {
      fs.writeFileSync("./dist/metafile.json", JSON.stringify(result.metafile));
    }
    console.log("Build successful:", await analyzeMetafile(result.metafile));
    process.exit(0);
  } catch (error) {
    console.error("Build failed:", error);
    process.exit(1);
  }
};

appBuild();
