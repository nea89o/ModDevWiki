# Events in Forge

Forge uses events to allow mods to communicate with Minecraft and each other. Most of the events you will need to use come from Forge, but you can also create your own events if you need more.

## Subscribing to events

If you are interested in an event you need to create an event handler. For this first create a method that has the `:::java @SubscribeEvent` annotation, is `:::java public`, return `:::java void` and takes an event as an argument. The type of the event argument is what decides which events your method receives. You can also only have one argument on an event handler.

```java
public class MyEventHandlerClass {
    int chatCount = 0;
    @SubscribeEvent //(1)!
    public void onChat(ClientChatReceivedEvent event) { //(2)!
        chatCount++;
        System.out.println("Chats received total: " + chatCount);
    }
}
```

1. This annotation informs Forge that your method is an event handler
2. The method parameter tells Forge which events this event handler listens to

This on it's own will not do anything yet. You must also register the event handler. To do that you register it on the corresponding event bus. For almost everything you will do, you need the `:::java MinecraftForge.EVENT_BUS` (yes, even your own custom events should use this event bus). The best place to do this is in one of your `FML*InitializationEvent`s.


```java
@Mod(modid = "examplemod", useMetadata = true)
public class ExampleMod {
    @Mod.EventHandler
    public void init(FMLInitializationEvent event) {
        MinecraftForge.EVENT_BUS.register(new MyEventHandlerClass());
        MinecraftForge.EVENT_BUS.register(this);
    }
}
```

## Cancelling Events

Forge Events can be cancelled. What exactly that means depends on the event, but it usually stops the action the event indicates from happening.

```java
@SubscribeEvent
public void onChat(ClientChatReceivedEvent event) {
    // No more talking about cheese
    if (event.message.getFormattedText().contains("cheese"))
        event.setCanceled(true); // (1)!
}
```

1. Cancel the event

Not all events can be cancelled. Check the event class in the decompilation for the `:::java @Cancellable` annotation.

If an event is cancelled, it not only changes what Minecraft's code does with the event, but also prevents all other event handlers that come afterwards from handling the event. If you want your event handler to even receive cancelled events, use `receiveCanceled = true`:


```java
@SubscribeEvent(receiveCanceled = true) // (1)!
public void onChat(ClientChatReceivedEvent event) {
    event.setCanceled(false); // (2)!
}
```

1. Make sure our event handler receives cancelled events
2. Uncancel the event. This means the event will be handled by Minecrafts code normally again and you will see the chat.


## Custom Events

!!! note
    This is an advanced topic that most mod developers don't need to worry about.

Forge also allows you to create custom events. Each event needs to have it's own class extending `:::java Event` (transitively or not). (Make sure you extend `:::java net.minecraftforge.fml.common.eventhandler.Event`, not any other event class).

```java
@Cancelable // (1)!
public class CheeseEvent extends Event { // (2)!
    public final int totalCheeseCount;

    public CheeseEvent(int totalCheeseCount) {
        this.totalCheeseCount = totalCheeseCount;
    }
}
```

1. If you want your event to be cancellable, you need this annotation. Remove it for an uncancellable event.
2. Extend the Forge `:::java Event` class. The rest of your class is just normal Java.

That's it, you are done. You have a custom event!

I'm kidding of course. The next step is actually using your event. For now, let's put our own custom event inside the forge chat event (you will later learn how to use [mixins](./mixins/index.md) to create even more events):

```java
int cheeseCount = 0;

@SubscribeEvent
public void onChat(ClientChatReceivedEvent event) {
    if (event.message.getFormattedText().contains("cheese")) {
        CheeseEvent cheeseEvent = new CheeseEvent(++cheeseCount); // (1)!
        MinecraftForge.EVENT_BUS.post(cheeseEvent); // (2)!
    }
}
```

1. Creates a new `CheeseEvent` instance. This is just a normal java object construction, which does not interact with Forge at all.
2. Send our `CheeseEvent` to be sent to all event handlers by Forge.

And now we are done, unless you want your event to be cancellable. For cancellable events we also need to add code to handle cancelled events. What that cancelling does is up to you, but in our example let's just cancel the original chat message event (hiding that chat message):

```java
@SubscribeEvent
public void onChat(ClientChatReceivedEvent event) {
    if (event.message.getFormattedText().contains("cheese")) {
        CheeseEvent cheeseEvent = new CheeseEvent(++cheeseCount);
        MinecraftForge.EVENT_BUS.post(cheeseEvent);
        if (cheeseEvent.isCanceled()) {
            event.setCanceled(true);
        }
    }
}
```

You can now subscribe to your custom event like you would to any other event:

```java
@SubscribeEvent
public void onCheese(CheeseEvent event) {
    if (event.totalCheeseCount > 10) {
        // Only 10 cheese messages are allowed per restart
        event.setCanceled(true);
    }
}
```


