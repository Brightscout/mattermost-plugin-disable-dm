# mattermost-plugin-disable-dm
A mattermost plugin to disable direct messages and group chats.

## Installation and setup
#### Platform & tools
- Make sure you have following components installed:

  * Go - v1.11 - https://golang.org/doc/install
    > **Note:** If you have installed Go to a custom location, make sure the $GOROOT variable is set properly. Refer [Installing to a custom location](https://golang.org/doc/install#install).

  * NodeJS - v10.11 and NPM - v6.4.1 - https://docs.npmjs.com/getting-started/installing-node

  * Make


## Building the plugins
- Run the following commands to prepare a compiled, distributable plugin zip:

```
$ mkdir -p ${GOPATH}/src/github.com/Brightscout
$ cd ${GOPATH}/src/github.com/Brightscout
$ git clone git@github.com:Brightscout/mattermost-plugin-disable-dm.git
$ cd mattermost-plugin-disable-dm
$ make dist
```


- This will produce three tar.gz files in `/dist ` directory corresponding to various platforms:

| Flavor  | Distribution |
|-------- | ------------ |
| Linux   | `mattermost-plugin-disable-dm-v<X.Y.Z>-linux-amd64.tar.gz`   |
| MacOS   | `mattermost-plugin-disable-dm-v<X.Y.Z>-darwin-amd64.tar.gz`  |
| Windows | `mattermost-plugin-disable-dm-v<X.Y.Z>-windows-amd64.tar.gz` |

This will also install, **Glide** - the Go package manager.

## Install the plugin to Mattermost
- Make sure that the plugin uploads are enabled in `PluginSettings.EnableUploads` in your `config.json` file.
- Go to **System Console > Plugins (Beta) > Management** and set `Enable Plugins` to `true`.
- From **System Console > Plugins (Beta) > Management**, upload the plugin generated above based on the OS of your Mattermost server.
- Once installed, open **System Console > Plugins (Beta) > Team Membership** in left-hand sidebar and configure the plugin settings.
- Enable the plugin from **System Console > Plugins (Beta) > Management**.

---

Made with &#9829; by [Brightscout](http://www.brightscout.com)
