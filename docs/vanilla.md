# Looking through Vanilla Code

Looking through Minecraft's code is often the only way to figure out how things work, so let's go on a little code safari through Vanilla code. 

## Setup

You might have already looked through some vanilla code by just ++ctrl++ clicking on a method and just having IntelliJ decompile the code. While this works for basic stuff, a lot of features are broken in that decompiled code. For example, you can't use a debugger to break on those lines, there is less Javadoc, and more. A lot of that is fixed by manually decompiling Minecraft.

First, go into your :simple-gradle: gradle tab and select the `gradle genSources` task. This will take a while to decompile the entire Minecraft JAR. Once this task is done you can navigate into a Minecraft class the normal way. This might still show you the IntelliJ decompiled code. You can tell, because there will be a banner at the top labeled "Decompiled class file". In that same banner you should either find a "Show source file" button, or a "Select sources" button. The "Select sources" button will allow you to select the `-sources.jar`. It should be in the same folder that your normal Minecraft JAR is already. Once you selected one of these buttons, you should automatically use the generated sources, instead of the decompiled ones.

## Minecraft

The `Minecraft` class is the entrypoint for almost all things you do as a client mod. The `Minecraft` is the actual Minecraft client instance. It contains references to nearly anything going on in the client, either directly (for example the `thePlayer` field) or transitively (for example the network handler `thePlayer.sendQueue`). You can get the reference to the `Minecraft` class using `:::java Minecraft.getMinecraft()`. I recommend you build your own set of utility methods for accessing things inside of the  `Minecraft` class.

Since the `Minecraft` class is quite big, I'll give you a few of the more interesting things to look at:

 - `theWorld` allows you to access information about the current world the player is in, like blocks and entities.
 - `thePlayer` allows you to get all kinds of information about the current player, like the position, inventory, and more, just like with any other player entity.
 - `thePlayer.sendQueue` allows you to send any kind of packet you want to the server. I wouldn't recommend you do this directly and instead use the `PlayerControllerMP`. Remember to closely follow the hypixel rules when doing this. The other useful thing in here is to fake packets from the server by calling the `handle*` methods. Oftentimes you would rather call the methods directly that that packet will eventually call, but injecting packets here allows other mods to react to those packets. Be careful however! Modifying Minecrafts internal state can cause it to send illegal packets to the server.   Methods in here are a prime target for mixins, allowing you to react to individual packets. Make sure to follow hypixel rules and to not provide the player with information that they couldn't otherwise get in the vanilla game.
 - `playerController` allows you to do things as the player in a more user friendly way than with packets. Minecraft often has checks here that prevent you from sending illegal packets or just a nicer described API. Remember to follow the Hypixel rules however. The other, far more practical, use of this class is as a mixin target. Whenever you want to react to the player doing something that doesn't already have a client side event, you can probably mix into a method in here to work it out.
 - `currentScreen` allows you to read (only read) the currently open GUI screen.
 - `displayGuiScreen` allows you to open screens (or close them, by calling this with `:::java null`)
 - `mcResourceManager` allows you to `registerReloadListener` which will call a function of yours after a resource pack reload. This allows you to re-read shaders, textures, or config files that you read from the minecraft asset folder.
 - `addScheduledTask` allows you to delay an action by a tick, or to reschedule something to be run on the Minecraft thread, if you are on another thread.



## GuiScreen

For our next subject of study, instead of looking how we can use a class from the outside, let's see how Minecraft itself uses the class on the inside. Let's look at how `GuiIngameMenu` (the escape menu) uses `GuiScreen`.

Of course the generated code isn't super beautiful, but we can gain some insights. We can see how `initGui` is used to add a bunch of `GuiButton`s to the `buttonList`. We can also see how `actionPerformed` is used to handle clicks on these buttons. We can also see a `GuiButton` be disabled.

## Scoreboard

Let's look at one last example: the scoreboard. The earlier sections all showed how you can discover new things, but what about investigating something specific you need. Let's say you want to read out what the scoreboad contains. It has plenty of info that we might want to use for our SkyBlock mod, like the Purse, Bits, current location, Jacobs Events, Season, whether we are in SkyBlock or not.

Let's start out with a blank slate. We don't know where any code is, but we can guess that it probably mentions "Scoreboard" somewhere. If we use IntelliJs Symbol Search feature (++shift+shift++) to search for "Scoreboard" (with "Include non-project items" turned on) we can quickly find a class called `Scoreboard`. In here we can find a lot of information. A bit too much info, actually.

Here we can find information about teams, objectives, scores, slots and criteria. All of this sounds a bit more confusing than the simple `:::java List<String>` we would like. A next step might be to go to the [minecraft wiki and read up on scoreboard terminology](https://minecraft.wiki/w/Scoreboard). And while i can recommend you to read that article if you want a deeper understanding, for us there is an easier path. Since we don't care about most things, we can just look up the code that is used to render the scoreboard on the side of the screen and figure out which methods to call from there.

At this point it helps to know that the class `GuiIngame` is responsible for rendering a lot of HUD elements (like the scoreboard). From there you can find the method `renderScoreboard` quite easily by searching for "scoreboard" in that class.

If we pretend for a second that we don't have this information already, we can find the `renderScoreboard` method an other way: we know that the info for rendering the scoreboard is inside the `Scoreboard` class. Now we can use "Right click" -> "Show usages" (or ++ctrl+alt+7++) to look up usages of `Scoreboard`. We might need to configure IntelliJ to look through usages in libraries as well in the popup. From there we can find two usages roughly related to rendering: `GuiPlayerTabOverlay` and `GuiIngame` (as well as `GuiIngameForge`, which just overrides `GuiIngame`). Since we care about the sidebar scoreboard, and not about the scores displayed in the tablist we have once again arrived at our `GuiIngame.renderScoreboard` method.

Once we have found the `renderScoreboard` method we need to figure out what it does. There are a lot of convoluted render calls going on, but if we ignore all the actual rendering for a second and focus on just the calls to the `Scoreboard` and adjacent class we can figure out what it does: 

 - First, get the scoreboard, for a given `ScoreObjective`. We might need to figure out where to get that from in a second.
 - Next we call `scoreboard.getSortedScore(objective)` to extract the scores. Those scores have player names attached, and we filter out all players who start with `#`.
 - Next we remove the beginning of the list until we only have 15 elements left. This gives us a hint that the list might be sorted from lowest to highest.
 - Next we have a loop iterating over all scores, and using `ScorePlayerTeam.formatPlayerName` to format the player names and then appending the score to the right to find the longest string. This is probably here to align all of our scores.
 - At this point we have all the info we need to infer the entire process. We know how to format the player names, where to get them from and in which order they are found.

The rest of that method is dedicated to more rendering. If we go through the rest of the code, we can see some of our suspicions confirmed (such as the rendering starting from the bottom and going upwards as we iterate over the list), but we already have a hunch of how we could get those strings ourselves.

Now the only mystery left is where we get our `ScoreObjective` from. Earlier we saw a method in `Scoreboard` called `getObjective` which returned a `ScoreObjective`, but it needed a name. So how about we look which method calls `renderScoreboard`. If we use ++ctrl+alt+7++ again to look up usages, we can see that `GuiIngameForge` and `GuiIngame` both call this function. Let's first look at the forge code, since that might override some vanilla behaviour. Here we can see `scoreobjective1` which is obtained from `getObjectiveInDisplaySlot` with either `1` or `3 + getTeamColor(currentPlayer)`. We might step through with our debugger to find out which of these paths Hypixel uses to set our scoreboard, or we might just try out the simpler case of always using `1` or we might reimplement this entire logic. We can also see that `theWorld.getScoreboard()` is used to get the scoreboard instance. If we investigate a bit more we might even find the `Scoreboard.getObjectiveDisplaySlot` confirming our suspicions that `1` means sidebar.

Now we can combine all that knowledge to write our own sidebar scoreboard parser:

```java
final int SIDEBAR_SLOT = 1;
Scoreboard scoreboard = Minecraft.getMinecraft().theWorld.getScoreboard();
ScoreObjective objective = scoreboard.getObjectiveInDisplaySlot(SIDEBAR_SLOT);
List<String> scoreList = scoreboard.getSortedScores(objective)
        .stream()
        .limit(15)
        .map(score ->
                ScorePlayerTeam.formatPlayerName(
                        scoreboard.getPlayersTeam(score.getPlayerName()),
                        score.getPlayerName()))
        .collect(Collectors.toList());
Collections.reverse(scoreList);
for (String s : scoreList) {
    LogManager.getLogger("Scoreboard").info(s);
    sender.addChatMessage(new ChatComponentText(s));
}
```

After writing this command and testing it in a single player world everything seems to work out! But not so fast! When we actually try this command on Hypixel something bad happens.

The printout in chat seems all right. But if we also print out the string into the console we see a bunch of weird emojis:
``` title="Output"
[17:03:46] [main/INFO] (Scoreboard) §701/29/24 §8m22💣§8AA
[17:03:46] [main/INFO] (Scoreboard)   👽
[17:03:46] [main/INFO] (Scoreboard)  Autumn 30th🔮
[17:03:46] [main/INFO] (Scoreboard)  §710:30am §e☀🐍
[17:03:46] [main/INFO] (Scoreboard)  §7⏣ §bVillage👾
[17:03:46] [main/INFO] (Scoreboard)  §7♲ §7Ironman🌠
[17:03:46] [main/INFO] (Scoreboard)        🍭
[17:03:46] [main/INFO] (Scoreboard) Piggy: §668,463⚽
[17:03:46] [main/INFO] (Scoreboard) Bits: §b46,180🏀
[17:03:46] [main/INFO] (Scoreboard)           👹
[17:03:46] [main/INFO] (Scoreboard) §6Spooky Festiva🎁§6l§f 31:14
[17:03:46] [main/INFO] (Scoreboard)             🎉
[17:03:46] [main/INFO] (Scoreboard) §ewww.hypixel.ne🎂§et
```

Turns out, hypixel uses Emojis as player name in order to never conflict with anyones player name. Those don't get rendered by vanillas text renderer, but our code of course doesn't know this yet.

At this point we are a bit tired, so instead of investigating which characters don't or do get rendered by Minecraft we might settle for the easy way out. Simply checking how wide Minecraft thinks a char is. If it is 0 wide, it is probably not being rendered:


```java
String stripAliens(String text) {
    StringBuilder sb = new StringBuilder();
    for (char c : text.toCharArray()) {
        if (Minecraft.getMinecraft().fontRendererObj.getCharWidth(c) > 0 || c == '§')
            sb.append(c);
    }
    return sb.toString();
}
```

Or you could go even easier and just manually have a blacklist of emojis (since they always seem to be the same). In either case you arrive at a beautiful, clean scoreboard string list:

``` title="Output"
[17:09:57] [main/INFO] (Scoreboard) §701/29/24 §8m23§8AP
[17:09:57] [main/INFO] (Scoreboard)
[17:09:57] [main/INFO] (Scoreboard)  Autumn 30th
[17:09:57] [main/INFO] (Scoreboard)  §75:50pm §e☀
[17:09:57] [main/INFO] (Scoreboard)  §7⏣ §bVillage
[17:09:57] [main/INFO] (Scoreboard)  §7♲ §7Ironman
[17:09:57] [main/INFO] (Scoreboard)
[17:09:57] [main/INFO] (Scoreboard) Piggy: §668,468
[17:09:57] [main/INFO] (Scoreboard) Bits: §b46,180
[17:09:57] [main/INFO] (Scoreboard)
[17:09:57] [main/INFO] (Scoreboard) §6Spooky Festiva§6l§f 25:04
[17:09:57] [main/INFO] (Scoreboard)
[17:09:57] [main/INFO] (Scoreboard) §ewww.hypixel.ne§et
```

Hopefully this last excurs has showed you how you might go about finding information in Minecraft's source code. Most things you will encounter are not going to be documented, and this scoreboard example was just one of the many example I could've chosen for this excurs. So don't be frustrated, because finding these kinds of things is exactly what the fun of modding is all about.

And lastly: If you do get stuck — seek help. Other people probably have walked this path before. Finding existing [open source projects][mod-list] and using their techniques for extracting information out of Minecraft can really speed up your work. Just make sure to properly check licenses and credit your code. Preferably both in a comment in the code, as well as the README of your mod. Or even better: ask before you take code. Most developers have been in your position before and will be sympathetic to someone just starting out with modding; Stealing code will leave you without that community and possible in legal troubles, once you encounter your next road block.


