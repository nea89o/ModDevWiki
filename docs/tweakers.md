# Tweakers and FMLLoadingPlugins

Forge offers a ton of capabilities to modders. A lot of things are hooked into events and nearly all methods in the Minecraft are callable from mod code.

But there are also limits. A lot of early loading (such as automatically loading dependencies) cannot be done using the Forge APIs. Similarly if a method or class is private or a certain method you would like an event for isn't hooked you can quickly run into problems.

Tweakers allow you to hook into early code, changing the way things are loaded, modifying classes to inject arbitrary calls and attributes into classes you don't own. They are immensely powerful, but also quite confusing and difficult to get right.

Note that I will talk about Tweakers for the most part here. `IFMLLoadingPlugin`s have similar capabilities for the most part and are more difficult to set up. They also have some unique capabilities which I'll cover at the end, but for now Tweakers are fine. I might also cover some other details of the FML launch process and the launchwrapper that aren't *strictly* part of the tweaker API.

## Getting Started

You probably have used a tweaker already. [Mixins](./mixins/) are loaded using a tweaker as well. You might not have realized since it is included in a bunch of templates already, but the tweaker system is exactly what allows mixin to modify all kinds of classes on your behalf.

Running [multiple tweakers](#delegating-tweakers) is usually a bit difficult, but while we are in a development environment we can just keep adding more `--tweakClass <className>` arguments. Those can be set in your loom settings in the `build.gradle.kts` file:

```kotlin
loom {
    launchConfigs {
        "client" {
            // You should already have a loom block, you can just add it in there
            arg("--tweakClass", "com.mymod.init.MyTweaker")
        }
    }
}
```

!!! note
    Note that we make use of a fully classified class name here (including the package). We also need to choose a dedicated package and *cannot* put it in a package with anything except tweaker related classes. Typically those packages are named either `init` or `tweaker`, although you can find other names too.

    Classes outside of that package are not typically available to the tweaker. While there are some ways to access those classes, most of them result in multiple classes being loaded down the line or other similar crashes, so put all of your tweaker classes and the classes those classes access into their own package.

    Referring to classes by `SomeClass.class.getName()` would be nicer, but sadly this does load a class, so try to avoid that if possible and use normal fully qualified strings instead.

Next we create the actual tweaker. For now that just means implementing the `:::java ITweaker`.

```java
package com.mymod.init;

public class TestTweaker implements ITweaker {
    @Override
    public void acceptOptions(List<String> args, File gameDir, File assetsDir, String profile) {

    }

    @Override
    public void injectIntoClassLoader(LaunchClassLoader classLoader) {

    }

    @Override
    public String getLaunchTarget() {
        return null;
    }

    @Override
    public String[] getLaunchArguments() {
        return new String[0];
    }
}
```

These are the default implementations of all the methods, so you can just implement the `:::java ITweaker` interface and auto implement the methods.

Feel free to add a few print statements into those methods and see what happens.

But what do those methods *actually* do (aside from very early print statements):

- `getLaunchTarget` returns the main class of Minecraft. Since there can be multiple tweakers only the first "primary" tweaker is called to get the main class. For mods (like we are writing) this method never gets called.

-   `getLaunchArguments` gets called for each tweaker and has to return an array. Those arrays get concatenated and are used as arguments for the Minecraft main method. You can set any option here that *Minecraft* expects. Note that options expected by other tweakers or Forge itself are ignored here. So extra `--tweakClass` args here are ignored.

    Some interesting arguments are `--uuid`, `--username` and `--accessToken`. Those are how DevAuth are implemented (which is another tweaker under the hood). Check out `net.minecraft.client.main.Main` for more options, but most of the time this stays empty.

- `acceptOptions` allows you to process arguments passed into Minecraft. The `args` array contains all unrecognized options, so it does not include the other options passed into that method (`--gameDir`, `--assetsDir`, `--version` which is called `profile`). It also does not include the `--tweakClass` arguments. We will learn how to access other tweakers later on. Most mods also ignore that method.

Lastly we have `injectIntoClassLoader`. So let's go over how to use `LaunchClassLoader` that is provided.

## Loading dependencies

Before we get into the juicy stuff, let's talk about something basic. How about adding some dependencies?

Usually you just include all your dependencies into a JAR, but sometimes you don't want that. There are a couple of possible reasons for this:

- Dynamically not loading a dependency if another mod is installed. Maybe that mod already bundles (or is) the dependency.
- Dynamically loading a dependency from a remote location. Maybe you have some big dependencies you don't want users to update every time they download a new version.
- Dynamically loading a dependency depending on some other variable, like depending on the operating system or even the Minecraft version.
- Downloading external code for auto updates. (Please don't do this btw. Just use a [regular updater](https://github.com/nea89o/libautoupdate) instead, it will be easier to set up, more transparent to users when they get a prompt and not slow down startup as much.)

If you have done dynamic class loading in the past you might know that you can achieve a lot of these things using a `URLClassLoader`. We can use the `LaunchClassLoader` in much the same way, except with some extra gadgets related to loading Minecraft classes.

```java
@Override
public void injectIntoClassLoader(LaunchClassLoader classLoader) {
    try {
        File downloadedFile = downloadSomeDependencyIfNotAlreadyOnDisk();
        classLoader.addURL(downloadedFile.toURI().toURL());
    } catch (IOException e) {
        throw new RuntimeException(e);
    }
}
```

## Blackboard

Sometimes you will want to communicate with other mods and their tweakers. This is most easily done through the blackboard. Directly accessing another mods tweaker is dangerous (although possible). Usually there is a lot of reflection involved and because we are so early in loading a lot of classes are not available yet (especially the ones outside of tweaker packages).

This is where blackboards come in. Blackboards allow mods to easily share data.

The blackboard is available using `Launch.blackboard` and is a simple `Map<String, Object>`. I would generally encourage you to only put objects in there that are made up entirely of simple java objects (`java.*` objects).

Similarly I would encourage you to use fully qualified names if possible: `:::java "com.mymod.init.Tweaker.someProp"`. This way name collisions can be avoided.

Let's go over some use cases of the blackboard.

### Delegating tweakers

While you can have many tweakers in a devenv, loading multiple tweakers from a JAR is not possible. Instead you can load one tweaker which will then instruct the launch process to load a second tweaker. This is done via `Launch.(List<String>) blackboard.get("TweakClasses")`

```java
    @Override
    public void injectIntoClassLoader(LaunchClassLoader classLoader) {
        List<String> tweakClasses = (List<String>) Launch.blackboard.get("TweakClasses");
        tweakClasses.add("com.mymod.init.SomeOtherTweaker");
    }
```

This can be combined with new dependencies added via `addURL` to load tweakers from dependencies as well.

These types of tweakers are sometimes also called cascading tweakers.

All loaded tweakers can be accessed via `:::java (List<ITweaker>) Launch.blackboard.get("Tweaks")`. This list can be useful sometimes, but should be considered read-only.

Another pit fall is when you can cascade new tweakers. You can only do so during `acceptOptions` and `injectIntoClassLoader`. At any other point in time the new tweakers can be either ignored or cause a crash.

### Negotiating

When negotiating some kind of version or other token that needs to be inspected by all tweakers before doing a final decision it pays to know how tweakers are processed. So, now a word about that.

The first tweaker that is loaded is the FML tweaker. This might be surprising, but the whole tweaker system is not actually done by Forge itself, but instead is part of what is called the launchwrapper. FML is just one big user of this system. The first FML tweaker now looks through your mod folder and loads a bunch of mods from there. First all `IFMLLoadingPlugin`s are loaded. Those are then wrapped into tweaker wrappers to hand them back to the launchwrapper. This way `IFMLLoadingPlugin`s can interact with tweakers in all the same way a normal `ITweaker` could (but notably with a more complex setup).

After all those plugins are loaded the tweakers from those same mods are loaded also, both of those get added to the `TweakClasses` list from earlier as cascading tweakers.

The tweakers and plugins are also sorted, based on the priority given to them using annotations (for `IFMLLoadingPlugin`) or the `TweakOrder` manifest attribute in a JAR. Note that the tweak order only applies for the methods called, not for the constructor or the `:::java static` init blocks.

Most of this does not matter for most users. What does matter is in what order methods are executed.

1. Run the static init and the constructor for each tweaker, one after the after.
2. Then run `acceptOptions` and `injectIntoClassLoader` for each tweaker.
3. If any new tweakers got added to `TweakClasses`, go back to step 1. (Note that duplicate class names get removed here, in case two tweakers add the same tweaker to be cascaded)
4. Once there are no more tweakers to be constructed and processed we continue
5. Now we collect all the arguments using `getLaunchArguments` from every tweaker
6. After all that has been collected the primary tweaker gets asked to provide a main class using `getLaunchTarget`.

As you can see there is a break in the middle, so you can synchronize all your tweakers by doing negotiation during `acceptOptions`, and then executing a final action in `getLaunchArguments`. For example you can put a version number into the blackboard in `acceptOptions` if you are higher than the current number in that blackboard variable. Then in `getLaunchArguments` you know that every other tweaker has put their number in the variable, so if you are still the highest variable, you are the tweaker with the most up to date version who should inject their dependency. Note here that you can still access the `LaunchClassLoader` after the `injectIntoClassLoader` method has been called using `Launch.classLoader`.

## Transformers

This is the big one. Class transformers allow you to change arbitrary code in your own mod, other mods, Forge and even Minecraft itself. There are some exclusions (such as not allowing to modify other tweakers and some core libraries), but almost all code can be changed.

!!!note
    This section presumes you have some familiarity with the java class file format. That kind of a tutorial would be a big undertaking, but if someone wants to pay me handsomely for it, i will do it.

At it's core a class transformer operates on JVM class files. Every class loaded can be transformed before by simply changing the class files contents. To do this the class transformer is given some information on which class it is operating on, as well as the bytes making up the original file. It is then expected to hand back a new byte array containing the modified file. This `.class` file is then loaded by the JVM.

Operating on raw bytes is rarely advisable and so Forge ships with the [asm library](https://asm.ow2.io/). Asm allows parsing a bytearray into a structure called a `ClassNode` (i will not be covering visitors here, even tho they can be more efficient). Accordingly a simple transformer scaffold to construct a `ClassNode` could look something like this:

```java
public class TestTransformer implements IClassTransformer {
    @Override
    public byte[] transform(String name, String transformedName, byte[] basicClass) {
        if (!name.equals("net.minecraft.client.Minecraft")) return basicClass;
        ClassNode node = new ClassNode();
        ClassReader reader = new ClassReader(basicClass);
        reader.accept(node, 0);

        doSomethingToTheClassNode(node);
        
        ClassWriter writer = new ClassWriter(0);
        node.accept(writer);
        return writer.toByteArray();
    }
}
```

Note that we check for the name first and immediately return the class bytes if the name does not match what we expect. Class transformers should be fast, if possible, since they are executed for every class and parsing a `ClassNode` is not necessarily cheap.

Next we create a class node and hand it off to another method. Finally we write the transformed class node back to a byte array and return it.

Also note how i used the name `net.minecraft.client.Minecraft`. Class names and method names can change depending on the environment. Forge generally runs under `MCP` names in the development environment and `searge` names in the live environment. While those have different names for methods, fields and variables, they do share the same class names, so checking the name this way is okay (but checking method names requires checking for both the searge and MCP names).

If you plan on doing lots of class transformations you might want to create a base class of sorts:

```java
public abstract class BasePatch implements IClassTransformer {

    protected abstract String getTargetedName();

    protected abstract ClassNode transformClassNode(ClassNode classNode);

    @Override
    public byte[] transform(String name, String transformedName, byte[] basicClass) {
        if (!name.equals(getTargetedName())) return basicClass;
        ClassNode node = new ClassNode();
        ClassReader reader = new ClassReader(basicClass);
        reader.accept(node, 0);

        node = transformClassNode(node);

        ClassWriter writer = new ClassWriter(0);
        node.accept(writer);
        return writer.toByteArray();
    }
}
```

This way you will also have a place to store all the helpful utilities you will most likely create.

How about we actually change something then?


```java
// Note that while i use the base patch class from earlier here, you could also just do this directly in a class transformer without utilities
public class MinecraftPublicMaker extends BasePatch {
    @Override
    protected String getTargetedName() {
        return "net.minecraft.client.Minecraft";
    }

    @Override
    protected ClassNode transformClassNode(ClassNode classNode) {
        for (MethodNode method : classNode.methods) {
            // for every method we set the access flag to public using bit wise operations
            // and remove the private and protected bits
            // Note that if you check for method.name here, you will need to check two strings - searge and MCP
            method.access = (method.access | Modifier.PUBLIC) & ~(Modifier.PRIVATE | Modifier.PROTECTED);
        }
        return classNode;
    }
}
```

Once you have access to a class node you can change anything. I won't do a full tutorial on bytecode and how to change the code of methods here, but you are welcome to movitate me to do so. Class transformers are vastly more powerful than mixins.


One final note about debugging. Since changing the class file can cause a lot of unexpected results, especially when (not if) you mess up and create broken bytecode it can be helpful to dump transformed classes. That can be done by specifying `-Dlegacy.debugClassLoading=true -Dlegacy.debugClassLoadingSave=true` as jvm arguments. This will create a folder called `CLASSLOADER_TEMP(and some number)`. In there you will find the bytes after all transformations have been done. This will allow you to decompile your transformed classes and debug your transformers. Make sure to clear out space for more class loader dump folders every 10 runs or it will stop working. And make sure to always test your transformers on a live environment as well as a development one!

## `IFMLLoadingPlugin`s

Why are there `ITweaker`s and `IFMLLoadingPlugin`s you might ask yourself. The simple answer is: everybody wanted to do their own standard. `ITweaker`s are by the launch wrapper which is not a Forge product itself, but is used to launch Forge. `IFMLLoadingPlugin`s are done by Forge and as such are more tightly integrated into Forge, but since they are done by Forge they are also needlessly complicated.

Some of the custom functionality provided by Forge is quite nice, such as providing a custom mod container, but for the most part `IFMLLoadingPlugin`s are used for one reason: Unlike tweakers (which are loaded from the `mods` folder), they are loaded from the classpath. This is useful for libraries, since it allows them to specify a loading plugin for class transformations or as an additional entrypoint since libraries dont have an init event like a mod does. A lot of libraries will just use that `IFMLLoadingPlugin` to load a `ITweaker` using [cascading tweakers](#delegating-tweakers), since `ITweaker`s generally have nicer semantics.

`IFMLLoadingPlugin`s also allow to specify a sorting order using annotations which can be nice if you need some early spot to add dependencies.

## Mod loading

One day you might want to leave the dev environment and once you do you will run into some problems. You specify your tweaker like you used to do with mixins (the `"TweakClass"` manifest attribute) and now when you run your mod it executes your tweaker. But - *just* your tweaker. Forge has made the executive decision to exclude any JAR that has a tweaker or an `IFMLLoadingPlugin` from participating in regular mod discovery. In order to make yourself eligible again for normal mod execution, you will need to remove yourself from that list. Similarly, if you still want to use mixins, you will not only need to load the mixin tweaker via delegation, but you will also need to add yourself to the mixin container list, since mixin checks that your `TweakClass` entry is equal to the expected mixin tweaker.

```java
@Override
public void acceptOptions(List<String> args, File gameDir, File assetsDir, String profile) {
    // Exercise for the reader: add delegation to the mixin tweaker
    URL location = getClass().getProtectionDomain().getCodeSource().getLocation();
    if (location == null) return;
    if (!"file".equals(location.getProtocol())) return;
    try {
        // Add yourself as mixin container
        MixinBootstrap.getPlatform().addContainer(location.toURI());
        String file = new File(location.toURI()).getName();
        // Remove yourself from both the ignore list in order to be eligible to be loaded as a mod.
        CoreModManager.getIgnoredMods().remove(file);
        CoreModManager.getReparseableCoremods().add(file);
    } catch (URISyntaxException e) {
        e.printStackTrace();
    }
}
```

## Future prospects

This tutorial already took a fairly long time and this is a really advanced topic not many people will read about. If you want more tutorials for advanced stuff like this, such as docs about FML loading internals or how you could create your own Minecraft client using launchwrapper (and why you shouldn't), or even a full JVM bytecode manipulation tutorial, then let me know. While I would love to create more tutorials like this, I do need some incentive to make these advanced/expert level tutorials.








