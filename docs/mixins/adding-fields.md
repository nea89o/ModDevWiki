# Adding new fields and methods

The next step up is injecting fields and methods into a class. This allows you to store additional state in objects, or can serve as an alternative to accessors for more complex operations that need to access private state of a class.

```java
@Mixin(EntityArmorStand.class)
public class InjectCustomField {
    Color colorOverride_mymodid = Color.RED;

    public void setColorOverride_mymodid(Color color) {
        colorOverride_mymodid = color;
    }

    public Color getColorOverride_mymodid() {
        return colorOverride_mymodid;
    }
}
```

This mixin is a `:::java class`, like all mixin (except for accessors) are. You can make the class abstract if you want. 

First we add a new field (of course with modid postfix) into every armor stand.

Then we also add a getter and a setter method for that field.

Right now we run into a problem. We can't access mixin `:::java class`es directly, so we cannot simply cast the `EntityArmorStand` into a `InjectCustomField`. Instead we create an interface (inside of our regular code, not inside of the mixin package) and implement that interface in our mixin class. You can also implement other interfaces this way, not just your own.

```java
// Inside our regular code. Not in the mixin package
public interface ColorFieldAccessor {
    void setColorOverride_mymodid(Color color);
    Color getColorOverride_mymodid();
}

// And the updated mixin
@Mixin(EntityArmorStand.class)
public class InjectCustomField implement ColorFieldAccessor {
    Color colorOverride_mymodid;

    @Override
    public void setColorOverride_mymodid(Color color) {
        colorOverride_mymodid = color;
    }

    @Override
    public Color getColorOverride_mymodid() {
        return colorOverride_mymodid;
    }
}
```

Now we can just cast any instance of `EntityArmorStand` to `ColorFieldAccessor`:

```java
public static Color getColorOverrideForArmorStand(EntityArmorStand armorStand) {
    return ((ColorFieldAccessor) armorStand).getColorOverride_mymodid();
}
```






