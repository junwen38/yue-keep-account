import 'package:flutter/material.dart';

class CategoryGridView extends StatelessWidget {
  final Function onPress;
  final Function onLongPress;
  final Function onAdditionPress;
  final List<dynamic> categories;
  final int type;
  final int selectedItem;

  CategoryGridView(
      {this.onPress,
      this.onLongPress,
      this.onAdditionPress,
      this.categories,
      this.type,
      this.selectedItem});

  MaterialColor getColor() {
    if (type == 0)
      return Colors.red;
    else
      return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    var moreWidget = Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: Colors.black26),
        child: Text(
          "...",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
    return GridView.count(
      crossAxisCount: 5,
      children: [
        ...categories.map(
          (e) => TextButton(
              style: ButtonStyle(
                  backgroundColor: e["id"] != selectedItem
                      ? MaterialStateProperty.all(Colors.white)
                      : MaterialStateProperty.all(getColor())),
              onPressed: () async => await onPress(e),
              onLongPress: () async => await onLongPress(e),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Flex(
                      mainAxisAlignment: MainAxisAlignment.center,
                      direction: Axis.vertical,
                      children: [
                        Icon(
                          Icons.grade,
                          color: e["id"] != selectedItem
                              ? getColor()
                              : Colors.white,
                          size: 40,
                        ),
                        Text(
                          e["name"],
                          style: TextStyle(
                              color: e["id"] != selectedItem
                                  ? getColor()
                                  : Colors.white),
                        ),
                      ]),
                  ...(e["haveChildren"] ? [moreWidget] : [])
                ],
              )),
        ),
        ...(onAdditionPress != null
            ? [
                TextButton(
                  onPressed: onAdditionPress,
                  child: Flex(
                    mainAxisAlignment: MainAxisAlignment.center,
                    direction: Axis.vertical,
                    children: [
                      Icon(Icons.add, color: getColor(), size: 40),
                    ],
                  ),
                )
              ]
            : []),
      ],
    );
  }
}
