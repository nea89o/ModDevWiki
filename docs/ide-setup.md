# Setting up

This is a slightly rewritten version of [SBMW's Getting started article](https://sbmw.ca/development/getting-started/). That one was also written by me, and contains roughly the same info.

!!!note
    Downloads in this tutorial are provided as a convenience, if you know what you are doing you can find these downloads somewhere else (in a package manager like chocolatey, pacman or [sdkman](https://sdkman.io/)). If you decide to go that route, please make sure that you download the exact same Software and not something similar.

## Setting up a Java Development Environment

Minecraft mods are written in Java and as such you will need a Java Development Setup. You will need *both*

 - [A Java JDK (*not JRE*) for version 17](https://adoptium.net/temurin/releases?version=17)
 - [A Java JDK (*not JRE*) for version 8](https://adoptium.net/temurin/releases?version=8)

## Setting up an Integrated Development Environment

There is pretty much only one IDE for mod development, which is [IntelliJ](https://www.jetbrains.com/idea/). In theory it is also possible to code in VSCode, Vim or Eclipse, but doing so is difficult to set up and not recommended. Even if you are already familiar with one of these IDEs, switching to IntelliJ is pretty much mandatory.

IntelliJ has a free community edition, as well as a paid ultimate edition, both available for download [here](https://www.jetbrains.com/idea/download/other.html).


## Setting up GitHub

Although not strictly neccessary, it is recommended that you create a [GitHub](https://github.com) Account. This tutorial will assume you have one. If you do not have a GitHub Account you might need to find some more manual work arounds for some things.

## Deciding on a Project

### Contributing to an existing Project

If you want to contribute to an existing project, find that project on GitHub and Discord. You can usually find both linked on their page on the [SkyBlock Mod Wiki][mod-list]. You can typically ask around in the Discord for help, which will help you to get up to speed with whether they will accept a feature you are planning to contribute. Once all of that is cleared, you can create a Fork on GitHub. You will then do everything with the forked repository as you would do with your own repository, and once you are done create a pull request in the original repository you are planning to contribute to.

### Creating a new Project

Go to [Forge1.8.9Template](https://github.com/nea89o/Forge1.8.9Template/). Click on "Use this template" and "Create a new Repository". Find a good name for your mod. If you want to code your mod in Kotlin or make a 1.12 mod you will need to tick "Include all branches". Don't worry about it too much, you can change this later with a little bit of effort.

!!! warning
    Do not clone the template repository directly (or download a zip of the template repository). When using the "Use this template" option on GitHub, there is some additional processing being done to insure your repository is fully set up.

    If you *must* you can also manually use the `make-my-own.sh` script, but only on Linux, and there are no guarantees for it to work.

## Setting up your IDE

IntelliJ has a built in option for cloning a project. Chose "New" then "Project from Version Control". Log into GitHub and clone the project.

Once the project is done cloning, you need to head into your :simple-gradle: gradle settings (the elephant on the right of your workspace, then click on the cogwheel) and change the gradle JVM to be a version *17* JDK.

Next go into your Project Settings (++ctrl+alt+shift+s++) and set the Project SDK to be a version 8 JDK.

Finally click on the reload button in the gradle tab on the right from earlier.

You should now have generated a Run Config in IntelliJ. You can find those next to the :material-play:. If you can't find it, check the :material-folder:`.idea/runConfigurations` folder. If you can find a file there, you just need to restart IntelliJ.

Always use these run configs instead the `runClient` task in the gradle tab. The gradle task ***does not work***.

## Common Issues

### No matching variant of dev.architectury:architectury-pack200:0.1.3 was found.

This error indicates that your Java Version does not support architectury. Fix this by setting your gradle JDK to 17

### Unsupported class file major version 65

This error indicates that your Java version is too new. Fix this by setting your gradle JDK to use exactly java version 17, not something newer like Java 21.






