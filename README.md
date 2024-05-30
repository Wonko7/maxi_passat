Instructions
============

This project is (initially) generated by `eliom-distillery` as the basic
project `maxi_passat`.

Note that external dependencies are required prior to building the
project.  Postgres is mandatory. By default, NPM is used for
automatically installing various NPM packages; you can disable this
via the `USE_NPM` variable in `Makefile.options` if you prefer to use
a system-wide NPM installation. SASS is optional, but not installing
it may negatively impact the rendering of the pages generated. All
needed packages (Postgres, NPM, SASS, ...) and required OPAM packages can be
installed via the command (from the maxi_passat directory):

```shell
opam install .
```

If you have issues with the NPM provided by your distribution, you can
use [NVM](https://github.com/creationix/nvm). If NPM is too old (< 2.0),
you can try updating it with `sudo npm install -g npm`. Depending on your
setup, you may have to update your `$PATH` for the new `npm` to become
visible.

Generally, you can compile it and run ocsigenserver on it by

```shell
make db-init
make db-create
make db-schema
make test.byte (or test.opt)
```

Then connect to `http://localhost:8080` to see the running app skeleton.
Registration will work only if sendmail if configured on your system.
But the default template will print the activation link on the standard
output to make it possible for you to create your first users (remove this!).

See below for other useful targets for make.

Generated files
---------------

The following files in this directory have been generated by
`eliom-distillery`:

- `maxi_passat*.eliom[i]`
  Initial source file of the project.
  All Eliom files (*.eliom, *.eliomi) in this directory are
  automatically compiled and included in the application.
  To add a .ml/.mli file to your project,
  append it to the variable `SERVER_FILES` or `CLIENT_FILES` in
  Makefile.options.

- `static/`.
  This folder contains the static data for your app.
  The content will be copied into the static file directory
  of the server and included in the mobile app.
  Put your CSS or additional JavaScript files here.

- `Makefile.options`
  Configure your project here.

- `maxi_passat.conf.in`.
  This file is a template for the configuration file for
  Ocsigen Server. You will rarely have to edit it yourself - it takes its
  variables from the Makefile.options. This way, the installation
  rules and the configuration files are synchronized with respect to
  the different folders.

- `mobile`
  The files needed by Cordova mobile apps

- `Makefile`
  This contains all rules necessary to build, test, and run your
  Eliom application. See below for the relevant targets.

- `README.md`


Makefile targets
----------------

Here's some help on how to work with this basic distillery project:

- Initialize, start, create, stop, delete a local db, or show status:
```Shell
make db-init
make db-start
make db-create
make db-stop
make db-delete
make db-status
```

- Test your application by compiling it and running ocsigenserver locally
```
make test.byte (or test.opt)
```

- Compile it only
```Shell
make all (or byte or opt)
```

- Deploy your project on your system
```Shell
sudo make install (or install.byte or install.opt)
```

- Run the server on the deployed project
```Shell
sudo make run.byte (or run.opt)
```

If `WWWUSER` in the `Makefile.options` is you, you don't need the
`sudo`. If Eliom isn't installed globally, however, you need to
re-export some environment variables to make this work:
```Shell
sudo PATH=$PATH OCAMLPATH=$OCAMLPATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH make run.byte/run.opt
```

- If you need a findlib package in your project, add it to the
  variables `SERVER_PACKAGES` and/or `CLIENT_PACKAGES`. The configuration
  file will be automatically updated.

Build the mobile applications
-----------------------------

## Prepare the mobile infrastructure.

### For all mobile platforms:

Make sure you have a working NPM installation. The needed NPM packages
(like Cordova) will be installed automatically.

Warning: NPM packages (and especially Cordova plugins) are very sensitive to
version changes. You may have to change version numbers in
`mobile/config.xml.in` if something goes wrong during app generation.
You may also have problems with old versions of `gradle` or wrong versions
of Android packages ...

If npm is causing a lot of errors (on Debian) in the following parts of the installation, an advice would be to uninstall nodejs and npm and do a clean installation of them **with aptitude**.

This installation was tested with those versions:

```
npm : 6.14.12
nodejs : v10.24.1
```

**Be prepared! You're entering an unstable world!**

### For Android:

- Install JDK 11 (`openjdk-11-jdk` package in Debian/Ubuntu)

  Run those commands and look carefully if the checked option for java and javac are from the same repository:
  ```
  sudo update-alternatives --config java
  sudo update-alternatives --config javac
  ```
- Install Gradle (`gradle` package in Debian/Ubuntu)
- Download and untar the [Android SDK](http://developer.android.com) (the smaller version without Android Studio is sufficent), rename it so that you have a `$HOME/android-sdk-linux/tools` folder.
- Using the Android package management interface (or sdkmanager):
  * List All System Images Available for Download: `sdkmanager --list | grep system-images`\
    (*As an example we're going to choose "system-images;android-26;default;x86" but you can choose your way.*)
  * Download Image: sdkmanager --install "system-images;android-26;default;x86"\
    (*Be aware that version > android-26 may not work.*)

If you want to emulate an Android device, you need to create an emulator :

```
echo "no" | avdmanager --verbose create avd --force --name "generic_10" --package "system-images;android-26 default;x86" --tag "default" --abi "x86"
# Check every available options that offers avdmanager to customize your emulator as you wish.
```

There is a couple more steps to follow:

Unfortunately there are two named emulator binary file, which are located under `$ANDROID_SDK/tools/emulator` and the other is under `$ANDROID_SDK/emulator/`.\
Make sure you have the right emulator configure (you need to add `$ANDROID_SDK/emulator` to your env PATH).

In order to do this:

1. Add in your `~/.bashrc` (or `~/.zshrc`) file:
    ```sh
    export ANDROID_SDK=$HOME'your_path_to_android_sdk'
    export PATH=$ANDROID_SDK/emulator:$PATH
    export PATH=$ANDROID_SDK/tools:$PATH
    export PATH=$ANDROID_SDK/tools/bin:$PATH
    export PATH=$ANDROID_SDK/platform-tools:$PATH
    export ANDROID_SDK_ROOT=$ANDROID_SDK 
    export ANDROID_AVD_HOME=$HOME/.android/and
    alias emulator='$ANDROID_SDK/emulator/emulator'
    ```
2. Then execute this command in your shell: `source ~/.bash_profile`
3. And show the installed emulators with: `emulator -list-avds`\
   You should have something displaying like:
   ```sh
   generic_10
   # Or even something like :
   Pixel_2_API_29
   Pixel_3a_API_29
   Pixel_C_API_29
   ```

### For iOS:

- Xcode installs all dependencies you need.

- Some iOS-specific code exists. You should check it out. For instance, looking carefully at the [`PROJECT_NAME.conf.in`](PROJECT_NAME.conf.in) file is mandatory if you're building an iOS app.

### For Windows:

Ocsigen Start uses
[cordova-hot-code-push-plugin](https://github.com/nordnet/cordova-hot-code-push)
to upload local files (like CSS and JavaScript files, images and logo) when the
server code changes.

Unfortunately, this plugin is not yet available for Windows Phone. However, as
ocsigen Start also builds the website part, an idea is to run the website into a
WebView on Windows Phones.

Even if Cordova allows you to build Windows app, it doesn't authorize you to
load an external URL without interaction with the user.

Another solution is to build an [Hosted Web
App](https://developer.microsoft.com/en-us/windows/bridges/hosted-web-apps). It
makes it possible to create easily an application based on your website. You can
also use Windows JavaScript API (no OCaml binding available for the moment) to
get access to native components. You can create the APPX package (package format
for Windows app) by using [Manifold JS](http://manifoldjs.com/), even if you are on MacOS X or Linux.

If you are on Windows, you can
use [Visual Studio Community](https://www.visualstudio.com/fr/vs/community/).
The Visual Studio Community solution is recommended to test and debug. You can
see all errors in the JavaScript console provided in Visual Studio.

[Here](https://blogs.windows.com/buildingapps/2016/02/17/building-a-great-hosted-web-app/#3mlzw0giKcuGZDeq.97) a
complete tutorial from the Windows blog for both versions (with Manifold JS and
Visual Studio).

If you use the Manifold JS solution, you need to sign the APPX before installing it on a device.

## Launching the mobile app

The following examples are described for Android but they are also available
for iOS: you only need to replace `android` by `ios`.

- Launch an Ocsigen server serving your app:
```
make test.opt
```

In the following commands, if `APP_REMOTE` is `yes`, the mobile app will
be created by getting all the necessary files (js, etc) from a server.
This may be used to create a mobile app for an which has not been
compiled locally. With `APP_REMOTE=no`, the local files will be used.

The remote server address is given in the variable `APP_SERVER`.
Replace `${YOUR_SERVER}` by `${YOUR_IP_ADDRESS}:8080` in the following
commands if you want to test on your local machine.

- To run the application in the emulator, use:

```
make APP_SERVER=http://${YOUR_SERVER} APP_REMOTE=no APP=dev emulate-android
```

The above command will attempt to launch your app in the Android emulator that
you have configured previously. Depending on your setup, you may need to start
the emulator before running the command.

Note: If the emulator does not start on your Linux system because of
a library problem, you can try to set the environment variable
`ANDROID_EMULATOR_USE_SYSTEM_LIBS` to `1` to make it start (see
https://developer.android.com/studio/command-line/variables.html for
details).

To run the application on a connected device, use:

```
make APP_SERVER=http://${YOUR_SERVER} APP_REMOTE=no APP=dev run-android
```
Notice that the `APP_SERVER` argument needs to point to your LAN or public
address (e.g., `192.168.1.x`), not to `127.0.0.1` (neither to `localhost`). The
reason is that the address will be used by the Android emulator/device, inside
which `127.0.0.1` has different meaning; it points to the Android host itself.

If you only want to build the mobile application, you can use:
```
make APP_SERVER=http://${YOUR_SERVER} APP_REMOTE=no APP=dev android
```

Before uploading on Google Play Store, check the variables in Makefile.options
(MOBILE_APP_IP, version number, etc).
You'll need to build a release version (default is debug version):
```
make APP_SERVER=http://${YOUR_SERVER} APP_REMOTE=no android-release
```
then sign it (see Android documentation).

If you want the application URL to include a path
(`http://${YOUR_SERVER}${PATH}`),
you need to provide an additional `APP_PATH` argument, e.g.,
`APP_PATH=/foo`. You need to include the leading `/`, but no trailing
`/`. You also need to modify the `maxi_passat.conf.in` with a
[`<site>` tag](http://ocsigen.org/ocsigenserver/manual/config#h5o-31).

Note: if any of the mobile-related targets fails due to the inexistent
`node` command, you may need to create a symlink from `node` to
`nodejs`, e.g., as follows:

```
ln -s /usr/bin/nodejs /usr/local/bin/node
```

## Update the mobile application.

The mobile app is updated automatically at launch time, every time the
server has been updated. To do that, Ocsigen Start is using Cordova Hot
Code Push.

In order to make it work, you MUST use the following command every time
you update the server:
```
make APP_SERVER=http://${YOUR_SERVER} APP_REMOTE={yes|no} chcp
```

## Use Makefile.local file.

You need to define `APP_REMOTE` and `APP_SERVER` each time you want to build
the mobile application or to update it. The `APP` variable is not mandatory per
say but when set to `dev` it enables cleartext traffic, so you might want to
keep it on while working on dev builds.

If you don't want to pass the variables `App`, `APP_SERVER` and
`APP_REMOTE` every time, you can change the values of these variables in
`Makefile.local.example` and rename this file to `Makefile.local`. This way,
the variables `App`, `APP_REMOTE` and `APP_SERVER` are not mandatory when you build
or update the mobile application. You can use:
```
make chcp
make run-android
make run-ios
...
```

This file is meant for rules and variables that are only relevant for local development
and it must not be deployed or shared (by default, this file is ignored by Git).
