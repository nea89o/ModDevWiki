# Events in Forge

Forge uses events to allow mods to communicate with Minecraft and each other. Most of the events you will need to use come from Forge, but you can also create your own events if you need more.

## Subscribing to events

If you are interested in an event you need to create an event handler. For this first create a method that has the `@SubscribeEvent` annotation, is `public`, return `void` and takes an event as an argument. The type of the event argument is what decides which events your method receives. You can also only have one argument on an event handler.

```java
public class MyEventHandlerClass {
    int chatCount = 0;
    @SubscribeEvent
    public void onChat(ClientChatReceivedEvent event) {
        chatCount++;
        System.out.println("Chats received total: " + chatCount);
    }
}
```

This on it's own will not do anything yet. You must also register the event handler. To do that you register it on the corresponding event bus. For almost everything you will do, you need the `MinecraftForge.EVENT_BUS` (yes, even your own custom events should use this event bus).


```java
@Mod(modid = "examplemod", useMetadata = true)
public class ExampleMod {
    @Mod.EventHandler
    public void init(FMLInitializationEvent event) {
        MinecraftForge.EVENT_BUS.register(new MyEventHandlerClass());
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
        event.setCanceled(true);
}
```

Not all events can be cancelled. Check the event class in the decompilation for the `@Cancellable` annotation.


## Custom Events

!!! note
    This is an advanced topic that most mod developers don't need to worry about.

Forge also allows you to create custom events. Each event needs to have it's own class extending `Event` (transitively or not). (Make sure you extend `net.minecraftforge.fml.common.eventhandler.Event`).

```java
// If you don't want your event to be cancellable, remove this annotation
@Cancelable
public class CheeseEvent extends Event {
    public final int totalCheeseCount;

    public CheeseEvent(int totalCheeseCount) {
        this.totalCheeseCount = totalCheeseCount;
    }
}
```

That's it, you are done. You have a custom event!

I'm kidding of course. The next step is actually using your event. For now, let's put our own custom event inside the forge chat event:

```java
int cheeseCount = 0;

@SubscribeEvent
public void onChat(ClientChatReceivedEvent event) {
    if (event.message.getFormattedText().contains("cheese")) {
        CheeseEvent cheeseEvent = new CheeseEvent(++cheeseCount);
        MinecraftForge.EVENT_BUS.post(cheeseEvent);
    }
}
```

And now we are done. Unless you want your event to be cancellable. We also need to add code to handle cancelled events (if you made your event `@Cancelable`). What that cancelling does is up to you, but in our example let's just cancel the original chat message event (hiding that chat message):

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


