# Mixins

Mixins allow you to change Minecraft code. This is massively powerful, but you need to be very careful when using them, especially when considering if you want to integrate well with other mods.

!!! info
    The [MinecraftDev](https://mcdev.io/) plugin is pretty much non negotiable when coding Mixins. It enables auto completion, shows errors when your mixins are wrong in your IDE and allows you to directly navigate to the code you are changing.

    It also has some other functions that allow for easier Minecraft development, but most of that functionality is aimed at higher Minecraft versions.

> Please forgive the the nonsensical examples. I try to make the examples as simple as possible. [Check](https://github.com/NotEnoughUpdates/NotEnoughUpdates/tree/master/src/main/java/io/github/moulberry/notenoughupdates/mixins) [out](https://github.com/hannibal002/SkyHanni/tree/beta/src/main/java/at/hannibal2/skyhanni/mixins/transformers) [some](https://github.com/Skytils/SkytilsMod/tree/1.x/src/main/java/gg/skytils/skytilsmod/mixins/transformers) [open](https://github.com/inglettronald/DulkirMod/tree/master/src/main/java/dulkirmod/mixins) source mods to check out some real world mixins.

## Layout

Mixins need to be in their own package. You should have a dedicated mixin package in the template already. You can have multiple subpackages, but your normal code and your Mixin code need to be separate. This is because Mixins are instructions for how to change the program, rather than actual program code itself. Mixins also need to be registered in your `mixin.example.json`. In there you only need to put the class name, not including the mixin package. Mixins also need to be written in Java, not in Kotlin.

```json
{
  "package": "${mixinGroup}",
  "refmap": "mixins.${modid}.refmap.json",
  "minVersion": "0.7",
  "compatibilityLevel": "JAVA_8",
  "mixins": [
        "MixinGuiMainMenu",
        "subpackage.MixinSomeOtherClass"
  ]
}
```

!!! info
    Depending on the template you used for your mod, you may have an auto mixin plugin installed already. That kind of plugin automatically finds all mixins that are inside of your mixin package, meaning you can just ignore the `mixin.modid.json`. You still need to put your mixins inside of the correct package, but you don't need to register them explicitly anymore.

    If you have such a plugin, you can find it by looking for something like this:
    ```json
      "plugin": "${basePackage}.init.AutoDiscoveryMixinPlugin",
    ```
    in your mixin json.

You can also have multiple mixins for the same Minecraft class.

## Mixin Use Cases

I recommend you start learning with accessor mixins, since those are the easiest, and go down the list from there.

 - [Accessors](./accessors.md)
 - [Adding Fields and Methods](./adding-fields.md)
 - [Simple Injects](./simple-injects.md)

## Compatibility

### Modid postfix

In order for your mod to be compatible with other mods it is *highly* recommend (if not borderline mandatory) to prefix or postfix all of your methods with your modid:

```java
public void someMixinMethod_mymodid() {}
// or
public void someMixinMethod$mymodid() {}
```

There are some exceptions for `:::java @Inject`s, but in general it doesn't hurt to just add the postfix.

### Non destructive mixins

When mixing into a class you would generally want that, if another mod has the exact same mixin, both of your mixins would work. Especially if your mixin only works sometimes (like being toggleable using a config option).

I.e. if you want a mixin to color mobs, and your mod decides not to color a mob, another mod should be able to use the exact same mixin (just in their mod) to color those mobs.

There are some general ground rules for achieving this behaviour: 

 - Only use `:::java cir.setReturnValue()` or `:::java ci.cancel()` if your mod decides to act on something. The default action should be to pass through to the next mixin or vanilla by doing nothing (`:::java return`ing from your inject).
 - Don't use `:::java @Redirect`. Only one mixin can ever use a `:::java @Redirect` on the same call. Only one redirect will ever work, even if your mod does nothing different with a given method call.
 - Don't use `:::java @Overwrite` (and don't overwrite without the annotation either, lol). Only one overwrite will ever work, even if your mod does nothing different with a given method call.

Of course you will have to break those rules from time to time. But before you do, think twice if you *really* need to. And if you do, maybe consider exposing some sort of API for other mods to hook into your code?

## Troubleshooting

The first step in troubleshooting mixins is to enable `-Dmixin.debug=true` in your run configurations jvm arguments. This will print out all the Mixins as they are applied and show you exactly what is wrong with each mixin, and why it wasn't applied.

Another common issue is to forget to register a mixin in the `mixins.modid.json`

You can also get exceptions when trying to load a mixin class directly. Accessing any mixin class except for an accessor from non mixin code will crash your game. If you want to call a method inside a mixin, have that mixin implement an interface instead.







