# Inspecting Inventories

Whether you want to sum up item prices in a chest, highlight bazaar orders that have been filled, or want to check if you are currently in an npc shop to prevent the player from selling their hyperion, almost every single SkyBlock mod will eventually want to read from an inventory.

## Getting the inventory

Let's just for now be quick and dirty and use a `ClientTickEvent`. The `ClientTickEvent` gets run multiple times each tick, so having code in there is generally not super recommended. But for now this will be fine.

```java
@SubscribeEvent
public void onTick(TickEvent.ClientTickEvent event) {
    if (event.phase != TickEvent.Phase.END) return; // (1)!
    GuiScreen currentScreen = Minecraft.getMinecraft().currentScreen;
    if (!(currentScreen instanceof GuiChest)) return; // (2)!
    GuiChest currentScreen1 = (GuiChest) currentScreen;
    ContainerChest container = (ContainerChest) currentScreen1.inventorySlots; // (3)!
    LogManager.getLogger("ExampleMod").info("Container Name: " 
        + container.getLowerChestInventory().getDisplayName().getFormattedText()); // (4)!
}
```

1. First, we only want to check in one phase. The `ClientTickEvent` is called multiple times per tick, but we only need to check the GUI once per tick.
2. Check if we are in a chest
3. Cast the screen chest, get the container coresponding to the chest and cast that to be a ContainerChest.
4. Log out the display name of the chest inventory

So there are a few interesting things going on here. And maybe we should start with the question what is a `GuiChest` versus a `ContainerChest` versus a `IInventory`.

The `GuiChest` is probably the easiest one. It represents the actual GUI you see, so it contains information about user actions (such as dragged item stacks, hovered slots) and does the actual drawing and click handling.

However, `GuiChest` does not store any items. Instead it has a reference to a `Container`. The `Container` represents the logical state of that chest interface. It contains informations about all the items on screen as well as logical counterparts to GUI state (such as the dragged item stacks).

But the `Container` is actually not the master of all things items either, instead it aggregates an `IInventory`. Those are the actual definitive sources of state for the items. In case of a `ChestContainer` there are actually two `IInventory` instance, one for the player inventory, and one for the chest contents. Confusingly the chest contents are called `lowerChestInventory` despite being in the upper part of the screen. The `IInventory` also contains information about the name of the chest.

Another thing to note here is that we cast a `Container` to a `ContainerChest`. We can do this, because the `GuiChest` always has a `ContainerChest` as container, even if that information isn't present in the type system.

## Accessing Items

Now that we know the basics of inventory logistics of Minecraft, we can actually make use of our opened chest gui.

```java
// Continuing the TickEvent from before
for (int i = 0; i < container.getLowerChestInventory().getSizeInventory(); i++) {
    ItemStack stack = container.getLowerChestInventory().getStackInSlot(i);
    if (stack != null)
        LogManager.getLogger("ExampleMod").info("Slot " + i + ": " + stack);
}
```

``` title="Output"
[22:19:28] [main/INFO] (ExampleMod) Container Name: Large Chest§r
[22:19:28] [main/INFO] (ExampleMod) Slot 0: 12xitem.enderPearl@0
[22:19:28] [main/INFO] (ExampleMod) Slot 1: 51xtile.tnt@0
```

Note that we access the `lowerChestInventory` here. Accessing the `ContainerChest` directly gives us not only the chest contents, but the player inventory also, as all slots get merged into one uber ItemStack storage. This behaviour might actually be wanted sometimes (for example, you might want to highlight slots in both your as well as the chest inventory). Also note that when we access the `IInventory` we directly access `ItemStack`s. Accessing the `ContainerChest` directly is a bit easier and more powerful, but also implicitly includes the player inventory, so extra measure need to be taken:


```java
for (int i = 0; i < container.inventorySlots.size(); i++) {
    Slot slot = container.inventorySlots.get(i);
    if (slot.getHasStack() /* equivalent to slot.getStack() != null */)
        LogManager.getLogger("ExampleMod").info("Slot " + i + ": " + slot.getStack());
}

```

``` title="Output"
[22:23:03] [main/INFO] (ExampleMod) Container Name: Large Chest§r
[22:23:03] [main/INFO] (ExampleMod) Slot 0: 12xitem.enderPearl@0
[22:23:03] [main/INFO] (ExampleMod) Slot 1: 51xtile.tnt@0
[22:23:03] [main/INFO] (ExampleMod) Slot 54: 1xitem.potion@0
[22:23:03] [main/INFO] (ExampleMod) Slot 55: 1xitem.potion@0
[22:23:03] [main/INFO] (ExampleMod) Slot 56: 1xitem.potion@0
[22:23:03] [main/INFO] (ExampleMod) Slot 57: 1xitem.potion@0
[22:23:03] [main/INFO] (ExampleMod) Slot 58: 1xitem.potion@0
[22:23:03] [main/INFO] (ExampleMod) Slot 59: 1xitem.bootsChain@0
[22:23:03] [main/INFO] (ExampleMod) Slot 60: 1xitem.skull@3
[22:23:03] [main/INFO] (ExampleMod) Slot 61: 6xitem.skull@3
[22:23:03] [main/INFO] (ExampleMod) Slot 62: 1xitem.swordIron@0
[22:23:03] [main/INFO] (ExampleMod) Slot 73: 1xitem.blazeRod@0
[22:23:03] [main/INFO] (ExampleMod) Slot 81: 1xitem.bow@0
[22:23:03] [main/INFO] (ExampleMod) Slot 82: 1xitem.swordDiamond@0
[22:23:03] [main/INFO] (ExampleMod) Slot 83: 1xitem.stick@0
[22:23:03] [main/INFO] (ExampleMod) Slot 84: 1xitem.pickaxeDiamond@0
[22:23:03] [main/INFO] (ExampleMod) Slot 85: 1xitem.swordGold@0
[22:23:03] [main/INFO] (ExampleMod) Slot 88: 1xitem.horsearmorgold@0
[22:23:03] [main/INFO] (ExampleMod) Slot 89: 1xitem.netherStar@0
``` 

First note that we can now use `Slot`s instead of plain `ItemStack`. A `Slot` contains extra information such as `xDisplayPosition` and `yDisplayPosition` which you might need in case you want to draw something around certain items.

If you want to use `Slot`s without worrying about potential player slots sneaking in, you can use two methods for finding out where a slot belongs:

```java
Slot slot = container.inventorySlots.get(i);
boolean isChestSlotA = !(slot.inventory instanceof InventoryPlayer);
boolean isChestSlotB = i < container.getLowerChestInventory().getSizeInventory();
boolean WRONG_METHOD = slot.getSlotIndex() < container.getLowerChestInventory().getSizeInventory();
```

!!! important
    You need to use `slot.slotNumber` or the `i` index you used for iterating here. Using the `getSlotIndex` is meaningless, since that index is the index *inside* of the `IInventory` (so the first hotbar slot is always index `0`, just like the first slot of a chest)

Overall I think that the index based method is a lot less pretty. Not only is it not a real invariant of the `Container` class for those two inventories to exist in this order (In theory you could have a `Container` that puts the `slotNumber` of the `InventoryPlayer` first, and then the chest contents. This is not the case in vanilla code, however), but it also very prone to mistakes, such as messing up `<` and `<=`. We also lose all help from the type system. That `int` has no types associated with it, so especially when passing arounds `int`s like that, they use meaning very quickly, so we have to write a lot more documentation to keep our code understandable. The `inventory instanceof InventoryPlayer` is very explicit and our code reads almost like documentation itself: "is this slot inside of the players inventory or not".

## Inside of Items

Just logging out items to the command line is neat and all, but in most cases you will want to programatically inspect items.

So, for the final time in this article, let's do a disambiguation: `ItemStack` versus `Item`. This one is hopefully a simple one.

`ItemStack` represents a concrete stack. It has a size, metadata (custom name, custom lore, ExtraAttributes). If you have two item stacks in a chest somewhere, you will have two instances of `ItemStack` that reference those *exact* two item stacks.

`Item` on the other hand represents a *type* of an item. For example, a `diamond_sword` or a `dirt`. Some things that you might think of as an "item type" is actually grouped together under one `Item` instance. Different coloured objects, such as wool or dyes are all just one `Item.dye` and which dye you are referencing is part of the `ItemStack` metadata. You will find most `Item`s inside of the `Items` class (`Items.apple`). However, items that correspond to a `Block` are usually not found in there. Instead, you can use `Item.getItemFromBlock(Blocks.dirt)` to get those `Item` types. Note that you will always get the same exact object instance from this method, so you can use `==` on those returned objects. Also be aware that some more exotic blocks (such as doors) might have individual `Item`s that end up placing a completely unrelated `Block`. For example: there is a `Items.wheat_seeds` which places a `Blocks.wheat` when right clicked on farmland, but calling `Item.getItemFromBlock(Blocks.wheat)` will get you a null instead of your `Items.wheat_seed`. For those "placer" `Item`s you will usually want to work in whatever medium is native for what you are doing (`Item` for inventories and entities, `Block` for reading world data).

How do you get data out of an `ItemStack` now. There are two ways of going about this: APIs or NBT.

### Item APIs

Item APIs are arguably easier to use, so you might be tempted to just always use the, but they have some disadvantages I will talk about soon.

```java
logger.info("Slot " + i + ":");
logger.info("  Item: " + stack.getItem());
logger.info("  Display Name: " + stack.getDisplayName());
logger.info("  Stack Size: " + stack.stackSize);
logger.info("  Lore:");
for (String loreLine : stack.getTooltip(Minecraft.getMinecraft().thePlayer, false)) {
    logger.info("   - " + loreLine);
}
```

This prints out all the information very nicely:

``` title="Output"
[22:50:07] [main/INFO] (ExampleMod) Slot 1:
[22:50:07] [main/INFO] (ExampleMod)   Item: net.minecraft.item.ItemBlock@68a94e58
[22:50:07] [main/INFO] (ExampleMod)   Display Name: §9Superboom TNT
[22:50:07] [main/INFO] (ExampleMod)   Stack Size: 51
[22:50:07] [main/INFO] (ExampleMod)   Lore:
[22:50:07] [main/INFO] (ExampleMod)    - §o§9Superboom TNT§r
[22:50:07] [main/INFO] (ExampleMod)    - §5§o§7Breaks weak walls. Can be used to
[22:50:07] [main/INFO] (ExampleMod)    - §5§o§7blow up Crypts in §cThe Catacombs §7and
[22:50:07] [main/INFO] (ExampleMod)    - §5§o§7§5Crystal Hollows§7.
[22:50:07] [main/INFO] (ExampleMod)    - §5§o
[22:50:07] [main/INFO] (ExampleMod)    - §5§o§9§lRARE
```

We get a bit of a hiccup with the `Item`. Turns out just system out printing a `Item` isn't great. You can call `.getRegistryName()` to fix this however:

``` title="Output"
[22:52:30] [main/INFO] (ExampleMod)   Item: minecraft:tnt
```

### NBT APIs

But, we soon run into problems. Two kinds of problems: logical and performance. Using the standard APIs for lore and display name invoke Forge events, which causes a *lot* of other code to run, exponentially more code the more mods you have. This is not only slow (since those other mods might do some expensive calculations), but will also obscure information. Some mods might append some information to the bottom of the tooltip, thereby not making the rarity the last line of the lore anymore, for example.

So we turn to the API that doesn't call mods: NBT. NBT (Named Binary Tag) is a data format for storing essentially complex key value objects, similar to JSON. Instead of using verbose (human readable) representation for numbers, strings, bytes, booleans, lists, dictionaries NBT uses binary. There is a format called SNBT that represents NBT data in a human readable way, which looks like slightly modified JSON, which i will also use for NBT in here.

Minecraft uses NBT to store all the information about items, blocks and entities in the background. Most of that data is only available on the server (thereby inaccessible inside of a client mod) and sent to the client via some other mean. The big exception to that are items. `ItemStack`s are sent (almost) entirely via NBT.

```java
byte STRING_NBT_TAG = new NBTTagString().getId(); // (1)!
NBTTagCompound tagCompound = stack.getTagCompound();// (2)!
if (tagCompound == null) continue; // (3)!
String displayName = tagCompound.getCompoundTag("display").getString("Name"); // (4)!
NBTTagList loreList = tagCompound.getCompoundTag("display").getTagList("Lore", STRING_NBT_TAG); // (5)!
for (int i1 = 0; i1 < loreList.tagCount(); i1++) { // (6)!
    String loreLine = loreList.getStringTagAt(i1); // (7)!
}
```

1. First let's save the tag id of a string. This is essentially the "type" of a string when using NBTs.
2. Access the NBT associated with an `ItemStack`. This will always be a `NBTTagCompound` which is equivalent to a JSON `object`
3. The `NBTTagCompound` of an `ItemStack` can be null.
4. First access the `NBTTagCompound` that is the "display". Then in that sub object access the string at "Name".
5. First access the `NBTTagCompound` that is the "display". Then in that sub object access a list with the elements of type `NBTTagString`
6. We can get the length of the list with `tagCount()`
7. Now we can access each line of lore from the list using `getStringTagAt`
   Given how long this code is, I usually have a helper method for these types of operations in my code:
   ```java
   public static <U extends NBTBase, T> List<T> listFromNBT(NBTTagList nbtList, Function<U, T> reader) {
       List<T> ts = new ArrayList<>(nbtList.tagCount());
       for (int i = 0; i < nbtList.tagCount(); i++) {
           ts.add(reader.apply((U) nbtList.get(i)));
       }
       return ts;
   }
   ``` 
   ```java
   NBTTagList loreList = tagCompound.getCompoundTag("display").getTagList("Lore", STRING_NBT_TAG);
   List<String> loreStrings = listFromNBT(loreList, NBTTagString::getString);
   ```
   This is a very powerful method that makes working with nbt lists a lot easier, but it also very easy to cause RuntimeExceptions this way. In the end I personally think that NBT is always a mess of potential runtime exceptions. There are some ways to make it more bearable, but it will always be error prone.


You can already see how our code is getting longer. And this isn't the only problem with NBTs. Some NBT elements might not be there even tho you expect them to be. There are two ways how this manifests. A `null` in case of the root `stack.getTagCompound()` or just missing properties inside of a `TagCompound`. In case of missing properties this will just silently default construct a matching object. This is already a problem here, since we will get an empty string if we don't have a display name set (instead of null, or a fallback to the item name). It would be great if we could have a more explicit "absent" value, but sadly NBT does not offer that. Instead you will need to manually and error pronely check with `hasKey`.

Another problem are those many string keys. Not only is it hard to remember them and look them up, but there is also 0 feedback at compile time for typos or any other faults in those strings. You will instead either crash at runtime, or more likely silently get empty (faulty) data.

All of this makes NBT extremely unattractive to work with. But if we want our code to work correctly, even with other mod installed, or if we want our code to run fast, then we will need to use NBT more often than we would like.

And it is not all bad. NBT also allows us access to bonus data that normal `ItemStack` APIs don't have access to. Enter `ExtraAttributes`.

### ExtraAttributes

`ExtraAttributes` is a set of extra NBT data that is sent along with most `ItemStack`s on Hypixel. It contains a lot of things from item ids to pet exp to enchants and reforges. It is essentially the machine readable counter part to the lore. Much like the lore it is not suuuper consistent, but usually survives more versions without changes. In the end we are always at the mercy of hypixel.


```json
{
    id: "minecraft:diamond_pickaxe",
    Count: 1b,
    tag: {
        ench: [{
            lvl: 9s,
            id: 32s
        }],
        Unbreakable: 1b,
        HideFlags: 254,
        display: {
            Lore: [ ... ],
            Name: "§aDiamond Pickaxe"
        },
        ExtraAttributes: {
            id: "DIAMOND_PICKAXE",
            enchantments: {
                efficiency: 9
            },
            uuid: "28d1c00d-2112-453a-82c1-c35a28bebf6f",
            timestamp: 1691931000000L
        }
    },
    Damage: 0s
}
```

We can see at the root the actual item metadata (the `Count`, `id` and `Damage`). Those are part of the `ItemStack` and are always parsed by the `ItemStack` APIs. The NBT we get access to with `getTagCompound` is the `tag` part of this SNBT.

The `ench` tag contains the *vanilla* enchantments. Those are used by vanilla code. Hypixel does not send all enchantments this way, only the ones that affect client behaviour, such as efficiency and depth strider.

The `Unbreakable` tag hides the durability bar. This makes your items not show the durability bar for a split second whenever you mine a block.

The `HideFlags` tag prevents minecraft from adding information to the lore. Each bit represents something different, like "Hide the fact that is item is marked as Unbreakable" or "hide the enchantments on this item".

We looked at the `display` tag earlier.

Lastly there is `ExtraAttributes`. This section is not vanilla at all. It is instead Hypixel's own internal data structures. This is used by Hypixels code to represent information about the item that go beyond what Minecraft can express. It contains an `id` that is the official hypixel id (which may be different from the vanilla id), `enchantments` (which is a tag compound mapping enchantment ids to levels), uuids which are a unique identifier for each item that exist (for example: no two ASPECT_OF_THE_END have the same uuid, you get a new one every time you craft) and so much more.

Some of this information is found on almost every item (such as `id`), some of this data is item specific and some of it is shared between only a few items.

Generally you can find out quite a lot about an item by looking at its `ExtraAttributes`. I can't go over everything here, but let's look at one more example:


```json
{
    id: "minecraft:skull",
    Count: 1b,
    tag: {
        SkullOwner: {
            Id: "ecc8937f-a09e-4f06-a10a-efadfaff1e3b",
            hypixelPopulated: 1b,
            Properties: {
                textures: [{
                    Value: "eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNzA3MWE3NmY2NjlkYjVlZDZkMzJiNDhiYjJkYmE1NWQ1MzE3ZDdmNDUyMjVjYjMyNjdlYzQzNWNmYTUxNCJ9fX0="
                }]
            },
            Name: "§ecc8937f-a09e-4f06-a10a-efadfaff1e3b"
        },
        display: {
            Lore: [ ... ],
            Name: "§7[Lvl 100] §6Elephant"
        },
        ExtraAttributes: {
            petInfo: "{\"type\":\"ELEPHANT\",\"active\":false,\"exp\":4.0048701025808394E7,\"tier\":\"LEGENDARY\",\"hideInfo\":false,\"heldItem\":\"GREEN_BANDANA\",\"candyUsed\":0,\"uuid\":\"8d35c8fe-1351-47f6-8609-e0b0fbcb077d\",\"uniqueId\":\"5cdc7008-009e-4730-8f52-cd970491ecc4\",\"hideRightClick\":false,\"noMove\":false}",
            id: "PET",
            uuid: "8d35c8fe-1351-47f6-8609-e0b0fbcb077d"
        }
    },
    Damage: 3s
}
```

This pet is a skull, which has some interesting information in the `SkullOwner` tag. That tag contains the texture for the skull. This can be used occassionally when identifying custom items that don't have a `ExtraAttributes.id` tag.


Also we can tell that the `id` of this pet is just `PET`. You might expect it to be `ELEPHANT_PET` from mods such as NEU, but those ids are just made up extensions to the `id` by Hypixel. The pet type is actually stored in the `petInfo` string, which is actually a string containing a normal JSON object that needs to be decoded on top of the NBT data parsing.

You can see all kinds of useful info in there, like `candyUsed` which is normally a stat hidden on level 100 pets. It contains information about the `type`, obviously, but also the total `exp` and the `heldItem` (with an item `id` instead of just a name).

This kind of way of inspecting data is really powerful and makes a lot of mods possible in the first place. But NBTs are messy and I would highly recommend you transfer NBTs into normal Java objects [as soon as possible](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

## Closing out - The GuiOpenEvent

And finally let's circle back to our first section, in which we started with the `ClientTickEvent`. In the end `ClientTickEvent` works just fine. But also, it leaves us lacking. The performance isn't great and we sometimes just miss items. Normally we could use a `GuiOpenEvent`. This fires whenever a gui is opened, so we could in theory just read all of our data once, when we open a chest. Sadly that doesn't work out, since Hypixel only sends the items after the GUI has opened. We might get some or all of the items in a single tick, but we can't be so sure about that when there are people with a 300, 400 or even 500 ms ping to Hypixel. There are many solutions to this problem: simply waiting a set amount of ticks after a `GuiOpenEvent` is probably the easiest one. That one is obviously a bit sloppy, but is also very simple to implement. Another solutions, would be mixing into `NetHandlerPlayClient.handleSetSlot` and listening for the bottommost rightmost item to be set (slotCount - 1) (this one is a lot cleaner, works faster and almost never gives us any partial inventory states), which still fails if Hypixel decides to use empty item stacks for that slot. Almost always there will be a glass pane or another item, but when a Hypixel GUI decides against using glass panes your code might not just run at all. You could maybe decide to mix those methods: either the last index is set, or we waited 5 ticks after the `GuiOpenEvent`. There are probably more options out there to explore and it is up to you how ridiculous you want to make your system for detecting inventory opens. In the end Hypixel doesn't specifically provide an API for mod developers, so we have to make due with what happens to work for us.



