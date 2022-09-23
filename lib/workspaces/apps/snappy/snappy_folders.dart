import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_macos_webview/flutter_macos_webview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';

class SnappyFolder extends StatefulWidget {
  const SnappyFolder({Key? key, required this.changeView, this.workspaceId}) : super(key: key);
  final changeView;
  final workspaceId;

  @override
  State<SnappyFolder> createState() => _SnappyFolderState();
}

class _SnappyFolderState extends State<SnappyFolder> {
  List _explorer = [];
  List _fakeFileUpload = [];
  List _itemSelected = [];
  List _currentPath = [0];
  // int _typeFolder = 0;
  bool _loading = false;
  int indexSort = 0;
  bool sortAscending = true;
  Map _currentWorkspace = {};
  Map _pathToStringData = {0: "Tài liệu công ty", 1: "Tài liệu của bạn"};
  bool _personalCreated = true;
  ScrollController _controller = ScrollController();
  // GlobalKey<ScaffoldMessengerState> _keyScafoldMessenger = GlobalKey<ScaffoldMessengerState>();


  @override
  void initState() {
    super.initState();
    _currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final token = Provider.of<Auth>(context, listen: false).token;
    _loadFolder(_currentWorkspace["id"],[0], token);
    _controller.addListener(() {
      if (!_isChannelFiles()) return;
      if (_controller.position.pixels >= _controller.position.maxScrollExtent) {
        _loadFolder(this._currentWorkspace["id"], _currentPath, token, loadMore: true, offset: _explorer.length);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SnappyFolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      final token = Provider.of<Auth>(context, listen: false).token;
      setState(() {
        _explorer = [];
      });
      this._currentWorkspace = currentWorkspace;
      _loadFolder(currentWorkspace["id"],[0], token);
    }
  }

  _resortableListByName(List list, {asc}) {
    final intAsc = asc ?? true ? 1 : -1;
    isFolder(a) {
      return a["is_folder"] != null && a["is_folder"];
    }
    list.sort((a, b) {
      if (isFolder(a) && isFolder(b))
        return a["name"].compareTo(b["name"]) * intAsc;
      else if (isFolder(a))
        return -1;
      else if (isFolder(b))
        return 1 ;
      else
        return a["name"].compareTo(b["name"]) * intAsc;
    });
    return list;
  }

  _resortableListBySize(List list, {asc}) {
    multiWithUnit(String unit) {
      switch (unit) {
        case "GB":
        case "gb":
          return 1000000000.0;
        case "MB":
        case "mb":
          return 1000000.0;
        case "kb":
        case "KB":
          return 1000.0;
        default:
          return 1.0;
      }
    }
    regexParseSize(String sizeString) {
      final regex = RegExp(r'^([0-9]+.[0-9]+) *([a-zA-Z][a-zA-Z])');
      final firstMatch = regex.firstMatch(sizeString);

      if (firstMatch != null) {
        String? _szSize = firstMatch.group(1);
        String? _szUnit = firstMatch.group(2);
        if (_szSize != null && _szUnit != null) {
          double _zSize = double.parse(_szSize);
          double _zUnit = multiWithUnit(_szUnit);
          return _zSize * _zUnit;
        }
      }
      return null;
    }
    final intAsc = asc ?? true ? 1 : -1;
    isFolder(a) {
      return a["is_folder"] != null && a["is_folder"];
    }
    list.sort((a, b) {
      if (isFolder(a) && isFolder(b)){
        return 1;
      }
      else if (isFolder(a))
        return -1;
      else if (isFolder(b))
        return 1 ;
      else {
        double? _aSize = regexParseSize(a["image_data"]["size"]);
        double? _bSize = regexParseSize(b["image_data"]["size"]);
        if (a["image_data"]["size"] == null || _aSize == null) return 1;
        if (b["image_data"]["size"] == null || _bSize == null) return -1;

        return _aSize.compareTo(_bSize) * intAsc;
      }
    });
    return list;
  }

  _resortableListByTime(List list, {asc}) {
    final intAsc = asc ?? true ? 1 : -1;
    isFolder(a) {
      return a["is_folder"] != null && a["is_folder"];
    }
    list.sort((a, b) {
      String _saTime = a["inserted_at"];
      String _sbTime = b["inserted_at"];
      DateTime _aTime = DateTime.parse(_saTime);
      DateTime _bTime = DateTime.parse(_sbTime);
      if (isFolder(a) && isFolder(b)){
        return _aTime.compareTo(_bTime) * intAsc;
      }
      else if (isFolder(a))
        return -1;
      else if (isFolder(b))
        return 1 ;
      else {
        return _aTime.compareTo(_bTime) * intAsc;
      }
    });
    return list;
  }


  _loadFolder(workspaceId, path, token, {loadMore = false, offset = 0}) async {
    _explorer = loadMore || listEquals(_currentPath, path) ? _explorer : [];
    _fakeFileUpload = listEquals(_currentPath, path) ? _fakeFileUpload : [];
    _itemSelected.clear();
    this._currentPath = path;
    setState(() => _loading = true);
    final url = Utils.apiUrl + "workspaces/$workspaceId/file_explorers/list_directory?token=$token";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({"path": path, "offset": offset})
      );
      if (response.data["success"]) {
        if (_currentPath.length == 1 && _currentPath[0] == 1 && response.data["data"]["list"].isEmpty) {
          setState(() {
            _personalCreated = false;
          });
        }
        else setState(() {
          _personalCreated = true;
          // _typeFolder = response.data["data"]["type"];
          _explorer = _resortableListByName(loadMore ? _explorer + response.data["data"]["list"] : response.data["data"]["list"]);
          _loading = false;
        });
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _createFolder(workspaceId, path, token, name) async {
    final url = Utils.apiUrl + "workspaces/$workspaceId/file_explorers/create_folder?token=$token";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({"path": path, "name": name})
      );

      if (response.data["success"]) {
        final newFolderCreated = {
          "is_folder": true,
          "name": name,
          "id": response.data["id"],
          "path": [response.data["id"]] + path,
          "inserted_at": response.data["inserted_at"]
        };
        setState(() {
          _explorer = _explorer + [newFolderCreated];
        });
      } else {
        // final snackBar = SnackBar(
        //   content: Text(response.data["message"])
        // );
        // _keyScafoldMessenger.currentState?.showSnackBar(snackBar);
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"])))
          ])
        );
      }

    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _move(workspaceId, path, name, newPath, token) async {
    final url = Utils.apiUrl + "workspaces/$workspaceId/file_explorers/move?token=$token";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({"path": path, "name": name, "new_path": newPath})
      );
      if (response.data["success"]) {
        _loadFolder(workspaceId, _currentPath, token);
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"])))
          ])
        );
      }
    } catch (e,trace) {
      print("$e\n$trace");
    }
  }

  _delete(workspaceId, path, name, token) async {
    final url = Utils.apiUrl + "workspaces/$workspaceId/file_explorers/remove?token=$token";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({"path": path, "name": name})
      );
      if (response.data["success"]) {
        _loadFolder(workspaceId, _currentPath, token);
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"])))
          ])
        );
      }
    } catch (e,trace) {
      print("$e\n$trace");
    }
  }

  _rename(workspaceId, path, oldName, newName, isFolder, token) async {
    final url = Utils.apiUrl + "workspaces/$workspaceId/file_explorers/rename?token=$token";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({"path": path, "old_name": oldName, "new_name": newName, "is_folder": isFolder})
      );
      if (response.data["success"]) {
        _loadFolder(workspaceId, path, token);
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"])))
          ])
        );
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _createPersonal(workspaceId, token) async {
    final url = Utils.apiUrl + "workspaces/$workspaceId/file_explorers/create_personal?token=$token";
    try {
      final response = await Dio().post(
        url
      );
      print(response.data);
      if (response.data["success"]) {
        _loadFolder(workspaceId, this._currentPath, token);
      }
    } catch (e) {
      print("_createPersonal $_createPersonal");
    }
  }

  _backToPrevious(workspaceId, List path, token) {
    if (path.length == 1) return;
    path.removeAt(0);
    this._currentPath = path;
    _loadFolder(workspaceId, path, token);
  }
  _updatePath(List path, name) {
    _pathToStringData[path.first] = name;
  }

  _uploadFile(workspaceId, token) async {
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    final uploader = Provider.of<Work>(context, listen: false);
    if (currentMember["role_id"] > 3 && _currentPath[0] == 0) {
      showModal(
        context: context,
        builder: (_) => SimpleDialog(
        children: <Widget>[
            new Center(child: new Container(child: new Text('Bạn không đủ quyền để thực hiện thao tác này')))
        ])
      );
      return;
    }
    try {
      List files = await Utils.openFilePicker([]);
      files.forEach((item) async {
        final fakeItem = {
          "status": "uploading",
          "describe": "",
          "name": item["name"],
        };
        setState(() {
          _fakeFileUpload.add(fakeItem);
        });
        var uploadFile = await uploader.getUploadData(item);
        final result = await uploader.uploadImage(token, workspaceId, uploadFile, uploadFile["mime_type"], (value){}, pathFolder: _currentPath);
        if (result["success"]) {
          _explorer = _explorer + [{
            "name": result["name"],
            "file_url": result["content_url"],
            "is_folder": false,
            "path": _currentPath,
            "image_data": result["image_data"],
            "inserted_at": result["inserted_at"],
          }];
          setState(() {
            _fakeFileUpload.remove(fakeItem);
          });
        }
        else {
          setState(() {
            final index = _fakeFileUpload.indexWhere((element) => element == fakeItem);
            _fakeFileUpload[index]['status'] = 'uploadfailed';
            _fakeFileUpload[index]['describe'] = result['message'];
          });
        }


      });
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  bool _isChannelFiles() {
    final path = this._currentPath;
    if (path.length == 2 && path[1] == 0 && _pathToStringData[path[0]] == "File các channel") {
      return true;
    }
    return false;
  }

  bool get _nonFolder =>
    _itemSelected.where(
      (element) =>
        element["is_folder"] != null
        && element["is_folder"] == true
      ).isEmpty;

  Widget get _buildHeaderApp => SizedBox(
    width: double.infinity,
    child: Row(
      children: [
        Container(
          margin: EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => widget.changeView(1),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Icon(PhosphorIcons.arrowLeft, size: 20,),
            ),
          ),
        ),
        Text(
          "Quản lý tài liệu",
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500
          )
        ),
      ],
    ),
  );

  Widget _buildMainParticipant({isDark, workspaceId, token}) {
    Widget _participantButton({onPressed, text}) {
      return Container(
        width: 213, height: 58,
        margin: EdgeInsets.only(right: 18, top: 16),
        child: OutlinedButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              color: isDark
                      ? Palette.defaultTextDark
                      : Palette.defaultTextLight
              ),
          ),),
      );
    }
    return Row(
      children: [
        _participantButton(
          onPressed: () {},
          text: 'Gần đây',
        ),
        _participantButton(
          onPressed: () {
            _loadFolder(workspaceId, [0], token);
          },
          text: 'Tài liệu công ty'
        ),
        _participantButton(
          onPressed: () {
            _loadFolder(workspaceId, [1], token);
          },
          text: 'Tài liệu của bạn'
        )
      ],
    );
  }

  Widget backButton({workspaceId, token}) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff2E2E2E),
        borderRadius: BorderRadius.all(Radius.circular(2))),
      height: 32,
      width: 90,
      child: InkWell(
        onTap: () => _backToPrevious(workspaceId, this._currentPath, token),
        child: HoverItem(
          colorHover: Colors.white.withOpacity(0.15),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SvgPicture.asset(
                  'assets/icons/backDark.svg',
                  color: Palette.defaultTextDark
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    S.current.back,
                    style: TextStyle(color: Colors.white)
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backAndPath({workspaceId, token}) {
    return Row(
      children: [
        // _backButton(workspaceId: workspaceId, token: token),
        // SizedBox(width: 20),
        Expanded(child: _buildPath(workspaceId, token)),
      ],
    );
  }

  Widget _createPersonalWidget({workspaceId, token}) => Column(
    children: [
      Align(
        alignment: Alignment.topLeft,
        child: TextButton(
          onPressed: (){
            _createPersonal(workspaceId, token);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_sharp),
              Text("  Tạo thư mục cá nhân"),
            ],
          )
        ),
      ),
      Text("Bạn chưa có thư mục cá nhân")
    ],
  );

  Widget _footerAction({workspaceId, isDark, token}) {
    Widget _footerButton({onPressed, text}) {
      return Container(
        height: 30,
        margin: EdgeInsets.only(right: 18, top: 16),
        child: OutlinedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              isDark
              ? Color(0xff2E2E2E)
              : Color(0xffFFFFFF)
            )
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              color: isDark
              ? Palette.defaultTextDark
              : Palette.defaultTextLight
            ),
          ),),
      );
    }

    Widget _actionForSelectedItem({onPressed, text}) {
      return Container(
        height: 30,
        margin: EdgeInsets.only(right: 18, top: 16),
        child: OutlinedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              isDark
              ? Color(0xff2E2E2E)
              : Color(0xffFFFFFF)
            )
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              color: isDark
              ? Palette.defaultTextDark
              : Palette.defaultTextLight
            ),
          )
        ),
      );
    }

    Widget _actionMoveSelectedButton() {
      return _actionForSelectedItem(
        text: 'Move all',
        onPressed: () {
            showModal(
              context: context,
              builder: (context) {
                return _PopupFolderTree(
                  onSelectedPath: (path) {
                    _itemSelected.forEach((e) {
                      bool isFolder = e["is_folder"] != null && e["is_folder"];
                      _move(workspaceId, e["path"], isFolder ? null : e["name"], path, token);
                    });
                    setState(() {
                      _itemSelected.clear();
                    });
                  },
                );
              }
            );
          }
      );
    }
    Widget _actionDeleteSelectedButton() {
      return _actionForSelectedItem(
        text: 'Delete all',
        onPressed: () {
            showModal(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text("Remove all items?"),
                  actions: [
                    TextButton(
                      onPressed: (){
                        _itemSelected.forEach((e) {
                          bool isFolder = e["is_folder"] != null && e["is_folder"];
                          _delete(
                            workspaceId,
                            e["path"],
                            isFolder ? null : e["name"],
                            token
                          );
                        });
                      _itemSelected.clear();
                      Navigator.pop(context);
                      },
                      child: Text("Delete")
                    ),
                    TextButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      child: Text("Cancel")
                    )
                  ],
                );
              }
            );
          }
      );
    }

    Widget _actionDownloadSelectedButton() {
      return _actionForSelectedItem(
        text: 'Download all',
        onPressed: () {
          showModal(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Text("Download all item?"),
                actions: [
                  TextButton(
                    onPressed: (){
                      _itemSelected.forEach((e) {
                        _downloadFile(e);
                      });
                    _itemSelected.clear();
                    Navigator.pop(context);
                    },
                    child: Text("Delete")
                  ),
                  TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    child: Text("Cancel")
                  )
                ],
              );
            }
          );
        },
      );
    }

    return Row(
      children: [
        _footerButton(
          onPressed: () {
            showModal(
              context: context,
              builder: (context) {
                return _CreateFolder(
                  onCreate: (name) {
                    _createFolder(workspaceId, this._currentPath, token, name);
                  }
                );
              }
            );
          },
          text: 'Thêm mới thư mục'
        ),
        _footerButton(
          onPressed: () {
            _uploadFile(workspaceId, token);
          },
          text: 'Tải lên tệp'
        ),
        if (_itemSelected.isNotEmpty) _actionMoveSelectedButton(),
        if (_itemSelected.isNotEmpty) _actionDeleteSelectedButton(),
        if (_itemSelected.isNotEmpty && _nonFolder) _actionDownloadSelectedButton()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;
    final token = auth.token;
    return LayoutBuilder(
      builder: (context, cts) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeaderApp,
              _buildMainParticipant(
                isDark: isDark,
                workspaceId: currentWorkspace['id'],
                token: token
              ),
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: _backAndPath(workspaceId: currentWorkspace["id"], token: token),
              ),
              Expanded(
                child: _personalCreated
                ? _buildFolderTable(currentWorkspace["id"], token, constraints: cts)
                : _createPersonalWidget(workspaceId: currentWorkspace["id"], token: token)
              ),
              _footerAction(workspaceId: currentWorkspace["id"], token: token, isDark: isDark)
            ],
          ),
        );
      }
    );
  }

  Widget _buildPath(workspaceId, token) {
    Color _getPathItemColor(bool isLast, isHighlight) {
      final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
      return isHighlight ? Colors.blue
            : isLast ? isDark ? Colors.white
              : Colors.black
                : isDark ? Color(0xffB7B5B5)
                  : Colors.grey;
    }
    void _loadPathWithItem(e) {
      final index = _currentPath.reversed.toList().indexOf(e);
      List subPath = _currentPath.reversed.toList().sublist(0, index + 1).reversed.toList();
      _loadFolder(workspaceId, subPath, token);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._currentPath.reversed.map((e) {
            final isLast = _currentPath.reversed.last == e;
            return Row(
              children: [
                InkWell(
                  onTap: () => _loadPathWithItem(e),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 150
                    ),
                    child: _HighlightWidgetBuilder(
                      builder: (context, isHighlight) {
                        return Text(
                          _pathToStringData[e], overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _getPathItemColor(isLast, isHighlight)),
                        );
                      }
                    ),
                  ),
                ),
                if (!isLast) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(CupertinoIcons.chevron_forward, size: 17,),
                )
              ],
            );
          })
        ],
      ),
    );
  }

  void _downloadFile(e) => Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": e["file_url"], "name": e["name"], "key_encrypt": ""});
  void _showFolderTree(e, workspaceId, token) => showModal(
    context: context,
    builder: (context) {
      return _PopupFolderTree(
        onSelectedPath: (path) {
          bool isFolder = e["is_folder"] != null && e["is_folder"];
          _move(workspaceId, e["path"], isFolder ? null : e["name"], path, token);
        },
      );
    }
  );
  void _showRename(e, workspaceId, token) => showModal(
    context: context,
    builder: (context) {
      return _Rename(
        name: e["name"],
        onRename: (newName){
          _rename(workspaceId, this._currentPath, e["name"], newName, e["is_folder"], token);
        }
      );
    }
  );
  void _showDeleteAlert(e, workspaceId, token) => showModal(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text("Bạn có muốn xoá file này?"),
        actions: [
          TextButton(
            onPressed: (){
              bool isFolder = e["is_folder"] != null && e["is_folder"];
              _delete(workspaceId, e["path"], isFolder ? null : e["name"], token);
              Navigator.pop(context);
            },
            child: Text("Delete")
          ),
          TextButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: Text("Cancel")
          )
        ],
      );
    }
  );

  void _onSortByName(index, asc) {
    _explorer = _resortableListByName(_explorer, asc: asc);
    setState(() {
      indexSort = index;
      sortAscending = asc;
    });
  }

  void _onSortBySize(index, asc) {
    _explorer = _resortableListBySize(_explorer, asc: asc);
    setState(() {
      indexSort = index;
      sortAscending = asc;
    });
  }

  void _onSortByTime(index, asc) {
    _explorer = _resortableListByTime(_explorer, asc: asc);
    setState(() {
      indexSort = index;
      sortAscending = asc;
    });
  }

  Widget _buildDropdownWindowAction(e, workspaceId, token) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    bool isDefaultItem = e["default_index"] != null;

    bool isFolder = e["is_folder"] != null && e["is_folder"];
    Widget _actionButton({onTap, text}) {
      return HoverItem(
        colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: InkWell (
            onTap: () {
              Navigator.pop(context);
              onTap.call();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              child: Text(text, style: TextStyle(color: onTap == null ? Colors.grey : Colors.white),),
            ),
          ),
        ),
      );
    }
    return DropdownOverlay(
      width: 200,
      menuDirection: MenuDirection.end,
      dropdownWindow: Container(
        decoration: BoxDecoration(
          color:Color(0xff4C4C4C),
          borderRadius: BorderRadius.circular(4)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _actionButton(
              text: "Copy",
              onTap: isFolder? null : (){}
            ),
            _actionButton(
              text: "Move",
              onTap: isDefaultItem ? null : () => _showFolderTree(e, workspaceId, token)
            ),
            _actionButton(
              text: "Rename",
              onTap: () => _showRename(e, workspaceId, token)
            ),
            _actionButton(
              text: "Download",
              onTap: isFolder ? null : () => _downloadFile(e)
            ),
            _actionButton(
              text: "Delete",
              onTap: isDefaultItem ? null :  () => _showDeleteAlert(e, workspaceId, token)
            ),
          ],
        ),
      ),
      onTap: () {
      },
      child: Icon(CupertinoIcons.ellipsis, size: 16)
    );
  }

  Widget _buildFolderTable(workspaceId, token, {constraints}) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    String? _renderTime(String? time) {
      if (time != null){
        final DateTime? _time = DateTime.tryParse(time);
        // return DateFormat.
        if (_time != null) return DateFormat.yMd('en_us').add_Hm().format(_time);
        return null;
      }
      return null;
    }
    List<DataRow> rows = [];
    for(int i = 0 ; i < _explorer.length; i ++) {
      bool isFolder = _explorer[i]["is_folder"] != null && _explorer[i]["is_folder"];
      bool isDefaultItem = _explorer[i]["default_index"] != null;
      bool isImage = () {
          return ["jpeg", "jpg", "png", "webp"]
                    .contains(_explorer[i]["name"]
                      .split(".")
                        .last.toString()
                          .toLowerCase());
        }.call();
        bool isVideo = () {
          return ["mp4", "mov"]
                  .contains(_explorer[i]["name"]
                    .split(".")
                      .last.toString()
                        .toLowerCase());
        }.call();
      var showImage = () =>
        showModal(
          context: context,
          builder: (context) {
            return AlertDialog(
              content:  ExtendedImage.network(
              _explorer[i]["file_url"],
              fit: BoxFit.contain,
              cache: true,
              clearMemoryCacheWhenDispose: true,
              mode: ExtendedImageMode.none,
            ),
            );
          }
        );
        var showVideo = () async {
          final webview = FlutterMacOSWebView(
            onWebResourceError: (err) {
            },
          );
          await webview.open(
            url: _explorer[i]["file_url"],
            presentationStyle: PresentationStyle.modal,
            modalTitle: "${_explorer[i]["name"]}",
            size: Size(1280, 720),
          );
        };

        var showUnknownType = () =>
        showModal(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text("Cannot show preview, download?"),
              actions: [
                TextButton(
                  onPressed: () {
                    _downloadFile(_explorer[i]);
                    Navigator.pop(context);
                  },
                  child: Text("Download")
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel")
                )
              ],
            );
          }
        );
      Widget nameButton;
      ButtonStyle nameButtonStyte = ButtonStyle(
        alignment: Alignment.centerLeft,
        padding: MaterialStateProperty.all(
          EdgeInsets.zero
        )
      );
      Color? iconColor = Theme.of(context).iconTheme.color;
      TextStyle? textStyle =  Theme.of(context).textTheme.bodyText1;
      Widget child;
      if (isFolder) {
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.folderLight, color: iconColor),
            SizedBox(width: 10),
            Text(_explorer[i]["name"], style: textStyle),
          ],
        );
        nameButton = TextButton(
          onPressed: () {
            _updatePath(_explorer[i]["path"], _explorer[i]["name"]);
            _loadFolder(workspaceId, _explorer[i]["path"], token);
          },
          style: nameButtonStyte,
          child: child,
        );
      } else {
        child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isImage? PhosphorIcons.image :
                  isVideo? PhosphorIcons.fileAudio :
                            PhosphorIcons.fileTextLight,
                color: iconColor),
            SizedBox(width: 10),
            Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 2 / 5),
              child: Text(_explorer[i]["name"],
                style: textStyle,
                overflow: TextOverflow.ellipsis
              )
            ),
          ],
        );

        var onPressed = isImage ? showImage : isVideo ? showVideo : showUnknownType;

        nameButton = TextButton(
          style: nameButtonStyte,
          onPressed: onPressed,
          child: child
        );
      }
      nameButton = Row(
        children: [
          Checkbox(
            value: _itemSelected.contains(_explorer[i]),
            onChanged: isDefaultItem ? null : (value) {
              if (value == null || !value) {
                _itemSelected.remove(_explorer[i]);
              } else {
                _itemSelected.add(_explorer[i]);
              }
              setState((){});
            }
          ),
          nameButton
        ],
      );
      Widget sizeWidget = Text(!isFolder ? _explorer[i]["image_data"]["size"] ?? "" : "");
      Widget timeAddedWidget = Row(
        children: [
          if (_explorer[i]["inserted_at"] != null) Text(_renderTime(_explorer[i]["inserted_at"])!),
          Expanded(child: Container()),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildDropdownWindowAction(_explorer[i], workspaceId, token),
          )
        ],
      );

      DataCell nameCellInRow = DataCell(nameButton);
      DataCell sizeCellInRow = DataCell(sizeWidget);
      DataCell timeCellInRow = DataCell(timeAddedWidget);

      DataRow row = DataRow(cells: [
        nameCellInRow,
        sizeCellInRow,
        timeCellInRow
      ]);

      rows.add(row);
    }
    return SingleChildScrollView(
      controller: _controller,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DataTable(
              sortColumnIndex: indexSort,
              sortAscending: sortAscending,
              border: TableBorder(),
              horizontalMargin: 0,
              columns: [
                DataColumn(label: Text("Name     "), onSort: _onSortByName),
                DataColumn(label: Text("File size     "), onSort: _onSortBySize),
                DataColumn(label: Text("Date added     "), onSort: _onSortByTime)
              ],
              rows: rows
            ),
          ),
          ..._fakeFileUpload.map((e) {
            return Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.symmetric(vertical: 10),
              color: Colors.white.withOpacity(0.15),
              child: Row(
                children: [
                  Text("Uploading ... ${e["name"]}"),
                  Expanded(
                    child: e['status'] == 'uploading' ? SpinKitThreeBounce(color: isDark ? Colors.white : Colors.grey[600]!, size: 18)
                    : Center(child: Text((e['describe'] ?? "Upload failed").toString(), style: TextStyle(color: Colors.red),))
                  )
                ],
              ),
            );
          }),
          if (_loading) Center(
            child: SpinKitFadingCircle(
              size: 35,
              color: isDark ? Colors.white60 : const Color(0xff096DD9)
            ),
          ),
          SizedBox(height: 200,)
        ],
      ),
    );
  }

  // _generateNewNameByIndex(String item) {
  //   List _filesWithIndex = _explorer.where((element) => element["is_folder"] == false).map((e) => e["name"]).cast<String>().where((element){
  //     return element.startsWith(item) && (item == element || int.tryParse(element.substring(item.length - 1, element.length - 1)) != null);
  //   }).toList();
  //   List<int> _existIndex = _filesWithIndex.cast<String>().map((e){
  //     if (e == item) return 0;
  //     else return int.parse(e.split(item)[1]);
  //   }).toList();
  //   return item + "(" + _existIndex.reduce((curr, next) => curr > next ? curr: next).toString() + ")";
  // }
}

class _PopupFolderTree extends StatefulWidget {
  _PopupFolderTree({Key? key, this.onSelectedPath}) : super(key: key);
  final onSelectedPath;

  @override
  State<_PopupFolderTree> createState() => _PopupFolderTreeState();
}

class _PopupFolderTreeState extends State<_PopupFolderTree> {
  List _currentPath = [];
  List _explorer = [];
  Map _pathToStringData = {0: "Tài liệu công ty", 1: "Tài liệu của bạn"};

  _loadFolder(workspaceId, path, token) async {
    this._currentPath = path;
    final url = Utils.apiUrl + "workspaces/$workspaceId/file_explorers/list_directory?token=$token";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({"path": path})
      );
      if (response.data["success"]) {
        setState(() {
          _explorer = response.data["data"]["list"];
          _explorer = _explorer.where((element) => element["is_folder"] != null && element["is_folder"]).toList();
          if (_currentPath.length == 1 && _currentPath[0] == 0) {
            _explorer.removeWhere((element) => element["default_index"] == 1);
          }
        });
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }
  _updatePath(List path, name) {
    _pathToStringData[path.first] = name;
  }

  _backToPrevious(workspaceId, List path, token) {
    if (path.isEmpty) return;
    path.removeAt(0);
    setState(() {
      this._currentPath = path;
    });
    if (path.length >= 1) _loadFolder(workspaceId, path, token);
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final token = Provider.of<Auth>(context, listen: true).token;
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;
    Widget _folderItem({text, onTap}) {
      return HoverItem(
        colorHover: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
            child: Row(
              children: [
                Icon(PhosphorIcons.folderLight, color: Theme.of(context).iconTheme.color),
                SizedBox(width: 10),
                Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w300, overflow: TextOverflow.ellipsis, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)))),
              ],
            ),
          ),
        ),
      );
    }
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(width: 1.0, color: Color(0xff828282))),
      backgroundColor: isDark ? Color(0xff2E2E2E) : Color(0xffFFFFFF),
      title: Container(
        width: 400,
        constraints: BoxConstraints(maxHeight: 55),
        color: isDark ?Color(0xff5E5E5E) : Color(0xffF3F3F3),
        padding: EdgeInsets.all(17.0),
        child: _currentPath.isNotEmpty ? Stack(
          children: [
            Container(
              height: double.infinity,
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () {
                  _backToPrevious(currentWorkspace["id"], this._currentPath, token);
                },
                child: Icon(Icons.arrow_back, size: 16)
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(_pathToStringData[_currentPath.first], style: TextStyle(fontWeight: FontWeight.w300, fontSize: 17, overflow: TextOverflow.ellipsis)),
              ),
            )
          ],
        ) : Container(),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actions: [
        OutlinedButton(
          style: ButtonStyle(side: MaterialStateProperty.all(BorderSide(color: Colors.redAccent, width: 1.0)), fixedSize: MaterialStateProperty.all(Size(90, 30))),
          onPressed: (){
            Navigator.pop(context);
          },
          child: Text("Cancel", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w300))
        ),
        OutlinedButton(
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue), fixedSize: MaterialStateProperty.all(Size(90, 30))),
          onPressed:  _currentPath.isEmpty ? null : () {
            widget.onSelectedPath(this._currentPath);
            Navigator.pop(context);
          },
          child: Text("Move to", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300))
        ),
      ],
      content: Container(
        height: 400,
        width: 400,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Color(0xffDBDBDB)))
        ),
        padding: EdgeInsets.all(7),
        child: _currentPath.length == 0 ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _folderItem(
              text: "Tài liệu công ty",
              onTap: () {
                _loadFolder(currentWorkspace["id"], [0], token);
              }
            ),
            _folderItem(
              text: "Tài liệu của bạn",
              onTap: () {
                _loadFolder(currentWorkspace["id"], [1], token);
              }
            )
          ],
        )
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ..._explorer.map((e) {
                return _folderItem(
                  text: e["name"],
                  onTap: () {
                    _updatePath(e["path"], e["name"]);
                    _loadFolder(currentWorkspace["id"], e["path"], token);
                  }
                );
              }).toList()
            ],
          ),
        ),
      ),
    );
  }
}

class _Rename extends StatefulWidget {
  _Rename({ Key? key, required this.onRename, required this.name }) : super(key: key);
  final String name;
  final Function onRename;

  @override
  State<_Rename> createState() => _RenameState();
}

class _RenameState extends State<_Rename> {
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    _controller.text = widget.name;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      title: Container(
        width: 350,
        color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3), child: Text("Rename Folder", style: TextStyle(fontSize: 16),),
        padding: EdgeInsets.all(10),
      ),
      content: Container(
        padding: EdgeInsets.all(20),
        child: CupertinoTextField(
          decoration: BoxDecoration(color: Colors.grey),
          controller: _controller,
        ),
      ),
      actions: [
        OutlinedButton(
          style: ButtonStyle(side: MaterialStateProperty.all(BorderSide(color: Colors.redAccent, width: 1.0))),
          onPressed: (){
            Navigator.pop(context);
          },
          child: Text("Cancel", style: TextStyle(color: Colors.red),)
        ),
        OutlinedButton(
          onPressed: (){
            widget.onRename.call(_controller.text);
            Navigator.pop(context);
          },
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue)),
          child: Text("Save", style: TextStyle(color: Colors.white),)
        )
      ],
    );
  }
}

class _CreateFolder extends StatefulWidget {
  _CreateFolder({ Key? key, required this.onCreate }) : super(key: key);
  final Function onCreate;

  @override
  State<_CreateFolder> createState() => _CreateFolderState();
}

class _CreateFolderState extends State<_CreateFolder> {
  final TextEditingController _controller = TextEditingController();
  String error = "";

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      title: Container(
        width: 350,
        color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3), child: Text("Create New Folder", style: TextStyle(fontSize: 16),),
        padding: EdgeInsets.all(10),
      ),
      content: Container(
        color: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CupertinoTextField(
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                placeholder: "Name folder",
                placeholderStyle: TextStyle(fontWeight: FontWeight.w400, color: CupertinoColors.placeholderText, fontSize: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Color(0xff5E5E5E) :Color(0xffC9C9C9)),
                  color: isDark ? Color(0xff2E2E2E) : Color(0xffF3F3F3)
                ),
                controller: _controller
              ),
            ),
            Divider(thickness: 1.0, color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2), height: 1.0),
            if (error != "") Text(error, style: TextStyle(fontStyle: FontStyle.italic))
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          style: ButtonStyle(side: MaterialStateProperty.all(BorderSide(color: Colors.redAccent, width: 1.0))),
          onPressed: (){
            Navigator.pop(context);
          },
          child: Text("Cancel", style: TextStyle(color: Colors.red),)
        ),
        OutlinedButton(
          onPressed: (){
            if (_controller.text.isEmpty) {
              setState(() {
                error = "Tên không được để trống";
              });
              return;
            }
            widget.onCreate.call(_controller.text);
            Navigator.pop(context);
          },
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue)),
          child: Text("Create Folder", style: TextStyle(color: Colors.white),)
        )
      ],
    );
  }
}

class _HighlightWidgetBuilder extends StatefulWidget {
  // ignore: unused_element
  const _HighlightWidgetBuilder({Key? key, this.builder}) : super(key: key);
  final builder;

  @override
  State<_HighlightWidgetBuilder> createState() => __HighlightWidgetBuilderState();
}

class __HighlightWidgetBuilderState extends State<_HighlightWidgetBuilder> {
  bool isHighlight = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => setState(() => isHighlight = true),
      onExit: (event) => setState(() => isHighlight = false),
      child: widget.builder(context, isHighlight),
    );
  }
}