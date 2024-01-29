# Creating your first command

This tutorial focuses on client commands, meaning they will get run on the client. If you want to develop a server command there are more considerations to be done (like permissions, and synchronizing server state to the client).

## Basic command class

First, let's create a new class for our command. We will call it `CrashCommand` because it will crash your game. Of course, your command can do whatever you want. We need to make sure our command `:::java extends CommandBase`.

```java
public class CrashCommand extends CommandBase {

    @Override
    public String getCommandName() {
        return "crashme"; // (1)!
    }

    @Override
    public String getCommandUsage(ICommandSender sender) {
        return ""; // (2)!
    }

    @Override
    public void processCommand(ICommandSender sender, String[] args) throws CommandException {
        throw new RuntimeException("Not yet implemented!"); // (3)!
    }

    @Override
    public boolean canCommandSenderUseCommand(ICommandSender sender) {
        return true; // (4)!
    }

    @Override
    public List<String> getCommandAliases() {
        return Arrays.asList("dontcrashme"); // (5)!
    }
}
```

1. This is the name of your command. You can call your command in chat with `/crashme`. You should only use numbers and letters for this name, since a lot of other characters make it impossible to call your command.
2. This can be left empty. By default this is used by the vanilla `/help` command. But since we are on SkyBlock, where Hypixel uses a custom help menu that does not show client commands, there isn't really any point in filling that one out.
3. We will implement the actual code in the next section
4. This method simply allows anyone to call this command. Since this is a client command, "anyone" just means "the local player".
5. The `getCommandAliases` method allows you to specify additional names that your command can be called by. You can just not implement this method if you want to only use the name returned by `getCommandName`.

!!! warning
    When writing a client command you will need to override `canCommandSenderUseCommand`. By default this method does not generate, but without it you will get a `You do not have permission to use this command` error (since you by default do not have any permissions on a server). Just always return `:::java true`, since the command is client side only anyway.

## Registering your command

After all this work your command still just will not run. This is because right now you just have a random Java class Forge knows nothing about. You need to register your command. You typically do this in the `FMLInitializationEvent`:


```java
@Mod.EventHandler
public void init(FMLInitializationEvent event) {
    ClientCommandHandler.instance.registerCommand(new CrashCommand());
}
```

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
    // Be sure to check the array length before checking an argument
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

    See [Events](events.md) for more info on how to set up event handlers.


## Tab Completion

Minecraft allows you to press tab to auto complete arguments for commands. Your command will already be tab completable, but in order for this to also work with the arguments of your command, you need to override `addTabCompletionOptions`:


```java
@Override
public void processCommand(ICommandSender sender, String[] args) throws CommandException {
    if (args.length == 0) {
        sender.addChatMessage(new ChatComponentText("§cPlease use an argument"));
    } else if (args[0].equals("weather")) {
        sender.addChatMessage(new ChatComponentText("§bCurrent Weather: " +
                (Minecraft.getMinecraft().theWorld.isRaining() ? "§7Rainy!" : "§eSunny!")));
    } else if (args[0].equals("coinflip")) {
        sender.addChatMessage(new ChatComponentText("§bCoinflip: " +
                (ThreadLocalRandom.current().nextBoolean() ? "§eHeads" : "§eTails")));
    } else {
        sender.addChatMessage(new ChatComponentText("§cUnknown subcommand"));
    }
}

@Override
public List<String> addTabCompletionOptions(ICommandSender sender, String[] args, BlockPos pos) {
    if (args.length == 1) // (1)!
        return getListOfStringsMatchingLastWord(args, "weather", "coinflip"); // (2)!
    return Arrays.asList();
}
```

1. The args array contains all the arguments. The last argument is the one you should autocomplete. It contains the partial argument, or an empty string. Make sure to check the length of the array, so you know which argument you are autocompleting.
2. The `getListOfStringsMatchingLastWord` function automatically filters your autocompletion results based on the options you give it. The first argument is the `args` array, the second argument is either a `:::java List<String>` or a vararg of `:::java String`s


