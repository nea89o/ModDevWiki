# Simple Injects

Let's get into method modifications. The real interesting part of mixins. Hopefully you know the basics from the first two mixin tutorials by now, because now we get into a whole another layer of complexity.

Now we will modify an existing method in Minecrafts code. This will allow us to react to changes in Minecrafts state. This is how almost all custom [events](../events.md) are done, but we are of course not limited to just events that observe state changes. Using method modifying mixins we can change almost any behaviour in Minecrafts code.

!!! note
    This is the simple tutorial, I will tell you *how* to use `@Inject`s and co, but I won't tell you the *why*. Check out the [advanced tutorial](./advanced-injects.md) for that.

## The easiest of the easiest

Let's start with probably the easiest `@Inject` out there. The HEAD inject. This mixin will inject whatever code you have inside your method at the start of the method you target.

```java
@Mixin(PlayerControllerMP.class)
public class RightClickWithItemEvent {

    @Inject(method = "sendUseItem", at = @At("HEAD"))
    private void onSendUseItem_mymod(EntityPlayer playerIn, World worldIn, ItemStack itemStackIn, CallbackInfoReturnable<Boolean> cir) {
        MinecraftForge.EVENT_BUS.post(new SendUseItemEvent(playerIn, worldIn, itemStackIn));
    }
}
```

First we want to inject into the `PlayerControllerMP` class.

We create an `@Inject`. This tells us in which method we want to inject (`sendUseItem`) and where in that method (`HEAD`, meaning the very top of the method).

The actual method signature for an inject is always to return a `void`. You can make them `private` or `public`. The arguments are the same arguments as the method you want to inject into, as well as a `CallbackInfo`.

For a method returning void, you just use a `CallbackInfo`, and if the method returns something, you use `CallbackInfoReturnable<ReturnTypeOfTheInjectedIntoMethod>`.

Your method will now be called every time the `sendUseItem` is called with the arguments to that method and the `CallbackInfo`.

!!! important
    Your method will be *called* at the beginning of the injected into method like this: 

    ```java
    public boolean sendUseItem(EntityPlayer playerIn, World worldIn, ItemStack itemStackIn) {
        onSendUseItem_mymod(playerIn, worldIn, itemStackIn, new CallbackInfo(/* ... */));
        // All the other code that is normally in the method
    }
    ```

    This means returning from your method will just continue as normal. See [cancelling](#cancelling) for info on how to return from the outer method.

## At a method call

Let's take this example method:

```java
public void methodA() {
    // ...
}

public void methodB() {
    System.out.println("Here 1");
    methodA();
    // We want to inject our method call right here.
    System.out.println("Here 2");
}
```

We can inject ourselves into `methodB` as well. It is *just* a bit more complicated than the `HEAD` inject.

```java
@Inject(method = "methodB", at = @At(target = "Lnet/some/Class;methodA()V", value = "INVOKE"))
private void onMethodBJustCalledMethodA(CallbackInfo ci) {
}
```

> **HUUUUH, where does that come from???**

Don't worry! I won't explain you how to understand these `target`s in this tutorial, but you also don't need to understand that `target`. Instead you can simply use the Minecraft Development IntelliJ Plugin to help you. Simply type `@At(value = "INVOKE", target = "")`, place your cursor inside of the target and use auto completion (<kbd>Ctrl + Space</kbd>) and the plugin will recommend you a bunch of method calls. Find whichever seems right to you and press enter. You can now (also thanks to the plugin) <kbd>Ctrl</kbd> click on the `target` string, which will take you to the decompiled code exactly to where that target will inject.

## Ordinals

Let's take the method injection example from before and change it a bit:

```java
public void methodA() {
    // ...
}

public void methodB() {
    System.out.println("Here 1");
    if (Math.random() < 0.4)
        methodA();
    System.out.println("Here 2");
    methodA();
    // We want to inject our method call right here.
    System.out.println("Here 3");
}
```

We can't simply use the same `@Inject` from before, since by default a `INVOKE` inject will inject just after *every* method call. Here, we can use the `ordinal` classifier to specify which method call we want to use. Keep in mind this is about where to place our injection, so many method calls in a loop will not increment the ordinal, only unique code locations that call the function will increase the ordinal. Keep in mind: we are programmers, we start counting with `0`.

```java
@Inject(method = "methodB", at = @At(target = "Lnet/some/Class;methodA()V", value = "INVOKE", ordinal = 1))
private void onMethodBJustCalledMethodA(CallbackInfo ci) {
}
```

## Cancelling

Cancelling a method means you return from the method you are injected to as soon as your injector method is done. In order to be able to use the cancelling methods, you need to mark your injection as cancellable.

```java
@Inject(method = "syncCurrentPlayItem", at = @At("HEAD"), cancellable = true)
private void onSyncCurrentPlayItem_mymod(CallbackInfo ci) {
    System.out.println("This code will be executed");
    if (Math.random() < 0.5)
        ci.cancel();
    System.out.println("This code will *also* be executed");
    // As soon as this method returns, the outer method will see that it was cancelled and *also* return
}

@Inject(method = "isHittingPosition", at = @At("HEAD"), cancellable = true)
private void onIsHittingPosition_mymod(BlockPos pos, CallbackInfoReturnable<Boolean> cir) {
    cir.setReturnValue(true);
}
```

For `void` methods you need to use `callbackInfo.cancel()`. For all other methods you need to use `callbackInfoReturnable.setReturnValue(returnValue)`.


!!! important
    Cancelling a `CallbackInfo` will only have an effect as soon as you return from your injector method.
    The rest of your method will run as normal.




