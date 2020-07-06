# README

Rails project demonstrating a webpacker configuration that splits each vendor
library into individual chunks.

* Ruby 2.7.1
* Rails 6.0.3.2
* Webpacker 4.2.2

## Quick intro to webpacker

* Webpacker lets us use `webpack` within a Rails application
* Entry points are defined in `app/javascript/packs`
* Running `bin/rails webpacker:compile` will invoke `webpack` to process packs, calculate dependencies, generate chunks
* Generated chunks will appear under `public/packs/js`

## This project's webpack configuration

* Webpacker is configured to split vendor chunks into per-package chunks
```
  optimization: {
    minimize: true,
    runtimeChunk: 'single',
    splitChunks: {
      chunks: 'all',
      maxInitialRequests: Infinity,
      minSize: 0,
      cacheGroups: {
        // @see https://hackernoon.com/the-100-correct-way-to-split-your-chunks-with-webpack-f8a9df5b7758
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name(module) {
            const packageName = module.context.match(/[\\/]node_modules[\\/](.*?)([\\/]|$)/)[1];
            return `npm.${packageName.replace('@', '')}`;
          },
          priority: 10,
        },
      }
    }
  }
```
* We use `HashedModuleIdsPlugin` to attempt to make the chunk hashes stable across updates.
```
  plugins: [
    new webpack.HashedModuleIdsPlugin(),
  ],
```

# Problem

* For a project with existing JS library dependencies, importing a new library will cause previous vendor chunks to be rehashed unexpectedly
  * Existing library versions have not changed, so we expect the hash to be the same
  * Hash changes invalidate cached chunks on our CDN, which is wasteful and expensive

## Example

In this project, we make the following change to our entry point:

```diff
# app/javascript/packs/application.js
 require("@rails/ujs").start()
 require("turbolinks").start()
 require("@rails/activestorage").start()
 require("channels")
 import 'msr'
 import copy from 'clipboard-copy'
+import axios from 'axios'
```

We expect that with our current webpack configuration,

* existing vendor chunks remain unchanged
* a new vendor chunk is created for the newly added `axios` library

In actuality, all existing vendor chunks are rehashed. See below for
reproducing the problem.

## Script to reproduce problem

* The project includes `compile.sh` and `diff.sh` that will demonstrate the
  effect on output chunk files when adding a library dependency to the entry
  point.
* Usage: `./compile.sh` - this will run `webpack` on commits before and after
  the library dependency was added, then it will compare the difference in
  chunk files.

## Result

Here's the chunk diff produced by the script above:

```diff
--- a	2020-07-06 18:39:52.202440803 +0000
+++ b	2020-07-06 18:39:52.210440748 +0000
@@ -1,6 +1,8 @@
-application-1e8721172ae65f57286b.chunk.js
-npm.clipboard-copy-10b42ffbc97b4e927071.chunk.js
-npm.msr-01ea266e2c932167f10b.chunk.js
-npm.rails-a4564cfc542024efeb95.chunk.js
-npm.turbolinks-eeef46ff44962af9ac87.chunk.js
-npm.webpack-7226f5cf46a8c4e61c26.chunk.js
+application-bad0ed20808541f88894.chunk.js
+npm.axios-40b4b54ebace2b9e3907.chunk.js
+npm.clipboard-copy-79d2051f48603e0267e0.chunk.js
+npm.msr-f5a4252b7a7e0a94157f.chunk.js
+npm.process-cfe824ecbab5abe0eecc.chunk.js
+npm.rails-aa1c430d6ceee3ca6bd6.chunk.js
+npm.turbolinks-e28554dbfd4b75aa12e5.chunk.js
+npm.webpack-35f718d9a20b8bca2927.chunk.js
```

* As we mentioned above, we only added `axios` so we expected a one-line diff
  for a new axios vendor chunk file, but actually all vendor chunk files are
  rehashed.
