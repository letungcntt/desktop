class CardItem{
  String id = "";
  String _title = "No title";
  int? listIndex;
  int? itemIndex;
  int? workspaceId;
  int? channelId;
  int? boardId;
  int? _listCardId;
  String _description = "";
  List _members = [];
  List _labels = [];
  List<dynamic> _activity = [];
  List _checklists = [];
  List _attachments = [];
  int _commentsCount = 0;
  List _tasks = [];
  int? _priority;
  DateTime? _dueDate;
  bool isArchived = false;

  DateTime? get dueDate => this._dueDate;
  set dueDate(DateTime? value) => this._dueDate = value;

  int? get priority => this._priority;
  set priority(int? value) => this._priority = value;

  List get tasks => this._tasks;
  set tasks(List value) => this._tasks = value;

  int get commentsCount => this._commentsCount;
  set commentsCount(int value) => this._commentsCount = value;

  List get attachments => this._attachments;
  set attachments(List value) => this._attachments = value;
 
  List get checklists => this._checklists;
  set checklists(List value) => this._checklists = value;

  List get labels => this._labels;
  set labels(List value) => this._labels = value;

  List get activity => this._activity;
  set activity(List? value) => this._activity = value ?? [];

  String get title => this._title;
  set title(String value) => this._title = value;

  int? get listCardId => _listCardId;
  set listCardId(int? value) => _listCardId = value ?? _listCardId;

  List get members => _members;
  set members(List? value) => _members = value ?? [];

  String get description =>  _description;
  set description(String? value) {
    _description = value ?? _description;
  }

  CardItem({id, title, listIndex, itemIndex, workspaceId, channelId, boardId, listCardId, description, members, labels, activity, checklists, attachments, commentsCount, tasks, isArchived, dueDate, priority}){
    this.id = id != null ? id.toString() : this.id;
    this.title = title ?? this.title;
    this.itemIndex = itemIndex;
    this.listIndex = listIndex;
    this.workspaceId = workspaceId;
    this.channelId = channelId;
    this.boardId = boardId;
    this.listCardId = listCardId;
    this.description = description ?? "";
    this.members = members ?? this.members;
    this.labels = labels ?? this.labels;
    this.activity = activity ?? this.activity;
    this.checklists = checklists ?? this.checklists;
    this.attachments = attachments ?? this.attachments;
    this.commentsCount = commentsCount ?? this.commentsCount;
    this.tasks = tasks ?? this.tasks;
    this.isArchived = isArchived ?? this.isArchived;
    this.dueDate = dueDate;
    this.priority = priority;
  }

  static cardFrom(obj) {
    var card = CardItem(
      id: obj["id"],
      title: obj["title"],
      description: obj["description"],
      listIndex: obj["listIndex"], 
      itemIndex: obj["itemIndex"],
      workspaceId: obj["workspaceId"],
      channelId: obj["channelId"],
      boardId: obj["boardId"],
      listCardId: obj["listCardId"],
      members: obj["members"],
      labels: obj["labels"],
      checklists: obj["checklists"],
      attachments: obj["attachments"],
      commentsCount: obj["commentsCount"],
      tasks: obj["tasks"],
      isArchived: obj["isArchived"],
      dueDate: obj["dueDate"] != null ? DateTime.parse(obj["dueDate"]) : null,
      priority: obj["priority"]
    );

    return card;
  }
}