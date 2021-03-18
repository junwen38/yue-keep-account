import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
            child: TextButton(
          child: Text("记一笔"),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue),
              padding: MaterialStateProperty.all(
                  EdgeInsets.fromLTRB(50, 10, 50, 10)),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              textStyle:
                  MaterialStateProperty.all(TextStyle(color: Colors.white))),
          onPressed: () {
            Navigator.of(context).pushNamed("Note", arguments: {});
          },
        )),
      ],
    );
  }
}

class SettingView extends StatefulWidget {
  @override
  _SettingViewState createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text("收支分类"),
          onTap: () {
            Navigator.pushNamed(context, "CategorySetting");
          },
        )
      ],
    );
  }
}
