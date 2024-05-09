/**
 * This script exists simply to get a locally built version of the
 * `openvscode-server-settings` plugin into the src directory in this repo so that
 * we can copy it over to the Docker container for installation. This is for
 * development purposes only. For production, the Dockerfile will clone the
 * `openvscode-server-settings` directly from Github into the container, buid
 * it, and install it from there.
 */

import {$} from 'bun'
import path from 'node:path'
import fs from 'node:fs'

const repoName = 'openvscode-server-settings'
const repoDir = path.resolve(import.meta.dir, `../${repoName}`)

// Change into the local repo directory.
process.chdir(repoDir)

// Ensure dependencies are installed.
if (!fs.existsSync(`${repoDir}/node_modules`)) {
  await $`bun install`
}

// Build the vsix file.
await $`bun run package`

// Get the name and absolute path to the vsix file.
const cliOutput = await $`ls *.vsix | head -n 1`.text()
const vsixFilename = cliOutput.trim()
const vsixPath = `${repoDir}/${vsixFilename}`

// Copy the vsix file into a directory our Dockerfile can access.
await $`cp ${vsixPath} ${import.meta.dir}/src`
