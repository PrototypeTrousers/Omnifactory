import crafttweaker.item.IItemStack;
import crafttweaker.item.IIngredient;
import crafttweaker.item.ITooltipFunction;
import crafttweaker.recipes.IRecipeFunction;
import crafttweaker.recipes.ICraftingInfo;
import crafttweaker.data.IData;
import crafttweaker.formatting.IFormattedText;

val framingMaterial as IIngredient = <*>.only(function(stack as IItemStack) as bool {
    if(!stack.isItemBlock) {
        return false;
    }
    return stack.asBlock().definition.getStateFromMeta(stack.metadata).opaqueCube;
});

val sideIngredient = (<xtones:zane> | framingMaterial).marked("MatS");
val trimIngredient = (<extendedcrafting:storage:4> | framingMaterial).marked("MatT");
val frontIngredient = (<xtones:zane:15> | framingMaterial).marked("MatF");

function addInfo(stack as IItemStack) as IItemStack {
    return stack.withDisplayName("Frame your drawers by hand!")
        .withLore([
            "Top left: sides",
            "Top right: trim",
            "Middle left: front"
        ]);
}

function asData(stack as IItemStack) as IData {
    return {
        id: stack.definition.id,
        Count: 1 as byte,
        Damage: stack.metadata
    } as IData;
}

<ore:handFramedThree>.add(<storagedrawers:customdrawers:*>,
                          <framedcompactdrawers:framed_drawer_controller>,
                          <framedcompactdrawers:framed_compact_drawer>,
                          <framedcompactdrawers:framed_slave>,
                          <contenttweaker:hand_framing_tool>);

<ore:handFramed>.addAll(<ore:handFramedThree>);
<ore:handFramed>.add(<storagedrawers:customtrim>);

function getRecipeOutput(out as IItemStack,
                         ins as IItemStack[string],
                         cInfo as ICraftingInfo) as IItemStack
{
    var tag = {} as IData[string];
    for key, stack in ins {
        if(key != "drawer") {
            tag[key] = asData(stack);
        }
    }
    if (!isNull(ins.drawer.tag) &&
        ins.drawer.tag has "sticks") {
        tag["sticks"] = ins.drawer.tag.sticks;
    }
    val ret as any[any] = tag;
    return ins.drawer.withTag(ret as IData) * 1;
}

val recipeFunction = function(out, ins, cinfo) { return getRecipeOutput(out, ins, cinfo); } as IRecipeFunction;

for front in [true, false] as bool[] {
    for trim in [true, false] as bool[] {
        val ingredients as IIngredient[][] = [
            [
                sideIngredient,
                trim ? trimIngredient : null
            ],
            [
                front ? frontIngredient : null,
                (front ? <ore:handFramedThree> : <ore:handFramed>).marked("drawer")
            ]
        ];

        val ins as IItemStack[string] = {
            MatS: sideIngredient.items[0],
            drawer: <framedcompactdrawers:framed_compact_drawer>
        };

        if (front) {
            ins["MatF"] = frontIngredient.items[0];
        }

        if (trim) {
            ins["MatT"] = trimIngredient.items[0];
        }

        recipes.addShaped(
            "hand_framing_" + (trim ? "trim_" : "") + (front ? "front_" : "") + "side",
            addInfo(getRecipeOutput(null, ins, null)),
            ingredients,
            recipeFunction
        );
    }
}

val sticksIngredient = <ore:stickWood>.transformConsume(64);
val sticksRecipeFunction = function(out, ins, cinfo) {
    val sticksTag = ins.hft.tag.sticks;
    var sticks as int = (isNull(sticksTag) ? 0 : sticksTag as int);
    for k, v in ins {
        if k != "hft" {
            sticks += v.amount;
        }
    }
    return ins.hft.updateTag({ "sticks": sticks });
} as IRecipeFunction;
val hftIngredient = <contenttweaker:hand_framing_tool>.marked("hft");

for stickStacks in 1 .. 9 {
    var ingredients = [hftIngredient] as IIngredient[];
    for i in 0 .. stickStacks {
        ingredients += sticksIngredient.marked("stick" + i);
    }
    recipes.addShapeless(
        "hand_framing_tool_sticks_" + stickStacks,
        <contenttweaker:hand_framing_tool>,
        ingredients,
        sticksRecipeFunction
    );
}

function getNested(inTag as IData, keys as string[], alt as IData) as IData {
    var tag = inTag;
    for key in keys {
        if isNull(tag) return alt;
        tag = tag.memberGet(key);
    }
    return isNull(tag) ? alt : tag;
}

<contenttweaker:hand_framing_tool>.addAdvancedTooltip(
    function(stack as IItemStack) {
        return "Sticks: " + (isNull(stack) ? "0" : getNested(stack.tag, ["sticks"], 0));
    } as ITooltipFunction
);

function makeTagFunc(name as string) as ITooltipFunction {
    val matTag = "Mat" + name[0];
    return function(stack as IItemStack) as string {
        val item as IItemStack =
            isNull(stack) ?
            null :
            itemUtils.getItem(getNested(stack.tag, [matTag, "id"], "-"),
                              getNested(stack.tag, [matTag, "Damage"], 0));
        return name + ": " + (isNull(item) ? "-" : item.displayName);
    } as ITooltipFunction;
}

<contenttweaker:hand_framing_tool>.addAdvancedTooltip(makeTagFunc("Side"));
<contenttweaker:hand_framing_tool>.addAdvancedTooltip(makeTagFunc("Front"));
<contenttweaker:hand_framing_tool>.addAdvancedTooltip(makeTagFunc("Trim"));

recipes.addShaped(
    "hand_framing_tool",
    <contenttweaker:hand_framing_tool>,
    [[null, null, <storagedrawers:framingtable>],
     [null, <ore:stickWood>, null],
     [<ore:stickWood>, null, null]]
);