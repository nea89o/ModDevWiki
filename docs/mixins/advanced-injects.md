# Advanced Injects

So you wanna learn how to *really* use Injects? It is gonna be a tough road, and I won't lead you all the way there (mostly because eventually there are diminishing returns on a tutorial like this), but eventually most SkyBlock devs fall down the rabbit hole.

This will be pretty dry compared to the other mixin tutorials, so feel free to skip reading this and just use this as a glossary.

## Remapping

Let's start with names. Names are important. If you call a method with the wrong name, You get a crash at best, and at worse you cause undefined behavior. But, most methods go by unpronounceable names like `v` or `method_12934`. This is because Mojang obfuscated Minecraft, replacing every class name, every method name, etc. with a randomly generated short name to prevent people from reverse engineering it (which has the nice side effect of bit of a smaller binary). Now if we develop mods, we don't want to work with names like those. So we use mappings. Those are long lists telling us which obfuscated method name corresponds to a readable method name. In modern versions you have [yarn](https://github.com/FabricMC/yarn/) (which is a community project), as well as official names from [Mojang](https://nea.moe/minecraft.html) themselves, but in older versions, we just have MCP.

Let's go through the process of how your normal Forge mod gets compiled:

 - Download Minecraft (obfuscated by mojang)
 - Actually download another copy of Minecraft (the server, also obfuscated)
 - Merge the two JARs into one, so you can reference both server and client classes from the same mod
 - Apply the MCP mappings to the JAR, turning Mojangs names into readable ones.
 - Apply some patches to the JAR, to inject Forge events and custom registries and such.
     - the order of those first 5 steps isn't always the same. minecraft version and liveenv/devenv differences can rearrange them sometimes
 - Now you compile your mod source against this new Minecraft JAR (as well as some extra libraries)
 - Forge in a live environment uses an intermediary between the completely obfuscated and the completely readable names, so now we need to turn our readable names back into intermediary ones
 - For this, Forge goes through your generated JAR and applies the mappings from earlier, but in reverse

This process has it's drawbacks. Especially that last step isn't perfect, and not everything you do will be remapped (and sometimes that is desired).

Let's look at some examples:


```java
public void myFunc() throws Throwable {
    ItemStack itemStack = new ItemStack(/* ... */);
    itemStack.getDisplayName();
    ItemStack.class.getMethod("getDisplayName").invoke(itemStack);
    System.out.println("net.minecraft.item.ItemStack");
    System.out.println("ItemStack");
}
```

Now the forge remapper will take that code and get you something like this in the actual compiled mod:

```java
public void myFunc() throws Throwable {
    azq itemStack = new azq(/* ... */);
    itemStack.b();
    azq.class.getMethod("getDisplayName").invoke(itemStack);
    System.out.println("net.minecraft.item.ItemStack");
    System.out.println("ItemStack");
}
```

There are a few things that work and a few things don't in this snippet.

The normal usage of `ItemStack` gets correctly replaced with `azq` the correct obfuscated name (well, in reality the obfuscated name would be a different one, but the basic idea holds) and the `getDisplayName` call gets replaced with `b`.

But the reflection didn't work out so great. While the `.class` literal did get remapped, the `getMethod` argument didn't. And if we used `Class.forName` that would also not get remapped. This is because those values are just strings that just so happen to have the same name as a class or method. For this simple case, you might think we could just do some flow analysis and remap those values, but for more complicated cases (maybe the method name gets passed as an argument, or stored in a variable) the flow analysis is not that clear. Those cases *could* be covered, but doing so would lead to a lot of inconsistencies around the edges of our flow analysis. A simple refactor could lead to your code not being remapped correctly. In that light it is better to just not remap strings at all.

The `println` is not changed either, but most likely those debug prints are not meant to change. If you later get an error relating to this method and you search for "ItemStack", you want to find those log entries in your log. So in this case the "failed" remap is actually the correct behaviour.

Now given all this information, let's see how mixins handle remaps.

## Refmaps

Refmaps are mixins way around the forge compilation step. Mixins uses a lot of string identifiers. From method names in `@Inject(method = "")` to method descriptors in `@At(target = "", value = "INVOKE")`, to many more. All those strings are not recognized by Forge as something to be remapped, and even if Forge did remapping on strings, those strings are often in complicated formats that are wildly different from how Forge expects them. Because of this mixins instead use their own extra compilation step to remap all that information.

The mixin refmap strategly looks like this:


 - Compile against the deobfuscated (readable name) Minecraft JAR, like the normal mod.
 - Let Forge take care of all the real java code (the method bodies, method arguments and return types, class references in annotations)
 - Afterwards, take a look at all mixin annotations and resolve the things they refer to using the readable names.
 - Then, since we are still in the development environment where those mappings are available, create a JSON file that contains all mappings relevant to all the mixin annotations.
    - Mixin doesn't just ship all the mappings because they are quite large and 99% not needed.
    - This JSON file is called the "refmap"
 - Later, at runtime, when the Mixin class transformer parses the annotations to apply class transformations it reads the refmap and resolves annotation arguments using those names.

You might run into a problem sometimes when referring to a non remapped method however. Not all methods in Minecrafts code are obfuscated. Some need to keep their original name in order to interact with other Java code. For example the `equals` method of an object needs to always be called `equals`. Obfuscating that method breaks comparisons used by a lot of Java standard library functions. When Mixin encounters those unobfuscated names during the refmap collection step, it notices the lack of a remapped name. This could mean that something is just named the same, but it could also mean that there is an error (the developmer mistyped a name). If you want to inform mixin that you are aware of a lacking mapping, you can do so by specifying `remap = false` on that annotation. It only applies to that specific annotation, so you might need to apply it to your `@Inject` and your `@At` separately.





