# Creating your first command

This tutorial focuses on client commands, meaning they will get run on the client. If you want to develop a server command there are more considerations to be done (like permissions, and synchronizing server state to the client).

## Basic command class

First, let's create a new class for our command. We will call it `CrashCommand` because it will crash your game. Of course, your command can do whatever you want. We need to make sure our command `:::java extends CommandBase`.

```java
public class CrashCommand extends CommandBase {

    @Override
    public String getCommandName() {
        return "crashme";
    }

    @Override
    public String getCommandUsage(ICommandSender sender) {
        return "";
    }

    @Override
    public void processCommand(ICommandSender sender, String[] args) throws CommandException {
        throw new RuntimeException("Not yet implemented!");
    }

    @Override
    public boolean canCommandSenderUseCommand(ICommandSender sender) {
        return true;
    }

}
```

I already implemented three methods into the command.

!!! warning
    When writing a client command you will need to override `canCommandSenderUseCommand`. By default this method does not generate, but without it you will get a `You do not have permission to use this command` error (since you by default do not have any permissions on a server). Just always return `:::java true`, since the command is client side only anyway.


First the method `getCommandName`, which returns the name of your command. The name is what you use in chat to run the command. The command name should be just numbers and letters (and maybe dashes, if you want). In chat you will need to run `/crashme` to run this command (the `/` gets added to the name automatically).

The second method is `getCommandUsage`. You need to override it because every commands needs to have a usage, but for most SkyBlock mods that usage doesn't matter — it only gets displayed in the `/help` menu, and Hypixel does not show client commands in it's help menu.

## Running your command

The `processCommand` method is run when your command is executed:


```java
@Override
public void processCommand(ICommandSender sender, String[] args) throws CommandException {
    LogManager.getLogger("CrashCommand").info("Intentionally crashing the Game!");
    FMLCommonHandler.instance().exitJava(1, false);
}
```

!!! info
    When using a Logger, make sure to use the `LogManager` from `org.apache.logging.log4j.LogManager`. Using the other log managers won't work.

!!! info
    If you want to close the game, you need to use `:::java FMLCommonHandler.instance().exitJava(exitCode, false)` instead of `:::java System.exit()`. Forge disables the normal `:::java System.exit()` calls.

But, this way of crashing the game might be a bit too easy to accidentally run. So let's add a confirmation system. When your `processCommand` is called, you are given two arguments: the `sender` is always the current player (since this is a client command), and the `args` array gives you all the arguments you are being called with. If a player runs the command `/crashme foo bar`, args will be `:::java new String[] {"foo", "bar"}`.

```java
@Override
public void processCommand(ICommandSender sender, String[] args) throws CommandException {
    // Make sure to check the array length before checking an argument
    if (args.length == 1 && args[0].equals("confirm")) {
        LogManager.getLogger("CrashCommand").info("Intentionally crashing the Game!");
        FMLCommonHandler.instance().exitJava(1, false);
    } else {
        sender.addChatMessage(new ChatComponentText("§aAre you sure you want to crash the game? Click to confirm!")
                .setChatStyle(new ChatStyle()
                    .setChatClickEvent(new ClickEvent(ClickEvent.Action.RUN_COMMAND, "/crashme confirm"))));
    }
}
```

!!! info
    Because `sender` is always the current player, you can also use
    ```java
    Minecraft.getMinecraft().thePlayer.addChatMessage(/* ... */);
    ```

Minecraft uses `IChatComponent`s in chat (and a few other places). You can make those by calling `:::java new ChatComponentText("")`. In there you can use format codes like `§a`. If you want, you can also use `:::java EnumChatFormatting.GREEN.toString()` instead of `§a`. You can change the chat style of a `ChatComponentText` in order to give it hover or click effects.


!!! warning
    You might be tempted to open a gui from your command like this:
    ```java
    @Override
    public void processCommand(ICommandSender sender, String[] args) throws CommandException {
        Minecraft.getMinecraft().displayGuiScreen(new MyGuiScreen());
    }
    ```
    This will not work, since your command gets executed from the chat gui and sending a chat line schedules the chat gui to be closed in the same tick (accidentally closing your gui instead).
    
    In order to make this work, you need to instead wait a tick and then open your gui. You can do this by having a tick event handler in your main mod class like this: 
    ```java
    // In your main mod class
    public static GuiScreen screenToOpenNextTick = null;

    @SubscribeEvent
    public void onTick(TickEvent.ClientTickEvent event) {
        if (event.phase == TickEvent.Phase.END) return;
        if (screenToOpenNextTick != null) {
            Minecraft.getMinecraft().displayGuiScreen(screenToOpenNextTick);
            screenToOpenNextTick = null;
        }
    }

    // In your command class:
    @Override
    public void processCommand(ICommandSender sender, String[] args) throws CommandException {
        ExampleMod.screenToOpenNextTick = new MyGuiScreen();
    }
    ```

    See [Events](/development/events) for more info on how to set up event handlers.

## Registering your command

After all this work your command still just will not run. This is because the final step of client commands is still missing. You need to register your command. You typically do this in the `FMLInitializationEvent`:


```java
@Mod.EventHandler
public void init(FMLInitializationEvent event) {
    ClientCommandHandler.instance.registerCommand(new CrashCommand());
}
```




