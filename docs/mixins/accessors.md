# Accessor Mixins

> a/k/a Reverse Patch

Let's start with the easiest form of Mixins — Accessors. Accessors allow you to access functions that are otherwise private in a Minecraft class. You can also do that using reflection, but you might notice that your reflection call will not easily work in both devenv and a live env. This is because the method names are different in a devenv compared to a normal Forge installation. You can still specify both names and just look through all the names using reflection, but Accessor Mixins are a lot easier to use, with less accidental pitfalls, and better performance.

```java
// This Mixin targets the Minecraft class
@Mixin(Minecraft.class)
public interface AccessorMinecraft {

    // Getter for the field theIntegratedServer
    // Notice the _mymodid at the end.
    @Accessor("theIntegratedServer")
    IntegratedServer getIntegratedServe_mymodid();

    // Setter for serverPort
    @Accessor("serverPort")
    void setServerPort_mymodid(int port);

    // Invoker for rightClickMouse.
    @Invoker("rightClickMouse")
    void rightClickMouse_mymodid();
}
```

First, notice that we need to use an `interface`. Most mixins are `class`es. Accessors are the exception, since we don't want to actually put any code into the `Minecraft` class. Accessor mixins can also not be mixed with other mixin styles, but since you should have multiple mixins even for the same class for different things anyway, this shouldn't be an issue.

Next we put the `@Mixin` annotation on our Accessor to let it known which class we want to inject into.

Then for a field we use the `@Accessor` annotation, with the name of the field we want to access. Please give all your mixin methods a `_mymodid` indicator, to avoid name collissions with other mods.

For a setter, the method returns void and takes one argument of the type of the field you are targetting. For a getter, the method returns the type of the field you are targeting and takes no arguments.

For an method invoker, you copy the method signature you want to call, but rename it to something unique with a `_mymodid` postfix.

Now if you want to use those methods, you can simply cast any instance of your targeted class to your accessor mixin class:

```java
Minecraft mc = Minecraft.getMinecraft();
AccessorMinecraft accessorMc = (AccessorMinecraft) mc;
accessorMc.rightClickMouse_mymodid();
```

If you get a class cast exception here, it means your mixin was not applied. This can happen if you forgot to register your mixin, or if your mixin contains errors.
