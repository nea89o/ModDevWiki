# Simple Injects

Let's get into method modifications. The real interesting part of mixins. Hopefully you know the basics from the first two mixin tutorials by now, because now we get into a whole another layer of complexity.

Now we will modify an existing method in Minecrafts code. This will allow us to react to changes in Minecrafts state. This is how almost all custom [events](../events.md) are done, but we are of course not limited to just events that observe state changes. Using method modifying mixins we can change almost any behaviour in Minecrafts code.

!!! note
    This is the simple tutorial, I will tell you *how* to use `@Inject`s and co, but I won't tell you the *why*. Check out the [advanced tutorial](./advanced-injects.md) for that.

## The easiest of the easiest

Let's start with probably the easiest `@Inject` out there. The `HEAD` inject. This mixin will inject whatever code you have inside your method at the start of the method you target.

```java
@Mixin(PlayerControllerMP.class) // (1)!
public class RightClickWithItemEvent {

    @Inject( // (2)!
        method = "sendUseItem", // (3)!
        at = @At("HEAD")) // (4)!
    private void onSendUseItem_mymod( // (5)!
        EntityPlayer playerIn, World worldIn, ItemStack itemStackIn, // (6)!
        CallbackInfoReturnable<Boolean> cir // (7)!
        ) {
        MinecraftForge.EVENT_BUS.post(new SendUseItemEvent(playerIn, worldIn, itemStackIn));
    }
}
```

1. First we declare which class we want to change 
2. `:::java @Inject` allows us to add code into an already existing method
3. This sets the method into which we want to inject something. Be careful of overloaded methods here. Check out the [advanced tutorial](./advanced-injects.md) for more info.
4. The `:::java @At` specifies where our code will be injected. `HEAD` just means the top of the method.
5. The injected code method should be `:::java private` and `:::java void` no matter what your target method is. You might also need to make your method `:::java static`
6. You need to copy over all the parameters from your original method into which you are injecting.
7. You need one extra parameter for the callback info.



First we want to inject into the `PlayerControllerMP` class.

We create an `@Inject`. This tells us in which method we want to inject (`sendUseItem`) and where in that method (`HEAD`, meaning the very top of the method).

The actual method signature for an inject is always to return a `void`. You can make them `private` or `public`. The arguments are the same arguments as the method you want to inject into, as well as a `CallbackInfo`.

For a method returning void, you just use a `:::java CallbackInfo`, and if the method returns something, you use `:::java CallbackInfoReturnable<ReturnTypeOfTheInjectedIntoMethod>`.

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
    // Let's pretend lots of code calls methodA, so we don't want to inject
    // ourselves into methodA
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
@Inject(
    method = "methodB", // (3)!
    at = @At(
        target = "Lnet/some/Class;methodA()V", // (1)!
        value = "INVOKE")) // (2)!
private void onMethodBJustCalledMethodA(CallbackInfo ci) {
}
```

1. This is the method call for which we are searching. This is not the method into which our code will be injected.
2. This tells mixin that we want `target` to point to a method call (not a field or anything else).
3. This is the method into which we want our code to be injected.

> **HUUUUH, where does that come from???**

Don't worry! I won't explain you how to understand these `target`s in this tutorial, but you also don't need to understand that `target`. Instead you can simply use the Minecraft Development IntelliJ Plugin to help you. Simply type `:::java @At(value = "INVOKE", target = "")`, place your cursor inside of the target and use auto completion (++ctrl+space++) and the plugin will recommend you a bunch of method calls. Find whichever seems right to you and press enter. You can now (also thanks to the plugin) ++ctrl++ click on the `target` string, which will take you to the decompiled code exactly to where that target will inject.

## Ordinals

Let's take the `INVOKE` injection example from before and change it a bit:

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

We can't simply use the same `:::java @Inject` from before, since by default a `INVOKE` inject will inject just after *every* method call. Here, we can use the `ordinal` classifier to specify which method call we want to use. Keep in mind this is about where to place our injection, so many method calls in a loop will not increment the ordinal, only unique code locations that call the function will increase the ordinal. Remember: we are programmers, we start counting with `0`.

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

For `void` methods you need to use `:::java callbackInfo.cancel()` which acts the same as a normal `:::java return;` would in the method you are injecting into. For all other methods you need to use `:::java callbackInfoReturnable.setReturnValue(returnValue)` which corresponds to `:::java return returnValue;`.


!!! important
    Cancelling a `CallbackInfo` will only have an effect as soon as you return from your injector method.
    The rest of your method will run as normal.




