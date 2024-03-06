# Hotswap

When talking about programming, hotswap refers to switching out code at runtime, without restarting your program.

By default, Java only has this capability in a very limited fashion, and this only works inside of a development environment.

## DCEVM

DCEVM is a custom JVM that allows you to do a lot more hotswapping. Not only can you change method bodies, but also add new methods, remove methods, add new fields and classes, and more.

To install DCEVM, first download the installer from https://dcevm.github.io/. Get the installer for the latest Java 8 version (181). The DCEVM installer modifies an existing JVM, and does not work on its own.

Next you need to download [the corresponding JVM itself](https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html). For versions as old as 1.8u181 you might need to create an Oracle account. Newer versions of Java *will not work*.

Once you got the normal 1.8u181 JVM installed, you can launch the DCEVM installer you downloaded earlier. You should use another version of Java to launch the JAR, otherwise you might get issues on windows. DCEVM will prompt you where to install itself to. Choose your 1.8u181 installation and **replace the JVM**. Do **not** install as alt VM.

Once that is done (which should be fairly quick), you can exit the installer.

## Using DCEVM

In order to use DCEVM (or any other hotswap enabled JVM), you need to launch using that JVM. Edit your run configuration in your IDE. Note that you don't need to change the JVM for your entire Module, only for your run configuration. You may also need to manually add the JVM in IntelliJ by choosing "Select alternative JVM" (this is not the same as the alt VM from DCEVM, that one is unrelated).

Then you need to launch in debug mode. You can do that by selecting the :beetle: next to your normal :material-play: run button.

Once your game is started, you can reload your changes by pressing ++ctrl+f9++ (or using the build project keybind). Once your project is built, you should automatically get a prompt to reload your changes. If not, you might need to change "reload classes after compilation" in the IntelliJ settings.

## Caveats

Even with DCEVM you cannot change all the things. Initialization code is not run again, so thinks like event listers, registered commands, mixins and similar configuration that is done once break. Even some things like static fields don't get properly initialized. Sometimes changes cannot be properly detected and all classes get reloaded, resulting in most of your event listeners being unregistered. There isn't much that can be done in those situations. Watch your IntelliJ notifications to see how many classes are being reloaded and restart if you see numbers that are too big or too small.

## Hotswap Agent

!!! note
    This is an advanced topic, and this section is incomplete. You probably don't need to use hotswap agent and it can be quite a bit confusing to set up.

Hotswap Agent is a software that is run on top of DCEVM that allows for additional reloading of classes. It adds some built-in functionality for things like running static initializers, reloading logging configurations and a lot of other open source frameworks reloading.

For most people installing hotswap agent is easiest by using the IntelliJ plugin. Once the plugin is installed, go into your global settings, into "Tools > Hotswap" and check the checkbox next to your run configuration.

Check your logs for `Loading Hotswap agent {VERSION} - unlimited runtime class redefinition.` to see if hotswap agent is running. If you don't see that line, you probably only run DCEVM.

By default hotswap agent does not do anything about forge. You can check out [hotswapagent-forge](https://github.com/nea89o/hotswapagent-forge/) to receive runtime information about class reloads in forge.






