import 'package:accountbook_mobile/widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api.dart';

class CategorySettingPage extends StatefulWidget {
  final Map _args;

  CategorySettingPage(this._args);

  @override
  State<StatefulWidget> createState() {
    return _CategorySettingPageState(_args);
  }
}

class _CategorySettingPageState extends State<CategorySettingPage> {
  Future<dynamic> _ajaxFuture;
  dynamic _parent;

  _CategorySettingPageState(Map args) {
    if (args != null) {
      _parent = args["parent"];
    }
  }

  @override
  void initState() {
    super.initState();
    _ajaxFuture = _refresh();
  }

  Future<dynamic> _refresh() async {
    var query = _parent == null ? "" : "?parentId=${_parent['id']}";
    var res = await api("/category/$query");
    return res.data;
  }

  void _showSubCategory(BuildContext context, dynamic parent) {
    if (this._parent != null) return;
    Navigator.of(context)
        .pushNamed("CategorySetting", arguments: {"parent": parent});
  }

  void _showAdditionForm(BuildContext context, dynamic parent, int type) async {
    await Navigator.of(context).pushNamed("CategoryAddition",
        arguments: {"parent": parent, "type": type});
    setState(() {
      _ajaxFuture = _refresh();
    });
  }

  void _showMenu(BuildContext context, dynamic category) {
    showModalBottomSheet(
        builder: (context) {
          return Container(
              height: 200,
              child: ListView(
                children: [
                  ListTile(
                    title: Text(
                      "重命名",
                    ),
                  ),
                  ListTile(
                    title: Text(
                      "删除",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _onDeleteCategory(category),
                  )
                ],
              ));
        },
        context: context);
  }

  void _onDeleteCategory(dynamic category) async {
    try {
      Navigator.of(context).pop();
      await api("/category/${category["id"]}", method: "DELETE");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("删除成功")));
      setState(() {
        _ajaxFuture = _refresh();
      });
    } on DioError catch (e) {
      handleError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Tab> tabs = [];
    if (_parent == null) {
      tabs.add(Tab(
        text: "支出",
      ));
      tabs.add(Tab(
        text: "收入",
      ));
    } else {
      if (_parent["type"] == 0) {
        tabs.add(Tab(text: "支出"));
      } else {
        tabs.add(Tab(text: "收入"));
      }
    }
    return DefaultTabController(
      length: tabs.length,
      initialIndex: 0,
      child: Scaffold(
          appBar: AppBar(
            title: Text("收支分类"),
            bottom: TabBar(tabs: tabs),
          ),
          body: FutureBuilder(
              future: _ajaxFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return TabBarView(
                    children: [
                      ...tabs.map((item) {
                        switch (item.text) {
                          case "支出":
                            return CategoryGridView(
                              type: 0,
                              categories: [
                                ...snapshot.data.where((i) => i["type"] == 0)
                              ],
                              onPress: (item) =>
                                  _showSubCategory(context, item),
                              onAdditionPress: () =>
                                  _showAdditionForm(context, _parent, 0),
                              onLongPress: (item) => _showMenu(context, item),
                            );
                          case "收入":
                            return CategoryGridView(
                              type: 1,
                              categories: [
                                ...snapshot.data.where((i) => i["type"] == 1)
                              ],
                              onPress: (item) =>
                                  _showSubCategory(context, item),
                              onAdditionPress: () =>
                                  _showAdditionForm(context, _parent, 1),
                              onLongPress: (item) => _showMenu(context, item),
                            );
                          default:
                            return Center();
                        }
                      })
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("数据加载失败"),
                  );
                } else {
                  return Center(
                    child: Text("Loading..."),
                  );
                }
              })),
    );
  }
}

class CategoryAdditionPage extends StatefulWidget {
  final Map _args;

  CategoryAdditionPage(this._args);

  @override
  State<StatefulWidget> createState() {
    return _CategoryAdditionPageState(_args);
  }
}

class _CategoryAdditionPageState extends State<CategoryAdditionPage> {
  Map<String, TextEditingController> _controllers = {
    "name": TextEditingController()
  };
  Map _args;

  _CategoryAdditionPageState(this._args);

  String getValue(String name) {
    return _controllers[name].value.text;
  }

  @override
  Widget build(BuildContext context) {
    Map arguments = _args;
    return Scaffold(
        appBar: AppBar(
          title: Text("添加分类"),
        ),
        body: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Form(
              child: Column(
                children: [
                  arguments['parent'] != null
                      ? Center(
                          child: Text("大分类：${arguments['parent']['name']}"))
                      : Center(),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: "分类名称",
                        labelStyle: TextStyle(
                            color: arguments["type"] == 0
                                ? Colors.red
                                : Colors.green)),
                    controller: _controllers["name"],
                  ),
                  Center(
                    child: Builder(builder: (context) {
                      return TextButton(
                        child: Center(child: Text("添加分类")),
                        onPressed: () async {
                          try {
                            await api("/category", method: "POST", data: {
                              "name": getValue("name"),
                              "type": arguments["type"],
                              ...(arguments["parent"] != null
                                  ? {"parentId": arguments["parent"]["id"]}
                                  : {})
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("分类添加成功"),
                            ));
                            Navigator.pop(context, true);
                          } on DioError catch (e) {
                            handleError(context, e);
                          }
                        },
                      );
                    }),
                  )
                ],
              ),
            )));
  }
}

class NotePage extends StatefulWidget {
  final Map _args;
  NotePage(this._args);

  @override
  State<StatefulWidget> createState() {
    return _NotePageState(_args);
  }
}

class _NotePageState extends State<NotePage> {
  Future _future;
  Map _args;
  dynamic _item;
  bool _showPayout = false;
  bool _showIncome = false;

  _NotePageState(this._args) {
    _future = _refresh();

    _item = _args["item"];
    if (_item == null) {
      _showIncome = true;
      _showPayout = true;
    } else {
      if (_item["type"] == 0) {
        _showPayout = true;
      } else if (_item["type"] == 1) {
        _showIncome = true;
      }
    }
  }

  Future<dynamic> _refresh() async {
    var res = await api("/category/");
    return res.data;
  }

  @override
  Widget build(BuildContext context) {
    var tabs = <Widget>[
      ...(_showPayout ? [Tab(text: "支出")] : []),
      ...(_showIncome ? [Tab(text: "收入")] : [])
    ];
    return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
            appBar: AppBar(
              title: Text("记一笔"),
              bottom: TabBar(
                tabs: tabs,
              ),
            ),
            body: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var categories = snapshot.data;
                  return TabBarView(children: [
                    ...(_showPayout ? [NoteForm(categories, 0, _item)] : []),
                    ...(_showIncome ? [NoteForm(categories, 1, _item)] : []),
                  ]);
                } else if (snapshot.hasError) {
                  //Error
                  return Center(child: Text("加载失败"));
                } else {
                  //Loading
                  return Center(child: Text("Loading..."));
                }
              },
            )));
  }
}
