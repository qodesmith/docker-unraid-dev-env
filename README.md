# docker-unraid-dev-env

A container containing all-the-things I want for a dev environment to run on an
Unraid server.

## What's inside

### [Bun](https://bun.sh/)

Bun makes it so easy to run arbitrary TypeScript. No more compiling or fussing
around with Node.

### [VS Code](https://github.com/gitpod-io/openvscode-server)

I've got all my favorite plugins as well as my
[favorite theme](https://github.com/qodesmith/outrun-meets-synthwave) installed.
The hardest part was figuring out how to initialize VS Code with settings. Turns
out there's no out-of-the-box way to do it so I had to write a
[custom plugin](https://github.com/qodesmith/openvscode-server-settings) to do
it for me.

### [Zsh](https://www.zsh.org/)

Because nobody wants a vanilla terminal prompt 😎

## Development

The `package.json` file has a `build:local:dev` which expects the
[openvscode-server-settings](https://github.com/qodesmith/openvscode-server-settings)
repo to be in a sibling folder to this project. This is because I wanted a way
to locally test out changes to that plugin without having to push the changes
to Github first. The script will build that plugin locally and copy the
resulting `.vsix` file to the Docker container. The `build:local` script clones
the repo from Github.
