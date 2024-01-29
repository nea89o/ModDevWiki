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
    You need to use `slot.slotNumber` or the `i` index you used for iterating here. Using the `getSlotIndex` is meaningless, since that index is the index *inside* of the inventory (so the first hotbar slot is always index `0`, just like the first slot of a chest)

Overall i think that the index based method is a lot less pretty. Not only is it not a real invariant of the `Container` class for those two inventories to exist in this order (In theory you could have a `Container` that puts the `slotNumber` of the `InventoryPlayer` first, and then the chest contents. This is not the case in vanilla code, however), but it also very prone to mistakes, such as messing up `<` and `<=`. We also lose all help from the type system. That `int` has no types associated with it, so especially when passing arounds `int`s like that, they use meaning very quickly, so we have to write a lot more documentation to keep our code understandable. The `inventory instanceof InventoryPlayer` is very explicit and our code reads almost like documentation itself: "is this slot inside of the players inventory or not".
